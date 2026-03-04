<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/systemControls.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->


dbug("starting getApiDetails.asp")
response.contentType = "application/json"
json 	= ""
msg 	= ""


select case request.servervariables("REQUEST_METHOD") 

	case "GET"
	
		dbug("REQUEST_METHOD = GET")

		customerID = request.querystring("customerID")
		
		SQL = "select cProfitApiKey, cProfitURI from customer where id = " & customerID & " " 
		dbug(SQL)
		set rsKey = dataconn.execute(SQL)
		if not rsKey.eof then 
			
			json = """key"":""" & rsKey("cProfitApiKey") 			& """," &_
					 """uri"":""" & rsKey("cProfitURI") 	& """"

			responseStatus = "200 OK"
			
		else
			
			data = ""
			responseStatus = "404 Not Found"
			
		end if 
		
		rsKey.close 
		set rsKey = nothing 
	
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
				
end select 

dataconn.close 
set dataconn = nothing 



json = "{" & json & "}"

dbug("json: " & json)
dbug("ending getApiDetails.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>