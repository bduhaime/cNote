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

dbug("product maintenance...")

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<products>"

msg = ""

select case request.querystring("cmd")

	case "update"

	
		id 						= request.querystring("id")
		name						= escapeQuotes(request.querystring("name"))
		description				= escapeQuotes(request.querystring("description"))
		productType				= request.querystring("productType")
		vendor					= request.querystring("vendor")
		focus						= request.querystring("focus")
		coreAnnualQty			= request.querystring("coreAnnualQty")
		advAnnualQty			= request.querystring("advAnnualQty")
		eliteAnnualQty			= request.querystring("eliteAnnualQty")
		availableAloneInd		= request.querystring("availableAloneInd")
	
		if len(id) > 0 then 
			
			newID = id
			
			SQL = "update products set " &_
						"name = '" & name & "', " &_
						"description = '" & description & "', " &_
						"productType = '" & productType & "', " &_
						"vendor = '" & vendor & "', " &_
						"focus = '" & focus & "', " &_
						"coreAnnualQty = " & coreAnnualQty & ", " &_
						"advAnnualQty = " & advAnnualQty & ", " &_
						"eliteAnnualQty = " & eliteAnnualQty & ", " &_
						"availableAloneInd = " & availableAloneInd & ", " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = current_timestamp " &_
					"where id = " & newID & " " 
					
			msg = "Process updated"
			
		else 
			
			newID = getNextID("products") 
			
			SQL = "insert into products (" &_
						"id, " &_
						"name, " &_
						"description, " &_
						"productType, " &_
						"vendor, " &_
						"focus, " &_
						"coreAnnualQty, " &_
						"advAnnualQty, " &_
						"eliteAnnualQty, " &_
						"availableAloneInd, " &_
						"updatedBy, " &_
						"updatedDateTime) " &_
					"values ( " &_
						newID & ", " &_
						"'" & name & "', " &_
						"'" & description & "', " &_
						"'" & productType & "', " &_
						"'" & vendor & "', " &_
						"'" & focus & "', " &_
						coreAnnualQty & ", " &_
						advAnnualQty & ", " &_
						eliteAnnualQty & ", " &_
						availableAloneInd & ", " &_
						"CURRENT_TIMESTAMP, " &_
						session("userID") & ") " 
						
			msg = "Process added"

		end if 
		response.write(SQL)
		
		set rs = dataconn.execute(SQL)
		set rs = nothing

		xml = xml & "<id>" & newID & "</id>"			
		xml = xml & "<name>" & name & "</name>"			
		xml = xml & "<description>" & description & "</description>"			
		xml = xml & "<productType>" & productType & "</productType>"			
		xml = xml & "<vendor>" & vendor & "</vendor>"			
		xml = xml & "<focus>" & focus & "</focus>"			
		xml = xml & "<coreAnnualQty>" & coreAnnualQty & "</coreAnnualQty>"			
		xml = xml & "<advAnnualQty>" & advAnnualQty & "</advAnnualQty>"			
		xml = xml & "<eliteAnnualQty>" & eliteAnnualQty & "</eliteAnnualQty>"			
		xml = xml & "<availableAloneInd>" & availableAloneInd & "</availableAloneInd>"			

		xml = xml & "<msg>" & msg & "</msg>"			


	case else 

		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"


end select 

userLog(msg)

dbug("operation complete")

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</products>"

response.write(xml)
%>