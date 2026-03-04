// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

// dbConfig = require('../config/database.json').mssql;
	let db = require('../config/db.js');

	//====================================================================================
	https.get('/api/userClients', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		try {

			if ( !req.query.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
			let finalResults = []
			let clients = await getClients( req.query.userID )
			for ( client of clients ) {
				let clientDetails = await getClientDetails( req.query.userID, client )
				let isChecked, isDefault, isInternal, isExternal
				if ( clientDetails ) {
					isChecked = ( clientDetails.userID ) ? true : false,
					isDefault = ( clientDetails.userDefault == 1 ) ? true : false,
					isInternal = ( clientDetails.internalCount > 0 ) ? true : false,
					isExternal = ( clientDetails.externalCount > 0 ) ? true : false
				} else {
					isChecked = null,
					isDefault = null,
					isInternal = null,
					isExternal = null
				}

				finalResults.push({
					clientID: client.id,
					clientName: client.name,
					isDefault: isDefault,
					isInternal: isInternal,
					isExternal: isExternal,
					isChecked: isChecked
				})

			}

			res.json( finalResults )

		} catch( err ) {

			console.error( err )
			logger.log({ level: 'error', label: 'GET:api/userClients -> getClients()', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		}

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/userClients', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.clientID ) return res.status( 400 ).send( 'clientID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'clientID', sql.BigInt, req.body.clientID )
				.input( 'userID', sql.BigInt, req.body.userID )
				.query( 'insert into csuite..clientUsers ( clientID, userID ) values ( @clientID, @userID ) ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/userClients', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/userClients/setUserDefault', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		try {

			if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
			if ( !req.body.clientID ) return res.status( 400 ).send( 'clientID Parameter missing' )

			const dbConnect = await sql.connect( dbConfig )
			const request = await new sql.Request( dbConnect )

			await request.query( `update csuite..clientUsers set userDefault = null` )

			await request
						.input( 'clientID', sql.BigInt, req.body.clientID )
						.input( 'userID', sql.BigInt, req.body.userID )
						.query( `update csuite..clientUsers set userDefault = 1 where userID = @userID and clientID = @clientID` )

			res.sendStatus( 200 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'PUT:api/userClients/setUserDefault', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		}



	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/userClients', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.clientID ) return res.status( 400 ).send( 'clientID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'clientID', sql.BigInt, req.body.clientID )
				.query( 'delete from csuite..clientUsers where userID = @userID and clientID = @clientID ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'DELETE:api/userClients', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	async function getClients ( userID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	= `select `
						+		`c.id, `
						+		`c.name, `
						+		`c.startDate, `
						+		`c.endDate, `
						+		`c.databaseName `
						+	`from csuite..clients c `
						+	`where (deleted = 0 or deleted is null) `
						+	`and (startDate <= current_timestamp or startDate is null) `
						+	`and (endDate >= current_timestamp or endDate is null) `
						+	`order by name `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'userID', sql.BigInt, userID )
					.query( SQL )

			}).then( results => {
				resolve( results.recordset )
			}).catch( err => {
				reject( err )
			})

		})


	}
	//====================================================================================


	//====================================================================================
	async function getClientDetails( userID, client ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL
			if ( client.databaseName.toLowerCase() != 'csuite' ) {
				SQL 	= 	`select `
						+		`cu.userID, `
						+		`cu.userDefault, `
						+		`sum(case when uc.customerID  = 1 then 1 else 0 end) as internalCount, `
						+		`sum(case when uc.customerID <> 1 then 1 else 0 end) as externalCount, `
						+		`sum(0) as csuiteAdminCount `
						+	`from csuite..clientUsers cu `
						+	`left join ${client.databaseName}..userCustomers uc on (uc.userID = cu.userID) `
						+	`where cu.clientID =  @clientID  `
						+	`and cu.userID =  @userID  `
						+	`group by cu.userID, cu.userDefault  `
			} else {
				SQL	= 	`select `
						+		`cu.userID, `
						+		`cu.userDefault, `
						+		`sum(0) as internalCount, `
						+		`sum(0) as externalCount, `
						+		`count(*) as csuiteAdminCount `
						+	`from csuite..clientUsers cu `
						+	`where cu.clientID = @clientID `
						+	`and cu.userID = @userID `
						+	`group by cu.userID, cu.userDefault `
			}

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'clientID', sql.BigInt, client.id )
					.input( 'userID', sql.BigInt, userID )
					.query( SQL )

			}).then( results => {
				resolve( results.recordset[0] )
			}).catch( err => {
				reject( err )
			})

		})

	}
	//====================================================================================

}
