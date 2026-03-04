// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.put('/api/systemInfo/offsetDaysAtRisk', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( req.body.value === undefined ) return res.status( 400 ).send( 'value parameter missing' );

		if ( !Number.isInteger( Number( req.body.value ) ) )
			return res.status( 400 ).send( 'value must be an integer' );

		let SQL	=	"update systemControls set "
					+		"[value] = @value "
					+	"where [name] = 'Work days at risk offset' ";

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'value', sql.Int, Number( req.body.value ) )
				.query( SQL );

		}).then( result => {

			utilities.invalidateDaysAtRiskOffsetCache();
			return res.status( 200 ).json({ success: true });

		}).catch( err => {
			console.error( err );
			logger.log({ level: 'error', label: 'PUT:api/tasks/taskOwner', message: err, user: req.session.userID });
			res.sendStatus( 500 ).json({ success: false });

		});

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/systemInfo/nodeInfo', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const info = {
			nodeVersion: process.version,
			nodeVersions: process.versions,
			execPath: process.execPath,
			platform: process.platform,
			arch: process.arch,
			cwd: process.cwd(),
			pid: process.pid,
		};

		res.status( 200 ).json( info );

	});
	//====================================================================================


}
