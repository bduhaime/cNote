<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNextID.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbug("starting accountHolderAddenda.asp")

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

	case "OPTIONS"
		
		select case request.serverVarialbes("Access-Control-Request-Method")

			case "GET","POST"
		
				responseStatus = "204 No Content"
				
			case else 
			
				responseStatus = "405 Method Not Allowed"
				
		end select 



	case "GET"
	
		customerID				= request.querystring("customerID")
		accountHolderNumber 	= request.querystring("accountHolderNumber")
		
		SQL = "select " &_
					"f.id, " &_
					"f.name, " &_
					"f.priority, " &_
					"f.color, " &_
					"case when a.id is not null then 'check' else '' end as checked, " &_
					"trim(concat(u.firstName, ' ', u.lastName)) as updatedBy, " &_
					"format(a.updatedDateTime, 'yyyy-MM-dd HH:mm') as updatedDateTime " &_
				"from flags f " &_
				"left join pr_accountHolderAddenda a on (a.flagID = f.id and type = 1 and a.customerID = " & customerID & " and [account holder number] = '" & accountHolderNumber & "') " &_
				"left join csuite..users u on (u.id = a.updatedBy) " &_
				"order by priority asc "		
				
		dbug(SQL)
		set rsFlags = dataconn.execute(SQL) 

		if not rsFlags.eof then 
			
			jsonFlags = """flags"": ["

			while not rsFlags.eof 
			
				jsonFlags = jsonFlags & "{"
					jsonFlags = jsonFlags & """id"": """ & rsFlags("id") & ""","
					jsonFlags = jsonFlags & """color"": """ & rsFlags("color") & ""","
					jsonFlags = jsonFlags & """name"": """ & rsFlags("name") & ""","
					jsonFlags = jsonFlags & """checked"": """ & rsFlags("checked") & ""","
					jsonFlags = jsonFlags & """updatedBy"": """ & rsFlags("updatedBy") & ""","
					jsonFlags = jsonFlags & """updatedDateTime"": """ & rsFlags("updatedDateTime") & """"
				jsonFlags = jsonFlags & "}"
				
				rsFlags.movenext 
				
				if not rsFlags.eof then jsonFlags = jsonFlags & "," end if
			
			wend 
			
			jsonFlags = jsonFlags & "]"
			
		else 
			
			jsonFlags = ""
			
		end if 

		rsFlags.close 
		set rsFlags = nothing 
		
		
		
		SQL = "SELECT " &_
					"a.id, " &_
					"a.color, " &_
					"a.content, " &_
					"trim(concat(u.firstName, ' ', u.lastName)) as updatedBy, " &_
					"format(a.updatedDateTime, 'yyyy-MM-dd HH:mm') as updatedDateTime " &_
				"FROM pr_accountHolderAddenda a " &_
				"LEFT JOIN csuite..users u on (u.id = a.updatedBy) " &_
				"WHERE a.customerID = " & customerID & " " &_
				"AND [account holder number] = '" & accountHolderNumber & "' " &_
				"AND a.type = 2 " &_
				"ORDER BY a.updatedDateTime DESC " 
					
		dbug(SQL)
		set rsComments = dataconn.execute(SQL)			
		
		if not rsComments.eof then 
			
			if len(jsonFlags) > 0 then 
				jsonComments = ","
			else 
				jsonComments = ""
			end if 

			jsonComments = jsonComments & """comments"": ["

			while not rsComments.eof 
			
				content = replace(rsComments("content"),vbLF,"\n")

				jsonComments = jsonComments & "{"
					jsonComments = jsonComments & """id"": """ & rsComments("id") & ""","
					jsonComments = jsonComments & """content"": """ & content & ""","
					jsonComments = jsonComments & """updatedBy"": """ & rsComments("updatedBy") & ""","
					jsonComments = jsonComments & """updatedDateTime"": """ & rsComments("updatedDateTime") & """"
				jsonComments = jsonComments & "}"
				
				
				rsComments.movenext 
				
				if not rsComments.eof then jsonComments = jsonComments & "," end if 

			wend 

			jsonComments = jsonComments & "]"

		else 
			
			jsonComments = ""
			
		end if 

		rsComments.close 
		set rsComments = nothing 
		
		json = "{" &_
					jsonFlags &_
					jsonComments &_
				 "}"

		responseStatus = "200 OK"



	case "POST"	
	
		accountHolderNumber 	= request.form("accountHolderNumber")
		customerID				= request.form("customerID") 
		flagID					= request.form("flagID")
		
		SQL = "select id " &_
				"from pr_accountHolderAddenda " &_
				"where [account holder number] = '" & accountHolderNumber & "' " &_
				"and customerID = " & customerID & " " &_
				"and flagID = " & flagID & " " &_
				"and type = 1 " 
				
		dbug(SQL) 
		set rsSelect = dataconn.execute(SQL) 
		if not rsSelect.eof then 
			
			SQL = "delete from pr_accountHolderAddenda where id = " & rsSelect("id") & " " 
			msg = "Flag removed"
			
		else 
			
			newID = getNextId("pr_accountHolderAddenda") 
			
			SQL = "insert into pr_accountHolderAddenda (id, customerID, [account holder number], updatedBy, updatedDateTime, type, flagID) " &_
					"values ( " &_
						newID & ", " &_
						customerID & ", " &_
						"'" & accountHolderNumber & "', " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						"1, " &_
						flagID & " " &_
					") "
			msg = "Flag added"
		
		end if 
		
		dbug(SQL) 
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 

		rsSelect.close 
		set rsSelect = nothing 
		
		json = "{""msg"": """ & msg & """}"
		
		responseStatus = "200 OK"		
		

	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (080)"
				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending accountHolderAddenda.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>