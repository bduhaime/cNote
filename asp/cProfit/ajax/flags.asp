
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../../includes/getNextID.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)


response.ContentType = "application/json"
dbug("start of cProfit/ajax/flags.asp")


dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	'!-- ------------------------------------------------------------------ -->
	case "GET"
	'!-- ------------------------------------------------------------------ -->

		SQL = "select " &_
					"id, " &_
					"name, " &_
					"priority, " &_
					"color " &_
				"from flags " &_
				"order by priority"
				
		dbug(SQL)
		
		json = "{""data"": ["
		
		set rsGet = dataconn.execute(SQL)
		
		while not rsGet.eof
		
			json = json & "{"
			json = json & """DT_RowId"":""" & rsGet("id") & ""","
			json = json & """name"":""" & rsGet("name") & ""","
			json = json & """priority"":""" & rsGet("priority") & ""","
			json = json & """color"":""" & rsGet("color") & """"
			json = json & "}"
			
			rsGet.movenext 
			
			if not rsGet.eof then json = json & ","
			
		wend
		
		json = json & "]}"
		
		rsGet.close 
		set rsGet = nothing 

		
	'!-- ------------------------------------------------------------------ -->
	case "POST"
	'!-- ------------------------------------------------------------------ -->

		flagName = request("flagName")
		if len(flagName) <= 0 then 
			json = "{""error"":""flagName is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		
		flagColor = request("flagColor")
		if len(flagColor) <= 0 then 
			json = "{""error"":""flagColor is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		
		flagID = request("flagID")
		if len(flagID) <= 0 then 

			flagID = getNextID("flags")

			SQL = "select max(priority) as maxPriority from flags " 
			dbug(SQL)
			set rsMax = dataconn.execute(SQL) 
			if not rsMax.eof then 
				newPriority = cInt(rsMax("maxPriority")) + 1
			else 
				newPriority = 1
			end if 
			rsMax.close 
			set rsMax = nothing 
			
			SQL = "insert into flags (id, name, priority, color) " &_
					"values ( " &_
						flagID & ", " &_
						"'" & flagName & "', " &_
						newPriority & ", " &_
						"'" & flagColor & "' " &_
					") " 
					
			msg = "Flag added"

		else 
			
			SQL = "update flags set " &_
						"name = '" & flagName & "', " &_
						"color = '" & flagColor & "', " &_
					"where id = " & flagID & " " 
					
			msg = "Flag updated" 
			
		end if 
		
		dbug(SQL)
		set rsPOST = dataconn.execute(SQL)
		set rsPOST = nothing 

		json = "{" 
		json = json & """id"":""" & newID & """," 
		json = json & """name"":""" & flagName & """," 
		json = json & """color"":""" & flagColor & """," 
		json = json & """msg"":""" & msg & """" 
		json = json & "}"
	

	'!-- ------------------------------------------------------------------ -->
	case "DELETE" 
	'!-- ------------------------------------------------------------------ -->
	
		customerID = request("customerID") 
		if len(customerID) <= 0 then 
			dbug("customerID missing")
			json = "{""error"":""customerID is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		
		flagID = request("flagID") 
		if len(flagID) <= 0 then 
			dbug("flagID missing")
			json = "{""error"":""flagID is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		
		SQL = "delete from pr_accountHolderAddenda " &_
				"where customerID = " & customerID & " " &_
				"and flagID = " & flagID & " " &_
				"and type = 1 " 

		dbug(SQL)
		set rsDelete1 = dataconn.execute(SQL)
		set rsDelete1 = nothing 
		
		SQL = "delete from flags " &_
				"where id = " & flagID & " "
				
		dbug(SQL)
		set rsDelete2 = dataconn.execute(SQL)
		set rsDelete2 = nothing 

		json = "{" 
		json = json & """customerID"":""" & customerID & """," 
		json = json & """id"":""" & flagID & """," 
		json = json & """msg"":""Flag deleted""" 
		json = json & "}"
	
	
	'!-- ------------------------------------------------------------------ -->
	case else 
	'!-- ------------------------------------------------------------------ -->
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (405)"
				
				
end select 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


