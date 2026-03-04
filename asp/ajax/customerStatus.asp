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

dbug("customerStatus maintenance...")

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<customerStatus>"

msg = ""

select case request.querystring("cmd")

	case "maintain"


		customerStatusID 		= request.querystring("customerStatusID")
		customerStatusName 	= escapeQuotes(request.querystring("customerStatusName"))
		customerStatusDesc 	= escapeQuotes(request.querystring("customerStatusDesc"))

		if len(customerstatusID) > 0 then 
			
			newID = customerStatusID
			
			SQL = "update customerStatus set " &_
						"name = '" & customerStatusName & "', " &_
						"description = '" & customerStatusDesc & "' " &_
					"where id = " & newID & " " 
					
			msg = "Customer status updated"
			
		else 
			
			newID = getNextID("customerStatus") 
			
			SQL = "insert into customerStatus (id, name, description, updatedDateTime, updatedBy) " &_
					"values ( " &_
						newID & ", " &_
						"'" & customerStatusName & "', " &_
						"'" & customerStatusDesc & "', " &_
						"CURRENT_TIMESTAMP, " &_
						session("userID") & ") " 
						
			msg = "Customer status updated"

		end if 
		dbug(SQL)
		
		set rs = dataconn.execute(SQL)
		set rs = nothing

		xml = xml & "<id>" & newID & "</id>"			
		xml = xml & "<name>" & customerStatusName & "</name>"			
		xml = xml & "<description>" & customerStatusDesc & "</description>"			
		xml = xml & "<msg>" & msg & "</msg>"			


	case else 

		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"


end select 

userLog(msg)

dbug("operation complete")

xml = xml & "</customerStatus>"
dbug(xml)
response.write(xml)
%>