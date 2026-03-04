<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

dbug("starting getSystemControls.asp")
response.contentType = "application/json"
json 	= ""
msg 	= ""


select case request.servervariables("REQUEST_METHOD") 

	case "GET"
	
		dbug("REQUEST_METHOD = GET")

		control = request.querystring("control")		
		
		SQL = "select [value] from systemControls where [name] = '" & control & "' " 
		dbug(SQL)
		set rsControl = dataconn.execute(SQL)
		if not rsControl.eof then 
			
			json = """" & control & """:""" &  rsControl("name") & """" 
			responseStatus = "200 OK"
			
		else
			
			data = ""
			responseStatus = "404 Not Found"
			
		end if 
		
		rsControl.close 
		set rsControl = nothing 
	
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
				
end select 

dataconn.close 
set dataconn = nothing 



json = "{" & json & "}"

dbug("json: " & json)
dbug("ending getSystemControls.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>