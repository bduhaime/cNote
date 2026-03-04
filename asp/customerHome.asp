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
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/taskDaysAtRisk.asp" -->
<!-- #include file="includes/taskDaysBehind.asp" -->
<!-- #include file="includes/taskDaysAhead.asp" -->
<!-- #include file="includes/workDaysBetween.asp" -->
<!-- #include file="includes/workDaysAdd.asp" -->
<% 
title = session("clientID") & " - Customer Home" 
userLog(title)
customerID = session("customerID")

maxProjs = systemControls("Max projects shown on customerHome")
if isNull(maxTasks) then 
	maxProjs = 5
end if

SQL = "select top " & maxProjs & " " &_
			"trim(cast(p.id as char)) as projectID, " &_ 
			"p.name, " &_
			"u.firstName as resource, " &_
			"p.startDate, " &_
			"p.endDate, " &_
			"null as duration, " &_
			"null as percentComplete, " &_
			"'' as dependencies " &_
		"from projects p " &_
		"left join customerManagers m on (m.customerID = p.customerID and m.startDate <= p.startDate and p.startDate <= m.endDate and m.managerTypeID = 0) " &_
		"left join cSuite..users u on (u.id = m.userID) " &_
		"where (p.complete = 0 or p.complete is null) " &_
		"and p.customerID = " & customerID & " "

dbug("customerProjects SQL")
customerProjects = jsonDataTable(SQL)


%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	
	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="moment-timezone.js"></script>

	<script type="text/javascript" src="customerView.js"></script>
	<script type="text/javascript" src="customerAnnotations.js"></script>

	<script type="text/javascript">

	   google.charts.load("visualization", "1", {packages:["corechart"]});
//  		google.charts.load('current', {'packages':['scatter','timeline','line','gauge','table','bar','controls']});
 		google.charts.load('current', {'packages':['corechart', 'controls']});
 		google.charts.load('current', {'packages':['timeline','gantt']});

		google.charts.setOnLoadCallback(drawCharts);

		
		function drawCharts() {
			
			var chartMaxDate = moment().toDate();
			var chartMinDate = moment().subtract(1, 'years').toDate();



			const rowHeight = 25;
			const chartExtra = 35;
			const chartWidth = 550;
	
 			var customerProjects 	= new google.visualization.DataTable(<% =customerProjects %>);

			var chartRowCount = customerProjects.getNumberOfRows();
			var chartHeight = chartRowCount * rowHeight + chartExtra; 
	
			if (chartHeight < 180) {
				chartHeight = 180;			
			}

			projectsChartDiv = document.getElementById('customerProjects');
		   var projectsGanttChart = new google.visualization.Gantt(projectsChartDiv);
			var ganttOptions = {
				width: chartWidth,
				height: chartHeight,
				gantt: {barHeight: 8},
			}

			google.visualization.events.addListener(projectsGanttChart, 'select', function() {
				var selectedItem = projectsGanttChart.getSelection()[0];
				if(selectedItem) {
					var projectID = customerProjects.getValue(selectedItem.row, 0);
					window.location.href = "/taskList.asp?customerID=<% =customerID %>&projectID=" + projectID + "&tab=overview";
				}
			});

			if (customerProjects.getNumberOfRows() > 0) { 
				projectsGanttChart.draw(customerProjects, ganttOptions);
			} else {
				projectsChartDiv.style.lineHeight = 10;
				projectsChartDiv.innerHTML = "No Project Data";
			}


		}
		
	</script>
	
</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">

	<div class="page-content">
	<!-- Your content goes here -->

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col mdl-shadow--3dp" align="center" style="overflow: scroll; height: 300px;">
				<div style="width: 100%;"><h10><b>Utopias</b></h10></div>
				<%
				SQL = "select id, narrative from customerUtopias where customerVisible = 1 and customerID = " & customerID & " " 
				dbug(SQL)
				set rsU = dataconn.execute(SQL)
				while not rsU.eof 
					%>
					<table style="border-collapse: collapse; border: solid lightgrey 1px; margin-left: 15px; margin-right: 15px; ">
						<tr>
							<td>
								<% response.write(rsU("narrative")) %>
							</td>
						</tr>
					</table>
					<%
					rsU.movenext 
				wend 
				rsU.close 
				set rsU = nothing 
				%>
			</div>
			<div class="mdl-cell mdl-cell--5-col mdl-shadow--3dp" align="center">
				<div style="width: 100%"><h10><b>Open Projects</b></h10></div>
				<div id="customerProjects" style="display: block; margin: 0 auto;"></div>

			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--9-col mdl-shadow--3dp" align="center">
				<div style="width: 100%"><h10><b>Open Tasks</b></h10></div>

				<table id="tasks" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin: 15px;">
				<!-- 	<table class="mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp"> -->
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">Project</th>
							<th class="mdl-data-table__cell--non-numeric">Task</th>
							<th class="mdl-data-table__cell--non-numeric">Start</th>
							<th class="mdl-data-table__cell--non-numeric">Due</th>
							<th class="mdl-data-table__cell--non-numeric">
								<i class="material-icons">ballot</i>
							</th>
							<th class="mdl-data-table__cell--non-numeric">Complete</th>
							<th class="mdl-data-table__cell--non-numeric">Owner</th>
<!--
							<th id="dar" class="mdl-data-table__cell--non-numeric">Days At Risk</th>
							<div class="mdl-tooltip" for="dar">
								For incomplete tasks that should have started: the number of work days between the start date and the lessor of the task due date or the current date.
							</div>
							<th class="mdl-data-table__cell--non-numeric">Days Behind</th>
-->
							<th class="mdl-data-table__cell--numeric">
							</th>
						</tr>
					</thead>
					<tbody class="list"> 
					<%
					maxTasks = systemControls("Max tasks shown on customerHome")
					SQL = "select top " & maxTasks & " " &_
								"t.id, " &_
								"p.name as projectName, " &_
								"t.name as taskName, " &_
								"t.startDate, " &_
								"t.dueDate, " &_
								"t.completionDate, " &_
								"t.ownerID, " &_
								"c.name as ownerName, " &_
								"t.deleted,  " &_
								"concat(u.firstName, ' ', u.lastName) as customerCompletedBy, " &_
								"t.customerCompletedInd, " &_
								"t.customerCompletedDateTime " &_
							"from tasks t " &_
							"join projects p on (p.id = t.projectID and p.customerID = " & customerID & ") " &_
							"left join customerContacts c on (c.id = t.ownerID) " &_
							"left join cSuite..users u on (u.id = t.customerCompletedBy) " &_
							"where t.completionDate is null " &_
							"and t.ownerID is not null " &_
							"order by t.dueDate desc " 
				
					dbug(SQL)
					set rs = dataconn.execute(SQL)
					
					projectDaysAtRisk = 0
					projectDaysBehind = 0
					projectDaysAhead = 0
					projectDaysNet = 0
					
					while not rs.eof
						if not isNull(rs("completionDate")) then 
							dbug("completionDate is not null")
							if isDate(rs("completionDate")) then 
								dbug("completionDate isDate = true")
								completionDate = formatDateTime(rs("completionDate"))
								listClass = "complete"
							else 
								dbug("completionDate isDate = false")
								completionDate = null 
							end if 
						else 
							dbug("completionDate is null")
							completionDate = null
							dbug("did we get here?")
						end if
						
						if rs("customerCompletedInd") then 
							checked = "checked"
							tooltip = "Completed on " & formatDateTime(rs("customerCompletedDateTime")) & "<br>by " & rs("customerCompletedBy")
						else 
							checked = ""
							tooltip = ""
						end if 
						
						%>
						<tr>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("projectName") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("taskName") %></td>							
							<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rs("startDate")) %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rs("dueDate")) %></td>
							<td class="mdl-data-table__cell--non-numeric">
								<%
								SQL = "select " &_
											"sum(case when  tci.completed = 1 then 1 else 0 end) as completed, " &_
											"count(*) as total " &_
										"from taskChecklists tc " &_
										"join taskChecklistItems tci on (tci.checklistID = tc.id) " &_
										"where tc.taskID = " & rs("id") & " "
								set rsCLI = dataconn.execute(SQL)
								if not rsCLI.eof then
									if rsCLI("total") > 0 then 
										if isNull(rsCLI("completed")) then 
											completed = 0
										else 
											completed = rsCLI("completed")
										end if
										checklistStatus = rsCLI("completed") & "/" & rsCLI("total")
									else 
										checklistStatus = ""
									end if
								else 
									checklistStatus = ""
								end if
								rsCLI.close 
								set rsCLI = nothing
								response.write(checklistStatus)
								%>
							</td>
							<td class="mdl-data-table__cell--non-numeric status" align="center">
								<div id="tt-<% =rs("id") %>">
									<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="customerCompletedInd-<% =rs("id") %>">
											<input type="checkbox" id="customerCompletedInd-<% =rs("id") %>" class="mdl-checkbox__input" <% =checked%>> 
									</label>
								</div>
								<span class="mdl-tooltip" for="tt-<% =rs("id") %>"><% =tooltip %></span>
							</td>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("ownerName") %></td>
<!--
							<td class="mdl-data-table__cell--numeric"><% =taskDaysAtRisk(rs("id")) %></td>
							<td class="mdl-data-table__cell--numeric"><% =taskDaysBehind(rs("id")) %></td>
-->
							<td class="mdl-data-table__cell--numeric">
								<% if userPermitted(38) then %>
									<a href="taskDetail.asp?cmd=edit&id=<% =rs("id") %>"><img src="/images/ic_edit_black_24dp_1x.png" ></a>
								<% end if %>
								<% 
								if userPermitted(22) then 
									if isNull(rs("deleted")) or rs("deleted") = 0 then
										image = "/images/ic_delete_black_24dp_1x.png"
									else
										image = "/images/ic_delete_forever_black_24dp_1x.png"
									end if
									%>
									<img name="deleted" id="imgDeleted-<% =rs("id") %>" data-val="<% =rs("id") %>" src="<% =image %>" style="cursor: pointer" onclick="TaskDelete_onClick(<% =rs("id") %>)">
									<%
								end if 
								%>
							</td>
						</tr>			
						<%
						projectDaysAtRisk = projectDaysAtRisk + taskDaysAtRisk(rs("id"))
						projectDaysBehind = projectDaysBehind + taskDaysBehind(rs("id"))
						projectDaysAhead = projectDaysAhead + taskDaysAhead(rs("id"))
						projectDaysNet = projectDaysAhead - projectDaysBehind
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

	</div>

</main>
<!-- #include file="includes/pageFooter.asp" -->


</body>
</html>