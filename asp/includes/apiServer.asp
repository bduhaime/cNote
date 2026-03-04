<%
'-- ------------------------------------------------------------------ -->
'-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'-- ------------------------------------------------------------------ -->

' serverProtocol = systemControls("server protocol")
' 
' serverHost 		= systemControls("server name")
' 
' if len( trim(systemControls("server port")) ) > 0 then 
' 	serverPort = systemControls("server port")
' else 
' 	serverPort = ""
' end if
' serverPort 		= systemControls("server port")
' 
' apiServer		= serverProtocol & "://" & serverHost & ":" & serverPort

apiServer = application("apiServer")
%>