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
<!-- #include file="includes/validUserDomain.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(15)


startTime = timer 

if len(request.querystring("id")) > 0 then 

	userID = request.querystring("id") 
	
	if cInt(userID) = cInt(session("userID")) then 
		
		if userPermitted(98) then 
			
			mode = "edit"
			disabled = ""

		else 
		
			mode = "view"
			disabled = " disabled" 
			popupMessage = "WARNING: You cannot edit your own user account."
			
		end if
		
	else 
	
		if userPermitted(15) then 
			mode = "edit"
			disabled = ""
		elseif userPermitted(58) then
			mode = "view"
			disabled = " disabled"
		else 
			response.clear()
			response.write("Access Denied")
			response.end() 
		end if
		
	end if 

else 
	
	userID = ""
	mode = "view" 
	disabled = "disabled" 	
	
	popupMessage = "ERROR: Internal error; please contact system administrator."

end if 

dbug("mode=" & mode)
userLog("User edit, mode=" & mode)

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""userList.asp?"">Users</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Edit A User" 

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	userID = request.querystring("id")
	
' 	SQL = "select users.*, customer.name as customerName " &_
' 			"from cSuite..users " &_
' 			"left join customer_view on (customer.id = users.customerID) " &_
' 			"where users.id = " & userID & " "

	SQL = "select " &_
				"u.id, " &_
				"u.username, " &_
				"u.firstName, " &_
				"u.lastName, " &_
				"u.laborRate, " &_
				"u.title, " &_
				"u.active, " &_
				"u.locked, " &_
				"u.resetPasswordOnLogin, " &_
				"u.lastLoginDate " &_
			"from cSuite..users u "
			
	if lcase(session("dbName")) <> "csuite" then 
		SQL = SQL &_
			"where exists ( " &_
				"select * " &_
				"from csuite..clientUsers cu " &_
				"join csuite..clients c on (c.id = cu.clientID and c.databaseName = '" & session("dbName") & "') " &_
				"where  cu.userID = u.id " &_
			") " &_
			"and u.id = " & userID & " " 
	else 
		SQL = SQL &_
			"where u.id = " & userID & " " 
	end if 
	
		
	dbug(SQL)
	startUsers = timer 
	set rsUsers = dataconn.execute(SQL)
	dbug("rsUsers objected successfully created")
	
	if not rsUsers.eof then
		dbug("not rsUsers.eof")
		dbug("rsUsers('username'): " & rsUsers("username"))
	else
		dbug("rsUsers.eof")
		if userPermitted(9) then 
			response.redirect "userList.asp"
		else 
			if userPermitted(2) then 
				response.redirect "admin.asp" 
			else 
				response.write("User not found on this client, redirect not possible due to permissions")
			end if 
		end if
	end if
	endUsers = timer

end if


dbug("after top-logic")
%>





<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	
	<script src="list.min.js"></script>
	<script type="text/javascript" src="userEdit.js"></script>

	<script>

		const params = new Proxy(new URLSearchParams(window.location.search), {
			get: (searchParams, prop) => searchParams.get(prop),
		});
		
		//================================================================================
		$(document).ready(function() {
		//================================================================================

			$( document ).tooltip();
			
			
			//-----------------------------------------------------------------------------
			var userClients_dt = $( '#userClients' )					
			//-----------------------------------------------------------------------------
				.DataTable({
			//-----------------------------------------------------------------------------
					ajax: {
						url: `${apiServer}/api/userClients`,
						data: { userID: params.id },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columnDefs: [
						{
							targets: 'checkbox',
							data: 'isChecked',
							className: 'checkbox dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( data ) {
									return `<span class="material-symbols-outlined">select_check_box</span>`;
								} else {
									return `<span class="material-symbols-outlined">check_box_outline_blank</span>`;
								}
							}
						},
						{ targets: 'clientName', data: 'clientName', className: 'clientName dt-body-left' },
						{
							targets: 'default',
							data: 'isDefault',
							className: 'default dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( data ) {
									return `<span class="material-symbols-outlined">radio_button_checked</span>`;
								} else {
									return `<span class="material-symbols-outlined">radio_button_unchecked</span>`;
								}
							}
						},
						{
							targets: 'internal',
							data: 'isInternal',
							className: 'internal dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( data ) {
									return `<span class="material-symbols-outlined">check</span>`;
								} else {
									return ``;
								}
							}
						},
						{
							targets: 'external',
							data: 'isExternal',
							className: 'external dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( data ) {
									return `<span class="material-symbols-outlined">check</span>`;
								} else {
									return ``;
								}
							}
						},
					],
					rowId: 'clientID',
					scroller: { rowHeight: 38 },
					scrollCollapse: true,
					scrollY: 400,
					searching: false,
					order: [[ 1, 'asc' ]],
				})
				.on( 'click', 'tbody > tr > td.checkbox', function( event ) {
					event.stopPropagation();
					let clientID = $( this ).closest( 'tr' ).prop( 'id' );
					
					if ( $( this ).find( 'span' ).html() === 'select_check_box' ) {
						
						$.ajax({
							url: `${apiServer}/api/userClients`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {clientID: clientID, userID: params.id },
							type: 'delete',
						}).done( function() {

							let customerNode = $( '#userClients' ).DataTable().row( '#'+clientID ).node();
							$( customerNode ).find( 'td.checkbox span' ).html( 'check_box_outline_blank' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Client removed'
							});

						}).fail( function( err ) {
							console.error( err );
							console.log( 'an error occurred while deleting userClient' );
						});
						
					} else {

						$.ajax({
							url: `${apiServer}/api/userClients`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {clientID: clientID, userID: params.id },
							type: 'put',
						}).done( function() {

							let customerNode = $( '#userClients' ).DataTable().row( '#'+clientID ).node();
							$( customerNode ).find( 'td.checkbox span' ).html( 'select_check_box' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Client added'
							});

						}).fail( function() {
							console.log( 'an error occurred while adding userClients' );
						});

					}
					
				})
				.on( 'click', 'tbody > tr > td.default', function( event ) {
					event.stopPropagation();
					
					let clientID = $( this ).closest( 'tr' ).prop( 'id' );
					
					//reset all the radio buttons to unselected...
					$( '#userClients' ).find( 'td.default span' ).html( 'radio_button_unchecked' );
					
					//set "this" radio button to selected...
					$( this ).find( 'span' ).html( 'radio_button_checked' );
					
					//update database via ajax...
					$.ajax({
						url: `${apiServer}/api/userClients/setUserDefault`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						data: {clientID: clientID, userID: params.id },
						type: 'put',
					}).done( function() {

						let clientNode = $( '#userClients' ).DataTable().row( '#'+clientID ).node();
						$( clientNode ).find( 'td.default span' ).html( 'radio_button_checked' ).effect( 'pulsate' );

						document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
							message: 'Default client updated'
						});

					}).fail( function( err ) {
						console.error( err );
						console.log( 'an error occurred while updating default client' );
					});

				});

			//-----------------------------------------------------------------------------
			var userCustomers_dt = $( '#userCustomers' )
			//-----------------------------------------------------------------------------
				.DataTable({

					ajax: {
						url: `${apiServer}/api/userCustomers`,
						data: { userID: params.id },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columnDefs: [
						{
							targets: 'checkbox',
							data: 'associatedCustomer',
							className: 'checkbox dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( !row.customerDisabled ) {
									if ( data ) {
										return `<span class="material-symbols-outlined">select_check_box</span>`;
									} else {
										return `<span class="material-symbols-outlined">check_box_outline_blank</span>`;
									}
								} else {
									return '';
								}
							}
						},
						{ targets: 'name', data: 'name', className: 'roleName dt-body-left' },
						{
							targets: 'info',
							className: 'info dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
	
								if ( row.titleText ) {
									return `<span class="material-symbols-outlined" title="${row.titleText}">warning</span>`;
								} else {
									return ``;
								}
							}
						},
					],
					language: { search: 'Search Customers:' },
					rowId: 'customerID',
					scroller: { rowHeight: 38 },
					scrollCollapse: true,
					scrollY: 400,
					order: [[ 1, 'asc' ]],
				})
				.on( 'click', 'tbody > tr > td.checkbox', function( event ) {
					event.stopPropagation();
					let customerID = $( this ).closest( 'tr' ).prop( 'id' );
					
					if ( $( this ).find( 'span' ).html() === 'select_check_box' ) {
						
						$.ajax({
							url: `${apiServer}/api/userCustomers`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {customerID: customerID, userID: params.id },
							type: 'delete',
						}).done( function() {

							let customerNode = $( '#userCustomers' ).DataTable().row( '#'+customerID ).node();
							$( customerNode ).find( 'td.checkbox span' ).html( 'check_box_outline_blank' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Customer removed'
							});

						}).fail( function() {
							console.log( 'an error occurred while deleting userCustomers' );
						});
						
					} else {

						$.ajax({
							url: `${apiServer}/api/userCustomers`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {customerID: customerID, userID: params.id },
							type: 'put',
						}).done( function() {

							let customerNode = $( '#userCustomers' ).DataTable().row( '#'+customerID ).node();
							$( customerNode ).find( 'td.checkbox span' ).html( 'select_check_box' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Customer added'
							});

						}).fail( function() {
							console.log( 'an error occurred while adding userCustomers' );
						});

					}
					
				});
			
			//-----------------------------------------------------------------------------


			//-----------------------------------------------------------------------------
			var userRoles_dt = $( '#userRoles' )
			//-----------------------------------------------------------------------------
				.DataTable({
					ajax: {
						url: `${apiServer}/api/userRoles`,
						data: { userID: params.id },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columnDefs: [
						{
							targets: 'checkbox',
							className: 'checkbox dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( row.userID ) {
									return `<span class="material-symbols-outlined">select_check_box</span>`;
								} else {
									return `<span class="material-symbols-outlined">check_box_outline_blank</span>`;
								}
							},
						},
						{ targets: 'roleName', data: 'roleName', className: 'roleName dt-body-left' },
					],
					rowId: 'roleID',
					scroller: { rowHeight: 38 },
					scrollCollapse: true,
					scrollY: 400,
					searching: false,
					order: [[ 1, 'asc' ]],
				})
				.on( 'click', 'tbody > tr', function(event) {
					var roleID = this.id;
					window.location.href = 'roleEdit.asp?id='+roleID;
				})
				.on( 'click', 'tbody > tr > td.checkbox', function( event ) {
					event.stopPropagation();
					$( '.highlight' ).removeClass( 'highlight' );					
					let roleID = $( this ).closest( 'tr' ).prop( 'id' );
					
					if ( $( this ).find( 'span' ).html() === 'select_check_box' ) {
						
						$.ajax({
							url: `${apiServer}/api/userRoles`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {roleID: roleID, userID: params.id },
							type: 'delete',
						}).done( function() {

							let roleNode = $( '#userRoles' ).DataTable().row( '#'+roleID ).node();
							$( roleNode ).find( 'td.checkbox span' ).html( 'check_box_outline_blank' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Role removed'
							});

						}).fail( function() {
							console.log( 'an error occurred while deleting userRoles' );
						});
						
					} else {

						$.ajax({
							url: `${apiServer}/api/userRoles`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {roleID: roleID, userID: params.id },
							type: 'put',
						}).done( function() {

							let roleNode = $( '#userRoles' ).DataTable().row( '#'+roleID ).node();
							$( roleNode ).find( 'td.checkbox span' ).html( 'select_check_box' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Role added'
							});

						}).fail( function() {
							console.log( 'an error occurred while adding userRoles' );
						});

					}
					
/* 					$( '#userPermissions' ).DataTable().ajax.reload(); */
					
				});
				
				 userRoles_dt.columns.adjust().draw();
			
			//-----------------------------------------------------------------------------


			//-----------------------------------------------------------------------------
			var userPermissions_dt = $( '#userPermissions' )
			//-----------------------------------------------------------------------------
				.DataTable({
					ajax: {
						url: `${apiServer}/api/userPermissions`,
						data: { userID: params.id },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columnDefs: [
						{
							targets: 'direct',
							data: 'direct',
							className: 'direct dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( data ) {
									return `<span class="material-symbols-outlined">select_check_box</span>`;
								} else {
									return `<span class="material-symbols-outlined">check_box_outline_blank</span>`;
								}
							},
						},
						{
							targets: 'indirect',
							data: 'indirect',
							className: 'indirect dt-body-center',
							orderable: false,
							render: function( data, type, row ) {
								if ( data ) {
									return `<span class="material-symbols-outlined">check</span>`;
								} else {
									return ``;
								}
							}
						},
						{ targets: 'name', data: 'name', className: 'name dt-body-left' },
					],
					createdRow: function( row, data, dataIndex ) {
						if ( data.description ) {
							$( row ).find( '.name' ).prop( 'title', data.description );
						}
					},
					language: { search: 'Search Permissions:' },
					rowId: 'permissionID',
					scroller: { rowHeight: 41 },
					scrollCollapse: true,
					scrollY: 650,
					order: [[ 1, 'asc' ]],
				})	
				.on( 'click', 'tbody > tr', function(event) {
					const permissionID = this.id;
					window.location.href = 'permissionEdit.asp?id='+permissionID;
				})
				.on( 'click', '.indirect', async function(event) {


					event.stopPropagation();
					
					const permissionID = $( this ).closest( 'tr' ).prop( 'id' );
					
					if ( $( this ).hasClass( 'highlight' ) ) {
						$( '.highlight' ).removeClass( 'highlight' );					
					} else {
						$( '.highlight' ).removeClass( 'highlight' );
						
						if ( $( this ).html() ) {
				
							$( this ).addClass( 'highlight' );
							
							$.ajax({
								url: `${apiServer}/api/userPermissions/inheritedFromRole`,
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								data: {permissionID: permissionID, userID: params.id },
							}).done( function( roles ) {
								
								for ( role of roles ) {
									let roleNode = $( '#userRoles' ).DataTable().row( '#'+role.roleID ).node();
									$( roleNode ).find( 'td.roleName' ).addClass( 'highlight' );
								}
		
							}).fail( function() {
								console.log( 'an error occurred while getting ancestor roles' );
							});
							
						}
						
					}
					


				})
				.on( 'click', 'tbody > tr > td.direct', function( event ) {
					event.stopPropagation();
					$( '.highlight' ).removeClass( 'highlight' );					
					let permissionID = $( this ).closest( 'tr' ).prop( 'id' );
					
					if ( $( this ).find( 'span' ).html() === 'select_check_box' ) {
						
						$.ajax({
							url: `${apiServer}/api/userPermissions`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {permissionID: permissionID, userID: params.id },
							type: 'delete',
						}).done( function() {

							let roleNode = $( '#userPermissions' ).DataTable().row( '#'+permissionID ).node();
							$( roleNode ).find( 'td.direct span' ).html( 'check_box_outline_blank' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Permission removed'
							});

						}).fail( function() {
							console.log( 'an error occurred while deleting userPermissions' );
						});
						
					} else {

						$.ajax({
							url: `${apiServer}/api/userPermissions`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							data: {permissionID: permissionID, userID: params.id },
							type: 'put',
						}).done( function() {

							let roleNode = $( '#userPermissions' ).DataTable().row( '#'+permissionID ).node();
							$( roleNode ).find( 'td.direct span' ).html( 'select_check_box' ).effect( 'pulsate' );

							document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
								message: 'Permission added'
							});

						}).fail( function() {
							console.log( 'an error occurred while adding userPermissions' );
						});

					}
				});
			
			//-----------------------------------------------------------------------------



		});
		//================================================================================
		//================================================================================


	</script>
	
	<style>
		
		tr {
			height: 38px;
			cursor: pointer;
		}
		
		.highlight {
			background-color: orange;
		}
		
		#userRoles tr th.roleNam {
			text-align: left;
		}
		
	</style>

</head>

<body>

<!-- <form action="userEdit.asp" method="POST" name="userEdit" id="userEdit"> -->

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
		<!-- Your content goes here -->

		<div id="snackbar" class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button type="button" class="mdl-snackbar__action"></button>
		</div>

		<!-- user detail infor -->
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="username" value="<% =server.htmlEncode(trim(rsUsers("username"))) %>" disabled>
				    <label class="mdl-textfield__label" for="username">Username / Email...</label>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="firstName" name="firstName" value="<% =trim(rsUsers("firstName")) %>" onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
				    <label class="mdl-textfield__label" for="firstName">First name...</label>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="lastName" name="lastName" value="<% =trim(rsUsers("lastName")) %>" onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
				    <label class="mdl-textfield__label" for="lastName">Last name...</label>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="laborRate" name="laborRate" value="<% =trim(rsUsers("laborRate")) %>" onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
				    <label class="mdl-textfield__label" for="lastName">Labor rate per hour...</label>
				</div>

			</div>



			<div class="mdl-cell mdl-cell--3-col">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="title" name="title" value="<% =trim(rsUsers("title")) %>" onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
				    <label class="mdl-textfield__label" for="title">Title...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="lastLoginDate" name="lastLoginDate" value="<% =trim(rsUsers("lastLoginDate")) %>" disabled>
				    <label class="mdl-textfield__label" for="lastLoginDate">Last login...</label>
				</div>


			</div>





			<div class="mdl-cell mdl-cell--3-col">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="active">
						<input type="checkbox" id="active" name="active" class="mdl-switch__input" <% if rsUsers("active") then response.write("checked") end if %> onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
						<span class="mdl-switch__label">Active?</span>
					</label>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="locked">
						<input type="checkbox" id="locked" name="locked" class="mdl-switch__input" <% if rsUsers("locked") then response.write("checked") end if %> onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
						<span class="mdl-switch__label">Locked?</span>
					</label>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="resetPasswordOnLogin">
						<input type="checkbox" id="resetPasswordOnLogin" name="resetPasswordOnLogin" class="mdl-switch__input" <% if rsUsers("resetPasswordOnLogin") then response.write("checked") end if %> onchange="userAttribute_onChange(this,<% =userID %>)" <% =disabled %>>
						<span class="mdl-switch__label">Reset password on next login?</span>
					</label>
				</div>

				<br>
				<%
				dbug(" ")
				dbug("checking internalUser indicator...")
				if lCase(session("dbName")) <> "csuite" then 
					SQL = "select * from userCustomers where userID = " & userID & " and customerID = 1 " 
					set rsIntUsr = dataconn.execute(SQL) 
					if not rsIntUsr.eof then 
						dbug("internalUser = true; user associated with customerID = 1")
						internalUser = true
						checked = "checked"
						if validUserDomain(rsUsers("username"), 1, session("clientDB")) then 
							dbug("validUserDomain(1) is true")
							if userPermitted(106) then 
								internalUserDisabled = ""
							else 
								internaluserDisabled = " disabled "
							end if
							internalUserColor 	= "black"
							internalUserIcon 		= "info"
							internalUserTitle 	= "User domain is valid for client"
						else 
							dbug("validUserDomain(1) is false")
							internalUserColor = "crimson"
							internalUserIcon = "warning"
							if userPermitted(59) then 
								dbug("current user has override permission")
								if userPermitted(106) then 
									internalUserDisabled = ""
								else 
									internaluserDisabled = " disabled "
								end if
								internalUserTitle 	= "User domain is not valid for client but you have permission to override"
							else 
								dbug("current user does not have override permission")
								internalUserDisabled = " disabled "
								internalUserTitle 	= "User domain is not valid for client"
							end if 
						end if 
					else 
						dbug("internalUser = false; user is not associated with customerID = 1")
						checked = ""
						internalUser = false
						if validUserDomain(rsUsers("username"), 1, session("clientDB")) then 
							dbug("validUserDomain(2) is true")
							if userPermitted(106) then 
								internalUserDisabled = ""
							else 
								internaluserDisabled = " disabled "
							end if
							internalUserColor 	= "black"
							internalUserIcon 		= "info"
							internalUserTitle 	= "User domain is valid for client"
						else 
							dbug("validUserDomain(2) is false")
							internalUserColor 	= "crimson"
							internalUserIcon 		= "warning"
							if userPermitted(59) then 
								dbug("current user has override permission")
								if userPermitted(106) then 
									dbug("current user has 'make internal' permission")
									internalUserDisabled = ""
								else 
									dbug("current user DOES NOT HAVE 'make internal' permission")
									internalUserDisabled = " disabled " 
								end if 
								internalUserTitle 	= "User domain is not valid for client but you have permission to override"
							else 
								dbug("current user does not have override permission")
								internalUserDisabled = " disabled "
								internalUserTitle 	= "User domain is not valid for client"
							end if 
						end if 
					end if
					rsIntUsr.close 
					set rsIntUsr = nothing
					dbug(" ")
					%>
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="position: relative; color: <% =internalUserColor %>">
						<i class="material-icons" style="top: 20px; right: 100px; z-index: 100; position: absolute;" title="<% =internalUserTitle %>"><% =internalUserIcon %></i>
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="internalUser">
							<input type="checkbox" id="internalUser" class="mdl-switch__input" <% =checked %> <% =internalUserDisabled %>>
							<span class="mdl-switch__label">Internal (client)?</span>
						</label>
					</div>
					<%
				end if 
				%>
					

			</div>			
			<div class="mdl-layout-spacer"></div>
		</div>

		<hr>

		<!-- This grid is where associated clients, customers, roles, and permissions are shown  -->
		<div class="mdl-grid">
			
			<div class="mdl-layout-spacer"></div>

			<% if lCase(session("dbName")) = "csuite" then %>
				
				<!-- Clients -->
				<div class="mdl-cell mdl-cell--3-col" style="padding-top: 27px;">
					
					<table id="userClients" class="display compact">
						<thead>
							<tr>
								<th class="checkbox"></th>
								<th class="clientName">Clients</th>
								<th class="default">Default</th>
								<th class="internal">Internal</th>
								<th class="external">External</th>
							</tr>
						</thead>
					</table>
					
				</div>
				<div class="mdl-layout-spacer"></div>

			<% else %>
			
				<%
				' Only show the list of customers when the user is not already marked "internal"
				dbug("internalUser: " & internalUser)
				if internalUser  then 
					display = "none" 
				else 
					dislpay = "block" 
				end if 
				%>

				<!-- Customers -->
				<div id="customersContainer" class="mdl-cell mdl-cell--3-col" style="display: <% =display %>;">
					
					<table id="userCustomers" class="compact display">
						<thead>
							<tr>
								<th class="checkbox"></th>
								<th class="name">Customers</th>
								<th class="info" title="Hover over an icon in this column to see additional information about the customer."><span class="material-symbols-outlined">info</span></th>
							</tr>
						</thead>
					</table>
								
				</div>
				<div class="mdl-layout-spacer" style="display: <% =display %>;"></div>


			
			<% end if %>

			<!-- Roles -->
			<div class="mdl-cell mdl-cell--2-col" style="padding-top: 27px;">

				<table id="userRoles" class="compact display" width="100%">
					<thead>
						<tr>
							<th class="checkbox">&nbsp;</th>
							<th class="roleName">Roles</th>
						</tr>
					</thead>
				</table>
					
			</div>
			<div class="mdl-layout-spacer"></div>


			<!-- Permissions -->
			<div class="mdl-cell mdl-cell--5-col">

				<table id="userPermissions" class="compact display">
					<thead>
						<tr>
							<th class="direct"></th>
							<th class="name">Permissions</th>
							<th class="indirect" title="If checked, the user has the permission granted via one or more roles; click on a check mark to higlight the role(s) from which the permission is inherited.">Inherited</th>
						</tr>
					</thead>
				</table>

			</div>
			<div class="mdl-layout-spacer"></div>
			
		</div>
	</div>

</main>


<%
rsUsers.close 
set rsUsers = nothing 
%>



<!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>