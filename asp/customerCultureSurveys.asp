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
call checkPageAccess( 142 )


dbug(" ")
userLog("Customer Culture Surveys")

customerID = request.querystring("id")

%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

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

dbug("startDate: " & startDate & ", endDate: " & endDate)

%>


<html>

<head>


	<!-- #include file="includes/globalHead.asp" -->
	<!-- #include file="includes/cNoteGlobalScripting.asp" -->

			
	<script type="text/javascript">
			
		const customerID						= '<% =customerID %>';
		
		google.charts.load( 'current', { 'packages': ['corechart'] } );
		
		google.charts.setOnLoadCallback( drawCharts );
		

		//====================================================================================
		function surveyResultsByDate( customerID ) {
		//====================================================================================
			
			return new Promise( (resolve, reject) => {

				$.ajax({

					dataType: "json",
					url: `${apiServer}/api/surveys/resultsByDate`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },

				}).done( function( data ) {

					let chart = new google.visualization.LineChart(document.getElementById( 'resultsByDate' ));
					let dataTable = new google.visualization.DataTable( data );
					chart.draw( dataTable, {
						explorer: 	tgim_explorer,
			         hAxis: 		tgim_hAxis,
			         height: 	'380',
			         tooltip: { isHtml: true },
				      legend: 	{ position: 'none' },
				      lineWidth: 4,
				      pointSize: 6,
			         title: 	'Survey Results by Date',
			         vAxis: 	{ 
				         title: 'Average Score',
				         maxValue: 7,
				         minValue: 1,
				         gridlines: { 
					         count: 7,
					         interval: [1],
					      },
					      minorGridlines: {
						      count: 0,
					      }
				       },
					});
					resolve();

				}).fail( function( req, status, err ) {
				
					console.error( `Something went wrong (${status}) in surveyResultsByDate(), please contact your system administrator.` );
					throw new Error( err );
				
				});
				
			});
	
			
		}
		//====================================================================================


		//====================================================================================
		function surveyResultsByDateLocation( customerID ) {
		//====================================================================================
			
			return new Promise( (resolve, reject) => {

				$.ajax({

					dataType: "json",
					url: `${apiServer}/api/surveys/resultsByDateLocation`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },

				}).done( function( data ) {

					let chart = new google.visualization.ColumnChart(document.getElementById( 'resultsByDateLocation' ));
					let dataTable = new google.visualization.DataTable( data );
					chart.draw( dataTable, {
						explorer: tgim_explorer,
			         hAxis: tgim_hAxis,
			         height: 	'380',
			         isStacked: false,
				      legend: { position: 'top' },
			         title: 'Survey Statistics by Date',
			         vAxis: { 
				         title: 'Response Count',
				       },
					});
					resolve();

				}).fail( function( req, status, err ) {
				
					console.error( `Something went wrong (${status}) in surveyStatsByDate(), please contact your system administrator.` );
					throw new Error( err );
				
				});
				
			});
	
			
		}
		//====================================================================================


		//====================================================================================
		function surveyStatsByDate( customerID ) {
		//====================================================================================
			
			return new Promise( (resolve, reject) => {

				$.ajax({

					dataType: "json",
					url: `${apiServer}/api/surveys/statsByDate`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },

				}).done( function( data ) {

					let chart = new google.visualization.ColumnChart(document.getElementById( 'statsByDate' ));
					let dataTable = new google.visualization.DataTable( data );
					chart.draw( dataTable, {
						explorer: 	tgim_explorer,
			         hAxis: 		tgim_hAxis,
			         height: 	'380',
			         isStacked: true,
				      legend: 	{ position: 'right' },
			         title: 	'Survey Statistics by Date',
			         tooltip: { isHtml: true },
			         vAxis: 	{ 
				         title: 'Response Count',
				       },
					});
					resolve();

				}).fail( function( req, status, err ) {
				
					console.error( `Something went wrong (${status}) in surveyStatsByDate(), please contact your system administrator.` );
					throw new Error( err );
				
				});
				
			});
	
			
		}
		//====================================================================================


		//====================================================================================
		function surveyParticipationByDate( customerID ) {
		//====================================================================================
			
			return new Promise( (resolve, reject) => {

				$.ajax({

					dataType: "json",
					url: `${apiServer}/api/surveys/participationByDate`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },

				}).done( function( data ) {

					let chart = new google.visualization.ColumnChart(document.getElementById( 'participationByDate' ));
					let dataTable = new google.visualization.DataTable( data );
					chart.draw( dataTable, {
						explorer: tgim_explorer,
/* 						bar: { groupWidth: '30%' }, */
			         hAxis: tgim_hAxis,
			         height: '380',
				      legend: { position: 'none' },
			         title: 'Survey Participation by Date',
			         tooltip: { isHtml: true },
			         vAxis: { 
				         title: 'Participation %',
				         format: 'percent',
// 				         maxValue: 1
							viewWindow: {
								min: 0, 
								max: 1,
							}
				       },
					});
					resolve();

				}).fail( function( req, status, err ) {
				
					console.error( `Something went wrong (${status}) in surveyStatsByDate(), please contact your system administrator.` );
					throw new Error( err );
				
				});
				
			});
	
			
		}
		//====================================================================================


		//====================================================================================
		function surveyDepartmentsBelowThreshold( customerID ) {
		//====================================================================================
			
			var table = $( '#deptBelowThresh' ).DataTable({

				ajax: {
					url: `${apiServer}/api/surveys/departmentsBelowThreshold`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				deferRender: true,
				rowId: 'survey_id',
				scrollY: 630,
				scroller: true,
				scrollCollapse: true,
				searching: false,
				columnDefs: [
					{ targets: 'title', data: 'title', className: 'title dt-body-left' },
					{ targets: 'department', data: 'department', className: 'department dt-body-left' },
					{ targets: 'responseCount', data: 'responseCount', className: 'responseCount dt-body-right' },
				],
				order: [[ 0, 'desc' ]],

			});
	
			
		}
		//====================================================================================


		//====================================================================================
		function surveysByCustomer( customerID ) {
		//====================================================================================
			
			var table = $( '#surveysByCustomer' ).DataTable({

				ajax: {
					url: `${apiServer}/api/surveys/surveysByCustomer`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				deferRender: true,
				rowId: 'survey_id',
				scrollY: 630,
				scroller: true,
				scrollCollapse: true,
				searching: false,
				columnDefs: [
					{ targets: 'title', data: 'title', className: 'title dt-body-left' },
					{ 
						targets: 'firstResponse', 
						data: 'firstResponse', 
						className: 'firstResponse dt-body-center',
						render: function( data, type, row ) {
							if (type === 'display' || type === 'filter') {
								var date = new Date(data);
								return date.toLocaleDateString();
							}
							return data;							
						},
					},
					{ 
						targets: 'lastResponse', 
						data: 'lastResponse', 
						className: 'lastResponse dt-body-center', 
						render: function( data, type, row ) {
							if (type === 'display' || type === 'filter') {
								var date = new Date(data);
								return date.toLocaleDateString();
							}
							return data;							
						},
					},
				],
				order: [[ 1, 'desc' ]],

			});
	
			
		}
		//====================================================================================


		//====================================================================================
		function surveyLocationsBelowThreshold( customerID ) {
		//====================================================================================
			
			var table = $( '#locsBelowThresh' ).DataTable({

				ajax: {
					url: `${apiServer}/api/surveys/locationsBelowThreshold`,
					data: { customerID: customerID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				deferRender: true,
				rowId: 'survey_id',
				scrollY: 630,
				scroller: true,
				scrollCollapse: true,
				searching: false,
				columnDefs: [
					{ targets: 'title', data: 'title', className: 'title dt-body-left' },
					{ targets: 'location', data: 'location', className: 'location dt-body-left' },
					{ targets: 'responseCount', data: 'responseCount', className: 'responseCount dt-body-right' },
				],
				order: [[ 0, 'desc' ]],

			});
	
			
		}
		//====================================================================================


		//================================================================================================ 
		function drawCharts() {
		//================================================================================================ 

			$( async function() {

				
				$( document ).tooltip();

				const chartMaxDate 				= dayjs().toDate();
				const chartMinDate 				= dayjs().add( -<% =monthsOnCharts %>, 'months').toDate();
				const chartExplorerMinDate 	= dayjs().add( -10, 'years' ).toDate();
				const colorPrimary 				= '#512DA8'  	// purple-ish
				const colorSecondary 			= '#F52C2C'		// red-ish
				const colorTertiary				= '#20B256'		// green-ish
				
			
				tgim_explorer = {
					axis: 'horizontal',
					keenInBounds: true,
					maxZoomIn: 7,
					zoomDelta: 1.1,
				}

				tgim_hAxis = {
// 					format: 'yyyy',
					minorGridlines: {count: 0},
	         	viewWindow: {
		         	min: chartMinDate,
		         	max: chartMaxDate,
		         },
				}
				
				
	
				surveyResultsByDate( customerID );
				surveyStatsByDate( customerID );
				surveyParticipationByDate( customerID );
				surveyDepartmentsBelowThreshold( customerID );
				surveyLocationsBelowThreshold( customerID );
				surveysByCustomer( customerID );

																			
			});
			
		}
		//================================================================================================ 

		
		window.onload = function() {
			if ( document.getElementById('mdl-spinner') ) {
				document.getElementById('mdl-spinner').classList.remove('is-active');	
			}
		}
				
	</script>		 

	<style>
		/* prevent Google Chart Tooltips from flashing... */
		svg > g:last-child > g:last-child { pointer-events: none }

/* 	div.google-visualization-tooltip { pointer-events: none !important } */
      .goog-tooltip {
			z-index: 1000 !important;
		}


		#tgim_progressbar .ui-progressbar-value {
			background-color: #ccc;
		}
	
		.page-content {
			padding-top: 1rem;
		}
		
		.kpiTitle {
/* 			border: solid red 1px; */
			font-family: Arial; 
			font-size: 12px;
			fill: #000000; 
			height: 40px;
			stroke: none; 
			stroke-width: 0px;
			font-weight: bold; 
			margin: 5px;  
		}
		
		.kpiContent {
/* 			border: solid orange 2px; */
			display: table;
			height: 60px;
			margin: 5px;
			text-align: center;
			vertical-align: middle;
			width: 93%;
		}

		.kpiValue {
/* 			border: solid green 1px; */
			display: table-cell;
/* 			float: right; */
			font-family: Arial; 
			font-size: 50px; 
			font-weight: bold; 
			line-height: 100%;
			stroke: none; 
		}
		
		.kpiFooter {
			display: table-cell;
			float: right;
			font-family: Arial; 
			stroke: none; 
			margin-right: 15px;
		}
		
		.kpiIcon {
/* 			border: solid blue 1px; */
			display: table-cell;
			height: 100%;
			float: left;
		}
		
		.kpiIcon .material-icons {
			font-size: 50px;
		}
		
		table.control {
			margin-left: auto;
			margin-right: auto;
		}
		
		table.control th {
			text-align: right;
		}
		
		table.control td {
			text-align: left;
		}
		
		
		.dataTableTitle {
			color: #848484;
			text-anchor: start;
			font-family: Roboto;
			font-size: 16px;
			stroke: none;
			stroke-width: 0;
			fill: rgb( 117, 117, 117 );
			margin: 10px 0px 15px 0px;
			text-align: center; 
			width: 100%;
			
		}
		
		#summarizeBy-button {
			float: right;
			z-index: 10;
		}

		#interpolateNullsLabel {
			float: right !important;
			z-index: 10;
		}

		
	</style>
	


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
		<span class="mdl-layout-title">Customer Mystery Shopping</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>
		
	
		<div class="page-content">
			<!-- Your content goes here -->
			
			<!-- Container One -->
			<div class="mdl-grid">


				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div>
						<div id="resultsByDate_progressbar"></div>
						<div id="resultsByDate" style="position: relative; height: 380px;" ></div>
					</div>
				</div>


				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
						<div id="statsByDate_progressbar"></div>
						<div id="statsByDate" style="position: relative; height: 380px;" ></div>
				</div>
			
			
			
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
						<div id="participationByDate_progressbar"></div>
						<div id="participationByDate" style="position: relative; height: 380px;" ></div>
				</div>
			
			

			</div>
			
			
			<!-- Container Two -->
			<div class="mdl-grid">


				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">

					<div style="text-align: center; width: 100%;"><b>Departments Below Reporting Threshold by Survey</b></div>	   	

					<table id="deptBelowThresh" class="compact display">
						<thead>
							<tr>
								<th class="title">Survey Name</th>
								<th class="department">Department</th>
								<th class="responseCount">#</th>
	 						</tr>
						</thead>
					</table>
							
				</div>


				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">

					<div style="text-align: center; width: 100%;"><b>Locations Below Reporting Threshold by Survey</b></div>	   	

					<table id="locsBelowThresh" class="compact display">
						<thead>
							<tr>
								<th class="title">Survey Name</th>
								<th class="location">Location</th>
								<th class="responseCount">#</th>
	 						</tr>
						</thead>
					</table>
							

				</div>
			
			
			
			</div>
			
			
			<!-- Container Three -->
			<div class="mdl-grid">


				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">

					<div style="text-align: center; width: 100%;"><b>Surveys (First and Last Completed Response Dates)</b></div>	   	

					<table id="surveysByCustomer" class="compact display">
						<thead>
							<tr>
								<th class="title">Survey Name</th>
								<th class="firstResponse">First Resp</th>
								<th class="lastResponse">Last Resp</th>
	 						</tr>
						</thead>
					</table>
							
				</div>


				<div class="mdl-cell mdl-cell--6-col">
				</div>
			
			
			
			</div>
			
			
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