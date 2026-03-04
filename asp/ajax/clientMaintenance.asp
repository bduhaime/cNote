<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' Copyright (C) 2017-2019, Brad Duhaime. All Rights Reserved.
dbug("start clientMaintenance...")
response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<clientMaintenance>"

select case request.querystring("cmd") 

	case "update"
	
		id 					= request.querystring("id") 
		name 					= request.querystring("name") 
		
		if len(request.querystring("startDate")) > 0 then 
			startDate 		= "'" & request.querystring("startDate") & "'" 
		else 
			startDate	 	= "NULL" 
		end if
		
		if len(request.querystring("endDate")) > 0 then 
			endDate 			= "'" & request.querystring("endDate") & "'" 
		else 
			endDate			= "NULL"
		end if 
		
		clientID 			= request.querystring("clientID") 
		dbName 				= request.querystring("dbName")
		validDomains 		= request.querystring("validDomains")
		
' 		dbug("id: " & id)
		
		if len(id) <= 0 then 
			
			' id is an identity column, so no value required on insert...
			SQL = "insert into clients (clientID, [name], startDate, endDate, databaseName) " &_
					"values ( " &_
						"'" & clientID 		& "', " &_
						"'" & name 				& "', " &_
						startDate 				& ", " &_
						endDate 					& ", " &_
						"'" & dbName 			& "' " &_
					") "

			msg = "Client added"
			
		else 
			
			SQL = "update clients set " 	&_
						"clientID = '" 		& clientID 			& "', " &_
						"[name] = '" 			& name 				& "', " &_
						"startDate = " 		& startDate 		& ", " &_
						"endDate = " 			& endDate 			& ", " &_
						"databaseName = '" 	& dbName 			& "' " &_
					"where id = " & id & " " 
					
			msg = "Client updated"
					
		end if 
		
' 		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		if len(dbName) > 0 then 
			if dbName <> "csuite" then 
				SQL = "update " & dbName & "..customer set validDomains = '" & validDomains & "' where id = 1 " 
				set rsUpdate = dataconn.execute(SQL) 
				set rsUpdate = nothing 
				msg = msg & "; valid domains updated for primary customer" 
			end if
		else 
			msg = msg & "; valid domains could not be save (no dbName)"
		end if



	case "delete" 
	
		id = request.querystring("id") 
		
		SQL = "delete from clients where id = " & id & " " 
		
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 
		
		SQL = "delete from clientUsers where clientID = " & id & " " 
		
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 
				
		msg = "Client deleted"



	case else 
	
' 		dbug("no valid command detected")
	
		msg = "invalid command; no work done"



end select 



dataconn.close 
set dataconn = nothing 

xml = xml & "<msg>" & msg & "</msg>"

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</clientMaintenance>"

response.write(xml)
%>