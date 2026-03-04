<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/md5.asp" -->
<!-- #include file="includes/randomString.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/smtpParms.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<% 
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" 
title = title & "<a href=""userList.asp?"">Users</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">New User" 
userLog("User Add")
dbug("start of top-logic")

if request.querystring("cmd") = "add" then
	dbug("cmd = 'add'")
	
	inputValidationError = false
	
	if len(request.form("username")) > 0 then
		username = request.form("username")
		SQL = "select id from cSuite..users where username = '" & username & "' "
		set rs = dataconn.execute(SQL)
		if rs.eof then
			dbug("username is unique")
		else 
			dbug("duplicate username entered: " & username)
			inputValidationError = true 
		end if
	else
		dbug("username missing")
		inputValidationError = true
	end if
	
	if len(request.form("customerID")) > 0 then
		customerID = request.form("customerID")
	else 
		dbug("customerID missing")
		inputValidationError = true
	end if

	dbug("inputValidationError=" & inputValidationError)
	if not inputValidationError then
		
		firstName = request.form("firstName")
		lastName = request.form("lastName")
		title = request.form("title")
		
		dbug("finding new id value...")
		SQL = "select max(id) as maxID from cSuite..users "
		
		set rs = dataconn.execute(SQL)
		if not rs.eof then
			newID = cInt(rs("maxID")) + 1
		else
			newID = 1
		end if
		rs.close
		
		tempPassword = randomString()
		tempPasswordHash = md5(tempPassword)
	
		SQL = "insert into cSuite..users (id, username, passwordHash, firstName, lastName, active, resetPasswordOnLogin, customerID, title) " &_
				"values (" & newID & ",'" & username & "','" & tempPasswordHash & "','" & firstName & "','" & lastName & "',1,1," & customerID & ",'" & title & "') "

		set rs = dataconn.execute(SQL)
		set rs = nothing

		session("msg") = "User " & trim(username) & " added"

		' Now that the user is created in cSuite..users, automatically add a corresponding row into cSuite..clientUsers for the "current" client...
		' start by getting the id# corresponding to session("clientID")...
		SQL = "select id from cSuite..clients where clientID = '" & session("dbName") & "' "
		set rsClient = dataconn.execute(SQL)
		if not rsClient.eof then 
			clientNbr = rsClient("id")
		else 
			clientNbr = "NULL"
		end if 
		rsClient.close 
		set rsClient = nothing
		
		' now do the inserting into cSuite..clientUsers....
		SQL = "insert into cSuite..clientUsers (clientID, userID, updatedBy, updatedDateTime) " &_
				"values (" & clientNbr & "," & newID & "," & session("userID") & ", current_timestamp) "
		set rsCU = dataconn.execute(SQL)
		set rsCU = nothing
		
		' all done. Now send out an email...

		
		set objmail		= createobject("CDO.Message")
		objmail.from	= "brad@sqware1.com"
		objmail.to		= username
		objmail.subject	= "New User Credentials"
		
		objmail.HTMLbody =	"<html><body>A new account has been created for you. Here is your temporary password:<br><br>Password: " & tempPassword &_
									"<br><br>Click <a href=""http://" & systemControls("server name") & "/login.asp"">here</a> to login." &_
									"<br><br>This message was generated at " & now() & " Central Time</body></html>"
		
		smtpParms
	
		if systemControls("Send system generated email") = "true" then 

			dbug("prior to .send")
			objmail.send
			dbug("after .send")
			set objmail = Nothing
			dbug("objmail destroyed")
			
		else 
		
			dbug("New user email generated but not sent because 'Send system generated email' is off")
			
		end if
	
		dbug("insert of new user complete, executing server.transfer...")
		server.transfer "userList.asp"
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
	
	<script type="text/javascript" src="userEdit.js"></script>

</head>

<body>

<form action="userAdd.asp?cmd=add" method="POST" name="userEdit" id="userEdit">

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

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
				    <input class="mdl-textfield__input" type="text" id="username" name="username" value="" pattern="[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$" onchange="checkUniqueUsername_onChange(this)" autocomplete="off">
				    <label class="mdl-textfield__label" for="username">Username / Email...</label>
				    <span class="mdl-textfield__error">Invalid email address</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="firstName" name="firstName" value="" pattern="[A-Z,a-z,\-, ]*" autocomplete="off">
				    <label class="mdl-textfield__label" for="firstName">First name...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="lastName" name="lastName" value="" pattern="[A-Z,a-z,\-, ]*" autocomplete="off">
				    <label class="mdl-textfield__label" for="lastName">Last name...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>

			</div>
			<div class="mdl-cell mdl-cell--3-col">

				<% if lCase(session("dbName")) <> "csuite" then %>
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						<input class="mdl-textfield__input" id="customerName" name="customerName" value="" type="text" list="customerList" oninput="CustomerName_onInput(this)" autocomplete="off" />
						<label class="mdl-textfield__label" for="customerName">Customer name...</label>
						<datalist id="customerList">
							<%
							SQL = "select id, name from customer_view where (deleted = 0 or deleted is null) order by name "
							dbug(SQL)
							set rsCust = dataconn.execute(SQL)
							while not rsCust.eof
								response.write("<option name=""" & rsCust("name") & """ value=""" & rsCust("name") & """ data-id=""" & rsCust("id") & """></option>")
								rsCust.movenext 
							wend
							rsCust.close 
							set rsCust = nothing
							%>
						</datalist>
						<input type="hidden" id="customerID" name="customerID" value="">
					</div>
		
					<br>
				<% end if %>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="title" name="title" value="" pattern="[A-Z,a-z,\-, ]*" autocomplete="off">
				    <label class="mdl-textfield__label" for="title">Title...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>

			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col"></div>
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

<script>
	
	document.getElementById('username').focus();
	
</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>