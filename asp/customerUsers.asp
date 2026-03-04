<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% ' response.buffer = true %>
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
<!-- #include file="includes/validContactDomain.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(111)

customerID = request.querystring("id")
%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customer users")


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
	
	<link rel="stylesheet" href="dialog-polyfill.css" />

	<script src="customerContacts.js"></script>
	<script src="customerAnnotations.js"></script>

	<script>

		$(document).ready(function() {
			$('#tbl_customerUsers').DataTable({
				columnDefs: [
					{targets: 'username', className: 'dt-body-left dt-head-left'},
					{targets: 'firstName', className: 'dt-body-left dt-head-left'},
					{targets: 'lastName', className: 'dt-body-left dt-head-left'},
					{targets: 'title', className: 'dt-body-left dt-head-left'},
					{targets: 'active', className: 'dt-body-center dt-head-center'},
					{targets: 'internal', className: 'dt-body-center dt-head-center'},
					{targets: 'external', className: 'dt-body-center dt-head-center'},
					{targets: 'contact', className: 'dt-body-center dt-head-center'},
				],
				scroller: { rowHeight: 38 },
				scrollCollapse: true,
				scrollY: 650,

			});
		} );

	</script>


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
		<span class="mdl-layout-title">Customer Users</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	
		<div class="page-content">
			<!-- Your content goes here -->
	
		
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--10-col">
					<br>
					<table id="tbl_customerUsers" class="compact display">
						<thead>
							<tr>
								<th class="username">Username</th>
								<th class="firstName">First Name</th>
								<th class="lastName">Last Name</th>
								<th class="title">Title</th>
								<th class="active">Active</th>
								<th class="internal">Internal</th>
								<th class="external">External</th>
								<th class="contact">Customer<br>Contact</th>
							</tr>
						</thead>
				  		<tbody > 
			
						<%
						SQL = "select distinct " &_
									"u.id, " &_
									"u.username, " &_
									"case when u.firstname = 'null' then '' else u.firstName end as firstName, " &_
									"case when u.lastName = 'null' then '' else u.lastName end as lastName, " &_
									"case when u.title = 'null' then '' else u.title end as title, " &_
									"u.active, " &_
									"uc.customerID, " &_
									"cc.id as customerContactID " &_
								"from csuite..users u " &_
								"join userCustomers uc on (uc.userID = u.id) " &_
								"left join customerContacts cc on (cc.email = u.username and cc.customerID = uc.customerID and (cc.deleted = 0 or cc.deleted is null)) " &_
								"where uc.customerID in (1, " & customerID & ") " &_
								"order by u.username "
								
								
						dbug(SQL)
						set rsCU = dataconn.execute(SQL)
						while not rsCU.eof 

							if lCase(rsCU("active")) = "true" then 
								active = "<i class=""material-symbols-outlined"">check</i>"
							else 
								active = ""
							end if
							
							if cInt(rsCU("customerID")) = 1 then 
								internal = "<i class=""material-symbols-outlined"">check</i>"
								external = ""
							else 
								internal = ""
								external = "<i class=""material-symbols-outlined"">check</i>"
							end if
							
							if not isNull(rsCU("customerContactID")) then 
								customerContactIcon = "<i class=""material-symbols-outlined"">contact_mail</i>"
							else 
								customerContactIcon = ""
							end if
							
							
							%>
							<tr>
								<td><% =rsCU("username") %></td>
								<td><% =rsCU("firstName") %></td>
								<td><% =rsCU("lastName") %></td>
								<td><% =rsCU("title") %></td>
								<td><% =active %></td>
								<td><% =internal %></td>
								<td><% =external %></td>
								<td><% =customerContactIcon %></td>
							</tr>
							<%
							rsCU.movenext 
	
						wend 
						rsCU.close 
						set rsCU = nothing 
						%>
	
				  		</tbody>
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