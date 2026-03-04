// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	const { sql, poolPromise } = require( '../db' ); // adjust path if needed

	// console.log('typeof poolPromise:', typeof poolPromise);
	// poolPromise.then(pool => console.log('typeof resolved pool:', typeof pool));

	//====================================================================================
	async function getPrimaryResults( pool, statusList ) {
	//====================================================================================

		const SQL	=	`select distinct `
						+		`c.id, `
						+		`case when c.periodicReviewComplete = 1 then 'true' else 'false' end as periodicReviewComplete, `
						+		`c.name as customerName, `
						+		`c.cert, `
						+		`s.name as statusName, `
						+		`case when len( c.anomoliesNarrative ) > 0 then 'true' else 'false' end as anomolies, `
						+		`concat( u.firstName, ' ', u.lastName ) as primaryCoach, `
						+		`case when ( c.secretShopperLocationName = '' or c.secretShopperLocationName is null ) then 'true' else 'false' end as customerNoMsBank, `
						+		`case when c.customerGradeID > 0 then c.customerGradeID else case when c.customerGradeNarrative > '' then c.customerGradeID else null end end as customerGradeID, `
						+		`customerGradeNarrative, `
						+		`c.anomoliesNarrative, `
						+		`case when (c.optOutOfMCCCalls = 0 or c.optOutOfMCCCalls is null) then 'false' else 'true' end as optOutOfMCCCalls, `
						+		`case when (dbo.customerHasOnboardingIssues( c.id ) = 0) then 'false' else 'true' end as hasOnboardingIssues `
						+	`from customer c `
						+	`join customerStatus s on (s.id = c.customerStatusID) `
						+	`left join customerManagers cm on (cm.customerID = c.id and cm.managerTypeID = 0 and (cm.startDate <= convert(date,getdate()) or cm.startDate is null ) AND cm.endDate is NULL ) `
						+	`left join csuite..users u on (u.id = cm.userID) `
						+	`where s.id in ( select value from STRING_SPLIT( @statusList, ',' ) ) `
						+	`and ( c.deleted = 0 or c.deleted is null ) `
						+	`order by 3 `;

		const result = await pool.request()
			.input( 'statusList', sql.VarChar, statusList )
			.query( SQL );

		return result.recordset;

	}
	//====================================================================================


	//====================================================================================
	async function getOpenTasksForCustomer( pool, customerID ) {
	//====================================================================================

		const SQL 	=	`SELECT `
						+		`id, `
						+		`startDate, `
						+		`dueDate, `
						+		`completionDate, `
						+		`taskStatusID, `
						+		`projectID `
						+	`FROM tasks `
						+	`WHERE customerID = @customerID `
						+	`AND (deleted = 0 OR deleted IS NULL) `
						+	`AND completionDate IS NULL `

		const results = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return results.recordset;

	}
	//====================================================================================


	//====================================================================================
	async function getTaskMetrics( pool, customerID ) {
	//====================================================================================

		const rawTasks = await getOpenTasksForCustomer( pool, customerID );

		const tasks = rawTasks.map( task => ({
			startDate: task.startDate,
			dueDate: task.dueDate,
			completionDate: task.completionDate ? task.completionDate : null,
			taskStatusID: task.taskStatusID
		}));

		const openTasks = tasks.length;

		const pastDueTasks = tasks.filter( task => {
			return dayjs().isAfter( task.dueDate );
		}).length;

		let totalDaysAhead = 0;
		let totalDaysBehind = 0;
		let totalDaysAtRisk = 0;

		for ( const task of tasks ) {

			const { daysAhead, daysBehind, daysAtRisk } = utilities.workDaysSummary(
				task.startDate,
				task.dueDate,
				task.completionDate
			);

			totalDaysAhead += daysAhead || 0;
			totalDaysBehind += daysBehind || 0;
			totalDaysAtRisk += daysAtRisk || 0;
		}

		const orphanedTaskCount = await getOrphanedTaskCount( pool, customerID, rawTasks );

		return {
			daysAhead: totalDaysAhead,
			daysBehind: totalDaysBehind,
			daysAtRisk: totalDaysAtRisk,
			openTaskCount: openTasks,
			pastDueTaskCount: pastDueTasks,
			orphanTaskCount: orphanedTaskCount,
		};

	}
	//====================================================================================


	//====================================================================================
	async function getOrphanedTaskCount( pool, customerID, taskList ) {
	//====================================================================================

		if ( taskList.length === 0 ) return 0;

		const taskIDs = taskList.map( t => t.id );

		const SQL 	= 	`SELECT taskID `
						+	`FROM keyInitiativeTasks `
						+	`WHERE taskID IN (${taskIDs.join(',')}) `;

		const result = await pool.request().query( SQL );

		const taskIDsWithKI = new Set( result.recordset.map( row => row.taskID ) );

		const orphaned = taskList.filter( t =>
			t.projectID === null && !taskIDsWithKI.has( t.id )
		);

		return orphaned.length;

	}
	//====================================================================================


	//====================================================================================
	async function getContractsSummaryByProduct( pool, cert, product ) {
	//====================================================================================

		const SQL	= `
			SELECT
				COUNT(*) AS contractCount,
				MIN(DATEDIFF(DAY, GETDATE(), expirationDate)) AS contractExpiration,
				(
					SELECT TOP 1 contractRenewalType
					FROM contracts
					WHERE cert = @cert
		 			AND product = @product
					AND active = 1
					ORDER BY expirationDate DESC
				) AS nextRenewalType
			FROM contracts
			WHERE cert = @cert
			AND product = @product
			AND active = 1;
		`;

		const result = await pool.request()
			.input( 'cert', sql.VarChar, cert )
			.input( 'product', sql.VarChar, product )
			.query( SQL );

		return result.recordset[0]; // shape: { contractCount, contractExpiration, nextRenewalType }

	}
	//====================================================================================


	//====================================================================================
	async function getUtopiaMetrics( pool, customerID ) {
	//====================================================================================

		const SQL	= 	`SELECT `
						+		`ISNULL(COUNT(*), 0) AS totUtopiaObj, `
						+		`ISNULL(SUM(CASE `
						+			`WHEN co.startDate IS NULL OR co.endDate IS NULL OR co.startValue IS NULL OR co.endValue IS NULL THEN 1 `
						+			`ELSE 0 `
						+		`END), 0) AS utopiaWithoutGoal, `
						+		`ISNULL(COUNT(DISTINCT CASE `
						+			`WHEN co.startDate IS NOT NULL AND co.endDate IS NOT NULL AND co.startValue IS NOT NULL AND co.endValue IS NOT NULL THEN ci.id `
						+			`ELSE NULL `
						+		`END), 0) AS utopiaCount `
						+	`FROM customerImplementations ci `
						+	`JOIN customerObjectives co ON co.implementationID = ci.id `
						+	`WHERE ci.customerID = @customerID `
						+	`AND (GETDATE() BETWEEN ci.startDate AND ci.endDate) `
						+	`AND (ci.deleted = 0 OR ci.deleted IS NULL) `
						+	`AND co.opportunityID IS NULL `
						+	`AND co.objectiveTypeID = 1 `;

		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return result.recordset[0];

	}
	//====================================================================================


	//====================================================================================
	async function getOpportunityMetrics( pool, customerID ) {
	//====================================================================================

		const SQL	=	`WITH activeImplementations AS ( `
						+		`SELECT id `
						+		`FROM customerImplementations `
						+		`WHERE customerID = @customerID `
						+		`AND (deleted = 0 OR deleted IS NULL) `
						+		`AND GETDATE() BETWEEN startDate AND endDate `
						+	`), `
						+	`activeOpportunities AS ( `
						+		`SELECT co.id, co.annualEconomicValue `
						+		`FROM customerOpportunities co `
						+		`JOIN activeImplementations ci ON co.implementationID = ci.id `
						+	`), `
						+	`opportunityObjectives AS ( `
						+		`SELECT `
						+			`co.id AS opportunityID, `
						+			`o.id AS objectiveID, `
						+			`o.startDate, `
						+			`o.endDate, `
						+			`o.startValue, `
						+			`o.endValue `
						+		`FROM activeOpportunities co `
						+		`LEFT JOIN customerObjectives o ON o.opportunityID = co.id `
						+	`) `

						+	`SELECT `
						+		`(SELECT COUNT(*) FROM activeOpportunities) AS oppCount, `
						+		`(SELECT ISNULL(SUM(annualEconomicValue), 0) FROM activeOpportunities) AS totalOppValue, `
						+		`(SELECT COUNT(*) FROM activeOpportunities WHERE annualEconomicValue IS NULL OR annualEconomicValue <= 0) AS oppNoValue, `
						+		`(SELECT COUNT(*) FROM opportunityObjectives WHERE startDate IS NULL OR endDate IS NULL OR startValue IS NULL OR endValue IS NULL) AS oppsWithoutGoal, `
						+		`(SELECT COUNT(*) FROM activeOpportunities ao WHERE NOT EXISTS ( SELECT 1 FROM customerObjectives o WHERE o.opportunityID = ao.id )) AS oppNoObj, `
						+		`(SELECT COUNT(*) FROM customerObjectives o JOIN activeOpportunities ao ON o.opportunityID = ao.id ) AS totOppObj `;

		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return result.recordset[0];

	}
	//====================================================================================


	//====================================================================================
	async function getKeyInitiativeMetrics( pool, customerID ) {
	//====================================================================================

		const SQL 	=	`WITH keyInitiativesFiltered AS ( `
						+		`SELECT ki.id, ki.completeDate, ki.startDate, ki.endDate `
						+		`FROM keyInitiatives ki `
						+		`WHERE ki.customerID = @customerID `
						+	`), `
						+	`nahproKIs AS ( `
						+		`SELECT ki.id `
						+		`FROM keyInitiativesFiltered ki `
						+		`WHERE ki.completeDate IS NULL `
						+		`AND NOT EXISTS (SELECT 1 FROM keyInitiativeProjects kip WHERE kip.keyInitiativeID = ki.id) `
						+		`AND NOT EXISTS (SELECT 1 FROM keyInitiativeTasks kit WHERE kit.keyInitiativeID = ki.id) `
						+	`) `

						+	`SELECT `
						+		`COUNT(CASE WHEN CAST(GETDATE() AS date) BETWEEN ki.startDate AND ki.endDate AND ki.completeDate IS NULL THEN 1 ELSE NULL END) AS openKICount, `
						+		`COUNT(CASE WHEN GETDATE() > ki.endDate AND ki.completeDate IS NULL THEN 1 ELSE NULL END) AS pastDueKICount, `
						+		`(SELECT COUNT(*) FROM nahproKIs) AS nahproKICount `
						+	`FROM keyInitiativesFiltered ki; `;

		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return result.recordset[0];
	}
	//====================================================================================


	//====================================================================================
	async function getProjectMetrics( pool, customerID ) {
	//====================================================================================

		const SQL 	= 	`WITH latestStatus AS ( `
						+		`SELECT psx.projectID, psx.type `
						+		`FROM projectStatus psx `
						+		`JOIN ( `
						+			`SELECT projectID, MAX(updatedDateTime) AS latest `
						+			`FROM projectStatus `
						+			`GROUP BY projectID `
						+		`) latestStatusDate ON latestStatusDate.projectID = psx.projectID AND latestStatusDate.latest = psx.updatedDateTime `
						+ 	`), `

						+ 	`noTasks AS ( `
						+		`SELECT p.id `
						+		`FROM projects p `
						+		`WHERE (p.deleted = 0 OR p.deleted IS NULL) `
						+		`AND NOT EXISTS ( SELECT 1 FROM tasks t WHERE t.projectID = p.id ) `
						+ 	`) `

						+	`SELECT `
						+		`COUNT(CASE WHEN (ps.type IS NULL OR ps.type <> 'Complete') AND (p.deleted = 0 OR p.deleted IS NULL) THEN 1 ELSE NULL END) AS openProjectCount, `
						+		`COUNT(CASE WHEN ps.type IN ('Escalate', 'Reschedule') AND (p.deleted = 0 OR p.deleted IS NULL) THEN 1 ELSE NULL END) AS atRiskProjectCount, `
						+		`COUNT(CASE WHEN (ps.type IS NULL OR ps.type <> 'Complete') AND GETDATE() > p.endDate AND (p.deleted = 0 OR p.deleted IS NULL) THEN 1 ELSE NULL END) AS pastDueProjectCount, `
						+		`( SELECT COUNT(*) FROM noTasks WHERE noTasks.id IN ( SELECT p.id FROM projects p WHERE p.customerID = @customerID ) ) AS nahproProjectCount `
						+ 	`FROM projects p `
						+ 	`LEFT JOIN latestStatus ps ON ps.projectID = p.id `
						+ 	`WHERE p.customerID = @customerID `;

		const result = await pool.request()
			.input('customerID', sql.BigInt, customerID)
			.query(SQL);

		return result.recordset[0];
	}
	//====================================================================================


	//====================================================================================
	async function getIntentionsMetrics( pool, customerID ) {
	//====================================================================================

		const SQL	=	`WITH activeImplementations AS ( `
						+		`SELECT id, startDate, endDate `
						+		`FROM customerImplementations `
						+		`WHERE customerID = @customerID `
						+		`AND (deleted = 0 OR deleted IS NULL) `
						+		`AND (CAST(GETDATE() AS date) BETWEEN startDate AND endDate) `
						+ `) `

						+ 	`SELECT `
						+		`(SELECT COUNT(*) FROM activeImplementations) AS activeIntentionsCount, `
						+		`COUNT(DISTINCT ci.id) AS overlappingIntentions `
						+ 	`FROM activeImplementations ci `
						+ 	`WHERE EXISTS ( `
						+		`SELECT 1 FROM activeImplementations cix `
						+		`WHERE cix.id <> ci.id `
						+		`AND cix.startDate <= ci.endDate `
						+		`AND cix.endDate >= ci.startDate `
						+	`);`;

		const result = await pool.request()
			.input('customerID', sql.BigInt, customerID)
			.query(SQL);

		return result.recordset[0];
	}
	//====================================================================================


	//====================================================================================
	async function getCallMetrics( pool, customerID ) {
	//====================================================================================

		const SQL =	`
			WITH baseCalls AS (
				SELECT cc.*, cct.idealFrequencyDays
				FROM customerCalls cc
				LEFT JOIN customerCallTypes cct ON cct.id = cc.callTypeID
				WHERE cc.customerID = @customerID
				AND (cc.deleted = 0 OR cc.deleted IS NULL)
			),

			completedCalls AS (
				SELECT * FROM baseCalls
				WHERE startDateTime IS NOT NULL AND endDateTime IS NOT NULL
			),

			incompleteCalls AS (
				SELECT * FROM baseCalls
				WHERE endDateTime IS NULL AND scheduledStartDateTime < GETDATE()
			),

			agendaMissing AS (
				SELECT cc.id FROM baseCalls cc
				WHERE NOT EXISTS (
					SELECT 1 FROM customerCallEmailLog e
					WHERE e.callID = cc.id AND e.subject LIKE '%agenda%'
				)
			),

			recapMissing AS (
				SELECT cc.id FROM completedCalls cc
				WHERE NOT EXISTS (
					SELECT 1 FROM customerCallEmailLog e
					WHERE e.callID = cc.id AND e.subject LIKE '%recap%'
				)
			),

			mccLate AS (
				SELECT DATEDIFF(day, cc.endDateTime, GETDATE()) - cc.idealFrequencyDays AS daysLate
				FROM completedCalls cc
				WHERE cc.callTypeID = 1
				AND cc.scheduledStartDateTime IS NOT NULL
				AND cc.scheduledEndDateTime IS NOT NULL
				AND EXISTS (
					SELECT 1 FROM customerCalls xx
					WHERE xx.customerID = cc.customerID
					AND xx.callTypeID = cc.callTypeID
					AND xx.endDateTime < GETDATE()
				)
			),

			sacLate AS (
				SELECT DATEDIFF(day, cc.endDateTime, GETDATE()) - cc.idealFrequencyDays AS daysLate
				FROM completedCalls cc
				WHERE cc.callTypeID = 2
				AND cc.scheduledStartDateTime IS NOT NULL
				AND cc.scheduledEndDateTime IS NOT NULL
				AND EXISTS (
					SELECT 1 FROM customerCalls xx
					WHERE xx.customerID = cc.customerID
					AND xx.callTypeID = cc.callTypeID
					AND xx.endDateTime < GETDATE()
				)
			)

			SELECT
				(SELECT COUNT(*) FROM completedCalls WHERE startDateTime > DATEADD(year, -1, GETDATE())) AS callCountYear,
				(SELECT DATEDIFF(day, MAX(startDateTime), GETDATE()) FROM completedCalls) AS daysSinceLastCall,
				(SELECT COUNT(*) FROM agendaMissing) AS callNoAgenda,
				(SELECT COUNT(*) FROM recapMissing) AS callNoRecap,
				(SELECT MIN(daysLate) FROM mccLate) AS mccDaysLate,
				(SELECT MIN(daysLate) FROM sacLate WHERE daysLate > 0) AS sacDaysLate,
				(SELECT COUNT(*) FROM incompleteCalls) AS missedCalls;

		`;

		const result = await pool.request()
			.input('customerID', sql.BigInt, customerID)
			.query(SQL);

		return result.recordset[0];
	}
	//====================================================================================


	//====================================================================================
	async function getDaysSinceLastShop( pool, customerID ) {
	//====================================================================================

		let SQL	= 	"select format( max( s.dateShopped ), 'yyyy-MM-dd' ) as dateOfLastShop "
					+	"from customer c "
					+	"join secretShopper..locations l on (l.grouperRegion = c.secretShopperLocationName) "
					+	"join secretShopper..shops s on (s.locationID = l.locationID) "
					+	"where c.id = @customerID "

		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return result.recordset[0];


	}
	//====================================================================================


	//====================================================================================
	async function getOverdueMetrics( pool, customerID ) {
	//====================================================================================

		try {

			let finalResults = [];

			let SQL = `
				select DISTINCT
					c.id as customerID,
					c.rssdID,
					m.id as metricID,
					m.name as metricName,
					m.sourceTableNameRoot,
					m.metricTypeID,
					m.frequency
				from customer c
				join customerImplementations i on (i.customerID = c.id)
				join customerObjectives o on (o.implementationID = i.id)
				join metric m on (m.id = o.metricID)
				where c.id = @customerID
				and cast( getdate() as date ) between i.startDate and i.endDate
				and (i.deleted = 0 or i.deleted is null)
				and m.active = 1
				and (m.deleted = 0 or m.deleted is null)
			`;

			const metrics = await pool.request()
				.input( 'customerID', sql.VarChar, customerID )
				.query( SQL );


			for ( metric of metrics.recordset ) {

				switch  ( metric.metricTypeID ) {
					case '1':		// TEG Internal Metrics
					case '2':		// Custom Internal Metrics

						SQL = `
							SELECT
								format( max( metricDate ), 'yyyy-MM-dd' ) as maxValueDate,
								30 as standardFrequency
							FROM customerInternalMetrics
							WHERE rssdID = ${metric.rssdID}
							AND metricID = ${metric.metricID}
						`;
						break;

					case '3':		// FDIC Metrics

						if ([ 'RCCI','RCN','RI','RIA','RIBII' ].includes( metric.sourceTableNameRoot ) ) {
							targetTableNamePrefix = 'fdic_calls.dbo.';
							targetColumnName = '[IDRSSD]';
						} else {
							targetTableNamePrefix = 'fdic_ratios.dbo.';
							targetColumnName = '[ID RSSD]';
						}

						// let targetTableNamePrefix 	= metric.sourceTableNameRoot === 'RIBII' ? 'fdic.dbo.' : 'fdic_ratios.dbo.'
						// let targetColumnName			= metric.sourceTableNameRoot === 'RIBII' ? '[IDRSSD]' : '[ID RSSD]'
						let targetTableName 			= targetTableNamePrefix + metric.sourceTableNameRoot.trim()

						SQL = `
							SELECT
								format( max( [reporting period] ), 'yyyy-MM-dd' ) as maxValueDate,
								120 as standardFrequency
							FROM ${targetTableName}
							WHERE ${targetColumnName} = ${metric.rssdID}
						`;
						break;

					case '4':		// TGIM-U
					default:

						continue

				}

				const results = await pool.request().query( SQL )

				if ( results.recordset[0].maxValueDate ) {

					let daysSinceLastValue = dayjs().diff( dayjs( results.recordset[0].maxValueDate ), 'day' )
					let daysOverdue = daysSinceLastValue - results.recordset[0].standardFrequency

					if ( daysOverdue > 0 ) {

						finalResults.push({
							customerID: metric.customerID,
							metricID: metric.metricID,
							metricTypeID: metric.metricTypeID,
							frequency: metric.frequency,
							maxValueDate: dayjs( results.recordset[0].maxValueDate ).format( 'YYYY-MM-DD' ),
							daysOverdue: daysOverdue
						})
					}

				} else {

					// this scenario means that an objective has been created, but no values have ever been posted

					finalResults.push({
						customerID: metric.customerID,
						metricID: metric.metricID,
						metricTypeID: metric.metricTypeID,
						frequency: metric.frequency,
						maxValueDate: null,
						daysOverdue: null
					})

				}

			}

			return finalResults

		} catch( err ) {

				logger.log({ level: 'error', label: 'exec/getOverdueMetrics()', message: err })
				throw new Error( err )

		}


	}
	//====================================================================================


	//====================================================================================
	async function getAverageScore( pool, customerID ) {
	//====================================================================================

		const SQL	= 	`select `
						+		`avg( cast(replace( score, '%', '' ) as NUMERIC(5,2))/100 ) as averageScore `
						+	`from customer c `
						+	`join secretShopper..locations l on ( l.grouperRegion = c.secretShopperLocationName ) `
						+	`join secretShopper..shops s on ( s.locationID = l.locationID ) `
						+	`where c.id = @customerID `
						+	`and dateShopped between dateadd( month, -12, getdate() ) and getdate() `
						+	`and s.score <> 'N/A' `

		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return result.recordset[0];

	}
	//====================================================================================


	//====================================================================================
	async function isMetricBelowObjective( objective ) {
	//====================================================================================

		// Check if metric values are available
		if (objective.metricStartValue == null || objective.metricEndValue == null) {
			return false;
		}

		// Simple logic: if the latest metric is below the objective's target end value
		return objective.metricEndValue < objective.objectiveEndValue;

	}
	//====================================================================================


	//====================================================================================
	async function getCustomerObjectivesAndMetrics( pool, customerID ) {
	//====================================================================================

		const SQL 	=
			`SELECT
				o.id AS objectiveID,
				o.objectiveTypeID,
				o.startDate AS objectiveStartDate,
				o.endDate AS objectiveEndDate,
				o.startValue AS objectiveStartValue,
				o.endValue AS objectiveEndValue,
				o.metricID,
				m.metricTypeID,
				m.sourceTableNameRoot
			FROM customerObjectives o
			INNER JOIN customerImplementations ci ON o.implementationID = ci.id
			INNER JOIN metric m ON o.metricID = m.id
			WHERE ci.customerID = @customerID
			AND o.startDate IS NOT NULL
			AND o.endDate IS NOT NULL
			AND o.startValue IS NOT NULL
			AND o.endValue IS NOT NULL
			AND (m.deleted = 0 OR m.deleted IS NULL)
			AND m.active = 1 `;

		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

		return result.recordset;

	}
	//====================================================================================


	//====================================================================================
	https.get('/api/customerMetrics/summary', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.statusList ) return res.status( 400 ).send( 'Parameter missing' );

			const pool = await poolPromise;

			const primaryResults = await getPrimaryResults( pool, req.query.statusList );

			await Promise.all(primaryResults.map( async ( customer ) => {

				const [
					taskMetrics,
					fcpContracts,
					msContracts,
					csContracts,
					utopiaMetrics,
					opportunityMetrics,
					keyInitiativeMetrics,
					projectMetrics,
					intentionsMetrics,
					callMetrics,
					overdueMetrics,
					daysSinceLastShop,
					averageScore,
					objectives
				] = await Promise.all([
					getTaskMetrics( pool, customer.id ),
					getContractsSummaryByProduct( pool, customer.cert, 'FCP' ),
					getContractsSummaryByProduct( pool, customer.cert, 'MS' ),
					getContractsSummaryByProduct( pool, customer.cert, 'CS' ),
					getUtopiaMetrics( pool, customer.id ),
					getOpportunityMetrics( pool, customer.id ),
					getKeyInitiativeMetrics( pool, customer.id ),
					getProjectMetrics( pool, customer.id ),
					getIntentionsMetrics( pool, customer.id ),
					getCallMetrics( pool, customer.id ),
					getOverdueMetrics( pool, customer.id ),
					getDaysSinceLastShop( pool, customer.id ),
					getAverageScore( pool, customer.id ),
					getCustomerObjectivesAndMetrics(pool, customer.id)
				]);

				// --- Handle Objectives
				let oppBelowObj = 0;
				let utopiaBelowObj = 0;
				let kpiBelowObj = 0;

				for (const objective of objectives) {
					if (isMetricBelowObjective(objective)) {
						switch (objective.objectiveTypeID?.toString()) {
							case '1': ++utopiaBelowObj; break;
							case '2': ++oppBelowObj; break;
							case '3': ++kpiBelowObj; break;
							default:
								console.error(`Unexpected objectiveTypeID: ${objective.objectiveTypeID}`);
						}
					}
				}

				Object.assign( customer, taskMetrics, {

					// Contracts
					fcpContractCount: fcpContracts.contractCount,
					fcpContractExpiration: fcpContracts.contractExpiration,
					fcpNextRenewalType: fcpContracts.nextRenewalType,
					fcpExpiring: fcpContracts.contractExpiration !== null && fcpContracts.contractExpiration <= 180,

					msContractCount: msContracts.contractCount,
					msContractExpiration: msContracts.contractExpiration,
					msNextRenewalType: msContracts.nextRenewalType,
					msExpiring: msContracts.contractExpiration !== null && fcpContracts.contractExpiration <= 180,

					csContractCount: csContracts.contractCount,
					csContractExpiration: csContracts.contractExpiration,
					csNextRenewalType: csContracts.nextRenewalType,
					csExpiring: csContracts.contractExpiration !== null && fcpContracts.contractExpiration <= 180,

					// Utopias
					utopiaCount: utopiaMetrics.utopiaCount,
					utopiaWithoutGoal: utopiaMetrics.utopiaWithoutGoal,
					totUtopiaObj: utopiaMetrics.totUtopiaObj,

					// Opportunities
					oppCount: opportunityMetrics.oppCount,
					totalOppValue: opportunityMetrics.totalOppValue,
					oppNoValue: opportunityMetrics.oppNoValue,
					oppsWithoutGoal: opportunityMetrics.oppsWithoutGoal,
					oppNoObj: opportunityMetrics.oppNoObj,
					totOppObj: opportunityMetrics.totOppObj,

					// Key Initiatives
					openKICount: keyInitiativeMetrics.openKICount,
					pastDueKICount: keyInitiativeMetrics.pastDueKICount,
					nahproKICount: keyInitiativeMetrics.nahproKICount,

					// Projects
					openProjectCount: projectMetrics.openProjectCount,
					atRiskProjectCount: projectMetrics.atRiskProjectCount,
					pastDueProjectCount: projectMetrics.pastDueProjectCount,
					nahproProjectCount: projectMetrics.nahproProjectCount,

					// Intentions
					activeIntentionsCount: intentionsMetrics.activeIntentionsCount,
					overlappingIntentions: intentionsMetrics.overlappingIntentions,

					// Calls
					callCountYear: callMetrics.callCountYear,
					daysSinceLastCall: callMetrics.daysSinceLastCall,
					callNoAgenda: callMetrics.callNoAgenda,
					callNoRecap: callMetrics.callNoRecap,
					mccDaysLate: callMetrics.mccDaysLate,
					sacDaysLate: callMetrics.sacDaysLate,
					missedCalls: callMetrics.missedCalls,

					// Overdue Metrics
					overdueMetrics: overdueMetrics.length ? overdueMetrics.length : 0,

					// Days Since Last Shop
					daysSinceLastShop: daysSinceLastShop.dateOfLastShop ? dayjs().diff( dayjs( daysSinceLastShop.dateOfLastShop ), 'day' ) : null,
					noShops: daysSinceLastShop.dateOfLastShop === null || dayjs().diff( dayjs( daysSinceLastShop.dateOfLastShop ), 'month' ) >= 12,

					// Average Score
					averageScore: averageScore.averageScore ? parseFloat( averageScore.averageScore * 100 ).toFixed( 2 ) + '%' : null,

					// Objectives
					oppBelowObj,
					utopiaBelowObj,
					kpiBelowObj

				});

			}));

			return res.json( primaryResults );

		} catch( err ) {

			logger.log({ level: 'error', label: 'customerMetrics/summary', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected error' )

		}

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/customerMetrics/overview', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'customerMetrics/overview', message: `statusList: ${req.query.statusList}`, user: req.session.userID })

		let aStatusList = JSON.parse( req.query.statusList )
		let inList = ''
		aStatusList.forEach( item => {
			if ( inList.length > 0 ) {
				inList += ','
			}
			inList += parseInt( item )
		})
		let statusList = req.query.statusList

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

		const pool = await poolPromise;
		const results = await pool.request()
			 .query( SQL );

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

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/customerMetrics/callTimeLine2', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const customerID = req.query.customerID


		function onlyUnique(value, index, self) {
			return self.indexOf(value) === index;
		}

		let SQL 	=	"select "
					+		"cc.id, "
					+		"shortName, "
					+		"case when (startDateTime is not null and endDateTime is not null) then 'true' else 'false' end as completed, "
					+		"case when startDateTime is not null then format(startDateTime, 'M/d/yyyy' ) else format(scheduledStartDateTime, 'M/d/yyyy' ) end as callDate, "
					+		"case when startDateTime is not null then format(startDateTime, 'hh:mm tt' ) else format(scheduledStartDateTime, 'hh:mm tt' ) end as callTime, "
					+		"case when startDateTime is not null then datediff(minute, startDateTime, endDateTime) else null end as durationMin, "
					+		"concat(u.firstName, ' ', u.lastName) as callLead, "
					+		"datediff( day, cc.startDateTime, cast( getdate() as date ) ) as [dateDiff] "
					+	"from customerCalls cc "
					+	"left join customerCallTypes cct on (cct.id = cc.calltypeID) "
					+	"left join csuite..users u on (u.id = cc.callLead) "
					+	"where ( cc.deleted = 0 or cc.deleted is null ) "
					+	"and ( ( endDateTime is not null and endDateTime is not null and startDateTime >= dateAdd( year, -1, cast( getdate() as date ) ) ) "
					+	"or  ( endDateTime is null and scheduledStartDateTime between cast( getdate() as date ) and dateAdd( month, 6, cast( getdate() as date ) ) ) ) "
					+	"and cc.customerID = @customerID "
					+	"order by 1 "

		logger.log({ level: 'debug', label: 'customerMetrics/callTimeLine2', message: SQL, user: req.session.userID })

		const pool = await poolPromise;
		const results = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );

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
			let duration = item['durationMin'] ? item["durationMin"]  + ' min.' : 'N/A'

			tooltip	= 	'<table>'
						+		'<tr><td>Type:</td><td>' + item["shortName"] + '</td></tr>'
						+		'<tr><td>Lead:</td><td>' + item["callLead"] + '</td></tr>'
						+		'<tr><td>Date:</td><td>' + item["callDate"] + ' ' + item["callTime"] + '</td></tr>'
						+		'<tr><td>Duration:</td><td>' + duration + '</td></tr>'
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

				// force a starting date of 1 year ago...
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

				// force an ending date of 6 months in future
				rows.push({ c: [
					{ v: item["shortName"] },
					{ v: '' },
					{ v: tooltip },
					{ v: utilities.date2GoogleDate( dayjs().add( 6, 'month' ) ) },
					{ v: utilities.date2GoogleDate( dayjs().add( 6, 'month' ) ) },
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

		const now = new Date()

		options = {
			timeline: {
				groupByRowLabel: true
			},
			tooltip: { isHtml: true },
			height: chartHeight
		}

		res.json({ data: { cols: cols, rows: rows }, options: options })

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/customerMetrics/objectiveAnalysis', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const customerID = req.query.customerID

		const SQL	=	`select
								c.rssdID,
								i.name as implementationName,
								o.implementationID,
								format( o.startDate, 'yyyy-MM-dd' ) as startDate,
								format( o.endDate, 'yyyy-MM-dd' ) as endDate,
								o.startValue,
								o.endValue,
								m.metricTypeID,
								m.ratiosColumnName,
								m.sourceTableNameRoot
							from customer c
							join customerImplementations i on (i.customerID = c.id)
							join customerObjectives o on (o.implementationID = i.id)
							join metric m on (m.id = o.metricID)
							and c.id = @customerID
							and (i.deleted = 0 or i.deleted is null) `

		const pool = await poolPromise;
		const result = await pool.request()
			.input( 'customerID', sql.BigInt, customerID )
			.query( SQL );


		const objectiveCount = results.recordset.length

		let startDateCount = 0
		let endDateCount = 0
		let startValueCount = 0
		let endValueCount = 0
		let startDateMatch = 0
		let startValueMatch = 0
		for ( objective of results.recordset ) {

			switch ( objective.metricTypeID ) {
				case '1':
				case '2':
					break
				case '3':

					if ( objective.startDate ) {
						startDateCount++

						let subSQL = 	`select ${objective.ratiosColumnName} as metricColumnValue
											 from fdic_ratios.dbo.${objective.sourceTableNameRoot}
											 where [reporting period] = @reportingPeriod
											 and [id rssd] = @rssdID `

						const pool = await poolPromise;
						const results = await pool.request()
							.input( 'reportingPeriod', sql.Date, dayjs( objective.startDate ).startOf('day').toDate() )
							.input( 'rssdID', sql.BigInt, objective.rssdID )
							.query( subSQL )

						if ( results.recordset.length > 0 ) {
							startDateMatch++
							if ( results.recordset[0].metricColumnValue == objective.startValue ) startValueMatch++
						}

					}

				case '4':
				default:

					continue

			}

			if ( objective.endDate) endDateCount++
			if ( objective.startValue ) startValueCount++
			if ( objective.endValue ) endValueCount++

		}

		output = {
			objectiveCount: objectiveCount,
			startDateCount: startDateCount,
			endDateCount: endDateCount,
			startValueCount: startValueCount,
			endValueCount: endValueCount,
			startDateMatch: startDateMatch,
			startValueMatch: startValueMatch
		}

		res.json( output )

	});
	//====================================================================================


}
