<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

on error resume next
	
	dataconnError = false

' 	dbug(" ")
' 	dbug("application('dbServer'): " & application("dbServer"))
' 	dbug("application('dbPort'): " & application("dbPort"))
' 	dbug("session('dbName'): " & session("dbName"))
' 	dbug("application('dbUser'): " & application("dbUser"))
' 	dbug("application('dbPass'): " & application("dbPass"))


	set dataconn=Server.createobject("ADODB.Connection")
' 	dataconn.open "Provider=sqloledb; Data Source=DESKTOP-S3M44ME,1433; Initial Catalog=banks; User Id=banks; Password=tyraBanks69; "

'	The following connection string, which utilizes the SQL Native Client, is not compatible with VBScript and causes way too many problem to be useful!
' 	dataconn.open "Provider=SQLNCLI11; Server=" & application("dbServer") & "," & application("dbPort") & "; Database=" & session("dbName") & "; Uid=" & application("dbUser") & "; Pwd=" & application("dbPass") & "; "

	dataconn.open "Provider=sqloledb; Data Source=" & application("dbServer") & "," & application("dbPort") & "; Initial Catalog=" & session("dbName") & "; User Id=" & application("dbUser") & "; Password=" & application("dbPass") & "; "

	if dataconn.errors.count > 0 OR isNull(dataconn.properties("DBMS Name")) then

		dbug(" ")
		dbug("database connection errors using generic credentials (informational only when Number or NativeError are zero ...")

		for each objError in dataconn.errors 
			dbug("... Number: " 			& objError.number)
			dbug("... NativeError: " 	& objError.nativeError)
			dbug("... SQLState: " 		& objError.SQLState)
			dbug("... Source: " 			& objError.source)
			dbug("... Description: " 	& objError.description)
			dbug(" ")
			if objError.number <> 0 then
				dataconnError = true
			end if
		next

		if dataconnError then
			logMessage = "Credentials in global.asa are invalid, contact your system administrator ' ( returnCode = -3 )"
			dbug(logMessage)
			session("error_message") = session("error_message") & logMessage
			response.Redirect("login.asp?msg=" & session("error_message"))
		end if
		
	else 
		
		dbug("No errors detected establishing DB connection")
	
	end if

	if not dataconnError then
		
		dbug("dataconn successfull...")
	
	else 
		
		dbug("dataconn failed!")
					
	end if
	
on error goto 0
dbug("ending dataconnection")
%>
