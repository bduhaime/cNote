
<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNextID.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021 Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

dbug("starting accountHolderComments.asp")

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

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	case "POST"	
	
		accountHolderNumber 	= request.form("accountHolderNumber")
		customerID				= request.form("customerID") 
		newComment				= replace(request.form("newComment"),"'","''")
		
		newID = getNextID("pr_accountHolderAddenda")
		
		SQL = "insert into pr_accountHolderAddenda (id, customerID, [account holder number], content, updatedBy, updatedDateTime, type) " &_
				"values ( " &_
					newID & ", " &_
					customerID & ", " &_
					"'" & accountHolderNumber & "', " &_
					"'" & newComment & "', " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP, " &_
					"2 " &_
				") "
		
		dbug(SQL) 
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 

		
		SQL = "select " &_
					"a.id, " &_
					"concat(u.firstName, ' ', u.lastName) as fullName, " &_
					"format(a.updatedDateTime, 'yyyy-MM-dd hh:mm tt') as updatedDateTime, " &_
					"a.content " &_
				"from pr_accountHolderAddenda a " &_
				"left join csuite..users u on (u.id = a.updatedBy) " &_
				"where a.id = " & newID & " " 
				
		dbug(SQL)
				
		set rsSelect = dataconn.execute(SQL)
		if not rsSelect.eof then 
			json = "{"
				json = json & """id"": """ & rsSelect("id") & ""","
				json = json & """author"": """ & rsSelect("fullName") & ""","
				json = json & """updatedDateTime"": """ & rsSelect("updatedDateTime") & ""","
				json = json & """content"": """ & rsSelect("content") & ""","
				json = json & """msg"": ""Comment saved"""
			json = json & "}"
		else 
			json = "{""msg"":""Comment failed to save""}"
		end if
			
		rsSelect.close 
		set rsSelect = nothing 
		
		responseStatus = "200 OK"		
		

	case "DELETE" 
	
		id = request.querystring("id") 
		
		SQL = "delete from pr_accountHolderAddenda where id = " & id & " " 
		
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 

		json = "{""msg"":""Comment deleted""}"
				
		responseStatus = "200 OK"

		
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed (by accountHolderComments)"

				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending accountHolderComments.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>