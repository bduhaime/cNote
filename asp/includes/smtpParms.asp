<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'**************************************************************************************************************
'* sets parms for email messages
'*
'* NOTE: This is dependent upon the /includes/systemControls.asp script which contains the systemControls()
'* function.
'**************************************************************************************************************
sub smtpParms 
'**************************************************************************************************************
dbug("smtpParms: start")
	
	dbug("smtpParms: if failing here, ensure that includes/systemControls.asp is included in the master script")

	if isObject(objmail) then 
		dbug("objmail IS an object") 
	else 
		dbug("objmail IS NOT NOT an object")
	end if
		
	
	smtpSendUsing = systemControls("SMTP sendUsing")
	if len(smtpSendUsing) > 0 then 
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = smtpSendUsing 
	end if
	
	smtpServer = systemControls("SMTP Server")
	if len(smtpServer) > 0 then 
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = smtpServer
	end if

	smtpPort = systemControls("SMTP Port")
	if len(smtpPort) > 0 then 
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = smtpPort
	end if

	smtpUseAuthenticate = systemControls("SMTP Use Authenticate")
	if len(smtpUseAuthenticate) > 0 then
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = smtpUseAuthenticate
	end if

	smtpUsername = systemControls("SMTP username")
	if len(smtpUsername) > 0 then
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusername") = smtpUsername
	end if

	smtpPassword = systemControls("SMTP password")
	if len(smtpPassword) > 0 then 
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendpassword") = smtpPassword
	end if

	smtpUseSSL = systemControls("SMTP Use SSL")
	if len(smtpUseSSL) > 0 then 
		objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = smtpUseSSL
	end if
	
	smtpUseSTARTTLS = systemControls("SMTP User STARTTLS")
	if len(smtpUseSTARTTLS) > 0 then 
		objmail.Configuration.Fields.Item ("https//schemas.microsoft.com/cdo/configuration/sendtls") = smtpUseSTARTTLS
	end if 		

	objmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") = 60

	dbug("CDO.Configuration.fields")	
	for each thing in objmail.Configuration.fields
		dbug("..." & thing.name & "=" & thing.value)
	next 
	dbug("")	
	
	dbug("smtpParms: updating configuration fields...")
	objmail.Configuration.Fields.Update
	

dbug("end smtpParms")
end sub
%>