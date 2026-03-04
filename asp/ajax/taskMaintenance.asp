<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/workDaysBetween.asp" -->
<!-- #include file="../includes/workDaysAdd.asp" -->
<!-- #include file="../includes/taskDaysAtRisk.asp" -->
<!-- #include file="../includes/taskDaysBehind.asp" -->
<!-- #include file="../includes/taskDaysAhead.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

'***** TASK MAINTENANCE *****
response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<taskMaintenance>"

msg = ""

'===============================================================================
sub updateProjectStatus(taskID,projectID) 
'===============================================================================
	
	if not isNull(projectID) then 
		
		SQL = "select count(*) as openTaskCount " &_
				"from tasks " &_
				"where projectID = " & projectID & " " &_
				"and completionDate is null "
	else 
		
		SQL = "select count(*) as openTaskCount " &_
				"from tasks " &_
				"where projectID = (select projectID from tasks where id = " & taskID & ") " &_
				"and completionDate is null "
				
	end if 

' 	dbug("count complete tasks SQL: " & SQL)

	set rsTC = dataconn.execute(SQL)
	if not rsTC.eof then 
		if not isNull(rsTC("openTaskCount")) then 
			if cInt(rsTC("openTaskCount")) > 0 then 
				projectComplete = 0 
			else 
				projectComplete = 1 
			end if 
		else 
			projectComplete = 0 
		end if
	else 
		projectComplete = 0 
	end if
	
	rsTC.close 
	set rsTC = nothing 
	
	if not isNull(projectID) then 
		
		SQL = "update projects set " &_
					"complete = " & projectComplete & ", " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP "  &_
				"where id = " & projectID & " " 
					
	else 
		
		SQL = "update projects set " &_
					"complete = " & projectComplete & ", " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP "  &_
				"where id = " &_
					"(select distinct projectID from tasks where id = " & taskID & ") " 
					
	end if
	
' 	dbug(SQL)
	
	set rsUpdate = dataconn.execute(SQL)
	set rsUpdate = nothing 
	
	
	
end sub 



'===============================================================================
'===============================================================================
'===============================================================================
'===============================================================================

select case request.querystring("cmd")

	'===============================================================================
	case "removeProject"
	'===============================================================================
	
		taskID = request.querystring("taskID")
		
		SQL = "update tasks set projectID = null where id  = " & taskID & " " 
		
' 		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 

		xml = xml & "<id>" & taskID & "</id>"

		msg = "Project removed from task"
		
		

	'===============================================================================
	case "delete"
	'===============================================================================

		task = request.querystring("task")
		project = request.querystring("project")
		
		SQL = "delete from tasks where id = " & task
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		
		SQL = "delete from keyInitiativeTasks where taskID = " & task 
		
		set rsDeleteKI = dataconn.execute(SQL)
		set rsDeleteKI = nothing 
		
		
		if len(project) > 0 then 
			updateProjectStatus null, project
		end if
		
		
		xml = xml & "<id>" & task & "</id>"
		xml = xml & "<projectComplete>" & projectComplete & "</projectComplete>" 

		msg = "Task deleted; refreshing page..."
		

	'===============================================================================
	case "update"
	'===============================================================================
	
		task = request.querystring("task")

		xml = xml & "<id>" & task & "</id>"

		select case request.querystring("name")

			case "taskName"
				name = "name"
				
				value = replace(request.querystring("value"),"'", "''")
' 				value = replace(value, """", "&quot;")
				
				sqlAssignment = name & " = '" & value & "' "
				msg = name & " updated"

			case "taskDescription"
				name = "description" 
				
				value = replace(request.querystring("value"),"'", "''")
' 				value = replace(value, """", "&quot;")
				
				sqlAssignment = name & " = '" & value & "' "
				msg = name & " updated"
				
			case "ownerID"
				name = "ownerID"
				
' 				dbug("value: " & request.querystring("value"))
' 				dbug("len(value): " & len(request.querystring("value")))
				
				if len(request.querystring("value")) > 0 then 
					value = request.querystring("value")
				else 
					value = "NULL"
				end if
				
				sqlAssignment = name & " = " & value & " " 
				msg = name & " updated"

			case "startDate","dueDate","completionDate"
' 				dbug("one of the dates updated...")
				name = request.querystring("name")
' 				dbug("date is question is " &  name)

				if len(request.querystring("value")) > 0 then 
					if isDate(request.querystring("value")) then 
						
						value = cDate(request.querystring("value"))
' 						dbug("date provided is a valid date: " & date )
						
						sqlAssignment = name & " = '" & formatDateTime(value,2) & "' "
						
						SQL = "select startDate, dueDate, completionDate from tasks where id = " & task & " "
' 						dbug("SQL for 'old' dates: " & SQL)
						set rsDates = dataconn.execute(SQL)
						if not rsDates.eof then 
' 							dbug("'old' dates found...")
							oldStartDate = rsDates("startDate")
							oldDueDate = rsDates("dueDate")
							oldCompletionDate = rsDates("completionDate")
						else 
' 							dbug("'old' dates not found")
							oldStartDate = null 
							oldDueDate = null 
							oldCompletionDate = null 
						end if 
						rsDates.close 
						set rsDate = nothing 
						
						select case name 
							case "startDate"
								if isDate(oldDueDate) then 
									estimatedWorkDays = workDaysBetween(value, oldDueDate)
									sqlAssignment = sqlAssignment & ", estimatedWorkDays = " & estimatedWorkDays
									xml = xml & "<estimatedWorkDays>" & estimatedWorkDays & "</estimatedWorkDays>"
								else 
									estimatatedWorkDays = null 
									sqlAssignment = sqlAssignment & ", estimatedWorkDays = null" 
									xml = xml & "<estimatedWorkDays></estimatedWorkDays>"
								end if 

								if isDate(oldCompletionDate) then 
									actualWorkDays = workDaysBetween(value, oldCompletionDate)
									sqlAssignment = sqlAssignment & ", actualWorkDays = " & actualWorkDays
									xml = xml & "<actualWorkDays>" & actualWorkDays & "</actualWorkDays>"
								else 
									actualWorkDays = null 
									sqlAssignment = sqlAssignment & ", actualWorkDays = null"
									xml = xml & "<actualWorkDays></actualWorkDays>"
								end if

							case "dueDate"
								if isDate(oldStartDate) then 
									estimatedWorkDays = workDaysBetween(oldStartDate, value)
									sqlAssignment = sqlAssignment & ", estimatedWorkDays = " & estimatedWorkDays
									xml = xml & "<estimatedWorkDays>" & estimatedWorkDays & "</estimatedWorkDays>"
								else 
									estimatedWorkDays = null 
									sqlAssignment = sqlAssignment & ", estimatedWorkDays = null"
									xml = xml & "<estimatedWorkDays></estimatedWorkDays>"
								end if

							case "completionDate"
								if isDate(oldStartDate) then 
									actualWorkDays = workDaysBetween(oldStartDate, value)
									sqlAssignment = sqlAssignment & ", actualWorkDays = " & actualWorkDays
									xml = xml & "<actualWorkDays>" & actualWorkDays & "</actualWorkDays>"
								else 
									actualWorkDays = null 
									sqlAssignment = sqlAssignment & ", actualWorkDays = null"
									xml = xml & "<actualWorkDays></actualWorkDays>"
								end if

							case else 
								estimatedWorkDays = null 
								actualWorkDays = null 
								sqlAssignment = sqlAssignment & ", estimatedWorkDays = null, actualWorkDays = null"
								xml = xml & "<estimatedWorkDays></estimatedWorkDays>"
								xml = xml & "<actualWorkDays></actualWorkDays>"
						end select 

						
						msg = name & " updated"
						
						
					else 
						value = "[invalid date]"
						sqlAssignment = name & " = '" & value & "' "
						msg = name & " is an invalid date"
					end if 
				else 
					value = null 
					sqlAssignment = name & " = NULL " 
					msg = name & " updated"
				end if 
				
				
			case "taskStatusID" 
			
				name = "taskStatusID"
				
				if len(request.querystring("value")) > 0 then 
					value = request.querystring("value")
				else 
					value = "NULL"
				end if
									
				sqlAssignment = name & " = " & value & " " 
				msg = "Status updated" 

				dbug("cInt(value): " & cInt(value))
				
				select case cInt(value) 
				
					case 1 			' *** In Progress ***
					
						' set taskStatusID = 1, completionDate = NULL, skippedReason = NULL
						
						sqlAssignment = "taskStatusID = 1, completionDate = NULL, skippedReason = NULL " 

					case 2			' ***   Complete  ***

						' set taskStatusID = 2, completionDate = getdate(), skippedReason = NULL

						sqlAssignment = "taskStatusID = 2, completionDate = getdate(), skippedReason = NULL " 

					case else 		' ***   unknown   ***

						' *** Skipping a task (taskStatusID=3) is handled by cmd="skipTask" so throw an error here
						' *** throw an error for any other value, too

						sqlAssignment = "*** UNEXPECTED taskStatusID IN UPDATE DIRECTIVE *** " 

				end select 


			case else 
				name = "[unknown attribute]"
				value = request.querystring("value")
				sqlAssignment = name & " = '" & value & "' "
				msg = name & " updated"

		end select 
		
		SQL = "update tasks set " &_
					 sqlAssignment & ", " &_
					 "updatedBy = " & session("userID") & ", " &_
					 "updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & task & " " 
				
		dbug("UPDATE SQL: " & SQL)
		
		
		set taskUpdate = dataconn.execute(SQL)
		set taskUpdate = nothing 
		
		' determine status of the project -- if all tasks are complete, then project is complete
		'  if one or more tasks are not complete then the project is not complete...
		if name = "completionDate" then 

			updateProjectStatus task, null

		end if
		
		
		

		xml = xml & "<" & name & "><![CDATA[" & value & "]]></" & name & ">"		
		xml = xml & "<taskDaysAtRisk>" & taskDaysAtRisk(task) & "</taskDaysAtRisk>"
		xml = xml & "<taskDaysAhead>" & taskDaysAhead(task) & "</taskDaysAhead>"
		xml = xml & "<taskDaysBehind>" & taskDaysBehind(task) & "</taskDaysBehind>" 
		xml = xml & "<projectComplete>" & projectComplete & "</projectComplete>" 
		
				
	'===============================================================================
	case "add"
	'===============================================================================
	
		taskName 			= replace(request.querystring("name"), "'", "''")
		taskName				= replace(taskName, """", "&quot;")
		
		taskDescription 	= replace(request.querystring("description"), "'", "''")
		taskDescription 	= replace(taskDescription, """", "&quot;")
		
		
		if not isNull(request.querystring("owner")) then 
			if len(request.querystring("owner")) > 0 then 
				if IsNumeric(request.querystring("owner")) then 
					taskOwnerID = request.querystring("owner") 
				else 
					taskOwnerID = "NULL"
				end if
			else 
				taskOwnerID = "NULL"
			end if 
		else 
			taskOwnerID = "NULL"
		end if 
		
		taskStartDate 		= formatDateTime(request.querystring("start"),2)
		taskDueDate 		= formatDateTime(request.querystring("due"),2)
		taskCustomerID		= request.querystring("customerID")
		
		if not isNull(request.querystring("projectID")) then 
			if len(request.querystring("projectID")) > 0 then 
				if isNumeric(request.querystring("projectID")) then 
					projectID = request.querystring("projectID")
				else 
					projectID = "NULL" 
				end if 
			else 
				projectID = "NULL"
			end if 
		else 
			projectID = "NULL"
		end if 
		
		if len(taskName) > 0 then 
			
' 			dbug("taskName present")
			
			if isDate(taskStartDate) then 
				
' 				dbug("taskStartDate isDate()")
				
				if isDate(taskDueDate) then 
					
' 					dbug("taskDueDate isDate()")
					
					newID = getNextID("tasks")						
					estimatedWorkDays = workDaysBetween(taskStartDate, taskDueDate)
					
					SQL = "insert into tasks (id, projectID, ownerID, name, description, startDate, dueDate, estimatedWorkDays, customerID) " &_
							"values ( " &_
								newID & ", " &_
								projectID & ", " &_
								taskOwnerID & ", " &_
								"'" & taskName & "', " &_
								"'" & taskDescription & "', " &_
								"'" & taskStartDate & "', " &_
								"'" & taskDueDate & "', " &_
								estimatedWorkDays & ", " &_
								taskCustomerID & " " &_
							") "
							
' 					dbug(SQL) 
					set rsInsert = dataconn.execute(SQL)
					set rsInsert = nothing 


					updateProjectStatus null, projectID 										
					
					
					xml = xml & "<id>" & newID & "</id>"
					xml = xml & "<customerID>" & taskCustomerID & "</customerID>"
					xml = xml & "<projectID>" & projectID & "</projectID>"
					xml = xml & "<ownerID>" & taskOwnerID & "</ownerID>"
					xml = xml & "<name>" & replace(taskName, "&", "&amp;") & "</name>"
					xml = xml & "<description>" & replace(taskDescription, "&", "&amp;") & "</description>"
					xml = xml & "<startDate>" & taskStartDate & "</startDate>"
					xml = xml & "<dueDate>" & taskDueDate & "</dueDate>"
					
					msg = "Task added"
					
					
				else 
					
					msg = "Due date missing or invalid"
					
				end if
				
			else 
				
				msg = "Start date missing or invalid"
				
			end if
			
		else 
			
			msg = "Task name missing"
			
		end if
		

	'===============================================================================
	case "addChecklist"
	'===============================================================================
	
		newID 	= getNextID("taskChecklists")
		taskID 	= request.querystring("task")
		
		name 		= request.querystring("name")
		name		= replace(name, "'", "''")
		
		SQL = "insert into taskChecklists (id, taskID, name, updatedBy, updatedDateTime) " &_
				"values (" &_
					newID & ", " &_
					taskID & ", " &_
					"'" & name & "', " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP) " 
					
' 		dbug(SQL)
		
		set rsInsert = dataconn.execute(SQL)
		set rsInser = nothing 

		msg = "Checklist added"
				
		xml = xml & "<taskID>" & taskID & "</taskID>"		
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<name>" & name & "</name>"
		
		
	'===============================================================================
	case "deleteTaskChecklist"
	'===============================================================================
	
		id = request.querystring("id")
		
		SQL = "delete from taskChecklistItems where checklistID = " & id & " "
		set rsDelete = dataconn.execute(SQL)
		SQL = "delete from taskChecklists where id = " & id & " " 
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing
		
		msg = "Checklist deleted"
				
		xml = xml & "<checklistID>" & id & "</checklistID>"		
		

	'===============================================================================
	case "deleteItem"
	'===============================================================================
	
' 		dbug("deleteItem detected")

		id = request.querystring("id")
		
		SQL = "delete from taskChecklistItems where id = " & id & " "
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing
		
		msg = "Item deleted"
				
		xml = xml & "<itemID>" & id & "</itemID>"		
		

	'===============================================================================
	case "addChecklistItem"
	'===============================================================================
	
' 		dbug("addChecklistItem detected")
		
		newID = getNextID("taskChecklistItems")
		checklistID = request.querystring("checklistID")
		description = request.querystring("description")

		description = replace(description, "'", "&#39;")
		description = replace(description, """", "&quot;")
		
		SQL = "insert into taskCheckListItems (id, checklistID, description, updatedBy, updatedDateTime) " &_
				"values ( " &_
					newID & ", " &_
					checklistID & ", " &_
					"'" & description & "', " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP) "
					
' 		dbug(SQL)
					
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		msg = "Checklist item added"
				
		xml = xml & "<id>" & newID & "</id>"		
		xml = xml & "<checklistID>" & checklistID & "</checklistID>"		
		xml = xml & "<description><![CDATA[" & description & "]]></description>"		
		
		

	'===============================================================================
	case "updateItem"
	'===============================================================================
	
		id 			= request.querystring("id")
		completed 	= request.querystring("completed")
		
		
		'--------------------------------------------------------------------
		' first update the checklistItem...
		'--------------------------------------------------------------------
		'		
		SQL = "update taskChecklistItems " &_
					"set completed = " & completed & " " &_
				"where id = " & id & " "

' 		dbug(SQL)				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		msg = "Item updated"
				
		xml = xml & "<id>" & id & "</id>"		
		xml = xml & "<cmd>Item</cmd>"		
		xml = xml & "<completed>" & completed & "</completed>"		
		
		
		'--------------------------------------------------------------------
		' determine if the item's parent checklist should be updated...
		'--------------------------------------------------------------------
		'		
		SQL = "select " &_
					"count(*) as totalItems, " &_
					"sum(case when completed = 1 then 1 else 0 end) as completedItems " &_
				"from taskChecklistItems " &_
				"where checklistID = ( " &_
					"select checklistID from taskChecklistItems where id = " & id & " " &_
				") "
		set rs = dataconn.execute(SQL) 
		if not rs.eof then 
			if cInt(rs("completedItems")) < cInt(rs("totalItems")) then 
				checklistCompleted = 0
			else
				checklistCompleted = 1
			end if

			SQL = "update taskChecklists set completed = " & checklistCompleted & " " &_
					"where id = ( " &_
						"select checklistID from taskChecklistItems where id = " & id & " " &_
					") "
' 			dbug("update taskChecklistItems: " & SQL)
			set rsUpdate = dataconn.execute(SQL) 
			set rsUpdate = nothing 
			
			xml = xml & "<checklistCompleted>" & checklistCompleted & "</checklistCompleted>"
		else 

			xml = xml & "<checklistCompleted></checklistCompleted>"

		end if 

		rs.close 
		set rs = nothing 
		
		
		'--------------------------------------------------------------------
		' determine if the task can now be completed...
		'--------------------------------------------------------------------
		'		
		SQL = "select count(i.completed) + count(c.completed) totalItems " &_
				"from tasks t " &_
				"join taskChecklists c on (c.taskID = t.id) " &_
				"join taskChecklistItems i on (i.checklistID = c.id) " &_
				"where t.id =  " &_
					"( " &_
					"select t.id " &_
					"from tasks t " &_
					"join taskChecklists c on (c.taskID = t.id) " &_
					"join taskChecklistItems i on (i.checklistID = c.id) " &_
					"where i.id = " & id & " " &_
					") " &_
				"and ((i.completed = 0 or i.completed is null) OR (c.completed = 0 or c.completed is null)) " 
		
' 		dbug("udpate taskChecklists: " & SQL)
		
		set rsC = dataconn.execute(SQL) 
		
		if rsC("totalItems") > 0 then 
			taskCompletable = "false" 
		else 
			taskCompletable = "true"
		end if

		rsC.close 
		set rsC = nothing 
		
		xml = xml & "<taskCompletable>" & taskCompletable & "</taskCompletable>"
	


	'===============================================================================
	case "updateList" 
	'===============================================================================
	
		id 			= request.querystring("id")
		completed 	= request.querystring("completed")
		
		SQL = "update taskChecklistItems " &_
					"set completed = " & completed & " " &_
				"where checklistID = " & id & " "
		
' 		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing
		
		SQL = "update taskChecklists " &_
					"set completed = " & completed & " " &_
				"where id = " & id & " "
		
' 		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing
		
		msg = "Checklist updated"
				
		xml = xml & "<id>" & id & "</id>"		
		xml = xml & "<cmd>Checklist</cmd>"		
		xml = xml & "<completed>" & completed & "</completed>"				
	
	
		SQL = "select count(i.completed) + count(c.completed) totalItems " &_
				"from tasks t " &_
				"join taskChecklists c on (c.taskID = t.id) " &_
				"join taskChecklistItems i on (i.checklistID = c.id) " &_
				"where t.id =  " &_
					"( " &_
					"select t.id " &_
					"from tasks t " &_
					"join taskChecklists c on (c.taskID = t.id) " &_
					"where c.id = " & id & " " &_
					") " &_
				"and (i.completed = 0 or i.completed is null) " &_
				"and (c.completed = 0 or c.completed is null) " 
		
' 		dbug(SQL)
		
		set rsC = dataconn.execute(SQL) 
		if rsC("totalItems") > 0 then 
			taskCompletable = "false" 
		else 
			taskCompletable = "true"
		end if

		rsC.close 
		set rsC = nothing 
		
		xml = xml & "<taskCompletable>" & taskCompletable & "</taskCompletable>"
	
		
	
	'===============================================================================
	case "updatedChecklistName"	
	'===============================================================================
	
' 		dbug("updatedChecklistName detected")
		
		id = request.querystring("id")
		name = request.querystring("name")

		name = replace(name, "'", "&#39;")
		name = replace(name, """", "&quot;")
		
		SQL = "update taskChecklists set " &_
					"name = '" & name & "' " &_
				"where id = " & id & " " 
				
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing
		
		msg = "Checklist updated"
				
		xml = xml & "<id>" & id & "</id>"		
		xml = xml & "<name>" & name & "</name>"		
	
	
	'===============================================================================
	case "updateChecklistItemName"	
	'===============================================================================
	
' 		dbug("updateChecklistItemName detected")
		
		id = request.querystring("id")
		name = request.querystring("name")
		
		name = replace(name, "'", "&#39;")
		name = replace(name, """", "&quot;")
		
		SQL = "update taskChecklistItems set " &_
					"description = '" & name & "' " &_
				"where id = " & id & " " 
				
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing
		
		msg = "Checklist Item updated"
				
		xml = xml & "<id>" & id & "</id>"		
		xml = xml & "<name>" & name & "</name>"		
	
	
	'===============================================================================
	case "getAcceptanceCriteria"
	'===============================================================================

		taskID = request.querystring("taskID")
		
		SQL = "select id, acceptanceCriteria " &_
				"from tasks " &_
				"where id = " & taskID & " "
		
' 		dbug(SQL)
		
		set rsAC = dataconn.execute(SQL)
		if not rsAC.eof then 
			acceptanceCriteria = rsAC("acceptanceCriteria")
			msg = "Acceptance criteria found"
		else 
			acceptanceCriteria = ""
			msg = "Acceptance criteria not found"
		end if
		rsAC.close 
		set rsAC = nothing 
		
		xml = xml & "<acceptanceCriteria>" & acceptanceCriteria & "</acceptanceCriteria>"



	'===============================================================================
	case "saveAcceptanceCriteria"
	'===============================================================================

		taskID 				= request("taskID")
		contentString		= escapeApostrophes(request("contentString"))
		contentHTML 		= escapeQuotes(request("contentHTML"))

		
		SQL = "update tasks set " &_
					"acceptanceCriteria = '" & contentString & "' " &_
				"where id = " & taskID & " " 
' 		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = "Acceptance criteria saved" 
				


	'===============================================================================
	case "skipTask" 
	'===============================================================================

		dbug("start of skipTask")
		taskID 					= request("taskID")
		skippedReasonString 	= request("skippedReasonString")
		skippedReasonHTML 	= request("skippedReasonHTML")
		taskStatusID			= 3

		nowDateTime				= now()
		
		completionDate 		= datePart("yyyy",nowDateTime) & "-" &_
									  datePart("m",nowDateTime) & "-" &_
									  datePart("d",nowDateTime) & " "

		updatedDateTime 		= datePart("yyyy",nowDateTime) & "-" &_
									  datePart("m",nowDateTime) & "-" &_
									  datePart("d",nowDateTime) & " " &_
									  datePart("h",nowDateTime) & ":" &_
									  right("00" & datePart("n",nowDateTime),2) & ":" &_
									  right("00" & datePart("s",nowDateTime),2) 

		dbug("... taskID = " & taskID)
		dbug("... skippedReasonString = " & skippedReasonString)
		dbug("... skippedReasonHTML = " & skippedReasonHTML)
		dbug("... taskStatusID = " & taskStatusID)
		dbug("... completionDate = " & completionDate)
		dbug("... updatedDateTime = " & updatedDateTime)

		SQL = "select * from tasks where id = " & taskID & " " 
		dbug(SQL)
		set rsTask = server.createObject("ADODB.Recordset")
		on error resume next 
		with rsTask 
			.open SQL, dataconn, adOpenDynamic, adLockOptimistic, adCmdText
			if not rsTask.eof then 
				dbug("task found; being updated.")
				.fields("completionDate") 	= cStr(completionDate)
				.fields("taskStatusID") 	= taskStatusID 
				.fields("skippedReason") 	= skippedReasonString
				.fields("updatedBy")			= session("userID") 
				.fields("updatedDateTime") = cStr(updatedDateTime) 
				.update 

				If dataconn.Errors.Count > 0 Then
					For each objError in dataconn.Errors
					
						If dataconn.number <> 0 then
							
							dbug("error number: " & objError.Number)
							dbug("error NativeError: " & objError.NativeError)
							dbug("error SQLState: " & objError.SQLState)
							dbug("error Source: " & objError.Source)
							dbug("error Description: " & objError.Description)
							
						End If
					
					Next
					
				end if



				
				msg = "Task skipped"
			else 
				msg = "Task not found; nothing updated"
			end if
			.close 
		end with 
		on error goto 0 

		
		xml = xml & "<completionDate>" & completionDate & "</completionDate>"
		xml = xml & "<taskStatusID>" & taskStatusID & "</taskStatusID>"
		
		dbug("end of skipTask")

	
	'===============================================================================
	case else 
	'===============================================================================

' 		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"


end select 

xml = xml & "<msg>" & msg & "</msg>"

userLog(msg)

dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</taskMaintenance>"

response.write(xml)
%>