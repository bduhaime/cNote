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
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(48)

dbug(" ")
userLog("customer overview")

customerID = request.querystring("id")
SQL = "select lsvtCustomerName from customer where id = " & customerID & " "
set rsLSVT = dataconn.execute(SQL)
if not rsLSVT.eof then 
	lsvtCustomerName = rsLSVT("lsvtCustomerName") 
else 
	lsvtCustomerName = ""
end if 
rsLSVT.close 
set rsLSVT = nothing 

%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")


chartEndDate = date()
chartStartDate = dateAdd("yyyy",-2,chartEndDate)
dbug("chartStartDate: " & chartStartDate & ", chartEndDate: " & chartEndDate)


'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

dbug("before top-logic")

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

chartHeight = 200

dbug("systemControls('Number of months shown on Customer Overview charts'): " & systemControls("Number of months shown on Customer Overview charts"))
if systemControls("Number of months shown on Customer Overview charts") = "" then
	monthsOnCharts = 12
else 
	monthsOnCharts = trim(systemControls("Number of months shown on Customer Overview charts"))
end if
dbug("monthsOnCharts: " & monthsOnCharts)

hAxisFormat = "yyyy"


'***************************************************************************************************

tempDate = dateAdd("yyyy", -1, date())
dbug("tempDate: " & tempDate)
startYear = year(tempDate)
startMonth = month(tempDate)
startDay = day(tempDate)
startDate = dateSerial(startYear, startMonth, 1)

endDate = date()
' endDate = dateSerial(2018, 11, 4)	' for testing only

%>


<html>

<head>

	<div id="mdl-spinner" class="mdl-spinner mdl-js-spinner is-active" style="position: fixed; top: 50%; left: 50%;"></div>
		
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	Google Visualization Loader -->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	
	<!-- 	Day.js -->
	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>

			
	<script type="text/javascript">
			
		const lsvtCustomerName 	= '<% =lsvtCustomerName %>';
		const customerID			= '<% =customerID %>';
		
		google.charts.load('current', {'packages':['corechart','gantt']});
		
		google.charts.setOnLoadCallback(drawCharts);				
		
		//================================================================================================ 
		function drawCharts() {
		//================================================================================================ 

			$( function() {
	
				$( document ).tooltip();


				$( '.context-menu' ).dialog({
					autoOpen: false,
					modal: true,
					height: 'auto',
					resizable: false,
					width: 300,
				});

			
	// 			alert('start of drawCharts');
	
				var chartMaxDate 				= dayjs().toDate();
				var chartMinDate 				= dayjs().add( -<% =monthsOnCharts %>, 'months').toDate();
				var chartExplorerMinDate 	= dayjs().add( -10, 'years' ).toDate();
				const colorPrimary 		= '#512DA8'  	// purple-ish
				const colorSecondary 	= '#F52C2C'		// red-ish
				const colorTertiary		= '#20B256'		// green-ish
				
			
				var options = {
					title: 	'Days Since Last Call by Call Type',
					vAxis:		{title: 'Days', minValue: 0},
					hAxis:		{title: 'Call Type'},
					bars:			'horizontal',
	//				legend:		{position: 'none'},
					chartArea:	{width: '55%', height:' 60%'},
					height: 		<% =chartHeight %>,
				};
				
				tgim_explorer = {
					axis: 'horizontal',
					keenInBounds: true,
					maxZoomIn: 7,
					zoomDelta: 1.1,
				}
				
				tgim_hAxis = {
					format: "<% =hAxisFormat %>",
					minorGridlines: {count: 0},
	         	viewWindow: {
		         	min: chartMinDate,
		         	max: chartMaxDate,
		         },
				}
	
	         tgim_lineWidth = 3
				tgim_pointSize = 3,
				
				tgim_vAxis = {
			      viewWindow: {min: 0, max:100},
			   }
			   
			   tgim_legend = {
				   position: 'none'
				}


				// get customer demographic info....
				$.ajax({
					url: `${apiServer}/api/customers/${customerID}`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				})
				.done( result => {
					
					$( '#instName' ).html( result.instName );
					$( '#instAddress' ).html( `${result.instAddress}<br>${result.instCity}<br>${result.instState}` );
					$( '#defaultTimeZone' ).html( `${result.defaultTimeZone}` );
					$( '#instCert' ).html( result.instCert );
					$( '#instRssdId' ).html( result.instRssdId );
					$( '#validDomains' ).html( result.validDomains );
					
					
				})
				.fail( error => {
					log.error( 'unexpected error while switching clients...' );
					log.error( err )
				})

							
				
				// get customer Last FFIEC Update...
				$.ajax({
					url: `${apiServer}/api/customers/latestFinancials/${customerID}`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				})
				.done( result => {
					
					$( '#lastUpdate' ).html( result.maxDate );
					$( '#lastUpdateSource' ).html( result.source );
					$( '#totalAssets' ).html( result.totalAssets );
					$( '#totalROA' ).html( result.totalROA );
					$( '#totalNIM' ).html( result.totalNIM );
										
				})
				.fail( error => {
					log.error( 'unexpected error while getting Last FFIEC Update...' );
					log.error( err )
				})

							
				

				// get "ASSETS" by day quarter
				$.ajax({
					beforeSend: function() {
						$( '#fdicAssets_progressbar' ).progressbar({ value: false });
					},
					url: `${apiServer}/api/metrics/chartCustomerFDICMetric`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID, metricID: 105 },
					success: function( data ) {
						let chartAssets = new google.visualization.ScatterChart(document.getElementById( 'fdicAssets' ));
						let dataAssets = new google.visualization.DataTable( data );
						chartAssets.draw(dataAssets, {
							explorer: 	tgim_explorer,
				         hAxis: 		tgim_hAxis,
				         vAxes:		{ 0: { title: "$Thousand" } },
							legend: 		{ position: 'none' },
							series: 		{ 0: { color: colorTertiary } },
				         lineWidth: 	tgim_lineWidth,
							pointSize: 	tgim_pointSize,
							title: 		'Total Assets ($Thousand)',
						});
						$( '#fdicAssets_progressbar' ).progressbar('destroy');
					},
					error: function( err ) {
						$( '#fdicAssets_progressbar' ).progressbar('destroy');
						$(' #fdicAssets' ).text( err.status + ' (' + err.responseText + ') ' );
					}
				});
				
				
	
				// get "ROA" by day quarter
				$.ajax({

					beforeSend: function() {
						$( '#fdicROA_progressbar' ).progressbar({ value: false });
					},
					url: `${apiServer}/api/metrics/chartCustomerFDICMetric`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID, metricID: 98, usesPGT: true }

				}).then( data => {
					console.log( data );
					$( '#fdicROA_progressbar' ).progressbar('destroy');
					let chartAssets = new google.visualization.ScatterChart(document.getElementById( 'fdicROA' ));
					let dataAssets = new google.visualization.DataTable( data );
					chartAssets.draw(dataAssets, {
						explorer: 	tgim_explorer,
			         hAxis: 		tgim_hAxis,
			         vAxes:		{ 
							0: { title: "Bank & PG" },
							1: { title: 'PG Percentile', maxValue: 100, textStyle: {color: colorPrimary}, titleTextStyle: {color: colorPrimary } }
						},
						legend: 		{ position: 'top' },
						series: 		{ 
							0: { type: "line", color: colorTertiary, targetAxisIndex: 0 },
							1: { type: 'line', color: colorSecondary, targetAxisIndex: 0 },
							2: { type: 'bars', dataOpacity: .5, color: colorPrimary, targetAxisIndex: 1 }
						},
			         lineWidth: 	tgim_lineWidth,
						pointSize: 	tgim_pointSize,
						title: 		'ROA - Net Income as a percent of Average Assets',
						tooltip: { isHtml: true }
					});

				}).fail( err => {
					$( '#fdicROA_progressbar' ).progressbar('destroy');
					$(' #fdicROA' ).text( err.status + ' (' + err.responseText + ') ' );
				});
				
				
	
				// get "NIM" by day quarter
				$.ajax({
					beforeSend: function() {
						$( '#fdicNIM_progressbar' ).progressbar({ value: false });
					},
					url: `${apiServer}/api/metrics/chartCustomerFDICMetric`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID, metricID: 85, usesPGT: true },
					success: function( data ) {
						let chartAssets = new google.visualization.ScatterChart(document.getElementById( 'fdicNIM' ));
						let dataAssets = new google.visualization.DataTable( data );
						chartAssets.draw(dataAssets, {
							explorer: 	tgim_explorer,
				         hAxis: 		tgim_hAxis,
				         vAxes:		{ 
								0: { title: "Bank & PG" },
								1: { title: 'PG Percentile', maxValue: 100, textStyle: {color: colorPrimary}, titleTextStyle: {color: colorPrimary } }
							},
							legend: 		{ position: 'top' },
							series: 		{ 
								0: { type: "line", color: colorTertiary, targetAxisIndex: 0 },
								1: { type: 'line', color: colorSecondary, targetAxisIndex: 0 },
								2: { type: 'bars', dataOpacity: .5, color: colorPrimary, targetAxisIndex: 1 }
							},
				         lineWidth: 	tgim_lineWidth,
							pointSize: 	tgim_pointSize,
							title: 		'NIM - Net Interest Income (TE) as a percent of Average Earning Assets',
							tooltip: { isHtml: true }
						});
						$( '#fdicNIM_progressbar' ).progressbar('destroy');
					},
					error: function( err ) {
						$( '#fdicNIM_progressbar' ).progressbar('destroy');
						$(' #fdicNIM' ).text( err.status + ' (' + err.responseText + ') ' );
					}
				});
				
				
	
				// get SIGNIN Utilization By Day...
				$.ajax({
					beforeSend: function() {
						$( '#tgim_signinsByDay_progressbar' ).progressbar({ value: false });
					},
					url: `${apiServer}/api/tgimu/utilization/signinsByDate`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID },
					success: function( data ) {
						let chart_A = new google.visualization.ScatterChart(document.getElementById( 'tgim_signinsByDay' ));
						let data_A = new google.visualization.DataTable( data );
						chart_A.draw(data_A, {
							explorer: 	tgim_explorer,
				         hAxis: 		tgim_hAxis,
							legend: 		tgim_legend,
				         lineWidth: 	tgim_lineWidth,
							pointSize: 	tgim_pointSize,
							title: 		'TGIM-U Signin Percentage By Month',
					      vAxis: 		tgim_vAxis
						});
						$( '#tgim_signinsByDay_progressbar' ).progressbar('destroy');
					},
					error: function( err ) {
						$( '#tgim_signinsByDay_progressbar' ).progressbar('destroy');
						$(' #tgim_signinsByDay' ).text( err.status + ' (' + err.responseText + ') ' );
					}
				});
	
	
				// get Training Attempt Utilization By Day
				$.ajax({
					beforeSend: function() {
						$( '#tgim_trainingsByDay_progressbar' ).progressbar({ value: false });
					},
					dataType: "json",
					url: `${apiServer}/api/tgimu/utilization/attemptedTrainingsByDate`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID },
					success: function( data ) {
						let chart_B = new google.visualization.ScatterChart(document.getElementById( 'tgim_trainingsByDay' ));
						let data_B = new google.visualization.DataTable( data );
						chart_B.draw(data_B, {
							explorer: 	tgim_explorer,
				         hAxis: 		tgim_hAxis,
							legend: 		tgim_legend,
				         lineWidth: 	tgim_lineWidth,
							pointSize: 	tgim_pointSize,
							title: 		'TGIM-U Training Attempts Percentage By Month',
					      vAxis: 		tgim_vAxis,
						});
						$( '#tgim_trainingsByDay_progressbar' ).progressbar('destroy');
	
					},
					error: function( err ) {
						$( '#tgim_trainingsByDay_progressbar' ).progressbar('destroy');
						$(' #tgim_trainingsByDay' ).text( err.status + ' (' + err.responseText + ') ' );
					}
				});
	
	
				// get Chapter Status Activity By Day
				$.ajax({
					beforeSend: function() {
						$( '#tgim_chapterStatusByDate_progressbar' ).progressbar({ value: false });
					},
					dataType: "json",
					url: `${apiServer}/api/tgimu/utilization/chapterStatusByDate`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID },
					success: function( data ) {
						let chart_C = new google.visualization.ScatterChart(document.getElementById( 'tgim_chapterStatusByDate' ));
						let data_C = new google.visualization.DataTable( data );
						chart_C.draw(data_C, {
							explorer: 	tgim_explorer,
				         hAxis: 		tgim_hAxis,
							legend: 		{ position: 'top' },
				         lineWidth: 	tgim_lineWidth,
							pointSize: 	tgim_pointSize,
							title: 		'TGIM-U Training Activity By Month',
						});
						$( '#tgim_chapterStatusByDate_progressbar' ).progressbar('destroy');
					},
					error: function( err ) {
						$( '#tgim_chapterStatusByDate_progressbar' ).progressbar('destroy');
						$(' #tgim_chapterStatusByDate' ).text( err.status + ' (' + err.responseText + ') ' );
					}
				});


	
				// task owner summary DataTable
				var taskOwnerSummary = $('#taskOwnerSummary').DataTable({
					ajax: {
						url: `${apiServer}/api/tasks/ownerSummary`,
						data: {
							customerID: customerID
						},
						headers: {
							'Authorization': 'Bearer ' + sessionJWT
						},
					},
					columnDefs: [
						{targets: 'name', 			data: 'name', 				className: 'name dt-body-left dt-head-left' },
						{targets: 'tasksAssigned', data: 'tasksAssigned', 	className: 'tasksAssigned dt-body-center dt-head-center' },
						{targets: 'daysAssigned', 	data: 'daysAssigned', 	className: 'daysAssigned dt-body-center dt-head-center' },
						{targets: 'daysAtRisk', 	data: 'daysAtRisk', 		className: 'daysAtRisk dt-body-center dt-head-center' },
						{targets: 'daysBehind', 	data: 'daysBehind', 		className: 'daysBehind dt-body-center dt-head-center' }
					]
	
				});
	
	
				// project summary DataTable
				var projectSummary = $('#projectSummary')
					.on( 'click', 'tbody > tr', function( event ) {
						if ( $( this ).find('td.name').text().trim() === 'None' ) {
							window.location.href = `customerTasks.asp?id=${customerID}&sort=orphan`;
						} else {
							window.location.href = 'taskList.asp?customerID='+customerID+'&projectID='+this.id;
						}
					})
					.DataTable({
						ajax: {
							url: `${apiServer}/api/tasks/projectSummary`,
							data: {
								customerID: customerID
							},
							headers: {
								'Authorization': 'Bearer ' + sessionJWT
							},
						},
						columnDefs: [
							{targets: 'name', 			data: 'name', 				className: 'name dt-body-left dt-head-left' },
							{targets: 'tasksAssigned', data: 'tasksAssigned', 	className: 'tasksAssigned dt-body-center dt-head-center' },
							{targets: 'daysAssigned', 	data: 'daysAssigned', 	className: 'daysAssigned dt-body-center dt-head-center' },
							{targets: 'daysAtRisk', 	data: 'daysAtRisk', 		className: 'daysAtRisk dt-body-center dt-head-center' },
							{targets: 'daysBehind', 	data: 'daysBehind', 		className: 'daysBehind dt-body-center dt-head-center' }
						]
		
					});

			});
			
		}
		
		window.onload = function() {
			document.getElementById('mdl-spinner').classList.remove('is-active');	
		}
				
	</script>		 

	<style>
		/* precent Google Chart Tooltips from flashing... */
		svg > g:last-child > g:last-child { pointer-events: none }
		div.google-visualization-tooltip { pointer-events: none }

		#tgim_progressbar .ui-progressbar-value {
			background-color: #ccc;
		}
	
		#projectSummary.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
	</style>
	


</head>

<body>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header" style="overflow: visible;">
  
	<header class="mdl-layout__header" >
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

			<!-- 	Customer Info		 -->
			<div class="mdl-grid">

				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<table>
						<tr>
							<th style="text-align: left;">FDIC Name:</th><td id="instName" colspan="3"></td>
						</tr>
						<tr>
							<th style="text-align: left; vertical-align: top;">Address:</th><td id="instAddress" colspan="3"></td>
						</tr>
						<tr>
							<th style="text-align: left;">Default Time Zone ID:</th><td id="defaultTimeZone" colspan="3"></td>
						</tr>
					</table>
				</div>

				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<table>
						<tr>
							<th style="text-align: left;">Cert:</th><td id="instCert"></td>
						</tr>
						<tr>
							<th style="text-align: left;">RSSD ID:</th><td id="instRssdId"></td>
						</tr>
						<tr>
							<th style="text-align: left;">Domains:</th><td id="validDomains" colspan="3"></td>
						</tr>
					</table>
				</div>


				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
					<table width="70%">
						<tr>
							<th style="text-align: left;">Last FFIEC Update:</th><td id="lastUpdate" style="text-align: right;"></td><td id="lastUpdateSource"></td>
						</tr>
						<tr>
							<th style="text-align: left;">Assets ($000):</th><td id="totalAssets" style="text-align: right;"></td>
						</tr>
						<tr>
							<th style="text-align: left;">ROA:</th><td id="totalROA" style="text-align: right;"></td>
						</tr>
						<tr>
							<th style="text-align: left;">NIM:</th><td id="totalNIM" style="text-align: right;"></td>
						</tr>
					</table>					
				</div>
				
				<div class="mdl-layout-spacer"></div>

			</div>
			
			<!-- cross sales, tgim-U, culture survey -->
			<div class="mdl-grid">

				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="fdicAssets_progressbar"></div>
					<div id="fdicAssets"></div>
				</div>
				
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="fdicROA_progressbar"></div>
					<div id="fdicROA"></div>
				</div>

				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="fdicNIM_progressbar"></div>
					<div id="fdicNIM"></div>
				</div>
	
			</div>
			


			<!-- TGIM-U Metrics (lightspeed vt based -->
			<div class="mdl-grid">

				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="tgim_signinsByDay_progressbar"></div>
					<div id="tgim_signinsByDay"></div>
				</div>

				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="tgim_trainingsByDay_progressbar"></div>
					<div id="tgim_trainingsByDay"></div>
				</div>
				
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="tgim_chapterStatusByDate_progressbar"></div>
					<div id="tgim_chapterStatusByDate"></div>
				</div>
				
			</div>



			<!-- task owner and project summary-->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>

				<div class="mdl-cell mdl-cell--5-col" align="center">
					<div style="text-align: center; width: 100%;"><b>Open Tasks By Owner</b></div>	   	
					<table id="taskOwnerSummary" class="compact display">
						<thead>
							<th class="name" title="Task owner name">Task Owner</th>
							<th class="tasksAssigned" title="Count of tasks assigned to owner">Tasks</th>
							<th class="daysAssigned" title="Sum of work days assigned to task owner">Work Days<br>Assigned</th>
							<th class="daysAtRisk" title="After Start Date, if Task not Complete, the number of work days from Start Date to the earlier of today's date or Due Date (otherwise zero). ">Work Days<br>At Risk</th>
							<th class="daysBehind" title="If Task not Complete by Due Date, the number of work days from Due Date to the earlier of today's date or Complete Date.">Work Days<br>Behind</th>
						</thead>
					</table>	   	
				</div>
				<div class="mdl-layout-spacer" style="background: linear-gradient(#000, #000) no-repeat center/2px 100%;"></div>
				<div class="mdl-cell mdl-cell--6-col" align="center">
					<div style="text-align: center; width: 100%;"><b>Open Tasks By Project</b></div>	   	
					<table id="projectSummary" class="compact display">
						<thead>
							<th class="name" title="Project name">Project</th>
							<th class="tasksAssigned" title="Count of tasks assigned in project">Tasks</th>
							<th class="daysAssigned" title="Sum of work days assigned in project">Work Days</th>
							<th class="daysAtRisk" title="After Start Date, if Task not Complete, the number of work days from Start Date to the earlier of today's date or Due Date (otherwise zero). ">Work Days<br>At Risk</th>
							<th class="daysBehind" title="If Task not Complete by Due Date, the number of work days from Due Date to the earlier of today's date or Complete Date.">Work Days<br>Behind</th>
						</thead>
					</table>	   	
				</div>

				<div class="mdl-layout-spacer"></div>
			</div>
		

		</div>
		

		<div id="completeCallHistory" style="display: none"></div>
		<div id="callTypePicker" style="display: none"></div>
			

	</main>

	<!-- #include file="includes/pageFooter.asp" -->
	
</div>



<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>