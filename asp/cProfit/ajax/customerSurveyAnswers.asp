<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="../../ajax/apiSecurity.asp" -->

<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/dbug.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
dbug("starting customerSurveyAnswers.asp")

dbug("querystring:")
for each item in request.querystring
	dbug("..." & item & ": " & request.querystring(item))
next 
dbug("form:") 
for each item in request.form 
	dbug("..." & item & ": " & request.form(item))
next 

response.contentType = "application/json"
json 	= ""
msg 	= ""

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	case "POST"	
	
		customerID				= request.form("customerID") 
		accountHolderNumber 	= request.form("accountHolderNumber")
		questionID				= request.form("questionID")
		newValue					= request.form("newValue") 
		
		if len(customerID) > 0 then 
			if isNumeric(customerID) then 
				dbug("customerID validated")
				customerPredicate = "WHERE customerID = " & customerID & " " 
			else 
				dbug("customerID is present but invalid")
				response.status = "412 Precondition Failed"
				response.end()
			end if 
		else 
			dbug("customerID is not present")
			response.status = "412 Precondition Failed"
			response.end() 
		end if 
		
		if len(accountHolderNumber) = 64 then 
			dbug("accountHolder validated")
			accountHolderPredicate = "AND [account holder number] = '" & accountHolderNumber & "' "
		else 
			dbug("accountHolderNumber is not present or invalid")
			response.status = "412 Precondition Failed"
			response.end() 
		end if 
		
		if len(questionID) > 0 then 
			if isNumeric(questionID) then 
				dbug("questionID validated")
				questionPredicate = "AND questionID = " & questionID & " "
			else 
				dbug("questionID is present but invalid")
				response.status = "412 Precondition Failed"
				response.end() 
			end if 
		else 
			dbug("questionID is not present")
			response.status = "412 Precondition Failed"
			response.end() 
		end if 
				
				
		sqlSelect = "select * from customerSurveyAnswers " &_
						customerPredicate &_
						accountHolderPredicate &_
						questionPredicate 
		dbug(sqlSelect)
		set rsA = dataconn.execute(sqlSelect) 
		if not rsA.eof then 
			
			sqlUpdate = "update customerSurveyAnswers set " &_
								"answer = '" & newValue & "', " &_
								"updatedBy = " & session("userID") & ", " &_
								"updatedDateTime = current_timestamp " &_
							customerPredicate &_
							accountHolderPredicate &_
							questionPredicate 

			dbug(sqlUpdate)
			set rsUpdate = dataconn.execute(sqlUpdate)
			set rsUpdate = nothing 
			
			msg = "Survey Answer Updated"

		else 

			sqlInsert = "insert into customerSurveyAnswers (customerID, [account holder number], questionID, answer, updatedBy, updatedDateTime) " &_
							"values ( " &_
								customerID & ", " &_
								"'" & accountHolderNumber & "', " &_
								questionID & ", " &_
								"'" & newValue & "', " &_
								session("userID") & ", " &_
								"current_timestamp " &_
								") "
								
			dbug(sqlInsert)
			set rsInsert = dataconn.execute(sqlInsert) 
			set rsInsert = nothing 

			msg = "Survey Answer Added"

		end if 
		rsA.close 
		set rsA = nothing 
			
				
		json = "{""msg"": """ & msg & """}"
		
		responseStatus = "200 OK"		
		

	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
		msg = "Method not allowed (080)"
				
end select 

dataconn.close 
set dataconn = nothing 


dbug("json: " & json)
dbug("ending accountHolderAddenda.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>