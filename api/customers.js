// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/customers/cprofitAccessInfo/:id', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.id ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL 	= 	"select "
					+		"cProfitApiKey, "
					+		"cProfitURI "
					+	"from customer "
					+	"where id = @customerID "

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'customerID', sql.BigInt, req.params.id )
				.query( SQL )
		}).then( results => {
			res.json( results.recordset[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET.customers/cprofitAccessInfo', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})
	})
	//====================================================================================


	//====================================================================================
	https.put('/api/customers/cprofitAccessInfo', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.body.cProfitURL ) return res.status( 400 ).send( 'Parameter missing' )

		const saltTime = dayjs().format( 'HHmmssSSS')
		const saltDate = dayjs().format( 'YYYYMMDD')
		const saltedString = req.body.customerID + saltTime + req.session.dbName + saltDate + req.body.cProfitURL

		let crypto = require( 'crypto' )

		const apiKey = crypto.createHash( 'sha256' ).update( saltedString ).digest( 'hex' )

		res.json({ apiKey: apiKey })

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customers', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		editPermitted = utilities.UserPermitted( req.session.userID, 18 )
		statusPermitted = utilities.UserPermitted( req.session.userID, 133 )
		deletePermitted = utilities.UserPermitted( req.session.userID, 22 )

		Promise.all([ editPermitted, statusPermitted, deletePermitted ]).then( permissions => {

			userPermissions = {
				edit: permissions[0],
				status: permissions[1],
				delete: permissions[2]
			}

			let internalUserPredicate = req.session.internalUser != 1 ? `and c.id in ( select customerID from userCustomers where userID = ${req.session.userID} )` : ''

			let SQL =  `select
								c.id as DT_RowId,
								c.name,
								i1.city,
								i1.stalp,
								s.description as status,
								c.deleted,
								c.cert,
								c.rssdID,
								c.nickname,
								c.validDomains,
								cProfitApiKey,
								cProfitURI,
								lsvtCustomerName,
								customerGradeID,
								customerGradeNarrative,
								anomoliesNarrative,
								optOutOfMCCCalls
							from customer_view c
							left join fdic.dbo.institutions i1 on (i1.fed_rssd = c.rssdID and i1.repdte = (select max(repdte) from fdic.dbo.institutions i2 where i2.cert = c.cert))
							left join customerStatus s on (s.id = c.customerStatusID and (s.deleted = 0 or s.deleted is null) )
							where (c.deleted = 0 or c.deleted is null)
							and c.id <> 1
							${internalUserPredicate}
							order by c.name `

			logger.log({ level: 'debug', label: 'GET.customers', message: SQL, user: req.session.userID })

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.query( SQL )
			}).then( results => {

				for ( row of results.recordset ) {
					row.userPermissions = userPermissions
				}
				res.json( results.recordset )

			}).catch( err => {
				logger.log({ level: 'error', label: 'GET.customers', message: err, user: req.session.userID })
				return res.status( 500 ).send( 'Unexpected database error' )
			})


		}).catch( err => {
			logger.log({ level: 'error', label: 'GET.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Error collecting promises' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/customers', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const optOutOfMCCCalls = req.body.optOutOfMCCCalls === 'true' ? 1 : 0

		let SQL =	`update customer set
							name = @name,
							nickname = @nickname,
							customerStatusID = @statusID,
							validDomains = @validDomains,
							lsvtCustomerName = @lsvtCustomerName,
							cProfitURI = @cProfitURI,
							cProfitAPIKey = @cProfitAPIKey,
							updatedBy = @updatedBy,
							updatedDateTime = CURRENT_TIMESTAMP,
							optOutOfMCCCalls = @optOutOfMCCCalls
						where id = @customerID`

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'name', sql.VarChar, req.body.customerName )
				.input( 'nickname', sql.VarChar, req.body.nickname )
				.input( 'statusID', sql.BigInt, req.body.statusID )
				.input( 'validDomains', sql.VarChar, req.body.validDomains )
				.input( 'lsvtCustomerName', sql.VarChar, req.body.lsvtCustomerName )
				.input( 'cProfitURI', sql.VarChar, req.body.cProfitURI )
				.input( 'cProfitAPIKey', sql.VarChar, req.body.cProfitAPIKey )
				.input( 'updatedBy', sql.BigInt, req.session.userID )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.input( 'optOutOfMCCCalls', optOutOfMCCCalls )
				.query( SQL )
		}).then( results => {

			if ( process.env.ENVIRONMENT != 'DEVELOPMENT' ) {

				const { spawn } = require('child_process')
				const interimLoad = spawn( 'interimLoad.bat', [ req.body.customerID ], { detached: true } )
				interimLoad.stdout.on( 'data', (data) => {
					console.log( `interim load stdout: ${data}`)
				})
				interimLoad.stderr.on( 'data', (data) => {
					console.log( `interim load stderr: ${data}`)
				})
				interimLoad.on( 'close', (code) => {
					console.log( `interim load exited with code ${code}`)
				})

			}

			return res.sendStatus( 200 )

		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customers', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL = 	`select cert, fed_rssd
						 from fdic.dbo.institutions
						 where name = @customerName
						 and city = @city
						 and stalp = @state`

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'customerName', sql.VarChar, req.body.customerName )
				.input( 'city', sql.VarChar, req.body.city )
				.input( 'state', sql.VarChar, req.body.state )
				.query( SQL )
		}).then ( results => {

			const customerID = utilities.GetNextID( 'customer' )
			const optOutOfMCCCalls = req.body.optOutOfMCCCalls === 'true' ? 1 : 0

			.then( customerID => {

				let SQL =	`insert into customer (
									id,
									cert,
									rssdID,
									name,
									customerStatusID,
									nickname,
									validDomains,
									updatedBy,
									updatedDateTime,
									optOutOfMCCCalls
								) values (
									@id,
									@cert,
									@rssdID,
									@name,
									@statusID,
									@nickname,
									@validDomains,
									@updatedBy,
									CURRENT_TIMESTAMP,
									@optOutOfMCCCalls
								)`

				sql.connect(dbConfig).then( pool => {
					return pool.request()
						.input( 'id', sql.BigInt, customerID )
						.input( 'cert', sql.VarChar, results.recordset[0].cert )
						.input( 'rssdID', sql.VarChar, results.recordset[0].fed_rssd )
						.input( 'name', sql.VarChar, req.body.customerName )
						.input( 'nickname', sql.VarChar, req.body.nickname )
						.input( 'statusID', sql.BigInt, req.body.statusID )
						.input( 'validDomains', sql.VarChar, req.body.validDomains )
						.input( 'updatedBy', sql.BigInt, req.session.userID )
						.input( 'optOutOfMCCCalls', optOutOfMCCCalls )
						.query( SQL )
				}).then( results => {

					const { spawn } = require('child_process')
					const interimLoad = spawn( 'interimLoad.bat', [ customerID ], { detached: true } )
					interimLoad.stdout.on( 'data', (data) => {
						console.log( `interim load stdout: ${data}`)
					})
					interimLoad.stderr.on( 'data', (data) => {
						console.log( `interim load stderr: ${data}`)
					})
					interimLoad.on( 'close', (code) => {
						console.log( `interim load exited with code ${code}`)
					})


					return res.sendStatus( 200 )
				}).catch( err => {
					logger.log({ level: 'error', label: 'POST.customers', message: err, user: req.session.userID })
					return res.status( 500 ).send( 'Unexpected database error' )
				})

			}).catch( err => {

				logger.log({ level: 'error', label: 'POST.customers', message: err, user: req.session.userID })
				return res.status( 500 ).send( 'Unexpected database error' )

			})



		}).catch( err => {
			logger.log({ level: 'error', label: 'POST.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})




	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/customers', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const SQL = `update customer set deleted = 1 where id @customerID`

		sql.connect( dbConfig ).then( pool => {
			return pool.request()
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.query( SQL )
		}).then( results => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'DELETE.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


}
