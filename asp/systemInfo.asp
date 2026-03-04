<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2020, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->

<% 
call checkPageAccess(17)

userLog("System Info")

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">System Controls" 
		
%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->
	
	<script type="text/javascript" src="systemInfo.js"></script>
	
	<script>
		
		//----------------------------------------------------------------------------------
		async function updateDaysAtRiskOffset( value ) {
		//----------------------------------------------------------------------------------
			
			$.ajax({
				type: 'PUT',
				url: `${apiServer}/api/systemInfo/offsetDaysAtRisk`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { value: value }
			}).done( function() {
				const notification = document.querySelector('.mdl-js-snackbar');
				notification.MaterialSnackbar.showSnackbar({ message: 'Offset updated' });
			}).fail( function( err ) {
				console.error( 'an error occurred while updating offset', err );
			});
			
		}
		//----------------------------------------------------------------------------------
		
		
		//----------------------------------------------------------------------------------
		$(document).ready( function() {
		//----------------------------------------------------------------------------------

			$( "#daysAtRiskOffset" ).spinner({
				change: async function( event, ui ) {
					const offsetValue = $(this).spinner( 'value' );
					await updateDaysAtRiskOffset( offsetValue );
				},
				spin: async function( event, ui ) {
					const offsetValue = $(this).spinner( 'value' );
					await updateDaysAtRiskOffset( offsetValue );
				}
			});
			
		});
		//----------------------------------------------------------------------------------


	</script>
	

	<style>

		a.attribution:link, a:visited {
			background-color:lightgrey;
			color: black;
			padding: 14px 25px;
			text-align: center; 
			text-decoration: none;
			display: inline-block;
		}
		
		a.attribution:hover, a:active {
			background-color: crimson;
			color: white;
		}

	</style>
	
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





	<!-- Tabs -->
	<div class="mdl-layout__tab-bar mdl-js-ripple-effect">
		<a href="#fixed-tab-about" class="mdl-layout__tab is-active">About</a>
		<a href="#fixed-tab-database" class="mdl-layout__tab">Database</a>
		<a href="#fixed-tab-session" class="mdl-layout__tab">Session Objects</a>
		<a href="#fixed-tab-application" class="mdl-layout__tab">Application Objects</a>
		<a href="#fixed-tab-system" class="mdl-layout__tab">System Controls</a>
		<% if userPermitted(56) then %><a href="#fixed-tab-server" class="mdl-layout__tab">Server Variables</a><% end if %>
		<a href="#fixed-tab-nodejs" class="mdl-layout__tab">Node.js</a>
	</div>
  </header>

	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title"><% =title %></span>
		<nav class="mdl-navigation">
			<a class="mdl-navigation__link" href="home.asp">Home</a>
			<% if userPermitted(2) then %><a class="mdl-navigation__link" href="admin.asp">Admin</a><% end if %>
			<a class="mdl-navigation__link" href="login.asp?cmd=logout">Logout</a>
		</nav>
	
	
	</div>

  <main class="mdl-layout__content">

	<div class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button type="button" class="mdl-snackbar__action"></button>
	</div>

	<br>
	
    <section class="mdl-layout__tab-panel is-active" id="fixed-tab-about">
      <div class="page-content">
			<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" align="center">
				<tbody>
					<tr>
						<td class="mdl-data-table__cell--non-numeric">Build Version</td>
						<td class="mdl-data-table__cell--non-numeric"><!-- #include file="includes/version.asp" --></td>
					</tr>
				</tbody>
			</table>
			<br><br>
			<div align="center">For best results, use one of the following browsers</div>
			<table align="center" >
				<tr>
					<td><a href="https://www.google.com/chrome/" target="_new"><img src="images\chromeLogo.jpeg" height="60" width="60"></a></td>
					<td><a href="https://www.mozilla.org/en-US/firefox/" target="_new"><img src="images\firefoxQuantumLogo.jpeg" height="60" width="60"></a></td>
					<td><a href="http://www.opera.com" target="_new"><img src="images\operaLogo.jpeg" height="60" width="60"></a></td>
					<td><a href="https://support.apple.com/en-us/HT204416" target="_new"><img src="images\safariLogo.jpeg" height="60" width="60"></a></td>
				</tr>
			</table>
			<br><br>
			<div align="center">Designed and built in Maple Grove, Minnesota<br>&copy; <% =year(date()) %> Polaris Consulting, LLC. All Rights Reserved.</div>
			<br><br>
			
		   <div class="mdl-grid"><!-- new row of grids... -->
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp" style="padding: 20px; text-align: center; font-size: large;">
					<a class="attribution" href="https://jquery.com" target="_new">jQuery</a>
				</div>
		
				<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp" style="padding: 20px; text-align: center; font-size: large;">
					<a class="attribution" href="https://datatables.net" target="_new">DataTables</a>
				</div>
		
				<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp" style="padding: 20px; text-align: center; font-size: large;">
					<a class="attribution" href="https://momentjs.com" target="_new">Moment.js</a>
				</div>
		
				<div class="mdl-layout-spacer"></div>
			
			</div>
		
		   <div class="mdl-grid"><!-- new row of grids... -->
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp" style="padding: 20px; text-align: center; font-size: large;">
					<a class="attribution" href="https://developers.google.com/chart/" target="_new">Google Visualization API</a>
				</div>
		
				<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp" style="padding: 20px; text-align: center; font-size: large;">
					<a class="attribution" href="https://quilljs.com/" target="_new">Quill.js	</a>
				</div>
		
				<div class="mdl-layout-spacer"></div>
			
			</div>
		
	   
	   
	   
	   
	   </div>
	   
	   
    </section>
    
    <section class="mdl-layout__tab-panel" id="fixed-tab-database">
      <div class="page-content">
	      <br><br>
			<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin-left: auto; margin-right: auto;">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Value</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td class="mdl-data-table__cell--non-numeric">DBMS Name (DBMS Version)</td>
						<td class="mdl-data-table__cell--non-numeric"><% =dataconn.properties("DBMS Name") %> (<% =dataconn.properties("DBMS Version") %>)</td>
					</tr>
					<tr>
						<td class="mdl-data-table__cell--non-numeric">Database Server</td>
						<td class="mdl-data-table__cell--non-numeric"><% =dataconn.properties("Server Name") %></td>
					</tr>
					<tr>
						<td class="mdl-data-table__cell--non-numeric">Database Name</td>
						<td class="mdl-data-table__cell--non-numeric"><% =dataconn.properties("Current Catalog") %></td>
					</tr>
					<tr>
						<td class="mdl-data-table__cell--non-numeric">Database Command Timeout</td>
						<td class="mdl-data-table__cell--non-numeric"><% =dataconn.CommandTimeout %></td>
					</tr>
					<tr>
						<td class="mdl-data-table__cell--non-numeric">Server Name</td>
						<td class="mdl-data-table__cell--non-numeric"><% =request.servervariables("SERVER_NAME") %></td>
					</tr>
				</tbody>
			</table>
	   </div>
    </section>
    
    <section class="mdl-layout__tab-panel" id="fixed-tab-session">
      <div class="page-content">
	      <br><br>
			<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin-left: auto; margin-right: auto;	">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Value</th>
					</tr>
				</thead>
				<tbody>
				<% for each objItem in session.Contents %>
					<tr>
						<%
						select case objItem
							
							case "userpass" 
	
								%>
								<td class="mdl-data-table__cell--non-numeric"><% =objItem %></td>
								<td class="mdl-data-table__cell--non-numeric">*******************</td>
								<%
								
							case "customerID","clientID","clientNbr","dbName"
	
								if cInt(session("userID")) = 1 then 
									%>
									<td class="mdl-data-table__cell--non-numeric"><% =objItem %></td>
									<td class="mdl-data-table__cell--non-numeric"><% =session.contents(objItem) %></td>
									<%
								end if 
	' 							
							case else 
	
								%>
								<td class="mdl-data-table__cell--non-numeric"><% =objItem %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =session.contents(objItem) %></td>
								<%
									
						end select
						%>
						<td class="mdl-data-table__cell--non-numeric"><% =name %></td>
						<td class="mdl-data-table__cell--non-numeric"><% =value %></td>
					</tr>
				<% next %>
				</tbody>
			</table>
	   </div>
    </section>
    
    <section class="mdl-layout__tab-panel" id="fixed-tab-application">
      <div class="page-content">
	      <br><br>
			<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin-left: auto; margin-right: auto;">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Value</th>
					</tr>
				</thead>
				<tbody>
				<% for each objItem in application.Contents %>
					<tr>
						<td class="mdl-data-table__cell--non-numeric"><% =objItem %></td>
						
						<% select case objItem %>
							<% case "dbug" %>
								<% if application.contents(objitem) then checked = "checked" else checked = "" end if %>
								<td class="mdl-data-table__cell--non-numeric">
								
									<label for="switch1" class="mdl-switch mdl-js-switch mdl-js-ripple-effect">
										<input type="checkbox" id="switch1" class="mdl-switch__input" onclick="ToggleDbug_onClick(this);" <% =checked %>>
									</label>
								
								</td>
								
							<% case "dbPass","dbUser" %>
								<td class="mdl-data-table__cell--non-numeric">************************</td>
							<% case else %>
							<td class="mdl-data-table__cell--non-numeric"><% =application.contents(objItem) %></td>
						<% end select %>
					</tr>
				<% next %>
				</tbody>
			</table>
	   </div>
    </section>
    
    <section class="mdl-layout__tab-panel" id="fixed-tab-system">
      <div class="page-content">
	      <br><br>
			<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin-left: auto; margin-right: auto;">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Value</th>
					</tr>
				</thead>
				<tbody>
				<%
				SQL = "select [name], [value] from systemControls order by [name] "
				set rs = dataconn.execute(SQL)
				
				while not rs.eof 
					%>
					<tr>
						<td class="mdl-data-table__cell--non-numeric"><% =rs("name") %></td>
						<td class="mdl-data-table__cell--non-numeric">
							<% 
							select case rs("name")
							case "SMTP password"
								if userPermitted(19) then 
									response.write(rs("value"))
								else 
									response.write(string(len(trim(rs("value"))),"*"))
								end if
							case "Show Footer"
								if rs("value") = "true" then checked = "checked" else checked = "" end if 
								%>
								<label for="switch_footer" class="mdl-switch mdl-js-switch mdl-js-ripple-effect">
									<input type="checkbox" id="switch_footer" class="mdl-switch__input" onclick="ToggleFooter_onClick(this);" <% =checked %>>
								</label>
								<%


							case "Use LSVT manual location/customer mapping"
								if rs("value") = "true" then checked = "checked" else checked = "" end if 
								%>
								<label for="toggleLSVT" class="mdl-switch mdl-js-switch mdl-js-ripple-effect">
									<input type="checkbox" id="toggleLSVT" class="mdl-switch__input" onclick="ToggleLSVT_onClick(this);" <% =checked %>>
								</label>
								<%


							case "Send system generated email"
								if rs("value") = "true" then checked = "checked" else checked = "" end if 
								if userPermitted(117) then 
									disabled = ""
								else 
									disabled = " disabled"
								end if
								%>
								<label for="switch_email" class="mdl-switch mdl-js-switch mdl-js-ripple-effect">
									<input type="checkbox" id="switch_email" class="mdl-switch__input" onclick="ToggleEmail_onClick(this);" <% =checked %> <% =disabled %>>
								</label>
								<%
									
							case "Work days at risk offset"
								%>
								<label for="daysAtRiskOffset">Select a value:</label>
								<input id="daysAtRiskOffset" name="value">
								<script>
									var spinner = $( "#daysAtRiskOffset" ).spinner();
									$( "#daysAtRiskOffset" ).spinner( "value", <% =rs("value") %> );

									
								</script>				
								<%
							case else
								response.write(rs("value"))
							end select 
							%>
						</td>
					</tr>
					<% 
					rs.movenext 
				wend
				rs.close 
				set rs = nothing
				%>
				</tbody>
			</table>
			<br><br>
	   </div>
    </section>

   <% if userPermitted(56) then %>
    <section class="mdl-layout__tab-panel" id="fixed-tab-server">
      <div class="page-content">
	      <br><br>

			<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin-left: auto; margin-right: auto; table-layout:fixed; width: 600px;">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Value</th>
					</tr>
				</thead>
				<tbody>
				<% for each field in request.ServerVariables %>
					<% select case field %>
					<% case "ALL_HTTP","ALL_RAW","HTTP_COOKIE" %>
					<% case else %>
						<tr>
							<td class="mdl-data-table__cell--non-numeric"><% =field %></td>
							<td class="mdl-data-table__cell--non-numeric" style="overflow: hidden; text-overflow: ellipsis; width: 400px; word-break: break-all;" title="<% =request.ServerVariables(field) %>"><% =request.ServerVariables(field) %></td>
						</tr>
					<% end select %>
				<% next %>
				</tbody>
			</table>
	
			<br><br>
	   </div>
    </section>
    <% end if %>


    <section class="mdl-layout__tab-panel" id="fixed-tab-nodejs"></section>

    
  </main>
	<!-- #include file="includes/pageFooter.asp" -->
</div>

<% 
dataconn.close
set dataconn = nothing
%>
</body>
</html>