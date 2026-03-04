// ----------------------------------------------------------------------------------------
// Copyright 2017-2022, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/surveys', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let SQL	=	"select "
					+		"s.survey_id as surveyID, "
					+		"s.type, "
					+		"s.title, "
					+		"s.status, "
					+		"s.tegType, "
					+		"s.employeesSurveyed, "
					+		"s.customerID, "
					+		"c.name as customerName "
					+	"from alchemer..surveys s "
					+	"left join customer c on (c.id = s.customerID) "
					+	"order by s.title "

		sql.connect(dbConfig).then( pool => {

			return pool.request().query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/surveys', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.surveyID ) return res.status( 400 ).send( 'surveyID Parameter missing' )
		// if ( !req.body.customerID ) return res.status( 400 ).send( 'customer Parameter missing' )

		let customerID = ( req.body.customerID === '' ) ? null : req.body.customerID
		let employeesSurveyed = ( req.body.employeesSurveyed ) ? req.body.employeesSurveyed : null

		let SQL	=	"update alchemer..surveys set "
					+		"customerID = @customerID, "
					+		"employeesSurveyed = @employeesSurveyed "
					+	"where survey_id = @surveyID "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'surveyID', sql.BigInt, req.body.surveyID )
				.input( 'customerID', sql.BigInt, customerID )
				.input( 'employeesSurveyed', sql.BigInt, employeesSurveyed )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/surveys', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/customers', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const SQL =	`
			select id, name
			from customer
			where (deleted = 0 or deleted is null)
			order by name
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request().query( SQL );

		}).then( result => {

			res.json( result.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/customers', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});


	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/surveys/unassociatedCustomers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================
	//
	// customers without any associated "culture" surveys
		if ( !req.query.statusList ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	=	`select count(*) as unassociatedCustomers `
					+	`from customer c `
					+	`where (c.deleted = 0 or c.deleted is null) `
					+	`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`and not exists ( `
					+		`select * `
					+		`from alchemer.dbo.surveys s `
					+		`where s.customerID = c.id `
					+	`) `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset[0].unassociatedCustomers )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/unassociatedCustomers', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/surveys/unassociatedSurveys', utilities.jwtVerify, async (req, res) => {
	//====================================================================================
	//
	// "culture" surveys without an associated customer
		if ( !req.query.statusList ) return res.status( 400 ).send( 'Parameter missing' )

		let SQL	=	`select count(*) as surveysNoCustomer `
					+	`from alchemer.dbo.surveys s `
					+	`where tegType = 'Culture' `
					+	`and status <> 'Archived' `
					+	`and not exists ( `
					+		`select * `
					+		`from customer c `
					+		`where c.id = s.customerID `
					+		`and (c.deleted = 0 or c.deleted is null) `
					+		`and c.customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
					+	`) `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'statusList', req.query.statusList )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset[0].surveysNoCustomer )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/unassociatedCustomers', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/surveys/participationByCustomer', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing (customerID)' )

		const cols = [
			{ id: "Year", label: "Year", type: "string" },
			{ id: "partial", label: "Partial", type: "number" },
			{ id: "complete", label: "Complete", type: "number" }
		]
		var rows = []



		let SQL	=	`select `
					+		`year(created_on) as surveyYear, `
					+		`JSON_VALUE([statistics], '$.Partial') as partial, `
					+		`JSON_VALUE([statistics], '$.Complete') as complete `
					+	`from alchemer.dbo.surveys s `
					+	`where s.customerID = @customerID `
					+	`and tegType = 'Culture' `
					+	`order by year(created_on) `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			for ( row of result.recordset ) {

				rows.push(
					{c: [
						{ v: row.surveyYear },
						{ v: row.complete },
						{ v: row.partial },
					]}
				)

			}

			res.json({ cols: cols, rows: rows })


		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/unassociatedCustomers', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/resultsByDate', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		const cols = [
	   	{ id: 'surveyDate', label: 'Date', type: 'date' },
			{ id: 'averageScore', label: 'Score', type: 'number' },
			{ type: 'string', role: 'tooltip', p: { 'html': true } }
		]

		var rows = []

		let SQL 	= 	`select `
					+		`s.survey_id, `
					+		`s.title, `
					+		`min( r.date_submitted ) as firstResponseDate, `
					+		`max( r.date_submitted ) as lastResponseDate, `
					+		`avg( r.respondentAverage ) as averageScore `
					+	`from alchemer..surveys s `
					+	`join alchemer..responses r on (r.survey_id = s.survey_id) `
					+	`where customerID = @customerID `
					+	`and r.status = 'complete' `
					+	`and r.is_test_data = 0 `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title  `
					+	`order by min( r.date_submitted ) asc `
					// +	`order by max( s.modified_on ) asc `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			result.recordset.forEach( item => {

				let title = item.title
				let firstSubmission = utilities.date2GoogleDate( dayjs( item.firstResponseDate ).format( 'MM/DD/YYYY' ) )
				let lastSubmission = utilities.date2GoogleDate( dayjs( item.lastResponseDate ).format( 'MM/DD/YYYY' ) )
				let displayValue = parseFloat( item.averageScore ).toFixed( 4 )
				let displayDate = dayjs( item.date_submitted ).format( 'MMM D, YYYY' )

				let tooltip = `<table width="250px">
										<thead><tr><th colspan="2">${title}</th></tr></thead>
										<tbody>
											<tr><td>Average:</td><td>${displayValue}</td></tr>
											<tr><td>First Response:</td><td>${ dayjs( item.firstResponseDate ).format( 'MM/DD/YYYY' ) }</td></tr>
											<tr><td>Last Response:</td><td>${ dayjs( item.lastResponseDate ).format( 'MM/DD/YYYY' ) }</td></tr>
										</tbody>
									</table>`

				rows.push(
					{c: [
						{ v: firstSubmission },
						{ v: displayValue },
						{ v: tooltip }
					]}
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'surveys/resultsByDate', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/resultsByDateLocation', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		var rows = []

		let SQL 	= 	`select `
					+		`s.survey_id, `
					+		`format( min( r.date_submitted ), 'MM/dd/yyyy' ) as firstSubmission, `
					+		`s.title, `
					+		`r.location, `
					+		`avg( r.respondentAverage ) as averageScore `
					+	`from alchemer..surveys s `
					+	`join alchemer..responses r on (r.survey_id = s.survey_id) `
					+	`where customerID = @customerID `
					+	`and r.status = 'complete' `
					+	`and r.is_test_data = 0 `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title, r.location `
					+	`order by min( r.date_submitted ) asc, avg( r.respondentAverage ) desc `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			const cols = [
	   		{ id: 'surveyDate', label: 'Date', type: 'date' },
				{ id: 'location', label: 'Location', type: 'string' },
				{ id: 'averageScore', label: 'Score', type: 'number' },
			]

			result.recordset.forEach( item => {

				rows.push(
					{c: [
						{ v: utilities.date2GoogleDate( item.firstSubmission)  },
						{ v: item.location },
						{ v: item.averageScore },
						{ v: tooltip }
					]}
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'surveys/resultsByDateLocation', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/statsByDate', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		const cols = [
	   	{ id: 'surveyDate', label: 'Date', type: 'date' },
			{ id: 'complete', label: 'Complete', type: 'number' }, { role: 'tooltip', p: { html: true } },
			{ id: 'partial', label: 'Partial', type: 'number' }, { role: 'tooltip', p: { html: true } },
			{ id: 'unresponsive', label: 'Unresponsive', type: 'number' }, { role: 'tooltip', p: { html: true } },
			{ id: 'testData', label: 'Test Data', type: 'number'}, { role: 'tooltip', p: { html: true } },
		]

		var rows = []

		let SQL 	= 	`select `
					+		`s.survey_id, `
					+		`s.title, `
					+		`sum( case when r.is_test_data = 1 then 0 else case when r.status = 'partial' then 1 else 0 end end ) as partialCount, `
					+		`min( case when r.is_test_data = 0 AND r.status = 'partial' THEN r.date_submitted END) AS partialMinDate, `
					+		`max( case when r.is_test_data = 0 AND r.status = 'partial' THEN r.date_submitted END) AS partialMaxDate,`
					+		`sum( case when r.is_test_data = 1 then 0 else case when r.status = 'complete' then 1 else 0 end end  ) as completeCount, `
					+		`min( case when r.is_test_data = 0 AND r.status = 'complete' THEN r.date_submitted END) AS completeMinDate, `
					+		`max( case when r.is_test_data = 0 AND r.status = 'complete' THEN r.date_submitted END) AS completeMaxDate,`
					+		`sum( case when r.is_test_data = 1 then 0 else case when r.status = 'disqualified' then 1 else 0 end end ) as dqCount, `
					+		`min( case when r.is_test_data = 0 AND r.status = 'disqualified' THEN r.date_submitted END) AS dqMinDate, `
					+		`max( case when r.is_test_data = 0 AND r.status = 'disqualified' THEN r.date_submitted END) AS dqMaxDate,`
					+		`sum( case when r.is_test_data = 1 then 1 else 0 end ) as testCount, `
					+		`min( case when r.is_test_data = 1 THEN r.date_submitted END) AS testMinDate,`
					+		`max( case when r.is_test_data = 1 THEN r.date_submitted END) AS testMaxDate,`
					+		`s.employeesSurveyed as employeesSurveyed `
					+	`from alchemer..surveys s `
					+	`left join alchemer..responses r on (r.survey_id = s.survey_id) `
					+	`where s.customerID = @customerID `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title, s.employeesSurveyed `
					+	`order by 8 asc `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			result.recordset.forEach( item => {

				let partialTooltip = `<table width="250px"><thead><tr><th colspan="2">${item.title}</th></tr></thead><tbody><tr><td>Partial Count:</td><td>${item.partialCount}</td></tr><tr><td>First Partial Response:</td><td>${ dayjs( item.partialMinDate ).format( 'MM/DD/YYYY' ) }</td></tr><tr><td>Last Partial Response:</td><td>${ dayjs( item.partialMaxDate ).format( 'MM/DD/YYYY' ) }</td></tr></tbody></table>`
				let completeTooltip = `<table width="250px"><thead><tr><th colspan="2">${item.title}</th></tr></thead><tbody><tr><td>Complete Count:</td><td>${item.completeCount}</td></tr><tr><td>First Complete Response:</td><td>${ dayjs( item.completeMinDate ).format( 'MM/DD/YYYY' ) }</td></tr><tr><td>Last Complete Response:</td><td>${ dayjs( item.completeMaxDate ).format( 'MM/DD/YYYY' ) }</td></tr></tbody></table>`
				let dqTooltip = `<table width="250px"><thead><tr><th colspan="2">${item.title}</th></tr></thead><tbody><tr><td>Disqualified Count:</td><td>${item.dqCount}</td></tr><tr><td>First Disqualified Response:</td><td>${ dayjs( item.dqMinDate ).format( 'MM/DD/YYYY' ) }</td></tr><tr><td>Last Disqualified Response:</td><td>${ dayjs( item.dqMaxDate ).format( 'MM/DD/YYYY' ) }</td></tr></tbody></table>`
				let testTooltip = `<table width="250px"><thead><tr><th colspan="2">${item.title}</th></tr></thead><tbody><tr><td>Test Count:</td><td>${item.testCount}</td></tr><tr><td>First Test Response:</td><td>${ dayjs( item.testMinDate ).format( 'MM/DD/YYYY' ) }</td></tr><tr><td>Last Test Response:</td><td>${ dayjs( item.testMaxDate ).format( 'MM/DD/YYYY' ) }</td></tr></tbody></table>`

				let unresponsive = item.employeesSurveyed - item.partialCount - item.completeCount - item.dqCount - item.testCount
				unresponsive = ( unresponsive > 0 ) ? unresponsive : 0

				rows.push(
					{c: [
						{ v: utilities.date2GoogleDate( item.completeMinDate )  },
						{ v: item.completeCount }, { v: completeTooltip },
						{ v: item.partialCount }, { v: partialTooltip },
						{ v: item.dqCount }, { v: dqTooltip },
						{ v: item.testCount }, { v: testTooltip },
						{ v: unresponsive },
					]}
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'surveys/statsByDate', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/participationByDate', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		const cols = [
	   	{ id: 'surveyDate', label: 'Date', type: 'date' },
			{ id: 'participation', label: 'Participation', type: 'number' },
			{ type: 'string', role: 'tooltip', p: { 'html': true } }
		]

		var rows = []

		// let SQL 	= 	`select `
		// 			+		`s.survey_id, `
		// 			+		`format( max( s.created_on ), 'MM/01/yyyy' ) as modified_on, `
		// 			+		`s.title, `
		// 			+		`s.employeesSurveyed, `
		// 			+		`sum( case when s.[statistics] = 'null' then 0 else JSON_VALUE( s.[statistics], '$.Complete' ) end ) as completeCount `
		// 			+	`from alchemer..surveys s `
		// 			+	`where s.customerID = @customerID `
		// 			+	`group by s.survey_id, s.title, s.employeesSurveyed `
		let SQL 	=	`select `
					+		`s.survey_id, `
					+		`s.title, `
					+		`min( r.date_submitted ) as firstResponseDate, `
					+		`max( r.date_submitted ) as lastResponseDate, `
					+		`count( * ) as completeCount, `
					+		`avg( s.employeesSurveyed ) as employeesSurveyed `
					+	`from alchemer..surveys s `
					+	`left join alchemer..responses r on (r.survey_id = s.survey_id) `
					+	`where customerID = @customerID `
					+	`and r.status = 'complete' `
					+	`and r.is_test_data = 0 `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title `
					+	`order by min( r.date_submitted ) asc `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			result.recordset.forEach( item => {

				let title = item.title
				let participationPct = ( item.employeesSurveyed != 0 && item.employeesSurveyed != null ) ? item.completeCount / item.employeesSurveyed : 0
				let firstSubmission = utilities.date2GoogleDate( dayjs( item.firstResponseDate ).format( 'MM/DD/YYYY' ) )
				let lastSubmission = utilities.date2GoogleDate( dayjs( item.lastResponseDate ).format( 'MM/DD/YYYY' ) )
				let displayPercent = parseFloat( participationPct * 100 ).toFixed( 0 ) + "%"
				let displayDate = dayjs( item.date_submitted ).format( 'MMM D, YYYY' )

				let tooltip = `<table width="250px">
										<thead><tr><th colspan="2">${title}</th></tr></thead>
										<tbody>
											<tr><td>Percent:</td><td>${displayPercent}</td></tr>
											<tr><td>First Response:</td><td>${ dayjs( item.firstResponseDate ).format( 'MM/DD/YYYY' ) }</td></tr>
											<tr><td>Last Response:</td><td>${ dayjs( item.lastResponseDate ).format( 'MM/DD/YYYY' ) }</td></tr>
										</tbody>
									</table>`



				rows.push(
					{c: [
						{ v: firstSubmission },
						{ v: participationPct },
						{ v: tooltip }
					]}
				)
			})

			res.json({ cols: cols, rows: rows })


		}).catch( err => {
			logger.log({ level: 'error', label: 'surveys/participationByDate', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/departmentsBelowThreshold', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		let SQL	=	`select `
					+		`s.survey_id, `
					+		`s.title, `
					+		`r.department, `
					+		`count(*) as responseCount `
					+	`from alchemer..responses r `
					+	`join alchemer..surveys s on (s.survey_id = r.survey_id) `
					+	`and s.customerID = @customerID `
					+	`and s.status = 'closed' `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title, r.department `
					+	`having count(*) < 5 `
					+	`order by 1, 3 `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/departmentsBelowThreshold', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/surveysByCustomer', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		let SQL	=	`select `
					+		`s.survey_id, `
					+		`s.title, `
					+		`min(r.date_submitted) as firstResponse, `
					+		`max(r.date_submitted) as lastResponse `
					+	`from alchemer..responses r `
					+	`join alchemer..surveys s on (s.survey_id = r.survey_id) `
					+	`and s.customerID = @customerID `
					+	`and r.is_test_data  = 0 `
					+	`and r.status = 'Complete' `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title `
					+	`order by 2 `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/surveysByCustomer', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/locationsBelowThreshold', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' )

		let SQL	=	`select `
					+		`s.survey_id, `
					+		`s.title, `
					+		`r.location, `
					+		`count(*) as responseCount `
					+	`from alchemer..responses r `
					+	`join alchemer..surveys s on (s.survey_id = r.survey_id) `
					+	`and s.customerID = @customerID `
					+	`and s.status = 'closed' `
					+	`and s.type <> '360Feedback' `
					+	`group by s.survey_id, s.title, r.location `
					+	`having count(*) < 5 `
					+	`order by 1 desc `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/locationsBelowThreshold', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/surveys/360BySurveyID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.surveyID ) return res.status( 400 ).send( 'surveyID parameter missing' )

		let SQL	=	`select * `
					+	`from alchemer..responses r `
					+	`where r.survey_id = @surveyID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'surveyID', sql.BigInt, req.query.surveyID )
				.query( SQL )

		}).then( result => {

			let self = {}
			let supervisors = []
			let peers = []
			let directReports = []

			let supervisorCount = selfCount = peerCount = directReportCount = 0

			for ( row of result.recordset ) {

				let json = JSON.parse( row.survey_data )
				let filteredJson = json.responses.filter(response => response !== null && response.type && response.answer)

				let responses = filteredJson.map( ( response, index ) => ({
					index: index,
					type: response.type,
					text: response.text,
					section: response.section,
					answer: response.answer
				}))

				let relationshipObj = responses.find( item => item.text === 'Relationship' )
				let relationship = relationshipObj ? relationshipObj.answer : 'Not Found'

				switch( relationship ) {

					case `"Supervisor"`:
						supervisors.push( responses )
						supervisorCount += 1
						break

					case `"Peer"`:
						peers.push( responses )
						peerCount += 1
						break

					case `"yourself"`:
						self = responses
						selfCount += 1
						break

					case `"Direct Report"`:
						directReports.push( responses )
						directReportCount += 1
						break

					case `"Direct Report"`:


					default:
						console.log( 'unknown relationship type: ' + relationship )

				}


				resultset = {
					counts: {
						supervisorCount: supervisorCount,
						selfCount: selfCount,
						peerCount: peerCount,
						directReportCount: directReportCount
					},
					response: {
						self: self,
						supervisors: supervisors,
						peers: peers,
						directReports: directReports,
					},
				}

			}
			res.json( resultset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/surveys/360BySurveyID', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/survey/respondents', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		// unlike most of the other functions in this controller, this function retreives information
		// about survey respondents directly from Alchemer's API. This is to ensure that this
		// data is 100% up-to-date.

		if ( !req.query.surveyID ) return res.status( 400 ).send( 'surveyID parameter missing' )

		const uniqueTimestamp = new Date().getTime(); // Gets the current time in milliseconds

		try {

			let output = []
			let id = ''
			let relationship = ''
			let status = ''
			let isTestData = ''
			let relationshipKey = ''

			const axios = require('axios')

			const surveyResponses = await axios.get(
				`https://api.alchemer.com/v5/survey/${req.query.surveyID}/surveyresponse`, {
				params: {
					api_token: process.env.ALCHEMER_API_KEY,
					api_token_secret: process.env.ALCHEMER_API_KEY_SECRET,
					cacheBust: uniqueTimestamp,
				}
			})

			for ( response of surveyResponses.data.data ) {

				id = response.id
				status = response.status
				isTestData = response.is_test_data
				relationship = ''
				let data = response.survey_data
				for ( key in data ) {
					if ( data[key].question === "Relationship" ) {
						relationshipKey = key
						relationship = data[key].answer
					}
				}

				output.push({
					DT_RowId: id,
					status: status,
					isTestData: isTestData,
					key: relationshipKey,
					relationship: relationship
				})


			}

			res.json( output )

		} catch( err ) {
			console.log( 'error access Alchemer API' )
			console.error ( err )
		}


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/survey/respondents/update', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		// unlike most of the other functions in this controller, this function retreives information
		// about survey respondents directly from Alchemer's API. This is to ensure that this
		// data is 100% up-to-date.

		if ( !req.query.surveyID ) return res.status( 400 ).send( 'surveyID parameter missing' )
		if ( !req.query.responseID ) return res.status( 400 ).send( 'responseID parameter missing' )
		if ( !req.query.key ) return res.status( 400 ).send( 'key parameter missing' )
		if ( !req.query.relationship ) return res.status( 400 ).send( 'relationship parameter missing' )

		try {
			const axios = require('axios')
			const dataKey = `data[${req.query.key}][value]`
			const params = {
				api_token: process.env.ALCHEMER_API_KEY,
				api_token_secret: process.env.ALCHEMER_API_KEY_SECRET,
			}
			params[dataKey] = req.query.relationship

			const surveyResponses = await axios.post(
				`https://api.alchemer.com/v5/survey/${req.query.surveyID}/surveyresponse/${req.query.responseID}`,
				{},
				{ 	params: params }
			)

			return res.sendStatus( 200 )

		} catch( err ) {
			console.log( 'error access Alchemer API' )
			console.error ( err )
			return res.sendStatus( 500 )
		}


	})
	//====================================================================================


}
