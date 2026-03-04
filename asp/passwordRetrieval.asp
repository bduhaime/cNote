<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% session("dbName") = "csuite" %>

<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/md5.asp" -->
<!-- #include file="includes/randomString.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/smtpParms.asp" -->
<%
userLog("Password Retrieval")
dbug("request.form('submit'): " & request.form("submit"))

' if request.form("submit") <> "forgot" then
	if request.form("submit") = "sendit" then
		
		pwdReset = true
	
		SQL = "select passwordHash from cSuite..users where username = '" & request.form("email") & "' "
		set rs = dataconn.execute(SQL)

		if rs.eof then
			dbug("email could not be found")
		else

			tempPassword = randomString()
			tempPasswordHash = md5(tempPassword)
			
			SQL = "update cSuite..users set " &_
					"passwordHash = '" & tempPasswordHash & "', " &_
					"resetPasswordOnLogin = 1 " &_
					"where username = '" & request.form("email") & "' "
				  
			set rs = dataconn.execute(SQL)
			set rs = nothing

			set objmail		= createobject("CDO.Message")

			smtpParms
			
			objmail.from	= systemControls("Generic Email From Address")
			objmail.to		= request.form("email")
			objmail.subject	= "Password retrieval"			
			
			objmail.HTMLbody= "<html><body>Here is the temporary password you requested:<br><br>Password: " & tempPassword & " <br><br>This message was generated at " & now() & " Central Time</body></html>"
			dbug("objmail.HTMLbody updated...")
			
			dbug("CDO.Message.fields")
			for each item in objMail.fields
				dbug("..." & item.name & "=" & item.value)
			next 
			dbug("")

			if systemControls("Send system generated email") = "true" then 

				dbug("prior to .send")
				objmail.send
				dbug("after .send")
				set objmail = Nothing
				dbug("objmail destroyed")
				
			else 
			
				dbug("Password email generated but not sent because 'Send system generated email' is off")
				
			end if
			
		end if
				
	end if
' else
' 
' 	server.transfer "login.asp"
' 	
' end if 

'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************

'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************
%>
<!DOCTYPE html>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	jQuery -->
	<script type="text/javascript" src="jQuery/jquery-3.5.1.js"></script>

	<!-- 	jQuery UI -->
	<script type="text/javascript" src="jquery-ui-1.12.1/jquery-ui.js"></script>
	<link rel="stylesheet" href="jquery-ui-1.12.1/jquery-ui.css" />


</head>
  
<body>
	<% if not pwdReset then %>
		<form action="passwordRetrieval.asp" method="POST" name="passwordRetrieval" id="passwordRetrieval">
	<% end if %>
	<div class="mdl-grid">
		<div class="mdl-layout-spacer"></div>
		<div class="mdl-card mdl-cell mdl-cell--4-col mdl-cell--3-col-tablet mdl-shadow--6dp">
			<div class="mdl-card__title mdl-color--primary mdl-color-text--white">
				<h2 class="mdl-card__title-text">Password Reset</h2>
			</div>
			<div id="info-text" class="mdl-card__supporting-text">
					<% if not pwdReset then %>
					<div class="mdl-textfield mdl-js-textfield">
						<input class="mdl-textfield__input" type="text" id="email" name="email" />
						<label class="mdl-textfield__label" for="email">Email Address</label>
					</div>
					<% end if %>
					<div class="mdl-card__supporting-text">
						<% if not pwdReset then %>
					    Enter the email address associated with your account.
					    <% else %>
					    A temporary password has been generated and sent to your email address. If you have not received it in a few minutes, be sure to check your junk mail folder. 
					    <% end if %>
					</div>
			</div>
			<div class="mdl-card__actions mdl-card--border">
				<% if not pwdReset then %>
					<button type="submit" name="submit" value="sendit" class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect"> Reset Password </button>
				<% else %>
					<a href="login.asp">Login</a>
				<% end if %>
			</div>
		</div>
		<div class="mdl-layout-spacer"></div>
	</div>
	<% if not pwdReset then %>
		</form>
	<% end if %>
<% session.abandon() %>

</body>

</html>                                                                                    