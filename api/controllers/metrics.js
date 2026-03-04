// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.delete('/api/metrics', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.id ) return res.status( 400 ).send( 'Parameter missing' )

		const id = req.body.id

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'id', sql.BigInt, id )
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
	https.put('/api/metrics', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.implementationID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.body.metricID ) return res.status( 400 ).send( 'Parameter missing' )

		var SQL, id

		if ( req.body.objectiveID ) {

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

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'id', 							sql.BigInt, 	id )
				.input( 'implementationID', 		sql.BigInt, 	req.body.implementationID )
				.input( 'narrative', 				sql.VarChar, 	req.body.narrative )
				.input( 'startDate', 				sql.Date, 		dayjs( req.body.objectiveStartDate ).isValid() ? dayjs( req.body.objectiveStartDate ).startOf('day').toDate() : null )
				.input( 'endDate', 					sql.Date, 		dayjs( req.body.objectiveEndDate ).isValid() ? dayjs( req.body.objectiveEndDate ).startOf('day').toDate() : null )
				.input( 'annualEconomicValue', 	sql.Money, 		req.body.annualEconomicValue )
				.input( 'objectiveTypeID', 		sql.BigInt, 	req.body.objectiveTypeID )
				.input( 'updatedBy', 				sql.BigInt, 	req.session.userID )
				.input( 'metricID', 					sql.BigInt, 	req.body.metricID )
				.input( 'showAnnualChangeInd', 	sql.Bit, 		req.body.showAnnualChangeInd )
				.input( 'peerGroupTypeID', 		sql.BigInt, 	req.body.peerGroupTypeID )
				.input( 'startValue', 				sql.Float, 		req.body.objectiveStartValue ? req.body.objectiveStartValue : null )
				.input( 'endValue', 					sql.Float, 		req.body.objectiveEndValue ? req.body.objectiveEndValue : null )
				.input( 'opportunityID', 			sql.BigInt, 	req.body.opportunityID )
				.input( 'startQuarterEndDate', 	sql.Date,		dayjs( req.body.startQuarterEndDate ).isValid() ? dayjs( req.body.startQuarterEndDate ).startOf('day').toDate() : null )
				.input( 'endQuarterEndDate', 		sql.Date, 		dayjs( req.body.endQuarterEndDate ).isValid() ? dayjs( req.body.endQuarterEndDate ).startOf('day').toDate() : null )
				.input( 'customName', 				sql.VarChar, 	req.body.customName )
				.query( SQL )
		}).then( results => {
			logger.log({ level: 'debug', label: 'PUT:api/metrics', message: 'customerObjective successfully updated', user: req.session.userID })
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/metrics', message: err, user: req.session.userID })
			res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/financialCtgys', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL 	= 	"select distinct financialCtgy "
					+	"from metric "
					+	"where internalMetricInd = 0 "
					+	"and active = 1 "
					+	"and (deleted = 0 or deleted is null) "
					+	"order by financialCtgy "

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordset )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/metrics/financialCtgys', message: err, user: req.session.userID })
			res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/ubprSections', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.financialCtgy ) return res.status( 400 ).send( 'Parameter missing' )

		const	financialCtgy 	= req.query.financialCtgy
		var	predicate 		= ''

		if ( financialCtgy ) {
			if ( financialCtgy != 'All' ) predicate += "and financialCtgy = '" + financialCtgy + "' "
		}

		let SQL 	= 	"select distinct ubprSection "
					+	"from metric "
					+	"where internalMetricInd = 0 "
					+	"and active = 1 "
					+	"and (deleted = 0 or deleted is null) "
					+	predicate
					+	"order by ubprSection "

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordset )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/metrics/ubprSections', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/ubprLines', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.financialCtgy ) return res.status( 400 ).send( 'Parameter missing' )

		const	financialCtgy 	= req.query.financialCtgy
		var	predicate 		= ''

		if ( financialCtgy ) {
			if ( financialCtgy != 'All' ) predicate += "and financialCtgy = '" + financialCtgy + "' "
		}

		let SQL 	= 	"select distinct ubprLine, cast(ubprLine as real) as seq "
					+	"from metric "
					+	"where internalMetricInd = 0 "
					+	"and active = 1 "
					+	"and (deleted = 0 or deleted is null) "
					+	predicate
					+	"order by 2 "

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			output = []
			results.recordset.forEach( item => {
				output.push({ ubprLine: item.ubprLine })
			})
			res.json( output )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/metrics/ubprLines', message: err, user: req.session.userID })
			res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/internalValues', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.metricID ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	= 	"select "
					+		"v.id, "
					+		"format( metricDate, 'MM/dd/yyyy' ) as [Date], "
					+		"format( metricDate, 'yyyyMMdd' ) as sortableDate, 	"
					+		"metricValue as [Value] "
					+	"from customerInternalMetrics v "
					+	"join customer c on (c.rssdID = v.rssdID and c.id = @customerID) "
					+	"and metricID = @metricID "
					+	"order by metricDate desc "

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'metricID', sql.BigInt, req.query.metricID )
				.query( SQL )
		}).then( results => {
			res.json( results.recordsets[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/metrics', message: err, user: req.session.userID })
			res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/metrics/internalValues', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.id ) return res.status( 400 ).send( 'Parameter missing' )

		const id = req.body.id

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'id', sql.BigInt, id )
				.query( "delete from customerInternalMetrics where id = @id " )
		}).then( results => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE:api/metrics/internalValues', message: err, user: req.session.userID })
			res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/metrics/internalValues', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( req.body.metricValueID ) {

			let SQL 	=	"update customerInternalMetrics set "
						+		"metricDate = @metricDate, "
						+		"metricValue = @metricValue "
						+	"where id = @metricValueID"

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'metricDate', sql.Date, dayjs( req.body.metricValueDate ).isValid() ? dayjs( req.body.metricValueDate ).startOf('day').toDate() : null )
					.input( 'metricValue', sql.Money, req.body.metricValueValue )
					.input( 'metricValueID', sql.BigInt, req.body.metricValueID )
					.query( SQL )
			}).then( result => {
				return res.sendStatus( 200 )
			}).catch( err => {
				logger.log({ level: 'error', label: 'PU:api/metrics/internalValues', message: 'error encountered while updating customerMetricValues: '+err, user: req.session.userID })
				return res.status( 500 ).send( 'Unexpected database error' )
			})

		} else {

			sql.connect( dbConfig ).then( pool => {
				SQL = "select rssdID from customer where id = @customerID "
				return pool.request()
					.input( 'customerID', sql.BigInt, req.body.customerID )
					.query( SQL )
			}).then( result => {

				SQL 	= 	"insert into customerInternalMetrics ( "
						+		"rssdID, "
						+		"metricDate, "
						+		"metricValue, "
						+ 		"metricID, "
						+		"updatedBy, "
						+		"updatedDateTime "
						+	") values ( "
						+		"@rssdID, "
						+		"@metricDate, "
						+		"@metricValue, "
						+		"@metricID, "
						+		"@updatedBy, "
						+		"CURRENT_TIMESTAMP "
						+	") "

				return pool.request()
					.input( 'rssdID', sql.BigInt, result.recordset[0].rssdID )
					.input( 'metricDate', sql.Date, dayjs( req.body.metricValueDate ).isValid() ? dayjs( req.body.metricValueDate ).startOf('day').toDate() : null )
					.input( 'metricValue', sql.Money, req.body.metricValueValue )
					.input( 'metricID', sql.BigInt, req.body.metricID )
					.input( 'updatedBy', sql.BigInt, req.session.userID )
					.query( SQL )
			}).then( result => {
				return res.sendStatus( 200 )
			}).catch( err => {
				logger.log({ level: 'error', label: 'PU:api/metrics/internalValues', message: 'error encountered while inserting into customerMetricValues: '+err, user: req.session.userID })
				return res.status( 500 ).send( 'Unexpected database error' )
			})

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		var predicate = ''

		switch ( req.query.metricType ) {

			case '2':				// customer specific

				if ( req.query.customerID ) {
					predicate = "and m.metricTypeID = 2 and m.customerID = " + req.query.customerID + " "
				} else {
					return res.sendStatus( 400 )
				}

				break

			case '3':				// external - FDIC

				predicate = "and m.metricTypeID = 3 "

				if ( req.query.financialCtgy ) {
					if ( req.query.financialCtgy != 'All' ) predicate += "and m.financialCtgy = '" + req.query.financialCtgy + "' "
				}

				if ( req.query.ubprSection ) {
					if( req.query.ubprSection != 'All' ) predicate += "and m.ubprSection = '" + req.query.ubprSection + "' "
				}

				if ( req.query.ubprLine ) {
					if ( req.query.ubprLine != 'All' ) predicate += "and m.ubprLine = '" + req.query.ubprLine + "' "
				}

				break

			default:					// unknown -- return all

				if ( req.query.metricType ) {
					if ( req.query.metricType >= '' ) predicate += "and m.metricTypeID = " + req.query.metricType + " "
				}

		}

		let SQL 	= "select "
					+		"m.id, "
					+		"m.name, "
					+		"m.ubprSection, "
					+		"m.ubprLine, "
					+		"m.financialCtgy, "
					+		"m.ranksColumnName, "
					+		"m.ratiosColumnName, "
					+		"m.statsColumnName, "
					+		"m.sourceTableNameRoot, "
					+		"m.dataType, "
					+		"m.displayUnitsLabel, "
					+		"cac.ratiosColumnName as correspondingAnnualChangeID, "
					+		"mt.name as metricType, "
					+		"m.frequency "
					+	"from metric m "
					+	"left join metricTypes mt on (mt.id = m.metricTypeID) "
					+	"left join metric cac on (cac.id = m.correspondingAnnualChangeID) "
					+	"where (m.deleted = 0 or m.deleted is null) "
					+	predicate
					+	"order by m.name "

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordsets[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/metrics', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metric/:id', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.id ) return res.status( 400 ).send( 'Parameter missing' )

		getMetricDetails( req.params.id )
		.then( results => {
			res.json( results )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:api/metric/:id', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/chartObjective', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.objectiveID ) return res.status( 400 ).send( 'Parameter missing' )

			const objectiveID = req.query.objectiveID;
			const maxEndDate = req.query.maxObjectiveEndDate;
			const objective 	= await utilities.getObjectiveDetails( objectiveID )
			const query 		= await buildMetricQuery( objective )
			const metricData 	= await getMetricData( query )
			const data 			= await finalizeOutput( objective, metricData, maxEndDate )

			res.json( data )

		} catch ( err ) {

			logger.log({ level: 'error', label: 'GET:api/metrics/chartObjective', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/chartCustomerFDICMetric', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing (customerID)' )
			if ( !req.query.metricID ) return res.status( 400 ).send( 'Parameter missing (metricID)' )
			// peerGroupType is an optional parameter

			const customerID 		= req.query.customerID
			const metricID			= req.query.metricID
			const peerGroupType 	= req.query.peerGroupType
			const usesPGT			= req.query.usesPGT === 'true' ? true : false
			const annChg 			= req.query.annChg === 'true' ? true : false


			let customer 				= await getCustomerInfo( customerID )
			let rssdID 					= customer.rssdID

			let metric 					= await getMetricDetails( metricID )
			let sourceTableNameRoot = metric.sourceTableNameRoot
			let ratiosColumnName 	= metric.ratiosColumnName
			let statsColumnName		= metric.statsColumnName
			let ranksColumnName		= metric.ranksColumnName

			let defaultPG 				= await getDefaultPeerGroupType( customerID, peerGroupType )
			let defaultPGT				= defaultPG

			let sqlParams = {
				rssdID: rssdID,
				sourceTableNameRoot: sourceTableNameRoot,
				ratiosColumnName: ratiosColumnName,
				statsColumnName: statsColumnName,
				ranksColumnName: ranksColumnName,
				usesPGT: usesPGT,
				defaultPGT: defaultPGT,
				annChg: annChg
			}

			const ubprTables = [
				'AssetYieldsFundingCosts',
				'BalanceSheetDollar',
				'BalanceSheetPercent',
				'CapitalAnalysisA',
				'IncomeStatementDollar',
				'LiquidityFunding',
				'NonIntIncExpYields',
				'SummaryRatios'
			]

			let sqlAndCols
			if ( ubprTables.includes( sourceTableNameRoot ) ) {
				sqlAndCols = await gengerateUbprSql( sqlParams )
			} else {
				sqlAndCols = await generateCallReportSql( sqlParams )
			}

			let SQL 	= 	sqlAndCols.sqlSelect
						+	sqlAndCols.sqlFrom
						+ 	`where d.quarterEndInd = 1 `
						+	`and r.[Reporting Period] is not null `
						+	`order by 1 `

			let cols = sqlAndCols.cols

			// query the database!!
			const dataconn	= await sql.connect( dbConfig )
			let result = await dataconn.request().query( SQL )

			// process the results!!
			let rows = []

			for ( item of result.recordset ) {

				let cells = [
					{ v: utilities.date2GoogleDate( item["Date"] ) },		// [reporting period]
					{ v: item["Bank"] }												//	[Bank]
				]

				// generate a tooltip when peer group type is included in the request...
				if ( usesPGT ) {
					if ( defaultPGT > '' ) {

						let tooltip 	= 	`<table>`
											+ 		`<tr><th align="left" colspan="2" style="border-bottom: solid black 1px;">${item["PG Description"]}</th></tr>`
											+ 		`<tr><th align="left" width="30%" nowrap>Report Period:</th><td>${dayjs( item["Date"] ).format( 'M/D/YYYY' )}</td></tr>`
											+ 		`<tr><th align="left" nowrap>PG Percentile:</th><td>${item["PG Percentile"]}</td></tr>`
											+ 		`<tr><th align="left" nowrap>Peer Group:</th><td>${item["Peer Group"]}</td></tr>`
											+ 	`</table>`
						cells.push({ v: item["PG"] })
						cells.push({ v: parseInt( item["PG Percentile"] ) })
						cells.push({ v: tooltip })
					}
				} else {
					if ( annChg ) {
						console.info( `need to figure out what to push for annual change` )
					}
				}

				rows.push({ c: cells })

			}

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'metrics/chartCustomerFDICMetric', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'error getting metric data for customer' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/metrics/maxObjectiveEndDate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.implementationID ) return res.status( 400 ).send( 'Parameter missing' )

			let SQL 	=	`select format( max( case when endDate is not null then endDate else getDate() end ), 'yyyy-MM-dd' ) as maxEndDate `
						+	`from customerObjectives `
						+	`where implementationID = @implementationID `

			const results = await pool.request()
				.input( 'implementationID', sql.BigInt, req.query.implementationID )
				.query( SQL )

			if ( results.recordset.length > 0 ) {
				// console.log({ maxEndDate: results.recordset[0].maxEndDate })
				return res.json( results.recordset[0] )
			} else {
				throw new Error( 'implementationID not found' )
			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.metrics/maxObjectiveEndDate', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	function gengerateUbprSql( parms ) {
	//====================================================================================

		let sqlSelect	=	`select `
							+		`format( d.id, 'yyyy-MM-dd' ) as [Date], `
							+	 	`r.[${parms.ratiosColumnName}] as [Bank] `

		let sqlFrom		=	`from dateDimension d `
							+	`left join fdic_ratios.dbo.${parms.sourceTableNameRoot} r on (cast(r.[reporting period] as date) = d.id and r.[id rssd] = ${parms.rssdID}) `

		let cols = [
			{ id: "Date", label: "Date", type: "date" },
			{ id: "Bank", label: "Bank", type: "number" }
		]

		if ( parms.usesPGT ) {

			if ( parms.statsColumnName && parms.ranksColumnName ) {

			// sqlSelect 	+=	`, s.[${parms.statsColumnName}] as [PG] `
			// 				+	`, k.[${parms.ranksColumnName}] as [PG Percentile] `
				sqlSelect 	+=	`, s.[${parms.statsColumnName}] as [PG] `
								+	`, k.[${parms.ranksColumnName}] as [PG Percentile] `
								+	`, pg.id as [Peer Group] `
								+	`, pg.description as [PG Description] `

				cols.push({ id: "PG", label: "PG", type: "number" })
				cols.push({ id: "PG Percentile", label: "PG Percentile", type: "number" })
				cols.push({ role: "tooltip", type: "string", p: { html: true } })

				sqlFrom 	+=	`left join fdic_ranks.dbo.${parms.sourceTableNameRoot} k on (k.[reporting period] = r.[reporting period] and k.[id rssd] = r.[id rssd] and k.[peer group] in (select id from fdic.dbo.peerGroup where peerGroupType = ${parms.defaultPGT}) ) `
							+	`left join fdic_stats.dbo.${parms.sourceTableNameRoot} s on (s.[reporting period]  = k.[reporting period] and s.[peer group] = k.[peer group]) `
							+	`left join fdic.dbo.peerGroup pg on (pg.id = s.[peer group]) `

			}

		} else {

			if ( parms.annChg ) {

				console.info( `need to figure out what SELECT needs for annual change` )
				// SQL += ?
				// cols.push({ id: "apc", label: "Annual % Change", type: "number" })

			}

		}

		return ({
			sqlSelect: sqlSelect,
			sqlFrom: sqlFrom,
			cols: cols
		})

	}
	//====================================================================================


	//====================================================================================
	function generateCallReportSql( parms ) {
	//====================================================================================

		let sqlSelect 	=	`select `
							+		`format( d.id, 'yyyy-MM-dd' ) as [Date], `
							+		`r.[${parms.ratiosColumnName}] as [Bank] `

		let sqlFrom
		if ( [ 'RIBII','RCCI','RCN','RI','RIA' ].includes( parms.sourceTableNameRoot ) ) {
			sqlFrom 	=	`from dateDimension d `
						+	`left join fdic_calls.dbo.${parms.sourceTableNameRoot} r on (cast(r.[reporting period] as date) = d.id and r.[idrssd] = ${parms.rssdID}) `
		} else {
			sqlFrom 	=	`from dateDimension d `
						+	`left join fdic_ratios.dbo.${parms.sourceTableNameRoot} r on (cast(r.[reporting period] as date) = d.id and r.[idrssd] = ${parms.rssdID}) `
		}

		let cols = [
				{ id: "Date", label: "Date", type: "date" },
				{ id: "Bank", label: "Bank", type: "number" }
			]

		return ({
			sqlSelect: sqlSelect,
			sqlFrom: sqlFrom,
			cols: cols
		})

	}
	//====================================================================================


	//====================================================================================
	function getDefaultPeerGroupType( customerID, peerGroupType ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			if ( peerGroupType ) {
				return resolve( peerGroupType )
			}

			let SQL	= 	"select inscoml, inssave, mutual "
						+ 	"from customer c "
						+	"join fdic.dbo.institutions i on ( i.cert = c.cert ) "
						+	"where id = @customerID  "

			sql.connect(dbConfig).then( pool => {
				return pool.request()
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL )
			}).then( result => {

				let data = result.recordset[0]
				let pgt = ''

				if ( data.inscoml == '1' ) {
					pgt = 1
				} else {
					if ( data.inssave == '1' ) {
						pgt = 2
					} else {
						pgt = ''
					}
				}

				return resolve( pgt )

			}).catch( err => {
				logger.log({ level: 'error', label: 'getDefaultPeerGroupType()', message: err, user: null })
				return reject( 'error in getDefaultPeerGroupType' )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function getCustomerInfo( customerID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL	= 	"select rssdID "
						+	"from customer "
						+	"where id = @customerID "

			sql.connect(dbConfig).then( pool => {
				return pool.request()
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL )
			}).then( result => {
				return resolve( result.recordset[0] )
			}).catch( err => {
				logger.log({ level: 'error', label: 'getCustomerInfo()', message: err, user: null })
				return reject( 'error in getCustomerInfo' )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	function finalizeOutput( objective, data, maxEndDate ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			const metricData = data.recordset
			const jsMaxDate = dayjs( maxEndDate, 'YYYY-MM-DD' )
			// const metricDataCols = Object.keys(metricData.columns)

			// build the google DataTable columns headers based on the metadata in the result sets...
			let rows 		= []
			let cols 		= []
			let dataType 	= ''
			let options 	= {}
			let vAxes 		= {}

//			const tenYearsAgo = dayjs().subtract( 41, 'quarter' )
			const tenYearsAgo = jsMaxDate.subtract( 41, 'quarter' )
			const minDate = new Date( dayjs( tenYearsAgo ).year(), dayjs( tenYearsAgo ).month(), dayjs( tenYearsAgo ).date() )
			const maxDate = new Date( dayjs( jsMaxDate ).year(), dayjs( jsMaxDate ).month(), dayjs( jsMaxDate ).date() )
//			const maxDate = new Date( maxYear, maxMonth, maxDay )
			const lineWidth = 3
			const pointSize = 3
			const colorPrimary 		= '#512DA8'  	// purple-ish
			const colorSecondary 	= '#F52C2C'		// red-ish
			const colorTertiary		= '#20B256'		// green-ish
			const colorObjective		= 'orange'		// orange. definitely orange.
			const explorer = {
					axis: 'horizontal',
					keenInBounds: true,
					maxZoomIn: 7,
					zoomDelta: 1.1,
				}
			const hAxis = {
					gridlines: {count: 7},
					viewWindow: {
						min: utilities.date2GoogleDate( minDate ),
						max: utilities.date2GoogleDate( maxDate ),
					},
				}
			const legend = {
					position: 'top'
				}



			switch ( parseInt( objective.metricTypeID ) ) {

				case 1:					// TEG Standard
				case 2:					// Custom
				case 5:					// FDIC Calc[ulated]

					cols = [
						{ id: "Date", label: "Date", type: "date" },
						{ id: "Value", label: "Value", type: "number" }
					]

					series = {
						0: { type: "line", color: colorTertiary, targetAxisIndex: 0 }
					}

					metricData.forEach( item => {

						rows.push(
							{c: [
								{ v: utilities.date2GoogleDate( item.Date ) },
								{ v: item.Value  },
								{ v: null }
							]}
						)
					})

					options = {
						explorer: explorer,
						hAxis: hAxis,
					   lineWidth: lineWidth,
						pointSize: pointSize,
						series: series,
						vAxis: {
							title: 'Value',
						},
						legend: legend,
						title: objective.name,
					}

					appendGoals( cols, rows, series, objective )

					return resolve({ data: { cols: cols, rows: rows }, options: options })

					break

				case 3:					// FDIC, data from FFIEC

					if ( objective.statsColumnName && objective.ranksColumnName ) {

						cols = [
							{ id: "Date", label: "Date", type: "date" },
							{ id: "Bank", label: "Bank", type: "number" },
							{ id: "PG", label: "PG", type: "number" },
							{ id: "PG Percentile", label: "PG Percentile", type: "number" },
							{ role: "tooltip", type: "string", p: { html: true } }
						]

						series = {
							0: { type: "line", color: colorTertiary, targetAxisIndex: 0 },
							1: { type: 'line', color: colorSecondary, targetAxisIndex: 0 },
							2: { type: 'bars', dataOpacity: .5, color: colorPrimary, targetAxisIndex: 1 }
						}



						metricData.forEach( item => {

							let rptPeriod	= utilities.date2GoogleDate( item["Date"] )
							let tooltip 	= 	'<table>'
												+ 		'<tr><th align="left" colspan="2" style="border-bottom: solid black 1px;">' + item["PG Description"] + '</th></tr>'
												+ 		'<tr><th align="left" width="30%" nowrap>Report Period:</th><td>' + dayjs( item["Date"] ).format( 'M/D/YYYY' ) + '</td></tr>'
												+ 		'<tr><th align="left" nowrap>PG Percentile:</th><td>' + item["PG Percentile"] + '</td></tr>'
												+ 		'<tr><th align="left" nowrap>Peer Group:</th><td>' + item["Peer Group"] + '</td></tr>'
												+ 	'</table>'

							rows.push({ c: [
								{ v: rptPeriod },							// [reporting period]
								{ v: item["Bank"] },						//	[Bank]
								{ v: item["PG"] }, 						//	[PG]
								{ v: item["PG Percentile"] },			// [PG Percentile]
								{ v: tooltip }
							]})

						})

					} else {

						includeAnnualChange = objective.correspondingAnnualChangeID && objective.showAnnualChangeInd ? true : false

						cols = [
							{ id: "Date", label: "Date", type: "date" },
							{ id: "Bank", label: "Bank", type: "number" }
						]
						if ( includeAnnualChange ) cols.push( { id: "apc", label: "Annual % Change", type: "number" } )

						if ( includeAnnualChange ) {
							series = {
								0: { type: "line", color: colorTertiary, targetAxisIndex: 0 },
								1: { type: "line", color: colorPrimary, targetAxisIndex: 1 }
							}
						} else {
							series = {
								0: { type: "line", color: colorTertiary, targetAxisIndex: 0 }
							}
						}

						if ( includeAnnualChange ) {
							vAxes = {
								0: { title: "Bank" },
								1: { title: 'Annual % Change', format: '#\'%\'', textStyle: {color: colorPrimary}, titleTextStyle: {color: colorPrimary} }
							}
						} else {
							vAxes = {
								0: { title: "Bank" },
							}
						}

						metricData.forEach( item => {

							let rptPeriod	= utilities.date2GoogleDate( item["Date"] )

							if( includeAnnualChange ) {
								rows.push({ c: [
									{ v: rptPeriod },						// [reporting period]
									{ v: item["Bank"]},					// [Bank]
									{ v: item["Annual % Change"]}		// [Annual % Change]
								]})
							} else {
								rows.push({ c: [
									{ v: rptPeriod },						// [reporting period]
									{ v: item["Bank"] }					//	[Bank]
								]})
							}

						})

					}


					options = {
						explorer: explorer,
						hAxis: hAxis,
					   lineWidth: lineWidth,
						pointSize: pointSize,
						series: series,
						vAxis: {minValue: 0},
						vAxes: vAxes,
						legend: legend,
						title: objective.name,
						tooltip: { isHtml: true }
					}

					appendGoals( cols, rows, series, objective )

					return resolve({ data: { cols: cols, rows: rows }, options: options })

					break

				case 4:					// TGIM-U, data from Lightspeed VT

					utilities.getTGIMUActiveUsersCount( objective.customerID )
					.then( totalActiveUsers => {

						switch( parseInt( objective.metricID ) ) {

							case 995: // TGIM-U Training Attempt Utilization

								cols = [
									{ id: "Date", label: "Date", type: "date" },
									{ id: "pass", label: "Pass", type: "number" },
									{ id: "fail", label: "Fail", type: "number" },
									{ id: "viewed", label: "Viewed", type: "number" }
								]

								series = {
									0: { type: "line", color: colorTertiary },
									1: { type: "line", color: colorSecondary },
									2: { type: "line", color: 'orange' }
								}

								metricData.forEach( item => {
									rows.push(
										{c: [
											{ v: utilities.date2GoogleDate( item.Date ) },
											{ v: item.pass },
											{ v: item.fail },
											{ v: item.viewed },
										]}
									)
								})

								options = {
									explorer: explorer,
									hAxis: hAxis,
								   lineWidth: lineWidth,
									pointSize: pointSize,
									series: series,
									vAxis: {
										title: 'Value',
									},
									legend: legend,
									title: objective.name,
								}

								break

							default:

								cols = [
									{ id: "Date", label: "Date", type: "date" },
									{ id: "value", label: "Value", type: "number" }
								]

								series = {
									0: { color: colorTertiary },
									1: { type: 'line', dataOpacity: .3, color: 'orange' }
								},


								metricData.forEach( item => {

									utilization	= Math.round(item.Value / totalActiveUsers * 100 * 10) / 10
									formatted = parseFloat(utilization).toFixed(1)+'% ('+item.Value+' of '+totalActiveUsers+')'

									rows.push(
										{c: [
											{ v: utilities.date2GoogleDate( item.Date ) },
											{ v: utilization, f: formatted},
										]}
									)
								})

								options = {
									explorer: explorer,
									hAxis: hAxis,
								   lineWidth: lineWidth,
									pointSize: pointSize,
									series: series,
									vAxis: {
										title: 'Utilization %',
										viewWindow: { min: 0, max:100 }
									},
									legend: legend,
									title: objective.name,
								}

						}

						appendGoals( cols, rows, series, objective )

						return resolve({ data: { cols: cols, rows: rows }, options: options })

					})
					.catch( err => {

						logger.log({ level: 'error', label: 'getMetricData()', message: 'Unexpected error formatting TGIM-U results: ' + err, user: null })
						console.error( err )
						return reject( 'Unexpected error formatting TGIM-U results' )

					})
					break


				default:

					logger.log({ level: 'error', label: 'getMetricData()', message: 'Unexpected metricID encountered in "finalizeOutput" ', user: null })
					return reject( 'Unexpected metricID encountered in "finalizeOutput" ')

			}

		})

	}
	//====================================================================================


	//====================================================================================
	function appendGoals( cols, rows, series, objective ) {
	//====================================================================================

		if ( objective.startDate && objective.endDate ) {

			// add an entry to the "series" object to support the goal...
			seriesKeys = Object.keys( series )
			lastSeries = parseInt( seriesKeys[ seriesKeys.length - 1 ] )
			goalSeries = lastSeries + 1

			series[ goalSeries ] = { type: "line", color: "orange" }


			// add an entry to the "cols" array to support the goal...
			cols.push({ id: "Objective", label: "Objective", type: "number" })


			// add an entry to "rows" array to support the start of the goal..
			let cellArray = []
			cellArray.push( { v: utilities.date2GoogleDate( objective.startDate ) } )
			for ( i = 1; i < cols.length - 1; ++i ) {
				// leave null in the metric's cells/columns...
				cellArray.push( { v: null } )
			}
			cellArray.push( { v: objective.startValue } )
			rows.push( 	{ c: cellArray } )


			// add an entry to the "rows" array to support the end of the goal...
			cellArray = []
			cellArray.push( { v: utilities.date2GoogleDate( objective.endDate ) } )
			for ( i = 1; i < cols.length - 1; ++i ) {
				// leave null in the metric's cells/columns
				cellArray.push( { v: null } )
			}
			cellArray.push( { v: objective.endValue } )
			rows.push( 	{ c: cellArray } )

		}

	}
	//====================================================================================


	//====================================================================================
	function getMetricData( query ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'metrics/getMetricData()', message: query });

			sql.connect(dbConfig).then( pool => {
				return pool.request().query( query );
			}).then( results => {
				resolve( results );
			}).catch( err => {
				logger.log({ level: 'error', label: 'getMetricData()', message: err });
				reject( err );
			});

		});

	}
	//====================================================================================


	//====================================================================================
	function buildMetricQuery( objective ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let query 		= ''
			let sqlSelect 	= ''
			let sqlFrom 	= ''
			let sqlWhere	= ''

			switch ( parseInt( objective.metricTypeID ) ) {

				case 1: 		// TEG Standards
				case 2: 		// Custom

					query	= 	`
						select
							format( metricDate, 'yyyy-MM-dd' ) as [Date],
							metricValue as [Value]
						from customerInternalMetrics
						where rssdID = ${objective.rssdID}
						and metricID = ${objective.metricID}
						order by 1
					`

					break

				case 3: 		// FDIC, data from FFIEC

					ubprTables = [
						'AllowanceLoanMixA',
						'AssetYieldsFundingCosts',
						'BalanceSheetDollar',
						'BalanceSheetPercent',
						'CapitalAnalysisA',
						'IncomeStatementDollar',
						'LiquidityFunding',
						'NonIntIncExpYields',
						'PDNonaccRestLoansB',
						'SummaryRatios'
					]

					callTables = [
						'RCCI',
						'RCN',
						'RI',
						'RIA',
						'RIBII'
					]

					sqlSelect 	=	`select format( d.id, 'yyyy-MM-dd' ) as [Date] `
					sqlFrom		=	`from dateDimension d `

					let objectiveTableNamePrefix 	= callTables.includes( objective.sourceTableNameRoot ) ? 'fdic_calls.dbo.' : 'fdic_ratios.dbo.';
					let objectiveTableName 			= objectiveTableNamePrefix + objective.sourceTableNameRoot.trim();
					let objectiveColumnName			= callTables.includes( objective.sourceTableNameRoot ) ? '[IDRSSD]' : '[ID RSSD]';




					if ( ubprTables.includes( objective.sourceTableNameRoot ) ) {
						// build UBPR SQL...
						if ( objective.ratiosColumnName ) {
							sqlSelect	+=	`, r.${objective.ratiosColumnName} as [Bank] `
							sqlFrom		+=	`left join ${objectiveTableName} r on (cast(r.[reporting period] as date) = d.id and r.${objectiveColumnName} = ${objective.rssdID}) `
							sqlWhere 	+= ( sqlWhere.length === 0 ? '' : ' or ' ) + 'r.[Reporting Period] is not null'
						}

						if ( objective.correspondingAnnualChangeID ) {

							if ( objective.showAnnualChangeInd ) {
								sqlSelect	+=	`, c.[${objective.corrAnnualChangeCol}] as [Annual % Change] `
								sqlFrom		+= `left join fdic_ratios.dbo.${objective.corrAnnualChangeTbl} c on (cast(c.[reporting period] as date) = d.id and c.[id rssd] = ${objective.rssdID}) `
								sqlWhere 	+= ( sqlWhere.length === 0 ? '' : ' or ' ) + 'c.[Reporting Period] is not null'
							}

						} else {

							if ( objective.statsColumnName && objective.ranksColumnName ) {

								sqlSelect	+=	`, s.[${objective.statsColumnName}] as [PG]
													 , k.[${objective.ranksColumnName}] as [PG Percentile]
													 , pg.id as [Peer Group]
													 , pg.description as [PG Description] `

								sqlFrom		+=	`left join fdic_ranks.dbo.${objective.sourceTableNameRoot} k on (k.[reporting period] = r.[reporting period] and k.[id rssd] = r.[id rssd] and k.[peer group] in (select id from fdic.dbo.peerGroup where peerGroupType = ${objective.peerGroupTypeID}) )
													 left join fdic_stats.dbo.${objective.sourceTableNameRoot} s on (s.[reporting period]  = k.[reporting period] and s.[peer group] = k.[peer group])
													 left join fdic.dbo.peerGroup pg on (pg.id = s.[peer group]) `

								sqlWhere 	+= ( sqlWhere.length === 0 ? '' : ' or ' ) + 'k.[Reporting Period] is not null or s.[Reporting Period] is not null'

							}

						}

					} else {

						sqlSelect	+=	`, ${objective.ratiosColumnName} as [Bank] `
						sqlFrom		+=	`left join ${objectiveTableName} r on (cast(r.[reporting period] as date) = d.id and r.${objectiveColumnName} = ${objective.rssdID}) `
						sqlWhere 	+= ( sqlWhere.length === 0 ? '' : ' or ' ) + 'r.[Reporting Period] is not null'

						if ( objective.correspondingAnnualChangeID ) {
							sqlSelect	+=	`, c.[${objective.corrAnnualChangeCol}] as [Annual % Change] `
							sqlFrom		+= `left join fdic_ratios.dbo.${objective.corrAnnualChangeTbl} c on (cast(c.[reporting period] as date) = d.id and c.[id rssd] = ${objective.rssdID}) `
							sqlWhere 	+= ( sqlWhere.length === 0 ? '' : ' or ' ) + 'c.[Reporting Period] is not null'
						}

					}

					query = `
						${sqlSelect}
						${sqlFrom}
						where d.quarterEndInd = 1
						and ( ${sqlWhere} )
						order by 1
					`

					break

				case 4: 		// TGIM-U, data from Lightspeed VT
				case 5:		// FDIC Calc[ulated]

					const queries = {
						995: { sqlPath: [ 'metrics', 'tgimu', '995_training_attempt_utilization_results.sql' ] } ,
						996: { sqlPath: [ 'metrics', 'tgimu', '996_training_attempt_utilization_count.sql' ] },
						997: { sqlPath: [ 'metrics', 'tgimu', '997_signin_utilization.sql' ] },
						9000: { sqlPath: [ 'metrics', 'fdic_calc', '9000_Noncurrent_Loans_to_Total_Loans.sql' ] }
					}

					const entry = parseInt( objective.metricID );

					if ( !entry ) {
						logger.log({ level: 'error', label: 'buildMetricQuery()', message: 'unkonwn TGIM-U metric ID' })
						return reject( 'unkonwn TGIM-U metric ID' )
					}
					query = utilities.loadSQL( ...queries[entry].sqlPath )
						.replace(/{{customerID}}/g, objective.customerID)
						.replace(/{{IDRSSD}}/g, objective.rssdID);

					break;



				default:

					logger.log({ level: 'error', label: 'buildMetricQuery()', message: 'unexpected metricTypeiD' })
					return reject( 'unexpected metricTypeiD')

			}

			if ( query != '' ) {
				logger.log({ level: 'debug', label: 'buildMetricQuery()', message: query })
				return resolve( query )
			} else {
				logger.log({ level: 'error', label: 'buildMetricQuery()', message: 'no query' })
				return reject( 'no query for', objective.name )
			}

		})

	}
	//====================================================================================


	//====================================================================================
	function getMetricDetails( metricID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL	= 	"select "
						+		"m.id as metricID, "
						+		"m.name, "
						+		"m.ranksColumnName, "
						+		"m.ratiosColumnName, "
						+		"m.statsColumnName, "
						+		"m.ubprSection, "
						+		"m.ubprLine, "
						+		"m.financialCtgy, "
						+		"m.sourceTableNameRoot, "
						+		"m.internalMetricInd, "
						+		"m.correspondingAnnualChangeID, "
						+		"m.type, "
						+		"m.dataType, "
						+		"mt.id as metricTypeID, "
						+		"mt.name as metricType "
						+	"from metric m "
						+	"left join metricTypes mt on (mt.id = m.metricTypeID) "
						+	"where m.id = @metricID "

			sql.connect(dbConfig).then( pool => {

				return pool.request()
				.input( 'metricID', sql.BigInt, metricID )
				.query( SQL )

			}).then( result => {

				return resolve( result.recordset[0] )

			}).catch( err => {

				logger.log({ level: 'error', label: 'getMetricDetails()', message: err, user: null })
				reject( err )

			})

		})

	}
	//====================================================================================


}
