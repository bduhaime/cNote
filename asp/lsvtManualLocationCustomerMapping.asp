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
call checkPageAccess( 140 )


title = session("clientID") & " - LSVT Manual Location/Customer Mapping" 
userLog(title)

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<!-- 	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script> -->

	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.18.1/moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script>


		//--------------------------------------------------------------------------------
		function updateUnassignedLocationCount() {
		//--------------------------------------------------------------------------------

			let api = $('#locations').DataTable();
			
			let emptyCount = api
				.rows({ search: 'applied' })
				.data()
				.filter(function(row) {
					return !row.customerID;   // or !row.customerName
				}).length;
			
			$('#unassignedLocationCount').text( emptyCount );

		}
		//--------------------------------------------------------------------------------
		

		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------

			// use ajax to get JSON of customers
			// then build a <select> element -- this will be cloned into each row of the DataTable
			// then build the DataTable
			//   for the customerName column, render a clone of the <select> element
			// that's the plan, anyway...

			let selectTemplate;

			$.ajax({
				url: `${apiServer}/api/tgimu/customers`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
			}).done( function( response ) {
				
				selectTemplate = document.createElement( 'select' );
				$( selectTemplate ).addClass( 'customer' );

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

				let activeFilter = ''; // default = show all
				
				if ( document.referrer && document.referrer.includes('executiveDashboard.asp') ) {
					activeFilter = 'true';                       // force filter
					$('#activeFilter').val('true');              // set dropdown UI
				}

				// Custom filter hook
				$.fn.dataTable.ext.search.push(function(settings, data, dataIndex, rowData) {
				if (!activeFilter) return true; // no filter applied
					return rowData.isActive === (activeFilter === 'true');
				});
				
				
				var table = $( '#locations' )
					.on( 'draw.dt', function() {
						
						// re-bind the select change handler
						$('select.customer').off('change').on('change', function() {

							let locationID = $(this).closest('tr').attr('id');
							let customerID = $(this).val();
							
							$.ajax({
								url: `${apiServer}/api/tgimu/locations`,
								type: 'PUT',
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								data: { locationID: locationID, customerID: customerID }
							}).done(function() {
								console.log('LSVT Location updated');
								
								updateUnassignedLocationCount();
  
							}).fail(function() {
								console.error('update of LSVT location failed');
							});
						});
						
						updateUnassignedLocationCount();						


					})
					.DataTable({
						ajax: {
							url: `${apiServer}/api/tgimu/locations`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: '',
						},
						rowId: 'locationID',
						scrollY: 630,
						deferRender: true,
						scroller: true,
						scrollCollapse: true,
						searching: true,
						columnDefs: [
							{ targets: 'locationName', 	data: 'locationName', 	className: 'locationName dt-body-left', searchable: true },
							{ 
								targets: 'isActive', 		
								data:	'isActive', 		
								className: 'isActive dt-body-center',
								render: function( data, type, row ) {
									
									return row.isActive ? '<span class="material-icons">done</span>' : null;

								},
								searchable: true,
							},
							{ targets: 'customerID', 	data: 'customerID', 		className: 'customerID dt-body-center', visible: false, searchable: false },
							{
								targets: 'customerName', 	
								data: 'customerName', 	
								className: 'customerName dt-body-center', 
								orderable: false,
								render: function( data, type, row ) {

									let $newSelect = $( selectTemplate ).clone( true );
									if ( row.customerID ) {
										$newSelect.find( `option[value="${row.customerID}"]` ).attr( 'selected', true );
									}

									return $newSelect.prop( 'outerHTML' );
		
								},
								searchable: false,
							},
						],
					});
				
// 				$( 'select.customer' ).on( 'change', function() {
// 					console.log( 'Customer changed' );
// 				});

			// Dropdown listener
			$('#activeFilter').on('change', function() {
				activeFilter = $(this).val(); // "" | "true" | "false"
				table.draw();
			});

				
			});
			

		});


	</script>
	
	<style>

		
	</style>
	
</head>
	
<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
		
		<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>
			
		<br><br>
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--7-col">

				<label for="activeFilter">Show: </label>
					<select id="activeFilter">
						<option value="">All</option>
						<option value="true">Active</option>
						<option value="false">Inactive</option>
					</select>

		
				<table id="locations" class="compact display">
					<thead>
						<tr>
							<th class="locationName">LSVT Location Name</th>
							<th class="isActive">Active?</th>
							<th class="customerID">customerID</th>
							<th class="customerName">Customer</th>
 						</tr>
					</thead>
				</table>
				
				
				<div>
					Unassigned Location count: <span id="unassignedLocationCount">0</span>
				</div>
				
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