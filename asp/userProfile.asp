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
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(112)
	
'====================================================================================================
'= NOTE: to prevent elements from "flashing" while the page is rendering, simply give them a class
'= of "hiddenObject" and style of "display: none". The existing code will take care of the rest.
'=
'= This is especially useful for HTML elements that are on the non-default tabs
'====================================================================================================

	
title = session("clientID") & " - " & "User Profile" 
userLog(title)
%>

<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	<script src="userProfile.js"></script>
	<script src="md5.min.js"></script>

	<script>

		const params = new Proxy(new URLSearchParams(window.location.search), {
			get: (searchParams, prop) => searchParams.get(prop),
		});

		//================================================================================
		function updateUserProfileOptions() {
		//================================================================================


			const showFooter = $( '#showFooter' ).parent().is( ':checked' ) ? '1' : '0';
			const showClassicCustomerMenu = $( '#showClassicCustomerMenu' ).parent().is( ':checked' ) ? '1' : '0';
			const newMenuStyle = $('input[type=radio][name=menuOption]').val();

			console.log( 'before update:', { showFooter, showClassicCustomerMenu, newMenuStyle });
			$.ajax({
				url: `${apiServer}/api/users/profile/CustomerMenuOptions`,
				data: { 
					showFooter: showFooter,
					showClassicCustomerMenu: showClassicCustomerMenu,
					newMenuStyle: newMenuStyle
				 },
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				type: 'put'
			}).done( response => {
				console.log( 'update successful' );
			}).fail( err => {
				console.log( 'an error occurred while updateUserProfileOptions' );
			});
			
		}
		//================================================================================
		

		//================================================================================
		$(document).ready(function() {
		//================================================================================

			const toast = $( '#toast' ).get(0);

// 			//--------------------------------------------------------------------------
// 			$.ajax({
// 			//--------------------------------------------------------------------------
// 				url: `${apiServer}/api/users/profile/CustomerMenuOptions`,
// 				data: { option: $( this ).val() },
// 				headers: { 'Authorization': 'Bearer ' + sessionJWT },
// 			}).done( response => {
// 				
// 				console.log( 'after get: ', response );
// 
// 				if ( response.showFooter ) {
// 					$( '#showFooter' ).parent()[0].MaterialSwitch.on();
// 				} else {
// 					$( '#showFooter' ).parent()[0].MaterialSwitch.off();
// 				}
// 				
// 				if ( response.showClassicCustomerMenu ) {
// 
// 					$( '#showClassicCustomerMenu' ).parent()[0].MaterialSwitch.on();					
// 					$( '#menuOptionsContainer' ).hide();
// 
// 				} else {
// 
// 					$( '#showClassicCustomerMenu' ).parent()[0].MaterialSwitch.off();					
// 					$( '#menuOptionsContainer' ).show();
// 
// 					if ( response.newMenuStyle ) {
// 						console.log( 'newMenuStyle: ' + response.newMenuStyle );
// 					} else {
// 						console.log( 'null - newMenuStyle: ' + response.newMenuStyle );
// 					}
// 
// 				}
// 				
// 				if ( [ 0, 1, 2 ].includes( response.newMenuStyle ) ) {
// 					
// 					const $radioButton = $( 'input[type=radio][name=menuOption]' ).filter( `[value=${response.newMenuStyle}]` );
// 					
// 					$radioButton.parent().get(0).MaterialRadio.check();			
// 
// 				}
// 				
// 				
// 				
// 			}).fail( err => {
// 				console.log( 'an error occurred while getting customer menu options' );
// 			});
// 			//--------------------------------------------------------------------------



// 			//--------------------------------------------------------------------------
// 			$( '#showClassicCustomerMenu' ).on( 'change', function() {
// 			//--------------------------------------------------------------------------
// 
// 				$.post({
// 					url: `${apiServer}/api/users/profile/toggleClassicCustomerMenu`,
// 					headers: { 'Authorization': 'Bearer ' + sessionJWT },
// 				}).done( response => {
// 					
// 					if ( $( '#showClassicCustomerMenu' ).parent().hasClass( 'is-checked' ) ) {
// 						$( '#menuOptionsContainer' ).hide();
// 					} else {
// 						$( '#menuOptionsContainer' ).show();
// 					}
// 
// 					toast.MaterialSnackbar.showSnackbar({ message: 'Show classic customer menu udpated' });
// 
// 				}).fail( function() {
// 					console.log( 'an error occurred while updating showClassicCustomerMenu' );
// 				});
// 				
// 			});
// 			//--------------------------------------------------------------------------
// 			
// 			
// 			
			//--------------------------------------------------------------------------
			$( '#showFooter' ).on( 'change', function() {
			//--------------------------------------------------------------------------
	
				$.post({ 
					url: `${apiServer}/api/users/profile/togglePageFooter`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				}).done( response => {
					toast.MaterialSnackbar.showSnackbar({ message: 'Show page footer udpated' });
				}).fail( err => {
					console.log( 'an error occurred while updating UserProfileOptions' );
				});
				
			});
			//--------------------------------------------------------------------------


			//--------------------------------------------------------------------------
			$( 'input[type=radio][name=menuOption]' ).on( 'change', function() {
			//--------------------------------------------------------------------------
	
				const menuOption = $( this ).val();
				
				$.post({ 
					url: `${apiServer}/api/users/profile/menuOption`,
					data: { menuOption: menuOption },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				}).done( response => {
					toast.MaterialSnackbar.showSnackbar({ message: 'Menu option udpated' });
				}).fail( err => {
					console.log( 'an error occurred while updating menu option' );
				});
				
			});
			//--------------------------------------------------------------------------


		});
		//================================================================================
		//================================================================================
		//================================================================================
		//================================================================================

	</script>
	
	<style>
		
	</style>
	
</head>

<body onload="unhideObjects()">

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">


		<div id="toast" class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>

		<!-- DIALOG: Change password -->
		<dialog id="changePasswordDialog" class="mdl-dialog">
			<div class="mdl-dialog__content">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="password" id="oldPassword">
				    <label class="mdl-textfield__label" for="oldPassword">Old password...</label>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="password" id="newPassword">
				    <label class="mdl-textfield__label" for="newPassword">New password...</label>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="password" id="confirmPassword">
				    <label class="mdl-textfield__label" for="confirmPassword">New password (again)...</label>
				</div>
				
			</div>
			<div class="mdl-dialog__actions">
				<button type="button" class="mdl-button okay">Save</button>
				<button type="button" class="mdl-button close">Cancel</button>
			</div>
		</dialog>

		

		<div class="page-content">
		<!-- Your content goes here -->
		
		<div class="mdl-tabs mdl-js-tabs mdl-js-ripple-effect">
			
			<div class="mdl-tabs__tab-bar">
				<a href="#profile-panel" 		class="mdl-tabs__tab is-active">Profile</a>
				<a href="#access-panel" 	class="mdl-tabs__tab">Clients/Customers</a>
			</div>
			<br><br>
		
			<div class="mdl-tabs__panel is-active" id="profile-panel">

			   <div class="mdl-grid">
			
					<div class="mdl-layout-spacer"></div>
			
					<div class="mdl-cell mdl-cell--3-col">
						
						<%
						SQL = "select * from csuite..users where id = " & session("userID") & " " 
						set rsUsr = dataconn.execute(SQL) 
						%>

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
							<input class="mdl-textfield__input" type="text" id="username" value="<% =rsUsr("username") %>" disabled>
							<label class="mdl-textfield__label" for="username">User name...</label>
						</div>			
						
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
							<input class="mdl-textfield__input" type="text" id="firstName" value="<% =rsUsr("firstName") %>">
							<label class="mdl-textfield__label" for="firstName">First name...</label>
						</div>			
						
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
							<input class="mdl-textfield__input" type="text" id="lastName" value="<% =rsUsr("lastName") %>">
							<label class="mdl-textfield__label" for="lastName">Last name...</label>
						</div>			
						
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
							<input class="mdl-textfield__input" type="text" id="title" value="<% =rsUsr("title") %>">
							<label class="mdl-textfield__label" for="title">Title...</label>
						</div>			
						
						<% if userPermitted(116) then %>
							<% if rsUsr("showFooter") then %>
								<% checked = "checked" %>
							<% else %>
								<% checked = "" %>
							<% end if %>
						<div style="padding-top: 15px; padding-bottom: 15px;">
							<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="showFooter"> 
								<input type="checkbox" id="showFooter" class="mdl-switch__input" <% =checked %>>
								<span class="mdl-switch__label">Show page footer?</span>
							</label>
						</div>
						<% end if %>


						<%
						rsUsr.close 
						set rsUsr = nothing 
						%>
						
						<br><br>
						<!-- Accent-colored raised button with ripple -->
						<button id="saveButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="width: 100%;">
							Save
						</button>


					</div>
			
					<div class="mdl-cell mdl-cell--2-col">

						<div class="controlContainer" style="height: 67.5px; padding: 16 0 16 0;">
							<button id="changePasswordButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
								Change Password
							</button>
						</div>
						



					</div>

					<div class="mdl-layout-spacer"></div>
			
				</div>

			</div><!-- profile (username, first name, last name, title -->

			<div class="mdl-tabs__panel" id="access-panel">

			   <div class="mdl-grid">
			
					<div class="mdl-layout-spacer"></div>
			
					<div class="mdl-cell mdl-cell--3-col">
						<div style="margin-left: auto; margin-right: auto;">
						
						<%
						SQL = "select c.id, c.name, cu.userID, c.databaseName " &_
								"from csuite..clients c " &_
								"join csuite..clientUsers cu on (cu.clientID = c.id) " &_
								"where cu.userID = " & session("userID") & " " &_
								"order by c.name "

						set rsClients = dataconn.execute(SQL) 
						
						while not rsClients.eof 
							%>
							<h4 class="hiddenObject" style="display: none;"><% =rsClients("name") %></h4>

							<ul class="hiddenObject" style="display: none;">
							<% 
							if rsClients("databaseName") = "csuite" then 
								%>
								<li>Not Applicable</li>
								<% 
							else 
								SQL = "select c.id, c.name " &_
										"from " & rsClients("databaseName") & "..userCustomers uc " &_
										"join " & rsClients("databaseName") & "..customer c on (c.id = uc.customerID) " &_
										"where uc.userID = " & session("userID") & " " &_
										"order by name "
								dbug(SQL)
								set rsCust = dataconn.execute(SQL) 

								while not rsCust.eof 
									if cInt(rsCust("id")) = 1 then 
										internal = " (internal user) " 
									else 
										internal = ""
									end if 
									%>
									<li><% =rsCust("name") & internal %></li>
									<%
									rsCust.movenext 
								wend 
								rsCust.close 
								set rsCust = nothing 
						
							end if
							
							%>
							</ul>
							<%
							
							rsClients.movenext 
							
						wend
						
						rsClients.close 
						set rsClients = nothing 

						%>

					</div>
					</div>
										
					<div class="mdl-cell mdl-cell--3-col">

						<h4 class="hiddenObject" style="display: none;">Default Client</h4>
						<%	
						SQL = "select c.id, c.name, cu.userDefault " &_
								"from csuite..clients c " &_
								"join csuite..clientUsers cu on (cu.clientID = c.id) " &_
								"where cu.userID = " & session("userID") & " " &_
								"order by c.name "
						set rsClients = dataconn.execute(SQL) 
						if not rsClients.eof then 
							%>
							<table class="hiddenObject" style="margin-left: auto; margin-right: auto; display: none;">
								<tbody>
								<%	
								while not rsClients.eof 
									if not isNull(rsClients("userDefault")) then 
										clientChecked = "checked"
									else 
										clientChecked = ""
									end if 
									%>
									<tr>
										<td>
											<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="option-<% =rsClients("id") %>">
												<input type="radio" id="option-<% =rsClients("id") %>" class="mdl-radio__button" name="defaultClient" data-userID="<% =session("userID") %>" value="<% =rsClients("id") %>" <% =clientChecked %>>
												<span class="mdl-radio__label"><% =rsClients("name") %></span>
											</label>									
										</td>
									</tr>
									<%
									rsClients.movenext 
								wend 
								rsClients.close 
								set rsClients = nothing 
								%>
								</tbody>
							</table>
							<%
						end if 
						%>
	
					</div>

					<div class="mdl-layout-spacer"></div>

			   </div><!-- change password -->
			   
			</div><!-- client/customers -->
			
			
		</div>


	</main>

	<!-- #include file="includes/pageFooter.asp" -->

</div>

<script src="dialog-polyfill.js"></script>  

<script>

	var changePasswordDialog = document.getElementById('changePasswordDialog');
	if (! changePasswordDialog.showModal) {
		dialogPolyfill.registerDialog(changePasswordDialog);
	}
	
	
	var changePasswordButton = document.getElementById('changePasswordButton');
	if (changePasswordButton) {
		changePasswordButton.addEventListener('click', function(){
			changePasswordDialog.querySelector('#oldPassword').value = '';
			changePasswordDialog.querySelector('#newPassword').value = '';
			changePasswordDialog.querySelector('#confirmPassword').value = '';

			//now position changePasswordDialog in relation to its button....
			var buttonTop 		= changePasswordButton.getBoundingClientRect().top; 
			var buttonHeight 	= changePasswordButton.getBoundingClientRect().height; 

			changePasswordDialog.showModal();
			
			changePasswordDialog.style.top 	= buttonTop + buttonHeight + 6 + 'px';
			changePasswordDialog.style.left	= '53px';
			
			
		});
	}

	changePasswordDialog.querySelector('.close').addEventListener('click', function() {
		changePasswordDialog.close();
	});
	changePasswordDialog.querySelector('.okay').addEventListener('click', function() {
	
		if(UpdatePassword(changePasswordDialog)) {
			changePasswordDialog.close();
		}
		
	});
	
	var defaultClients = document.querySelectorAll('[name="defaultClient"]');
	console.log('defaultClients.length: ' + defaultClients.length);
	if (defaultClients) {
		for (i = 0; i < defaultClients.length; ++i) {
			defaultClients[i].addEventListener('click', function() {
				UpdateDefaultClient(this);
			})
		}
	}

	
	var saveButton = document.getElementById('saveButton');
	if (saveButton) {
		saveButton.addEventListener('click', function() {
			SaveUserProfile(this);
		});
	}
	
	
	
	
		
</script>



</body>

</html>