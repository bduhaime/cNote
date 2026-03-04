// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function(app) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	app.get('/api/customerMetrics/summary', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let aStatusList = JSON.parse( req.query.statusList )

		if ( aStatusList.length <= 0 ) {
			return res.json([])
		}

		let inList = ''
		aStatusList.forEach( item => {
			if ( inList.length > 0 ) {
				inList += ','
			}
			inList += parseInt( item )
		})

		let output = []

		let SQL	=	"select "
					+		"c.id, "
					+		"c.rssdID, "
					+		"c.name as customerName, "
					+		"s.name as statusName, "
					+		"concat( u.firstName, ' ', u.lastName ) as primaryCoach, "

					+		"( select count(*) from customerCalls cc where cc.customerID = c.id and ( cc.deleted = 0 or cc.deleted is null ) AND ( cc.startDateTime is not null and cc.endDateTime is not null ) and cc.startDateTime > DATEADD(year, -1, getdate()) ) as callCountYear, "
					+		"( SELECT  datediff( day, max(startDateTime), getdate() ) FROM customerCalls cc WHERE cc.customerID = c.id AND ( cc.deleted = 0 OR cc.deleted IS NULL ) AND ( cc.startDateTime is not null and cc.endDatetime is not null ) ) as daysSinceLastCall, "
					+		"( select count(*) from customerImplementations ci where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) ) as activeIntentionsCount, "
					+		"( SELECT COUNT(*) FROM customerCalls cc WHERE cc.customerID = c.id AND ( cc.deleted = 0 OR cc.deleted IS NULL ) and not exists ( select * from customerCallEmailLog a where a.callID = cc.id and a.subject like '%agenda%' ) ) as callNoAgenda, "
					+		"( SELECT COUNT (*) FROM customerCalls cc WHERE cc.customerID = c.id AND ( cc.deleted = 0 OR cc.deleted IS NULL ) AND ( cc.startDateTime is not null and cc.endDatetime is not null ) AND NOT EXISTS ( SELECT * FROM customerCallEmailLog a WHERE a.callID = cc.id  AND a.subject LIKE '%recap%' ) ) as callNoRecap, "

					+		"( select count(*) from customerImplementations ci join customerOpportunities co on (co.implementationID = ci.id) where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) ) as oppCount, "

					+		"( select sum(annualEconomicValue) from customerImplementations ci join customerOpportunities co on (co.implementationID = ci.id) where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) ) as totalOppValue, "
					+		"( select count(*) from customerImplementations ci join customerOpportunities co on (co.implementationID = ci.id) where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) and (co.annualEconomicValue <= 0 or co.annualEconomicValue is null) ) as oppNoValue, "
					+		"( select count(*) from customerImplementations ci join customerObjectives co on (co.implementationID = ci.id) where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) and ( co.startDate is null OR co.endDate is null OR co.startValue is null or co.endValue is null) and co.opportunityID is not null ) as oppsWithoutGoal, "
					+		"( select count(*) from customerImplementations ci join customerOpportunities co on (co.implementationID = ci.id) where ci.customerID = c.id and not exists ( select * from customerObjectives obj where obj.opportunityID = co.id ) ) as oppNoObj, "

					+		"( select count(*) from customerImplementations ci join customerObjectives co on (co.implementationID = ci.id) where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) and co.opportunityID is null ) as utopiaCount, "
					+		"( select count(*) from customerImplementations ci join customerObjectives co on (co.implementationID = ci.id) where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) and ( co.startDate is null OR co.endDate is null OR co.startValue is null or co.endValue is null) and co.opportunityID is null ) as utopiaWithoutGoal, "

					+		"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND ( completeDate is null ) ) as openKICount, "
					+		"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND getdate() > ki.endDate AND ( completeDate is null ) ) as pastDueKICount, "
					+		"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND ( completeDate is null ) AND not exists ( 	select * from keyInitiativeProjects kip where kip.keyInitiativeID = ki.id ) AND not exists ( select * from keyInitiativeTasks kit where kit.keyInitiativeID = ki.id ) ) as nahproKICount, "
					+		"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ( p.deleted = 0 or p.deleted is null ) ) as openProjectCount, "

					+		"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ps.type in ( 'Escalate', 'Reschedule' ) and ( p.deleted = 0 or p.deleted is null ) ) as atRiskProjectCount, "
					+		"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ps.type NOT in ( 'Complete' ) and ( getdate() > p.endDate ) and ( p.deleted = 0 or p.deleted is null ) ) as pastDueProjectCount, "
					+		"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and not exists ( select * from tasks t where t.projectID = p.id ) and ( p.deleted = 0 or p.deleted is null ) ) as nahproProjectCount, "
					+		"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and ( t.deleted = 0 or t.deleted is null ) ) as openTaskCount, "

					+		"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and ( getdate() > t.dueDate ) and ( t.deleted = 0 or t.deleted is null ) ) as pastDueTaskCount, "
					+		"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and t.projectID is NULL and not exists ( select * from keyInitiativeTasks kit where kit.taskID = t.id ) and ( t.deleted = 0 or t.deleted is null ) ) as orphanTaskCount, "
					+		"( SELECT SUM( CASE WHEN t.completionDate IS NULL THEN CASE WHEN getdate( ) BETWEEN t.startDate AND t.dueDate THEN dbo.workDaysBetween ( t.startDate, getdate( ) ) ELSE CASE WHEN getdate( ) > t.dueDate THEN	dbo.workDaysBetween ( t.startDate, t.dueDate ) ELSE 0 END END ELSE 0 END ) from tasks t where t.customerID = c.id and t.completionDate is null and ( t.deleted = 0 or t.deleted is null ) ) as daysAtRisk, "
					+		"( select SUM( CASE WHEN getDate( ) > t.dueDate THEN dbo.workDaysBetween ( DATEADD( DAY, 1, t.dueDate ), getDate( ) ) ELSE 0 END ) from tasks t where t.customerID = c.id AND ( t.taskStatusID = 1 OR t.taskStatusID IS NULL ) AND ( t.deleted = 0 OR t.deleted IS NULL ) AND t.completionDate IS NULL ) as daysBehind, "
					+		"( select count(*) from customerCalls cc where cc.customerID = c.id AND ( cc.deleted = 0 or cc.deleted is null ) AND cc.scheduledStartDateTime < getdate() AND cc.endDateTime is null ) as missedCalls "

					+	"from customer c "
					+	"join customerStatus s on (s.id = c.customerStatusID) "
					+	"left join customerManagers cm on (cm.customerID = c.id and cm.managerTypeID = 0 and (cm.startDate <= convert(date,getdate()) or cm.startDate is null ) AND cm.endDate is NULL ) "
					+	"left join csuite..users u on (u.id = cm.userID) "
					+	"where s.id in ( " + inList + " ) "
					+	"and ( c.deleted = 0 or c.deleted is null ) "
					+	"group by c.id, c.name, s.name, concat( u.firstName, ' ', u.lastName ), c.cert, c.rssdID "
					+	"order by c.name "

		logger.log({ level: 'debug', label: 'customerMetrics/summary', message: SQL, user: req.session.userID })

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {

			// check the start dates/values of all customerMetrics
			results.recordsets[0].forEach( customer => {

				customerObjectiveBadStarts = 0

				let SQL 	= 	"select c.rssdID, ci.id as implementationID, co.id as objectiveID, co.opportunityID, m.metricTypeID, co.startDate, co.startValue, m.ratiosColumnName, m.sourceTableNameRoot "
							+	"from customerImplementations ci "
							+	"join customerOpportunities opp on (opp.implementationID = ci.id) "
							+	"join customerObjectives co on (co.opportunityID = opp.id) "
							+	"join metric m on (m.id = co.metricID) "
							+	"join customer c on (c.id = ci.customerID) "
							+	"where getdate() between ci.startDate and ci.endDate "
							+	"and co.startDate is not null "
							+	"and co.endDate is not null "
							+	"and ci.customerID = @customerID "
							+	"UNION "
							+ 	"select c.rssdID, ci.id as implementationID, co.id as objectiveID, co.opportunityID, m.metricTypeID, co.startDate, co.startValue, m.ratiosColumnName, m.sourceTableNameRoot "
							+	"from customerImplementations ci "
							+	"join customerObjectives co on (co.implementationID = ci.id and co.opportunityID is null) "
							+	"join metric m on (m.id = co.metricID) "
							+	"join customer c on (c.id = ci.customerID) "
							+	"where getdate() between ci.startDate and ci.endDate "
							+	"and co.startDate is not null and co.startValue is not NULL "
							+	"and ci.customerID = @customerID "

				sql.connect(dbConfig).then( pool => {
					return pool.request()
						.input( 'customerID', sql.BigInt, customer.id )
						.query( SQL )
				})
				.then( customerObjectives => {

					customerObjectives.recordsets[0].forEach( customerObjective => {

						switch ( customerObjective.metricTypeID ) {
							case '1':		// TEG Internal (ie, Standard) Metrics
							case '2':		// Customer Internal Metrics (customer specific)
								logger.log({ level: 'debug', label: 'customerMetrics/summary', message: `metricTypeID 1 or 2 encountered`, user: req.session.userID })

								// let validObjStartInd = validObjectiveStart_InternalMetrics( customerObjective )
								// if ( !validObjStartInd ) {
								// 	console.log( 'incrementing customerObjectiveBadStarts' )
								// 	customerObjectiveBadStarts++
								// } else {
								// 	console.log( 'customerObjectiveBadStarts WAS NOT incremented' )
								// }
								break

							case '3':
								logger.log({ level: 'debug', label: 'customerMetrics/summary', message: `metricTypeID 3 encountered`, user: req.session.userID })
								break
							case '4':
								logger.log({ level: 'debug', label: 'customerMetrics/summary', message: `metricTypeID 4 encountered`, user: req.session.userID })
								break
							default:
								logger.log({ level: 'debug', label: 'customerMetrics/summary', message: `Unexpected metricTypeID encountered`, user: req.session.userID })
								throw Error( 'Unexpected metricTypeID encountered' )
						}

					}) // end of customerObjectives.forEach

// 					console.log( 'done looking at customerObjectives, returning customerObjectiveBadStarts: ', customerObjectiveBadStarts )
					return customerObjectiveBadStarts

				}).then( customerObjectiveBadStarts => {

// 					console.log( 'intecting customerObjectiveBadStarts into customer object' )
					customer.customerObjectiveBadStarts = customerObjectiveBadStarts

// 					console.log( 'pushing customer into output array' )
					output.push( customer )

				}).catch( err => {

					console.error( 'Error getting customerObjectives for a customer', err )

				})


			}) // of of customer.forEach

		}).catch( err => {
			console.error( 'Error getting customerInfo Summary', err )
		}).then( () => {

// 			console.log( 'responding with .json( output )' )
			res.json( output )

		})

	})
	//====================================================================================


	//====================================================================================
	app.get('/api/customerMetrics/overview', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		// console.log( req.query.statusList )
		let aStatusList = JSON.parse( req.query.statusList )
		let inList = ''
		aStatusList.forEach( item => {
			if ( inList.length > 0 ) {
				inList += ','
			}
			inList += parseInt( item )
		})
		let statusList = req.query.statusList
		// console.log({ 'req.query.statusList': req.query.statusList, inList: inList })

		let SQL	=	"select "
					+		"sum(callsCount) as sumCalls, "
					+		"avg(callsCount) as avgCalls, "
					+		"sum(activeIntentionsCount) as sumIntentions, "
					+		"avg(activeIntentionsCount) as avgIntentions, "
					+		"sum(openKICount) as sumOpenKIs, "
					+		"avg(openKICount) as avgOpenKIs, "
					+		"sum(pastDueKICount) as sumPastDueKICount, "
					+		"avg(pastDueKICount) as avgPastDueKICount, "
					+		"sum(openProjectCount) as sumOpenProjects, "
					+		"avg(openProjectCount) as avgOpenProjects, "
					+		"sum(atRiskProjectCount) as sumAtRiskProjects, "
					+		"avg(atRiskProjectCount) as avgAtRiskProjects, "
					+		"sum(pastDueProjectCount) as sumPastDueProjects, "
					+		"avg(pastDueProjectCount) as avgPastDueProjects, "
					+		"sum(openTaskCount) as sumOpenTasks, "
					+		"avg(openTaskCount) as avgOpenTasks, "
					+		"sum(pastDueTaskCount) as sumPastDueTasks, "
					+		"avg(pastDueTaskCount) as avgPastDueTasks "
					+	"from ( "
					+		"select "
					+			"( select count(*) from customerCalls cc where cc.customerID = c.id and ( cc.deleted = 0 or cc.deleted is null ) AND ( cc.startDatetime is not null and cc.endDatetime is not null ) ) as callsCount, "
					+			"( select count(*) from customerImplementations ci where ci.customerID = c.id and ( ci.deleted = 0 or ci.deleted is null )  ) as activeIntentionsCount, "
					+			"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND ( completeDate is null ) )  as openKICount, "
					+			"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND getdate() > ki.endDate AND ( completeDate is null ) ) as pastDueKICount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ( p.deleted = 0 or p.deleted is null ) ) as openProjectCount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ps.type in ( 'Escalate', 'Reschedule' ) and ( p.deleted = 0 or p.deleted is null ) ) as atRiskProjectCount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ps.type NOT in ( 'Complete' ) and ( getdate() > p.endDate ) and ( p.deleted = 0 or p.deleted is null ) ) as pastDueProjectCount, "
					+			"( select count(*) from tasks t where t.customerID = c.id and ( t.deleted = 0 or t.deleted is null ) ) as openTaskCount, "
					+			"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and ( getdate() > t.dueDate ) and ( t.deleted = 0 or t.deleted is null ) ) as pastDueTaskCount "
					+		"from customer c "
					+		"join customerStatus s on (s.id = c.customerStatusID) "
					+		"left join customerManagers cm on (cm.customerID = c.id and cm.managerTypeID = 0 and (cm.startDate <= convert(date,getdate()) or cm.startDate is null ) AND cm.endDate is NULL ) "
					+		"left join csuite..users u on (u.id = cm.userID) "
					+		"where s.id in ( " + inList + " ) "
					+		"and ( c.deleted = 0 or c.deleted is null ) "
					+	") as x "

		logger.log({ level: 'debug', label: 'customerMetrics/overview', message: SQL, user: req.session.userID })

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {

			output = []
			output.push({
				measure: "Completed Calls",
				total: results.recordset[0].sumCalls,
				average: results.recordset[0].avgCalls
			})
			output.push({
				measure: "Intentions",
				total: results.recordset[0].sumIntentions,
				average: results.recordset[0].avgIntentions
			})
			output.push({
				measure: "Open KIs",
				total: results.recordset[0].sumOpenKIs,
				average: results.recordset[0].avgOpenKIs
			})
			output.push({
				measure: "Past Due KIs",
				total: results.recordset[0].sumPastDueKICount,
				average: results.recordset[0].avgPastDueKICount
			})
			output.push({
				measure: "Open Projects",
				total: results.recordset[0].sumOpenProjects,
				average: results.recordset[0].avgOpenProjects
			})
			output.push({
				measure: "At Risk Projects",
				total: results.recordset[0].sumAtRiskProjects,
				average: results.recordset[0].avgAtRiskProjects
			})
			output.push({
				measure: "Past Due Projects",
				total: results.recordset[0].sumPastDueProjects,
				average: results.recordset[0].avgPastDueProjects
			})
			output.push({
				measure: "Open Tasks",
				total: results.recordset[0].sumOpenTasks,
				average: results.recordset[0].avgOpenTasks
			})
			output.push({
				measure: "Past Due Tasks",
				total: results.recordset[0].sumPastDueTasks,
				average: results.recordset[0].avgPastDueTasks
			})

			res.json( output )

		}).catch( err => {
			console.error( 'Error getting customerInfo Summary', err )
		})

	})
	//====================================================================================


	//====================================================================================
	app.get('/api/customerMetrics/callTimeLine2', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		const customerID = req.query.customerID


		function onlyUnique(value, index, self) {
			return self.indexOf(value) === index;
		}

		let SQL	=	"select "
					+		"cc.id, "
					+		"shortName, "
					+		"format(startDateTime, 'M/d/yyyy' ) as callDate, "
					+		"format(startDateTime, 'hh:mm tt' ) as callTime, "
					+		"datediff(minute, startDateTime, endDateTime) as durationMin, "
					+		"concat(u.firstName, ' ', u.lastName) as callLead "
					+	"from customerCalls cc "
					+	"left join customerCallTypes cct on (cct.id = cc.calltypeID) "
					+	"left join csuite..users u on (u.id = cc.callLead) "
					+	"where ( cc.startDatetime is not null AND datediff(day, cc.startDateTime, getdate()) <= 365 ) "
					+	"and cc.endDatetime is not null "
					+	"and ( cc.deleted = 0 or cc.deleted is null ) "
					+	"and cc.customerID = @customerID "
					+	"order by 1 "

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL )
		}).then( results => {

			let cols = [
				{ id: "shortName", label: "Type", type: "string" },
				{ id: "dummy bar label", type: "string" },
				{ role: "tooltip", type: "string" },
				{ id: "Start", type: "date" },
				{ id: "End", type: "date" },
			]

			let rows = []
			let firstTime = true
			let tooltip = ''

			results.recordsets[0].forEach( item => {

				let callDate	= utilities.date2GoogleDate( item["callDate"] )
				let callLead = ''

				tooltip	= 	'<table>'
							+		'<tr><td>Type:</td><td>' + item["shortName"] + '</td></tr>'
							+		'<tr><td>Lead:</td><td>' + item["callLead"] + '</td></tr>'
							+		'<tr><td>Date:</td><td>' + item["callDate"] + ' ' + item["callTime"] + '</td></tr>'
							+		'<tr><td>Duration:</td><td>' + item["durationMin"]  + ' min.</td></tr>'
							+	'</table>'

				rows.push({ c: [
					{ v: item["shortName"] },
					{ v: '' },
					{ v: tooltip },
					{ v: callDate },
					{ v: callDate },
				]})

				if ( firstTime ) {

					tooltip	= 	'<table>'
								+		'<tr><td>Chart Start Date (not a call)</td></tr>'
								+	'</table>'

					rows.push({ c: [
						{ v: item["shortName"] },
						{ v: '' },
						{ v: tooltip },
						{ v: utilities.date2GoogleDate( dayjs().subtract( 1, 'year' ) ) },
						{ v: utilities.date2GoogleDate( dayjs().subtract( 1, 'year' ) ) },
					]})

					tooltip	= 	'<table>'
								+		'<tr><td>Chart End Date (not a call)</td></tr>'
								+	'</table>'
					rows.push({ c: [
						{ v: item["shortName"] },
						{ v: '' },
						{ v: tooltip },
						{ v: utilities.date2GoogleDate( dayjs() ) },
						{ v: utilities.date2GoogleDate( dayjs() ) },
					]})

					firstTime = false
				}

			})


			const pixelsPerBar = 40

			let allCallTypes = []
			results.recordsets[0].forEach( item => {
				allCallTypes.push( item.shortName  )
			})
			let uniqueCallTypes = allCallTypes.filter( onlyUnique )

			const chartHeight = pixelsPerBar * uniqueCallTypes.length + 55

			options = {
				title: 'Call Timeline Of Completed Calls In The Last Year',
				timeline: {
					groupByRowLabel: true
				},
				tooltip: { isHtml: true },
				height: chartHeight,
				hAxis: {
					min: 'new Date(2021, 3, 19)',
					max: 'new Date(2020, 3, 19)'
				}
			}

			res.json({ data: { cols: cols, rows: rows }, options: options })

		}).catch( err => {
			logger.log({ level: 'error', label: 'customerMetrics/callTimeLine', message: err })
			res.sendStatus( 500 )
		})


	})
	//====================================================================================


	//====================================================================================
	function validObjectiveStart_InternalMetrics( customerObjective ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL	=	"select * "
						+	"from customerInternalMetrics "
						+	"where rssdID = @rssdID "
						+	"and metricDate = @startDate "
						+	"and metricValue = @startValue "

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'rssdID', sql.BigInt, customerObjective.rssdID )
					.input( 'startDate', sql.Date, dayjs( customerObjective.startDate ).startOf('day').toDate() )
					.input( 'startValue', sql.Float, customerObjective.startValue )
					.query( SQL )

			}).then( results => {

				if ( results.recordset.length <= 0 ) {
// 					console.log( 'objective start is BAD' )
					return resolve( false )
				} else {
// 					console.log( 'objective start is GOOD' )
					return resolve( true )
				}

			}).catch( err => {

				return reject( 'error in validObjectiveStart_InternalMetrics, ', err )

			})

		})

	}
	//====================================================================================

}
