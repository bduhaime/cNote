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
<% 
call checkPageAccess(11)

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png""><a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Permissions"
userLog(title)

%>

<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />


	<script src="permissionList.js"></script>

	<script>

		$(document).ready(function() {
			
			$( document ).tooltip();

			$('#tbl_permissions').DataTable({
				scrollY: 700,
				scroller: true,
				scrollCollapse: true,
				columnDefs: [
					{targets: 'csuiteOnly', className: 'dt-body-center'},
					{targets: 'nonCsuiteOnly', className: 'dt-body-center'},
					{targets: 'customerUserAllowed', className: 'dt-body-center'},
					{targets: 'actions', className: 'dt-body-center', orderable: false}
				]
			});
			
		});

	</script>
	
</head>

<body>
	
<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div id="tbl_PermissionList" class="page-content">
    <!-- Your content goes here -->
	<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
	</div>

		<!-- DIALOG: Add New Permission -->
		<dialog id="dialog_permission" class="mdl-dialog" style="width: 700px;">
			<h4 id="dialogTitle" class="mdl-dialog__title">New Permission</h4>
			<div class="mdl-dialog__content">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="permissionName" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="username">Permission name...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="scriptName" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="scriptName">Script name...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="csuiteOnly" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="csuiteOnly">cSuite only...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="csuiteOnly" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="csuiteOnly">cSuite only...</label>
				</div>

				<input id="permissionID" type="hidden" value=""/>

			</div>
			<div id="dialog_buttons" class="mdl-dialog__actions" style="text-align: right;">
				<button id="buttonSave" 	type="button" class="mdl-button save">Save</button>
				<button id="buttonCancel" 	type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog>
  
			
   	<div class="mdl-grid" style="padding-bottom: 0px;">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--5-col" style="position: relative; padding-bottom: 0px; margin-bottom: 0px;">
				
				<% if (lcase(session("dbName")) = "csuite" AND userPermitted(109)) then %>
				<button id="button_newPermission" 	class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" 
																style="position: absolute; bottom: 15px; float: left;">
				  New Permission
				</button>
				<% end if %>
				
				    
		   </div>
			<div class="mdl-layout-spacer"></div>
		</div>


   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<% if lCase(session("dbName")) = "csuite" then cellWidth = "9" else cellWidth = "7" end if %>
			
		   <div id="tbl_PermissionList" class="mdl-cell mdl-cell--<% =cellWidth %>-col">
			   
				<table id="tbl_permissions" class="compact display">
					<thead>
						<tr>
							<th class="permissionName">Permission Name</th>
							<th class="scriptName">Script Name</th>
							<% if lCase(session("dbName")) = "csuite" then %>
								<th class="csuiteOnly">cSuite<br>Only?</th>
								<th class="nonCsuiteOnly">Non-cSuite<br>Only?</th>
								<th class="customerUserAllowed">Cust User<br>Allowed?</th>
								<th class="actions">Actions</th>
							<% end if %>
						</tr>
					</thead>
					<tbody> 
					<%
					if cInt(session("clientNbr")) <> 1 then 
						SQL = "select id, name, script_name, csuiteOnly, nonCsuiteOnly, deleted, description, customerUserAllowed " &_
								"from cSuite..permissions p " &_
								"where (p.deleted = 0 or p.deleted is null) " &_
								"and   (p.csuiteOnly = 0 or p.csuiteOnly is null) " &_
								"order by name "
					else  
						SQL = "select id, name, script_name, csuiteOnly, nonCsuiteOnly, deleted, description, customerUserAllowed " &_
								"from cSuite..permissions p " &_
								"order by name "
					end if 
					
					dbug(SQL)
					set rsPerm = dataconn.execute(SQL)
					while not rsPerm.eof
						%>
						<tr id="<% =rsPerm("id") %>" class="selectPerm">
							<td title="<% =rsPerm("description") %>"><% =rsPerm("name") %></td>
							<td><% =rsPerm("script_name") %></td>

							<% if lCase(session("dbName")) = "csuite" then %>

								<td>
									<% if rsPerm("csuiteOnly") then %>
										<i class="material-icons">done</i>
									<% end if %>
								</td>

								<td>
									<% if rsPerm("nonCsuiteOnly") then %>
										<i class="material-icons">done</i>
									<% end if %>
								</td>

								<td>
									<% if rsPerm("customerUserAllowed") then %>
										<i class="material-icons">done</i>
									<% end if %>
								</td>

								<td>
									<div id="actions-<% =rsPerm("id") %>" style="visibility: hidden; float: right; vertical-align: middle; align-content: center;">
										<% if userPermitted(41) then %>
											<% 
											if rsPerm("deleted") then 
												icon = "delete_forever" 
											else 
												icon = "delete_outline"
											end if
											%>
											<i id="deletePerm-<% =rsPerm("id") %>" class="material-icons deletePermButton" data-val="<% =rsPerm("id") %>" style="cursor: pointer; vertical-align: middle;"><% =icon %></i>
										<% end if %>
									</div>
								</td>

							<% end if %>

						</tr>			
						<%
						rsPerm.movenext 
					wend
					rsPerm.close 
					set rsPerm = nothing
					%>
				
					</tbody>
				</table>
		   </div>
			<div class="mdl-layout-spacer"></div>
   	</div>
	
    
  </main>
  <!-- #include file="includes/pageFooter.asp" -->


 <script src="dialog-polyfill.js"></script>  
 <script src="datalist-polyfill.js"></script>  
 <script>

	 var searchField = document.getElementById('search');
	 if (searchField) {
		 searchField.addEventListener('click', function() {
			 this.select();
		 });
	 }
	 
	 	
	 	
	// ****************************************************************************************/
	// Register the add/edit dialog
	// ****************************************************************************************/
	
	var dialog_permission = document.querySelector('#dialog_permission');
	if (! dialog_permission.showModal) {
		dialogPolyfill.registerDialog(dialog_permission);
	}
	

		
	// ****************************************************************************************/
	// Add Event Listener for Dialog CANCEL button
	// ****************************************************************************************/
	
	dialog_permission.querySelector('.cancel').addEventListener('click', function() {
		
// 		dialog_permission.querySelector('#instructions').textContent = 'Enter an email address and press the NEXT button.';
// 		
// 		dialog_permission.querySelector('#username').value = '';
// 		
// 		dialog_permission.querySelector('#firstName').value = '';
// 		dialog_permission.querySelector('#firstName').parentNode.style.display = 'none';
// 		
// 		dialog_permission.querySelector('#lastName').value = '';
// 		dialog_permission.querySelector('#lastName').parentNode.style.display = 'none';
// 		
// 		dialog_permission.querySelector('#customer').options.selectedIndex = null;
// 		dialog_permission.querySelector('#customer').parentNode.style.display = 'none';
// 		
// 		dialog_permission.querySelector('#title').value = '';
// 		dialog_permission.querySelector('#title').parentNode.style.display = 'none';
// 		
// 		dialog_permission.querySelector('#buttonCancel').style.display = 'block';
// 		dialog_permission.querySelector('#buttonNext').style.display = 'block';
// 		dialog_permission.querySelector('#buttonSave').style.display = 'none';
		
		dialog_user.close();

	});
	
		
	// ****************************************************************************************/
	// Add Event Listener for Dialog SAVE button
	// ****************************************************************************************/
	
	dialog_permission.querySelector('.save').addEventListener('click', function() {
		AddUser_onSave(dialog_user)
		dialog_user.close();
	});
		 
	
	// ****************************************************************************************/
	// Add Event Listener for New User button
	// ****************************************************************************************/
	
	var button_newPermission = document.getElementById('button_newPermission');
	
	if (button_newPermission) {
		button_newPermission.addEventListener('click', function() {
			
			dialog_permission.querySelector("#permissionName").value = null;
			dialog_permission.querySelector("#permissionName").value = null;
			
		});
	}
	
		
	// ****************************************************************************************/
	// Add Event Listeners for Row (selecting a Permission, toggle edit/delete buttons
	// ****************************************************************************************/
	
	var selectPerms = document.querySelectorAll('.selectPerm');
	if (selectPerms) {
		
		for (i = 0; i < selectPerms.length; ++i) {

			selectPerms[i].addEventListener('click', function(event) {
				GoToPermission(this);
			})

			selectPerms[i].addEventListener('mouseover', function(event) {
				event.stopPropagation()
				ToggleActions(this);
			})
			
			selectPerms[i].addEventListener('mouseout', function(event) {
				event.stopPropagation()
				ToggleActions(this);
			})
			

		}
		
	}
	
	
	//****************************************************************************************/
	// Add Event Listeners for Delete buttons
	//****************************************************************************************/
	
	var deleteUserButtons = document.querySelectorAll('.deletePermButton'), i;
	if (deleteUserButtons != null) {
		
		for (i = 0; i < deleteUserButtons.length; ++i) {
			deleteUserButtons[i].addEventListener('click', function(event) {

				event.stopPropagation()
				PermDelete_onClick(this);

			})
		}
		
	}
		
		

  </script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>