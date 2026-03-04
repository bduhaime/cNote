
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"

customerID 				= request.querystring("customerID")
accountHolderNumber 	= request.querystring("accountHolderNumber")


if len(customerID) <= 0 then 
	json = "{""error"":""CustomerID is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if not isNumeric(customerID) then 
		json = "{""error"":""CustomerID is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	end if
end if			
		
if len(accountHolderNumber) <= 0 then 
	json = "{""error"":""accountHolderNumber is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
end if			
		

json = "{"

SQL = "select top 1 " &_
			"a.type, " &_
			"f.name, " &_
			"f.color " &_
		"from pr_accountHolderAddenda a " &_
		"left join flags f on (f.id = a.flagID) " &_
		"where customerID = " & customerID & " " &_
		"and a.type in (1,2) " &_
		"and [Account Holder Number] = '" & accountHolderNumber & "' " &_
		"order by a.type, f.priority "

dbug(SQL)

set rsFlag = dataconn.execute(SQL) 

if not rsFlag.eof then 

	if cInt(rsFlag("type")) = 1 then 
		
		iconToShow 		= "flag"
		iconColor		= rsFlag("color")
		iconTitle 		= rsFlag("name") 
		iconVisibility	= "visible"

	elseif cInt(rsFlag("type")) = 2 then 

		iconToShow 		= "notes" 
		iconColor		= "black"
		iconTitle 		= "" 
		iconVisibility	= "visible"		

	else 

		iconToShow 		= "add"
		iconColor		= "black"
		iconTitle 		= "" 
		iconVisibility	= "hidden"

	end if

else 

	iconToShow 		= "add"
	iconColor		= "black"
	iconTitle 		= "" 
	iconVisibility	= "hidden"
	
end if 

json = json & """accountHolderNumber"":""" & accountHolderNumber & ""","
json = json & """iconToShow"":""" & iconToShow & ""","
json = json & """iconColor"":""" & iconColor & ""","
json = json & """iconTitle"":""" & iconTitle & ""","
json = json & """iconVisibility"":""" & iconVisibility & """"

rsFlag.close 
set rsFlag = nothing 

json = json & "}"

dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


