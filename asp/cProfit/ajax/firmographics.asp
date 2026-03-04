
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)


response.ContentType = "application/json"
dbug("start of cnote/firmographics.asp")


customerID 		= request("customerID")
if isEmpty(customerID) then 
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
	else 
		dbug("customerID: " & customerID)
		customerPredicate = "WHERE customerID = " & customerID & " " 
	end if
end if 
	
surveyType = request("surveyType")
if isEmpty(surveyType) then 
	json = "{""error"":""surveyType is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if not isNumeric(surveyType) then 
		json = "{""error"":""surveyType is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		dbug("surveyType: " & surveyType)
		surveyPredicate = "AND surveyType = " & surveyType & " " 
	end if
end if 
	

SQL = "select " &_
			"id, " &_
			"seq, " &_
			"prompt, " &_
			"responseType, " &_
			"responseValues, " &_
			"regex, " &_
			"source " &_
		"from customerSurveyQuestions " &_
		customerPredicate &_
		surveyPredicate
		
dbug(SQL)

json = "{""data"": ["

set rsSurvey = dataconn.execute(SQL)

while not rsSurvey.eof

	if not isNull(rsSurvey("regex")) then 
		regex = replace( rsSurvey("regex"), "\", "\\" )
	else 
		regex = ""
	end if 
	
	json = json & "{"
	json = json & """DT_RowId"":""" & rsSurvey("id") & ""","
	json = json & """seq"":""" & rsSurvey("seq") & ""","
	json = json & """prompt"":""" & rsSurvey("prompt") & ""","
	json = json & """responseType"":""" & rsSurvey("responseType") & ""","
	json = json & """responseValues"":""" & rsSurvey("responseValues") & ""","
	json = json & """regex"":""" & regex & ""","
	json = json & """source"":""" & rsSurvey("source") & """"
	json = json & "}"
	
	rsSurvey.movenext 
	
	if not rsSurvey.eof then json = json & ","
	
wend


json = json & "]}"

rsSurvey.close 
set rsSurvey = nothing 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


