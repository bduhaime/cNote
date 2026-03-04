<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->
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
call checkPageAccess(31)


userLog("Call type agenda")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""callTypes.asp?"">Call Types</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
' title = title & "Call Type Agenda" 

callTypeID = request.querystring("id") 

set cmdSelect = server.CreateObject("ADODB.Command")
cmdSelect.activeConnection = dataconn
cmdSelect.commandText = "select name from customerCallTypes where id = ? " 
cmdSelect.parameters.append = cmdSelect.createParameter("id", adInteger, adParamInput, , callTypeID)

set rsCT = cmdSelect.execute()
if not rsCT.eof then 
	callTypeName = rsCT("name")
else 
	callTypeName = ""
end if
rsCT.close 
set rsCT = nothing 
set cmdSelect = nothing 

title = title & callTypeName 


dbug(" ")
dbug("start of script....")

dbug("request.querystring('cmd'): " & request.querystring("cmd"))

select case request.querystring("cmd")

	case "delete"
	
		dbug("delete detected")
		
		ntID = request.querystring("ntID")
		
		set cmdDelete = server.CreateObject("ADODB.Command")
		cmdDelete.activeConnection = dataconn
		cmdDelete.commandText = "delete from noteTypes where id = ? " 
		cmdDelete.parameters.append = cmdDelete.createParameter("id", adInteger, adParamInput, , ntID)
		set rsDelete = cmdDelete.execute()
		set rsDelete = nothing 
		set cmdDelete = nothing 
		
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

	<script src="callTypeAgenda.js"></script>

	<script>

		$(document).ready(function() {
			$('#tbl_callTypeAgenda').DataTable({
				columnDefs: [
					{targets: 'includeInEmails', className: 'dt-body-center'},
					{targets: 'copyUtopias', className: 'dt-body-center'},
					{targets: 'copyKIs', className: 'dt-body-center'},
					{targets: 'copyProjects', className: 'dt-body-center'},
					{targets: 'sequence', className: 'dt-body-center'},
					{targets: 'actions', className: 'dt-body-center', orderable: false}
				],
				order: [[ 6, 'asc' ]]
			});
		});

	</script>
		
</head>

<body>

<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Call Type Agenda Item</span>
	</div>

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content">
		<!-- Your content goes here -->

		<!-- DIALOG: New Customer Call Type -->
		<dialog id="dialog_addCTA" class="mdl-dialog" data-role='popup' data-history='false' >
			<form id="form_addCTA">

				<h4 class="mdl-dialog__title">New Agenda Item</h4>
				<div class="mdl-dialog__content">
							
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input form="form_addCCT" class="mdl-textfield__input" type="text" id="add_ntName" value="" required pattern="[A-Z,a-z, ]*">
						    <label class="mdl-textfield__label" for="add_ntName">Item name...</label>
						    <span>Letters and spaces only</span>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <textarea form="form_addCCT" class="mdl-textfield__input" id="add_ntDesc" value="" rows="5"></textarea>
						    <label class="mdl-textfield__label" for="add_ntDesc">Item description...</label>
						</div>
						
						<input type="hidden" id="add_callTypeID" value="<% =callTypeID %>">
						<input type="hidden" id="add_noteTypeID" value="">
		
				</div>
				
				<div class="mdl-dialog__actions">
					<button form="form_addCTA" type="submit" class="mdl-button save">Save</button>
					<button form="form_addCTA" type="button" class="mdl-button cancel">Cancel</button>
				</div>
				
			</form>
		</dialog>
	  
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--6-col" align="left">
				<button id="button_newCTA" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Agenda Item
				</button>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
			
		
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--7-col">

				<table id="tbl_callTypeAgenda" class="compact display">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="description">Description</th>
							<th class="includeInEmails">Include In Emails?</th>
							<th class="copyUtopias">Copy<br>Utopias?</th>
							<th class="copyKIs">Copy Key<br>Initiatives?</th>
							<th class="copyProjects">Copy<br>Projects?</th>
							<th class="sequence">Sequence</th>
							<th class="actions">Actions</th>
						</tr>
					</thead>
			  		<tbody> 
				  	<%
				  	set cmdSelect = server.CreateObject("ADODB.Command")
				  	cmdSelect.activeConnection = dataconn
				  	cmdSelect.commandText = "select id, name, description, seq, quillID, utopiaInd, keyInitiativeInd, projectInd, includeWithEmails " &_
													"from noteTypes " &_
													"where callTypeID = ? " &_
													"order by seq, name "
				  	
					cmdSelect.parameters.append = cmdSelect.createParameter("id", adInteger, adParamInput, , callTypeID)
					set rsNT = cmdSelect.execute()

					while not rsNT.eof

						if rsNT("utopiaInd") then 
							utopiaChecked = "checked"
							utopiaClass = "is-checked"
						else 
							utopiaChecked = ""
							utopiaClass = ""
						end if 
						
						if rsNT("keyInitiativeInd") then 
							kiChecked = "checked"
							kiClass = "is-checked"
						else 
							kiChecked = ""
							kiClass = ""
						end if 
						
						if rsNT("projectInd") then 
							projectChecked = "checked"
							projectClass = "is-checked"
						else 
							projectChecked = ""
							projectClass = ""
						end if 
						
						if rsNT("includeWithEmails") then 
							includeWithEmailsChecked = "checked"
						else 
							includeWithEmailsChecked = ""
						end if
					
					  	%>
						<tr>
							<td><% =rsNT("name") %></td>
							<td><% =rsNT("description") %></td>
							
							
							
							<td style="text-align: center;">
								<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="includeWithEmails-<% =rsNT("id") %>" style="width: 48px;">
									<input class="mdl-switch__input" id="includeWithEmails-<% =rsNT("id") %>" style="text-align: center;" data-val="<% =rsNT("id") %>" type="checkbox" <% =includeWithEmailsChecked %> onclick="ToggleIncludeWithEmails_onClick(this)" >
								</label>
							</td>
							
							
							
							
							<td>
								<input class="mdl-radio__button <% =utopiaClass %>" id="copyUtopia-<% =rsNT("id") %>" data-val="<% =rsNT("id") %>" name="copyUtopiaInd" type="radio" <% =utopiaChecked %> onclick="UpdateCopy_onClick(this,'utopias','<% =callTypeID %>')" style="<% =utopiaStyleText %>">
							</td>
							
							<td>
								<input class="mdl-radio__button <% =kiClass %>" id="copyKI-<% =rsNT("id") %>" data-val="<% =rsNT("id") %>" name="copyKeyInitiativesInd" type="radio" <% =kiChecked %> onclick="UpdateCopy_onClick(this,'kis','<% =callTypeID %>')" style="<% =kiStyleText %>">
							</td>
							
							<td>
								<input class="mdl-radio__button <% =projectClass %>" id="copyProject-<% =rsNT("id") %>" data-val="<% =rsNT("id") %>" name="copyProjectInd" type="radio" <% =projectChecked %> onclick="UpdateCopy_onClick(this,'projects','<% =callTypeID %>')" style="<% =projectStyleText %>">
							</td>
							
							
							<td>
								<input type=text data-val="<% =rsNT("id") %>" value="<% =rsNT("seq") %>" onblur="UpdateSequence_onBlur(this)" size="7" style="text-align: center">
							</td>
							
	   					<td>
								<button type="button" id="button_editCallType" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsNT("id") %>" onclick="EditCallTypeAgenda_onClick(this);">
								  <i class="material-icons">mode_edit</i>
								</button>								
								<a href="callTypeAgenda.asp?cmd=delete&id=<% =callTypeID %>&ntID=<% =rsNT("id") %>" onclick="return confirm('Are you sure you want to delete this item?');"><img src="/images/ic_delete_black_24dp_1x.png"></a>
	   					</td>

						</tr>
						<%
						rsNT.movenext 
					wend 
					rsNT.close 
					set rsNT = nothing 
					set cmdSelect = nothing 
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

	var dialog_addCTA = document.querySelector('#dialog_addCTA');
	var button_newCTA = document.querySelector('#button_newCTA');	
	
	if (! dialog_addCTA.showModal) {
		dialogPolyfill.registerDialog(dialog_addCTA);
	}
		
	button_newCTA.addEventListener('click', function() {
		dialog_addCTA.showModal();
	});
	
	dialog_addCTA.querySelector('.cancel').addEventListener('click', function() {
		dialog_addCTA.close();
	});

	dialog_addCTA.querySelector('.save').addEventListener('click', function() {
// 		document.forms["form_addCTA"].submit();
		AddCTA_onSave(dialog_addCTA);
		dialog_addCTA.close();
	});



</script>

<%
dataconn.close 
set dataconn = nothing
%>
</body>
</html>