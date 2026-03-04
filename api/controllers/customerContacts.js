// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customerContacts', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Customer ID parameter missing' );

		let SQL 	= 	`
			SELECT
				c.id,
				c.firstName,
				c.lastName,
				/* ...other columns... */
				NULLIF(roles.roleNamesJson, '[]') AS roleNames
			FROM customerContacts AS c
			CROSS APPLY (
				SELECT ccr.name
				FROM contactRoleXref AS x
				JOIN customerContactRoles AS ccr ON ccr.id = x.roleID
				WHERE x.contactID = c.id
				GROUP BY ccr.name
				FOR JSON PATH
			) AS roles(roleNamesJson)
			WHERE c.customerID = @customerID
			AND ( c.deleted = 0 OR c.deleted IS NULL )
			ORDER BY c.firstName, c.lastName;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( results => {

			res.json( results.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/customerContacts', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================




}
