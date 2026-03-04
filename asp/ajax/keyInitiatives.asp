<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug("start of keyInitiatives.asp")

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	'!-- ------------------------------------------------------------------ -->
	case "GET"
	'!-- ------------------------------------------------------------------ -->

		dbug("start of GET, dumping request.querystring...")
		for each item in request.querystring
			dbug("request.querystring('" & item & "'): " & request.querystring(item))
		next 
	
		'!-- ------------------------------------------------------------------ -->
		'!-- validate customerID
		'!-- ------------------------------------------------------------------ -->
		customerID 		= request("customerID")
		if isEmpty(customerID) then 
			json = "{""error"":""CustomerID is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		else 
			if not isNumeric(customerID) then 
				json = "{""error"":""CustomerID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
				dbug("customerID validated: " & customerID)
				customerPredicate = "WHERE ki.customerID = " & customerID & " "
			end if
		end if 
		
		'!-- ------------------------------------------------------------------ -->
		'!-- validate projectID
		'!-- ------------------------------------------------------------------ -->
		projectID = request("projectID") 
		if len(projectID) <= 0 then 
			dbug("Project NOT present in request")
			projectProjection = ", null AS projectID "
			projectJoin = ""
		else 
			dbug("Project IS present in request")
			if not isNumeric(projectID) then 
				json = "{""error"":""Project ID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
		
				SQL = "select id, startDate, endDate " &_
						"from projects " &_
						"where id = " & projectID & " " &_
						"and customerID = " & customerID & " "
		
				set rsProj = dataconn.execute(SQL) 
				if not rsProj.eof then 
					projectStartDate = rsProj("startDate")
					projectEndDate = rsProj("endDate") 
					dbug("project validated: " & projectID) 
		
					projectProjection = ", p.id AS projectID "
					projectJoin = "left JOIN keyInitiativeProjects kip ON ( kip.keyInitiativeID = ki.id AND kip.projectID = " & projectID & ") " &_
									  "left join projects p on ( p.id = kip.projectID AND ki.customerID = " & customerID & ") "
		
				else 
					json = "{""error"":""Key Initiative ID is not found""}"
					response.status = "400 Bad Request"
					response.write json
					response.end()
				end if 
				rsProj.close 
				set rsProj = nothing 
					
			end if 
		end if 
		
		
		'!-- ------------------------------------------------------------------ -->
		'!-- validate taskID
		'!-- ------------------------------------------------------------------ -->
		taskID = request("taskID") 
		if len(taskID) <= 0 then 
			taskProjection = ", null AS taskID "
			taskJoin = ""
		else 
			if not isNumeric(taskID) then 
				json = "{""error"":""taskID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
		
				SQL = "select id, startDate, dueDate " &_
						"from tasks " &_
						"where id = " & taskID & " " &_
						"and customerID = " & customerID & " "
		
				set rsTask = dataconn.execute(SQL) 
				if not rsTask.eof then 
					taskStartDate = rsTask("startDate")
					taskDueDate = rsTask("dueDate") 
					dbug("taskID validated: " & taskID) 
		
					taskProjection = ", t.id AS taskID "
					taskJoin = 	"left JOIN keyInitiativeTasks kit ON ( kit.keyInitiativeID = ki.id and kit.taskID = " & taskID & ") " &_
									"left join tasks t on ( t.id = kit.taskID AND ki.customerID = " & customerID & ") "
		
				else 
					json = "{""error"":""taskID is not found""}"
					response.status = "400 Bad Request"
					response.write json
					response.end()
				end if 
				rsTask.close 
				set rsTask = nothing 
					
			end if 
		end if 
		
		
			
		json = "{"
			
		'	
		'!-- ------------------------------------------------------------------ -->
		'!-- get all keyInitiatives for the customer...
		'!-- ------------------------------------------------------------------ -->
		
		SQL = "SELECT " &_
					"ki.id, " &_
					"ki.name, " &_
					"ki.description, " &_
					"format ( ki.startDate, 'M/d/yyyy' ) AS startDate, " &_
					"format ( ki.endDate, 'M/d/yyyy' ) AS dueDate, " &_
					"format ( ki.completeDate, 'M/d/yyyy' ) AS completeDate " &_
					projectProjection &_
					taskProjection &_
				"FROM keyInitiatives ki " &_
				projectJoin &_
				taskJoin &_
				customerPredicate 
		
		dbug(SQL)
		set rsKI = dataconn.execute(SQL) 
		
			
		json = json & """data"": ["
		while not rsKI.eof 
		
		
			' determine if the KI is "completable"...
			
			if ( not isNull(rsKI("completeDate")) ) then 
				kiCompletable = false 
				dbug(rsKI("id") & " - already complete")
			else 
				
				SQL = "select count(*) as countOfIncompleteTasks " &_
						"from tasks t " &_
						"join keyInitiativeTasks kit on (kit.taskID = t.id and kit.keyInitiativeID = " & rsKI("id") & ") " &_ 
						"where t.completionDate is null " &_
						"and (t.deleted = 0 or t.deleted is null) "
						
				set rsTasks = dataconn.execute(SQL) 
				if not rsTasks.eof then 
					countOfIncompleteTasks = rsTasks("countOfIncompleteTasks") 
				else 
					countOfIncompleteTasks = 0 
				end if 
				rsTasks.close 
				set rsTasks = nothing 
		
				dbug(rsKI("id") & " - countOfIncompleteTasks: " & countOfIncompleteTasks)
		
				SQL = "select count(*) as countOfIncompleteProjects " &_
						"from ( " &_
							"select " &_
								"p.id, " &_
								"(select top 1 type " &_
								" from projectStatus ps " &_
								" where ps.projectID = p.id " &_
								" order by updatedDateTime desc " &_
								") as [Project Status] " &_
							"from projects p " &_
							"join keyInitiativeProjects kip on (kip.projectID = p.id and kip.keyInitiativeID = " & rsKI("id") & ") " &_
							"where (p.deleted = 0 or p.deleted is null) " &_ 
						") as x " &_
						"where ([Project Status] <> 'Complete' or [Project Status] is null) "
				
				set rsProj = dataconn.execute(SQL) 
				if not rsProj.eof then 
					countOfIncompleteProjects = rsProj("countOfIncompleteProjects")
				else 
					countOfIncompleteProjects = 0 
				end if 
				rsProj.close 
				set rsProj = nothing 
				
				dbug(rsKI("id") & " - countOfIncompleteProjects: " & countOfIncompleteProjects)
		
				if ( countOfIncompleteTasks > 0 ) then 
					kiCompletable = false 
				else 
					if ( countOfIncompleteProjects > 0 ) then 
						kiCompletable = false 
					else 
						kiCompletable = true 
					end if 
				end if 
				
				dbug(rsKI("id") & " - kiCompletable: " & kiCompletable)
				
			end if 
		
			if userPermitted(45) then 
				dbug("userPermitted(45) is true")
				if ( isNull(rsKI("completeDate") ) ) then 
					kiUncompletable = false 
					dbug(rsKI("id") & " - already unComplete")
				else 
					kiUncompletable = true 
				end if 
			else 
				dbug("userPermitted(45) is false")
				kiUncompletable = false 
			end if
			
			dbug(rsKI("id") & " - kiUncompletable: " & kiUncompletable) 
			
			
			
			
		
			' determine the KIs relatability to the project....
			
			if not isNull(rsKI("projectID")) then 
				relatability = "linked"
			else 
				
				if len(projectJoin) > 0 then 		
				
					if ( not isNull(rsKI("startDate")) AND not isNull(projectStartDate) ) then 
						if ( isDate(rsKI("startDate")) AND isDate(projectStartDate) ) then 
							if cDate(rsKI("startDate")) < cDate(projectStartDate) then  
								relatabilityInfo = "project starts before the KI"
								relatability = "false"
							else 
								if ( not isNull(rsKI("dueDate")) AND not isNull(projectEndDate) ) then 
									if ( isDate(rsKI("dueDate")) AND isDate(projectEndDate) ) then 
										if cDate(rsKI("dueDate")) > cDate(projectEndDate) then 
											relatabilityInfo = "project ends after the KI"
											relatability = "false" 
										else 
											relatability = "true" 
										end if 
									else 
										relatabilityInfo = "project dueDate or KI endDate is not a date"
										relatability = "false"
									end if 
								else 
									relatabilityInfo = "project dueDate or KI endDate is null"
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
					
					relatabilityInfo = "project not present, can't determine relatability"
					relatability = ""
					
				end if
		
			end if
			
			' determine the KI's relatabiity to the task...
			if ( not isNull(rsKI("taskID")) ) then 
				taskRelationship = "linked" 
			else 
				if ( len(taskJoin) > 0 ) then 
					if ( not isNull(rsKI("startDate")) and not isNull(taskStartDate) ) then 
						if ( isDate(rsKI("startDate")) and isDate(taskStartDate) ) then 
							if ( cDate(rsKI("startDate")) <= cDate(taskStartDate) ) then 
								if ( isDate(rsKI("dueDate")) and isDate(taskDueDate) ) then 
									if ( cDate(rsKI("dueDate")) >= cDate(taskDueDate) ) then 
										taskRelationship = "possible"
									else 
										taskRelationship = "Key initiative ends before task is due"
									end if
								else 
									taskRelationship = "Key initiative end date or task due date is not a date" 
								end if 
							else 
								taskRelationship = "Key initiative starts after task"
							end if 
						else 
							taskRelationship = "Key initiative or task start date is not a date" 
						end if 
					else 
						taskRelationship = "Key initiative or task start date is null"
					end if 
				else 
					taskRelationship = "Task not present, can't determine relatability"
				end if
			end if 
			
			
			
			
			kiName 			= replace( rsKI("name"), """", "&quot;")			
			kiDescription 	= replace( rsKI("description"), """", "&quot;" )
			kiDescription	= replace( kiDescription, vbCrLf, "<br><br>" )
			kiDescription	= replace( kiDescription, vbLf, "<br>" )
			kiDescription	= replace( kiDescription, vbTab, "" )
			
		
		
			json = json & "{"
			json = json & """DT_RowId"":""" & rsKI("id") & ""","
			json = json & """kiName"":""" & kiName & ""","
			json = json & """description"":""" & kiDescription & ""","
			json = json & """startDate"":""" & rsKI("startDate") & ""","
			json = json & """dueDate"":""" & rsKI("dueDate") & ""","
			json = json & """completeDate"":""" & rsKI("completeDate") & ""","
			json = json & """relatability"":""" & relatability & ""","
			json = json & """relatabilityInfo"":""" & relatabilityInfo & ""","
			json = json & """taskRelationship"":""" & taskRelationship & ""","
			json = json & """kiCompletable"":""" & kiCompletable & ""","
			json = json & """kiUncompletable"":""" & kiUncompletable & ""","
			json = json & """customerID"":""" & customerID & """"
			json = json & "}"
		
			rsKI.movenext 
		
			if not rsKI.eof then json = json & "," end if
		
		wend 
		
		json = json & "]"	
		
		
		rsKI.close 
		set rsKI = nothing 
		
		json = json & "}"

		responseStatus = "200 OK"		


	'!-- ------------------------------------------------------------------ -->
	case "POST" 
	'!-- ------------------------------------------------------------------ -->
	
		id  				= request("id")
		customerID		= request("customerID")
		name				= request("name")
		description		= request("description")
		startDate		= request("startDate") 
		endDate			= request("endDate") 
		
		if len(request("completeDate")) > 0 then 
			completeDate	= "'" & request("completeDate") & "'"
		else 
			completeDate = "NULL" 
		end if 
		
		name 			= replace( name, "&quote;", "\u2122" )
		name 			= replace( name, "(tm)", "\u2122" )
		name 			= replace( name, "â„¢", "\u2122" )
		name			= replace ( name, "'", "''" )

		description = replace( description, "&quote;", "\u2122" )
		description = replace( description, "(tm)", "\u2122" )
		description = replace( description, "â„¢", "\u2122" )
		description = replace( description, "'", "''" )
		
		if len(id) > 0 then 
			
			SQL = "update keyInitiatives set " &_
						"name 				= '" & name 					& "', " &_
						"description 		= '" & description 			& "', " &_
						"startDate 			= '" & startDate 				& "', " &_
						"endDate 			= '" & endDate 				& "', " &_
						"completeDate 		= "  & completeDate 			& ", " &_
						"updatedBy 			= "  & session("userID") 	& ", " &_
						"updatedDateTime 	= CURRENT_TIMESTAMP " 		&_
					"where id 			= " & id 			& " " &_
					"and customerID 	= " & customerID 	& " " 
					
			msg = "Key Initiative updated"
					
		else 
			
			id = getNextID("keyInitiatives")
			
			SQL = "insert into keyInitiatives (id, customerID, name, description, startDate, endDate, completeDate, updatedBy, updatedDateTime) " &_
					"values ( " &_
						id & ", " &_
						customerID & ", " &_
						"'" & name & "', " &_
						"'" & description & "', " &_
						"'" & startDate & "', " &_
						"'" & endDate & "', " &_
						completeDate & ", " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP " &_
					") "

			msg = "Key Initiative added"
					
		end if 
		
		dbug("POST SQL: " & SQL)
		
		set rsPOST = dataconn.execute(SQL) 
		set rsPOST = nothing 

		json = "{""msg"": """ & msg & """}"

		responseStatus = "200 OK"
		
	
	
	'!-- ------------------------------------------------------------------ -->
	case "DELETE" 
	'!-- ------------------------------------------------------------------ -->
	
		id  				= request("id")
		customerID		= request("customerID")
		
		' delete any associated projects...
		SQL = "delete from keyInitiativeProjects " &_
				"where keyInitiativeID = " & id & " " 
				
		dbug(SQL)
		set rsDELETE = dataconn.execute(SQL) 
		set rsDELETE = nothing 

		
		' delete any associated tasks...
		SQL = "delete from keyInitiativeTasks " &_
				"where keyInitiativeID = " & id & " " 
				
		dbug(SQL)
		set rsDELETE = dataconn.execute(SQL) 
		set rsDELETE = nothing 

		
		' finally, delete the Key Initiative...
		SQL = "delete from keyInitiatives " &_
				"where id = " & id &_
				"and customerID = " & customerID & " " 
				
		dbug(SQL)
		set rsDELETE = dataconn.execute(SQL) 
		set rsDELETE = nothing 

		json = "{""msg"": ""Key Initiative deleted""}"

		responseStatus = "200 OK"


	'!-- ------------------------------------------------------------------ -->
	case else 
	'!-- ------------------------------------------------------------------ -->
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (405)"
				
				
end select 


dbug(json)

response.status = responseStatus
response.write json 

%>			

		
	


