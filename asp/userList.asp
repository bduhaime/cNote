<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/validUserDomain.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(9)


title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png""><a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Users"
userLog(title)

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>


	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

	<script src="userList.js"></script>


	<script>

		// this little if statement automatically refreshes this page if the user navigates here using browser's back arrow...	
		if(!!window.performance && window.performance.navigation.type == 2) {
			window.location.reload();
		}

		$(document).ready(function() {
			
			$( document ).tooltip();


			$( '#dialog-confirm' ).dialog({
				autoOpen: false,
				resizable: false,
				height: 'auto',
				width: 400,
				modal: true,
				buttons: {
					'Delete the user': function() {
						alert('gonna delete!');
						$( this ).dialog( 'close' );
					},
					'Cancel': function() {
						$( this ).dialog( 'close' );
					},
				}
			});

			
			$( '#dialog-newerUser' ).dialog({
				autoOpen: false,
				resizable: false,
				height: 'auto',
				width: 600,
				modal: true,
				buttons: {
					'Save': function() {
						alert('gonna save!');
						$( this ).dialog( 'close' );
					},
					'Cancel': function() {
						$( this ).dialog( 'close' );
					},
				}
			});

			
			$( 'input.checkboxradio' ).checkboxradio();


			$( '.checkboxradio.internal ').click( function(event) {
				event.preventDefault();
				$( '#externalCustomerWrapper' ).css( 'display', 'none' );
				$( '#internalCustomerWrapper' ).css( 'display', 'inline-block' );
			});

					
			$( '.checkboxradio.external ').click( function(event) {
				event.preventDefault();
				$( '#internalCustomerWrapper' ).css( 'display', 'none' );
				$( '#externalCustomerWrapper' ).css( 'display', 'inline-block' );
			});

					
			$( '#button_newerUser' ).click( function(event) {
				event.preventDefault();
				$( '#dialog-newerUser' ).dialog( 'open' );
			});


			var datatable = $('#tbl_users')
				.on( 'mouseover', 'tbody tr', function() {
					$( this ).find( 'i.delete' ).css( 'visibility', 'visible' );
				})
				.on( 'mouseout', 'tbody tr', function() {
					$( this ).find( 'i.delete' ).css( 'visibility', 'hidden' );
				})
				.on( 'click', 'tbody tr', function() {
					window.location.href = 'userEdit.asp?id='+this.id;
				})
				.on( 'click', 'i.delete', function(event) {
					event.preventDefault();
					event.stopPropagation();
					$( '#dialog-confirm' ).dialog( 'open' );
				})
				.DataTable({
					ajax: { 
						url: `${apiServer}/api/users`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
					},
					rowId: 'id',
					scrollY: 800,
					scroller: {
						rowHeight: 38,
					},
					scrollCollapse: true,
	
	// 				dom: 'Bftip',
	// 				buttons: [
	// 					{
	// 						text: 'NEW USER',
	// 						action: function() {
	// 							UserAdd_onClick();
	// 						}
	// 					},
	// 				],
	
					columnDefs: [
						{ 	targets: 'username', data: 'username', className: 'username dt-body-left dt-head-left' },
						{ 	targets: 'firstName', data: 'firstName', className: 'firstName dt-body-left dt-head-left' },
						{ 	targets: 'lastName', data: 'lastName',	className: 'lastName dt-body-left dt-head-left' },
						{ 	targets: 'title', data: 'title', className: 'title dt-body-left dt-head-left' },
						{ 	targets: 'active', data: 'active', className: 'active dt-body-center dt-head-center',
							render: function( data, type, row, meta ) {
								if ( data ) {
									return `<i class="material-symbols-outlined">check</i>`;
								} else {
									return '';
								}
							},								
						},
						{ 	targets: 'isInternal', 	data: 'isInternal', 		className: 'isInternal dt-body-center dt-head-center',
							render: function( data, type, row, meta ) {
								if ( data ) {
									return `<i class="material-symbols-outlined">check</i>`;
								} else {
									return '';
								}
							},								
						},
						{ 	targets: 'isExternal', 	data: 'isExternal', 		className: 'isExternal dt-body-center st-head-center',
							render: function( data, type, row, meta ) {
								if ( data ) {
									return `<i class="material-symbols-outlined">check</i>`;
								} else {
									return '';
								}
							},								
						},
						{	target: 'customerContact', data: null, className: 'customerContact dt-body-center dt-head-center',
							render: function( data, type, row, meta ) {
								if ( row.customerContactName || row.customerContactCompanyName ) {
									return `<i class="material-symbols-outlined" title="${data.customerContactName} - ${data.customerContactCompanyName}">contact_mail</i>`;
								} else {
									return '';
								}
							},
							
						},
						{	targets: 'contactID', 				data: 'contactID', 		className: 'contactID dt-body-center dt-head-center'},
						{	targets: 'contactName', 			data: 'contactName', 	className: 'contactName', visible: false},
						{	targets: 'contactCustomerName',	data: 'contactName', 	className: 'contactCustomerName', visible: false},
	 					{	targets: 'actions', data: null, className: 'actions dt-body-center dt-head-center', defaultContent: '<i class="material-icons delete">delete_outline</i>', orderable: false },
					],
				});
			
		} );

	</script>


	<style>
		
		i.delete {
			visibility: hidden;
		}		

		table.dataTable tbody tr:hover {
			cursor: pointer;
		}
		
		button.dt-button {
			background-color: rgb( 255, 171, 64 );
		}
		
	</style>
	
</head>

<body>
	
<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div class="page-content">
    <!-- Your content goes here -->

		<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>
	

		<div id="dialog-confirm" title="Confirm User Delete?">
		  <p><i class="material-icons" style="color: crimson; vertical-align: middle; float:left; margin-right: 12px;">warning</i>Are you sure you want to delete this user?</p><p>This will remove the user from your client. The user can be re-associated with your client at any time, but roles, permissions, and customer associations for the user will need to be recreated.</p>
		</div>
		

		<!-- DIALOG: Add New User -->
		<dialog id="dialog_user" class="mdl-dialog" style="width: 700px;">
			<h4 id="dialogTitle" class="mdl-dialog__title">New User</h4>
			<div class="mdl-dialog__content">
				
				
				<p id="userTypeInstructions" style="display: none;">Select "Internal" for client users; select "External for customer users.</p>
				<div id="userTypeSelector" style="display: none;">
					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="internalUser" >
						<input type="radio" id="internalUser" class="mdl-radio__button userType" name="userType" value="internal">
						<span class="mdl-radio__label">Internal (client)</span>
					</label>
					<br>
					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="externalUser" >
						<input type="radio" id="externalUser" class="mdl-radio__button userType" name="userType" value="external">
						<span class="mdl-radio__label">External (customer)</span>
					</label>				
					<br><br>
				</div>

				<%	if lCase(session("dbName")) <> "csuite" then %>
				
					<p id="customerInstructions" style="display: none;">Select a customer from the list. If you don't see the customer you are looking for, click <a href="customerList.asp">here</a> and ensure that the customer has a valid email domain.</p>
	
					<table>
						<tr>
							<td>
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
									
									<select class="mdl-textfield__input" id="externalCustomer">
										<option></option>
										<%
										SQL = "select id, name, validDomains " &_
												"from customer_view " &_
												"where validDomains is not null " &_
												"and (deleted = 0 or deleted is null) " &_
												"and id <> 1 " &_
												"order by name "
												
										dbug(SQL) 
										set rsExtCust = dataconn.execute(SQL) 
										while not rsExtCust.eof
											%>
											<option value="<% =rsExtCust("id") %>" data-domains="<% =rsExtCust("validDomains") %>"><% =rsExtCust("name") %></option>
											<%
											rsExtCust.movenext 
										wend 
										rsExtCust.close 
										set rsExtCust = nothing
										%>
									</select>
									<label class="mdl-textfield__label" for="externalCustomer">Customer...</label>
									
								</div>

								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label is-dirty" style="display: none;">
									<%
									SQL = "select id, name, validDomains from customer_view where id = 1 "
									set rsIntCust = dataconn.execute(SQL)
									if not rsIntCust.eof then 
										%>
									    <input class="mdl-textfield__input" type="text" id="internalCustomer" name="internalCustomer" value="<% =rsIntCust("name") %>" data-id="<% =rsIntCust("id") %>" data-domains="<% =rsIntCust("validDomains") %>" disabled>
									    <label class="mdl-textfield__label" for="internalCustomer">Internal customer (client)...</label>
										<%
									end if
									rsIntCust.close 
									set rsIntCust = nothing 
									%>
								</div>

							</td>
							<td width="50px"></td>
							<td><div id="validDomains" style="display: none;">Domains here</div></td>
						</tr>
					</table>
					
				<% end if %>



				<p id="userNameInstructions" style="display: none;">Enter an email address and press ENTER or TAB.</p>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
				    <input class="mdl-textfield__input" type="text" id="username" name="username" value="" pattern="[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$" autocomplete="off">
				    <label class="mdl-textfield__label" for="username">User name...</label>
				    <span class="mdl-textfield__error">Invalid email address (or invalid domain for customer)</span>
				</div>


				<p id="remainingInstructions" style="display: none;">Complete the rest of the information for this user and click the SAVE button.</p>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
				    <input class="mdl-textfield__input" type="text" id="firstName" name="firstName" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="firstName">First name...</label>
				    <span class="mdl-textfield__error">First name is required</span>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
				    <input class="mdl-textfield__input" type="text" id="lastName" name="lastName" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="lastName">Last name...</label>
				    <span class="mdl-textfield__error">Last name is required</span>
				</div>

				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
				    <input class="mdl-textfield__input" type="text" id="title" name="title" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="title">Title...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>

				<input id="customerID" type="hidden" value=""/>
				<input id="clientID" type="hidden" value="<% =session("clientID") %>"/>
				<input id="clientNbr" type="hidden" value="<% =session("clientNbr") %>"/>
				<input id="userID" type="hidden" value=""/>
				
			
				
			</div>
			<div id="dialog_buttons" class="mdl-dialog__actions" style="text-align: right;">
				<button id="buttonSave" 	type="button" class="mdl-button save" disabled>Save</button>
				<button id="buttonCancel" 	type="button" class="mdl-button cancel">Cancel</button>
<!-- 				<button id="buttonNext" 	type="button" class="mdl-button next" style="display: none;">Next</button> -->
			</div>
		</dialog><!-- Add New User -->
  
			
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			   <div id="tbl_userList" class="mdl-cell mdl-cell--11-col" style="text-align: center;">
				
				<% if userPermitted(107) then %>
					<div style="text-align: left;">
						<button id="button_newUser" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="float: left;">
							New User
						</button>
<!--
						<button id="button_newerUser" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="float: left;">
							Newer User
						</button>
-->
					</div>
					<br>
				<% end if %>
				
				<br><br>
				<table id="tbl_users" class="compact display">
					<thead>
						<tr>
							<th class="username">Username/Email</th>
							<th class="firstName">First Name</th>
							<th class="lastName">Last Name</th>
							<th class="title">Title</th>
							<th class="active">Active?</th>
							<th class="isInternal">Internal?</th>
							<th class="isExternal">External?</th>
							<th class="customerContact">Customer<br>Contact</th>
<!-- 							<th class="actions">Actions</th> -->
						</tr>
					</thead>
				</table>
				

			</div>
			<div class="mdl-layout-spacer"></div>
			
   	</div>
	
    
  </main>
  <!-- #include file="includes/pageFooter.asp" -->


 <script src="dialog-polyfill.js"></script>  
 <script src="datalist-polyfill.js"></script>  
 <script>

	 	
	 var clientID = '<% =session("clientID") %>'; 	
	 var clientNbr = <% =session("clientNbr") %>; 	
	 
	// ****************************************************************************************/
	// Register the add/edit dialog
	// ****************************************************************************************/
	
	var dialog_user = document.querySelector('#dialog_user');
	if (! dialog_user.showModal) {
		dialogPolyfill.registerDialog(dialog_user);
	}

	// ****************************************************************************************/
	// Add Event Listener for Dialog CANCEL button
	// ****************************************************************************************/
	
	dialog_user.querySelector('.cancel').addEventListener('click', function() {
		dialog_user.close();
	});
	
		
	
	// ****************************************************************************************/
	// Add Event Listeners for the internal/external radio buttons
	// ****************************************************************************************/
	var userTypeRadioButtons = dialog_user.querySelectorAll('.userType');
	if (userTypeRadioButtons) {
		for (i = 0; i < userTypeRadioButtons.length; ++i) {
			userTypeRadioButtons[i].addEventListener('change', function() {
				UserType_onChange(this);
			});
		}
	}


	// ****************************************************************************************/
	// Add Event Listeners for customer name <select>
	// ****************************************************************************************/

	if (dialog_user.querySelector('#externalCustomer')) {

		dialog_user.querySelector('#externalCustomer').addEventListener('change', function() {
			
			Customer_onChange(this);
			
		});
	
	}



	dialog_user.querySelector('#username').addEventListener('change', function() {
			
		// validate the username matches one of the valid domains for the customer...
		const newUserName		= $( '#username' ).val().trim();
		var newUserDomain;
		if ( newUserName.indexOf( '@' ) != -1 ) {
			newUserDomain = newUserName.substring( newUserName.indexOf( '@') + 1 ).trim();
		} else {
			alert( 'Username is not a valid email address' );
			return false;
		}
		
// 		const validDomains 	= $( '#internalCustomer' ).attr( 'data-domains' ).split( ',' );
		const validDomains = $( '#validDomainList' ).text().split( ',' );
		var userDomainValid	= false;
		
		for ( i = 0; i < validDomains.length; ++i ) {
			
			if	( validDomains[i].trim() == newUserDomain ) {
				userDomainValid = true;
				break;
			}
			
		}
		
		if ( userDomainValid ) {

			// validate the username is unique...	
			checkUniqueUsername_onChange(this);

		} else {
			
			alert( 'New user email address does not match one of the valid domains.' );
			return false;
			
		}			

	});
		
	// ****************************************************************************************/
	// Add Event Listener for Dialog CANCEL button
	// ****************************************************************************************/
	
	dialog_user.querySelector('.cancel').addEventListener('click', function() {
		
		dialog_user.querySelector('#userNameInstructions').textContent = 'Enter an email address and press the NEXT button.';
		
		dialog_user.querySelector('#username').value = '';
		
		dialog_user.querySelector('#firstName').value = '';
		dialog_user.querySelector('#firstName').parentNode.style.display = 'none';
		
		dialog_user.querySelector('#lastName').value = '';
		dialog_user.querySelector('#lastName').parentNode.style.display = 'none';
		
// 		dialog_user.querySelector('#customer').options.selectedIndex = null;
// 		dialog_user.querySelector('#customer').parentNode.style.display = 'none';
		
		dialog_user.querySelector('#title').value = '';
		dialog_user.querySelector('#title').parentNode.style.display = 'none';
		
		dialog_user.querySelector('#buttonCancel').style.display = 'block';
		dialog_user.querySelector('#buttonNext').style.display = 'block';
		dialog_user.querySelector('#buttonSave').style.display = 'none';
		
		dialog_user.close();

	});
	
		
	// ****************************************************************************************/
	// Add Event Listener for Dialog SAVE button
	// ****************************************************************************************/
	
	dialog_user.querySelector('.save').addEventListener('click', async function() {

		let userStatus = await AddUser_onSave( sessionJWT );

		if ( userStatus ) {
			dialog_user.close();
			$( '#tbl_users' ).DataTable().ajax.reload();
		}

	});
		 
	
	// ****************************************************************************************/
	// Add Event Listener for New User button
	// ****************************************************************************************/
	
	var button_newUser = document.querySelector('#button_newUser');
	if (button_newUser) {
		button_newUser.addEventListener('click', function() {
			UserAdd_onClick();
		});
	}
	
		
	
	
	// ****************************************************************************************/
	// Add Event Listeners for Edit buttons
	// ****************************************************************************************/
	
	var customerContacts = document.querySelectorAll('.customerContact'), i;
	if (customerContacts) {
		
		for (i = 0; i < customerContacts.length; ++i) {
			customerContacts[i].addEventListener('click', function(event) {

				event.stopPropagation();
				var customerID = this.getAttribute('data-id');
				location = 'customerContacts.asp?id=' + customerID;
			});
		}
		
	}
		
		
	
	
	//****************************************************************************************/
	// Add Event Listeners for Delete buttons
	//****************************************************************************************/
	
	var deleteUserButtons = document.querySelectorAll('.deleteUserButton'), i;
	if (deleteUserButtons) {
		
		for (i = 0; i < deleteUserButtons.length; ++i) {
			deleteUserButtons[i].addEventListener('click', function(event) {

				event.stopPropagation();
				UserDelete_onClick(this);

			});
		}
		
	}
		
		
  </script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>