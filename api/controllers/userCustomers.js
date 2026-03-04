// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

// dbConfig = require('../config/database.json').mssql;
	let db = require('../config/db.js');

	//====================================================================================
	https.get('/api/userCustomers', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.query.userID ) return res.status( 400 ).send( 'userID Parameter missing' )

		let SQL 	= `select `
					+		`c.id as customerID, `
					+		`c.name, `
					+		`c.validDomains, `
					+		`case when uc.customerID is not null then 1 else 0 end as associatedCustomer `
					+	`from customer_view c `
					+	`left join userCustomers uc on (uc.customerID = c.id and userID =  @userID ) `
					+	`where (c.deleted = 0 or c.deleted is null) `
					+	`and c.id <> 1 `
					+	`order by c.name `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.query.userID )
				.query( SQL )

		}).then( async (result) => {

			finalResults = []
			for ( customer of result.recordset ) {

				let userDomainIsValid = await utilities.isUserDomainValid( req.session.username, customer.customerID, req.session.dbName )
				let customerDisabled, customerColor, titleText

				if ( await utilities.UserPermitted( req.session.userID, 59 ) ) {
					customerDisabled = false
					if ( userDomainIsValid ) {
						customerColor = 'black'
						titleText = ''
					} else {
						customerColor = 'crimson'
						titleText = 'Username domain is not valid for this customer, but this can be overriden'
					}
				} else {
					if ( userDomainIsValid ) {
						customerDisabled = false
						customerColor = 'black'
						titleText = ''
					} else {
						customerDisabled = true
						customerColor = 'rgba(0,0,0,.26)'
						titleText = 'Username domain is not valid for this customer'
					}
				}

				finalResults.push({
					customerID: customer.customerID,
					name: customer.name,
					validDomains: customer.validDomains,
					associatedCustomer: customer.associatedCustomer,
					customerDisabled: customerDisabled,
					customerColor: customerColor,
					titleText: titleText
				})
			}


			res.json( finalResults )

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/userCustomers', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/userCustomers', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.customerID ) return res.status( 400 ).send( 'customerID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.query( 'insert into userCustomers ( userID, customerID ) values ( @userID, @customerID ) ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/userCustomers', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/userCustomers', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		if ( !req.body.userID ) return res.status( 400 ).send( 'userID Parameter missing' )
		if ( !req.body.customerID ) return res.status( 400 ).send( 'customerID Parameter missing' )

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'userID', sql.BigInt, req.body.userID )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.query( 'delete from  userCustomers where userID = @userID and customerID = @customerID ' )

		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE:api/userCustomers', message: err, user: req.session.userID })
			res.sendStatus( 500 )
		})

	})
	//====================================================================================


}
