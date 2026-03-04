// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

// dbConfig = require('../config/database.json').mssql;
	let db = require('../config/db.js');

	//====================================================================================
	https.get('/api/userPermissions', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.query.userID ) return res.status( 400 ).send( 'userID Parameter missing' )

		let SQL 	= `select `
					+		`p.id as permissionID, `
					+		`p.name, `
					+		`p.description, `
					+		`case when up.userID is not null then 1 else 0 end as direct, `
					+		`case when r.userID is not null then 1 else 0 end as indirect `
					+	`from csuite..permissions p `
					+	`left join userPermissions up on (up.permissionID = p.id and up.userID =  @userID ) `
					+	`left join ( `
					+		`select distinct rp.permissionID, ur.userID `
					+		`from rolePermissions rp `
					+		`join userRoles ur on (ur.roleID = rp.roleID) `
					+	`) as r on (r.permissionID = p.id and r.userID =  @userID ) `
					+	`where (p.deleted = 0 or p.deleted is null) `


		if ( req.session.dbName === 'cSuite' ) {
			SQL += `and (p.nonCsuiteOnly = 0 OR p.nonCsuiteOnly is null) `
		} else {
			SQL += `and (p.csuiteOnly = 0 OR p.csuiteOnly is null) `
		}

		SQL += `order by p.name `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.query.userID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'GET:api/userPermissions', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/userPermissions/inheritedFromRole', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.query.permissionID ) return res.status( 400 ).send( 'PermissionID parameter missing' )
		if ( !req.query.userID ) return res.status( 400 ).send( 'UserID parameter missing' )

		let SQL 	= 	`select ur.roleID `
					+	`from rolePermissions rp `
					+	`join roles r on (r.id = rp.roleID) `
					+	`join userRoles ur on (ur.roleID = r.id) `
					+	`where rp.permissionID = @permissionID `
					+	`and ur.userID = @userID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.query.userID )
				.input( 'permissionID', sql.BigInt, req.query.permissionID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'GET:api/userPermissions', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/userPermissions', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.permissionID ) return res.status( 400 ).send( 'permissionID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'permissionID', sql.BigInt, req.body.permissionID )
				.query( 'insert into userPermissions (userID, permissionID) values ( @userID, @permissionID ) ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/userPermissions', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/userPermissions', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.permissionID ) return res.status( 400 ).send( 'permissionID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'permissionID', sql.BigInt, req.body.permissionID )
				.query( 'delete from  userPermissions where userID = @userID and permissionID = @permissionID ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE:api/userPermissions', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/userPermissions/userPermitted', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		try {

			if ( !req.session.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
			if ( !req.query.permissionID ) return res.status( 400 ).send( 'permissionID Parameter missing' )

			const userPermitted = await utilities.UserPermitted( req.session.userID, req.query.permissionID )
			res.json( userPermitted )

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/userPermissions/userPermitted', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		}

	})
	//====================================================================================


}
