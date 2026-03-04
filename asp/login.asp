<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/md5.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<%

if len(request.querystring("msg")) > 0 then 
	msg = request.querystring("msg")
else 
	msg = ""
end if

if (request.serverVariables("REMOTE_ADDR") = "127.0.0.1" AND request.serverVariables("HTTP_USER_AGENT") = "") then 
	dbug("phantom request detected; abandoning session and ending response.")
	session.abandon()
	response.end()
end if

dbug("login attempt initiated from " & request.serverVariables("REMOTE_ADDR"))
if request.querystring("cmd") = "logout" then
	session.abandon()
	if request.querystring("msg") > "" then 
		msg = request.querystring("msg") 
	else 
		msg = "You have successfully logged out"
	end if
end if

'*********************************************************************************************
sub getFirstValidClient(userIdNbr, byRef dbConn)
'*********************************************************************************************
dbug("getFirstValidClient...")

	SQL = "select top 1 c.id, c.clientID, c.name, c.databaseName, cu.userDefault " &_
			"from csuite..clients c " &_
			"join csuite..clientUsers cu on (cu.clientID = c.id) " &_
			"where cu.userID = " & userIdNbr & " " &_
			"and (c.startDate <= current_timestamp or c.startDate is null) " &_
			"and (c.endDate >= current_timestamp or c.endDate is null) " &_
			"order by cu.userDefault desc "
			
	dbug(SQL)
		
	set rsFirstValidClient = dbConn.execute(SQL) 
	if not rsFirstValidClient.eof then 
		dbug("valid clientID found for this user, configuring session...")
		
		session("dbName") 		= rsFirstValidClient("databaseName")
		session("clientID") 		= rsFirstValidClient("clientID")
		session("clientName")	= rsFirstValidClient("name")
		session("clientNbr")		= rsFirstValidClient("id")
		
	else 
	
		dbug("NO valid clientID found for this user, abandoning session...")
		session.abandon() 
	
	end if 
	
	rsFirstValidClient.close 
	set rsFirstValidClient = nothing 
	
	if NOT len(session("userID")) > 0 then
		response.redirect "login.asp" 
	end if 

end sub



'*********************************************************************************************
sub signin
'*********************************************************************************************
dbug("signin button pressed")


	on error resume next
	set userconn=Server.createobject("ADODB.Connection")
	userconn.open "Provider=sqloledb; Data Source=" & application("dbServer") & "," & application("dbPort") & "; Initial Catalog=cSuite; User Id=" & application("dbUser") & "; Password=" & application("dbPass") & "; "
' 	if userconn.errors.count > 0 OR isNull(userconn.properties("DBMS Name")) then

	if userconn.errors.count > 0 then
		
		dbug("could not connect to cSuite database")
		session.abandon()
		response.end()
		
	end if 
	dbug("connection to cSuite database established")
	on error goto 0

	
	dbug("authenticating user...")
	if (len(request.form	("username")) > 0 AND len(request.form("userpass")) > 0) then
	
		set cmdSelect = server.CreateObject("ADODB.Command")
		cmdSelect.activeConnection = userconn
		cmdSelect.commandText = "select u.id, u.firstName, u.lastName, u.resetPasswordOnLogin " &_
										"from csuite..users u " &_
										"where u.username = ? " &_
										"and u.passwordHash = ? " &_
										"and (active = 1) " 
											
		cmdSelect.parameters.append = cmdSelect.createParameter("username", adVarChar, adParamInput, 50, request("username"))
		cmdSelect.parameters.append = cmdSelect.createParameter("password", adVarChar, adParamInput, 255, md5(request("userpass")))
	
		set rs = cmdSelect.execute()

		if not rs.eof then
			
			dbug("credentials valid for " & request("username") & "; configuring session properties...")

			session("userID") 		= rs("id")
			session("firstName") 	= rs("firstName")
			session("lastName") 		= rs("lastName")
			session("username") 		= request.form("username")			
			
			dbug("determining clientID/database for userID=" & session("userID"))
			
			dbug("request.cookies('user')('username') = " & request.cookies("user")("username"))
			dbug("request.cookies('user')('clientID') = " & request.cookies("user")("clientID"))
			
			if (len(request.cookies("user")("username")) > 0 AND len(request.cookies("user")("clientID")) > 0) then 
				' values for username and clientID are present in cookies...
				
				if request.cookies("user")("username") = session("username") then 
					' cookie is for the user that is logging in, so now validate that the user has access to this client...
					
					set cmdCookieClient = server.createObject("ADODB.Command")
					cmdCookieClient.activeConnection = userconn
					
					cmdCookieClient.commandText = "select c.id, c.clientID, c.name, c.databaseName " &_
															"from csuite..clients c " &_
															"join csuite..clientUsers cu on (cu.clientID = c.id) " &_
															"where cu.userID = ? " &_
															"and c.clientID = ? " &_
															"and (c.startDate <= current_timestamp or c.startDate is null) " &_
															"and (c.endDate >= current_timestamp or c.endDate is null) " 
				
				
					cmdCookieClient.parameters.append = cmdSelect.createParameter("userID", adBigInt, adParamInput, 0, session("userID"))
					cmdCookieClient.parameters.append = cmdSelect.createParameter("clientiD", adVarChar, adParamInput, 10, request.cookies("user")("clientID"))

					set rsClient = cmdCookieClient.execute()
					
					if not rsClient.eof then 
					
						dbug("clientID found in cookies is valid for this user, configuring session...")
						
						session("dbName") 		= rsClient("databaseName")
						session("clientID") 		= rsClient("clientID")
						session("clientName")	= rsClient("name")
						session("clientNbr")		= rsClient("id")
						
					else 
						
						dbug("clientID found in cookies is NOT valid for this user, checking database for another valid client...")
						
						getFirstValidClient session("userID"), userconn

					end if 
					
				else 
					
					dbug("user cookie is NOT for this user; checking database for another valid client...")
					
					getFirstValidClient session("userID"), userconn
					
				end if 
				
			else 

				dbug("user cookie NOT present; checking database for another valid client...")

				getFirstValidClient rs("id"), userconn
				
			end if
				
			dbug("should only get here if user/client validated....")						
						
									
					
			
			set cmdUpdate = server.createObject("ADODB.Command")
			cmdUpdate.activeConnection = userconn
			cmdUpdate.commandText = "update users set lastLoginDate = CURRENT_TIMESTAMP where id = ? "
			cmdUpdate.parameters.append = cmdUpdate.createParameter("userID", adInteger, adParamInput, , session("userID"))
			set rsUpdate = cmdUpdate.execute()
			set rsUpdate = nothing
			set cmdUpdate = nothing 

			dbug("prior to dataconn -- session('dbName'): " & session("dbName"))
			%>
			<!-- #include file="includes/dataconnection.asp" -->
			<%

			if rs("resetPasswordOnLogin") then
				session("internalUser") = ""
				userLog("user logged in with a temporary password and needs to reset it")
				response.redirect "resetPassword.asp"
			else
				if lCase(session("dbName")) = "csuite" then 
					dbug("csuite/admin user detected")
					session("internalUser") = 0
					userLog("cSuite user logged in successfully")
				else 
					SQL = "select customerID from userCustomers where userID = " & session("userID") & " and customerID = 1 "
					dbug(SQL)
					set rsUC = dataconn.execute(SQL) 
					if not rsUC.eof then 
						dbug("internal user detected")
						session("internalUser") = 1
						userLog("internal user logged in successfully")
					else 
						dbug("external user detected")
						session("internalUser") = -1
						userLog("external user logged in successfully")
					end if 
					rsUC.close 
					set rsUC = nothing
				end if
			end if				
	
		else
		
			dbug("credentials not valid, abandoning session...")
			Session.Contents.Remove("userID")
			session.abandon()
	
		end if
		
		rs.close 
		set rs = nothing
		set cmdSelect = nothing 
		
		userconn.close 
		set userconn = nothing
		
		if len(session("userID")) > 0 then
			
			session("loginFailed") = false
			
			response.cookies("user")("clientID") = session("clientID")
			response.cookies("user")("username") = session("username")
			
			dbug("login successful for " & request("username") & " from " & request.serverVariables("REMOTE_ADDR"))
			response.clear
			
			dbug("session('internalUser'): " & session("internalUser"))
			
			select case session("internalUser") 
			
				case 1 	' true -- internal user (companyID = 1)

					dbug("redirecting to home.asp, dbName=" & session("dbName") & ", customerID=" & session("customerID"))
					userLog( "successful login" )
					response.redirect "home.asp"

				case 0 	' csuite / admin client (companyID is N/A)

					' double-checking session('dbName'), just in case...
					if lCase(session("dbName")) = "csuite" then 
						dbug("redirecting to adminHome.asp, dbName=" & session("dbName") & ", customerID=" & session("customerID"))
						response.redirect "adminHome.asp" 
					else 
						dbug("customer home page cannot be determine, redirecting to login.asp")
						response.redirect "login.asp"
					end if
	
				case -1 	' false -- external user (companyID != 1

' 					dbug("redirecting to externalUserCustomerList.asp, dbName=" & session("dbName") & ", customerID=" & session("customerID"))
' 					response.redirect "externalUserCustomerList.asp" 
					dbug("redirecting to home.asp, dbName=" & session("dbName") & ", customerID=" & session("customerID"))
					response.redirect "home.asp"


				case else 
				
					dbug("user home page cannot be determine, redirecting to login.asp")
					response.redirect "login.asp user home could not be determined. Contact admin."

			end select 


		else
			
			dbug("login login failed for " & request("username") & " from " & request.serverVariables("REMOTE_ADDR"))
			session("loginFailed") = true 
	
		end if
	
	end if
	
	
end sub

'*********************************************************************************************
'*********************************************************************************************

select case request.form("submit")
	case "signin"
		call signin 
	case "forgot"
		dbug("forgot password button pressed")
		response.redirect "passwordRetrieval.asp"
	case else
		dbug("HTTP_USER_AGENT: " & request.serverVariables("HTTP_USER_AGENT"))
		dbug("some other button pressed: " & request.form("submit"))
end Select

'*********************************************************************************************
'*********************************************************************************************
'*********************************************************************************************

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<script>
		
		'use strict';
		
		$( function() {
			
			$( '#browserWidth' ).val( $( window ).width() );
			$( '#browserHeight' ).val( $( window ).height() );
			$( '#screenWidth' ).val( screen.width );
			$( '#screenHeight' ).val( screen.height );
				
		});
		

		//======================================================================================
		$(document).ready(function() {
		//======================================================================================


			let form,
			
			// From http://www.whatwg.org/specs/web-apps/current-work/multipage/states-of-the-type-attribute.html#e-mail-state-%28type=email%29
			emailRegex = /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/,
			email = $( '#email' ),
			allFields = $( [] ).add( email ),
			tips = $( '.validateTips' );


			//-----------------------------------------------------------------------------
			function updateTips( t ) {
			//-----------------------------------------------------------------------------

				tips
					.text( t )
					.addClass( 'ui-state-highlight' );

				setTimeout(function() {
					tips.removeClass( 'ui-state-highlight', 1500 );
				}, 500 );

			}
			//-----------------------------------------------------------------------------
			
			
			//-----------------------------------------------------------------------------
			function checkRegexp( o, regexp, n ) {
			//-----------------------------------------------------------------------------

				if ( !( regexp.test( o.val() ) ) ) {

					o.addClass( 'ui-state-error' );
					updateTips( n );
					return false;

				} else {

					return true;
				}

			}			
			//-----------------------------------------------------------------------------


			//-----------------------------------------------------------------------------
			var dialog = $( '#dialog-form' ).dialog({
			//-----------------------------------------------------------------------------
				autoOpen: false,
				width: 350,
				modal: true,
				buttons: {
					'Reset Password': resetPassword,
					Cancel: function() {
						dialog.dialog( "close" );
					}
				},
				close: function() {
					allFields.removeClass( 'ui-state-error' );
				}
			});			
			//-----------------------------------------------------------------------------


			//-----------------------------------------------------------------------------
			$( '#iForgot' ).on('click', function() {
			//-----------------------------------------------------------------------------
				// 'forgot' button clicked...
				dialog.dialog( 'open' );
				$( '#email' ).val( $( '#username' ).val() );
				$( '#email' ).focus();
				$( '#email' ).select();
				
			});
			//-----------------------------------------------------------------------------
			
			
			//-----------------------------------------------------------------------------
			function resetPassword() {
			//-----------------------------------------------------------------------------


				var valid = true;

				valid = valid && checkRegexp( email, emailRegex, "Email address is not valid" );

				if ( valid ) {

					$.ajax({
						url: `${apiServer}/api/users/resetPassword`,
						type: 'POST',
						data: JSON.stringify({ 
							email: email.val()
						}),
						contentType: 'application/json; charset=utf-8',
						dataType   : 'json',
					});

					$( '#username' ).val( $( '#email' ).val() );
					$( '#username' ).parent().addClass( 'is-dirty' );

					$( '#userpass' ).val('');
					$( '#userpass' ).parent().addClass( 'is-dirty' );
					$( '#userpass' ).focus();
					
					$( "#email" ).val('');
					dialog.dialog( 'close' );
					
					$( '.mdl-js-snackbar' ).get(0).MaterialSnackbar.showSnackbar({
						message: 'Reset requested'
					});
					
					$( '#infoMessage' ).text('Check your email for a new temporary password');

				}
			}
			//-----------------------------------------------------------------------------

			
		});
		//======================================================================================
		
	</script>

	<style>
		label, input { display:block; }
		input.text { margin-bottom:12px; width:95%; padding: .4em; }
		fieldset { padding:0; border:0; margin-top:25px; }
		h1 { font-size: 1.2em; margin: .6em 0; }
		div#users-contain { width: 350px; margin: 20px 0; }
		div#users-contain table { margin: 1em 0; border-collapse: collapse; width: 100%; }
		div#users-contain table td, div#users-contain table th { border: 1px solid #eee; padding: .6em 10px; text-align: left; }
		.ui-dialog .ui-state-error { padding: .3em; }
		.validateTips { border: 1px solid transparent; padding: 0.3em; }
		.ui-dialog-titlebar { color: white; background-color: rgb(103,58,183); }
		
		.mdl-textfield {
			width: 280px;
		}
		
		i.material-symbols-outlined {
			font-size: 30px;
			font-weight: bold;
		}
	</style>
	
</head>
  
<body>

	<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
	</div>

	<div id="dialog-form" title="Password Reset">

		<p class="validateTips">Enter the email address associated with your account and click the Reset Password button.</p>
		
		<label for="email">Email</label>
		<input type="text" name="email" id="email" class="text ui-widget-content ui-corner-all" autocomplete="off">
		
		<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">

	</div>
	

	<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>


		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-card mdl-cell mdl-cell--3-col mdl-cell--3-col-tablet mdl-shadow--6dp">
				<form action="login.asp" method="POST" name="loginForm" id="loginForm">
					<div class="mdl-card__title mdl-color--primary mdl-color-text--white">
						<h2 class="mdl-card__title-text">Login</h2>
					</div>
					<% if session("loginFailed") then display = "block" else display = "none" end if %>
					<div id="loginFailed" style="display: <% =display %>; border: solid crimson 4px; margin: 15px;">
						<table style="border-collapse: collapse;">
							<tr>
								<td style="padding: 15px; background-color: crimson;">
									<i class="material-symbols-outlined" style="color: #ffffff;">error</i>
								</td>
								<td style="padding: 15px;">
									Oops! The email or password did not match our records. Please try again.
								</td>
							</tr>
						</table>
					</div>
						
					<div class="mdl-card__supporting-text">
						<div id="infoMessage" class="mdl-color-text--red"><% =msg %></div>
							<div>
								<i class="material-symbols-outlined" style="vertical-align: middle;">person</i>
								<span class="mdl-textfield mdl-js-textfield">
									<input class="mdl-textfield__input" type="text" id="username" name="username" autocomplete="off" />
									<label class="mdl-textfield__label" for="username">Username</label>
								</span>
							</div>
							<div>
								<i class="material-symbols-outlined" style="vertical-align: middle; display: inline-block;">lock</i>
								<div class="mdl-textfield mdl-js-textfield">
									<input class="mdl-textfield__input" type="password" id="userpass" name="userpass" autocomplete="off" />
									<label class="mdl-textfield__label" for="userpass">Password</label>
								</div>
							</div>
					</div>

					<div class="mdl-card__actions mdl-card--border">
						<a id="iForgot" href="#" style="float: left; padding: 7px 0px 0px 7px;"> Forgot Password? </a>
						<button type="submit" name="submit" value="signin" style="float: right;" class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect"> Sign In </button>
					</div>
					
					<input type="hidden" id="browserWidth">
					<input type="hidden" id="browserHeight">
					<input type="hidden" id="screenWidth">
					<input type="hidden" id="screenHeight">
				</form>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
<!--
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col" style="text-align: right;">
				
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
-->
</body>

</html>