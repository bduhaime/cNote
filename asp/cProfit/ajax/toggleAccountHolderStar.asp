
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
dbug("toggleAccountHolderStar.asp started")

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

SQL = "select id " &_
		"from pr_accountHolderAddenda " &_
		"where customerID = " & customerID & " " &_
		"and [Account Holder Number] = '" & accountHolderNumber & "' " &_
		"and type = 3 " 

dbug(SQL)


set rsStar = dataconn.execute(SQL) 

if not rsStar.eof then 
	
	updateSQL = "delete from pr_accountHolderAddenda " &_
					"where customerID = " & customerID & " " &_
					"and [Account Holder Number] = '" & accountHolderNumber & "' " &_
					"and type = 3 " 

	msg = "Star removed"

else 
	
	newID = getNextId("pr_accountHolderAddenda") 
	updateSQL = "insert into pr_accountHolderAddenda (id, customerID, [account holder number], updatedBy, updatedDateTime, type) " &_
					"values ( " &_
						newID & ", " &_
						customerID & ", " &_
						"'" & accountHolderNumber & "', " &_
						session("userID") & ", " &_
						"current_timestamp, " &_
						"3 " &_
					") " 
	msg = "Star added" 
	
end if 

dbug("updateSQL: " & updateSQL)

set rsUpdate = dataconn.execute(updateSQL) 
set rsUpdate = nothing 


json = json & """msg"":""" & msg & """"

rsStar.close 
set rsStar = nothing 

json = json & "}"

dbug(json)
dbug("toggleAccountHolderStar.asp ended")

response.status = "200 Okay"
response.write json 
%>			

		
	


