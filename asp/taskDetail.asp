 <!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/randomString.asp" -->
<!-- #include file="includes/md5.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/formatDate.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/workDaysBetween.asp" -->
<!-- #include file="includes/workDaysAdd.asp" -->
<!-- #include file="includes/taskDaysAtRisk.asp" -->
<!-- #include file="includes/taskDaysBehind.asp" -->
<!-- #include file="includes/taskDaysAhead.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(38)
	
userLog("Task detail")
dbug("start of top-logic")

taskID = request("taskID")

if len(request("customerID")) > 0 then 
	customerID 	= request("customerID")
	dbug("querystring customerID: " & customerID & ", validating...")
	%>
	<!-- #include file="includes/validateCustomerAccess.asp" -->
	<%	
end if


projectID  	= request("projectID")
if len(projectID) > 0 then 
	SQL = "select id, name, startDate, endDate, customerID from projects where id = " & projectID & " " 
else 	
	SQL = "select p.id, p.name, p.startDate, p.endDate, p.customerID from projects p join tasks t on (t.projectID = p.id) where t.id = " & taskID & " "
end if 

dbug("project SQL: " & SQL)
set rsProj = dataconn.execute(SQL) 
if not rsProj.eof then 

	customerID			= rsProj("customerID") 
	dbug("project customerID: " & customerID & ", validating...")
	%>
	<!-- #include file="includes/validateCustomerAccess.asp" -->
	<%	
	projectID 			= rsProj("id") 
	projectName 		= rsProj("name")	
	projectStartDate 	= rsProj("startDate")
	projectEndDate 	= rsProj("endDate")
else 
	customerID			= request.querystring("customerID")
	projectID 			= ""
	projectName 		= "No Project" 
	projectStartDate 	= ""
	projectEndDate 	= ""
end if
rsProj.close 
set rsProj = nothing 




' currentDate - current date formatted as YYYY-MM-DD for use in max attribute of completionDate input field...
currentYYYY = year(date())
currentMM	= month(date())
currentDD	= day(date())
currentDate = currentYYYY & "-" & currentMM & "-" & currentDD
	




http_host		= request.serverVariables("HTTP_HOST")
http_referer 	= request.serverVariables("HTTP_REFERER")

linkBack 		= replace(replace(http_referer, "HTTP://", ""), "HTTPS://", "")
linkBack			= replace(linkBack, http_host, "")
linkBack			= replace(linkBack, "/", "")


 
title = session("clientID") & " - <a href=""/customerList.asp"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""customerTasks.asp?id=" & customerID & """>" & customerTitle(customerID) & "</a>"

' if projectName = "No Project" then 
' ' 	title = title & projectName & "<img src=""images/ic_chevron_right_white_18dp_2x.png"">" 
' else 
' 	title = title & "<a href=""/taskList.asp?id=" & projectID & """>" & projectName & "</a>" 
' end if 

title = title & "<img src=""images/ic_chevron_right_white_18dp_2x.png"">Edit A Task"

dbug("end of top-logic")

'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************


SQL = "select " &_
			"t.name as taskName, " &_
			"t.description as taskDescription, " &_
			"t.ownerID as taskOwnerID, " &_
			"t.startDate as taskStartDate, " &_
			"t.dueDate as taskDueDate, " &_
			"t.completionDate as taskCompleteDate, " &_
			"t.acceptanceCriteria, " &_
			"t.projectID, " &_
			"p.name as projectName, " &_
			"p.startDate as projectStartDate, " &_
			"p.endDate as projectEndDate, " &_
			"p.completeDate as projectCompleteDate, " &_
			"cs.name as customerStatusName, " &_
			"p.id as projectID, " &_
			"ps.statusDate as projectStatusDate, " &_
			"ps.type as projectStatus, " &_
			"t.taskStatusID, " &_
			"ts.name as taskStatusName, " &_
			"t.skippedReason, " &_
			"t.customerID, " &_
			"ki.kiCompletedCount " &_
		"from tasks t " &_
		"left join taskStatus ts on (ts.id = t.taskStatusID) " &_
		"left join projects p on (p.id = t.projectID) " &_
		"left join customer_view c on (c.id = t.customerID) " &_
		"left join customerStatus cs on (cs.id = c.customerStatusID) " &_
		"left join " &_
			"( " &_
			"select top 1 id, projectID, statusDate, type " &_
			"from projectStatus " &_
			"order by id desc " &_
			") ps on (ps.projectID = t.projectID) " &_
		"outer apply ( " &_
			"select count(*) as kiCompletedCount " &_
			"from keyInitiativeTasks a " &_
			"join keyInitiatives b on (b.id = a.keyInitiativeID) " &_
			"where a.taskID = t.id " &_
		") as ki " &_
		"where t.id = " & taskID & " "

dbug(SQL)
set rsTask = dataconn.execute(SQL)
if not rsTask.eof then

	dbug("task customerID: " & rsTask("customerID")) 
	if len(rsTask("customerID")) > 0 then 
		customerID = rsTask("customerID")
		%>
		<!-- #include file="includes/validateCustomerAccess.asp" -->
		<%	
	end if 
		

	dbug("task found, getting project status...")

	if len(rsTask("projectID")) > 0 then 
		
		SQL = "select top 1 " &_
					"statusDate, " &_
					"type as status " &_
				"from projectStatus " &_
				"where projectID = " & rsTask("projectID") & " " &_
				"order by updatedDateTime desc "
		dbug(SQL) 
		set rsProj = dataconn.execute(SQL) 

		if not rsProj.eof then 

			projectStatus		= rsProj("status") 
			projectStatusDate	= rsProj("statusDate")

			if lcase(projectStatus) = "complete" then 
				projectCompleted 	= true 
				disabled 			= " disabled " 
			else 
				projectCompleted 	= false 
				if len(rsTask("taskCompleteDate")) > 0 then 
					taskCompleted 		= true 
					disabled 			= " disabled " 
				else 
					taskCompleted 		= false 
					disabled 			= ""
				end if
			end if

		else 

			projectStatus 			= ""
			projectStatusDate		= ""
			projectCompleted		= false 

			if len(rsTask("taskCompleteDate")) > 0 then 
				taskCompleted 		= true 
				disabled 			= " disabled " 
			else 
				taskCompleted 		= false 
				disabled 			= ""
			end if

		end if
		
	else 
		
		projectStatus 		= ""
		projectStatusDate = ""
		projectCompleted 	= false 
	
		if len(rsTask("taskCompleteDate")) > 0 then 
			taskCompleted 		= true 
			disabled 			= " disabled " 
		else 
			taskCompleted 		= false 
			disabled 			= ""
		end if

	end if 

else 
	
	dbug("task NOT found.")

	response.write("TASK NOT FOUND")
	response.end
	
end if

dbug("checking completeability...")
if isNull(rsTask("taskCompleteDate")) then 
	
	'-------------------------------------------------------------------------------
	'	if there is no taskCompleteDate, completion is allowable when:
	'		- all checkslistItems are complete
	'		- all checklists are complete
	'-------------------------------------------------------------------------------
	SQL = "select count(*) as uncompletedChecklists " &_
			"from taskChecklists " &_
			"where (completed = 0 or completed is null) " &_
			"and taskID = " & taskID & " " 
	set rsCL = dataconn.execute(SQL) 
	if not rsCL.eof then 
		if cInt(rsCL("uncompletedChecklists")) > 0 then 
			dbug("completionAllowed is false because there are incomplete checklist(s)")
			completionAllowed = false 
		else 
			SQL = "select count(*) as uncompletedItems " &_
					"from taskChecklistItems " &_
					"where (completed = 0 or completed is null) " &_
					"and checklistID in ( " &_
						"select id " &_
						"from taskChecklists " &_
						"where taskID = " & taskID &_
					") "
			set rsCLI = dataconn.execute(SQL) 
			if not rsCLI.eof then 
				if cInt(rsCLI("uncompletedItems")) > 0 then 
					dbug("completionAllowed is false because there are incomplete checklist items")
					completionAllowed = false 
				else 
					completionAllowed = true 
				end if 
			else 
				CompletionAllowed = true 
			end if 
			rsCLI.close 
			set rsCLI = nothing 
		end if 
		rsCL.close 
		set rsCL = nothing 
	else 
		completionAllowed = true
	end if
		
else 
	
	dbug("completionAllowed is false because there is already a completion date")
	completionAllowed = false

	'-------------------------------------------------------------------------------
	'	if there is a taskCompleteDate, UnCompletion is allowable when:
	'		- There are no associated project/KIs that are complete
	'-------------------------------------------------------------------------------

	dbug("checking uncompletability...")
	if ( rsTask("projectStatus") <> "Complete" OR isNull(rsTask("projectStatus")) ) then 

		dbug("rsTask('kiCompletedCount'): " & rsTask("kiCompletedCount"))
		if ( cInt(rsTask("kiCompletedCount")) ) <= 0 then 

			if userPermitted(45) then 
				dbug("user has permission(45), so unCompletionAllowed will be TRUE")
				unCompletionAllowed = true 
			else 
				dbug("user does not have permission(45), so unCompletionAllowed will be FALSE")
				unCompletionAllowed = false
			end if 
			
		else 
			
			dbug("completed KI(s) present, so unCompletionAllowed will be FALSE")
			unCompletionAllowed = false
			
		end if 

	else 

		dbug("rsTask('projectStatus') = 'Complete' ")
		unCompletionAllowed = false

	end if

	dbug("done checking uncompletability")

		
end if


%>

<html>

<head>
	
	<title></title>

	<!-- #include file="includes/globalHead.asp" -->
	
	<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/moment-timezone/0.5.33/moment-timezone-with-data.min.js"></script>

	<!-- Quill.js Stylesheet and Library -->
<!--
	<script src="//cdn.quilljs.com/1.3.6/quill.js"></script>
	<link href="//cdn.quilljs.com/1.3.6/quill.snow.css" rel="stylesheet">
-->
	
	<script src="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js"></script>
	<link href="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css" rel="stylesheet">

	
	<script src="https://cdn.jsdelivr.net/npm/dayjs@1/dayjs.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/date-holidays@3/dist/umd.min.js"></script>
	
	<script>
	
		// Find the real constructor no matter how the UMD wrapped it
		const HolidaysCtor =
			( window.Holidays && ( window.Holidays.default || window.Holidays ) ) ||
			( window.DateHolidays && ( window.DateHolidays.default || window.DateHolidays ) );
		
		if ( typeof HolidaysCtor !== 'function' ) {
			console.error( 'date-holidays v3 UMD loaded but no constructor found:', window.Holidays );
		} else {
			// expose for later code on the page
			window.hd = new HolidaysCtor( 'US' ); // or 'US-MN'
		}
	
	</script>
	

	<script src="script/taskDetail.js"></script>

	
	
	<script>
	
		const customerID = '<% =customerID %>';
		const taskID = '<% =taskID %>';
		
	</script>	
	
	<style>

/* for jQuery UI */
label, input { display:block; }
input.text { margin-bottom:12px; width:95%; padding: .4em; }
fieldset { padding:0; border:0; margin-top:25px; }
h1 { font-size: 1.2em; margin: .6em 0; }
.ui-dialog .ui-state-error { padding: .3em; }
.validateTips { border: 1px solid transparent; padding: 0.3em; }
/* END for jQuery UI */

.ui-widget-content {
	font-family: "Helvetica","Arial",sans-serif;
}

textarea.ui-widget-content {
	font-size: 14px !important;
	font-weight: 400;
}

label.dialogLabel {
	font-weight: bold;
}

table.workDays, table.details, table.projectStatus {
	border-collapse: collapse;
	width: 100%;
}

table.details td {
	padding-bottom: 8px;
}

th.workDays, td.workDays {
	border: solid rgba(0, 0, 0, 0.33) 1px;
	padding: 5px;
	text-align: right;
}

th.projectStatus, td.projectStatus {
	border: solid rgba(0, 0, 0, 0.33) 1px;
	padding: 5px;
	text-align: left;
}

td.rowHeading {
	padding: 5px;
	text-align: right;
	font-weight: bold;
}

th.details {
	padding: 5px;
	text-align: left;
}

.truncate {
	max-width: 400px; 
	white-space: nowrap; 
	overflow: hidden;
	text-overflow: ellipsis;
}

div.checklists {
	margin: 5px;
	width: 100%;
	display: inline-block;
	vertical-align: top;
}

i.checklistControlIcon {
	visibility: hidden;
}

th.checklistControls {
	text-align: right;
	vertical-align: top;
	white-space: nowrap;
	width: 3%;
}

th.checklistControls i, 
i.deleteChecklistItem, 
td.checklistItemCheckbox i,
#addChecklist {
	cursor: pointer;
}

td.checklistItemControls {
	text-align: right;
	vertical-align: top;
	white-space: nowrap;
	width: 2%;
}

th.checklistName {
	padding-top: 3px;
	text-align: left;
	vertical-align: top;
	width: 96%;
}

th.checklistCheckbox {
	text-align: left;
	vertical-align: top;
	width: 2%;
}

td.checklistItemCheckbox {
	text-align: left;
	vertical-align: top;
	white-space: nowrap;
	width: 2%;
}

td.checklistItemName {
	text-align: left;
	vertical-align: top;
	width: 96%;
}

table.checklist {
	border: solid rgba(0, 0, 0, 0.33) 1px;
	border-collapse: collapse;
	border-radius: 10px;
	display: inline-block;
	margin-right: 10px;
	margin-bottom: 20px;
	padding: 8px 8px 8px 8px;
	vertical-align: top;
	width: 99%;
}

i.deleteChecklistItem {
	float: right;
}

i.placeholder {
	display: inline-block;
	width: 24px;
	height: 24px;
}

#addChecklist {
	cursor: pointer;
}

#taskOverview, #taskOverview td, #taskOverview div {
	width: 100%;
}


#taskOverview td {
    box-sizing: border-box;
    padding: 0; /* Adjust as needed */
}



#taskOverview textarea {
	width: 100%;
}

/* styles for Jira-like editing of individual fields */

/* Hide the input and buttons in view mode */

.checklistHeader .edit-mode, 
.checklistItem .edit-mode,
.taskName .edit-mode,
.taskDescription .edit-mode,
.taskSkippedReason .edit-mode
{
	display: none;
}

.checklistHeader .view-mode, 
.checklistItem .view-mode,
.taskName .view-mode,
.taskDescription .view-mode,
.taskSkippedReason .view-mode
{
	display: block;
	cursor: pointer;
}

.checklistHeader.editing .edit-mode, 
.checklistItem.editing .edit-mode,
.taskName.editing .edit-mode,
.taskDescription.editing .edit-mode,
.taskSkippedReason.editing .edit-mode
{
	display: block;
}

.checklistHeader.editing .view-mode, 
.checklistItem.editing .view-mode,
.taskName.editing .view-mode,
.taskDescription.editing .view-mode,
.taskSkippedReason.editing .view-mode
{
	display: none;
}

/*
.view-mode.task {
	margin: 3px 0px 20px 20px !important;
	border: solid black 1px;
	width: 100%;
	max-width: 100%;
	box-sizing: border-box;
	overflow: hidden;
}
*/
.view-mode.task {
    margin: 3px 0px 20px 0px !important; /* Remove left margin */
    border: solid black 1px;
    width: 100%;
    max-width: 100%;
    min-height: 20px;
    box-sizing: border-box;
    overflow: hidden;
}



.edit-mode.task > textarea {
	text-align: left !important;
	width: 100%;
	box-sizing: border-box;
	min-height: 20px;
}

.edit-mode.task > button {
	float: right;
}

.view-mode.checklist {
	margin: 3px 5px 0px 5px !important;
}

.edit-mode.checklist > textarea {
	float: left !important;
	width: 100%;
	box-sizing: border-box;
}

.edit-mode.checklist > button {
	float: right !important;
}

#quillAcceptanceCriteria {
	float: right !important;
	border: solid black 1px !important;
	min-height: 20px;
}

.edit-mode.acceptanceCriteria button {
	float: right !important;
}	


/* END: styles for Jira-like editing of inidivisual fields */



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

		<!-- DIALOG: Reason Skipped -->
		<dialog id="dialog_skippedReason" class="mdl-dialog" style="width: 800px;">
			<h4 class="mdl-dialog__title">Reason Skipped</h4>
			<p style="margin-left: 25px; margin-top: 10px;">Please provide rationale for skipping this task.</p>
			<div class="mdl-dialog__content">

				<div id="skippedReasonContainer">
					<div id="skippedReason"></div>
				</div>
					
				<input id="customerID" name="customerID" type="hidden" value="">
				<input id="skippedReasonTaskID" name="skippedReasonTaskID" type="hidden" value="<% =taskID %>">
	
			</div>
			<div class="mdl-dialog__actions">
				<button type="button" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog><!-- DIALOG: Skipped Reason -->
		


		<div id="addChecklist" title="Add Checklist">
			<label for="add_checklistName">Checklist name...</label>
			<input type="text" id="add_checklistName" class="text ui-widget-content ui-corner-all" value="">
		</div>
		
		<div id="deleteChecklist" title="Delete the checklist?">
			<p><span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>The checklist and its items will be permanently deleted and cannot be recovered. Are you sure?</p>
		</div>		
		
		<div id="addChecklistItem" title="Add Checklist Item">
			<label for="add_checklistItemName">Checklist item name...</label>
			<input type="text" id="add_checklistItemName" class="text ui-widget-content ui-corner-all" value="">
		</div>

		<div id="deleteChecklistItem" title="Delete the checklist item?">
			<p><span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>The checklist item will be permanently deleted and cannot be recovered. Are you sure?</p>
		</div>		
		
		
				
		
		<!-- the big, outer grid -->
		<div class="mdl-grid" >
			<div class="mdl-layout-spacer"></div>
			<div id="mainContainer" class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 5px;">
				
				<table id="taskOverview">

					<tr>
						<td class="mdl-typography--title" align="left" width="90%">Task Name</td>
					</tr>
					<tr class="taskName editable">
						<td>
							<div class="edit-mode task">
								<textarea></textarea>
				            <button class="save-button edit"><span class="material-symbols-outlined">check</span></button>
				            <button class="cancel-button edit"><span class="material-symbols-outlined">close</span></button>
							</div>
							<div class="view-mode task"></div>
						</td>
					</tr>

					<tr><th class="mdl-typography--title" align="left">Description</th></tr>
					<tr class="taskDescription editable">
						<td>
							<div class="edit-mode task">
								<textarea></textarea>
				            <button class="save-button edit"><span class="material-symbols-outlined">check</span></button>
				            <button class="cancel-button edit"><span class="material-symbols-outlined">close</span></button>
							</div>
							<div class="view-mode task"></div>
						</td>
					</tr>

					<tr><th class="mdl-typography--title" align="left">Skipped Reason</th></tr>
					<tr class="taskSkippedReason editable">
						<td>
							<div class="edit-mode task">
								<textarea></textarea>
				            <button class="save-button edit"><span class="material-symbols-outlined">check</span></button>
				            <button class="cancel-button edit"><span class="material-symbols-outlined">close</span></button>
							</div>
							<div class="view-mode task"></div>
						</td>
					</tr>



					<tr><th class="mdl-typography--title" align="left">Conditions of Satisfaction</th></tr>
					<tr class="taskConditionsOfSatisfaction quillable">
						<td>
							<div id="quillAcceptanceCriteria" style="border: solid black 1px !important;"></div>
							<div class="edit-mode acceptanceCriteria">
								<div id="originalAcceptanceCriteria" style="display: none;"></div>
								<div>
					            <button class="save-button edit"><span class="material-symbols-outlined">check</span></button>
					            <button class="cancel-button edit"><span class="material-symbols-outlined">close</span></button>
								</div>
							</div>
						</td>
					</tr>





				</table>


				<%
				if len(rsTask("taskStatusID")) then 
					if cInt(rsTask("taskStatusID")) = 3 then 
						showSkippedReason = "block"
					else 						
						showSkippedReason = "none"
					end if 
				else 
					showSkippedReason = "none"
				end if
				%>
				


				<br>
				<div id="taskChecklists">
					<div class="mdl-typography--title">
						Checklists&nbsp;
						<span id="addChecklist" class="material-symbols-outlined" style="vertical-align: middle;" title="Add a new checklist">assignment_add</span>
					</div>
				</div>





			</div>
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="padding: 5px;">
				
				<table class="details">
					<tbody>
						<tr>
							<td class="rowHeading">Owner</td>
							<td><select id="newTaskOwner"></select></td>
						</tr>
						<tr>
							<td class="rowHeading">Start Date</td>
							<td><div title=""><input type="text" id="startDate"></div></td>
						</tr>
						<tr>
							<td class="rowHeading">Due Date</td>
							<td><div title=""><input type="text" id="dueDate"></div></td>
						</tr>
						<tr>
							<td class="rowHeading">Status</td>
							<td><select id="newTaskStatus"></select></td>
						</tr>
						<tr style="visibility: hidden;">
							<td class="rowHeading">Completion Date</td>
							<td><input type="text" id="newCompletionDate" class="dateTime" disabled></td>
						</tr>

					</tbody>
				</table>

				<br>
								
				<table class="workDays">
					<thead>
						<tr>
							<th colspan="4" class="workDays" style="text-align: center;">Work Days...</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<th class="workDays">Estimated</th><td class="workDays"><div id="newEstimatedWorkDays"></div></td>
							<th class="workDays">Actual</th><td class="workDays"><div id="newActualWorkDays"></div></td>
						</tr>
						<tr>
							<th class="workDays">Ahead</th><td class="workDays"><div id="newWorkDaysAhead"></div></td>
							<th class="workDays">Behind</th><td class="workDays"><div id="newWorkDaysBehind"></div></td>
						</tr>
						<tr>
							<th class="workDays">At Risk</th><td class="workDays"><div id="newWorkDaysAtRisk"></div></td>
						</tr>
					</tbody>
				</table>

				<br>
								
				<table id="projectInfo" class="projectStatus">
					<thead>
						<tr>
							<th colspan="4" class="projectStatus" style="text-align: center;">Project Info</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<th class="projectStatus">Name</th>
							<td class="projectStatus" align="left"><div id="projectName"></div></td>
						</tr>
						<tr>
							<th class="projectStatus">Start Date</th>
							<td class="projectStatus" align="left"><div id="projectStartDate"></div></td>
						</tr>
						<tr>
							<th class="projectStatus">End Date</th>
							<td class="projectStatus" align="left"><div id="projectEndDate"></div></td>
						</tr>
						<tr>
							<th class="projectStatus">Status</th>
							<td class="projectStatus" align="left"><div id="projectStatus"></div></td>
						</tr>
						<tr>
							<th class="projectStatus">Status Date</th>
							<td class="projectStatus" align="left"><div id="projectStatusDate"></div></td>
						</tr>
					</tbody>
				</table>
				
				<br>
				
				<table id="taskKeyInitiatives" class="compact display">
					<thead>
						<th class="name">Key Initiatives</th>
						<th class="completeDate">Complete</th>
					</thead>
				</table>
	




			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
		
		
		<%
		dbug("just prior to CoS, disabled: " & disabled)
		%>
		
		
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--5-col">
				

				
<!-- 				<div class="mdl-typography--title"> -->
				
								
			</div><!-- conditions of satifaction -->

						
			<div class="mdl-layout-spacer"></div>
			
		</div><!-- conditions of satifaction, project info, key initiatives -->

		<input type="hidden" id="projectStartDate" value="<% =projectStartDate %>">
		<input type="hidden" id="projectEndDate" value="<% =projectEndDate %>">
		

		
	</div><!-- END page-content -->


</main>



<!-- #include file="includes/pageFooter.asp" -->


<%
rsTask.close 
set rsTask = nothing 


dataconn.close 
set dataconn = nothing
%>

</body>
</html>