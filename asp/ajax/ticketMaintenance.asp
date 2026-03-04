<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

'***** TICKET MAINTENANCE *****

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<ticketMaintenance>"

msg = ""

select case request.querystring("cmd")

	case "query"
	
		SQL = "select t.id, t.title, p.name as priorityName, c.name as categoryName, s.name as severityName, u.firstName, u.lastName, st.name as statusName, t.reportedBy, t.narrative, t.openedDate, t.closedDate " &_
				"from supportTickets t " &_
				"left join supportPriorities p on (p.id = t.priorityID) " &_
				"left join supportCategories c on (c.id = t.categoryID) " &_
				"left join supportSeverities s on (s.id = t.severityID) " &_
				"left join cSuite..users u on (u.id = t.assignedID) " &_
				"left join supportStatuses st on (st.id = t.statusID) " &_
				"where t.id = " & request.querystring("id") & " " 
				
		set rs = dataconn.execute(SQL)
		if not rs.eof then 
			
			xml = xml & "<id>" & rs("id") & "</id>"
			xml = xml & "<title>" & rs("title") & "</title>"
			xml = xml & "<priorityName>" & rs("priorityName") & "</priorityName>"
			xml = xml & "<categoryName>" & rs("categoryName") & "</categoryName>"
			xml = xml & "<severityName>" & rs("severityName") & "</severityName>"
			xml = xml & "<assignedTo>" & rs("firstName") & " " & rs("lastName") & "</assignedTo>"
			xml = xml & "<statusName>" & rs("statusName") & "</statusName>"
			xml = xml & "<reportedBy>" & rs("reportedBy") & "</reportedBy>"
			xml = xml & "<narrative>" & rs("narrative") & "</narrative>"
			xml = xml & "<openedDate>" & rs("openedDate") & "</openedDate>"
			xml = xml & "<closedDate>" & rs("closedDate") & "</closedDate>"
			
			msg = "Ticket Found"

		else 
			
' 			dbug("rs.eof")
			msg = "Ticket Not Found"
			
		end if
				
				

	case "add"

		SQL = "select max(id) as maxID from supportTickets "
' 		dbug(SQL)
		set rsMaxTix = dataconn.execute(SQL)
		if not rsMaxTix.eof then 
' 			dbug("NOT rsMaxTix.eof")
			newID = cInt(rsMaxTix("maxID")) + 1
		else 
' 			dbug("rsMaxTix.eof")
			newID = 1
		end if
		rsMaxTix.close 
		set rsMaxTix = nothing 
' 		dbug("newID: " & newID)
		
		severityID	= request.querystring("severity")
		title			= escapeQuotes(request.querystring("title"))
		reportedBy 	= escapeQuotes(request.querystring("reportedBy"))
		narrative 	= escapeQuotes(request.querystring("narrative"))
		
		SQL = "insert into supportTickets (id, severityID, title, reportedBy, narrative, openedDate, updatedBy, updatedDateTime) " &_
				"values ( " &_
				newID & ", " &_
				severityID & ", " &_
				"'" & title & "', " &_
				"'" & reportedBy & "', " &_
				"'" & narrative & "', " &_
				"GETDATE(), " &_
				session("userID") & ", " &_
				"CURRENT_TIMESTAMP " &_
				") "
		
' 		dbug(SQL)	
		on error resume next 	
		set rsAddTix = dataconn.execute(SQL)
		set rsAddTix = nothing 
' 		dbug("immediately after executing SQL")
		on error goto 0
				
' 		dbug("building out xml...")
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<title>" & title & "</title>"
		xml = xml & "<severityID>" & severityID & "</severityID>"
		xml = xml & "<reportedBy>" & reportedBy & "</reportedBy>"
		xml = xml & "<narrative>" & narrative & "</narrative>"
		
' 		dbug("completing msg...")
		msg = "Ticket added."		
		

	case "delete"
	
		SQL = "update supportTickets set deleted = 1 where id = " & request.querystring("id")
' 		dbug(SQL)
		on error resume next 
		set rsDeleteTix = dataconn.execute(SQL)
		set rsDeleteTix = nothing
		on error goto 0 
		
		xml = xml & "<id>" & request.querystring("id") & "</id>"
		
		msg = "Ticket logically deleted."
	
	 
	case "deleteNote"
	
		SQL = "update supportNotes set deleted = 1 where id = " & request.querystring("id")
' 		dbug(SQL)
		on error resume next 
		set rsDeleteTix = dataconn.execute(SQL)
		set rsDeleteTix = nothing
		on error goto 0 
		
		xml = xml & "<id>" & request.querystring("id") & "</id>"
		
		msg = "Note logically deleted."
	
	 
	case "mod" 

		id 			= request.querystring("id")
		attrName 	= request.querystring("attribute")
		attrValue 	= escapeQuotes(request.querystring("value"))
	
		if attrName = "newNote" then 
			SQL = "select max(id) as maxID from supportNotes "
			set rsMax = dataconn.execute(SQL)
			if not rsMax.eof then 
				if isNull(rsMax("maxID")) then 
					newID = 1
				else 
					newID = cInt(rsMax("maxID")) + 1
				end if
			else 
				newID = 1
			end if
			SQL = "insert into supportNotes (id, ticketID, note, addedBy, addedDateTime ) values (" & newID & ", " & id & ", '" & attrValue & "', " & session("userID") & ", CURRENT_TIMESTAMP) " 
		else 	
			SQL = "update supportTickets set " & attrName & " = '" & attrValue & "' where id = " & id & " "
		end if 
		
' 		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing
		
' 		dbug("update completed")
		msg = attrName & " updated"
	
	 
	case else 

		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"

end select 

xml = xml & "<msg>" & msg & "</msg>"

dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</ticketMaintenance>"

response.write(xml)
%>