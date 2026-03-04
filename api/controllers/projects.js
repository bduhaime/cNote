 32// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const utilities 	= require( '../utilities' );


	//====================================================================================
	https.get('/api/projects/byCustomer', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'customerID missing parameter' );

		let kiID = kiJoin = '';
		let = kiProjection = ', null as kiID ';
		if ( !!req.query.keyInitiativeID ) {
			kiID = req.query.keyInitiativeID;
			kiJoin	=	`left JOIN keyInitiativeProjects kip ON ( kip.projectID = p.id AND kip.keyInitiativeID = ${kiID}) `
						+	`left join keyInitiatives ki on ( ki.id = kip.keyInitiativeID AND ki.customerID = @customerID ) `;
			kiProjection = `, ki.id as kiID `;
		}

		let taskID = taskJoin = '';
		let taskProjection = `, null as taskID `;
		if ( !!req.query.taskID ) {
			taskID = req.query.taskID;
			taskJoin = `left join tasks t on (t.projectID = p.id and t.id = ${taskID} ) `;
			taskProjection = `, t.id as taskID `;
		}

		const db = await sql.connect( dbConfig );

		try {

			let SQL	=	`SELECT `
						+		`p.id, `
						+		`p.name, `
						+		`prod.name as productName, `
						+		`format ( p.startDate, 'M/d/yyyy' ) AS startDate, `
						+		`format ( p.endDate, 'M/d/yyyy' ) AS endDate, `
						+		`format ( p.completeDate, 'M/d/yyyy' ) AS completeDate, `
						+		`p.projectManagerID, `
						+		`p.generatedFrom, `
						+		`pt.name as generatedFromTemplateName, `
						+		`concat ( gu.firstName, ' ', gu.lastName ) AS generatedBy, `
						+		`p.generatedDateTime, `
						+		`concat(u.firstName, ' ', u.lastName) as projectManagerName, `
						+		`cu.clientID, `
						+		`uc.customerID, `
						+		`c.name as customerName `
						+		`${kiProjection} `
						+		`${taskProjection } `
						+		`FROM projects p `
						+		`left join products prod on (prod.id = p.productID) `
						+		`${kiJoin} `
						+		`${taskJoin} `
						+		`left join csuite..users u on (u.id = p.projectManagerID) `
						+		`left join csuite..clientUsers cu on (cu.userID = u.id and cu.clientID = @clientNbr ) `
						+		`LEFT JOIN csuite..users gu on (gu.id = p.generatedBY) `
						+		`left join userCustomers uc on (uc.userID = u.id and uc.customerID = 1) `
						+		`LEFT JOIN projectTemplates pt on (pt.id = p.generatedFromTemplateID) `
						+		`LEFT JOIN customer c on (c.id = p.customerID) `
						+		`WHERE ( p.deleted = 0 OR p.deleted IS NULL ) `
						+		`and p.customerID = @customerID `

			const results = await  db.request()
				.input( 'clientNbr', sql.BigInt, req.session.clientNbr )
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL );

			let finalResults = []
			for ( row of results.recordset ) {

				finalResults.push({
					id: row.id,
					name: utilities.filterSpecialCharacters( row.name ),
					productName: utilities.filterSpecialCharacters( row.productName ),
					startDate: row.startDate,
					endDate: row.endDate,
					completeDate: row.completeDate,
					projectManagerID: row.projectManagerID,
					generatedFrom: row.generatedFrom,
					generatedFromTemplateName: row.generatedFromTemplateName,
					generatedBy: row.generatedBy,
					generatedDateTime: row.generatedDateTime,
					projectManagerName: row.projectManagerName,
					clientID: row.clientID,
					customerID: row.customerID,
					customerName: row.customerName,
					kID: row.kID,
					taskID: row.taskID
				});

			}

			res.setHeader('Content-Type', 'application/json; charset=utf-8');
			res.json( finalResults );

		} catch( err ) {

			console.error('Error in projects/byCustomer:', err);
			throw new Error( err );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/projects/projectDetail', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.projectID ) return res.status( 400 ).send( 'projectID missing parameter' )

		let SQL	= 	`select `
					+		`id, `
					+		`name, `
					+		`customerID, `
					+		`productID, `
					+		`format( startDate, 'yyyy-MM-dd' ) as startDate, `
					+		`format( endDate, 'yyyy-MM-dd' ) as endDate, `
					+		`complete, `
					+		`projectManagerID, `
					+		`completeDate `
					+	`from projects `
					+	`where id = @projectID `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'projectID', sql.BigInt, req.query.projectID )
				.query( SQL )

		}).then( result => {

			const row = result.recordset[0]

			res.json({
				id: row.id,
				name: utilities.filterSpecialCharacters( row.name ),
				customerID: row.customerID,
				productID: row.productID,
				startDate: row.startDate,
				endDate: row.endDate,
				complete: row.complete,
				projectManagerID: row.projectManagerID,
				completeDate: row.completeDate,
			})

		}).catch( err => {

			console.error( err )
			res.status( 500 ).send( 'Unexpected database error' )


		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/projects/openItems', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.projectID ) return res.status( 400 ).send( 'projectID missing parameter' );

		const openItems = await getOpenItems( req.query.projectID );
		const massCompletePermission = await utilities.UserPermitted( req.session.userID, 44 );
		const uncompletePermission = await utilities.UserPermitted( req.session.userID, 45 );

		res.json({ openItems, massCompletePermission, uncompletePermission });


	});
	//====================================================================================


	//====================================================================================
	https.get('/api/projects/projectStatus', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.projectID ) return res.status( 400 ).send( 'projectID missing parameter' )

			const SQL =	`
				select top 1
					projectID,
					type as status,
					format( statusDate, 'yyyy-MM-dd' ) as statusDate,
					comments
				from projectStatus
				where projectID = @projectID
				order by updatedDateTime desc;
			`;

			const results = await pool.request()
					.input( 'projectID', sql.BigInt, req.query.projectID )
					.query( SQL );

			const status = results.recordset?.[0] ?? null;
			return res.json( status );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/projects/projectStatus', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		};

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/projects/projectStatusHistory', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.projectID ) return res.status( 400 ).send( 'projectID missing parameter' )

		const SQL =	`
			SELECT
				ps.id,
				ps.[type] AS statusName,
				CONVERT( char(10), ps.statusDate, 23 ) AS statusDate, -- yyyy-MM-dd
				CONCAT( u.firstName, ' ', u.lastName ) AS updatedBy,
				ps.comments,
				ps.updatedDateTime,
				CAST( CASE WHEN ROW_NUMBER() OVER ( ORDER BY ps.updatedDateTime DESC, ps.id DESC ) = 1 THEN 1 ELSE 0 END AS bit ) AS isCurrent
			FROM projectStatus ps
			LEFT JOIN csuite.dbo.[users] u ON ( u.id = ps.updatedBy )
			WHERE ps.projectID = @projectID
			ORDER BY ps.updatedDateTime DESC, ps.id DESC;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'projectID', sql.BigInt, req.query.projectID )
				.query( SQL );

		}).then( results => {

			res.json( results.recordset );

		}).catch( err => {

			console.error( err )
			res.status( 500 ).send( 'Unexpected database error' )


		});

	});
	//====================================================================================


	//====================================================================================
	https.put('/api/projects/updateStatus', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.projectID ) return res.status( 400 ).json({ ok: false, error: 'Missing parameter' });
		if ( !req.body.projectStatusDate ) return res.status( 400 ).json({ ok: false, error: 'Missing parameter' });
		if ( !req.body.projectStatusType ) return res.status( 400 ).json({ ok: false, error: 'Missing parameter' });

		let projectStatusComments = req.body.projectStatusComments ? req.body.projectStatusComments : ''
		let projectStatus = null

		switch ( req.body.projectStatusType ) {

			//------------------------------------------------------------------------------
			case 'On Time':
			case 'Behind':
			//------------------------------------------------------------------------------

				try {

					const projectStatus = await updateProjectStatus(
						req.body.projectID,
						req.body.projectStatusType,
						req.body.projectStatusDate,
						req.session.userID,
						projectStatusComments
					);

					return res.status( 200 ).json( { ok: true } );

				} catch( err ) {

					logger.log({ level: 'error', label: 'PUT:projects/updateStatus', message: 'Error encountered while updating on-time/behind status', user: req.session.userID });

					return res.status( 500 ).json({ ok: false, error: 'Unexpected database error' });

				}

				break;


			//------------------------------------------------------------------------------
			case 'Escalate':
			case 'Reschedule':
			//------------------------------------------------------------------------------

				try {

					const projectStatus = await updateProjectStatus(
						req.body.projectID,
						req.body.projectStatusType,
						req.body.projectStatusDate,
						req.session.userID,
						projectStatusComments
					);

					const permissionID = req.body.projectStatusType == 'Escalate' ? 24 : 25
					const recipients = await utilities.usersWithPermission( permissionID );
					const projectInfo = await getProjectInfo( req.body.projectID );
					const userInfo = await utilities.getUserInfo( req.session.userID );

					let recipientList = [];
					for ( recipient of recipients ) {
						recipientList.push( recipient );
					}

					const requestedBy = userInfo.firstName.trim() + ' ' + userInfo.lastName.trim();

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
					});

					const html = `
						<html><body>Escalation has been requested on a project<br><br>
							<table style="margin-left: 20px">
								<tr><td style="font-weight: bold;" nowrap>Customer Name:&nbsp;</td><td>${projectInfo.customerName}</td></tr>
								<tr><td style="font-weight: bold;" nowrap>Project Name:&nbsp;</td><td>${projectInfo.projectName}</td></tr>
								<tr><td style="font-weight: bold;" nowrap>Project Status:&nbsp;</td><td>${req.body.projectStatusType}</td></tr>
								<tr><td style="font-weight: bold;" nowrap>Requested By:&nbsp;</td><td>${requestedBy}</td></tr>
								<tr><td style="font-weight: bold;" nowrap>Comments:&nbsp;</td><td>${req.body.projectStatusComments}</td></tr>
							</table>
						</body></html>
					`;

					const text = `
						Escalation has been requested on a project\n\n\tCustomer Name: ${projectInfo.customerName}\n
							\tProject Name: ${projectInfo.projectName}\n
							\tProject Status: ${req.body.projectStatusType}\n
							\tRequested By: ${requestedBy}\n
							\tComments: ${req.body.projectStatusComments}
					`;

					let envTag  = process.env.ENVIRONMENT ? '[' + process.env.ENVIRONMENT + ']' : '';
					let subject = `cNote: Project ${req.body.projectStatusType} Request ${envTag}	`;

					let email = transporter.sendMail({
						from: process.env.CLIENT_EMAIL_USER,
						replyTo: process.env.CLIENT_EMAIL_REPLYTO,
						to: recipientList,
						subject: subject,
						text: text,
						html: html
					});

					logger.log({ level: 'info', label: '/api/projects', message: 'project escalation email sent', user: null });

					return res.status( 200 ).json( { ok: true } );

				} catch( err ) {

					logger.log({ level: 'error', label: '/api/projects', message: 'project escalation email failed to send: '+ err, user: null });

					return res.status( 500 ).json({ ok: false, error: 'Project escalation email failed to send' });

				}

				break;


			//------------------------------------------------------------------------------
			case 'Complete':
			//------------------------------------------------------------------------------

				try {

					const openItems = await getOpenItems( req.body.projectID );
					const openItemCount = openItems.openTasks + openItems.openChecklists + openItems.openChecklistItems;
					const userHasMassUpdate = await utilities.UserPermitted( 44 );

					// check to see if the project is completable for this users...
					if ( openItemCount > 0 ) {
						if ( !userHasMassUpdate ) {
							// user cannot complete a project with open items..
							logger.log({ level: 'warning', label: '/api/projects', message: 'User cannot complete a project with open items', user: null });
							return res.status( 201 ).json({ ok: false, error: 'User cannot complete a project with open items' });
						}
					}

					// no longer need to complete all the items in the hierarchy...
					// const completeItems = await completeTaskChecklistItems( req.body.projectID );
					// const completeChecklists = await completeTaskChecklists( req.body.projectID );
					// const completeTasks = await completeTasks( req.body.projectID );

					const projectStatus = await updateProjectStatus(
						req.body.projectID,
						req.body.projectStatusType,
						req.body.projectStatusDate,
						req.session.userID,
						projectStatusComments
					);

					logger.log({ level: 'debug', label: '/api/projects', message: 'Project complete status update successfull', user: null });

					return res.status( 200 ).json( { ok: true } );

				} catch( err ) {

					logger.log({ level: 'error', label: '/api/projects', message: 'Project complete status update failed', user: null });

					return res.status( 500 ).json({ ok: false, error: 'Project status update failed' });

				}

				break;


			//------------------------------------------------------------------------------
			default:
			//------------------------------------------------------------------------------

				logger.log({ level: 'error', label: '/api/projects', message: 'unexpected project status type encountered', user: null });

				return res.status( 400 ).json({ ok: false, error: 'Unexpected parameter value' });

		}

	});
	//====================================================================================


	//====================================================================================
	https.post( '/api/projects/fromScratch', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.name ) return res.status( 400 ).send( 'Name required' );
		if ( !req.body.customerID ) return res.status( 400 ).send( 'CustomerID required' );
		// if ( !req.body.startDate ) return res.status( 400 ).send( 'Start Date required' );
		// if ( !req.body.endDate ) return res.status( 400 ).send( 'End Date required' );
		// if ( !req.body.projectManagerID ) return res.status( 400 ).send( 'Project Manager required' );

		const	db = await sql.connect( dbConfig );

		try {

			const projectInfo = {
				projectName: req.body.name,
				customerID: req.body.customerID,
				startDate: req.body.startDate,
				endDate: req.body.endDate,
				projectManagerID: req.body.projectManagerID,
				generatedFrom: null,
				generatedFromTemplateID: null,
				userID: req.session.userID,
			}

			const projectID = await addProject( db, projectInfo );

			res.status( 201 ).send( 'Project created successfully' );

		} catch( err ) {

				res.status( 500 ).send( 'Failed to create project' );

		}


	});
	//====================================================================================


	//====================================================================================
	https.post( '/api/projects/fromTemplate', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.body.customerID ) return res.status( 400 ).send( 'Missing customerID parameter' );
		if ( !req.body.name ) return res.status( 400 ).send( 'Missing name parameter' );
		if ( !req.body.product ) return res.status( 400 ).send( 'Missing product parameter' );
		// if ( !req.body.projectManagerID ) return res.status( 400 ).send( 'Missing projectManagerID parameter' );
		if ( !req.body.anchorDateType ) return res.status( 400 ).send( 'Missing anchorDateType parameter' );
		if ( !req.body.anchorDate ) return res.status( 400 ).send( 'Missing anchorDate parameter' );

		const templateID = req.body.product;
		const db = await sql.connect( dbConfig );
		let templateTasks, templateChecklists, templateChecklistItems, projectDurationDays, startDate, endDate;

		try {

			// Fetch template tasks
			const templateTasks = await getTemplateTasks( db, templateID );

			// Iterate over tasks and fetch checklists
			const tasksWithChecklists = await Promise.all(
				templateTasks.map( async ( task ) => {

					const checklists = await getTemplateChecklists( db, task.id );

					// Iterate over checklists and fetch checklist items
					const checklistsWithItems = await Promise.all(
						checklists.map( async ( checklist ) => {
							const items = await getTemplateChecklistItems( db, checklist.id) ;
							return { ...checklist, items };
						})
					);

				return { ...task, checklists: checklistsWithItems };

				})

			);

			const projectInfo = {
				projectName: req.body.name,
				customerID: req.body.customerID,
				startDate: startDate,
				endDate: endDate,
				projectManagerID: ( !!req.body.projectManagerID ) ? req.body.projectManagerID : null,
				generatedFrom: 'template',
				generatedFromTemplateID: templateID,
				userID: req.session.userID,
			}

			// transaction = await new sql.Transaction( db );

			// await transaction.begin();
			const projectID = await addProject( db, projectInfo );

			// console.log({ "project added": projectInfo });

			for ( task of tasksWithChecklists ) {

				try {

					task.projectID = projectID;
					task.userID = req.session.userID;
					task.customerID = req.body.customerID;
					const taskDurationDays = parseInt( task.taskDurationDays, 10 );
					const taskStartOffsetDays = parseInt( task.startOffsetDays, 10 );
					const taskEndOffsetDays = parseInt( task.endOffsetDays, 10 );

					if ( req.body.anchorDateType === 'start' ) {
						task.startDate = await utilities.workDaysAddv2( req.body.anchorDate, taskStartOffsetDays );
						task.dueDate = await utilities.workDaysAddv2( task.startDate, taskDurationDays - 1 );
					} else {
						task.dueDate = await utilities.workDaysAddv2( req.body.anchorDate, -taskEndOffsetDays );
						task.startDate = await utilities.workDaysAddv2( task.dueDate, -taskDurationDays + 1 );
					}

					let taskID = await addProjectTask( db, task );

					for ( checklist of task.checklists) {

						try {

							checklist.taskID = taskID;
							checklist.userID = req.session.userID;
							let checklistID = await addProjectChecklist( db, checklist );

							for ( item of checklist.items ) {

								try {

									item.checklistID = checklistID;
									item.userID = req.session.userID;
									await addProjectChecklistItem( db, item );

								} catch( err ) {

									console.error( 'project from template failed processing checklist items', err )
									res.status( 500 ).send( 'Failed processing checklist items' );

								}

							}

						} catch( err ) {

							console.error( 'project from template failed processing checklists', err )
							res.status( 500 ).send( 'Failed processing checklists' );

						}

					}

				} catch( err ) {
					console.error( 'project from template failed processing tasks', err )
					res.status( 500 ).send( 'Failed processing tasks' );

				}

			}

			await updateProjectStartEndDates( db, projectID );


			res.status( 201 ).send( 'Project created successfully' );

		} catch( err ) {

			// if ( transaction ) {
			// 	await transaction.rollback();
			// }
			console.error( `failed to create project: ${err}` );
			res.status( 500 ).send( 'Failed to create project' );

		}

	});
	//====================================================================================


	//====================================================================================
	https.put( '/api/projects', utilities.jwtVerify, async (req, res) => {
	//====================================================================================
debugger
		if ( !req.body.projectID ) return res.status( 400 ).send( 'Missing projectID parameter' );
		if ( !req.body.customerID ) return res.status( 400 ).send( 'Missing customerID parameter' );

		const db = await sql.connect( dbConfig );

		try {

			let SQL	=	`UPDATE projects SET `
						+		`name = @name, `
						+		`projectManagerID = @projectManagerID, `
						+ 		`startDate = @startDate, `
						+		`endDate = @endDate, `
						+		`updatedBy = @userID, `
						+		`updatedDateTime = CURRENT_TIMESTAMP `
						+	`WHERE id = @projectID `
						+	`AND customerID = @customerID; `

			const results = await  db.request()
				.input( 'name', sql.NVarChar(80), req.body.name )
				.input( 'projectManagerID', sql.BigInt, req.body.projectManagerID )
				.input( 'startDate', sql.Date, dayjs(req.body.startDate).toDate() )
				.input( 'endDate', sql.Date, dayjs(req.body.endDate).toDate() )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'projectID', sql.BigInt, req.body.projectID )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.query( SQL );

			return res.sendStatus( 200 );

		} catch( err ) {

			res.status( 500 ).send( 'Failed to update project' );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/projects', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Missing customerID parameter' );

		const db = await sql.connect( dbConfig );
		let templateTasks, templateChecklists, templateChecklistItems, projectDurationDays, startDate, endDate;

		try {

			let SQL	=	`
				SELECT
					p.id,
					p.name,
					p.projectManagerID,
					p.startDate,
					p.endDate,
					p.customerID,
					generatedFrom,
					pt.name as generatedFromTemplateName,
					concat ( gu.firstName, ' ', gu.lastName ) AS generatedBy,
					generatedDateTime,
					concat( u.firstName, ' ', u.lastName ) as projectManagerName,
					( select count(*) from keyInitiativeProjects kip join keyInitiatives ki on (ki.id = kip.keyInitiativeID ) where kip.projectID = p.id ) as kiCount,
					( select count(*) from tasks t where t.projectID = p.id ) as taskCount,
					( select top 1 type from projectStatus ps where ps.projectID = p.id order by updatedDateTime desc ) as status
				FROM projects p
				LEFT JOIN cSuite..users u on (u.id = p.projectManagerID)
				LEFT JOIN projectTemplates pt on (pt.id = p.generatedFromTemplateID)
				LEFT JOIN csuite..users gu on (gu.id = p.generatedBY)
				WHERE ( p.deleted = 0 OR p.deleted IS NULL )
				AND p.customerID = @customerID;
			`

			const results = await  db.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'clientID', sql.BigInt, req.session.clientNbr )
				.query( SQL );

			await Promise.all(
				results.recordset.map(async row => {
					row.isTemplatable = await getIsTemplatable(db, row.id, row.startDate, row.endDate);
				})
			);

			res.json( results.recordset );

		} catch( err ) {

			console.error( 'unexepcted database error', err );
			res.status( 500 ).send( 'unexpected database error' );

		}

	});
	//====================================================================================


	//====================================================================================
	async function completeTaskChecklistItems( projectID ) {
	//====================================================================================

		try {

			const SQL = `
			 	update taskChecklistItems set
					completed = 1,
					updatedBy = @userID
					updatedDateTime = CURRENT_TIMESTAMP
				where (completed = 0 or completed is null)
				and checklistID in (
					select tc.id
					from taskChecklists tc
					join tasks t on (t.id = tc.taskID and t.projectID = @projectID
				);
			`;

			const results = await pool.request()
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			return results.rowsAffected;

		} catch( err ) {

			logger.log({ level: 'error', label: '/api/projects: completeTaskChecklistItems()', message: 'Error mass completing taskChecklistItems for a project:', user: null });
			logger.log({ level: 'error', label: '/api/projects: completeTaskChecklistItems()', message: err, user: null });
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function completeTaskChecklists( projectID ) {
	//====================================================================================

		try {

			const SQL = `
				update taskChecklists set "
					completed = 1, "
					updatedBy = @userID, "
					updatedDateTime = CURRENT_TIMESTAMP "
				where (completed = 0 or completed is null) "
				and taskID in ( "
					select id "
					from tasks t "
					where projectID = @projectID"
				);
			`;

			const results = await pool.request()
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			return results.rowsAffected;

		} catch( err ) {

				logger.log({ level: 'error', label: '/api/projects: completeTaskChecklists()', message: 'Error mass completing taskChecklists for a project:', user: null });
				logger.log({ level: 'error', label: '/api/projects: completeTaskChecklists()', message: err, user: null });
				throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function completeTasks( projectID ) {
	//====================================================================================

		try {

			const SQL = `
				update tasks set
					completionDate = @completionDate
					taskStatusID = 2,
					updatedBy = @userID
					updatedDateTime = CURRENT_TIMESTAMP
				where (deleted = 0 or deleted is null)
				and (completionDate is null)
				and projectID = @projectID;
			`;

			const results = pool.request()
				.input( 'completionDate', sql.Date, req.body.date )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			return results.rowsAffected;

		} catch( err ) {

			logger.log({ level: 'error', label: '/api/projects: completeTasks()', message: 'Error mass completing tasks for a project:', user: null });
			logger.log({ level: 'error', label: '/api/projects: completeTasks()', message: err, user: null });
			throw new Error( err );

		}

	}
	//====================================================================================



	//====================================================================================
	async function getProjectInfo( projectID ) {
	//====================================================================================

		try {

			const SQL = `
				select
					p.name as projectName,
					c.name as customerName
				from projects p
				left join customer c on ( c.id = p.customerID)
				where p.id = @projectID;
			`;

			const results = await pool.request()
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			return results;

		} catch( err ) {

				logger.log({ level: 'error', label: '/api/projects: getProjectInfo()', message: 'Error while retrieving project info:', user: null })
				logger.log({ level: 'error', label: '/api/projects: getProjectInfo()', message: err, user: null })
				throw new Error( err )

		}

	}
	//====================================================================================


	//====================================================================================
	async function getOpenItems( projectID ) {
	//====================================================================================

		try {

			const SQL = `
				WITH baseTasks AS (
					SELECT t.id
					FROM tasks t
					WHERE t.projectID = @projectID
					AND t.completionDate IS NULL
					AND ISNULL( t.deleted, 0 ) = 0
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
					(SELECT COUNT(*) FROM baseTasks) as openTasks,
					(SELECT COUNT(*) FROM openChecklists) as openCheckLists,
					(SELECT COUNT(*) FROM openItems) AS openChecklistItems;
			`;

			const results = await pool.request()
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			return results.recordset[0];

		} catch( err ) {

			logger.log({ level: 'error', label: '/api/projects: getOpenItems()', message: 'Error counting open items for a project:', user: null });
			logger.log({ level: 'error', label: '/api/projects: getOpenItems()', message: err, user: null });
			throw new Error( err );
		}

	}
	//====================================================================================


	//====================================================================================
	async function updateProjectStatus( projectID, type, date, userID, comments  ) {
	//====================================================================================

		try {

			const statusDate = dayjs( date ).toDate();
			let newID = await utilities.GetNextID( 'projectStatus' );

			const SQL = `
				insert into projectStatus (
					id,
					statusDate,
					type,
					updatedBy,
					updatedDateTime,
					projectID,
					comments
				) values (
					@id,
					@statusDate,
					@type,
					@userID,
					CURRENT_TIMESTAMP,
					@projectID,
					@comments
				);
			`;

			const results = await pool.request()
				.input( 'id', sql.BigInt, newID )
				.input( 'statusDate', sql.Date, statusDate )
				.input( 'type', sql.VarChar, type )
				.input( 'userID', sql.BigInt, userID )
				.input( 'projectID', sql.BigInt, projectID )
				.input( 'comments', sql.VarChar, comments )
				.query( SQL );

			return results;


		} catch( err ) {

			logger.log({ level: 'error', label: '/api/projects: updateProjectStatus()', message: 'Error adding projectStatus:', user: null });
			logger.log({ level: 'error', label: '/api/projects: updateProjectStatus()', message: err, user: null });
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function getTemplateTasks( db, projectTemplateID ) {
	//====================================================================================

		try {

			let SQL	=	`select * `
						+	`from projectTemplateTasks `
						+	`where projectTemplateID = @projectTemplateID `;

			const results = await  db.request()
				.input( 'projectTemplateID', sql.BigInt, projectTemplateID )
				.query( SQL );

			return results.recordset;

		} catch( err ) {

			console.error('Error fetching projectTemplateTasks:', err);
			throw err;

		}

	}
	//====================================================================================


	//====================================================================================
	async function getTemplateChecklists( db, projectTemplateTaskID ) {
	//====================================================================================

		try {

			let SQL	=	`select * `
						+	`from projectTemplateTaskChecklists `
						+	`where projectTemplateTaskID = @projectTemplateTaskID `;

			const results = await  db.request()
				.input( 'projectTemplateTaskID', sql.BigInt, projectTemplateTaskID )
				.query( SQL );

			return results.recordset;

		} catch( err ) {

			console.error('Error fetching projectTemplateTaskChecklists:', err);
			throw err;

		}

	}
	//====================================================================================


	//====================================================================================
	async function getTemplateChecklistItems( db, projectTemplateTaskChecklistID ) {
	//====================================================================================

		try {

			let SQL	=	`select * `
						+	`from projectTemplateTaskChecklistItems `
						+	`where projectTemplateTaskChecklistID = @projectTemplateTaskChecklistID `;

			const results = await  db.request()
				.input( 'projectTemplateTaskChecklistID', sql.BigInt, projectTemplateTaskChecklistID )
				.query( SQL );

			return results.recordset;

		} catch( err ) {

			console.error('Error fetching projectTemplateTaskChecklistItems:', err);
			throw err;

		}

	}
	//====================================================================================


	//====================================================================================
	async function getProjectDurationDays( db, templateID ) {
	//====================================================================================

		try {

			let SQL	=	`select top 1 startOffsetDays + taskDurationDays + endOffsetDays as projectDurationDays `
						+	`from projectTemplateTasks `
						+	`where projectTemplateID = @templateID `

			const results = await  db.request()
				.input( 'templateID', sql.BigInt, templateID )
				.query( SQL );

			// If no rows, return 0.
			if  (!results.recordset || results.recordset.length === 0 ) {
				return 0;
			}

			// Safely convert the result to an integer
			const projectDurationDays = results.recordset[0]?.projectDurationDays;

			if (projectDurationDays === undefined || projectDurationDays === null) {
				throw new Error(`Project duration days not found for templateID: ${templateID}`);
			}

			return parseInt(projectDurationDays, 10);

		} catch( err ) {

			throw err;

		}

	}
	//====================================================================================


	//====================================================================================
	async function updateProjectStartEndDates( db, projectID ) {
	//====================================================================================

		try {

			// console.log( 'updateProjectStartEndDates called with projectID:', projectID );

			SQL	= 	`UPDATE projects SET `
					+		`startDate = (SELECT MIN(startDate) FROM tasks WHERE projectID = @projectID), `
					+		`endDate   = (SELECT MAX(dueDate) FROM tasks WHERE projectID = @projectID) `
					+	`WHERE id = @projectID; `;

			const result = await db.request()
				.input( 'projectID', sql.BigInt, projectID )
				.query(SQL);

			return;

		} catch( err ) {

			console.error( 'Error in updateProjectStartEndDates', err );
			throw err;

		}

	}
	//====================================================================================


	//====================================================================================
	async function addProject( db, projectInfo ) {
	//====================================================================================

		try {

			const newProjectID = await utilities.GetNextID( 'projects' );

			let SQL	=	`insert into projects ( `
						+		`id, `
						+		`name, `
						+		`customerID, `
						+		`startDate, `
						+		`endDate, `
						+		`updatedBy, `
						+		`updatedDateTime, `
						+		`projectManagerID, `
						+		`generatedFrom, `
						+		`generatedFromTemplateID, `
						+		`generatedBy, `
						+		`generatedDateTime `
						+	`) values ( `
						+		`@projectID, `
						+		`@projectName, `
						+		`@customerID, `
						+		`@startDate, `
						+		`@endDate, `
						+		`@updatedBy, `
						+		`CURRENT_TIMESTAMP, `
						+		`@projectManagerID, `
						+		`@generatedFrom, `
						+		`@generatedFromTemplateID, `
						+		`@generatedBy, `
						+		`CURRENT_TIMESTAMP `
						+	`) `

			const results = await  db.request()
				.input( 'projectID', sql.BigInt, newProjectID )
				.input( 'projectName', sql.NVarChar(80), projectInfo.projectName )
				.input( 'customerID', sql.BigInt, projectInfo.customerID )
				.input( 'startDate', sql.Date, dayjs( projectInfo.startDate ).toDate() )
				.input( 'endDate', sql.Date, dayjs( projectInfo.endDate ).toDate() )
				.input( 'updatedBy', sql.BigInt, projectInfo.userID )
				.input( 'projectManagerID', sql.BigInt, projectInfo.projectManagerID )
				.input( 'generatedFrom', sql.Char, projectInfo.generatedFrom )
				.input( 'generatedFromTemplateID', sql.BigInt, projectInfo.generatedFromTemplateID )
				.input( 'generatedBy', sql.BigInt, projectInfo.userID )
				.query( SQL );

			return newProjectID;

		} catch( err ) {

			console.error('Error in addProject:', err);
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function addProjectTask( db, task ) {
	//====================================================================================

		try {

			const newTaskID = await utilities.GetNextID( 'tasks' );

			let SQL	= 	`insert into tasks WITH (ROWLOCK) ( `
						+		`id, `
						+		`projectID, `
						+		`name, `
						+		`description, `
						+		`startDate, `
						+		`dueDate, `
						+		`updatedBy, `
						+		`updatedDateTime, `
						+		`estimatedWorkDays, `
						+		`dependencies, `
						+		`acceptanceCriteria, `
						+		`customerID `
						+	`) values ( `
						+		`@id, `
						+		`@projectID, `
						+		`@name, `
						+		`@description, `
						+		`@startDate, `
						+		`@dueDate, `
						+		`@updatedBy, `
						+		`CURRENT_TIMESTAMP, `
						+		`@estimatedWorkDays, `
						+		`@dependencies, `
						+		`@acceptanceCriteria, `
						+		`@customerID `
						+	`) `

			const results = await  db.request()
				.input( 'id', sql.BigInt, newTaskID )
				.input( 'projectID', sql.VarChar, task.projectID )
				.input( 'name', sql.VarChar, task.name )
				.input( 'description', sql.VarChar, task.description )
				.input( 'startDate', sql.Date, dayjs( task.startDate ).toDate() )
				.input( 'dueDate', sql.Date, dayjs( task.dueDate ).toDate() )
				.input( 'updatedBy', sql.BigInt, task.userID )
				.input( 'estimatedWorkDays', sql.BigInt, task.estimatedWorkDays )
				.input( 'dependencies', sql.VarChar(80), task.dependencies )
				.input( 'acceptanceCriteria', sql.VarChar, task.acceptanceCriteria )
				.input( 'customerID', sql.BigInt, task.customerID )
				.query( SQL );


			return newTaskID;

		} catch( err ) {

			console.error('Error in addProjectTasks:', err);
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function addProjectChecklist( db, checklist ) {
	//====================================================================================

		try {

			// console.log( 'addProjectChecklist...' );

			const userID = checklist.userID

			let SQL	= 	`INSERT INTO taskChecklists WITH (ROWLOCK) ( `
						+		`taskID, `
						+		`name, `
						+		`updatedBy, `
						+		`updatedDateTime `
						+	`) `
						+	`OUTPUT INSERTED.id `
						+	`VALUES ( `
						+		`@taskID, `
						+		`@name, `
						+		`@updatedBy, `
						+		`CURRENT_TIMESTAMP `
						+	`) `

			const results = await  db.request()
				.input( 'taskID', sql.VarChar, checklist.taskID )
				.input( 'name', sql.VarChar, checklist.name )
				.input( 'updatedBy', sql.BigInt, userID )
				.query( SQL );

			return results.recordset[0].id;

		} catch( err ) {

			console.error('Error in addProjectChecklists:', err);
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function addProjectChecklistItem( db, item ) {
	//====================================================================================

		try {

			// console.log( 'addProjectChecklistItem...' );

			const newChecklistItemID = await utilities.GetNextID( 'taskChecklistItems' );

			let SQL	=	`insert into taskChecklistItems WITH (ROWLOCK) ( `
						+		`checklistID, `
						+		`description, `
						+		`updatedBy, `
						+		`updatedDateTime `
						+	`) values ( `
						+		`@checklistID, `
						+		`@description, `
						+		`@updatedBy, `
						+		`CURRENT_TIMESTAMP `
						+	`) `

			const results = await db.request()
				.input( 'checklistID', sql.BigInt, item.checklistID )
				.input( 'description', sql.VarChar( sql.Max ), item.description )
				.input( 'updatedBy', sql.BigInt, item.userID )
				.query( SQL );

			return;

		} catch( err ) {

			console.error('Error in addProjectChecklists:', err);
			throw new Error( err );

		}

	}
	//====================================================================================

	//====================================================================================
	async function getIsTemplatable( db, projectID, projectStartDate, projectEndDate ) {
	//====================================================================================

		try {

			// debugger
			if ( !utilities.isWorkday( projectStartDate) || !utilities.isWorkday( projectEndDate ) ) {
				return false;
			}

			let SQL	=	`
				select startDate, dueDate
				from tasks
				where projectID = @projectID
				and ( deleted = 0 or deleted is null );
			`

			const results = await  db.request()
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			for ( task of results.recordset ) {
				if ( !utilities.isWorkday( task.startDate ) || !utilities.isWorkday( task.dueDate ) ) {
					return false;
				}
			}

			return true;

		} catch( err ) {

			throw err;

		}

	}
	//====================================================================================


	//====================================================================================
	async function getProejctStatus( db, projectID ) {
	//====================================================================================

		try {

			let SQL	=	`
				SELECT TOP 1
					type,
					format( updatedDateTime, 'M/d/yyyy' ) as statusDate
				FROM projectStatus
				WHERE projectID = @projectID
				ORDER BY updatedDateTime desc
			`

			const results = await  db.request()
				.input( 'projectID', sql.BigInt, projectID )
				.query( SQL );

			for ( task of results.recordset ) {
				if ( !utilities.isWorkday( task.startDate ) || !utilities.isWorkday( task.dueDate ) ) {
					return false;
				}
			}

			return true;

		} catch( err ) {

			throw err;

		}

	}
	//====================================================================================



}
