<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

dbug("start of top-logic")

title = "Add A Role" 

if request.querystring("cmd") = "add" then
	dbug("cmd = 'add'")
	inputValidationError = false
	if len(request.form("roleName")) > 0 then
		roleName = request.form("roleName")
	else
		inputValidationError = true
	end if
	
	dbug("inputValidationError=" & inputValidationError)
	if not inputValidationError then
		
		dbug("finding new id value...")
		SQL = "select max(id) as maxID from roles "
		
		set rs = dataconn.execute(SQL)
		if not rs.eof then
			newID = cInt(rs("maxID")) + 1
		else
			newID = 1
		end if
		rs.close
		dbug("new id found: " & newID)
		

	
		SQL = 	"insert into roles (id, name, deleted, updatedBy, updatedDateTime) " &_
				"values (" & newID & ",'" & roleName & "',0," & session("userID") & ",current_timestamp) "
		dbug("inserting new role: " & SQL)
		set rs = dataconn.execute(SQL)
		dbug("new role inserted")	
' 		rs.close 
		set rs = nothing
		session("msg") = "Role " & trim(roleName) & " added"

		dbug("insert of new role complete, executing server.transfer...")
		server.transfer "roleList.asp"
		dbug("post server.transfer...")

	else
		
		dbug("required fields missing...")
		session("msg") = "Required fields missing"
		
	end if

	
end if

userID = 0

dbug("end of top-logic")
%>





<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<% dbug("after include of globalHeader") %>
	
	<!--getmdl-select-->   
	<link rel="stylesheet" href="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.css">
	<script defer src="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.js"></script>	

	<script type="text/javascript" src="roldEdit.js"></script>

</head>

<body>

<form action="roleAdd.asp?cmd=add" method="POST" name="userEdit" id="userEdit">

<% dbug("before includes/mdlLayoutNavLarge.asp") %>
<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->
<% dbug("before includes/mdlLayoutNavLarge.asp") %>

<main class="mdl-layout__content">
	<div class="page-content">
		<!-- Your content goes here -->

		<div class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button type="button" class="mdl-snackbar__action"></button>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="roleName" name="roleName" value="" pattern="[A-Z,a-z,\-, ]*">
				    <label class="mdl-textfield__label" for="roleName">Role name...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>

			</div>

			<div class="mdl-layout-spacer"></div>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">

				<div align="right">
					<!-- Flat button with ripple -->
					<button class="mdl-button mdl-js-button mdl-js-ripple-effect">
					CANCEL
					</button>
					<!-- Flat button with ripple -->
					<button class="mdl-button mdl-js-button mdl-js-ripple-effect" type="submit">
					SAVE
					</button>
				</div>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

	</div>

</main>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>