
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../includes/validateDrilldownParameters.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug("start of customerSurvey.asp")


customerID 		= request("customerID")
if isEmpty(customerID) then 
	dbug("customerID is empty")
	json = "{""error"":""CustomerID is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if not isNumeric(customerID) then 
		dbug("customerID is not numeric")
		json = "{""error"":""CustomerID is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		dbug("customerID: " & customerID)
		customerPredicate = "WHERE q.customerID = " & customerID & " " 
	end if
end if 

surveyType = request("surveyType")
if isEmpty(surveyType) then 
	dbug("surveyType is empty")
	json = "{""error"":""surveyType is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if not isNumeric(surveyType) then 
		dbug("surveyType is not numeric")
		json = "{""error"":""surveyType is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		if ( cInt(surveyType) = 1 OR cInt(surveyType) = 2 ) then 
			surveyTypePredicate = "AND q.surveyType = " & surveyType & " " 
		else 
			dbug("surveyType is an unexpected value")
			json = "{""error"":""surveyType is not valid""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if
	end if 
end if

' accountHolderNumber = request("accountHolder")
' if isEmpty(accountHolderNumber) then 
' 	dbug("accountHolderNumber is empty")
' 	json = "{""error"":""accountHolder is not present""}"
' 	response.status = "400 Bad Request"
' 	response.write json
' 	response.end()
' else 
' 	if len(accountHolderNumber) <> 64 then 
' 		dbug("accountHolderNumber has an invalid length")
' 		json = "{""error"":""accountHolder is not valid""}"
' 		response.status = "400 Bad Request"
' 		response.write json
' 		response.end()
' 	else 
' 		dbug("accountHolder: " & accountHolderNumber)
' 		accountHolderPredicate = "AND [account holder number] = " & accountHolderNumber & " " 
' 	end if 
' end if 


	

SQL = "select " &_
			"q.id, " &_
			"q.seq, " &_
			"q.prompt, " &_
			"q.responseType, " &_
			"q.responseValues, " &_
			"q.source " &_
		"from customerSurveyQuestions q " &_
		customerPredicate &_
		surveyTypePredicate &_
		"order by seq asc "
		
dbug(SQL)

json = "{""data"": ["

set rsQ = dataconn.execute(SQL)

while not rsQ.eof

	json = json & "{"
	json = json & """DT_RowId"":""" 			& rsQ("id") 				& ""","
	json = json & """prompt"":""" 			& rsQ("prompt") 			& ""","
	json = json & """responseType"":""" 	& rsQ("responseType") 	& ""","
	json = json & """responseValues"":""" 	& rsQ("responseValues") & ""","
	json = json & """source"":""" 			& rsQ("source") 			& """"
	json = json & "}"
	
	rsQ.movenext 
	
	if not rsQ.eof then json = json & ","
	
wend


json = json & "]}"

rsQ.close 
set rsQ = nothing 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


