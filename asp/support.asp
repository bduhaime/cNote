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
<% 
if not userPermitted(32) then response.end() end if
userLog("Support")

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Support" 


dbug("end of top-logic")
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************


%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<script type="text/javascript" src="support.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

	<style>
		
		.ticketDetails, .ticketDetail.tr, ticketDetails.td {
			border: none; 
			padding: 5px;
			
		}


	</style>


</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->


<main class="mdl-layout__content">
	<div class="page-content">
		<!-- Your content goes here -->		

		<div class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button type="button" class="mdl-snackbar__action"></button>
		</div>
		
		
		<!-- DIALOG: Update Project Status -->
		<dialog id="dialog_addTicket" class="mdl-dialog">
			<h4 class="mdl-dialog__title">New Ticket</h4>
			<div class="mdl-dialog__content">
				<form id="form_addTicket">

					<h5>Severity:</h5>
					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="add_severityCritical">
						<input class="mdl-radio__button" id="add_severityCritical" name="add_severity" type="radio" value="critical">
						<span class="mdl-radio__label">Critical</span>
					</label><br>

					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="add_severityHigh">
						<input class="mdl-radio__button" id="add_severityHigh" name="add_severity" type="radio" value="high">
						<span class="mdl-radio__label">High</span>
					</label><br>

					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="add_severityNormal">
						<input checked class="mdl-radio__button" id="add_severityNormal" name="add_severity" type="radio" value="normal">
						<span class="mdl-radio__label">Normal</span>
					</label><br>

					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="add_severityLow">
						<input class="mdl-radio__button" id="add_severityLow" name="add_severity" type="radio" value="low">
						<span class="mdl-radio__label">Low</span>
					</label><br>

					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="add_ticketTitle" name="add_ticketTitle" value="">
					    <label class="mdl-textfield__label" for="add_ticketTitle">Title for this ticket...</label>
					</div>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					    <input class="mdl-textfield__input" type="text" id="add_reportedBy" name="add_reportedBy" value="" pattern="[A-Z,a-z,\-, ]*">
					    <label class="mdl-textfield__label" for="add_reportedBy">Reported by...</label>
					    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
					</div>

					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						<textarea class="mdl-textfield__input" type="text" id="add_narrative" name="add_narrative" rows="5" ></textarea>
						<label class="mdl-textfield__label" for="add_narrative">Narrative...</label>
					</div>

				</form>
			</div>
			<div class="mdl-dialog__actions">
				<button type="button" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog>
  


		
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

<!--
			<div class="mdl-cell mdl-cell--1-col">
				<button id="button_newTicket" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Ticket
				</button>
				<br><br>
				<label for="showDeleted" class="mdl-switch mdl-js-switch">
					<input type="checkbox" id="showDeleted" class="mdl-switch__input">
					<span class="mdl-switch__label">Include Deleted</span>
				</label>
			</div>
-->

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--9-col">

				<button id="button_newTicket" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Ticket
				</button>
				<br><br>
				<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">#</th>
							<th class="mdl-data-table__cell--non-numeric">Name</th>
							<th class="mdl-data-table__cell--non-numeric">Priority</th>
							<th class="mdl-data-table__cell--non-numeric">Category</th>
							<th class="mdl-data-table__cell--non-numeric">Severity</th>
							<th class="mdl-data-table__cell--non-numeric">Assigned</th>
							<th class="mdl-data-table__cell--non-numeric">Status</th>
							<th class="mdl-data-table__cell--non-numeric">Reported By</th>
							<th class="mdl-data-table__cell--non-numeric">Opened</th>
							<th class="mdl-data-table__cell--non-numeric">Actions</th>
						</tr>
					</thead>
					<tbody>
						<%
						SQL = "select t.id, t.title, p.name as priorityName, c.name as categoryName, s.name as severityName, u.firstName, u.lastName, x.name as statusName, t.reportedBy, t.narrative, t.openedDate, t.deleted " &_
								"from supportTickets t " &_
								"left join supportPriorities p on (p.id = t.priorityID) " &_
								"left join supportCategories c on (c.id = t.categoryID) " &_
								"left join supportSeverities s on (s.id = t.severityID) " &_
								"left join cSuite..users u on (u.id = t.assignedID) " &_
								"left join supportStatuses x on (x.id = t.statusID) " &_
								"where (t.deleted = 0 or t.deleted is null) " &_
								"order by openedDate desc " 
						dbug(SQL)
						set rsTix = dataconn.execute(SQL)
						while not rsTix.eof
							%>
							<tr>
								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("id") %></td>

								<td class="mdl-data-table__cell--non-numeric">
									<div style="width: 250px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">
										<% =rsTix("title") %>
									</div>
								</td>

								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("priorityName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("categoryName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("severityName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("firstName") & " " & rsTix("lastName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("statusName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsTix("reportedBy") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rsTix("openedDate")) %></td>

								<td class="mdl-data-table__cell--non-numeric">
									<a href="ticketDetail.asp?id=<% =rsTix("id") %>"><img src="/images/ic_arrow_forward_black_24dp_1x.png"></a>
								</td>

							</tr>
							<%
							rsTix.movenext 
						wend
						rsTix.close 
						set rsTix = nothing 
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
	 
	var dialog_addTicket = document.querySelector('#dialog_addTicket');
	var button_newTicket = document.querySelector('#button_newTicket');
	
	if (! dialog_addTicket.showModal) {
		dialogPolyfill.registerDialog(dialog_addTicket);
	}

	button_newTicket.addEventListener('click', function() {
		dialog_addTicket.showModal();
	});
	dialog_addTicket.querySelector('.cancel').addEventListener('click', function() {
		dialog_addTicket.close();
	});
	dialog_addTicket.querySelector('.save').addEventListener('click', function() {
		AddTicket_onSave(dialog_addTicket)
		dialog_addTicket.close();
	});
	 
  </script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>