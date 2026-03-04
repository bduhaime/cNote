// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = async function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const pool = await sql.connect( dbConfig );

	const formatter = new Intl.NumberFormat('en-US', {
		style: 'currency',
		currency: 'USD',
		minimumFractionDigits: 0, // (this suffices for whole numbers, but will print 2500.10 as $2,500.1)
		maximumFractionDigits: 0, // (causes 2500.99 to be printed as $2,501)
	});

	//====================================================================================
	https.get('/api/customers/cprofitAccessInfo/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.params.id ) return res.status( 400 ).send( 'Parameter missing' )

			let SQL 	= 	"select "
						+		"cProfitApiKey, "
						+		"cProfitURI "
						+	"from customer "
						+	"where id = @customerID "

			const results = await pool.request()
				.input( 'customerID', sql.BigInt, req.params.id )
				.query( SQL )

			if ( results.recordset.length > 0 ) {
				return res.json( results.recordset[0] )
			} else {
				throw new Error( 'Customer not found' )
			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers/cprofitAccessInfo', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

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

		return res.json({ apiKey: apiKey })

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/customers/togglePeriodicReview/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.params.id ) return res.status( 400 ).send( 'Parameter missing' )

			let SQL 	= 	`update customer set `
						+		`periodicReviewComplete = case when ( periodicReviewComplete = 0 or periodicReviewComplete is null ) then 1 else 0 end `
						+	`where id = @customerID `

			const results = await pool.request()
				.input( 'customerID', sql.BigInt, req.params.id )
				.query( SQL )

			return res.sendStatus( 201 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'PUT.customers/togglePeriodicReview/:id', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/customers/resetAllPeriodicReviewIndicators', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL 	= 	`update customer set periodicReviewComplete = 0 `

			const results = await pool.request().query( SQL )

			return res.sendStatus( 201 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'PUT.customers/resetAllPeriodicReviewIndicators', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const editPermitted = await utilities.UserPermitted( req.session.userID, 18 )
			const statusPermitted = await utilities.UserPermitted( req.session.userID, 133 )
			const deletePermitted = await utilities.UserPermitted( req.session.userID, 22 )

			userPermissions = {
				edit: editPermitted,
				status: statusPermitted,
				delete: deletePermitted
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
								secretShopperLocationName,
								customerGradeID,
								customerGradeNarrative,
								anomoliesNarrative,
								optOutOfMCCCalls,
								c.defaultTimezone
							from customer_view c
							left join fdic.dbo.institutions i1 on (i1.fed_rssd = c.rssdID and i1.repdte = (select max(repdte) from fdic.dbo.institutions i2 where i2.cert = c.cert))
							left join customerStatus s on (s.id = c.customerStatusID and (s.deleted = 0 or s.deleted is null) )
							where (c.deleted = 0 or c.deleted is null)
							and c.id <> 1
							${internalUserPredicate}
							order by c.name `

				logger.log({ level: 'debug', label: 'GET.customers', message: SQL, user: req.session.userID })

				const results = await pool.request().query( SQL )

				for ( row of results.recordset ) {
					row.userPermissions = userPermissions
				}

				res.json( results.recordset )

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Error collecting promises' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customers/latestFinancials/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let dateInfo = await getLatestUpdate( req.params.id )
			let totalAssets = await getTotalAssets( req.params.id, dateInfo.maxDate )
			let roaAndNim = await getRoaAndNim( req.params.id, dateInfo.maxDate )

			return res.json({
				maxDate: dayjs( dateInfo.maxDate ).format( 'MM/DD/YYYY' ),
				source: `(${dateInfo.source})`,
				totalAssets: formatter.format( totalAssets.totalAssets ),
				totalROA: parseFloat( roaAndNim.totalROA ).toFixed( 2 )+'%',
				totalNIM: parseFloat( roaAndNim.totalNIM ).toFixed( 2 )+'%'
			})

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers/latestFinancials', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customers/customersMultipleValidDomains', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL 	=  `
				select id, name, validDomains
				from customer_view
				where validDomains like '%.%,%.%'
				or validDomains like '%.% %.%'
				order by name
			`;

			const results = await pool.request().query( SQL );
			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customersMultipleValidDomains', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected database error' );

		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customers/customersRecentlyUpdatedDomains', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL 	=  `
				select
					x.customerID,
					x.name,
					x.updatedDateTime,
					x.updatedBy,
					concat(u.firstName, ' ', u.lastName) as userFullName,
					validDomains
				from (
					select
					id as customerID,
					name,
					lead(name) over(order by name, sysEndDateTime desc) nextName,
					updatedBy,
					updatedDateTime,
					case when validDomains is null then '' else validDomains end as validDomains,
					case when lead(validDomains) over (order by name, sysEndDateTime desc) is null then '' else lead(validDomains) over (order by name, sysEndDateTime desc) end as nextValidDomains,
					sysEndDateTime
					from customer
					for system_time all
				) as x
				left join csuite..users u on (u.id = x.updatedBy)
				where x.name = x.nextName
				and x.validDomains <> nextValidDomains
				and x.sysEndDateTime > dateAdd(d, -30, current_timestamp)
				order by x.name, x.sysEndDateTime desc
			`;

			const results = await pool.request().query( SQL );
			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customersMultipleValidDomains', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected database error' );

		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customers/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL 	=  `select `
						+		`i.name as instName, `
						+		`i.cert as instCert, `
						+		`i.fed_rssd as instRssdId, `
						+		`i.address as instAddress, `
						+		`i.city as instCity, `
						+		`i.stname as instState, `
						+		`i.asset as instAsset, `
						+		`i.dep as instDeposit, `
						+		`i.eq as instEquity, `
						+		`i.dateupdt instLastUpdate, `
						+		`c.validDomains, `
						+		`c.name, `
						+		`c.nickname, `
						+		`case when tz.fullName is not null then tz.fullName else td.fullname end as defaultTimeZone `
						+	`from customer_view c `
						+	`left join fdic.dbo.institutions i on i.cert = c.cert `
						+	`left join timezones tz on tz.id = c.defaultTimezone `
						+	`join timezones td on ( td.[default] = 1 ) `
						+	`where c.id = @customerID `

			const results = await pool.request()
				.input( 'customerID', sql.BigInt, req.params.id )
				.query( SQL )

			if ( results.recordset[0])

			return res.json( results.recordset[0] )

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}


	})
	//====================================================================================


	//====================================================================================
	async function getLatestUpdate( customerID  ) {
	//====================================================================================

		try {

			let SQL 	=	`select `
						+		`[reporting period] as maxDate, `
						+		`source `
						+	`from fdic_ratios.dbo.SummaryRatios r `
						+	`join customer c on (c.rssdID = r.[ID RSSD]) `
						+	`where r.[reporting period] = (  `
						+		`select max([reporting period]) `
						+		`from fdic_ratios.dbo.SummaryRatios r1 `
						+		`join customer c1 on (c1.rssdID = r1.[ID RSSD]) `
						+		`and c1.id = @customerID `
						+	`) `
						+	`and c.id = @customerID `

			const results = await pool.request()
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL )

			return results.recordset[0]

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers', message: err })
			throw new Error( err )

		}


	}
	//====================================================================================


	//====================================================================================
	async function getTotalAssets( customerID, maxDate  ) {
	//====================================================================================

		try {

			let SQL 	=	`
				SELECT UBPR2170 as totalAssets
				FROM fdic_ratios.dbo.BalanceSheetDollar r
				JOIN customer c ON ( c.rssdID = r.[ID RSSD] )
				where cast([reporting period] as date) = @maxDate
				and c.id = @customerID;
			`;

			let results = await pool.request()
					.input( 'maxDate', sql.Date, dayjs( maxDate ).startOf('day').toDate() )
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL );

			return results.recordset[0];

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers', message: err });
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function getRoaAndNim( customerID, maxDate  ) {
	//====================================================================================

		try {

			let SQL 	=	`select UBPRE013 as totalROA, UBPRE018 as totalNIM `
						+	`from fdic_ratios.dbo.SummaryRatios r `
						+	`join customer c on (c.rssdID = r.[ID RSSD]) `
						+	`where cast([reporting period] as date) = @maxDate `
						+	`and c.id = @customerID`

			const results = await pool.request()
					.input( 'maxDate', sql.Date, dayjs( maxDate ).startOf('day').toDate() )
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL )

			return results.recordset[0]

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.customers', message: err })
			throw new Error( err )

		}


	}
	//====================================================================================


	//====================================================================================
	https.put('/api/customers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const optOutOfMCCCalls = req.body.optOutOfMCCCalls === 'true' ? 1 : 0

			let SQL 	=	`update customer set `
						+		`name = @name, `
						+		`nickname = @nickname, `
						+		`customerStatusID = @statusID, `
						+		`validDomains = @validDomains, `
						+		`lsvtCustomerName = @lsvtCustomerName, `
						+		`cProfitURI = @cProfitURI, `
						+		`cProfitAPIKey = @cProfitAPIKey, `
						+		`updatedBy = @updatedBy, `
						+		`updatedDateTime = CURRENT_TIMESTAMP, `
						+		`optOutOfMCCCalls = @optOutOfMCCCalls, `
						+		`defaultTimezone = @defaultTimezone, `
						+		`secretShopperLocationName = @secretShopperLocationName `
						+	`where id = @customerID `

			const results = await pool.request()
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
					.input( 'defaultTimezone',sql.BigInt, req.body.defaultTimezone )
					.input( 'secretShopperLocationName', req.body.secretShopperLocationName )
					.query( SQL )

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

		} catch( err ) {

			logger.log({ level: 'error', label: 'PUT.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/customers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let cert, rssdID

			let SQL 	=	`select cert, fed_rssd `
							+	`from fdic.dbo.institutions `
							+	`where name = @customerName `
							+	`and city = @city `
							+	`and stalp = @state `

			const institution = await pool.request()
				.input( 'customerName', sql.VarChar, req.body.customerName )
				.input( 'city', sql.VarChar, req.body.city )
				.input( 'state', sql.VarChar, req.body.state )
				.query( SQL )

			if ( institution.recordset.length > 0 ) {
				cert = institution.recordset[0].cert
				rssdID = institution.recordset[0].fed_rssd
			} else {
				throw new Error( 'institution not found for customer name' )
			}

			const optOutOfMCCCalls = req.body.optOutOfMCCCalls === 'true' ? 1 : 0
			const defaultTimezone = ( !!req.body.defaultTimezone ) ? req.body.defaultTimezone : null
			const customerID = await utilities.GetNextID( 'customer' )

			SQL 	=	`insert into customer ( `
					+		`id, `
					+		`cert, `
					+		`rssdID, `
					+		`name, `
					+		`customerStatusID, `
					+		`nickname, `
					+		`validDomains, `
					+		`updatedBy, `
					+		`updatedDateTime, `
					+		`optOutOfMCCCalls, `
					+		`defaultTimezone `
					+	`) values ( `
					+		`@id, `
					+		`@cert, `
					+		`@rssdID, `
					+		`@name, `
					+		`@statusID, `
					+		`@nickname, `
					+		`@validDomains, `
					+		`@updatedBy, `
					+		`CURRENT_TIMESTAMP, `
					+		`@optOutOfMCCCalls, `
					+		`@defaultTimezone `
					+	`) `

			const results = await  pool.request()
				.input( 'id', sql.BigInt, customerID )
				.input( 'cert', sql.VarChar, cert )
				.input( 'rssdID', sql.VarChar, rssdID )
				.input( 'name', sql.VarChar, req.body.customerName )
				.input( 'nickname', sql.VarChar, req.body.nickname )
				.input( 'statusID', sql.BigInt, req.body.statusID )
				.input( 'validDomains', sql.VarChar, req.body.validDomains )
				.input( 'updatedBy', sql.BigInt, req.session.userID )
				.input( 'optOutOfMCCCalls', optOutOfMCCCalls )
				.input( 'defaultTimezone', sql.BigInt, defaultTimezone )
				.query( SQL )

			if ( results.rowsAffected > 0 ) {

				try {

					console.log( `launching interim load for customer ${customerID}` )
					const { spawn } = require( 'child_process' )
					// const interimLoad = spawn( 'interimLoad.bat', [ customerID ], { detached: true } )
					const interimLoad = spawn( 'cmd.exe', [ '/c', 'interimLoad.bat', customerID ], { detached: true } )




					interimLoad.stdout.on( 'data', ( data ) => {
						console.log( `interim load stdout: ${data}` )
					})
					interimLoad.stderr.on( 'data', ( data ) => {
						console.log( `interim load stderr: ${data}` )
					})
					interimLoad.on( 'exit', ( code ) => {
						console.log( `interim load exited with code ${code}` )
					})

				} catch( err ) {

					console.error( 'error encountered while spawning detached process for a new customer' )
					console.error( err )

				}

			} else {
				throw new error( 'Unexpected error while inserting new customer' )
			}

			return res.sendStatus( 200 )


		} catch( err ) {

			logger.log({ level: 'error', label: 'POST.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/customers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.body.customerID ) return res.status( 400 ).send( 'Parameter missing' )

			const SQL = `update customer set deleted = 1 where id @customerID `

			const results = await pool.request()
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.query( SQL )

			if ( results.rowsAffected > 0 ) {
				return res.sendStatus( 200 )
			} else {
				throw new Error( 'Unexpected error while deleted customer' )
			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'DELETE.customers', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


}
