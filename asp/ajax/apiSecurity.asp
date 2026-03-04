<%
' ------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ------------------------------------------------------------------

if len(session("userID")) <= 0 then
	
	dbug(" ")
	dbug("**********************************************************************************************")
	dbug("** 401 - UNAUTHORIZED: " & request.serverVariables("SCRIPT_NAME"))
	dbug("**")
	dbug("**     Querystring: " & request.serverVariables("querystring"))
	dbug("**     Remote Address: " & request.serverVariables("REMOTE_ADDR"))
	dbug("**     Remote Host: " & request.serverVariables("REMOTE_HOST"))
	dbug("**     Remote User: " & request.serverVariables("REMOTE_USER"))
	dbug("**     Request Method: " & request.serverVariables("REQUEST_METHOD"))
	dbug("**     Authentication Method: " & request.serverVariables("AUTH_TYPE"))
	dbug("**     Authentication User: " & request.serverVariables("AUTH_USER"))
	dbug("**")
	dbug("**********************************************************************************************")
	dbug(" ")
	
	response.status = "401 Unauthorized"
	session("401") = request.serverVariables("SCRIPT_NAME")
	response.clear()
	response.end() 
		
end if
%>
