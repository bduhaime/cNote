// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/coachMetrics/summary', utilities.jwtVerify, (req, res) => {
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

		let SQL	=	"select "
					+		"primaryCoachID as id, "
					+		"primaryCoach, "
					+		"count( customerName ) as customerCount, "
					+		"sum( callCount ) as callCount, "
					+		"sum( missedCalls ) as missedCalls, "
					+		"sum( activeIntentionsCount ) as activeIntentionsCount, "
					+		"sum( openKICount ) as openKICount, "
					+ 		"sum( pastDueKICount ) as pastDueKICount, "
					+		"sum( nahproKICount ) as nahproKICount, "
					+		"sum( openProjectCount ) as openProjectCount, "
					+		"sum( atRiskProjectCount ) as atRiskProjectCount, "
					+		"sum( pastDueProjectCount ) as pastDueProjectCount, "
					+		"sum( nahproProjectCount ) as nahproProjectCount, "
					+		"sum( openTaskCount ) as openTaskCount, "
					+		"sum( pastDueTaskCount ) as pastDueTaskCount, "
					+		"sum( orphanTaskCount ) as orphanTaskCount, "
					+		"sum( daysAtRisk ) as daysAtRisk, "
					+		"sum( daysBehind ) as daysBehind "
					+	"from ( "
					+		"select "
					+			"c.id, "
					+			"c.name as customerName, "
					+			"s.name as statusName, "
					+			"u.id as primaryCoachID, "
					+			"concat( u.firstName, ' ', u.lastName ) as primaryCoach, "
					+			"( select count(*) from customerCalls cc where cc.customerID = c.id and ( cc.deleted = 0 or cc.deleted is null ) AND ( cc.startDateTime is not null and cc.endDateTime is not null ) ) as callCount, "
					+			"( SELECT  datediff( day, max(startDateTime), getdate() ) FROM customerCalls cc WHERE cc.customerID = c.id AND ( cc.deleted = 0 OR cc.deleted IS NULL ) AND ( cc.startDateTime is not null and cc.endDatetime is not null ) ) as daysSinceLastCall, "
					+			"( select count(*) from customerImplementations ci where ci.customerID = c.id AND ( getdate() between ci.startDate and ci.endDate ) and ( ci.deleted = 0 or ci.deleted is null ) ) as activeIntentionsCount, "
					+			"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND ( completeDate is null ) ) as openKICount, "
					+			"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND getdate() > ki.endDate AND ( completeDate is null ) ) as pastDueKICount, "
					+			"( select count(*) from keyInitiatives ki where ki.customerID = c.id AND ( completeDate is null ) AND not exists ( 	select * from keyInitiativeProjects kip where kip.keyInitiativeID = ki.id ) AND not exists ( select * from keyInitiativeTasks kit where kit.keyInitiativeID = ki.id ) ) as nahproKICount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ( p.deleted = 0 or p.deleted is null ) ) as openProjectCount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ps.type in ( 'Escalate', 'Reschedule' ) and ( p.deleted = 0 or p.deleted is null ) ) as atRiskProjectCount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and ps.type NOT in ( 'Complete' ) and ( getdate() > p.endDate ) and ( p.deleted = 0 or p.deleted is null ) ) as pastDueProjectCount, "
					+			"( select count(*) from projects p LEFT JOIN ( select projectID, type from projectStatus psx where updatedDateTime = ( select max(updatedDateTime) from projectStatus psy where psy.projectID = psx.projectID ) ) as ps on (ps.projectID = p.id)  where p.customerID = c.id and not exists ( select * from tasks t where t.projectID = p.id ) and ( p.deleted = 0 or p.deleted is null ) ) as nahproProjectCount, "
					+			"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and ( t.deleted = 0 or t.deleted is null ) ) as openTaskCount, "
					+			"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and ( getdate() > t.dueDate ) and ( t.deleted = 0 or t.deleted is null ) ) as pastDueTaskCount, "
					+			"( select count(*) from tasks t where t.customerID = c.id and t.completionDate is null and t.projectID is NULL and not exists ( select * from keyInitiativeTasks kit where kit.taskID = t.id ) and ( t.deleted = 0 or t.deleted is null ) ) as orphanTaskCount, "
					+			"( SELECT SUM( CASE WHEN t.completionDate IS NULL THEN CASE WHEN getdate( ) BETWEEN t.startDate AND t.dueDate THEN dbo.workDaysBetween ( t.startDate, getdate( ) ) ELSE CASE WHEN getdate( ) > t.dueDate THEN	dbo.workDaysBetween ( t.startDate, t.dueDate ) ELSE 0 END END ELSE 0 END ) from tasks t where t.customerID = c.id and t.completionDate is null and ( t.deleted = 0 or t.deleted is null ) ) as daysAtRisk, "
					+			"( select SUM( CASE WHEN getDate( ) > t.dueDate THEN dbo.workDaysBetween ( DATEADD( DAY, 1, t.dueDate ), getDate( ) ) ELSE 0 END ) from tasks t where t.customerID = c.id AND ( t.taskStatusID = 1 OR t.taskStatusID IS NULL ) AND ( t.deleted = 0 OR t.deleted IS NULL ) AND t.completionDate IS NULL ) as daysBehind, "
					+			"( select count(*) from customerCalls cc where cc.customerID = c.id and ( cc.deleted = 0 or cc.deleted is null) AND cc.scheduledStartDateTime < getdate() AND endDateTime is null ) as missedCalls "
					+		"from customer c "
					+		"join customerStatus s on (s.id = c.customerStatusID) "
					+		"left join customerManagers cm on (cm.customerID = c.id and cm.managerTypeID = 0 and (cm.startDate <= convert(date,getdate()) or cm.startDate is null ) AND cm.endDate is NULL ) "
					+		"left join csuite..users u on (u.id = cm.userID and ( u.deleted = 0 or u.deleted is null ) ) "
					+		"where s.id in ( " + inList + " ) "
					+		"and ( c.deleted = 0 or c.deleted is null ) "
					+		"group by c.id, c.name, s.name, u.id, concat( u.firstName, ' ', u.lastName ) "
					+	") as x "
					+	"group by primaryCoachID, primaryCoach "
					+	"order by 2 "

		logger.log({ level: 'debug', label: 'GET:sysop/coachMetrics', message: SQL, user: req.session.userID })

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordsets[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'coachMetrics/summary', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/coachMetrics/missedCallsByCustomer', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		let coachID = req.query.coachID

		if ( coachID ) {
			coachPredicated = "and primaryCoachID = " + coachID + " "
		} else {
			coachPredicate = "and primaryCoachID is null "
		}

		let SQL	=	"select "
					+		"customerName, "
					+		"sum( missedCalls ) as missedCalls, "
					+	"from ( "
					+		"select "
					+			"c.id, "
					+			"u.id as primaryCoachID, "
					+			"( select count(*) from customerCalls cc where cc.customerID = c.id and ( cc.deleted = 0 or cc.deleted is null) AND cc.scheduledStartDateTime < getdate() AND endDateTime is null ) as missedCalls "
					+		"from customer c "
					+		"join customerStatus s on (s.id = c.customerStatusID) "
					+		"left join customerManagers cm on (cm.customerID = c.id and cm.managerTypeID = 0 and (cm.startDate <= convert(date,getdate()) or cm.startDate is null ) AND cm.endDate is NULL ) "
					+		"left join csuite..users u on (u.id = cm.userID) "
					+		"and ( c.deleted = 0 or c.deleted is null ) "
					+		"group by c.id, c.name, s.name, u.id, concat( u.firstName, ' ', u.lastName ) "
					+	") as x "
					+	"group by primaryCoachID, primaryCoach "
					+	"order by 2 "

		logger.log({ level: 'debug', label: 'coachMetrics/missedCallsByCustomer', message: SQL, user: req.session.userID })

		sql.connect(dbConfig).then( pool => {
			return pool.request().query( SQL )
		}).then( results => {
			res.json( results.recordsets[0] )
		}).catch( err => {
			logger.log({ level: 'error', label: 'coachMetrics/missedCallsByCustomer', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )
		})

	})
	//====================================================================================


}
