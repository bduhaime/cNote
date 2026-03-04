<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->
<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/jsonDataTable.asp" -->
<% 

	dbug("dataSource/internalMetric")
	
' 	response.buffer = true 
	
	response.contentType = "application/json "

	responseVersion	= "version:0.6,"
	responseReqId		= ""
' 	responseVersion	= "version:0.6"
' 	responseReqId		= "reqId:0"
	responseStatus 	= ""
	responseWarnings 	= ""
	responseErrors 	= ""
	responseTable 		= ""

	
	customerID 	= request("customerID") 
	metricID 	= request("metricID") 
	objectiveID	= request("objectiveID")

	dbug(request("tqx"))
		
	tqxParms			= split(request("tqx"),";")
	
	for i = 0 to uBound(tqxParms)

		delimitLocation = inStr(tqxParms(i),":")
		parmName = mid(tqxParms(i),1,delimitLocation-1)
		parmValue = mid(tqxParms(i),delimitLocation+1,len(tqxParms(i)))
				
		select case parmName 
			
			case "reqId"
				dbug("reqId found: " & parmValue)
				responseReqId = "reqId:" & parmValue & ","
' 			case "version"
' 				responseVersion = tqx(i)
' 			case "sig"
' 			case "out"
' 			case "responseHandler"
' 			case "outFileName"
			case else 
		end select 
	
	next 
	
	
	
'===================================================================================================
' validate that all the required parameters are present...
'===================================================================================================

	if (len(customerID) <= 0 OR len(metricID) <= 0 OR len(objectiveID) <= 0) then 
		
		responseStatus = "status:'error',"
		errors 			= ""

		if len(customerID) <= 0 then 
			errors = errors & "customerID missing. "
		end if 
		
		if len(metricID) <= 0 then 
			errors = errors & "metricID missing. "
		end if 
			
		if len(objectiveID) <= 0 then 
			errors = errors & "objectiveID missing. "
		end if 
			
		
		responseErrors = " errors:[{reason:'other',message:'" & errors & "'}]"
		response.contentType = "application/json "
		response.write("google.visualization.Query.setResponse({" & responseVersion & responseReqId & responseStatus &  responseErrors & "})")
' 		response.write("google.visualization.Query.setResponse({" & responseVersion & "," & responseReqId & "," & responseStatus & "," & responseErrors & "})")
		response.end()
		
	end if 


'===================================================================================================
' validate that customer exists and retrieve additional identity info...
'===================================================================================================

	sqlCust = 	"select cert, rssdid from customer_view where id = " & customerID & " " 

	dbug(sqlCust)
	set rsCust = dataconn.execute(sqlCust) 

	if not rsCust.eof then 
		dbug("customer info found")
		customerCert = rsCust("cert")
		customerRSSD = rsCust("rssdid")
	else 
		dbug("customer information cannot be found")
		rsCust.close 
		set rsCust = nothing

		responseStatus = " status:'error',"
		responseErrors = " errors:[{reason:'other',message:'Customer cannot be found'}]"
		response.write("google.visualization.Query.setResponse({" & responseVersion & responseReqId & responseStatus & responseErrors & "})")		
' 		response.write("google.visualization.Query.setResponse({" & responseVersion & "," & responseReqId & "," & responseStatus & "," & responseErrors & "})")		
		response.end()

	end if 
	
	rsCust.close 
	set rsCust = nothing


'===================================================================================================
' retreive the actual values for the customer/internal metric
'===================================================================================================

	metricSQL = "select metricDate as [Reported Date], metricValue as [Value], null as [Objective] " &_
					"from customerInternalMetrics " &_
					"where rssdID = " & customerRSSD & " " &_
					"and metricID = " & metricID & " " &_
					"UNION ALL " &_
					"select startDate as [Reported Date], null as [Value], startValue as [Objective] " &_
					"from customerObjectives " &_
					"where id = " & objectiveID & " " &_
					"and startDate is not null " &_
					"UNION ALL " &_
					"select endDate as [Reported Date], null as [Value], endValue as [Objective] " &_
					"from customerObjectives " &_
					"where id = " & objectiveID & " " &_
					"and endDate is not null " &_
					"order by 1 "
	
		responseTable = jsonDataTable(metricSQL)

		if len(responseTable) > 0 then 
			responseStatus = "status:'ok',"
			responseTable = "table:" & jsonDataTable(metricSQL)
			response.write("google.visualization.Query.setResponse({" & responseVersion & responseReqId & responseStatus & responseTable & "})")		
		else 
			responseStatus = "status:'error',"
			responseErrors = " errors:[{reason:'other',message:'No values found for this metric'}]"
			response.write("google.visualization.Query.setResponse({" & responseVersion & responseReqId & responseStatus & responseErrors & "})")		
		end if
			
%>