// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.put('/api/customerPriorities', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.customerID ) return res.status( 400 ).send( 'Parameter missing' )

		if ( req.body.customerGradeID ) {
			if ( req.body.customerGradeID < 0 || req.body.customerGradeID > 10 ) return res.status( 400 ).send( 'Parameter missing' )
		}

		let customerGradeNarrative = req.body.customerGradeNarrative

		const SQL	=	"update customer set "
						+		"customerGradeID = @customerGradeID, "
						+		"customerGradeNarrative = @customerGradeNarrative, "
						+		"anomoliesNarrative = @anomoliesNarrative "
						+	"where id = @customerID "

// 		console.log( 'customerID: ' + req.body.customerID )
// 		console.log( 'customerGradeID: ' + req.body.customerGradeID )
// 		console.log( 'customerGradeNarrative: ' + customerGradeNarrative )
// 		console.log( 'anomoliesNarrative: ' + req.body.anomoliesNarrative )

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.input( 'customerGradeID', sql.BigInt, req.body.customerGradeID )
				.input( 'customerGradeNarrative', sql.VarChar, customerGradeNarrative )
				.input( 'anomoliesNarrative', sql.VarChar, req.body.anomoliesNarrative )
				.query( SQL )
		}).then( results => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'customerPriorities', message: err, user: req.session.userID })
			return res.send( 500 ).status( 'Unexpected database error' )
		})

	})
	//====================================================================================


}
