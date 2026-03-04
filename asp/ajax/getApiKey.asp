<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbugTemp = application("dbug")
application("dbug") = true


dbug("starting getApiKey.asp")
response.contentType = "application/json"
json 	= ""
msg 	= ""


select case request.servervariables("REQUEST_METHOD") 

	case "GET"
	
		dbug("REQUEST_METHOD = GET")

		customerID = request.querystring("customerID")
		
		SQL = "select cProfitApiKey from customer where id = " & customerID & " " 
		dbug(SQL)
		set rsCust = dataconn.execute(SQL)
		if not rsCust.eof then 
			
			json = """cProfitApiKey"":""" &  rsCust("cProfitApiKey") & """" 
			responseStatus = "200 OK"
			
		else
			
			data = ""
			responseStatus = "404 Not Found"
			
		end if 
		
		rsCust.close 
		set rsCust = nothing 
	
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
				
end select 

dataconn.close 
set dataconn = nothing 



json = "{" & json & "}"

dbug("json: " & json)
dbug("ending getApiKey.asp")
dbug(" ")

application("dbug") = dbugTemp

response.status = responseStatus
response.write json 
%>