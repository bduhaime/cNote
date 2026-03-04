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
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/jsonDataArray.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeByCustomer.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(50)

customerID 	= request.querystring("id")

targetKI		= request.querystring("ki")
if len(targetKI) <= 0 then
	targetKI = "null"
end if

kiFilter 	= lCase(request.querystring("kiFilter"))
dbug("initial kiFilter: " & kiFilter)
if ( kiFilter = "all" ) then 
	initFilter 			= "^$"
	initPageLength		= 5
	initButtonText 	= "Show All Key Initiatives"
else
	initFilter 			= ""
	initPageLength		= -1
	initButtonText 	= "Hide Complete Key Initiatives"
end if 

dbug("initFilters: " 	& initFilter)
dbug("initPageLength" 	& initPageLength) 
dbug("initButtonText: " & initButtonText)

%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customer key initiatives")

ki = request.querystring("ki") ' if present this Key Initiative should be "open" for the user to see


'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

dbug("before top-logic")

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


	<script src="customerKeyInitiatives.js"></script>

	<script>

		// this little script automatically refreshes this page if the user navigates here using the browser's back arrow		
		if(!!window.performance && window.performance.navigation.type == 2) {
			window.location.reload();
		}
		
		const customerID		= <% =customerID %>
		const targetKI 		= '<% =targetKI %>';
		const initPageLength	= <% =initPageLength %>;
		const initFilter 		= '<% =initFilter %>';

		console.log('initFilter before ready(): ' + initFilter);
		
		

		function ShowDetails_onClick( htmlElement, table ) {
			
			var tr 				= $( htmlElement );
			var row 				= table.row( tr );
			var customerID 	= row.data().customerID;
			var ki 				= row.data().DT_RowId;
			var description 	= row.data().description;
			
			if ( row.child.isShown() ) {
				return true;
			} 
			
			row.child( 
				'<div class="child">'
					+	'<table style="width: 100%;"><tr>'
						+	'<td style="width: 70%; vertical-align: top;"><b>' + description + '</b></td>'
						+	'<td style="vertical-align: bottom; text-align: right;">'
							+	'<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent showProjects" data-ki="'+ki+'">'
								+ 	'show all projects'
							+	'</button>'
						+	'</td>'
					+	'</tr></table>'
            	+	'<table class="childProjects compact display" id="projectsForKI_' + ki + '"><thead><tr>'
            		+	'<th>Projects</th>'
            		+	'<th>Start</th>'
            		+	'<th>End</th>'
            		+	'<th>Manager</th>'
            		+	'<th>Status Date</th>'
            		+	'<th>Status</th>'
            		+	'<th></th>'
            	+ 	'</tr></thead><tbody></tbody></table>'
					+	'<br><br>'
					+	'<table style="width: 100%;"><tr>'
						+	'<td style="vertical-align: bottom; text-align: right; width: 100%;">'
							+	'<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent showTasks" data-ki="'+ki+'">'
								+ 	'show all tasks'
							+	'</button>'
						+	'</td>'
					+	'</tr></table>'
            	+	'<table class="childTasks compact display" id = "tasksForKI_' + ki + '"><thead><tr>'
            		+	'<th class="taskName">Tasks</th>'
            		+	'<th>Start</th>'
            		+	'<th>Due</th>'
            		+	'<th>Complete</th>'
            		+	'<th>Owner</th>'
            		+	'<th></th>'
            	+ 	'</tr></thead><tbody></tbody></table>'
         	+	'</div>'
            ).show();

			var projectTable = $('#projectsForKI_'+ki)
				.on( 'click', 'tbody tr', function() {

					projectID = this.id;
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
					const keyInitiativeID = projectWrapperID.substring(projectWrapperID.indexOf('_')+1, projectWrapperID.lastIndexOf('_'));
					
					const button = this.querySelector('i');
					
					if ( button.classList.contains('add') ) {
						AddProjectKeyInitiative(keyInitiativeID, projectID);
					} else if ( button.classList.contains('remove') ) { 
						RemoveProjectKeyInitiative(keyInitiativeID, projectID);
					}

					$( '.ui-tooltip-content' ).parents( 'div' ).remove();
					
					console.log('prior to reload()');
					var tempTable = $('#projectsForKI_'+keyInitiativeID).DataTable();
					tempTable.ajax.reload( null, false );
					console.log('after reload()');
					
				})
				.DataTable({
					paging: true,
					lengthMenu: [[5,10,15,-1],[5,10,15,'All']],
					info: true,
					searching: true,
					processing: false,
					serverSide: false,
					ajax: {
						url: '/ajax/projects.asp?customerID='+customerID+'&ki='+ki
					},
					columns: [
						{targets: 'projectName', 							data: 'projectName', 			className: 'dt-body-left'},
						{targets: 'startDate', 			width: '50px', data: 'startDate', 				className: 'dt-body-center'},
						{targets: 'endDate', 			width: '50px', data: 'endDate', 					className: 'dt-body-center'},
						{targets: 'projectManagerName', 					data: 'projectManagerName', 											visible: false},
						{targets: 'statusDate', 		width: '50px', data: 'statusDate', 				className: 'dt-body-center', 	visible: false},
						{targets: 'status', 									data: 'status', 					className: 'dt-body-center'},
						{
							targets: 'actions', 	
							width: '24px', 
							orderable: true, 
							className: 'link dt-body-center', 
							data: function( row, type, val, meta ) {
								var iconName;
								if ( row.relatability == 'linked') {
									iconName 	= 'remove_circle_outline';
									className 	= 'remove linked';
									title 		= 'Click to remove project from key initiatibe';
								} else if ( row.relatability == 'true' ) {
									iconName 	= 'add_circle_outline';
									className 	= 'add linkable';
									title 		= 'Click to add project to key initiative';
								} else {
									iconName 	= 'block';
									className 	= 'unlinkable disabled';
									title			= row.relatabilityInfo;
								}	
								return '<i class="material-icons '+className+'" title="'+title+'">'+iconName+'</i>';
							}		
						},
						{targets: 'relatability', 		data: 'relatability', 		visible: false, searchable: true},
						{targets: 'relatabilityInfo', data: 'relatabilityInfo', 	visible: false, searchable: false},
						{targets: 'taskID',				data: 'taskID',	visible: false},
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
				
				
			var taskTable = $('#tasksForKI_'+ki)
				.on( 'click', 'tbody tr', function() {

					taskID = this.id;
					
					if ( taskID ) {
						window.location.href = 'taskDetail.asp?customerID=<% =customerID %>&taskID='+taskID;
					}

				})
				.on( 'click', 'td.link', function (event) {
				
					event.preventDefault();
					event.stopPropagation();
				
					const taskID = this.closest('tr').id;
					const customerID = <% =customerID %>;
					const projectTable = this.closest('table');
					const projectWrapper = projectTable.closest('div');
					const projectWrapperID = projectWrapper.id;
					const keyInitiativeID = projectWrapperID.substring(projectWrapperID.indexOf('_')+1, projectWrapperID.lastIndexOf('_'));

					const button = this.querySelector('i');
					
					if ( button.classList.contains('add') ) {
						AddTaskKeyInitiative(keyInitiativeID, taskID);
					} else if ( button.classList.contains('remove') ) { 
						RemoveTaskKeyInitiative(keyInitiativeID, taskID);
					}

					$( '.ui-tooltip-content' ).parents( 'div' ).remove();
					
					console.log('prior to tasks reload()');										
					var tempTable = $('#tasksForKI_'+keyInitiativeID).DataTable();
					tempTable.ajax.reload( null, false );
					console.log('after tasks reload()');										
					
				})
				.DataTable({
					paging: true,
					lengthMenu: [[5,10,15,-1],[5,10,15,'All']],
					info: true,
					searching: true,
					processing: false,
					serverSide: false,
					ajax: {
						url: '/ajax/tasks.asp?customerID=' + customerID +'&ki='+ ki
					},
					columns: [
						{targets: 'taskName', 		data: 'taskName', 		className: 'taskName dt-body-left'},
						{targets: 'startDate', 		data: 'startDate', 		className: 'dt-body-center'},
						{targets: 'dueDate', 		data: 'dueDate', 			className: 'dt-body-center'},
						{targets: 'completeDate', 	data: 'completeDate', 	className: 'dt-body-center'},
						{targets: 'ownerName', 		data: 'ownerName', 		className: 'dt-body-left'},
						{
							targets: 'actions', 	
							width: '24px', 
							orderable: true, 
							className: 'link dt-body-center ', 
							data: function( row, type, val, meta ) {
								var iconName;
								if ( row.relatability == 'linked') {
									iconName 	= 'remove_circle_outline';
									className 	= 'remove linked';
									title 		= 'Click to remove task from key initiative';
								} else if ( row.relatability == 'true' ) {
									iconName 	= 'add_circle_outline';
									className 	= 'add linkable';
									title 		= 'Click to add task to key initiative';
								} else {
									iconName 	= 'block';
									className 	= 'unlinkable disabled';
									title 		= row.relatabilityInfo;
								}	
								return '<i class="material-icons '+className+'" title="'+title+'">'+iconName+'</i>';
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
						null,
						{ search: 'remove_circle_outline' },
						null,
					]
				});
			tr.addClass('shown');
			
		}


		$( document ).ready( function() {

			$.fn.dataTable.moment( 'M/D/YYYY' );

			$( document ).tooltip();
			
			
			var searchButton = document.getElementById('searchButton');
			if ( searchButton ) {
				searchButton.addEventListener( 'click', function() {
					var currentLabel = this.textContent;
					var table = $( '#tbl_keyInitiatives' ).DataTable();
					if ( currentLabel.trim() == 'Show All Key Initiatives' ) {
						table.column( 4 ).search( '' ).draw();
						searchButton.textContent = 'Hide Complete Key Initiatives';
					} else {
						table.column( 4 ).search( '^$', true, false ).draw();
						searchButton.textContent = 'Show All Key Initiatives';
					}
				});				
			}
			
 
			dialog = $( "#dialog-form" ).dialog({
				autoOpen: false,
// 				height: 400,
				width: 500,
				modal: true,
				buttons: {
					"Save": async function() {
						
						var formValid = AddKeyInitiative_OnSave( dialog );
						formValid.then( function( result ) {
							if ( result ) {
								$( '.ui-state-error' ).removeClass( 'ui-state-error' );
								$( 'input' ).val( '' );	
								$( 'textarea' ).val( '' );	
								$( '#startDate' ).datepicker( 'option', 'maxDate', null );
								$( '#endDate' ).datepicker( 'option', 'minDate', null );
								$( this ).dialog( 'close' );
							}
						})
					},
					Cancel: function() {
						$( '.ui-state-error' ).removeClass( 'ui-state-error' );
						$( 'input' ).val( '' );
						$( 'textarea' ).val( '' );	
						$( '#startDate' ).datepicker( 'option', 'maxDate', null );
						$( '#endDate' ).datepicker( 'option', 'minDate', null );
						$( this ).dialog( 'close' );
					}
				},
				close: function() {
					$( '.ui-state-error' ).removeClass( 'ui-state-error' );
					$( 'input' ).val( '' );					
					$( 'textarea' ).val( '' );	
					$( '#startDate' ).datepicker( 'option', 'maxDate', null );
					$( '#endDate' ).datepicker( 'option', 'minDate', null );
					$( this ).dialog( 'close' );
				}
			});
			
			
			$( '#button_newKeyInitiative' ).on( 'click', function( event ) {
				$( '#dialog-form' ).dialog( {
					title: 'Add Key Initiative'
				} );
				$( '#customerID' ).val( customerID );
				$( '#dialog-form' ).dialog( 'open' );
			});
			

			var dateFormat = 'mm/dd/yy',
				startDate = $( '#startDate' )
					.datepicker({
						defaultDate: '+1w',
						changeMonth: true,
						changeYear: true,
					})
					.on( 'change', function() {
						endDate.datepicker( 'option', 'minDate', getDate( this ) );
					}),
				
				endDate = $( '#endDate' )
					.datepicker({
						defaultDate: '+1w',
						changeMonth: true,
						changeYear: true,
					})
					.on( 'change', function() {
						startDate.datepicker( 'option', 'maxDate', getDate( this ) );
					}),
				
				completeDate = $( '#completeDate' ).datepicker();
				
					
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
		        "Delete KI": function() {
						DeleteKI( this );
						$( '.ui-tooltip-content' ).parents( 'div' ).remove()
		        },
		        Cancel: function() {
		          $( this ).dialog( "close" );
		        }
		      }
		    });			


			var table = $('#tbl_keyInitiatives')
				.on( 'click', 		'td.details-control', function() {
					
					const htmlRow = this.closest( 'TR' );
					if ( table.row( this ).child.isShown() ) {

						table.row( this ).child.hide();
						$( htmlRow ).removeClass( 'shown' );
					
					} else {
						
						ShowDetails_onClick( htmlRow, table );
						
					}
					
				
				})
				.on( 'click', 		'button.showProjects', function() {
					
					const ki 						= this.getAttribute( 'data-ki' );
					const childProjectsTable 	= $( '#projectsForKI_'+ki ).DataTable();
					const currSearch 				= childProjectsTable.column( 6 ).search();

					if (currSearch == 'remove_circle_outline') {
						this.textContent = 'Show Linked Projects';
						childProjectsTable.column( 6 ).search( '' ).draw();
					} else {
						this.textContent = 'Show All Projects';
						childProjectsTable.column( 6 ).search( 'remove_circle_outline' ).draw();
					}


				})
				.on( 'click', 		'button.showTasks', function() {
					
					const ki 						= this.getAttribute( 'data-ki' );
					const childTasksTable 		= $( '#tasksForKI_'+ki ).DataTable();
					const currSearch 				= childTasksTable.column( 5 ).search();

					if (currSearch == 'remove_circle_outline') {
						this.textContent = 'Show Linked Tasks';
						childTasksTable.column( 5 ).search( '' ).draw();
					} else {
						this.textContent = 'Show All Tasks';
						childTasksTable.column( 5 ).search( 'remove_circle_outline' ).draw();
					}


				})
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons(this);
				})
				.on( 'mouseout', 	'tbody tr', function() {
					ToggleActionIcons(this);
				})
				.on( 'click', 		'i.delete', function( event ) {
					kiDelete_OnClick( this );
				})
				.on( 'click', 		'i.edit', function( event ) {

					const row 	= $( this ).closest('TR');
					const data 	= $( '#tbl_keyInitiatives' ).DataTable().row( row ).data();
					
					$( '#id' ) 				.val( data[ 'DT_RowId' ] );
					$( '#customerID' )	.val( customerID );
					
					$( '#name' )			.val( data[ 'kiName' ]
													.replace( /&quot;/gi, '\"' )
													.replace( /&trade;/gi, '\u2122' ) 
													.replace( /\(tm\)/gi, '\u2122') 
													.replace( /â„¢/gi, '\u2122') 
													.replace( /<br>/gi, '\n') 
												);
	
					$( '#description' )	.val( data[ 'description' ]
													.replace( /&quot;/gi, '\"' )
													.replace( /&trade;/gi, '\u2122') 
													.replace( /\(tm\)/gi, '\u2122') 
													.replace( /<br>/gi, '\n') 
												);
	
					$( '#startDate' )		.val( data[ 'startDate' ] );
					$( '#startDate' )		.datepicker( 'option', 'maxDate', data[ 'dueDate' ] )
	
					$( '#endDate' )		.val( data[ 'dueDate' ] );
					$( '#endDate' )		.datepicker( 'option', 'minDate', data[ 'startDate' ] )
	
	
					$( '#completeDate' )	.val( data[ 'completeDate' ]  );
					if ( data[ 'completeDate' ] ) {
						
						if ( data[ 'kiUncompletable' ] === 'True' ) {
							$( '#completeDate' ).prop( 'disabled', false );
						} else {
							$( '#completeDate' ).prop( 'disabled', true );
						}
					
					} else {
						
						if ( data[ 'kiCompletable' ] === 'True' ) {
							$( '#completeDate' ).prop( 'disabled', false );						
						} else {
							$( '#completeDate' ).prop( 'disabled', true );
						}
	
					}
						
					$( '#dialog-form' ).dialog( {
						title: 'Edit Key Initiative'
					} );
	
					$( '#dialog-form' ).dialog( 'open' );
	
				})
				.on( 'init.dt', function() {
					
					table.rows().every( function( rowIdx, tableLoop, rowLoop ) {
						
						if ( this.data().DT_RowId == targetKI ) {

							ShowDetails_onClick( this, table );
														
						}
						
						
					});
 
				})
				.DataTable({

					ajax: {
						url: '/ajax/keyInitiatives.asp?customerID='+customerID
					},

					pageLength: initPageLength,
					deferRender: true,
					
					columns: [
						{
							className: 'details-control dt-body-center',
							orderable: false,
							data: null,
							defaultContent: ''
						},
						{targets: 'name', 				data: 'kiName', 				className: 'name dt-body-left dt-head-left', 	width: '40%'},
						{targets: 'startDate', 			data: 'startDate', 			className: 'startDate dt-body-center dt-head-center'},
						{targets: 'dueDate', 			data: 'dueDate', 				className: 'dueDate dt-body-center dt-head-center'},
						{targets: 'completeDate', 		data: 'completeDate', 		className: 'completeDate dt-body-center dt-head-center'},
						{
							targets: 'actions', 	
							data: null,			
							orderable: false, 
							className: 'actions dt-body-center dt-head-center',
							defaultContent: '',
							render: function() {
								return '<i class="material-icons edit" title="Edit Key Initiative">edit</i><i class="material-icons delete" title="Delete Key Initiative">delete_outline</i>';
							}
						},
						{targets: 'customerID', 		data: 'customerID', 			className: 'customerID',							visible: false},
						{targets: 'description', 		data: 'description', 		className: 'description',							visible: false},
						{targets: 'kiCompletable', 	data: 'kiCompletable', 		className: 'kiCompletable dt-body-center',	visible: false},
						{targets: 'kiUncompletable', 	data: 'kiUncompletable', 	className: 'kiUncompletable dt-body-center',	visible: false},
					],
					order: [[2, 'desc']],

					searchCols: [
						null,
						null,
						null,
						null,
						{ search: initFilter, regex: true },
						null,
					]
			});

			
		});



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
				
		/* HIDE THE FILTER INPUT FIELD ON THE CHILD DATATABLES.... */
		div.child .dataTables_wrapper .dataTables_filter {
			visibility: hidden;
		}		
		
		table.childProjects tbody tr:hover {
			cursor: pointer;			
		}

		table.childTasks tbody tr:hover {
			cursor: pointer;			
		}

		table th.name, table td.name {
			max-width: 300px; 
			min-width: 70px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; }
		}

/*
		table th.projectName, table td.projectName, table th.taskName, table td.taskName {
			max-width: 400px; 
			min-width: 70px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; 
		}		
				
*/
		
		table.dataTable td.actions {
			cursor: pointer;
			visibility: hidden;
		}

		i.delete, i.edit {
			cursor: pointer;
			visibility: hidden;
		}

	 label, input, textarea { display:block; }
	 span { display: inline-block }
	 input.text, textarea { margin-bottom:12px; width:95%; padding: .4em; }
	 input.date { margin-bottom:12px; width:100px; padding: .4em; margin-right: 12px; }
	 fieldset { padding:0; border:0; margin-top:25px; }
	 h1 { font-size: 1.2em; margin: .6em 0; }
	 				
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
		<span class="mdl-layout-title">Customer Key Initiatives</span>
	</div><!-- drawer -->

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div><!-- snackbar -->


	<!-- Confirm DELETE Dialog -->
	<div id="dialog-confirm" title="Delete the key initiative?" style="display: none;">
		<p><span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>The key initiative will be permanently deleted and cannot be recovered. Are you sure?</p>
		<input type="hidden" name="id" id="id">
		<input type="hidden" name="customerID" id="customerID">
	</div>
	
	<!-- New Add/Edit KI Dialog -->
	<div id="dialog-form" title="Add/Edit Key Initiative" style="display: none;">
				
		<form id="formKI" action="#" method="get" name="formKI">
			 <p class="validateTips">Name, start date, and end date are required.</p>
			
			<fieldset>
				
				<input type="hidden" name="id" id="id" />
				<input type="hidden" name="customerID" id="customerID" value="<% =customerID %>" />

				<label for="name">Name</label>
				<input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all"  />
				
				<label for="description">Description</label>
				<textarea name="description" id="description" class="text ui-widget-content ui-corner-all" rows="5"></textarea>
<!-- 				<input type="text" name="description" id="description" class="text ui-widget-content ui-corner-all"> -->
				

				<div>
					<span>
						<label for="startDate">Start date</label>
						<input type="text" name="startDate" id="startDate" class="date ui-widget-content ui-corner-all" />
					</span>
					
					<span>
						<label for="endDate">End date</label>
						<input type="text" name="endDate" id="endDate" class="date ui-widget-content ui-corner-all" />
					</span>
					
					<span>
						<label for="completeDate">Complete date</label>
						<input type="text" name="completeDate" id="completeDate" class="date ui-widget-content ui-corner-all" />
					</span>

				</div>
				
				
				
				<!-- Allow form submission with keyboard without duplicating the dialog button -->
				<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
			
			</fieldset>
			
		</form>
		
	</div><!-- New Add/Edit KI Dialog -->

	<div class="page-content">


		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--8-col" align="left">
				<% if userPermitted(65) then %>
					<button id="button_newKeyInitiative" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
						New Key Initiative
					</button>
				<% end if %>

				<div style="float: right; display: inline-block; margin-bottom: 15px;">
					<button id="searchButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
						<% =initButtonText %>
					</button>					
				</div>

			</div><!-- New KI & Hide/Show Buttons -->

			<div class="mdl-layout-spacer"></div>

		</div>


		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
			
			<div class="mdl-cell mdl-cell--8-col">
				
				<table id="tbl_keyInitiatives" class="compact display" data-targetKI="<% =targetKI %>">
					<thead>
						<tr>
							<th></th>
							<th class="name">Key Initiative Name</th>
							<th class="startDate">Start</th>
							<th class="dueDate">Due</th>
							<th class="completeDate">Complete</th>
<!-- 							<% if (userPermitted(66) OR userPermitted (67)) then %> -->
								<th class="actions">Actions</th>
<!-- 							<% end if %> -->
							<th class="customerID"></th>
							<th class="description"></th>
							<th class="kiCompletable">Completable?</th>
							<th class="kiUncompletable">Uncompletable?</th>
						</tr>
					</thead>
				</table>		    			    
							
			</div>
			
			<div class="mdl-layout-spacer"></div>
			
		</div><!-- end grid -->
		
	</div>
		


	</main>

	<!-- #include file="includes/pageFooter.asp" -->

</div>


<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>