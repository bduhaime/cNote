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
userLog("Customer Mystery Shopping - Shops")

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
	
		}
		//====================================================================================



		//====================================================================================
		$( async function() {
		//====================================================================================
			
			$( document ).tooltip();


			let searchParams = new URLSearchParams(window.location.search);
			
			const minMaxShoppedDates = await getMinMaxShoppedDates( customerID );
			
		
			$( '#clearFilters' ).click( function(e) {
				e.preventDefault;
				searchParams.delete( 'filter' );
				$( '#bankers' ).DataTable().search( '' ).columns().search( '' ).draw();
				$( '#clearFilters' ).hide();
			});				
			


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

					$( '#shops' ).DataTable().ajax.reload();

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

				if ( searchParams.get( 'startDate' ) && searchParams.get( 'endDate' ) ) {
					console.log( 'dates set by parameter' );
					startDate = searchParams.get( 'startDate' );
					endDate = searchParams.get( 'endDate' );
				} else {
					console.log( 'dates set by API' );
					startDate = minMaxShoppedDates.minDate;
					endDate = minMaxShoppedDates.maxDate;
				}				

			}


			let table = $( '#shops' )
				.on( 'click', 'tbody > tr', function( event ) {
					
					const shopID = $( '#shops' ).DataTable().row( this ).data().shopID;
					const locationID = $( '#shops' ).DataTable().row( this ).data().locationID;
					
					window.location.href = `customerMysteryShoppingShopDetail.asp?customerID=${customerID}&locationID=${locationID}&shopID=${shopID}`;
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/mysteryShopping/shops`,
						data: { 
							customerID: customerID,
							startDate: function() {
								return $( '#startDate' ).val();
							},
							endDate: function() {
								return $( '#endDate' ).val();
							}
						},
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					autoWidth: false,
					rowId: 'shopID',
					scrollY: 630,
					deferRender: true,
					scroller: true,
					scrollCollapse: true,
					columnDefs: [
						{ targets: 'dateShopped', 		data: 'dateShopped',		className: 'dateShopped dt-body-center' },
						{ targets: 'locationID',		data: 'locationID', 		className: 'locationID dt-body-left', visible: false  },
						{ targets: 'bankerName',		data: 'bankerName', 		className: 'bankerName dt-body-left' },
						{
							targets: 'bankerTitle',	
							data: 'bankerTitle', 	
							className: 'bankerTitle dt-body-left',
							render: function ( data, type, row ) {
								if ( data.length > 45 ) {
									return data.substr( 0, 45 ) + '…';
								} else { 
									return data;
								}
									
							},
							createdCell: function( cell, cellData, rowData, rowIndex, colIndex ) {
								$( cell ).prop( 'title', cellData );
							}
						},
						{ targets: 'supervisor',		data: 'supervisor', 		className: 'supervisor dt-body-left', defaultContent: '<i> none</i>' },
						{ targets: 'branch', 			data: 'branch',			className: 'branch dt-body-left', defaultContent: '<i> none</i>' },
						{ targets: 'score', 				data: 'score',				className: 'score dt-body-center' },
						{ targets: 'scorePoints', 		data: 'scorePoints',		className: 'scorePoints dt-body-center' },
					],
					order: [[ 0, 'asc' ]],
				}
			);


			if ( searchParams.get( 'branch' ) ) {

				const branchTerm 		= searchParams.get( 'branch' ) == 'null' ? ' none' : searchParams.get( 'branch' )
				const supervisorTerm = searchParams.get( 'supervisor' ) == 'null' ? ' none' : searchParams.get( 'supervisor' )
				$( '#clearFilters' ).show();
				$( '#shops' ).DataTable()
					.column( '.branch' ).search( `^${branchTerm}$`, true, false, true )
					.column( '.supervisor' ).search( `^${supervisorTerm}$`, true, false, true )
					.draw();

			}
// 			if ( searchParams.get( 'supervisor' ) ) {
// 
// 				const supervisorTerm = searchParams.get( 'branch' ) == 'null' ? 'none' : searchParams.get( 'branch' )
// 				$( '#clearFilters' ).show();
// 				$( '#bankers' ).DataTable()
// 				.column( '.supervisor' ).search( `^${supervisorTerm}$`, true, false, true )
// 				.draw();
// 
// 			}
						
														
		});
			
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
		
		
		table.control td {
			white-space: nowrap;
		}
		
		td.bankerTitle {
			width: 200px;
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

		   <div><h4>Mystery Shopping - Shops</h4></div>

			<div class="mdl-layout-spacer"></div>

   	</div>
   	
   	
   	
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--11-col controls">

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
						<td>&nbsp;</td>
						<td><button id="clearFilters" class="ui-button ui-widget ui-corner-all">Clear Filters</button></td>
					</tr>
				</table>
				
			</div>
			<div class="mdl-layout-spacer"></div>

   	</div>
   	
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--11-col">
			
				<table id="shops" class="compact display">
					<thead>
						<tr>
							<th class="dateShopped">Date Shopped</th>
							<th class="locationID">locationID</th>
							<th class="bankerName">Banker</th>
							<th class="bankerTitle">Title</th>
							<th class="supervisor">Supervisor</th>
							<th class="branch">Branch</th>
							<th class="score">Score</th>
							<th class="scorePoints">Points</th>
 						</tr>
					</thead>
				</table>
				
			</div>

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