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
' call checkPageAccess(139)


dbug("customerMysteryShopping - MS Banks Not Assigned to a Customer ")
title = "customerMysteryShopping - MS Banks Not Assigned to a Customer" 
userLog( title )

%>


<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<!-- #include file="includes/cNoteGlobalStyling.asp" -->

	<!-- #include file="includes/cNoteGlobalScripting.asp" -->

			
	<script type="text/javascript">

		console.log({ sessionJWT });

		const customerID						= '<% =customerID %>';


		//====================================================================================
		$( async function() {
		//====================================================================================
			

			let table = $( '#msBanks' ).DataTable({
				ajax: {
					url: `${apiServer}/api/mysteryShopping/msBanksWithoutCustomers`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				scrollY: 630,
				deferRender: true,
				scroller: true,
				scrollCollapse: true,
				columnDefs: [
					{targets: 'bankName',				data: 'bankName', 				className: 'bankName dt-body-left' },
					{targets: 'lastDateShopped',		data: 'lastDateShopped', 		className: 'lastDateShopped dt-body-center' },
				],
				order: [[ 0, 'asc' ]],
			});
						
														
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

		   <div><h4>Mystery Shopping - Shopped Banks Not Assigned To A Customer</h4></div>

			<div class="mdl-layout-spacer"></div>

   	</div>
   	
   	
   	
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--6-col">
			
				<table id="msBanks" class="compact display">
					<thead>
						<tr>
							<th class="bankName">Shopped Bank</th>
							<th class="lastDateShopped">Last Shopped</th>
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