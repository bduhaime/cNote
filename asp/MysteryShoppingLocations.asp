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
call checkPageAccess( 143 )


title = session("clientID") & " - Mystery Shopping Location/Customer Mapping" 
userLog(title)

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<!-- 	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script> -->

	<script>

		let table;

		//--------------------------------------------------------------------------------
		async function updateLocation( selectEl, e ) {
		//--------------------------------------------------------------------------------
		
			const $select = $( selectEl );
			
			// Find the row this select lives in
			const $tr = $select.closest( 'tr' );
			const dtRow = table.row( $tr );
			const rowData = dtRow.data();
			
			// New selection
			const newCustomerID = String( $select.val() ?? '' );
			const bankName = rowData.cnote_bankName ?? '';
			
			// If no bank name, just do single update (no bulk option)
			const canBulk = bankName.trim() !== '';
			
			// Helpful label for confirm (text of selected option)
			const customerLabel = $select.find( 'option:selected' ).text().trim();
			
			// Optional: count how many rows match this bank (for the confirm message)
			let matchCount = 0;
			if ( canBulk ) {
				matchCount = table
					.rows( function( idx, d ) { return d.cnote_bankName === bankName; } )
					.count();
			}
			
			let applyToAllForBank = false;
			
			if ( canBulk && matchCount > 1 ) {
				applyToAllForBank = window.confirm(
					`Apply "${customerLabel}" to ALL ${matchCount.toLocaleString()} locations for "${bankName}"?\n\nOK = all locations\nCancel = just this row`
				);
			}
			
			// Call API
			const payload = {
				locationID: rowData.id,
				cnote_customerID: newCustomerID,
				applyToAllForBank: applyToAllForBank,
				cnote_bankName: bankName,
			};
			
			const res = await fetch( `${apiServer}/api/mysteryShopping/locations`, {
				method: 'PUT',
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer ' + sessionJWT,
				},
				body: JSON.stringify( payload ),
			});
			
			if ( !res.ok ) {
				alert( 'Update failed. Try again.' );
				return;
			}
			
			// Update DataTables cache (FAST) so the UI reflects changes immediately
			if ( applyToAllForBank ) {
			
				table.rows( function( idx, d ) {
					return d.cnote_bankName === bankName;
				}).every( function() {

					const d = this.data();
					d.cnote_customerID = newCustomerID;
					
					// if your API provides / you compute customerName separately, update it too:
					// d.customerName = customerLabel;
					
					this.data( d );

				});
				
			} else {
			
				rowData.cnote_customerID = newCustomerID;
				// rowData.customerName = customerLabel;
				dtRow.data( rowData );

			}
			
			// Single redraw, keep scroll/paging position
			table.draw( false );

		}
		//--------------------------------------------------------------------------------



		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------


			// use ajax to get JSON of customers
			// then build a <select> element -- this will be cloned into each row of the DataTable
			//		for the user to identify which cNote customer is associated with each survey
			//	next build a <input> element -- this will also be cloned into each row of the
			//		DataTable for the user to input the total number of employees targeted for each
			//		surve. This is used to determine participation percentage
			// then build the DataTable
			//   	for the customerName column, render a clone of the <select> element
			//		for the employeesSurveyed column, render a clone of the <input> element
			// that's the plan, anyway...

			let selectTemplate;
			$( document ).tooltip();
			
			$.ajax({
				url: `${apiServer}/api/surveys/customers`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
			}).done( function( response ) {
				
				selectTemplate = document.createElement( 'select' );
				$( selectTemplate ).addClass( 'customer' );
				
				inputTemplate = document.createElement( 'input' );
				$( inputTemplate ).addClass( 'employeesSurveyed' );
				

				let firstOpt = document.createElement( 'option' );
				firstOpt.value = '';
				firstOpt.innerHTML = 'Select a customer...';
				selectTemplate.appendChild( firstOpt );
				
				for ( customer of response ) {
					let opt = document.createElement( 'option' );
					opt.value = customer.id;
					opt.innerHTML = customer.name;
					selectTemplate.appendChild( opt );
				}
				
				
				
			}).fail( function( err ) {
				alert( 'Something went wrong, contact system administrator (err: ' + err );
			}).then( function() {
				
				table = $( '#locations' )
					.on( 'change', 'select.customer', function( e ) {
						updateLocation( this, e ); 
					})
					.DataTable({
						ajax: {
							url: `${apiServer}/api/mysteryShopping/locations`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: ''
						},
						deferRender: true,
						rowId: 'id',
						scrollY: 630,
						scroller: {
							rowHeight: 38,
						},
						scrollCollapse: true,
						columnDefs: [
							{ targets: 'name', 					data: 'name', 					className: 'name dt-body-left', searchable: true },
							{ targets: 'cnote_bankName', 		data: 'cnote_bankName', 	className: 'cnote_bankName dt-body-left', visible: false },
							{ targets: 'cnote_bankerTitle', 	data: 'cnote_bankerTitle', className: 'cnote_bankerTitle dt-body-left', visible: false },
							{ targets: 'cnote_bankerName', 	data: 'cnote_bankerName', 	className: 'cnote_bankerName dt-body-left', visible: false },

// 							{ targets: 'cnote_city', 			data: 'cnote_city', 			className: 'cnote_city dt-body-left' },
							{
								targets: 'cnote_city',
								data: 'cnote_city',
								className: 'cnote_city dt-body-center',
								searchable: false,
							
								render: function( data, type, row ) {
							
									const value = row.cnote_city ?? '';
							
									// Tell DataTables what to use for sorting & type detection
									if ( type === 'sort' || type === 'type' ) {
										return value.toLowerCase();
									}
									// What the user actually sees
									return `<input class="cnote_city" value="${value}">`;
							
								}
							},

							{ targets: 'cnote_customerID', 	data: 'cnote_customerID', 	className: 'cnote_customerID dt-body-left', visible: false },

							{
								targets: 'customerName',
								data: 'customerName',
								className: 'customerName dt-body-center',
								orderable: false,
								searchable: false,
								render: function( data, type, row ) {
								
									if ( type !== 'display' ) {
										return data ?? '';
									}
									
									const customerID = String( row.cnote_customerID ?? '' );
									
									const $newSelect = $( selectTemplate ).clone( false );
									$newSelect.val( customerID );
									
									return $newSelect[ 0 ];   // <-- key change
								},
							},

						],
					});

					$.fn.dataTable.ext.search.push( function( settings, data, dataIndex ) {
					
					  if ( settings.nTable.id !== 'locations' ) { return true; }
					
					  const unmappedOnly = $( '#showUnmappedOnly' ).prop( 'checked' );
					  if ( !unmappedOnly ) { return true; }
					
					  const row = table.row( dataIndex ).data();
					  const customerID = row?.cnote_customerID;
					
					  return customerID === null || customerID === undefined || String( customerID ) === '';
					});
					
					$( '#showUnmappedOnly' ).on( 'change', function() {
					  table.draw();
					});


			});

			


		});


	</script>
	
	<style>

		.merge.material-symbols-outlined {
			cursor: pointer;
		}
		
	</style>
	
</head>
	
<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
		
		<div id="snackbar" class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>
			
		<br><br>
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--11-col">
		
				<label style="display:inline-flex; gap:8px; align-items:center;">
					<input type="checkbox" id="showUnmappedOnly">
					Show only unmapped
				</label>

				<table id="locations" class="compact display">
					<thead>
						<tr>
							<th class="name">Secret Shopper Location Name</th>
							<th class="cnote_bankName">Bank Name</th>
							<th class="cnote_bankerName">Banker Name</th>
							<th class="cnote_bankerTitle">Banker Title</th>
							<th class="cnote_city">City</th>
							<th class="cnote_customerID">cNote Customer</th>
							<th class="customerName">Customer</th>
 						</tr>
					</thead>
				</table>
				
			</div>

			<div class="mdl-layout-spacer"></div>
		
		</div><!-- end mdl-grid -->
		
	</div><!-- end page-content -->
    
	<!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>