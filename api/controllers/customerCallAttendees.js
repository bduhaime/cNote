// ----------------------------------------------------------------------------------------
// Copyright 2017-2021\2, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customerCallAttendees/customerAttendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )

		let SQL 	= 	`select `
					+		`cca.id as attendeeID, `
					+		`cc.id as contactID, `
					+		`cc.email, `
					+		`case when (cc.firstName is null and cc.lastName is null) then cc.name else concat(cc.firstName, ' ', cc.lastName) end as fullName, `
					+		`cca.attendedIndicator `
					+	`from customerCallAttendees cca `
					+	`left join customerContacts cc on (cc.id = cca.attendeeID) `
					+	`where cca.attendeeType = 'contact' `
					+	`and cca.customerCallID = @callID `
					+	`and ( cca.deleted = 0 or cca.deleted is null ) `
					+	`order by 4 `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCallAttendees/customerAttendees', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCallAttendees/clientAttendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL 	= 	`select `
					+		`ca.id as attendeeID, `
					+		`u.id as userID, `
					+		`u.firstName, `
					+		`u.lastName, `
					+		`trim( u.username ) as username, `
					+		`trim( concat( u.firstName, ' ', u.lastName ) ) as fullName, `
					+		`ca.id as invitedID, `
					+		`ca.attendedIndicator, `
					+		`u.customerID `
					+	`from cSuite..users u `
					+	`join customerCallAttendees ca on ( `
					+		`ca.attendeeID = u.id and `
					+		`attendeeType = 'user' and `
					+		`( ca.deleted = 0 or ca.deleted is null ) and `
					+		`customerCallID = @callID `
					+	`) `
					+	`order by u.firstName, u.lastName `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/:callID/callEmails', message: 'failed for callID: ' + callID, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCallAttendees/allPossibleClientAttendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )

		// this query should retreive all internal active users ( internal users are indicated by customerID=1 )
		let SQL 	= 	`select distinct `
					+		`u.id as attendeeID, `
					+		`trim( u.username ) as attendeeEmail, `
					+		`concat( u.firstName, ' ', u.lastName ) as fullName, `
					+		`cca.id as invitedID, `
					+		`cca.attendedIndicator `
					+	`from csuite..users u `
					+	`left join customerCallAttendees cca on ( `
					+		`cca.attendeeID = u.id and `
					+		`cca.attendeeType = 'user' and `
					+		`cca.customerCallID = @callID and `
					+		`( cca.deleted = 0 or cca.deleted is null ) `
					+	`) `
					+	`where u.active = 1 `
					+	`and ( u.deleted = 0 or u.deleted is null ) `
					+	`and u.customerID = 1 `
					// +	`and exists ( `
					// +		`select * `
					// +		`from userCustomers uc `
					// +		`where uc.userID = u.id `
					// +		`and uc.customerID = 1 `
					// +	`) `
					+	`order by 2 `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCallAttendees/allPossibleClientAttendees', message: 'failed for callID: ' + callID, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCallAttendees/allPossibleCustomerAttendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )
		if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )

		let SQL 	= 	`select `
					+		`cc.id as attendeeID, `
					+		`trim( cc.email ) as attendeeEmail, `
					+		`concat( cc.firstName, ' ', cc.lastName ) as fullName, `
					+		`cca.id as invitedID, `
					+		`cca.attendedIndicator `
					+	`from customerContacts cc `
					+	`left join customerCallAttendees cca on ( `
					+		`cca.attendeeID = cc.id and `
					+		`cca.attendeeType = 'contact' and `
					+		`cca.customerCallID = @callID and `
					+		`( cca.deleted = 0 or cca.deleted is null ) `
					+	`) `
					+	`where cc.customerID = @customerID `
					+	`and ( cc.deleted = 0 or cc.deleted is null ) `
					+	`order by 2 `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCallAttendees/allPossibleCustomerAttendees', message: 'failed for callID: ' + callID, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCallAttendees/attendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.attendeeID ) return res.status( 400 ).send( 'Parameter missing for attendeeID' )

		let message, SQL, attendedIndicator

		SQL 	= 	`select id, attendedIndicator `
				+	`from customerCallAttendees `
				+	`where id = @attendeeID `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'attendeeID', sql.BigInt, req.body.attendeeID )
				.query( SQL )

		}).then( result => {

			if ( result.rowsAffected[0] > 0 ) {

				attendedIndicator 	= result.recordset[0].attendedIndicator ? false : true
				message 				= result.recordset[0].attendedIndicator ? "Attendee marked absent" : "Attendee marked present"

				SQL 	=	"update customerCallAttendees set "
						+		"attendedIndicator = @attendedIndicator "
						+	"where id = @id "

			} else {

				logger.log({ level: 'error', label: 'POST:api/customerCallAttendees/attendees', message: 'Attempting to toggle an attendee that does not exist', user: req.session.userID })
				res.sendStatus( 500 )

			}

			sql.connect(dbConfig).then( pool => {

				logger.log({ level: 'debug', label: 'POST:api/customerCallAttendees/attendees', message: SQL, user: req.session.userID })
				logger.log({ level: 'debug', label: 'POST:api/customerCallAttendees/attendees', message: message, user: req.session.userID })

				return pool.request()
					.input( 'id', sql.BigInt, req.body.attendeeID )
					.input( 'attendedIndicator', sql.Bit, attendedIndicator )
					.query( SQL )

			}).then( result => {

				logger.log({ level: 'debug', label: 'POST:api/customerCallAttendees/attendees', message: 'attendee POSTed successfully', user: req.session.userID })
				return res.status( 200 ).send( message )

			}).catch( err => {

				logger.log({ level: 'error', label: 'POST:api/customerCallAttendees/attendees', message: err, user: req.session.userID })
				res.sendStatus( 500 )
			})

		}).catch( err => {

			logger.log({ level: 'debug', label: 'POST:api/customerCallAttendees/attendees', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/customerCallAttendees/attendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.attendeeID ) return res.status( 400 ).send( 'Parameter missing for attendeeID' )

		let message, SQL, attendedIndicator

		SQL 	= 	`delete customerCallAttendees `
				+	`where id = @attendeeID `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'attendeeID', sql.BigInt, req.body.attendeeID )
				.query( SQL )

		}).then( result => {

			logger.log({ level: 'debug', label: 'DELETE:api/customerCallAttendees/attendees', message: 'attendee DELETEDed successfully', user: req.session.userID })
			return res.status( 200 ).send( 'Attendee deleted' )

		}).catch( err => {

			logger.log({ level: 'debug', label: 'DELETE:api/customerCallAttendees/attendees', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCallAttendees/attendeePresent', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.callAttendeeID ) return res.status( 400 ).send( 'callAttendeeID parameter missing' )

		const attendedIndicator = ( req.body.attendedIndicator === '1' ) ? true : false

		let SQL 	=	`update customerCallAttendees set `
					+		`attendedIndicator = @attendedIndicator, `
					+		`updatedBy = @userID, `
					+		`updatedDateTime = CURRENT_TIMESTAMP `
					+	'where id = @callAttendeeID '

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'attendedIndicator', sql.Bit, req.body.attendedIndicator )
				.input( 'callAttendeeID', sql.BigInt, req.body.callAttendeeID )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			res.status( 200 ).send( 'Attendee updated' )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCallAttendees/attendeePresent', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customerCallAttendees/saveCallAttendees', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		try {

			if ( !req.body.callID ) return res.status( 400 ).send( 'callID parameter missing' )
			if ( !req.body.attendees ) return res.status( 400 ).send( 'attendees parameter missing' )
			if ( !req.body.attendeeType ) return res.status( 400 ).send( 'attendeeType parameter missing' )

			let attendees = req.body.attendees

			for ( attendee of attendees ) {
				saveCustomerCallAttendee( req.body.callID, attendee, req.body.attendeeType, req.session.userID )
			}

			res.sendStatus( 200 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'customerCallAttendees/saveCallAttendees', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )
		}

	})
	//====================================================================================


	//====================================================================================
	function saveCustomerCallAttendee( callID, attendeeID, attendeeType, userID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			if ( !callID ) return reject( 'callID parameter missing' )
			if ( !attendeeID ) return reject( 'attendeeID parameter missing' )
			if ( !attendeeType ) return reject( 'attendeeType parameter missing' )
			if ( !userID ) return reject( 'userID parameter missing' )

			let SQL 	=	`insert into customerCallAttendees ( `
						+		`customerCallID, `
						+		`attendeeType, `
						+		`attendeeID, `
						+		`updatedBy, `
						+		`updatedDateTime `
						+	`) values ( `
						+		`@callID, `
						+		`@attendeeType, `
						+		`@attendeeID, `
						+		`@userID, `
						+		`CURRENT_TIMESTAMP `
						+	`) `

			sql.connect( dbConfig ).then( pool => {

				return pool.request()
					.input( 'callID', sql.BigInt, callID )
					.input( 'attendeeType', sql.VarChar( 20 ), attendeeType )
					.input( 'attendeeID', sql.BigInt, attendeeID )
					.input( 'userID', sql.BigInt, userID )
					.query( SQL )

			}).then( result => {

				return resolve( true )

			}).catch( err => {

				logger.log({ level: 'error', label: 'customerCallAttendees/saveCallAttendees', message: err, user: userID })
				return reject( 'Unexpected database error' )

			})

	})

	}
	//====================================================================================



}
