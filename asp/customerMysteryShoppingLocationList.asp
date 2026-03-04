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
			
		const customerID						= '<% =customerID %>';
		const locationID						= '<% =locationID %>';
		
				
		$( function() {
			
			$( document ).tooltip();

			let table = $( '#locations' )
				.on( 'click', 'tbody > tr', function( event ) {
					var locationID = this.id;
					window.location.href = `customerMysteryShoppingShopListByLocation.asp?customerID=${customerID}&locationID=${locationID}`;
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/mysteryShopping/locationsByCustomer`,
						data: { customerID: customerID },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					scrollY: 630,
					deferRender: true,
					rowId: 'locationID',
					scroller: true,
					scrollCollapse: true,
					searching: false,
					columnDefs: [
						{targets: 'bankerName',				data: 'bankerName', 				className: 'bankerName dt-body-left' },
						{targets: 'bankerTitle', 			data: 'bankerTitle', 			className: 'bankerTitle dt-body-left' },
						{targets: 'address', 				data: 'address',					className: 'address dt-body-left' },
						{targets: 'city', 					data: 'city',						className: 'city dt-body-left' },
						{targets: 'stateAbbreviation', 	data: 'stateAbbreviation',		className: 'stateAbbreviation dt-body-center' },
						{targets: 'zipCode', 				data: 'zipCode',					className: 'zipCode dt-body-left' },
						{targets: 'phoneNumber', 			data: 'phoneNumber',				className: 'phoneNumber dt-body-left' },
						{targets: 'branch', 					data: 'branch',					className: 'branch dt-body-left' },
						{targets: 'supervisor', 			data: 'supervisor',				className: 'supervisor dt-body-left' },
						{targets: 'timesShopped', 			data: 'timesShopped',			className: 'timesShopped dt-body-center' },
						{targets: 'lastDateShopped', 		data: 'lastDateShopped',		className: 'lastDateShopped dt-body-center' },
					],
					order: [[ 10, 'desc' ]],
				}
			);

						
														
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

		   <div><h4>Mystery Shopping Banker/Location List</h4></div>

			<div class="mdl-layout-spacer"></div>

   	</div>
   	
   	
   	
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--10-col">
			
				<table id="locations" class="compact display">
					<thead>
						<tr>
							<th class="bankerName">Banker</th>
							<th class="bankerTitle">Title</th>
							<th class="address">Address</th>
							<th class="city">City</th>
							<th class="stateAbbreviation">State</th>
							<th class="zipCode">Zip Code</th>
							<th class="phoneNumber">Phone</th>
							<th class="branch">Branch</th>
							<th class="supervisor">Supervisor</th>
							<th class="timesShopped"># Times<br>Shopped</th>
							<th class="lastDateShopped">Date Last<br>Shopped</th>
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