<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/userPermittedPage.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------


response.contentType = "text/xml"

dbug("start clientSwitcher...")
xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<clientSwitcher>"

dbName				= request.querystring("db")		// csuite..clients.databaseName
clientNbr			= request.querystring("nbr")		// csuite..clients.id
clientID 			= request.querystring("id") 		// csuite..clients.clientID

' remove " (default)" if it is present in clientName...
clientName 			= request.querystring("name")		// csuite..clients.name
clientName 			= left(clientName, inStr(clientName, " (default)"))

httpReferer 		= request.serverVariables("HTTP_REFERER")
fullScriptName		= mid(httpReferer,inStrRev(httpReferer,"/")+1)

' determine name of current script...
delimiterPosition = inStr(fullScriptName,"?")
if delimiterPosition > 0 then 
	currentQuerystring 	= mid(fullScriptName,inStr(fullScriptName,"?"))
	currentScript			= left(fullScriptName,inStr(fullScriptName,"?")-1)
else 
	currentQuerystring 	= ""
	currentScript			= fullScriptName
end if 

if len(clientID) > 0 then 
	
	if clientDb <> session("dbName") then 

		' changing databases/clients, so kill the current database connection object....
		if isObject(dataconn) then 
			dataconn.close 
			dataconn = nothing 
		end if

		' reset client-related session variables...
		session("dbName") 		= dbName
		session("clientID") 		= clientID
		session("clientName")	= clientName
		session("clientNbr") 	= clientNbr

		' re-establish the datavase connection object with the new session variables...
		%>
		<!-- #include file="../includes/dataconnection.asp" -->
		<%
		' determine if the user is internal (1), external (-1), or a cSuite user (0)...
		if lCase(session("dbName")) = "csuite" then 
			session("internalUser") = 0
		else 
			SQL = "select customerID from userCustomers where userID = " & session("userID") & " and customerID = 1 "
			set rsUC = dataconn.execute(SQL) 
			if not rsUC.eof then 
				session("internalUser") = 1
			else 
				session("internalUser") = -1
			end if 
			rsUC.close 
			set rsUC = nothing
		end if

		' determine where to send the user in the new client...
		if userPermittedPage(currentScript) then 

			' user is permitted to access the same page on the new client, so dig further...
			select case currentScript 
			
				case "userEdit.asp","permissionEdit.asp"
					' these scripts use a global id, so add it to the new querystring...
					redirectTo = currentScript & currentQuerystring
					
				case "home.asp","externalUserCustomerList.asp","adminHome.asp"
					' these scripts have additional permissions, depending on if the the user is internal, external, or both...
				
					if (session("internalUser") = 1 and userPermitted(97)) then 
						redirectTo = "home.asp"
					elseif (session("internalUser") = -1 and userPermitted(60)) then 
						redirectTo = "externalUserCustomerList.asp"
					elseif (session("internalUser") = 0 and userPermitted(47))  then 
						redirectTo = "adminHome.asp"
					else 
						' can't figure it out, so send them to the login page to start over...
						dbug("invalid combo for session('internalUser')/userPermitted() encountered (001): " & session("internalUser"))
						redirectTo = "login.asp"
					end if
					
				case "taskDetail.asp" 
					' this script requires that the user pick a customer, if the user has permission, redirect to customerList.asp
					
					if userPermitted(5) then 	 		' customerList.asp
						redirectTo = "customerList.asp" 
					else
						if userPermitted(97) then 		' home.asp
							redirectTo "home.asp" 
						else 
							redirectTo "login.asp" 
						end if 
					end if 
					
			
				case else 
					' everything else is straight forward...
					redirectTo = currentScript

			end select  

		else 
			
			' user is not permitted to access the same page in the new client, so dig further...
			
			if lCase(session("dbName")) = "csuite" and userPermitted(47) then
				' if the new client is cSuite, just send them to the home page...
				redirectTo = "adminHome.asp"
			else 
				
				' if the new client is not cSuite, then determine where to go depending on if the user internal, external, or both...
				if (session("internalUser") = 1 and userPermitted(97)) then 
					redirectTo = "home.asp"
				elseif (session("internalUser") = -1 and userPermitted(60)) then 
					redirectTo = "externalUserCustomerList.asp"
				elseif (session("internalUser") = 0 and userPermitted(47))  then 
					redirectTo = "adminHome.asp"
				else 
					' can't figure it out, so send them to the login page to start over...
					dbug("invalid combo for session('internalUser')/userPermitted() encountered (002): " & session("internalUser"))
					redirectTo = "login.asp"
				end if

			end if
			
		end if 
		
		msg = "client successfully switched, DB connection reset."
		
	else 

		' it's the same client/database, to just redirect to the same page the user was on...		
		redirectTo = currentScript & currentQuerystring

		msg = "same client selected, no changes made."
		
	end if
	
else 
	
	redirectTo = currentScript & currentQuerystring
	msg = "no selection made"
				
end if


xml = xml & "<redirect id='" & session("dbName") & "'>" & redirectTo & "</redirect>"

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</clientSwitcher>"

response.cookies("user")("clientID") = session("clientID")
response.write(xml)
%>