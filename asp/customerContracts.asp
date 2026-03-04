<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess( 132 )


title = session("clientID") & " - Customer Contracts" 
userLog(title)

if len( request.querystring("id") ) > 0 then 
	customerID = request.querystring("id" )
else 
	customerID = 0
end if

if ( userPermitted( 141 ) ) then 
	pricingVisibility = 1 
else 
	pricingVisibility = 0
end if 

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<!-- DataTables Editor -->
	<script type="text/javascript" src="Editor-2.5.1/js/dataTables.editor.js"></script>
	<script type="text/javascript" src="Editor-2.5.1/js/editor.jqueryui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="Editor-2.5.1/css/editor.dataTables.css">



<!-- 	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script> -->

	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.18.1/moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script>

		const customerID		= <% =customerID %>;
		const pricingVisibility = ( <% =pricingVisibility %> ) ? true : false;
		
		
		( function($) {
					 
			$( document ).ready( function() {
				
				$( document ).tooltip();
				
				var editor = new $.fn.dataTable.Editor( {
					ajax: {
						url: `${apiServer}/api/customerContracts`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					},
					formOptions: {
						main: {
							onEsc: 'none'
						}
					},
					table: "#customerContracts",
					fields: [ 
						{ 
							label: '',
							name: "active"	,
							type: "checkbox",
							options: [
								{ label: "Active", value: 1 }
							], 
							separator: '', 
							unselectedValue: 0 
						}, 
						{ label: "Federal Certificate:", 					name: "cert" }, 
						{ label: "Product:", 									name: "product", 				type: "select" }, 
						{ label: "Contract Version:", 						name: "contractType" }, 
						{ label: "Contract Level:", 							name: "contractLevel" }, 
						{ label: "Contract Renewal Type:", 					name: "contractRenewalType" }, 
						{ label: "Term:", 										name: "term" }, 
						{ label: "Effective Date:", 							name: "effectiveDate", 		type: "datetime" }, 
						{ label: "Termination Letter Date:", 				name: "termLetterDate", 	type: "datetime" }, 
						{ label: "Superseded Date:", 							name: "supersededDate",		type: "datetime" }, 
						{ label: "MOM / BFL Start Date:", 					name: "mom_bfl_startDate",	type: "datetime" }, 
						{ label: "Expiration Date:", 							name: "expirationDate",		type: "datetime" }, 
						{ label: "Initial MRR Amount:", 						name: "initialMRRAmt"  }, 
						{ label: "CPI Start Date:", 							name: "cpiStartDate",		type: "datetime",  }, 
						{ label: "CPI Increate Percent:", 					name: "cpiIncreasePct"  }, 
						{ label: "Increate From Asset Growth Amount:", 	name: "increaseFromAssetGrowthAmt"  }, 
						{ label: "Total Monthly Increase Amount:", 		name: "totalMonthlyIncreaseAmt"  }, 
						{ label: "Prior Year Increase Percent:", 			name: "priorYearIncreasePct"  }, 
						{ label: "Notes:",										name: "notes",					type: "textarea" }
					]
				});
	
	
				contractProducts = [];
				$.getJSON( {
					url: `${apiServer}/api/customerContracts/products`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				},
				function( data ) {
					let option = {};
					$.each( data.data, function( i, e ) { 
						option.label 	= e.name;
						option.value	= e.id;
						contractProducts.push( option );
						option = {};
					});
				}).done( function() {
					editor.field( 'product' ).update( contractProducts );
				})						
						
	
				$('#customerContracts').DataTable( {
					<% if userPermitted( 130 ) then %>
					dom: "Bfrtip",
					<% end if %>
					ajax: { 
						url: `${apiServer}/api/customerContracts`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						data: { customerID: customerID }
					},
					columns: [
						{ data: "customerName", className: "dt-body-left dt-head-left" },
						{ data: "cert" },
						{ 
							data: 'active', 
							className: "dt-body-center dt-head-center",
							render: function( data, type, row ) {
								if ( data ) {
									return '<span class="material-symbols-outlined">check</span>'
								} else {
									return ''
								}
							}
						},
						{ data: "product", className: "dt-body-left dt-head-left" },
						{ data: "contractType", className: "dt-body-left dt-head-left" },
						{ data: "contractLevel", className: "dt-body-left dt-head-left" },
						{ data: "contractRenewalType", className: "dt-body-left dt-head-left" },
						{ data: "term", className: "dt-body-left dt-head-left" },
						{ data: "effectiveDate", 					className: "dt-body-center dt-head-center" },
						{ data: "termLetterDate", 					className: "dt-body-center dt-head-center" },
						{ data: "supersededDate", 					className: "dt-body-center dt-head-center" },
						{ data: "mom_bfl_startDate", 				className: "dt-body-center dt-head-center" },
						{ data: "expirationDate", 					className: "dt-body-center dt-head-center" },
						
						{ 
							data: "initialMRRAmt", 					
							className: "dt-body-right dt-head-right", 
							render: $.fn.dataTable.render.number( ',', '.', 0, '$' ),
							visible: pricingVisibility 
						},
						{ 
							data: "cpiStartDate", 					
							className: "dt-body-center dt-head-center",
							visible: pricingVisibility 
						},
						{ 
							data: "cpiIncreasePct", 					
							className: "dt-body-right dt-head-right", 
							render: $.fn.dataTable.render.number(',', '.', 2, '', '%'),
							visible: pricingVisibility 
						},
						{ 
							data: "increaseFromAssetGrowthAmt", 	
							className: "dt-body-right dt-head-right", 
							render: $.fn.dataTable.render.number( ',', '.', 0, '$' ),
							visible: pricingVisibility 
						},
						{ 
							data: "totalMonthlyIncreaseAmt", 		
							className: "dt-body-right dt-head-right", 
							render: $.fn.dataTable.render.number( ',', '.', 0, '$' ),
							visible: pricingVisibility 
						},
						{ 
							data: "priorYearIncreasePct", 			
							className: "dt-body-right dt-head-right", 
							render: $.fn.dataTable.render.number(',', '.', 2, '', '%'),
							visible: pricingVisibility 
						},
						{ 
							data: "notes", 
							visible: pricingVisibility 
						}
					],
					scroller: { rowHeight: 38 },
					scrollX: true,
					fixHeader: true,
					scrollCollapse: true,
					scrollY: 650,
					select: true,
					lengthChange: false,
					searching: false,
					buttons: [
						{ extend: "create", editor: editor },
						{ extend: "edit",   editor: editor },
						{ extend: "remove", editor: editor }
					]
				});
	
	
				editor.on( 'create', function( e, json, data, id ) {
					console.log({ 'function': 'create', e: e, json: json, data: data, id: id });
				});
	
				editor.on( 'edit',  function( e, json, data, id ) {
					console.log({ 'function': 'edit', e: e, json: json, data: data, id: id });
				});
	
				editor.on( 'remove', function( e, json, data, id ) {
					console.log({ 'function': 'delete', e: e, json: json, data: data, id: id });
				});
				
			});

 
		}(jQuery));


	</script>
	
	<style>

		/* Customized Styling For [D]ata[T]able [E]ditor */
		.DTE_Header { display: none; 	}
		.DTE_Body { padding-top: 0px !important; padding-bottom: 0px !important; }
		.DTE_Field { padding-left: 15px !important; padding-right: 15px !important; }
		.DTE_Footer { display: none; }		

		
		table.dataTable > tbody > tr:hover {
			cursor: pointer;
		}

		i.delete, i.edit, i.contracts {
			visibility: hidden;
		}
		
		#contractDetail {
			display: none;
			border-collapse: collapse;
		}
		
		#contractDetail th {
			text-align: left;
		}
		
		#contractDetail th.title {
			text-align: center;
			background: lightgrey;
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
	    
<% if customerID > 0 then %>
    
	<!-- #include file="includes/customerTabs.asp" -->

<% end if %>


  </header>


  <main class="mdl-layout__content">
    <div id="tbl_customerList" class="page-content">
    <!-- Your content goes here -->
    
	 	<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
	</div>

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--11-col">
			
				<table id="customerContracts" class="compact display">
					<thead>
						<tr>
							<th class="customerName" title="Customer Name">Customer Name</th>
							<th class="cert" title="FDIC Cert#">Cert</th>
							<th class="active">Active</th>
							<th class="product">Product</th>
							<th class="contractType" title="Contract Type Legacy: Legacy FCP: Full Culture Program BBPC: Better Banking Performance Culture CC: Continuing Client">Version</th>
							<th class="contractLevel" title="Contract Level Codes: A:  Advanced C:  Core EM:  Elite Customized: Customized">Level</th>
							<th class="contractRenewalType" title="Contract renewal type: AR-Auto-Roll;  BFL-Better Future Lock-In;  MOM-Momentum">Renewal Type</th>
							<th class="term" title="Term of Current Contract">Term</th>
							<th class="effectiveDate" title="Current Contract Sign Date/ Effective Date">Effective Date</th>
							<th class="termLetterDate" title="Date of Termination Letter">Term Letter Date</th>
							<th class="supercededDate" title="Date Contract Superseded">Superseded Date</th>
							<th class="mom_bfl_startDate" title="MOM/Bigger Future Lock-In (BFL) Start Date">MOM/BFL Date</th>
							<th class="expirationDate" title="Contract Expiration Date is based upon: • End of term in agreement with no compulsory extension option • End of current Momentum or Bigger Future Lock-In extension with no compulsory extension option • No date provided if term is ongoing subject to 12-month notice">Expiration Date</th>
							<th class="initialMRRAmt" title="Initial MRR">Initial MRR</th>
							<th class="cpiStartDate" title="CPI Start Date (invoice date)">CPI Start Date</th>
							<th class="cpiIncreasePct" title="CPI Increase (1.4%)">CPI Increase Percent</th>
							<th class="increaseFromAssetGrowthAmt" title="Increase from Growth in Total Assets (Capped at 20%)">Increase From Asset Growth</th>
							<th class="totalMonthlyIncreaseAmt" title="Total monthly increase">Total Monthly Increase</th>
							<th class="priorYearIncreasePct" title="Total Prior Year Increase %">Prior Year Increase Percent</th>
							<th class="notes" title="Notes extracted from Contract Billing Master">notes</th>
						</tr>
					</thead>
				</table>
				

				</div>
			<div class="mdl-layout-spacer"></div>
			
   	</div>	
    
  </main>
  <!-- #include file="includes/pageFooter.asp" -->

<% if customerID <> 0 then %>
</div>
<% end if %>


<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>