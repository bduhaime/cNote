// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get( '/api/users', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	= `select `
					+		`u.id, `
					+		`u.username, `
					+		`u.firstName, `
					+		`u.lastName, `
					+		`u.title, `
					+		`u.active, `
					+		`case when i.customerID is not null then 1 else 0 end as isInternal, `
					+		`case when x.customerID is not null then 1 else 0 end as isExternal, `
					+		`cc.customerContactID, `
					+		`cc.customerContactName, `
					+		`cc.customerContactCompanyName `
					+	`from csuite..users u `
					+	`left join ( `
					+		`select userID, customerID `
					+		`from userCustomers uc `
					+		`where uc.customerID = 1 `
					+	`) as i on ( i.userID = u.id ) `
					+	`left join ( `
					+		`select userID, customerID `
					+		`from userCustomers uc `
					+		`where uc.customerID <> 1 `
					+	`) as x on ( x.userID = u.id ) `
					+	`left join ( `
					+		`select cc.id as customerContactID , cc.name as customerContactName, c.name as customerContactCompanyName, cc.email `
					+		`from customerContacts cc `
					+		`left join customer c on ( c.id = cc.customerID ) `
					+	`) as cc on ( cc.email = u.username ) `
					+	`where exists ( `
					+		`select * `
					+		`from csuite..clientUsers cu `
					+		`where cu.userID = u.id `
					+		`and cu.clientID = @clientID `
					+	`) `
					+	`order by u.username `

		sql.connect(dbConfig).then( pool => {
			return pool.request()
			.input( 'clientID', sql.BigInt, req.session.clientNbr )
			.query( SQL )
		}).then( result => {
			res.json( result.recordset )
		}).catch( err => {
			logger.log({ level: 'error', label: 'GET:/api/users', message: err, user: req.session.userID })
			return res.status( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/users/resetPassword', async (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: '/api/users/resetPassword', message: 'resetPassword starting...', user: 'system' })

		if ( !req.body.email ) return res.status( 400 ).send( 'email parameter missing' )

		try {
			debugger
			let newPassword = await UpdateUserPassword( req.body.email )
			await SendPasswordToUser( newPassword, req.body.email )

			logger.log({ level: 'info', label: '/api/users/resetPassword', message: 'Password reset for ' + req.body.email, user: 'system' })
			return res.sendStatus(200)

		} catch( err ) {

			logger.log({ level: 'error', label: '/api/users/resetPassword', message: 'Error while resetting password for ' + req.body.email + ': ' + err, user: 'system' })
			return res.sendStatus( err )

		}

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/users/activityLog', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	=	"insert into userActivity ( "
					+		"activityDateTime, "
					+		"userID, "
					+		"activityDescription, "
					+		"remoteAddr, "
					+		"scriptName, "
					+		"customerID "
					+	") values ( "
					+		"CURRENT_TIMESTAMP, "
					+		"@userID, "
					+		"@activityDescription, "
					+		"@remoteAddr, "
					+		"@scriptName, "
					+		"@customerID "
					+	") "

		sql.connect(dbConfig).then( pool => {
			return pool.request()
			.input( 'userID', sql.BigInt, req.session.userID )
			.input( 'activityDescription', sql.VarChar, req.body.activityDescription )
			.input( 'remoteAddr', sql.VarChar, req.ip.substring( req.ip.lastIndexOf(':')+1, req.ip.length ) )
			.input( 'scriptName', sql.VarChar, req.body.scriptName )
			.input( 'customerID', sql.BigInt, req.body.customerID ? req.body.customerID : null )
			.query( SQL )
		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'POST:api/users/activityLog', message: err, user: req.session.userID })
			return res.status( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/editUser', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: '/api/editUser', message: 'editUser starting...', user: req.session.userID })

		if ( !req.body.username ) return res.status( 400 ).send( 'username parameter missing' )
		if ( !req.body.firstName ) return res.status( 400 ).send( 'firstName parameter missing' )
		if ( !req.body.lastName ) return res.status( 400 ).send( 'lastName parameter missing' )

		try {

			let emailServer = await utilities.SystemControls( 'server name' )
			let newUserInfo = await SaveUser( req )
			await SaveClientUser( newUserInfo )
			await SaveUserCustomer( newUserInfo )
			await SendNewUserEmail( emailServer, newUserInfo )

			// return 201 to indicate the POST was successful
			return res.status( 201 ).send( 'User created' )

		} catch( err ) {

			await cleanupErrantUser( newUserInfo.userID )

			logger.log({ level: 'error', label: '/api/editUser', message: { text: 'error saving user', err: err }, user: req.session.userID })
			return res.status( 500 ).send( 'Error saving user' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/users/profile/togglePageFooter', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	=	`update csuite..users set `
					+		`showFooter = showFooter ^ 1 `
					+	`where id = @userID `

		sql.connect(dbConfig).then( pool => {
			return pool.request()
			.input( 'userID', sql.BigInt, req.session.userID )
			.query( SQL )
		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/users/profile/pageFooter', message: err, user: req.session.userID })
			return res.status( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/users/profile/menuOption', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.menuOption ) return res.status( 400 ).send( 'Menu option parameter missing' )

		let SQL	=	`update csuite..users set `
					+		`newMenuStyle = @menuOption `
					+	`where id = @userID `

		sql.connect(dbConfig).then( pool => {
			return pool.request()
			.input( 'userID', sql.BigInt, req.session.userID )
			.input( 'menuOption', sql.BigInt, req.body.menuOption )
			.query( SQL )
		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/users/profile/menuOption', message: err, user: req.session.userID })
			return res.status( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/users/profile/toggleClassicCustomerMenu', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	=	`update csuite..users set `
					+		`showClassicCustomerMenu = showClassicCustomerMenu ^ 1 `
					+	`where id = @userID `

		sql.connect(dbConfig).then( pool => {
			return pool.request()
			.input( 'userID', sql.BigInt, req.session.userID )
			.query( SQL )
		}).then( result => {
			return res.sendStatus( 200 )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/users/profile/ClassicCustomerMenu', message: err, user: req.session.userID })
			return res.status( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/users/profile/CustomerMenuOptions', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	=	`select `
					+		`showFooter, `
					+		`showClassicCustomerMenu, `
					+		`newMenuStyle `
					+	`from csuite..users `
					+	`where id = @userID `

		sql.connect(dbConfig).then( pool => {
			return pool.request()
			.input( 'userID', sql.BigInt, req.session.userID )
			.query( SQL )
		}).then( result => {
			res.json( result.recordset[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'PUT:api/users/profile/toggleClassicCustomerMenu/:userID', message: err, user: req.session.userID })
			return res.status( 500 )
		})

	})
	//====================================================================================


	//====================================================================================
	function SaveUser( req ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: '/api/editUser/SaveUser()', message: 'SaveUser starting...', user: req.session.username })

			var tempPassword = generator.generate({
				length: 36,
				numbers: true,
				symbols: true,
				lowercase: true,
				uppercase: true,
				excludeSimilarCharacters: true,
				strict: false
			})

			var hashedPassword = md5( tempPassword )

			let SQL 	= 	'insert into cSuite..users ( '
						+		'username, '
						+		'passwordHash, '
						+ 		'firstName, '
						+		'lastName, '
						+		'active, '
						+		'resetPasswordOnLogin, '
						+		'title, '
						+		'updatedBy, '
						+		'updatedDateTime '
						+	') values ( '
						+		'@username, '
						+		'@tempPasswordHash, '
						+		'@firstName, '
						+		'@lastName, '
						+		'@active, '
						+		'@resetPasswordOnLogin, '
						+		'@title, '
						+		'@updatedBy, '
						+		'CURRENT_TIMESTAMP '
						+	'); '
						+	'SELECT SCOPE_IDENTITY() AS id;'

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'username', sql.VarChar, req.body.username )
					.input( 'firstName', sql.VarChar, req.body.firstName )
					.input( 'lastName', sql.VarChar, req.body.lastName )
					.input( 'active', sql.Bit, 1 )
					.input( 'resetPasswordOnLogin', sql.Bit, 1 )
					.input( 'title', sql.VarChar, req.body.title )
					.input( 'tempPasswordHash', sql.VarChar, hashedPassword )
					.input( 'updatedBy', sql.BigInt, req.session.userID )
					.query( SQL )

			}).then( result => {

				newUserInfo ={
					userID: result.recordset[0].id,
					userName: req.body.username,
					tempPassword: tempPassword,
					clientNbr: req.session.clientNbr,
					updatedBy: req.session.userID,
					customerID: req.body.customerID
				}

				logger.log({ level: 'debug', label: '/api/editUser/SaveUser()', message: 'user saved to users table', user: req.session.userID })
				return resolve( newUserInfo )

			}).catch( err => {

				logger.log({ level: 'error', label: '/api/editUser/SaveUser()', message: err, user: req.session.userID })
				return reject( err )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function SaveClientUser( newUserInfo ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	= 	'insert into cSuite..clientUsers ( '
						+		'clientID, '
						+		'userID, '
						+		'updatedBy, '
						+		'updatedDateTime '
						+	') values ( '
						+		'@clientNbr, '
						+		'@userID, '
						+		'@updatedBy, '
						+		'CURRENT_TIMESTAMP '
						+	') '

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'clientNbr', sql.BigInt, newUserInfo.clientNbr )
					.input( 'userID', sql.BigInt, newUserInfo.userID )
					.input( 'updatedBy', sql.BigInt, newUserInfo.updatedBy )
					.query( SQL )

			}).then( results => {

				logger.log({
					level: 'debug',
					label: 'controllers/index.js - SaveClientUser',
					message: 'user saved to clientUsers',
					user: newUserInfo.addedBy
				})

				logger.log({ level: 'debug', label: '/api/editUser/SaveClientUser()', message: 'user saved to clientUsers table', user: newUserInfo.updatedBy })
				return resolve( newUserInfo )

			}).catch( err => {

				logger.log({ level: 'error', label: '/api/editUser/SaveClientUser()', message: err, user: newUserInfo.updatedBy })
				return reject( err )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function SaveUserCustomer( newUserInfo ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let requestUserCust = new sql.Request( pool )

			let SQL 	=	'insert into userCustomers ( '
						+		'userID, '
						+		'customerID, '
						+		'updatedBy, '
						+		'updatedDateTime '
						+	') values ( '
						+		'@userID, '
						+		'@customerID, '
						+		'@updatedBy, '
						+		'CURRENT_TIMESTAMP '
						+	') '

			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'userID', sql.BigInt, newUserInfo.userID )
					.input( 'customerID', sql.BigInt, newUserInfo.customerID )
					.input( 'updatedBy', sql.BigInt, newUserInfo.updatedBy )
					.query( SQL )

			}).then( results => {

				logger.log({
					level: 'debug',
					label: 'controllers/index.js - SaveUserCustomer',
					message: 'user saved to userCustomers',
					user: newUserInfo.addedBy
				})

				logger.log({ level: 'debug', label: '/api/editUser/SaveUserCustomer()', message: 'user saved to userCustomers table', user: newUserInfo.updatedBy })
				return resolve( newUserInfo )

			}).catch( err => {

				logger.log({ level: 'error', label: '/api/editUser/SaveUserCustomer()', message: err, user: newUserInfo.updatedBy })
				return reject( err )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function cleanupErrantUser( userID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let requestUserCust = new sql.Request( pool )

			let SQL 	=	'delete from cSuite..users where userID = @userID; '
						+	'delete from cSuite..clientUsers where userId = @userID; '
						+	'delete from cSuite..clientUsers where userId = @userID; '
						+	'dedlete from userCustomers where userID = @userID; '


			sql.connect(dbConfig).then( pool => {
				return pool.request()
					.input( 'userID', sql.BigInt, userID )
					.query( SQL )

			}).then( results => {

				logger.log({ level: 'debug', label: '/api/editUser/cleanupErrantUser()', message: 'errant user successfully cleaned', user: newUserInfo.updatedBy })
				return resolve()

			}).catch( err => {

				logger.log({ level: 'error', label: '/api/editUser/cleanupErrantUser()', message: err, user: newUserInfo.updatedBy })
				return reject( err )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function SendNewUserEmail( serverName, newUserInfo ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			try {

				logger.log({ level: 'debug', label: '/api/editUser/SendNewUserEmail()', message: 'SendNewUserEmail starting', user: newUserInfo.addedBy })

				let transporter = nodemailer.createTransport({
					host: process.env.CLIENT_EMAIL_HOST,
					port: process.env.CLIENT_EMAIL_PORT,
					secure: false,
					tls: {
						secure: true,
						requireTLS: true,
						rejectUnauthorized: false
					},
					auth: {
						user: process.env.CLIENT_EMAIL_USER,
						pass: process.env.CLIENT_EMAIL_PASS
					},
					debug: false,
					logger: true
				})

				var html = 	'<html>'
							+		'<head>'
							+			'<title></title>'
							+			'<style>'
							+			'</style>'
							+		'</head>'
							+		'<body>'
							+			'Welcome to cNote&trade;!<br><br>'
							+			'A new account has been created for you on cNote&trade;, the Business Optimization Platform. Here is your temporary password:'
							+			'<br><br>'
							+			'<div class="tempPassord">'
							+				newUserInfo.tempPassword
							+			'</div>'
							+			'<br><br>'
							+			'Click <a href="https://' + serverName + '/login.asp">here</a> to login.'
							+			'<br><br>'
							+			'This message was generated at ' + dayjs().format('M/D/YYYY h:ss a') + ' Central Time.'
							+		'</body>'
							+	'</html>'

				var text = 	'Welcome to cNote(tm)!\n\n'
							+	'A new account has been created for you on cNote(tm), the Business Optimization Platform. Here is your temporary password:\n\n'
							+	'\t' + newUserInfo.tempPassword + '\n\n'
							+	'Go to https://' + serverName + '/login.asp to login.\n\n'
							+	'This message was generated at ' + dayjs().format('M/D/YYYY h:ss a') + ' Central Time.'

				var subject = 'cNote: New User Credentials'
				if ( process.env.ENVIRONMENT ) {
					subject += ' ['+process.env.ENVIRONMENT+']'
				}

				logger.log({ level: 'debug', label: '/api/editUser', message: 'new user email sent to: ' + newUserInfo.userName, user: newUserInfo.updatedBy })

				let email = transporter.sendMail({
					from: 'coachesadmin@emmerichgroup.com',
					to: newUserInfo.userName,
					subject: subject,
					text: text,
					html: html
				})

				logger.log({ level: 'debug', label: '/api/editUser/SendNewUserEmail()', message: 'new user email sent', user: newUserInfo.updatedBy })
				return resolve( true )

			} catch( err ) {

				logger.log({ level: 'error', label: '/api/editUser/SendNewUserEmail()', message: err, user: newUserInfo.updatedBy })
				return reject( err )

			}

		})

	}
	//====================================================================================


	//====================================================================================
	function UpdateUserPassword( username ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			var newPassword = generator.generate({
				length: 36,
				numbers: true,
				symbols: true,
				lowercase: true,
				uppercase: true,
				excludeSimilarCharacters: true,
				strict: false
			})

			var passwordHash = md5( newPassword )
			logger.log({ level: 'debug', label: 'UpdateUserPassword()', message: 'username: ' + username + ', password: ' + newPassword + ', hash: ' + passwordHash, user: 'system' })

			// update the user...
			let requestUser = new sql.Request(pool)
			requestUser.input('passwordHash', sql.VarChar, passwordHash)
			requestUser.input('username', sql.VarChar, username)

			requestSQL 	= 	'UPDATE csuite..users SET '
							+ 		'passwordHash = @passwordHash, '
							+		'resetPasswordOnLogin = 1 '
							+ 	'WHERE username = @username '

			requestUser.query(requestSQL, ( err, result ) => {

				if ( err ) reject( err )

				logger.log({ level: 'debug', label: 'UpdateUserPassword()', message: 'User table upated with new password hash', user: 'system' })
				resolve( newPassword )

			})

		})

	}
	//====================================================================================


	//====================================================================================
	function SendPasswordToUser( newPassword, sendTo ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			logger.log({ level: 'debug', label: 'SendPasswordToUser()', message: 'defining email transporter...', user: 'system' })

			try {
				debugger
				let transporter = nodemailer.createTransport({
					host: process.env.CLIENT_EMAIL_HOST,
					port: process.env.CLIENT_EMAIL_PORT,
					secure: false,
					tls: {
						secure: true,
						requireTLS: true,
						rejectUnauthorized: false,
						debug: true,
						logger: true
					},
					auth: {
						user: process.env.CLIENT_EMAIL_USER,
						pass: process.env.CLIENT_EMAIL_PASS
					}
				})

				var subject = 'cNote Password Reset'
				if ( process.env.ENVIRONMENT ) {
					subject += ' ['+process.env.ENVIRONMENT+']'
				}

				let email = transporter.sendMail({
					from: 'coachesadmin@emmerichgroup.com',
					to: sendTo,
					subject: subject,
					text: 'Here is the temporary password you requested:\n\n\t' + newPassword
				})

				 return resolve('Email sent')

			} catch( err ) {

				logger.log({ level: 'error', label: 'SendPasswordToUser()', message: err, user: 'system' })
				return reject()

			}

		})

	}
	//====================================================================================


}
