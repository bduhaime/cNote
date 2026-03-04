<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

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
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(55)
	

customerID = request.querystring("id")
%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customer overview")
templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")


chartEndDate = date()
chartStartDate = dateAdd("yyyy",-2,chartEndDate)
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
	
	SQL =	"select " &_
				"projects.id as projID, " &_
				"case when projects.name > '' then " &_
					"replace(replace(replace(projects.name,'&trade;','\u2122'),'(tm)','\u2122'),'â„¢','\u2122') " &_
				"else " &_
					"replace(replace(replace(products.name,'&trade;','\u2122'),'(tm)','\u2122'),'â„¢','\u2122') " &_
				"end as projectName, " &_
				"products.name as productName, " &_
				"projects.startDate, " &_
				"projects.endDate, " &_
				"projects.complete " &_
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
				"( " &_
					"select ct.shortName, ct.idealFrequencyDays, max(endDateTime) as lastCallDate " &_
					"from customerCallTypes ct " &_
					"left join customerCalls cc on (cc.callTypeID = ct.id) " &_
					"where cc.customerID = " & customerID & " " &_
					"group by ct.shortName, ct.idealFrequencyDays " &_
					"having max(endDateTime) is not null " &_
				") x "
				
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
		"where startDateTime is not null " &_
		"order by startDateTime "
'			"and callTypeID = 1 " &_
	
dbug("dtDaysSinceLast...")
dtDaysSinceLast = jsonDataTable(SQL)


SQL = "select " &_
			"cct.shortName, " &_
			"datediff(day,max(cc.endDateTime),getDate()) as [Days], " &_
			"cct.idealFrequencyDays as [Goal] " &_
		"from customerCallTypes cct " &_
		"left join customerCalls cc on (cc.callTypeID = cct.id) " &_
		"where cct.idealFrequencyDays is not null " &_
		"and cc.customerID = " & customerID & " " &_
		"group by cct.shortName, cct.idealFrequencyDays "
		
dbug("newDaysSinceLast: " & SQL)
newDaysSinceLast = jsonDataTable(SQL)



SQL = "select " &_
			"trim(cast(p.id as char)) as projectID, " &_ 
			"replace(p.name,'&trade;',char(226)+char(132)+char(162)) as name, " &_
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

dbug("dtCustomerProjects...")
dtCustomerProjects = jsonDataTable(SQL)

 
SQL = "select " &_
			"cim.metricID, " &_
			"cim.metricDate, " &_
			"case when metricID in (6) then " &_
				"cim.metricValue * 100 " &_
			"else " &_
				"cim.metricValue " &_
			"end as metricValue " &_
		"from customerInternalMetrics cim " &_
		"join customer_view c on (c.rssdid = cim.rssdid) " &_
		"where c.id = " & customerID & " " &_
		"order by cim.metricDate "
	
dbug("dtCustomerMetrics...")	
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

dbug("dtcustomerManagers...")
dtcustomerManagers = jsonDataTable(SQL)

dbug("systemControls('Number of months shown on Customer Overview charts'): " & systemControls("Number of months shown on Customer Overview charts"))
if systemControls("Number of months shown on Customer Overview charts") = "" then
	monthsOnCharts = 12
else 
	monthsOnCharts = trim(systemControls("Number of months shown on Customer Overview charts"))
end if
dbug("monthsOnCharts: " & monthsOnCharts)

hAxisFormat = "yyQ"



' get taskowner status...
SQL = "select " &_
			"case when ownerName is null then 'Unassigned' else ownerName end as [Owner], " &_
			"sum(workDaysBehind) as [Days Behind], " &_
			"count(*) as [# Tasks] " &_
		"from " &_
			"( " &_
			"select  " &_
				"t.id,  " &_
				"t.name,  " &_
				"t.dueDate,  " &_
				"( " &_
					"select count(*) " &_
					"from dateDimension  " &_
					"where id between t.dueDate and getDate() " &_
					"and weekdayInd = 1  " &_
					"and usaHolidayInd = 0 " &_
				") as workDaysBehind, " &_
				"concat(c.firstName, ' ', c.lastName) as ownerName,  " &_
				"p.name as projectName " &_
			"from tasks t  " &_
			"left join customerContacts c on (c.id = t.ownerID) " &_
			"left join projects p on (p.id = t.projectID and (p.deleted = 0 or p.deleted is null)) " &_
			"where (completionDate <= getDate() or completionDate is null) " &_
			"and (t.deleted = 0 or t.deleted is null) " &_
			"and t.customerID = " & customerID & " " &_
			") as x  " &_
		"group by ownerName "

dbug("task status by owner...")
dtTaskOwnerSummary = jsonDataTable(SQL)

%>


<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->
	
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="moment-timezone.js"></script>

	<script type="text/javascript" src="customerView.js"></script>
	<script type="text/javascript" src="customerAnnotations.js"></script>

	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

	<style>
		.cssHeaderCell {
			color: 'crimson';
		}
	</style>
	
	<script type="text/javascript">
		

//  		google.charts.load('current', {'packages':['scatter','timeline','line','gauge','table','bar','controls']});
 		google.charts.load('current', {'packages':['corechart', 'controls']});
 		google.charts.load('current', {'packages':['timeline','gantt','table']});

// 		google.charts.setOnLoadCallback(drawMccCallHistory);
		google.charts.setOnLoadCallback(drawCharts);
		google.charts.setOnLoadCallback(drawNewDaysSinceLast);

		//================================================================================================ 
		function drawNewDaysSinceLast() {
		//================================================================================================ 
			
			var data = new google.visualization.DataTable(<% =newDaysSinceLast %>);

	      var chart = new google.visualization.ColumnChart(document.getElementById('newCallSummary'));
			
			var options = {
				title: 	'Days Since Last Call by Call Type',
				vAxis:		{title: 'Days', minValue: 0},
				hAxis:		{title: 'Call Type'},
				bars:			'horizontal',
//				legend:		{position: 'none'},
				chartArea:	{width: '55%', height:' 60%'},
				height: 		<% =chartHeight %>,
			};
			
			chart.draw(data,options);
			
		}


		function drawCharts() {
			
			var chartMaxDate 				= moment().toDate();
			var chartMinDate 				= moment().subtract(<% =monthsOnCharts %>, 'months').toDate();
			var chartExplorerMinDate 	= moment().subtract(10, 'years').toDate();
			
		
			var options = {
				title: 	'Days Since Last Call by Call Type',
				vAxis:		{title: 'Days', minValue: 0},
				hAxis:		{title: 'Call Type'},
				bars:			'horizontal',
//				legend:		{position: 'none'},
				chartArea:	{width: '65%', height:' 60%'},
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
		         chartArea: {width: '80%', height: '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartExplorerMinDate,
			         	max: chartMaxDate,
			         },
						format: "<% =hAxisFormat %>",
					},
					explorer: {
						axis: 'horizontal',
						keenInBounds: true,
						maxZoomIn: 6,
						zoomDelta: 1.1,
					},
			      vAxis: {
				      viewWindow: {min: 0, max: 100},
					},
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
		         chartArea: {width: '80%', height: '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartExplorerMinDate,
			         	max: chartMaxDate,
			         },
						format: "<% =hAxisFormat %>",
					},
					explorer: {
						axis: 'horizontal',
						keenInBounds: true,
						maxZoomIn: 6,
						zoomDelta: 1.1,
					},
			      vAxis: {
				      viewWindow: {min: 0},
					},
		      },
		   });		
				

		   var chart_cultureSurvey = new google.visualization.ChartWrapper({
		      view: {columns: [1,2]},
		      chartType: 'ScatterChart',
		      containerId: 'cultureSurvey',
				animation: {startup: true, duration: 500, easing: 'out'},
		      options: {
		         title: 'Culture Survey',
		         legend: {position: 'none'},
		         lineWidth: 1,
					pointSize: 2,
		         chartArea: {width: '80%', height: '65%'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartExplorerMinDate,
			         	max: chartMaxDate,
			         },
						format: "<% =hAxisFormat %>",
					},
					explorer: {
						axis: 'horizontal',
						keenInBounds: true,
						maxZoomIn: 6,
						zoomDelta: 1.1,
					},
			      vAxis: {
				      viewWindow: {min: 0, max: 7},
					},
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
			
			
			var tgimChartDiv 				= document.getElementById('tgimUtilitization');
			var csChartDiv 				= document.getElementById('crossSales');
			var cultureSurveyChartDiv 	= document.getElementById('cultureSurvey');

			if (customerMetrics.getNumberOfRows() > 0) {
			
				tgimDataView.setRows(customerMetrics.getFilteredRows([
					{column: 0, value: 6}
				]));
	 			if (tgimDataView.getNumberOfRows() > 0) {
					chart_tgimUtilization.setDataTable(tgimDataView);
					chart_tgimUtilization.draw();
				} else {
					tgimChartDiv.style.lineHeight = 10;
					tgimChartDiv.innerHTML 			= 'No TGIM Data';	
				}
	      
	      
				var csDataView = new google.visualization.DataView(customerMetrics);
				csDataView.setRows(customerMetrics.getFilteredRows([
					{column: 0, value: 1}
				]));
	 			if (csDataView.getNumberOfRows() > 0) {
					chart_csUtilization.setDataTable(csDataView);
					chart_csUtilization.draw();
				} else {
					csChartDiv.style.lineHeight 	= 10;
					csChartDiv.innerHTML 			= 'No Cross Sales Data';	
				}


				var cultureSurveyDataView = new google.visualization.DataView(customerMetrics);
				cultureSurveyDataView.setRows(customerMetrics.getFilteredRows([
					{column: 0, value: 9}
				]));
	 			if (cultureSurveyDataView.getNumberOfRows() > 0) {
					chart_cultureSurvey.setDataTable(cultureSurveyDataView);
					chart_cultureSurvey.draw();
				} else {
					cultureSurveyChartDiv.style.lineHeight = 10;
					cultureSurveyChartDiv.innerHTML 			= 'No Culture Survey Data';	
				}


			} else {

				tgimChartDiv.style.lineHeight 				= 10;
				tgimChartDiv.innerHTML 							= 'No TGIM Data';	
				csChartDiv.style.lineHeight 					= 10;
				csChartDiv.innerHTML 							= 'No Cross Sales Data';	
				cultureSurveyChartDiv.style.lineHeight 	= 10;
				cultureSurveyChartDiv.innerHTML 				= 'No Culture Survey Data';	
				
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
		         chartArea: {'width': '65%', 'height': '65%'},
		         vAxis: {title: 'Days'},
		         hAxis: {
		         	slantedText: true, 
		         	viewWindow: {
			         	min: chartMinDate,
			         	max: chartMaxDate,
			         },
						format: "<% =hAxisFormat %>",
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
		
			const rowHeight = 25;
			const chartExtra = 35;
			const chartWidth = 950;

			var chartRowCount = customerProjects.getNumberOfRows();
			var chartHeight = chartRowCount * rowHeight + chartExtra; 

			if (chartHeight < 180) {
				chartHeight = 180;			
			}

		   
			projectsChartDiv = document.getElementById('chart_projectGantt');
		   var projectsGanttChart = new google.visualization.Gantt(projectsChartDiv);

			var cssClassNames = {
				'headerCell': 'cssHeaderCell',
// 				'headerRow': 'cssHeaderRow',
// 				'tableRow': 'cssTableRow',
/* 				'tableCell': 'cssTableCell', */
// 				'rowNumberCell': 'cssRowNumberCell'
//				'oddTableRow': 'cssOddTableRow',
//				'selectedTableRow': 'cssSelectedTableRow',
//				'hoverTableRow': 'cssHoverTableRow',
			};
			   
			var ganttOptions = {
				height: chartHeight,
				gantt: {
					barHeight: 8,
					labelMaxWidth: 550,
				},
				cssClassNames: cssClassNames,
			}


 			
 			
 			var taskOwnerSummary 	= new google.visualization.DataTable(<% =dtTaskOwnerSummary %>);
			taskOwnerSummaryDiv = document.getElementById('taskOwnerSummary');
			var taskOwnerSummaryTable = new google.visualization.Table(taskOwnerSummaryDiv);
			var taskOwnerTableOptions = {
				width: chartWidth,
// 				height: chartHeight,
			}
			
			if (taskOwnerSummary.getNumberOfRows() > 0) {
				taskOwnerSummaryTable.draw(taskOwnerSummary, taskOwnerTableOptions);
			} else {
				taskOwnerSummaryDiv.style.lineHeight = 10;
				taskOwnerSummaryDiv.innerHTML = "No Task Owner Summary Data";
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



	 			var hfyView = new google.visualization.DataView(callHistory);
	 			hfyView.setRows(callHistory.getFilteredRows([
		 			{column: 0, value: 'HFY'}
	 			]));
	 			
			});
			
			
		   var callDashboard = new google.visualization.Dashboard(document.getElementById('customerDashboard'));

			if (callHistory.getNumberOfRows() > 0) {
			   callDashboard.bind(callTypePicker, completeCallHistory);
				callDashboard.draw(callHistory);
			}

		}
				
	</script>		 


</head>

<body>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
		
		<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

    </div>
    
    
<!-- #include file="includes/customerTabs.asp" -->


  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>
		
	
		<div id="customerDashboard" class="page-content">
			<!-- Your content goes here -->
	
			
			<!-- start grid -->
			<div class="mdl-grid">
				
				<div class="mdl-layout-spacer"></div>
	
				<!-- Call History for each call type -->
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center" style="display: none;">
					<div id="completeCallHistory" style="display: none"></div>
					<div id="callTypePicker" style="display: none"></div>
					<div id="chart_mccCallHistory"></div>	   	
				</div>
				
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<div id="jsonCalls" style="display: none;"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Call Data Found</div>	   	
					<div id="newCallSummary"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Call Data Found</div>	   	
				</div>
	
				<div class="mdl-layout-spacer"></div>
	
			</div>					
			<!-- end grid -->
				
						
			<!-- start grid -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
						
				<!-- TGIM Utilization -->
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<div id="tgimUtilitization"></div>	   	
				</div>
				
				<!-- Cross Sales -->
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<div id="crossSales"></div>	   	
				</div>
								
				<div class="mdl-layout-spacer"></div>		
				
			</div>
			<!-- end grid -->
			

			<!-- start grid -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
						
				<!-- Culture Survey -->
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<div id="cultureSurvey"></div>	   	
				</div>
				
				<!-- Task Owner Summary -->
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<div style="text-align: left; margin-left: 15px;"><b>Task Owner Summary</b></div>	   	
					<div id="taskOwnerSummary">Task Owner Summary</div>	   	
				</div>
				
				<div class="mdl-layout-spacer"></div>		
				
			</div>
			<!-- end grid -->
			

			<!-- start grid -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				
					<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" align="center"><br>
					<div style="width: 100%"><h10><b>Projects</b></h10></div>
					<div id="chart_projectGantt"></div>	   	
				</div>
	
				<div class="mdl-layout-spacer"></div>
			</div>
			<!-- end grid -->
			
		</div>
		

	</main>
	
	<!-- #include file="includes/pageFooter.asp" -->
	
</div>



<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>