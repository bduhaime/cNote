<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<%
' ------------------------------------------------------------------
' Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
' ------------------------------------------------------------------
response.ContentType = "application/json"

for each item in request.querystring
	dbug("request.querystring('item'): " & request.querystring(item) )
next 

for each item in request.form
	dbug("request.form('item'): " & request.form(item) )
next 

dbug("at top of session.asp, session('userID'): " & session("userID") )


select case request.servervariables("REQUEST_METHOD") 

	case "POST"

		dbug("at top of POST, session('userID'): " & session("userID") )
	
		dbug( "POST: step 1")
		userLog( "session extended by user" & session("userID") & ", timer reset to " & application("sessionTimeout") & " minutes" )

		dbug( "POST: step 2")
		session.timeout = application( "sessionTimeout" )

		dbug( "POST: step 3" )
		session("lastActivity") = now()

		dbug( "POST: step 4")
		response.status = "200"

		dbug( "POST: step 5")
		json = "{ ""sessionTimeout"": " & session.timeout & ", ""lastActivity"": """ & session("lastActivity") & """ }" 

		dbug( "POST: step 6")
		response.status = "200 OK"


	case "DELETE"
	
		dbug("at top of DELETE, session('userID'): " & session("userID") )
	
		dbug( "DELETE: step 1")
		if request("cmd") = "timeout" then 
		dbug( "DELETE: step 2a")

			logMsg = "user session timed out" 
			redirectMsg = "Your session timed out, please log in"

		elseif request("cmd") = "manual" then 
		dbug( "DELETE: step 2b")

			logMsg = "user manually logged out"
			redirectMsg = "Log out successful"

		else 
		dbug( "DELETE: step 2c")

			logMsg = "session ended" 
			redirectMsg = "Session ended, please log in" 

		end if
		dbug( "DELETE: step 3")
		
		userLog( logMsg )
		dbug( "DELETE: step 4")
		
		session.abandon()
		dbug( "DELETE: step 5")


		redirectURL = "login.asp"
		dbug( "DELETE: step 6")


		response.write( "{ redirectURL: """ & redirectURL & ", redirectMsg: """ & redirectMsg & """ }" )
		dbug( "DELETE: step 7")
		

	case else 
		dbug("DELETE: step 8")

		response.status = "405 Not allowed"
				
end select 

dbug( "ALL: step 9")
response.write json 
%>
