<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/workDaysBetween.asp" -->
<!-- #include file="includes/workDaysAdd.asp" -->
<!-- #include file="includes/taskDaysAtRisk.asp" -->
<!-- #include file="includes/taskDaysBehind.asp" -->
<!-- #include file="includes/taskDaysAhead.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(23)

userLog("Task list")
currentDate = date() 
' currentDate = cDate("10/31/2017") 	' Scenario 1
' currentDate = cDate("11/14/2017") 	' Scenario 2 
' currentDate = cDate("11/28/2017")		' Scenario 3

' currentDate - current date formatted as YYYY-MM-DD for use in max attribute of projectStatusDate input field...
currentYYYY = year(date())
currentMM	= right( "00" & cStr( month(date()) ), 2 )
currentDD	= right( "00" & cStr( day(date()) ), 2 )
currentDate = currentYYYY & "-" & currentMM & "-" & currentDD



' use the projectID to determine the customer info to populate in the title....
projectID = request.querystring("projectID")
customerID = request.querystring("customerID")
tab = request.querystring("tab")

%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	


'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

http_host		= request.serverVariables("HTTP_HOST")
http_referer 	= request.serverVariables("HTTP_REFERER")

linkBack 		= replace(replace(http_referer, "HTTP://", ""), "HTTPS://", "")
linkBack			= replace(linkBack, http_host, "")
linkBack			= replace(linkBack, "/", "")

dbug("linkBack: " & linkBack)

' title = session("clientID") & " - <a href=""customerList.asp"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
' title = title & "<a href=""customerProjects.asp?id=" & customerID & """>" & customerTitle(customerID) & "</a>" 



' title = title & "<a href=""" & linkBack & """>" & customerTitle(customerID) & "</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" 
' 
' title = title & projectName
%>

	
<html>

<head>

	
	<!-- #include file="includes/globalHead.asp" -->
	<link rel="stylesheet" href="dialog-polyfill.css" />

	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script src="https://www.gstatic.com/charts/loader.js"></script>
	<script src="taskList.js"></script>

	<script src="https://cdn.jsdelivr.net/npm/dayjs@1/dayjs.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/date-holidays@3/dist/umd.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/dayjs@1/plugin/utc.js"></script>
	<script>
		dayjs.extend( window.dayjs_plugin_utc );
	</script>
	
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



	<script type="text/javascript">
		
		const queryString = window.location.search; // Get the query string (e.g., "?name=John&age=30")
		const params = new URLSearchParams(queryString);
		
		
		const projectID 	= params.get( 'projectID' );
		const customerID	= params.get( 'customerID' );
		const serverName 	= '<% =systemControls("server name") %>';




		if ( !!window.performance && window.performance.navigation.type == 2 ) {
			$('.mdl-spinner').removeClass( 'is-active' );
			window.location.reload();
		}

		window.onload = function() {
// 			FilterStatus_onClick();
			$('.mdl-spinner').removeClass( 'is-active' );
		}



		//================================================================================
		function showTransientMessage( msg ) {
		//================================================================================

			let notification = document.querySelector('.mdl-js-snackbar');
			
			notification.MaterialSnackbar.showSnackbar({ message: msg });
			

		}
		//================================================================================

		
		//======================================================================================================
		async function deleteTask( taskID ) {
		//======================================================================================================

			if ( confirm( 'Are you sure you want to delete this task (this cannot be un-done)?' ) ) {

				$.ajax({
					url: `${apiServer}/api/tasks`,
					data: { taskID: taskID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					type: 'delete'
				}).done( function( response) {
					showTransientMessage( 'Task deleted' );
				}).fail( function( err ) {
					console.error( err );
					showTransientMessage( 'Error while deleting task' );
				}).always( async function() {
					$( '#tbl_tasks' ).DataTable().ajax.reload();
					const projectInfo = await getProjectInfo( projectID );

					if ( !!projectInfo.startDate ) {
						$('#titleProjectStartDate').text( moment( projectInfo.startDate, 'YYYY-MM-DD' ).format( 'M/D/YYYY' ) );
					} else {
						$('#titleProjectStartDate').text( 'No Start Date' );
					}
		
					if ( !!projectInfo.endDate ) {
						$('#titleProjectEndDate').text( moment( projectInfo.endDate, 'YYYY-MM-DD' ).format( 'M/D/YYYY' ) );
					} else {
						$('#titleProjectEndDate').text( 'No End Date' );
					}

					drawTasksGanttChart();
					
				});
				
			}
			
		}
		//======================================================================================================



		//======================================================================================================
		async function drawTasksGanttChart() {
		//======================================================================================================
			
			try {
				
				$( '#progressbarGanttChart' ).progressbar({ value: false });			
				
				const data = await $.ajax({
					url: `${apiServer}/api/tasks/ganttChart`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
					data: { projectID: projectID }
				});
				
				if ( !data || !Array.isArray( data.rows ) || data.rows.length === 0 ) {
					$('#taskTimeline').empty();          // ensure container is clean
					// optional: $('#taskTimeline').closest('.someWrapper').hide();
					return;
				}

				const timelineChart = new google.visualization.Gantt( document.getElementById( 'taskTimeline' ) );
				const timelineData = new google.visualization.DataTable( data );
				const minChartHeight = 200;
				const rowHeight = 24;
				const chartTitleBuffer = 20
				const xAxisLabelBuffer = 20
				const chartHeight = Math.max( rowHeight * timelineData.getNumberOfRows() + chartTitleBuffer + xAxisLabelBuffer, minChartHeight );
				
				timelineChart.draw( timelineData, {
					height: chartHeight,
					gantt: { barHeight: 8, labelMaxWidth: 400 },
				});

				
			} catch( err ) {
				
				throw new Error( err );

			} finally {

				$( '#progressbarGanttChart' ).progressbar( 'destroy' );			
				
			}
				
				
		}
		//======================================================================================================


		//======================================================================================================
		function drawTaskTable() {
		//======================================================================================================
			
			$( '#tbl_tasks' ).DataTable({

				ajax: {
					url: `${apiServer}/api/tasks`,
					data: { 
						customerID: customerID,
						projectID: projectID
					},
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				rowId: 'id',
				columns: [
					{ data: 'taskName', className: 'taskName dt-body-left', width: '20%' },
					{ 
						data: 'startDate', 
						className: 'startDate dt-body-center dt-head-center', 
						width: '8%', 
						type: 'date',
						render: function( data ) {

							let weekend = false;
							let holiday = false;
							
							// Convert to Date object first
							let dateObj = new Date( data );
							
							// Disable weekends: 0 = Sunday, 6 = Saturday							
							if (dateObj.getDay() === 0 || dateObj.getDay() === 6) {
								weekend = true;
							} else {
								var formattedDate = moment( dateObj ).format("YYYY-MM-DD");
								if ( publicHolidays.indexOf( formattedDate ) !== -1 ) {
									holiday = true;
								}
							}
							
							if ( weekend || holiday ) {
								return `<span style="color:red;" title="${data} is not a workday">${data}</span>`;
							} else {
								return data;
							}
							
						}
					},
					{ 
						data: 'dueDate', 
						className: 'dueDate dt-body-center dt-head-center', 
						width: '8%', 
						type: 'date',
						render: function( data ) {

							let weekend = false;
							let holiday = false;
							
							// Convert to Date object first
							let dateObj = new Date( data );
							
							// Disable weekends: 0 = Sunday, 6 = Saturday							
							if (dateObj.getDay() === 0 || dateObj.getDay() === 6) {
								weekend = true;
							} else {
								var formattedDate = moment( dateObj ).format("YYYY-MM-DD");
								if ( publicHolidays.indexOf( formattedDate ) !== -1 ) {
									holiday = true;
								}
							}
							
							if ( weekend || holiday ) {
								return `<span style="color:red;" title="${data} is not a workday">${data}</span>`;
							} else {
								return data;
							}
							
						}
					},
					{ 
						data: 'taskStatusName',		
						className: 'taskStatusName dt-body-left', 	
						width: '11%',
						render: function( data, type, row, meta ) {
							if ( data === 'Skipped' ) {
								return `Skipped&nbsp;&nbsp;<span class="material-symbols-outlined" style="vertical-align: middle;" title="This task was skipped -- it is not shown in the timeline chart and is not included in 'Days At Risk' and 'Days Behind' totals">info</span>`;
							}
							return data || '';
						}
					},
					{
						defaultContent: '',					
						className: 'checklistStatus dt-body-center dt-head-center', 	
						width: '5%',
						render: function( data, type, row, meta ) {
							return row.totalTasks > 0 ? `${row.completedTasks}/${row.totalTasks}` : '';
						}
					},
					{ data: 'completeDate', className: 'completeDate dt-body-center dt-head-center', width: '8%', type: 'date' },
					{ data: 'ownerName', className: 'ownerName dt-body-left', width: '13%' },
					{ data: 'daysAtRisk', className: 'daysAtRisk dt-body-center dt-head-center', width: '8%' },
					{ data: 'daysBehind', className: 'daysBehind dt-body-center dt-head-center', width: '8%' },
					{ 
						defaultContent: '',					
						className: 'dt-body-center dt-head-center', 
						orderable: false,
						render: function ( data, type, row, meta ) {
							// Notice we use row.taskName instead of row.name
							return `<span class="material-symbols-outlined deleteButton" style="vertical-align: middle; cursor: pointer; display: none;" title="Click to delete task '${row.taskName}'">delete</span>`;
						},
						width: '5%'
					},
					{ data: 'taskStatusID', visible: false }
				],
				order: [ [ 1, 'asc' ] ],
				searchCols: [
					null,
					null,
					null,
					{ search: '^(In Progress)|$', regex: true },
				]

			})
			.on( 'click', 'tbody > tr', function(event) {
				event.stopPropagation();
				var taskID = this.closest('TR').id;
				window.location.href=`taskDetail.asp?cmd=edit&customerID=${ customerID }&taskID=${taskID}`;
			})
			.on( 'click', 'tbody > tr > td .deleteButton', async function(event) {
				event.stopPropagation();
				var taskID = this.closest('TR').id;
				deleteTask(taskID);
			})
			.on( 'mouseover', 'tbody tr', function() {
 				$( this ).find( '.deleteButton' ).toggle();
			})
			.on( 'mouseout', 'tbody tr', function() {
 				$( this ).find( '.deleteButton' ).toggle();
			});
				
		}
		//======================================================================================================


		//======================================================================================================
		async function drawKeyInitiativesTable() {
		//======================================================================================================
			
			$( '#tbl_keyInitiatives' )
				.on( 'click', 'tbody > tr', function( e ) {
					e.stopPropagation();
					var kiID = this.closest('TR').id;
					window.location.href=`customerKeyInitiatives.asp?id=${ customerID }&ki=${kiID}`;
				})
				.on( 'click', 'tbody > tr > td .deleteButton', function(event) {

					/* what is supposed to happen here? */

				})
				.DataTable({
	
					ajax: {
						url: `${apiServer}/api/keyInitiatives/byProject`,
						data: { projectID: projectID },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columnDefs: [
						{ targets: 'kiName', 			data: 'name', 				className: 'kiName dt-body-left' },
						{ targets: 'kiCompleteDate', 	data: 'completeDate', 	className: 'kiCompleteDate dt-body-center dt-head-center', type: 'date' },
					],
					info: false,
					lengthChange: false,
					order: [ [ 0, 'asc' ] ],
					paging: false,
					rowId: 'id',
					searching: false,
	
				});

		}
		//======================================================================================================


		//======================================================================================================
		async function getProjectInfo( projectID ) {
		//======================================================================================================
			
			try {
		
				return await $.ajax({
					url: `${apiServer}/api/projects/projectDetail`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
					data: { projectID: projectID }
				});
		
			} catch ( jqXHR ) {
		
				// jQuery rejects with jqXHR, not a nice Error
				console.error( "Error getting projectDetail", {
					status: jqXHR?.status,
					statusText: jqXHR?.statusText,
					responseText: jqXHR?.responseText,
					responseJSON: jqXHR?.responseJSON
				} );
		
				// Throw a useful message so you see it in the console
				const msg =
					jqXHR?.responseJSON?.message ||
					jqXHR?.responseText ||
					jqXHR?.statusText ||
					`HTTP ${jqXHR?.status || "?"} calling projectDetail`;
		
				throw new Error( msg );
		
			}
		
		}
		//======================================================================================================



		//======================================================================================================
		async function getProjectStatus( projectID ) {
		//======================================================================================================
			
			try {

				return await $.ajax({
					url: `${apiServer}/api/projects/projectStatus`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
					data: { projectID: projectID }
				});
								
			} catch ( jqXHR ) {

				// jQuery rejects with jqXHR, not a nice Error
				console.error( "Error getting project status", {
					status: jqXHR?.status,
					statusText: jqXHR?.statusText,
					responseText: jqXHR?.responseText,
					responseJSON: jqXHR?.responseJSON
				} );
		
				// Throw a useful message so you see it in the console
				const msg =
					jqXHR?.responseJSON?.message ||
					jqXHR?.responseText ||
					jqXHR?.statusText ||
					`HTTP ${jqXHR?.status || "?"} calling project status`;
		
				throw new Error( msg );
		
			}

		}
		//======================================================================================================


		//======================================================================================================
		async function getProjectOpenItems( projectID ) {
		//======================================================================================================
			
			try {

				return await $.ajax({
					url: `${apiServer}/api/projects/openItems`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
					data: { projectID: projectID }
				});
								
			} catch ( jqXHR ) {

				// jQuery rejects with jqXHR, not a nice Error
				console.error( "Error getting projectDetail", {
					status: jqXHR?.status,
					statusText: jqXHR?.statusText,
					responseText: jqXHR?.responseText,
					responseJSON: jqXHR?.responseJSON
				} );
		
				// Throw a useful message so you see it in the console
				const msg =
					jqXHR?.responseJSON?.message ||
					jqXHR?.responseText ||
					jqXHR?.statusText ||
					`HTTP ${jqXHR?.status || "?"} calling project open items`;
		
				throw new Error( msg );
		
			}

		}
		//======================================================================================================


		//======================================================================================================
		async function showProjectStatus( projectID ) {
		//======================================================================================================
			
			const projectStatus = await getProjectStatus( projectID );

			// ---- no status yet ----
			if ( !projectStatus ) {
				$( '#projectStatus' ).text( '' );      // or '' if you prefer blank
				$( '#button_newTask' ).prop( 'disabled', false );   // choose true/false based on your rules
				return null;
			}
			
			const projectStatusDate = dayjs( projectStatus.statusDate ).format( 'M/D/YYYY' );


			switch ( projectStatus.status ) {
				
				case 'On Time':
				case 'Behind':
					
					$( '#projectStatus' ).text( `${projectStatus.status} as of ${projectStatusDate}` );
					$( "#button_newTask" ).prop( "disabled", false );
					break;
				
				case 'Escalated':
				case 'Escalate':

					$( '#projectStatus' ).text( `Escalation requested on ${projectStatusDate}` );
					$( "#button_newTask" ).prop( "disabled", false );
					break;
				
				case 'Rescheduled':
				case 'Reschedule':
				
					$( '#projectStatus' ).text( `Reschedule requested on ${projectStatusDate}` );
					$( "#button_newTask" ).prop( "disabled", false );
					break;
				
				case 'Complete':
				case 'Completed':

					$( '#projectStatus' ).text( `Completed on ${projectStatusDate}` );
					$( "#button_newTask" ).prop( "disabled", true );
					break;
				
				default:

					if ( !!projectStatus.status ) {
						$( '#projectStatus' ).text( `${projectStatus.status} as of ${projectStatusDate}` );
					}
					$( "#button_newTask" ).prop( "disabled", true );
					
			}

			return projectStatus;

		}
		//======================================================================================================



		//======================================================================================================
		async function getCustomerContacts( customerID ) {
		//======================================================================================================
			
			try {

				return await $.ajax({
					url: `${apiServer}/api/customerContacts`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
					data: { customerID: customerID }
				});
								
			} catch (err) {

				console.error(`Error getting projectDetail: ${err}`);
				throw new Error(err);

			}

		}
		//======================================================================================================



		//======================================================================================================
		async function getCustomerInfo( customerID ) {
		//======================================================================================================
			
			try {

				return await $.ajax({
					url: `${apiServer}/api/customers/${customerID}`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json",
				});

			} catch( err ) {

				console.error(`Error getting customerInfo: ${err}`);
				throw new Error( err );

			}

		}
		//======================================================================================================



		//======================================================================================================
		$(document).ready( async function() {
		//======================================================================================================

			const projectInfo = await getProjectInfo( projectID );
			const projectStatus = await showProjectStatus( projectID );

			
			$('#titleProjectName').text( projectInfo.name );
			
			if ( !!projectInfo.startDate ) {
				$('#titleProjectStartDate').text( moment( projectInfo.startDate, 'YYYY-MM-DD' ).format( 'M/D/YYYY' ) );
			} else {
				$('#titleProjectStartDate').text( 'No Start Date' );
			}

			if ( !!projectInfo.endDate ) {
				$('#titleProjectEndDate').text( moment( projectInfo.endDate, 'YYYY-MM-DD' ).format( 'M/D/YYYY' ) );
			} else {
				$('#titleProjectEndDate').text( 'No End Date' );
			}

			$( document ).tooltip();
			$( "checkboxradio" ).checkboxradio();
			$( "fieldset" ).controlgroup();
			$( '#projectStatusDate' ).datepicker({
				dateFormat: 'mm/dd/yy'
			});

			

			


			$( "#taskOwner" ).selectmenu({ 
				width: 300,
				appendTo: "body",
				position: { my: "left top", at: "left bottom", collision: "none" },
				open: function(event, ui) {
					$(ui.menuWrap).appendTo('body').css('z-index', 11001 );
				}
			});
			
			
			
			$( "#dialog_newTask" ).dialog({
				autoOpen: false,
				resizable: false,
				height: "auto",
				width: 600,
				modal: true,
				buttons: {
					Save: function() {
						
						let taskName = $("#name").val().trim();
		            let taskStartDate = $("#taskStartDate").val().trim();
		            let taskDueDate = $("#taskDueDate").val().trim();
		
		            if ( !taskName ) {
		                alert("Task name is required.");
		                $("#taskName").focus();
		                return;
		            }
		            if ( !taskStartDate ) {
		                alert("Start date is required.");
		                $("#taskStartDate").focus();
		                return;
		            }
		            if ( !taskDueDate ) {
		                alert("Due date is required.");
		                $("#taskDueDate").focus();
		                return;
		            }
	
	
							const payload = {
								customerID: $( '#customerID' ).val(),
								projectID: projectID,
								name: taskName,
								description: $( '#description' ).val(),
								ownerID: ( !!$( '#taskOwnerID' ).val() ) ? $( '#taskOwnerID' ).val() : null,
								startDate: taskStartDate,
								dueDate:taskDueDate
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
								console.error( 'an error occurred while updating/inserting customer', err );
							}).always( async function () {
								const projectInfo = await getProjectInfo( projectID );
	
								if ( !!projectInfo.startDate ) {
									$('#titleProjectStartDate').text( moment( projectInfo.startDate, 'YYYY-MM-DD' ).format( 'M/D/YYYY' ) );
								} else {
									$('#titleProjectStartDate').text( 'No Start Date' );
								}
					
								if ( !!projectInfo.endDate ) {
									$('#titleProjectEndDate').text( moment( projectInfo.endDate, 'YYYY-MM-DD' ).format( 'M/D/YYYY' ) );
								} else {
									$('#titleProjectEndDate').text( 'No End Date' );
								}
	
								drawTasksGanttChart();
								$( "#dialog_newTask" ).dialog( 'close' );							
							});
	

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



			$( '#dialog_projectStatus' ).dialog({
				autoOpen: false,
				resizable: false,
				height: "auto",
				width: 900,
				modal: true,
				buttons: {
					Save: async function() {
						
						const selectedStatus = $( "input[name='projectStatus']:checked" ).val();

						if ( selectedStatus === 'Complete' ) {

							const response = await getProjectOpenItems( projectID );
							const openItems = response.openItems.openTasks + response.openItems.openCheckLists + response.openItems.openChecklistItems;
							const massCompletePermission = response.massCompletePermission;

							if ( openItems > 0 && massCompletePermission ) {
								if ( !confirm( `There are ${openItems} in this project. Only the project will be completed, tasks, checklists, and checklist items will be left as-is. Are you sure you want to continue?\n\nThis action cannot be undone.`) ){
									return;
								}
							}

						}
							
						const projectStatusDate = $( '#projectStatusDate' ).val();
						const projectStatusComments = $( '#projectStatusComments' ).val();

						$.ajax({
							url: `${apiServer}/api/projects/updateStatus`,
							method: "PUT",
							headers: { Authorization: "Bearer " + sessionJWT },
							dataType: "json",
							data: { 
								projectID: projectID,
								projectStatusDate: projectStatusDate,
								projectStatusType: selectedStatus,
								projectStatusComments: projectStatusComments
							}
						}).done( async function() {

							const notification = document.querySelector('.mdl-js-snackbar');
							notification.MaterialSnackbar.showSnackbar({ message: 'Project status updated' });

							// update project status on main page
							const projectStatus = await showProjectStatus( projectID );
							
						}).fail( function( err ) {
							console.error( 'an error occurred while updating project status', err );
						}).always( function() {
							$( '#dialog_projectStatus' ).dialog( "close" );
						});



					},
					Cancel: function() {
						
						$( this ).dialog( "close" );
						
					}
				},



				open: async function() {

					$( '#status_onTime' ).checkboxradio( 'disable' );
					$( '#status_behind' ).checkboxradio( 'disable' );
					$( '#status_escalate' ).checkboxradio( 'disable' );
					$( '#status_reschedule' ).checkboxradio( 'disable' );
					$( '#status_complete' ).checkboxradio( 'disable' );

					$( '#projectStatusDate' ).datepicker( 'setDate', new Date() );
					
					const $dlg = $( this );
					
					// disable Save initially
					const $saveBtn = $dlg
						.parent()
						.find( '.ui-dialog-buttonpane button:contains("Save")' );
					
					$saveBtn.button( 'disable' );
					

					try {
						
						
						// Do them in parallel
						const [ projectStatus, openCounts ] = await Promise.all([
							getProjectStatus( projectID ),     // may be null
							getProjectOpenItems( projectID )
						]);
						
						const openItems = openCounts.openItems;
						const openItemCount =
							openItems.openTasks +
							openItems.openCheckLists +
							openItems.openChecklistItems;
						
						$( '#projectOpenItemCount' ).val( openItemCount );

						$( 'p.projectSummary' ).text(
							`Open Tasks: ${openItems.openTasks}, ` +
							`Checklists: ${openItems.openCheckLists}, ` +
							`Checklist Items: ${openItems.openChecklistItems}.`
						);
						
						// ---- status enable rules ----
						const currentStatus = projectStatus?.status ?? null;
						
						if ( currentStatus === 'Complete' ) {
							
							if ( openCounts.uncompletePermission ) {
								
								$( '#status_onTime' ).checkboxradio( 'enable' );
								$( '#status_behind' ).checkboxradio( 'enable' );
								$( '#status_escalate' ).checkboxradio( 'enable' );
								$( '#status_reschedule' ).checkboxradio( 'enable' );
								$( '#status_complete' ).checkboxradio( 'enable' );
								
							}
						
						} else {
							
							// currentStatus is NOT Complete OR it is null (no status yet)
							$( '#status_onTime' ).checkboxradio( 'enable' );
							$( '#status_behind' ).checkboxradio( 'enable' );
							$( '#status_escalate' ).checkboxradio( 'enable' );
							$( '#status_reschedule' ).checkboxradio( 'enable' );

							// Only allow Complete if there are open items AND they have permission
					      if ( openItemCount > 0 ) {
								
								if ( openCounts.massCompletePermission ) {
									$( '#status_complete' ).checkboxradio( 'enable' );
								} else {
									$( '#status_complete' ).checkboxradio( 'disable' );									
								}
														
							} else {
								
								$( '#status_complete' ).checkboxradio( 'enable' );
								
							}
												
						}

						
						const $projectSummary = $( 'p.projectSummary' );
						
						$projectSummary.text(
							`Open Tasks: ${openItems.openTasks}, ` +
							`Checklists: ${openItems.openCheckLists}, ` +
							`Checklist Items: ${openItems.openChecklistItems}.`
						);
						
						

										
					} catch (err) {
		
						console.error( 'Error initializing project status dialog', err );

						// Keep everything disabled and show something useful
						$( 'p.projectSummary' ).text( 'Unable to load status info right now.' );
						$( '#projectOpenItemCount' ).val( '' );
		
					}




					
					dtProjectStatusHistory = $( '#tbl_projectStatusHistory' ).DataTable({

						deferRender: true,
						scrollY: 240,
						scrollCollapse: true,
						scroller: { rowHeight: 35 },
						ordering: false,
						paging: true,
						searching: false,
						info: false,
						dom: 't',
						ajax: {
							url: `${apiServer}/api/projects/projectStatusHistory`,
							data: { 
								projectID: projectID
							},
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: ''
						},
						rowId: 'id',
						columns: [
							{ data: 'statusName', className: 'statusName dt-body-left dt-head-left', width: '120px' },
							{ 
								data: 'statusDate', className: 'statusDate dt-body-left dt-head-left', width: '110px',	
								render: function( data, type ) {
									if ( !data ) return '';
									const d = dayjs( data );
									if ( type === 'display' || type === 'filter' ) {
										return d.format( 'MM/DD/YYYY' );
									}
									return d.valueOf();
								}
							},
							{ data: 'updatedBy', className: 'updatedBy dt-body-left dt-head-left', width: '120px', visible: false },
							{ data: 'comments', className: 'comments dt-body-left dt-head-left', width: 'auto' },
							{ data: 'updatedDateTime', className: 'updatedDateTime', visible: false },
							{ data: 'isCurrent', className: 'isCurrent', visible: false }
						],
						createdRow: function ( row, data ) {



							const name = ( data.updatedBy || '' ).trim() || 'Unknown';
							const when = data.updatedDateTime
								? dayjs( data.updatedDateTime ).local().format( 'M/D/YYYY h:mm A' )
								: '';
							
							let tip = when
								? `Updated by ${name}, ${when}`
								: `Updated by ${name}`;

							if ( data.isCurrent ) {
								$( row ).addClass( 'current-status-row' );
								tip = `Current Status. ${tip}`;
							}

							
							row.title = tip;                 // sets the title attribute
							row.setAttribute( 'title', tip );// (either is fine)


						},
					});

					


				},



				close: function() {
					
					
					// make sure the stacked radio buttons are unchecked...
					const $radios = $( '#dialog_projectStatus input[name="projectStatus"]' );
					$radios
						.prop( 'checked', false )
						.checkboxradio( 'refresh' );


					// properly destroy the project status history DataTable and clean up the DOM
					const $t = $( '#tbl_projectStatusHistory' );
					if ( $.fn.DataTable.isDataTable( $t ) ) {
						$t.DataTable().destroy();
						$t.find( 'tbody' ).empty();
					}
					dtProjectStatusHistory = null;				


					// initialize the Comments field
					$( '#projectStatusComments' ).val( '' );

				
				}

			});


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





			await google.charts.load( 'current', { 'packages': [ 'gantt' ] } );
			
			const projectStartDate = moment( projectInfo.startDate ).format( 'YYYY-MM-DD' );
			const projectEndDate = moment( projectInfo.endDate ).format( 'YYYY-MM-DD' );
			$( '#projectStartDate' ).val( projectStartDate );
			$( '#projectEndDate' ).val( projectEndDate );
				

			const customerInfo = await getCustomerInfo ( customerID );
			const customerTitle = `${customerInfo.name}: ${customerInfo.instCity}, ${customerInfo.instState}`;
			const customerTitleHTML = 
				`<% =session("clientID") %> - <a href="customerList.asp">Customers</a><img src="images/ic_chevron_right_white_18dp_2x.png">` +
				`<a href="customerProjects.asp?id=${ customerID }">${ customerTitle }</a>`;

			$( "body > div.mdl-layout__container > div > header > div.mdl-layout__header-row > span" ).html( customerTitleHTML );
			
			
			drawTasksGanttChart();
			drawKeyInitiativesTable();
			drawTaskTable();


			//-----------------------------------------------------------------------------------------------------
			$( '#filterButton' ).on( 'click', function() {
			//-----------------------------------------------------------------------------------------------------
				
				const taskTable = $( '#tbl_tasks' ).DataTable();
				const currSearch = taskTable.column( 3).search();
				
				if ( currSearch === '^(In Progress)|$' ) {
					this.textContent = 'Hide Completed Tasks';
					taskTable.column( 3 ).search( '' ).draw();
				} else {
					this.textContent = 'Show Completed Tasks';
					taskTable.column( 3 ).search( '^(In Progress)|$' ).draw();
				}

			});
			//-----------------------------------------------------------------------------------------------------


			//-----------------------------------------------------------------------------------------------------
			$( '#button_newTask' ).on( 'click', function( event ) {
			//-----------------------------------------------------------------------------------------------------

				$( "#dialog_newTask" ).dialog( 'open' );
					

			});
			//-----------------------------------------------------------------------------------------------------
				

			//-----------------------------------------------------------------------------------------------------
			$( '#button_UpdateProjectStatus' ).on( 'click', function( event ) {
			//-----------------------------------------------------------------------------------------------------

				$( "#dialog_projectStatus" ).dialog( 'open' );
					

			});
			//-----------------------------------------------------------------------------------------------------
				

			//-----------------------------------------------------------------------------------------------------
			$( document ).on( 'change', 'input[name="projectStatus"]', function () {
			//-----------------------------------------------------------------------------------------------------
			
				const $dlg = $( '#dialog_projectStatus' );
				
				if ( !$dlg.dialog( 'isOpen' ) ) return;
				
				const $saveBtn = $dlg
					.parent()
					.find( '.ui-dialog-buttonpane button:contains("Save")' );
				
				$saveBtn.button( 'enable' );
				
			});
			//-----------------------------------------------------------------------------------------------------



		});

			


	</script>		 

	<script>
		window.addEventListener('pageshow', function(event) {
			if (event.persisted) {
				window.location.reload();
			}
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
/* 	  .selectable li { margin: 3px; padding: 0.4em; font-size: 1.4em; height: 18px; } */

	
		
		.skipped {
			text-decoration: line-through;
		}

		td.taskName {
			max-width: 450px;
			text-overflow: ellipsis;
			white-space: nowrap;
			overflow: hidden;		
		}
		
		table > tfoot th.dt-body-right {
			text-align: right;
		}

		table.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
		table.dataTable > tbody > tr {
			height: 35px;
		}


		/* these styles allow the Open Tasks Gantt chart to grow vertically when needed */
		#taskTimeline {
		    height: auto;
		    min-height: 200px; /* Or whatever minimum height you prefer */
		}
		
		.mdl-cell--8-col {
		    height: auto;
		}
		
		input.date { margin-bottom:12px; width:100px; padding: .4em; margin-right: 12px; }
		input.text, textarea { margin-bottom:25px; width:95%; padding: .4em; }


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

		label.checkboxradio {
			text-align: left;
			width: 150px;
		}
		
		.projectStatusHistoryCell {
			vertical-align: top;          /* aligns cell contents to top */
		}
		
		.projectStatusHistoryWrapper {
			width: 100%;
			table-layout: fixed;
		}
		
		table.projectStatusLayout {
			width: 100%;
			table-layout: fixed;        /* key: makes the right cell actually get the remaining width */
		}
		
		td.projectStatusLeft {
			width: 340px;               /* pick whatever fits your radio stack */
			vertical-align: top;
		}
		
		td.projectStatusRight {
			width: auto;
			vertical-align: top;
			text-align: left;
		}
		
		#tbl_projectStatusHistory {
			width: 100% !important;     /* DataTables likes to get cute */
		}

		.dtFill .dataTables_wrapper,
		.dtFill table.dataTable {
		  width: 100% !important;
		}


		/* Layout */
		#dialog_projectStatus .ps-grid{
		  display: grid;
		  grid-template-columns: 250px 1fr; /* left fixed, right fills */
		  gap: 12px;
		  align-items: start;
		}
		
		#dialog_projectStatus .ps-left,
		#dialog_projectStatus .ps-right{
		  min-width: 0; /* important: lets the DataTable shrink/grow correctly */
		}
		
		/* Make sure nothing right-aligns the DataTable */
		#dialog_projectStatus .ps-right{
		  text-align: left;
		}
		
		/* DataTable fill rules (scoped + forceful) */
		#dialog_projectStatus .ps-dtWrap{
		  width: 100%;
		}
		
		#dialog_projectStatus .ps-dtWrap .dataTables_wrapper,
		#dialog_projectStatus .ps-dtWrap table.dataTable{
		  width: 100% !important;
		}
		
		/* Comments */
		#dialog_projectStatus .ps-comments{
		  margin-top: 16px;
		}
		
		#dialog_projectStatus #projectStatusComments{
		  width: 100%;
		  box-sizing: border-box;
		  padding: 6px;
		  resize: vertical;
		}
		
		.ps-fieldset > label {
			width: 180px;
			text-align: left;
		}
		
		.ps-historyTitle,
		.ps-fieldset > legend {
			font-weight: bold;
		}
		
		#tbl_projectStatusHistory tr.current-status-row td {
			background-color: #fff8d6;
			font-weight: 600;
		}

	</style>
	
</head>


<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div class="page-content">

    <!-- Your content goes here -->


	<div class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button type="button" class="mdl-snackbar__action"></button>
	</div>
	
		
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
		
	</div><!-- New Add/Edit Project Dialog -->


	<!-- Project Status Dialog -->
<div id="dialog_projectStatus" title="Update Project Status" style="display:none;">

  <p class="validateTips">
    Select a project status and then click SAVE to update the project status to the date shown.
  </p>
  <p class="projectSummary"></p>
  

  <div class="ps-grid">

		<div class="ps-left">
			<fieldset class="ps-fieldset">

				<legend>Select an action:</legend>
				
				<label for="status_onTime">Mark On Time</label>
				<input type="radio" name="projectStatus" id="status_onTime" value="On Time">
				<br>
				<label for="status_behind">Mark Behind Schedule</label>
				<input type="radio" name="projectStatus" id="status_behind" value="Behind">
				<br>
				<label for="status_escalate">Escalate</label>
				<input type="radio" name="projectStatus" id="status_escalate" value="Escalate">
				<br>
				<label for="status_reschedule">Reschedule</label>
				<input type="radio" name="projectStatus" id="status_reschedule" value="Reschedule">
				<br>
				<label for="status_complete">Complete</label>
				<input type="radio" name="projectStatus" id="status_complete" value="Complete">
				<br>
			
			</fieldset>
			
			<div class="ps-dateRow">
			<label for="projectStatusDate">Status Date:</label>
			<input type="text" id="projectStatusDate" class="ui-widget ui-widget-content ui-corner-all">
			</div>
		</div>
		
		<div class="ps-right">
			<div class="ps-historyTitle" style="width: 100%; text-align: center; border-bottom: 1px solid #000;">Project Status History</div>
			
			<div class="ps-dtWrap">
				<table id="tbl_projectStatusHistory" class="compact display" style="width:100%">
					<thead>
						<tr>
							<th>Status</th>
							<th>Date</th>
							<th>Updated By</th>
							<th>Comments</th>
							<th>updatedDateTime</th>
							<th>isCurrent</th>
						</tr>
					</thead>
				</table>
			</div>
		</div>


		<input type="hidden" id="projectOpenItemCount">

  </div>

  <div class="ps-comments">
    <label for="projectStatusComments">Comments</label>
    <textarea id="projectStatusComments" rows="3"
      class="ui-widget ui-widget-content ui-corner-all"></textarea>
  </div>

</div>		

	
	<div class="mdl-grid">
		
		<div class="mdl-layout-spacer"></div>

		<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" align="center">
			<h5>
				<span id="titleProjectName"></span><br><span id="titleProjectStartDate"></span> - <span id="titleProjectEndDate"></span>
			</h5>
		</div>

		<div class="mdl-layout-spacer"></div>
		
	</div>


	<div id="gridForTaskTimeLine" class="mdl-grid ">

		<div class="mdl-layout-spacer"></div>
		<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" align="center" style="text-align: center; padding: 5px;">
			<h5 style="margin-bottom: 0">Open Tasks</h5>
			<div id="progressbarGanttChart"></div>
			<div id="taskTimeline"></div>	   	
			
		</div>
		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="text-align: center; padding: 5px;">
			<h5>Key Initiatives</h5>
			<table id="tbl_keyInitiatives" class="compact display">
				<thead>
					<tr>
						<th class="kiName">Name</th>
						<th class="kiCompleteDate">Complete</th>
					</tr>
				</thead>
			</table>

		</div>
		
		<div class="mdl-layout-spacer"></div>

	</div>


	<div id="gridForButton" class="mdl-grid" style="padding-bottom: 0;">

		<div class="mdl-layout-spacer"></div>
		<div class="mdl-cell mdl-cell--3-col" style="position: relative; margin-bottom: 0px;">
			<% if userPermitted(72) then %>
				<button id="button_newTask" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="position: absolute; left: 0; bottom: 0;"> 
				  New Task
				</button>
			<% end if %>
		</div>
		<div class="mdl-cell mdl-cell--3-col" style="text-align: center; margin-bottom: 0px;">
			<div>
				<div id="projectStatus"></div>
				<% if userPermitted(96) then %>
					<button id="button_UpdateProjectStatus" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--colored" data-projectID="<% =projectID %>" >
						Update Project Status 
					</button>
					<br>
				<% end if %>
			</div>
		</div>
		<div class="mdl-cell mdl-cell--3-col" style="position: relative; margin-bottom: 0px;">
			<button id="filterButton" class="mdl-button mdl-js-button mdl-js-ripple-effect" style="position: absolute; right: 0; bottom: 0;">
			  Show Completed Tasks
			</button>
		</div>
		<div class="mdl-layout-spacer"></div>

	</div>


	<div class="mdl-grid">
	<div class="mdl-layout-spacer"></div>		
		
   <div class="mdl-cell mdl-cell--10-col " align="center" style="overflow-x: auto">
	    

		<table id="tbl_tasks" class="compact display">
			<thead>
				<tr>
					<th class="taskName">Task</th>
					<th class="startDate">Start</th>
					<th class="dueDate">Due</th>
					<th class="taskStatusName">Status</th>
					<th class="checklistStatus"><i class="material-symbols-outlined" style="vertical-align: middle;" title="Open checklist items / Total checklist items">checklist</i></th>
					<th class="completeDate">Complete</th>
					<th class="ownerName">Owner</th>
					<th class="daysAtRisk" title="After Start Date, if Task not Complete, the number of work days from Start Date to the earlier of today's date or Due Date (otherwise zero). ">Work&nbsp;Days<br>At&nbsp;Risk</th>
					<th class="daysBehind" title="If Task not Complete by Due Date, the number of work days from Due Date to the earlier of today's date or Complete Date.">Work&nbsp;Days<br>Late</th>
					<th class="actions">Actions</th>
					<th class="taskStatusID"></th>
				</tr>
			</thead>
		</table>		    			    

	</div>

	<div class="mdl-layout-spacer"></div>
	
    
  </main>
	<!-- #include file="includes/pageFooter.asp" -->
</div>

<%
dataconn.close 
set dataconn = nothing
%>


</body>
</html>