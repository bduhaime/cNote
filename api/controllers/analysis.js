// ----------------------------------------------------------------------------------------
// Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	const dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/analysis/pgDeltas', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const reportingPerids = await [ '2021-12-31 00:00:00.000', '2022-03-31 00:00:00.000', '2022-06-30 00:00:00.000', '2022-09-30 00:00:00.000', '2022-12-31 00:00:00.000' ]
			// const reportingPerids = await [ '2021-12-31', '2022-03-31', '2022-06-30', '2022-09-30', '2022-12-31' ]
			const peerGroup = 'COM'
			let results = []
			let totalRows = 0

			let SQL	= 	await	`select i.name, i.cert, i.fed_rssd, a.*, b.*, c.*, d.*, e.*, f.*, h.* `
								+	`from fdic..institutions i  `
								+	`join fdic_ranks..balanceSheetDollar a 	on ( a.[ID RSSD] = i.FED_RSSD and a.[reporting period] = @reportingPeriod and a.[Peer Group] = @peerGroup ) `
								+	`join fdic_ranks..balanceSheetPercent b 	on ( b.[ID RSSD] = i.FED_RSSD and b.[reporting period] = @reportingPeriod and b.[Peer Group] = @peerGroup ) `
								+	`join fdic_ranks..CapitalAnalysisA c 		on ( c.[ID RSSD] = i.FED_RSSD and c.[reporting period] = @reportingPeriod and c.[Peer Group] = @peerGroup ) `
								+	`join fdic_ranks..IncomeStatementDollar d	on ( d.[ID RSSD] = i.FED_RSSD and d.[reporting period] = @reportingPeriod and d.[Peer Group] = @peerGroup ) `
								+	`join fdic_ranks..LiquidityFunding e 		on ( e.[ID RSSD] = i.FED_RSSD and e.[reporting period] = @reportingPeriod and e.[Peer Group] = @peerGroup ) `
								+	`join fdic_ranks..NonIntIncExpYields f 	on ( f.[ID RSSD] = i.FED_RSSD and f.[reporting period] = @reportingPeriod and f.[Peer Group] = @peerGroup ) `
								+	`join fdic_ranks..SummaryRatios h 			on ( h.[ID RSSD] = i.FED_RSSD and h.[reporting period] = @reportingPeriod and h.[Peer Group] = @peerGroup ) `
								+	`where i.ACTIVE = 1 `

			const pool = await sql.connect( dbConfig )

			for ( quarter of reportingPerids ) {

				let result = await pool.request()
					.input( 'reportingPeriod', sql.DateTime, quarter )
					.input( 'peerGroup', sql.VarChar( 10 ), peerGroup )
					.query( SQL )

				totalRows += result.recordset.length
				await results.push( result.recordset )

			}

			// continue processing

			res.sendStatus( 200 )

		} catch( err ) {
			consol.error( err )
		}

	})
	//====================================================================================

}
