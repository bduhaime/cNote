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
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(101)


title = session("clientID") & " - Clients" 
userLog(title)
%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<script src="list.min.js"></script>
	<script src="clientList.js"></script>
	<script src="moment.min.js"></script>

	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

	<style>
	div#load_screen{
		background: #000;
		opacity: .5;
		position: fixed;
	    z-index:10;
		top: 0px;
		width: 100%;
		height: 1600px;
	}
	div#load_screen > div#loading{
		color:#FFF;
		width:120px;
		height:24px;
		margin: 300px auto;
	}


	.fixedTableHeaders {
		width: 1225px;
		
		thead {
			tr {
				display: block;
				position: relative;
			}
		}
	}

	</style>

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

		<!-- DIALOG: Add New Client -->
		<dialog id="dialog_addClient" class="mdl-dialog" style="width: 700px;">
			<h4 id="formTitle" class="mdl-dialog__title">New Client</h4>
			<div class="mdl-dialog__content">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="client_name" value="" autocomplete="off">
				    <label class="mdl-textfield__label" for="client_name">Client name...</label>
				</div>

				<div style="display: table;">
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: table-cell;">
					    <input class="mdl-textfield__input" type="date" id="client_startDate" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="client_startDate">Start date...</label>
					</div>
					<div style="display: table-cell; width: 40px;"></div>
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: table-cell;">
					    <input class="mdl-textfield__input" type="date" id="client_endDate" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="client_endDate">End date...</label>
					</div>
				</div>
				
				<div style="display: table;">
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="client_clientID" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="client_clientID">Client ID...</label>
					</div>
					<div style="display: table-cell; width: 40px;"></div>
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: table-cell;">
					    <input class="mdl-textfield__input" type="text" id="client_databaseName" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="client_databaseName">Database name...</label>
					</div>
				</div>

				<div style="display: table;">
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 650px;">
						<textarea class="mdl-textfield__input" type="text" rows= "3" id="client_validDomains" ></textarea>
						<label class="mdl-textfield__label" for="client_validDomains">Valid domains...</label>
					</div>
				</div>

				
				<input id="id" type="hidden">

			</div>
			<div id="dialog_buttons" class="mdl-dialog__actions">
				<button type="button" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
			
		</dialog>
  
			
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div id="tbl_clientList" class="mdl-cell mdl-cell--8-col" style="clear: left;">
				
				<div style="width: 90%; text-align: center;">
					
					<% if userPermitted(102) then %>
					<button id="button_newClient" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="float: left;">
					  New Client
					</button>
					<% end if %>
	
				    
					<!-- Expandable Textfield -->
				  <div class="mdl-textfield mdl-js-textfield mdl-textfield--expandable" style="float: right; vertical-align: top;	">
				    <label class="mdl-button mdl-js-button mdl-button--icon" for="search">
				      <i class="material-icons">search</i>
				    </label>
				    <div class="mdl-textfield__expandable-holder">
				      <input id="search" class="mdl-textfield__input search" type="text" id="search" autocomplete="off" style="display: block;">
				    </div>
				  </div>
				  <br>
				  
				  
				</div>
				<br><br>
				<table id="tbl_clients" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp fixedHeaders" style="margin: 0 auto; display: inline-block; text-align: center;">
					<thead>
						<tr style="display: block; position: relative;">
							<th class="mdl-data-table__cell--non-numeric sort" data-sort="name" style="width: 400px">Name</th>
							<th class="mdl-data-table__cell--non-numeric sort" data-sort="clientID" style="width: 100px">Client ID</th>
							<th class="mdl-data-table__cell--non-numeric sort" data-sort="dbName" style="width: 75px">DB Name</th>
							<th class="mdl-data-table__cell--non-numeric sort" data-sort="startDate" style="width: 100px">Start Date</th>
							<th class="mdl-data-table__cell--non-numeric sort" data-sort="endDate" style="width: 150px">End Date</th>
							<th class="mdl-data-table__cell--non-numeric sort" style="width: 150px; text-align: center;">Valid<br>Domains</th>
							<th class="mdl-data-table__cell--non-numeric" style="text-align: center; width: 120px">Actions</th>
						</tr>
					</thead>
					<tbody class="list" style="display: block; overflow: auto; height: 622px;"> 
					<%
					SQL = "select id, clientID, name, startDate, endDate, databaseName " &_
							"from cSuite.dbo.clients " &_
							"where (deleted = 0 or deleted is null) " &_
							"order by name "
				
					dbug(SQL)
					set rs = dataconn.execute(SQL)
					while not rs.eof
						%>
						<tr id="clientRow-<% =rs("id") %>" class="selectClient" data-val="<% =rs("id") %>" style="cursor: pointer" onClick="location='clientDetail.asp?id=<% =rs("id") %>'">
							<td class="mdl-data-table__cell--non-numeric name" style="width: 400px"><% =rs("name") %></td>
							<td class="mdl-data-table__cell--non-numeric clientID" style="width: 100px"><% =rs("clientID") %></td>
							<td class="mdl-data-table__cell--non-numeric dbName" style="width: 75px"><% =rs("databaseName") %></td>
							<td class="mdl-data-table__cell--non-numeric startDate" style="width: 100px"><% =rs("startDate") %></td>
							<td class="mdl-data-table__cell--non-numeric endDate" style="width: 150px"><% =rs("endDate") %></td>

							<td class="mdl-data-table__cell--non-numeric" style="width: 150px; text-align: center;">
								<% 
								if lcase(rs("databaseName")) <> "csuite" then 
									SQL = "select validDomains from " & rs("databaseName") & "..customer where id = 1 " 
									dbug(SQL)
									set rsCust = dataconn.execute(SQL) 
									if not rsCust.eof then 
										validDomains = rsCust("validDomains") 
									else 
										validDomains = "" 
									end if 
									%>
									<i class="material-icons" title="<% =validDomains %>">language</i>
									<%
								end if 
								%>
							</td>

							<td class="mdl-data-table__cell--non-numeric" style="text-align: center; width: 120px">
								<div id="actions-<% =rs("id") %>" style="visibility: hidden; float: right; vertical-align: middle; align-content: center;">
									<% if userPermitted(103) then %>
										<i id="editCustomer-<% =rs("id") %>" class="material-icons editClientButton" data-val="<% =rs("id") %>" style="cursor: pointer; vertical-align: middle;">edit</i>
									<% end if %>
									<% if userPermitted(104) then %>
										<i id="deletecustomer-<% =rs("id") %>" class="material-icons deleteClientButton" data-val="<% =rs("id") %>" style="cursor: pointer; vertical-align: middle;">delete_outline</i>
									<% end if %>
								</div>
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
	
	var dialog_addClient = document.querySelector('#dialog_addClient');
	if (! dialog_addClient.showModal) {
		dialogPolyfill.registerDialog(dialog_addClient);
	}
	
	
	// ****************************************************************************************/
	// Add Event Listener for Dialog CANCEL button
	// ****************************************************************************************/
	
	dialog_addClient.querySelector('.cancel').addEventListener('click', function() {
		dialog_addClient.close();
	});
	
		
	// ****************************************************************************************/
	// Add Event Listener for Dialog SAVE button
	// ****************************************************************************************/
	
	dialog_addClient.querySelector('.save').addEventListener('click', function() {
		AddClient_onSave(dialog_addClient)
		dialog_addClient.close();
	});
		 
	
	// ****************************************************************************************/
	// Add Event Listener for New Client button
	// ****************************************************************************************/
	
	var button_newClient = document.querySelector('#button_newClient');
	button_newClient.addEventListener('click', function() {
		ClientAdd_onClick();
	});
	
		
	// ****************************************************************************************/
	// Add Event Listeners for Row (selecting a customer, toggle edit/delete buttons
	// ****************************************************************************************/
	
	var selectClients = document.querySelectorAll('.selectClient');
	if (selectClients) {
		
		for (i = 0; i < selectClients.length; ++i) {

// 			selectClients[i].addEventListener('click', function(event) {
// 				GoToClient(this);
// 			})

			selectClients[i].addEventListener('mouseover', function(event) {
				ToggleActions(this);
			})
			
			selectClients[i].addEventListener('mouseout', function(event) {
				ToggleActions(this);
			})
			

		}
		
	}
	
	
	// ****************************************************************************************/
	// Add Event Listeners for Edit buttons
	// ****************************************************************************************/
	
	var editClientButtons = document.querySelectorAll('.editClientButton');
	if (editClientButtons) {
		
		for (i = 0; i < editClientButtons.length; ++i) {
			editClientButtons[i].addEventListener('click', function(event) {

				event.stopPropagation()
				EditClient_onClick(this);

			})
		}
		
	}
	
	
	//****************************************************************************************/
	// Add Event Listeners for Delete buttons
	//****************************************************************************************/
	
	var deleteClientButtons = document.querySelectorAll('.deleteClientButton'), i;
	if (deleteClientButtons != null) {
		
		for (i = 0; i < deleteClientButtons.length; ++i) {
			deleteClientButtons[i].addEventListener('click', function(event) {

				event.stopPropagation()
				ClientDelete_onClick(this);

			})
		}
		
	}
		
		
	//****************************************************************************************/
	// for List.js (search feature)....
	//****************************************************************************************/
	
	var options = {
		valueNames: [
			'name', 
			'clientID', 
			'startDate', 
			'endDate', 
			'dbName'
		]
	};
	
	var clientList = new List('tbl_clientList', options);
	
/*
	var searchElem = document.getElementById('search');
	searchElem.value = 'Active';
	
	clientList.filter(function(item) {
	
		// the first time the page is displayed, only customers with status of 'Active' are displayed
		if (item.values().status == 'Active') {
		   return true;
		} else {
		   return false;
		}

	});	
*/
	
	clientList.on('searchStart', function() {

		// for all non-first time searches, first clear the filter and start over
		clientList.filter();

	});
	
	
	// additional list.js events for reference only....
	//
	// 	customerList.on('searchComplete', function() {
	// 		alert('searchComplete event!');
	// 	});
	// 
	// 	customerList.on('filterStart', function() {
	// 		alert('filterStart event!');
	// 	});
	// 	
	// 	customerList.on('filterComplete', function() {
	// 		alert('filterComplete event!');
	// 	});
	// 	
	// 	customerList.on('sortStart', function() {
	// 		alert('sortStart event!');
	// 	});
	// 	
	// 	customerList.on('sortComplete', function() {
	// 		alert('sortComplete event!');
	// 	});
	// 	
		
		

  </script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>