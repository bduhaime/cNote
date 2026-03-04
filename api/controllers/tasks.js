// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/tasks', utilities.jwtVerify, async (req, res) => {
	//====================================================================================


		try {

			const tasks = await getTasks(req.query.customerID, req.query.projectID, pool);

			let finalResults = [];

			// Process the results...
			for ( let task of tasks ) {

				let daysBehind, daysAtRisk;

				if (task.completionDate) {
					if (dayjs(task.completionDate).isAfter(dayjs(task.dueDate))) {
						daysBehind = await utilities.workDaysBetweenv2(task.dueDate, task.completionDate);
						daysBehind = daysBehind > 0 ? daysBehind - 1 : 0;
					} else {
						daysBehind = 0;
					}
				} else {
					if (dayjs(task.dueDate).isBefore(dayjs())) {
						daysBehind = await utilities.workDaysBetweenv2(task.dueDate, dayjs().format('YYYY-MM-DD'));
						daysBehind = daysBehind > 0 ? daysBehind - 1 : 0;
					} else {
						daysBehind = 0;
					}
				}

				daysAtRisk = await utilities.daysAtRiskv2( task.startDate, task.dueDate, task.completionDate );
				// if (!task.completionDate) {
				// 	if (dayjs(task.startDate).isBefore(dayjs())) {
				// 		daysAtRisk = await utilities.workDaysBetweenv2(task.startDate, task.dueDate);
				// 		daysAtRisk = daysAtRisk > 0 ? daysAtRisk - 1 : 0;
				// 	} else {
				// 		daysAtRisk = await utilities.workDaysBetweenv2(task.startDate, dayjs().format('YYYY-MM-DD'));
				// 		daysAtRisk = daysAtRisk > 0 ? daysAtRisk - 1 : 0;
				// 	}
				// } else {
				// 	daysAtRisk = 0;
				// }

				let taskListStatus = await getTaskChecklistStatus(task.id);
				let completionDate = task.completionDate ? task.completionDate : null;

				finalResults.push({
					id: task.id,
					taskName: utilities.filterSpecialCharacters(task.name),
					description: utilities.filterSpecialCharacters(task.description),
					startDate: task.startDate ? dayjs(task.startDate).format('MM/DD/YYYY') : null,
					dueDate: task.dueDate ? dayjs(task.dueDate).format('MM/DD/YYYY') : null,
					completeDate: task.completionDate ? dayjs(task.completionDate).format('MM/DD/YYYY') : null,
					taskStatusID: task.taskStatusID,
					taskStatusName: task.taskStatusName,
					projectID: task.projectID,
					ownerID: task.ownerID,
					ownerName: task.resource,
					delete: task.deleted,
					daysBehind: daysBehind,
					daysAtRisk: daysAtRisk,
					completedTasks: taskListStatus.completed,
					totalTasks: taskListStatus.total
				});

			}

			res.json(finalResults);

		} catch( err ) {

			res.status(500).json({ error: err.message });

		}


	});
	//====================================================================================


	//====================================================================================
	https.post('/api/tasks', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const projectID = req.body.projectID ?? null;
		if ( !req.body.name ) return res.status( 400 ).send( 'Project name parameter missing' );
		if ( !req.body.customerID ) return res.status( 400 ).send( 'customerID parameter missing' );

		const newTaskID = await utilities.GetNextID( "tasks" );
		const estimatedWorkDays = await utilities.workDaysBetweenv2( req.body.startDate, req.body.dueDate );

		let SQL	=	`insert tasks ( `
					+		`id, `
					+		`projectID, `
					+		`ownerID, `
					+		`name, `
					+		`description, `
					+		`startDate, `
					+		`dueDate, `
					+		`customerID, `
					+		`estimatedWorkDays, `
					+		`updatedBy, `
					+		`updatedDateTime `
					+	`) values ( `
					+		`@taskID, `
					+		`@projectID, `
					+		`@ownerID, `
					+		`@name, `
					+		`@description, `
					+		`@startDate, `
					+		`@dueDate, `
					+		`@customerID, `
					+		`@estimatedWorkDays, `
					+		`@userID, `
					+		`CURRENT_TIMESTAMP `
					+	`) `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskID', sql.BigInt, newTaskID )
				.input( 'projectID', sql.BigInt, projectID )
				.input( 'ownerID', sql.BigInt, req.body.ownerID )
				.input( 'name', sql.VarChar( sql.Max ), req.body.name )
				.input( 'description', sql.VarChar( sql.Max ), req.body.description )
				.input( 'startDate', sql.Date, dayjs( req.body.startDate ).startOf('day').toDate() )
				.input( 'dueDate', sql.Date, dayjs( req.body.dueDate ).startOf('day').toDate() )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.input( 'estimatedWorkDays', sql.BigInt, estimatedWorkDays )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL );

		}).then( async result => {

			if ( projectID ) {
				await updateProjectStartEndDates( projectID );
			}

			return res.sendStatus( 200 );

		}).catch( err => {

			console.error( err );
			logger.log({ level: 'error', label: 'POST:api/tasks', message: err, user: req.session.userID });
			res.sendStatus( 500 )

		});

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/taskDetail', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.taskID ) return res.status( 400 ).send( 'Task ID parameter missing' )

			let SQL	= 	`select `
						+		`t.name as taskName, `
						+		`t.description as taskDescription, `
						+		`t.ownerID as taskOwnerID, `
						+		`format( t.startDate, 'yyyy-MM-dd' ) as taskStartDate, `
						+		`format( t.dueDate, 'yyyy-MM-dd' ) as taskDueDate, `
						+		`format( t.completionDate, 'yyyy-MM-dd' ) as taskCompleteDate, `
						+		`t.acceptanceCriteria, `
						+		`t.projectID, `
						+		`p.name as projectName, `
						+		`format( p.startDate, 'yyyy-MM-dd' ) as projectStartDate, `
						+		`format( p.endDate, 'yyyy-MM-dd' ) as projectEndDate, `
						+		`format( p.completeDate, 'yyyy-MM-dd' ) as projectCompleteDate, `
						+		`format( ps.statusDate, 'yyyy-MM-dd' ) as projectStatusDate, `
						+		`ps.type as projectStatus, `
						+		`t.taskStatusID, `
						+		`ts.name as taskStatusName, `
						+		`t.ownerID, `
						+		`concat(cc.firstName, ' ', cc.lastName) as ownerName, `
						+		`t.skippedReason, `
						+		`t.customerID, `
						+		`ki.kiCompletedCount `
						+	`from tasks t `
						+	`left join taskStatus ts on (ts.id = t.taskStatusID) `
						+	`left join projects p on (p.id = t.projectID) `
						+	`left join customerContacts cc on (cc.id = t.ownerID) `
						+	`left join `
						+		`( `
						+		`select top 1 id, projectID, statusDate, type `
						+		`from projectStatus `
						+		`order by id desc `
						+		`) ps on (ps.projectID = t.projectID) `
						+	`outer apply ( `
						+		`select count(*) as kiCompletedCount `
						+		`from keyInitiativeTasks a `
						+		`join keyInitiatives b on (b.id = a.keyInitiativeID) `
						+		`where a.taskID = t.id `
						+	`) as ki `
						+	`where t.id = @taskID `

			const results = await pool.request()
				.input('taskID', sql.BigInt, req.query.taskID )
				.query( SQL );

			const row = results.recordset?.[0];

			if ( row ) {

				let taskListStatus = await getTaskChecklistStatus( row.id );
				let completionDate = ( !!row.taskCompleteDate ) ? row.taskCompleteDate : null;

				if ( !completionDate ) {
					// determine "completability"
				} else {
					// determine "uncompletability"
				}

				res.json({
					taskID: req.query.taskID,
					taskName: ( row.taskName ) ? utilities.filterSpecialCharacters( row.taskName ) : null,
					description: ( row.taskDescription ) ? utilities.filterSpecialCharacters( row.taskDescription ) : null,
					skippedReason: ( row.skippedReason ) ? utilities.filterSpecialCharacters( row.skippedReason ) : null,
					acceptanceCriteria: ( row.acceptanceCriteria ) ? JSON.stringify( row.acceptanceCriteria ) : null,
					startDate: ( row.taskStartDate ) ? row.taskStartDate : null,
					dueDate: row.taskDueDate,
					completionDate: row.taskCompleteDate,
					taskStatusID: row.taskStatusID,
					taskStatusName: row.taskStatusName,
					projectID: row.projectID,
					projectName: row.projectName,
					projectStartDate: row.projectStartDate,
					projectEndDate: row.projectEndDate,
					projectCompleteDate: row.projectCompleteDate,
					customerStatusName: row.customerStatusName,
					projectStatusDate: row.projectStatusDate,
					skippedReason: row.skippedReason,
					kiCompletedCount: row.kiCompletedCount,
					ownerID: row.ownerID,
					ownerName: row.ownerName,
					delete: row.deleted,
					completedTasks: taskListStatus.completed,
					totalTasks: taskListStatus.total
				});


			} else {

				logger.log({ level: 'error', label: 'GET:api/tasks/taskDetail', message: err, user: req.session.userID })
				return res.status( 500 ).send( 'Unexpected database error' )

			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/tasks/taskDetail', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/workDays', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.taskID ) return res.status( 400 ).send( 'Task ID parameter missing' )

			const SQL	= 	`select `
							+		`format( t.startDate, 'yyyy-MM-dd' ) as taskStartDate, `
							+		`format( t.dueDate, 'yyyy-MM-dd' ) as taskDueDate, `
							+		`format( t.completionDate, 'yyyy-MM-dd' ) as taskCompleteDate, `
							+		`t.taskStatusID, `
							+		`t.estimatedWorkDays, `
							+		`t.actualWorkDays `
							+	`from tasks t `
							+	`where t.id = @taskID `

			const results = await pool.request()
				.input('taskID', sql.BigInt, req.query.taskID )
				.query( SQL );

			const task = results.recordset[0];
			if ( !task ) return res.status(404).send( 'Task not found' );

			const startDate = task.taskStartDate;
			const dueDate = task.taskDueDate;
			const completionDate = task.taskCompleteDate;

			let summary = utilities.workDaysSummary( startDate, dueDate, completionDate );
			summary.estimatedWorkDays = task.estimatedWorkDays;
			summary.actualWorkDays = task.actualWorkDays;

			return res.json( summary );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/tasks/taskDetail', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/checklistsByTask', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.taskID ) return res.status( 400 ).send( 'Task ID parameter missing' )

			let results = []

			let SQL	= 	`select id, name, completed from taskChecklists where taskID = @taskID `
			const checklists = await pool.request()
				.input( 'taskID', sql.BigInt, req.query.taskID )
				.query( SQL )

			for ( checklist of checklists.recordset ) {

				let SQL = `select id, description, completed from taskChecklistItems where checklistID = @checklistID order by seq`
				const checklistItems = await pool.request()
					.input( 'checklistID', sql.BigInt, checklist.id )
					.query( SQL )

				results.push({
					id: checklist.id,
					name: checklist.name,
					completed: checklist.completed,
					items: checklistItems.recordset,
				})


			}

			res.json( results )


		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/tasks/checklistsByTask', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/openItems', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.taskID ) return res.status( 400 ).send( 'taskID missing parameter' );
			const openItems = await getOpenItems( req.query.taskID );
			res.json( openItems );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:apiapi/tasks/openItems', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		}

	});
	//====================================================================================



	//====================================================================================
	https.put('/api/tasks/taskStatus', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID Parameter missing' )
		if ( !req.body.taskStatusID ) return res.status( 400 ).send( 'taskStatusID cannot be blank' )

		const completionDate = ( req.body.taskStatusID != '1' ) ? dayjs().format( 'YYYY-MM-DD' ) : null

		const SQL = `
			SET NOCOUNT ON;
			update tasks set
				taskStatusID = @taskStatusID,
				completionDate = @completionDate,
				updatedBy = @userID,
				updatedDateTime = CURRENT_TIMESTAMP
			where id = @id;
			select dbo.userPermitted( @userID, @permissionID ) as userPermitted;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskStatusID', sql.VarChar( sql.Max ), req.body.taskStatusID )
				.input( 'completionDate', sql.Date, completionDate )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'id', sql.BigInt, req.body.taskID )
				.input( 'permissionID', sql.BigInt, 45 )
				.query( SQL );

		}).then( result => {

			const allowUncomplete = result.recordset[0].userPermitted;
			return res.status(200).json({ allowUncomplete });

		}).catch( err => {

			console.error( err );
			logger.log({ level: 'error', label: 'PUT:api/tasks/taskStatus', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		})


	});
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/taskOwner', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID Parameter missing' )
		if ( !req.body.taskOwnerID ) return res.status( 400 ).send( 'taskOwnerID cannot be blank' )

		let SQL	=	"update tasks set "
					+		"ownerID = @taskOwnerID, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @id "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskOwnerID', sql.VarChar( sql.Max ), req.body.taskOwnerID )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'id', sql.BigInt, req.body.taskID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/taskOwner', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/taskDate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const { taskID, taskDate, targetDate } = req.body;

		if ( !taskID ) return res.status( 400 ).send( 'taskID Parameter missing' )
		if ( !taskDate ) return res.status( 400 ).send( 'task date cannot be blank' )
		if ( !targetDate ) return res.status( 400 ).send( 'target date cannot be blank' )

		const allowedFields = ['startDate', 'dueDate'];
		if ( !allowedFields.includes(targetDate) ) {
			return res.status(400).send('Invalid targetDate field');
		}

		const taskIDInt = parseInt(taskID, 10);

		try {

			const pool = await sql.connect( dbConfig );
			const transaction = new sql.Transaction(pool);

			await transaction.begin();

			const request = new sql.Request(transaction)
				.input( 'taskDate', sql.Date, dayjs( taskDate ).startOf('day').toDate() )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'taskID', sql.BigInt, taskIDInt )

			await request.query( `
				UPDATE tasks SET
					${targetDate} = @taskDate,
					updatedBy = @userID,
					updatedDateTime = CURRENT_TIMESTAMP
				WHERE id = @taskID
			`);

			const result = await request.query( `
				SELECT projectID from tasks where id = @taskID
			` );

			const projectID = result.recordset[0]?.projectID;

			if ( projectID ) {

				const projectRequest = new sql.Request(transaction)
					.input('projectID', sql.BigInt, projectID);

				await projectRequest.query( `
					UPDATE projects SET
						startDate = ( SELECT MIN( startDate ) FROM tasks WHERE projectID = @projectID ),
						endDate = ( SELECT MAX( dueDate ) FROM tasks WHERE projectID = @projectID )
					WHERE id = @projectID
				` );

			}

			await transaction.commit();

			res.status(200).send({ success: true });

		} catch( err ) {
			console.error( 'Transaction failed', err );

			try {
				if ( transaction && transaction._aborted !== true ) {
					await transaction.rollback();
				}
			} catch (rollbackErr) {
				console.error( 'Rollback failed:', rollbackErr );
			}

			logger.log({ level: 'error', label: 'PUT:api/tasks/taskDate', message: err, user: req.session.userID });
			res.sendStatus(500);
		}

	});
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/taskProject', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID parameter missing' );

		const projectID = ( !!req.body.projectID ) ? req.body.projectID : null;

		let SQL	=	`update tasks set `
					+		`projectID = @projectID, `
					+		`updatedBy = @userID, `
					+		`updatedDateTime = CURRENT_TIMESTAMP `
					+	`where id = @taskID `;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'projectID', sql.BigInt, projectID )
				.input( 'taskID', sql.BigInt, req.body.taskID )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL );

		}).then( result => {

			// return res.sendStatus( 200 )
			res.status(200).json({ success: true });

		}).catch( err => {

			console.error( err );
			logger.log({ level: 'error', label: 'PUT:api/tasks/taskProject', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});


	});
	//====================================================================================


	//====================================================================================
	https.post('/api/tasks/taskKeyInitiative', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.keyInitiativeID ) return res.status( 400 ).send( 'taskID parameter missing' )
		if ( !req.body.projectID ) return res.status( 400 ).send( 'projectID parameter missing' )

		let SQL	=	`insert into keyInitiativeProjects ( `
					+		`keyInitiativeID, `
					+		`projectID, `
					+		`updatedBy, `
					+		`updatedDateTime `
					+	`) values ( `
					+		`@keyInitiativeID, `
					+		`@projectID, `
					+		`@userID, `
					+		`CURRENT_TIMESTAMP `
					+	`) `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'keyInitiativeID', sql.BigInt, req.body.keyInitiativeID )
				.input( 'projectID', sql.BigInt, req.body.projectID )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'POST:api/tasks/taskKeyInitiative', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		});

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/tasks/taskKeyInitiative', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.keyInitiativeID ) return res.status( 400 ).send( 'taskID parameter missing' )
		if ( !req.body.projectID ) return res.status( 400 ).send( 'projectID parameter missing' )

		let SQL	=	`delete from keyInitiativeProjects `
					+	`where keyInitiativeID = @keyInitiativeID `
					+	`and projectID = @projectID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'keyInitiativeID', sql.BigInt, req.body.keyInitiativeID )
				.input( 'projectID', sql.BigInt, req.body.projectID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'DELETE:api/tasks/taskKeyInitiative', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		});

	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/checklistName', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.id ) return res.status( 400 ).send( 'id Parameter missing' )
		if ( !req.body.name ) return res.status( 400 ).send( 'name cannot be blank' )

		let SQL	=	"update taskChecklists set "
					+		"name = @name, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @id "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'id', sql.BigInt, req.body.id )
				.input( 'name', sql.VarChar( sql.Max ), req.body.name )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/checklistName', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/acceptanceCriteria', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'id Parameter missing' )
		const acceptanceCriteria = ( !!req.body.acceptanceCriteria ) ? req.body.acceptanceCriteria : ''

		let SQL	=	"update tasks set "
					+		"acceptanceCriteria = @acceptanceCriteria, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @taskID "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskID', sql.BigInt, req.body.taskID )
				.input( 'acceptanceCriteria', sql.VarChar( sql.Max ), acceptanceCriteria )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/acceptanceCriteria', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/taskName', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID Parameter missing' )
		if ( !req.body.name ) return res.status( 400 ).send( 'name cannot be blank' )

		let SQL	=	"update tasks set "
					+		"name = @name, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @taskID "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskID', sql.BigInt, req.body.taskID )
				.input( 'name', sql.VarChar( sql.Max ), req.body.name )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/taskName', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/taskDescription', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID Parameter missing' )
		if ( !req.body.description ) return res.status( 400 ).send( 'description cannot be blank' )

		let SQL	=	"update tasks set "
					+		"description = @description, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @taskID "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskID', sql.BigInt, req.body.taskID )
				.input( 'description', sql.VarChar( sql.Max ), req.body.description )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/taskDescription', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/tasks/checklist', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID Parameter missing' )
		if ( !req.body.name ) return res.status( 400 ).send( 'checklistName cannot be blank' )

		let SQL	=	`insert taskChecklists ( `
					+		`taskID, `
					+		`name, `
					+		`updatedBy, `
					+		`updatedDateTime `
					+	`) values ( `
					+		`@taskID, `
					+		`@name, `
					+		`@userID, `
					+		`CURRENT_TIMESTAMP `
					+	`); `
					+	`select SCOPE_IDENTITY() as id; `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'taskID', sql.BigInt, req.body.taskID )
				.input( 'name', sql.VarChar( sql.Max ), req.body.name )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			res.json({
				id: result.recordset[0].id,
				name: req.body.name,
				completed: false,
				items: []
			})

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'POST:api/tasks/checklist', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/tasks/checklistItem', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.checklistID ) return res.status( 400 ).send( 'checklistID Parameter missing' )
		if ( !req.body.description ) return res.status( 400 ).send( 'checklist description cannot be blank' )

		let SQL	=	`insert taskChecklistItems ( `
					+		`checklistID, `
					+		`description, `
					+		`updatedBy, `
					+		`updatedDateTime `
					+	`) values ( `
					+		`@checklistID, `
					+		`@description, `
					+		`@userID, `
					+		`CURRENT_TIMESTAMP `
					+	`); `
					+	`select SCOPE_IDENTITY() as id; `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'checklistID', sql.BigInt, req.body.checklistID )
				.input( 'description', sql.VarChar( sql.Max ), req.body.description )
				.input( 'userID', sql.BigInt, req.session.userID )
				.query( SQL )

		}).then( result => {

			res.json({
				id: result.recordset[0].id,
				description: req.body.description,
				completed: false,
			})

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'POST:api/tasks/checklistItem', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/tasks/checklist', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.checklistID ) return res.status( 400 ).send( 'checklistID Parameter missing' )

		let SQL	=	`delete from taskChecklists `
					+	`where id = @checklistID; `
					+	`delete from taskChecklistitems `
					+	`where checklistID = @checklistID; `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'checklistID', sql.BigInt, req.body.checklistID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'DELETE:api/tasks/checklist', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/tasks/checklistItem', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.checklistItemID ) return res.status( 400 ).send( 'checklistItemID Parameter missing' )

		let SQL	=	`delete from taskChecklistItems `
					+	`where id = @checklistItemID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'checklistItemID', sql.BigInt, req.body.checklistItemID )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'DELETE:api/tasks/checklistItem', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/checklistItemDescription', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.id ) return res.status( 400 ).send( 'id Parameter missing' )
		if ( !req.body.description ) return res.status( 400 ).send( 'checklistName cannot be blank' )



		let SQL	=	"update taskChecklistItems set "
					+		"description = @description, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @id "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'description', sql.VarChar( sql.Max ), req.body.description )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'id', sql.BigInt, req.body.id )
				.query( SQL )

		}).then( result => {

			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/checklistItemDescription', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.put('/api/tasks/checklistItemStatus', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.id ) return res.status( 400 ).send( 'id Parameter missing' )
		if ( !req.body.completed ) return res.status( 400 ).send( 'completed parameter cannot be blank' )

		// console.log( 'req.body.completed:', req.body.completed )

		let SQL	=	"update taskChecklistItems set "
					+		"completed = @completed, "
					+		"updatedBy = @userID, "
					+		"updatedDateTime = CURRENT_TIMESTAMP "
					+	"where id = @id "

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'completed', sql.Int, req.body.completed )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'id', sql.BigInt, req.body.id )
				.query( SQL )

		}).then( result => {

			// console.log( `teskChecklistItem completed status udpated to ${req.body.completed}` )
			return res.sendStatus( 200 )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'PUT:api/tasks/checklistItemStatus', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/ganttChart', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const tasks = await getTasks(req.query.customerID, req.query.projectID, pool);

			if ( tasks.length > 0 ) {

				cols = [
					{ id: 'taskID', label: 'taskID', type: 'string' },
					{ id: 'taskName', label: 'taskName', type: 'string' },
					{ id: 'resource', label: 'resource', type: 'string' },
					{ id: 'startDate', label: 'startDate', type: 'date' },
					{ id: 'dueDate', label: 'dueDate', type: 'date' },
					{ id: 'duration', label: 'duration', type: 'number' },
					{ id: 'percentComplete', label: 'percentComplete', type: 'number' },
					{ id: 'dependencies', label: 'dependencies', type: 'string' },
					{ id: 'tooltip', label: 'tooltip', type: 'string', role: 'tooltip', p: { html: true } }
				]

				const millisecondsPerDay = 24 * 60 * 60 * 1000;
				const aDay = 86400000 - 1;
				rows = []
				for ( task of tasks ) {

					const tooltip = `Task: ${task.taskName}\nResource: ${task.resource || 'N/A'}\nDuration: ${task.duration}\nPercent Done: ${task.percentComplete || 0}%`;
					// let duration = dayjs(task.dueDate).diff(dayjs(task.startDate)) + millisecondsPerDay;
					let startDate = utilities.date2GoogleDate( dayjs( task.startDate, 'M/D/YYYY' ) );
					let endDate = null;
					let duration = dayjs( task.dueDate ).diff( dayjs( task.startDate ) ) + aDay;


					let percentComplete = 0.00;

					if ( task.completionDate ) {

						percentComplete = 100.00;

					} else if ( task.statusDate ) {

						const start = dayjs( task.startDate );
						const status = dayjs( task.statusDate );
						const due = dayjs( task.dueDate) ;

						if ( status.isAfter(due) ) {
							percentComplete = 100.00;
						} else if ( start.isSameOrBefore(status) && status.isSameOrBefore(due) ) {
							const elapsed = utilities.workDaysBetweenv2( task.startDate, task.statusDate );
							const total = utilities.workDaysBetweenv2( task.startDate, task.dueDate );
							percentComplete = total > 0 ? ( elapsed / total ) * 100.00 : 0.00;
						}

					}

					rows.push({

						c: [
							{ v: task.id },
							{ v: utilities.filterSpecialCharacters( task.name ) },
							{ v: task.resource ? task.resource : null },
							{ v: utilities.date2GoogleDate( dayjs( task.startDate, 'M/D/YYYY' ) ) },
							{ v: utilities.date2GoogleDate( dayjs( task.dueDate, 'M/D/YYYY' ) ) },
							{ v: duration },
							{ v: task.percentComplete ? task.percentComplete : 0 },
							{ v: task.dependencies ? task.dependencies : '' },
							{ v: tooltip }
						]

					});

				}

				res.json({ cols: cols, rows: rows });

			} else {

				res.json({})

			}

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/tasks/ganttChart', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected database error' );

		};

	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/tasks', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.taskID ) return res.status( 400 ).send( 'taskID parameter missing' )

		sql.connect(dbConfig).then( pool => {

			let SQL	= 	`delete from tasks where id = @taskID; `
						+	`delete from keyInitiativeTasks where taskID = @taskID; `

			return pool.request()
				.input( 'taskID', sql.BigInt, req.body.taskID )
				.query( SQL )

		}).then( async results => {

			await updateProjectStartEndDates( req.body.projectID );

			res.status( 200 ).send( 'Task deleted' )

		}).catch( err => {

			logger.log({ level: 'error', label: 'DELETE:api/tasks/', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/projectSummary', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' );

		const SQL	= 	`
			SELECT
				p.id as DT_RowId,
				COALESCE(NULLIF(REPLACE(p.name, 'â„¢', '&trade;'), ''), 'None') AS name,
				t.startDate,
				t.dueDate,
				t.completionDate
			FROM tasks t
			left join projects p on (p.id = t.projectID)
			WHERE t.customerID = @customerID
			AND ( t.taskStatusID = 1 OR t.taskStatusID IS NULL )
			AND ( t.deleted = 0 OR t.deleted IS NULL )
			AND t.completionDate IS NULL
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL );

		}).then( result => {

			const projectMap = new Map();

			for ( const row of result.recordset ) {

				const projectID = row.DT_RowId;

				if ( !projectMap.has( projectID ) ) {
					projectMap.set( projectID, {
						DT_RowId: projectID,
						name: row.name,
						tasksAssigned: 0,
						daysAssigned: 0,
						daysAtRisk: 0,
						daysBehind: 0
					});
				}

				const summary = utilities.workDaysSummary( row.startDate, row.dueDate, row.completionDate );

				const projectSummary = projectMap.get( projectID );
				projectSummary.tasksAssigned++;
				projectSummary.daysAssigned += utilities.workDaysBetweenv2( row.startDate, row.dueDate );
				projectSummary.daysAtRisk  += summary.daysAtRisk;
				projectSummary.daysBehind  += summary.daysBehind;
			}

			res.json({ data: Array.from( projectMap.values() ) });

		}).catch( err => {
			logger.log({ level: 'error', label: 'controllers/tasks.js', message: 'error in tasks/projectSummary starting...', err });
			throw err
		})

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/ownerSummary', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID parameter missing' );

		const SQL	= 	`
			SELECT
				c.name,
				t.startDate,
				t.dueDate,
				t.completionDate
			FROM tasks t
			LEFT JOIN customerContacts c ON c.id = t.ownerID
			WHERE t.customerID = @customerID
			AND ( t.taskStatusID = 1 OR t.taskStatusID IS NULL )
			AND ( t.deleted = 0 OR t.deleted IS NULL )
			AND t.completionDate IS NULL
		`;

		sql.connect(dbConfig).then(pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL );

		}).then(result => {

			const ownerMap = new Map();

			for ( const row of result.recordset ) {

				const ownerName = row.name || 'Unassigned'; // fallback just in case

				if ( !ownerMap.has(ownerName) ) {
					ownerMap.set(ownerName, {
						name: ownerName,
						tasksAssigned: 0,
						daysAssigned: 0,
						daysAtRisk: 0,
						daysBehind: 0
					});
				}

				const summary = utilities.workDaysSummary( row.startDate, row.dueDate, row.completionDate );

				// console.log({ name: row.name, summary: summary });

				const owner = ownerMap.get( ownerName );
				owner.tasksAssigned++;
				owner.daysAssigned += utilities.workDaysBetweenv2( row.startDate, row.dueDate );
				owner.daysAtRisk  += summary.daysAtRisk;
				owner.daysBehind  += summary.daysBehind;
			}

// debugger
			res.json({ data: Array.from(ownerMap.values()) });

		}).catch(err => {

			console.error('error in /api/tasks/ownerSummary', err);
			res.status(500).send('Internal server error');

		});

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/tasks/openTasksByCustomer', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if (!req.query.customerID) return res.status(400).send('customerID Parameter missing');

			const SQL =	`select ` +
				`t.dueDate, ` +
				`t.ownerID, ` +
				`c.firstName, ` +
				`c.lastName ` +
			`from tasks t ` +
			`left join customerContacts c on (c.id = t.ownerID) ` +
			`where t.completionDate is null ` +
			`and (t.deleted = 0 or t.deleted is null) ` +
			`and t.customerID = @customerID`;

		sql.connect(dbConfig).then(pool => {

			return pool.request()
				.input('customerID', sql.BigInt, req.query.customerID)
				.query(SQL);

		}).then(result => {

			const tasks = result.recordset;

			// Aggregate in Node
			const summary = {};

			tasks.forEach(task => {

				const { dueDate, firstName, lastName } = task;
				const ownerName = (firstName && lastName) ? `${firstName} ${lastName}` : 'Unassigned';

				if (!summary[ownerName]) {
					summary[ownerName] = {
						ownerName,
						taskCount: 0,
						daysBehind: 0
					};
				}

				// Calculate daysBehind using your own utility
				summary[ownerName].taskCount += 1;
				summary[ownerName].daysBehind += utilities.workDaysBetweenv2(dueDate, new Date());

			});

			// Convert to array and sort
			const data = Object.values(summary).sort((a, b) => b.daysBehind - a.daysBehind);

			res.json({ data });

		}).catch(err => {

			console.error('Error in /openTasksByCustomer:', err);
			res.status(500).send('Internal server error');

		});


	});
	//====================================================================================


	//====================================================================================
	function getTaskChecklistStatus( taskID ) {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	=	`select `
						+		`sum(case when  tci.completed = 1 then 1 else 0 end) as completed, `
						+		`count(*) as total `
						+	`from taskChecklists tc `
						+	`join taskChecklistItems tci on (tci.checklistID = tc.id) `
						+	`where tc.taskID = @taskID `

			sql.connect(dbConfig).then( pool => {

				return pool.request()
					.input( 'taskID', sql.BigInt, taskID )
					.query( SQL)

			}).then( results => {

				let completed = results.recordset[0].completed ? results.recordset[0].completed : 0
				return resolve({
					completed: completed,
					total: results.recordset[0].total
				})

			}).catch( err => {
				logger.log({ level: 'error', label: 'tasks/getTaskChecklistStatus()', message: err })
				return reject( err )
			})

		})

	}
	//====================================================================================


	//====================================================================================
	async function updateProjectStartEndDates( projectID ) {
	// ====================================================================================
		try {

			let SQL 	=	`UPDATE projects SET `
						+		`startDate = ( SELECT MIN(t.startDate) FROM tasks t WHERE t.projectID = projects.id ), `
						+		`endDate = ( SELECT MAX(t.dueDate) FROM tasks t WHERE t.projectID = projects.id ), `
						+		`updatedDateTime = CURRENT_TIMESTAMP `
						+	`WHERE id = @projectID; `

			await pool.request()
				.input('projectID', sql.BigInt, projectID)
				.query( SQL );

		} catch (err) {
			console.error('Error in updateProject:', err);
			throw err;
		}
	}
	//====================================================================================


	//====================================================================================
	async function getTasks(customerID, projectID, pool) {
	//====================================================================================

		if (!customerID && !projectID) {
			throw new Error('Either customerID or projectID must be provided.');
		}

		try {

			const request = pool.request();

			if (projectID) {
				request.input( 'projectID', sql.BigInt, projectID );

				const result = await request.query(`
					SELECT DISTINCT
						t.*,
						concat( c.firstName, ' ', c.lastName ) as resource,
						ts.name as taskStatusName
					FROM dbo.tasks t
					LEFT JOIN projects p ON t.projectID = p.id
					LEFT JOIN customerContacts c ON c.id = t.ownerID
					LEFT JOIN taskStatus ts ON ts.id = t.taskStatusID
					WHERE t.projectID = @projectID;
				`);

				return result.recordset;

			} else {

				request.input('customerID', sql.BigInt, customerID);

				const result = await request.query(`
					SELECT DISTINCT
						t.*,
						concat( c.firstName, ' ', c.lastName ) as resource
					FROM dbo.tasks t
					LEFT JOIN projects p ON t.projectID = p.id
					LEFT JOIN customerContacts c ON c.id = t.ownerID
					WHERE (t.customerID = @customerID OR p.customerID = @customerID);
				`);

				return result.recordset;

			}

		} catch (err) {

			console.error('Error fetching tasks:', err);
			throw new Error('Failed to fetch tasks from the database.');

		}

	}
	//====================================================================================


	//====================================================================================
	async function getOpenItems( taskID ) {
	//====================================================================================

		try {

			const SQL = `
			WITH baseTasks AS (
				SELECT t.id
				FROM tasks t
				WHERE t.id = @taskID
			),
			openChecklists AS (
				SELECT tc.id
				FROM taskChecklists tc
				JOIN baseTasks t ON t.id = tc.taskID
				WHERE ISNULL( tc.completed, 0 ) = 0
			),
			openItems AS (
				SELECT tci.id
				FROM taskChecklistItems tci
				JOIN openChecklists tc ON tc.id = tci.checklistID
				WHERE ISNULL( tci.completed, 0 ) = 0
			)
			SELECT
				(SELECT COUNT(*) FROM openChecklists) as openCheckLists,
				(SELECT COUNT(*) FROM openItems) AS openChecklistItems;
			`;

			const results = await pool.request()
				.input( 'taskID', sql.BigInt, taskID )
				.query( SQL );

			return results.recordset[0];

		} catch( err ) {

			logger.log({ level: 'error', label: 'getOpenItems()', message: 'Error counting open items for a project:', user: null });
			logger.log({ level: 'error', label: 'getOpenItems()', message: err, user: null });
			throw new Error( err );
		}

	}
	//====================================================================================

}
