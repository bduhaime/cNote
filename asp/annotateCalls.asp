<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLOg.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/getNextID.asp" -->
<!-- #include file="includes/escapeQuotes.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->

<% 
call checkPageAccess(57)


quillTrade 	= chr(226) & chr(132) & chr(162)

customerID 		= request.querystring("customerID")
callID			= request.querystring("callID")

%>


<!-- #include file="includes/validateCustomerAccess.asp" -->

<%	

userLog("Annotate a call")

	
'===============================================================================
'===============================================================================
'===============================================================================
'===============================================================================
'===============================================================================



dbug("edit existing call...")
customerID = request.querystring("customerID")
customerCallID = request.querystring("callID")
callMode = "existing"
		
		
http_host		= request.serverVariables("HTTP_HOST")
http_referer 	= request.serverVariables("HTTP_REFERER")

linkBack 		= replace(replace(http_referer, "HTTP://", ""), "HTTPS://", "")
linkBack			= replace(linkBack, http_host, "")
linkBack			= replace(linkBack, "/", "")

dbug("linkBack: " & linkBack)


' title = customerTitle(customerID)
title = session("clientID") & " - <a href=""customerList.asp"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""" & linkBack & """>" & customerTitle(customerID) & "</a>"
 

if userPermitted(114) then 
	dbug("userPermitted(114) is true")
	disableAllEdits = "" 
else 
	dbug("userPermitted(114) is false")
	if not isNull(endDateTime) then 
		dbug("endDateTime isNull() is false")
		if len(endDateTime) > 0 then 
			dbug("endDateTime len() > 0")
			disableAllEdits = " disabled"
		else 
			dbug("endDateTime len() <= 0")
			disableAllEdits = "" 
		end if 
	else 
		dbug("endDateTime isNull() is false") 
		disableAllEdits = "" 
	end if
end if 
dbug("-->")
dbug("scheduledStartTime=" & scheduledStartTime)
dbug("scheduledEndTime=" & scheduledEndTime)
dbug("-->")
			

%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />

<!-- 	<script src="moment.min.js"></script> -->
	<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/moment-timezone/0.5.33/moment-timezone-with-data.min.js"></script>

	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>


	<!-- Quill.js Stylesheet and Library -->
	<script src="//cdn.quilljs.com/1.3.6/quill.js"></script>
	<link href="//cdn.quilljs.com/1.3.6/quill.snow.css" rel="stylesheet">

	
	<script type="text/javascript" src="script/annotateCalls.legacy.js"></script>
	<script type="text/javascript" src="script/annotateCalls.js"></script>

	


	<script>
		
		const disableAllEdits 	= '<% =disableAllEdits %>';	// querystring

	</script>

	
	<style>
		
		.divTable{
			display: table;
			width: 100%;
		}
		
		.divTableRow {
			display: table-row;
		}
		
		.divTableHeading {
			background-color: #EEE;
			display: table-header-group;
		}
		
		.divTableCell, .divTableHead {
/* 		border: 1px solid #999999; */
			display: table-cell;
			padding: 3px 10px;
		}
		
		.divTableHeading {
			background-color: #EEE;
			display: table-header-group;
			font-weight: bold;
		}
		
		.divTableFoot {
			background-color: #EEE;
			display: table-footer-group;
			font-weight: bold;
		}
		
		.divTableBody {
			display: table-row-group;
		}
		
		span.mdl-chip__text {
			width: 250px;
		}

		
			.csuite-textfield span {
				font-size: 12px;
				font-weight: 400;
				color: rgb(103, 58, 183)
			}
			
			.csuite-textfield {
				margin-top: 5px;
				display: inline-block; 
				float: left
			}
			
			.csuite-textfield i.edit {
				vertical-align: bottom;
				color: rgb(103, 58, 183);
				visibility: hidden;
				cursor: pointer;
			}
			
			.csuite-textfield-viewValue {
				font-size: 16px; 
				height: 25px;
				margin-top: 3px;
				border-bottom: solid lightgrey 1px;
				cursor: pointer;
			}
			
			.csuite-textfield-viewValue.is-invalid, .csuite-textfield__input.is-invalid {
				color: crimson;
			}
			
			.csuite-textfield-editValue {
				display: none;
			}
			
			.csuite-textfield-editValue input, .csuite-textfield-editValue textarea {
				font-size: 16px;
				font-weight: 400;
				width: 99%;
			}
			
			.csuite-textfield__editControls {
				float: right;
			}
			
			.csuite-textfield__editControls.placeHolder {
				float: right;
				height: 34px;
				visibility: hidden;
			}
			
			.csuite-textfield.notEditable i {
				display: none;
			}
			
			.csuite-textfield.notEditable input, csuite-textfield.notEditable textarea {
				disabled: disabled;
			}

			input[type="time"]::-webkit-clear-button {
			    display: none;
			}

			input[type="date"]::-webkit-clear-button {
			    display: none;
			}

		table.dataTable tr:hover {
			cursor: pointer;
		}
		
		.ql-editor > ul:hover {
			cursor: pointer;
		}
		
		#genericQuillNote {
			max-height: 375px;
			overflow: scroll;
		}

		table th.toList, table td.toList {
			max-width: 300px; 
			min-width: 70px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; }
		}
		
		#clientAttendeeList {
			margin: 15px;
		}
		
		span.clientAttendee {
			display: inline-block;
		}
		
		
		.callNoteRow {
			border: solid 2px black;
			width: 100%;
		}
		
/*
		.quill {
			margin-bottom: 20px;
		}
*/
		
		.ql-toolbar {
			display: none;											/* the initial display is none; this is changed by the selection-change event handler */
		}
		
		.ql-editor {
			border-top: 1px solid rgb(204, 204, 204);		/* the initial border-top; this is changed by the selection-change event handler */
		}
		
		.mdl-typography--caption {
			float: right;
		}
		
		.trQuillFooter {
			display: none;
		}
		
		.trQuillFooter td {
			padding-bottom: 20px;
		}

		div.message {
			margin-left: 10px;
			vertical-align: middle;
			height: 57px%;
			color: crimson;
		}	
		
		


		button.startCall1, button.endCall1, button.editUserAttendees, button.editCustomerAttendees {	
			height: 48px;
			width: 48px;
		}

		
		.startCall, .endCall, .editScheduledStart {
			font-size: 35px;
			cursor: pointer;
		}

		button.editUserAttendees, button.editCustomerAttendees {	
			height: 40px;
			width: 40px;
			float: right;
			vertical-align: top;
		}
		
		span.editUserAttendees, span.editCustomerAttendees {
			font-size: 35px;
		}


		.dialogWithDropShadow {
			-webkit-box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.5);  
			-moz-box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.5); 
		}
		
		td.actualStart, td.scheduledStart {
			display: flex;
			align-items: center; 		/* Vertically align items */
			justify-content: left; 		/* Horizontally align items */
			height: 100%; 					/* Set the height of the container */
		}			
		
		
</style>		
		

</head>



<body>

	<div style="display: none;">placeholder</div>
	
	
<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->

		<!-- Snackbar -->
		<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>
		
		
		<!-- (NEW) DIALOG: Edit Attendees -->
		<div id="editAttendeesDialog" title="Edit Attendees">

			<p>Select attendees you want to invite to the call (or show they were present for the call) then press the SAVE button</p>
									
			<table id="editAttendeesTable">
				<tbody>
				</tbody>
			</table>
			
			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
			<input type="hidden" id="attendeeType">
  		</div>
		
		
		
		<!-- (NEW) DIALOG: sendCall -->
		<div id="sendCallDialog" title="Send Call Summary Email">

			<div class="ui-widget">
				<label for="subject" style="font-weight: bold">Subject: </label><br>
				<input id="subject" style="width: 99%;">
			</div>
			
			<div style="display: inline-block; vertical-align: top; width: 25%; float: left; margin: 10px;">

				<br>
				<table id="sendContactAttendees">
					<thead>
						<tr>
							<th colspan="2" align="left" style="background-color: rgb(103,58,183); color: rgb(255,255,255); padding: 10px;">To: Customer Contacts</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox5">
								<input type="checkbox" id="checkbox5" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox6">
								<input type="checkbox" id="checkbox6" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox7">
								<input type="checkbox" id="checkbox7" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox8">
								<input type="checkbox" id="checkbox8" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
					</tbody>
				</table>
				
			</div>
			<div style="display: inline-block; vertical-align: top; width: 25%; float: left; margin: 10px;">
	
				<br>
				<table id="sendUserAttendees">
					<thead>
						<tr>
							<th colspan="2" align="left" style="background-color: rgb(255,171,64); padding: 10px;">CC: TEG Users</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox1">
								<input type="checkbox" id="checkbox1" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox2">
								<input type="checkbox" id="checkbox2" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox3">
								<input type="checkbox" id="checkbox3" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
						<tr>
							<td>
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox4">
								<input type="checkbox" id="checkbox4" class="mdl-checkbox__input">
								</label>
							</td>
							<td>
								<span class="mdl-chip">
								<span class="mdl-chip__text">Basic Chip</span>
								</span>							
							</td>
						</tr>
					</tbody>
				</table>
	
			</div>
			
			<div style="display: inline-block; vertical-align: top; width: 40%; float: left; margin: 10px;">

				<br><br>
				<div class="ui-widget">
					<label for="additionalComments" style="font-weight: bold">Additional Comments:</label><br>
					<textarea id="additionalComments" class="ui-widget ui-state-default ui-corner-all" style="width: 98%;" placeholder="Enter additional comments here" rows="10"></textarea>
				</div>

				<br><br>
				<div class="ui-widget">
					<label for="additionalRecipients" style="font-weight: bold">Additional Recipients:</label><br>
					<textarea id="additionalRecipients" class="ui-widget ui-state-default ui-corner-all" style="width: 98%;" placeholder="Separate email addresses with a comma" rows="3"></textarea>
				</div>

			</div>


			
		</div>


		
		<!-- (NEW) DIALOG: NOTE HISTORY -->
		<div id="dialog_callNoteHistory" title="Call Note History">

			<div class="mdl-grid">
				
				<div class="mdl-layout-spacer"></div>
				
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="height: 600px; overflow:scroll; white-space:nowrap;">
					<table id="updatedByTable" class="mdl-data-table mdl-js-data-table" style="width: 100%;"></table>
				</div>

				<div id="quillContainer" class="mdl-cell mdl-cell--8-col narrative" style="height: 555px;">
					
					<div id="historicQuillNote" class="mdl-shadow--2dp currentVersion" style="height: 100%; margin-bottom: 10px;"></div>

					<button id="makeCurrent" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="width: 100%; visibility: visible;" disabled <% =disableAllEdits %>>
						Make this version the &quot;current&quot; version
					</button>

				</div>
				
				<div class="mdl-layout-spacer"></div>
				
			</div><!-- END mdl-grid -->

		</div>



		<!-- NEW scheduled/actual start date/time/timezone, duration and actuals -->
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp" style="padding-top: 15px; padding-left: 30px; padding-right: 15px;">
				
				<div class="mdl-typography--title" style="text-align: center; margin-bottom: 10px;" id="callTypeName"></div>

				<table style="margin-left: auto; margin-right: auto; margin-bottom: 8px;">
					<tr>
						<th class="mdl-typography--title" style="text-align: right;">Scheduled:</th>
						<td class="scheduledStart">
							<span id="scheduledStartDateTime"></span>
							<span id="scheduledDuration"></span>
							<span class="material-symbols-outlined editScheduledStart" title="Click to edit the scheduled/actual start/end dates and times" style="display: none;">edit</span>
						</td>
					</tr>
					<tr>
						<th class="mdl-typography--title" style="text-align: right;">Actual:</th>
						<td class="actualStart">
							<span id="actualStartDateTime"></span>
							<span id="actualDuration"></span>
							<span class="material-symbols-outlined endCall" style="display: none;" title="Click to stop the call timer">stop_circle</span>
							<span class="material-symbols-outlined startCall" style="display: none;" title="Click to start the call timer">play_circle</span>
						</td>
					</tr>
				</table>							

			</div>
				
						
			<!-- SEND RECAP/AGENDA -->
			<% 
			if len(actualStartTime) > 0 then 
				if len(actualEndTime) <= 0 or isNull(actualEndTime) then 
					sendType = "Agenda"
				else 
					sendType = "Recap"
				end if
			else 
				sendType = "Agenda"
			end if
			%>
			<div class="mdl-cell mdl-cell--1-col mdl-shadow--2dp" align="center">
				<div id="sendTitleBody" class="mdl-typography--title" style="margin-top: 15px"></div>
				<div id="sendCallIcon">
					<span class="material-icons" style="cursor: pointer; font-size: 48px;" oncontextmenu="PrepSendDialog('<% =callName %>','<% =scheduledStartDateTime %>','<% =startDatetime %>','<% =timezoneName %>')">forward_to_inbox</span>
				</div>
			</div><!-- Send -->
						
			<div class="mdl-layout-spacer"></div>

   	</div>



		<!-- Attendees, and Notes  -->
   	<div class="mdl-grid">
			
			<div class="mdl-layout-spacer"></div>

				<!-- TEG Attendees, Call Lead, Customer Attendees, Open Task Status By Owner -->
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
					
 					<!-- Customer Attendees -->
					<div style="margin: 15px;">
						<div class="mdl-typography--title" style="margin-left: 5px">
							Customer Attendees

							<button class="mdl-button mdl-js-button mdl-button--icon mdl-button--colored editAttendees editCustomerAttendees" title="Click to add customer attendees">
								<span class="material-symbols-outlined editCustomerAttendees">person_add</span>
							</button>

						</div>

						<!-- customer attendee container -->
						<table id="customerAttendeeList" width="90%" style="margin: 15px;"></table>
						
						
						<button id="manageCustomerManagers" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--colored" style="width: 100%;" onclick="location='customerContacts.asp?id=<% =customerID %>&tab=contacts';">
							Manage customer contacts...
						</button>
						
					</div><!-- Customer Attendees -->
					<hr>


					<!-- 'user' Attendees -->
					<div style="margin: 15px;">

						<div class="mdl-typography--title" style="margin-left: 5px; margin-bottom: 15px;">
							<% =session("clientID") %> Attendees

							<button class="mdl-button mdl-js-button mdl-button--icon mdl-button--accent editAttendees editUserAttendees" title="Click to add client attendees">
								<span class="material-symbols-outlined editUserAttendees">person_add</span>
							</button>

						</div>

						<!-- 'contact' attendees container -->
						<table id="clientAttendeeList" width="90%" style="margin: 15px;"></table>

						<!-- call lead select container -->
						<div style="margin: 15px;">

							<div style="font-size: 14px; font-weight: 700;">Call Lead</div>
							<select id="clientCallLeadNew" name="clientCallLeadNew">
								<option selected></option>
							</select>
							
						</div>

						<button id="manageCustomerManagers" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" style="width: 100%;" <% =disableAllEdits %> onclick="location='customerManagers.asp?id=<% =customerID %>&tab=contacts';">
							Manage customer managers...
						</button>
							
						
					</div><!-- CLIENT (like TEG) Attendees -->
					<hr>					

					
					<!-- Open Task Status By Owner -->
					<div style="margin: 15px;">
						<div class="mdl-typography--title" style="margin-left: 5px">Open Task Status By Owner</div>
						<table id="openTasks" class="compact display">
							<thead>
								<tr>
									<th class="ownerName">Owner</th>
									<th class="daysBehind">Work Days<br>Behind</th>
									<th class="taskCount"># Tasks</th>
								</tr>
							</thead>
						</table>
						<div style="float: right;">as of <% =date() %></div>

					</div><!-- Open Task Status By Owner -->


				</div>


				<!-- Customer Call Notes -->
				<div class="mdl-cell mdl-cell--7-col mdl-shadow--2dp" style="padding-left: 8px; padding-right: 8px;">
					
					
					<table id="callNotes" width="100%"></table>
					

				</div>

				
			<div class="mdl-layout-spacer"></div>
			
   	</div>


		<!-- Email Log -->
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

				<div class="mdl-cell mdl-cell--7-col">
					
						<div style="text-align: center;">
							<span style="display: inline-block; float: center;"><h5>Email Log</h5></span>
							<span style="float: right; padding: 20px 0;"><a id="displayAs" href="javascript: ToggleDisplayAs()">Show "Sent" as timestamp</a></span>
						</div>
						<table id="tbl_emails" class="compact display">
							<thead>
								<tr>
									<th class="fullName">Sender</th>
									<th class="subject">Subject</th>
									<th class="toList">Recipient</th>
									<th class="addedDateTime">Sent</th>
								</tr>
							</thead>


						</table>
						<br><br>

				</div>

			<div class="mdl-layout-spacer"></div>
   	</div><!-- Send Call Log -->


	</div><!-- end of page content -->

</main>

<!-- #include file="includes/pageFooter.asp" -->


<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>