// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

// dbConfig = require('../config/database.json').mssql;
	let db = require('../config/db.js');

	//====================================================================================
	https.get('/api/userRoles', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.query.userID ) return res.status( 400 ).send( 'userID Parameter missing' )

		let SQL 	= `select id as roleID, name as roleName, userID `
					+	`from roles r `
					+	`left join userRoles ur on  (ur.roleID = r.id and ur.userID = @userID ) `
					+	`order by name `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.query.userID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'GET:api/userRoles', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/userRoles', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.roleID ) return res.status( 400 ).send( 'roleID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'roleID', sql.BigInt, req.body.roleID )
				.query( 'insert into userRoles (userID, roleID) values ( @userID, @roleID ) ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/userRoles', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/userRoles', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.roleID ) return res.status( 400 ).send( 'roleID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'roleID', sql.BigInt, req.body.roleID )
				.query( 'delete from  userRoles where userID = @userID and roleID = @roleID ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE:api/userRoles', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


}
