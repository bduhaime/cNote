// ----------------------------------------------------------------------------------------
// Copyright 2017-2022, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customerCalls/', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'GET:customerCalls/', message: 'start of GET:customerCalls/', user: req.session.userID })

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	= 	`select `
					+		`c.id as callID, `
					+		`c.name as callName, `
					+		`c.callTypeID, `
					+		`ct.name as callTypeName, `
					+		`case when scheduledNamedOffset is not null then concat( format( c.scheduledStartDateTime, 'MM/dd/yyyy hh:mm tt' ), ' ', c.scheduledNamedOffset ) else format( c.scheduledStartDateTime, 'MM/dd/yyyy hh:mm tt' ) end as scheduledStartDateTime, `
					+		`format( c.scheduledStartDateTime, 'MM/dd/yyyy' ) as scheduledStartDate, `
					+		`format( c.scheduledStartDateTime, 'hh:mm tt' ) as scheduledStartTime, `
					+		`case when scheduledNamedOffset is not null then concat( format( c.scheduledEndDateTime, 'MM/dd/yyyy hh:mm tt' ), ' ', c.scheduledNamedOffset ) else format( c.scheduledEndDateTime, 'MM/dd/yyyy hh:mm tt' ) end as scheduledEndDateTime, `
					+		`format( c.scheduledEndDateTime, 'MM/dd/yyyy' ) as scheduledEndDate, `
					+		`format( c.scheduledEndDateTime, 'hh:mm tt' ) as scheduledEndTime, `
					+		`datediff( minute, c.scheduledStartDateTime, c.scheduledEndDateTime ) as scheduledDuration, `
					+		`case when scheduledNamedOffset is not null then null else t.name end as scheduledTimezone, `
					+		`c.scheduledTimeZoneInd, `
					+		`case when c.startDateTime is not null then case when scheduledNamedOffset is not null then concat( format( c.startDateTime, 'MM/dd/yyyy hh:mm tt' ), ' ', c.scheduledNamedOffset ) else format( c.startDateTime, 'MM/dd/yyyy hh:mm tt' )  end else null end as actualStartDateTime, `
					+		`format( c.startDateTime, 'MM/dd/yyyy' ) as actualStartDate, `
					+		`format( c.startDateTime, 'hh:mm tt' ) as actualStartTime, `
					+		`format( c.endDateTime, 'MM/dd/yyyy hh:mm tt' ) as actualEndDateTime, `
					+		`format( c.endDateTime, 'hh:mm tt' ) as actualEndTime, `
					+		`datediff( minute, c.startDateTime, c.endDateTime ) as actualDuration, `
					+		`c.callLead as callLeadID, `
					+ 		`case when u.firstName is not null then concat( u.firstName, ' ', u.lastName ) else null end as callLeadName `
					+	`from customerCalls c `
					+	`left join customerCallTypes ct on ( ct.id = c.callTypeID ) `
					+	`left join csuite..users u on ( u.id = c.callLead ) `
					+	`left join timezones t on (t.id = c.scheduledTimezone) `
					+	`where (c.deleted = 0 or c.deleted is null) `
					+	`and c.customerID = @customerID `
					+	`order by scheduledStartDateTime desc `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( results => {

			res.json( results.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:customerCalls/', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCalls/', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		// return new Promise( async (resolve, reject) => {

			try {

				let callInfo

				logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of POST:customerCalls/', user: req.session.userID })

				if ( !req.body.customerID ) return res.status( 400 ).send( 'Customer ID Parameter missing' )
				if ( !req.body.callType ) return res.status( 400 ).send( 'Call type Parameter missing' )
				if ( !req.body.scheduledStartDateTime ) return res.status( 400 ).send( 'scheduledStartDateTime Parameter missing' )

				let callTypeInfo = await getCustomerCallTypeInfo( req.body.callType )		// gets name, description for the callTypeID

				if ( !!req.body.callID ) {
					// for updating an existing call

					callInfo = await saveExistingCustomerCall( req, callTypeInfo )

				} else {
					// for inserting a new call

					callInfo = await saveNewCustomerCall( req, callTypeInfo )
					let clientAttendees = await saveDefaultClientAttendees( req.body.customerID, callInfo.callID, req.session.userID )
					let customerAttendees = await saveDefaultCustomerAttendees( req.body.customerID, callInfo.callID, req.session.userID )
					let callAgenda = await getCallAgenda( req.body.callType )

					const copyUtopias = ( req.body.copyUtopias == 'true' ) ? true : false
					const copyKeyInitiatives = ( req.body.copyKeyInitiatives == 'true' ) ? true : false
					const copyProjects = ( req.body.copyProjects == 'true' ) ? true : false

					for await ( item of callAgenda ) {

						callInfo.callNoteType = item.id
						callInfo.utopiaInd = item.utopiaInd
						callInfo.copyUtopias = copyUtopias
						callInfo.keyInitiativeInd = item.keyInitiativeInd
						callInfo.copyKeyInitiatives = copyKeyInitiatives
						callInfo.projectInd = item.projectInd
						callInfo.copyProjects = copyProjects
						callInfo.seq = item.seq
						callInfo.name = item.name
						callInfo.description = item.description
						callInfo.quillID = item.quillID

						await saveDefaultCustomerCallNote( callInfo )

					}

				}


				// return res.status( 200 ).send( callInfo )
				// return res.sendStatus( 200 )
				res.json( callInfo.callID )

			} catch( err ) {

				logger.log({ level: 'error', label: 'POST:customerCalls', message: err, user: req.session.userID })
				return res.status( 500 ).send( 'Error while saving call' )

			}

		// })

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/callDetail', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'GET:customerCalls/callDetail', message: 'start of GET:customerCalls/callDetail', user: req.session.userID })

		try {

			if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )


					// +		`case when scheduledNamedOffset is not null then concat( format( c.scheduledStartDateTime, 'MM/dd/yyyy hh:mm tt' ), ' ', c.scheduledNamedOffset ) else format( c.scheduledStartDateTime, 'MM/dd/yyyy hh:mm tt' ) end as scheduledStartDateTime, `


			let SQL	= 	`select `
						+		`c.id as callID, `
						+		`c.name as callName, `
						+		`c.callTypeID, `
						+		`ct.name as callTypeName, `
						+		`case when scheduledNamedOffset is not null then concat( format( c.scheduledStartDateTime, 'MM/dd/yyyy hh:mm tt' ), ' ', c.scheduledNamedOffset ) else format( c.scheduledStartDateTime, 'MM/dd/yyyy hh:mm tt' ) end as scheduledStartDateTime, `
						+		`format( c.scheduledStartDateTime, 'MM/dd/yyyy' ) as scheduledStartDate, `
						+		`format( c.scheduledStartDateTime, 'hh:mm tt' ) as scheduledStartTime, `
						+		`format( c.scheduledEndDateTime, 'MM/dd/yyyy' ) as scheduledEndDate, `
						+		`format( c.scheduledEndDateTime, 'hh:mm tt' ) as scheduledEndTime, `
						+		`datediff( minute, c.scheduledStartDateTime, c.scheduledEndDateTime ) as scheduledDuration, `
						+		`c.scheduledTimezone as scheduledTimezone, `
						+		`case when c.startDateTime is not null then case when scheduledNamedOffset is not null then concat( format( c.startDateTime, 'MM/dd/yyyy hh:mm tt' ), ' ', c.scheduledNamedOffset ) else format( c.startDateTime, 'MM/dd/yyyy hh:mm tt' )  end else null end as actualStartDateTime, `
						+		`format( c.startDateTime, 'MM/dd/yyyy' ) as actualStartDate, `
						+		`format( c.startDateTime, 'hh:mm:ss tt' ) as actualStartTime, `
						+		`datediff( minute, c.startDateTime, c.endDateTime ) as actualDuration, `
						+		`c.callLead as callLeadID, `
						+ 		`case when u.firstName is not null then concat( u.firstName, '', u.lastName ) else null end as callLeadName, `
						+		`c.scheduledTimeZoneInd `
						+	`from customerCalls c `
						+	`left join customerCallTypes ct on ( ct.id = c.callTypeID ) `
						+	`left join csuite..users u on ( u.id = c.callLead ) `
						+	`where c.id = @callID `

			const results = await pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

			const timeZones = moment.tz.names()

			res.json({
				callDetail: results.recordsets[0],
				timezones: timeZones
			})

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:customerCalls/callDetail', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCalls/start/:callID', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			logger.log({ level: 'debug', label: 'POST:customerCalls/start/:callID', message: 'start of POST:customerCalls/start/:callID', user: req.session.userID })

			if ( !req.params.callID ) return res.status( 400 ).send( 'Parameter missing' )

			const callDetails = await getCallDetails( req.params.callID )

			const tempStartDateTime = dayjs()
			const tempStartDateTimeTz = dayjs.tz( tempStartDateTime, callDetails.scheduledTimeZoneInd )
			const startDateTime = dayjs( tempStartDateTimeTz ).format( 'YYYY-MM-DD HH:mm:ss')
			const startDate = dayjs( tempStartDateTimeTz ).format( 'YYYY-MM-DD' )
			const startTime = dayjs( tempStartDateTimeTz ).format( 'hh:mm:ss A' )

			let update = await updateCallStartDateTime( req.params.callID, startDateTime, req.session.userID )

			res.json({
				startDateTime: startDateTime,
				startDate: startDate,
				startTime: startTime
			})

		} catch ( err ) {

			logger.log({ level: 'error', label: 'POST:customerCalls/start/:callID', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCalls/updateScheduledStartDateTime/:callID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'POST:customerCalls/updateScheduledStartDateTime/:callID', message: 'start of POST:customerCalls/updateScheduledStartDateTime/:callID', user: req.session.userID })

		if ( !req.params.callID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.body.scheduledStartDate ) return res.status( 400 ).send( 'Scheduled start date parameter missing' )
		if ( !req.body.scheduledStartTime ) return res.status( 400 ).send( 'Scheduled start time parameter missing' )
		if ( !req.body.scheduledDuration ) return res.status( 400 ).send( 'Scheduled duration parameter missing' )
		if ( !req.body.scheduledTimezone ) return res.status( 400 ).send( 'Scheduled timezone parameter missing' )

		let scheduledStartHour = Number( req.body.scheduledStartTime.split( ':' )[0] )
		const scheduledStartMinAmPm = req.body.scheduledStartTime.split( ':' )[1].split( ' ' )
		const scheduledStartMin = Number( scheduledStartMinAmPm[0] )

		if ( scheduledStartMinAmPm[1] == 'PM' ) {
			scheduledStartHour += 12
			if ( scheduledStartHour > 23 ) {
				scheduledStartHour = 0
			}
		}

		const scheduledStartDateTime = dayjs()
			.year( dayjs( req.body.scheduledStartDate ).year() )
			.month( dayjs( req.body.scheduledStartDate ).month() )
			.date( dayjs( req.body.scheduledStartDate ).date() )
			.hour( scheduledStartHour )
			.minute( scheduledStartMin )
			.format( 'YYYY-MM-DD HH:mm' )

		const scheduledEndDateTime = dayjs( scheduledStartDateTime )
			.add( req.body.scheduledDuration, 'minute' )
			.format( 'YYYY-MM-DD HH:mm' )

		const scheduledTimezone = req.body.scheduledTimezone

		let SQL	= 	`update customerCalls set `
					+		`scheduledStartDateTime = @scheduledStartDateTime, `
					+		`scheduledEndDateTime = @scheduledEndDateTime, `
					+		`scheduledTimezone = @scheduledTimezone, `
					+		`updatedDateTime = CURRENT_TIMESTAMP, `
					+		`updatedBy = @userID `
					+	`where id = @callID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.params.callID )
				.input( 'scheduledStartDateTime', sql.DateTime, scheduledStartDateTime )
				.input( 'scheduledEndDateTime', sql.DateTime, scheduledEndDateTime )
				.input( 'scheduledTimezone', sql.BigInt, scheduledTimezone )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			res.sendStatus( 200 )

		}).catch( err => {

			logger.log({ level: 'error', label: 'POST:customerCalls/updateScheduledStartDateTime/:callID', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCalls/updateActualStartDateTime/:callID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'POST:customerCalls/updateActualStartDateTime/:callID', message: 'start of POST:customerCalls/updateActualStartDateTime/:callID', user: req.session.userID })

		if ( !req.params.callID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.body.actualStartDate ) return res.status( 400 ).send( 'Actual start date parameter missing' )
		if ( !req.body.actualStartTime ) return res.status( 400 ).send( 'Actual start time parameter missing' )
		if ( !req.body.actualDuration ) return res.status( 400 ).send( 'Actual duration parameter missing' )

		let actualStartHour = Number( req.body.actualStartTime.split( ':' )[0] )
		const actualStartMinAmPm = req.body.actualStartTime.split( ':' )[1].split( ' ' )
		const actualStartMin = Number( actualStartMinAmPm[0] )

		if ( actualStartMinAmPm[1] == 'PM' ) {
			actualStartHour += 12
			if ( actualStartHour > 23 ) {
				actualStartHour = 0
			}
		}

		const actualStartDateTime = dayjs()
			.year( dayjs( req.body.actualStartDate ).year() )
			.month( dayjs( req.body.actualStartDate ).month() )
			.date( dayjs( req.body.actualStartDate ).date() )
			.hour( actualStartHour )
			.minute( actualStartMin )
			.format( 'YYYY-MM-DD HH:mm' )

		const actualEndDateTime = dayjs( actualStartDateTime )
			.add( req.body.actualDuration, 'minute' )
			.format( 'YYYY-MM-DD HH:mm' )

		let SQL	= 	`update customerCalls set `
					+		`startDateTime = @actualStartDateTime, `
					+		`endDateTime = @actualEndDateTime, `
					+		`updatedDateTime = CURRENT_TIMESTAMP, `
					+		`updatedBy = @userID `
					+	`where id = @callID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.params.callID )
				.input( 'actualStartDateTime', sql.DateTime, actualStartDateTime )
				.input( 'actualEndDateTime', sql.DateTime, actualEndDateTime )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			res.sendStatus( 200 )

		}).catch( err => {

			logger.log({ level: 'error', label: 'POST:customerCalls/updateActualStartDateTime/:callID', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCalls/end/:callID', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			logger.log({ level: 'debug', label: 'POST:customerCalls/end/:callID', message: 'start of POST:customerCalls/end/:callID', user: req.session.userID })

			if ( !req.params.callID ) return res.status( 400 ).send( 'Parameter missing' )

			const callDetails = await getCallDetails( req.params.callID )

			const tempEndDateTime = await dayjs()
			const tempEndDateTimeTz = await dayjs.tz( tempEndDateTime, callDetails.scheduledTimeZoneInd )
			const endDateTime = await dayjs( tempEndDateTimeTz ).format( 'YYYY-MM-DD HH:mm:ss')
			const endDate = await dayjs( tempEndDateTimeTz ).format( 'YYYY-MM-DD' )
			const endTime = await dayjs( tempEndDateTimeTz ).format( 'hh:mm:ss A' )

			let update = await updateCallEndDateTime( req.params.callID, endDateTime, req.session.user )
			const updatedCallDetails = await getCallDetails( req.params.callID )

			res.json({
				endDateTime: endDateTime,
				endDate: endDate,
				endTime: endTime,
				duration: updatedCallDetails.callDuration
			})

		} catch( err ) {

			logger.log({ level: 'error', label: 'POST:customerCalls/end/:callID', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================



	//====================================================================================
	https.post('/api/customerCalls/saveCallLead', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'POST:customerCalls/saveCallLead', message: 'start of POST:customerCalls/saveCallLead', user: req.session.userID })

		if ( !req.body.callID ) return res.status( 400 ).send( 'callID arameter missing' )

		callLead = ( !!req.body.callLead ) ? req.body.callLead : null

		sql.connect(dbConfig).then( pool => {

		let SQL	= 	`update customerCalls set `
					+		`callLead = @callLead, `
					+		`updatedDateTime = CURRENT_TIMESTAMP, `
					+		`updatedBy = @userID `
					+	`where id = @callID; `

			return pool.request()
				.input( 'callID', sql.BigInt, req.body.callID )
				.input( 'callLead', sql.BigInt, callLead )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			return res.status( 200 ).send( 'Call lead updated' )

		}).catch( err => {

			logger.log({ level: 'error', label: 'POST:customerCalls/saveCallLead', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================



	//====================================================================================
	https.delete('/api/customerCalls/:callID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.callID ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	= 	`update customerCalls set `
					+		`deleted = 1 `
					+	`where id = @callID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.params.callID )
				.query( SQL )

		}).then( result => {

			res.status( 200 ).send( 'Call successfully deleted' )

		}).catch( err => {

			logger.log({ level: 'error', label: 'DELETE:customerCalls/:callID', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCallLeads/', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		// if ( !req.query.callID ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	=	`select `
					+		`u.id, `
					+		`concat( u.firstName, ' ', u.lastName ) as name, `
					+		`active `
					+	`from cSuite..users u `
					+	`join cSuite..clientUsers cu on (cu.userID = u.id) `
					+	`join cSuite..clients c on (c.id = cu.clientID and c.databaseName = @databaseName ) `
					+	`where ( u.deleted = 0 or u.deleted is null ) `
					+	`order by u.firstName, u.lastName `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'databaseName', req.session.dbName )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/callLead', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCalls/emailCall', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const sendAllowed = await utilities.UserPermitted( req.session.userID, 114 )

			if ( sendAllowed ) {
				SendCallEmail( req )
				logger.log({ level: 'debug', label: 'customerCalls/emailCall', message: 'emailCall completed successfully', user: req.session.username })
			} else {
				logger.log({ level: 'debug', label: 'customerCalls/emailCall', message: 'emailCall not sent, user does not have permission', user: req.session.username })
			}
			return res.sendStatus( 200 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'customerCalls/emailCall', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected error while sending email' )

		}
	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/callsByTimeOfDay', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'startDate parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		const cols = [
	   	{id: 'hourOfDay', label: 'hourOfDay', type: 'number'},
			{id: 'callCount', label: 'callCount', type: 'number'}
		]

		let rows = []

		let SQL	= 	`select `
					+		`datepart( hour, cc.endDateTime ) as hourOfDay, `
					+		`count(*) as callCount `
					+	`from customerCalls cc `
					+	`join customer c on ( c.id = cc.customerID ) `
					+	`where cc.endDateTime is not null `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+	`and cc.startDateTime between @startDate and @endDate `
					+ 	`group by datepart( hour, cc.endDateTime ) `
					+	`order by 1 `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			for ( item of result.recordset ) {

				rows.push(
					{c: [
						{ v: item.hourOfDay },
						{ v: item.callCount }
					]}
				)
			}

			res.json({ cols: cols, rows: rows })

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/callsByTimeOfDay', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/callsByDayOfWeek', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'startDate parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		const cols = [
	   	{id: 'dayOfWeekNo', label: 'dayOfWeekNo', type: 'number'},
			{id: 'callCount', label: 'callCount', type: 'number'}
		]

		let rows = []

		let SQL	= 	`select `
					+		`d.dayOfWeekNo, `
					+		`count(*) as callCount `
					+	`from customerCalls cc `
					+	`join customer c on ( c.id = cc.customerID ) `
					+	`left join dateDimension d on ( d.id = convert(date, cc.startDateTime ) ) `
					+	`where cc.startDateTime is not null `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+	`and cc.startDateTime between @startDate and @endDate `
					+	`group by d.dayOfWeekNo `
					+	`order by 1 `

		sql.connect(dbConfig).then( pool => {

			logger.log({ level: 'debug', label: 'customerCalls/callsByDayOfWeek', message: SQL, user: req.session.userID })

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			result.recordset.forEach( item => {

				rows.push(
					{c: [
						{ v: item.dayOfWeekNo },
						{ v: item.callCount }
					]}
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'customerCalls/callsByDayOfWeek', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/completeCallDurationByCustomerType', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'startDate parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		let cols = [
	   	{id: 'customerName', label: 'customerName', type: 'string'}
		]

		let callTypes = await getCustomerCallTypes()

		let sqlCallTypes = []
		callTypes.forEach( column => {
			cols.push({
				id: column.shortName,
				label: column.shortName,
				type: 'number'
			})
			sqlCallTypes.push( column.shortName.toString() ? column.shortName.toString() : 'unknown' )
		})

		let rows = []

		let SQL	= 	`select * `
					+	`from ( `
					+		`select `
					+			`c.name as customerName, `
					+			`cct.shortName as callType, `
					+			`datediff(minute, cc.startDateTime, cc.endDateTime) as callDuration, `
					+			`totals.totalDuration `
					+		`from customerCalls cc `
					+		`join customer c on (c.id = cc.customerID) `
					+		`left join customerCallTypes cct on (cct.id = cc.calltypeID) `

					+		`left join ( `
					+			`select `
					+				`c.id as customerID, `
					+				`sum( datediff(minute, cc.startDateTime, cc.endDateTime) ) as totalDuration `
					+			`from customer c `
					+			`join customerCalls cc on (cc.customerID = c.id) `
					+			`where cc.endDateTime is not null `
					+			`and ( cc.deleted = 0 or cc.deleted is null ) `
					+			`and ( c.deleted = 0 or c.deleted is null ) `
					+			`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+			`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+			`and cc.startDateTime between @startDate and @endDate `
					+			`group by c.id, c.name `
					+		`) totals on (totals.customerID = c.id) `

					+		`where endDateTime is not null `
					+		`and ( cc.deleted = 0 or cc.deleted is null ) `
					+		`and ( c.deleted = 0 or c.deleted is null ) `
					+		`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+		`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+		`and cc.startDateTime between @startDate and @endDate `
					+		`and totals.totalDuration > 0 `
					+	`) as source `
					+	`PIVOT `
					+	`( `
					+		`sum( callDuration ) for callType in ( ` + sqlCallTypes.toString() + ` ) `
					+	`) as pivot_table `
					+	`order by totalDuration desc `

		logger.log({ level: 'debug', label: 'customerCalls/completeCallDurationByCustomerType', message: SQL, user: req.session.userID })

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			result.recordset.forEach( item => {

				let cellValues = [
					{ v: item.customerName }
				]

				callTypes.forEach( column => {
					cellValues.push(
						{ v: item[column.shortName] }
					)
				})

				rows.push(
					{c: cellValues }
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'customerCalls/completeCallDurationByCustomerType', message: err, user: req.session.userID })
			console.error( err )
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/completeCallDurationByCallLeadType', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'startDate parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )


		let cols = [
	   	{id: 'customerName', label: 'customerName', type: 'string'}
		]

		let callTypes = await getCustomerCallTypes()

		let sqlCallTypes = []
		callTypes.forEach( column => {
			cols.push({
				id: column.shortName,
				label: column.shortName,
				type: 'number'
			})
			sqlCallTypes.push( column.shortName.toString() ? column.shortName.toString() : 'unknown' )
		})

		var rows = []

		let SQL	= 	`select * `
					+	`from ( `
					+		`select `
					+			`concat( u.firstName, ' ', u.lastName) as leadName, `
					+			`cct.shortName as callType, `
					+			`datediff( minute, cc.startDateTime, cc.endDateTime ) as callDuration, `
					+			`totals.totalDuration `
					+		`FROM csuite..users u `
					+		`LEFT JOIN customerCalls cc on ( cc.callLead = u.id ) `
					+		`left join customer c on (c.id = cc.customerID) `
					+		`left join customerCallTypes cct on ( cct.id = cc.calltypeID ) `
					+		`left join ( `
					+			`select `
					+				`u.id as userID, `
					+				`sum( datediff(minute, cc.startDateTime, cc.endDateTime) ) as totalDuration `
					+			`from csuite..users u `
					+			`join customerCalls cc on ( cc.callLead = u.id ) `
					+			`join customer c on ( c.id = cc.customerID ) `
					+			`where cc.endDateTime is not null `
					+			`and ( cc.deleted = 0 or cc.deleted is null ) `
					+			`and ( u.deleted = 0 or u.deleted is null ) `
					+			`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+			`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+			`and cc.startDateTime between @startDate and @endDate `
					+			`group by u.id `
					+	`) totals on (totals.userID = u.id) `
					+	`where cc.endDateTime is not null `
					+	`and ( cc.deleted = 0 or cc.deleted is null ) `
					+	`and ( u.deleted = 0 or u.deleted is null ) `
					+		`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+		`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+	`and cc.startDateTime between @startDate and @endDate `
					+	`and totals.totalDuration > 0 `
					+	`) as source `
					+	`PIVOT `
					+	`( `
					+		`sum( callDuration ) for callType in ( ` + sqlCallTypes.toString() + ` ) `
					+	`) as pivot_table `
					+	`order by totalDuration desc `


		sql.connect(dbConfig).then( pool => {


			logger.log({ level: 'debug', label: 'customerCalls/completeCallDurationByCallLeadType', message: SQL, user: req.session.userID })

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			result.recordset.forEach( item => {

				let cellValues = [
					{ v: item.leadName }
				]

				callTypes.forEach( column => {
					cellValues.push(
						{ v: item[column.shortName] }
					)
				})

				rows.push(
					{c: cellValues }
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'customerCalls/completeCallDurationByCallLeadType', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/customersNoCompletedCalls', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'startDate parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		let SQL	= 	`select `
					+		`c.id as customerID, `
					+		`c.name as customerName, `
					+		`cs.name as customerStatusName `
					+	`from customer c `
					+	`left join customerStatus cs on ( cs.id = c.customerStatusID ) `
					+	`where ( c.deleted = 0 or c.deleted is null ) `
					+	`and not exists ( `
					+		`select id `
					+		`from customerCalls cc `
					+		`where cc.customerID = c.id `
					+		`and ( cc.deleted = 0 or cc.deleted is null ) `
					+		`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+		`and cc.scheduledStartDateTime between @startDate and @endDate `
					+	`) `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+ 	`order by c.name `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( results => {

			res.json( results.recordsets[0] )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/customersNoCompletedCalls', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/scheduledCalls', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		let SQL	= 	`select `
					+		`cc.id as callID, `
					+		`format( scheduledStartDateTime, 'yyyy-MM-dd HH:mm') as scheduledStartDateTime, `
					+		`cct.shortName as callType, `
					+		`c.id as customerID, `
					+		`c.name as customerName, `
					+		`cs.name as customerStatus, `
					+		`concat(u.firstName, ' ', u.lastName) as callLead `
					+	`from customerCalls cc `
					+	`left join customer c on (c.id = cc.customerID) `
					+	`left join customerStatus cs on (cs.id = c.customerStatusID) `
					+	`left join customerCallTypes cct on (cct.id = cc.calltypeID) `
					+	`left join csuite..users u on (u.id = cc.callLead) `
					+	`where ( cc.deleted = 0 or cc.deleted is null ) `
					+	`and (c.deleted = 0 or c.deleted is null) `
					+	`and cc.endDateTime is null `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+	`and format( cc.scheduledStartDateTime, 'yyyy-MM-dd' ) between getdate() and @endDate `
					+	`order by scheduledStartDateTime desc  `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( results => {

			res.json( results.recordsets[0] )

		}).catch( err => {
			logger.log({ level: 'error', label: 'customerCalls/scheduledCalls', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/missedCalls', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		let SQL	= 	`select `
					+		`cc.id as callID, `
					+		`format( scheduledStartDateTime, 'yyyy-MM-dd HH:mm') as scheduledStartDateTime, `
					+		`cct.shortName as callType, `
					+		`c.id as customerID, `
					+		`c.name as customerName, `
					+		`cs.name as customerStatus, `
					+		`concat(u.firstName, ' ', u.lastName) as callLead `
					+	`from customerCalls cc `
					+	`left join customer c on (c.id = cc.customerID) `
					+	`left join customerStatus cs on (cs.id = c.customerStatusID) `
					+	`left join customerCallTypes cct on (cct.id = cc.calltypeID) `
					+	`left join csuite..users u on (u.id = cc.callLead) `
					+	`where ( cc.deleted = 0 or cc.deleted is null ) `
					+	`and (c.deleted = 0 or c.deleted is null) `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+	`and cc.scheduledStartDateTime between @startDate and getdate() `
					+	`and cc.endDateTime is null `
					+	`order by scheduledStartDateTime desc  `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.query( SQL )

		}).then( results => {

			res.json( results.recordsets[0] )

		}).catch( err => {
			logger.log({ level: 'error', label: 'customerCalls/missedCalls', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/completedCalls', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeList ) return res.status( 400 ).send( 'callTypeID parameter missing' )
		if ( !req.query.statusList ) return res.status( 400 ).send( 'statusList parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'startDate parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'endDate parameter missing' )

		let SQL	= 	`select `
					+		`cc.id as callID, `
					+		`format( scheduledStartDateTime, 'yyyy-MM-dd HH:mm') as scheduledStartDateTime, `
					+		`cct.shortName as callType, `
					+		`c.id as customerID, `
					+		`c.name as customerName, `
					+		`cs.name as customerStatus, `
					+		`concat(u.firstName, ' ', u.lastName) as callLead `
					+	`from customerCalls cc `
					+	`left join customer c on (c.id = cc.customerID) `
					+	`left join customerStatus cs on (cs.id = c.customerStatusID) `
					+	`left join customerCallTypes cct on (cct.id = cc.calltypeID) `
					+	`left join csuite..users u on (u.id = cc.callLead) `
					+	`where ( cc.deleted = 0 or cc.deleted is null ) `
					+	`and (c.deleted = 0 or c.deleted is null) `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`and cc.callTypeID in ( select value from STRING_SPLIT( @callTypeList, ',' ) ) `
					+	`and cc.scheduledStartDateTime between @startDate and @endDate `
					+	`and cc.endDateTime is not null `
					+	`order by scheduledStartDateTime desc  `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.input( 'callTypeList', req.query.callTypeList )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( results => {

			res.json( results.recordsets[0] )

		}).catch( err => {
			logger.log({ level: 'error', label: 'customerCalls/completedCalls', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/callEmails', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )

		let SQL 	= 	"select "
					+		"l.id as [DT_RowId], "
					// +		"format( l.addedDateTime, 'MM/dd/yyyy HH:mm:ss' ) as [addedDateTime], "
					+		"format( l.addedDateTime, 'yyyy-MM-ddTHH:mm:ss' ) as [addedDateTime], "
					+		"concat(u.firstName, ' ', u.lastName) as fullName, "
					+		"l.subject, "
					+		"l.toList, "
					+		"l.ccList "
					+	"from customerCallEmailLog l "
					+	"left join cSuite..users u on (u.id = l.addedBy) "
					+	"where l.callID = @callID "
					+	"order by l.addedDateTime desc "

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/callEmails', message: 'failed for callID: ' + req.query.callID, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/callInviteesByType', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( `callID parameter missing` )
		if ( !req.query.attendeeType ) return res.status( 400 ).send( `attendeeType parameter missing` )

		let SQL
		if ( req.query.attendeeType === 'user' ) {

			SQL	= 	`select `
					+		`u.id, `
					+		`concat(u.firstName, ' ', u.lastName) as fullName `
					+	`from cSuite..users u `
					+	`where u.id in ( `
					+		`select uc.userID `
					+		`from userCustomers uc `
					+		`where uc.customerID = 1) `
					+	`and u.active = 1 `
					+	`and (u.deleted = 0 or u.deleted is null) `
					+	`and u.id not in ( `
					+		`select ca.attendeeID `
					+		`from customerCallAttendees ca `
					+		`where attendeeType = 'user' `
					+		`and customerCallID = @callID `
					+	`) `
					+	`order by 2 `

		} else if ( req.query.attendeeType === 'contact' ) {

			if ( !req.query.customerID ) return res.status( 400 ).send( `customerID parameter missing` )

			SQL	=	`select `
					+		`cc.id, `
					+		`case when (cc.firstName is null and cc.lastName is null) then cc.name else concat(cc.firstName, ' ', cc.lastName) end as fullName `
					+	`from customerContacts cc `
					+	`where customerID = @customerID `
					+	`and cc.id not in ( `
					+		`select ca.attendeeID `
					+		`from customerCallAttendees ca `
					+		`where attendeeType = 'contact' `
					+		`and customerCallID = @callID `
					+	`) `
					+	`order by 2 `
		} else {

			return res.status( 400 ).send( `attendeeType parameter invalid` )

		}


		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/callInviteesByType', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCalls/callLead', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )

		let SQL 	=	`select `
					+		`u.id, `
					+		`u.firstName, `
					+		`u.lastName, `
					+		`case when cc.callLead is not null then 1 else null end as callLeadInd `
					+	`from cSuite..users u `
					+	`join cSuite..clientUsers cu on ( cu.userID = u.id ) `
					+	`join cSuite..clients c on ( c.id = cu.clientID and c.databaseName = @dbName ) `
					+	`left join customerCalls cc on ( cc.callLead = u.id and cc.id = @callID ) `
					+	`order by u.firstName, u.lastName `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'dbName', sql.VarChar( 128 ), req.session.dbName )
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/callLead', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	async function SendCallEmail( req ) {
	//====================================================================================

		try {

			logger.log({ level: 'debug', label: 'sendCallEmail', message: 'SendCallEmail starting...', user: req.session.username })

			const callID = req.body.callID
			const comments = ( !!req.body.comments ) ? specialCharacters2htmlEntities( req.body.comments ) : ''

			const call = await getCallDetails( callID )
			const agenda = await getCallAgendaNotes( callID )
			const keyInitiatives = await getCallKeyInitiatives( callID )
			const projects = await getCallProjects( callID )
			const tasks = await getCallTasks( callID )


			const transporter = nodemailer.createTransport({
				host: process.env.CLIENT_EMAIL_HOST,
				port: process.env.CLIENT_EMAIL_PORT,
				secure: false,
				tls: {
					secure: true,
					requireTLS: true,
					rejectUnauthorized: false,
					debug: true,
					logger: true
				},
				auth: {
					user: process.env.CLIENT_EMAIL_USER,
					pass: process.env.CLIENT_EMAIL_PASS
				}
			})

			let recap = false
			let requestCall = new sql.Request( pool )

			// const attendees = await getCallAttendees( callID )

			//--------------------------------------------------------------------------------------------------------------------
			//--	Call Details
			//--------------------------------------------------------------------------------------------------------------------
			if ( !!call.actualEndDateTime ) {
				call.emailType 	= 'recap'
				call.agendaHeader = 'Discussion Notes:<br><br>'
			} else {
				call.emailType 	= 'agenda'
				call.agendaHeader = 'Discussion Agenda:<br><br>'

				const callDuration = dayjs( call.scheduledEndDateTime ).diff( call.scheduledStartDateTime, 'minute' )
				const event = {
					title: req.body.subject,
					start: call.scheduledStartTime,
					end: call.scheduledEndDateTime,
					duration: [ callDuration, 'minute' ]
				}
			}

			//--------------------------------------------------------------------------------------------------------------------
			//--	Call Agenda
			//--------------------------------------------------------------------------------------------------------------------
			let agendaList = ''
			for ( item of agenda ) {

				try {

					agendaList += '<table style="border-collapse: collapse; width: 100%;"><thead><tr><th style="text-align: left; padding: 1px 5px 1px 5px; border: solid black 1px;">' + item.name + '</th></tr></thead>'
					if ( call.emailType == 'recap' ) {

						agendaList += '<tbody class="thisIsTheThinkImWorkingOn">'
						// if ( !!item.narrativeHTML && item.narrativeHTML.length > 0 ) {
						if ( !!item.narrative && item.narrative.length > 0 ) {
							agendaList += '<tr><td style="padding: 5px 5px 5px 5px; border: solid black 1px; text-align: left;">' + specialCharacters2htmlEntities( item.narrative ) + '</td></tr>'
							// agendaList += '<tr><td style="padding: 5px 5px 5px 5px; border: solid black 1px; text-align: left;">' + specialCharacters2htmlEntities( item.narrativeHTML ) + '</td></tr>'
							// agendaList += '<tr><td style="padding: 1px 5px 1px 5px; border: solid black 1px;"><div class="ql-editor" contenteditable="false">' + agendaItems[i].narrativeHTML + '<div></td></tr>'
						} else {
							agendaList += '<tr><td style="padding: 5px 5px 5px 5px; border: solid black 1px; text-align: left;">No notes saved for this item</td></tr>'
							// agendaList += '<tr><td style="padding: 1px 5px 1px 5px; border: solid black 1px;"><div class="ql-editor" contenteditable="false"><i>no notes saved for this item</i><div></td></tr>'
						}
						agendaList += '</tbody>'
					}
					agendaList 	+= '</table><br>'

				} catch( err ) {
					logger.log({ level: 'error', label: 'SendCallEmail-Call Agenda', message: `error building 'Call Agenda'` })
					logger.log({ level: 'error', label: 'SendCallEmail-Call Agenda', message: err })
				}
			}


			//--------------------------------------------------------------------------------------------------------------------
			//--	Call Key Initiatives
			//--------------------------------------------------------------------------------------------------------------------
			let kiTable	= '<table><thead><tr><th>Key Initiatives</th><th>Start</th><th>End</th></tr></thead><tbody>'
			for( ki of keyInitiatives ) {

				kiTable 	+= '<tr>'
							+		'<td>' + ki.name.replace( /â„¢/g, '&trade;' ) + '</td>'
							+		'<td class="date">' + dayjs( ki.startDate ).format( 'M/DD/YYYY' ) + '</td>'
							+		'<td class="date">' + dayjs( ki.endDate ).format( 'M/DD/YYYY' ) + '</td>'
							+	'</tr>'
			}
			kiTable += '</tbody></table>'


			//--------------------------------------------------------------------------------------------------------------------
			//--	Call Projects
			//--------------------------------------------------------------------------------------------------------------------
			let projectTable	= '<table><thead><tr><th>Projects</th><th>Start</th><th>End</th></tr></thead><tbody>'
			for ( project of projects ) {
				projectTable 	+= '<tr>'
									+		'<td>' + project.name.replace( /â„¢/g, '&trade;' ) + '</td>'
									+		'<td class="date">' + dayjs( project.startDate ).format('M/DD/YYYY') + '</td>'
									+		'<td class="date">' + dayjs( project.endDate ).format('M/DD/YYYY') + '</td>'
									+	'</tr>'
			}
			projectTable += '</tbody></table>'


			//--------------------------------------------------------------------------------------------------------------------
			//--	Call Tasks
			//--------------------------------------------------------------------------------------------------------------------
			let taskTable	= '<table><thead><tr><th>Tasks</th><th>Start</th><th>Due</th><th>Work Days<br>At Risk</th><th>Work Days<br>Late</th><th>Owner</th><th>Project</th></tr></thead><tbody>'
			for ( task of tasks ) {
				taskTable 	+= '<tr>'
								+		'<td>' + task.name.replace( /â„¢/g, '&trade;' ) + '</td>'
								+		'<td class="date">' + dayjs( task.startDate ).format('M/DD/YYYY') + '</td>'
								+		'<td class="date">' + dayjs( task.dueDate ).format('M/DD/YYYY') + '</td>'
								+		'<td class="wdar">' + task.workDaysAtRisk + '</td>'
								+		'<td class="wdb">' + task.workDaysBehind + '</td>'
								+		'<td>' + task.ownerName + '</td>'

				if ( task.projectName ) {
					taskTable += '<td>' + task.projectName.replace( /â„¢/g, '&trade;' ) + '</td>'
				} else {
					taskTable += '<td></td>'
				}
				taskTable += '</tr>'

			}
			taskTable += '</tbody></table>'


			//--------------------------------------------------------------------------------------------------------------------
			//--	Build the HTML for the email....
			//--------------------------------------------------------------------------------------------------------------------

			const html 	= 	'<html>'
							+		'<head>'
							+			'<meta charset="UTF-8">'
							+			'<title></title>'
							+			'<link href="https://cdn.quilljs.com/1.3.5/quill.snow.css" rel="stylesheet">'
							+			'<style>'
							+				'body {width: 600px;}'
							+				'table {border-collapse: collapse; width: 100%;}'
							+				'table.header th, table.header td {border: none; text-align: center;}'
							+				'th, td {padding: 1px 5px 1px 5px; border: solid black 1px;}'
							+				'.date {white-space: nowrap; width: 80px; text-align: center;}'
							+				'li, .agenda {text-align: left;}'
							+				'.wdar {text-align: right;}'     // wdb:: Work Days A Risk
							+				'.wdb {text-align: right;}'     // wdb:: Work Days Behind
							+			'</style>'
							+		'</head>'
							+		'<body>'
							+			'<div style="width: 100%">' + comments.replace(/\n/g, '<br>') + '</div>'
							// +			'<br><br>'
							// +			linksTable
							+			'<br><br>'
							+			'<table class="header">'
							+				'<thead>'
							+					'<tr>'
							+						'<th>Call Info</th>'
							+					'</tr>'
							+					'<tr>'
							+						'<th>' + call.customerName + ' - ' + call.callName + '<br>' + dayjs(call.scheduledStartDateTime).format('dddd, MMMM D YYYY') + ': ' + dayjs(call.scheduledStartDateTime).format('h:mm A') + ' - ' + dayjs(call.scheduledEndDateTime).format('h:mm A') + ' ' + call.scheduledTimeZone + '</th>'
							+					'</tr>'
							+				'</thead>'
							+				'<tbody>'
							+					'<tr>'
							+						'<td><div class="agenda"><br><b>' + call.agendaHeader + '</b></div></td>'
							+					'</tr>'
							+					'<tr>'
							+						'<td class="agenda-item">' + agendaList + '	</td>'
							+					'</tr>'
							+				'</tbody>'
							+			'</table>'
							+			'<br><br>'
							+			kiTable
							+			'<br><br>'
							+			projectTable
							+			'<br><br>'
							+			taskTable
							+		'</body>'
							+	'</html>'

			const subject = process.env.ENVIRONMENT ? req.body.subject + ' [' + process.env.ENVIRONMENT + ']' : req.body.subject


			let email = transporter.sendMail({
				from: process.env.CLIENT_EMAIL_USER,
				to: req.body.to,
				cc: req.body.cc,
				replyTo: process.env.CLIENT_EMAIL_REPLYTO,
				subject: subject,
				text: comments,
				html: html
			})

			logger.log({ level: 'debug', label: 'sendCallEmail', message: 'Message sent: ' + email.messageId, user: req.session.username })

			const objEmail = {
				addedBy: req.session.userID,
				subject: subject,
				toList: req.body.to,
				ccList: req.body.cc,
				body: comments,
				html: html,
				callID: callID
			}

			try {
				await saveCallEmail( objEmail )
			} catch( err ) {
				throw new Error( err )
			}


		} catch( err ) {

			logger.log({ level: 'error', label: 'sendCallEmail', message: err })
			throw new Error( err )

		}

	}
	//====================================================================================


	//====================================================================================
	function getCallDetails( callID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	= 	`select `
						+		`cc.id, `
						+		`cc.name as callName, `
						+		`cc.scheduledStartDateTime, `
						+		`cc.scheduledEndDateTime, `
						+		`scheduled.name as scheduledTimeZone, `
						+		`cc.startDateTime as actualStartDateTime, `
						+		`cc.endDateTime as actualEndDateTime, `
						+		`c.name as customerName, `
						+		`cc.scheduledTimeZoneInd, `
					+			`datediff(minute, cc.startDateTime, cc.endDateTime) as callDuration `
						+	`from customerCalls cc `
						+	`left join customer c on (c.id = cc.customerID) `
						+	`left join timezones scheduled on (scheduled.id = cc.scheduledTimeZone) `
						+	`where cc.id = @callID `

			sql.connect(dbConfig).then( pool => {
				return pool.request().input( 'callID', sql.BigInt, callID ).query( SQL)
			}).then( result => {
				return resolve( result.recordset[0] )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCallDetails()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function updateCallStartDateTime( callID, startDateTime, userID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL	= 	`update customerCalls set `
						+		`startDateTime = @startDateTime, `
						+		`updatedDateTime = CURRENT_TIMESTAMP, `
						+		`updatedBy = @userID `
						+	`where id = @callID `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'callID', sql.BigInt, callID )
					.input( 'startDateTime', sql.DateTime, startDateTime )
					.input( 'userID', sql.BigInt, userID )
					.query( SQL )

			}).then( result => {

				return resolve()

			}).catch( err => {

				logger.log({ level: 'error', label: 'customerCalls/updateCallStartDateTime()', message: err })
				return reject( err )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function updateCallEndDateTime( callID, endDateTime, userID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL	= 	`update customerCalls set `
						+		`endDateTime = @endDateTime, `
						+		`updatedDateTime = CURRENT_TIMESTAMP, `
						+		`updatedBy = @userID `
						+	`where id = @callID `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'callID', sql.BigInt, callID )
					.input( 'endDateTime', sql.DateTime, endDateTime )
					.input( 'userID', sql.BigInt, userID )
					.query( SQL )

			}).then( result => {

				return resolve()

			}).catch( err => {

				logger.log({ level: 'error', label: 'customerCalls/updateCallEndDateTime()', message: err })
				return reject( err )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCallAgendaNotes( callID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`cn.seq, `
						+		`cn.name, `
						+		`cn.narrative, `
						+		`replace(replace(replace(narrativeHTML, 'â„¢', '&trade;'), 'â€“', '&ndash;' ), 'â€”', '&mdash;' )  as narrativeHTML `
						+	`from customerCallNotes cn `
						+	`left join noteTypes nt on (nt.id = cn.noteTypeID) `
						+	`where cn.customerCallID = @callID `
						+	`and nt.includeWithEmails = 1 `
						+	`order by cn.seq `

			sql.connect(dbConfig).then( pool => {
				return pool.request().input( 'callID', sql.BigInt, callID ).query( SQL)
			}).then( result => {

				let agendaNotes = []
				let html = ''
				const { QuillDeltaToHtmlConverter } = require( 'quill-delta-to-html' )

				for ( row of result.recordset ) {

					try {

						const narrative = JSON.parse( row.narrative )

						if ( !!narrative && narrative.ops.length > 0 ) {
							const converter = new QuillDeltaToHtmlConverter( narrative.ops, {} )
							html = converter.convert()
						} else {
							html = ''
						}

						agendaNotes.push({
							seg: row.seq,
							name: row.name,
							narrative: html,
							narrativeHTML: row.narrativeHTML
						})

					} catch( err ) {

						logger.log({ level: 'error', label: 'customerCalls/getCallAgendaNotes()', message: `Error retrieving/parsing Quill.js delta` })
						logger.log({ level: 'error', label: 'customerCalls/getCallAgendaNotes()', message: err })

					}

				}

				return resolve( agendaNotes )

			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCallAgendaNotes()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCallAttendees( callID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`a.id, `
						+		`a.attendeeType as [type], `
						+		`case when attendeeType = 'user' then trim(u.userName) else trim(c.email) end as email, `
						+		`case when attendeeType = 'user' then concat(u.firstName, ' ', u.lastName) else concat(c.firstName, ' ', c.lastName) end as [name] `
						+	`from customerCallAttendees a `
						+	`left join cSuite..users u on (u.id = a.attendeeID and attendeeType = 'user') `
						+	`left join customerContacts c on (c.id = attendeeID and attendeeType = 'contact') `
						+	`where customerCallID = @callID `
						+	`order by u.lastName, u.firstName `

			sql.connect(dbConfig).then( pool => {
				return pool.request().input( 'callID', sql.BigInt, callID ).query( SQL)
			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCallAttendees()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCallKeyInitiatives( callID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`replace(name, 'â„¢', '&trade;') as name, `
						+		`startDate, `
						+		`endDate `
						+	`from keyInitiatives `
						+	`where completeDate is null `
						+	`and customerID = (select customerID from customerCalls where id = @callID) `
						+	`order by endDate `

			sql.connect(dbConfig).then( pool => {
				return pool.request().input( 'callID', sql.BigInt, callID ).query( SQL)
			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCallKeyInitiatives()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCallProjects( callID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`p.id, `
						+		`replace(p.name, 'â„¢', '&trade;') as name, `
						+		`p.startDate, `
						+		`p.endDate, `
						+		`status.type as status `
						+	`from projects p `
						+	`outer apply ( `
						+		`select top 1 * `
						+		`from projectStatus ps `
						+		`where ps.projectID = p.id `
						+		`order by updatedDateTime desc `
						+		`) as status `
						+	`where p.customerID = (select customerID from customerCalls where id = @callID) `
						+	`and (status.type <> 'Complete' or status.type is null) `
						+	`and (p.deleted = 0 or p.deleted is null) `
						+	`order by p.endDate `

			sql.connect(dbConfig).then( pool => {
				return pool.request().input( 'callID', sql.BigInt, callID ).query( SQL)
			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCallProjects()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCallTasks( callID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`t.id, `
						+		`replace(t.name, 'â„¢', '&trade;') as name, `
						+		`t.startDate, `
						+		`t.dueDate, `
						+		`t.completionDate, `
						+		`t.ownerID, `
						+		`concat(c.firstName, ' ', c.lastName) as ownerName, `
						+		`p.name as projectName `
						+	`from tasks t `
						+	`left join customerContacts c on (c.id = t.ownerID) `
						+	`left join projects p on (p.id = t.projectID) `
						+	`where completionDate is null `
						+	`and t.ownerID is not null `
						+	`and t.customerID = (select customerID from customerCalls where id = @callID) `
						+	`order by t.dueDate `

			sql.connect(dbConfig).then( pool => {
				return pool.request().input( 'callID', sql.BigInt, callID ).query( SQL)
			}).then( result => {

				let tasks = [];
				let workDaysAtRisk, workDaysBehind;

				for (const row of result.recordset) {

					const { daysAtRisk, daysBehind } = utilities.workDaysSummary( row.startDate, row.dueDate, row.completionDate );

					tasks.push({
						id: row.id,
						name: row.name,
						startDate: row.startDate,
						dueDate: row.dueDate,
						workDaysAtRisk: daysAtRisk,
						workDaysBehind: daysBehind + 1,
						ownerID: row.ownerID,
						ownerName: row.ownerName,
						projectName: row.projectName
					});

				}

				return resolve( tasks );

			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCallTasks()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function saveCallEmail( objEmail ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	= `insert into customerCallEmailLog ( `
						+		`addedDateTime, `
						+		`addedBy, `
						+		`subject, `
						+		`toList, `
						+		`ccList, `
						+		`body, `
						+		`html, `
						+		`callID `
						+	`) values ( `
						+		`current_timestamp, `
						+		`@addedBy, `
						+		`@subject, `
						+		`@toList, `
						+		`@ccList, `
						+		`@body, `
						+		`@html, `
						+		`@callID `
						+	`) `

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'addedBy', sql.BigInt, objEmail.addedBy )
					.input( 'subject', sql.NVarChar( sql.Max ), objEmail.subject )
					.input( 'toList', sql.NVarChar( sql.Max ), objEmail.toList )
					.input( 'ccList', sql.NVarChar( sql.Max ), objEmail.ccList )
					.input( 'body', sql.NVarChar( sql.Max ), objEmail.body )
					.input( 'html', sql.NVarChar( sql.Max ), objEmail.html )
					.input( 'callID', sql.BigInt, objEmail.callID )
					.query( SQL)
			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/saveCallEmail()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function specialCharacters2htmlEntities( html ) {
	//====================================================================================

		return html
			.replace( /·/g, "&bull;" )
			.replace( /•/g, "&bull;" )
			.replace( /'/g, "&apos;" )						// single-quote
			.replace( /‘/g, "&apos;")						// left smart single-quote
			.replace( /’/g, "&apos;")						// right  smart singe-quote
			.replace( /"/g, "&quot;" )						// double-quote
			.replace( /“/g, "&quot;" )						// left smart double-quote
			.replace( /”/g, "&quot;" )						// right smart double-quote
			.replace( /\—/g, "&mdash;" )
			.replace( /\–/g, "&ndash;" )
			.replace( /™/g, "&trade;" )
			.replace( /\u2122/g, "&trade;" )
			.replace( /\u2013/g, "&ndash;" )
			.replace( /\u2022/g, "&bull;" )
			.replace( /\u0022/g, "&quot;" )
			.replace( /<p><br><\/p>/g, "" )

	}
	//====================================================================================


	//====================================================================================
	function getCustomerCallTypes() {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	"select shortName as shortName "
						+	"from customerCallTypes "

			sql.connect(dbConfig).then( pool => {
				return pool.request().query( SQL)
			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCustomerCallTypes()', message: err })
				return reject( 'Error getting customerCallTypes' )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function parseCallTypeList( callTypes ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			try {

				let arrCallTypeList = JSON.parse( callTypes )

				if ( arrCallTypeList.length <= 0 ) {
					return reject( 'no call type selected' )
				}

				let inList = ''
				arrCallTypeList.forEach( item => {
					if ( inList.length > 0 ) {
						inList += ','
					}
					inList += parseInt( item )
				})

				return resolve( inList )

			} catch( err ) {

				logger.log({ level: 'error', label: 'customerCalls/parseCallTypeList()', message: err })
				return reject( err )

			}

		})

	}
	//====================================================================================


	//====================================================================================
	function getCustomerCallTypeInfo( callTypeID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of getCustomerCallTypeInfo()' })

			let SQL 	=	`select id, name, description `
						+	`from customerCallTypes `
						+	`where id = @callTypeID `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'callTypeID', sql.BigInt, callTypeID )
					.query( SQL)

			}).then( result => {

				return resolve( result.recordset[0] )

			}).catch( err => {

				logger.log({ level: 'error', label: 'customerCalls/getCustomerCallTypeInfo()', message: err })
				return reject( 'Error getting getCustomerCallTypeName' )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function saveNewCustomerCall( req, callTypeInfo ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of saveNewCustomerCall()' })

			const startTimezone = ( !!req.body.timezone ) ? req.body.timezone : 3	// "3" represents Central - America/Chicago timeZone
			const duration = ( !!req.body.duration ) ? req.body.duration : 30
			const scheduledTimeZoneInd = req.body.scheduledTimeZoneInd
			const scheduledNamedOffset = req.body.scheduledNamedOffset

			const scheduledStartDateTime = dayjs( req.body.scheduledStartDateTime )
				.format( 'YYYY-MM-DD HH:mm' )

			const scheduledEndDateTime = dayjs( scheduledStartDateTime )
				.add( duration, 'minute' )
				.format( 'YYYY-MM-DD HH:mm' )

			let SQL 	= 	`insert into customerCalls ( `
						+		`customerID, `
						+		`userID, `
						+		`callTypeID, `
						+		`scheduledStartDateTime, `
						+		`name, `
						+		`description, `
						+		`updatedBy, `
						+		`updatedDateTime, `
						+		`scheduledTimezone, `
						+		`scheduledEndDateTime, `
						+		`scheduledTimeZoneInd, `
						+		`scheduledNamedOffset `
						+	`) values ( `
						+		`@customerID, `
						+		`@userID, `
						+		`@callTypeID, `
						+		`@scheduledStartDateTime, `
						+		`@callTypeName, `
						+		`@callTypeDescription, `
						+		`@userID, `
						+		`CURRENT_TIMESTAMP, `
						+		`@scheduledTimezone, `
						+		`@scheduledEndDateTime, `
						+		`@scheduledTimeZoneInd, `
						+		`@scheduledNamedOffset `
						+	`); `
						+	`select SCOPE_IDENTITY() as id; `


			sql.connect( dbConfig ).then( pool => {

				return pool.request()
					.input( 'customerID', sql.BigInt, req.body.customerID )
					.input( 'userID', sql.BigInt, req.session.userID )
					.input( 'callTypeID', sql.BigInt, callTypeInfo.id )
					.input( 'scheduledStartDatetime', sql.DateTime2, scheduledStartDateTime )
					.input( 'callTypeName', sql.VarChar( 255 ), callTypeInfo.name )
					.input( 'callTypeDescription', sql.VarChar( sql.MAX ), callTypeInfo.description )
					.input( 'scheduledTimezone', sql.BigInt, startTimezone)
					.input( 'scheduledEndDateTime', sql.DateTime2, scheduledEndDateTime )
					.input( 'scheduledTimeZoneInd', sql.VarChar( 50 ), scheduledTimeZoneInd )
					.input( 'scheduledNamedOffset', sql.VarChar( 50 ), scheduledNamedOffset )
					.query( SQL)

			}).then( result => {

				return resolve({
					callID: result.recordset[0].id,
					customerID: req.body.customerID,
					callTypeID: callTypeInfo.id,
					callTypeName: callTypeInfo.name,
					callTypeDescription: callTypeInfo.description,
					scheduledStartDateTime: scheduledStartDateTime,
					scheduledTimezone: startTimezone,
					duration: duration,
					scheduledEndDateTime: scheduledEndDateTime,
					userID: req.session.userID,
					scheduledTimeZoneInd: scheduledTimeZoneInd,
					scheduledNamedOffset: scheduledNamedOffset
				})

			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/saveNewCustomerCall()', message: err })
				return reject( 'Error inserting into customerCalls' )
			})


		})

	}
	//====================================================================================


	//====================================================================================
	function saveExistingCustomerCall( req, callTypeInfo ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of saveExistingCustomerCall()' })

			const callID = req.body.callID
			const startTimezone = ( req.body.timezone ) ? req.body.timezone : 3	// "3" represents Central timeZone
			const duration = ( req.body.duration ) ? req.body.duration : 30
			const scheduledTimeZoneInd = req.body.scheduledTimeZoneInd
			const scheduledNamedOffset = req.body.scheduledNamedOffset

			const scheduledStartDateTime = dayjs( req.body.scheduledStartDateTime )
				.format( 'YYYY-MM-DD HH:mm' )

			const scheduledEndDateTime = dayjs( scheduledStartDateTime )
				.add( duration, 'minute' )
				.format( 'YYYY-MM-DD HH:mm' )

			const startDateTime = ( !!req.body.actualStartDateTime ) ? dayjs( req.body.actualStartDateTime, 'YYYY-MM-DDTHH:mm' ).format( 'YYYY-MM-DD HH:mm' ) : null
			const endDateTime = ( !!req.body.actualEndDateTime ) ? dayjs( req.body.actualEndDateTime, 'YYYY-MM-DDTHH:mm' ).format( 'YYYY-MM-DD HH:mm' ) : null

			let SQL 	= 	`update customerCalls set `
						+		`callTypeID = @callTypeID, `
						+		`scheduledStartDateTime = @scheduledStartDateTime, `
						+		`name = @callTypeName, `
						+		`description = @callTypeDescription, `
						+		`updatedBy = @userID, `
						+		`updatedDatetime = CURRENT_TIMESTAMP, `
						+		`scheduledTimezone = @scheduledTimezone, `
						+		`scheduledEndDateTime = @scheduledEndDateTime, `
						+		`scheduledTimeZoneInd = @scheduledTimeZoneInd, `
						+		`scheduledNamedOffset = @scheduledNamedOffset, `
						+		`startDateTime = @startDateTime, `
						+		`endDateTime = @endDateTime `
						+	`where id = @id `

			sql.connect( dbConfig ).then( pool => {

				return pool.request()
					.input( 'id', sql.BigInt, callID )
					.input( 'callTypeID', sql.BigInt, callTypeInfo.id )
					.input( 'scheduledStartDatetime', sql.DateTime2, scheduledStartDateTime )
					.input( 'callTypeName', sql.VarChar( 255 ), callTypeInfo.name )
					.input( 'callTypeDescription', sql.VarChar( sql.MAX ), callTypeInfo.description )
					.input( 'userID', sql.BigInt, req.session.userID )
					.input( 'scheduledTimezone', sql.BigInt, startTimezone)
					.input( 'scheduledEndDateTime', sql.DateTime2, scheduledEndDateTime )
					.input( 'scheduledTimeZoneInd', sql.VarChar( 50 ), scheduledTimeZoneInd )
					.input( 'scheduledNamedOffset', sql.VarChar( 50 ), scheduledNamedOffset )
					.input( 'startDateTime', sql.DateTime2, startDateTime )
					.input( 'endDateTime', sql.DateTime2, endDateTime )
					.query( SQL)

			}).then( result => {

				return resolve({
					callID: callID
				})

			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/saveExistingCustomerCall()', message: err })
				console.err( err )
				return reject( 'Error updating customerCalls' )
			})


		})

	}
	//====================================================================================



	//====================================================================================
	async function saveDefaultCustomerCallNote( callInfo ) {
	//====================================================================================

		try {

			logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of saveDefaultCustomerCallNote()' })

			switch ( true ) {

				case ( callInfo.utopiaInd ):
					if ( callInfo.copyUtopias ) {
						let utopiaRawNotes = await getCustomerUtopias( callInfo.customerID )
						callInfo.narrative = await getQuillNotes( utopiaRawNotes )
					} else {
						callInfo.narrative = null
					}
					break

				case ( callInfo.keyInitiativeInd ):
					if ( callInfo.copyKeyInitiatives ) {
						let kiRawNotes = await getCustomerKeyInitiative( callInfo.customerID )
						callInfo.narrative = await getQuillNotes( kiRawNotes )
					} else {
						callInfo.narrative = null
					}
					break

				case ( callInfo.projectInd ):
					if ( callInfo.copyProjects ) {
						let projectRawNotes = await getCustomerProjects( callInfo.customerID )
						callInfo.narrative = await getQuillNotes( projectRawNotes )
					} else {
						callInfo.narrative = null
					}
					break

				default:
					callInfo.narrative = null

			}

			await insertCustomerCallNote( callInfo )

			return true

		} catch( err ) {

			logger.log({ level: 'error', label: 'customerCalls/saveDefaultCustomerCallNote()', message: err })
			throw new Error( 'Error saving default customer call notes, see log' )

		}


	}
	//====================================================================================


	//====================================================================================
	async function getQuillNotes( rawNotes ) {
	//====================================================================================

		try {

			logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of getQuillNotes()' })

			let narrativeArray = []

			if ( rawNotes ) {

				for ( item of rawNotes ) {

					let itemName = ( item.itemName ) ? utilities.filterSpecialCharacters( item.itemName ) : 'Unnamed Item'
					let objectiveName = ( item.objName ) ? utilities.filterSpecialCharacters( item.objName ) : ''
					let narrative

					if ( objectiveName ) {
						narrative = `${itemName}: ${objectiveName}`
					} else {
						narrative = `${itemName}`
					}

					narrativeArray.push(
						{ insert: narrative }, {attributes: { list: 'bullet' }, insert: '\n' }
					)

				}

			}

			return { "ops": narrativeArray }

		} catch( err ) {

			logger.log({ level: 'error', label: 'customerCalls/getQuillNotes()', message: err })
			throw new Error( 'Error in getQuillNotes()' )

		}

	}
	//====================================================================================


	//====================================================================================
	function getCustomerUtopias( customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'customerCalls/getCustomerUtopias()', message: 'start of getCustomerUtopias()' })

			let SQL 	=	`select `
						+		`i.name as itemName, `
						+		`case when o.narrative is not null then o.narrative else m.name end as objName `
						+	`from customerImplementations i `
						+	`left join customerObjectives o on (o.implementationID = i.id) `
						+	`left join metric m on (m.id = o.metricID) `
						+	`where (o.startDate <= current_timestamp or o.startDate is null) `
						+	`and (o.endDate > CURRENT_TIMESTAMP or o.endDate is null) `
						+	`and (i.startDate <= CURRENT_TIMESTAMP or i.startDate is null) `
						+	`and (i.endDate > CURRENT_TIMESTAMP or i.endDate is null) `
						+	`and (i.deleted = 0 or i.deleted is null) `
						+	`and o.objectiveTypeID = 1 `
						+	`and o.opportunityID is null `
						+	`and i.customerID = @customerID `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL)

			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCustomerUtopias()', message: err })
				return reject( 'Error in customerCalls/getCustomerUtopias()' )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCustomerKeyInitiative( customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'customerCalls/getCustomerKeyInitiative()', message: 'start of getCustomerKeyInitiative()' })

			let SQL 	=	`select name as itemName `
						+	`from keyInitiatives `
						+	`where completeDate is null `
						+	`and customerID = @customerID  `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL)

			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCustomerKeyInitiative()', message: err })
				return reject( 'Error in customerCalls/getCustomerKeyInitiative()' )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCustomerProjects( customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'customerCalls/getCustomerProjects()', message: 'start of getCustomerProjects()' })

			let SQL 	=	`select name as itemName `
						+	`from projects p `
						+	`left join ( `
						+		`select ps1.projectID, type `
						+		`from projectStatus ps1 `
						+		`where updatedDateTime = ( `
						+			`select max( updatedDateTime ) `
						+			`from projectStatus ps2 `
						+			`where ps2.projectID = ps1.projectID `
						+		`) `
						+	`) ps on (ps.projectID = p.id) `
						+	`where ( type <> 'Complete' or type is null ) `
						+	`and customerID = @customerID `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL)

			}).then( result => {
				return resolve( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'customerCalls/getCustomerProjects()', message: err })
				return reject( 'Error in customerCalls/getCustomerProjects()' )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCallAgenda( callTypeID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of getCallAgenda()' })

			let SQL 	=	`select `
						+		`id, `
						+		`name, `
						+		`description, `
						+		`quillID, `
						+		`utopiaInd, `
						+		`keyInitiativeInd, `
						+		`projectInd, `
						+		`seq `
						+	`from noteTypes `
						+	`where callTypeID = @callTypeID `
						+	`order by seq  `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'callTypeID', sql.BigInt, callTypeID )
					.query( SQL)

			}).then( result => {

				return resolve( result.recordset )

			}).catch( err => {

				logger.log({ level: 'error', label: 'customerCalls/getCallAgenda()', message: err })
				return reject( 'Error getting getCallAgenda()' )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function insertCustomerCallNote( callNoteInfo ) {
	//====================================================================================

		return new Promise( async (resolve, reject) => {

			try {

				logger.log({ level: 'debug', label: 'POST:customerCalls/', message: 'start of insertCustomerCallNote()' })

				const newID = await utilities.GetNextID( 'customerCallNotes' )

				let SQL 	=	`insert into customerCallNotes ( `
							+		`id, `
							+		`customerCallID, `
							+		`noteTypeID, `
							+		`updatedBy, `
							+		`updatedDateTime, `
							+		`narrative, `
							+		`seq, `
							+		`name, `
							+		`quillID, `
							+		`description `
							+	`) values ( `
							+		`@newID, `
							+		`@customerCallID, `
							+		`@noteTypeID, `
							+		`@userID, `
							+		`CURRENT_TIMESTAMP, `
							+		`@narrative, `
							+		`@seq, `
							+		`@name, `
							+		`@quillID, `
							+		`@description `
							+	`) `

				sql.connect(dbConfig).then( pool => {

					return pool.request()
						.input( 'newID', sql.BigInt, newID )
						.input( 'customerCallID', sql.BigInt, callNoteInfo.callID )
						.input( 'noteTypeID', sql.BigInt, callNoteInfo.callNoteType )
						.input( 'userID', sql.BigInt, callNoteInfo.userID )
						.input( 'narrative', sql.VarChar( sql.MAX ), JSON.stringify( callNoteInfo.narrative ) )
						.input( 'seq', sql.Int, callNoteInfo.seq )
						.input( 'name', sql.VarChar( 255 ), callNoteInfo.name )
						.input( 'quillID', sql.VarChar( 20 ), callNoteInfo.quillID )
						.input( 'description', sql.VarChar( sql.MAX ), callNoteInfo.description )
						.query( SQL)

				}).then( result => {

					return resolve()

				}).catch( err => {

					logger.log({ level: 'error', label: 'POST:customerCalls/', message: 'err' })
					throw new Error( 'error inserting customerCalNotes in Error in insertCustomerCallNote()' )

				})

			} catch( err ) {

				return reject( err )

			}

		})

	}
	//====================================================================================


	//====================================================================================
	function saveDefaultClientAttendees( customerID, callID, userID ) {
	//====================================================================================

		return new Promise( async (resolve, reject) => {

			try {

				logger.log({ level: 'debug', label: 'customerCalls/saveDefaultClientAttendees()', message: 'start of insertCustomerCallNote()' })

				if ( !customerID ) throw new Error( 'customerID Parameter missing' )
				if ( !callID ) throw new Error( 'callID Parameter missing' )
				if ( !userID ) throw new Error( 'userID Parameter missing' )

				let SQL 	=	`insert into customerCallAttendees ( customerCallID, attendeeType, attendeeID, updatedBy, updatedDateTime ) `
							+	`select distinct `
							+		`@callID, `
							+		`'user', `
							+		`cm.userID, `
							+		`@userID, `
							+		`CURRENT_TIMESTAMP `
							+	`from customerManagers cm `
							+	`join csuite..users u on (u.id = cm.userID) `
							+	`where cm.startDate <= CURRENT_TIMESTAMP `
							+	`and (cm.endDate >= CURRENT_TIMESTAMP or cm.endDate is null) `
							+	`and u.active = 1 `
							+	`and (u.deleted = 0 or u.deleted is null) `
							+	`and cm.customerID = @customerID `

				sql.connect(dbConfig).then( pool => {

					return pool.request()
						.input( 'callID', sql.BigInt, callID )
						.input( 'userID', sql.BigInt, userID )
						.input( 'customerID', sql.BigInt, customerID )
						.query( SQL)

				}).then( result => {

					return resolve( true )

				}).catch( err => {

					logger.log({ level: 'error', label: 'customerCalls/saveDefaultClientAttendees()', message: 'err' })
					throw new Error( 'error inserting default client attendees in saveDefaultClientAttendees()' )

				})

			} catch( err ) {

				return reject( err )

			}

		})

	}
	//====================================================================================


	//====================================================================================
	function saveDefaultCustomerAttendees( customerID, callID, userID ) {
	//====================================================================================

		return new Promise( async (resolve, reject) => {

			try {

				logger.log({ level: 'debug', label: 'customerCalls/saveDefaultCustomerAttendees()', message: 'start of insertCustomerCallNote()' })

				if ( !customerID ) throw new Error( 'customerID Parameter missing' )
				if ( !callID ) throw new Error( 'callID Parameter missing' )
				if ( !userID ) throw new Error( 'userID Parameter missing' )

				let SQL 	=	`insert into customerCallAttendees ( customerCallID, attendeeType, attendeeID, updatedBy, updatedDateTime ) `
							+	`select distinct `
							+		`@callID, `
							+		`'contact', `
							+		`cc.id, `
							+		`@userID, `
							+		`CURRENT_TIMESTAMP `
							+	`from customerContacts cc `
							+	`where cc.customerID = @customerID `
							+	`and cc.callAttendee = 1 `
							+	`and ( cc.deleted = 0 or cc.deleted is null ) `

				sql.connect(dbConfig).then( pool => {

					return pool.request()
						.input( 'callID', sql.BigInt, callID )
						.input( 'userID', sql.BigInt, userID )
						.input( 'customerID', sql.BigInt, customerID )
						.query( SQL)

				}).then( result => {

					return resolve( true )

				}).catch( err => {

					logger.log({ level: 'error', label: 'customerCalls/saveDefaultCustomerAttendees()', message: 'err' })
					throw new Error( 'error inserting default client attendees in saveDefaultCustomerAttendees()' )

				})

			} catch( err ) {

				return reject( err )

			}

		})

	}
	//====================================================================================


}
