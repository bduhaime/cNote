
<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNextID.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbug("starting users.asp")

response.contentType = "application/json"


dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	case "GET"

		if lCase(session("dbName")) <> "csuite" then 
			SQL = "select u.id, u.username, u.firstName, u.lastName, u.title, u.active " &_
					"from cSuite..users u " &_
					"where exists ( " &_
						"select * " &_
						"from csuite..clientUsers cu " &_
						"where cu.userID = u.id " &_
						"and cu.clientID = " & session("clientNbr") & " " &_
					") " &_								
					"order by u.username "
		else 
			SQL = "select u.id, u.username, u.firstName, u.lastName, u.title, u.active " &_
					"from cSuite..users u " &_
					"order by u.username "
		end if
		
		dbug(SQL)
		set rsUsers = dataconn.execute(SQL) 

		json = "{""data"": ["
			
		while not rsUsers.eof 
		
			if lCase(session("dbName")) <> "csuite" then 
				
				SQL = "select top 1 customerID from userCustomers where customerID = 1 and userID = " & rsUsers("id") & " "
				set rsInt = dataconn.execute(SQL) 
				if not rsInt.eof then 
					isInternal = "true"
				else 
					isInternal = "false"
				end if 
				rsInt.close
				set rsInt = nothing

				SQL = "select top 1 customerID from userCustomers where customerID <> 1 and userID = " & rsUsers("id") & " "
				set rsExt = dataconn.execute(SQL) 
				if not rsExt.eof then 
					isExternal = "true"
				else 
					isExternal = "false"
				end if 
				rsExt.close 
				set rsExt = nothing

				SQL = "select top 1 cc.id, cc.name, c.name as customerName " &_
						"from customerContacts cc " &_
						"left join customer c on (c.id = cc.customerID) " &_
						"where trim(email) = '" & trim(rsUsers("username")) & "' "
						
' 				SQL = "select top 1 id, name from customerContacts where trim(email) = '" & trim(rsUsers("username")) & "' "

				set rsCC = dataconn.execute(SQL) 
				if not rsCC.eof then 
					contactID				= """" & rsCC("id") & """" 
					contactName 			= """" & rsCC("name") & """"
					contactCustomerName 	= """" & rsCC("customerName") & """"
				else 
					contactID				= "null"
					contactName				= "null"
					contactCustomerName	= "null"
				end if
				rsCC.close 
				set rsCC = nothing 
			
			else 
				
				isInternal 				= "null"
				isExternal 				= "null"
				contactID				= "null"
				contactName				= "null"
				contactCustomerName	= "null"
				
			end if 

			json = json & "{"
			json = json & """DT_RowId"":""" & rsUsers("id") & ""","
			json = json & """userName"":""" & trim(rsUsers("username")) & ""","
			json = json & """firstName"":""" & trim(rsUsers("firstName")) & ""","
			json = json & """lastName"":""" & trim(rsUsers("lastName")) & ""","
			json = json & """title"":""" & trim(rsUsers("title")) & ""","
			json = json & """isInternal"":" & isInternal & ","
			json = json & """isExternal"":" & isExternal & ","
			json = json & """contactID"":" & contactID & ","
			json = json & """contactName"":" & contactName & ","
			json = json & """contactCustomerName"":" & contactCustomerName & ","
			json = json & """isActive"": " & lCase(rsUsers("active"))
			json = json & "}"

			rsUsers.movenext 
			
			if not rsUsers.eof then json = json & "," end if
		
		wend
		
		json = json & "]}"
		
		rsUsers.close 
		set rsUsers = nothing 

		responseStatus = "200 OK"

	
' 	case "POST"
' 	
' 		SQL = "update tasks " &_
' 					"set projectID = " & projectID & " " &_
' 				"where id = " & taskID & " " &_
' 				"and customerID = " & customerID & " " 
' 	
' 		dbug(SQL) 
' 		set rsUpdate = dataconn.execute(SQL) 
' 		set rsUpdate = nothing 
' 			
' 		json = "{"
' 			json = json & """taskID"": """ & taskID & ""","
' 			json = json & """projectID"": """ & projectID & ""","
' 			json = json & """customerID"": """ & customerID & ""","
' 			json = json & """taskIsOrphan"": false,"
' 			json = json & """msg"": ""Task added to project"""
' 		json = json & "}"
' 			
' 		responseStatus = "200 OK"		
' 		
' 
' 	case "DELETE" 
' 	
' 		SQL = "update tasks " &_
' 					"set projectID = null " &_
' 				"where id = " & taskID & " " &_
' 				"and customerID = " & customerID & " " 
' 		
' 		dbug(SQL) 
' 		set rsDelete = dataconn.execute(SQL) 
' 		set rsDelete = nothing 
' 		
' 		SQL = "select count(*) as kiCount from keyInitiativeTasks where taskID = " & taskID & " "
' 		dbug(SQL) 
' 		set kiCount = dataconn.execute(SQL) 
' 		if cInt(kiCount("kiCount")) > 0 then 
' 			taskIsOrphan = "false"
' 		else 
' 			taskIsOrphan = "true"
' 		end if 
' 		kiCount.close 
' 		set kiCount = nothing 
' 
' 		json = "{"
' 			json = json & """taskID"": """ & taskID & ""","
' 			json = json & """customerID"": """ & customerID & ""","
' 			json = json & """taskIsOrphan"": " & taskIsOrphan & ","
' 			json = json & """msg"": ""Task removed from project"""
' 		json = json & "}"
' 				
' 		responseStatus = "200 OK"
' 
' 		
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"

				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending users.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>