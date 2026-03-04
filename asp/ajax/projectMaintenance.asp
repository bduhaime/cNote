<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<!-- #include file="../includes/escapeHtmlCharacters.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/smtpParms.asp" -->
<!-- #include file="../includes/usersWithPermission.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<!-- #include file="../includes/workDaysBetween.asp" -->
<!-- #include file="../includes/workDaysAdd.asp" -->
<!-- #include file="../includes/formatHTML5Date.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<% 
'!-- ----------------------------------------------------------------------------------------
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
'!-- ----------------------------------------------------------------------------------------

'***** PROJECT MAINTENANCE *****

response.contentType = "text/xml"

'!-- ----------------------------------------------------------------------------------------
function updateProjectStatus(projectID, statusDate, statusComments, statusType) 
'!-- ----------------------------------------------------------------------------------------
	
	newID	= getNextID("projectStatus")
	
	
	SQL = "insert into projectStatus (id, statusDate, type, updatedBy, updatedDateTime, projectID, comments) " &_
			"values ( " &_
				newID & ", " &_
				"'" & formatDateTime(statusDate,2) & "',	" &_
				"'" & statusType & "', " &_
				session("userID") & ", " &_
				"current_timestamp, " &_
				projectID & ", " &_
				"'" & escapeQuotes(statusComments) & "' " &_
			") " 
				
	dbug(SQL)
	
	set rsInsert = dataconn.execute(SQL)
	set rsInsert = nothing 
	
	updateProjectStatus = true 	
	
end function 


'!-- ----------------------------------------------------------------------------------------
'!-- ----------------------------------------------------------------------------------------
'!-- ----------------------------------------------------------------------------------------
'!-- ----------------------------------------------------------------------------------------
'!-- ----------------------------------------------------------------------------------------


xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<projectMaintenance>"

msg = ""

select case request.querystring("cmd")

	case "updateStatus"
	
		xml = xml & "<projectStatus>"

		newID					= getNextID("projectStatus")
		statusDate 			= request.querystring("date")
		statusComments 	= left(request.querystring("comments"),255)
		projectID	 		= request.querystring("id")
		projectStatusType = request.querystring("type")
		
		select case lCase(projectStatusType)
		
			case "on time"

				updateSuccessful = updateProjectStatus(projectID, statusDate, statusComments, projectStatusType) 			
				msg = "Project status updated to 'on time' "

			case "escalate"
			
' 				dbug("projectStatus type is escalate")
				
				recipientList = usersWithPermission(24,"email")
				xml = xml & "<recipientList>" & recipientList & "</recipientList>"
' 				dbug("recipientList: " & recipientList)
									
				if len(recipientList) > 0 then 

' 					dbug("recipientList: " & recipientList)
					
					SQL = "select p.name as projectName, c.name as customerName " &_
							"from projects p " &_
							"left join customer_view c on ( c.id = p.customerID) " &_
							"where p.id = " & projectID & " "
					set rsProj = dataconn.execute(SQL)
					if not rsProj.eof then 
						projectName = trim(rsProj("projectName"))
						customerName = trim(rsProj("customerName"))
					end if 
					
					requestedBy = trim(session("firstName"))
					if len(trim(session("lastName"))) then 
						requestedBy = requestedBy & " " & trim(session("lastName"))
					end if
					
					
' 					dbug("creating CDO object...")
					set objmail			= createobject("CDO.Message")
					objmail.from		= systemControls("Generic Email From Address")
					objmail.to			= recipientList
					objmail.subject	= "Project Escalation Request"
					objmail.HTMLbody	= 	"<html><body>Escalation has been requested on a project<br><br>" &_
												"<table style=""margin-left: 20px"">" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Customer Name:&nbsp;</td><td>" & customerName & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Project Name:&nbsp;</td><td>" & projectName & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Project Status:&nbsp;</td><td>" & projectStatusType & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Requested By:&nbsp;</td><td>" & requestedBy & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Comments:&nbsp;</td><td>" & statusComments & "</td></tr>" &_
												"</table>" &_
												"</body></html>"
					smtpParms
					
					if systemControls("Send system generated email") = "true" then 
					
						objmail.send
						msg = "Project escalation request sent"
' 						dbug("project escalation request email sent")

						
					else 
					
						dbug("project escalation request generatedbut not sent because 'Send system generated email' is off") 				
						msg = "Project escalation generated but not sent"
						
					end if

				else 
					
' 					dbug("WARNING: no recipients setup to receive escalations")
					msg = "Project escalation request updated with warnings (no recipients)"
					
				end if

				updateSuccessful = updateProjectStatus(projectID, statusDate, statusComments, projectStatusType) 			
				

			case "reschedule"
			
' 				dbug("projectStatus type is reschedule")
				
				recipientList = usersWithPermission(25,"email")
				xml = xml & "<recipientList>" & recipientList & "</recipientList>"
' 				dbug("recipientList: " & recipientList)
									
				if len(recipientList) > 0 then 

' 					dbug("recipientList: " & recipientList)
					
					SQL = "select p.name as projectName, c.name as customerName " &_
							"from projects p " &_
							"left join customer_view c on ( c.id = p.customerID) " &_
							"where p.id = " & projectID & " "
					set rsProj = dataconn.execute(SQL)
					if not rsProj.eof then 
						projectName = trim(rsProj("projectName"))
						customerName = trim(rsProj("customerName"))
					end if 
					
					requestedBy = trim(session("firstName"))
					if len(trim(session("lastName"))) then 
						requestedBy = requestedBy & " " & trim(session("lastName"))
					end if
					
					
' 					dbug("creating CDO object...")
					set objmail			= createobject("CDO.Message")
					objmail.from		= systemControls("Generic Email From Address")
					objmail.to			= recipientList
					objmail.subject	= "Project Reschedule Request"
					objmail.HTMLbody	= 	"<html><body>Rescheduling has been requested for a project<br><br>" &_
												"<table style=""margin-left: 20px"">" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Customer Name:&nbsp;</td><td>" & customerName & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Project Name:&nbsp;</td><td>" & projectName & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Project Status:&nbsp;</td><td>" & projectStatusType & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Requested By:&nbsp;</td><td>" & requestedBy & "</td></tr>" &_
													"<tr><td style=""font-weight: bold;"" nowrap>Comments:&nbsp;</td><td>" & statusComments & "</td></tr>" &_
												"</table>" &_
												"</body></html>"
					smtpParms

					if systemControls("Send system generated email") = "true" then 

						objmail.send
						msg = "Project reschedule request sent"
' 						dbug("project reschedule request email sent")

					else 
					 
						msg = "Project reschedule request generated but not sent"
 						dbug("project reschedule request email generated by not sent because 'Send system generated email' is off")
					 
					end if 

				else 
					
					dbug("WARNING: no recipients setup to receive escalations")
					msg = "Project reschedule set with warnings (no recipients) "
					
				end if
				
				updateSuccessful = updateProjectStatus(projectID, statusDate, statusComments, projectStatusType) 			
				
			
			case "complete"
			
				' first check that it's possible to complete the project (even though the UI should protect against this)...
				projectCompletable = false 
				if not userPermitted(44) then 

					SQL = "select count(*) as openCount " &_
							"from projects p " &_
							"join tasks t on (t.projectID = p.id) " &_
							"join taskChecklists tc on (tc.taskID = t.id) " &_
							"join taskChecklistItems tci on (tci.checklistID = tc.id) " &_
							"where p.id = " & projectID & " " &_
							"and (p.deleted = 0 or p.deleted is null) " &_
							"and (t.completionDate is null) " &_
							"and (t.deleted = 0 or t.deleted is null) " &_
							"and (tc.completed = 0 or tc.completed is null) " &_
							"and (tci.completed = 0 or tci.completed is null) " 
							
					dbug(SQL) 
					set rsOpen = dataconn.execute(SQL) 
					if not rsOpen.eof then 
						if not isNull(rsOpen("openCount")) then 
							if cInt(rsOpen("openCount")) > 0 then 
								projectCompletable = false 
								dbug("project cannot be completed because there are " & rsOpen("openCount") & " open items.")
								msg = "Project cannot be completed because there are open items, user cannot 'mass update.'"
							else 
								dbug("project completable because open items <= 0")
								projectCompletable = true 
							end if 
						else 
							dbug("project completable because open items is null")
							projectCompletable = true 
						end if 
					else 
						dbug("project completable because no open items were found") 
						projectCompletable = true 
					end if 
					rsOpen.close 
					set rsOpen = nothing 

				else 
					
					dbug("project completable despite open items; user can 'mass update.'")
					projectCompletable = true 
					
				end if 
					
				if projectCompletable then 
					
					if userPermitted(44) then 
						
						' complete any open taskChecklistItems....
						
						SQL = "update taskChecklistItems set " &_
									"completed = 1, " &_
									"updatedBy = " & session("userID") & ", " &_
									"updatedDateTime = CURRENT_TIMESTAMP " &_
								"where (completed = 0 or completed is null) " &_
								"and checklistID in ( " &_
									"select tc.id " &_
									"from taskChecklists tc " &_
									"join tasks t on (t.id = tc.taskID and t.projectID = " & projectID & ") " &_
								") "
								
						dbug(SQL)
						set rsUpdate = dataconn.execute(SQL, recordsAffected) 
						set rsUpdate = nothing 
						
						xml = xml & "<taskCheckListItemsCompleted>" & recordsAffected & "</taskCheckListItemsCompleted>"

						
						' complete any open taskChecklists... 
						
						SQL = "update taskChecklists set " &_
									"completed = 1, " &_
									"updatedBy = " & session("userID") & ", " &_
									"updatedDateTime = CURRENT_TIMESTAMP " &_
									"where (completed = 0 or completed is null) " &_
									"and taskID in ( " &_
										"select id " &_
										"from tasks t " &_
										"where projectID = " & projectID & " " &_
									") " 
						dbug(SQL) 
						set rsUpdate = dataconn.execute(SQL, recordsAffected) 
						set rsUpdate = nothing 
						
						xml = xml & "<taskChecklistsCompleted>" & recordsAffected & "</taskChecklistsCompleted>"

						
						' complete any open tasks... 
						
						SQL = "update tasks set " &_
									"completionDate = '" & statusDate & "', " &_
									"taskStatusID = 2, " &_
									"updatedBy = " & session("userID") & ", " &_
									"updatedDateTime = CURRENT_TIMESTAMP " &_
								"where (deleted = 0 or deleted is null) " &_
								"and (completionDate is null) " &_
								"and projectID = " & projectID & " " 
								
						dbug(SQL) 
						set rsUpdate = dataconn.execute(SQL, recordsAffected) 
						set rsUpdate = nothing 
					
						xml = xml & "<tasksCompleted>" & recordsAffected & "</tasksCompleted>"

					end if 
				
					updateSuccessful = updateProjectStatus(projectID, statusDate, statusComments, projectStatusType) 			
				
					msg = "project status successfully completed"
				
				end if 
					
			case else 
		
				dbug("projectStatus type is unknown")

		end select 

		xml = xml & "<statusDate>" & statusDate & "</statusDate>"
		xml = xml & "<projectStatusType>" & projectStatusType & "</projectStatusType>"
		xml = xml & "<statusComments>" & statusComments & "</statusComments>"
		
		xml = xml & "</projectStatus>"
		
		
	case "add"
	
		xml = xml & "<newProject>"

		projectID 				= request.querystring("id")
		projectName 			= replace(request.querystring("name"), "'", "''")
		
' 		dbug("request.querystring('product'): " & request.querystring("product"))
		if len(request.querystring("product")) > 0 then 			
			projectProduct 		= request.querystring("product")
		else 
			projectProduct			= "NULL"
		end if 
' 		dbug("projectProduct: " & projectProduct)

' 		dbug("request.querystring('pm'): " & request.querystring("pm"))
		if len(request.querystring("pm")) > 0 then 
			projectManagerID		= request.querystring("pm")
		else 
			projectManagerID		= "NULL"
		end if 	

		projectStartDate 		= request.querystring("start")
		projectEndDate 		= request.querystring("end")
		
		if len(request.querystring("complete")) > 0 then 
			if isDate(request.querystring("complete")) then 			
				projectCompleteDate 	= "'" & request.querystring("complete") & "'" 
			else 
				projectCompleteDate = "NULL"
			end if
		else 
			projectCompleteDate = "NULL"
		end if
			
		projectCustomerID 	= request.querystring("customer")

' 		dbug("projectID: " & projectID)
' 		dbug("len('projectID') = " & len("projectID"))
' 		dbug("isNull('projectID') = " & isNull("projectID"))
		
		if len(projectID) then 
			
' 			dbug("updating an existing project...")
			
			' if projectCompleteDate is null, determine if the project was complete prior to this update...
			if projectCompleteDate = "NULL" then 
				
' 				dbug("previous projectCompleteDate is not null")

				uncomplete = false 
				SQL = "select completeDate from projects where id = " & projectID & " " 
				set rsCompl = dataconn.execute(SQL)
				if not rsCompl.eof then 
					if len(rsCompl("completeDate")) > 0 then 
' 						dbug("previous completeDate was not null, so going to uncomplete...")
						uncomplete = true
					end if 
				end if 
				rsCompl.close 
				set rsCompl = nothing	
				
			else 
				
' 				dbug("previousCompleteDate IS null, so completing project...")		
				newID = getNextID("projectStatus")

				statusSQL = "insert into projectStatus (id, statusDate, updatedBy, updatedDateTime, projectID, comments, type) " &_
								"values ( " &_
									newID & ", " &_
									"getDate(), " &_
									session("userID") & ", " &_
									"CURRENT_TIMESTAMP, " &_
									projectID & ", " &_
									"null, " &_
									"'Complete') "

' 				dbug(statusSQL)
				
				set rsStatus = dataconn.execute(statusSQL)
				set rsStatus = nothing 
				
			end if 
			
			
			SQL = "update projects set " &_
						"name = '" & projectName & "', " &_
						"productID = " & projectProduct & ", " &_
						"startDate = '" & projectStartDate & "', " &_
						"endDate = '" & projectEndDate & "', " &_
						"completeDate = " & projectCompleteDate & ", " &_
						"projectManagerID = " & projectManagerID & " " &_
					"where id = " & projectID & " " 
					
' 			dbug(SQL)
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing
					
			msg = "Project updated"
			
' 			dbug("existing project updated")
			
			' if project was previously complete, update status to "Uncomplete"...
			if uncomplete then 

' 				dbug("now uncompleting...")
				
				newID = getNextID("projectStatus")
				
				statusSQL = "insert into projectStatus (id, statusDate, updatedBy, updatedDateTime, projectID, comments, type) " &_
								"values ( " &_
									newID & ", " &_
									"getDate(), " &_
									session("userID") & ", " &_
									"CURRENT_TIMESTAMP, " &_
									projectID & ", " &_
									"'Project has been un-completed', " &_
									"'Uncomplete') "
							
' 				dbug(statusSQL)
							
				set rsStatus = dataconn.execute(statusSQL)
				set rsSTatus = nothing 
			
' 				dbug("finished un-completing")
			
			end if 
			
					
		else
			
			newID = getNextID("projects")
			
			SQL = "insert into projects (id, name, customerID, productID, startDate, endDate, completeDate, updatedBy, updatedDateTime, projectManagerID) " &_
					"values ( " &_
						newID & ", " &_
						"'" & projectName & "', " &_
						projectCustomerID & ", " &_
						projectProduct & ", " &_
						"'" & projectStartDate & "', " &_
						"'" & projectEndDate & "', " &_
						projectCompleteDate & ", " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						projectManagerID & ") " 
					
			msg = "Project added"
			
' 			dbug("new project added")
					
		end if
					
' 		dbug(SQL)
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		SQL = "select name from products where id = " & projectProduct & " " 
' 		dbug(SQL)
		set rsProduct = dataconn.execute(SQL)
		if not rsProduct.eof then 
			projectProductName = rsProduct("name")
		else 
			projectProductName = ""
		end if
		rsProduct.close 
		set rsProduct = nothing 
		
	
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<name>" & projectName & "</name>"
		xml = xml & "<customer>" & projectCustomerID & "</customer>"
		xml = xml & "<product>" & projectProduct & "</product>"
		xml = xml & "<productName>" & projectProductName & "</productName>"
		xml = xml & "<projectManagerID>" & projectManagerID & "</projectManagerID>"
		xml = xml & "<startDate>" & formatDateTime(projectStartDate,2) & "</startDate>"
		xml = xml & "<endDate>" & formatDateTime(projectEndDate,2) & "</endDate>"
		xml = xml & "<completeDate>" & projectCompleteDate & "</completeDate>"
	
		xml = xml & "</newProject>"

	
	case "delete"
	
		projectID = request.querystring("id") 
		
' 		SQL = "delete from projects where id = " & request.querystring("id") & " " 
' 		set rsDelete = dataconn.execute(SQL)
' 		set rsDelete = nothing 
' 		
' 		xml = xml & "<id>" & request.querystring("id") & "</id>"
' 		msg = "Project deleted"
		

		SQL = "select id from tasks where projectID = " & projectID & " " 
		dbug("get all tasks SQL: " & SQL)
		set rsTasks = dataconn.execute(SQL)
		while not rsTasks.eof 
		
			SQL = "select id from taskChecklists where taskID = " & rsTasks("id") & " " 
' 			dbug("get taskChecklists SQL: " & SQL)
			set rsTaskChecklists = dataconn.execute(SQL)
			while not rsTaskChecklists.eof 
			
				SQL = "delete from taskChecklistItems where checklistID = " & rsTaskChecklists("id") & " " 
				dbug("delete taskChecklistItems SQL: " & SQL)
				xml = xml & "<taskChecklistItemsDeleted>true</taskChecklistItemsDeleted>"
				
				set rsDelete1 = dataconn.execute(SQL)
				set rsDelete1 = nothing 
				rsTaskChecklists.movenext 
								
			wend 
			rsTaskChecklists.close 
			set rsTaskChecklists = nothing 
			
			SQL = "delete from taskChecklists where taskID = " & rsTasks("id") & " " 
' 			dbug("delete taskChecklists SQL: " & SQL)
			xml = xml & "<taskChecklistsDeleted>true</taskChecklistsDeleted>"

			set rsDelete2 = dataconn.execute(SQL)
			set rsDelete2 = nothing  
			rsTasks.movenext 
			
		wend 
		rsTasks.close 
		set rsTasks = nothing 
		
		SQL = "delete from tasks where projectID = " & projectID & " " 
' 		dbug("delete tasks SQL: " & SQL)
		xml = xml & "<tasksDeleted>true</tasksDeleted>"

		set rsDelete3 = dataconn.execute(SQL)
		set rsDelete3 = nothing 
		
		SQL = "delete from keyInitiativeProjects where projectID = " & projectID & " " 
		xml = xml & "<keyInitiativeProjectsDeleted>true</keyInitiativeProjectsDeleted>"
		
		set rsDelete3a = dataconn.execute(SQL)
		set rsDelete3a = nothing
		
		SQL = "delete from projects where id = " & projectID & " " 
' 		dbug("delete project SQL " & SQL)
		xml = xml & "<projectDeleted>true</projectDeleted>"

		set rsDelete4 = dataconn.execute(SQL)
		set rsDelete4 = nothing 
		
		xml = xml & "<id>" & request.querystring("id") & "</id>"
		msg = "Project deleted"
		
		
	'====================================================================================================================	
	case "createTemplate"
	'====================================================================================================================	
	
		sourceProjectID 		= request.querystring("sourceProjectID")
		targetTemplateName 	= replace(request.querystring("targetTemplateName"), "'", "''")

		' delete existing project template (and descendents), even if it doesn't exist!
		SQL = "delete from projectTemplateTaskChecklistItems " &_
				"where projectTemplateTaskChecklistID in " &_
					"(" &_
					"select c.id " &_
					"from projectTemplateTaskChecklists c " &_
					"join projectTemplateTasks b on (b.id = c.projectTemplateTaskID) " &_
					"join projectTemplates a on (a.id = b.projectTemplateID) " &_
					"where a.name = '" & targetTemplateName & "' " &_
					") "
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		
		SQL = "delete from projectTemplateTaskChecklists " &_
				"where projectTemplateTaskID in " &_
					"(" &_
					"select b.id " &_
					"from projectTemplateTasks b " &_
					"join projectTemplates a on (a.id = b.projectTemplateID) " &_
					"where a.name = '" & targetTemplateName & "' " &_
					") "
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		
		SQL = "delete from projectTemplateTasks " &_
				"where projectTemplateID in " &_
					"(" &_
					"select a.id " &_
					"from projectTemplates a " &_
					"where a.name = '" & targetTemplateName & "' " &_
					") "
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		
		SQL = "delete from projectTemplates " &_
				"where name = '" & targetTemplateName & "' "
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 		

		i = 0
		
		newID 					= getNextID("projectTemplates")
		projectTemplateID 	= newID
		
		SQL = "select name from projectTemplates where name = '" & targetTemplateName & "' "
		dbug(SQL)
		set rsName = dataconn.execute(SQL)
		if not rsName.eof then
			
			for i = 1 to 100

				rsName.close 
				set rsName = nothing 
				suffix = "(" & i & ")"
				tryThisName = targetTemplateName & suffix
				SQL = "select name from projectTemplates where name = '" & tryThisName & "' "
				set rsName = dataconn.execute(SQL)
				if rsName.eof then exit for end if 
				
			next 
		
		end if 

		if len(suffix) > 0 then 
			targetTemplateName = targetTemplateName & suffix
		end if
		
		SQL = "insert into projectTemplates (id, name, updatedBy, updatedDateTime) " &_
				"values ( " &_
					newID & ", " &_
					"'" & targetTemplateName & "', " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP) " 
					
		dbug(SQL)

		xml = xml & "<sourceProjectID>" & sourceProjectID & "</sourceProjectID>"
		xml = xml & "<newTemplateID>" & newID & "</newTemplateID>"
		xml = xml & "<targetTemplateName>" & targetTemplateName & "</targetTemplateName>"
		
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		projectTemplateCreated = true 
		
		
		SQL = "select t.id, t.name, t.description, t.startDate, t.dueDate, t.estimatedWorkDays, t.dependencies, t.acceptanceCriteria, p.startDate as projectStartDate, p.endDate as projectEndDate " &_
				"from tasks t " &_
				"join projects p on (p.id = t.projectID) " &_
				"where projectID = " & sourceProjectID & " " 
				
		dbug(SQL)
		set rsTasks = dataconn.execute(SQL)
		while not rsTasks.eof 
		
			sourceTaskID				= rsTasks("id")
			newID 						= getNextID("projectTemplateTasks")
			projectTemplateTaskID 	= newID
			taskName						= "'" & replace(rsTasks("name"), "'", "''") & "'" 
			
			if isNull(rsTasks("description")) then 
				taskDescription		= "NULL"
			else 
				taskDescription		= "'" & replace(rsTasks("description"), "'", "''") & "'"
			end if 
			
			startOffsetDays 		= workDaysBetween(rsTasks("projectStartDate"),rsTasks("startDate"))
			taskDurationDays 		= workDaysBetween(rsTasks("startDate"),rsTasks("dueDate")) 
			endOffsetDays 			= workDaysBetween(rsTasks("dueDate"),rsTasks("projectEndDate")) 
			
			if isNull(rsTasks("estimatedWorkDays")) then 
				estimatedWorkDays = "NULL"
			else 
				estimatedWorkDays 	= rsTasks("estimatedWorkDays")
			end if
			
			if isNull(rsTasks("dependencies")) then 
				dependencies = "NULL"
			else 
				dependencies 			= "'" & rsTasks("dependencies") & "'" 
			end if
			
			if isNull(rsTasks("acceptanceCriteria")) then 
				acceptanceCriteria = "NULL"
			else 
' 				acceptanceCriteria = "'" & rsTasks("acceptanceCriteria") & "'" 
				acceptanceCriteria = "'" & replace(rsTasks("acceptanceCriteria"), "'", "''") & "'" 
			end if
			
			SQL = "insert into projectTemplateTasks (id, name, description, startOffsetDays, taskDurationDays, endOffsetDays, estimatedWorkDays, dependencies, projectTemplateID, acceptanceCriteria) " &_
					"values ( " &_
						newID & ", " &_
						taskName & ", " &_
						taskDescription & ", " &_
						startOffsetDays & ", " &_
						taskDurationDays & ", " &_
						endOffsetDays & ", " &_
						estimatedWorkDays & ", " &_
						dependencies & ", " &_
						projectTemplateID & ", " &_
						acceptanceCriteria & ") "
					
			dbug(SQL)
					
			set rsInsertPTT = dataconn.execute(SQL)
			set rsInsertPTT = nothing 
			
			xml = xml & "<task id=""" & newID & """>"
			xml = xml & "<sourceTaskID>" & sourceTaskID & "</sourceTaskID>"
			xml = xml & "<name>" & taskName & "</name>"
			xml = xml & "<description>" & taskDescription & "</description>"
			xml = xml & "<startOffsetDays>" & startOffsetDays & "</startOffsetDays>"
			xml = xml & "<taskDurationDays>" & taskDurationDays & "</taskDurationDays>"
			xml = xml & "<endOffsetDays>" & endOffsetDays & "</endOffsetDays>"
			xml = xml & "<estimatedWorkDays>" & estimatedWorkDays & "</estimatedWorkDays>"
			xml = xml & "<dependencies>" & dependencies & "</dependencies>"
			xml = xml & "<projectTemplateID>" & projectTemplateID & "</projectTemplateID>"
			
			' build checklists here
			SQL = "select * from taskChecklists where taskID = " & rsTasks("id") & " " 
			dbug(SQL)
			set rsChecklists = dataconn.execute(SQL)
			while not rsChecklists.eof 
			
				newID 									= getNextID("projectTemplateTaskChecklists")
				projectTemplateTaskChecklistID 	= newID

				
				if isNull(rsChecklists("name")) then 
					checklistName = "NULL"
				else 
					checklistName = "'" & replace(rsChecklists("name"), "'", "''") & "'"
				end if
				
				SQL = "insert into projectTemplateTaskChecklists (id, projectTemplateTaskID, name) " &_
						"values ( " &_
							newID & ", " &_
							projectTemplateTaskID & ", " &_
							checklistName & ") "

				dbug(SQL)			

				set rsInsertPTTC = dataconn.execute(SQL)
				set rsInsertPTTC = nothing 
				
				dbug("insert insert projectTemplatTaskXhecklists complete, continuing...") 
				xml = xml & "<checklist id=""" & newID & """>"
				xml = xml & "<projectTemplateTaskID>" & projectTemplateTaskID & "</projectTemplateTaskID>"
				xml = xml & "<name>" & checklistName & "</name>"
				dbug("xml for insert projectTemplatTaskXhecklists complete, continuing...") 
				
				' build checklistItems here
				SQL = "select * from taskChecklistItems where checklistID = " & rsChecklists("id") & " " 
				dbug(SQL)
				set rsChecklistItems = dataconn.execute(SQL)
				while not rsChecklistItems.eof 
				
					newID = getNextID("projectTemplateTaskChecklistItems")
					
					if isNull(rsChecklistItems("description")) then 
						itemDescription = "NULL"
					else 
						itemDescription = "'" & replace(rsChecklistItems("description"), "'", "''") & "'" 
					end if 
					
					SQL = "insert into projectTemplateTaskChecklistItems (id, projectTemplateTaskChecklistID, description) " &_
							"values ( " &_
								newID & ", " &_
								projectTemplateTaskChecklistID & ", " &_
								itemDescription & ") " 
					
					dbug(SQL) 
													
					set rsInsertPTTCI = dataconn.execute(SQL)
					set rsInsertPTTCI = nothing 
					
					xml = xml & "<item id=""" & newID & """>"
					xml = xml & "<projectTemplateTaskChecklistID>" & projectTemplateTaskChecklistID & "</projectTemplateTaskChecklistID>"
					xml = xml & "<description>" & itemDescription & "</description>"
					xml = xml & "</item>"
					
					rsChecklistItems.movenext 
					
				wend 
					
				
				xml = xml & "</checklist>"
				
				rsChecklists.movenext 
				
			wend 
					
			
			xml = xml & "</task>"
			
			rsTasks.movenext 
			
		wend 
		
		rsTasks.close 
		set rsTasks = nothing 
		
		msg = "Template created"
		
		
	case "projectFromTemplate"
	
		projectTemplateID 	= request.querystring("projectTemplateID")
		newProjectName 		= "'" & replace(request.querystring("newProjectName"), "'", "''") & "'" 
		anchorDateType 		= request.querystring("anchorDateType")
		anchorDate 				= request.querystring("anchorDate")
		
		if len(request.querystring("projectManagerID")) > 0 then 
			projectManagerID		= request.querystring("projectManagerID")
		else 
			projectManagerID		= "NULL"
		end if 
		
		customerID				= request.querystring("customerID")
		
		newProjectID = getNextID("projects")
		

		SQL = "select top 1 startOffsetDays + taskDurationDays + endOffsetDays as projectDurationDays " &_
				"from projectTemplateTasks " &_
				"where projectTemplateID = " & projectTemplateID & " " 
				
' 		dbug(SQL)
		set rsPT = dataconn.execute(SQL)
		if not rsPT.eof then 
			projectDurationDays = rsPT("projectDurationDays")
		else 
			response.write("Error: could not determine project duration")
			response.end()
		end if
		rsPT.close 
		set rsPT = nothing
		
		if lCase(anchorDateType) = "start" then 
			startDate 	= anchorDate
			endDate   	= workDaysAdd(startDate, cInt(projectDurationDays))
		else 
			endDate 		= anchorDate
' 			dbug("endDate: " & endDate)
' 			dbug("projectDurationDays: " & projectDurationDays)
			startDate	= workDaysAdd(endDate, -cInt(projectDurationDays))	
		end if
				
		
		SQL = "insert into projects (id, name, customerID, startDate, endDate, updatedBy, updatedDateTime, projectManagerID) " &_
				"values ( " &_
					newProjectID & ", " &_
					newProjectName & ", " &_
					customerID & ", " &_
					"'" & startDate & "', " &_
					"'" & endDate & "', " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP, " &_
					projectManagerID & ") "

' 		dbug(SQL)					
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
					
		xml = xml & "<project id=""" & newProjectID & """>"
		xml = xml & "<name>" & escapeHtmlCharacters(newProjectName) & "</name>"
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<startDate>" & startDate & "</startDate>"
		xml = xml & "<endDate>" & endDate & "</endDate>"
		xml = xml & "<projectManagerID>" & projectManagerID & "</projectManagerID>"
		
		SQL = "select * from projectTemplateTasks where projectTemplateID = " & projectTemplateID & " " 
' 		dbug(SQL)
		set rsTasks = dataconn.execute(SQL)
		while not rsTasks.eof
		
			newTaskID 			= getNextID("tasks")
			taskName 			= "'" & replace(rsTasks("name"), "'", "''") & "'"
			taskDescription	= "'" & replace(rsTasks("description"), "'", "''") & "'"
			startOffsetDays 	= cInt(rsTasks("startOffsetDays"))
			taskDurationDays 	= cInt(rsTasks("taskDurationDays"))
			endOffsetDays 		= cInt(rsTasks("endOffsetDays"))
			
			if lCase(anchorDateType) = "start" then 
				taskStartDate 	= workDaysAdd(anchorDate, cInt(startOffsetDays))
				taskDueDate 	= workDaysAdd(taskStartDate, cInt(taskDurationDays))
			else 
				taskDueDate 	= workDaysAdd(anchorDate, -cInt(endOffsetDays))
				taskStartDate 	= workDaysAdd(taskDueDate, -cInt(taskDurationDays))
			end if
			
			if isNull(rsTasks("estimatedWorkDays")) then 
				estimatedWorkDays = "NULL"
			else 
				estimatedWorkDays = cInt(rsTasks("estimatedWorkDays"))
			end if 
			
			if isNull(rsTasks("acceptanceCriteria")) then 
				acceptanceCriteria = "NULL" 
			else 
				acceptanceCriteria = "'" & replace(rsTasks("acceptanceCriteria"), "'", "''") & "'"
			end if
			
			
			SQL = "insert into tasks (id, projectID, name, description, startDate, dueDate, updatedBy, updatedDateTime, estimatedWorkDays, dependencies, acceptanceCriteria, customerID) " &_
					"values ( " &_
						newTaskID & ", " &_
						newProjectID & ", " &_
						taskName & ", " &_
						taskDescription & ", " &_
						"'" & taskStartDate & "', " &_
						"'" & taskDueDate & "', " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						estimatedWorkDays & ", " &_
						"'" & rsTasks("dependencies") & "', " &_
						acceptanceCriteria & ", " &_
						customerID & ") " 


' 			dbug(SQL)
			set rsInsert = dataconn.execute(SQL)
			set rsInsert  = nothing 
						
			xml = xml & "<task id=""" & newTaskID & """>"
			xml = xml & "<name>" & taskName & "</name>"
			xml = xml & "<description>" & taskDescription & "</description>"
			xml = xml & "<startDate>" & taskStartDate & "</startDate>"
			xml = xml & "<dueDate>" & taskDueDate & "</dueDate>"
			xml = xml & "<estimatedWorkDays>" & rsTasks("estimatedWorkDays") & "</estimatedWorkDays>"
			xml = xml & "<dependencies>" & rsTasks("dependencies") & "</dependencies>"
			xml = xml & "<acceptanceCriteria>" & acceptanceCriteria & "</acceptanceCriteria>"
			xml = xml & "<customerID>" & customerID & "</customerID>"
				
			SQL = "select * from projectTemplateTaskChecklists where projectTemplateTaskID = " & rsTasks("id") & " " 
' 			dbug(SQL)
			set rsChecklists = dataconn.execute(SQL) 
			while not rsChecklists.eof 
			
				newChecklistID = getNextID("taskChecklists") 
				checklistName	= "'" & replace(rsChecklists("name"), "'", "''") & "'" 
				
			if isNull(rsTasks("acceptanceCriteria")) then 
				acceptanceCriteria = "NULL" 
			else 
				acceptanceCriteria = "'" & replace(rsTasks("acceptanceCriteria"), "'", "''") & "'"
			end if
			
				SQL = "insert into taskChecklists (id, taskID, name, updatedBy, updatedDateTime) " &_
						"values ( " &_
							newChecklistID & ", " &_
							newTaskID & ", " &_
							checklistName & ", " &_
							session("userID") & ", " &_
							"CURRENT_TIMESTAMP) " 
				
' 				dbug(SQL)
				set rsInsert = dataconn.execute(SQL)
				set rsInsert = nothing 
							
				xml = xml & "<checklist id=""" & newChecklistID & """>"
				xml = xml & "<name>" & escapeHtmlCharacters(rsChecklists("name")) & "</name>"
					
				
				SQL = "select * from projectTemplateTaskChecklistItems where projectTemplateTaskChecklistID = " & rsChecklists("id") & " " 
' 				dbug(SQL)
				set rsItems = dataconn.execute(SQL) 
				while not rsItems.eof 
				
					newItemID 			= getNextID("taskChecklistItems") 
					itemDescription 	= "'" & replace(rsItems("description"), "'", "''") & "'" 
					
					
					SQL = "insert into taskChecklistItems (id, checklistID, description, updatedBy, updatedDateTime) " &_
							"values ( " &_
								newItemID & ", " &_
								newChecklistID & ", " &_
								itemDescription & ", " &_
								session("userID") & ", " &_
								"CURRENT_TIMESTAMP) "
								
' 					dbug(SQL)
					set rsInsert = dataconn.execute(SQL)
					set rsInsert = nothing 
					
					xml = xml & "<item id=""" & newItemID & """>"
					xml = xml & "<description>" & escapeHtmlCharacters(rsItems("description")) & "</description>"
					xml = xml & "</item>"
					rsItems.movenext 
					
				wend 
				
				rsItems.close 
				set rsItems = nothing 
				xml = xml & "</checklist>"
				rsChecklists.movenext 
				
			wend 

			rsChecklists.close 
			set rsChecklists = nothing 
			xml = xml & "</task>"
			rsTasks.movenext 

		wend 

		rsTasks.close 
		set rsTasks = nothing 					
		xml = xml & "</project>"
		
		msg = "Project generated from template"
	
	
	case "queryMinFinishDate"	
	
		templateID = request.querystring("templateID")
		
		SQL = "select max(startOffsetDays + taskDurationDays + endOffsetDays) as maxDays from projectTemplateTasks where projectTemplateID = " & templateID & " " 
' 		dbug(SQL)
		set rsMax = dataconn.execute(SQL)
		if not isNull(rsMax("maxDays")) then 
			maxDays = rsMax("maxDays")
		else 
			maxDays = 0
		end if 
' 		dbug("maxDays: " & maxDays)
		
		tempDate = (workDaysAdd(date(),maxDays))
' 		dbug("tempDate: " & tempDate)
		
		minFinishDate = formatHTML5Date(tempDate)
' 		dbug("minFinishDate: " & minFinishDate)
		
		msg = "Min finish date retrieved"
		
		xml = xml & "<templateID>" & templateID & "</templateID>"
		xml = xml & "<templateDuration>" & maxDays & "</templateDuration>"
		xml = xml & "<minFinishDate>" & minFinishDate & "</minFinishDate>"
		
	
	case "addTaskProject"
	
		'NOTE this section is used to associate (or to disassociate) a task to a project. 
		
' 		customerID = request.form("customerID")
' 		taskID 		= request.form("taskID")
' 		projectID	= request.form("projectID")
		
		customerID = request.querystring("customerID")
		taskID 		= request.querystring("taskID")
		projectID	= request.querystring("projectID")
		
		if len(projectID) > 0 then 
			project = projectID
			msg = "Task associated to project"
		else 
			project = "NULL"
			msg = "Task disassociated from project"
		end if 
		
		SQL = "update tasks set " &_
					"projectID = " & project & ", " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where customerID = " & customerID & " " &_
				"and id = " & taskID & " " 
				
' 		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<taskID>" & taskID & "</taskID>"
		xml = xml & "<projectID>" & projectID & "</projectID>"
		

	case "addTaskKeyInitiative"
	
' 		customerID = request.form("customerID")
' 		taskID 		= request.form("taskID")
' 		projectID	= request.form("projectID")
' 		
		customerID = request.querystring("customerID")
		taskID 		= request.querystring("taskID")
		keyInitiativeID	= request.querystring("keyInitiativeID")
		
		SQL = "insert into keyInitiativeTasks (keyInitiativeID, taskID, updatedBy, updatedDateTime) " &_
				"values ( " &_
					keyInitiativeID & ", " &_
					taskID & ", " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP) "
					
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		msg = "Task associated with key initiative" 
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<taskID>" & taskID & "</taskID>"
		xml = xml & "<keyInitiativeID>" & keyInitiativeID & "</keyInitiativeID>"


	case "removeKeyInitiativeTask"
	
		keyInitiativeID 	= request.querystring("keyInitiativeID")
		taskID				= request.querystring("taskID")
		
' 		keyInitiativeID 	= request.form("keyInitiativeID")
' 		taskID				= request.form("taskID")
		
		SQL = "delete from keyInitiativeTasks " &_
				"where keyInitiativeID = " & keyInitiativeID & " " &_
				"and taskID = " & taskID & " " 
				
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		msg = "Task removed from key initiative"
		xml = xml & "<keyInitiativeID>" & keyInitiativeID & "</keyInitiativeID>"
		xml = xml & "<taskID>" & taskID & "</taskID>"

		
	case "deleteProjectTemplate"	
	
		projectTemplateID = request.form("id")
		
		SQL = "delete from projectTemplateTaskChecklistItems " &_
				"where id in " &_
					"( " &_
					"select ttci.id " &_
					"from projectTemplates t " &_
					"join projectTemplateTasks tt on (tt.projectTemplateID = t.id) " &_
					"join projectTemplateTaskChecklists ttc on (ttc.projectTemplateTaskID = tt.id) " &_
					"join projectTemplateTaskChecklistItems ttci on (ttci.projectTemplateTaskChecklistID = ttc.id) " &_
					"where t.id = " & projectTemplateID & ") "

' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
' 		dbug("projectTemplateTaskChecklistItems successfully deleted...")
		
		
		SQL = "delete from projectTemplateTaskChecklists " &_
				"where id in " &_
					"( " &_
					"select ttc.id " &_
					"from projectTemplates t " &_
					"join projectTemplateTasks tt on (tt.projectTemplateID = t.id) " &_
					"join projectTemplateTaskChecklists ttc on (ttc.projectTemplateTaskID = tt.id) " &_
					"where t.id = " & projectTemplateID & ") "
		
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
' 		dbug("projectTemplateTaskChecklists deleted...")
		
		
		SQL = "delete from projectTemplateTasks " &_
				"where id in " &_
					"( " &_
					"select tt.id " &_
					"from projectTemplates t " &_
					"join projectTemplateTasks tt on (tt.projectTemplateID = t.id) " &_
					"where t.id = " & projectTemplateID & ") "
		
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
' 		dbug("projectTemplateTasks deleted...")
		
		
		SQL = "delete from projectTemplates " &_
				"where id = " & projectTemplateID & " "
				
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		msg = "Project template deleted"

		xml = xml & "<projectTemplateID>" & projectTemplateID & "</projectTemplateID>"
		
	
	
	case "getProjectStatusAndPermissions"
	
		dbug("start of getProjectStatusAndPermissions..")
	
		projectCompletable 	= true 
		
		dbug("projectUnCompletable initially set to false...")
		projectUnCompletable = false
		
		projectID = request.querystring("projectID") 
		
		SQL = "select count(*) as openTaskCount " &_
				"from tasks " &_
				"where projectID = " & projectID & " " &_
				"and completionDate is null "
				
		set rsOpenTasks = dataconn.execute(SQL) 
		if not rsOpenTasks.eof then 
			openTaskCount = cInt(rsOpenTasks("openTaskCount"))
		else 
			openTaskCount = 0
		end if 
		rsOpenTasks.close 
		set rsOpenTasks = nothing 
		
		SQL = "select count(*) as kiCompletedCount " &_
				"from keyInitiativeProjects a " &_
				"join keyInitiatives b on (b.id = a.keyInitiativeID) " &_
				"where a.projectID = " & projectID & " " &_
				"AND b.completeDate is not null "
				
		dbug(SQL)
		set rsKICount = dataconn.execute(SQL) 
		if not rsKiCount.eof then 
			dbug("NOT rsKiCount.eof; rsKICount('kiCompleteCount'): " & rsKICount("kiCompletedCount") )
			if ( cint(rsKICount("kiCompletedCount")) ) <= 0 then 
				dbug("projectUnCompletable being set to true")
				projectUnCompletable = true 
			else 
				dbug("projectUnCompletable being set to false")
				projectUnCompletable = false 
			end if 
		else 
			dbug("projectUnCompletable being set to true")
			projectUnCompletable = true 
		end if 				
		

		SQL = "select top 1 type " &_
				"from projectStatus " &_
				"where projectID = " & projectID & " " &_
				"order by updatedDateTime desc "
				
		set rsProjectStatus = dataconn.execute(SQL) 
		if not rsProjectStatus.eof then
			projectStatus = lCase(rsProjectStatus("type"))
		else 
			projectStatus = "none" 
		end if 
		rsProjectStatus.close 
		set rsProjectStatus = nothing 
		
					
		select case lCase(projectStatus) 
		
			case "on time", "none", "uncomplete"
			
				ontimeState 		= "enabled"
				escalateState		= "enabled"
				rescheduleState	= "enabled"
				
				if userPermitted(44) then 
					completeState		= "enabled"
				else 
					if openTaskCount = 0 then 
						completeState = "enabled"
					else 
						completeState = "disabled"
					end if 
				end if
				
				msg = "On Time status/permission complete"
				
			case "escalate" 
		
				ontimeState 		= "enabled"
				escalateState		= "disabled"
				rescheduleState	= "enabled"
				
				if userPermitted(44) then 
					completeState		= "enabled"
					msg = "Project can be completed because even though there are incomplete tasks you have override permission"
				else 
					if openTaskCount = 0 then 
						completeState = "enabled"
						msg = "Project can be completed because all tasks are complete"
						projectCompletable = true 
					else 
						completeState = "disabled"
						msg = "Project cannot be completed because there are incomplete tasks"
						projectCompletable = false 
					end if 
				end if
				
' 				projectUnCompletable = false 
				

			case "reschedule"

				ontimeState 		= "enabled"
				escalateState		= "enabled"
				rescheduleState	= "disabled"
				
				if userPermitted(44) then 
					completeState		= "enabled"
					msg = "Project can be completed because even though there are incomplete tasks you have override permission"
				else 
					if openTaskCount = 0 then 
						completeState = "enabled"
						msg = "Project can be completed because all tasks are complete"
						projectCompletable = true 
					else 
						completeState = "disabled"
						msg = "Project cannot be completed because there are incomplete tasks"
						projectCompletable = false 
					end if 
				end if
				
' 				projectUnCompletable = false 
				

			case "complete"
			
				if projectUnCompletable then 
				
					if userPermitted(45) then 
	
						ontimeState 			= "enabled"
						escalateState			= "enabled"
						rescheduleState		= "enabled"
						msg = "Project can be un-completed because you have permission"
	' 					projectUnCompletable = true 
						
					else 
	
						ontimeState 			= "disabled"
						escalateState			= "disabled"
						rescheduleState		= "disabled"
						msg = "Project cannot be un-completed because you do not have permission"
	' 					projectUnCompletable = false 
	
					end if 	
					
				else 
					
					ontimeState 			= "disabled"
					escalateState			= "disabled"
					rescheduleState		= "disabled"
					msg = "Project is not un-completable"
					
				end if

				completeState = "disabled" 
				projectCompletable = false 
				

			case else 
			
				ontimeState 			= ""
				escalateState 			= "" 
				rescheduleState 		= ""
				completeState 			= ""
				
				msg = "unknown status encountered"
				
				projectCompletable 	= ""
				projectUnCompletable = ""
				
		end select 
			
			
		xml = xml & "<ontimeState>" & ontimeState & "</ontimeState>"		
		xml = xml & "<escalateState>" & escalateState & "</escalateState>"		
		xml = xml & "<rescheduleState>" & rescheduleState & "</rescheduleState>"		
		xml = xml & "<completeState>" & completeState & "</completeState>"		

		xml = xml & "<projectCompletable>" & projectCompletable & "</projectCompletable>"
		xml = xml & "<projectUncompletable>" & projectUncompletable & "</projectUncompletable>"
		


	case else 
	
		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"


end select 

userLog(msg)

dataconn.close
set dataconn = nothing

xml = xml & "<msg>" & msg & "</msg>"
%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</projectMaintenance>"

response.write(xml)
%>