<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

response.contentType = "text/xml"
xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<customerImplementations>" 

select case request.querystring("cmd")

	'====================================================================================================================
	case "updateImplementation" 
	'====================================================================================================================
	
		implementationID			= request("implementationID")
		customerID					= request("customerID")
		
		if len(request("startDate")) > 0 then 
			if isDate(request("startDate")) then 
				startDate				= "'" & request("startDate") & "'"
			else 
				startDate				= "NULL"
			end if 
		else 
			startDate					= "NULL"
		end if

		if len(request("endDate")) > 0 then 
			if isDate(request("endDate")) then 
				endDate				= "'" & request("endDate") & "'"
			else 
				endDate				= "NULL"
			end if 
		else 
			endDate					= "NULL"
		end if

		if len(request("name")) > 0 then 
			name						= "'" & request("name") & "'"
		else 
			name						= "NULL"
		end if
		
		
		if len(implementationID) > 0 then 
			
			xml = xml & "<implementationID>" & implementationID & "</implementationID>"
			
			SQL = "update customerImplementations set " &_
						"name = " 						& name			 				& ", " 	&_
						"startDate = " 				& startDate			 			& ", " 	&_
						"endDate = " 					& endDate			 			& ", " 	&_
						"updatedBy = " 				& session("userID") 			& ", "	&_
						"updatedDateTime = CURRENT_TIMESTAMP, " 								&_
						"customerID = " 				& customerID					& " "		&_
					"where id = " & implementationID 								& " " 
					
			msg = "Customer implementation updated"
						
			
		else 
			
			implementationID = getNextID("customerImplementations") 
			
			xml = xml & "<implementationID>" & implementationID & "</implementationID>"

			SQL = "insert into customerImplementations (id, name, startDate, endDate, updatedBy, updatedDateTime, customerID) " &_
					"values ( " 								&_
						implementationID 			& ", " 	&_
						name 							& ", " 	&_
						startDate 					& ", " 	&_
						endDate 						& ", " 	&_
						session("userID") 		& ", " 	&_
						"CURRENT_TIMESTAMP, " 				&_
						customerID 					& ") "
						
			msg = "Customer implementation added"
						
			
		end if

		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<msg>" & msg & "</msg>"



	'====================================================================================================================
	case "deleteImplementation" 
	'====================================================================================================================

		implementationID			= request("id")
		
		SQL = "update customerImplementations set deleted = 1 where id = " & implementationID & " " 
	
		dbug(SQL)
		
		set rsDelete = dataconn.execute(SQL) 
		
		set rsDelete = nothing 
		
		xml = xml & "<msg>Implementation logically deleted</msg>"



	'====================================================================================================================
	case else 
	'====================================================================================================================

		if len(request("id")) > 0 then
		
			xml = xml & "<crossSales customer=""" & request("id") & """>"
		
		 	json = "["
			json = json & "[""Date"",""Value""]"
			
			SQL =	"select d.id, cm.value " &_
					"from dateDimension d " &_
					"left join customerMetric cm on (cm.updatedDate = d.id and cm.metricID = 1) " &_
					"where d.id between '9/26/2016' and '9/25/2017' " &_
					"order by d.id asc "
			
			set rs = dataconn.execute(SQL)
			while not rs.eof 
				if isNull(rs("value")) then
					varValue = "null"
				else
					varValue = rs("value")
				end if
			' 	json = json & ",['" & rs("repdte") & "'," & rs("asset") & "," & rs("dep") & "]"
				json = json & ",[""" & rs("id") & """," & varValue & "]"
				rs.movenext 
			wend
			
			rs.close 
			set rs = nothing 
			
			json = json & "]"
		
			xml = xml & json 
			xml = xml & "</crossSales>"
			
		end if
	
		dataconn.close
		set dataconn = nothing



end select 

userLog(msg)


dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</customerImplementations>"

response.write(xml)	

%>