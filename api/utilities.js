// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

const path = require( 'path' );
const fs = require( 'fs' );

// Uses global.dayjs and global.hd set in index.js
const holidayCache = {};  // Year-based holiday cache shared within this module
const systemControlsCache = {};


// ----------------------------------------------------------------------------------------
function getPublicUSHolidaysBetween( start, end ) {
// ----------------------------------------------------------------------------------------

	const startYear = dayjs( start ).year();
	const endYear = dayjs( end ).year();
	const blockedTypes = [ 'public', 'bank' ];
	const holidaySet = new Set();

	for ( let year = startYear; year <= endYear; year++ ) {

		if ( !holidayCache[year] ) {

			holidayCache[year] = global.hd.getHolidays( year )
				.filter( h => blockedTypes.includes( h.type ) )
				.map( h => dayjs( h.date ).format('YYYY-MM-DD') ); // normalize to match input date

		}

		for ( const date of holidayCache[year] ) {
			holidaySet.add( date );
		}

	}

	return holidaySet;

}
// ----------------------------------------------------------------------------------------



module.exports = {

	//====================================================================================
	isUserDomainValid: async function( username, customerID, client ) {
	//====================================================================================

		try {

			if ( !username ) return reject( 'username parameter missing' )

			const userDomain = username.split('@').pop()

			if ( !userDomain ) return false

			// else there is a userDomain...
			if ( customerID ) {

				let SQL
				if ( client.toLowerCase() === 'csuite' ) {
					SQL 	= 	`select count(*) as userDomainCount `
							+	`from csuite..clients `
							+	`where databaseName = '${client}' `
							+	`and validDomains like '%${userdomain}%' `
				} else {
					SQL 	= 	`select count(*) as userDomainCount `
							+	`from ${client}..customer `
							+	`where id = ${customerID} `
							+	`and validDomains like '%${userDomain}%' `
				}

				const results = await pool.request().query( SQL )

				if ( results.recordset[0].userDomainCount > 0 ) {
					return true
				} else {
					return false
				}

			} else {

				if ( client.toLowerCase() === 'csuite' ) {
					// since there is no customer table in 'csuite,' any domain is valid
					return true
				} else {
					// since there is no customerID, the domain cannot be validated, so return false
					return false
				}

			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.isUserDomainValid()', message: err, user: null })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	getUserInfo: async function( userID ) {
	//====================================================================================

		try {

			const SQL = `
				select firstName, lastName
				from csuite..users
				where id = @userID;
			`;

			const results = await pool.request()
				.input( 'userID', sql.BigInt, userID )
				.query( SQL );

			return results.recordset[0];

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.getUserInfo()', message: err, user: null });
			throw err;

		}

	},
	//====================================================================================


	//====================================================================================
	usersWithPermission: async function( permimssionID ) {
	//====================================================================================

		try {

			let userList = [];

			if ( !permimssionID ) {
				logger.log({ level: 'error', label: 'utilities.usersWithPermission()', message: 'No permimssionID parameter present in utilities.usersWithPermission()', user: null });
				throw new Error( 'No permimssionID parameter present in utilities.usersWithPermission()' );
			}

			const SQL =	`
				select u.id, u.username
				from cSuite..permissions p
				join userPermissions up on (up.permissionID = p.id and p.id = @permissionID)
				join cSuite..users u on (u.id = up.userID)
				union
				select u.id, u.username
				from cSuite..permissions p
				join rolePermissions rp on (rp.permissionID = p.id and p.id = @permissionID)
				join roles r on (r.id = rp.roleID)
				join userRoles ur on (ur.roleID = r.id)
				join cSuite..users u on (u.id = ur.userID);
			`;

			const results = await pool.request()
				.input( 'permissionID', sql.BigInt, permimssionID )
				.query( SQL );

			for ( row of results.recordset ) {
				userList.push( row.username.trim() );
			}

			return userList;

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.usersWithPermission()', message: err, user: null });
			throw err;

		}

	},
	//====================================================================================


	//====================================================================================
	validateDate: function (date, format) {
	//====================================================================================

		if ( dayjs( date ).isValid() ) {
			return dayjs(date, format).format(format) === date
		} else {
			return false
		}

	},
	//====================================================================================


	//====================================================================================
	date2GoogleDate: function( inputDate ) {
	//====================================================================================

		const strYear 	= dayjs( inputDate ).year()
		const strMonth	= dayjs( inputDate ).month()
		const strDate	= dayjs( inputDate ).date()

		return 'Date(' + strYear + ',' + strMonth + ',' + strDate + ')'

	},
	//====================================================================================


	//====================================================================================
	UserPermitted: async function( userID, permissionID ) {
	//====================================================================================
	// this function calls an MS SQL stored procedure to determine if userID
	// has been granted access to a permissionID (permissionIDs represent a
	// feature, function, or resource).
	//
	// the stored procedure returns a boolean 1 (truthy) or 0 (falsey).
	//====================================================================================

		try {

			let SQL = "select dbo.userPermitted( @userID, @permissionID ) as userPermitted "

			const results = await pool.request()
				.input('userID', sql.BigInt, userID)
				.input('permissionID', sql.BigInt, permissionID)
				.query( SQL )

			if ( results.recordset[0].userPermitted ) {
				return true
			} else {
				return false
			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.usersWithPermission()', message: err, user: null })
			throw err
		}

	},
	//====================================================================================


	//====================================================================================
	jwtVerify: function ( req, res, next ) {
	//====================================================================================
	// this function looks for a JWT token in the authorization header of a request.
	//
	// if a token is found, it is decrypted and the contents are inserted into the
	// request object for easy access by other modules.
	//====================================================================================

		try {

			var ip = req.headers['x-forwarded-for'] ||
			     req.connection.remoteAddress ||
			     req.socket.remoteAddress ||
			     (req.connection.socket ? req.connection.socket.remoteAddress : null)

	  		// bypass authentication on the DEVELOPMENT server/environment for PostMan requests only...
			if (  [ 'banks.bill.local', 'bill' ].includes( req.hostname ) && process.env.ENVIRONMENT == 'DEVELOPMENT' && req.headers["user-agent"].startsWith( 'PostmanRuntime' ) ) {

				logger.log({ level: 'warn', label: 'utilities.jwtVerify', message: 'JWT authentication bybassed for Postman requests on DEVL platform, ip: '+ip, user: 'system' })
				req.session = {
					userID: 1,
					username: 'brad@sqware1.com',
					dbName: 'demo',
					clientNbr: 2,
					internalUser: 1,
					exp: null
				}

				next()

			} else {

				const authHeader = req.headers[ 'authorization' ]
				const token = authHeader && authHeader.split( ' ' )[ 1 ]

				// logger.log({
				//   level: 'debug',
				//   label: 'utilities.jwtVerify',
				//   message: 'Auth header present: ' + !!req.headers.authorization +
				// 			  ', token length: ' + ( token ? token.length : 0 ) +
				// 			  ', parts: ' + ( token ? token.split( '.' ).length : 0 )
				// });

				if ( token == null ) {																					// check if a token has been set...
					logger.log({ level: 'error', label: 'utilities.jwtVerify', message: 'No token present' })
					throw new Error( 'No token present' )
				} else {

//					jwt.verify( token, 'secretkey', { alg: 'HS256' }, ( err, sessionInfo ) => {		// attempt to decrypt
					jwt.verify( token, 'secretkey', { algorithms: [ 'HS256' ] }, ( err, sessionInfo ) => {

						if ( err ) {																						// decryption failed
							logger.log({ level: 'error', label: 'utilities.jwtVerify', message: 'Error decrypting token' })
							logger.log({ level: 'error', label: 'utilities.jwtVerify', message: 'JWT verify failed: ' + err.message });
							throw new Error( 'Decryption error: ' + err )
						}  else {																							// decryption successful
							if ( dayjs().isAfter( dayjs.unix( sessionInfo.exp ) ) ) {						// check if token expired
								logger.log({ level: 'error', label: 'utilities.jwtVerify', message: 'Token expired' })
								throw new Error( 'Token expired' )
							} else {
								// logger.log({ level: 'debug', label: 'utilities.jwtVerify', message: 'Token valid', user: sessionInfo.userID })
								req.session = sessionInfo																// token is valid

								next()

							}
						}
					})

				}

			}

			utilities.LogUserActivity( req )

		} catch ( err ) {

			logger.log({
				level: 'error',
				label: 'utilities.jwtVerify',
				message: JSON.stringify({
					msg: err,
					referer: req.headers.referer,
					originalUrl: req.originalUrl
				})
			})
			res.sendStatus( 401 )

		}


	},
	//====================================================================================


	//====================================================================================
	LogUserActivity: async function( req ) {
	//====================================================================================

		try {

			// NOTE: id and activityDateTime are calculated automatically by the DBMS
			let SQL	= 	`insert into userActivity ( `
						+		`userID, `
						+		`activityDescription, `
						+		`remoteAddr, `
						+		`scriptName, `
						+		`customerID `
						+	`) values ( `
						+		`@userID, `
						+		`@activityDescription, `
						+		`@remoteAddr, `
						+		`@scriptName, `
						+		`@customerID `
						+	`) `

			// extract IP address from req.socket...
			const remoteAddress = req.socket.remoteAddress
			const lastColon = remoteAddress.lastIndexOf( ':' )
			const ipAddress = remoteAddress.substr( lastColon + 1, 15 )

			let customerID = null
			if ( req.query.customerID ) {
				customerID = req.query.customerID
			} else {
				if ( req.body.customerID ) {
					customerID = req.body.customerID
				} else {
					if ( req.route.path.includes( 'customer' ) ) {
						if ( req.query.id ) {
							customerID = req.query.id
						} else {
							if ( req.body.id ) {
								customerID = req.body.id
							}
						}
					}
				}
			}

			const method = req.method.toUpperCase()
			const activityDescription = `${method}: ${req.route.path}`

			const results = await pool.request()
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'activityDescription', sql.VarChar, activityDescription )
				.input( 'remoteAddr', sql.Char, ipAddress )
				.input( 'scriptName', sql.VarChar, req.route.path )
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL )

			if ( results.rowAffected <= 0 ) throw new Error( 'Error inserting user activity log' )

		} catch( err ) {

			logger.log({ level: 'error', label: 'LogUserActivity()', message: err, user: null })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	SystemControls: async function( controlName ) {
	//====================================================================================
	// this function retrieves a value from the systemControls table based upon the
	// controlName passed as a parameter.
	//====================================================================================

		try {

			let SQL = "select [value] from systemControls where [name] = @controlName "

			const results = await pool.request()
				.input('controlName', sql.VarChar, controlName)
				.query( SQL )

			if ( results.recordset.length > 0 ) {
				return results.recordset[0].value
			} else {
				throw new Error ( `${controlName} not found` )
			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.SystemControls', message: err, user: null })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	GetNextID: async function( tableName ) {
	//====================================================================================
	// this function retrieves the highest ID value from a table and returns that
	// value + 1 -- typically used when inserting new rows.
	//====================================================================================

		try {

			const SQL = `select max(id) + 1 as newID from ${tableName} `

			const results = await pool.request().query( SQL )

			return results.recordset[0].newID

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.GetNextID', message: { 'message': 'error in GetNextID', err: err } })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	getMetricObjectives: async function( objectiveID ) {
	//====================================================================================

		try {

			if ( objectiveID ) {

				let SQL	=	`select `
							+		`year(startDate) as startDateYear, `
							+		`month(startDate) as startDateMonth, `
							+		`startValue, `
							+		`year(endDate) as endDateYear, `
							+		`month(endDate) as endDateMonth, `
							+		`endValue `
							+	`from customerObjectives `
							+	`where id = @objectiveID `

				const results = await pool.request()
					.input( 'objectiveID', sql.BigInt, objectiveID )
					.query( SQL )

				if ( results.recordset.length > 0 ) {

					strYear 	= result.recordset[0].startDateYear
					strMonth = result.recordset[0].startDateMonth - 1
					strDate	= 'Date(' + strYear + ',' + strMonth + ',1)'

					endYear 	= result.recordset[0].endDateYear
					endMonth = result.recordset[0].endDateMonth - 1
					endDate	= 'Date(' + endYear + ',' + endMonth + ',1)'

					return {
						startDate: strDate,
						startValue: result.recordset[0].startValue,
						endDate: endDate,
						endValue: result.recordset[0].endValue,
					}

				} else {

					throw new Error( 'objectives not found for this id', objectiveID )

				}

			} else {

				return {}

			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.getMetricObjectives', message: { 'message': 'error in getMetricObjectives', err: err } })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	getObjectiveDetails: async function( objectiveID ) {
	//====================================================================================

		try {

			let SQL = `
				select
					m.id as metricID,
					m.name,
					m.ranksColumnName,
					m.ratiosColumnName,
					m.statsColumnName,
					m.ubprSection,
					m.ubprLine,
					m.financialCtgy,
					m.sourceTableNameRoot,
					m.internalMetricInd,
					m.correspondingAnnualChangeID,
					m.type,
					m.dataType,
					mt.id as metricTypeID,
					mt.name as metricType,
					c.id as customerID,
					c.rssdID,
					o.id as objectiveID,
					o.narrative,
					format( o.startDate, 'yyyy-MM-dd' ) as startDate,
					o.startValue,
					format( o.endDate, 'yyyy-MM-dd' ) as endDate,
					o.endValue,
					o.objectiveTypeID,
					o.peerGroupTypeID,
					o.showAnnualChangeInd,
					trim( replace( replace( replace( o.customName, char(9), '' ), char(10), '' ), char(13), '' ) ) as customName,
					cc.ratiosColumnName as corrAnnualChangeCol,
					cc.sourceTableNameRoot as corrAnnualChangeTbl
				from customerObjectives o
				join metric m on (m.id = o.metricID)
				join metricTypes mt on (mt.id = m.metricTypeID)
				join customerImplementations i on (i.id = o.implementationID)
				join customer c on (c.id = i.customerID)
				left join metric cc on (cc.id = m.correspondingAnnualChangeID)
				where o.id = @objectiveID;
			`;

			const results = await pool.request()
				.input( 'objectiveID', sql.BigInt, objectiveID )
				.query( SQL )

			if ( results.recordset.length > 0 ) {

				return results.recordset[0]

			} else {

				logger.log({ level: 'error', label: 'getObjectiveDetails()', message: 'objectiveID not found, id: ' + objectiveID, user: null })
				throw new Error( 'objectiveID not found' )

			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'getObjectiveDetails()', message: err, user: null })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	getTGIMUActiveUsersCount: async function( customerID ) {
	//====================================================================================

		try {

			let SQL 	= 	"select lsvtCustomerName "
						+	"from customer "
						+	"where id = @customerID "

			const customerResults = await pool.request()
					.input( 'customerID', sql.BigInt, customerID )
					.query( SQL )

			if ( customerResults.recordset[0].lsvtCustomerName ) {

				let utilSQL = 	"select count(*) as userCount "
								+	"from lightspeed..users "
								+	"where locationID in ( "
								+		"select locationID "
								+		"from lightspeed..locations "
								+		"where name like @lsvtCustomerPrefix "
								+	")	"
								+	"and isActive = 1 "

				const userResults = await pool.request()
					.input( 'lsvtCustomerPrefix', sql.VarChar, customerResults.recordset[0].lsvtCustomerName+'%' )
					.query( utilSQL )

				if ( userResults.recordset.length > 0 ) {
					return userResults.recordset[0].userCount
				} else {
					logger.log({ level: 'error', label: 'getActiveUsersCount()', message: err, user: null })
					throw new Error('Error selecting active user count')
				}

			} else {
				return 0
			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'getActiveUsersCount()', message: err, user: null })
			throw err

		}

	},
	//====================================================================================


	//====================================================================================
	filterSpecialCharacters: function( deltaString ) {
	//====================================================================================

		try {

			if ( deltaString ) {

				return deltaString
					.replace( /â€“/g, "\u2013" )			// en dash
					.replace( /Â/g, "\u0020" )				// space, typically a file encoding issue (UTF-8 versus ISO-8859-1)
					.replace( /ï»¿/g, '' )					// Byte Order Mark, typically a file encoding issue (UTF-8 versus ISO-8859-1)
					.replace( /â„¢/g, "\u2122" )			// trademark symbol
					.replace( /\&trade;/g, "\u2122" )	// trademark symbol
					.replace( /\(tm\)/g, "\u2122" )		// trademark symbol
					.replace( /™/g, "\u2122" )				// trademark symbol
					.replace( /™/g, "u2022" )				// trademark symbol
//					.replace( /\\"/g, "\u0022" )			// quotation mark (double-quote) -- this ultimately caused issued with the format of the JSON in deltaString
					.replace( /·/g, "\u2022" )				// bullet point

//					.replace( /an "/g, "an \\u0022" )	// 'an' + space + quotation mark (double-quote) { edge-case from previously entered faulty data }
//						in actual usage the user entered the follow line:
//
//						"Step 2 – Identify the team and create pre-call plan "


			} else {

				return deltaString

			}

		} catch ( err ) {

			logger.log({ level: 'error', label: 'utilities.filterSpecialCharacters', message: err })

			throw new Error( err )

		}

	},
	//====================================================================================


	//====================================================================================
	workDaysBetweenxxx: async function( startDate, endDate ) {
	//====================================================================================

		try {

			let SQL = `select dbo.workDaysBetween( @startDate, @endDate ) `;

			const results = await pool.request()
				.input( 'startDate', sql.Date, startDate )
				.input( 'endDate', sql.Date, endDate )
				.query( SQL);

				let returnValue = results.recordset[0][''] ? results.recordset[0][''] : 0;

				return returnValue;

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.workDaysBetween', message: err });
			throw err;

		}

	},
	//====================================================================================


	//====================================================================================
	workDaysAddxxx: async function( startDate, workDays ) {
	//====================================================================================

// 		try {
//
// 			if ( typeof  workDays === 'string' ) {
// 				workDays = Number( workDays );
// 			}
// 			if ( !Number.isFinite( workDays ) ) {
// 				throw new Error("Invalid BigInt value for workDays: " + workDays );
// 			}
// 			workDays = Math.trunc( workDays );
//
//
//
// 			if (!(startDate && !isNaN(new Date(startDate).getTime()))) {
// 				throw new Error('Invalid or missing startDate');
// 			}
//
// 			// if (!(Number.isInteger(workDays))) {
// 			// 	throw new Error('Invalid or missing workDays (must be an integer)');
// 			// }
//
// 			if ( startDate === 0 ) {
// 				return startDate;
// 			}
//
// 			if ( workDays === 0 ) {
// 				return startDate;
// 			}
//
// 			const isForward = workDays > 0;
// 			const direction = isForward ? '>' : '<';
// 			const order = isForward ? 'asc' : 'desc';
//
// 			// Build the SQL query dynamically
// 			const SQL = `
// 				SELECT ${isForward ? 'MAX' : 'MIN'}(id) AS resultDate
// 				FROM (
// 					SELECT TOP (@workDays) *
// 					FROM dateDimension
// 					WHERE id ${direction} @startDate
// 					AND weekdayInd = 1
// 					AND usaHolidayInd = 0
// 					ORDER BY id ${order}
// 					) x
// 				`;
//
// 			// Execute the query
// 			const results = await pool.request()
// 				.input( 'workDays', sql.BigInt, Math.abs( workDays ) )
// 				.input( 'startDate', sql.Date, startDate )
// 				.query( SQL );
//
// 			const resultDate = results.recordset[0].resultDate;
// 			const returnDate = dayjs( resultDate ).format( 'MM/DD/YYYY' );
//
// 			return returnDate;
//
// 		} catch( err ) {
//
// 			logger.log({ level: 'error', label: 'utilities.workDaysAdd', message: err })
// 			throw err
//
// 		}

		// Step 1: Check if startDate is a workday
		let checkSQL = `
			SELECT COUNT(*) AS isWorkday
			FROM dateDimension
			WHERE id = @startDate
			AND weekdayInd = 1
			AND usaHolidayInd = 0;
		`;

		const checkResult = await pool.request()
			.input( 'startDate', sql.Date, )
			.query( checkSQL );
		let isWorkday = checkResult.recordset[0].isWorkday > 0;

		// Step 2: Determine offset logic
		let direction = workDays > 0 ? 'ASC' : 'DESC'; // Determine forward or backward
		let operator = workDays > 0 ? '>=' : '<='; // Choose >= for future, <= for past
		let offsetValue = isWorkday ? Math.abs(workDays) : Math.abs(workDays) - 1; // Adjust offset correctly

		// Step 3: Fetch the correct workday
		let SQL = `
		SELECT id
			FROM dateDimension
			WHERE id ${operator} @startDate
			AND weekdayInd = 1
			AND usaHolidayInd = 0
			ORDER BY id ${direction}
			OFFSET @offsetValue ROWS
			FETCH NEXT 1 ROWS ONLY;
		`;

		try {

			const result = await pool.request()
				.input( 'offsetValue', sql.Int, offsetValue )
				.query( SQL );

			return result.recordset.length ? result.recordset[0].id : null;

		} catch (err) {

			console.error('Database error:', err);
			throw new Error('Failed to compute workDaysAdd');

		}

	},
	//====================================================================================

	//====================================================================================
	isWorkday: function( inputDate ) {
	//====================================================================================

		if ( inputDate == null ) {
			return false;   // or return null if you want to distinguish "no date"
		}

		const d = dayjs( inputDate );
		if ( !d.isValid() ) {
			throw new Error( `Invalid date passed to isWorkday(): ${inputDate}` );
		}

		const isWeekend = [0, 6].includes( d.day() );
		if ( isWeekend ) return false;

		const holidaySet = getPublicUSHolidaysBetween( d, d );
		return !holidaySet.has( d.format('YYYY-MM-DD') );

	},
	//====================================================================================


	//====================================================================================
	workDaysAddv2: function( startDate, days ) {
	//====================================================================================

		days = parseInt(days, 10);
		if (isNaN(days)) {
			throw new Error(`Invalid days parameter: ${days}`);
		}

		let current = dayjs( startDate );
		let count = 0;

		// Direction: +1 for forward, -1 for backward
		const direction = days >= 0 ? 1 : -1;

		while ( !this.isWorkday( current ) ) {
			current = current.add( direction, 'day' );
		}

		// abs() used to ensure proper loop termination regardless of direction
		while ( Math.abs(count) < Math.abs(days) ) {
			current = current.add( direction, 'day' );
			if ( this.isWorkday( current ) ) {
				count += direction;
			}
			// console.log({ current: current.format('YYYY-MM-DD'), count });
		}

		return current.format( 'YYYY-MM-DD' );

	},
	//====================================================================================


	//====================================================================================
	daysAtRiskv2: async function( startDate, dueDate, completionDate ) {
	//====================================================================================

		try {

			const start = dayjs( startDate );
			const due = dayjs( dueDate );
			const complete = completionDate ? dayjs( completionDate ) : null;
			const now = dayjs();

			// if ( !start.isValid() ) throw new Error( `Invalid startDate in daysAtRiskv2, val: ${startDate}` );
			// if ( !due.isValid() ) throw new Error( `Invalid dueDate in daysAtRiskv2, val: ${dueDate}` );
			// if ( complete && !complete.isValid() ) throw new Error( `Invalid completionDate in daysAtRiskv2, val: ${completionDate}` );
			if ( !start.isValid() ) return null;
			if ( !due.isValid() ) return null;
			if ( complete && !complete.isValid() ) return null;

			const offset = await this.getDaysAtRiskOffset();

			if ( !complete ) {
				if ( now.isBetween( start, due, null, '[]' ) ) {
					return this.workDaysBetweenv2( start, now ) + offset;
				}
				if ( now.isAfter( due ) ) {
					return this.workDaysBetweenv2( start, due ) + offset;
				}
				return 0;
			} else {
				return 0;
			}

		} catch( err ) {
			console.error( 'error in dasAtRiskv2:', err )
			throw new Error( err );
		}

	},
	//====================================================================================


	//====================================================================================
	daysBehindv2: function( dueDate, completionDate ) {
	//====================================================================================

		//
		// the legacy code for days behind typically adds +1 to the result because of the "offset" rule.
		// might need to do that here if this update proved to always be off by 1 day.
		//

		const due = dayjs( dueDate );
		const complete = completionDate ? dayjs( completionDate )  : null;
		const now = dayjs();

		if ( !due.isValid() ) {
			throw new Error( 'Invalid dueDate in daysBehindv2' );
		}

		if ( complete ) {
			if ( !complete.isValid() ) {
				throw new Error( 'Invalid completionDate in daysBehindv2' );
			}
			return complete.isAfter( due )
				? this.workDaysBetweenv2( due, complete )
				: '';
		} else {
			return due.isBefore( now )
				? this.workDaysBetweenv2( due, now )
				: '';
		}

	},
	//====================================================================================


	//====================================================================================
	estimatedDaysv2: function( startDate, dueDate ) {
	//====================================================================================

		//
		// the legacy code for days behind typically adds +1 to the result because of the "offset" rule.
		// might need to do that here if this update proved to always be off by 1 day.
		//

		if ( !startDate || !dueDate ) {
			return '';
		}

		const start = dayjs( startDate );
		const due = dayjs( dueDate );

		if ( !start.isValid() ) {
			throw new Error( 'Invalid startDate in estimatedDaysv2' );
		}
		if ( !due.isValid() ) {
			throw new Error( 'Invalid dueDate in estimatedDaysv2' );
		}

		return this.workDaysBetweenv2( start, due );

	},
	//====================================================================================


	//====================================================================================
	workDaysBetweenv2: function( startDate, endDate ) {
	//====================================================================================

		const start = dayjs( startDate );
		const end = dayjs( endDate );

		if ( !start.isValid() || !end.isValid() || end.isBefore( start ) ) return 0;

		const totalDays = end.diff( start, 'day' ) + 1;
		const weeks = Math.floor( totalDays / 7 );
		const remainingDays = totalDays % 7;
		let workdays = weeks * 5;

		// Count weekdays in the remaining partial week
		for ( let i = 0; i < remainingDays; i++ ) {
			const d = start.add( i + (weeks * 7), 'day' );
			const day = d.day();
			if ( day !== 0 && day !== 6 ) workdays++;
		}

		// Subtract public holidays
		const holidaySet = getPublicUSHolidaysBetween( start, end );
		for ( let d = dayjs( start ); d.isSameOrBefore( end ); d = d.add( 1, 'day' ) ) {
			if ( d.day() !== 0 && d.day() !== 6 && holidaySet.has( d.format('YYYY-MM-DD') ) ) {
				workdays--;
			}
		}

		return workdays;
	},
	//====================================================================================


	//====================================================================================
	workDaysSummary: function( startDate, dueDate, completionDate ) {
	//====================================================================================

		//
		// Returns a consistent summary of work day deltas:
		// {
		//   actualDays: number | '',
		//   daysAhead: number | '',
		//   daysBehind: number | '',
		//   daysAtRisk: number | '',
		//   estimatedDays: number | ''
		// }
		//
		// usage for specific value(s): const { daysBehind } = utilities.daysSummary( start, due, complete );
		//

		let actualDays = 0;
		let daysAhead = 0;
		let daysBehind = 0;
		let daysAtRisk = 0;
		let estimatedDays = 0;

		const start     = startDate ? dayjs( startDate ).local() : null;
		const due       = dueDate ? dayjs( dueDate ).local() : null;
		const complete  = completionDate ? dayjs( completionDate ).local() : null;

		// const start 		= startDate ? dayjs( startDate ) : null;
		// const due 			= dueDate ? dayjs( dueDate ) : null;
		// const complete 	= completionDate ? dayjs( completionDate ) : null;
		const now 			= dayjs();

		if ( start && !start.isValid() ) throw new Error( 'Invalid startDate in daysSummary' );
		if ( due && !due.isValid() ) throw new Error( 'Invalid dueDate in daysSummary' );
		if ( complete && !complete.isValid() ) throw new Error( 'Invalid completionDate in daysSummary' );

		if ( start && complete ) {
			actualDays = this.workDaysBetweenv2( start, complete );
		}

		if ( complete && due ) {
			if ( complete.isBefore( due ) ) {
				daysAhead = this.workDaysBetweenv2( complete, due );
			}
		}

		if ( complete ) {
			if ( complete.isAfter( due ) ) {
				daysBehind = this.workDaysBetweenv2( due, complete );
			}
		} else {
			if ( due.isBefore( now ) ) {
				daysBehind = this.workDaysBetweenv2( due, now );
			}
		}



		if ( start && due && !complete ) {
			if ( now.isBetween( start, due, null, '[]' ) ) {
				daysAtRisk = this.workDaysBetweenv2( start, now );
			} else if ( now.isAfter( due ) ) {
				daysAtRisk = this.workDaysBetweenv2( start, due );
			}
		}

		if ( start && due ) {
			estimatedDays = this.workDaysBetweenv2( start, due );
		}

		return {
			actualDays,
			daysAhead,
			daysBehind,
			daysAtRisk,
			estimatedDays
		};
	},
	//====================================================================================


	//====================================================================================
	getDaysAtRiskOffset: async function() {
	//====================================================================================

		if ( systemControlsCache.daysAtRiskOffset !== undefined ) {
			return systemControlsCache.daysAtRiskOffset;
		}

		const sql = require( 'mssql' );
		const pool = await sql.connect( dbConfig );

		const result = await pool.request()
			.input( 'name', sql.NVarChar, 'Work days at risk offset' )
			.query(`
				SELECT [value]
				FROM systemControls
				WHERE [name] = @name
			`);

		if ( result.recordset.length === 0 ) {
			throw new Error( 'Work days at risk offset not found in systemControls' );
		}

		const offset = Number( result.recordset[0].value );
		systemControlsCache.daysAtRiskOffset = offset;
		return offset;
	},
	//====================================================================================


	//====================================================================================
	invalidateDaysAtRiskOffsetCache: function() {
	//====================================================================================

		systemControlsCache.daysAtRiskOffset = undefined;

	},
	//====================================================================================


	//====================================================================================
	loadSQL: function( ...pathSegments ) {
	//====================================================================================

		try {

			const filePath = path.join( __dirname, 'sql', ...pathSegments );
			return fs.readFileSync( filePath, 'utf8' );

		} catch( err ) {

			logger.log({ level: 'error', label: 'utilities.loadSQL()', message: err, user: null });
			throw new Error( err );

		}

	}
	//====================================================================================


}
