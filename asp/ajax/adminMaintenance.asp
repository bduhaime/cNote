<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2020, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<adminMaintenance>"

dbug("adminMaintenance: cmd: " & request.querystring("cmd"))

select case request.querystring("cmd")

	'====================================================================================================================
	case "deleteCustomerManagerType"
	'====================================================================================================================

		managerTypeID = request.querystring("managerTypeID") 
		
		if managerTypeID <> 0 then 
			
			SQL = "select count(*) as inUseCount from customerManagers where managerTypeID = " & managerTypeID & " " 
			
			set rsIUC = dataconn.execute(SQL) 
			if not rsIUC.eof then 
				if cInt(rsIUC("inUseCount")) > 0 then 
					isInUse = true 
				else 
					isInUse = false 
				end if
			else 
				isInUse = false
			end if 
			rsIUC.close 
			set rsIUC = nothing 

			if not isInUse then 

		' 		SQL = "delete from customerManagerTypes where id = " & managerTypeID & " " 
				SQL = "update customerManagerTypes set deleted = 1 where id = " & managerTypeID & " " 
		
				dbug(SQL) 
				
				set rsDelete = dataconn.execute(SQL) 
				set rsDelete = nothing 
				
				msg = "Customer Manager Type deleted"
				
			else 
				
				msg = "Customer Manager Type in use"
				
			end if
		
		else 
			
			msg = "CMT Not Deleted due to special logic"
			
		end if 

		xml = xml & "<isInUse>" & isInUse & "</isInUse>"
		xml = xml & "<msg>" & msg & "</msg>" 		
		


	'====================================================================================================================
	case "updateCustomerManagerType" 
	'====================================================================================================================
	
		managerTypeID 		= request.querystring("managerTypeID")
		managerTypeName 	= "'" & request.querystring("managerTypeName") & "'"
		
		SQL = "update customerManagerTypes set " &_
					"name = " & managerTypeName & ", " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = current_timestamp " &_
				"where id = " & managerTypeID & " " 
				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 

		xml = xml & "<msg>Customer manager type updated</msg>" 		
		
		

	'====================================================================================================================
	case "newCMT" 
	'====================================================================================================================

		name = "'" & request.querystring("name") & "'" 
		newID = getNextID("customerManagerTypes") 
		
		SQL = "insert into customerManagerTypes (id, name, updatedBy, updatedDateTime) " &_
				"values ( " &_
					newID & ", " &_
					name & ", " &_
					session("userID") & ", " &_
					"current_timestamp " &_
				") " 
				
		set rsInsert = dataconn.execute(SQL) 
		set rsInsert = nothing 
		
		xml = xml & "<msg>Customer manager type added</msg>"

	
	
	'====================================================================================================================
	case "updateRole" 
	'====================================================================================================================

		roleID 		= request.querystring("roleID")
		attribute 	= request.querystring("attribute") 
		value			= replace(request.querystring("value"), "'", "''")
		
		if attribute = "name" then 
			value = "'" & value & "'" 
		end if 

		SQL = "update roles set " &_
					attribute & " = "	& value & " " &_
				"where id = " & roleID & " " 
				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<msg>Role updated</msg>"


	
	'====================================================================================================================
	case else 
	'====================================================================================================================
	
		xml = xml & "<msg>Unrecognized command</msg>" 		

		

end select 

userLog(msg)


dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</adminMaintenance>"


response.write(xml)	

%>