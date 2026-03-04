// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.delete('/api/objectives', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.id ) return res.status( 400 ).send( 'Parameter missing' )

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'id', sql.BigInt, req.body.id )
				.query( "delete from customerObjectives where id = @id " )
		}).then( results => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE:api/metrics', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/objectives', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.implementationID ) return res.status( 400 ).send( 'Parameter missing' )

		addCustomMetric( req )
		.then( addCustomerObjective )
		.then( results => {
			logger.log({ level: 'debug', label: 'PUT:api/metrics', message: 'customerObjective successfully updated', user: req.session.userID })
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/metrics', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/objective/:id', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		utilities.getObjectiveDetails( req.params.id )
		.then( results => {
			res.json( results )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/objective/:id', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	function addCustomMetric( req ) {
	//====================================================================================

		return new Promise( async (resolve, reject) => {

			if ( req.body.metricID && req.body.metricID != '0' ) return resolve( req ) 					// a custom metric already exists
			if ( req.body.metricTypeID != '2' ) return resolve( req )	// request is not for a custom metric
			if ( !req.body.customName ) return reject( 'No name for custom metric present in request' )	// name for custom metric is required

			id = await utilities.GetNextID( 'metric' )

			let SQL	=	"insert into metric ( "
						+		"id, "
						+		"name, "
						+		"updatedDateTime, "
						+		"updatedBy, "
						+		"active, "
						+		"type, "
						+		"internalMetricInd, "
						+		"customerID, "
						+		"metricTypeID "
						+	") values ("
						+		"@id, "
						+		"@name, "
						+		"CURRENT_TIMESTAMP, "
						+		"@updatedBy, "
						+		"@active, "
						+		"@type, "
						+		"@internalMetricInd, "
						+		"@customerID, "
						+		"@metricTypeID "
						+	") "

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'id', 						sql.BigInt, 	id )
					.input( 'name', 					sql.VarChar, 	req.body.customName )
					.input( 'updatedBy', 			sql.BigInt, 	req.session.userID )
					.input( 'active', 				sql.Bit, 		1 )
					.input( 'type', 					sql.VarChar, 	'B' )
					.input( 'internalMetricInd', 	sql.Bit, 		1 )
					.input( 'customerID', 			sql.BigInt, 	req.body.customerID )
					.input( 'metricTypeID', 		sql.BigInt, 	req.body.metricTypeID )
					.query( SQL )
			}).then( results => {
				logger.log({ level: 'debug', label: 'PUT:api/metrics', message: 'custom metric added', user: req.session.userID })
				req.body.metricID = id
				resolve( req )
			}).catch( err => {
				logger.log({ level: 'error', label: 'PUT:api/metrics', message: 'error while inserting custom metric', user: req.session.userID })
				reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function addCustomerObjective( req ) {
	//====================================================================================

		return new Promise( async (resolve, reject) => {

			let startDate = dayjs( req.body.objectiveStartDate ).isValid() ? req.body.objectiveStartDate : null
			console.log({ 'req.body.objectiveStartDate': req.body.objectiveStartDate, startDate: startDate })

			let endDate = dayjs( req.body.objectiveEndDate ).isValid() ? req.body.objectiveEndDate : null
			console.log({ 'req.body.objectiveEndDate': req.body.objectiveEndDate, endDate: endDate })

			if ( req.body.objectiveID ) {

				var SQL
				id = req.body.objectiveID

				SQL 	= 	"update customerObjectives set "
						+		"implementationID = @implementationID, "
						+		"narrative = @narrative, "
						+		"startDate = @startDate, "
						+		"endDate = @endDate, "
						+		"annualEconomicValue = @annualEconomicValue, "
						+		"objectiveTypeID = @objectiveTypeID, "
						+		"updatedBy = @updatedBy, "
						+		"updatedDateTime = CURRENT_TIMESTAMP, "
						+		"metricID = @metricID, "
						+		"showAnnualChangeInd = @showAnnualChangeInd, "
						+		"peerGroupTypeID = @peerGroupTypeID, "
						+ 		"startValue = @startValue, "
						+		"endValue = @endValue, "
						+ 		"opportunityID = @opportunityID, "
						+		"startQuarterEndDate = @startQuarterEndDate, "
						+		"endQuarterEndDate = @endQuarterEndDate, "
						+		"customName = @customName "
						+	"where id = @id "

			} else {

				id = await utilities.GetNextID( 'customerObjectives' )

				SQL 	= 	"insert into customerObjectives ( "
						+		"id, "
						+		"implementationID, "
						+		"narrative, "
						+		"startDate, "
						+		"endDate, "
						+		"annualEconomicValue, "
						+		"objectiveTypeID, "
						+		"updatedBy, "
						+		"updatedDateTime, "
						+		"metricID, "
						+		"showAnnualChangeInd, "
						+		"peerGroupTypeID, "
						+		"startValue, "
						+		"endValue, "
						+		"opportunityID, "
						+		"startQuarterEndDate, "
						+		"endQuarterEndDate, "
						+		"customName "
						+	") values ( "
						+		"@id, "
						+		"@implementationID, "
						+		"@narrative, "
						+		"@startDate, "
						+		"@endDate, "
						+		"@annualEconomicValue, "
						+		"@objectiveTypeID, "
						+		"@updatedBy, "
						+		"CURRENT_TIMESTAMP, "
						+		"@metricID, "
						+		"@showAnnualChangeInd, "
						+		"@peerGroupTypeID, "
						+		"@startValue, "
						+		"@endValue, "
						+		"@opportunityID, "
						+		"@startQuarterEndDate, "
						+		"@endQuarterEndDate, "
						+		"@customName "
						+	") "

			}

			logger.log({ level: 'debug', label: 'objectives/addCustomerObjective()', message: SQL, user: req.session.userID })

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'id', 							sql.BigInt, 	id )
					.input( 'implementationID', 		sql.BigInt, 	req.body.implementationID )
					.input( 'narrative', 				sql.VarChar, 	req.body.narrative )
					.input( 'startDate', 				sql.Date, 		startDate )
					.input( 'endDate', 					sql.Date, 		endDate )
					.input( 'annualEconomicValue', 	sql.Money, 		req.body.annualEconomicValue )
					.input( 'objectiveTypeID', 		sql.BigInt, 	req.body.objectiveTypeID )
					.input( 'updatedBy', 				sql.BigInt, 	req.session.userID )
					.input( 'metricID', 					sql.BigInt, 	req.body.metricID )
					.input( 'showAnnualChangeInd', 	sql.Bit, 		req.body.showAnnualChangeInd )
					.input( 'peerGroupTypeID', 		sql.BigInt, 	req.body.peerGroupTypeID )
					.input( 'startValue', 				sql.Float, 		req.body.objectiveStartValue ? req.body.objectiveStartValue : null )
					.input( 'endValue', 					sql.Float, 		req.body.objectiveEndValue ? req.body.objectiveEndValue : null )
					.input( 'opportunityID', 			sql.BigInt, 	req.body.opportunityID )
					.input( 'startQuarterEndDate', 	sql.Date,		dayjs( req.body.startQuarterEndDate ).isValid() ? req.body.startQuarterEndDate : null )
					.input( 'endQuarterEndDate', 		sql.Date, 		dayjs( req.body.endQuarterEndDate ).isValid() ? req.body.endQuarterEndDate : null )
					.input( 'customName', 				sql.VarChar, 	req.body.customName )
					.query( SQL )
			}).then( results => {
				logger.log({ level: 'debug', label: 'PUT:api/metrics', message: 'customerObjective successfully updated', user: req.session.userID })
				resolve( true )
			}).catch( err => {
				logger.log({ level: 'error', label: 'PUT:api/metrics', message: err, user: req.session.userID })
				reject( err )
			})

		})

	}
	//====================================================================================


}
