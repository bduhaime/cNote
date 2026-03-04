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
<% 
call checkPageAccess(40)

userLog("Project template task detail")
dbug("start of top-logic")

id = request("id")

SQL = "select * " &_
		"from projectTemplateTasks " &_
		"where id = " & id & " " 

dbug(SQL)
set rs = dataconn.execute(SQL)
if not rs.eof then
	projectTemplateID				= rs("projectTemplateID")
	projectTemplateTaskName 	= rs("name")
else 
	projectTemplateTasklName 	= ""
end if



title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""projectTemplateList.asp"">Project Templates</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""projectTemplateTaskList.asp?id=" & projectTemplateID & """>" & projectTemplateTaskName & "</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Project Template Task Detail"


dbug("end of top-logic")
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<script type="text/javascript" src="projectTemplateTaskDetail.js"></script>

	<link href="https://cdn.quilljs.com/1.3.5/quill.snow.css" rel="stylesheet">
	
	<script>
		
		$( function() {
	
			$( document ).tooltip();
			
		});
				
	</script>

</head>
<% dbug("completed 'HTML <head>' ") %>

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


		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--6-col">
		
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%">
				    <input  class="mdl-textfield__input" type="text" id="taskName" value="<% =rs("name") %>" disabled>
				    <label class="mdl-textfield__label" for="taskName">Task name...</label>
				</div>
		
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
				    <textarea class="mdl-textfield__input" type="text" rows="3" id="taskDescription" disabled><% =rs("description") %></textarea>
				    <label class="mdl-textfield__label" for="taskDescription">Task description...</label>
				</div>
				
			</div>
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--2-col">
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="number" id="startOffsetDays" value="<% =rs("startOffsetDays") %>" disabled>
				    <label class="mdl-textfield__label" for="startDate">Start offset (days)...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="number" id="endOffsetDays" value="<% =rs("endOffsetDays") %>" disabled>
				    <label class="mdl-textfield__label" for="endOffsetDays">End offset (days)...</label>
				</div>
			</div>			
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--2-col">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="number" id="taskDurationDays" value="<% =rs("taskDurationDays") %>" disabled>
				    <label class="mdl-textfield__label" for="taskDurationDays">Task duration (days)...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="number" id="estimatedWorkDays" value="<% =rs("estimatedWorkDays") %>"disabled>
				    <label class="mdl-textfield__label" for="estimatedWorkDays">Estimated work days...</label>
				</div>

			</div>


			<div class="mdl-layout-spacer"></div>
		</div>
		


		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--9-col">
				
				<div class="mdl-typography--title" style="color: lightgrey;">
					Conditions of Satisfaction
				</div>
				
				<div id="acceptanceCriteriaPromptContainer" style="display: none;">
					<div id="acceptanceCriteriaPrompt" style="border: solid lightgrey 1px;"></div>
				</div>


				<div id="acceptanceCriteriaInputContainer" style="display: block;">
					<div id="acceptanceCriteriaInputQuillContainer" style="border: solid lightgrey 1px; color: lightgrey;">
						<div id="acceptanceCriteriaHTML" style="margin: 15px;">acceptanceCriteriaHTML</div>
					</div>
				</div>
								
								
			</div>
			<div class="mdl-layout-spacer"></div>
			
		</div>

		

	</div>

		<%
		SQL = "select count(*) as checklistCount from projectTemplateTaskChecklists where projectTemplateTaskID = " & id & " " 
		dbug(SQL)
		set rsChecklistCount = dataconn.execute(SQL)
		if not isNull(rsChecklistCount("checklistCount")) then 
			checkListCount = rsChecklistCount("checklistCount")
		else 
			checkListCount = 0
		end if
		rsChecklistCount.close 
		set rsChecklistCount = nothing 


		const listsPerRow = 4 								' this is the maximum number of lists in a single row of checklists
		numberOfRows = checklistCount \ listsPerRow	' this is the initial number of rows needed
			if (numberOfRows mod listsPerRow) > 0 then	' this accounts for partial row at the end
			numberOfRows = numberOfRows + 1
		end if 


' 		if numberOfRows > 1 then 
			mdlGridSize = "mdl-cell--3-col"
' 		else 
' 			if checkListCount <= 1 then 
' 				mdlGridSize = "mdl-cell--12-col"
' 			elseif checklistCount = 2 then 
' 				mdlGridSize = "mdl-cell--6-col"
' 			elseif checklistCount = 3 then 
' 				mdlGridSize = "mdl-cell--4-col"
' 			else 
' 				mdlGridSize = "mdl-cell--3-col"
' 			end if 
' 		end if
		
		dbug("mdlGridSize = " & mdlGridSize)

		
		SQL = "select id, name from projectTemplateTaskChecklists where projectTemplateTaskID = " & id & " " 
		set rsChecklists = dataconn.execute(SQL)
		
		cellCount = 0			
		while not rsChecklists.eof 

			dbug("cellCount: " & cellCount)
			dbug("cellCount mod listsPerRow: " & cellCount mod listsPerRow)

			if cellCount mod listsPerRow = 0 then 
				%>
				<!-- start a row -->
				<div class="mdl-grid">
					<div class="mdl-layout-spacer"></div>
				<!-- start a row -->
				<%
			end if
			%>
			
				<!-- 	MDL Grid for Checklists  -->
				<div class="mdl-cell <% =mdlGridSize %>">
					<table class="mdl-data-table mdl-shadow--2dp" style="table-layout: fixed; width: 100%;" border="1">
						<thead>

							<tr data-val="<% =rsChecklists("id") %>" bgcolor="lightgrey" onmouseover="ShowDeleteIcon(this)" onmouseout="HideDeleteIcon(this)">
								<th>
									<label id="checklist-<% =rsChecklists("id") %>" data-val="<% =rsChecklists("id") %>" class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect mdl-data-table__select checklist-<% =rsChecklists("id") %> prompt" for="list-<% =rsChecklists("id") %>" style="display: block">
										<input type="checkbox" id="list-<% =rsChecklists("id") %>" class="mdl-checkbox__input " <% =checklistChecked %> disabled />
									</label>
								</th>								
								<th class="mdl-data-table__cell--non-numeric" style="color: white; width: 100%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; -o-text-overflow: ellipsis; padding-left: 55px;" onclick="UpdateChecklistName_onClick(this)">
									<div id="checklistNamePrompt-<% =rsChecklists("id") %>" class="prompt" data-val="<% =rsChecklists("id") %>" onclick="UpdateChecklistName_onClick(this)" style="cursor: pointer">
										<% =rsChecklists("name") %>
									</div>
								</th>
							</tr>

						</thead>
						<tbody>
							<%
							SQL = "select id, description from projectTemplateTaskChecklistItems where projectTemplateTaskChecklistID = " & rsChecklists("id") & " "
							dbug(SQL)
							set rsItems = dataconn.execute(SQL)
							while not rsItems.eof 
								%>
								<tr data-val="<% =rsItems("id") %>">
									<td>
										<label id="item-<% =rsItems("id") %>" data-val="<% =rsItems("id") %>" class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect mdl-data-table__select checklist-<% =rsChecklists("id") %>" for="<% =rsItems("id") %>" >
											<input type="checkbox" class="mdl-checkbox__input" <% =itemChecked %> disabled />
										</label>
									</td>									
									<td id="<% =rsItems("id") %>" class="mdl-data-table__cell--non-numeric" title="<% =rsItems("description") %>" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis; -o-text-overflow: ellipsis; padding-left: 55px; color: lightgrey;">
										<% =rsItems("description") %>
									</td>
								</tr>
								<%
								rsItems.movenext 
							wend 
							rsItems.close 
							set rsItems = nothing 	
							%>
						</tbody>

					</table>
						
				</div>
				

			<%
			dbug("at bottom of loop, cellCount: " & cellCount & ", checkListCount: " & checkListCount)
			if (cellCount + 1) mod listsPerRow = 0  or (cellCount + 1) = checkListCount then 
			
				%>
				<!-- end a row -->
					<div class="mdl-layout-spacer"></div>
				</div>
				<!-- end a row -->
				<%
			end if
			cellCount = cellCount + 1
			rsChecklists.movenext 
		wend 

		rsChecklists.close 
		set rsChecklists = nothing 
		%>
			
			
<!--
			<div class="mdl-layout-spacer"></div>

		</div>
-->
		
</main>



<!-- #include file="includes/pageFooter.asp" -->

<script src="https://cdn.quilljs.com/1.3.5/quill.js"></script>
	
<script>

	document.onkeydown = function(evt) {
		evt = evt || window.event;
		var isEscape = false;
		if ("key" in evt) {
			isEscape = (evt.key == "Escape" || evt.key == "Esc");
		} else {
			isEscape = (evt.keyCode == 27);
		}
		if (isEscape) {
			dialog_editAcceptanceCriteria.close();
			document.getElementById('quillContainer').innerHTML = '<div id="genericQuillNote"></div>'
		}
	};

	

	// populate the "Prompt" version of acceptanceCriteria on the page...	
	var acceptanceCriteriaPrompt = new Quill('#acceptanceCriteriaPrompt', {
		modules: {
			toolbar: false,
			},
			readOnly: true,
			theme: 'snow'
	});
	
	<% if (not isNull(rs("acceptanceCriteria")) and len(rs("acceptanceCriteria")) > 0) then %>
		var raweditAcceptanceCriteria = <% =rs("acceptanceCriteria") %>;
		acceptanceCriteriaPrompt.setContents(raweditAcceptanceCriteria);
		acceptanceCriteriaPrompt.enable(false);
		$( '#acceptanceCriteriaHTML' ).html( acceptanceCriteriaPrompt.root.innerHTML );
// 		acceptanceCriteriaInput.setContents(raweditAcceptanceCriteria);
	<% end if %>
	
</script>

<%
rs.Close
set rs = nothing 

dataconn.close 
set dataconn = nothing
%>

</body>
</html>