
<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNextID.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbug(" ")
dbug("starting taskKeyInitiatives.asp")

response.contentType = "application/json"
json 	= ""
msg 	= ""

keyInitiativeID = request("keyInitiativeID") 
if len(keyInitiativeID) > 0 then 
	if isNumeric(keyInitiativeID) then 
		dbug("keyInitiativeID validated: " & keyInitiativeID)
	else 
		response.status = "422 Key Initiative ID is invalid"
		response.write("{""error"":""Key Initiative ID is invalid""}")
		response.end()
	end if
else 
	response.status = "422 Key Initiative ID is missing"
	response.write("{""error"":""Key Initiative ID is missing""}")
	response.end()
end if 


taskID = request("taskID") 
if len(taskID) > 0 then 
	if isNumeric(taskID) then 
		dbug("taskID validated: " & taskID)
	else 
		response.status = "422 task ID is invalid"
		response.write("{""error"":""task ID is invalid""}")
		response.end()
	end if
else 
	response.status = "422 task ID is missing"
	response.write("{""error"":""task ID is missing""}")
	response.end()
end if 



dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	case "GET"

		dbug("GETing nothing...")
		response.status = "200"
		response.write( "{""msg"":""Nothing to GET""}")
		response.end()
	
	case "POST"
	
		SQL = "insert into keyInitiativeTasks (keyInitiativeID, taskID, updatedBy, updatedDateTime) " &_
				"values ( " &_
					keyInitiativeID & ", " &_
					taskID & ", " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP " &_
				") "
		
		dbug(SQL) 
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
			
		json = "{"
			json = json & """keyInitiativeID"": """ & keyInitiativeID & ""","
			json = json & """taskID"": """ & taskID & ""","
			json = json & """taskIsOrphan"": false,"
			json = json & """msg"": ""KI/Task added"""
		json = json & "}"
			
		responseStatus = "200 OK"		
		

	case "DELETE" 
	
		SQL = "delete from keyInitiativeTasks " &_
				"where keyInitiativeID = " & keyInitiativeID & " " &_
				"and taskID = " & taskID & " " 
		
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 

		SQL = "select count(*) as kiCount from keyInitiativeTasks where taskID = " & taskID & " "
		dbug(SQL) 
		set kiCount = dataconn.execute(SQL) 
		if cInt(kiCount("kiCount")) > 0 then 
			taskIsOrphan = "false"
		else 
			taskIsOrphan = "true"
		end if 
		kiCount.close 
		set kiCount = nothing 

		json = "{"
			json = json & """keyInitiativeID"": """ & keyInitiativeID & ""","
			json = json & """taskID"": """ & taskID & ""","
			json = json & """taskIsOrphan"": " & taskIsOrphan & ","
			json = json & """msg"": ""KI/Task deleted"""
		json = json & "}"
				
		responseStatus = "200 OK"

		
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"

				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending taskKeyInitiatives.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>