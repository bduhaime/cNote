<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% ' response.buffer = true %>
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/jsonDataArray.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeByCustomer.asp" -->
<!-- #include file="includes/validContactDomain.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(54)

customerID = request.querystring("id")
%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customer contacts")


dbug("before top-logic")

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************


'***********************************************************************************
Function cleanPhoneNumber(strng)
'***********************************************************************************

   Dim regEx, Match, Matches   ' Create variable.

   Set regEx = New RegExp   ' Create a regular expression.

   regEx.Pattern = patrn   ' Set pattern.
   regEx.IgnoreCase = True   ' Set case insensitivity.
   regEx.Global = True   ' Set global applicability.
   Set Matches = regEx.Execute(strng)   ' Execute search.
   For Each Match in Matches   ' Iterate Matches collection.
      RetStr = RetStr & "Match found at position "
      RetStr = RetStr & Match.FirstIndex & ". Match Value is '"
      RetStr = RetStr & Match.Value & "'." & vbCRLF
   Next
   RegExpTest = RetStr

End Function
'***********************************************************************************


%>


<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->
	
	<link rel="stylesheet" href="dialog-polyfill.css" />

	<script src="customerContacts.js"></script>
	<script src="customerAnnotations.js"></script>

	<script>

		$(document).ready(function() {
			
			$('#tbl_customerContacts')
				.on ( 'draw.dt', function() {

					componentHandler.upgradeDom();

				})
				.DataTable({
					columnDefs: [
						{targets: 'prefix', 			className: 'prefix dt-body-center dt-head-center'},
						{targets: 'firstName', 		className: 'firstName dt-body-left dt-head-left'},
						{targets: 'lastName', 		className: 'lastName dt-body-left dt-head-left'},
						{
							targets: 'title', className: 'title dt-body-left  dt-head-left',
							render: function( data, type, row ) {
								return type === 'display' && data.length > 35 ? data.substr(0, 35) + '...' : data;
							}
						},
						{targets: 'email', 			className: 'email dt-body-left  dt-head-left'},
						{targets: 'roles', 			className: 'roles dt-body-left  dt-head-left'},
						{targets: 'zeroRisk', 		className: 'zeroRisk dt-body-left  dt-head-left'},
						{targets: 'attendee', 		className: 'attendee dt-body-center dt-head-center'},
						{targets: 'user', 			className: 'user dt-body-center dt-head-center'},
						{targets: 'actions', 		className: 'actions dt-body-center dt-head-center', orderable: false},
						{targets: 'contactRoles', 	visible: false, orderable: false},
					],
					scroller: { rowHeight: 38 },
					scrollCollapse: true,
					scrollY: 650,
					order: [[1, 'asc'], [2, 'asc']],
			});
		
		});

	</script>

			

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

	 <!-- #include file="includes/customerTabs.asp" -->

  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	
		<div class="page-content">
			<!-- Your content goes here -->
	
			<!-- DIALOG: New Contact -->
			<dialog id="dialog_addContact" class="mdl-dialog" style="width: 650px;">
				<h4 id="add_contactDialogTitle" class="mdl-dialog__title">New Contact</h4>
				<div class="mdl-dialog__content">
		
					<table>
						<tr>
							<td>						

								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <select class="mdl-textfield__input" type="text" id="add_gender" autocomplete="off" tabindex="1">
									    <option></option>
									    <option>Mr.</option>
									    <option>Ms.</option>
								    </select>
								    <label class="mdl-textfield__label" for="add_gender">Prefix...</label>
								</div>
		
							</td>
							<td class="spacerColumn" style="width: 20px;"></td>
							<td><h5>Roles:</h5></td>
						</tr>
						<tr>
							<td>

								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <input class="mdl-textfield__input" type="text" id="add_firstName" required autocomplete="off" tabindex="2">
								    <label class="mdl-textfield__label" for="add_firstName">First name...</label>
								</div>
								
							</td>
							<td class="spacerColumn" style="width: 20px;"></td>
							<td rowspan="7" style="vertical-align: top;">
								<%
								SQL = "select id, name " &_
										"from customerContactRoles " &_
										"order by name "
								dbug(SQL)
								set rsRoles = dataconn.execute(SQL) 
								while not rsRoles.eof 
									%>
									<input type="checkbox" id="role-<% =rsRoles("id") %>" data-id="<% = rsRoles("id") %>" class="roles" tabindex="9">&nbsp;<% =rsRoles("name") %></input><br>
									
									
									<%
									rsRoles.movenext 
								wend 
								rsRoles.close 
								set rsRoles = nothing 
								%>
							</td>
						</tr>
						<tr>
							<td>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <input class="mdl-textfield__input" type="text" id="add_lastName" required autocomplete="off" tabindex="3">
								    <label class="mdl-textfield__label" for="add_lastName">Last name...</label>
								</div>
								
							</td>
						</tr>
						<tr>
							<td>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <input class="mdl-textfield__input" type="text" id="add_contactTitle" tabindex="4">
								    <label class="mdl-textfield__label" for="add_contactTitle">Title...</label>
								</div>
								
							</td>
						</tr>
						<tr>
							<td>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <input class="mdl-textfield__input" type="text" id="add_contactEmail" tabindex="5" onchange="ContactEmail_onChange(this,<% =customerID %>)">
								    <label class="mdl-textfield__label" for="add_contactEmail">Email...</label>
									 <span class="mdl-textfield__error">Email is not valid for this customer</span>
								</div>
								
							</td>
						</tr>
						<tr>
							<td>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <input class="mdl-textfield__input" type="text" id="add_contactPhone" tabindex="5">
								    <label class="mdl-textfield__label" for="add_contactPhone">Phone...</label>
								</div>
								
							</td>
						</tr>
						<tr>
							<td>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								    <input class="mdl-textfield__input" type="text" id="add_contactGrade" pattern="\d{3} [A-Z] \d{3} \d\.\d" tabindex="6">
								    <label class="mdl-textfield__label" for="add_contactGrade">ZeroRisk type...</label>
									 <span class="mdl-textfield__error">ZeroRisk must match pattern: ### @ ### #.#</span>
								</div>
								
							</td>
						</tr>
						<tr>
							<td>
				
								<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_contactCallAttendeeInd">
									<input type="checkbox" id="add_contactCallAttendeeInd" class="mdl-switch__input" tabindex="7">
									<span class="mdl-switch__label">Call attendee?</span>
								</label>
							</td>
						</tr>
					</table>

					<input id="add_contactID" type="hidden" value="">
					<input id="add_contactCustomerID" type="hidden" value="<% =customerID %>">
			
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save" tabindex="11">Save</button>
					<button type="button" class="mdl-button cancel" tabindex="10">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	
			<!-- DIALOG: Add New User For Contact -->
			<dialog id="dialog_user" class="mdl-dialog" style="width: 700px;">
				<h4 id="dialogTitle" class="mdl-dialog__title">New User From Contact</h4>

				<div class="mdl-dialog__content">
					
					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="externalUser">
						<input type="radio" id="externalUser" class="mdl-radio__button userType" name="userType" value="external" checked disabled>
						<span class="mdl-radio__label">External (customer)</span>
					</label>	
					<br><br>
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="username" name="username" value="" autocomplete="off" disabled>
					    <label class="mdl-textfield__label" for="username">User name...</label>
					    <span class="mdl-textfield__error">Invalid email address (or invalid domain for customer)</span>
					</div>
					<br><br>
	
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="firstName" name="firstName" disabled>
					    <label class="mdl-textfield__label" for="firstName">First name...</label>
					    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
					</div>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="lastName" name="lastName" value="" disabled>
					    <label class="mdl-textfield__label" for="lastName">Last name...</label>
					    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
					</div>
	
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					    <input class="mdl-textfield__input" type="text" id="title" name="title" value="" disabled>
					    <label class="mdl-textfield__label" for="title">Title...</label>
					    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
					</div>
	
					<input id="customerID" type="hidden" value="<% =customerID %>"/>
					<input id="clientID" type="hidden" value="<% =session("dbName") %>"/>
					<input id="clientNbr" type="hidden" value="<% =session("clientNbr") %>"/>
					
				</div>
				
				<div id="dialog_buttons" class="mdl-dialog__actions" style="text-align: right;">
					<button id="buttonSave" 	type="button" class="mdl-button save">Save</button>
					<button id="buttonCancel" 	type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog>

			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--10-col" align="left">
					<% if userPermitted(77) then %>
						<button id="button_newContact" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
						  New Contact
						</button>
					<% end if %>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>

			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--12-col">
	
					<table id="tbl_customerContacts" class="compact display">
						<thead>
							<tr>
								<th class="prefix">Prefix</th>
								<th class="firstName">First Name</th>
								<th class="lastName">Last Name</th>
								<th class="title">Title</th>
								<th class="email">Email/Phone</th>
								<th class="roles">Role(s)</th>
								<th class="zeroRisk">ZeroRisk</th>
								<th class="attendee">Call<br>Attendee?</th>
								<th class="user">User?</th>
								<th class="actions">Actions</th>
								<th class="contactRoles"></th>
							</tr>
						</thead>
				  		<tbody> 
			
						<%
						SQL = "select " &_
									"c.id, " &_
									"c.firstName, " &_
									"c.lastName, " &_
									"c.title, " &_
									"c.email, " &_
									"c.phone, " &_
									"c.depositInd, " &_
									"c.loanInd, " &_
									"c.zeroRiskGrade, " &_
									"c.callAttendee, " &_
									"c.contactRoleID, " &_
									"c.gender " &_
								"from customerContacts c " &_
								"where c.customerID = " & request.querystring("id") & " " &_
								"and (c.deleted = 0 or c.deleted is null) " &_
								"order by c.firstName, c.lastName " 
								
						dbug("main SQL: " & SQL)
						set rsCC = dataconn.execute(SQL)
						while not rsCC.eof 

							dbug(" ")
							dbug("c.id: " & rsCC("id") )
							dbug("c.firstName: " & rsCC("firstName") )
							dbug("c.lastName: " & rsCC("lastName") )
							dbug("c.email: " & rsCC("email") )
	
							if rsCC("depositInd") then 
								depositIndChecked = "checked"
							else 
								depositIndChecked = ""
							end if
	
							if rsCC("loanInd") then 
								loanIndChecked = "checked"
							else 
								loanIndChecked = ""
							end if
							
							if rsCC("callAttendee") then 
								callAttendeeChecked = "checked"
							else 
								callAttendeeChecked = ""
							end if
							
							if validContactDomain(rsCC("email"), request.querystring("id")) then 
								dbug("validContactDomain() is true for: " & rsCC("email"))
								emailColor 		= "black"
								addUserIcon		= "person_add"
								addUserTitle 	= "Make contact a user"
							else 
								dbug("validContactDomain() is false for: " & rsCC("email"))
								emailColor 		= "crimson"
								addUserIcon 	= "person_add_disabled"
								addUserTitle 	= "Make user disabled"
							end if 
							%>

							<tr class="contact">
								<td><% =rsCC("gender") %></td>
								<td><% =rsCC("firstName") %></td>
								<td><% =rsCC("lastName") %></td>
								<td><% =rsCC("title") %></td>
								<td>
									<div class="email" style="color: <% =emailColor %>"><% =rsCC("email") %></div>
									<div class="phone"><% =rsCC("phone") %></div>
								</td>


								<td>
									<ul class="roles" style="list-style-type:none; margin: 0px;">
										<%
										SQL = "select " &_
													"ccr.id, " &_
													"ccr.name, " &_
													"case when x.contactID is not null then 1 else 0 end as roleInd " &_
												"from customerContactRoles ccr " &_
												"left join contactRoleXref x on (x.roleID = ccr.id and x.contactID = " & rsCC("id") & ") " &_
												"order by name "
										dbug(SQL) 
										set rsRoles = dataconn.execute(SQL) 
										while not rsRoles.eof 
											if cInt(rsRoles("roleInd")) = 1 then 
												response.write("<li class=""role"" data-id=""" & rsRoles("id") & """>" & rsRoles("name") & "</li>")
											end if
											rsRoles.movenext 
										wend 
										%>
									</ul>
								</td>


								<td><% =rsCC("zeroRiskGrade") %></td>

								
								<td data-order="<% =callAttendeeChecked %>">
									<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="callAttendee-<% =rsCC("id") %>" style="width: 48px;">
										<input type="checkbox" id="callAttendee-<% =rsCC("id") %>" data-val="<% =rsCC("id") %>" class="mdl-switch__input" <% =callAttendeeChecked %> onclick="ClientContactToggle_onClick(this,'callAttendee')" />
									</label>
								</td>
								
								<td> 
									<%
									if not isNull(rsCC("email")) then 

										SQL = "select id, 'external' as type " &_
												"from csuite..users u " &_
												"join csuite..clientUsers cu on (cu.userID = u.id and clientID = " & session("clientNbr") & ") " &_
												"join userCustomers uc on (uc.userID = cu.userID and uc.customerID= " & customerID & ") " &_
												"where u.username = '" & trim(rsCC("email")) & "' " &_
												"UNION ALL " &_
												"select id, 'internal' as type " &_
												"from csuite..users u " &_
												"join csuite..clientUsers cu on (cu.userID = u.id and clientID = " & session("clientNbr") & ") " &_
												"join userCustomers uc on (uc.userID = cu.userID and uc.customerID= 1) " &_
												"where u.username = '" & trim(rsCC("email")) & "' "

										dbug(SQL)
										set rsUser = dataconn.execute(SQL) 
										if not rsUser.eof then 
											dbug("matching user found for contact...") 
											
											if rsUser("type") = "external" then 
												dbug("contact is an external user for this customer")
												if userPermitted(105) then  ' "Allow Create External User from Customer Contact"
													dbug("current user has 'Allow External from Contact' permission, so generating link to existing external user...") 
													iconName 		= "person" 
													userIconTitle 	= "Click to see contact's user account"
													userIconEvent 	= "location='userEdit.asp?id=" & rsUser("id") & "'"
													userIconCursor = "pointer"
													userIconColor	= "black"
												else 
													dbug("current user does NOT have 'Allow External from Contact' permission, so just displaying info...")
													iconName 		= "person" 
													userIconTitle 	= "Contact is an external user for this customer"
													userIconEvent 	= ""
													userIconCursor = "default"
													userIconColor	= "black"
												end if 
											else 
												dbug("contact is an INTERNAL user for current client")
												if userPermitted(105) then  ' "Allow Create External User from Customer Contact"
													dbug("current user has 'Allow External from Contact' permission, so generating link to existing INTERNAL user...") 
													iconName 		= "person" 
													userIconTitle 	= "Click to see contact's internal user account"
													userIconEvent 	= "location='userEdit.asp?id=" & rsUser("id") & "'"
													userIconCursor = "pointer"
													userIconColor	= "crimson"
												else 
													dbug("current user does NOT have 'Allow External from Contact' permission, so just displaying info...")
													iconName 		= "person" 
													userIconTitle 	= "Contact is an internal user for this client"
													userIconEvent 	= ""
													userIconCursor = "default"
													userIconColor	= "crimson"
												end if 
											end if 
										else 
											dbug("not matching user found contact...")
											if userPermitted(105) then 	' "Allow Create External User from Customer Contact"
												dbug("user has 'Allow External from Contact' permission, validating email...")
												if validContactDomain(rsCC("email"), request.querystring("id")) then 
													dbug("customer contact email domain IS valid for customer, generating 'add new user user' link")
													iconName 		= "person_add" 
													userIconTitle 	= "Click to add contact as a user"
													userIconEvent 	= "NewUserFromContact(this)"
													userIconCursor = "pointer"
													userIconColor	= "black"
												else 
													dbug("customer contact email domain is NOT valid, so displaying nothing because user cannot be added here")
													iconName 		= "" 
													userIconTitle 	= ""
													userIconEvent 	= ""
													userIconCursor = "default"
													userIconColor	= "black"
												end if 
											else 
												dbug("user does not have 'Allow External from Contact' permission, so displaying nothing")
												iconName 		= ""
												iconTitle 		= ""
												userIconEvent 	= ""
												userIconCursor = "default"
												userIconColor	= "black"
											end if
										end if
									
									end if 
									
									%>
									
									
									<i class="material-symbols-outlined" title="<% =userIconTitle %>" onclick="<% =userIconEvent %>" style="cursor: <% =userIconCursor %>; color: <% =userIconColor %>;"><% =iconName %></i>
								</td>								
	
			   				<td>
										
									<div class="actionButtons" style="visibility: hidden;">

										<% if userPermitted(78) then %>
											<button type="button" id="button_editContact" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsCC("id") %>" onclick="EditContact_onClick(this);">
												<i class="material-symbols-outlined" title="Edit contact">edit</i>
											</button>								
										<% end if %>

										<% if userPermitted(79) then %>
											<button type="button" id="contactDelete-<% =rsCC("id") %>" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsCC("id") %>" style="cursor: pointer" onclick="CustomerContactDelete_onClick(this)" title="Delete contact">
												<i class="material-symbols-outlined" title="Delete contact">delete</i>
											</button>								
										<% end if %>

									</div>
									
		   					</td>

		   					<td>
			   					<%
				   				rsRoles.requery 
				   				assignedRoles = ""
				   				while not rsRoles.eof 
				   					if rsRoles("roleInd") = 1 then 
					   					if len(assignedRoles) > 0 then 
						   					assignedRoles = assignedRoles & ","
						   				end if
				   						assignedRoles = assignedRoles & rsRoles("id")
				   					end if 
			   						rsRoles.movenext 
									wend 
									rsRoles.close 
									set rsRoles = nothing 
				   				%>
			   					<input type="hidden" class="contactRoles" value="<% =assignedRoles %>">
		   					</td>
		   					
							</tr>
	
	
							
							<%
							rsCC.movenext 
	
						wend 
						rsCC.close 
						set rsCC = nothing 
						%>
	
				  		</tbody>
					</table>
				</div>
				<div class="mdl-layout-spacer"></div>
				
			</div><!-- end grid -->
		</div>

	</main>

	<!-- #include file="includes/pageFooter.asp" -->
	
</div>

<script src="dialog-polyfill.js"></script>  
<script>

// add/edit Contact Dialog Controls
	var dialog_addContact 	= document.querySelector('#dialog_addContact');

	var button_newContact = document.querySelector('#button_newContact');	
	if (! dialog_addContact.showModal) {
		dialogPolyfill.registerDialog(dialog_addContact);
	}	

	if (button_newContact) {
		button_newContact.addEventListener('click', function() {
			document.getElementById('add_contactDialogTitle').innerHTML = 'Add Contact';
			dialog_addContact.showModal();
		});
	}

	dialog_addContact.querySelector('.cancel').addEventListener('click', function() {
		contactRoles = dialog_addContact.querySelectorAll('.roles');
		for (i = 0; i < contactRoles.length; ++i) {
			contactRoles[i].checked = false;
		}
		dialog_addContact.close();
	});


	dialog_addContact.querySelector('.save').addEventListener('click', function() {

		dialog_addContact.close();
		AddContact_onSave( dialog_addContact );

	});


	var dialog_user = document.querySelector('#dialog_user');
	
	if (! dialog_user.showModal) {
		dialogPolyfill.registerDialog(dialog_user);
	}	
	
	dialog_user.querySelector('.cancel').addEventListener('click', function() {
		dialog_user.close();
	});



	function NewUserFromContact(htmlElement) {
		
		var currTD = htmlElement.parentNode;
		var currTR = currTD.parentNode;
		
		dialog_user.showModal();
		
		var currUsername = currTR.children[4].children[0].textContent.trim();
		dialog_user.querySelector('#username').value = currUsername;
		dialog_user.querySelector('#username').parentNode.classList.add('is-dirty');
		
		var currFirstName = currTR.children[1].textContent.trim();
		dialog_user.querySelector('#firstName').value = currFirstName;
		dialog_user.querySelector('#firstName').parentNode.classList.add('is-dirty');
		
		var currLastName = currTR.children[2].textContent.trim();
		dialog_user.querySelector('#lastName').value = currLastName;
		dialog_user.querySelector('#lastName').parentNode.classList.add('is-dirty');
		
		var currTitle = currTR.children[3].textContent.trim();
		dialog_user.querySelector('#title').value = currTitle;
		dialog_user.querySelector('#title').parentNode.classList.add('is-dirty');
		
		dialog_user.querySelector('.save').addEventListener('click', function() {

			AddUserFromContact(dialog_user);
			dialog_user.close();
			location = location;
			
		});

				
		
	}


	var contactRows 		= document.querySelectorAll('.contact');
	if (contactRows) {
		for (i = 0; i < contactRows.length; ++i) {
			
			contactRows[i].addEventListener('mouseover', function(event) {
				var actionButtons = this.querySelector('.actionButtons');
				ToggleActionButtons(actionButtons);
			});

			contactRows[i].addEventListener('mouseout', function(event) {
				var actionButtons = this.querySelector('.actionButtons');
				ToggleActionButtons(actionButtons);
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