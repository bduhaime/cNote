<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

dbug("start validateCustomerAccess.asp")

SQL = "select * from userCustomers where customerID = 1 and userID = " & session("userID") & " " 
set rsIU = dataconn.execute(SQL)
if not rsIU.eof then 
	internalUser = true 
	session("internalUser") = 1
else
	internalUser = false 
	session("internalUser") = -1
end if
rsIU.close 
set rsIU = nothing 

if len(customerID) <= 0 then			'customerID is missing, so redirect the user to select a customerID....

	dbug("customerID is missing, user will be transferred...")

	if lcase(session("dbName")) = "csuite" then 
	
		dbug("cSuite user attempted to access a customer page, transferring to adminHome.asp...")
		server.transfer "adminHome.asp"

	else 
		
		dbug("customerID missing, transferring internal/external user to customerList.asp...")
		server.transfer "customerList.asp" 				

	end if 
	
else 
	
	if internalUser then 
			
		'internal users can see all customers, do nothing
		dbug("internal user detected; customer access enforced by page...")

	else 
		
		'external users can see only authorized customer; check that here....
		SQL = "select * from userCustomers where customerID = " & customerID & " and userID = " & session("userID") & " " 
		set rsUC = dataconn.execute(SQL) 
		if not rsUC.eof then
			externalUserAllowed = true
		else 
			externalUserAllowed = false
		end if				
		rsUC.close 
		set rsUC = nothing 
		
		if not externalUserAllowed then 
			dbug("external user attempted to access an unauthorized customer, transferring to customerList.asp...")
			server.transfer "customerList.asp" 
		else 
			dbug("external user is authorized to access this customer")
		end if
		
	end if 
	
end if

dbug("end validateCustomerAccess.asp")
dbug(" ")

%>