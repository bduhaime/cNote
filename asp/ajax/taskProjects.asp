
<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNextID.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbug("starting taskProjects.asp")

dbug("querystring:")
for each item in request.querystring
	dbug("..." & item & ": " & request.querystring(item))
next 
dbug("form:") 
for each item in request.form 
	dbug("..." & item & ": " & request.form(item))
next 

response.contentType = "application/json"
json 	= ""
msg 	= ""

'!-- ------------------------------------------------------------------ -->
'!-- validate customerID
'!-- ------------------------------------------------------------------ -->
customerID 		= request("customerID")
if len(customerID) > 0 then 
	if isNumeric(customerID) then 
		dbug("customerID validated: " & customerID)
	else 
		response.status = "422 customerID is invalid"
		response.write("{""error"":""customerID is invalid""}")
		response.end()
	end if
else 
	response.status = "422 customerID is missing"
	response.write("{""error"":""customerID is missing""}")
	response.end()
end if 


'!-- ------------------------------------------------------------------ -->
'!-- validate taskID
'!-- ------------------------------------------------------------------ -->
taskID = request("taskID") 
if len(taskID) > 0 then 
	if isNumeric(taskID) then 
		dbug("taskID validated: " & taskID)
	else 
		response.status = "422 taskID is invalid"
		response.write("{""error"":""taskID is invalid""}")
		response.end()
	end if
else 
	response.status = "422 taskID is missing"
	response.write("{""error"":""taskID is missing""}")
	response.end()
end if 


'!-- ------------------------------------------------------------------ -->
'!-- validate projectID
'!-- ------------------------------------------------------------------ -->
projectID = request("projectID") 
if len(projectID) > 0 then 
	if isNumeric(projectID) then 
		dbug("projectID validated: " & projectID)
	else 
		response.status = "422 Project ID is invalid"
		response.write("{""error"":""Project ID is invalid""}")
		response.end()
	end if
else 
	response.status = "422 Project ID is missing"
	response.write("{""error"":""Project ID is missing""}")
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
	
		SQL = "update tasks " &_
					"set projectID = " & projectID & " " &_
				"where id = " & taskID & " " &_
				"and customerID = " & customerID & " " 
	
		dbug(SQL) 
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
			
		json = "{"
			json = json & """taskID"": """ & taskID & ""","
			json = json & """projectID"": """ & projectID & ""","
			json = json & """customerID"": """ & customerID & ""","
			json = json & """taskIsOrphan"": false,"
			json = json & """msg"": ""Task added to project"""
		json = json & "}"
			
		responseStatus = "200 OK"		
		

	case "DELETE" 
	
		SQL = "update tasks " &_
					"set projectID = null " &_
				"where id = " & taskID & " " &_
				"and customerID = " & customerID & " " 
		
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
			json = json & """taskID"": """ & taskID & ""","
			json = json & """customerID"": """ & customerID & ""","
			json = json & """taskIsOrphan"": " & taskIsOrphan & ","
			json = json & """msg"": ""Task removed from project"""
		json = json & "}"
				
		responseStatus = "200 OK"

		
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"

				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending taskProjects.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>