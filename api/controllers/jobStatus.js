// ----------------------------------------------------------------------------------------
// Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = async function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const pool = await sql.connect( dbConfig );

	//====================================================================================
	https.get('/api/jobStatus', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL 	= 	`
				select
					id,
					jobName,
					startDateTime,
					endDateTime,
					status,
					message,
					runType,
					version
				from csuite.dbo.jobLogs
				order by startDateTime desc
			`;

			const results = await pool.request().query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.jobStatus', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Error getting jobStatus' );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/jobStatus/mostRecent', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL 	= 	`
				SELECT *
				FROM csuite.dbo.jobLogs j
				WHERE j.startDateTime = (
					SELECT MAX(startDateTime)
					FROM csuite.dbo.jobLogs
					WHERE jobName = j.jobName
				);
			`;

			const results = await pool.request().query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.jobStatus', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Error getting jobStatus' );

		}

	});
	//====================================================================================

}
