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
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(110)

title = session("clientID") & " - Client Detail" 
userLog(title)

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	id = request.querystring("id")
end if
%>

<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<!--getmdl-select-->   
	<link rel="stylesheet" href="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.css">
	<script defer src="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.js"></script>	

	<script src="clientDetail.js"></script>

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
		
		<%
		SQL = "select * " &_
				"from csuite..clients " &_
				"where id = " & id & " "
				
		set rsClient = dataconn.execute(SQL) 
		if not rsClient.eof then 
			%>		
	
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--12-col" style="text-align: center;">

					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					    <input class="mdl-textfield__input attribute" type="text" id="clientName" value="<% =rsClient("name") %>" disabled>
					    <label class="mdl-textfield__label" for="clientName">Client name...</label>
					</div>

					<span>&nbsp;</span>
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					    <input class="mdl-textfield__input attribute" type="text" id="startDate" value="<% =rsClient("startDate") %>" disabled>
					    <label class="mdl-textfield__label" for="startDate">Start date...</label>
					</div>

					<span>&nbsp;</span>
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					    <input class="mdl-textfield__input attribute" type="text" id="endDate" value="<% =rsClient("enddate") %>" disabled>
					    <label class="mdl-textfield__label" for="endDate">End date...</label>
					</div>

				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
			<hr>
	
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--4-col">
					<div class="mdl-typography--title" style="text-align: center;">Users With Access to <% =rsClient("name") %></div>
					<hr>
	
					<table class="mdl-data-table mdl-js-data-table" style="margin-left: auto; margin-right: auto;">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Name</th>
								<th class="mdl-data-table__cell--non-numeric">Title</th>
								<th class="mdl-data-table__cell--non-numeric">Active</th>
							</tr>
						</thead>
						<tbody>
							<%
							SQL = "select u.id, u.username, concat(firstName, ' ', lastName) as userFullName, title, active " &_
									"from cSuite..users u " &_
									"join cSuite..clientUsers cu on (cu.userID = u.id and cu.clientID = " & id & ") " &_
									"order by username "
							dbug(SQL)
							set rsCU = dataconn.execute(SQL)
							while not rsCU.eof

								if lCase(rsCU("active")) = "true" then 
									active = "<i class=""material-icons"">check</i>"
								else 
									active = ""
								end if
							
								%>
								<tr>
									<td class="mdl-data-table__cell--non-numeric" data-id="<% =rsCU("id") %>"><% =rsCU("userFullName") %></td>
									<td class="mdl-data-table__cell--non-numeric"><% =rsCU("title") %></td>
									<td class="mdl-data-table__cell--non-numeric" style="text-align: center;"><% =active %></td>
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
			</div>
		<%
		end if 
		%>
		
	</div>

</main>

	<!-- #include file="includes/pageFooter.asp" -->

<%
	
rsClient.close 
set rsClient = nothing 
	
dataconn.close 
set dataconn = nothing
%>

</body>
</html>