<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/md5.asp" -->
<!-- #include file="../includes/randomString.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/smtpParms.asp" -->
<!-- #include file="../includes/validUserDomain.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

'***** USER MAINTENANCE *****
response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<userMaintenance>"

msg = ""

'***********************************************************
sub updateAttribute(user, attribute,value)
'***********************************************************

	xml = xml & "<user id=""" & user & """><" & attribute & ">" & value & "</" & attribute & "></user>"

	valid = true
	if attribute = "username" then
		SQL = "select count(*) as usernameCount from cSuite..users where username = '" & value & "' "
		set rs = dataconn.execute(SQL)
		if rs("usernameCount") > 0 then 			' duplicate username
			valid = false
			xml = xml & "<msg>Duplicate username</msg>"
			xml = xml & "<status>error</status>"
		else										' go ahead with update
			valid = true
		end if
		rs.close
	end if
	
	
	if valid then
		SQL = "update cSuite..users set " & attribute & " = '" & value & "', " &_
				"updatedBy = " & session("userID") & ", " &_
				"updatedDateTime = current_timestamp " &_
				"where id = " & user & " "
		dbug(SQL) 
		
		set rs = dataconn.execute(SQL)
		set rs = nothing
	
		xml = xml & "<msg>" & attribute & " updated</msg>"
		xml = xml & "<status>success</status>"
	end if

	userLog(attribute & " update")
' 	dbug("end of updateAttribute")
end sub


'***********************************************************
sub toggleIndicator(user, indicator)
'***********************************************************

	SQL = "update cSuite..users set " & indicator & " = case when " & indicator & " = 1 then 0 else 1 end where id = " & user & " "
	set rs = dataconn.execute(SQL)
	
	SQL = "select " & indicator & " as updatedValue from cSuite..users where id = " & user & " "
' 	dbug("toggleIndicator, secondary SQL: " & SQL)
	set rs = dataconn.execute(SQL)
	if not rs.eof then 
		updatedValue = rs("updatedValue")
	else
		updatedValue = "not found"
	end if
' 	dbug("updatedValue: " & updatedValue)

	rs.close
	set rs = nothing
	
	
	xml = xml & "<user id=""" & user & """><" & indicator & ">" & updatedValue & "</" & indicator & "></user>"
	xml = xml & "<msg>" & indicator & " indicator updated</msg>"
	xml = xml & "<status>success</status>"

	userLog(indicator & " indicator updated")

end sub


'***********************************************************
sub updateClient(client, user)
'***********************************************************

	SQL = 	"select c.databaseName " &_
				"from cSuite..clientUsers cu " &_
				"join cSuite..clients c on (c.id = cu.clientID) " &_
				"where cu.userID = '" & user & "' and cu.clientID = " & client & " "

' 	dbug("initial query: " & SQL)
	set rs = dataconn.execute(SQL)

	if rs.eof then
		SQL = "insert into cSuite..clientUsers (userID, clientID, updatedBy, updatedDateTime) values (" & user & "," & client & ", " & session("userID") & ", current_timestamp) "
		set rsInsert = dataconn.execute(SQL) 
		set rsInsert = nothing 
		msg = "User added to client"
	else

		if	lCase(rs("databaseName")) <> "csuite" then
			SQL = "delete from " & rs("databaseName") & "..userCustomers where userID = " & user & " " 
			set rsDelete = dataconn.execute(SQL)
		end if 

		SQL = "delete from " & rs("databaseName") & "..userRoles where userID = " & user & " " 		
		set rsDelete = dataconn.execute(SQL)

		SQL = "delete from " & rs("databaseName") & "..userPermissions where userID = " & user & " " 
		set rsDelete = dataconn.execute(SQL)

		SQL = "delete from cSuite..clientUsers where userID = " & user & " and clientID = " & client & " "
		set rsDelete = dataconn.execute(SQL)

		msg = "Client, customers, roles, and permissions removed from user"
		
		set rsDelete = nothing 
		
	end if 	

	rs.close 
	set rs = nothing

	xml = xml & "<user id=""" & user & """><client id=""" & client & """>toggled</client></user>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<status>success</status>"

	userLog(msg)

end sub


'***********************************************************
sub updateRole(user, role)
'***********************************************************

	SQL_1 = 	"select * from userRoles where userID = '" & user & "' and roleID = " & role & " "

	set rs = dataconn.execute(SQL_1)

	if rs.eof then
		sqlUpdateRoles = "insert into userRoles (userID, roleID) values (" & user & "," & role & ") "
		msg = "User added to role"
	else
		sqlUpdateRoles = "delete from userRoles where userID = " & user & " and roleID = " & role & " "
		msg = "User removed from role"
	end if 	

	set rs = dataconn.execute(sqlUpdateRoles)
	set rs = nothing

	xml = xml & "<user id=""" & user & """><role id=""" & role & """>toggled</role></user>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<status>success</status>"

	userLog(msg)

end sub


'***********************************************************
sub updatePermission(user, permission)
'***********************************************************

	SQL_1 = 	"select * from userPermissions where userID = '" & user & "' and permissionID = " & permission & " "
	set rs = dataconn.execute(SQL_1)

	if rs.eof then
		sqlUpdatePermissions = "insert into userPermissions (userID, permissionID) values (" & user & "," & permission & ") "
		msg = "Permission granted to user"
	else
		sqlUpdatePermissions = "delete from userPermissions where userID = " & user & " and permissionID = " & permission & " "
		msg = "Permission revoked from user"
	end if 	

	set rs = dataconn.execute(sqlUpdatePermissions)
	set rs = nothing

	xml = xml & "<user id=""" & user & """><permission id=""" & permission & """>toggled</permission></user>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<attribute>userPermission</attribute>"
	xml = xml & "<value></value>"
	xml = xml & "<status>success</status>"
	
	userLog(msg)

end sub


'***********************************************************
sub updateRolePermission(role, permission)
'***********************************************************

	SQL_1 = 	"select * from rolePermissions where roleID = '" & role & "' and permissionID = " & permission & " "
' 	dbug(SQL_1)
	set rs = dataconn.execute(SQL_1)


	if rs.eof then
		sqlUpdatePermissions = "insert into rolePermissions (roleID, permissionID) values (" & role & "," & permission & ") "
		msg = "Permission granted to role"
	else
		sqlUpdatePermissions = "delete from rolePermissions where roleID = " & role & " and permissionID = " & permission & " "
		msg = "Permission revoked from role"
	end if 	

' 	dbug(sqlUpdatePermissions)
	set rs = dataconn.execute(sqlUpdatePermissions)
	set rs = nothing

	xml = xml & "<role id=""" & role & """><permission id=""" & permission & """>toggled</permission></role>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<attribute>rolePermission</attribute>"
	xml = xml & "<value></value>"
	xml = xml & "<status>success</status>"
	
	userLog(msg)

end sub


'***********************************************************
sub addUserToClient(username, clientID, userID, customerID)
'***********************************************************

	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<username>" & username & "</username>"
	xml = xml & "<clientID>" & clientID & "</clientID>"
	xml = xml & "<customerID>" & customerID & "</customerID>"

	SQL = "select id from cSuite..clients where clientID = '" & clientID & "' "
' 	dbug(SQL)
	
	set rsClient = dataconn.execute(SQL)
	if not rsClient.eof then 
		
' 		dbug("client found, so proceeding to determine if user already associated with client...")

		clientIDNbr = rsClient("id")
		xml = xml & "<clientIDNbr>" & clientIDNbr & "</clientIDNbr>"
		SQL = "select * from cSuite..clientUsers where clientID = " & clientIDNbr & " and userID = " & userID & " "
' 		dbug(SQL)
		set rsUser = dataconn.execute(SQL) 
		if rsUser.eof then 
			
' 			dbug("user is NOT associated with client, so establishing the link...")
			
			if len(customerID) <= 0 then 
				customerID = "NULL"
			end if
		
			SQL = "insert into cSuite..clientUsers (clientID, userID, updatedBy, updatedDateTime) " &_
					"values (" & clientIDNbr & "," & userID & "," & session("userID") & ", current_timestamp) " 
' 			dbug(SQL)
			
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
			xml = xml & "<msg>User added to client</msg>"

			userLog("User added to client")
			
		else 
			
' 			dbug("user is already associated with client, so nothing to do.")
			clientIDNbr = null 
			xml = xml & "<msg>User already associate with this client</msg>"
			
			userLog("User already associate with this client")
			
		end if 
		
		rsUser.close 
		set rsUser = nothing
		
' 		dbug("user is associated with client, now associate with customer...")
		
		SQL = "select * from userCustomers where userID = " & userId & " and customerID = " & customerID & " " 
		set rsUC = dataconn.execute(SQL) 
		if rsUC.eof then 
' 			dbug("associating user (" & userID & ") to customer (" & customerID &")")
			SQL = "insert into userCustomers (userID, customerID, updatedBy, updatedDateTime) " &_
					"values ( " &_
						userID & ", " &_
						customerID & ", " &_
						session("userID") & ", " &_
						"current_timestamp " &_
					") " 
			set rsInsert = dataconn.execute(SQL) 
			set rsInsert = nothing 
		else 
			
			dbug("WARNING: user is already associated with this customer; this is not expected.") 
			
		end if 
			
		

	else 
		
		dbug("client not found, so giving up.")
		
		clientIDNbr = NULL
		xml = xml & "<msg>clientIDNbr could not be found</msg>"
		
		userLog("clientIDNbr could not be found")
			
	end if
	
	rsClient.close 
	set rsClient = nothing

end sub


'***********************************************************
sub CheckUniqueUsername(username, customerID)
'***********************************************************

	SQL = "select id from csuite..users where username = '" & username & "' "
' 	dbug(SQL)
	
	set rsUsr = dataconn.execute(SQL) 
	if rsUsr.eof then 

		feedback = "unique" 
		userID = ""
		
	else 
		
		userID = rsUsr("id")

		SQL = "select * from csuite..clientUsers where userID = " & userID & " and clientID = " & session("clientNbr") & " " 
' 		dbug(SQL)
		set rsCU = dataconn.execute(SQL) 
		if not rsCU.eof then 
			
			' user already in client
			
			if len(customerID) > 0 then 
			
				SQL = "select * from userCustomers where userID = " & userID & " and customerID = " & customerID & " " 
' 				dbug(SQL)

				set rsUC = dataconn.execute(SQL) 
				if not rsUC.eof then  
					if customerID = 1 then 
						feedback = "duplicate - already in this client, already an internal user"
					else 
						feedback = "duplicate - already in this client, already an external user associated with this customer"
					end if
				else 
					feedback = "duplicate - already in this client, not associated with this customer" 
				end if 
				rsUC.close 
				set rsUC = nothing 

			else 
				
				feedback = "duplicate - already in this client, customer association not checked"
				
			end if
				
			
		else 
			
			' user NOT in client 
			feedback = "duplicate - can be added to this client"
			userID = rsUsr("id") 
			
		end if

		rsCU.close 
		set rsCU = nothing 
		
	end if 
	
	rsUsr.close 
	set rsUsr = nothing 

' 	dbug(feedback)
		
	xml = xml & "<username value=""" & username & """ userID=""" & userID & """>" & feedback 
	
	xml = xml & "</username>"
	xml = xml & "<customerID>" & customerID & "</customerID>"

	if validUserDomain(username, customerID, session("dbName")) then 
		xml = xml & "<validUserDomain override=""n/a"">true</validUserDomain>"
	else 
		if userPermitted(59) then 
			xml = xml & "<validUserDomain override=""true"">true</validUserDomain>"
		else 
			xml = xml & "<validUserDomain override=""true"">false</validUserDomain>"
		end if
	end if
		
	
end sub


'***********************************************************
sub deleteUser(user)
'***********************************************************

' 	SQL = "select id from cSuite..clients where clientID = '" & session("clientID") & "' " 
' 	dbug(SQL)
' 	set rsClient = dataconn.execute(SQL)
' 	if not rsClient.eof then 
' 		dbug("delete user from cSuite..clientUsers...")

' 		clientNbr = rsClient("id") 
' 		SQL = "delete from cSuite..clientUsers where clientID = " & clientNbr & " and userID = " & user & " " 
		SQL = "delete from cSuite..clientUsers where userID = " & user & " and clientID = " & session("clientNbr")
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL, rowsAffected)
		clientsDeleted = rowsAffected
		
		SQL = "delete from userPermissions where userID = " & user & " "
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL, rowsAffected)
		userPermissionsDeleted = rowsAffected

		SQL = "delete from userRoles where userID = " & user & " " 		
' 		dbug(SQL)
		set rsDelete = dataconn.execute(SQL, rowsAffected)
		userRolesDeleted = rowsAffected
		
		if cInt(session("clientNbr")) <> 1 then 
			SQL = "delete from userCustomers where userID = " & user & " " 
' 			dbug(SQL)
			set rsDelete = dataconn.execute(SQL, rowsAffected)
			userCustomersDeleted = rowsAffected
		end if
		
		set rsDelete = nothing 

' 	else 
' 		dbug("clientID not found on cSuite..clients")
' 	end if
' 	rsClient.close 
' 	set rsClient = nothing 
		
	xml = xml & "<user id=""" & user & """><deleted>True</deleted></user>"
	xml = xml & "<clientsDeleted>" & clientsDeleted & "</clientsDeleted>"
	xml = xml & "<userPermissionsDeleted>" & userPermissionsDeleted & "</userPermissionsDeleted>"
	xml = xml & "<userRolesDeleted>" & userRolesDeleted & "</userRolesDeleted>"
	xml = xml & "<userCustomersDeleted>" & userCustomersDeleted & "</userCustomersDeleted>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<status>success</status>"
	
	userLog(msg)
			
' 	dbug("end of deleteUser")

end sub


'***********************************************************
sub undeleteUser(user)
'***********************************************************

	SQL = "update cSuite..users set deleted = 0, " &_
			"updatedBy = " & session("userID") & ", " &_
			"updatedDateTime = current_timestamp " &_
			"where id = " & user & " "
	set rs = dataconn.execute(SQL)
	set rs = nothing
	
	msg = "User logically undeleted"

	xml = xml & "<user id=""" & user & """><deleted>False</deleted></user>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<status>success</status>"
	
	userLog(msg)
			
end sub


'***********************************************************
sub addUser(user)
'***********************************************************

	username 						= request.querystring("username") 

	if len(request.querystring("customer")) > 0 then 
		customerID 						= request.querystring("customer") 
	else 
		customerID						= "NULL" 
	end if

	
	' check if username already exists....
	SQL = "select * from csuite..users where username = '" & username & "' " 
	dbug(SQL)
	
	set rsUsr = dataconn.execute(SQL) 
	
	if rsUsr.eof then 

		firstName 						= replace(request.querystring("firstName"),"'","''")
		lastName 						= replace(request.querystring("lastName"),"'","''")
		userID							= request.querystring("userID")
	
		
		title								= "'" & replace(request.querystring("title"),"'","''") & "'" 
		
		const active 					= 1
		const resetPasswordOnLogin = 1
	
		tempPassword = randomString()
		tempPasswordHash = md5(tempPassword)
		
		newID 		= getNextID("cSuite..users")
		
		SQL = "insert into cSuite..users (id, username, passwordHash, firstName, lastName, active, resetPasswordOnLogin, title, updatedBy, updatedDateTime) " &_
				"values (" &_
					newID & ",'" &_
					username & "','" &_ 
					tempPasswordHash & "','" &_ 
					firstName & "','" &_ 
					lastName & "'," &_ 
					active & "," &_ 
					resetPasswordOnLogin & "," &_
					title & "," &_
					session("userID") & "," &_
					"CURRENT_TIMESTAMP " &_
				") "
				
		dbug(SQL)
				
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
	
		msg = "User " & trim(username) & " added"
	
	else 

		newID = rsUsr("id")		
		msg = "User " & trim(username) & " already exists"

	end if
	
	rsUsr.close 
	set rsUsr = nothing 
	
	
	' Now that the user is created in cSuite..users, automatically add a corresponding row into cSuite..clientUsers for the "current" client...
	' start by getting the id# corresponding to session("clientID")...
	SQL = "select id from cSuite..clients where clientID = '" & session("clientID") & "' "
' 	dbug(SQL)
	set rsClient = dataconn.execute(SQL)
	if not rsClient.eof then 
		clientNbr = rsClient("id")
	else 
		clientNbr = "NULL"
	end if 
	rsClient.close 
	set rsClient = nothing
	
	' determine if user is already associated with client....
	
	SQL = "select * from csuite..clientUsers where clientID = " & clientNbr & " and userID = " & newID & " " 
' 	dbug(SQL)
	
	set rsCU = dataconn.execute(SQL) 
	
	if not rsCU.eof then 
' 		dbug("user already associated with client")
		msg = "User already associated with client"
	else 
' 		dbug("user is not associated with client, creating association...")
		SQL = "insert into cSuite..clientUsers (clientID, userID, updatedBy, updatedDateTime) " &_
				"values (" & clientNbr & "," & newID & "," & session("userID") & ", current_timestamp) "
				
' 		dbug(SQL) 
		
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing
		msg = "User associated with client"
	end if
	rsCU.close 
	set rsCU = nothing
	
		

' 	dbug("request.querystring('customer'): " & request.querystring("customer"))
' 	dbug("customerID: " & customerID)
' 	dbug("session('clientID'): " & session("clientID")) 

	if lCase(session("clientID")) <> "csuite" then
		
		on error resume next 		
		
' 			dbug("associating user to customer...")
	
			SQL = "insert into userCustomers (userID, customerID, updatedBy, updatedDateTime) " &_
					"values (" &_
						newID & ", " &_
						customerID & ", " &_
						session("userID") & ", " &_
						"current_timestamp " &_
					") " 
		
' 			dbug(SQL)			
			set rsUC = dataconn.execute(SQL) 
			set rsUC = nothing 
			
			if err.number <> 0 then 
				msg = "Problem encountered associating user to customer"
			else 
				msg = "User associated with customer"
			end if
			
		on error goto 0

	end if 
	
	xml = xml & "<userID>" & newID & "</userID>"
	xml = xml & "<username>" & username & "</username>"
	xml = xml & "<firstName>" & firstName & "</firstName>"
	xml = xml & "<lastName>" & lastName & "</lastName>"
	xml = xml & "<active>" & active & "</active>"
	xml = xml & "<resetPasswordOnLogin>" & resetPasswordOnLogin & "</resetPasswordOnLogin>"
	xml = xml & "<customerID>" & customerID & "</customerID>"
	xml = xml & "<title>" & title & "</title>"
	
	' all done. Now send out an email...

	
' 	set objmail		= createobject("CDO.Message")
	objmail.from	= systemControls("Generic Email From Address")
	objmail.to		= username
	objmail.subject	= "New User Credentials"
	
	objmail.HTMLbody =	"<html>" &_
									"<body>" &_ 
										"Welcome to cNote&trade;!<br><br>" &_
										"A new account has been created for you on cNote&trade;, the Business Optimization Platform. Here is your temporary password:<br><br>Password: " & tempPassword &_
										"<br><br>" &_ 
										"Click <a href=""http://" & systemControls("server name") & "/login.asp"">here</a> to login." &_
										"<br><br>This message was generated at " & now() & " Central Time" &_
									"</body>" &_
								"</html>"
		
	smtpParms


	if systemControls("Send system generated email") = "true" then 
' 		dbug("prior to .send")
		objmail.send
' 		dbug("after .send")
		set objmail = Nothing
' 		dbug("objmail object destroyed")
	else 
		dbug("New user email generated but not sent because 'Send system generated email' is off")
	end if

' 	dbug("insert of new user complete, executing server.transfer...")
' 	server.transfer "userList.asp"
' 	dbug("post server.transfer...")
	xml = xml & "<email>sent</email>"
	xml = xml & "<msg>" & msg & "</msg>"
	
	userLog(msg)
			
	
end sub



'***********************************************************
sub updateUser (userID) 
'***********************************************************

	firstName 	= replace(request.querystring("firstName"),"'","''")
	lastName 	= replace(request.querystring("lastName"),"'","''")
	title 		= replace(request.querystring("title"),"'","''")
	
	SQL = "update csuite..users set " &_
				"firstName = '" & firstName & "', " &_
				"lastName = '" & lastName & "', " &_
				"title = '" & title & "' " &_
			"where id = " & userID & " " 
			
' 	dbug(SQL)
	
	set rsUpdate = dataconn.execute(SQL) 
	set rsUpdate = nothing 
	
	msg = "User updated" 
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<firstName>" & firstName & "</firstName>"
	xml = xml & "<lastName>" & lastName & "</lastName>"
	xml = xml & "<title>" & title & "</title>"
	xml = xml & "<msg>" & msg & "</msg>"

	userLog(msg)
			
end sub 



'***********************************************************
sub updateCustomer (userID, customerID) 
'***********************************************************

	SQL = "update csuite..clientUsers " &_
			"set customerID = " & customerID & " " &_
			"where userID = " & userID & " " &_
			"and clientID = " & session("clientNbr") & " " 
			
' 	dbug(SQL) 
	
	set rsUpdate = dataconn.execute(SQL) 
	set rsUpdate = nothing 
	
	msg = "Company updated"
	
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<customerID>" & customerID & "</customerID>"
	xml = xml & "<clientNbr>" & session("clientNbr") & "</clientNbr>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<status>success</status>"

	userLog(msg)	
	
end sub


'***********************************************************
sub customerUser (userID, customerID) 
'***********************************************************

	SQL = "select * from userCustomers where userID = " & userID & " and customerID = " & customerID & " " 
' 	dbug(SQL)
	set rsCU = dataconn.execute(SQL)
	if not rsCU.eof then 
		SQL = "delete from userCustomers where userID = " & userID & " and customerID = " & customerID & " "
		msg = "User disassociated from customer"
	else 
		SQL = "insert into userCustomers (userID, customerID) " &_
				"values (" & userID & "," & customerID & ") " 
		msg = "User associated to customer"
	end if 

	rsCU.close 
	set rsCU = nothing 
	
	set rsUpdate = dataconn.execute(SQL)
	set rsUpdate = nothing 
	
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<customerID>" & customerID & "</customerID>"
	xml = xml & "<msg>" & msg & "</msg>"

	userLog(msg)
			
end sub



'***********************************************************
sub toggleInternalUser(userID) 
'***********************************************************

	SQL = "select * from  userCustomers where userID = " & userID & " and customerID = 1 " 
	set rsIU = dataconn.execute(SQL) 
	if not rsIU.eof then 
		sqlUpdate = "delete from userCustomers where userID = " & userID & " and customerID = 1 " 
		set rsUpdate = dataconn.execute(sqlUpdate)
		set rsUpdate = nothing 
		iuStatus = "false"
	else 
		sqlUpdate = "insert into userCustomers (userID, customerID) values (" & userID & ", 1) "
		set rsUpdate = dataconn.execute(sqlUpdate)
		set rsUpdate = nothing 
		sqlUpdate = "delete from userCustomers where userID = " & userID & " and customerID <> 1 " 
		iuStatus = "true"
		set rsUpdate = dataconn.execute(sqlUpdate)
		set rsUpdate = nothing 
	end if
	rsIU.close 
	set rsIU = nothing 
	
	
	
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>" & iuStatus & "</status>"
	xml = xml & "<msg>Internal user status updated</msg>"

	userLog("Internal user status updated")
			
end sub 


'***********************************************************
sub ToggleAllUserClients(userID) 
'***********************************************************

	SQL = "select * from csuite..clientUsers where userID = " & userID & " " 
	set rsInit = dataconn.execute(SQL)
	
	if rsInit.eof then
		' insert all 
		SQL = "select id from csuite..clients " 
		set rsClients = dataconn.execute(SQL)
		while not rsClients.eof 
			SQL = "insert into csuite..clientsUsers (clientID, userID) values (" & rsClients("id") & "," & userID & ") "
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
			rsClients.movenext 
		wend 
		rsClients.close 
		set rsClients = nothing 
		msg = "All clients added"
		
	else 
		' delete all 
		SQL = "delete from csuite..clientUsers where userID = " & userID & " " 
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 
		msg = "All clients removed"
		
	end if 
	
	rsInit.close 
	set rsInit = nothing 
	
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<msg>" & msg & "</msg>"
	
	userLog(msg)
			
end sub 


'***********************************************************
sub addAllClients(userID) 
'***********************************************************

	xml = xml & "<clients>"
	
	SQL = "select id from csuite..clients " 

	set rsClients = dataconn.execute(SQL)

	while not rsClients.eof 
	
		SQL = "select userID from csuite..clientUsers where clientID = " & rsClients("id") & " and userID = " & userID & " " 
		set rsCU = dataconn.execute(SQL)
		if rsCU.eof then 
			SQL = "insert into csuite..clientUsers (clientID, userID) values (" & rsClients("id") & "," & userID & ") "
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
			xml = xml & "<client id=""" & rsClients("id") & """>Added to user</client>"
		else 
			xml = xml & "<client id=""" & rsClients("id") & """>already present for user</client>"
		end if
		rsCU.close 
		set rsCU = nothing 
		
		rsClients.movenext 
	wend 

	rsClients.close 
	set rsClients = nothing 
	xml = xml & "</clients>"


	msg = "All missing clients added"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	
	userLog(msg)
			
end sub



'***********************************************************
sub removeAllClients(userID)
'***********************************************************

	xml = xml & "<clients>"

	SQL = "select c.id, c.clientID, c.databaseName " &_
			"from csuite..clientUsers cu " &_
			"join csuite..clients c on (c.id = cu.clientID) " &_
			"where cu.userID = " & userID & " " 
	
' 	dbug(SQL)
	
	set rsCU = dataconn.execute(SQL) 
	
	while not rsCU.eof 
	
		xml = xml & "<client clientID=""" & rsCU("id") & """>"
	
		if rsCU("databaseName") <> "csuite" then 
			SQL = "delete from " & rsCU("databaseName") & "..userCustomers where userID = " & userID & " " 
			set rsDeleteCusts = dataconn.execute(SQL)
			set rsDeleteCusts = nothing 
			xml = xml & "<customers>deleted okay</customers>"
		end if
		
		SQL = "delete from " & rsCU("databaseName") & "..userRoles where userID = " & userID & " " 
		set rsDeleteRoles = dataconn.execute(SQL)
		set rsDeleteRoles = nothing 
		xml = xml & "<roles>deleted okay</roles>"
		
		SQL = "delete from " & rsCU("databaseName") & "..userPermissions where userID = " & userID & " " 
		set rsDeletePerms = dataconn.execute(SQL) 
		set rsDeletePerms = nothing 
		xml = xml & "<permissions>deleted okay</permissions>"
		
		SQL = "delete from csuite..clientUsers where clientID = " & rsCU("id") & " and userID = " & userID & " " 
		set rsDeleteClients = dataconn.execute(SQL) 
		set rsDeleteClients = nothing 
		xml = xml & "<clientMsg>deleted okay</clientMsg>"
	
		xml = xml & "</client>" 
		
		rsCU.movenext 
		
	wend 
	
	rsCU.close 
	set rsCU = nothing 

	msg = "All clients, customer, roles, and permissions removed"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "</clients>"

	userLog(msg)
			
end sub 



	
'***********************************************************
sub addAllCustomers(userID) 
'***********************************************************

	xml = xml & "<customers>"
	
	SQL = "select id " &_
			"from customer_view c " &_
			"where (c.deleted = 0 or c.deleted is null) " &_
			"and id <> 1 " 

' 	dbug(SQL)
	set rsCust = dataconn.execute(SQL)

	while not rsCust.eof 
	
		SQL = "select userID from userCustomers " &_
				"where customerID = " & rsCust("id") & " " &_
				"and userID = " & userID & " " 
' 		dbug(SQL)
		set rsCU = dataconn.execute(SQL)
		if rsCU.eof then 
			SQL = "insert into userCustomers (customerID, userID) values (" & rsCust("id") & "," & userID & ") "
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
			xml = xml & "<customer id=""" & rsCust("id") & """>Added to user</customer>"
		else 
			xml = xml & "<customer id=""" & rsCust("id") & """>already present for user</customer>"
		end if
		rsCU.close 
		set rsCU = nothing
		
		rsCust.movenext 
	wend 

	rsCust.close 
	set rsCust = nothing 
	xml = xml & "</customers>"


	msg = "All missing customers added"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	
	userLog(msg)
			
end sub 


'***********************************************************
sub removeAllCustomers(userID)
'***********************************************************

	xml = xml & "<customers>"

	SQL = "delete from userCustomers " &_
			"where userID = " & userID & " " 
			
	set rsDelete = dataconn.execute(SQL) 
	set rsDelete = nothing 

	msg = "All customers removed"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "</customers>"

	userLog(msg)
			
end sub 



'***********************************************************
sub addAllRoles(userID) 
'***********************************************************

	xml = xml & "<roles>"
	
	SQL = "select id " &_
			"from roles " &_
			"where (deleted = 0 or deleted is null) " 

' 	dbug(SQL)
	set rsRoles = dataconn.execute(SQL)

	while not rsRoles.eof 
	
		SQL = "select userID from userRoles " &_
				"where roleID = " & rsRoles("id") & " " &_
				"and userID = " & userID & " " 
' 		dbug(SQL)
		set rsUR = dataconn.execute(SQL)
		if rsUR.eof then 
			SQL = "insert into userRoles (userID, roleID) values (" & userID & "," & rsRoles("id") & ") "
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
			xml = xml & "<role id=""" & rsRoles("id") & """>Added to user</role>"
		else 
			xml = xml & "<role id=""" & rsRoles("id") & """>already present for user</role>"
		end if
		rsUR.close 
		set rsUR = nothing 
		rsRoles.movenext 
	wend 

	rsRoles.close 
	set rsRoles = nothing 
	xml = xml & "</roles>"


	msg = "All missing roles added"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	
	userLog(msg)
			
end sub 


'***********************************************************
sub removeAllRoles(userID)
'***********************************************************

	xml = xml & "<roles>"

	SQL = "delete from userRoles where userID = " & userID & " " 
	set rsDelete = dataconn.execute(SQL) 
	set rsDelete = nothing 

	msg = "All roles removed"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "</roles>"

	userLog(msg)
			
end sub 



'***********************************************************
sub addAllPermissions(userID) 
'***********************************************************

	xml = xml & "<permissions>"
	
	SQL = "select id " &_
			"from csuite..permissions " &_
			"where (deleted = 0 or deleted is null) " 

' 	dbug(SQL)
	set rsPerm = dataconn.execute(SQL)

	while not rsPerm.eof 
	
		SQL = "select userID from userPermissions " &_
				"where permissionID = " & rsPerm("id") & " " &_
				"and userID = " & userID & " " 
' 		dbug(SQL)
		set rsUP = dataconn.execute(SQL)
		if rsUP.eof then 
			SQL = "insert into userPermissions (userID, permissionID) values (" & userID & "," & rsPerm("id") & ") "
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
			xml = xml & "<permission id=""" & rsPerm("id") & """>Added to user</permission>"
		else 
			xml = xml & "<permission id=""" & rsPerm("id") & """>already present for user</permission>"
		end if
		rsUP.close 
		set rsUP = nothing 
		rsPerm.movenext 
	wend 

	rsPerm.close 
	set rsPerm = nothing 
	xml = xml & "</permissions>"


	msg = "All missing permissions added"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"
	
	userLog(msg)
			
end sub 


'***********************************************************
sub removeAllPermissions(userID)
'***********************************************************

	xml = xml & "<permissions>"

	SQL = "delete from userPermissions where userID = " & userID & " " 
	set rsDelete = dataconn.execute(SQL) 
	set rsDelete = nothing 

	xml = xml & "</permissions>"


	msg = "All permissions removed"
		
	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>" & msg & "</msg>"

	userLog(msg)
			
end sub 



'***********************************************************
sub ToggleUserPageFooter(footerChecked)
'***********************************************************

	xml = xml & "<userPageFooter>"

	SQL = "update csuite..users " &_
			"set showFooter = " & footerChecked & " " &_
			"where id = " & session("userID") & " "

	set rsUpdate = dataconn.execute(SQL) 
	set rsUpdate = nothing 

	xml = xml & "<userID>" & session("userID") & "</userID>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>Show footer preference toggled</msg>"

	xml = xml & "</userPageFooter>"

	userLog("Show footer preference toggled")
			
end sub 


'***********************************************************
sub updateUserProfile()
'***********************************************************

	xml = xml & "<userProfile>"

	firstName 	= replace(request.querystring("firstName"),"'","''")
	lastName 	= replace(request.querystring("lastName"),"'","''")
	title 		= replace(request.querystring("title"),"'","''")
	
	SQL = "update csuite..users set " &_
				"firstName = '" & firstName & "', " &_
				"lastName = '" & lastName & "', " &_
				"title = '" & title & "' " &_
			"where id = " & session("userID") & " " 
			
' 	dbug(SQL)
	
	set rsUpdate = dataconn.execute(SQL) 
	set rsUpdate = nothing 
	
	xml = xml & "<userID>" & session("userID") & "</userID>"
	xml = xml & "<firstName>" & request.querystring("firstName") & "</firstName>"
	xml = xml & "<lastName>" & request.querystring("lastName") & "</lastName>"
	xml = xml & "<title>" & request.querystring("title") & "</title>"
	xml = xml & "<status>okay</status>"
	xml = xml & "<msg>User profile updated</msg>"

	xml = xml & "</userProfile>"

	userLog("User profile updated")
			
end sub 




'***********************************************************
sub updatePassword()
'***********************************************************

	xml = xml & "<updatePassword>"

	oldHash 		= request.querystring("old")
	newHash 		= request.querystring("new")
	confirmHash	= request.querystring("confirm")
	
	' check length of all hashes on the querystring...
	if len(oldHash) = 32 then 
		if len(newHash) = 32 then 
			if len(confirmHash) = 32 then 
				proceed = true 
			else 
				proceed = false 
' 				dbug("'confirmation' hash is the wrong length")
				reasonCode = 1
			end if 
		else 
			proceed = false 
' 			dbug("'new' hash is the wrong length")
			reasonCode = 2
		end if
	else 
		proceed = false 
' 		dbug("'old' hash is the wrong length")
		reasonCode = 3
	end if
	
	
	' ensure the 'old' hash on the request is the current passwordHash for the user...
	if proceed then 
		SQL = "select count(*) as userCount from csuite..users where id = " & session("userID") & " and passwordHash = '" & oldHash & "' " 
		set rsOld = dataconn.execute(SQL) 
		if not rsOld.eof then 
			if rsOld("userCount") <> 1 then 
				proceed = false
' 				dbug("session('userID') and oldHash combination is ambiguous") 
				reasonCode = 4
			end if
		else 
			proceed = false 
' 			dbug("session('userID') and oldHash combination resulted in an unexpected empty recordset") 
			reasonCode = 5
		end if
	end if 
	
	' ensure that the newHash is not the same as the old hash...
	
	if newHash = oldHash then 
		proceed = false 
' 		dbug("newHash and oldHash are the same")
		reasonCode = 6
	end if 
	
	
	' ensure that the newHash and confirmHash match...
	if newHash <> confirmHash then 
		proceed = false 
' 		dbug("newHash and confirmHash do not match")
		reasonCode = 7
	end if 
	
	
	if proceed then 
		
		SQL = "update csuite..users set " &_
					"passwordHash = '" & newHash & "', " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = current_timestamp " &_
				"where id = " & session("userID") & " " 
				
' 		dbug(SQL) 
		set rsUpdatePass = dataconn.execute(SQL) 
		set rsUpdatePass = nothing 
		
		status = "okay"
		msg = "Password updated" 
		reasonCode = 0
		
	else 
		
		status = "fail"
		msg = "Password could not be updated"
		
	end if
	
	xml = xml & "<userID>" & session("userID") & "</userID>"
	xml = xml & "<status>" & status & "</status>"
	xml = xml & "<reasonCode>" & reasonCode & "</reasonCode>"
	xml = xml & "<msg>" & msg & "</msg>"

	xml = xml & "</updatePassword>"

	userLog("User password updated")
			
end sub 



'**********************************************************************************************************************
sub updateDefaultClient
'**********************************************************************************************************************
	
	xml = xml & "<updateDefaultClient>"
	
	userID 		= request.querystring("userID") 
	clientID 	= request.querystring("clientID")
	

	
	SQL = "update csuite..clientUsers set " &_
				"userDefault = null " &_
			"where userID = " & userID & " " 			
	set rsUpdate = dataconn.execute(SQL) 
	
	
	
	SQL = "update csuite..clientUsers set " &_
				"userDefault 		= 1, " &_
				"updatedBy 			= " & session("userID") & ", " &_
				"updatedDateTime 	= current_timestamp " &_
			"where clientID 	= " & clientID & " " &_
			"and userID			= " & userID & " " 
			
	set rsUpdate = dataconn.execute(SQL) 
	set rsUpdate = nothing 

	xml = xml & "<userID>" & userID & "</userID>"
	xml = xml & "<clientID>" & clientID & "</clientID>"
	xml = xml & "<msg>Default client updated</msg>"
	
	xml = xml & "</updateDefaultClient>"
	
	
end sub



'**********************************************************************************************************************
sub getCustomerManagers
'**********************************************************************************************************************
	
	xml = xml & "<getCustomerManagers>"
	
	managerTypeID = request.querystring("managerTypeID")

	xml = xml & "<managerTypeID>" & managerTypeID & "</managerTypeID>"
	
	SQL = "select " &_
				"u.username, " &_
				"concat(u.firstName, ' ', u.lastName) as fullName, " &_
				"m.customerID, " &_
				"m.startDate, " &_
				"m.endDate, " &_
				"c.name as customerName " &_
			"from customerManagers m " &_
			"join csuite..users u on (u.id = m.userID) " &_
			"left join customer_view c on (c.id = m.customerID) " &_
			"where managerTypeID = " & managerTypeID & " " 
			
' 	dbug(SQL) 
	
	xml = xml & "<customerManagers>"
	
	set rsCM = dataconn.execute(SQL) 
	while not rsCM.eof 
	
		xml = xml & "<customerManager>"
		xml = xml & 	"<user id=""" & trim(rsCM("username")) & """>" & rsCM("fullName") & "</user>" 
		xml = xml & 	"<customer id=""" & rsCM("customerID") & """><![CDATA["& rsCM("customerName") & "]]></customer>" 
		xml = xml & 	"<startDate>" & rsCM("startDate") & "</startDate>"
		xml = xml & 	"<endDate>" & rsCM("endDate") & "</endDate>"
		xml = xml & "</customerManager>"
		
		rsCM.movenext 
		
	wend 
	
	rsCM.close 
	set rsCM = nothing 

	xml = xml & "</customerManagers>"
	
	
	xml = xml & "</getCustomerManagers>"


end sub

	

'**********************************************************************************************************************
'**********************************************************************************************************************
'**********************************************************************************************************************
'**********************************************************************************************************************


select case request.querystring("cmd")
	case "addUser"
	
		set objmail		= createobject("CDO.Message")
		call addUser(request.querystring("username"))
	
	case "update"

		select case request.querystring("attribute")

			case "active","locked","resetPasswordOnLogin","deleted"
				call toggleIndicator(request.querystring("user"),request.querystring("attribute"))

			case "client"
				call updateClient(request.querystring("client"), request.querystring("user"))

			case "role"
				call updateRole(request.querystring("user"),request.querystring("role"))

			case "permission"
				call updatePermission(request.querystring("user"),request.querystring("permission"))

			case "rolePermission"
				call updateRolePermission(request.querystring("role"),request.querystring("permission"))
				
			case "customerID"
				call updateCustomer(request.querystring("user"),request.querystring("value"))

			case else
				call updateAttribute(request.querystring("user"),request.querystring("attribute"),request.querystring("value"))

		end select

		
	case "uniqueUsername"
		call checkUniqueUsername(request.querystring("username"),request.querystring("customerID"))
		
	case "addUserToClient"
		call addUserToClient(request.querystring("username"), request.querystring("clientID"), request.querystring("userID"), request.querystring("customerID"))
		
	case "deleteUser"
		call deleteUser(request.querystring("user"))
		
	case "updateUser"
		call updateUser(request.querystring("userID"))
		
	case "customerUser"
		call customerUser(request.querystring("userID"), request.querystring("customerID")) 
		
	case "toggleInternalUser"
		call toggleInternalUser(request.querystring("userID"))
		
	case "addAllClients"
		call addAllClients(request.querystring("userID"))
		
	case "removeAllClients"
		call removeAllClients(request.querystring("userID"))
		
	case "addAllCustomers"
		call addAllCustomers(request.querystring("userID"))
		
	case "removeAllCustomers"
		call removeAllCustomers(request.querystring("userID"))
		
	case "addAllRoles"
		call addAllRoles(request.querystring("userID"))
		
	case "removeAllRoles"
		call removeAllRoles(request.querystring("userID"))
		
	case "addAllPermissions"
		call addAllPermissions(request.querystring("userID"))
		
	case "removeAllPermissions"
		call removeAllPermissions(request.querystring("userID"))
		
	case "ToggleUserPageFooter"
		call ToggleUserPageFooter(request.querystring("footerChecked"))
		
	case "updateUserProfile"
		call updateUserProfile()
		
	case "updatePassword"
		call updatePassword()
		
		
	case "updateDefaultClient"
		call updateDefaultClient()
	
	case "getCustomerManagers" 
		call getCustomerManagers()
		
	case else 
		dbug("cmd not recognized")
	
end select 

dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</userMaintenance>"

response.write(xml)
%>