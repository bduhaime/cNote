
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<% 
dbug("start of /cprofit/ajax/accountHolderFlags.asp...")
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"

customerID 				= request("customerID")
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
		


accountHolderNumber 	= request("accountHolderNumber")
if len(accountHolderNumber) <= 0 then 
	json = "{""error"":""accountHolderNumber is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
end if			

		

json = "{""data"": ["

SQL = "select " &_
			"f.id, " &_
			"f.name, " &_
			"f.color, " &_
			"a.[account holder number] " &_
		"from flags f " &_
		"left join pr_accountHolderAddenda a on (a.flagID = f.id and a.customerID = " & customerID & " and [account holder number] = '" & accountHolderNumber & "') " &_
		"order by f.priority "

dbug(SQL)

set rsFlags = dataconn.execute(SQL) 

while not rsFlags.eof 

	if not isNull(rsFlags("account holder number")) then 
		checked = "checked" 
	else 
		checked = ""
	end if

	json = json & "{"
	json = json & """DT_RowId"":""" & rsFlags("id") & ""","
	json = json & """flagName"":""" & rsFlags("name") & ""","
	json = json & """flagColor"":""" & rsFlags("color") & ""","
	json = json & """checked"":""" & checked & ""","
	json = json & """iconColor"":""" & iconColor & """"
	json = json & "}"
	
	rsFlags.movenext 

	if not rsFlags.eof then json = json & ","

wend 

rsFlags.close 
set rsFlags = nothing 

json = json & "]}"

dbug(json)

response.status = "200 Okay"
response.write json 
dbug("end of /cprofit/ajax/accountHolderFlags.asp")
%>			

		
	


