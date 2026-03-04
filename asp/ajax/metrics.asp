
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
dbug("start of metrics.asp")

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))
select case request.servervariables("REQUEST_METHOD") 

	'!-- ------------------------------------------------------------------ -->
	case "GET"
	'!-- ------------------------------------------------------------------ -->

		
		'!-- ------------------------------------------------------------------ -->
		'!-- Determine if current user is "internal" or "external"
		'!-- ------------------------------------------------------------------ -->
			
		json = "{"
			
		SQL = "select " &_
					"m.id as [ID], " &_
					"m.name, " &_
					"m.ubprSection, " &_
					"m.ubprLine, " &_
					"m.financialCtgy, " &_
					"m.ranksColumnName, " &_
					"m.ratiosColumnName, " &_
					"m.statsColumnName, " &_
					"m.sourceTableNameRoot, " &_
					"m.dataType, " &_
					"m.displayUnitsLabel, " &_
					"m.active, " &_
					"m1.name as [annualChangeColumn] " &_
				"from metric m " &_
				"left join metric m1 on (m1.id = m.correspondingAnnualChangeID) " &_
				"where (m.deleted = 0 or m.deleted is null) " 

				
		dbug("GET SQL: " & SQL)
		set rsMetrics = dataconn.execute(SQL) 
		
		json = json & """data"": ["
		while not rsMetrics.eof 
		
			json = json & "{"
			json = json & """DT_RowId"":""" & rsMetrics("id") & ""","
			json = json & """metricName"":""" & rsMetrics("name") & ""","
			json = json & """ubprSection"":""" & rsMetrics("ubprSection") & ""","
			json = json & """ubprLine"":""" & rsMetrics("ubprLine") & ""","
			json = json & """financialCtgy"":""" & rsMetrics("financialCtgy") & ""","
			json = json & """ranksColumnName"":""" & rsMetrics("ranksColumnName") & ""","
			json = json & """ratiosColumnName"":""" & rsMetrics("ratiosColumnName") & ""","
			json = json & """statsColumnName"":""" & rsMetrics("statsColumnName") & ""","
			json = json & """sourceTableNameRoot"":""" & rsMetrics("sourceTableNameRoot") & ""","
			json = json & """dataType"":""" & rsMetrics("dataType") & ""","
			json = json & """displayUnitsLabel"":""" & rsMetrics("displayUnitsLabel") & ""","
			json = json & """annualChangeColumn"":""" & rsMetrics("annualChangeColumn") & """"
			json = json & "}"
		
			rsMetrics.movenext 
		
			if not rsMetrics.eof then json = json & "," end if
		
		wend 
		
		json = json & "]"	
		
		
		rsMetrics.close 
		set rsMetrics = nothing 
		
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


dbug("Metrics: " & json)

response.status = responseStatus
response.write json 

%>			

		
	


