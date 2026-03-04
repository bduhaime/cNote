<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% ' response.buffer = true %>
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="includes/userHasPermission.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/jsonDataArray.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeByCustomer.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(53)

customerID = request.querystring("id")
%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customer managers")
templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")



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

chartHeight = 200
 

'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

%>


<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<!-- DataTables Editor -->
	<script type="text/javascript" src="Editor-2.5.1/js/dataTables.editor.js"></script>
	<script type="text/javascript" src="Editor-2.5.1/js/editor.jqueryui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="Editor-2.5.1/css/editor.dataTables.css">


	<!-- 	Moment JS ( must be loaded prior to jQuery, DataTables, and Editor ) -->
	<script type="text/javascript" src="moment.min.js"></script>


	<!-- 	Google Visualizations -->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>


	<script type="text/javascript">

		const customerID		= <% =customerID %>;
		var chart;


		google.charts.load('current', {'packages':['timeline']});

		google.charts.setOnLoadCallback(drawCharts);
		
		
		//================================================================================================ 
		function snackBarNotification( messagge ) {
		//================================================================================================ 

			const  notification 		= document.querySelector('.mdl-js-snackbar');
			
			notification.MaterialSnackbar.showSnackbar({ message: messagge });

		}
		//================================================================================================ 


		//================================================================================================ 
		function buildChart_customerManagerTimeLine() {
		//================================================================================================ 

			$.ajax({
				beforeSend: function() {
					$( '#customerManagersTimeline_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/customerManagers/timeline`,
				data: { customerID: customerID },
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				success: function( data ) {
					let dataTable = new google.visualization.DataTable( data );
					
					let dataView = new google.visualization.DataView(dataTable);
					dataView.setColumns([ 1, 3, 6, 4, 5 ]);

					// calculate chart height...
					rowHeight = 20;
					chartExtra = 35;
					let rowCount = dataTable.getNumberOfRows();
					let chartHeight = ( rowCount * rowHeight ) + chartExtra; 

					let chart = new google.visualization.Timeline(document.getElementById( 'customerManagersTimeline' ));
					chart.draw( dataView, {
						height: 500,
						tooltip: { isHtml: true }
						
					 });

					chart = new google.visualization.ChartWrapper({
						chartType: 'Timeline',
						containerId: 'customerManagersTimeline',
						dataTable: dataTable,
						options: {
							height: 500,
							tooltip: { isHtml: true }
						},
						view: { columns: [ 1, 3, 6, 4, 5 ] },
					});
					chart.draw();
					

					$( '#customerManagersTimeline_progressbar' ).progressbar('destroy');


					google.visualization.events.addListener(chart, 'select', function() {
						
						let selectedItem = chart.getChart().getSelection()[0];
						let selectedRow = selectedItem.row;
						let selectedRowID = chart.getDataTable().getValue( selectedRow, 0 );

						let rowID = '#row_'+selectedRowID;
						console.log( 'rowID: ' + rowID );

						let jqDataTable = $('#customerManagers').DataTable();
						jqDataTable.rows().deselect();
						jqDataTable.row( rowID ).select().scrollTo();
		
					});

					
				}
				
			});	// end of Project Manager Timeline Chart
			
			

		}
		//================================================================================================ 
		
		
		
		//================================================================================================ 
		function drawCharts() {
		//================================================================================================ 


/* 			(function($){ */
	
			
					$(document).ready(function() {
			
						buildChart_customerManagerTimeLine();
			
						$( document ).tooltip();
			
			
						$.fn.dataTable.Editor.display.jqueryui.modalOptions = {
							width: 700,
							modal: true
						}

						var editor = new $.fn.dataTable.Editor( {
							ajax: {
								url: `${apiServer}/api/customerManagers`,
								headers: { 'Authorization': 'Bearer ' + sessionJWT }
							},
							formOptions: {
								main: {
									onEsc: 'none'
								}
							},
							table: '#customerManagers',
							display: 'jqueryui',
							fields: [
								{ label: 'Customer ID:', 			name: 'customerID', 		type: 'hidden', 	def: customerID },
								{ label: 'User ID:', 				name: 'userID',			type: 'select' },
								{ label: 'Manager Type ID:', 		name: 'managerTypeID',	type: 'select' },
								{ label: 'Start Date:', 			name: 'startDate',		type: 'datetime' },
								{ label: 'End Date:', 				name: 'endDate',			type: 'datetime' },
							]
						}).on( 'edit', function() {
							snackBarNotification( 'Manager updated' );
							buildChart_customerManagerTimeLine();
						}).on( 'create', function() {
							snackBarNotification( 'Manager added' );
							buildChart_customerManagerTimeLine();
						}).on( 'remove', function() {
							snackBarNotification( 'Manager deleted' );
							buildChart_customerManagerTimeLine();
						});
		
		
						// build managers <select> options and add it to the editor...
						var managerNameOptions = [];

						$.ajax({ 
							url: `${apiServer}/api/customerManagers/selectList`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
						}).done( function( data ) {
		
							data.forEach( manager => {
								let label = manager.fullName + ', ' + manager.username ;
								if ( !manager.active ) label += ' - (Inactive)';
	
								managerNameOptions.push({
									label: label,
									value: manager.id 
								});
	
							});
							
							editor.field( "userID" ).update( managerNameOptions );
		
						}).fail( function( err ) {
							console.error( 'failed getting manager name options for table editor' );
							throw new Error( err );							
						});

		
						// build managerType <select> options and add it to the editor...
						var managerTypeOptions = [];


						$.ajax({
							url: `${apiServer}/api/customerManagers/managerTypes`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
						}).done( function( data ) {
		
							data.forEach( managerType => {
	
								managerTypeOptions.push({
									label: managerType.name,
									value: managerType.id 
								});
	
							});
							
							editor.field( "managerTypeID" ).update( managerTypeOptions );
		
						}).fail( function( err ) {
							
							console.error( 'failed getting manager type' );
							throw new Error( err );
		
						});

		
			
						var table = $('#customerManagers').DataTable( {
							dom: 'Bfrtip',
							buttons: [
								{ extend: 'create', editor: editor },
								{ extend: 'edit',   editor: editor },
								{ extend: 'remove', editor: editor }
							],
							ajax: {
								url: `${apiServer}/api/customerManagers`,
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								data: { customerID: customerID }
							},

							createdRow: function (row, data, rowIndex) {

								$.each( $( 'td', row ), function ( colIndex ) {
									if( $( this ).hasClass( 'managerName' ) ) {
										$( this ).attr( 'title', 'Username: ' + data.username );
									}
								});
							},

							columns: [
								{ data: 'customerID', 				className: 'customerID', 		visible: false },
								{ data: 'userID',						className: 'userID', 			visible: false },
								{ data: 'username',					className: 'userName', 			visible: false },
								{ data: 'managerName',				className: 'managerName dt-body-left  dt-head-left' },
								{ 
									data: 'active',
									className: 'active dt-body-center dt-head-center',
									render: function(data, type, row) {
										if ( data ) {
											return '<input type="checkbox" checked disabled>';
										} else {
											return '<input type="checkbox" disabled>';
										}
										return data;
									},
									
								},
								{ data: 'managerTypeID', 			className: 'managerTypeID', 	visible: false },
								{ data: 'managerTypeName',			className: 'managertTypeName dt-body-left  dt-head-left',  },
								{ data: 'startDate',					className: 'startDate dt-body-center dt-head-center' },
								{ data: 'endDate',					className: 'endDate dt-body-center dt-head-center' },
							],
							info: false,
							searching: false,
							select: true,
							scrollY: 200,
							scroller: true,
							scrollCollapse: true,
							lengthChange: false,
							order: [
								[ 5, 'asc' ],		// managerTypeID
								[ 7, 'asc' ]		// startDate
							]
						});
						
		
					});
										
		
/* 			}(jQuery)); */
		
		} // end drawCharts
				
	</script>		
	
	
	<style>
		
		/* Customized Styling For [D]ata[T]able [E]ditor */
		.DTE_Header { display: none; 	}
		.DTE_Body { padding-top: 0px !important; padding-bottom: 0px !important; }
		.DTE_Field { padding-left: 15px !important; padding-right: 15px !important; }
		.DTE_Footer { display: none; }		
		
		h5.timeline_title {
			margin-top: 5px;
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
	
	<div class="page-content">	


		<!-- DataTable -->
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--6-col">
			
				<table id="customerManagers" class="compact display" style="width: 100%;">
					<thead>
						<tr>
							<th class="customerID">Customer ID</th>
							<th class="userID">User ID</th>
							<th class="username">User Name (email)</th>
							<th class="managerName">Manager Name</th>
							<th class="active">Manager User<br>Account Active?</th>
							<th class="managerTypeID">Manager Type ID</th>
							<th class="managerTypeName">Manager Type Name</th>
							<th class="startDate">Start Date</th>
							<th class="endDate">End Date</th>
						</tr>
					</thead>
				</table>

			</div>
			<div class="mdl-layout-spacer"></div>
			
   	</div>


		<!-- Timeline Chart -->
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--9-col" align="center">
				<div><h5 class="timeline_title">Timeline</h5></div>
				<div id="customerManagersTimeline_progressbar"></div>
				<div id="customerManagersTimeline"></div>
			</div>
			<div class="mdl-layout-spacer"></div>

		</div>



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