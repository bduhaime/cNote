// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customerCallNoteTypes/', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callTypeID ) return res.status( 400 ).send( 'callTypeID parameter missing' )

		let SQL	= 	`select `
					+		`sum( case when utopiaInd = 1 then 1 else 0 end ) as utopiaInd, `
					+		`sum( case when projectInd = 1 then 1 else 0 end ) as projectInd, `
					+		`sum( case when keyInitiativeInd = 1 then 1 else 0 end ) as keyInitiativeInd `
					+	`from noteTypes `
					+	`where callTypeID = @callTypeID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'callTypeID', sql.BigInt, req.query.callTypeID )
				.query( SQL )

		}).then( result => {

			res.json({
				utopiaInd: result.recordset[0].utopiaInd > 0 ? true : false,
				projectInd: result.recordset[0].projectInd > 0 ? true : false,
				keyInitiativeInd: result.recordset[0].keyInitiativeInd > 0 ? true : false
			})

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/customerCallNoteTypes', message: 'Unexpected database error' })
			reject( 'Unexpected database error' )

		})

	})
	//====================================================================================


}
