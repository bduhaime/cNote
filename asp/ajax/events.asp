<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

dbug("event maintenance...")

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<events>"

msg = ""

select case request.querystring("cmd")

	case "maintain"


		eventID 				= request.querystring("eventID")
		eventName 			= escapeQuotes(request.querystring("eventName"))
		eventDescription 	= escapeQuotes(request.querystring("eventDescription"))

		if len(eventID) > 0 then 
			
			newID = eventID
			
			SQL = "update event set " &_
						"name = '" & eventName & "', " &_
						"description = '" & eventDescription & "' " &_
					"where id = " & newID & " " 
					
			msg = "Event updated"
			
		else 
			
			newID = getNextID("event") 
			
			SQL = "insert into event (id, name, description, updatedDateTime, updatedBy) " &_
					"values ( " &_
						newID & ", " &_
						"'" & eventName & "', " &_
						"'" & eventDescription & "', " &_
						"CURRENT_TIMESTAMP, " &_
						session("userID") & ") " 
						
			msg = "Event updated"

		end if 
		dbug(SQL)
		
		set rs = dataconn.execute(SQL)
		set rs = nothing

		xml = xml & "<id>" & newID & "</id>"			
		xml = xml & "<name>" & eventName & "</name>"			
		xml = xml & "<description>" & eventDescription & "</description>"			
		xml = xml & "<msg>" & msg & "</msg>"			


	case else 

		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"


end select 

userLog(msg)

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</events>"

response.write(xml)
%>