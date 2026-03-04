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


dbug("customerMysteryShopping - Branches! ")
userLog("Customer Mystery Shopping - Bankers")

customerID = request.querystring("customerID")

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
			
		const customerID						= '<% =customerID %>';
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
		async function setStartEndFromRange( range ) {
		//====================================================================================
			
			const minMaxDates = await getMinMaxShoppedDates( customerID );

			switch ( range ) {

				case 'allDates':

					$( '#startDate' ).val( dayjs( minMaxDates.minDate ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
					break;

				case 'monthToDate':

					$( '#startDate' ).val( dayjs().startOf( 'month' ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs().format( 'MM/DD/YYYY' ) );
					break;

				case 'quarterToDate':

					$( '#startDate' ).val( dayjs().startOf( 'quarter' ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs().format( 'MM/DD/YYYY' ) );
					break; 

				case 'yearToDate':

					$( '#startDate' ).val( dayjs().startOf( 'year' ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs().format( 'MM/DD/YYYY' ) );
					break;

				case 'mostRecent30':

					$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 30, 'day' ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
					break;

				case 'mostRecent90':

					$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 90, 'day' ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
					break;

				case 'mostRecent12Months':

					$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 12, 'month' ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
					break;

				case 'custom': 
				
					$( '#startDate' ).val( dayjs( searchParams.get( 'startDate' ) ).format( 'MM/DD/YYYY' ) );
					$( '#endDate' ).val( dayjs( searchParams.get( 'endDate' ) ).format( 'MM/DD/YYYY' ) );
					break;

				default: 

					console.error( 'Unexpected date range encountered' );

			}
	
		}
		//====================================================================================



		//====================================================================================
		async function getMonthlyTrend( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#monthlyTrend_progressbar' );
			const $kpiContent 	= $( '#monthlyTrend' );
			const $kpiValue		= $( '.monthlyTrend .kpiValue' );
			const $kpiFooter		= $( '.monthlyTrend .kpiFooter' );
			
			const summarizeBy = $( '#summarizeBy' ).val();
			const minMaxDates = await getMinMaxShoppedDates( customerID );

// 			var chartMaxDate 				= dayjs( minMaxDates.maxDate ).toDate();
// 			var chartMinDate 				= dayjs( minMaxDates.minDate ).toDate();
			var chartMaxDate 				= dayjs( $( '#startDate' ).val() ).toDate();
			var chartMinDate 				= dayjs( $( '#endDate' ).val() ).toDate();
			var chartExplorerMinDate 	= dayjs( minMaxDates.minDate ).toDate();

			tgim_explorer = {
				axis: 'horizontal',
				keenInBounds: true,
				maxZoomIn: 7,
				zoomDelta: 1.1,
			}

/*
			tgim_hAxis = {
				format: "<% =hAxisFormat %>",
				minorGridlines: {count: 0},
         	viewWindow: {
	         	min: chartMinDate,
	         	max: chartMaxDate,
	         },
			}
			
*/


			

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/averageScoreByPeriod`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: searchParams.get( 'customerID' ),
					summarizeBy: function() {
						return $( '#summarizeBy' ).val();
					},
					branch: searchParams.get( 'branch' )
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
							top: '25%',
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
			         lineWidth: 	2,
						pointSize: 	2,
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
		function getMostMissedQuestionCategoryByCustomer( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#mostMissedQuestionCategory_progressbar' );
			const $kpiContent 	= $( '.mostMissedQuestionCategory .kpiContent' );
			const $kpiValue		= $( '.mostMissedQuestionCategory .kpiValue' );
			const $kpiFooter		= $( '.mostMissedQuestionCategory .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionCategoryByCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: searchParams.get( 'customerID' ),
					startDate: function() {
						return $( '#startDate' ).val();
					},
					endDate: function() {
						return $( '#endDate' ).val();
					},
					branch: searchParams.get( 'branch' )
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				let html = ( data.length ) ? data[0].name : 'N/A';
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
		function getMostMissedQuestionByCustomer( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#mostMissedQuestion_progressbar' );
			const $kpiContent 	= $( '.mostMissedQuestion .kpiContent' );
			const $kpiValue		= $( '.mostMissedQuestion .kpiValue' );
			const $kpiFooter		= $( '.mostMissedQuestion .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$kpiFooter.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionByCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: searchParams.get( 'customerID' ),
					startDate: function() {
						return $( '#startDate' ).val();
					},
					endDate: function() {
						return $( '#endDate' ).val();
					},
					branch: searchParams.get( 'branch' )
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				let html = ( data.length ) ? data[0].questionText : 'N/A';
				let foot = ( data.length ) ? `Category: ${data[0].categoryName}` : '';
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
	
	
				const minMaxShoppedDates = await getMinMaxShoppedDates( customerID );
				
			
	// 			$( '#clearFilters' ).click( function(e) {
	// 				e.preventDefault;
	// 				searchParams.delete( 'filter' );
	// 				$( '#bankers' ).DataTable().search( '' ).columns().search( '' ).draw();
	// 				$( '#clearFilters' ).hide();
	// 			});				
				
	
	
				$( "#startDate" ).datepicker({
					changeMonth: true,
					changeYear: true,
					maxDate: minMaxShoppedDates.endDate,
					minDate: minMaxShoppedDates.startDate,
					onClose: function( startDate ) {
	
						let dateRange = $( '#dateRange' );
						dateRange[0].selectedIndex = 7;
						dateRange.selectmenu( 'refresh' );
	
						$( '#endDate' ).datepicker( 'option', 'minDate', startDate );
						$( '#branches' ).DataTable().ajax.reload();
					},
				});
				
				$( "#endDate" ).datepicker({
					changeMonth: true,
					changeYear: true,
					maxDate: minMaxShoppedDates.endDate,
					minDate: minMaxShoppedDates.startDate,
					onClose: function( endDate ) {
	
						let dateRange = $( '#dateRange' );
						dateRange[0].selectedIndex = 7;
						dateRange.selectmenu( 'refresh' );
	
						$( '#startDate' ).datepicker( 'option', 'maxDate', endDate );
						$( '#branches' ).DataTable().ajax.reload();
					},
				});
				
				$( '#dateRange' ).selectmenu({
					select: async function( event, ui ) {
	
						const minMaxDates = await getMinMaxShoppedDates( customerID );
	
						switch ( ui.item.value ) {
	
							case 'allDates':
	
								$( '#startDate' ).val( dayjs( minMaxDates.minDate ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;
	
							case 'monthToDate':
	
								$( '#startDate' ).val( dayjs().startOf( 'month' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs().format( 'MM/DD/YYYY' ) );
								break;
	
							case 'quarterToDate':
	
								$( '#startDate' ).val( dayjs().startOf( 'quarter' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs().format( 'MM/DD/YYYY' ) );
								break; 
	
							case 'yearToDate':
	
								$( '#startDate' ).val( dayjs().startOf( 'year' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs().format( 'MM/DD/YYYY' ) );
								break;
	
							case 'mostRecent30':
	
								$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 30, 'day' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;
	
							case 'mostRecent90':
	
								$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 30, 'day' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;
	
							case 'mostRecent12Months':
	
								$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 12, 'month' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;
	
							default: 
	
								console.error( 'Unexpected date range encountered' );
	
						}
	
						$( '#bankers' ).DataTable().ajax.reload();
	
					}
				});
				
				
	
	
				let startDate, endDate;
				
				if ( searchParams.get( 'dateRange' ) ) {
	
					dateRange = searchParams.get( 'dateRange' );
					console.log( 'dates set by dateRange parameter' );
					await setStartEndFromRange( dateRange );	
	
					$( `#dateRange option[value="${dateRange}"]` ).prop( 'selected', true );
					$( '#dateRange' ).selectmenu( 'refresh' );
					
					
				} else {
	
					let dateRange = $( '#dateRange' );
					dateRange[0].selectedIndex = 7;
					dateRange.selectmenu( 'refresh' );
	
					if ( searchParams.get( 'startDate' ) && searchParams.get( 'endDate' ) ) {
						console.log( 'dates set by parameter' );
						$( '#startDate' ).val( searchParams.get( 'startDate' ) );
						$( '#endDate' ).val( searchParams.get( 'endDate' ) );
					} else {
						console.log( 'dates set by API' );
						$( '#startDate' ).val( minMaxShoppedDates.minDate );
						$( '#endDate' ).val( minMaxShoppedDates.maxDate );
					}				
	
				}
	
	
	
				let table = $( '#bankers' )
					.on( 'click', 'tbody > tr', function( event ) {
						var locationID = $( '#bankers' ).DataTable().row( this ).data().locationID;
						
						window.location.href = `customerMysteryShoppingShopListByLocation.asp?customerID=${customerID}&locationID=${locationID}`;
					})
					.DataTable({
						ajax: {
							url: `${apiServer}/api/mysteryShopping/bankers`,
							data: { 
								customerID: customerID,
								startDate: function() {
									return $( '#startDate' ).val();
								},
								endDate: function() {
									return $( '#endDate' ).val();
								},
								branch: 		searchParams.get( 'branch' ),
								supervisor: searchParams.get( 'supervisor' ),
								grade: 		searchParams.get( 'grade' ),
							},
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: ''
						},
						rowId: 'locationID',
						scrollY: 630,
						deferRender: true,
						scroller: true,
						scrollCollapse: true,
						columnDefs: [
							{ targets: 'bankerName',			data: 'bankerName', 				className: 'bankerName dt-body-left' },
							{ 
								targets: 'bankerTitle',			
								data: 'bankerTitle', 			
								className: 'bankerTitle dt-body-left', 
								render: function ( data, type, row ) {
									if ( data.length > 35 ) {
										return data.substr( 0, 35 ) + '…';
									} else { 
										return data;
									}
										
								},
								createdCell: function( cell, cellData, rowData, rowIndex, colIndex ) {
									$( cell ).prop( 'title', cellData );
								}
							},
							{ targets: 'phoneNumber',			data: 'phoneNumber', 			className: 'phoneNumber dt-body-left' },
							{ targets: 'branch',					data: 'branch', 					className: 'branch dt-body-left' },
							{ targets: 'supervisor',			data: 'supervisor', 				className: 'supervisor dt-body-left', width: '10%' },
							{ targets: 'Ace', 					data: 'Ace',						className: 'Ace dt-body-center' },
							{ targets: 'A', 						data: 'A',							className: 'A dt-body-center' },
							{ targets: 'B', 						data: 'B',							className: 'B dt-body-center' },
							{ targets: 'C', 						data: 'C',							className: 'C dt-body-center' },
							{ targets: 'D', 						data: 'D',							className: 'D dt-body-center' },
							{ targets: 'NA', 						data: 'NA',							className: 'NA dt-body-center' },
							{ targets: 'averageScore', 		data: 'averageScore',			className: 'averageScore dt-body-center' },
							{ targets: 'totalShops', 			data: 'totalShops',				className: 'totalShops dt-body-center' },
							{ targets: 'daysSinceLastShop', 	data: 'daysSinceLastShop',		className: 'daysSinceLastShop dt-body-center' },
						],
						order: [[ 0, 'asc' ]],
					}
				);
							
	
				getMonthlyTrend( customerID );
// 				getMostMissedQuestionCategoryByCustomer();
// 				getMostMissedQuestionByCustomer();
	
				$( '#interpolateNulls' ).on( 'change', function() {
					getMonthlyTrend( customerID );
// 					getMostMissedQuestionCategoryByCustomer();
// 					getMostMissedQuestionByCustomer();
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

		
		table.control td {
			white-space: nowrap;
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

		   <div><h4>Mystery Shopping - Bankers</h4></div>

			<div class="mdl-layout-spacer"></div>

   	</div>
   	
   	
   	
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--7-col controls">

				<table class="control">
					<tr>
						<td>Shop Dates:</td>
						<td>
							<select name="dateRange" id="dateRange">
								<option value="allDates">All dates</option>
								<option value="monthToDate">Month to date</option>
								<option value="quarterToDate" selected>Quarter to date</option>
								<option value="yearToDate">Year to date</option>
								<option value="mostRecent30">Most recent 30 days</option>
								<option value="mostRecent90">Most recent 90 days</option>
								<option value="mostRecent12Months">Most recent 12 months</option>
								<option value="custom" disabled>Custom</option>
							</select>
						</td>
						<td>&nbsp;</td>
						<td>Start Date:</td>
						<td><input id="startDate" type="text" class="datepicker" readonly="readonly"></td>
						<td>&nbsp;</td>
						<td>End Date:</td>
						<td><input id="endDate" type="text" class="datepicker" readonly="readonly"></td>
<!--
						<td>&nbsp;</td>
						<td><button id="clearFilters" class="ui-button ui-widget ui-corner-all">Clear Filters</button></td>
-->
					</tr>
				</table>
				
			</div>
			<div class="mdl-layout-spacer"></div>

   	</div><!-- Date Controls -->
   	

		<div class="mdl-grid">
			
			
			<div class="mdl-layout-spacer"></div>


			<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp">

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
		   

			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp mostMissedQuestionCategory">
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
				

			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp mostMissedQuestion">
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

		   <div class="mdl-cell mdl-cell--12-col">
			
				<table id="bankers" class="compact display">
					<thead>
						<tr>
							<th class="bankerName" rowspan="2">Banker</th>
							<th class="bankerTitle" rowspan="2" style="width: 75px;">Title</th>
							<th class="branch" rowspan="2">Branch</th>
							<th class="supervisor" rowspan="2" style="width: 75px;">Supervisor</th>
							<th colspan="7">Shops Grade Distribution</th>
							<th class="averageScore" rowspan="2">Avg.<br>Score</th>
						</tr>
						<tr>
							<th class="Ace">100%</th>
							<th class="A">A</th>
							<th class="B">B</th>
							<th class="C">C</th>
							<th class="D">D</th>
							<th class="NA">N/A</th>
							<th class="totalShops">Total</th>
 						</tr>
					</thead>
				</table>
				
			</div>

			<div class="mdl-layout-spacer"></div>
			
   	</div><!-- DataTable -->

    
  </main>

	<!-- #include file="includes/pageFooter.asp" -->
	
</div>



<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>