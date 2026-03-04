<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% ' response.buffer = true %>
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(71)

dbug("start of customerPRojectsSendDetails.asp....")
userLog("customerProjects")

templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")
dbug("templateFromIncompleteProj: " & templateFromIncompleteProj)

if len(request("customerID")) > 0 then
	
	customerID = request("customerID")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title

end if



dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<link href="https://cdn.quilljs.com/1.3.5/quill.snow.css" rel="stylesheet">
	<script src="https://cdn.quilljs.com/1.3.5/quill.js"></script>
	
	<style>
		
		.project {
			width: 90%;
			margin-left: 30px;
			margin-top: 30px;
			border-collapse: collapse;
			border: solid black 6px;
		}
		.project th, .project td {
			border-collapse: collapse;
			border: solid black 1px;
		}
		.project th {
			text-align: left;
		}

		
		.task {
			width: 85%;
			margin-left: 50px;
			border-collapse: collapse;
			border: solid black 3px;
		}
		.task th, .task td {
			border-collapse: collapse;
			border: solid black 1px;
		}
		.task th {
			text-align: left;
		}

		
		.checklist {
			width: 80%;
			margin-left: 50px;
		}

		.checklist, .checklist th, .checklist td {
			border-collapse: collapse;
			border: solid black 1px;
		}
		.checklist th {
/* 			background-color: lightgrey; */
/* 			background-color: red; */
			text-align: left;
		}
		
		.checklist .checkbox {
			display: table-cell;
			vertical-align: top;
			float: left;
			padding: 5px;
		}
		
		.checklist .itemName {
			display: table-cell;
			vertical-align: top;
			padding: 5px;
		}
		
		.dates {
			width: 10%; 
		}
	</style>
					

</head>

<body>
	
	<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>

	<%
	SQL = "select name from customer_view where id = " & customerID & " " 
	dbug("rsCust: " & SQL) 
	set rsCust = dataconn.execute(SQL) 
	%>
	<br>
	<table style="width: 90%; text-align: center;">
		<tr>
			<th><h4>Open Items<br><% =rsCust("name") %></h4></th>
		</tr>
	</table>
	<%
	rsCust.close 
	set rsCust = nothing 
	
	reDim quillArray(2,1) ' first dimension is columns, second dimension is rows


' 	SQL = "select " &_
' 				"p.id, " &_
' 				"p.name, " &_
' 				"p.startDate, " &_
' 				"p.endDate, " &_
' 				"p.completeDate, " &_
' 				"case when (u.firstName is not null and u.lastName is not null) then concat(u.firstName, ' ', u.lastName) else 'Unassigned' end as managerName " &_
' 			"from projects p " &_
' 			"left join csuite..users u on (u.id = p.projectManagerID) " &_
' 			"where p.completeDate is null " &_
' 			"and (p.deleted = 0 or p.deleted is null) " &_
' 			"and exists ( " &_
' 				"select t.id " &_
' 				"from tasks t " &_
' 				"where t.projectID = p.id " &_
' 				"and t.completionDate is null " &_
' 				"and (t.deleted = 0 or t.deleted is null) " &_
' 				"and t.ownerID is not null " &_
' 				") " &_
' 			"and p.customerID = " & customerID & " " &_
' 			"UNION " &_
' 			"select distinct " &_
' 				"null as id, " &_
' 				"'*** None ***' as name, " &_
' 				"null as startDate, " &_ 
' 				"null as endDate, " &_ 
' 				"null as completeDate, " &_
' 				"null as managerName " &_
' 			"from projects p " &_ 
' 			"where exists ( " &_
' 				"select t.id " &_ 
' 				"from tasks t " &_
' 				"where t.projectID is null " &_
' 				"and t.completionDate is null " &_
' 				"and (t.deleted = 0 or t.deleted is null) " &_
' 				"and t.ownerID is not null " &_
' 				"and t.customerID = " & customerID & " " &_
' 				") "
				
				
	SQL = "select " &_
				"p.id, " &_
				"p.name, " &_
				"p.startDate, " &_
				"p.endDate, " &_
				"case when (u.firstName is not null and u.lastName is not null) then concat(u.firstName, ' ', u.lastName) else 'Unassigned' end as managerName, " &_
				"convert(date,ps1.statusDate) as statusDate, " &_
				"ps1.type " &_
			"from projects p " &_
			"left join csuite..users u on (u.id = p.projectManagerID) " &_
			"left join projectStatus ps1 on (ps1.projectID = p.id) " &_
			"left join projectStatus ps2 on (ps2.projectID = ps1.projectID AND ps1.updatedDateTime < ps2.updatedDateTime) " &_
			"where ps2.updatedDateTime is null " &_
			"and (ps1.type <> 'Complete' or ps1.type is null) " &_
			"and p.customerID = " & customerID & " " &_
			"UNION " &_
			"select distinct " &_
				"null as id, " &_
				"'*** None ***' as name, " &_
				"null as startDate, " &_
				"null as endDate, " &_
				"null as managerName, " &_
				"null as statusDate, " &_
				"null as type " &_
			"from projects p " &_
			"where exists ( " &_
				"select t.id " &_
				"from tasks t " &_
				"where t.projectID is null " &_
				"and t.completionDate is null " &_
				"and (t.deleted = 0 or t.deleted is null) " &_
				"and t.ownerID is not null and t.customerID = " & customerID & " " &_
			") " &_
			"order by 3, 4 "
			
	dbug("rsProject: " & SQL)
			
	set rsProjects = dataconn.execute(SQL) 
	while not rsProjects.eof 

		if not isNull(rsProjects("startDate")) then 
			startDate = formatDateTime(rsProjects("startDate"),2)
		else 
			startDate = ""
		end if 

		if not isNull(rsProjects("endDate")) then 
			endDate = formatDateTime(rsProjects("endDate"),2)
		else 
			endDate = ""
		end if 

		if not isNull(rsProjects("statusDate")) then 
			statusDate = formatDateTime(rsProjects("statusDate"),2)
		else 
			statusDate = ""
		end if 

		%>
		<table class="project">
			<thead>
				<tr>
					<th>Project Name</th>
					<th>Project Manager</th>
					<th class="dates" style="text-align: center;">Start Date</th>
					<th class="dates" style="text-align: center;">End Date</th>
					<th class="dates" style="text-align: center;">Status</th>
					<th class="dates" style="text-align: center;">Status Date</th>
				</tr>
				<tr>
					<td><% =rsProjects("name") %></td>
					<td><% =rsProjects("managerName") %></td>
					<td class="dates" style="text-align: center;"><% =startDate %></td>
					<td class="dates" style="text-align: center;"><% =endDate %></td>
					<td class="dates" style="text-align: center;"><% =rsProjects("type") %></td>
					<td class="dates" style="text-align: center;"><% =statusDate %></td>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td colspan="6">
		
						<% 
						SQL = "select " &_
									"t.id, " &_
									"t.name, " &_
									"case when (c.firstName is not null and c.lastName is not null) then concat(c.firstName, ' ', c.lastName) else 'Unassigned' end as ownerName, " &_
									"t.startDate, " &_
									"t.dueDate, " &_
									"t.completionDate, " &_
									"t.acceptanceCriteria " &_
								"from tasks t " &_
								"left join customerContacts c on (c.id = t.ownerID) " &_
								"where t.completionDate is null " &_
								"and (t.deleted = 0 or t.deleted is null) " &_
								"and t.ownerID is not null "
						
						dbug("rsTasks: " & SQL)
								
						if not isNull(rsProjects("id")) then 
							SQL = SQL & "and t.projectID = " & rsProjects("id") & " " 
						else 
							SQL = SQL & "and t.projectID is null and t.customerID = " & customerID & " "
						end if 

						SQL = SQL & "order by t.startDate, t.dueDate "
							
							
						set rsTasks = dataconn.execute(SQL) 
						
						while not rsTasks.eof 

							quillArray(1,uBound(quillArray,2)) = rsTasks("id")
							quillArray(2,uBound(quillArray,2)) = rsTasks("acceptanceCriteria")
							redim preserve quillArray(2, uBound(quillArray, 2)+1)
							
							if not isNull(rsTasks("startDate")) then 
								startDate = formatDatetime(rsTasks("startDate"),2)
							else 
								startDate = ""
							end if 

							if not isNull(rsTasks("dueDate")) then 
								dueDate = formatDatetime(rsTasks("dueDate"),2)
							else 
								dueDate = ""
							end if 

							%>
							<br><br>
							<table class="task">
								<tr>
									<th>Task Name</th>
									<th>Task Owner</th>
									<th class="dates" style="text-align: center;">Start Date</th>
									<th class="dates" style="text-align: center;">Due Date</th>
								</tr>
								<tr>
									<td><% =rsTasks("name") %></td>
									<td><% =rsTasks("ownerName") %></td>
									<td class="dates" style="text-align: center;"><% =startDate %></td>
									<td class="dates" style="text-align: center;"><% =dueDate %></td>
								</tr>


								<tr class="acceptanceCriteria">
									<td colspan="4" style="padding-left: 15px; padding-right: 15px;">
										<h6 style="margin: 12px 0px 0px;">Conditions of Satisfaction:</h6>
										<hr style="margin: 0px 0px 4px;">
										<div class="acceptanceCriteria" data-id="<% =rsTasks("id") %>">
										</div>
										<br>
									</td>
								</tr>

								<%
								SQL = "select id, name, completed " &_
										"from taskChecklists " &_
										"where (completed = 0 or completed is null) " &_
										"and taskID = " & rsTasks("id") & " "
										
								dbug("rsChecklists: " & SQL)
								set rsChecklists = dataconn.execute(SQL) 

								if not rsChecklists.eof then 
									%>
									<tr>
										<td colspan="4">
											<% while not rsChecklists.eof %>
												<br>
												<table class="checklist">
													<thead>
														<tr>
															<th style="padding: 0px;">
																<div style="background: url('images/lightgrey_1px.png') 0 0 no-repeat lightgrey;">
																	<!-- <img src="images/lightgrey_1px.png" style="height: 30px; width: 100%;"> -->
																	<div style="display: inline-block; vertical-align: top; padding-left: 5px; padding-top: 3px;">																
																		<% if rsChecklists("completed") then %>
																			<img src="images/ic_check_box_black_24dp_1x.png" style="display: inline-block;">
																		<% else %>
																			<img src="images/ic_check_box_outline_blank_black_24dp_1x.png" style="display: inline-block;">
																		<% end if %>
																	</div>
																	<div style="display: inline-block; width: 95%; padding: 5px;">
																		<% =rsChecklists("name") %>
																	</div>
																</div>
															</th>
														</tr>
													</thead>
													<tbody>
														<%
														SQL = "select * " &_
																"from taskChecklistItems " &_
																"where (completed = 0 or completed is null) " &_
																"and checklistID = " & rsChecklists("id") & " " 
														dbug("rsItems: " & SQL) 
														set rsItems = dataconn.execute(SQL) 
														while not rsItems.eof 
															%>
															<tr>
																<td>
																	<% if rsItems("completed") then %>
																		<img src="images/ic_check_box_black_24dp_1x.png" style="display: inline-block; padding-left: 5px; padding-top: 3px;">
<!-- 																		<div class="checkbox"><i class="material-icons">check_box</i></div> -->
																	<% else %>
																		<img src="images/ic_check_box_outline_blank_black_24dp_1x.png" style="display: inline-block; padding-left: 5px; padding-top: 3px;">
<!-- 																		<div class="checkbox"><i class="material-icons">check_box_outline_blank</i></div> -->
																	<% end if %>
																	<div class="itemName" style="display: inline-block; width: 95%;"><% =rsItems("description") %><div>
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
												<br>
												<%
												rsChecklists.movenext 
											wend
											%>
										</td>
									</tr>
									<%
								end if
								%>
									
									
							</table>
							<br><br>
							<%
							rsTasks.movenext 

						wend 
						rsTasks.close 
						set rsTasks = nothing 
						%>


					</td>
				</tr>
			</tbody>
		</table>
		<br><br>
		<%
		rsProjects.movenext 
	wend
	rsProjects.close 
	set rsProjects = nothing 
	%>

<!-- #include file="includes/pageFooter.asp" -->
	
</body>
<script>

	var quillTemp = document.createElement('div');
	var targetAC;

	objQuill = new Quill(quillTemp, {
		modules: {
			toolbar: false,
			},
			readOnly: true,
			theme: 'snow'
	});

	
<%
	
i = 1
while i <= uBound(quillArray,2) 

	if len(quillArray(1,i)) > 0 then 
		%>
	
		targetAC = document.querySelector('.acceptanceCriteria[data-id="<% =quillArray(1,i) %>"]');
		<%	if len(quillArray(2,i)) > 0 then %>
			objQuill.setContents(<% =quillArray(2,i) %>);
		<% else %>
			objQuill.setContents({"ops":[{"insert":"*** nothing specified *** \n"}]});
		<%	end if %>
		targetAC.innerHTML = objQuill.root.innerHTML;
	
		<%
	end if
	i = i + 1
	
wend 

%>

</script>
	
<%	
dataconn.close 
set dataconn = nothing 
%>
</html>