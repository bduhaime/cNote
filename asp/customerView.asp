<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<% ' response.buffer = true %>
<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/jsonDataArray.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeByCustomer.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(37)

dbug(" ")
userLog("customer view")
templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")


customerID = request.querystring("id")
if request.querystring("mode") = "kiosk" then 
	kioskMode = true
else 
	kioskMode = false 
end if
tab = request.querystring("tab") 

select case request.querystring("tab")
	case "calls"
		activateOverview 		= ""
		activateCalls 			= "is-active"
		activateUtopias 		= ""
		activateProjects 		= ""
		activateAttributes 	= ""
		activateValues 		= ""
		activateManagers 		= ""
		activateContacts 		= ""
	case "projects" 
		activateOverview 		= ""
		activateCalls 			= ""
		activateUtopias 		= ""
		activateProjects 		= "is-active"
		activateAttributes 	= ""
		activateValues 		= ""
		activateManagers 		= ""
		activateContacts 		= ""
	case "contacts" 
		activateOverview 		= ""
		activateCalls 			= ""
		activateUtopias 		= ""
		activateProjects 		= ""
		activateAttributes 	= ""
		activateValues 		= ""
		activateManagers 		= ""
		activateContacts 		= "is-active"
	case else 
		activateOverview 		= "is-active"
		activateCalls 			= ""
		activateUtopias 		= ""
		activateProjects 		= ""
		activateAttributes 	= ""
		activateValues 		= ""
		activateManagers 		= ""
		activateContacts 		= ""
end select 

' chartEndDate = date()
' chartStartDate = dateAdd("yyyy",-1,chartEndDate)

' using hard-coded dates to match test data...
chartEndDate = "8/1/2017"
chartStartDate = "8/1/2016"

dbug("chartStartDate: " & chartStartDate & ", chartEndDate: " & chartEndDate)

'***********************************************************************************
function metricJSON1(customer)
'***********************************************************************************
dbug("metricJSON1(" & metric & "," & customer & ")")

	json = "["
	json = json & "['Date', {label: 'Cross-Sales', type: 'number'}, {label: 'TGMI-U Utilization', type: 'number'}, {label: 'MRR', type: 'number'}]"
	
	SQL = "select d.yearNo, d.monthNo, avg(x.metricValue) as crossSales, avg(y.metricValue) as tgimuUtil, sum(z.metricValue) as mrr " &_
			"from dateDimension d " &_
			"left join " &_
			"	( " &_	
			"	select cim.metricDate, cim.metricValue, cim.rssdid " &_
			"	from customerInternalMetrics cim " &_
			"	join customer_view c on (c.rssdid = cim.rssdid) " &_
			"	and cim.metricID = 1 " &_
			"	and c.id = " & customer & " " &_
			"	) x on (x.metricDate = d.id) " &_
			"left join " &_
			"	( " &_
			"	select cim.metricDate, cim.metricValue, cim.rssdid " &_
			"	from customerInternalMetrics cim " &_
			"	join customer_view c on (c.rssdid = cim.rssdid) " &_
			"	and cim.metricID = 6 " &_
			"	and c.id = " & customer & " " &_
			"	) y on (y.metricDate = d.id) " &_
			"left join " &_
			"	( " &_
			"	select cim.metricDate, cim.metricValue, cim.rssdid " &_
			"	from customerInternalMetrics cim " &_
			"	join customer_view c on (c.rssdid = cim.rssdid) " &_
			"	and cim.metricID = 2 " &_
			"	and c.id = " & customer & " " &_
			"	) z on (z.metricDate = d.id) " &_
			"where d.id between '2/1/2015' and '1/31/2018' " &_
			"group by d.yearNo, d.monthNo " &_
			"order by d.yearNo, d.monthNo "



	dbug(SQL)
	
	set rsM1 = dataconn.execute(SQL)

	if rsM1.eof then
		
		json = json & ",['9/25/2017','no data']"
		
	else 
		
		while not rsM1.eof 
		
			if isNull(rsM1("crossSales")) then
				crossSales = "null"
			else
				crossSales = rsM1("crossSales")
			end if
			
			if isNull(rsM1("tgimuUtil")) then
				tgimuUtil = "null"
			else
				tgimuUtil = rsM1("tgimuUtil") * 10
			end if
			
			if isNull(rsM1("mrr")) then
				mrr = 0
			else
				if cCur(rsM1("mrr")) > 0 then 
					mrr = 10
				else 
					mrr = 0
				end if 
			end if
			
			json = json & ",['" & rsM1("monthNo")&"/"&rsM1("yearNo") & "'," & crossSales & "," & tgimuUtil & "," & mrr & "]"
			rsM1.movenext 
		wend

	end if
	json = json & "]"

	rsM1.close
	set rsM1 = nothing 
	
	metricJSON1 = json

	dbug("json: " & json)
end function


'***********************************************************************************
function getJSON ( metric , customer )
'***********************************************************************************
dbug("getJSON(" & metric & "," & customer & ")")


	SQL = "select name from metric where id = " & metric & " "
	set rsMetric = dataconn.execute(SQL)
	if not rsMetric.eof then 
		labelName = rsMetric("name")
	else 
		lableName = "not found"
	end if
	rsMetric.close 
	set rsMetric = nothing 

	json = "["
' 	json = json & "['Date', {label: '" & labelName & "', type: 'number'}]"
	
	SQL = "select d.yearNo, d.monthNo, avg(x.metricValue) as metricAvg  " &_
			"from dateDimension d " &_
			"left join " &_
			"	( " &_	
			"	select cim.metricDate, cim.metricValue, cim.rssdid " &_
			"	from customerInternalMetrics cim " &_
			"	join customer_view c on (c.rssdid = cim.rssdid) " &_
			"	and cim.metricID = " & metric & " " &_
			"	and c.id = " & customer & " " &_
			"	) x on (x.metricDate = d.id) " &_
			"where d.id between '" & chartStartDate & "' and '" & chartEndDate & "' " &_
			"group by d.yearNo, d.monthNo " &_
			"order by d.yearNo, d.monthNo "

	dbug(SQL)
	
	set rsM1 = dataconn.execute(SQL)

	if rsM1.eof then
		
		json = json & ",['" & chartEndDate & "','no data']"
		
	else 
		
		while not rsM1.eof 
		
			if isNull(rsM1("metricAvg")) then
				metricAvg = "null"
			else
				select case metric 
					case 6
						metricAvg = rsM1("metricAvg") * 100
					case else 
						metricAvg = rsM1("metricAvg")
				end select 
			end if
						
			json = json & "['" & rsM1("monthNo")&"/"&rsM1("yearNo") & "'," & metricAvg & "]"
			rsM1.movenext 
			if not rsM1.eof then 
				json = json & ","
			end if
			
		wend

	end if
	json = json & "]"

	rsM1.close
	set rsM1 = nothing 
	
	dbug("getJSON: " & json)
	getJSON = json
	
end function


'***********************************************************************************
function getJSONGauges(customer) 
'***********************************************************************************

	dbug("getJSONGauges")
	
	json = "["
	
	SQL = "select cim.metricID, max(cim.metricDate) as lastDate " &_
			"from customerInternalMetrics cim " &_
			"join customer_view c on (c.rssdID = cim.rssdID) " &_
			"left join metric m on (m.id = cim.metricID) " &_
			"where c.id = " & customer & " " &_
			"and cim.metricID in (14,15,16,19) " &_
			"group by cim.metricID " 
			
	dbug(SQL)
	
	set rsGauges = dataconn.execute(SQL)
	while not rsGauges.eof 

		select case cint(rsGauges("metricID"))
			case 14
				label = "Exec MCC"
			case 15
				label = "CEO MCC"
			case 16
				label = "SAC"
			case 19
				label = "NPS"
			case else 
				label = "?"
		end select 
			
		monthsSince = cInt(dateDiff("m",rsGauges("lastDate"),date()))

		json = json & "['" & label & "'," & monthsSince & "]"
		rsGauges.movenext 
		if not rsGauges.eof then json = json & "," end if

	wend 
	
	json = json & "]"
	
	rsGauges.close 
	set rsGauges = nothing 
	
	dbug(json)
	getJSONGauges = json 


end function 


'***********************************************************************************
function getJSONValues(customer) 
'***********************************************************************************

	dbug("getJSONValues")
	
	json = "["
	
	SQL = "select cim.id, m.name, cim.metricDate, cim.metricValue " &_
			"from customerInternalMetrics cim " &_
			"left join metric m on (m.id = cim.metricID) " &_
			"join customer_view c on (c.rssdid = cim.rssdid) " &_
			"where c.id = " & customer & " " &_
			"order by metricDate desc " 
			
	dbug("Values: " & SQL)
	
	set rsVals = dataconn.execute(SQL)
	while not rsVals.eof 

' 		json = json & "[" & rsVals("id") & ",'" & rsVals("name") & "','" & formatDateTime(rsVals("metricDate")) & "'," & rsVals("metricValue") & "]"
		json = json & "['" & rsVals("name") & "','" & formatDateTime(rsVals("metricDate")) & "'," & rsVals("metricValue") & "]"
		rsVals.movenext 
		if not rsVals.eof then json = json & "," end if

	wend 
	
	json = json & "]"
	
	rsVals.close 
	set rsVals = nothing 
	
	dbug(json)
	getJSONValues = json 


end function 


'***********************************************************************************
function projectTimeLine (customer)
'***********************************************************************************
dbug("projectTimeLine")
	
	json = "["
' 	json = json & "['productName','projectName','startDate','endDate']"
	
	SQL =	"select projects.id as projID, case when projects.name > '' then projects.name else products.name end as projectName, products.name as productName, projects.startDate, projects.endDate, projects.complete " &_
			"from projects " &_
			"left join products on (products.id = projects.productID) " &_
			"where projects.customerID =  " & customer & " " &_
			"order by products.name, projects.startDate "
	firstTime = true
	dbug("project timeline SQL: " & SQL)
	set rsPTL = dataconn.execute(SQL)
	while not rsPTL.eof 
		if firstTime then 
' 			json = json & "['  ','Today', new Date(" & year(now) & ", " & month(now)-1 & ", " & day(now) & "), new Date(" & year(now) & ", " & month(now)-1 & ", " & day(now) & ")],["
			json = json & "["
			firstTime = false 
		else 
			json = json & ",["
		end if 
		tooltip = "Product: " & rsPTL("productName") & "<hr>Project: " & rsPTL("projectName") & "<br>Start: " & rsPTL("startDate") & "<br>End: " & rsPTL("endDate")
		json = json & "'" & rsPTL("projID") & "'" &_
						  ",'" & rsPTL("projectName") & "'" &_
						  ",'" & tooltip & "'" &_
						  ", new Date(" & year(rsPTL("startDate")) & ", " & month(rsPTL("startDate"))-1 & ", " & day(rsPTL("startDate")) & ")" &_
						  ", new Date(" & year(rsPTL("endDate"))   & ", " & month(rsPTL("endDate"))-1   & ", " & day(rsPTL("endDate"))   & ")" &_
						  " ]"
						  
						  
		rsPTL.movenext 
	wend
	
	json = json & "]"

	rsPTL.close
	set rsPTL = nothing 
	
	dbug("projecTimeLine.json: " & json)
	
	projectTimeLine = json

	
end function 	


'===============================================================================
function formatBrowserDateTime(inputDateTime)
'===============================================================================
	
	dbug("formatBrowserDateTime(" & inputDateTime & ")")
	
	
	if not isNull(inputDateTime) then 

		inputDateYYYY 	= cStr(datePart("yyyy",inputDateTime))
		inputDateMM	 	= right("0" & cStr(datePart("m",inputDateTime)),2)
		inputDateDD	 	= right("0" & cStr(datePart("d",inputDateTime)),2)

		if (datePart("h",inputDateTime)) > 12 then 
			inputDateHH	 	= right("0" & cStr(datePart("h",inputDateTime)-12),2)
			inputDateAP		= "PM"
		else 
			inputDateHH	 	= right("0" & cStr(datePart("h",inputDateTime)),2)
			inputDateAP		= "AM"
		end if

		inputDateNN	 	= right("0" & cStr(datePart("n",inputDateTime)),2)
		
		formatBrowserDateTime = inputDateYYYY 	& "-" &_
										inputDateMM		& "-" &_
										inputDateDD		& " " &_
										inputDateHH		& ":" &_
										inputDateNN		& " " &_
										inputDateAP

	else 

		formatBrowserDateTime = ""

	end if
	
end function



'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

dbug("before top-logic")

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
	'***** get info fo customer metrics *****

' 	jsonCombo = metricJSON1(customerID)

	SQL = "select shortName as [Call Type], datediff(day, lastCallDate, current_timestamp) as [Actual], idealFrequencyDays as [Goal] " &_
			"from " &_
				"(select ct.shortName, ct.idealFrequencyDays, max(endDateTime) as lastCallDate " &_
				"from customerCallTypes ct " &_
				"left join customerCalls cc on (cc.callTypeID = ct.id) " &_
				"where cc.customerID = " & customerID & " " &_
				"group by ct.shortName, ct.idealFrequencyDays) x "
				
' 	dbug("jsonCalls SQL: " & SQL)
	jsonCalls = jsonDataTable(SQL)

	
	json6 = getJSON(6,customerID)
	json2 = getJSON(2,customerID)
	json1 = getJSON(1,customerID)

	jsonGauges = getJSONGauges(customerID)
	jsonValues = getJSONValues(customerID)
	
' 	json4 = metricJSON1(9,customerID)
	

end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

chartHeight = 200



' cmTimelineSQL = "select u.firstName + ' ' + u.lastName as userFullName, startDate, case when endDate is null then convert(date, current_timestamp) else endDate end as endDate " &_
' 					 "from customerManagers cm " &_
' 					 "left join cSuite..users u on (u.id = cm.userID) " &_
' 					 "where cm.customerID = 8 and cm.managerTypeID = 0 "

SQL = "select name, fullName, startDate, endDate " &_
		"from ( " &_
			"select distinct " &_
				"t.seq, " &_
				"m.startDate, " &_
				"case when m.endDate is null then convert(date, current_timestamp) else m.endDate end as endDate, " &_
				"t.name, " &_
				"CONCAT(u.firstName, ' ', u.lastName) as fullName " &_
			"from customerManagers m " &_
			"left join cSuite..users u on (u.id = m.userID) " &_
			"left join customerManagerTypes t on (t.id = m.managerTypeID) " &_
			"where m.endDate > m.startDate or m.endDate is null " &_
			"and m.customerID  = " & customerID & " " &_
			") x " 

cmTimeLineData = 	jsonDataArray(SQL,false)


SQL = "select " &_
			"shortName, " &_
			"startDateTime, " &_
			"Goal, " &_
			"case when prevCallDate is null then " &_
				"dateDiff(day,currSignedDate,startDateTime) " &_
			"else " &_
				"dateDiff(day,prevCallDate,startDateTime) " &_
			"end as Actual " &_
		"from " &_
			"( " &_
			"select " &_
				"shortName, " &_
				"startDateTime, " &_
				"idealFrequencyDays as Goal, " &_
				"(select max(startDateTime) from customerCalls x where x.customerID = a.customerID and x.startDateTime < a.startDateTime ) as prevCallDate, " &_
				"'1/1/2015' as currSignedDate " &_
			"from customerCalls a " &_
			"left join customerCallTypes b on (b.id = a.callTypeID) " &_
			"left join customer_view c on (a.customerID = c.id) " &_
			"left join contracts d on (d.cert = c.cert) " &_
			"where (a.deleted = 0 or a.deleted is null) " &_
			"and customerID = " & customerID & " " &_
			") y " &_
		"order by startDateTime "
'			"and callTypeID = 1 " &_
	
dbug("dtDaysSinceLast SQL: " & SQL)
dtDaysSinceLast = jsonDataTable(SQL)


SQL = "select " &_
			"trim(cast(p.id as char)) as projectID, " &_ 
			"p.name, " &_
			"u.firstName as resource, " &_
			"p.startDate, " &_
			"p.endDate, " &_
			"null as duration, " &_
			"null as percentComplete, " &_
			"'' as dependencies " &_
		"from projects p " &_
		"left join customerManagers m on (m.customerID = p.customerID and m.startDate <= p.startDate and p.startDate <= m.endDate and m.managerTypeID = 0) " &_
		"left join cSuite..users u on (u.id = m.userID) " &_
		"where p.customerID = " & customerID & " "

dbug("dtCustomerProjects SQL" & SQL)
dtCustomerProjects = jsonDataTable(SQL)

 
SQL = "select  cim.metricID, cim.metricDate, cim.metricValue " &_
		"from customerInternalMetrics cim " &_
		"join customer_view c on (c.rssdid = cim.rssdid) " &_
		"where c.id = " & customerID & " " 
	
dbug("dtCustomerMetrics SQL: " & SQL)	
dtCustomerMetrics = jsonDataTable(SQL)


SQL = "select " &_
			"t.name as managerType, " &_
			"u.firstName, " &_
			"m.startDate, " &_
			"case when m.endDate is null then " &_
				"cast(current_timestamp as date) " &_
			"else " &_
				"m.endDate " &_
			"end as endDate " &_
		"from customerManagers m " &_
		"left join customerManagerTypes t on (t.id = m.managerTypeID) " &_
		"left join cSuite..users u on (u.id = m.userID) " &_
		"where m.customerID = " & customerID & " "

dbug("dtcustomerManagers SQL: " & dtcustomerManagers)
dtcustomerManagers = jsonDataTable(SQL)

%>


<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->
	
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	<link rel="stylesheet" type="text/css" href="spinner.css"></script>

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="moment-timezone.js"></script>

	<script type="text/javascript" src="customerView.js"></script>
	<script type="text/javascript" src="customerAnnotations.js"></script>

			
	<script type="text/javascript">
		
	   google.charts.load("visualization", "1", {packages:["corechart"]});
//  		google.charts.load('current', {'packages':['scatter','timeline','line','gauge','table','bar','controls']});
 		google.charts.load('current', {'packages':['corechart', 'controls']});
 		google.charts.load('current', {'packages':['timeline','gantt']});

// 		google.charts.setOnLoadCallback(drawMccCallHistory);
		google.charts.setOnLoadCallback(drawCharts);

// 		function drawMccCallHistory() {
// 			
// 		}
		
		function drawCharts() {
			
			var chartMaxDate = moment().toDate();
			var chartMinDate = moment().subtract(1, 'years').toDate();
			
		
			var options = {
				title: 	'Days Since Last Call by Call Type',
				vAxis:		{title: 'Days', minValue: 0},
				hAxis:		{title: 'Call Type'},
				bars:			'horizontal',
//				legend:		{position: 'none'},
				chartArea:	{width: '55%', height:' 60%'},
				height: 		<% =chartHeight %>,
			};
			

		   var chart_tgimUtilization = new google.visualization.ChartWrapper({
		      view: {columns: [1,2]},
		      chartType: 'ScatterChart',
		      containerId: 'tgimUtilitization',
				animation: {startup: true, duration: 500, easing: 'out'},
		      options: {
		         title: 'TGIM Utilization',
		         legend: {position: 'none'},
		         lineWidth: 1,
					pointSize: 2,
		         chartArea: {width: '75%', height: '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartMinDate,
			         	max: chartMaxDate,
			         },
						format: "MMM ''yy",
					},
			      vAxis: {maxValue: 10},
		      },
		   });		
				


		   var chart_csUtilization = new google.visualization.ChartWrapper({
		      view: {columns: [1,2]},
		      chartType: 'ScatterChart',
		      containerId: 'crossSales',
				animation: {startup: true, duration: 500, easing: 'out'},
		      options: {
		         title: 'Cross Sales',
		         legend: {position: 'none'},
		         lineWidth: 1,
					pointSize: 2,
		         chartArea: {width: '75%', height: '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartMinDate,
			         	max: chartMaxDate,
			         },
						format: "MMM ''yy",
					},
			      vAxis: {maxValue: 10},
		      },
		   });		
				

			var callSummaryData = new google.visualization.DataTable(<% =jsonCalls %>);

			chartDiv = document.getElementById('jsonCalls');
	      var chart = new google.visualization.ColumnChart(chartDiv);
			if (callSummaryData.getNumberOfRows() > 0) {
				chart.draw(callSummaryData, options);
			} else {
				chartDiv.style.lineHeight = 10;
				chartDiv.innerHTML = 'No Call Data';	
	      }
	      


	      var customerMetrics = new google.visualization.DataTable(<% =dtCustomerMetrics %>)
		      
			var tgimDataView = new google.visualization.DataView(customerMetrics);
			
			
			var tgimChartDiv = document.getElementById('tgimUtilitization');
			var csChartDiv = document.getElementById('crossSales');

			if (customerMetrics.getNumberOfRows() > 0) {
			
				tgimDataView.setRows(customerMetrics.getFilteredRows([
					{column: 0, value: 6}
				]));
	 			if (tgimDataView.getNumberOfRows() > 0) {
					chart_tgimUtilization.setDataTable(tgimDataView);
					chart_tgimUtilization.draw();
				} else {
					tgimChartDiv.style.lineHeight = 10;
					tgimChartDiv.innerHTML = 'No TGIM Data';	
				}
	      
	      
				var csDataView = new google.visualization.DataView(customerMetrics);
					csDataView.setRows(customerMetrics.getFilteredRows([
					{column: 0, value: 1}
				]));
	 			if (csDataView.getNumberOfRows() > 0) {
					chart_csUtilization.setDataTable(csDataView);
					chart_csUtilization.draw();
				} else {
					csChartDiv.style.lineHeight = 10;
					csChartDiv.innerHTML = 'No Cross Sales Data';	
				}

			} else {

				tgimChartDiv.style.lineHeight = 10;
				tgimChartDiv.innerHTML = 'No TGIM Data';	
				csChartDiv.style.lineHeight = 10;
				csChartDiv.innerHTML = 'No Cross Sales Data';	
				
			}



 			var callHistory 			= new google.visualization.DataTable(<% =dtDaysSinceLast %>);
 			var customerProjects 	= new google.visualization.DataTable(<% =dtCustomerProjects %>);
 			var customerManagers 	= new google.visualization.DataTable(<% =dtCustomerManagers %>);

		   var callTypePicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'callTypePicker',
		      options: {
		         filterColumnLabel: 'shortName',
		         ui: {
		            label: 'Call Type'
		         }
		      },
		   });
		   
		   var completeCallHistory = new google.visualization.ChartWrapper({
			   chartType: 'Table',
			   containerId: 'completeCallHistory',
		   });

		   var chart_mccCallHistory = new google.visualization.ChartWrapper({
		      view: {columns: [1,2,3]},
		      chartType: 'ScatterChart',
		      containerId: 'chart_mccCallHistory',
				animation: {startup: true, duration: 500, easing: 'out'},
		      options: {
		         title: 'MCC Call History',
		         lineWidth: 1,
					pointSize: 2,
		         chartArea: {'width': '55%', 'height': '65%'},
		         vAxis: {title: 'Days'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartMinDate,
			         	max: chartMaxDate,
			         },
						format: "MMM ''yy",
			       },
					series: {
						0: {color: 'red', pointSize: 0},
						1: {color: 'black', pointSize: 2}
					},
					trendlines: {
//						1: {color: 'purple', lineWidth: 5, opacity: 0.4, type: 'polynomial', degree: 2}
						1: {type: 'linear', color: 'purple', lineWidth: 5, opacity: 0.4}
					},
		      },
		   });		
		
		   var chart_sacCallHistory = new google.visualization.ChartWrapper({
		      view: {columns: [1,2,3]},
		      chartType: 'ScatterChart',
		      containerId: 'chart_sacCallHistory',
				animation: {startup: true, duration: 500, easing: 'out'},
		      options: {
		         title: 'SAC Call History',
		         lineWidth: 1,
					pointSize: 2,
		         chartArea: {'width': '60%', 'height': '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartMinDate,
			         	max: chartMaxDate,
			         },
						format: "MMM ''yy",
			       },
					series: {
						0: {color: 'red', pointSize: 0},
						1: {color: 'black', pointSize: 2}
					},
					trendlines: {
//						1: {color: 'purple', lineWidth: 5, opacity: 0.4, type: 'polynomial', degree: 2}
						1: {type: 'linear', color: 'purple', lineWidth: 5, opacity: 0.4}
					},
		      },
		   });		
		

		   var chart_hfyCallHistory = new google.visualization.ChartWrapper({
		      view: {columns: [1,2,3]},
		      chartType: 'ScatterChart',
		      containerId: 'chart_sacCallHistory',
				animation: {startup: true, duration: 500, easing: 'out'},
		      options: {
		         title: 'HFY Call History',
		         lineWidth: 1,
					pointSize: 2,
		         chartArea: {'width': '60%', 'height': '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartMinDate,
			         	max: chartMaxDate,
			         },
						format: "MMM ''yy",
			       },
					series: {
						0: {color: 'red', pointSize: 0},
						1: {color: 'black', pointSize: 2}
					},
					trendlines: {
						1: {color: 'purple', lineWidth: 5, opacity: 0.4, type: 'polynomial', degree: 2}
					},
		      },
		   });		
		   
		   
		   
		   

			const rowHeight = 25;
			const chartExtra = 35;
			const chartWidth = 550;

			var chartRowCount = customerProjects.getNumberOfRows();
			var chartHeight = chartRowCount * rowHeight + chartExtra; 

			if (chartHeight < 180) {
				chartHeight = 180;			
			}

		   
			projectsChartDiv = document.getElementById('chart_projectGantt');
		   var projectsGanttChart = new google.visualization.Gantt(projectsChartDiv);
			var ganttOptions = {
				<% if not kioskMode then %>
					width: chartWidth,
				<% else %>
					width: 1000,
				<% end if %>
				height: chartHeight,
				gantt: {barHeight: 8},
			}

			google.visualization.events.addListener(projectsGanttChart, 'select', function() {
								
				var selectedItem = projectsGanttChart.getSelection()[0];
				if(selectedItem) {
					var projectID = customerProjects.getValue(selectedItem.row, 0);
					window.location.href = "/taskList.asp?customerID=<% =customerID %>&projectID=" + projectID + "&tab=overview";
				}

			});

			if (customerProjects.getNumberOfRows() > 0) { 
				projectsGanttChart.draw(customerProjects, ganttOptions);
			} else {
				projectsChartDiv.style.lineHeight = 10;
				projectsChartDiv.innerHTML = "No Project Data";
			}


			
// NOTE: The customer managers timeline chart is shown on two separate tabs (Overview and Managers) on this page. Since the
// available real estate is different, the charts are declared and drawn separately but use the same DataTable object.

			<% if not kioskMode then %>
				var managersTimeLineDiv = document.getElementById('chart_managerTimeline');
				var managersTimelineChart = new google.visualization.Timeline(managersTimeLineDiv);
				var timelineOptions = {
					timeline: {
						showRowLabels: true,
					},
					height: chartHeight,
					width: 435,
					fontSize: 6,
				}
				
	
				var managersTimeLineDiv2 = document.getElementById('tlCustomerManagers');
				var managersTimelineChart2 = new google.visualization.Timeline(managersTimeLineDiv2);
				var timelineOptions2 = {
					timeline: {
						showRowLabels: true,
					},
					height: chartHeight,
					width: 700,
					fontSize: 6,
				}
	
				if (customerManagers.getNumberOfRows() > 0) {
					managersTimelineChart.draw(customerManagers, timelineOptions);
					managersTimelineChart2.draw(customerManagers, timelineOptions2);
				} else {
					managersTimeLineDiv.style.lineHeight = 10;
					managersTimeLineDiv.innerHTML = "No Customer Managers Data";
					managersTimeLineDiv2.style.lineHeight = 10;
					managersTimeLineDiv2.innerHTML = "No Customer Managers Data";
				}
			<% end if %>


			google.visualization.events.addListener(completeCallHistory, 'ready', function() {
						
	 			var mccView = new google.visualization.DataView(callHistory);
	 			mccView.setRows(callHistory.getFilteredRows([
		 			{column: 0, value: 'MCC'}
	 			]));

	 			if (mccView.getNumberOfRows() > 0) {
					chart_mccCallHistory.setDataTable(mccView);
					chart_mccCallHistory.draw();
				} else {
					var mccChartDiv = document.getElementById('chart_mccCallHistory');
					mccChartDiv.style.lineHeight = 10;
					mccChartDiv.innerHTML = 'No MCC Data';	
				}



	 			var sacView = new google.visualization.DataView(callHistory);
	 			sacView.setRows(callHistory.getFilteredRows([
		 			{column: 0, value: 'SAC'}
	 			]));
	 				
	 			if (sacView.getNumberOfRows() > 0) {
					chart_sacCallHistory.setDataTable(sacView);
					chart_sacCallHistory.draw();
				} else {
					var sacChartDiv = document.getElementById('chart_sacCallHistory');
					sacChartDiv.style.lineHeight = 10;
					sacChartDiv.innerHTML = 'No SAC Data';	
				}



	 			var hfyView = new google.visualization.DataView(callHistory);
	 			hfyView.setRows(callHistory.getFilteredRows([
		 			{column: 0, value: 'HFY'}
	 			]));
	 			
	 			if (hfyView.getNumberOfRows() > 0) {
					chart_hfyCallHistory.setDataTable(hfyView);
					chart_hfyCallHistory.draw();
				} else {
					var hfyChartDiv = document.getElementById('chart_hfyCallHistory');
					hfyChartDiv.style.lineHeight = 10;
					hfyChartDiv.innerHTML = 'No HFY Data';	
				}

				


			});
			
			
		   var callDashboard = new google.visualization.Dashboard(document.getElementById('customerDashboard'));

			if (callHistory.getNumberOfRows() > 0) {
			   callDashboard.bind(callTypePicker, completeCallHistory);
				callDashboard.draw(callHistory);
			}

// 			var projectDashboard = new google.visualization.Dashboard(document.getElementById('customerDashboard'));
// 			projectDashboard.bind(projects);


		}
				
	</script>		 

	<style>
		.divTable{
			display: table;
			width: 100%;
		}
		
		.divTableRow {
			display: table-row;
		}
		
		.divTableHeading {
			background-color: #EEE;
			display: table-header-group;
		}
		
		.divTableCell, .divTableHead {
			border: 1px solid #999999;
			display: table-cell;
			padding: 3px 10px;
		}
		
		.divTableHeading {
			background-color: #EEE;
			display: table-header-group;
			font-weight: bold;
		}
		
		.divTableFoot {
			background-color: #EEE;
			display: table-footer-group;
			font-weight: bold;
		}
		
		.divTableBody {
			display: table-row-group;
		}
	</style>		

</head>

<body>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header mdl-layout--fixed-tabs">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
      <!-- Navigation. We hide it in small screens. -->
      <nav class="mdl-navigation mdl-layout--large-screen-only">
        <a class="mdl-navigation__link" href="home.asp">Home</a>
        <% if userPermitted(2) then %><a class="mdl-navigation__link" href="admin.asp">Admin</a><% end if %>
        <a class="mdl-navigation__link" href="login.asp?cmd=logout">Logout</a>
      </nav>
    </div>
    
    
   <% if not kioskMode then %>
<!-- =========================== TABS =========================== -->
    <div class="mdl-layout__tab-bar mdl-js-ripple-effect">
	 
      <a id="tab_overview" 	href="#fixed-tab-overview" 		class="mdl-layout__tab <% =activateOverview %>">Overview</a>
		<% if customerID <> 1 then %><!-- suppress the "CALLS" and "UTOPIAS" tabs for company = TEG -->
	      <a id="tab_calls" 		href="#fixed-tab-calls" 			class="mdl-layout__tab <% =activateCalls %>">Calls</a>
	      <a id="tab_utopias" 		href="#fixed-tab-utopias" 			class="mdl-layout__tab <% =activateUtopias %>">Utopias</a>
	   <% end if %>
      <a id="tab_projects" 	href="#fixed-tab-projects" 		class="mdl-layout__tab <% =activateProjects %>">Projects</a>
      <a id="tab_attributes" 	href="#fixed-tab-attributes" 		class="mdl-layout__tab <% =activateAttributes %>">Attributes</a>
      <a id="tab_values" 		href="#fixed-tab-values" 			class="mdl-layout__tab <% =activateValues %>">Values</a>
		<% if customerID <> 1 then %><!-- suppress the "Managers" tab for company = TEG -->
	      <a id="tab_managers" 	href="#fixed-tab-clientManagers" class="mdl-layout__tab <% =activateManagers %>">Managers</a>
	   <% end if %>
      <a id="tab_contacts" 	href="#fixed-tab-contacts" 		class="mdl-layout__tab <% =activateContacts %>">Contacts</a>
    </div>
<!-- =========================== TABS =========================== -->
	<% end if %>

  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

<!-- =========================== OVERVIEW TAB =========================== -->
<!-- =========================== OVERVIEW TAB =========================== -->  
   <section class="mdl-layout__tab-panel <% =activateOverview %>" id="fixed-tab-overview">
		<div id="customerDashboard" class="page-content">
			<!-- Your content goes here -->
	
			<!-- start grid -->
			<% if customerID <> 1 then %>
				<% if not kioskMode then %>
				<div class="mdl-grid">
					<div class="mdl-layout-spacer"></div>		
					<div class="mdl-cell mdl-cell--1-col mdl-shadow--2dp" align="center">
						<a href="customerOverview.asp?mode=kiosk&id=<% =request.querystring("id") %>" target="_new"	>
							<div>
								<img src="/images/ic_present_to_all_black_24dp_2x.png"><br>Kiosk Mode
							</div>
						</a>
					</div>
					<div class="mdl-layout-spacer"></div>		
				</div>
				<% end if %>
			<% end if %>
			<!-- end grid -->
			
			<!-- start grid -->
			<div class="mdl-grid">
				
				<div class="mdl-layout-spacer"></div>

				<!-- Call History for each call type -->
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">
					<div id="completeCallHistory" style="display: none"></div>
					<div id="callTypePicker" style="display: none"></div>
					<div id="chart_mccCallHistory"></div>	   	
				</div>
				
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">
					<div id="chart_sacCallHistory" style="vertical-align: middle"></div>	   	
				</div>

				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">
					<div id="chart_hfyCallHistory" style="vertical-align: middle"></div>	   	
				</div>

				<div class="mdl-layout-spacer"></div>

			</div>					
			<!-- end grid -->
				
						
			<!-- start grid -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
						
				<!-- jsonCalls Bar Chart -->
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">
					<div id="jsonCalls"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Call Data Found</div>	   	
				</div>
				
				<!-- TGIM Utilization -->
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">
					<div id="tgimUtilitization"></div>	   	
				</div>
				
				<!-- Cross Sales -->
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">
					<div id="crossSales"></div>	   	
				</div>
								
				<div class="mdl-layout-spacer"></div>		
				
			</div>
			<!-- end grid -->
			
			<!-- start grid -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<% if not kioskMode then %>
					<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp" align="center"><br>
				<% else %>
					<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp" align="center"><br>
				<% end if %>
					<div style="width: 100%"><h10><b>Projects</b></h10></div>
					<div id="chart_projectGantt"></div>	   	
				</div>

				<% if not kioskMode then %>
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center"><br>
						<div style="width: 100%"><h10><b>Managers</b></h10></div>
						<div id="chart_managerTimeline"></div>
					</div>
				<% end if %>
				
				<div class="mdl-layout-spacer"></div>
			</div>
			<!-- end grid -->
			
		</div>
		
	</section>



<!-- =========================== CALLS TAB =========================== -->
<!-- =========================== CALLS TAB =========================== -->  
   <section class="mdl-layout__tab-panel <% =activateCalls %>" id="fixed-tab-calls">
		<div class="page-content">
			<!-- Your content goes here -->
	
			<!-- DIALOG: New Call -->
			<dialog id="dialog_addCall" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Call</h4>
				<div class="mdl-dialog__content">
					<form id="form_addCall" action="annotateCalls.asp?cmd=addNew&customerID=<% =customerID %>" method="POST">

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_callType" name="add_callType" required>
								<option></option>
								<%
								SQL = "select id, name " &_
										"from customerCallTypes " &_
										"order by name "
								dbug(SQL)
								set rsCCT = dataconn.execute(SQL)
								while not rsCCT.eof 
									response.write("<option value=""" & rsCCT("id") & """>" & rsCCT("name") & "</option>")
									rsCCT.movenext 
								wend
								rsCCT.close
								set rsCCT = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_callType">Customer call type...</label>
						</div>


						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<input class="mdl-textfield__input" type="datetime-local" id="add_callStartDateTime" name="add_callStartDateTime" onblur="UpdateEndDateTime_onBlur(this)">
							<label class="mdl-textfield__label" for="add_callStartDateTime">Scheduled start...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy) and time (hh:mm)</span>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<input class="mdl-textfield__input" type="datetime-local" id="add_callEndDateTime" name="add_callEndDateTime">
							<label class="mdl-textfield__label" for="add_callEndDateTime">Scheduled end...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy) and time (hh:mm)</span>
						</div>
						<br>
						
						<br>
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_timezone" name="add_timezone" required>
								<%
								SQL = "select id, name, fullName from timezones order by utcOffset desc " 
								dbug(SQL)
								set rsTZ = dataconn.execute(SQL)
								while not rsTZ.eof
									if rsTZ("name") = "Central" then selected = "selected" else selected = "" end if 
									response.write("<option value=""" & rsTZ("id") & """" & selected & ">" & rsTZ("name") & "</option>")
									rsTZ.movenext 
								wend 
								rsTZ.close 
								set rsTZ = nothing 
								%>
								</select>
							<label class="mdl-textfield__label" for="add_timezone">Time zone...</label>
						</div>
						<br>

						<br>
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_callCopyUtopias">
						  <input type="checkbox" id="add_callCopyUtopias" name="add_callCopyUtopias" class="mdl-switch__input" checked value="copyUtopias">
						  <span class="mdl-switch__label">Copy Utopias</span>
						</label>
						<br>
						
						<br>
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_callCopyProjects">
						  <input type="checkbox" id="add_callCopyProjects" name="add_callCopyProjects" class="mdl-switch__input" checked value="copyProjects">
						  <span class="mdl-switch__label">Copy Projects</span>
						</label>
						<br>
						
						<input id="add_callCustomerID" name="add_callCustomerID" type="hidden" value="<% =customerID %>">
			
					</form>
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save & Open</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	

			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--8-col" align="left">
					<button id="button_newCall" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Call
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--8-col" align="center">
	
	
					<table id="tbl_clientCalls" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Call Lead</th>
								<th class="mdl-data-table__cell--non-numeric">Type</th>
								<th class="mdl-data-table__cell--non-numeric">Scheduled</th>
								<th class="mdl-data-table__cell--non-numeric">Actual</th>
								<th class="mdl-data-table__cell--numeric">Duration (mins)</th>
								<th class="mdl-data-table__cell--non-numeric">Actions</th>
							</tr>
						</thead>
				  		<tbody> 
					  	<%
						SQL = "select " &_
									"c.id, " &_
									"c.scheduledStartDateTime, " &_
									"c.startDateTime, " &_
									"c.endDateTime, " &_
									"c.name as callTypeName, " &_
									"c.timezone, u.firstName, " &_
									"tzSched.shortName as scheduledTimezone, " &_
									"tzActual.shortName as actualTimezone " &_
								"from customerCalls c " &_
								"left join cSuite..users u on (u.id = c.callLead) " &_
								"left join timezones tzSched on (tzSched.id = c.scheduledTimezone) " &_
								"left join timezones tzActual on (tzActual.id = c.actualTimezone) " &_
								"where c.customerID = " & customerID & " " &_
								"and (c.deleted = 0 or c.deleted is null) " &_
								"order by c.scheduledStartDateTime desc "
																
						dbug("Calls: " & SQL)
						set rsCall = dataconn.execute(SQL)
						while not rsCall.eof
							
							if not isNull(rsCall("scheduledStartDateTime")) then 
								scheduledStartDateTime = formatBrowserDateTime(rsCall("scheduledStartDateTime"))
								displayScheduledStartDateTime = formatBrowserDateTime(rsCall("scheduledStartDateTime")) & " (" & rsCall("scheduledTimezone") & ")"
							else 
								scheduledStartDateTime = ""
							end if
							
							if not isNull(rsCall("startDateTime")) then 
								startDateTime = formatBrowserDateTime(rsCall("startDateTime"))
								displayStartDateTime = formatBrowserDateTime(rsCall("startDateTime")) & " (" & rsCall("actualTimezone") & ")"
							else 
								startDateTime = ""
							end if
							
							if not isNull(rsCall("endDateTime")) then 
								endDateTime = formatBrowserDateTime(rsCall("endDateTime"))
							else 
								endDateTime = ""
							end if

							dbug("startDateTime: " & startDateTime & ", endDateTime: :" & endDateTime)
							if len(startDateTime) > 0 and len(endDateTime) > 0 then 
								duration = dateDiff("n",startDateTime,endDateTime)
							else 
								duration = ""
							end if
							

						  	%>
							<tr onclick="window.location.href='annotateCalls.asp?customerID=<% =customerID %>&callID=<% =rsCall("id") %>&tab=calls';" style="cursor: pointer" onmouseover="ToggleCallActionIcons('<% =rsCall("id") %>')" onmouseout="ToggleCallActionIcons('<% =rsCall("id") %>')" >
								<td class="mdl-data-table__cell--non-numeric"><% =rsCall("firstName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsCall("callTypeName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =displayScheduledStartDateTime %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =displayStartDateTime %></td>
								<td class="mdl-data-table__cell--numeric"><% =duration %></td>
		   					<td class="mdl-data-table__cell--non-numeric" style="text-align: center">
<!-- 									<img class="deleteCallButton" name="deleted" id="callDelete-<% =rsCall("id") %>" data-val="<% =rsCall("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer"> -->
									<i id="callDelete-<% =rsCall("id") %>" class="material-icons deleteCallButton" data-val="<% =rsCall("id") %>" style="float: right; vertical-align: text-bottom; display: none; cursor: pointer">delete_outline</i>
		   					</td>
							</tr>
							<%
							rsCall.movenext 
						wend 
						rsCall.close 
						set rsCall = nothing 
						%>
				  		</tbody>
					</table>
	
	
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
		</div>
		
	</section>



<!-- =========================== UTOPIAS TAB =========================== -->
<!-- =========================== UTOPIAS TAB =========================== -->  
   <section class="mdl-layout__tab-panel <% =activateUtopias %>" id="fixed-tab-utopias">
		<div class="page-content">
			<!-- Your content goes here -->
	
			<!-- DIALOG: New Contact -->
			<dialog id="dialog_addUtopia" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Utopia</h4>
				<div class="mdl-dialog__content">
					<form id="form_addCall" action="annotateCalls.asp?cmd=addNew&customerID=<% =customerID %>" method="POST">

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="xadd_callType" name="xadd_callType" required>
								<option></option>
								<%
								SQL = "select id, name " &_
										"from customerCallTypes " &_
										"order by name "
								dbug(SQL)
								set rsCCT = dataconn.execute(SQL)
								while not rsCCT.eof 
									response.write("<option value=""" & rsCCT("id") & """>" & rsCCT("name") & "</option>")
									rsCCT.movenext 
								wend
								rsCCT.close
								set rsCCT = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="xadd_callType">Customer call type...</label>
						</div>


						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<input class="mdl-textfield__input" type="datetime-local" id="add_callStartDateTime" name="add_callStartDateTime">
							<label class="mdl-textfield__label" for="add_callStartDateTime">Start date, time...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy) and time (hh:mm)</span>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<input class="mdl-textfield__input" type="datetime-local" id="add_callEndDateTime" name="add_callEndDateTime">
							<label class="mdl-textfield__label" for="add_callEndDateTime">End date, time...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy) and time (hh:mm)</span>
						</div>
						<br>
						
						<br>
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_timezone" name="add_timezone" required>
								<%
								SQL = "select name, fullName from timezones order by name " 
								dbug(SQL)
								set rsZZ = dataconn.execute(SQL)
								while not rsZZ.eof
									if rsZZ("name") = "Central" then selected = "selected" else selected = "" end if 
									response.write("<option value=""" & rsZZ("fullName") & """" & selected & ">" & rsZZ("name") & "</option>")
									rsZZ.movenext 
								wend 
								rsZZ.close 
								set rsZZ = nothing 
								%>
								</select>
							<label class="mdl-textfield__label" for="add_timezone">Time zone...</label>
						</div>
						<br>

						<br>
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_callCopyUtopias">
						  <input type="checkbox" id="add_callCopyUtopias" name="add_callCopyUtopias" class="mdl-switch__input" checked value="copyUtopias">
						  <span class="mdl-switch__label">Copy Utopias</span>
						</label>
						<br>
						
						<br>
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_callCopyProjects">
						  <input type="checkbox" id="add_callCopyProjects" name="add_callCopyProjects" class="mdl-switch__input" checked value="copyProjects">
						  <span class="mdl-switch__label">Copy Projects</span>
						</label>
						<br>
						
						<input id="add_callCustomerID" name="add_callCustomerID" type="hidden" value="<% =customerID %>">
			
					</form>
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save & Open</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	

			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--7-col" align="left">
					<button id="button_newCall" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Utopia
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--9-col" align="center">
	
	
					<div class="divTable">

				  		<div class="divTableBody"> 
					  	<%
						SQL = "select id, narrative, customerVisible " &_
								"from customerUtopias " &_
								"where customerID = " & customerID & " "
																
						dbug("Utopias: " & SQL)
						set rsUtopias = dataconn.execute(SQL)
						while not rsUtopias.eof
						  	%>
							<div class="divTableRow">
								<div class="divTableCell">

									<div id="utopia_<% =rsUtopias("id") %>" style="border: none; text-align: left">
										<% =rsUtopias("narrative") %>
									</div>									

								</div>
							</div>
							<%
							rsUtopias.movenext 
						wend 
' 						rsUtopias is used below by the Quilljs library, so don't close it here
' 						rsUtopias.close 
' 						set rsUtopias = nothing 
						%>
				  		</div>
					</div>
	
	
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
		</div>
		
	</section>



<!----------------------------- PROJECTS TAB ----------------------------->
<!----------------------------- PROJECTS TAB ----------------------------->  
   <section class="mdl-layout__tab-panel <% =activateProjects %>" id="fixed-tab-projects">
		<div class="page-content">
			<!-- Your content goes here -->
	
			<!-- DIALOG: New Project -->
			<dialog id="dialog_addProject" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Project</h4>
				<div class="mdl-dialog__content">
					<form id="form_addProject">
			
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_projectProduct" name="add_projectProduct" onchange="ProductName_onChange(this)">
								<option></option>
								<%
								SQL = "select id, name from products order by name " 
								dbug(SQL)
								set rsProd = dataconn.execute(SQL)
								while not rsProd.eof 
									response.write("<option value=""" & rsProd("id") & """>" & rsProd("name") & "</option>")
									rsProd.movenext 
								wend
								rsProd.close
								set rsProd = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_projectProduct">Process...</label>
							<span class="mdl-textfield__error">Select a process</span>
						</div>
						
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="add_projectName" name="add_projectName" value="" required> 
						    <label class="mdl-textfield__label" for="add_projectName">Project name...</label>
						</div>

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_projectManager" name="add_projectManager" required >
								<option></option>
								<%
								SQL = "select id, concat(firstName, ' ', lastName) as fullName " &_
										"from cSuite..users " &_
										"where active = 1 " &_
										"and customerID = 1 " &_
										"order by 2 "
								dbug(SQL)
								set rsPM = dataconn.execute(SQL)
								while not rsPM.eof 
									response.write("<option value=""" & rsPM("id") & """>" & rsPM("fullName") & "</option>")
									rsPM.movenext 
								wend
								rsPM.close
								set rsPM = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_projectManager">Project manager...</label>
						</div>
						
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label is-dirty">
							<input class="mdl-textfield__input" type="date" id="add_projectStartDate" pattern="<% =dateValidationPattern("simple") %>" required>
							<label class="mdl-textfield__label" for="add_projectStartDate">Start date...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy)</span>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						   <input class="mdl-textfield__input" type="date" id="add_projectEndDate" pattern="<% =dateValidationPattern("simple") %>" required>
						   <label class="mdl-textfield__label" for="add_projectEndDate">End date...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy)</span>
						</div>
						<input id="add_projectID" name="add_projectID" type="hidden">
						<input id="add_projectCustomerID" name="add_projectCustomerID" type="hidden" value="<% =customerID %>">
			
					</form>
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog>
			<!-- DIALOG: New Project -->


			<!-- DIALOG: Clone A Project -->
			<dialog id="dialog_cloneProject" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Project Template</h4>
				<div class="mdl-dialog__content">
					<form id="form_cloneProject">

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="clone_sourceProjectName" name="clone_sourceProjectName" value="" disabled> 
						    <label class="mdl-textfield__label" for="clone_sourceProjectName">Source project...</label>
						</div>

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="clone_projectName" name="clone_projectName" value="" required autocomplete="off"> 
						    <label class="mdl-textfield__label" for="clone_projectName">Target template...</label>
						</div>


						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="clone_projectNameSelect" onchange="TemplateNameSelect_onChange(this)" size="5">
								<%
								SQL = "select id, name " &_
										"from projectTemplates " &_
										"order by name "
								dbug(SQL)
								set rsPT = dataconn.execute(SQL)
								while not rsPT.eof 
									response.write("<option value=""" & rsPT("id") & """>" & rsPT("name") & "</option>")
									rsPT.movenext 
								wend
								rsPT.close
								set rsPT = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="clone_projectNameSelect">Existing project templates...</label>
						</div>

						<input type="hidden" id="clone_sourceProjectID" name="clone_sourceProjectID">

					</form>
				</div>

				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>

			</dialog>
			<!-- DIALOG: Clone A Project -->
	
				
			
			<!-- DIALOG: New Project From Template -->
			<dialog id="dialog_addProjectFromTemplate" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Project From Template</h4>
				<div class="mdl-dialog__content">
					<form id="form_cloneProject">

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_projectSourceTemplate" onchange="TemplateSourceSelect_onChange(this)">
								<option></option>
								<%
								SQL = "select id, name " &_
										"from projectTemplates " &_
										"order by name "
								dbug(SQL)
								set rsPT = dataconn.execute(SQL)
								while not rsPT.eof 
									response.write("<option value=""" & rsPT("id") & """>" & rsPT("name") & "</option>")
									rsPT.movenext 
								wend
								rsPT.close
								set rsPT = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="clone_projectNameSelect">Select a template...</label>
						</div>
						
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="add_projectNameFromTemplate" name="add_projectNameFromTemplate"> 
						    <label class="mdl-textfield__label" for="add_projectNameFromTemplate">Project name...</label>
						</div>

						<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="anchorType-start">
							<input type="radio" id="anchorType-start" class="mdl-radio__button" name="anchorType" value="1" checked onchange="AnchorType_onChange(this)">
							<span class="mdl-radio__label">Start on</span>
						</label>
						<br>
						<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="anchorType-finish">
							<input type="radio" id="anchorType-finish" class="mdl-radio__button" name="anchorType" value="2" onchange="AnchorType_onChange(this)">
							<span class="mdl-radio__label">Finish by</span>
						</label>						

						<div id="anchorDate_div" class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						   <input class="mdl-textfield__input" type="date" id="add_anchorDate" min="<% =formatHTML5Date(date()) %>">
						   <label id="anchorDate_label" class="mdl-textfield__label" for="add_anchorDate">Start date (minimum: <% =formatHTML5Date(date()) %>)...</label>
						</div>

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_projectManagerFromTemplate" name="add_projectManagerFromTemplate">
								<option></option>
								<%
								SQL = "select id, concat(firstName, ' ', lastName) as fullName " &_
										"from cSuite..users " &_
										"where active = 1 " &_
										"and customerID = 1 " &_
										"order by 2 "
								dbug(SQL)
								set rsPM = dataconn.execute(SQL)
								while not rsPM.eof 
									response.write("<option value=""" & rsPM("id") & """>" & rsPM("fullName") & "</option>")
									rsPM.movenext 
								wend
								rsPM.close
								set rsPM = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_projectManagerFromTemplate">Project manager...</label>
						</div>
						
						<input type="hidden" id="projectFromTemplateCustomerID" value="<% =customerID %>">

						<input type="hidden" id="clone_sourceProjectID" name="clone_sourceProjectID">

					</form>
				</div>

				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>

			</dialog>
			<!-- DIALOG: New Project From Template -->
	
				
			
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--7-col" align="left">
					<button id="button_newProject" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Project
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
				
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--7-col" align="center">
	
	
					<table id="tbl_clientProjects" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric"></th>
								<th class="mdl-data-table__cell--non-numeric">Name</th>
								<th class="mdl-data-table__cell--non-numeric">Process</th>
								<th class="mdl-data-table__cell--non-numeric">Primary PM</th>
								<th class="mdl-data-table__cell--non-numeric">Start Date</th>
								<th class="mdl-data-table__cell--non-numeric">End Date</th>
								<th class="mdl-data-table__cell--non-numeric">Status</th>
								<th class="mdl-data-table__cell--non-numeric">Completed</th>
								<th class="mdl-data-table__cell--non-numeric" style="text-align: center;">Actions</th>
							</tr>
						</thead>
				  		<tbody> 
					  	<%
						SQL = "select proj.id, proj.name, prod.name as productName, proj.startDate, proj.endDate, proj.complete, ps.type, ps.type, concat(u.firstName, ' ', u.lastName) as fullName " &_
								"from projects proj " &_
								"left join products prod on (prod.id = proj.productID) " &_
								"left join " &_
									"( " &_
									"select projectID, type " &_
									"from projectStatus " &_
									"where updatedDateTime = (select max(updatedDateTime) from projectStatus) " &_
									") ps on ps.projectID = proj.id " &_
								"left join cSuite..users u on (u.id = proj.projectManagerID) " &_
								"where proj.customerID = " & request.querystring("id") & " " &_
								"and (prod.deleted = 0 or prod.deleted is null) " &_
								"order by proj.startDate, prod.name "
						dbug("Projects: " & SQL)
						set rsProj = dataconn.execute(SQL)
						while not rsProj.eof
													
							if userPermitted(39) then 
								if templateFromIncompleteProj = "true" then 
									showCloneButton = true 
								else 
									if rsProj("complete") then 
										showCloneButton = true
									else 
										showCloneButton = false
									end if
								end if 
							end if
							
						  	%>
							<tr onclick="window.location.href='taskList.asp?customerID=<% =customerID %>&projectID=<% =rsProj("id") %>&tab=projects';" style="cursor: pointer">
								<td class="mdl-data-table__cell--non-numeric">
									<i class="material-icons">
									<% if cInt(rsProj("id")) = 1 then %>
										star_border	
									<% else %>
										star
									<% end if %>
									</i>
								</td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsProj("Name") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsProj("productName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsProj("fullName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rsProj("startDate"),2) %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rsProj("endDate"),2) %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsProj("type") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsProj("complete") %></td>
		   					<td class="mdl-data-table__cell--non-numeric" style="text-align: right">

									<% if showCloneButton then %>
										<button type="button" id="button_createTemplate-<% =rsProj("id") %>" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsProj("id") %>" onclick="createTemplate_onClick(this);">
										  <i class="material-icons">file_copy</i>
										</button>
										<div for="button_createTemplate-<% =rsProj("id") %>" class="mdl-tooltip">Create project template</div>							
									<% end if %>	

									<button type="button" id="button_editPROJECGT-<% =rsProj("id") %>" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsProj("id") %>" onclick="EditProject_onClick(this);">
									  <i class="material-icons">mode_edit</i>
									</button>
									<div for="button_editPROJECGT-<% =rsProj("id") %>" class="mdl-tooltip">Edit project info</div>							
									<img name="deleted" id="projectDelete-<% =rsProj("id") %>" data-val="<% =rsProj("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer" onclick="ProjectDelete_onClick(this)">
									<div for="projectDelete-<% =rsProj("id") %>" class="mdl-tooltip">Delete project</div>							
									
		   					</td>
							</tr>
							<%
							rsProj.movenext 
						wend 
						rsProj.close 
						set rsProj = nothing 
						%>
				  		</tbody>
					</table>
	
	
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
		</div>
		
	</section>



<!----------------------------- ATTRIBUTES TAB ----------------------------->
<!----------------------------- ATTRIBUTES TAB ----------------------------->

   <section class="mdl-layout__tab-panel <% =activateAttributes %>" id="fixed-tab-attributes">
		<div class="page-content">
	
			<!-- DIALOG: New Annotation -->
			<dialog id="dialog_addAttribute" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Attribute</h4>
				<div class="mdl-dialog__content">
					<form id="form_addAnnotation">
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_attributeTypeID" required onchange="AttributeType_onChange(this)">
								<option></option>
								<%
								SQL = "select id, name " &_
										"from attributeTypes " &_
										"order by name "
								dbug(SQL)
								set rsAttr = dataconn.execute(SQL)
								while not rsAttr.eof 
									response.write("<option value=""" & rsAttr("id") & """>" & rsAttr("name") & "</option>")
									rsAttr.movenext 
								wend
								rsAttr.close
								set rsAttr = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_attributeTypeId">Attribute type...</label>
						</div>


						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_ubprSection" onchange="UbprSection_onChange(this)">
								<option></option>
								<option>Internal</option>
									<%
									SQL = "select distinct ubprSection from metric where internalMetricInd = 0 order by ubprSection " 
									dbug(SQL)
									set rsSect = dataconn.execute(SQL)
									while not rsSect.eof 
										response.write("<option value=""" & rsSect("ubprSection") & """>" & rsSect("ubprSection") & "</option>")
										rsSect.movenext 
									wend 
									rsSect.close 
									set rsSect = nothing 
									%>
								</select>
							<label class="mdl-textfield__label" for="add_ubprSection">UBPR section...</label>
						</div>


						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_annotationMetricID">
								<option></option>
								</select>
							<label class="mdl-textfield__label" for="add_annotationMetricID">Associated metric...</label>
						</div>




						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="date" id="add_annotationDate" pattern="<% =dateValidationPattern("simple") %>">
						    <label id="attributeDateLabel" class="mdl-textfield__label" for="add_annotationDate">Start date...</label>
							<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy)</span>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<textarea class="mdl-textfield__input" type="text" rows="3" id="add_annotationNarrative"></textarea>
							<label class="mdl-textfield__label" for="add_AnnotationNarrative">Narrative</label>
						</div>
					
						<div id="addMetricValueContainer" class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="add_metricValue">
						    <label class="mdl-textfield__label" for="add_metricValue">Target metric value...</label>
						</div>
		
	
						<input id="add_annotationCustomerID" type="hidden" value="<% =customerID %>">
			
					</form>
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--7-col" align="left">
					<button id="button_newAttribute" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Attribute
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				
				<div class="mdl-cell mdl-cell--10-col" align="center">
					
					<table id="tbl_customerAnnotations" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Attribute Type</th>
								<th id="attrDateHeader" class="mdl-data-table__cell--non-numeric">Date</th>
									<div class="mdl-tooltip" for="attrDateHeader">The date on a chart or graph with an inflection or trend to which an annotation refers.</div>
								<th class="mdl-data-table__cell--non-numeric">Narrative</th>
								<th class="mdl-data-table__cell--non-numeric">Added By</th>
								<th class="mdl-data-table__cell--non-numeric">Metric</th>
								<th class="mdl-data-table__cell--non-numeric">Goal Value</th>
								<th class="mdl-data-table__cell--non-numeric">Actions</th>
							</tr>
						</thead>
							<tbody> 
						<%
						SQL = "select ca.id, a.name as attributeType, a.description as attributeDescription, ca.attributeDate, ca.narrative, ca.addedBy, m.name as metricName, ca.attributeValue, u.firstName + ' ' + u.lastName as userName  " &_
								"from customerAnnotations ca " &_
								"left join metric m on (m.id = ca.metricID) " &_
								"left join cSuite..users u on (u.id = ca.addedBy) " &_
								"left join attributeTypes a on (a.id = ca.attributeTypeID) " &_
								"where ca.customerID = " & request("id") & " " 
					
						dbug(SQL)
						set rs = dataconn.execute(SQL)
						while not rs.eof
							%>
							<tr>
								<td id="attr<% =rs("id") %>" class="mdl-data-table__cell--non-numeric"><% =rs("attributeType") %></td>
									<div class="mdl-tooltip" for="attr<% =rs("id") %>"><% =rs("attributeDescription") %></div>
								<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rs("attributeDate"),2) %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("narrative") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("userName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("metricName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("attributeValue") %></td>
								<td class="mdl-data-table__cell--non-numeric">
									<% if userPermitted(18) then %>
										<img src="/images/ic_edit_black_24dp_1x.png" data-val="<% =rs("id") %>" onclick="CustomerAnnotationEdit_onClick(this)">
									<% end if %>
									<img name="deleted" id="annotationDelete-<% =rs("id") %>" data-val="<% =rs("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer" onclick="AnnotationDelete_onClick(this,<% =rs("id") %>)">
								</td>
							</tr>			
							<%
							rs.movenext 
						wend
						rs.close 
						set rs = nothing
						%>
					
							</tbody>
					</table>		    			    
								
				</div>
				
				<div class="mdl-layout-spacer"></div>
				
			</div><!-- end grid -->
			
		</div>
		
	</section>



<!----------------------------- VALUES TAB ----------------------------->
<!----------------------------- VALUES TAB ----------------------------->  
   <section class="mdl-layout__tab-panel <% =activateValues %>" id="fixed-tab-values">
		<div class="page-content">
			<!-- Your content goes here -->
			<br>
			<!-- start grid -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
						
				<!-- TABLE Chart -->
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp" style="text-align: center; height: 100%">
					<div id="valuesTable"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Values Found</div>	   	
				</div>
								
				<div class="mdl-layout-spacer"></div>		
				
			</div>
			<!-- end grid -->
			
		</div>
	</section>



<!-- ========================== CLIENT MANAGERS TAB ========================== -->
<!-- ========================== CLIENT MANAGERS TAB ========================== -->

   <section class="mdl-layout__tab-panel <% =activateManagers %>" id="fixed-tab-clientManagers">
		<div class="page-content">	
	
			<br><br>
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--6-col" align="center">
					
					<table id="tbl_clientManagers" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Name</th>
								<th class="mdl-data-table__cell--non-numeric">Title</th>
								<th class="mdl-data-table__cell--non-numeric">Primary</th>
								
								<%
								SQL = "select id, name from customerManagerTypes where id <> 0 order by seq "
								dbug(SQL)
								set rsMT = dataconn.execute(SQL)
								while not rsMT.eof 
									%>
									<th class="mdl-data-table__cell--non-numeric"><% =rsMT("name") %></th>
									<%
									rsMT.movenext 
								wend 
								' leave rsMT open for use in the body of the table below
								%>
							</tr>
						</thead>
				  		<tbody> 
					  	<%
						' temp variable for the currently selected primary contact
						primaryContactID = ""
						
						' userList gets a comma-delimited list of users associated with permission "35" -- aka "Allow Customer Manager"
						userList = usersWithPermission(35,"id")
						
						if len(userList) > 0 then 

							SQL = "select u.id, u.firstName, u.lastName, u.title, cm.userID, cm.active as primaryInd " &_
									"from cSuite..users u " &_
									"left join customerManagers cm on (cm.userID = u.id and cm.managerTypeID = 0 and cm.endDate is null) " &_
									" where u.id in (" & userList & ") " &_ 
									"order by u.lastName, u.firstName " 								
							dbug("Client Managers: " & SQL)
							set rsCM = dataconn.execute(SQL)
							while not rsCM.eof
							  	%>
								<tr>
									<td class="mdl-data-table__cell--non-numeric"><% =rsCM("firstName") & " " & rsCM("lastName") %></td>
									<td class="mdl-data-table__cell--non-numeric"><% =rsCM("title") %></td>
									<td class="mdl-data-table__cell--non-numeric" style="text-align: center;">
										<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="primary-<% =rsCM("id") %>">
											<% 
											if rsCM("primaryInd") then 
												checked = "checked" 
												primaryContactID = "primary-" & rsCM("id") 
											else 
												checked = "" 
											end if 
											%>
											<input class="mdl-radio__button" id="primary-<% =rsCM("id") %>" data-val="<% =rsCM("id") %>" name="primary" type="radio" <% =checked %> onclick="ClientManagerUpdatePrimary_onClick(this,<% =customerID %>)">
										</label>
									</td>
									<%
									' rsMT is created/opened in the <thead> of this table
				
									rsMT.movefirst
									while not rsMT.eof 
										dbug("determine if user: " & rsCM("id") & " is active for customerManagerType: " & rsMT("id"))
										if len(rsCM("id")) > 0 then 
											SQL = "select active from customerManagers " &_
													"where customerID = " & customerID & " " &_
													"and userID = " & rsCM("id") & " " &_
													"and managerTypeID = " & rsMT("id") & " " 
											set rsActive = dataconn.execute(SQL)
											if not rsActive.eof then 
												dbug("row found for user...")
												if rsActive("active") then 
													checked = "checked"
													dbug("...and active")
												else 
													checked = ""
													dbug("...not active")
												end if 
											else 
												dbug("no row found for user")
												checked = ""
											end if 
											rsActive.close 
											set rsActive = nothing 
										else 
											checked = ""
											dbug("nothing to check")
										end if 
										%>
										<td class="mdl-data-table__cell--numeric" style="text-align: center;">

											<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="c:<% =rsCM("id") %>-t:<% =rsMT("ID") %>" >
												<input type="checkbox" id="c:<% =rsCM("id") %>-t:<% =rsMT("id") %>" cmID="<% =rsCM("id") %>" mtID="<% =rsMT("id") %>" class="mdl-checkbox__input" onclick="UpdateCustomerManager_onClick(this, <% =customerID %>)" <% =checked %> >
											</label>
											
										</td>
										<%
										rsMT.movenext 
									wend 
									%>
								</tr>
								<%
								rsCM.movenext 
							wend 
							rsCM.close 
							set rsCM = nothing 
							
						else 
							
							response.write("No TEG users have 'Allow user to act as a customer manager' permission")
							
						end if

						rsMT.close 
						set rsMT = nothing 
						%>
				  		</tbody>
					</table>
					<input type="hidden" id="primaryContactID" value="<% =primaryContactID %>" />
												
				</div>
				<div class="mdl-layout-spacer"></div>

				
			</div><!-- end grid -->
   	

			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
	
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp" align="center"><br>
					<div>Timeline</div>
						<div id="tlCustomerManagers"></div>
				</div>
	
				<div class="mdl-layout-spacer"></div>
				
			</div>
	
			
			
		</div>

	</section>



<!----------------------------- CONTACTS TAB ----------------------------->
<!----------------------------- CONTACTS TAB ----------------------------->

   <section class="mdl-layout__tab-panel <% =activateContacts %>" id="fixed-tab-contacts">
		<div class="page-content">
			<!-- Your content goes here -->
	
			<!-- DIALOG: New Contact -->
			<dialog id="dialog_addContact" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Contact</h4>
				<div class="mdl-dialog__content">
					<form id="form_addContact">
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="add_contactName" required autocomplete="off">
						    <label class="mdl-textfield__label" for="add_contactName">Name...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="add_contactTitle">
						    <label class="mdl-textfield__label" for="add_contactTitle">Title...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_contactRole" name="add_contactRole">
								<option></option>
								<%
								SQL = "select id, name " &_
										"from customerContactRoles " &_
										"order by name "
								dbug(SQL)
								set rsCCR = dataconn.execute(SQL)
								while not rsCCR.eof 
									response.write("<option value=""" & rsCCR("id") & """>" & rsCCR("name") & "</option>")
									rsCCR.movenext 
								wend
								rsCCR.close
								set rsCCR = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_contactRole">Role...</label>
						</div>

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="add_contactGrade">
						    <label class="mdl-textfield__label" for="add_contactGrade">ZeroRisk type...</label>
						</div>
		
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_contactDepositInd">
							<input type="checkbox" id="add_contactDepositInd" class="mdl-switch__input" checked>
							<span class="mdl-switch__label">Deposit?</span>
						</label>
		
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_contactLoanInd">
							<input type="checkbox" id="add_contactLoanInd" class="mdl-switch__input">
							<span class="mdl-switch__label">Loan?</span>
						</label>
						<br><br>
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="add_contactCallAttendeeInd">
							<input type="checkbox" id="add_contactCallAttendeeInd" class="mdl-switch__input">
							<span class="mdl-switch__label">Call attendee?</span>
						</label>
		
						<input id="add_contactID" type="hidden" value="">
						<input id="add_contactCustomerID" type="hidden" value="<% =customerID %>">
			
					</form>
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--6-col" align="left">
					<button id="button_newContact" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Contact
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--6-col">
	
					<table id="tbl_customerContacts" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Name</th>
								<th class="mdl-data-table__cell--non-numeric">Title</th>
								<th class="mdl-data-table__cell--non-numeric">Role</th>
								<th class="mdl-data-table__cell--non-numeric">Deposit?</th>
								<th class="mdl-data-table__cell--non-numeric">Loan?</th>
								<th class="mdl-data-table__cell--non-numeric" style="width: 50px">ZeroRisk</th>
								<th class="mdl-data-table__cell--non-numeric">Call<br>Attendee?</th>
								<th class="mdl-data-table__cell--numeric">Actions</th>
							</tr>
						</thead>
				  		<tbody> 
			
						<%
						SQL = "select c.id, c.name, c.title, c.depositInd, c.loanInd, c.zeroRiskGrade, c.callAttendee, c.contactRoleID, r.name as roleName " &_
								"from customerContacts c " &_
								"left join customerContactRoles r on (r.id = c.contactRoleID) " &_
								"where customerID = " & request.querystring("id") & " "
						dbug(SQL)
						set rsCC = dataconn.execute(SQL)
						while not rsCC.eof 
	
							if rsCC("depositInd") then 
								depositIndChecked = "checked"
							else 
								depositIndChecked = ""
							end if
	
							if rsCC("loanInd") then 
								loanIndChecked = "checked"
							else 
								loanIndChecked = ""
							end if
							
							if rsCC("callAttendee") then 
								callAttendeeChecked = "checked"
							else 
								callAttendeeChecked = ""
							end if
							
							%>
							
							
							<tr>
								<td class="mdl-data-table__cell--non-numeric"><% =rsCC("name") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsCC("title") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsCC("roleName") %></td>
	
								<td class="mdl-data-table__cell--non-numeric">
									<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="contactDepositInd-<% =rsCC("id") %>">
										<input type="checkbox" id="contactDepositInd-<% =rsCC("id") %>" data-val="<% =rsCC("id") %>" class="mdl-switch__input" <% =depositIndChecked %> onclick="ClientContactToggle_onClick(this,'depositInd')" />
									</label>
								</td>
								
								<td class="mdl-data-table__cell--non-numeric">
									<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="contactLoanInd-<% =rsCC("id") %>">
										<input type="checkbox" id="contactLoanInd-<% =rsCC("id") %>" data-val="<% =rsCC("id") %>" class="mdl-switch__input" <% =loanIndChecked %> onclick="ClientContactToggle_onClick(this,'loanInd')" />
									</label>
								</td>
	
								<td class="mdl-data-table__cell--non-numeric" style="width: 100px"><% =rsCC("zeroRiskGrade") %></td>
								
								<td class="mdl-data-table__cell--non-numeric">
									<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="callAttendee-<% =rsCC("id") %>">
										<input type="checkbox" id="callAttendee-<% =rsCC("id") %>" data-val="<% =rsCC("id") %>" class="mdl-switch__input" <% =callAttendeeChecked %> onclick="ClientContactToggle_onClick(this,'callAttendee')" />
									</label>
								</td>
	
		   					<td class="mdl-data-table__cell--non-numeric">

									<button type="button" id="button_editContact" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rsCC("id") %>" onclick="EditContact_onClick(this);">
									  <i class="material-icons">mode_edit</i>
									</button>								

									<img name="deleted" id="contactDelete-<% =rsCC("id") %>" data-val="<% =rsCC("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer" onclick="CustomerContactDelete_onClick(this)">
		   					</td>
		   					
							</tr>
	
	
							
							<%
							rsCC.movenext 
	
						wend 
						rsCC.close 
						set rsCC = nothing 
						%>
	
				  		</tbody>
					</table>
				</div>
				<div class="mdl-layout-spacer"></div>
				
			</div><!-- end grid -->
		</div>
	</section>



	</main>
	
</div>

<!-- #include file="includes/pageFooter.asp" -->

<script src="dialog-polyfill.js"></script>  
<script>
	
	var deleteCallButtons = document.querySelectorAll('.deleteCallButton'), i;
	
	if (deleteCallButtons != null) {
		
		for (i = 0; i < deleteCallButtons.length; ++i) {
			deleteCallButtons[i].addEventListener('click', function(event) {
				CallDelete_onClick(this);
				event.cancelBubble = true;
			})
		}
		
	}
	
	
// New Call Controls
	var dialog_addCall = document.querySelector('#dialog_addCall');
	var button_newCall = document.querySelector('#button_newCall');	
	if (! dialog_addCall.showModal) {
		dialogPolyfill.registerDialog(dialog_addCall);
	}	
	button_newCall.addEventListener('click', function() {
		
		var currTime = moment().format('YYYY-MM-DDTHH:mm');
		
		document.getElementById('add_callStartDateTime').value = currTime;
		document.getElementById('add_callStartDateTime').parentNode.classList.add('is-dirty');
		
		document.getElementById('add_callEndDateTime').value = moment().add(1, 'hours').format('YYYY-MM-DDTHH:mm');
		document.getElementById('add_callEndDateTime').parentNode.classList.add('is-dirty');
		
		dialog_addCall.showModal();
		
	});
	dialog_addCall.querySelector('.cancel').addEventListener('click', function() {
		dialog_addCall.close();
	});
	dialog_addCall.querySelector('.save').addEventListener('click', function() {
/* 		dialog_addCall.close(); */
/*
		alert('add_callType: ' + document.getElementById('add_callType').value);
		alert('add_callDate: ' + document.getElementById('add_callDate').value);
		alert('add_callTime: ' + document.getElementById('add_callTime').value);
		alert('add_callCopyUtopias: ' + document.getElementById('add_callCopyUtopias').checked);
		alert('add_callCopyProjects: ' + document.getElementById('add_callCopyProjects').checked);
*/
		
		document.getElementById('form_addCall').submit();		
	});
	
	

	
// add/edit Projects

	var dialog_addProject 					= document.querySelector('#dialog_addProject');
	var dialog_cloneProject 				= document.querySelector('#dialog_cloneProject');	
	var dialog_addProjectFromTemplate 	= document.querySelector('#dialog_addProjectFromTemplate');

	var button_newProject					= document.querySelector('#button_newProject');	
	var editMode;

	// register all three dialogs
	if (! dialog_addProject.showModal) {
		dialogPolyfill.registerDialog(dialog_addProject);
	}	
	if (! dialog_cloneProject.showModal) {
		dialogPolyfill.registerDialog(dialog_cloneProject);
	}	
	if (! dialog_addProjectFromTemplate.showModal) {
		dialogPolyfill.registerDialog(dialog_addProjectFromTemplate);
	}	

	// event listener for click on  "New Project" button...
	button_newProject.addEventListener('click', function() {
		editMode = 'add';
		if (confirm('Do you want to use a template?')) {
			dialog_addProjectFromTemplate.showModal();
			document.getElementById('add_anchorDate').parentNode.classList.add('is-dirty');
		} else {
			dialog_addProject.showModal();
			document.getElementById('add_projectStartDate').parentNode.classList.add('is-dirty');
			document.getElementById('add_projectEndDate').parentNode.classList.add('is-dirty');			
		}
	});

	// event listeners for concel/save on dialog_addProject
	dialog_addProject.querySelector('.cancel').addEventListener('click', function() {
		editMode = '';
		dialog_addProject.close();
	});
	dialog_addProject.querySelector('.save').addEventListener('click', function() {
		editMode = '';
		AddProject_onSave(dialog_addProject)
		dialog_addProject.close();
	});


	// event listeners for concel/save on dialog_cloneProject (create a template from a project)
	dialog_cloneProject.querySelector('.cancel').addEventListener('click', function() {
		editMode = '';
		dialog_cloneProject.close();
	});
	dialog_cloneProject.querySelector('.save').addEventListener('click', function() {
		CreateTemplate_onSave(dialog_addProject)
		dialog_cloneProject.close();
	});

	// event listeners for concel/save on dialog_addProjectFromTemplate 
	dialog_addProjectFromTemplate.querySelector('.cancel').addEventListener('click', function() {
		editMode = '';
		dialog_addProjectFromTemplate.close();
	});
	dialog_addProjectFromTemplate.querySelector('.save').addEventListener('click', function() {
		CreateProjectFromTemplate_onSave(dialog_addProjectFromTemplate)
		dialog_addProjectFromTemplate.close();
	});



// add/edit Attribute Dialog Controls
	var dialog_addAttribute = document.querySelector('#dialog_addAttribute');
	var button_newAttribute = document.querySelector('#button_newAttribute');	
	if (! dialog_addAttribute.showModal) {
		dialogPolyfill.registerDialog(dialog_addAttribute);
	}	
	button_newAttribute.addEventListener('click', function() {
		dialog_addAttribute.showModal();
		document.getElementById('add_annotationDate').parentNode.classList.add('is-dirty');
	});
	dialog_addAttribute.querySelector('.cancel').addEventListener('click', function() {
		dialog_addAttribute.close();
	});
	dialog_addAttribute.querySelector('.save').addEventListener('click', function() {
		AddAnnotation_onSave(dialog_addAttribute)
		dialog_addAttribute.close();
	});


// add/edit Contact Dialog Controls
	var dialog_addContact = document.querySelector('#dialog_addContact');
	var button_newContact = document.querySelector('#button_newContact');	
	if (! dialog_addContact.showModal) {
		dialogPolyfill.registerDialog(dialog_addContact);
	}	
	button_newContact.addEventListener('click', function() {
		dialog_addContact.showModal();
	});
	dialog_addContact.querySelector('.cancel').addEventListener('click', function() {
		dialog_addContact.close();
	});
	dialog_addContact.querySelector('.save').addEventListener('click', function() {
		AddContact_onSave(dialog_addContact)
		dialog_addContact.close();
	});


</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>