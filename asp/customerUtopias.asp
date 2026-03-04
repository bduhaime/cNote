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
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(37)

dbug(" ")
userLog("customer attributes")
templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")


customerID = request.querystring("id")

if systemControls("Number of months shown on Customer Overview charts") = "" then
	monthsOnCharts = 12
else 
	monthsOnCharts = trim(systemControls("Number of months shown on Customer Overview charts"))
end if
dbug("monthsOnCharts: " & monthsOnCharts)

hAxisFormat = "yyQ"


'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

dbug("before top-logic")

if len(request.querystring("id")) > 0 then

	dbug("'id' value present in querystring")
		
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
else 
end if

SQL = "select " &_
			"ca.id, " &_
			"a.name as attributeType, " &_
			"a.description as attributeDescription, " &_
			"ca.attainByDate, ca.narrative, " &_
			"ca.addedBy, " &_
			"m.id as metricID, " &_
			"m.name as metricName, " &_
			"m.ubprSection, " &_
			"ca.attributeValue, " &_
			"u.firstName + ' ' + u.lastName as userName, " &_
			"ca.customName, " &_
			"replace(replace(replace(replace(m.name, ' ', ''), '-', ''), '(', ''), ')', '') as internalMetricName " &_
		"from customerAnnotations ca " &_
		"left join metric m on (m.id = ca.metricID) " &_
		"left join cSuite..users u on (u.id = ca.addedBy) " &_
		"left join attributeTypes a on (a.id = ca.attributeTypeID) " &_
		"where ca.customerID = " & customerID & " " &_
		"and a.id = 2 "

dbug(SQL)
set rsMetric = dataconn.execute(SQL)


'***********************************************************************************
function getDataTable(metricID, customerID)
'***********************************************************************************

	dbug("getDataTable: metricID=" & metricID & ", customerID=" & customerID)

	SQL = "select m.metricDate, m.metricValue " &_
			"from customer_view c " &_
			"join customerInternalMetrics m on (m.rssdid = c.rssdid) " &_
			"where c.id = " & customerID & " " &_
			"and m.metricID = " & metricID & " "	
			
	getDataTable = jsonDataTable(SQL)
	
end function 


'***********************************************************************************
function getSeriesColor(metricID)
'***********************************************************************************


	if len(metricID) > 0 then

		SQL = "select seriesColor from metric where id = " & metricID & " " 
		
		dbug(SQL)
		set rsColor = dataconn.execute(SQL)
		
		if not rsColor.eof then 
			if not isNull(rsColor("seriesColor")) then 
				getSeriesColor = rsColor("seriesColor")
			else 
				getSeriesColor = "black"
			end if
		else 
			getSeriesColor = "black"
		end if
		
		rsColor.close 
		set rsColor = nothing 

	else 
		
		getSeriesColor = "black"
		
	end if
	
	
end function 

'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

%>


<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->
	
	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="moment-timezone.js"></script>

	<script type="text/javascript" src="customerView.js"></script>
	<script type="text/javascript" src="customerAnnotations.js"></script>

	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

	<script type="text/javascript">
	
	   google.charts.load("visualization", "1", {packages:["corechart"]});
//       google.charts.load('current', {'packages':['line']});

		<%
		if not rsMetric.eof then 
		
			dbug("NOT rsMetric.eof -- there are customerAnnotation rows for this customer, creating google charts callback functions...")

			rsMetric.movefirst 
			while not rsMetric.eof
				metricID = rsMetric("internalMetricName") & rsMetric("id")
				dbug("creating setOnLoadCallback for metric: " & metricID)
				response.write("google.charts.setOnLoadCallback(" & metricID & ");" & vbCrLf & vbTab & vbTab)
				rsMetric.movenext 
			wend
	
	
			rsMetric.movefirst 
			while not rsMetric.eof 
			
				dbug("metricID: " & metricID)
				dbug("len('metricID'): " & len(metricID))
				dbug("isNull('metricID'): " & isNull("metricID"))
				dbug("rsMetric('metricID'): " & rsMetric("metricID"))
				dbug("len(rsMetric('metricID'): " & len(rsMetric("metricID")))
				dbug("isNull(rsMetric('metricID')): " & isNull(rsMetric("metricID")))
			
				if len(rsMetric("metricID")) > 0 then 
			
					metricID = rsMetric("internalMetricName") & rsMetric("id")
					dbug("creating callback function for metric: " & metricID)
					%>
					//======================================================================================================
					function <% =metricID %>() {
					//======================================================================================================
		
						const rowHeight = 25;
						const chartExtra = 35;
						const chartWidth = 776;
						const chartHeight = 180
						const chartMaxDate = moment().toDate();
						const chartMinDate = moment().subtract(10, 'years').toDate();
						const seriesColor = '<% =getSeriesColor(rsMetric("metricID")) %>';
		
						var chartDiv<% =metricID %> = document.getElementById('<% =metricID %>');
		
						var chart<% =metricID %> = new google.visualization.LineChart(chartDiv<% =metricID %>);
		
						var dataTable<% =metricID %> = new google.visualization.DataTable(<% =getDataTable(rsMetric("metricID"), customerID) %>);
						
						if (dataTable<% =metricID %>.getNumberOfRows() > 0) {
							
							var options = {
								width: chartWidth,
								height: chartHeight,
								animation: {
									duration: 1000,
									startup: true,
									easing: 'out',
								},
								hAxis: {
									minValue: chartMinDate, 
									maxValue: chartMaxDate,
								},
								legend: {
									position: 'none',
								},
								series: {
									0: {
										color: seriesColor,
										lineWidth: 4,
		// 							curveType: 'function',
										pointSize: 6,
									},
								},
								explorer: {
									keepInBounds: true,
									axis: 'horizontal',
		// 							actions: ['dragToZoom', 'rightClickToReset'],
									zoomDelta: 1.1,
									maxZoomIn: .05,
								},
								title: '<% =rsMetric("metricName") %>',
								chartArea: {
									width: '85%',
									height: '65%',
								},
								<% if cInt(rsMetric("metricID")) = 1 then %>
							      vAxis: {minValue: 0},
								<% end if %>
							};
							chart<% =metricID %>.draw(dataTable<% =metricID %>, options);
							
						} else {
			
							chartDiv<% =metricID %>.style.lineHeight = 10;
							chartDiv<% =metricID %>.innerHTML = 'No <% =rsMetric("metricName") %> Data';	
			
						}
		
					}
					
					<%
				end if 

				rsMetric.movenext 


			wend 
			
			rsMetric.movefirst
			
		else 
			
			dbug("rsMetric.eof -- there are NO customerAnnotation rows for this customer")
			
		end if
		%>

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

	<div class="page-content">

		<%
		if not rsMetric.eof then 
			
			dbug("NOT rsMetric.eof, creating MDL grid...")
		
			while not rsMetric.eof 
				metricID = rsMetric("internalMetricName") & rsMetric("id")
				dbug("creating MDL cells for metric: " & metricID)
				
				if not isNull(rsMetric("attainByDate")) then 
					attainByDate = formatDateTime(rsMetric("attainByDate"),2)
				else 
					attainByDate = ""
				end if
				%>
				<div class="mdl-grid">
		
					<div class="mdl-layout-spacer"></div>
					<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="left">
						<table>
							<tr>
								<td style="vertical-align: top; text-align: right;"><b>Attain By:</b></td>
								<td valign="top"><% =attainByDate %></td>
							</tr>
							<% if len(rsMetric("customName")) > 0 then %>
								<tr>
									<td style="vertical-align: top; text-align: right;"><b>Name:</b>
									<td valign="top">
										<% if not isNull(rsMetric("customName")) then response.write(server.htmlEncode(rsMetric("customName"))) %>
									</td>
								</tr>
							<% end if %>
							<tr>
								<td style="vertical-align: top; text-align: right;"><b>Description:</b>
								<td valign="top">
									<% if not isNull(rsMetric("narrative")) then response.write(server.htmlEncode(rsMetric("narrative"))) %>
								</td>
							</tr>
							<tr>
								<td style="vertical-align: top; text-align: right;"><b>Metric:</b></td>
								<td valign="top"><% =rsMetric("metricName") %></td>
							</tr>
							<tr>
								<td style="vertical-align: top; text-align: right;"><b>UBPR Section:</b></td>
								<td valign="top"><% =rsMetric("ubprSection") %></td>
							</tr>
							<tr>
								<td style="vertical-align: top; text-align: right;"><b>Goal Value:</b></td>
								<td valign="top"><% =rsMetric("attributeValue") %></td>
							</tr>
						</table>
					</div>
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp" align="center">
						<div id="<% =metricID %>" style="vertical-align: middle">
							<% if isNull(rsMetric("metricID")) then response.write("<br>Customer Rated, no data to chart at this time") end if %>
						</div>
					</div>
					<div class="mdl-layout-spacer"></div>
					
				</div><!-- end grid -->
				<%
				rsMetric.movenext 
			wend

		else 
			dbug("rsMetric.eof, no metrics for this customer so displaying signage")
			%>

				<div class="mdl-grid">
					<div class="mdl-layout-spacer"></div>
					<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">No Utopias found for this customer</div>
					<div class="mdl-layout-spacer"></div>
				</div>

			<%
		end if			
		
		rsMetric.close 
		set rsMetric = nothing 
		%>
		
	</div>
		


	</main>
	
</div>

<!-- #include file="includes/pageFooter.asp" -->


<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>