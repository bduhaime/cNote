<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% ' response.buffer = true %>
<%
Response.Expires = -1  ' Makes IE/older browsers not cache
Response.CacheControl = "no-store, must-revalidate"
Response.AddHeader "Pragma", "no-cache"
%>
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(52)

customerID = request.querystring("id")

%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customerTasks")

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
		

end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
%>


<html>

<head>
	

	<!-- #include file="includes/globalHead.asp" -->
	
	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/dayjs@1/dayjs.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/date-holidays@3/dist/umd.min.js"></script>
	
	<script>
	
		// Find the real constructor no matter how the UMD wrapped it
		const HolidaysCtor =
			( window.Holidays && ( window.Holidays.default || window.Holidays ) ) ||
			( window.DateHolidays && ( window.DateHolidays.default || window.DateHolidays ) );
		
		if ( typeof HolidaysCtor !== 'function' ) {
			console.error( 'date-holidays v3 UMD loaded but no constructor found:', window.Holidays );
		} else {
			// expose for later code on the page
			window.hd = new HolidaysCtor( 'US' ); // or 'US-MN'
		}
	
	</script>
	
	<script>
	
		// now this works
		const blockedTypes = [ 'public', 'bank' ];
		const currentYear = new Date().getFullYear();
		const holidayList = hd.getHolidays( currentYear );
		const publicHolidays = holidayList
			.filter( holiday => blockedTypes.includes( holiday.type ) )
			.map( h => dayjs( h.date ).format( 'YYYY-MM-DD' ) );
	
	</script>


	<script type="text/javascript" src="customerView.js"></script>
	<script type="text/javascript" src="customerTasks.js"></script>
	
	<script>
		
		// this little script automatically refreshes this page if the user navigates here using the browser's back arrow		
// 		if (
// 			window.performance &&
// 			performance.getEntriesByType &&
// 			performance.getEntriesByType('navigation')[0] &&
// 			performance.getEntriesByType('navigation')[0].type === 'back_forward'
// 		) {
// 			window.location.reload();
// 		}

		const queryString = window.location.search; // Get the query string (e.g., "?name=John&age=30")
		const params = new URLSearchParams(queryString);
		
		
		const customerID	= params.get( 'id' );
		const sort = params.get( 'sort' );



		//======================================================================================================
		async function getCustomerContacts( customerID ) {
		//======================================================================================================
			
			try {

				const data = await $.ajax({
					url: `${apiServer}/api/customerContacts`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
					data: { customerID: customerID }
				});
								
				return data;

			} catch (err) {

				console.error(`Error in getCustomerContacts: ${err}`);
				throw new Error(err);

			}

		}
		//======================================================================================================





		$(document).ready(function() {
						
			$( document ).tooltip();

			$( "#taskOwner" ).selectmenu({ 
				width: 300,
			  appendTo: "body",
			  position: { my: "left top", at: "left bottom", collision: "none" },
			  open: function(event, ui) {
			    $(ui.menuWrap).appendTo('body').css('z-index', 11001 );
			  }
			});

			$.fn.dataTable.moment( 'M/D/YYYY' );

			var searchButton = document.getElementById('searchButton');
			if (searchButton) {
				searchButton.addEventListener('click', function() {
					var currentLabel = this.textContent;
					var table = $('#tbl_tasks').DataTable();
					if ( currentLabel.trim() == 'Show All Tasks' ) {
						table.column(7).search('').draw();
						searchButton.textContent = 'Hide Completed Tasks';
					} else {
						table.column(7).search( '^$', true, false ).draw();
						searchButton.textContent = 'Show All Tasks';
					}
				});
				
			}



			$( "#dialog_newTask" ).dialog({
				autoOpen: false,
				resizable: false,
				height: "auto",
				width: 600,
				modal: true,
				buttons: {
					Save: function() {
						
						const name      = $('#name').val().trim();
						const startDate = $('#taskStartDate').val().trim();
						const dueDate   = $('#taskDueDate').val().trim();
						
						// collect missing fields
						const missing = [];
						if (!name)      missing.push('Name');
						if (!startDate) missing.push('Start Date');
						if (!dueDate)   missing.push('Due Date');
						
						if (missing.length) {
							alert(`Please enter: ${missing.join(', ')}`);
							return; // stop save
						}


						const payload = {
							customerID: $( '#customerID' ).val(),
							name: $( '#name' ).val(),
							description: $( '#description' ).val(),
							ownerID: ( !!$( '#taskOwner' ).val() ) ? $( '#taskOwner' ).val() : null,
							startDate: $( '#taskStartDate' ).val(),
							dueDate: $( '#taskDueDate' ).val()
						}
				
						$.ajax({
							type: 'POST',
							url: `${apiServer}/api/tasks`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: payload
						}).done( function() {
							const notification = document.querySelector('.mdl-js-snackbar');
							notification.MaterialSnackbar.showSnackbar({ message: 'Task added' });
							$( '#tbl_tasks' ).DataTable().ajax.reload( null, false );
						}).fail( function( err ) {
							console.error( 'an error occurred while adding task', err );
						}).always( async function () {
							$( "#dialog_newTask" ).dialog( 'close' );							
						})


					},
					Cancel: function() {
						$( this ).dialog( "close" );
					}
				},
				open: async function() {

					const taskOwners = await getCustomerContacts( customerID );
					const $taskOwner = $( '#taskOwner' );
					
					$taskOwner.empty();
					$taskOwner.append( `<option value=""></option>` );

					taskOwners.forEach( contact => {
						const fullName = `${contact.firstName} ${contact.lastName}`;
						const title = contact.title ? ` (${contact.title})` : '';
						const label = `${fullName}${title}`;
						$taskOwner.append(`<option value="${contact.id}">${label}</option>`);
					});

					$taskOwner.selectmenu('refresh');
					
				},
		    });			


// 			var dateFormat = 'mm/dd/yy',
// 				taskStartDate = $('#taskStartDate').datepicker({
// 					defaultDate: '+1w',
// 					changeMonth: true,
// 					changeYear: true,
// // 					minDate: moment(projectInfo.startDate).toDate(),
// // 					maxDate: moment(projectInfo.endDate).toDate(),
// 					beforeShowDay: function(date) {
// 						// your logic for disabling weekends/holidays…
// 						var formattedDate = moment(date).format("YYYY-MM-DD");
// 						if (date.getDay() === 0 || date.getDay() === 6) {
// 							return [false, "", "Weekends are disabled"];
// 						}
// 						if (publicHolidays.indexOf(formattedDate) !== -1) {
// 							return [false, "holiday", "Holiday is disabled"];
// 						}
// 						return [true, ""];
// 					},
// 					onSelect: function(dateText, inst) {
// 						const selectedDate = $(this).datepicker('getDate');
// 						taskDueDate.datepicker('option', 'minDate', selectedDate);
// 						$(this).blur();
// 					},
// 				}),
// 				
// 				taskDueDate = $( '#taskDueDate' ).datepicker({
// 					defaultDate: '+1w',
// 					changeMonth: true,
// 					changeYear: true,
// // 					minDate: moment( projectInfo.startDate ).toDate(),
// // 					maxDate: moment( projectInfo.endDate ).toDate(),
// 					beforeShowDay: function( date ) {
// 	
// 						// Disable weekends: 0 = Sunday, 6 = Saturday							
// 						if (date.getDay() === 0 || date.getDay() === 6) {
// 							return [false, "", "Weekends are disabled"];
// 						}
// 
// 						// Format date with dayjs to "YYYY-MM-DD"
// 						var formattedDate = moment(date).format("YYYY-MM-DD");
// 						
// 						// Check if the date is a holiday
// 						if (publicHolidays.indexOf(formattedDate) !== -1) {
// 							return [false, "holiday", "Holiday is disabled"];
// 						}
// 
// 						return [true, ""];
// 
// 					},
// 					onSelect: function(dateText, inst) {
// 						var selectedDate = $(this).datepicker('getDate');
// 						taskStartDate.datepicker('option', 'maxDate', selectedDate);
// 						// Optionally force close:
// 						$.datepicker._hideDatepicker();					
// 					},
// 				});
// 
// 			$("#taskStartDate").attr("readonly", true);
// 			$("#taskDueDate").attr("readonly", true);




			const dateFormat = 'mm/dd/yy';

			function loadHolidaysForYear( year ) {
				holidaySet = new Set(
					hd.getHolidays( year )
						.filter( holiday => blockedTypes.includes( holiday.type ) )
						.map( h => dayjs( h.date ).format( 'YYYY-MM-DD' ) )
				);
			}
			
			function isHolidayString( d ) {
				return holidaySet.has( dayjs( d ).format( 'YYYY-MM-DD' ) );
			}
			
			
			// Common cell logic: disable weekends + holiday types from `blockedTypes`
			function beforeShowDay( d ) {
	
				const day = d.getDay();
				if ( day === 0 || day === 6 ) {
					return [ false, '', 'Weekends are disabled' ];
				}
				const blocked = isHolidayString( d );
				return [ !blocked, blocked ? 'holiday' : '', blocked ? 'Holiday is disabled' : '' ];
	
			}
			
			
			// One shared options object; only define what’s common once
			const baseOpts = {
				defaultDate: '+1w',
				changeMonth: true,
				changeYear: true,
				beforeShowDay,     // shared
				onChangeMonthYear: function ( year /*, month*/ ) {
					loadHolidaysForYear( year );
				}
			};
			
			// Prime cache for the initial calendar view
			loadHolidaysForYear( new Date().getFullYear() );
			
			// Wire up pickers (unique bits stay local)
			const taskStartDate = $( '#taskStartDate' )
				.attr("readonly", true)
				.datepicker( baseOpts )
				.on( 'change', function () {
					taskDueDate.datepicker( 'option', 'minDate', getDate( this ) );
					$( '.startDateTip' ).remove();
					$( this ).css( 'color', '' );
				});
			
			const taskDueDate = $( '#taskDueDate' )
				.attr("readonly", true)
				.datepicker( baseOpts )
				.on( 'change', function () {
					taskStartDate.datepicker( 'option', 'maxDate', getDate( this ) );
					$( '.endDateTip' ).remove();
					$( this ).css( 'color', '' );
				});
			
			loadHolidaysForYear( new Date().getFullYear() );	

			function getDate( element ) {

				var date;
				try {
					date = $.datepicker.parseDate( dateFormat, element.value );
				}
				catch ( error ) {
					date = null;
				}
				
				return date;
					
			}



			let orderArray = [];
			if ( sort === "orphan" ) {
				orderArray.push( [3, 'desc' ]);
			} else {
				orderArray.push( [5, 'desc'] );
			}
			
			var table = $('#tbl_tasks')

				.on( 'click', 'tbody > tr', function() {
					var taskID = this.id;
					if ( taskID ) {
						window.location.href = 'taskDetail.asp?customerID=<% =customerID %>&taskID='+taskID;
					}
				})
				.on( 'click', 'td.details-control', function(event) {

					event.preventDefault();
					event.stopPropagation();

					var tr = $(this).closest('tr');
					var row = table.row( tr );

					const customerID 		= <% =customerID %>;
					const taskID			= row.data().DT_RowId;
					const currProjectID	= row.data().projectID;
					const taskStartDate 	= row.data().startDate;
					const taskDueDate		= row.data().dueDate;
					
					if ( row.child.isShown() ) {
						row.child.hide();
						tr.removeClass('shown');
					} else {
						row.child( 
							'<div class="child">'
								+	'<table style="width: 100%;"><tr>'
									+	'<td style="vertical-align: bottom; text-align: right;">'
										+	'<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent showProjects" data-taskID="'+taskID+'">'
											+ 	'show all projects'
										+	'</button>'
									+	'</td>'
								+	'</tr></table>'
		               	+	'<table class="childProjects compact display" id="projectsForTask_' + taskID + '" data-currProjectID="'+currProjectID+'" data-startDate="'+taskStartDate+'" data-dueDate="'+taskDueDate+'"><thead><tr>'
		               		+	'<th class="projectName">Projects</th>'
		               		+	'<th class="startDate">Start</th>'
		               		+	'<th class="dueDate">End</th>'
		               		+	'<th class="projectManagerName">Manager</th>'
		               		+	'<th class="statusDate">Status Date</th>'
		               		+	'<th class="status">Status</th>'
		               		+	'<th></th>'
		               	+ 	'</tr></thead><tbody></tbody></table>'
								+	'<br><br>'
								+	'<table style="width: 100%;"><tr>'
									+	'<td style="vertical-align: bottom; text-align: right; width: 100%;">'
										+	'<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent showKIs" data-taskID="'+taskID+'">'
											+ 	'show all Key Initiatives'
										+	'</button>'
									+	'</td>'
								+	'</tr></table>'
		               	+	'<table class="childKIs compact display" id="KIsForTask_' + taskID + '"><thead><tr>'
		               		+	'<th>Key Initiatives</th>'
		               		+	'<th>Start</th>'
		               		+	'<th>Due</th>'
		               		+	'<th>Complete</th>'
		               		+	'<th></th>'
		               	+ 	'</tr></thead><tbody></tbody></table>'
	               	+	'</div>'
		               ).show();

						var projectTable = $('#projectsForTask_'+taskID)
							.on( 'click', 'tbody tr', function(event) {

								event.preventDefault();
								event.stopPropagation();

								const customerID = <% =customerID %>;
								const projectID = this.id;

								if ( projectID ) {
									window.location.href = 'taskList.asp?customerID='+customerID+'&projectID='+projectID;
								}

							})
							.on( 'click', 'td.link', function (event) {
							
								event.preventDefault();
								event.stopPropagation();
							
								const projectID = this.closest('tr').id;
								const customerID = <% =customerID %>;
								const projectTable = this.closest('table');
								const projectWrapper = projectTable.closest('div');
								const projectWrapperID = projectWrapper.id;
								const taskID = projectWrapperID.substring(projectWrapperID.indexOf('_')+1, projectWrapperID.lastIndexOf('_'));
								
								const button = this.querySelector('i');
								
								if ( button.classList.contains('add') ) {
									AddTaskProject(customerID, projectID, taskID);
								} else if ( button.classList.contains('remove') ) { 
									RemoveTaskProject(customerID, projectID, taskID);
								}

								var tempTable = $('#projectsForTask_'+taskID).DataTable();
								var delayInMilliseconds = 1000;
								
								setTimeout(function() {
									tempTable.ajax.reload( null, false );
								}, delayInMilliseconds);

								
							})
							.DataTable({
								paging: true,
								lengthMenu: [[5,10,15,-1],[5,10,15,'All']],
								info: true,
								searching: true,
								processing: false,
								serverSide: false,
								ajax: {
									url: '/ajax/projects.asp?customerID='+customerID+'&taskID='+taskID,
								},
								columns: [
									{targets: 'projectName', 							data: 'projectName', 			className: 'dt-body-left dt-head-left'},
									{
										targets: 'startDate', 			
										width: '50px', data: 'startDate', 				
										className: 'dt-body-center dt-head-center',

										render: function (data, type, row, meta) {
			
											if (!data) return type === 'display' ? '' : data;
											
											const m = moment.utc(data).local();
											
											const isWeekend = (m.day() === 0 || m.day() === 6);
											const isHoliday = publicHolidays.includes(m.format('YYYY-MM-DD'));
											
											if (type === 'display' || type === 'filter') {
												const fmt = m.format('M/D/YYYY');
												if (isWeekend || isHoliday) {
													return `<span style="color:red;" title="${fmt} is not a workday">${fmt}</span>`;
												}
											return fmt;
											}
											
											// For sort/type !== display|filter return a sortable primitive (ms since epoch)
											return m.valueOf();
			
										}						



									},
									{
										targets: 'endDate', 			
										width: '50px', data: 'endDate', 					
										className: 'dt-body-center dt-head-center',

										render: function (data, type, row, meta) {
			
											if (!data) return type === 'display' ? '' : data;
											
											const m = moment.utc(data).local();
											
											const isWeekend = (m.day() === 0 || m.day() === 6);
											const isHoliday = publicHolidays.includes(m.format('YYYY-MM-DD'));
											
											if (type === 'display' || type === 'filter') {
												const fmt = m.format('M/D/YYYY');
												if (isWeekend || isHoliday) {
													return `<span style="color:red;" title="${fmt} is not a workday">${fmt}</span>`;
												}
											return fmt;
											}
											
											// For sort/type !== display|filter return a sortable primitive (ms since epoch)
											return m.valueOf();
			
										}						

									},
									{targets: 'projectManagerName',					data: 'projectManagerName', 	className: 'dt-body-left dt-head-left'},
									{targets: 'statusDate', 		width: '50px', data: 'statusDate', 				className: 'dt-body-centerdt-head-center', visible: true},
									{targets: 'status', 									data: 'status', 					className: 'dt-body-center dt-header-center'},
									{
										targets: 'actions', 	
										width: '24px', 
										orderable: true, 
										className: 'link dt-body-center dt-head-center', 
										data: function( row, type, val, meta ) {
											var iconName;
											
											
											 
											const currProjectID 	= document.querySelector('table.childProjects').getAttribute('data-currProjectID');
											const taskStartDate 	= moment(document.querySelector('table.childProjects').getAttribute('data-startDate'), 'M/D/YYYY');
											const taskDueDate 	= moment(document.querySelector('table.childProjects').getAttribute('data-dueDate'), 'M/D,YYYY');

											if ( currProjectID ) {
												
												if ( row.taskID ) {
												
													if ( row.taskID == taskID ) {
														iconName 	= 'remove_circle_outline';
														className 	= 'remove linked';
														title 		= 'Click to remove task from project';
													} else {
														iconName = 'block';
														className = 'disabled';
														title = 'Task is part of a different project';
													}
												
												} else {

													iconName = 'block';
													className = 'disabled';
													title = 'Task is part of a different project';

												}
												
											} else {
												
												const projectStartDate 	= moment(row.startDate);
												const projectDueDate		= moment(row.endDate);

												if ( row.status == 'Complete' ) {
													iconName 	= 'block';
													className 	= 'disabled';
													title 		= 'Project is complete; changes not permitted';
												} else {

													if ( projectStartDate.isSameOrBefore(taskStartDate) ) {
														if ( projectDueDate	.isSameOrAfter(taskDueDate) ) {
															iconName 	= 'add_circle_outline';
															className 	= 'add linkable';
															title 		= 'Click to add task to project';
														} else {
															iconName 	= 'block';
															className 	= 'unlinkable disabled';
															title			= 'Project ends before task is due';
														}
													} else {
														iconName 	= 'block';
														className 	= 'unlinkable disabled';
														title			= 'Project starts after task begins';
													}

												}

											}

											return '<i class="material-symbols-outlined '+className+'" title="'+title+'">'+iconName+'</i>';

										}

									},
									{targets: 'relatability', 		data: 'relatability', 		visible: false, searchable: true},
									{targets: 'relatabilityInfo', data: 'relatabilityInfo', 	visible: false, searchable: true},
								],
								order: [[1, 'desc']],
								searchCols: [
									null,
									null,
									null,
									null,
									null,
									null,
									{ search: 'remove_circle_outline' },
									null,
								]
							});
							
						var kiTable = $('#KIsForTask_'+taskID)
							.on( 'click', 'tbody tr', function(event) {

								event.preventDefault();
								event.stopPropagation();

								kiID 			= this.id;
								kidFilter 	= '';
								
								if ( kiID ) {
									window.location.href = 'customerKeyInitiatives.asp?id=<% =customerID %>&ki='+kiID+'&filter='+kidFilter;
								}

							})
							.on( 'click', 'td.link', function (event) {
							
								event.preventDefault();
								event.stopPropagation();
							
								const keyInitiativeID 	= this.closest('tr').id;

								const kiTable 				= this.closest('table');
								const kiWrapper 			= kiTable.closest('div');
								const kiWrapperID 		= kiWrapper.id;
								const taskID 				= kiWrapperID.substring(kiWrapperID.indexOf('_')+1, kiWrapperID.lastIndexOf('_'));

								const button = this.querySelector('i');
								
								if ( button.classList.contains('add') ) {
									AddTaskKeyInitiative(keyInitiativeID, taskID);
								} else if ( button.classList.contains('remove') ) { 
									RemoveTaskKeyInitiative(keyInitiativeID, taskID);
								}
								
								var tempTable = $('#KIsForTask_'+taskID).DataTable();
								tempTable.ajax.reload( null, false );
								
							})
							.DataTable({
								paging: true,
								lengthMenu: [[5,10,15,-1],[5,10,15,'All']],
								info: true,
								searching: true,
								processing: false,
								serverSide: false,
								ajax: {
									url: '/ajax/keyInitiatives.asp?customerID='+customerID+'&taskID='+taskID,
								},
								columns: [
									{targets: 'kiName', 			data: 'kiName', 			className: 'dt-body-left'},
									{targets: 'startDate', 		data: 'startDate', 		className: 'dt-body-center'},
									{targets: 'dueDate', 		data: 'dueDate', 			className: 'dt-body-center'},
									{targets: 'completeDate', 	data: 'completeDate', 	className: 'dt-body-center'},
									{
										targets: 'actions', 	
										width: '24px', 
										orderable: true, 
										className: 'link dt-body-center ', 
										data: function( row, type, val, meta ) {
											var iconName;
											if ( row.taskRelationship == 'linked') {
												iconName 	= 'remove_circle_outline';
												className 	= 'remove linked';
												title 		= '';
											} else if ( row.taskRelationship == 'possible' ) {
												iconName 	= 'add_circle_outline';
												className 	= 'add linkable';
												title 		= '';
											} else {
												iconName 	= 'block';
												className 	= 'unlinkable disabled';
												title 		= row.taskRelationship;
											}	
											return '<i class="material-symbols-outlined '+className+'" title="'+title+'">'+iconName+'</i>';
										}		
									},
									{targets: 'taskRelationship', data: 'taskRelationship', visible: false, searchable: true},
								],
								order: [[1, 'desc']],
								searchCols: [
									null,
									null,
									null,
									null,
									{ search: 'remove_circle_outline' },
								]
							});
						tr.addClass('shown');
					}

				})
				.on( 'click', 'button.showProjects', function(event) {

					event.preventDefault();
					event.stopPropagation();
					
					const taskID 					= this.getAttribute( 'data-taskID' );
					const childProjectsTable 	= $( '#projectsForTask_'+taskID ).DataTable();
					const currSearch 				= childProjectsTable.column( 6 ).search();

					if (currSearch == 'remove_circle_outline') {
						this.textContent = 'Show Linked Projects';
						childProjectsTable.column( 6 ).search( '' ).draw();
					} else {
						this.textContent = 'Show All Projects';
						childProjectsTable.column( 6 ).search( 'remove_circle_outline' ).draw();
					}


				})
				.on( 'click', 'button.showKIs', function(event) {

					event.preventDefault();
					event.stopPropagation();
					
					const taskID 				= this.getAttribute( 'data-taskID' );
					const childTasksTable 	= $( '#KIsForTask_'+taskID ).DataTable();
					const currSearch 			= childTasksTable.column( 4 ).search();

					if (currSearch == 'remove_circle_outline') {
						this.textContent = 'Show Linked Key Initiatives';
						childTasksTable.column( 4 ).search( '' ).draw();
					} else {
						this.textContent = 'Show All Key Initiatives';
						childTasksTable.column( 4 ).search( 'remove_circle_outline' ).draw();
					}

				})
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons(this);
				})
				.on( 'mouseout', 'tbody tr', function() {
					ToggleActionIcons(this);
				})
				.on( 'click', 'i.delete', function( event ) {

					taskDelete_OnClick(this);

				})
				
				<% if userPermitted(73) then %>
					.on( 'click', 'tbody > tr.taskRow', function() {
						
						const customerID 		= <% =customerID %>;
						const taskID 			= this.id;
						window.location.href = 'taskDetail.asp?customerID='+customerID+'&taskID='+taskID;
						
					})
				<% end if %>

				.DataTable({
					ajax: {
						url: '/ajax/tasks.asp?customerID='+<% =customerID %>
					},
					columns: [
						{
							className: 'details-control dt-body-center',
							orderable: false,
							data: null,
							defaultContent: ''
						},
						{targets: 'taskName', 				data: 'taskName', 				className: 'taskName dt-body-left dt-head-left'},
						{targets: 'kis', 						data: 'kis', 						className: 'kis dt-body-center dt-head-center', visible: false},
						{
							targets: 'orphan', 					
							orderable: true,
							className: 'orphan dt-body-center dt-head-center',
							data: function( row, type, val, meta ) {
								if ( row.orphan == 'true') {
									return '<i class="material-symbols-outlined orphan" title="This Task is not associated with any Projects or Key Initiatives">check</i>';
								} else {
									return '';
								}	
							}		
						},
						{targets: 'ownerName', 				data: 'ownerName', 				className: 'ownerName dt-body-left dt-head-left'},
						{
							targets: 'startDate', 				
							data: 'startDate', 				
							className: 'startDate dt-body-center dt-head-center',

							render: function (data, type, row, meta) {

								if (!data) return type === 'display' ? '' : data;
								
// 								const m = moment.utc(data).local();
								const m = moment( data );
								
								
								const isWeekend = (m.day() === 0 || m.day() === 6);
								const isHoliday = publicHolidays.includes(m.format('YYYY-MM-DD'));
								
								if (type === 'display' || type === 'filter') {
									const fmt = m.format('M/D/YYYY');
									if (isWeekend || isHoliday) {
										return `<span style="color:red;" title="${fmt} is not a workday">${fmt}</span>`;
									}
								return fmt;
								}
								
								// For sort/type !== display|filter return a sortable primitive (ms since epoch)
								return m.valueOf();

							}						


						},
						{
							targets: 'dueDate', 				
							data: 'dueDate', 					
							className: 'dueDate dt-body-center dt-head-center',
							render: function (data, type, row, meta) {

								if (!data) return type === 'display' ? '' : data;
								
// 							const m = moment.utc(data).local();
								const m = moment( data );

								
								const isWeekend = (m.day() === 0 || m.day() === 6);
								const isHoliday = publicHolidays.includes(m.format('YYYY-MM-DD'));
								
								if (type === 'display' || type === 'filter') {
									const fmt = m.format('M/D/YYYY');
									if (isWeekend || isHoliday) {
										return `<span style="color:red;" title="${fmt} is not a workday">${fmt}</span>`;
									}
								return fmt;
								}
								
								// For sort/type !== display|filter return a sortable primitive (ms since epoch)
								return m.valueOf();

							}						
						},
						{targets: 'completeDate', 			data: 'completeDate', 			className: 'completeDate dt-body-center dt-head-center'},
						{targets: 'estWorkDays', 			data: 'estWorkDays', 			className: 'estWorkDays dt-body-center', visible: false},
						{targets: 'actWorkDays', 			data: 'actWorkDays', 			className: 'actWorkDays dt-body-center', visible: false},
						{targets: 'completedByCustomer', data: 'completedByCustomer', 	className: 'completedByCustomer dt-body-center', visible: false},
						{
							targets: 'actions', 	
							data: null,			
							orderable: false, 
							className: 'actions dt-body-center dt-head-center',
							defaultContent: '',
							render: function() {
								return '<i class="material-symbols-outlined delete" title="Click to delete this Task">delete_outline</i>';
							}
						},
						{targets: 'projectID', 				data: 'projectID',				className: 'projectID', visible: false},
					],
					order: orderArray,
					processing: true,
					searchCols: [
						null,
						null,
						null,
						null,
						null,
						null,
						null,
						{ search: '^$', regex: true },
						null,
						null,
					]
			});


			//-----------------------------------------------------------------------------------------------------
			$( '#button_newTask' ).on( 'click', function( event ) {
			//-----------------------------------------------------------------------------------------------------
	
				$( "#dialog_newTask" ).dialog( 'open' );
					
	
			});
			//-----------------------------------------------------------------------------------------------------


			window.addEventListener( 'pageshow', (e) => {
				if ( localStorage.getItem( 'projects:dirty' ) ) {
					table.ajax.reload( null, false );
					localStorage.removeItem( 'projects:dirty' );
				}
			});



		});





	</script>
	
	

	<style>

		label, input, textarea { display:block; }
		span { display: inline-block }
		input.text, textarea { margin-bottom:25px; width:95%; padding: .4em; }
		input.date { margin-bottom:12px; width:100px; padding: .4em; margin-right: 12px; }
		fieldset { padding:0; border:0; margin-top:25px; }
		h1 { font-size: 1.2em; margin: .6em 0; }
		
		.ui-selectmenu-button { margin-bottom: 25px; }
		fieldset { margin-bottom: 25px; }
		
		.ui-checkboxradio-icon { margin-right: 10px; }

		.ui-controlgroup-vertical { width: 150px; }
		.ui-controlgroup.ui-controlgroup-vertical > button.ui-button,
		.ui-controlgroup.ui-controlgroup-vertical > .ui-controlgroup-label { text-align: center; }
		.ui-controlgroup-horizontal .ui-spinner-input { width: 20px; }
		
		.selectable .ui-selecting { background: #FECA40; }
		.selectable .ui-selected { background: #F39814; color: white; }
		.selectable { list-style-type: none; margin: 0; padding: 0; width: 60%; }

		
		.skipped {
			text-decoration: line-through;
		}

		.hideMe {
			display: none;
		}

		td.details-control {
			background: url('../images/baseline_unfold_more_black_18dp.png') no-repeat center center;
			cursor: pointer;
		}

		tr.shown td.details-control {
			background: url('../images/baseline_unfold_less_black_18dp.png') no-repeat center center;
		}		
		
		div.child {
			padding: 8px 64px 64px 64px;
			background-color: #fff;
		}
		
		i.add {
			color: green;
		}
		
		i.disabled {
			color: lightgrey;
			cursor: default;
		}
		
		i.remove, i.block {
			color: crimson;
			cursur: default;
		}
		
		/* HIDE THE FILTER INPUT FIELD ON THE CHILD DATATABLES.... */
		div.child .dataTables_wrapper .dataTables_filter {
			visibility: hidden;
		}		

		table.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
		table th.taskName, table td.taskName {
			max-width: 500px; 
			min-width: 70px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; }
		}
		
		table.dataTable td.actions {
			cursor: pointer;
			visibility: hidden;
		}

		i.delete, i.edit {
			cursor: pointer;
			visibility: hidden;
		}


		#dateFieldsWrapper {
		  display: flex;
		  gap: 10px;
		  align-items: flex-start;
		}
		
		.dateField {
		  display: flex;
		  flex-direction: column;
		  width: 25%; /* previously 'flex: 1' — this keeps them tighter */
		}	
		
		#nameFieldset,
		#descriptionFieldset,
		#taskOwnerFieldset {
		  margin-top: 1em;
		  margin-bottom: 1em;
		  display: flex;
		  flex-direction: column;
		}
		
		#taskOwner {
		  padding: 6px; /* optional: matches input box look more closely */
		}
		
		.ui-selectmenu-menu, .ui-menu {
		  z-index: 11000 !important;
		}

		
	</style>

</head>

<body>

<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
		
		<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

    </div>

<!-- #include file="includes/customerTabs.asp" -->

  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer Tasks</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	
	<div class="page-content">
		<!-- Your content goes here -->

		<!-- DIALOG: New Task -->
		<dialog id="dialog_addTask" class="mdl-dialog">
			<h4 class="mdl-dialog__title">New Task</h4>
			<div class="mdl-dialog__content">			

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="taskName" name="taskName" value="">
				    <label class="mdl-textfield__label" for="taskName">Task name...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <textarea class="mdl-textfield__input" type="text" rows="3" id="taskDescription" name="taskDescription"></textarea>
				    <label class="mdl-textfield__label" for="taskDescription">Task description...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<select class="mdl-textfield__input" id="taskOwnerID" name="taskOwnerID">
						<option></option>
						<%
						SQL = "select " &_
									"id, " &_
									"concat(firstName, ' ', lastName) as [name], " &_
									"title " &_
								"from customerContacts " &_
								"where customerID = " & customerID & " " &_
								"order by lastName, firstName "
								
						dbug(SQL)
						set rsUser = dataconn.execute(SQL)
						while not rsUser.eof 
							if len(rsUser("title")) > 0 then 
								title = " (" & rsUser("title") & ")"
							else 
								title = ""
							end if 
							response.write("<option value=""" & rsUser("id") & """>" & rsUser("name") & title & "</option>")
							rsUser.movenext 
						wend
						rsUser.close
						set rsUser = nothing
						%>
						</select>
					<label class="mdl-textfield__label" for="taskOwnerID">Task owner...</label>
				</div>

				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="date" id="startDate" name="startDate" min="<% =projectStartDate %>" max="<% =projectEndDate %>"  onblur="StartDate_onBlur(this)" value="" required>
				    <label class="mdl-textfield__label" for="startDate">Start date...</label>
					  <span class="mdl-textfield__error">Input is not valid!</span>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="date" id="dueDate" name="dueDate" min="<% =projectStartDate %>" max="<% =projectEndDate %>" onblur="DueDate_onBlur(this)" value="" required>
				    <label class="mdl-textfield__label" for="dueDate">Due date...</label>
					  <span class="mdl-textfield__error">Input is not valid!</span>
				</div>
				
				<input id="add_projectID" type="hidden">
				<input id="add_customerID" type="hidden" value="<% =customerID %>">
		
			</div>
			<div class="mdl-dialog__actions">
				<button type="button" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog><!-- DIALOG: New Task -->


	  	<div id="dialog_newTask" title="New Task" style="display: none;">
					
			<form action="" name="task">
			
				<p class="validateTips"></p>
	
				<input type="hidden" name="id" id="id">
				<input type="hidden" name="customerID" id="customerID" value="<% =customerID %>">
	
				<div id="nameFieldset">
					<label for="name">Name</label>
					<input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all">
				</div>
				
	
				<div id="descriptionFieldset">
					<label for="description">Description</label>
					<textarea name="description" id="description" rows="3" class="text ui-widget-content ui-corner-all"></textarea>
				</div>
				
				
				<div id="taskOwnerFieldset">
					
					<label for="taskOwner">Owner</label>
					<select name="taskOwner" id="taskOwner"></select>
					
				</div>			
	
				<div id="dateFieldsWrapper">
					<div class="dateField">
						<label for="taskStartDate">Start date</label>
						<input type="text" name="taskStartDate" id="taskStartDate" class="date ui-widget-content ui-corner-all" />
					</div>
					
					<div class="dateField">
						<label for="taskDueDate">Due date</label>
						<input type="text" name="taskDueDate" id="taskDueDate" class="date ui-widget-content ui-corner-all" />
					</div>
				</div>			
				<!-- Allow form submission with keyboard without duplicating the dialog button -->
				<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
				
			</form>
			
		</div><!-- New Add/Edit tastk Dialog -->



		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col" align="left" >
				<% if userPermitted(72) then %>
					<button id="button_newTask" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Task
					</button>
				<% end if %>
			</div>
				
			<div class="mdl-cell mdl-cell--3-col" align="right" >
				<button id="searchButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
				  Show All Tasks
				</button>
				<% if userPermitted(71) then %>
					<a href="customerProjectsSendDetails.asp?customerID=<% =customerID %>" title="Printer friendly version of open project/task details"><i class="material-icons" style="vertical-align: middle;">print</i></a>
				<% end if %>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
			
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--11-col" align="center">

				<table id="tbl_tasks" class="compact display">
					<thead>
						<tr>
							<th></th>
							<th class="taskName">Task Name</th>
							<th class="kis"># KI's</th>
							<th class="orphan">Orphan?</th>
							<th class="ownerName">Owner</th>
							<th class="startDate">Start</th>
							<th class="dueDate">Due</th>
							<th class="completeDate">Complete</th>
							<th class="estWorkDays">Est. Work<br>Days</th>
							<th class="actWorkDays">Act. Work<br>Days</th>
							<th class="completedByCustomer">Completed<br>By Cust</th>
							<%' if userPermitted(73) or userPermitted(74) then %>
								<th class="actions" style="text-align: center;">Actions</th>
							<%' end if %>
							<th class="projectID"></th>
						</tr>
					</thead>
				</table>


			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

	</div><!-- end of your content -->
	
	</main>
	
	<!-- #include file="includes/pageFooter.asp" -->
	
</div>

<script src="dialog-polyfill.js"></script>  
<script>

//****************************************************************************************/
// Add Event Listeners for Toggle Task buttons
//****************************************************************************************/
//
	var toggleTaskButtons = document.querySelectorAll('.toggleTask'), i;
	if (toggleTaskButtons != null) {
		
		for (i = 0; i < toggleTaskButtons.length; ++i) {
			toggleTaskButtons[i].addEventListener('click', function(event) {
				ToggleProjectsKIs(this);
				event.cancelBubble = true;
			})
		}
		
	}
	
	
//****************************************************************************************/
// Add Event Listeners for Edit buttons
//****************************************************************************************/
//
	var taskEditButtons = document.querySelectorAll('.taskEditButton'), i;
	if (taskEditButtons != null) {
		
		for (i = 0; i < taskEditButtons.length; ++i) {
			taskEditButtons[i].addEventListener('click', function(event) {
				taskEdit_OnClick(this);
				event.cancelBubble = true;
			})
		}
		
	}
	
	
//****************************************************************************************/
// Add Event Listeners for Delete buttons
//****************************************************************************************/
//
	var taskDeleteButtons = document.querySelectorAll('.taskDeleteButton'), i;
	if (taskDeleteButtons != null) {
		
		for (i = 0; i < taskDeleteButtons.length; ++i) {
			taskDeleteButtons[i].addEventListener('click', function(event) {
				taskDelete_OnClick(this);
				event.cancelBubble = true;
			})
		}
		
	}
	
	


//****************************************************************************************/
// Add Event Listeners for Remove Project from task buttons
//****************************************************************************************/
//
	var removeProjButtons = document.querySelectorAll('.removeProj'), i;
	
	if (removeProjButtons != null) {
		
		for (i = 0; i < removeProjButtons.length; ++i) {
			removeProjButtons[i].addEventListener('click', function(event) {
				RemoveProjFromTask(this, <% =customerID %>);
				event.cancelBubble = true;
			})
		}
		
	}
	
	
//****************************************************************************************/
// Add Event Listeners for Remove KI from task buttons
//****************************************************************************************/
//
	var removeKIButtons = document.querySelectorAll('.removeKI'), i;
	
	if (removeKIButtons != null) {
		
		for (i = 0; i < removeKIButtons.length; ++i) {
			removeKIButtons[i].addEventListener('click', function(event) {
				RemoveTaskFromKeyInitiative(this, <% =customerID %>);
				event.cancelBubble = true;
			})
		}
		
	}
	
	


</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>