
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../../includes/getNextID.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)
dbug("customerSurveyReorder.asp started")

response.ContentType = "application/json"


customerID 			= request("customerID")
surveyType			= request("surveyType")
arrReorderedRows 	= request("arrReorderedRows") 

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
		
if len(surveyType) <= 0 then 
	json = "{""error"":""surveyType is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if isNumeric(surveyType) then 
		if ( cInt(surveyType) = 1  OR  cInt(surveyType) = 2 ) then 
			dbug("surveyType is validated")
		else 
			json = "{""error"":""surveyType is not valid""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if 
	else 
		json = "{""error"":""surveyType is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	end if		
end if			


dbug("arrReorderedRows: " & arrReorderedRows)

' strip leading and trailing double-quotes...
if left(arrReorderedRows,1) = """" then 
	arrReorderedRows = mid(arrReorderedRows,2,len(arrReorderedRows))
end if 
if right(arrReorderedRows,1) = """" then 
	arrReorderedRows = mid(arrReorderedRows,1,len(arrReorderedRows)-1)
end if
dbug("arrReorderedRows (after stripping double-quotes: " & arrReorderedRows)


tempAll = split(arrReorderedRows, "|")


if isArray(tempAll) then 
	
	dbug("tempAll is an array")


	if UBound(tempAll) > 0 then 

		for i = 0 to uBound(tempAll) 
			
			temp = split(tempAll(i),",")
			SQL = "update customerSurveyQuestions set " &_
						"seq = " & temp(1) & " " &_
						"where id = " & temp(0) & " " 
						
			dbug(SQL) 
			
			set rsUpdate = dataconn.execute(SQL) 
			set rsUpdate = nothing 
			
		next 

		msg = "Sequence Updated"

	else 
		
		msg = "tempAll array has not contents"

	end if 		


else 

	dbug("tempAll is NOT an array")

	json = "{""error"":""arrReorderRows is not valid""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
end if 



json = "{""msg"":""" & msg & """}"

dbug(json)
dbug("customerSurveyReorder.asp ended")

response.status = "200 Okay"
response.write json 
%>			

		
	


