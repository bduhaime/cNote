
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<!-- #include file="../includes/workDaysAdd.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug("start of projects.asp")

currProjectID = request("currProjectID")
dbug("currProjectID: " & currProjectID)


dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	'!-- ------------------------------------------------------------------ -->
	case "GET"
	'!-- ------------------------------------------------------------------ -->

	
		'!-- ------------------------------------------------------------------ -->
		'!-- validate customerID
		'!-- ------------------------------------------------------------------ -->
		dbug("request('customerID'): " & request("customerID"))
		customerID 		= request("customerID")
		if isEmpty(customerID) then 
' 			json = "{""error"":""CustomerID is not present""}"
' 			response.status = "400 Bad Request"
' 			response.write json
' 			response.end()
			dbug("customerID is empty")
			customerPredicate = ""
		else 
			if not isNumeric(customerID) then 
				dbug("customerID is not numeric")
				json = "{""error"":""CustomerID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
				dbug("customerID validated: " & customerID)
				customerPredicate = "AND p.customerID = " & customerID & " "
			end if
		end if 
		
		'!-- ------------------------------------------------------------------ -->
		'!-- validate keyInitiativeID
		'!-- ------------------------------------------------------------------ -->
		dbug("request('ki'): " & request("ki"))
		keyInitiativeID = request("ki")
		if len(keyInitiativeID) <= 0 then 
			kiProjection = ", null as kiID "
			kiJoin = ""
		else 
			if not isNumeric(keyInitiativeID) then 
				json = "{""error"":""Key Initiative ID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
				
				SQL = "select id, startDate, endDate " &_
						"from keyInitiatives " &_
						"where id = " & keyInitiativeID & " " &_
						"and customerID = " & customerID & " "
						
				set rsKI = dataconn.execute(SQL) 
				if not rsKI.eof then 
					kiStartDate = rsKI("startDate")
					kiEndDate = rsKI("endDate") 
					dbug("keyInitiativeID validated: " & keyInitiativeID) 
					kiProjection = ", ki.id as kiID "
					kiJoin = "left JOIN keyInitiativeProjects kip ON ( kip.projectID = p.id AND kip.keyInitiativeID = " & keyInitiativeID & ") " &_
								"left join keyInitiatives ki on ( ki.id = kip.keyInitiativeID AND ki.customerID = " & customerID & ") "
					
				else 
					json = "{""error"":""Key Initiative ID is not found""}"
					response.status = "400 Bad Request"
					response.write json
					response.end()
				end if 
				rsKI.close 
				set rsKI = nothing 
					
			end if 
		end if 
			
		'!-- ------------------------------------------------------------------ -->
		'!-- validate taskID
		'!-- ------------------------------------------------------------------ -->
		dbug("request('taskID'): " & request("taskID"))
		taskID = request("taskID")
		if len(taskID) <= 0 then 
			taskProjection = ", null as taskID "
			taskJoin			= ""
		else 
			
			if not isNumeric(taskID) then 
				json = "{""error"":""Task ID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
		
				taskProjection = ", t.id as taskID " 
				taskJoin = "left join tasks t on (t.projectID = p.id and t.id = " & taskID & ") "
							
			end if 
			
		end if 
			
		
		
		json = "{"
			
		'	
		'!-- ------------------------------------------------------------------ -->
		'!-- get all projects for the customer, link any associated KIs...
		'!-- ------------------------------------------------------------------ -->
		
		SQL = "SELECT " &_
					"p.id, " &_
					"p.name, " &_
					"prod.name as productName, " &_
					"format ( p.startDate, 'M/d/yyyy' ) AS startDate, " &_
					"format ( p.endDate, 'M/d/yyyy' ) AS endDate, " &_
					"format ( p.completeDate, 'M/d/yyyy' ) AS completeDate, " &_
					"p.projectManagerID, " &_
					"p.generatedFrom, " &_
					"pt.name as generatedFromTemplateName, " &_
					"concat ( gu.firstName, ' ', gu.lastName ) AS generatedBy, " &_
					"p.generatedDateTime, " &_
					"concat(u.firstName, ' ', u.lastName) as projectManagerName, " &_
					"cu.clientID, " &_
					"uc.customerID, " &_
					"c.name as customerName " &_
					kiProjection &_
					taskProjection &_
				"FROM projects p " &_
				"left join products prod on (prod.id = p.productID) " &_
				kiJoin &_
				taskJoin &_
				"left join csuite..users u on (u.id = p.projectManagerID) " &_
				"left join csuite..clientUsers cu on (cu.userID = u.id and cu.clientID = " & session("clientNbr") & ") " &_
				"LEFT JOIN csuite..users gu on (gu.id = p.generatedBY) " &_
				"left join userCustomers uc on (uc.userID = u.id and uc.customerID = 1) " &_
				"LEFT JOIN projectTemplates pt on (pt.id = p.generatedFromTemplateID) " &_
				"LEFT JOIN customer c on (c.id = p.customerID) " &_
				"WHERE ( p.deleted = 0 OR p.deleted IS NULL ) " &_
				customerPredicate 
		
		dbug("GET projects: " & SQL)
		set rsProj = dataconn.execute(SQL) 
		
			
		json = json & """data"": ["
		while not rsProj.eof 
		
			' get the project's status
			SQL = "select top 1 " &_
						"type, " &_
						"format(updatedDateTime, 'M/d/yyyy') as statusDate " &_
					"from projectStatus " &_
					"where projectID = " & rsProj("id") & " " &_
					"order by updatedDateTime desc "
		
			set rsPS = dataconn.execute(SQL) 
		
			if not rsPS.eof then 
				projectStatusDate = formatDateTime(rsPS("statusDate"),2)
				projectStatusType = rsPS("type") 
			else 
				projectStatusDate = ""
				projectStatusType = ""
			end if
			
			rsPS.close 
			set rsPS = nothing 
		
			' determine the project's relatability to the KI....
			if not isNull(rsProj("kiID")) then 
				relatability = "linked"
			else 
				
				if len(kiJoin) > 0 then 		
				
					if ( not isNull(rsProj("startDate")) AND not isNull(kiStartDate) ) then 
						if ( isDate(rsProj("startDate")) AND isDate(kiStartDate) ) then 
							if cDate(rsProj("startDate")) < cDate(kiStartDate) then  
								relatabilityInfo = "project starts before the KI"
								relatability = "false"
							else 
								if ( not isNull(rsProj("endDate")) AND not isNull(kiEndDate) ) then 
									if ( isDate(rsProj("endDate")) AND isDate(kiEndDate) ) then 
										if cDate(rsProj("endDate")) > cDate(kiEndDate) then 
											relatabilityInfo = "project ends after the KI"
											relatability = "false" 
										else 
											relatability = "true" 
										end if 
									else 
										relatabilityInfo = "project endDate or KI endDate is not a date"
										relatability = "false"
									end if 
								else 
									relatabilityInfo = "project endDate or KI endDate is null"
									relatability = "false" 
								end if
							end if 
						else 
							relatabilityInfo = "project startDate or KI startDate is not a date"
							relatability = "false" 
						end if 
					else 
						relatabilityInfo = "project startDate or KI startDate is null"
						relatability = "false" 
					end if
		
				else 
					
					relatabilityInfo = "ki not present, can't determine relatability"
					relatability = ""
					
				end if
		
			end if
			
			' determine number of KIs associated with the project...
			SQL = "select count(*) as kiCount from keyInitiativeProjects where projectID = " & rsProj("id") & " "
			dbug(SQL)
			set rsCount = dataconn.execute(SQL)
			if cInt(rsCount("kiCount")) > 0 then 
				kiCount = cInt(rsCount("kiCount"))
			else 
				kiCount = ""
			end if
			rsCount.close 
			set rsCount = nothing 
			
			' get project manager info...
			if not isNull(rsProj("projectManagerID")) then 
				' validate the project manager's user account status....
				if isNull(rsProj("projectManagerName")) then 
					pmName = ""
					warning = true
					message = "Could not find a user account for the project manager"
				else 
					pmName = rsProj("projectManagerName")
					if isNull(rsProj("clientID")) then  
						warning = true 
						message = "Project manager's user account is not associated with the current client"
					else 
						if isNull(rsProj("customerID")) then 
							warning = true
							message = "Project manager's user account is not an internal user" 
						else 
							warning = false
							message = ""
						end if
					end if
				end if 
				
			else 
				pmName = ""
				warning = true 
				message = "No project manager assigned" 
			end if			
			
			
			' determine if the project is completeable...
			SQL = "select count(*) as incompleteTasks " &_
					"from tasks t " &_
					"where t.projectID = " & rsProj("id") & " " &_
					"and (deleted = 0 or deleted is null) " 
					
			set rsTasks = dataconn.execute(SQL) 
			if not rsTasks.eof then 
				countOfIncompleteTasks = rsTasks("incompleteTasks") 
			else 
				countOfIncompleteTasks = 0
			end if 
			rsTasks.close 
			set rsTasks = nothing 
			
			if projectStatusType <> "Complete" then 
				if countOfIncompleteTasks > 0 then 
					projectCompletable = false  
				else 
					projectCompletable = true 
				end if 
				projectUncompletalbe = false
			else 
				if userPermitted(45) then 
					projectUncompletable = true
				else 
					projectUncompletable = false 
				end if 
			end if
			
		
' 			projectName = replace(rsProj("name"), """", "&quot;")			
			If isNull( rsProj( "name" ) ) Then
			   projectName = ""
			Else
				projectName = "" & Replace( rsProj("name"), """", "\""" )
			End If
			
			
			dbug("generating JSON for project: " & projectName)
		
			json = json & "{"
			json = json & """DT_RowId"":""" & rsProj("id") & ""","
			json = json & """customerID"":""" & customerID & ""","
			json = json & """customerName"":""" & rsProj("customerName") & ""","
			json = json & """projectName"":""" & projectName & ""","
			json = json & """productName"":""" & productName & ""","
			json = json & """startDate"":""" & rsProj("startDate") & ""","
			json = json & """endDate"":""" & rsProj("endDate") & ""","
			json = json & """projectManagerID"":""" & rsProj("projectManagerID") & ""","
			json = json & """projectManagerName"":""" & pmName & ""","
			json = json & """projectManagerInfo"":""" & message & ""","

			json = json & """generatedFrom"":""" & rsProj("generatedFrom") & ""","
			json = json & """generatedFromTemplateName"":""" & rsProj("generatedFromTemplateName") & ""","
			json = json & """generatedBy"":""" & rsProj("generatedBy") & ""","
			json = json & """generatedDateTime"":""" & rsProj("generatedDateTime") & ""","
			
			
			json = json & """statusDate"":""" & projectStatusDate & ""","
			json = json & """status"":""" & projectStatusType & ""","
			json = json & """relatability"":""" & relatability & ""","
			json = json & """relatabilityInfo"":""" & relatabilityInfo & ""","
			json = json & """kiCount"":""" & kiCount & ""","
			json = json & """projectCompletable"":""" & projectCompletable & ""","
			json = json & """projectUncompletable"":""" & projectUncompletable & ""","
			json = json & """taskID"":""" & rsProj("taskID") & """"
			json = json & "}"
		
			rsProj.movenext 
		
			if not rsProj.eof then json = json & "," end if
		
		wend 
		
		dbug("after completion of main processing loop")
		
		json = json & "]"	

		rsProj.close 
		set rsProj = nothing 

		json = json & "}"
		
		dbug("end of GET processing")



	'!-- ------------------------------------------------------------------ -->
	case "POST" 
	'!-- ------------------------------------------------------------------ -->

		'!-- get the input parameters...
		cmd					= request("cmd") 
		id						= request("id")
		customerID			= request("customerID")
		name					= request("name") 
		projectTemplateID	= request("product") 
		
		dbug(" ")
		dbug("parameters...")
		dbug("projectTemplateID: " & projectTemplateID)
		dbug("customerID: " & customerID)

		if len(request("projectManager")) > 0 then 
			projectManager		= request("projectManager")
		else 
			projectManager		= "NULL"
		end if
		

		startDate			= request("startDate")
		endDate				= request("endDate")

		if len(request("projectManager")) > 0 then 
			projectManager		= request("projectManager")
		else 
			projectManager		= "NULL"
		end if
		
		anchorDateType		= request("anchorDateType")
		anchorDate			= request("anchorDate")
		
		 		
		'!-- process the request...
		
		select case cmd 
		
			case "scratch"
		
				if len(id) > 0 then 
					
					dbug("going to update a project...")
					
					SQL = "update projects set " &_
								"name = '" & name & "', " &_
								"projectManagerID = " & projectManager & ", " &_
								"startDate = '" & startDate & "', " &_
								"endDate = '" & endDate & "', " &_
								"updatedBy = " & session("userID") & ", " &_
								"updatedDateTime = CURRENT_TIMESTAMP " &_
							"where id = " & id & " " &_
							"and customerID = " & customerID & " " 
							
					dbug("UPDATE: " & SQL)
							
					msg = "Project updated"

				else 
					
					dbug("going to add a project...")
					
					generatedFrom = "'scratch'"
					generatedFromTemplateID = "null"		
					
					id = getNextID("projects")
					
					SQL = "insert into projects (id, name, customerID, startDate, endDate, updatedBy, updatedDateTime, projectManagerID, generatedFrom, generatedFromTemplateID, generatedBy, generatedDateTime) " &_
							"values ( " &_
								id & ", " &_
								"'" & name & "', " &_
								customerID & ", " &_
								"'" & startDate & "', " &_
								"'" & endDate & "', " &_
								session("userID") & ", " &_
								"CURRENT_TIMESTAMP, " &_
								projectManager & ", " &_
								generatedFrom & ", " &_
								generatedFromTemplateID & ", " &_
								session("userID") & ", " &_
								"CURRENT_TIMESTAMP " &_
								 ") " 
								
					dbug("INSERT: " & SQL)
								
					msg = "Project added"
		
				end if 
				
				dbug("POST SQL: " & SQL)
				
				set rsPOST = dataconn.execute(SQL) 
				set rsPOST = nothing 
		
				dbug("End of 'scratch' processing")
		
				json = "{""msg"": """ & msg & """}"
				responseStatus = "200 OK"
				

			case "template" 
				
				newProjectID = getNextID("projects")
		
				SQL = "select top 1 startOffsetDays + taskDurationDays + endOffsetDays as projectDurationDays " &_
						"from projectTemplateTasks " &_
						"where projectTemplateID = " & projectTemplateID & " " 
						
				dbug(SQL)
				set rsPT = dataconn.execute(SQL)
				if not rsPT.eof then 
					projectDurationDays = rsPT("projectDurationDays")
				else 
					dbug("Error: could not determine project duration")
					responseStatus = "405 Method Not Allowed"
					response.end()
				end if
				rsPT.close 
				set rsPT = nothing
				dbug("projectDurationDays: " & projectDurationDays)
				
				dbug("anchorDateType: " & anchorDateType)
				if lCase(anchorDateType) = "start" then 
					startDate 	= anchorDate
					endDate   	= workDaysAdd(startDate, cInt(projectDurationDays))
				else 
					endDate 		= anchorDate
					dbug("endDate: " & endDate)
					dbug("projectDurationDays: " & projectDurationDays)
					startDate	= workDaysAdd(endDate, -cInt(projectDurationDays))	
				end if

				generatedFrom 				= "'template'"
				generatedFromTemplateID = projectTemplateID
						
				
				SQL = "insert into projects (id, name, customerID, startDate, endDate, updatedBy, updatedDateTime, projectManagerID, generatedFrom, generatedFromTemplateID, generatedBy, generatedDateTime) " &_
						"values ( " &_
							newProjectID & ", " &_
							"'" & name & "', " &_
							customerID & ", " &_
							"'" & startDate & "', " &_
							"'" & endDate & "', " &_
							session("userID") & ", " &_
							"CURRENT_TIMESTAMP, " &_
							projectManager & ", " &_
							generatedFrom & ", " &_
							generatedFromTemplateID & ", " &_
							session("userID") & ", " &_
							"CURRENT_TIMESTAMP " &_
							 ") "
		
				dbug(SQL)					
				set rsInsert = dataconn.execute(SQL)
				set rsInsert = nothing 

				
				SQL = "select * from projectTemplateTasks where projectTemplateID = " & projectTemplateID & " " 
				dbug(SQL)
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
		
		
					dbug(SQL)
					set rsInsert = dataconn.execute(SQL)
					set rsInsert  = nothing 
								
						
					SQL = "select * from projectTemplateTaskChecklists where projectTemplateTaskID = " & rsTasks("id") & " " 
					dbug(SQL)
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
						
						dbug(SQL)
						set rsInsert = dataconn.execute(SQL)
						set rsInsert = nothing 
									
						
						SQL = "select * from projectTemplateTaskChecklistItems where projectTemplateTaskChecklistID = " & rsChecklists("id") & " " 
						dbug(SQL)
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
										
							dbug(SQL)
							set rsInsert = dataconn.execute(SQL)
							set rsInsert = nothing 
							
							rsItems.movenext 
							
						wend 
						
						rsItems.close 
						set rsItems = nothing 

						rsChecklists.movenext 
						
					wend 
		
					rsChecklists.close 
					set rsChecklists = nothing 

					rsTasks.movenext 
		
				wend 
		
				rsTasks.close 
				set rsTasks = nothing 					

				
				dbug("End of 'template' processing")
		
				json = "{""msg"": ""Project added from template""}"
				responseStatus = "200 OK"
				
				
			case else 
			
				dbug("400 Bad Request - unexpected cmd, " & cmd & ", encountered")
				msg = "Unexpected directive encountered in taskMaintenance.asp"
			
				json = "{""msg"": ""400 Bad Request""}"
				responseStatus = "400 Bad Request"

			
		end select 
		
		dbug("End of POST processing")
	
	
	'!-- ------------------------------------------------------------------ -->
	case "DELETE" 
	'!-- ------------------------------------------------------------------ -->
	
		id  				= request("id")
		customerID		= request("customerID")
		
		SQL = "select id from tasks where projectID = " & id & " " 
		dbug("get all tasks SQL: " & SQL)
		set rsTasks = dataconn.execute(SQL)
		while not rsTasks.eof 
		
			SQL = "select id from taskChecklists where taskID = " & rsTasks("id") & " " 
			dbug("get taskChecklists SQL: " & SQL)
			set rsTaskChecklists = dataconn.execute(SQL)
			while not rsTaskChecklists.eof 
			
				SQL = "delete from taskChecklistItems where checklistID = " & rsTaskChecklists("id") & " " 
				dbug("delete taskChecklistItems SQL: " & SQL)
				
				set rsDelete1 = dataconn.execute(SQL)
				set rsDelete1 = nothing 
				rsTaskChecklists.movenext 
								
			wend 
			rsTaskChecklists.close 
			set rsTaskChecklists = nothing 
			
			SQL = "delete from taskChecklists where taskID = " & rsTasks("id") & " " 
			dbug("delete taskChecklists SQL: " & SQL)

			set rsDelete2 = dataconn.execute(SQL)
			set rsDelete2 = nothing  
			rsTasks.movenext 
			
		wend 
		rsTasks.close 
		set rsTasks = nothing 
		
		SQL = "delete from tasks where projectID = " & id & " " 
		dbug("delete tasks SQL: " & SQL)

		set rsDelete3 = dataconn.execute(SQL)
		set rsDelete3 = nothing 
		
		SQL = "delete from keyInitiativeProjects where projectID = " & id & " " 
		dbug("delete kiProjects SQL: " & SQL)
		
		set rsDelete3a = dataconn.execute(SQL)
		set rsDelete3a = nothing
		
		SQL = "delete from projects where id = " & id & " " 
		dbug("delete project SQL " & SQL)

		set rsDelete4 = dataconn.execute(SQL)
		set rsDelete4 = nothing 
		
		json = "{""msg"": ""Project deleted""}"

		responseStatus = "200 OK"


	'!-- ------------------------------------------------------------------ -->
	case else 
	'!-- ------------------------------------------------------------------ -->
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (405)"
				
				
end select 


dbug("Projects: " & json)

response.status = "200 Okay"
response.write json 

%>			

		
	


