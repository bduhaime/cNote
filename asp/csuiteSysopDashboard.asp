<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(99)


title = session("clientID") & " - cSuite Sysop Dashboard" 
userLog(title)

numberOfDays = systemControls("cSuite SysOp Dashboard Days")
if numberOfDays = "" then 
	numberOfDays = 1
else 
	numberOfDays = numberOfDays - 1
end if

' numberOfDays = 2

SQL = "select " &_
			"datefromparts(year(ua.activityDateTime), month(ua.activityDateTime), day(ua.activityDateTime)) as [Date], " &_
			"timefromparts(datepart(hour, ua.activityDateTime), datepart(minute,ua.activityDateTime), datepart(second,ua.activityDateTime),0,0) as [Time], " &_
			"concat(u.firstName, ' ', u.lastName) as [User Name], " &_
			"ua.activityDescription as [Activity], " &_
			"ua.remoteAddr as [IP], " &_
			"ua.sessionID as [Session ID], " &_
			"ua.scriptName as [URL], " &_
			"d.dayOfWeekNo, " &_
			"datepart(hour, ua.activityDateTime) as hourOfDay, " &_
			"ua.clientID as [Client ID] " &_
		"from ( " &_
			"select 'cSuite' as clientID, * " &_
			"from csuite..userActivity " &_
			"UNION ALL " &_
			"select 'Demo' as clientID, * " &_
			"from demo..userActivity " &_
			"UNION ALL " &_
			"select 'TEG' as clientID, * " &_
			"from emmerich..userActivity " &_
		") as ua " &_
		"right join cSuite..users u on (u.id = ua.userID) " &_
		"left join dateDimension d on (d.id = convert(date, ua.activityDateTime)) " &_
		"where activityDateTime >= dateAdd(day, -" & numberOfDays & ", current_timestamp) " &_
		"order by ua.activityDateTime desc "

dbug(SQL)
masterQuery = jsonDataTable(SQL)

summaryEndDate 	= date()
summaryStartDate 	= dateAdd("yyyy", -1, summaryEndDate)

SQL = "select " &_
			"d.monthNo, " &_
			"d.monthName, " &_
			"d.weekNo, " &_
			"ua.clientID, " &_
			"ua.userID, " &_
			"concat(u.firstName, ' ', u.lastName) as [User Name], " &_
			"count(*) " &_
		"from ( " &_
			"select 'cSuite' as clientID, * from csuite..userActivity " &_
			"UNION ALL " &_
			"select 'Demo' as clientID, * from demo..userActivity " &_
			"UNION ALL " &_
			"select 'TEG' as clientID, * from emmerich..userActivity " &_
		") as ua " &_
		"join dateDimension d on (d.id = convert(date, ua.activityDateTime)) " &_
		"left join cSuite..users u on (u.id = ua.userID) " &_
		"where d.id between '" & summaryStartDate & "' and '" & summaryEndDate & "' " &_
		"group by " &_
			"d.monthNo, " &_
			"d.monthName, " &_
			"d.weekNo, " &_
			"ua.clientID, " &_
			"ua.userID, " &_
			"concat(u.firstName, ' ', u.lastName) "

dbug(SQL)
summaryQuery = jsonDataTable(SQL)


%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	
	<style>
	
	.csuiteFilters .goog-inline-block {
		float: right;
	}
		
	</style>

    <script type="text/javascript">

		google.charts.load('current', {'packages':['corechart', 'controls']});
		google.charts.setOnLoadCallback(drawVisualization);
		
		function drawVisualization() {
			
			const chartHeight = 300;
		
			var chartMaxDate = moment().toDate();
			var chartMinDate = moment().subtract(1, 'years').toDate();
		
		   var data = new google.visualization.DataTable(<% =masterQuery %>);
		
		   var dateFormatter = new google.visualization.DateFormat({pattern: 'MM/dd/yyyy'});
		   dateFormatter.format(data, 0);
		
		   var timeFormatter = new google.visualization.DateFormat({pattern: 'hh:mm:ss'});
		   timeFormatter.format(data, 1);
		   
			// CONTROL WRAPPER: Client Picker....   
			var clientPicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'clientPicker',
		      options: {
		         filterColumnLabel: 'Client ID',
		         ui: {
			         caption: 'Select a client...',
			         sortValues: true,
		            selectedValuesLayout: 'belowStacked',
		            labelSeparator: ':',
		            label: 'Client',
		         }
		      }
		   });
		
		
			// CONTROL WRAPPER: User Picker....   
			var userPicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'userPicker',
		      options: {
		         filterColumnLabel: 'User Name',
		         ui: {
			         caption: 'Select a user...',
			         sortValues: true,
		            selectedValuesLayout: 'belowStacked',
		            labelSeparator: ':',
		            label: 'User',
		         }
		      }
		   });
		
		
			// CONTROL WRAPPER: Activity Type Picker....   
			var activityTypePicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'avtivityType',
		      options: {
		         filterColumnLabel: 'Activity',
		         ui: {
			         caption: 'Select an activity...',
			         sortValues: true,
		            selectedValuesLayout: 'belowStacked',
		            labelSeparator: ':',
		            label: 'Activity',
		         }
		      }
		   });
		   
		   // CONTROL WRAPPER: Date Slider....
		   var dateSlider = new google.visualization.ControlWrapper({
			   controlType: 'DateRangeFilter',
			   containerId: 'dateSlider',
			   options: {
				   filterColumnLabel: 'Date',
				   ui: {
					   format: {pattern: 'MMM d'},
					   label: 'Date Range',
					   labelSeparator: ':',
					   labelStacking: 'horizontal',
					   showRangeValues: true,
				   },
			   },
		   })
		
		
		
			// ROW 1; COL 1
			// CHART WRAPPER: All Data...   
		   var everythingTable = new google.visualization.ChartWrapper({
		      chartType: 'Table',
		      containerId: 'everythingTable',
		      options: {
		         title: 'Everything',
		         height: '200',
		      },
		   });		
		
		
			// ROW 1; COL 2
			// CHART WRAPPER: Activity by Client...   
		   var activityByClientPieChart = new google.visualization.ChartWrapper({
		      chartType: 'PieChart',
		      containerId: 'activityByClient',
		      options: {
		         title: 'Activity By Client',
		         height: '200',
		         is3D: true,
		      },
		   });		
		
		
			// ROW 2; COL 1
			// CHART WRAPPER: Aggregated Activity By Date...   
		   var dateSummaryColumnChart = new google.visualization.ChartWrapper({
		      chartType: 'ColumnChart',
		      containerId: 'aggregateActivityByDate',
		      options: {
		         title: 'Activity By Date',
		         height: '200',
			      legend: {
				      position: 'none',
			      },
			      hAxis: {
				      format: 'MMM d',
				      slantedText: true,
			      },
			      series: {
				      0: {color: 'red'},
			      },
		      },
		   });		
		
		
			// ROW 2; COL 2
			// CHART WRAPPER: Aggregated Activity By User...   
		   var userSummaryColumnChart = new google.visualization.ChartWrapper({
		      chartType: 'ColumnChart',
		      containerId: 'chartActivityByUser',
		      options: {
		         title: 'Activity By User',
		         height: '200',
			      legend: {
				      position: 'none',
			      },
			      hAxis: {
				      slantedText: false,
			      },
			      series: {
				      0: {color: 'purple'},
			      },
		      },
		   });		
		
		
			// ROW 3; COL 1
			// CHART WRAPPER: Aggregated Activity By Day Of Week...   
		   var weekdaySummaryColumnChart = new google.visualization.ChartWrapper({
		      chartType: 'ColumnChart',
		      containerId: 'chartActivityByDayOfWeek',
		      options: {
		         title: 'Activity By Day Of Week',
		         height: '200',
			      legend: {
				      position: 'none',
			      },
			      hAxis: {
				      ticks: [{v: 1, f: 'Sun'}, {v: 2, f: 'Mon'}, {v: 3, f: 'Tue'}, {v: 4, f: 'Wed'}, {v: 5, f: 'Thu'}, {v: 6, f: 'Fri'}, {v: 7, f: 'Sat'}],
			      },
			      series: {
				      0: {color: 'blue'},
			      },
		      },
		   });		
		
		
			// ROW 3; COL 2
			// CHART WRAPPER: Aggregated Activity By Time Of Day...   
		   var timeofdaySummaryColumnChart = new google.visualization.ChartWrapper({
		      chartType: 'ColumnChart',
		      containerId: 'chartActivityByTime',
		      options: {
		         title: 'Activity By Time Of Day',
		         height: '200',
			      legend: {
				      position: 'none',
			      },
			      series: {
				      0: {color: 'orange'},
			      },
			      hAxis: {
				      ticks: [{v: 0, f: '12a'}, {v: 4, f: '4a'}, {v: 8, f: '8a'}, {v: 12, f: '12p'}, {v: 16, f: '4p'}, {v: 20, f: '8p'}, {v: 24, f: '12a'}],
			      },
		      },
		   });		
		
		
		
			// SUMMARY CHARTS:
			
			// ROW 4; COL 0 -- this chart is only shown for debuggin purposes.
			// CHART WRAPPER: All Data...   
		   var summaryTable = new google.visualization.ChartWrapper({
		      chartType: 'Table',
		      containerId: 'summaryTable',
		      options: {
		         title: 'Summary',
		         height: '200',
		      },
		   });		
		
		
			
			
			// ROW 4, COL 1
			// CHART WRAPPER: Activity By Month of Year
			var activityByMonthColumnChart = new google.visualization.ChartWrapper({
				chartType: 'ColumnChart',
				containerID: 'activityByMonth',
				options: {
					title: 'Activity By Month',
					height: '200',
					legend: {
						position: 'none',
					},
					series: {
						0: {color: 'orange'},
					},
				},
			});

			// ROW 4, COL 2
			// CHART WRAPPER: Activity By Week of Year
			var activityByMonthColumnChart = new google.visualization.ChartWrapper({
				chartType: 'ColumnChart',
				containerID: 'activityByWeek',
				options: {
					title: 'Activity By Week',
					height: '200',
					legend: {
						position: 'none',
					},
					series: {
						0: {color: 'orange'},
					},
				},
			});





		   
		
		
		
			google.visualization.events.addListener(everythingTable, 'ready', function() {   	
		
		
				aggregateActivityByClient = new google.visualization.data.group(
		   	   everythingTable.getDataTable(),
		   	   [9],
		   	   [
		   		   {column: 0, 'aggregation': google.visualization.data.count, type: 'number', label: 'Count'},
		      	]
				);
		   	activityByClientPieChart.setDataTable(aggregateActivityByClient);
		   	activityByClientPieChart.draw();
				
				
		   	aggregateActivityByDate = new google.visualization.data.group(
		   	   everythingTable.getDataTable(),
		   	   [0],
		   	   [
		   		   {column: 4, 'aggregation': google.visualization.data.count, type: 'number', label: 'Count'},
		      	]
		   	);
		   	dateSummaryColumnChart.setDataTable(aggregateActivityByDate);
		   	dateSummaryColumnChart.draw();
		   	
		
				aggregateActivityByUser = new google.visualization.data.group(
		   	   everythingTable.getDataTable(),
		   	   [2],
		   	   [
		   		   {column: 4, 'aggregation': google.visualization.data.count, type: 'number', label: 'Count'},
		      	]
		   	);
		   	userSummaryColumnChart.setDataTable(aggregateActivityByUser);
		   	userSummaryColumnChart.draw();
		
		
		
		
		
		
		   	aggregateActivityByWeekday = new google.visualization.data.group(
		   	   everythingTable.getDataTable(),
		   	   [7],
		   	   [
		   		   {column: 4, 'aggregation': google.visualization.data.count, type: 'number', label: 'Count'},
		      	]
		   	);
		   	weekdaySummaryColumnChart.setDataTable(aggregateActivityByWeekday);
		   	weekdaySummaryColumnChart.draw();
		   	
		
		   	aggregateActivityByTime = new google.visualization.data.group(
		   	   everythingTable.getDataTable(),
		   	   [8],
		   	   [
		   		   {column: 4, 'aggregation': google.visualization.data.count, type: 'number', label: 'Count'},
		      	]
		   	);
		   	timeofdaySummaryColumnChart.setDataTable(aggregateActivityByTime);
		   	timeofdaySummaryColumnChart.draw();
		   	
		
		   });
		
		
		   var dashboard1 = new google.visualization.Dashboard(document.getElementById('dashboard1'));
		   dashboard1.bind([clientPicker, userPicker, activityTypePicker, dateSlider], everythingTable);
		   dashboard1.draw(data);	
		
		
	  }
	 
  </script>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	
	<div id="dashboard1" class="page-content">
	<!-- Your content goes here -->

	<div class="mdl-grid"><!-- new row of grids... -->

		<div class="mdl-layout-spacer"></div>

		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="padding: 20px">
			<h5>Filters</h5>
			<div id="clientPicker"></div><br>
			<div id="userPicker"></div><br>
			<div id="avtivityType"></div><br>
			<hr>
			Last User Activity:&nbsp;
			<%
			SQL = "select max(activityDateTime) lastActivity from userActivity " 
			exclusionList = systemControls("Users excluded from last activity")
			if len(exclusionList) > 0 then 
				SQL = SQL & "where userID not in (" & exclusionList & ") " 
			end if
			
			dbug(sql)
			set rsLast = dataconn.execute(SQL)
			if not rsLast.eof then 
				lastActivity = rsLast("lastActivity")
			else 
				lastActivity = null 
			end if
			rsLast.close 
			set rsLast = nothing 
			
			if not isNull(lastActivity) then 
				duration = dateDiff("s", lastActivity, now())
				if duration > 60 then
					minutes = duration / 60
					if minutes > 60 then 
						hours = minutes / 60 
						if hours > 24 then 
							days = hours / 24 
							if days > 7 then 
								weeks = days / 7 
								months = dateDiff("m",lastActivity, now())
								if months > 1 then 
									if months > 12 then 
										years = months / 12
										msg = "About " & formatNumber(years,1) & " year(s) ago" 
									else 
										msg = "Over " & months & " month(s) ago"
									end if
								else 
									msg = "About " & formatNumber(weeks,1) & " weeks ago"
								end if 
							else 	
								msg = "About " & formatNumber(days,1) & " days ago"
							end if
						else 
							msg = "About " & formatNumber(hours,1) & " hours ago"
						end if
					else 
						msg = "About " & int(minutes) & " minutes ago"
					end if 
				else 
					msg = duration & " seconds ago"
				end if
			else 
				msg = "No previous activity"
			end if
			response.write(msg)
			%>

<!--
			<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">
				<div id="lastActivityByUser">lastActivityByUser</div>
			</div>
-->

		</div><!-- controls for all charts -->
   		
		<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp">

			<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">
				
				<h5 style="padding-left: 16px; display: inline-block">Detail Charts</h5>
				<div id="dateSlider" style="display: inline-block; padding-left: 16px;"></div>
				
				<div class="mdl-grid"><!-- row 1, detail data -->
	
					<div class="mdl-layout-spacer"></div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="everythingTable"><!-- everythingTable --></div>
					</div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="activityByClient">activityByClient</div>
					</div>
	
					<div class="mdl-layout-spacer"></div>
	
				</div><!-- row 1, detail data -->
	
				<div class="mdl-grid"><!-- row 2, detail data -->
	
					<div class="mdl-layout-spacer"></div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="aggregateActivityByDate">aggregateActivityByDate</div>
					</div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="chartActivityByUser">chartActivityByUser</div>
					</div>
	
					<div class="mdl-layout-spacer"></div>
	
				</div><!-- row 2, detail data -->
	
				<div class="mdl-grid"><!-- row 3, detail data -->
	
					<div class="mdl-layout-spacer"></div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="chartActivityByDayOfWeek">chartActivityByDayOfWeek</div>
					</div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="chartActivityByTime">chartActivityByTime</div>
					</div>
	
					<div class="mdl-layout-spacer"></div>
	
				</div><!-- row 3, detail data -->
	
			</div>
			
			<br>

			<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">

				<h5 style="padding-left: 16px; display: inline-block">Summary Charts</h5>

				<div class="mdl-grid"><!-- row 4, SUMMARY data -->
	
					<div class="mdl-layout-spacer"></div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="summaryTable">summaryTable</div>
					</div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="activityByMonth">activityByMonth</div>
					</div>
	
					<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
						<div id="activityByWeek">activityByWeek</div>
					</div>
	
					<div class="mdl-layout-spacer"></div>
	
				</div><!-- row 4, SUMMARY data -->

			</div>
			
		<div class="mdl-layout-spacer"></div>
	    
	</div><!-- end mdl-grid -->


	</div><!-- end of the dashboard -->
	
	
	
	<div class="mdl-grid"><!-- new row of grids... -->

		<div class="mdl-layout-spacer"></div>

		<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp">
			<div style="font-size: 12; font-weight: bold; margin-left: 35px; margin-top: 10px; margin-bottom: 10px;">Internal Users that Are Customer Contacts</div>
			<table class="mdl-data-table mdl-js-data-table" style="margin-left: auto; margin-right: auto; margin-bottom: 10px;">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Username</th>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Client</th>
						<th class="mdl-data-table__cell--non-numeric">Customer</th>
					</tr>
				</thead>
				<tbody>
					<%
					SQL = "select databaseName from csuite..clients where id <> 1 "
					set rsClients = dataconn.execute(SQL) 
					while not rsClients.eof 
						SQL = "select " &_
									"iu.id as userID, " &_
									"iu.username, " &_
									"iu.fullName, " &_
									"iu.client, " &_
									"c.id as customerID, " &_
									"c.name as customerName " &_
								"from ( " &_
									"select " &_
										"u.id, " &_
										"u.username, " &_
										"concat(u.firstName, ' ', u.lastName) as fullName, " &_
										"'" & rsClients("databaseName") & "' as client " &_
									"from " & rsClients("databaseName") & "..userCustomers uc " &_
									"join users u on (u.id = uc.userID) " &_
									"where uc.customerID = 1 " &_
								") as iu " &_
								"join " & rsClients("databaseName") & "..customerContacts cc on (cc.email = iu.username) " &_
								"join " & rsClients("databaseName") & "..customer c on (c.id = cc.customerID) "
						
						set rs = dataconn.execute(SQL) 
						while not rs.eof 
							%>				
							<tr>
								<td class="mdl-data-table__cell--non-numeric" data-id="<% =rs("userID") %>"><% =rs("username") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("fullName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("client") %></td>
								<td class="mdl-data-table__cell--non-numeric"data-id="<% =customerID %>"><% =rs("customerName") %></td>
							</tr>
							<%
							rs.movenext 
						wend 
						rs.close 
						set rs = nothing 
						
						rsClients.movenext 
					wend 
					rsClients.close 
					set rsClients = nothing 
					%>
				</tbody>
			</table>
								
				
		</div><!-- end of MDL cell -->

		<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp">
			<div style="font-size: 12; font-weight: bold; margin-left: 35px; margin-top: 10px; margin-bottom: 10px;">Internal Users that Are External Users</div>
			<table class="mdl-data-table mdl-js-data-table" style="margin-left: auto; margin-right: auto; margin-bottom: 10px;">
				<thead>
					<tr>
						<th class="mdl-data-table__cell--non-numeric">Username</th>
						<th class="mdl-data-table__cell--non-numeric">Name</th>
						<th class="mdl-data-table__cell--non-numeric">Client</th>
						<th class="mdl-data-table__cell--non-numeric">Customer</th>
					</tr>
				</thead>
				<tbody>
					<%
					SQL = "select databaseName from csuite..clients where id <> 1 "
					set rsClients = dataconn.execute(SQL) 
					while not rsClients.eof 
						SQL = "select " &_
									"z.userID, " &_
									"u.username, " &_
									"concat(u.firstName, ' ', u.lastName) as fullName, " &_
									"'" & rsClients("databaseName") & "' as client, " &_
									"c.id as customerID, " &_
									"c.name as customerName " &_
								"from ( " &_
									"select i.userID, x.customerID " &_
									"from ( " &_
										"select * " &_
										"from " & rsClients("databaseName") & "..userCustomers " &_
										"where customerID = 1 " &_
									") as i " &_
									"join ( " &_
										"select * " &_
										"from " & rsClients("databaseName") & "..userCustomers " &_
										"where customerID <> 1 " &_
									") as x on (x.userID = i.userID) " &_
								") z " &_
								"join users u on (u.id = z.userID) " &_
								"join " & rsClients("databaseName") & "..customer c on (c.id = z.customerID) "
						
						set rs = dataconn.execute(SQL) 
						while not rs.eof 
							%>				
							<tr>
								<td class="mdl-data-table__cell--non-numeric" data-id="<% =rs("userID") %>"><% =rs("username") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("fullName") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("client") %></td>
								<td class="mdl-data-table__cell--non-numeric"data-id="<% =customerID %>"><% =rs("customerName") %></td>
							</tr>
							<%
							rs.movenext 
						wend 
						rs.close 
						set rs = nothing 
						
						rsClients.movenext 
					wend 
					rsClients.close 
					set rsClients = nothing 
					%>
				</tbody>
			</table>
			
		</div>
		
		
		<div class="mdl-layout-spacer"></div>
	
	</div><!-- end of MDL grid for internal user reports -->
	
	        
</main>
<!-- #include file="includes/pageFooter.asp" -->
</div>


</body>
</html>