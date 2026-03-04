<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- Navigation. We hide it in small screens. -->
<nav class="mdl-navigation mdl-layout--large-screen-only">
	
	<% if lCase(session("dbName")) = "csuite" then %>
		<a class="mdl-navigation__link" href="/adminHome.asp" style="padding: 12px;"><i class="material-icons" title="Home">home</i></a>
	<% else %>
		<a class="mdl-navigation__link" href="/home.asp" style="padding: 12px;"><i class="material-icons" title="Home">home</i></a>
	<% end if %>
	
	<% if userPermitted(2) then %>

		<% if userPermitted(9) or userPermitted(10) or userPermitted(11) then %>
			<button id="adminMenu" class="mdl-navigation__link mdl-button mdl-js-button mdl-button--icon" >
				<i class="material-icons" title="Settings">settings</i>
			</button>
			<ul class="mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect" for="adminMenu">
				<li class="mdl-menu__item" onclick="location='/admin.asp'">Administration...</li>
				<% if userPermitted(9) or userPermitted(10) or userPermitted(11) then %>
					<ul>
					<% if userPermitted(9) then %><li class="mdl-menu__item" onclick="location='/userList.asp'">Users...</li><% end if %>
					<% if userPermitted(10) then %><li class="mdl-menu__item" onclick="location='/roleList.asp'">Roles...</li><% end if %>
					<% if userPermitted(11) then %><li class="mdl-menu__item" onclick="location='/permissionList.asp'">Permissions..</li><% end if %>
					</ul>
				<% end if %>
			</ul>
		<% else %>
			<a class="mdl-navigation__link" href="admin.asp" style="padding: 12px;"><i id="settingsButton" class="material-icons" title="Admin">settings</i></a>
		<% end if %>

	<% end if %>
	
	<button id="userMenu" class="mdl-navigation__link mdl-button mdl-js-button mdl-button--icon" >
		<i class="material-icons" title="User">person</i>
	</button>
	<ul class="mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect" for="userMenu">
		<li disabled class="mdl-menu__item"><% =session("firstName") & " " & session("lastName") %></li>
		<% if userPermitted(112) then %><li class="mdl-menu__item" onclick="location='/userProfile.asp'">Profile & Settings...</li><% end if %>
		<li class="mdl-menu__item">
			Client: 
			<div class="mdl-textfield mdl-js-textfield">
				<select class="mdl-textfield__input" id="clientID">
					<%
					SQL = "select distinct c.id, c.clientID, c.name, c.databaseName, cu.userDefault " &_
							"from csuite..clientUsers cu, csuite..clients c " &_
							"where cu.clientID = c.id " &_
							"and (c.startDate <= current_timestamp or c.startDate is null) " &_
							"and (c.endDate >= current_timestamp or c.endDate is null) " &_
							"and cu.userID = " & session("userID") & " " 
					set rsClient = dataconn.execute(SQL)
					while not rsClient.eof
						clientName = rsClient("name")
						if rsClient("userDefault") then 
							clientName = clientName & " (default)"
						end if
						if session("dbName") = rsClient("databaseName") then 
							selected = " selected "
						else 
							selected = ""
						end if
						%>
						<option value="<% =rsClient("databaseName") %>" data-nbr="<% =rsClient("id") %>" data-id="<% =rsClient("clientID") %>" <% =selected %>><% =clientName %></option>
						<%
						rsClient.movenext 
					wend
					rsClient.close 
					set rsClient = nothing 
					%>
				</select>
			</div>
		</li>
<!-- 		<li class="mdl-menu__item" onclick="location='/ajax/logout.asp?cmd=manual'">Logout</li> -->
		<li class="mdl-menu__item" onclick="location='login.asp?cmd=logout'">Logout</li>
	</ul>

</nav>

<script>
	
	$(document).ready( function() {
		
		$( '#clientID' ).on( 'click', function(e) {
			e.stopPropagation();
		});
	
		$( '#clientID' ).on( 'change', function(e) {

			const clientDB = $( this ).val();
			const clientName = $( this ).find( 'option:selected' ).text();
			const clientNbr = $( this ).find( 'option:selected' ).data( 'nbr' );
			const clientID = $( this ).find( 'option:selected' ).data( 'id' );
			
			$.ajax({ 
				url: `/ajax/clientSwitcher.asp?db=${clientDB}&name=${clientName}&nbr=${clientNbr}&id=${clientID}`
			})
			.done( response => {
				location = $( response ).find( 'redirect' ).text();
			})
			.fail( err => {
				log.error( 'unexpected error while switching clients...' );
				log.error( err )
			});
			
		});
		
	});	

</script>
