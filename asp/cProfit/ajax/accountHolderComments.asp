
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../../includes/getNextID.asp" -->
<% 
dbug("start of /cprofit/ajax/accountHolderComents.asp...")
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"

customerID 				= request("customerID")
if len(customerID) <= 0 then 
	json = "{""error"":""CustomerID is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if not isNumeric(customerID) then 
		json = "{""error"":""CustomerID is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	end if
end if			
		


accountHolderNumber 	= request("accountHolderNumber")
if len(accountHolderNumber) <= 0 then 
	json = "{""error"":""accountHolderNumber is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
end if			


dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	case "GET"

		json = "{""data"": ["
	
		SQL = "select " &_
					"c.id, " &_
					"c.content, " &_
					"concat(u.firstName, ' ', u.lastName) as userName, " &_
					"c.updatedDateTime " &_
				"from pr_accountHolderAddenda c " &_
				"left join csuite..users u on (u.id = c.updatedBy) " &_
				"where c.[account holder number] = '" & accountHolderNumber & "' " &_
				"and c.customerID = " & customerID & " " &_
				"and c.type = 2 " &_
				"order by c.updatedDateTime asc " 
				
		set rsGet = dataconn.execute(SQL) 
		while not rsGet.eof 
		
			json = json & "{"
			json = json & """DT_RowId"":""" & rsGet("id") & ""","
			json = json & """content"":""" & rsGet("content") & ""","
			json = json & """updatedBy"":""" & rsGet("userName") & ""","
			json = json & """updatedDateTime"":""" & rsGet("updatedDateTime") & """"
			json = json & "}"
			
			rsGet.movenext 
			
			if not rsGet.eof then json = json & "," end if 
		
		wend 
		
		rsGet.close 
		set rsGet = nothing 
		
		json = json & "]}"

	case "DELETE" 
	
		dbug("inside the DELETE logic...")
	
		commentID = request.form("commentID")
		dbug("request.form('commentID'): " & commentID)
		
		if len(commentID) <= 0 then 
			json = "{""error"":""commentID is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
		
	
		SQL = "delete from pr_accountHolderAddenda " &_
				"where id = " & commentID & " " &_
				"and customerID = " & customerID & " " &_
				"and [account holder number] = '" & accountHolderNumber & "' " 
				
		dbug(SQL) 
		set rsDelete = dataconn.execute(SQL)

		json = "{""msg"":""Comment deleted""}"
	
	
	case "POST"
		
		dbug("inside the POST logic...") 
		
		content = request.form("content") 
		dbug("request.form('content'): " & content) 
		
		if len(content) <= 0 then 
			json = "{""error"":""content is not present""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if			
				
		newID = getNextID("pr_accountHolderAddenda") 
		
		SQL = "insert into pr_accountHolderAddenda (id, customerID, [account holder number], updatedBy, updatedDateTime, type, content) " &_
				"values ( " &_
					newID & ", " &_
					customerID & ", " &_
					"'" & accountHolderNumber & "', " &_
					session("userID") & ", " &_
					"current_timestamp, " &_
					"2, " &_
					"'" & content & "') " 
					
		dbug(SQL) 
		set rsPOST = dataconn.execute(SQL) 
		set rsPOST = nothing 
	
		json = "{""msg"":""Comment added"",""newID"":""" & newID & """}"
		
	
	case else 
	
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (405)"
				
end select 

dbug(json)

response.status = "200 Okay"
response.write json 
dbug("end of /cprofit/ajax/accountHolderComents.asp")
%>			

		
	


