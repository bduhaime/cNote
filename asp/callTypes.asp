<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/getNextID.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(30)

userLog("Call types")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Call Types"

dbug(" ")
dbug("start of script....")

dbug("request.querystring('cmd'): " & request.querystring("cmd"))

dbug("start enumerating request.form...")
for each item in request.form
	dbug("form." & item.name & ":" & item.value)
next 
dbug("done enumerating request.form")

select case request.querystring("cmd")

	case "delete"
	
		dbug("delete detected")
		
		SQL = "delete from customerCallTypes where id = " & request.querystring("id") & " " 
		
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		SQL = "delete from noteTypes where callTypeID = " & request.querystring("id") & " " 
		
		dbug(SQL)

		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 		
		
	case else 
	
end select 


dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

	<script src="callTypes.js"></script>

	<script>

		$(document).ready(function() {
			$('#tbl_clientProjects').DataTable({
				columnDefs: [
					{targets: 'frequency', className: 'dt-body-center'},
					{targets: 'requiredForNewCustomers', className: 'dt-body-center' },
					{targets: 'actions', className: 'dt-body-center', orderable: false},
					{ 
						targets: 'requiredForNewCustomers', 
						data: 'requiredForNewCustomers', 
						className: 'requiredForNewCustomers dt-body-center',
						createdCell: function (td, cellData, rowData, row, col) {
							if ( rowData.requiredForNewCustomers ) {
								$( td ).html( '<span class="material-icons">done</span>' );
							} else {
								$( td ).html( '' );
							}
						}
					},
				]
			});
		});

	</script>

	<style>
		
		td.name, td.description {
			max-width: 120px;
			text-overflow: ellipsis;
			white-space: nowrap;
			overflow: hidden;		
		}
				

		
	</style>
	
</head>

<body>

<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content">
		<!-- Your content goes here -->

		<!-- DIALOG: New Customer Call Type -->
		<dialog id="dialog_addCCT" class="mdl-dialog" data-role='popup' data-history='false' >
			<h4 class="mdl-dialog__title"><div id="dialogTitle">New Customer Call Type</div></h4>
			<div class="mdl-dialog__content">
		
				<form id="form_customerCallType">


					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input form="form_addCCT" class="mdl-textfield__input" type="text" id="add_cctName" value="" required autocomplete="off">
					    <label class="mdl-textfield__label" for="add_cctName">Call type name...</label>
					</div>
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <textarea form="form_addCCT" class="mdl-textfield__input" id="add_cctDesc" value="" rows="5" autocomplete="off"></textarea>
					    <label class="mdl-textfield__label" for="add_cctDesc">Call type description...</label>
					</div>
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input form="form_addCCT" class="mdl-textfield__input" id="add_idealFrequencyDays" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="add_idealFrequencyDays">Goal frequency (days)...</label>
					</div>
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input form="form_addCCT" class="mdl-textfield__input" id="add_shortName" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="add_shortName">Short name...</label>
					</div>
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input form="form_addCCT" class="mdl-textfield__input" id="add_weight" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="add_weight">Weight...</label>
					</div>

					<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="requiredForNewCustomers">
						<input type="checkbox" id="requiredForNewCustomers" class="mdl-checkbox__input" <% =disabled %>>
						<span class="mdl-checkbox__label">Required for new customers</span>
					</label>
	
					<input type="hidden" id="callTypeID" value="">

				</form>

			</div>
			<div class="mdl-dialog__actions">
				<button form="form_addCCT" type="submit" class="mdl-button save">Save</button>
				<button form="form_addCCT" type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog>
	  

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--7-col" align="left">
				<button id="button_newCCT" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Call Type
				</button>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
			
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div id="cNoteTableParent" class="mdl-cell mdl-cell--9-col">


				<table id="tbl_clientProjects" class="compact display">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="description">Description</th>
							<th class="frequency">Goal Frequency</th>
							<th class="shortName">Short Name</th>
							<th class="weight">Weight</th>
							<th class="requiredForNewCustomers">Req'd For New<br>Customers</th>
							<th class="actions">Actions</th>
						</tr>
					</thead>
			  		<tbody class="list"> 
				  	<%
					SQL = "select id, name, description, idealFrequencyDays, shortName, weight, requiredForNewCustomers from customerCallTypes order by name "
							
					dbug(SQL)
					set rsCCT = dataconn.execute(SQL)
					while not rsCCT.eof
						if not isNull(rsCCT("weight")) then 
							if isNumeric(rsCCT("weight")) then 
								weight = formatNumber(rsCCT("weight"),2) 
							else 
								weight = ""
							end if 
						else 
							weight = ""
						end if 
						
					  	%>
						<tr id="<% =rsCCT("id") %>">
							<td class="name" title="<% = rsCCT("name") %>"><% =rsCCT("name") %></td>
							<td class-"description" title="<% =rsCCT("description") %>"><% =rsCCT("description") %></td>
							<td><% =rsCCT("idealFrequencyDays") %></td>
							<td><% =rsCCT("shortName") %></td>
							<td><% =weight %></td>
							<td class="requiredForNewCustomers"><% =rsCCT("requiredForNewCustomers") %></td>
	   					<td>
								<a href="callTypeAgenda.asp?id=<% =rsCCT("id") %>"><img src="/images/ic_arrow_forward_black_24dp_1x.png"></a>
								
								<button type="button" id="button_editCallType" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsCCT("id") %>" onclick="EditCallType_onClick(this);">
								  <i class="material-icons">mode_edit</i>
								</button>								

								<a href="callTypes.asp?cmd=delete&id=<% =rsCCT("id") %>" onclick="return confirm('Are you sure you want to delete this Call Type and associated Agenda Items?');"><img src="/images/ic_delete_black_24dp_1x.png"></a>
	   					</td>
						</tr>
						<%
						rsCCT.movenext 
					wend 
					rsCCT.close 
					set rsCCT = nothing 
					%>
			  		</tbody>
				</table>


			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
	</div>
		


</main>

<!-- #include file="includes/pageFooter.asp" -->


<script src="dialog-polyfill.js"></script>  
<script>
	
// add/edit Projects
	var dialog_addCCT = document.querySelector('#dialog_addCCT');
	var button_newCCT = document.querySelector('#button_newCCT');	
	if (! dialog_addCCT.showModal) {
		dialogPolyfill.registerDialog(dialog_addCCT);
	}	
	button_newCCT.addEventListener('click', function() {
		document.getElementById('dialogTitle').innerHTML = 'New Call Type';
		dialog_addCCT.showModal();
	});
	dialog_addCCT.querySelector('.cancel').addEventListener('click', function() {
		dialog_addCCT.close();
	});

	dialog_addCCT.querySelector('.save').addEventListener('click', function() {

		AddCCT_onSave(dialog_addCCT);

	});
	
	
</script>

<%
dataconn.close 
set dataconn = nothing
%>
<!-- </form> -->
</body>
</html>