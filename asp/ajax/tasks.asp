
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug("start of tasks.asp")

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	'!-- ------------------------------------------------------------------ -->
	case "GET"
	'!-- ------------------------------------------------------------------ -->


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
				customerPredicate = "where t.customerID = "& customerID & " "
			end if
		end if 
		
		'!-- ------------------------------------------------------------------ -->
		'!-- validate keyInitiativeID
		'!-- ------------------------------------------------------------------ -->
		keyInitiativeID = request("ki")
		if len(keyInitiativeID) <= 0 then 
			kiProjection = "null AS kiID "
			kiJoin = ""
		else 
			if not isNumeric(keyInitiativeID) then 
				json = "{""error"":""Key Initiative ID is not valid""}"
				dbug("error: Key Initiative ID is not valie")
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
				
				SQL = "select id, startDate, endDate " &_
						"from keyInitiatives " &_
						"where id = " & keyInitiativeID & " " &_
						"and customerID = " & customerID & " "
				dbug(SQL)
				set rsKI = dataconn.execute(SQL) 
				if not rsKI.eof then 
					kiStartDate = rsKI("startDate")
					kiEndDate = rsKI("endDate") 
					dbug("keyInitiativeID validated: " & keyInitiativeID) 
		
					kiProjection = "ki.id AS kiID "
					kiJoin = "left JOIN keyInitiativeTasks kip ON ( kip.taskID = t.id AND kip.keyInitiativeID = " & keyInitiativeID & ") " &_
								"left join keyInitiatives ki on ( ki.id = kip.keyInitiativeID AND ki.customerID = " & customerID & ") "
		
				else 
					json = "{""error"":""Key Initiative ID is not found""}"
					dbug("error: Key Initiative ID is not found")
					response.status = "400 Bad Request"
					response.write json
					response.end()
				end if 
				rsKI.close 
				set rsKI = nothing 
					
			end if 
		end if 
		
		'!-- ------------------------------------------------------------------ -->
		'!-- validate projectID
		'!-- ------------------------------------------------------------------ -->
		projectID = request("projectID") 
		if len(projectID) <= 0 then 
			projectPredicate = ""
		else 
			if not isNumeric(projectID) then 
				json = "{""error"":""Project ID is not valid""}"
				response.status = "400 Bad Request"
				response.write json
				response.end()
			else 
				projectPredicate = "and t.projectID = " & projectID & " " 
			end if 
		end if 
		
		
			
		json = "{"
			
		SQL = "SELECT " &_
					"t.id, " &_
					"t.name, " &_
					"format ( t.startDate, 'M/d/yyyy' ) AS startDate, " &_
					"format ( t.dueDate, 'M/d/yyyy' ) AS dueDate, " &_
					"format ( t.completionDate, 'M/d/yyyy' ) AS completeDate, " &_
					"t.taskStatusID, " &_
					"ts.name AS taskStatusName, " &_
					"t.estimatedWorkDays, " &_
					"t.actualWorkDays, " &_
					"t.customerCompletedInd, " &_
					"concat ( cc.firstName, ' ', cc.lastName ) AS ownerName, " &_
					"t.projectID, " &_
					kiProjection &_
				"from tasks t " &_
				kiJoin &_
				"LEFT JOIN customerContacts cc ON ( cc.id = t.ownerID ) " &_
				"LEFT JOIN taskStatus ts ON ( ts.id = t.taskStatusID ) " &_
				customerPredicate 
				
		dbug(SQL)
		set rsTask = dataconn.execute(SQL) 
		
		json = json & """data"": ["
		while not rsTask.eof 
		
			if not isNull(rsTask("projectID")) then 
				SQL = "select top 1 type from projectStatus where projectID = " & rsTask("projectID") & " order by updatedDateTime desc " 
				set rsStatus = dataconn.execute(SQL) 
				if not rsStatus.eof then 
					projectStatus = rsStatus("type") 
				else 
					projectStatus = ""
				end if
			else 
				projectStatus = ""
			end if 
		
		
			if not isNull(rsTask("kiID")) then 
				relatability = "linked"
			else 
		
				if ( not isNull(rsTask("startDate")) AND not isNull(kiStartDate) ) then 
					if ( isDate(rsTask("startDate")) AND isDate(kiStartDate) ) then 
						if cDate(rsTask("startDate")) < cDate(kiStartDate) then  
							relatabilityInfo = "task starts before the KI"
							relatability = "false"
						else 
							if ( not isNull(rsTask("dueDate")) AND not isNull(kiEndDate) ) then 
								if ( isDate(rsTask("dueDate")) AND isDate(kiEndDate) ) then 
									if cDate(rsTask("dueDate")) > cDate(kiEndDate) then 
										relatabilityInfo = "task ends after the KI"
										relatability = "false" 
									else 
										relatability = "true" 
									end if 
								else 
									relatabilityInfo = "task dueDate or KI endDate is not a date"
									relatability = "false"
								end if 
							else 
								relatabilityInfo = "task dueDate or KI endDate is null"
								relatability = "false" 
							end if
						end if 
					else 
						relatabilityInfo = "task startDate or KI startDate is not a date"
						relatability = "false" 
					end if 
				else 
					relatabilityInfo = "task startDate or KI startDate is null"
					relatability = "false" 
				end if
		
			end if
			
			
			SQL = "select count(*) as kiCount from keyInitiativeTasks where taskID = " & rsTask("id") & " " 
			dbug(SQL)
			set rsCount = dataconn.execute(SQL) 
			if not rsCount.eof then 
				if cInt(rsCount("kiCount")) > 0 then 
					kiCount = cInt(rsCount("kiCount")) 
					orphan = "false"
				else 
					kiCount = "0"
					if isNull(rsTask("projectID")) then 
						orphan = "true"
					else 
						orphan = "false" 
					end if 
				end if 
			end if 
			rsCount.close 
			set rsCount = nothing 
		
		
			taskName = replace(rsTask("name"), """", "&quote;")
		
			json = json & "{"
			json = json & """DT_RowId"":""" & rsTask("id") & ""","
			json = json & """taskName"":""" & taskName & ""","
			json = json & """startDate"":""" & rsTask("startDate") & ""","
			json = json & """dueDate"":""" & rsTask("dueDate") & ""","
			json = json & """completeDate"":""" & rsTask("completeDate") & ""","
			json = json & """ownerName"":""" & rsTask("ownerName") & ""","
			json = json & """projectID"":""" & rsTask("projectID") & ""","
			json = json & """projectStatus"":""" & projectStatus & ""","
			json = json & """relatability"":""" & relatability & ""","
			json = json & """relatabilityInfo"":""" & relatabilityInfo & ""","
			json = json & """kis"":""" & kiCount & ""","
			json = json & """estWorkDays"":""" & rsTask("estimatedWorkDays") & ""","
			json = json & """actWorkDays"":""" & rsTask("actualWorkDays") & ""","
			json = json & """completedByCustomer"":""" & rsTask("customerCompletedInd") & ""","
			json = json & """orphan"":""" & orphan & """"
			json = json & "}"
		
			rsTask.movenext 
		
			if not rsTask.eof then json = json & "," end if
		
		wend 
		
		json = json & "]"	
		
		
		rsTask.close 
		set rsTask = nothing 
		
		json = json & "}"

		dbug("end of GET processing")


	'!-- ------------------------------------------------------------------ -->
	case else 
	'!-- ------------------------------------------------------------------ -->
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (405)"
				
				
end select 


dbug("Tasks: " & json)

response.status = "200 Okay"
response.write json 

%>			

		
	


