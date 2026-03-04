
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

		controlName = request("name")
		if len(controlName) <= 0 then 
			json = "{""error"":""name is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		

		SQL = "select [value] from systemControls where [name] = '" & controlName & "' " 
		dbug(SQL)
		
		set rsGet = dataconn.execute(SQL)
		
		if not rsGet.eof then 
		
			json = "{"
			json = json & """name"":""" & controlName & ""","
			json = json & """value"":""" & rsGet("value") & ""","
			json = json & """msg"":""Control found"""
			json = json & "}"
			
		else 
		
			json = "{"
			json = json & """name"":""" & controlName & ""","
			json = json & """msg"":""Control not found"""
			json = json & "}"
	
		end if 

		rsGet.close 
		set rsGet = nothing 

		
	'!-- ------------------------------------------------------------------ -->
	case "POST"
	'!-- ------------------------------------------------------------------ -->

		controlName = request.form("name")
		controlName = replace(controlName, "_", " ")
		if len(controlName) <= 0 then 
			json = "{""error"":""name is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
	
		controlValue = request.form("value")
		dbug("controlValue: " & controlValue)
		if len(controlName) <= 0 then 
			json = "{""error"":""value is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		
		SQL = "update systemControls set " &_
					"[value] = '" & controlValue & "' " &_
				"where [name] = '" & controlName & "' "
				
		dbug(SQL)
		
		set rsPOST = dataconn.execute(SQL) 
		set rsPOST = nothing 
		
		json = "{"
		json = json & """name"":""" & controlName & ""","
		json = json & """value"":""" & controlValue & ""","
		json = json & """msg"":""Control updated"""
		json = json & "}"

		
	

	'!-- ------------------------------------------------------------------ -->
' 	case "DELETE" 
	'!-- ------------------------------------------------------------------ -->
	
	
	
	'!-- ------------------------------------------------------------------ -->
	case else 
	'!-- ------------------------------------------------------------------ -->
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (405)"
				
				
end select 

dataconn.close 
set dataconn = nothing 

dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


