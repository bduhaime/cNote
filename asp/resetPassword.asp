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
<%
title = "Save New Password"
userLog(title)

dbug("request.form('submit'): " & request.form("submit"))

' if request.form("submit") <> "forgot" then
if request.form("submit") = "saveit" then
	
	if request.form("newPassword") = request.form("confPassword") then
		dbug("passwords match")
		
		passwordsMatch = true
		
		SQL = "update cSuite..users set " &_
				"passwordHash = '" & md5(request.form("newPassword")) & "', " &_
				"resetPasswordOnLogin = 0 " &_
				"where id = " & session("userID") & " "
		dbug(SQL)
				
		set rs = dataconn.execute(SQL)
		dbug("update successful")
		set rs = nothing
		
		session.abandon()
		server.transfer "login.asp"
		
	else
		dbug("passwords don't match")
		
		passwordsMatch = false
		
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
</head>
  
<body>
	<form action="resetPassword.asp" method="POST" name="resetPassword" id="resetPassword">
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-card mdl-cell mdl-cell--4-col mdl-cell--3-col-tablet mdl-shadow--6dp">
				<div class="mdl-card__title mdl-color--primary mdl-color-text--white">
					<h2 class="mdl-card__title-text">Save New Password</h2>
				</div>
				<div class="mdl-card__supporting-text">
						<div class="mdl-textfield mdl-js-textfield">
							<input class="mdl-textfield__input" type="password" id="newPassword" name="newPassword" />
							<label class="mdl-textfield__label" for="newPassword">New Password</label>
						</div>
						<div class="mdl-textfield mdl-js-textfield">
							<input class="mdl-textfield__input" type="password" id="confPassword" name="confPassword" />
							<label class="mdl-textfield__label" for="confPassword">Confirm New Password</label>
						</div>
						<div class="mdl-card__supporting-text">
						    <% if not passwordsMatch then %>
							    Please enter a new password and confirm it by entering it a second time. You will then be prompted to login with your new password.
							<% else %>
								The "New" and "Confirmation" passwords must match exactly. Please try again. You will then be prompted to login with your new password.
							<% end if %>
						</div>
				</div>
				<div class="mdl-card__actions mdl-card--border">
						<button type="submit" name="submit" value="saveit" class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect"> Save New Password </button>
				</div>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
	</form>
</body>

</html>                                                                                    