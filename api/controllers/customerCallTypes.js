// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customerCallTypes/', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	= 	`select `
						+		`id, `
						+		`name, `
						+		`description, `
						+		`idealFrequencyDays, `
						+		`shortName `
						+	`from customerCallTypes `
						+	`order by name `

		sql.connect(dbConfig).then( pool => {

			return pool.request().query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'getCallTypes()', message: 'Unexpected database error' })
			reject( 'Unexpected database error' )

		})

	})
	//====================================================================================


}
