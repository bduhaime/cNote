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
call checkPageAccess(6)

userLog("Events")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Events"

dbug(" ")
dbug("start of script....")

dbug("request.querystring('cmd'): " & request.querystring("cmd"))

select case request.querystring("cmd")

	case "delete"
	
		dbug("delete detected")
		
		SQL = "delete from event where id = " & request.querystring("id") & " " 
		
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
	<script type="text/javascript" src="event.js"></script>

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
		<dialog id="dialog_event" class="mdl-dialog" data-role='popup' data-history='false' >
			<h4 class="mdl-dialog__title">Events</h4>
			<div class="mdl-dialog__content">
		
				<form id="form_event">


					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="eventName" value="" required autocomplete="off">
					    <label class="mdl-textfield__label" for="eventName">Event name...</label>
					</div>
	
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <textarea class="mdl-textfield__input" id="eventDescription" value="" rows="5" autocomplete="off"></textarea>
					    <label class="mdl-textfield__label" for="eventDescription">Event description...</label>
					</div>
	
					<input type="hidden" id="eventID" value="">

				</form>

			</div>
			<div class="mdl-dialog__actions">
				<button type="submit" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog>
	  

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col" align="left">
				<button id="button_newEvent" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Event
				</button>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
			
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col" align="center">


				<table id="tbl_clientProjects" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">Name</th>
							<th class="mdl-data-table__cell--non-numeric">Description</th>
							<th class="mdl-data-table__cell--non-numeric" style="text-align: center">Actions</th>
						</tr>
					</thead>
			  		<tbody> 
				  	<%
					SQL = "select id, name, description, active from event order by name "
							
					dbug(SQL)
					set rsEvent = dataconn.execute(SQL)
					while not rsEvent.eof
					  	%>
						<tr>
							<td class="mdl-data-table__cell--non-numeric"><% =rsEvent("name") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rsEvent("description") %></td>
	   					<td class="mdl-data-table__cell--non-numeric" align="center">

								<button type="button" id="button_editCallType" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsEvent("id") %>" onclick="EditCustomerStatus_onClick(this);">
								  <i class="material-icons">mode_edit</i>
								</button>								
								
								<a href="eventList.asp?cmd=delete&id=<% =rsEvent("id") %>" onclick="return confirm('Are you sure you want to delete this item?');"><img src="/images/ic_delete_black_24dp_1x.png"></a>
	   					</td>
						</tr>
						<%
						rsEvent.movenext 
					wend 
					rsEvent.close 
					set rsEvent = nothing 
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
	var dialog_event = document.querySelector('#dialog_event');
	var button_newEvent = document.querySelector('#button_newEvent');	
	if (! dialog_event.showModal) {
		dialogPolyfill.registerDialog(dialog_event);
	}	
	button_newEvent.addEventListener('click', function() {
		dialog_event.showModal();
	});
	dialog_event.querySelector('.cancel').addEventListener('click', function() {
		dialog_event.close();
	});

	dialog_event.querySelector('.save').addEventListener('click', function() {
		document.forms["form_event"].submit();
		addEvent(dialog_event);
// 		dialog_addCCT.close();
	});


</script>

<%
dataconn.close 
set dataconn = nothing
%>
</body>
</html>