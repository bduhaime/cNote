// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;


	//====================================================================================
	https.get('/api/opportunities/:id', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.id ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	= 	"select "
					+		"narrative, "
					+		"format( startDate, 'MM/dd/yyyy' ) as startDate, "
					+		"format( endDate, 'MM/dd/yyyy' ) as endDate, "
					+		"startValue, "
					+		"endValue, "
					+		"annualEconomicValue "
					+	"from customerOpportunities "
					+	"where id = @opportunityID "

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'opportunityID', sql.BigInt, req.params.id )
				.query( SQL )
		}).then( results => {
			res.json( results.recordset[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/opportunities/:id', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/opportunities', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.implementationID ) return res.status( 400 ).send( 'Parameter missing' )

		const title = req.body.title ? req.body.title.substr( 0, 50 ) : ''

		const startDate	= dayjs( req.body.startDate ).isValid() ? dayjs( req.body.startDate ).format( 'MM/DD/YYYY') : null
		const endDate 		= dayjs( req.body.endDate).isValid() ? dayjs( req.body.endDate ).format( 'MM/DD/YYYY' ) : null

		let SQL, id
		if ( req.body.opportunityID ) {

			id = req.body.opportunityID
			SQL	=	"update customerOpportunities set "
					+		"implementationID = @implementationID, "
					+		"title = @title, "
					+		"narrative = @narrative, "
					+		"startDate = @startDate, "
					+		"endDate = @endDate, "
					+		"annualEconomicValue = @annualEconomicValue, "
					+		"updatedBy = @updatedBy, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @opportunityID "

		} else {

			id = await utilities.GetNextID( 'customerOpportunities' )
			SQL	=	"insert into  customerOpportunities ( "
					+		"id, "
					+		"implementationID, "
					+		"title, "
					+		"narrative, "
					+		"startDate, "
					+		"endDate, "
					+		"annualEconomicValue, "
					+		"updatedBy, "
					+		"updatedDateTime "
					+	") values ( "
					+		"@opportunityID, "
					+		"@implementationID, "
					+		"@title, "
					+		"@narrative, "
					+		"@startDate, "
					+		"@endDate, "
					+		"@annualEconomicValue, "
					+		"@updatedBy, "
					+		"CURRENT_TIMESTAMP "
					+	") "

		}

		try {

			const pool = await sql.connect( dbConfig )

			await pool.request()
				.input( 'opportunityID', 			sql.BigInt, 	id )
				.input( 'implementationID', 		sql.BigInt, 	req.body.implementationID )
				.input( 'title', 						sql.VarChar, 	title )
				.input( 'narrative', 				sql.VarChar, 	req.body.narrative )
				.input( 'startDate', 				sql.Date, 		startDate )
				.input( 'endDate', 					sql.Date, 		endDate )
				.input( 'annualEconomicValue', 	sql.Money, 		req.body.annualEconomicValue )
				.input( 'updatedBy', 				sql.BigInt, 	req.session.userID )
				.query( SQL )

			await res.sendStatus( 200 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'PUT:api/opportunities', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/opportunities', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const opportunityID = req.body.id

		sql.connect( dbConfig ).then( pool => {
			return pool.request()
				.input( 'opportunityID', sql.BigInt, opportunityID )
				.query( "delete from customerObjectives where opportunityID = @opportunityID " )
		}).then( () => {

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'id', sql.BigInt, opportunityID	 )
					.query( "delete from customerOpportunities where id = @id " )
			}).then( results => {
				return res.sendStatus( 200 )
			}).catch( err => {
				logger.log({ level: 'error', label: 'DELETE:api/opportunities', message: err, user: req.session.username })
				return res.status( 500 ).send( 'Unexpected database error' )
			})

		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE:api/opportunities', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


}
