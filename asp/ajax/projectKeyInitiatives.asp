
<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNextID.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbug("starting projectKeyInitiatives.asp")

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
	
		SQL = "insert into keyInitiativeProjects (keyInitiativeID, projectID, updatedBy, updatedDateTime) " &_
				"values ( " &_
					keyInitiativeID & ", " &_
					projectID & ", " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP " &_
				") "
		
		dbug(SQL) 
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
			
		json = "{"
			json = json & """keyInitiativeID"": """ & keyInitiativeID & ""","
			json = json & """projectID"": """ & projectID & ""","
			json = json & """customerID"": """ & customerID & ""","
			json = json & """msg"": ""KI/Project added"""
		json = json & "}"
			
		responseStatus = "200 OK"		
		

	case "DELETE" 
	
		SQL = "delete from keyInitiativeProjects " &_
				"where keyInitiativeID = " & keyInitiativeID & " " &_
				"and projectID = " & projectID & " " 
		
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 

		json = "{""msg"":""KI/Project deleted""}"
				
		responseStatus = "200 OK"

		
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"

				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending accountHolderComments.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>