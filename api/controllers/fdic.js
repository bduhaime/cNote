// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/fdic/maxDate', (req, res) => {
	//====================================================================================

		let SQL 	= 	"select "
					+		"max([reporting period]) as maxDate "
					+	"from fdic_stats.dbo.SummaryRatios "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.query(SQL)

		}).then( result => {

			res.json({ maxDate: result.recordset[0].maxDate })

		}).catch( err => {

			throw err

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/fdic/reportingPeriods', (req, res) => {
	//====================================================================================

		let SQL 	= 	"select distinct "
					+		"format( [reporting period], 'yyyy-MM-dd' ) as reportingPeriod "
					+	"from fdic_stats.dbo.SummaryRatios "
					+ "order by 1 desc "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.query(SQL)

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			throw err

		})

	})
	//====================================================================================



}
