// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customerStatuses', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	=	`select
							 id,
							 name,
							 description,
							 active,
							 [default],
							 interimFdicLoad,
							 selectByDefault
						 from customerStatus
						 order by name `

		logger.log({ level: 'debug', label: 'customerStatuses', message: SQL, user: req.session.userID })

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordsets[0] )
		}).catch( err => {
			console.error( 'Error getting customerStatuses', err )
			return res.sendStatus( 500 )
		})

	})
	//====================================================================================


}
