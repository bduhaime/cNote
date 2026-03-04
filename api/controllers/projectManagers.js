// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = async function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const pool = await sql.connect( dbConfig );

	//====================================================================================
	https.get('/api/projectManagers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			// if ( !req.query.clientNbr ) return res.status( 400 ).send( 'clientNbr missing parameter' );
			if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID missing parameter' );

			let SQL	= 	`select u.id, concat(u.firstName, ' ', u.lastName) as fullName, cast( 0 as bit ) as disabled `
						+	`from csuite.dbo.users u `
						+	`join csuite.dbo.clientUsers cu on (cu.userID = u.id and cu.clientID = @clientNbr ) `
						+	`join userCustomers uc on (uc.userID = u.id and uc.customerID = 1) `
						+	`UNION `
						+	`select distinct p.projectManagerID, concat(u.firstName, ' ', u.lastName) as fullName, cast( 1 as bit ) as disabled `
						+	`from projects p `
						+	`join csuite.dbo.users u on (u.id = p.projectManagerID) `
						+	`where p.customerID = @customerID `
						+	`and u.id not in ( `
						+		`select u.id `
						+		`from csuite.dbo.users u `
						+		`join csuite.dbo.clientUsers cu on (cu.userID = u.id and cu.clientID = @clientNbr ) `
						+		`join userCustomers uc on (uc.userID = u.id and uc.customerID = 1) `
						+	`) `
						+	`order by fullName `;

			const results = await pool.request()
					.input( 'clientNbr', sql.BigInt, req.session.clientNbr )
					.input( 'customerID', sql.BigInt, req.query.customerID )
					.query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.projectManagers', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected database error' );

		}

	});
	//====================================================================================


}
