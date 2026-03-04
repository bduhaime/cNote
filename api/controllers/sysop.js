// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = async function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const pool = await sql.connect( dbConfig );


	//====================================================================================
	function getCustomerIdFromParms( searchArray, parameterKey ) {
	//====================================================================================

		for ( i = 0; i < searchArray.length; ++i ) {

			let parameter = searchArray[i].split( '=' )
			if ( parameter[0] == parameterKey ) {
				return parameter[1]
				break
			}

		}

		return -1

	}
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/userSelectionList', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )

			let SQL 	= 	"select "
 						+		"id, "
 						+		"concat( firstName, ' ', lastName ) as userName, "
 						+		"dbo.getRelativeTime( activityDateTime ) as lastActivity, "
 						+		"format( activityDateTime, 'M/d/yyyy hh:mm tt' ) as activityDateTime "
 						+	"from ( "
 						+		"SELECT u.id, u.firstName, u.lastName, MAX ( a.activityDateTime ) AS activityDateTime "
 						+		"FROM userActivity a "
 						+		"JOIN csuite..users u ON ( u.id = a.userID ) "
						+		"WHERE format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate "
 						+		"GROUP BY u.id, u.firstName, u.lastName "
 						+	") as x "
 						+	"ORDER BY 2 "

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			let users = []
			for ( user of results.recordset ) {
				users.push({
					id: user.id,
					userName: user.userName,
					lastActivity: dayjs( user.activityDateTime, 'M/D/YYYY HH:mm A' ).fromNow(),
					activityDateTime: user.activityDateTime
				})
			}

			return res.json( users )

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/userSelectionList', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/activityByUser', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const users = req.query.users

			const cols = [
	   		{id: 'lastName', label: 'User', type: 'string' },
				{id: 'activityCount', label: 'Page hits', type: 'number' }
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			var rows = []


			let SQL	= 	`select `
						+		`a.userID, `
						+		`u.firstName, `
						+		`count(*) as activityCount `
						+	`from userActivity a `
						+	`left join csuite..users u on ( u.id = a.userID ) `
						+	`where userID in ( ${userList} ) `
						+	`and format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and scriptName not like '/ajax/%' `
						+	`and scriptName not like '/api/%' `
						+	`group by a.userID, u.firstName `
						+	`order by 1 `

			logger.log({ level: 'debug', label: 'sysop/activityByUser', message: SQL, user: req.session.userID })

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {

				rows.push(
					{c: [
						{ v: item.firstName },
						{ v: item.activityCount }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/activityByUser', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/activityByDate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols = [
	   		{id: 'activityDate', label: 'Date', type: 'date'},
				{id: 'activityCount', label: 'Page hits', type: 'number'}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			var rows = []

			let SQL	= 	`select `
						+		`format( activityDateTime, 'yyyy-MM-dd' ) as activityDate, `
						+		`count(*) as activityCount `
						+	`from userActivity a `
						+	`where userID in ( ${userList} ) `
						+	`and format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and scriptName not like '/ajax/%' `
						+	`and scriptName not like '/api/%' `
						+	`group by format( activityDateTime, 'yyyy-MM-dd' ) `
						+	`order by 1 `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {

				rows.push(
					{c: [
						{ v: utilities.date2GoogleDate( item.activityDate)  },
						{ v: item.activityCount }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })


		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/activityByDate', message: err, user: req.session.userID })
			console.err( err )
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/activityByDayOfWeek', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols = [
	   		{id: 'dayOfWeekNo', label: 'dayOfWeekNo', type: 'number'},
				{id: 'activityCount', label: 'Page Hits', type: 'number'}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			var rows = []

			let SQL	= 	`select `
						+		`d.dayOfWeekNo, `
						+		`count(*) as activityCount `
						+	`from userActivity a `
						+	`left join dateDimension d on ( d.id = convert(date, a.activityDateTime ) ) `
						+	`where userID in ( ${userList} ) `
						+	`and format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and scriptName not like '/ajax/%' `
						+	`and scriptName not like '/api/%' `
						+	`group by d.dayOfWeekNo `
						+	`order by 1 `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {

				rows.push(
					{c: [
						{ v: item.dayOfWeekNo },
						{ v: item.activityCount }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/activityByDayOfWeek', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/activityByTimeOfDay', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols 	= [
	   		{id: 'hourOfDay', label: 'Hour', type: 'number'},
				{id: 'activityCount', label: 'Page hits', type: 'number'}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			let rows = []

			let SQL	= 	`select `
						+		`datepart( hour, activityDateTime ) as hourOfDay, `
						+		`count(*) as activityCount `
						+	`from userActivity `
						+	`where userID in ( ${userList} ) `
						+	`and format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and scriptName not like '/ajax/%' `
						+	`and scriptName not like '/api/%' `
						+ 	`group by datepart( hour, activityDateTime ) `
						+	`order by 1 `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {

				rows.push(
					{c: [
						{ v: item.hourOfDay },
						{ v: item.activityCount }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })


		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/activityByTimeOfDay', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/pageHits', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols = [
				{id: "Page Name", label: "Page Name", type: "string"},
				{id: "Hits", label: "Hits", type: "number"}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			let predicate = ``
			if ( req.query.interstitials === 'false' ) {
				predicate = `and scriptName not in ( '/home.asp', '/login.asp', '/customerList.asp', '/userList.asp', '/roleList.asp', '/permissionList.asp', 'admin.asp' ) `
			}

			var rows = []

			let SQL	=	`select `
						+		`SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', scriptName) > 0 THEN CHARINDEX('?', scriptName)-2 ELSE  LEN(scriptName) END ) as scriptName, `
						+		`count(*) as hits `
						+	`from userActivity `
						+	`where format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and userID in ( ` + userList + ` ) `
						+	`and scriptName not like '/ajax/%' `
						+	`and scriptName not like '/api/%' `
						+	predicate
						+	`group by SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', scriptName) > 0 THEN CHARINDEX('?', scriptName)-2 ELSE  LEN(scriptName) END ) `
						+	`order by 2 desc `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {
				rows.push(
					{c: [
						{ v: item.scriptName },
						{ v: item.hits }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })


		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/pageHits', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/pageHitsDetail', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const days = 30 * -1

			let SQL	=	`select `
						+		`format( a.activityDateTime, 'yyyy-MM-dd HH:mm:ss' ) as activityDateTime, `
						+		`SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', a.scriptName) > 0 THEN CHARINDEX('?', a.scriptName)-2 ELSE  LEN(a.scriptName) END ) as scriptName, `
						+		`a.userID, `
						+		`trim( u.userName ) as userName, `
						+		`concat( u.firstName, '', u.lastName) as userFullName, `
						+		`a.activityDescription `
						+	`from userActivity a `
						+	`left join csuite..users u on (u.id = a.userID) `
						+	`where activityDatetime > DATEADD( day, @days, getdate() ) `
						+	`and scriptName not like '/ajax/%' `
						+	`and scriptName not like '/api/%' `

			const results = await pool.request()
				.input( 'days', sql.BigInt, days )
				.query( SQL )


			return res.json( results.recordset )

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/pageHitsDetail', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/nodeEndPointHits', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols = [
				{id: "Page Name", label: "Page Name", type: "string"},
				{id: "Hits", label: "Hits", type: "number"}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			var rows = []

			let SQL	=	`select `
						+		`SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', scriptName) > 0 THEN CHARINDEX('?', scriptName)-2 ELSE  LEN(scriptName) END ) as scriptName, `
						+		`count(*) as hits `
						+	`from userActivity `
						+	`where format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and userID in ( ${userList} ) `
						+	`and scriptName like '/api/%' `
						+	`group by SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', scriptName) > 0 THEN CHARINDEX('?', scriptName)-2 ELSE  LEN(scriptName) END ) `
						+	`order by 2 desc `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {
				rows.push(
					{c: [
						{ v: item.scriptName },
						{ v: item.hits }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/nodeEndPointHits', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/aspEndPointHits', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols = [
				{id: "Page Name", label: "Page Name", type: "string"},
				{id: "Hits", label: "Hits", type: "number"}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			var rows = []

			let SQL	=	`select `
						+		`SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', scriptName) > 0 THEN CHARINDEX('?', scriptName)-2 ELSE  LEN(scriptName) END ) as scriptName, `
						+		`count(*) as hits `
						+	`from userActivity `
						+	`where format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and userID in ( ${userList} ) `
						+	`and scriptName like '/ajax/%' `
						+	`group by SUBSTRING( scriptName, 2, CASE WHEN CHARINDEX('?', scriptName) > 0 THEN CHARINDEX('?', scriptName)-2 ELSE  LEN(scriptName) END ) `
						+	`order by 2 desc `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {
				rows.push(
					{c: [
						{ v: item.scriptName },
						{ v: item.hits }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/aspEndPointHits', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/aspVsNodeHits', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.users ) return res.status( 400 ).send( 'users parameter missing' )

			const cols = [
				{id: "Type", label: "Type", type: "string"},
				{id: "Hits", label: "Hits", type: "number"}
			]

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			var rows = []

			let SQL	= `select 'ASP' as apiType, count(*) as hits `
						+	`from userActivity `
						+	`where format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and userID in ( ${userList} ) `
						+	`and scriptName like '/ajax/%' `
						+	`UNION `
						+	`select 'Node.js' as apiType, count(*) as hits `
						+	`from userActivity `
						+	`where format( activityDateTime, 'MM/dd/yyyy' ) between @startDate and @endDate `
						+	`and userID in ( ${userList} ) `
						+	`and scriptName like '/api/%' `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( item => {
				rows.push(
					{c: [
						{ v: item.apiType },
						{ v: item.hits }
					]}
				)
			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/aspVsNodeHits', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/dashboardUsage', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )
			if ( !req.query.dashboardScript ) return res.status( 400 ).send( 'dashboardScript parameter missing' )

			let userList = ''
			if ( !req.query.users || req.query.users.length <=0 ) {
				return res.json({ cols: cols, rows: [] })
			} else {
				userList = req.query.users.toString()
			}

			const cols = [
				{ id: 'User', label: 'Type', type: 'string' },
				{ id: 'Hits', label: 'Hits', type: 'number' },
				{ role: 'tooltip', type: 'string', 'p': { 'html': true }}
			]

			var rows = []


			let SQL	= `select `
						+		`u.firstName, `
						+		`count(*) as activityCount, `
						+		`format( max( activityDateTime ), 'M/d/yyyy' ) as lastActivity `
						+	`from userActivity ua `
						+	`left join csuite..users u on ( u.id = ua.userID ) `
						+	`where cast( activityDateTime as date ) between @startDate and @endDate `
						+	`and userID in ( ${userList} ) `
						+	`and scriptName = @dashboard `
						+	`group by u.firstName `
						+	`order by 2 desc `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.input( 'dashboard', sql.VarChar, req.query.dashboardScript )
				.query( SQL )

			results.recordset.forEach( item => {

				tooltip	= 	'<table>'
							+		'<tr><td>Name:</td><td>' + item.firstName + '</td></tr>'
							+		'<tr><td>Count:</td><td>' + item.activityCount + '</td></tr>'
							+		'<tr><td>Most Recent:</td><td>' + item.lastActivity + '</td></tr>'
							+	'</table>'
				// tooltip	= 	'<span>Name:&nbsp;'+item.firstName + '</span><br>'
				// 			+	'<span>Count:&nbsp;' + item.activityCount + '</span><br>'
				// 			+	'<span>Most Recent:&nbsp;' + item.lastActivity + '</span>'

				rows.push(
					{c: [
						{ v: item.firstName },
						{ v: item.activityCount },
						{ v: tooltip }
					]}
				)

			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/dashboardUsage', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/sysop/sessionUsage', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.startDate ) return res.status( 400 ).send( 'start date parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'end date parameter missing' )

			const cols = [
				{ id: 'user', label: 'user', type: 'string' },
				{ id: 'count', label: 'count', type: 'number' },
				{ role: 'tooltip', type: 'string', 'p': { 'html': true }},
				{ id: 'length', label: 'length', type: 'number' },
				{ role: 'tooltip', type: 'string', 'p': { 'html': true }},
			]

			var rows = []


			let SQL	= 	`select `
						+		`userID, `
						+		`firstName, `
						+		`count(*) as sessionCount, `
						+		`avg( sessionLengthSeconds ) as avgSessionLength, `
						+		`format( max( sessionEnd ), 'M/d/yyyy hh:mm tt' ) as mostRecentSession `
						+	`from ( `
						+		`select `
						+			`ua.userID, `
						+			`ua.sessionID, `
						+			`u.firstName, `
						+			`min( ua.activityDateTime ) as sessionStart, `
						+			`max( ua.activityDateTime ) as sessionEnd, `
						+			`DATEDIFF(second, min(activityDateTime) ,max(activityDateTime) ) as sessionLengthSeconds `
						+		`from userActivity ua `
						+		`left join csuite..users u on ( u.id = ua.userID ) `
						+		`where cast( activityDateTime as date) between @startDate and @endDate `
						+		`and ua.sessionID is not null ` 						// sessionID is null when requests are made to the Node.js API
						+		`group by userID, u.firstName, sessionID `
						+	`) x `
						+	`group by userID, firstName `
						+	`order by avgSessionLength desc `

			const results = await pool.request()
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			results.recordset.forEach( row => {

				let tooltip1	= 	'<table>'
									+		'<tr><td>Name:</td><td>' + row.firstName + '</td></tr>'
									+		'<tr><td>Count:</td><td>' + row.sessionCount + '</td></tr>'
									+		'<tr><td>Most Recent:</td><td>' + dayjs( row.mostRecentSession ).fromNow() + '</td></tr>'
									+	'</table>'

				let tooltip2	= 	'<table>'
									+		'<tr><td>Name:</td><td>' + row.firstName + '</td></tr>'
									+		'<tr><td>Average Length:</td><td>' + dayjs.duration( row.avgSessionLength, 'seconds' ).humanize() + '</td></tr>'
									+		'<tr><td>Most Recent:</td><td>' + dayjs( row.mostRecentSession ).fromNow() + '</td></tr>'
									+	'</table>'

				rows.push(
					{c: [
						{ v: row.firstName },
						{ v: row.sessionCount },
						{ v: tooltip1 },
						{ v: row.avgSessionLength },
						{ v: tooltip2 },
					]}
				)

			})

			return res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'sysop/sessionUsage', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


}
