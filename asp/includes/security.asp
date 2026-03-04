<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

if len(session("userID")) <= 0 then

	response.clear()
	response.redirect "/login.asp?msg=Please login" 

else 
	
	session("sessionTimeout") = Session.Timeout
	session("lastActivity") = now()
	
end if
%>
