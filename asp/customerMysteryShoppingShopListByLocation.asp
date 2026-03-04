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
call checkPageAccess(139)


dbug(" ")
userLog("Customer Mystery Shopping")

customerID = request.querystring("customerID")
locationID = request.querystring("locationID")

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

if len(request.querystring("customerID")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("customerID")
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

	<!-- #include file="includes/cNoteGlobalStyling.asp" -->

	<!-- #include file="includes/cNoteGlobalScripting.asp" -->

			
	<script type="text/javascript">
			
		const customerID	= '<% =customerID %>';
		const locationID	= '<% =locationID %>';
		const sessionJWT	= '<% =sessionJWT %>';
		
		google.charts.load( 'current', { 'packages': ['corechart'] } );
		
		google.charts.setOnLoadCallback( drawCharts );


		let searchParams = new URLSearchParams(window.location.search);
				
		//====================================================================================
		function getMinMaxShoppedDates( customerID ) {
		//====================================================================================

			return new Promise( (resolve, reject) => {

				$.ajax({
					url: `${apiServer}/api/mysteryShopping/minMaxShopDatesForCustomer`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID }
				}).done( data => {
					return resolve( data );
				}).fail( err => {
					return reject( err );
				});
				
			});

		}
		//====================================================================================


		//====================================================================================
		async function getMonthlyTrend( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#monthlyTrend_progressbar' );
			const $kpiContent 	= $( '#monthlyTrend' );
			const $kpiValue		= $( '.monthlyTrend .kpiValue' );
			const $kpiFooter		= $( '.monthlyTrend .kpiFooter' );
			const summarizeBy 	= $( '#summarizeBy' ).val();

			const minMaxDates 				= await getMinMaxShoppedDates( customerID );
			const chartMaxDate 				= dayjs( minMaxDates.maxDate ).toDate();
			const chartMinDate 				= dayjs( minMaxDates.minDate ).toDate();
			const chartExplorerMinDate 	= dayjs( minMaxDates.minDate ).toDate();

			tgim_explorer = {
				axis: 'horizontal',
				keenInBounds: true,
				maxZoomIn: 7,
				zoomDelta: 1.1,
			}


			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/averageScoreByPeriod`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					summarizeBy: summarizeBy,
					startDate: minMaxDates.minDate,
					endDate: minMaxDates.maxDate,
					locationID: searchParams.get( 'locationID' ),
				},
			}).done( data => {

				$progressBar.progressbar( 'destroy' );
				
				let interpolateNulls = $( '#interpolateNulls' ).val();
				
				let dataTable = new google.visualization.DataTable( data );
				let wrapper = new google.visualization.ChartWrapper({
					chartType: 'LineChart',
					dataTable: dataTable,
					options: {
						aggregationTarget: 'none',
						interpolateNulls: $( '#interpolateNulls' ).prop( 'checked' ),
						theme: 'material',
						chartArea:{ 
							left: '12%',
							top: '30%',
							width:'75%',
							height:'50%',
						},
						explorer: 	tgim_explorer,
			         hAxis: {
							minorGridlines: {count: 0},
			         	viewWindow: {
				         	min: chartMinDate,
				         	max: chartMaxDate,
				         },
						},
						height: 180,
						isStacked: true,
						legend: 		{ position: 'top' },
			         lineWidth: 	3,
						pointSize: 	3,
						series: {
							0: { color: 'green', targetAxisIndex: 0 },
							1: { color: 'crimson', targetAxisIndex: 1 },
						},
						title: 'Average Shop Score By Period (all dates)',
						tootltip: { isHtml: true },
						vAxes: {
							0: { title: 'Average Score', textStyle: { color: 'green' }, minValue: 0, maxValue: 100, titleTextStyle: { color: 'green' }  },
							1: { title: '# N/As', textStyle: { color: 'crimson' }, titleTextStyle: { color: 'crimson' } },
						},
					},
					containerId: 'monthlyTrend'
				});

				wrapper.draw();
				
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


		//====================================================================================
		async function getMostMissedQuestionCategoryByCustomer( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#mostMissedQuestionCategory_progressbar' );
			const $kpiContent 	= $( '.mostMissedQuestionCategory .kpiContent' );
			const $kpiValue		= $( '.mostMissedQuestionCategory .kpiValue' );
			const $kpiFooter		= $( '.mostMissedQuestionCategory .kpiFooter' );

			const minMaxDates 	= await getMinMaxShoppedDates( customerID );

			let rando = await $.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionCategoryByCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: minMaxDates.minDate,
					endDate: minMaxDates.maxDate,
					locationID: searchParams.get( 'locationID' )
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				let html = ( data.length ) ? data[0].name : 'None';
				$kpiValue.html( html );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================

				
		//====================================================================================
		async function getMostMissedQuestionByCustomer( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#mostMissedQuestion_progressbar' );
			const $kpiContent 	= $( '.mostMissedQuestion .kpiContent' );
			const $kpiValue		= $( '.mostMissedQuestion .kpiValue' );
			const $kpiFooter		= $( '.mostMissedQuestion .kpiFooter' );

			const minMaxDates 	= await getMinMaxShoppedDates( customerID );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$kpiFooter.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionByCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: minMaxDates.minDate,
					endDate: minMaxDates.maxDate,
					locationID: searchParams.get( 'locationID' )
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				let html = ( data.length ) ? data[0].questionText : 'None';
				let foot = ( data.length ) ? `Category: ${data[0].categoryName}` : 'None';
				$kpiValue.html( html );
				$kpiFooter.html( foot );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================

				
				
		//================================================================================================ 
		function drawCharts() {
		//================================================================================================ 

			$( async function() {
				
	
				$( document ).tooltip();
	
	
				$( '#interpolateNulls' ).checkboxradio();
	
	
				$( '#summarizeBy' ).selectmenu({
					select: function( event, ui ) {
						
						getMonthlyTrend( customerID );
						
					}
				});

	
				// get the data for DataTable...
				let table = $( '#tbl_shops' )
					.on( 'click', 'tbody > tr', function( event ) {
						var shopID = this.id;
						window.location.href = `customerMysteryShoppingShopDetail.asp?customerID=${customerID}&shopID=${shopID}`;
					})
					.DataTable({
						ajax: {
							url: `${apiServer}/api/mysteryShopping/shopsByLocation/${locationID}`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: ''
						},
						scrollY: 630,
						deferRender: true,
						rowId: 'shopID',
						scroller: true,
						scrollCollapse: true,
						searching: false,
						columnDefs: [
							{targets: 'dateShopped',	data: 'dateShopped', 	className: 'dateShopped dt-body-center' },
							{targets: 'score', 			data: 'score', 			className: 'score dt-body-center' },
							{targets: 'scorePoints', 	data: 'scorePoints',		className: 'scorePoints dt-body-center' },
							{targets: 'formName', 		data: 'formName',			className: 'formName dt-body-center' }
						],
						order: [[ 0, 'desc' ]],
					}
				);
	
	
				// retrieve all the info about the location/banker...
				$.ajax({
					url: `${apiServer}/api/mysteryShopping/locations/${locationID}`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				}).then( function( response ) {
	
					$( 'td.locationID' ).html( response.locationID );
					$( 'td.name' ).html( response.name );
					$( 'td.address' ).html( response.address );
					$( 'td.city' ).html( response.city );
					$( 'td.state' ).html( response.state );
					$( 'td.zipCode' ).html( response.zipCode );
					$( 'td.phoneNumber' ).html( response.phoneNumber );
					$( 'td.grouperRegion' ).html( response.grouperRegion );
					$( 'td.grouperDistrict' ).html( response.grouperDistrict );
					$( 'td.grouperArea' ).html( response.grouperArea );
					$( 'td.notesForShopper' ).html( response.notesForShopper );
					$( 'td.notesForCoordinator' ).html( response.notesForCoordinator );
					$( 'td.bankerName' ).html( response.bankerName );
					$( 'td.bankerTitle' ).html( response.bankerTitle );
					$( 'td.bankName' ).html( response.bankName );
					$( 'td.bankerFirstName' ).html( response.bankerFirstName );
					$( 'td.bankerLastName' ).html( response.bankerLastName );
	
				}).fail( function( req, status, err ) {
					console.error( `Something went wrong (${status}) in api/mysteryShopping/shops/:locationID, please contact your system administrator.` );
					throw new Error( err );
				});


				getMonthlyTrend( customerID );
// 				getMostMissedQuestionCategoryByCustomer( customerID );
// 				getMostMissedQuestionByCustomer( customerID );
	


				$( '#interpolateNulls' ).on( 'change', function() {
					getMonthlyTrend( customerID );
// 					getMostMissedQuestionCategoryByCustomer( customerID );
// 					getMostMissedQuestionByCustomer( customerID );
				});

							
															
			});
		
		
		}
			
	</script>		 

	<style>
		/* prevent Google Chart Tooltips from flashing... */
		svg > g:last-child > g:last-child { pointer-events: none }
		div.google-visualization-tooltip { pointer-events: none }

		#tgim_progressbar .ui-progressbar-value {
			background-color: #ccc;
		}
	
		#projectSummary.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
		.page-content {
			padding-top: 1rem;
		}
		
		.accordian {
			margin-left: 1rem;
			margin-right: 1rem;
		}
		
		h3.ui-accordion-header {
			padding-top: 0rem !important;
			padding-bottom: 0rem !important;
		}
		
		div.ui-accordion-content {
			padding-left: 1rem !important;
			padding-right: 1rem !important;
		}
		
		span.peerGroupType {
			float: right;
			vertical-align: middle;
		}

		#locationDetail {
			margin-left: auto;
			margin-right: auto;			
		}
		
		#locationDetail th {
			text-align: left;
			white-space: nowrap; 
		}
		
		#locationDetail td {
			padding-right: 15px;
		}

		#summarizeBy-button {
			float: right;
			z-index: 10;
		}

		#interpolateNullsLabel {
			float: right !important;
			z-index: 10;
		}

		.kpiContent {
			display: flex;
			justify-content: center;
			align-items: center;
			margin: 25px;
		}
		
		.kpiValue {
			width: 100%;
			font-family: Arial; 
			font-size: 16px;
			font-weight: bold; 
			line-height: 100%;
			text-align: center;
			stroke: none; 
		}
		
		.kpiFooter {
			display: table-cell;
			float: right;
			font-family: Arial; 
			stroke: none; 
			margin-right: 15px;
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
			
		<!-- Primary Grid & DataTable -->
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--7-col">
			   
				<table id="locationDetail">
					
					<tr>
						<th>Banker:</th><td class="bankerName"></td>
						<th>&nbsp;</th>
						<th>Title:</th><td class="bankerTitle"></td>
						<th>&nbsp;</th>
						<th>Phone:</th><td class="phoneNumber"></td>
						<th>&nbsp;</th>
						<th>Branch:</th><td class="grouperDistrict"></td>
						<th>&nbsp;</th>
						<th>Supervisor:</th><td class="grouperArea"></td>
					</tr>

				</table>
				   
					   
			   
		   </div>

			<div class="mdl-layout-spacer"></div>

	   </div>
	   
	   
		<div class="mdl-grid">
			
			
			<div class="mdl-layout-spacer"></div>


			<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">

				<div style="margin-top: 10px; margin-right: 10px; margin-bottom: 20px;">					
					<select name="summarizeBy" id="summarizeBy" style="float: right;">
						<option value="day">Summarize By Day</option>
						<option value="week">Summarize By Week</option>
						<option value="month" selected>Summarize By Month</option>
						<option value="quarter">Summarize By Quarter</option>
					</select>

					<label id="interpolateNullsLabel" for="interpolateNulls" style="float: left;" title="Enabling this option connects data points with a line even if there are periods between them without a value.">Fill Gaps</label>
					<input type="checkbox" name="interpolateNulls" id="interpolateNulls" style="float: right;" checked>
					
				</div><br>
				<div>
					<div id="monthlyTrend_progressbar"></div>
					<div id="monthlyTrend"></div>
				</div>
				
			</div><!-- Monthly Trend Chart -->
		   

			<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp mostMissedQuestionCategory">
				<div class="kpiTitle">Most Missed Question Category</div>
				<div class="kpiContent">
					<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">engineering</span>
					<span style="margin-left: 15px;">Under Construction</span>
					<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">construction</span>
					<div id="mostMissedQuestionCategory_progressbar"></div>
					<div class="kpiValue"></div>
				</div>
				<div class="kpiFooter"></div>
			</div><!-- Most Missed Question Category -->
				

			<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp mostMissedQuestion">
				<div class="kpiTitle">Most Missed Question</div>
				<div class="kpiContent">
					<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">engineering</span>
					<span style="margin-left: 15px;">Under Construction</span>
					<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">construction</span>
					<div id="mostMissedQuestion_progressbar"></div>
					<div class="kpiValue"></div>
				</div>
				<div class="kpiFooter"></div>
			</div><!-- Most Missed Question -->
			

			<div class="mdl-layout-spacer"></div>
			
		</div><!-- Chart and Widgets -->
	

   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--7-col" style="height: 400px;">
			
				<table id="tbl_shops" class="compact display">
					<thead>
						<tr>
							<th class="dateShopped">Date Shopped</th>
							<th class="score">Score</th>
							<th class="scorePoints">Points</th>
							<th class="formName">Form</th>
 						</tr>
					</thead>
				</table>
				
			</div><!-- DataTable -->

			<div class="mdl-layout-spacer"></div>
			
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