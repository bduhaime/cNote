
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug("start of customers.asp")

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	'!-- ------------------------------------------------------------------ -->
	case "GET"
	'!-- ------------------------------------------------------------------ -->

		
		'!-- ------------------------------------------------------------------ -->
		'!-- Determine if current user is "internal" or "external"
		'!-- ------------------------------------------------------------------ -->
		if cInt(session("internalUser")) <> 1 then 
			internalUserPredicate = "and c.id in (select customerID from userCustomers where userID = " & session("userID") & ") "
		else 
			internalUserPredicate = ""
		end if 

		up = 		"{"
		up = up & 	"""edit"":" & lcase(userPermitted( 18 ) ) & ","
		up = up & 	"""status"":" & lcase(userPermitted( 133 ) ) & ","
		up = up & 	"""delete"":" & lcase(userPermitted( 22 ) ) 
		up = up & "}"
		
		json = "{"
			
		SQL = "select " &_
					"c.id, " &_
					"c.name, " &_
					"i1.city, " &_
					"i1.stalp, " &_
					"s.description as status, " &_
					"c.deleted, " &_
					"c.cert, " &_
					"c.rssdID, " &_
					"c.nickname, " &_
					"c.validDomains, " &_
					"cProfitApiKey, " &_
					"cProfitURI, " &_
					"lsvtCustomerName, " &_
					"customerGradeID, " &_
					"customerGradeNarrative " &_
				"from customer_view c " &_
				"left join fdic.dbo.institutions i1 on (i1.fed_rssd = c.rssdID and i1.repdte = (select max(repdte) from fdic.dbo.institutions i2 where i2.cert = c.cert)) " &_
				"left join customerStatus s on (s.id = c.customerStatusID and (s.deleted = 0 or s.deleted is null) ) " &_
				"where (c.deleted = 0 or c.deleted is null) " &_
				"and c.id <> 1 " &_
				internalUserPredicate

				
		dbug("GET SQL: " & SQL)
		set rsCusts = dataconn.execute(SQL) 
		
		json = json & """data"": ["
		while not rsCusts.eof 
				
			json = json & "{"
			json = json & """DT_RowId"":""" & rsCusts("id") & ""","
			json = json & """name"":""" & rsCusts("name") & ""","
			json = json & """city"":""" & rsCusts("city") & ""","
			json = json & """stalp"":""" & rsCusts("stalp") & ""","
			json = json & """status"":""" & rsCusts("status") & ""","
			json = json & """deleted"":""" & rsCusts("deleted") & ""","
			json = json & """cert"":""" & rsCusts("cert") & ""","
			json = json & """rssdID"":""" & rsCusts("rssdID") & ""","
			json = json & """nickname"":""" & rsCusts("nickname") & ""","
			json = json & """validDomains"":""" & rsCusts("validDomains") & ""","
			json = json & """cProfitApiKey"":""" & rsCusts("cProfitApiKey") & ""","
			json = json & """cProfitURI"":""" & rsCusts("cProfitURI") & ""","
			json = json & """lsvtCustomerName"":""" & rsCusts("lsvtCustomerName") & ""","
			json = json & """customerGradeID"":""" & rsCusts("customerGradeID") & ""","
			json = json & """customerGradeNarrative"":""" & rsCusts("customerGradeNarrative") & ""","
			json = json & """userPermissions"":" & up 
			json = json & "}"
		
			rsCusts.movenext 
		
			if not rsCusts.eof then json = json & "," end if
		
		wend 
		
		json = json & "]"	
		
		
		rsCusts.close 
		set rsCusts = nothing 
		
		
		
' ' 		determine userPermissions....
' 		if userPermitted( 18 ) then 
' 			edit = true 
' 		else 
' 			edit = false 
' 		end if 
' 		
' 		if userPermitted( 22 ) then 
' 			delete = true 
' 		else 
' 			delete = false
' 		end if 
' 		
' 		if userPermitted( 129 ) then 
' 			contracts = true 
' 		else 
' 			contracts = false 
' 		end if
' 		
' 		if userPermitted( 133 ) then 
' 			flag = true 
' 		else 
' 			flag = false 
' 		end if 
' 		
' 		json = json & ",""permissions"": {"
' 		json = json & 	"""edit"":""" & edit & """, "
' 		json = json & 	"""delete"":""" & delete & """, "
' 		json = json & 	"""status"":""" & flag & """, "
' 		json = json & 	"""contracts"":""" & contracts & """"
' 		json = json & "}"		
		
		json = json & "}"

		responseStatus = "200 Okay"

		dbug("end of GET processing")


	'!-- ------------------------------------------------------------------ -->
	case "DELETE" 
	'!-- ------------------------------------------------------------------ -->
	
		if len(request("id")) > 0 then 
			
			SQL = "update customer set deleted = 1 where id = " & request("id") & " " 
			
			set rsDELETE = dataconn.execute(SQL)
			set rsDELETE = nothing 
			responseStatus = "200 Okay"
			json = "{""msg"":""Customer deleted""}"
			
		else
			 
			responseStatus = "400 Bad Request"
			dbug("Customer ID missing from attempted delete") 
			json = "{""msg"":""Customer ID missing""}"
			
		end if 
			 
	
	
	'!-- ------------------------------------------------------------------ -->
	case else 
	'!-- ------------------------------------------------------------------ -->
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "405 Method not allowed"
				
				
end select 


dbug("Customers: " & json)

response.status = responseStatus
response.write json 

%>			

		
	


