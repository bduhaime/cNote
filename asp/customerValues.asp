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
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeByCustomer.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(37)

dbug(" ")
userLog("customer values")
templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")
customerID = request.querystring("id")

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


	</main>
	
</div>

<!-- #include file="includes/pageFooter.asp" -->

<script src="dialog-polyfill.js"></script>  
<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>