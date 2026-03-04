// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = async function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const pool = await sql.connect( dbConfig );


	//====================================================================================
	https.get('/api/institutions', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.term ) return res.status( 400 ).send( 'Search term missing' )
			// if ( !req.query.active ) return res.status( 400 ).send( 'Active term missing' )

			const searchTerm = `%${req.query.term}%`

			let activePredicate
			if ( req.query.active == 1 ) {
				activePredicate = 'and i.active = 1 '
			} else {
				activePredicate = ''
			}

			const active = req.query.active ? 1 : 2

			let SQL 	= 	`select i.name + ' - ' + i.city + ', ' + i.stalp + ' (CERT: ' + trim(cast(i.cert as char)) + ')' as name, i.fed_rssd `
						+	`from fdic..institutions i `
						+	`where i.fed_rssd not in ( select rssdid from customer where rssdid is not null and ( deleted = 0 or deleted is null ) ) `
						+	`and i.name like @searchTerm `
						+	`${activePredicate} `
						+	`order by 1 `

			const results = await pool.request()
				.input( 'searchTerm', sql.VarChar, searchTerm )
				.query( SQL )

			// Map the results to a simple array of names
			const institutions = results.recordset.map( row => ({
				value: row.fed_rssd, 	// ID to be stored
				label: row.name 			// Displayed value
			}))

			res.json( institutions )

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.institutions', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Error getting institutions' )

		}

	})
	//====================================================================================



}
