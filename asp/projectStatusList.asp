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

title = session("clientID") & " - <a href=""executiveDashboard.asp"">Executive Dashboard</a> > "
select case lcase( request.querystring("type") )
	case "escalate"
		title = title & "Project Escalation Requests"
		escalationType = "Escalate"
	case "reschedule"
		title = title & "Project Reschedule Requests"
		escalationType = "Reschedule"
	case else 
		title = title & "Product Requests"
		escalationType = "Unknown"
end select 
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


	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>


    <script type="text/javascript">
	    
	   'use strict';
	   
	   
	   
		const escalationType	= '<% =escalationType %>';

		const queryString = window.location.search;
		const urlParams = new URLSearchParams(queryString);
		const statusList 		= urlParams.get( 'statusList' );


		//================================================================================================ 
		$(document).ready( function() {
		//================================================================================================ 

					
			let table = $( '#projects' )
				.on( 'click', 'tbody > tr', function(event) {
					const projectID = this.id;
					const customerID = $( '#projects' ).DataTable().row( $(this).closest('tr') ).data().customerID;

					window.location.href = `taskList.asp?customerID=${customerID}&projectID=${projectID}`;
					
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/exec/projectEscalations`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: { 
							type: escalationType,
							statusList: statusList
						},
					},
					rowId: 'projectID',
					scrollY: 630,
					deferRender: true,
					scroller: true,
					scrollCollapse: true,
					columnDefs: [
						{targets: 'projectStatusID', data: 'projectStatusID', className: 'projectStatusID dt-body-left', visible: false },
						{targets: 'statusDate', data: 'statusDate', className: 'statusDate dt-body-left dt-head-left' },
						{targets: 'projectStatusType', data: 'projectStatusType', className: 'projectStatusType dt-body-left' },
						{targets: 'projectID', data: 'projectID', className: 'projectID dt-body-left', visible: false },
						{targets: 'projectName', data: 'projectName', className: 'projectName dt-body-left' },
						{targets: 'customerID', data: 'customerID', className: 'customerID dt-body-left', visible: false },
						{targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
						{targets: 'customerStatusName', data: 'customerStatusName', className: 'customerStatusName dt-body-left' },
						{targets: 'managerName', data: 'managerName', className: 'managerName dt-body-left' }
					]
	
				});

		});	    
		//================================================================================================ 


	</script>
	
</head>

<body>

	<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Project Escalation Requests</span>
	</div>

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div id="dashboard1" class="page-content">
		<!-- Your content goes here -->

		<br>
		
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--9-col">
			
				<table id="projects" class="compact display">
					<thead>
						<tr>
							<th class="projectStatusID">Project Status ID</th>
							<th class="statusDate">Status Date</th>
							<th class="projectStatusType">project Status</th>
							<th class="projectID">Project ID</th>
							<th class="projectName">Project Name</th>
							<th class="customerID">Customer ID</th>
							<th class="customerName">Customer</th>
							<th class="customerStatusName">Customer Status</th>
							<th class="managerName">Customer Manager</th>
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