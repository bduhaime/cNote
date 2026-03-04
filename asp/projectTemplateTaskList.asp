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
call checkPageAccess(40)

userLog("Project template task list")

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""projectTemplateList.asp"">Project Templates</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"

projectTemplateID = request.querystring("id")

if len(request.querystring("id")) then 
	SQL = "select name from projectTemplates where id = " & projectTemplateID
	set rs = dataconn.execute(SQL)
	if not rs.eof then 
		name = rs("name")
	else 
		name = ""
	end if
else 
	name = ""
end if

title = title & name

dbug(" ")
dbug("start of script....")

dbug("request.querystring('cmd'): " & request.querystring("cmd"))

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

	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script type="text/javascript" src="projectTemplateTaskList.js"></script>

	<script>
		
		$(document).ready(function() {

			$( document ).tooltip();
						
			$.fn.dataTable.moment( 'M/D/YYYY' );
			$.fn.dataTable.moment( 'H:mm A' );

			var table = $('#tbl_projectTemplateTasks').DataTable({
				scrollY: 650,
				scroller: true,
				scrollCollapse: true,
				columnDefs: [
					{ targets: 'name', 				className: 'name dt-body-left', width: '40%' },
					{ targets: 'description', 		className: 'description dt-body-left', width: '40%' },
					{ targets: 'startOffset', 		className: 'startOffset dt-body-center' },
					{ targets: 'duration', 			className: 'duration dt-body-center' },
					{ targets: 'endOffset', 		className: 'endOffset dt-body-center' },
					{ targets: 'estimate', 			className: 'estimate dt-body-center' },
					{ targets: 'dependencies', 	className: 'dependencies dt-body-left', visible: false },
					{ targets: 'actions', 			className: 'dt-body-center', orderable: false }
				],
				order: [ [0, 'asc'] ]
			});
		} );

	</script>
	
	<style>

		table th.name, 
		table td.name,
		table th.description, 
		table td.description {
			max-width: 200px; 
			min-width: 70px; 
			overflow: hidden; 
			text-overflow: ellipsis; 
			white-space: nowrap; }
		}

	</style>

</head>

<body>
<form id="form_addCCT" action="projectTemplateList.asp" method="POST">

<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content">
		<!-- Your content goes here -->
		<br>
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--11-col" align="center">


				<table id="tbl_projectTemplateTasks" class="compact display">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="description">Description</th>
							<th class="startOffset">Start Offset</th>
							<th class="duration">Duration</th>
							<th class="endOffset">End Offset</th>
							<th class="estimate">Estimate</th>
							<th class="dependencies">Dependencies</th>
							<th class="actions">Actions</th>
						</tr>
					</thead>
			  		<tbody> 
				  	<%
					SQL = "select * from projectTemplateTasks where projectTemplateID = " & projectTemplateID & " order by startOffsetDays "
							
					dbug(SQL)
					set rsTask = dataconn.execute(SQL)
					while not rsTask.eof			
						titleName = replace(rsTask("name"),"""", "&quot;")			
						titleDesc = replace(rsTask("description"),"""", "&quot;")			
					  	%>
						<tr data-val="<% =rsTask("id") %>" onclick="window.location.href='projectTemplateTaskDetail.asp?id=<% =rsTask("id") %>';" style="cursor: pointer" onmouseover="ToggleDeleteIcon(this)" onmouseout="ToggleDeleteIcon(this)">
							<td title="<% =titleName %>"><% =rsTask("name") %></td>
							<td title="<% =titleDesc %>"><% =rsTask("description") %></td>
							<td><% =rsTask("startOffsetDays") %></td>
							<td><% =rsTask("taskDurationDays") %></td>
							<td><% =rsTask("endOffsetDays") %></td>
							<td><% =rsTask("estimatedWorkDays") %></td>
							<td><% =rsTask("dependencies") %></td>
	   					<td>
								<i id="project-<% =rsTask("id") %>" class="material-symbols-outlined" style="display: none">delete</i>
	   					</td>
						</tr>
						<%
						rsTask.movenext 
					wend 
					rsTask.close 
					set rsTask = nothing 
					%>
			  		</tbody>
				</table>


			</div>
			<div class="mdl-layout-spacer"></div>
		</div>


		<%
		SQL = "SELECT " &_
					"trim(concat(u.firstName, ' ', u.lastName)) as updatedBy, " &_
					"format(pt.updatedDateTime, 'M/d/yyyy') as updatedDate, " &_
					"format(pt.updatedDateTime, 'h:mm:ss tt') as updatedTime " &_
				"FROM projectTemplates pt " &_
				"LEFT JOIN csuite..users u on (u.id = pt.updatedBy) " &_
				"WHERE pt.id = " & projectTemplateID & " " 
				
		set rsProj = dataconn.execute(SQL) 
		if not rsProj.eof then 
			%>
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--10-col" align="center">
					Updated by <% =rsProj("updatedBy") %> on <% =rsProj("updatedDate") %> at <% =rsProj("updatedTime") %>
				</div>	
				<div class="mdl-layout-spacer"></div>
			</div>
			<%
		end if
		rsProj.close 
		set rsProj = nothing 
		%>
		
	</div>
		


</main>

<!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>
</form>
</body>
</html>