// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	let db = require('../config/db.js');

	let {
		Editor,
		Field,
		Validate,
		Format,
		Options
	} = require("datatables.net-editor-server");


	//====================================================================================
	https.all('/api/customerManagers', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		let editor = new Editor( db, "customerManagers" ).fields(
			new Field( "customerManagers.customerid", "customerID" )
				.setFormatter( Format.ifEmpty( null ) ),
			new Field( "customerManagers.userid", "userID" )
				.setFormatter( Format.ifEmpty( null ) ),
			new Field( "trim( u.username )", "username" ),
			new Field( "u.active", "active" ),
			new Field( "concat(u.firstName, ' ', u.lastName)", "managerName" )
				.set( false )
				.setFormatter( Format.ifEmpty( null ) ),
			new Field( "customerManagers.managertypeid", "managerTypeID" )
				.setFormatter( Format.ifEmpty( null ) ),
			new Field("cmt.name", "managerTypeName" )
				.set( false )
				.setFormatter( Format.ifEmpty( null ) ),
			new Field("customerManagers.startdate", "startDate" )
				.getFormatter( (val, data) => val ? dayjs.utc( val ).format('YYYY-MM-DD') : null )
				.setFormatter( (val, data) => val ? val : null ),
			new Field("customerManagers.enddate", "endDate" )
				.getFormatter( (val, data) => val ? dayjs.utc( val ).format('YYYY-MM-DD') : null )
				.setFormatter( (val, data) => val ? val : null ),
			new Field( "customerManagers.updatedby", "updatedBy" )
				.getFormatter( ( val, data ) => val ? req.session.userID : null ),
			new Field( "customerManagers.updateddatetime", "updatedDateTime" )
				.getFormatter( ( val, data ) => val ? dayjs().format( 'YYYY-MM-DD HH:mm:ss' ) : null )
		);

		editor.leftJoin( "customerManagerTypes as cmt", "cmt.id", "=", "customerManagers.managerTypeid" )
		editor.leftJoin( "users as u", "u.id", "=", "customerManagers.userID" )

		if ( req.query.customerID ) {
			if ( parseInt( req.query.customerID ) != 0 ) {
				editor.where({ "customerManagers.customerid": parseInt( req.query.customerID ) })
			}
		}

		await editor.process( req.body )
		res.json( editor.data() )

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/customerManagers/timeline', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let customerID = req.query.customerID

		const cols = [
	   	{id: 'id', label: 'id', type: 'number'},
	   	{id: 'managerType', label: 'managerType', type: 'string'},
			{id: 'userID', label: 'userID', type: 'number'},
			{id: 'fullName', label: 'fullName', type: 'string'},
			{id: 'startDate', label: 'startDate', type: 'date'},
			{id: 'endDate', label: 'endDate', type: 'date'},
			{type: 'string', role: 'tooltip', 'p': { 'html': true }}
		]

		var rows = []

		sql.connect(dbConfig).then( pool => {

			let SQL	= 	"select "
						+		"m.id, "
						+		"t.name as managerType, "
						+		"m.userID, "
						+		"u.username, "
						+		"u.active, "
						+		"concat(u.firstName, ' ', lastName) as fullName, "
						+		"format( m.startDate, 'yyyy-MM-dd' ) as startDate, "
						+		"format( case when m.endDate is null then  cast(current_timestamp as date) else m.endDate end, 'yyyy-MM-dd') as endDate, "
						+		"m.endDate as actualEndDate "
						+	"from customerManagers m "
						+	"left join customerManagerTypes t on (t.id = m.managerTypeID) "
						+	"left join cSuite..users u on (u.id = m.userID) "
						+	"where m.customerID = @customerID "
						+	"order by t.id, m.startDate "

			logger.log({ level: 'debug', label: 'customerManagers/timeline', message: SQL, user: req.session.userID })

			return pool.request()
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL )

		})
		.then( result => {

			result.recordset.forEach( item => {

				let userStatus = item.active ? 'Active' : 'Inactive'

				let tooltip = 	'<table>'
								+		'<tr>'
								+			'<th align="right">Manager Type:</th><td>' + item.managerType + '</td>'
								+		'</tr>'
								+		'<tr>'
								+			'<th align="right">Manager Full Name:</th><td>' + item.fullName + '</td>'
								+		'</tr>'
								+		'<tr>'
								+			'<th align="right">Manager User Name:</th><td>' + item.username + '</td>'
								+		'</tr>'
								+		'<tr>'
								+			'<th align="right">Mgr User Account Status:</th><td>' + userStatus + '</td>'
								+		'</tr>'
								+		'<tr>'
								+			'<th align="right">Start:</th><td>' + dayjs( item.startDate ).format( 'YYYY-MM-DD' ) + '</td>'
								+		'</tr>'
								+		'<tr>'
								+			'<th align="right">End:</th><td>' + dayjs( item.endDate ).format( 'YYYY-MM-DD' ) + '</td>'
								+		'</tr>'
								+	'</table>'

				rows.push(
					{c: [
						{ v: item.id },
						{ v: item.managerType },
						{ v: item.userID },
						{ v: item.fullName },
						{ v: utilities.date2GoogleDate( item.startDate ) },
						{ v: utilities.date2GoogleDate( item.endDate ) },
						{ v: tooltip }

					]}
				)
			})

			res.json({ cols: cols, rows: rows })

		}).catch( err => {
			logger.log({ level: 'error', label: 'customerManagers/timeline', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})




	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerManagers/selectList', utilities.jwtVerify,  (req, res) => {
	//====================================================================================

		let dbName = req.session.dbName

		sql.connect(dbConfig).then( pool => {

			let SQL	= 	"select "
						+		"u.id, "
						+		"u.username, "
						+		"concat(u.firstName, ' ', u.lastName) as fullName, "
						+		"u.active "
						+	"from cSuite..users u "
						+	"join cSuite..clientUsers cu on ( cu.userID = u.id ) "
						+	"join cSuite..clients c on ( c.id = cu.clientID and c.databaseName = @dbName ) "
						// +	"join " + dbName + "..userCustomers uc on ( uc.userID = u.id and uc.customerID = 1 ) "
						+	"order by 3 "

			logger.log({ level: 'debug', label: 'customerManagers/selectList', message: SQL, user: req.session.userID })

			return pool.request()
				.input( 'dbName', sql.VarChar, dbName )
				.query( SQL )

		}).then( results => {
			res.json( results.recordset )
		}).catch( err => {
			logger.log({ level: 'error', label: 'customerManagers/selectList', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})




	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerManagers/managerTypes', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		sql.connect(dbConfig).then( pool => {
			let SQL	= 	"SELECT id, name "
						+	"FROM customerManagerTypes "
						+	"WHERE ( deleted = 0 OR deleted IS NULL ) "
						+	"ORDER BY seq "
			logger.log({ level: 'debug', label: 'customerManagers/managerTypes', message: SQL, user: req.session.userID })
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordset )
		}).catch( err => {
			logger.log({ level: 'error', label: 'customerManagers/managerTypes', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})




	})
	//====================================================================================


}
