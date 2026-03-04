<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

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
call checkPageAccess(51)

customerID = request.querystring("id")
%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customerProjects")

templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")


if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	projectID = request.querystring("projectID")
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

	<script src="customerView.js"></script>
	<script src="customerProjects.js"></script>


	<script>

		// this little script automatically refreshes this page if the user navigates here using the browser's back arrow		
		if (!!window.performance && window.performance.navigation.type == 2 ) {
			window.location.reload();

		}

		const queryString = window.location.search; // Get the query string (e.g., "?name=John&age=30")
		const params = new URLSearchParams(queryString);
		const customerID	= params.get( 'id' );
		const HIDE_COMPLETED_REGEX = '^(?!Complete$).*$'; // exclude exact "Complete"

		
		//============================================================================
		function setHideCompleted( table, hideCompleted ) {
		//============================================================================

			const statusCol = table.column( 'status:name' );
			
			if ( hideCompleted ) {
				statusCol.search( HIDE_COMPLETED_REGEX, true, false ); // regex=true, smart=false
			} else {
				statusCol.search( '' );
			}
			
			table.draw();
			
		}
		//============================================================================

		
		//============================================================================
		$(document).ready(function() {
		//============================================================================

			$( "#process" ).selectmenu({
				 appendTo: ".ui-dialog"
			});

			dialog = $( "#dialog-form" ).dialog({
				// new PROJECT dialog
				autoOpen: false,
// 				height: 400,
				width: 523,
				modal: true,
				buttons: {
					"Save": async function() {
						
						if ( dialog.dialog('option','title').includes( 'Edit' ) ) {


					    	$.ajax({
					
								url: `${apiServer}/api/projects`,
								method: 'PUT',
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								data: {
									projectID: $( '#id' ).val(),
									name: $( '#name' ).val(),
									customerID: $( '#customerID' ).val(),
									projectManagerID: $( '#projectManager' ).val(),
									startDate: moment( $( '#startDate' ).val() ).format( 'YYYY-MM-DD' ),
									endDate: moment( $( '#endDate' ).val() ).format( 'YYYY-MM-DD' )
								},
								success: function( response ) {
				
									const notification = $( '.mdl-js-snackbar' ).get(0);
									notification.MaterialSnackbar.showSnackbar({message: `Project updated` });
									dialog.dialog( 'close' );
									$( '#tbl_projects' ).DataTable().ajax.reload();
				
								},
								error: function( xhr, status, error ) {
									const notification = $( '.mdl-js-snackbar' ).get(0);
									notification.MaterialSnackbar.showSnackbar({message: `Error adding project` });
									console.error( "Error updating project:", status, error );
								}
					
							});
							
							
						} else {
							// adding a new project....
							
							let $thisButton = $(this).parent().find("button:contains('Save')");
							$thisButton.prop("disabled", true);  // Disable button to prevent re-entry
							
							var saveResult = await AddProject_onSave( dialog );
							
							if ( saveResult ) {
	
								setTimeout(() => {						
									$( this ).dialog( 'close' );
									$( this ).find( 'form' )[0].reset();	
									$( '#startDate' ).datepicker( 'option', 'maxDate', null );
									$( '#endDate' ).datepicker( 'option', 'minDate', null );
									$( '#anchorDateLabel' ).hide();
									$( '#anchorDate' ).hide();
								}, 0);  // Delays execution, preventing re-entrancy
							
							}
							
							$thisButton.prop("disabled", false);  // Re-enable button after operation

						}
				
					},
					Cancel: function() {
						$( this ).dialog( 'close' );
						$( this ).find( 'form' )[0].reset();					
						$( '#startDate' ).datepicker( 'option', 'maxDate', null );
						$( '#endDate' ).datepicker( 'option', 'minDate', null );
						$( '#anchorDateLabel' ).hide();
						$( '#anchorDate' ).hide();
					}
				},
				open: function () {
					
 					
					const mode = ( dialog.dialog('option','title').includes( 'Edit' ) ) ? 'edit' : 'add';
					

					if ( mode === 'add' ) {

						let $processSelect = $("#process");
						$processSelect.empty().append('<option value="">Loading...</option>');
						
						
						
						$.ajax({
							url: `${apiServer}/api/projectTemplates`,
							method: 'GET',
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
	// 						dataSrc: '',
							dataType: 'json'
						}).done(function (data) {
							
							$processSelect.empty().append(`
								<option disabled selected>Please pick one</option>
								<option value="scratch">Create a project from scratch</option>
								<optgroup label="Existing Templates">
							`);
							
							data.forEach(function (item) {
								$processSelect.append(
									$('<option>', {
										value: item.id,
										text: item.name
									})
								);
							});
							
							$( "#process" ).selectmenu( "refresh" );
							
						}).fail(function () {
							$processSelect.empty().append('<option value="">Error loading templates</option>');
						});

					}

				},
				close: function() {

					$( this ).dialog( 'close' );
					$( this ).find( 'form' )[0].reset();					
					$( '#startDate' ).datepicker( 'option', 'maxDate', null );
					$( '#endDate' ).datepicker( 'option', 'minDate', null );
					$( '#anchorDateLabel' ).hide();
					$( '#anchorDate' ).hide();


				}

 			});


			templateDialog = $( "#dialog-template" ).dialog({
				// new PROJECT dialog
				autoOpen: false,
// 				height: 400,
				width: 523,
				modal: true,
				buttons: {
					"Save": async function() {
						
// 						alert('you pressed the save template dialog button');

				    	$.ajax({
				
							url: `${apiServer}/api/projectTemplates`,
							method: 'POST',
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {
								sourceProjectID: $( '#sourceProjectID' ).val(),
								targetTemplateName: $( '#targetTemplate' ).val(),
							},
							success: function( response ) {
			
								const notification = $( '.mdl-js-snackbar' ).get(0);
								notification.MaterialSnackbar.showSnackbar({message: `Template added` });
								templateDialog.dialog( 'close' );
			
							},
							error: function( xhr, status, error ) {
								const notification = $( '.mdl-js-snackbar' ).get(0);
								notification.MaterialSnackbar.showSnackbar({message: `Error adding template` });
								console.error( "Error adding template:", status, error );
							}
				
						});




					},
					Cancel: function() {
						
						templateDialog.dialog( 'close' );
					}

				},
				open: function () {

					const rowData = templateDialog.data( 'rowData' );
					$( '#sourceProject' ).val( rowData.name );
					$( '#sourceProjectID' ).val( rowData.id );

					const $templateTips = $( '#templateTips' );
					$templateTips.html( 'Enter a new template name, or select the name of existing template to replace that template.' );

					const $templateWarning = $( '#templateWarning' );
					if ( !rowData.isTemplatable ) {
						$templateWarning.html( `<span style="color: red">NOTE: The source project or its tasks use non-workday dates; template may differ from source project.</span>` );
					}

					let $existingTemplates = $("#existingTemplates");
					$existingTemplates.empty().append('<option value="">Loading...</option>');
					
					$.ajax({
						url: `${apiServer}/api/projectTemplates`,
						method: 'GET',
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataType: 'json'
					}).done(function (data) {
						
						$existingTemplates.empty();
						
						data.forEach(function (item) {
							$existingTemplates.append(
								$('<option>', {
									value: item.id,
									text: item.name
								})
							);
						});
						
						$( "#existingTemplates" ).selectmenu( "refresh" );
						
					}).fail(function () {
						$existingTemplates.empty().append('<option value="">Error loading existing templates</option>');
					});
				},
				close: function() {
					
					templateDialog.dialog( 'close' )

				}

 			});


			
			$( '#button_newProject' ).on( 'click', function( event ) {
				$( '#dialog-form' ).dialog( {
					title: 'Add Project'
				} );
				
				$( '#processFieldset' ).show();

				$( '#nameFieldset' ).hide();
				$( '#existingProjectsFieldset' ).hide();
				$( '#projectManagerFieldset' ).hide();
				$( '#addDatesFieldset' ).hide();		

				$( '.ui-state-error' ).removeClass( 'ui-state-error' );
				
// 				$( 'button.ui-button:contains(Save)' ).prop('disabled',true).css('opacity',0.5);
				$( '#customerID' ).val( <% =customerID %> );
				$( '#dialog-form' ).dialog( 'open' );

			});


			const dateFormat = 'mm/dd/yy';

			//------------------------------------------------------------------------------
			function loadHolidaysForYear( year ) {
			//------------------------------------------------------------------------------

				holidaySet = new Set(
					hd.getHolidays( year )
						.filter( holiday => blockedTypes.includes( holiday.type ) )
						.map( h => dayjs( h.date ).format( 'YYYY-MM-DD' ) )
				);

			}
			//------------------------------------------------------------------------------

			
			//------------------------------------------------------------------------------
			function isHolidayString( d ) {
			//------------------------------------------------------------------------------

				return holidaySet.has( dayjs( d ).format( 'YYYY-MM-DD' ) );

			}
			//------------------------------------------------------------------------------
			
			
			//------------------------------------------------------------------------------
			function beforeShowDay( d ) {
			//------------------------------------------------------------------------------
	
				// Common cell logic: disable weekends + holiday types from `blockedTypes`
				
				const day = d.getDay();
				if ( day === 0 || day === 6 ) {
					return [ false, '', 'Weekends are disabled' ];
				}
				const blocked = isHolidayString( d );
				return [ !blocked, blocked ? 'holiday' : '', blocked ? 'Holiday is disabled' : '' ];
	
			}
			//------------------------------------------------------------------------------
			
			
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
			const startDate = $( '#startDate' )
				.attr("readonly", true)
				.datepicker( baseOpts )
				.on( 'change', function () {
					endDate.datepicker( 'option', 'minDate', getDate( this ) );
					$( '.startDateTip' ).remove();
					$( this ).css( 'color', '' );
				});
			
			const endDate = $( '#endDate' )
				.attr("readonly", true)
				.datepicker( baseOpts )
				.on( 'change', function () {
					startDate.datepicker( 'option', 'maxDate', getDate( this ) );
					$( '.endDateTip' ).remove();
					$( this ).css( 'color', '' );
				});
			
			const anchorDate = $( '#anchorDate' )
				.attr("readonly", true)
				.datepicker( baseOpts );

			
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


			$( "#dialog-confirm" ).dialog({
				autoOpen: false,
		      resizable: false,
		      height: "auto",
		      width: 350,
		      modal: true,
		      buttons: {
		        "Delete Project": function() {
						DeleteProject( this );
						$( '.ui-tooltip-content' ).parents( 'div' ).remove()
		        },
		        Cancel: function() {
		          $( this ).dialog( "close" );
		        }
		      }
		    });			

			
			$.fn.dataTable.moment( 'M/D/YYYY' );

			$( document ).tooltip();
			
			$( '#process' ).selectmenu({ width: 300 });
			$( '#projectManager' ).selectmenu({ width: 300 });

			$( '#existingProjects' ).selectable({
				
				// this function ensures that only one item is selected at a time...
				selected: function(event, ui) { 
					$(ui.selected).addClass("ui-selected").siblings().removeClass("ui-selected");           
   			}, 				
				
				stop: function() {
					var result = $( "#select-result" ).empty();
					$( ".ui-selected", this ).each(function() {
						$( '#name' ).val( $( this ).text() );
					});
				}
				
			});

			$( '.controlgroup' ).controlgroup();
			$( "#controlgroup" ).controlgroup();
			$( ".anchorDateType" ).checkboxradio();


			
/*
			var searchButton = document.getElementById('searchButton');
			if (searchButton) {
				searchButton.addEventListener('click', function() {
					var currentLabel = this.textContent;
					var table = $('#tbl_projects').DataTable();
					if ( currentLabel.trim() == 'Show All Projects' ) {
						table.column(8).search('').draw();
						searchButton.textContent = 'Hide Completed Projects';
					} else {
						table.column(8).search( '^((?!Complete).)*$', true, false ).draw();
						searchButton.textContent = 'Show All Projects';
					}
				});
				
			}
*/
			const searchButton = document.getElementById('searchButton');
			let hideCompleted = true;
			
			searchButton.textContent = 'Show All Projects';
			
			//------------------------------------------------------------------------------
			searchButton.addEventListener('click', function () {
			//------------------------------------------------------------------------------

				hideCompleted = !hideCompleted;
				setHideCompleted( table, hideCompleted );
				searchButton.textContent = hideCompleted ? 'Show All Projects' : 'Hide Completed Projects';

			});
			//------------------------------------------------------------------------------


			var table = $('#tbl_projects')
				.on( 'click', 		'tbody > tr', function() {

					event.preventDefault();
					
					if ( !!this.id ) {
						var projectID = this.id;
						window.location.href = 'taskList.asp?customerID=<% =customerID %>&projectID='+projectID;
					}

				})
				.on( 'click', 		'td.details-control', function(event) {

					event.preventDefault();
					event.stopPropagation();
					
					var tr 	= $(this).closest('tr');
					var row 	= table.row( tr );
					
					var customerID 			= row.data().customerID;
					var projectID				= row.data().id;
					var projectStartDate 	= row.data().startDate;
					var projectEndDate		= row.data().endDate;
					var projectStatus			= row.data().status;
					

					if ( row.child.isShown() ) {
						row.child.hide();
						tr.removeClass('shown');
					} else {
						row.child( 
							'<div class="child">'
								+	'<table style="width: 100%;"><tr>'
									+	'<td style="vertical-align: bottom; text-align: right; width: 100%;">'
										+	'<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent showTasks" data-projectID="'+projectID+'">'
											+ 	'show all tasks'
										+	'</button>'
									+	'</td>'
								+	'</tr></table>'
		               	+	'<table class="childTasks compact display" id="tasksForProject_' + projectID + '"><thead><tr>'
		               		+	'<th class="taskName">Tasks</th>'
		               		+	'<th>Start</th>'
		               		+	'<th>Due</th>'
		               		+	'<th>Complete</th>'
		               		+	'<th>Owner</th>'
		               		+	'<th></th>'
		               	+ 	'</tr></thead><tbody></tbody></table>'
								+	'<br><br>'
								+	'<table style="width: 100%;"><tr>'
									+	'<td style="vertical-align: bottom; text-align: right;">'
										+	'<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent showKIs" data-projectID="'+projectID+'">'
											+ 	'show all Key Initiatives'
										+	'</button>'
									+	'</td>'
								+	'</tr></table>'
		               	+	'<table class="childKIs compact display" id="kisForProject_' + projectID + '"><thead><tr>'
		               		+	'<th class="kiName">Key Initiatives</th>'
		               		+	'<th>Start</th>'
		               		+	'<th>Due</th>'
		               		+	'<th class="kiCompleteDate">Complete</th>'
		               		+	'<th></th>'
		               	+ 	'</tr></thead><tbody></tbody></table>'
	               	+	'</div>'
		               ).show();
						var taskTable = $('#tasksForProject_'+projectID)
							.on( 'click', 'td.link', async function(event) {
							
								event.stopPropagation();
							
								try {

									// remove lingering tooltips...
									$( '.ui-tooltip-content' ).parents( 'div' ).remove();
	
									if ( $(this).find('i').hasClass('disabled') ) {
										return false;
									}
								
									const taskID 				= this.closest( 'tr' ).id;
									const customerID 			= <% =customerID %>;
									const projectTable 		= this.closest( 'table' );
									const projectWrapper 	= projectTable.closest( 'div' );
									const projectWrapperID 	= projectWrapper.id;
									const projectID 			= projectWrapperID.substring(projectWrapperID.indexOf('_')+1, projectWrapperID.lastIndexOf('_'));
	
									const button = this.querySelector( 'i' );
	
									let taskProjectID;
									
									if ( button.classList.contains( 'add' ) ) {
										taskProjectID = projectID;
									} else { 
										taskProjectID = null;
									}
									
									await toggleTaskProject( taskID, customerID, taskProjectID );
	
									$( '#tasksForProject_'+projectID ).DataTable().ajax.reload( null, false );

									$( '.mdl-js-snackbar' ).get(0).MaterialSnackbar.showSnackbar({message: `Task updated` });

										
								} catch( err ) {
									
									const notification = $( '.mdl-js-snackbar' ).get(0);
									notification.MaterialSnackbar.showSnackbar({message: `Task update failed` });
									
									
								}
								
							})
							.on( 'click', 'tbody > tr[role!="child"]', function(event) {

								event.preventDefault();
								event.stopPropagation();
								
								if ( !!this.id ) {
									var taskID = this.id;
									window.location.href = 'taskDetail.asp?customerID=<% =customerID %>&taskID='+taskID;
								}

							})
							.DataTable({
								destroy: true,
								paging: true,
								lengthMenu: [[5,10,15,-1],[5,10,15,'All']],
								info: true,
								searching: true,
								processing: false,
								serverSide: false,
								ajax: {
									url: `${apiServer}/api/tasks`,
									headers: { 'Authorization': 'Bearer ' + sessionJWT },
									data: { customerID: customerID },
									dataSrc: '',
								},
								rowId: 'id',
								columns: [
									{ 	data: 'taskName', 		className: 'taskName dt-body-left',defaultContent: '' },
									{ 	
										data: 'startDate', 		
										width: '10%', 	
										className: 'dt-body-center',
										defaultContent: '',
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
										width: '10%', 	
										className: 'dt-body-center',
										defaultContent: '',
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
									{ 	data: 'completeDate', 	width: '10%', 	className: 'dt-body-center', defaultContent: '' },
									{ 	data: 'ownerName', 		className: 'dt-body-left',	defaultContent: '' },
									{
										data: function( row, type, val, meta ) {
											let iconName, title, className;

											if ( row.projectID == projectID ) {

												if ( row.projectStatus == 'Complete' ) {
													iconName	 	= 'remove_circle_outline';
													className 	= 'disabled';
													title 		= 'Project is complete; removing task is not allowed';
												} else {
													iconName	 	= 'remove_circle_outline';
													className 	= 'remove';
													title 		= 'Click to remove this task from the project';
												}
											} else {
												if ( row.projectID ) {
													iconName		= 'block';
													className	= 'disabled';
													title			= 'This task is assigned to a different project';
												} else {
													if ( moment(row.startDate).isSameOrAfter(moment(projectStartDate)) ) {
														if ( moment(row.dueDate).isSameOrBefore(moment(projectEndDate)) ) {
															iconName		= 'add_circle_outline';
															className	= 'add';
															title			= 'Click to add this task to the project';
														} else {
															iconName		= 'block';
															className	= 'disabled';
															title			= 'Task is due after project ends';
														}
													} else {
														iconName		= 'block';
														className	= 'disabled';
														title			= 'Task starts before project starts';
													}
												}
											}
											
											return '<i class="material-icons '+className+'" title="'+title+'">'+iconName+'</i>';

										},		
										width: '24px', 
										orderable: true, 
										className: 'link dt-body-center', 
										defaultContent: ''
									},
								],
								order: [[1, 'desc']],
								searchCols: [
									null,
									null,
									null,
									null,
									null,
									{ search: '^remove_circle_outline$|^$', regex: true },
								]
							});
						var kiTable = $('#kisForProject_'+projectID)
							.on( 'click', 'tbody > tr[role!="child"]', function(event) {

								event.preventDefault();
								event.stopPropagation();

								if ( !!this.id ) {
									keyInitiativeID = this.id;
									kiCompleteDate = this.querySelector('td.kiCompleteDate').textContent;
									kiFilter = '';
									
									window.location.href = 'customerKeyInitiatives.asp?id=<% =customerID %>&ki=' + keyInitiativeID + '&kiFilter=' + kiFilter;
								}

							})
							.on( 'click', 'td.link', async function (event) {
							
								event.stopPropagation();

								// remove lingering tooltips...
								await $( '.ui-tooltip-content' ).parents( 'div' ).remove();

								if ( $(this).find('i').hasClass('disabled') ) {
									return false;
								}
							
								const keyInitiativeID = this.closest('tr').id;
								const customerID = <% =customerID %>;
								const kiTable = this.closest('table');
								const projectWrapper = kiTable.closest('div');
								const projectWrapperID = projectWrapper.id;
								const projectID = projectWrapperID.substring(projectWrapperID.indexOf('_')+1, projectWrapperID.lastIndexOf('_'));

								const button = this.querySelector('i');
								
								if ( button.classList.contains('add') ) {
									await addTaskKeyInitiative( keyInitiativeID, projectID );
								} else { 
									await deleteTaskKeyInitiative( keyInitiativeID, projectID );
								}

								$( '#kisForProject_'+projectID ).DataTable().ajax.reload( null, false );
								$( '.mdl-js-snackbar' ).get(0).MaterialSnackbar.showSnackbar({message: `Key initiative updated` });
								
							})
							.DataTable({
								paging: true,
								lengthMenu: [[5,10,15,-1],[5,10,15,'All']],
								info: true,
								searching: true,
								processing: false,
								serverSide: false,
								ajax: {
									url: '/ajax/keyInitiatives.asp?customerID='+<% =customerID %>+'&projectID='+projectID,
								},
								columns: [
									{targets: 'kiName', 									data: 'kiName', 			className: 'kiName dt-body-left'},
									{targets: 'startDate', 			width: '10%', 	data: 'startDate', 		className: 'dt-body-center'},
									{targets: 'dueDate', 			width: '10%', 	data: 'dueDate', 			className: 'dt-body-center'},
									{targets: 'kiCompleteDate', 	width: '10%', 	data: 'completeDate',	className: 'kiCompleteDate dt-body-center'},
									{
										targets: 'actions', 	
										width: '24px', 
										orderable: true, 
										className: 'link dt-body-center', 
										data: function( row, type, val, meta ) {
											var iconName, title;

											if ( row.relatability == 'linked') {
												iconName 	= 'remove_circle_outline';
												className 	= 'remove linked';
												title 		= 'Click to dis-associate key initiative and project';

											} else {
												
												if ( moment(row.startDate).isSameOrBefore(moment(projectStartDate)) ) {
													
													if ( moment(row.dueDate).isSameOrAfter(moment(projectEndDate)) ) {
														
														iconName 	= 'add_circle_outline';
														className 	= 'add linkable';
														title			= 'Click to associate key initiative and project';
														
													} else {
														
														iconName 	= 'block';
														className 	= 'disabled';
														title			= 'Key initiative ends before project ends';
														
													}

												} else {
													
													iconName 	= 'block';
													className 	= 'disabled';
													title			= 'Key initiative starts after project starts';													
													
												}
																								
												
											}	

											return '<i class="material-icons '+className+'" title="'+ title + '">'+iconName+'</i>';

										}		
									},
									{targets: 'relatability', 	data: 'relatability', visible: false, searchable: true},
								],
								order: [[1, 'desc']],
								searchCols: [
									null,
									null,
									null,
									null,
									{ search: 'remove_circle_outline' },
									null,
								]
							});
						
						if ( row.data().status == 'Complete' ) {
							$( 'button.showTasks' ).hide();
						}
						
						tr.addClass('show');
						
					}

				})
				.on( 'click', 		'button.showKIs', function(event) {
					
					event.preventDefault();
					event.stopPropagation();
					
					const projectID			= this.getAttribute( 'data-projectID' );
					const childKIsTable 		= $( '#kisForProject_'+projectID ).DataTable();
					const currSearch 			= childKIsTable.column( 4 ).search();

					if (currSearch == 'remove_circle_outline') {
						this.textContent = 'Show Linked Key Initiatives';
						childKIsTable.column( 4 ).search( '' ).draw();
					} else {
						this.textContent = 'Show All Key Initiatives';
						childKIsTable.column( 4 ).search( 'remove_circle_outline' ).draw();
					}


				})
				.on( 'click', 		'button.showTasks', function(event) {

					event.preventDefault();
					event.stopPropagation();

					const projectID			= this.getAttribute( 'data-projectID' );
					const childTasksTable 	= $( '#tasksForProject_'+projectID ).DataTable();
					const currSearch			= childTasksTable.column( 5 ).search();

					if (currSearch == '^remove_circle_outline$|^$') {
						this.textContent = 'Show Linked Tasks';
						childTasksTable.column( 5 ).search( '' ).draw();
					} else {
						this.textContent = 'Show All Tasks';
						childTasksTable.column( 5 ).search( '^remove_circle_outline$|^$' ).draw();
					}


				})
				.on( 'click', 		'i.clone', function( event ) {

// 					event.preventDefault();
					event.stopPropagation();
					
					if ( $( this ).hasClass( 'disabled' ) ) {
						return;
					}

					const row = table.row( $(this).closest('tr') ).data();
					templateDialog.data('rowData', row);
					templateDialog.dialog( 'open' );
					
				})
				.on( 'click', 		'i.edit', function(event) {

					event.preventDefault();
					event.stopPropagation();
					
					EditProject_onClick(this);
					
				})
				.on( 'click', 		'i.delete', function( event ) {
					
					event.stopPropagation();
					
					ConfirmProjectDelete_onClick( this );
				})
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons(this);
				})
				.on( 'mouseout', 	'tbody tr', function() {
					ToggleActionIcons(this);
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/projects?customerID=${customerID}`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					rowId: 'id',
					columns: [
						{
							className: 'details-control dt-body-center dt-head-center',
							orderable: false,
							data: null,
							defaultContent: ''
						},
						{ targets: 'projectName', 				data: 'name', 			className: 'projectName dt-body-left dt-header-left' },
						{ targets: 'kiCount', 					data: 'kiCount', 					className: 'kiCount dt-body-center dt-head-center' },
						{ targets: 'projectManagerName',		data: 'projectManagerName',	className: 'projectManagerName dt-body-left dt-header-left' },
						{ 
							targets: 'startDate', 				
							data: 'startDate', 				
							className: 'startDate dt-body-center dt-head-center',
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
							data: 'endDate', 					
							className: 'endDate dt-body-center dt-head-center',
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
							targets: 'status',
							data: 'status',
							name: 'status',
							className: 'status dt-body-center dt-head-center' 
						},
						{ 
							targets: 'info', 						
							data: null, 						
							className: 'info dt-body-center dt-head-center', 
							defaultContent: '',
							render: function ( data, type, row ) {
								
								if ( !!row['generatedFrom'] ) {
								
									if ( row['generatedFrom'].trim() == 'scratch' ) {
										return '<span class="material-symbols-outlined" title="Generated from scratch by ' + row['generatedBy'] + ' ' + moment( row['generatedDateTime'] ).fromNow() + '">info</span>';
									} else if ( row['generatedFrom'].trim() == 'template' ) {
										return '<span class="material-symbols-outlined" title="Generated from template \'' + row['generatedFromTemplateName'] + '\' by ' + row['generatedBy'] + ' ' + moment( row['generatedDateTime'] ).fromNow() + '">info</span>';
									} else {
										return null;
									}

								} else {
									return null;
								}

							}
						},
						{
							targets: 'actions', 	
							data: null,			
							orderable: false, 
							searchable: false,
							className: 'actions dt-body-center dt-head-center',
							defaultContent: '',

							render: function (data, type, row) {
								// Default: disabled clone icon

								let cloneIcon;
								
								if ( row.taskCount > 0 ) {

									cloneIcon = ( !!row.isTemplatable )
										? '<i class="material-symbols-outlined clone" title="Create project template">file_copy</i>'
										: '<i class="material-symbols-outlined clone" title="Template may differ: this project or its tasks use non-workday dates">file_copy</i>'

								} else {
								
									cloneIcon = '<i class="material-symbols-outlined clone disabled" title="Cannot create template: project has no tasks">file_copy_off</i>';
									
								}
								

								const editIcon   = '<i class="material-symbols-outlined edit" title="Edit project">mode_edit</i>';

								const deleteIcon = '<i class="material-symbols-outlined delete" title="Delete project">delete_outline</i>';
								
								return cloneIcon + editIcon + deleteIcon;
							}


						},
						{ targets: 'projectManagerID', 		data: 'projectManagerID', 		className: 'dt-body-center dt-head-center', 	visible: false }
					],
					order: [[6, 'asc']],
					processing: true,
					searchCols: [
						null,
						null,
						null,
						null,
						null,
						null,
						null,
						null,
						{ search: '^(?!Complete).*$', regex: true },
						null,
					],
			});
			
			setHideCompleted( table, true );
			

			//------------------------------------------------------------------------------
			$( '#process' ).on( 'selectmenuselect', function() {
			//------------------------------------------------------------------------------

				$( '#nameFieldset' ).show();
				$( '#existingProjectsFieldset' ).show();
				$( '#projectManagerFieldset' ).show();

				if ( $( this ).val() == 'scratch' ) {
					$( '#scratch' ).show();
					$( '#template' ).hide();
					$( '.validateTips' ).text( 'Project name, start date, and end date are required.' );
					$( '#name' ).val( '' );
// 					alert( 'cNote now has dynamic project start and end dates. You can optionally set initial start and end dates now, and cNote will adjust them as you add tasks to the project.' );
					alert( 'While you have the option to set initial Project start/end dates, cNote will adjust these dates to match the earliest start and latest end date of associated tasks.' );
				} else {
					$( '#scratch' ).hide();
					$( '#template' ).show();
					$( '#name' ).val( $( this ).find( ':selected' ).text() );
				}

				$( '#name' ).focus();

				$( '#addDatesFieldset' ).show();

				$( '#dialog-form' ).dialog( 'option', 'position', { 
					my: 'center', 
					at: 'center', 
					of: $( window ) 
				});

		
			});
			//------------------------------------------------------------------------------

			
			//------------------------------------------------------------------------------
			$( '#anchorStart' ).on( 'click', function() { 
			//------------------------------------------------------------------------------

				$( '#anchorDateLabel' ).text( 'Start Date' );
				$( '#anchorDateLabel' ).show();
				$( '#anchorDate' ).show();

			});
			//------------------------------------------------------------------------------


			//------------------------------------------------------------------------------
			$( '#anchorEnd' ).on( 'click', function() {
			//------------------------------------------------------------------------------

				$( '#anchorDateLabel' ).text( 'End Date' );
				$( '#anchorDateLabel' ).show();
				$( '#anchorDate' ).show();

			});
			//------------------------------------------------------------------------------



		});
		//============================================================================
		//============================================================================
		//============================================================================
		//============================================================================

	
		
	</script>
	
	

	<style>
		
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
		
		i.disabled, i.unlinkable {
			color: lightgrey;
			cursor: default;
		}

		i.remove, i.block {
			color: crimson;
			cursur: default;
		}
				
		
		i.clone, i.delete, i.edit {
			visibility: hidden;
		}

		/* HIDE THE FILTER INPUT FIELD ON THE CHILD DATATABLES.... */
		div.child .dataTables_wrapper .dataTables_filter {
			visibility: hidden;
		}		

		table.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
		table th.projectName, 
		table td.projectName, 
		table th.taskName, 
		table td.taskName
		 {
			max-width: 400px; 
			min-width: 70px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; 
		}
		
		table th.kiName,
		table td.kiName
		 {
			max-width: 500px !important; 
			min-width: 90px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; 
		}
		
		table td span {
			cursor: default;
		}

		table.dataTable tbody td {
			height: 40px;
		}

				
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
		.overflow { height: 200px; }

.ui-datepicker, 
.ui-selectmenu-menu,
.select2-dropdown {
    z-index: 2000 !important;
}
		
		/* Style holiday dates: color red */
		.holiday a {
			background-color: red !important;
			color: white !important;
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
		<span class="mdl-layout-title">Customer View</span>
	</div>
	<main id="mainContent" class="mdl-layout__content">
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>

	<!-- Confirm DELETE Dialog -->
	<div id="dialog-confirm" title="Delete the project?" style="display: none;">
		<p><span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>The project will be permanently deleted and cannot be recovered. Are you sure?</p>
		<input type="hidden" name="id" id="id">
		<input type="hidden" name="customerID" id="customerID">
	</div>

	<!-- New Add/Edit Project Dialog -->
	<div id="dialog-form" title="Add/Edit Key Initiative" style="display: none;">
				
		<form action="" name="project">

			 <p class="validateTips">Select a process: define a project from scratch, or select a template from which a project will be generated.</p>
		
			<input type="hidden" name="id" id="id">
			<input type="hidden" name="customerID" id="customerID" value="<% =customerID %>">

			<div id="processFieldset">
				<label for="process">Process (project template)</label>
				<select id="process" name="process" class="select ui-widget-content ui-corner-all" style="width: 200px">
				</select>
			</div>
			
			<div id="nameFieldset">
				<label for="name">Name</label>
				<input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all">
			</div>

			
			<div id="projectManagerFieldset">
				<label for="projectManager">Project Manager</label>
				<select id="projectManager" name="projectManager" class="select ui-widget-content ui-corner-all">
					<option></option>
					<%
					SQL = "select u.id, concat(u.firstName, ' ', u.lastName) as fullName, '' as disabled " &_
							"from csuite..users u " &_
							"join csuite..clientUsers cu on (cu.userID = u.id and cu.clientID = " & session("clientNbr") & " ) " &_
							"join userCustomers uc on (uc.userID = u.id and uc.customerID = 1) " &_
							"UNION " &_
							"select distinct p.projectManagerID, concat(u.firstName, ' ', u.lastName) as fullName, 'disabled' as disabled " &_
							"from projects p " &_
							"join csuite..users u on (u.id = p.projectManagerID) " &_
							"where p.customerID = " & customerID & " " &_
							"and u.id not in ( " &_
								"select u.id " &_
								"from csuite..users u " &_
								"join csuite..clientUsers cu on (cu.userID = u.id and cu.clientID = " & session("clientNbr") & " ) " &_
								"join userCustomers uc on (uc.userID = u.id and uc.customerID = 1) " &_
							") " &_
							"order by fullName "
							
					dbug(SQL)
					set rsPM = dataconn.execute(SQL)
					while not rsPM.eof 
						response.write("<option value=""" & rsPM("id") & """" & rsPM("disabled") & ">" & rsPM("fullName") & "</option>")
						rsPM.movenext 
					wend
					rsPM.close
					set rsPM = nothing
					%>
				</select>
			</div>
			
			<div id="addDatesFieldset">
				<fieldset id="scratch" style="display: none; margin-top: 0px; margin-bottom: 12px;">
					<div>
						<span title="Start Date is now dynamic. You can optionally select a start date from the popup menu. As you add or delete tasks the start date will be adjusted automatically.">
							<label for="startDate">Start date</label>
							<input type="text" name="startDate" id="startDate" class="date ui-widget-content ui-corner-all" />
						</span>
						
						<span title="End Date is now dynamic. You can optionally select an end date from the popup menu. As you add or delete tasks the end date will be adjusted automatically.">
						<span>
							<label for="endDate">End date</label>
							<input type="text" name="endDate" id="endDate" class="date ui-widget-content ui-corner-all" />
						</span>
						
					</div>
				</fieldset>
				
				<fieldset id="template" style="display: none; margin-top: 0px; margin-bottom: 12px;">
	
					<label for="anchorStart">Start on</label>
				   <input type="radio" name="anchorStart" id="anchorStart" class="anchorDateType">
				    
					<label for="anchorEnd">Finish by</label>
				   <input type="radio" name="anchorEnd" id="anchorEnd" class="anchorDateType">
				    
					<label id="anchorDateLabel" for="anchorDate" style="display: none;"></label>
					<input type="text" name="anchorDate" id="anchorDate" class="date ui-widget-content ui-corner-all" style="display: none;" />
	
				</fieldset>
			</div>
			
			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
			
		</form>
		
	</div><!-- New Add/Edit Project Dialog -->
	
	
	<!-- new Create Template from project dialog -->
	<div id="dialog-template" title="Create Template" style="display: none;">
				
		<form action="" name="template">

			<p id="templateTips"></p>
		
			<fieldset>

				<label for="sourceProject">Source Project</label>
				<input id="sourceProject" name="sourceProject" class="text ui-widget-content ui-corner-all" style="margin-bottom: 0px;" disabled>
				<input type="hidden" id="sourceProjectID" />
				<div id="templateWarning" style="margin-bottom: 25px;">&nbsp;</div>
			
				<label for="targetTemplate">Target Template</label>
				<input id="targetTemplate" name="targetTemplate" class="text ui-widget-content ui-corner-all">
			
				<label for="existingTemplates">Existing Templates</label>
				<select id="existingTemplates" name="existingTemplates" size="7"></select>
				
				
				<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">

			</fieldset>
				
		</form>
		
	</div>
	
	
	
			
	





	
		<div class="page-content">
			<!-- Your content goes here -->
	
			<!-- DIALOG: Clone A Project -->
			<dialog id="dialog_cloneProject" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Project Template</h4>
				<div class="mdl-dialog__content">

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="clone_sourceProjectName" name="clone_sourceProjectName" value="" disabled> 
						    <label class="mdl-textfield__label" for="clone_sourceProjectName">Source project...</label>
						</div>

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="clone_projectName" name="clone_projectName" value="" required autocomplete="off"> 
						    <label class="mdl-textfield__label" for="clone_projectName">Target template...</label>
						</div>


						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="clone_projectNameSelect" onchange="TemplateNameSelect_onChange(this)" size="5">
								<%
								SQL = "select id, name " &_
										"from projectTemplates " &_
										"order by name "
								dbug(SQL)
								set rsPT = dataconn.execute(SQL)
								while not rsPT.eof 
									response.write("<option value=""" & rsPT("id") & """>" & rsPT("name") & "</option>")
									rsPT.movenext 
								wend
								rsPT.close
								set rsPT = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="clone_projectNameSelect">Existing project templates...</label>
						</div>

						<input type="hidden" id="clone_sourceProjectID" name="clone_sourceProjectID">

				</div>

				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>

			</dialog><!-- DIALOG: Clone A Project -->
	
							
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--5-col" align="left">
					<% if userPermitted(68) then %>
						<button id="button_newProject" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
						  New Project
						</button>
					<% end if %>
				</div>

				<div class="mdl-cell mdl-cell--4-col" align="right">
					<button id="searchButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
					  Show All Projects
					</button>
					<% if userPermitted(71) then %>
						<a href="customerProjectsSendDetails.asp?customerID=<% =customerID %>" title="Printer friendly version of open project/task details"><i class="material-symbols-outlined" style="vertical-align: middle;">print</i></a>
					<% end if %>
				</div>

				<div class="mdl-layout-spacer"></div>
			</div>
				
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--9-col">
	
	
					<table id="tbl_projects" class="compact display">
						<thead>
							<tr>
								<th></th>
								<th class="projectName">Project Name</th>
								<th class="kiCount"># KI's</th>
								<th class="projectManagerName">Proj Mgr</th>
								<th class="startDate">Start</th>
								<th class="endDate">End</th>
								<th class="status">Status</th>
								<th class="info"><i class="material-symbols-outlined">info</i></th>
								<% if userPermitted(69) or userPermitted(70) then %>
									<th class="actions">Actions</th>
								<% end if %>
								<th class="projectManagerID">Proj Mgr ID</th>
							</tr>
						</thead>
					</table>
	
	
				</div>
				<div class="mdl-layout-spacer"></div>
			</div><!-- primary grid of tasks and associated KIs -->
		</div>
		


	</main>
	
	<!-- #include file="includes/pageFooter.asp" -->
	
</div>

<script src="dialog-polyfill.js"></script>  
<script>	

//****************************************************************************************/
// add/edit Projects
//****************************************************************************************/
//

/* 	var dialog_addProject 					= document.querySelector('#dialog_addProject'); */
	var dialog_cloneProject 				= document.querySelector('#dialog_cloneProject');	
	var dialog_addProjectFromTemplate 	= document.querySelector('#dialog_addProjectFromTemplate');

/* 	var button_newProject					= document.querySelector('#button_newProject');	 */
	var editMode;

	// register all dialogs
/*
	if (! dialog_addProject.showModal) {
		dialogPolyfill.registerDialog(dialog_addProject);
	}	
*/
	if (! dialog_cloneProject.showModal) {
		dialogPolyfill.registerDialog(dialog_cloneProject);
	}	


/*
	// add event listener for project start date...
	var add_projectStartDate = dialog_addProject.querySelector('#add_projectStartDate');
	if (add_projectStartDate) {
		add_projectStartDate.addEventListener('blur', function(event) {
			event.stopPropagation();
			ProjectStartDate_onBlur(this);
		});
	}
	

	// add event listener for project end date....
	var add_projectEndDate = dialog_addProject.querySelector('#add_projectEndDate');
	if (add_projectEndDate) {
		add_projectEndDate.addEventListener('blur', function(event) {
			event.stopPropagation();
			ProjectEndDate_onBlur(this);			
		});
	}
*/







	// event listener for click on  "New Project" button...
/*
	if (button_newProject) {

		button_newProject.addEventListener('click', function() {
	
			dialog_addProject.showModal();
	
			document.getElementById('newProjectTitle').innerHTML = 'New Project';
	
			var add_projectProductElem = document.getElementById('add_projectProduct');
			add_projectProductElem.parentNode.style.display = 'inline-block';
			add_projectProductElem.parentNode.classList.remove('is-invalid');
// 			add_projectProductElem.parentNode.classList.add('is-dirtly');
			
			var add_projectNameElem = document.getElementById('add_projectName');
			add_projectNameElem.value = '';
			add_projectNameElem.parentNode.classList.remove('is-invalid');
// 			add_projectNameElem.parentNode.classList.add('is-dirty');
	
			var add_projectManagerElem = document.getElementById('add_projectManager');
			add_projectManagerElem.options.selectedIndex = 0;
			add_projectManagerElem.parentNode.classList.remove('is-invalid');
// 			add_projectManagerElem.parentNode.classList.add('is-dirty');
	
			var add_projectStartDateElem = document.getElementById('add_projectStartDate');
			add_projectStartDateElem.value = '';
			add_projectStartDateElem.parentNode.classList.remove('is-invalid');
			add_projectStartDateElem.parentNode.style.display = 'none';
// 			add_projectStartDateElem.parentNode.classList.add('is-dirty');
	
			var add_projectEndDateElem = document.getElementById('add_projectEndDate');
			add_projectEndDateElem.value = '';
			add_projectEndDateElem.parentNode.classList.remove('is-invalid');
			add_projectEndDateElem.parentNode.style.display = 'none';
// 			add_projectEndDateElem.parentNode.classList.add('is-dirty');

			
	// 		document.getElementById('add_projectCompleteDate').parentNode.style.display = 'none';
	
			document.getElementById('existingProjects').parentNode.classList.add('is-dirty');
	
		});

	}
*/

// 	// event listeners for concel/save on dialog_addProject
// 	dialog_addProject.querySelector('.cancel').addEventListener('click', function() {
// 		editMode = '';
// 		dialog_addProject.close();
// 	});
// 	dialog_addProject.querySelector('.save').addEventListener('click', function() {
// 		editMode = '';
// 		if (AddProject_onSave(dialog_addProject)) {
// 			dialog_addProject.close();
// 		}
// 	});


	// event listeners for concel/save on dialog_cloneProject (create a template from a project)
	dialog_cloneProject.querySelector('.cancel').addEventListener('click', function() {
		editMode = '';
		dialog_cloneProject.close();
	});
	dialog_cloneProject.querySelector('.save').addEventListener('click', function() {
		CreateTemplate_onSave(dialog_cloneProject)
		dialog_cloneProject.close();
	});



</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>