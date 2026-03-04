// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = async function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const pool = await sql.connect( dbConfig );

	//====================================================================================
	https.get('/api/projectTemplates', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			let SQL	= 	`
				SELECT
					pt.id,
					pt.name,
					u.updatedBy,
					concat( u.firstName, ' ', u.lastName ) as updatedByName,
					pt.updatedDateTime
				FROM 	projectTemplates pt
				LEFT JOIN csuite..users u on (u.id = pt.updatedBy )
				ORDER BY	pt.name
			`;

			const results = await pool.request().query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET.projectTemplates', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected database error' );

		}

	});
	//====================================================================================


	//====================================================================================
	https.post('/api/projectTemplates', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.sourceProjectID) return res.status( 400 ).send( 'source project id parameter missing' );
		if ( !req.body.targetTemplateName ) return res.status( 400 ).send( 'target template name parameter missing' );

		const sourceProjectID =  req.body.sourceProjectID;
		const targetTemplateName = req.body.targetTemplateName;
		// const { sourceProjectID, targetTemplateName: rawName } = req.body;
		// let targetTemplateName = rawName;
		let suffix = '';

		try {

			const request = pool.request();
			request.input( 'targetTemplateName', sql.NVarChar, targetTemplateName );

			// Delete existing project template and descendents
			await request.query(`
				delete from projectTemplateTaskChecklistItems
				where projectTemplateTaskChecklistID in (
					select c.id
					from projectTemplateTaskChecklists c
					join projectTemplateTasks b on b.id = c.projectTemplateTaskID
					join projectTemplates a on a.id = b.projectTemplateID
					where a.name = @targetTemplateName
				);

				delete from projectTemplateTaskChecklists
				where projectTemplateTaskID in (
					select b.id
					from projectTemplateTasks b
					join projectTemplates a on a.id = b.projectTemplateID
					where a.name = @targetTemplateName
				);

				delete from projectTemplateTasks
				where projectTemplateID in (
					select a.id
					from projectTemplates a
					where a.name = @targetTemplateName
				);

				delete from projectTemplates
				where name = @targetTemplateName;
			`);

			// Generate new template ID
			const projectTemplateID = await utilities.GetNextID( 'projectTemplates' );

			await pool.request()
				.input( 'id', sql.BigInt, projectTemplateID )
				.input( 'name', sql.NVarChar, targetTemplateName )
				.input( 'updatedBy', sql.Int, req.session.userID )
				.query( `
					insert into projectTemplates (id, name, updatedBy, updatedDateTime)
					values (@id, @name, @updatedBy, CURRENT_TIMESTAMP)
				` );

			// Clone tasks
			const taskResult = await pool.request()
				.input( 'projectID', sql.BigInt, sourceProjectID )
				.query( `
					select t.id, t.name, t.description, t.startDate, t.dueDate, t.estimatedWorkDays,
							t.dependencies, t.acceptanceCriteria,
							p.startDate as projectStartDate, p.endDate as projectEndDate
					from tasks t
					join projects p on p.id = t.projectID
					where t.projectID = @projectID
				` );

				const { minStart, maxDue } = (taskResult.recordset || []).reduce((acc, row) => {
					const start = row.startDate ? dayjs(row.startDate) : null;
					const due   = row.dueDate   ? dayjs(row.dueDate)   : null;

					if (start && (!acc.minStart || start.isBefore(acc.minStart))) acc.minStart = start;
					if (due   && (!acc.maxDue   || due.isAfter(acc.maxDue)))     acc.maxDue   = due;

					return acc;
				}, { minStart: null, maxDue: null });

			// console.log({
			// 	minStart: dayjs( minStart ).format( 'MM/DD/YYYY' ),
			// 	maxDue: dayjs( maxDue ).format( 'MM/DD/YYYY' )
			// });

			const projectStartDate = utilities.isWorkday( minStart ) ? minStart : getNearestWorkday( 'before', minStart );
			const projectEndDate = utilities.isWorkday( maxDue ) ? maxDue : getNearestWorkday( 'after', maxDue );

			for ( const task of taskResult.recordset )  {

				const taskName 					= task.name ?? null;
				const taskDescription 			= task.description ?? null;
				const estimatedWorkDays 		= task.estimatedWorkDays ?? null;
				const dependencies				= task.dependencies ?? null;
				const acceptanceCriteria		= task.acceptanceCriteria ?? null;

				const taskStartDate = utilities.isWorkday( task.startDate ) ? task.startDate : getNearestWorkday( 'before', task.startDate );
				const taskDueDate = utilities.isWorkday( task.dueDate ) ? task.dueDate : getNearestWorkday( 'after', task.dueDate );


				const startOffsetDays 			= utilities.workDaysBetweenv2( projectStartDate, taskStartDate ) - 1;
				const taskDurationDays 			= utilities.workDaysBetweenv2( taskStartDate, taskDueDate );
				const endOffsetDays 				= utilities.workDaysBetweenv2( taskDueDate, projectEndDate ) - 1;

				// console.log({
				// 	taskName: taskName,
				// 	projectStartDate: dayjs( projectStartDate ).format( 'MM/DD/YYYY'),
				// 	projectEndDate: dayjs( projectEndDate ).format( 'MM/DD/YYYY' ),
				// 	taskStartDate: dayjs( taskStartDate ).format( 'MM/DD/YYYY' ),
				// 	taskDueDate: dayjs( taskDueDate ).format( 'MM/DD/YYYY' ),
				// 	startOffsetDays: startOffsetDays,
				// 	taskDurationDays: taskDurationDays,
				// 	endOffsetDays: endOffsetDays
				// });


				const projectTemplateTaskID	= await utilities.GetNextID( 'projectTemplateTasks' );

				await pool.request()
					.input( 'id', sql.BigInt, projectTemplateTaskID )
					.input( 'name', sql.NVarChar, taskName )
					.input( 'description', sql.NVarChar, taskDescription )
					.input( 'startOffsetDays', sql.Int, startOffsetDays )
					.input( 'taskDurationDays', sql.Int, taskDurationDays)
					.input( 'endOffsetDays', sql.Int, endOffsetDays )
					.input( 'estimatedWorkDays', sql.Int, estimatedWorkDays )
					.input( 'dependencies', sql.NVarChar, dependencies )
					.input( 'projectTemplateID', sql.BigInt, projectTemplateID )
					.input( 'acceptanceCriteria', sql.NVarChar, acceptanceCriteria )
					.query( `
						insert into projectTemplateTasks (
							id, name, description, startOffsetDays, taskDurationDays, endOffsetDays,
							estimatedWorkDays, dependencies, projectTemplateID, acceptanceCriteria
						)
						values (
							@id, @name, @description, @startOffsetDays, @taskDurationDays, @endOffsetDays,
							@estimatedWorkDays, @dependencies, @projectTemplateID, @acceptanceCriteria
						)
					` );

				// Clone checklists
				const checklistResult = await pool.request()
					.input( 'taskID', sql.BigInt, task.id )
					.query( `select * from taskChecklists where taskID = @taskID` );

				for (const checklist of checklistResult.recordset) {

					const checklistID = await utilities.GetNextID( 'projectTemplateTaskChecklists' );
					const checklistName = checklist.name ?? null;

					await pool.request()
						.input( 'id', sql.BigInt, checklistID )
						.input( 'taskID', sql.BigInt, projectTemplateTaskID )
						.input( 'name', sql.NVarChar, checklistName )
						.query( `
							insert into projectTemplateTaskChecklists (id, projectTemplateTaskID, name)
							values (@id, @taskID, @name)
						` );

					// Clone checklist items
					const itemResult = await pool.request()
						.input( 'checklistID', sql.BigInt, checklist.id )
						.query( `select * from taskChecklistItems where checklistID = @checklistID` );

					for (const item of itemResult.recordset) {

						const checklistItemID = await utilities.GetNextID( 'projectTemplateTaskChecklistItems' );
						const itemDescription = item.description ?? null;

						await pool.request()
							.input( 'id', sql.BigInt, checklistItemID )
							.input( 'checklistID', sql.BigInt, checklistID )
							.input( 'description', sql.NVarChar, itemDescription )
							.query( `
								insert into projectTemplateTaskChecklistItems (id, projectTemplateTaskChecklistID, description)
								values (@id, @checklistID, @description)
							` );

					}

				}

			}

			res.sendStatus( 200 );

		} catch (err) {
			console.error( 'Error creating template from project:', err );
			res.status( 500 ).send( 'Server error' );
		}
	});
	//====================================================================================


	//====================================================================================
	https.delete('/api/projectTemplates/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.params.id ) return res.status( 400 ).send( 'template ID parameter missing' )

		try {

			let SQL	= 	`
				delete from projectTemplateTaskChecklistItems
				where projectTemplateTaskChecklistID in (
					select c.id
					from projectTemplateTaskChecklists c
					join projectTemplateTasks b on b.id = c.projectTemplateTaskID
					join projectTemplates a on a.id = b.projectTemplateID
					where a.id = @id
				);
				delete from projectTemplateTaskChecklists
				where projectTemplateTaskID in (
					select b.id
					from projectTemplateTasks b
					join projectTemplates a on a.id = b.projectTemplateID
					where a.id = @id
				);
				delete from projectTemplateTasks
				where projectTemplateID in (
					select a.id
					from projectTemplates a
					where a.id = @id
				);
				delete from projectTemplates
				where id = @id;
			`;

		const results = await pool.request()
			.input( 'id', sql.BigInt, req.params.id )
			.query( SQL );


			return res.sendStatus( 200 )

		} catch( err ) {

			logger.log({ level: 'error', label: 'DELETE.projectTemplates', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected database error' );

		}

	});
	//====================================================================================


	//====================================================================================
	function getNearestWorkday( direction, date ) {
	//====================================================================================

		const step = ( direction === 'before' ? -1 : 1 );
		let d = dayjs( date );

		do {
			d = d.add( step, 'day' );
		} while ( !utilities.isWorkday( d ) );

		return d;
	}
	//====================================================================================


}
