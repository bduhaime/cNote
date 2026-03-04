// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get( '/api/tgimu/utilization/signinsByDate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'customer Parameter missing' )

			const cols = [
				{id: "Date", label: "Date", type: "date"},
				{id: "Utilization", label: "Utilization", type: "number"},
				{id: "Objective", label: "Objective", type: "number"}
			]
			var rows = []

			// const metricObjectives = utilities.getMetricObjectives( req.query.objectiveID )
			let useMapping = await utilities.SystemControls( 'Use LSVT manual location/customer mapping' )
			let locationSubquery = await getLocationSubquery( useMapping )
			let activeUserCount = await getActiveUsersCount( locationSubquery, req.query.customerID )

			if ( activeUserCount > 0 ) {

				let signins = await getSignins( locationSubquery, req.query.customerID )

				for ( item of signins ) {

					strYear 	= item.signinDateYear
					strMonth = item.signinDateMonth - 1
					strDate	= 'Date(' + strYear + ',' + strMonth + ',1)'

					monthName = dayjs().year(strYear).month(strMonth).format('MMM YYYY')
					utilization	= Math.round(item.signinCount / activeUserCount * 100 * 10) / 10
					formatted = parseFloat(utilization).toFixed(1)+'% ('+item.signinCount+' of '+activeUserCount+')'

					if ( utilization > 100.0 ) utilization = 100.0
					rows.push(
						{c: [
							{ v: strDate, f: monthName },
							{ v: utilization, f: formatted },
							{ v: null }
						]}
					)
				}

			}

			res.json({ cols: cols, rows: rows })

		} catch( err ) {
			logger.log({ level: 'error', label: 'GET:api/tgimu/utilization/signinsByDate', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tgimu/utilization/attemptedTrainingsByDate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'customer Parameter missing' )

			const cols = [
				{id: "Date", label: "Date", type: "date"},
				{id: "Utilization", label: "Utilization", type: "number"},
				{id: "Objective", label: "Objective", type: "number"}
			]
			var rows = []

			// const metricObjectives = utilities.getMetricObjectives( req.query.objectiveID )
			let useMapping = await utilities.SystemControls( 'Use LSVT manual location/customer mapping' )
			let locationSubquery = await getLocationSubquery( useMapping )
			let activeUserCount = await getActiveUsersCount( locationSubquery, req.query.customerID )

			if ( activeUserCount > 0 ) {

				let attemptedTrainings = await getAttemptedTrainings( locationSubquery, req.query.customerID )

				for ( item of attemptedTrainings ) {

					strYear 	= item.attemptDateYear
					strMonth = item.attemptDateMonth - 1
					strDate	= 'Date(' + strYear + ',' + strMonth + ',1)'
					monthName = dayjs().year(strYear).month(strMonth).format('MMM YYYY')
					utilization	= Math.round(item.trainingCount / activeUserCount * 100 * 10) / 10
					formatted = parseFloat(utilization).toFixed(1)+'% ('+item.trainingCount+' of '+activeUserCount+')'

					if ( utilization > 100.0 ) utilization = 100.0

					rows.push(
						{c: [
							{ v: strDate, f: monthName },
							{ v: utilization, f: formatted },
							{ v: null }
						]}
					)

				}

			}

			res.json({ cols: cols, rows: rows })

		} catch( err ) {
			logger.log({ level: 'error', label: 'GET:api/tgimu/utilization/attemptedTrainingsByDate', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tgimu/utilization/chapterStatusByDate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const cols = [
				{id: "Date", label: "Date", type: "date"},
				{id: "Passed", label: "Passed", type: "number"},
				{id: "Failed", label: "Failed", type: "number"},
				{id: "In Process", label: "In Process", type: "number"}
			]
			var rows = []

			let useMapping = await utilities.SystemControls( 'Use LSVT manual location/customer mapping' )
			let locationSubquery = await getLocationSubquery( useMapping )
			let activeUserCount = await getActiveUsersCount( locationSubquery, req.query.customerID )

			if ( activeUserCount > 0 ) {

				let chapterStatuses = await getChapterStatuses( locationSubquery, req.query.customerID )


				for ( item of chapterStatuses ) {

					strYear 	= item.attemptDateYear
					strMonth = item.attemptDateMonth - 1
					strDate	= 'Date(' + strYear + ',' + strMonth + ',1)'
					monthName = dayjs().year(strYear).month(strMonth).format('MMM YYYY')

					rows.push(
						{c: [
							{ v: strDate, f: monthName },
							{ v: item.pass },
							{ v: item.fail },
							{ v: item.viewed },
						]}
					)

				}

			}

			res.json({ cols: cols, rows: rows })

		} catch( err ) {
			logger.log({ level: 'error', label: 'GET:api/tgimu/utilization/chapterStatusByDate', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tgimu/unmappedLsvtLocations', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.isActive ) return res.status( 400 ).send( 'isActive Parameter missing' )
		if ( !req.query.resultsAs ) return res.status( 400 ).send( 'resultsAs parameter missing' )

		const isActive = ( req.query.isActive === 'true' ) ? 1 : 0

		let SQL	=	"select "
					+		"l.locationID, "
					+		"l.name as locationName "
					+	"from lightspeed..locations l "
					+	"where l.customerID is null "
					+ 	"and isActive = @isActive "
					+	"order by l.name "


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'isActive', sql.Bit, isActive )
				.query( SQL )

		}).then( result => {

			if ( req.query.resultsAs === 'list' ) {
				res.json( result.recordset )
			} else if ( req.query.resultsAs === 'count' ) {
				res.json( result.rowsAffected[0] )
			} else {
				res.status( 400 ).send( 'invalid resultsAs parameter' )
			}


		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/tgimu/locations', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tgimu/locations', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		sql.connect(dbConfig).then( pool => {

			SQL	=	"select "
					+		"l.locationID, "
					+		"l.name as locationName, "
					+		"l.isActive, "
					+		"l.customerID, "
					+		"c.name as customerName "
					+	"from lightspeed..locations l "
					+	"left join customer c on (c.id = l.customerID) "
					+	"order by l.name "

			return pool.request().query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/tgimu/locations', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tgimu/locations', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.locationID ) return res.status( 400 ).send( 'location Parameter missing' )
		// if ( !req.body.customerID ) return res.status( 400 ).send( 'customer Parameter missing' )


		let customerID = ( req.body.customerID === '' ) ? null : req.body.customerID

		sql.connect(dbConfig).then( pool => {

			SQL	=	"update lightspeed..locations "
					+		"set customerID = @customerID "
					+	"where locationID = @locationID "

			return pool.request()
				.input( 'locationID', sql.BigInt, req.body.locationID )
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/tgimu/locations', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tgimu/customers', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		sql.connect(dbConfig).then( pool => {

			SQL	=	"select id, name "
					+	"from customer "
					+	"where (deleted = 0 or deleted is null) "
					+	"order by name "

			return pool.request().query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/tgimu/locations', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	function getChapterStatuses( locationSubquery, customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select attemptDateYear, attemptDateMonth, [pass], [fail], [viewed] `
						+	`from ( `
						+		`select `
						+			`a.chapterAttemptStatus, `
						+			`year(a.chapterAttemptDate) as attemptDateYear, `
						+			`month(a.chapterAttemptDate) as attemptDateMonth `
						+		`from lightspeed..userChapterAttempts a `
						+		`where a.locationID in ( ${locationSubquery} ) `
						+	`) p `
						+	`PIVOT `
						+	`(count(chapterAttemptStatus) `
						+	`for chapterAttemptStatus in ([pass],[fail],[viewed]) `
						+	`) as pvt `
						+	`order by 1, 2 `

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'customerID', sql.BigInt, parseInt( customerID ) )
					.query( SQL )
			}).then( result => {
				resolve ( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'getAttemptedTrainings()', message: err, user: null })
				reject( 'Error getting attempted trainings' )
			})

		})


	}
	//====================================================================================


	//====================================================================================
	function getAttemptedTrainings( locationSubquery, customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL	=	`select `
						+		`year(a.chapterAttemptDate) as attemptDateYear, `
						+		`month(a.chapterAttemptDate) as attemptDateMonth, `
						+		`count(distinct a.userID) as trainingCount `
						+	`from lightspeed..userChapterAttempts a `
						+	`where a.locationID in ( ${locationSubquery} ) `
						+	`group by `
						+		`year(a.chapterAttemptDate), `
						+		`month(a.chapterAttemptDate) `
						+	`order by 1, 2 `

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'customerID', sql.BigInt, parseInt( customerID ) )
					.query( SQL )
			}).then( result => {
				resolve ( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'getAttemptedTrainings()', message: err, user: null })
				reject( 'Error getting attempted trainings' )
			})

		})


	}
	//====================================================================================


	//====================================================================================
	function getSignins( locationSubquery, customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`year(a.accessDateTime) as signinDateYear, `
						+		`month(a.accessDateTime) as signinDateMonth, `
						+		`count(distinct a.userID) as signinCount `
						+	`from lightspeed..usersAccessInfo a `
						+	`where a.locationID in ( ${locationSubquery} ) `
						+	`group by `
						+		`year(a.accessDateTime), `
						+		`month(a.accessDateTime) `
						+	`order by 1, 2 `

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'customerID', sql.BigInt, parseInt( customerID ) )
					.query( SQL )
			}).then( result => {
				resolve ( result.recordset )
			}).catch( err => {
				logger.log({ level: 'error', label: 'getSignings()', message: err, user: null })
				reject( 'Error getting signins' )
			})

		})


	}
	//====================================================================================


	//====================================================================================
	function getActiveUsersCount( locationSubquery, customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	= 	`select count(*) as userCount `
						+	`from lightspeed..users u `
						+	`where u.locationID in ( ${locationSubquery} ) `
						+	`and isActive = 1 `

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'customerID', sql.BigInt, parseInt( customerID ) )
					.query( SQL )

			}).then( result => {
				resolve( result.recordset[0].userCount )
			}).catch( err => {
				logger.log({ level: 'error', label: 'getActiveUsersCount()', message: err, user: null })
				reject('Error selecting active user count')
			})

		})


	}
	//====================================================================================


	//====================================================================================
	function getLocationSubquery( useMapping ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let subquery
			if ( useMapping === 'true' ) {		// using new mapping

				subquery	= 	`select locationID `
							+	`from lightspeed..locations `
							+	`where customerID = @customerID `
							// +	`and isActive = 1 `

			} else {										// using old location name prefix

				subquery = 	`select locationID `
							+	`from lightspeed..locations `
							+	`where name like (`
							+		`select lsvtCustomerName+'%' `
							+		`from customer `
							+		`where id = @customerID `
							+	`) `
							// +	`and isActive = 1 `

			}

			resolve( subquery )

		})

	}
	//====================================================================================


}
