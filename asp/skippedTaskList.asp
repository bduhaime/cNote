<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->

<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(24)

title = session("clientID") & " - <a href=""executiveDashboard.asp"">Executive Dashboard</a> > Skipped Tasks"
userLog(title)


dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	jQuery -->
	<script type="text/javascript" src="jQuery/jquery-3.5.1.js"></script>


	<!-- 	jQuery UI -->
	<script type="text/javascript" src="jquery-ui-1.12.1/jquery-ui.js"></script>
	<link rel="stylesheet" href="jquery-ui-1.12.1/jquery-ui.css" />


	<!-- 	DataTables -->
	<script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.10.21/b-1.6.3/b-colvis-1.6.3/b-html5-1.6.3/b-print-1.6.3/fh-3.1.7/sc-2.0.2/datatables.min.js"></script>
	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.10.21/b-1.6.3/b-colvis-1.6.3/b-html5-1.6.3/b-print-1.6.3/fh-3.1.7/sc-2.0.2/datatables.min.css"/>

	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>


    <script type="text/javascript">
	    
	   'use strict';
	   
		const queryString = window.location.search;
		const urlParams = new URLSearchParams(queryString);
		const statusList 		= urlParams.get( 'statusList' );

		//================================================================================================ 
		$(document).ready( function() {
		//================================================================================================ 

					
			let table = $( '#skippedTasks' )
				.on( 'click', 'tbody > tr', function(event) {
					const taskID = this.id;
					const customerID = $( '#skippedTasks' ).DataTable().row( $(this).closest('tr') ).data().customerID;

					window.location.href = `taskDetail.asp?customerID=${customerID}&taskID=${taskID}`;
					
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/exec/skippedTasks`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: { 
							statusList: statusList
						},
					},
					rowId: 'taskID',
					scrollY: 630,
					deferRender: true,
					scroller: true,
					scrollCollapse: true,
					columnDefs: [
						{targets: 'customerID', data: 'customerID', className: 'customerID dt-body-left', visible: false },
						{targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
						{targets: 'customerStatusName', data: 'customerStatusName', className: 'customerStatusName dt-body-left' },
						{targets: 'managerName', data: 'managerName', className: 'managerName dt-body-left' },
						{targets: 'taskID', data: 'taskID', className: 'taskID dt-body-left', visible: false },
						{targets: 'taskName', data: 'taskName', className: 'taskName dt-body-left' },
						{targets: 'taskStatusID', data: 'taskStatusID', className: 'taskStatusID dt-body-left', visible: false },
					]
	
				});

		});	    
		//================================================================================================ 


	</script>
	
</head>

<body>

	<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Skipped Tasks</span>
	</div>

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content"><!-- Your content goes here -->
		
		<br>
		
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--9-col">
			
				<table id="skippedTasks" class="compact display">
					<thead>
						<tr>
							<th class="customerID">Customer ID</th>
							<th class="customerName">Customer</th>
							<th class="customerStatusName">Customer Status</th>
							<th class="managerName">Customer Manager</th>
							<th class="taskID">Task ID</th>
							<th class="taskName">Task</th>
							<th class="taskStatusID">Task Status ID</th>
						</tr>
					</thead>
				</table>
				

				</div>
			<div class="mdl-layout-spacer"></div>
			
   	</div>
		
	</div><!-- end page-content -->
		


</main>

<!-- #include file="includes/pageFooter.asp" -->
<%
dataconn.close 
set dataconn = nothing
%>
</body>
</html>