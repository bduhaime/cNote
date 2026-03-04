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
call checkPageAccess(36)

statusList 	= request.querystring("statusList")
cmtID 		= request.querystring("cmtID")

if isNumeric(request.querystring("cmtID")) then 
	SQL = "select name from customerManagerTypes where id = " & request.querystring("cmtID") & " "
	
	set rs = dataconn.execute(SQL)
	if not rs.eof then 
		cmtName = rs("name")
	else 
		cmtName = "Unknown"
	end if 
else 
	cmtName = "Unknown"
end if 

title = session("clientID") & " - <a href=""executiveDashboard.asp"">Executive Dashboard</a> > Customers Without Manager of Type: " & cmtName
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
	   
		const cmtID 			= '<% =cmtID %>';
		const statusList 		= '<% =statusList %>';

		//================================================================================================ 
		$(document).ready( function() {
		//================================================================================================ 

					
			let table = $( '#customerWithoutManagers' )
				.on( 'click', 'tbody > tr', function(event) {

					const customerID = $( '#customerWithoutManagers' ).DataTable().row( $(this).closest('tr') ).data().customerID;
					window.location.href = `customerManagers.asp?id=${customerID}`;
					
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/exec/customersWithoutManagers`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: { 
							cmtID: cmtID,
							statusList: statusList,
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
		   <div class="mdl-cell mdl-cell--5-col">
			
				<table id="customerWithoutManagers" class="compact display">
					<thead>
						<tr>
							<th class="customerID">Customer ID</th>
							<th class="customerName">Customer</th>
							<th class="customerStatusName">Customer Status</th>
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