// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/taskStatuses', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const SQL =	`
			select id, name
			from taskStatus
			order by name;

			select dbo.userPermitted( @userID, 44 ) as allowMassComplete;
			select dbo.userPermitted( @userID, 45 ) as allowUncomplete;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL );

		}).then( results => {

			let response = {};
			response.data = results.recordsets[0];
			response.allowMassComplete = Boolean( results.recordsets?.[1]?.[0]?.allowMassComplete );
			response.allowUncomplete = Boolean( results.recordsets?.[2]?.[0]?.allowUncomplete );

			res.json( response );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/taskStatuses', message: err, user: req.session.userID });
			return res.status( 500 ).json({ message: 'Unexpected database error' });

		})

	});
	//====================================================================================




}
