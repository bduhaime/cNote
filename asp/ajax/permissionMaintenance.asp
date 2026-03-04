<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

dbug("start permissionMaintenance...")
response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<permissionMaintenance>"

select case request.querystring("cmd") 

	case "update"
	
		id 				= request.querystring("id") 
		dbug("permissionID = " & id)
		
		attribute 		= request.querystring("attribute")
		dbug("attribute = " & attribute)
		
		setString = ""
		
		select case attribute 
			case "name","description"

				tempValue 	= replace(request.querystring("value"), "&", "&amp;")			
				tempValue	= replace(tempValue,"'","''")
				value			= "'" & tempValue & "'"

				setString = attribute & " = "	& value
				
			case "deleted", "customerUserAllowed"
			
				value = request.querystring("value")
				dbug(attribute & " toggle detected with value = " & value)
			
				if lCase(value) = "on" then 
					value = 0
				else 
					value = 1
				end if

				setString = attribute & " = "	& value

				
			case "csuiteOnly"
			
				value = request.querystring("value")
				dbug(attribute & " toggle detected with value = " & value)
			
				if lCase(value) = "on" then 
					cSuiteValue = 0
					setString = "csuiteOnly = " & cSuiteValue
				else 
					cSuiteValue = 1
					nonCsuiteValue = 0
					setString = "csuiteOnly = " & cSuiteValue & ", nonCsuiteOnly = " & nonCsuiteValue
				end if
				
				tempValue = cSuiteValue

				
			case "nonCsuiteOnly"
			
				value = request.querystring("value")
				dbug(attribute & " toggle detected with value = " & value)
			
				if lCase(value) = "on" then 
					nonCsuiteValue = 0
					setString = "nonCsuiteOnly = " & nonCsuiteValue
				else 
					nonCsuiteValue = 1
					csuiteValue = 0
					setString = "csuiteOnly = " & cSuiteValue & ", nonCsuiteOnly = " & nonCsuiteValue
				end if

				tempValue = nonCsuiteValue
				
			case else 
			
				value	= request.querystring("value")
				setString = attribute & " = "	& value
				tempValue = value

		end select
		
		SQL = "update csuite..permissions set " 	&_
					setString & " " &_
				"where id = " & id & " " 
				
' 		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		msg = "Permission updated"
		
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<attribute>" & attribute & "</attribute>"
		xml = xml & "<value>" & tempValue & "</value>"
		xml = xml & "<setString>" & setString & "</setString>"
		

	case "physicalDelete"

		permissionID = request.querystring("permissionID") 

		SQL = "delete from csuite..permissions where id = " & permissionID & " " 
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL, rowsAffected)
		permissionsDeleted = rowsAffected 
		set rsDelete = nothing 
		
		SQL = "delete from userPermissions where permissionID = " & permissionID & " " 
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL, rowsAffected)
		userPermissionsDeleted = rowsAffected 
		set rsDelete = nothing 
		
		SQL = "delete from rolePermissions where permissionID = " & permissionID & " " 
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL, rowsAffected) 
		rolePermissionsDeleted = rowsAffected
		set rsDelete = nothing 
		
		xml = xml & "<id>" & permissionID & "</id>"
		xml = xml & "<permissionsDeleted>" & permissionsDeleted & "</permissionsDeleted>"
		xml = xml & "<userPermissionsDeleted>" & userPermissionsDeleted & "</userPermissionsDeleted>"
		xml = xml & "<rolePermissionsDeleted>" & rolePermissionsDeleted & "</rolePermissionsDeleted>"
		
		msg = "Permission physically deleted"
		

	
	case "logicalDelete"
	
		permissionID = request.querystring("permissionID") 
		
		SQL = "update csuite..permissions set " &_
					"deleted = 1, " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = current_timestamp " &_
				"where id = " & permissionID & " " 
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing

		xml = xml & "<id>" & permissionID & "</id>"
		
		msg = "Permission logically deleted"
		
		
	
	case else 
	
		dbug("no valid command detected")
	
		msg = "invalid command; no work done"
	

end select 



dataconn.close 
set dataconn = nothing 

xml = xml & "<msg>" & msg & "</msg>"
%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</permissionMaintenance>"

response.write(xml)
%>