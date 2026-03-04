<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess( 144 )

title = session("clientID") & " - Marketing Research" 
userLog(title)
%>

<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<script>

		//================================================================================
		function showTransientMessage( msg ) {
		//================================================================================

			let notification = document.querySelector('.mdl-js-snackbar');
			
			console.log( 'toast!' );
			
			notification.MaterialSnackbar.showSnackbar({ message: msg });
			

		}
		//================================================================================

		

		//================================================================================
		function changeInstitutionLabel( domElement ) {
		//================================================================================

			const payload = {
				cert: $( domElement ).closest( 'tr').find( '.cert' ).text(),
				label: $( domElement ).val()
			}
			
			$.ajax({

				url: `${apiServer}/api/marketing/labels`,
				type: 'POST',
				async: false,
				data: payload,
				headers: { 'Authorization': 'Bearer ' + sessionJWT }

			}).done( function() {

				const $table = $( '#institutions' ).DataTable();
				const thisCell = $( domElement ).closest( 'td' ).get(0);				
				$table.cell( thisCell ).data( payload.label );
				
				showTransientMessage( 'Label updated' );

			}).fail( function( err ) {
				
				console.info( 'error in changeInstitutionLabel()' );
				console.error( err );
			
			}); 

		}
		//================================================================================



		//================================================================================
		function multiDeleteLables( certs ) {
		//================================================================================
			
			$.ajax({

				url: `${apiServer}/api/marketing/labels`,
				type: 'DELETE',
				async: false,
				data: { certs: certs },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }

			}).done( function() {

				return true;

			}).fail( function( err ) {
				
				console.info( 'error in multiDeleteLables()' );
				console.error( err );
			
			}); 

		}
		//================================================================================


		//================================================================================
		function multiReplaceLabels( certs, label ) {
		//================================================================================
			
			$.ajax({

				url: `${apiServer}/api/marketing/labels/replace`,
				type: 'POST',
				async: false,
				data: { 
					certs: certs,
					label: label
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }

			}).done( function() {

				return true;

			}).fail( function( err ) {
				
				console.info( 'error in multiReplaceLabels()' );
				console.error( err );
			
			}); 

		}
		//================================================================================


		//================================================================================
		function multiAppendLabels( certs, label ) {
		//================================================================================
			
			$.ajax({

				url: `${apiServer}/api/marketing/labels/append`,
				type: 'POST',
				async: false,
				data: { 
					certs: certs,
					label: label
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }

			}).done( function() {

				return true;

			}).fail( function( err ) {
				
				console.info( 'error in multiAppendLabels()' );
				console.error( err );
			
			}); 

		}
		//================================================================================


		//================================================================================
		function getFilteredCerts() {
		//================================================================================
			
			let certsList = '';
			
			
			const filteredRowsObj = $( '#institutions' ).DataTable().rows({ search: 'applied' }).nodes();
			const filteredRowsArr = Array.from( filteredRowsObj );
			
			filteredRowsArr.forEach( function( row ) {
			
				certsList += ( certsList.length > 0 ) ? ','+row.id : row.id;
				
			});
			
			return certsList;

		}
		//================================================================================



		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------
			
			$( '.mdl-spinner' ).addClass( 'is-active' );

			$( 'input' ).tooltip();
			
			$( document ).tooltip({

				items: '#institutions tbody td:not(.dataTables_empty)',
				content: function() {
					
					const currentRow = $( this ).closest( 'tr' );
					
					const api     = $( '#institutions' ).DataTable();
					const row     = api.row( currentRow );
					const rowData = row && row.length ? row.data() : null;
					
					if ( !rowData || $( this ).hasClass( 'label' ) ) return '';
					
					const NAME = rowData.NAME || '';

					const SPECGRPN 	= rowData.SPECGRPN;
					const STALP 		= rowData.STALP;
					const CITY			= rowData.CITY;
					const WEBADDR 		= rowData.WEBADDR;
					const PARCERT 		= rowData.PARCERT ? rowData.PARCERT : '';
					const OFFICES 		= rowData.OFFICES;
					const MUTUAL		= rowData.MUTUAL;
					const cNoteStatus = rowData.customerStatusName ? rowData.customerStatusName : '';
					const CB				= rowData.CB
					
					return `<table><tbody>
									<tr><td colspan="2" style="font-weight: bold;">${ NAME }<hr></td></tr>
									<tr><td style="font-weight: bold;">Special&nbsp;Group:</td><td>${ SPECGRPN }</td></tr>
									<tr><td style="font-weight: bold;">City/State:</td><td>${CITY}, ${ STALP }</td></tr>
									<tr><td style="font-weight: bold;">Web:</td><td>${ WEBADDR }</td></tr>
									<tr><td style="font-weight: bold;">Parent&nbsp;Cert:</td><td>${ PARCERT }</td></tr>
									<tr><td style="font-weight: bold;">#&nbsp;Offices:</td><td>${ OFFICES }</td></tr>
									<tr><td style="font-weight: bold;">Ownership:</td><td>${ MUTUAL }</td></tr>
									<tr><td style="font-weight: bold;">cNote Status:</td><td>${ cNoteStatus }</td></tr>
									<tr><td style="font-weight: bold;">Community&nbsp;Bank?:</td><td>${ CB }</td></tr>
								</tbody></table>`;
				},
				track: true,
			});
			

			$( "#multiLabel" ).dialog({
				autoOpen: false,
				resizable: false,
				modal: true,
				height: 'auto',
				dialogClass: 'dialogWithDropShadow',		// combined with CSS to create a drop shadow for this dialog
				width: 500,
				buttons: {
					Replace: async function() {

						$( '.mdl-spinner' ).addClass( 'is-active' );
						$( "#multiLabel" ).dialog( "close" );

						let certs = '';	// certs is a comma-delimited string of certs to be updated
						let label = $( '#label' ).val();
						let table = $( '#institutions' ).DataTable();
						let rows = table.rows({ search: 'applied' });
						
						for ( i=0; i <= rows[0].length - 1; ++i ) {
							let cert = table.row( rows[0][i] ).data().cert;
							certs += ( certs.length > 0 ) ? ','+cert : cert;
						}

						multiReplaceLabels( certs, label );
						table.ajax.reload( function() {
							$( '.mdl-spinner' ).removeClass( 'is-active' );
							showTransientMessage( 'Labels replaced' );							
						});
						
					},
					Append: function() {

						$( '.mdl-spinner' ).addClass( 'is-active' );
						$( "#multiLabel" ).dialog( "close" );

						let certs = '';
						let label = $( '#label' ).val();
						let table = $( '#institutions' ).DataTable();
						let rows = table.rows({ search: 'applied' });

						for ( i=0; i <= rows[0].length - 1; ++i ) {
							let cert = table.row( rows[0][i] ).data().cert;
							certs += ( certs.length > 0 ) ? ','+cert : cert;
						}

						multiAppendLabels( certs, label );
						table.ajax.reload( function() {
							$( '.mdl-spinner' ).removeClass( 'is-active' );
							showTransientMessage( 'Labels appended' );							
						});

					},
					Clear: function() {
						
						$( '.mdl-spinner' ).addClass( 'is-active' );
						$( "#multiLabel" ).dialog( "close" );

						let certs = '';
						let label = ''
						let table = $( '#institutions' ).DataTable();
						let rows = table.rows({ search: 'applied' });

						for ( i=0; i <= rows[0].length - 1; ++i ) {
							let cert = table.row( rows[0][i] ).data().cert;
							certs += ( certs.length > 0 ) ? ','+cert : cert;
						}

						multiDeleteLables( certs );
						table.ajax.reload( function() {
							$( '.mdl-spinner' ).removeClass( 'is-active' );
							showTransientMessage( 'Labels cleared' );							
						});
						
					},
					Cancel: function() {
						console.log( 'Cancel button clicked' );
						$( this ).dialog( "close" );
					}
				}
			});


			// Map header class → data property (only where the name differs)
			// Everything else (UBPR*, UBPKE*, RIAD*, etc.) maps 1:1 by default.
			const DATA_KEY_MAP = {
			  CERT: 'cert',
			  label: 'label',
			  Fed_RSSD: 'Fed_RSSD',
			  NAME: 'NAME',
			  ADDRESS: 'ADDRESS',
			  CITY: 'CITY',
			  STALP: 'STALP',
			  ZIP: 'ZIP',
			  CB: 'CB',
			  SPECGRPN: 'SPECGRPN',
			  WEBADDR: 'WEBADDR',
			  PARCERT: 'PARCERT',
			  OFFICES: 'OFFICES',
			  MUTUAL: 'MUTUAL',
			  customerStatusName: 'customerStatusName',
			  ASSET: 'ASSET'
			};
			


			var table = $( '#institutions' )

				.on( 'init.dt', function( e, settings, json ) {
					// Only Claude AI and God know how this function works. But it works.
					// Don't waste time trying to improve it.
				
					const reportingPeriod = json.params.reportingPeriod;
					$( '.reportingPeriod' ).text( reportingPeriod );
					
					$( '.mdl-spinner' ).removeClass( 'is-active' );
					
					// Set up observer to sort SearchBuilder columns alphabetically
					const observer = new MutationObserver(function(mutations) {
						mutations.forEach(function(mutation) {
							mutation.addedNodes.forEach(function(node) {
								if (node.nodeType === 1) { // Element node
									// Check if this is a SearchBuilder data select
									const selects = $(node).find('select.dtsb-data').addBack('select.dtsb-data');
									if (selects.length > 0) {
										selects.each(function() {
											sortSelectOptions(this);
										});
									}
								}
							});
						});
					});
					
					// Start observing the document for SearchBuilder elements
					observer.observe(document.body, {
						childList: true,
						subtree: true
					});
					
					// Also handle existing SearchBuilder if already present
					setTimeout(function() {
						$('select.dtsb-data').each(function() {
							sortSelectOptions(this);
						});
					}, 100);
				
				})
    


				.on( 'init.dt', function( e, settings, json ) {
					
					const reportingPeriod = json.params.reportingPeriod;
					$( '.reportingPeriod' ).text( reportingPeriod );
					
					$( '.mdl-spinner' ).removeClass( 'is-active' );
					
					
				})
				.DataTable({
					buttons: [
						{
							extend: 'colvisGroup',
							text: 'DEPOSIT',
							show: '.deposit',
							hide: '.income, .loan, .balance, .efficiency, .misc '
						},
						{
							extend: 'colvisGroup',
							text: 'INCOME',
							show: '.income',
							hide: '.deposit, .loan, .balance, .efficiency, .misc'
						},
						{
							extend: 'colvisGroup',
							text: 'LOAN',
							show: '.loan',
							hide: '.deposit, .income, .balance, .efficiency, .misc'
						},
						{
							extend: 'colvisGroup',
							text: 'BALANCE',
							show: '.balance',
							hide: '.deposit, .income, .loan, .efficiency, .misc'
						},
						{
							extend: 'colvisGroup',
							text: 'EFFICIENCY',
							show: '.efficiency',
							hide: '.deposit, .income, .loan, .balance, .misc'
						},
						{
							extend: 'colvisGroup',
							text: 'MISC',
							show: '.misc',
							hide: '.deposit, .income, .loan, .balance, .efficiency '
						},
						{
							extend: 'colvisGroup',
							text: 'ALL',
							show: '.deposit, .income, .loan, .balance, .efficiency, .misc '
						},
						{
							extend: 'csv',
							text: 'Download',
							exportOptions: {
							format: {
								body: function( data, row, column, node ) {
									
									if ( column === 0 ) {
										return $( data ).val();
									}
									return data;
									
								}
							}
		                },
		                exportData: function() {
		                    console.log('Exporting data...');
		                }
		            },
						{
							text: 'Labels',
							action: function() {
								$( "#multiLabel" ).dialog( "open" );
							}
						},
						{
							text: 'Map',
							action: function() {
								certsToMap = getFilteredCerts();
								sessionStorage.setItem( 'certsToMap', certsToMap );
								window.location.href = 'marketingMap.asp';
							}
						}
					],

					ajax: { 
						url: `${apiServer}/api/marketing/institutions`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: 'data',
					},
 					deferRender: true,
 					processing: false,
 					rowId: 'cert',
					responsive: false,
					rowCallback: async function ( row, data, displayNum, displayIndex, dataIndex ) {

						$( row ).on( 'change', 'input.label', function () {
							const newLabel = $( this ).val();
							changeInstitutionLabel( this );
						});

					},
					scrollX: true,
					scrollY: 600,
					scroller: true,

					dom: 'QBftip',
// 					dom: 'Bftip',

					searchBuilder: { columns: '.searchable' },

					

					columnDefs: [
						{ targets: 'label', data: 'label', className: 'label dt-body-left searchable', 
							render: function( data, type, row, meta ) {
								if ( type === 'display' ) {
									const text = data ? data : '';
// 									return `<input class="label" value="${text}"></>`;
									return `<input class="label" value="${text}" onchange="changeInstitutionLabel( this );"></>`;
								}
								return data;
							},
							searchBuilder: {
								orthogonal: {
									display: 'filter'
								}
							},
						},
						
						{
							targets: 'dummy',
							data: null,                 // <- IMPORTANT: explicitly says "no data source"
							defaultContent: '',         // render blank (also silences the warning)
							orderable: false,
							searchable: false
						},


						{ targets: 'CERT', data: 'cert', className: 'cert dt-body-left searchable' },
						{ targets: 'Fed_RSSD', data: 'Fed_RSSD', className: 'Fed_RSSD misc dt-body-left searchable', searchBuilderTitle: 'Federal RSSD' },
						{ targets: 'NAME', data: 'NAME', className: 'NAME dt-nowrap dt-body-left searchable', searchBuilderTitle: 'Institution Name' },
						{ targets: 'ADDRESS', data: 'ADDRESS', className: 'ADDRESS misc dt-body-left searchable', visible: false },
						{ targets: 'CITY', data: 'CITY', className: 'CITY misc dt-body-left searchable', searchBuilderTitle: 'City' },
						{ targets: 'STALP', data: 'STALP', className: 'STALP dt-body-left searchable', searchBuilderTitle: 'State' },
						{ targets: 'ZIP', data: 'ZIP', className: 'ZIP dt-body-left searchable', type: 'string', searchBuilderTitle: 'Zip' },
						{ targets: 'CB', data: 'CB', className: 'CB misc dt-body-left searchable', searchBuilderTitle: 'Community Bank?' },
						{ targets: 'SPECGRPN', data: 'SPECGRPN', className: 'SPECGRPN dt-body-left', visible: false, searchBuilderTitle: 'Ownership' },
						{ targets: 'WEBADDR', data: 'WEBADDR', className: 'WEBADDR dt-body-left', visible: false, searchBuilderTitle: 'Web Address' },
						{ targets: 'PARCERT', data: 'PARCERT', className: 'PARCERT dt-body-left', visible: false, searchBuilderTitle: 'Parent CERT' },
						{ targets: 'OFFICES', data: 'OFFICES', className: 'OFFICES dt-body-right', render: $.fn.dataTable.render.number( ',', '.', 0 ), visible: false }, 
						{ targets: 'MUTUAL', data: 'MUTUAL', className: 'MUTUAL dt-body-left searchable', searchBuilderTitle: 'Ownership' },
						{ targets: 'customerStatusName', data: 'customerStatusName', className: 'customerStatusName misc dt-body-left searchable', searchBuilderTitle: 'cNote Customer Status' },
						{ targets: 'UBPR2170', data: 'UBPR2170', className: 'UBPR2170 dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 0, '$' ), searchBuilderTitle: 'Total Assets' },


						{ targets: 'UBPR2200', data: 'UBPR2200', className: 'UBPR2200 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 0, '$' ), searchBuilderTitle: 'Total Deposits ($Thousand) - Bank' },
						{ targets: 'UBPRE162', data: 'UBPRE162', className: 'UBPRE162 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Total Deposits one quarter change - Bank' },
						{ targets: 'UBPRE209', data: 'UBPRE209', className: 'UBPRE209 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Total Deposits Annual Change - Bank' },
						{ targets: 'UBPKE209', data: 'UBPKE209', className: 'UBPKE209 deposit dt-body-right dt-head-right searchable', searchBuilderTitle: 'Total Deposits Annual Change - %ile' },
						{ targets: 'UBPRK435', data: 'UBPRK435', className: 'UBPRK435 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Core Deposits Annual Change - Bank' },
						{ targets: 'UBPRE591', data: 'UBPRE591', className: 'UBPRE591 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Core Deposits % Total Assets - Bank' },
						{ targets: 'UBPKE591', data: 'UBPKE591', className: 'UBPKE591 deposit dt-body-right dt-head-right searchable', searchBuilderTitle: 'Core Deposits % Total Assets - %ile' },
						{ targets: 'UBPRM009', data: 'UBPRM009', className: 'UBPRM009 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Domestic Demand Deposits % Total Deposits - Bank' },
						{ targets: 'UBPKM009', data: 'UBPKM009', className: 'UBPKM009 deposit dt-body-right dt-head-right searchable', searchBuilderTitle: 'Domestic Demand Deposits % Total Deposits - %ile' },
						{ targets: 'UBPRE380', data: 'UBPRE380', className: 'UBPRE380 deposit dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Memo: All Brokered Deposits % Avg Assets - Bank' },
						{ targets: 'UBPKE380', data: 'UBPKE380', className: 'UBPKE380 deposit dt-body-right dt-head-right searchable', searchBuilderTitle: 'Memo: All Brokered Deposits % Avg Assets - %ile' },


						{ targets: 'UBPRE075', data: 'UBPRE075', className: 'UBPRE075 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Net Operating Income one-year growth rate - Bank' },
						{ targets: 'UBPKE075', data: 'UBPKE075', className: 'UBPKE075 income dt-body-right dt-head-right searchable', searchBuilderTitle: 'Net Operating Income one-year growth rate - %ile' },
						{ targets: 'UBPRE013', data: 'UBPRE013', className: 'UBPRE013 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'ROA - Net Income % Avg Assets - Bank' },
						{ targets: 'UBPKE013', data: 'UBPKE013', className: 'UBPKE013 income dt-body-right dt-head-right searchable', searchBuilderTitle: 'ROA - Net Income % Avg Assets - %ile' },
						{ targets: 'UBPRE018', data: 'UBPRE018', className: 'UBPRE018 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'NIM - Net Interest Income (TE) % Avg Earning Assets - Bank' },
						{ targets: 'UBPKE018', data: 'UBPKE018', className: 'UBPKE018 income dt-body-right dt-head-right searchable', searchBuilderTitle: 'NIM - Net Interest Income (TE) % Avg Earning Assets - %ile' },
						{ targets: 'UBPRE004', data: 'UBPRE004', className: 'UBPRE004 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Noninterest Income % Avg Assets - Bank' },
						{ targets: 'UBPKE004', data: 'UBPKE004', className: 'UBPKE004 income dt-body-right dt-head-right searchable', searchBuilderTitle: 'Noninterest Income % Avg Assets - %ile' },
						{ targets: 'UBPRE630', data: 'UBPRE630', className: 'UBPRE630 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'ROE - Return on Equity - Bank' },
						{ targets: 'UBPKE630', data: 'UBPKE630', className: 'UBPKE630 income dt-body-right dt-head-right searchable', searchBuilderTitle: 'ROE - Return on Equity - %ile' },
						{ targets: 'UBPRKW06', data: 'UBPRKW06', className: 'UBPRKW06 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 0, '$' ), searchBuilderTitle: 'Provision for Credit Losses on all Other Assets - Bank' },
						{ targets: 'UBPRKW08', data: 'UBPRKW08', className: 'UBPRKW08 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Provision for Credit Losses on all Other Assets - annual change - Bank' },
						{ targets: 'UBPRE070', data: 'UBPRE070', className: 'UBPRE070 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Provision for Loan & Lease Losses - annual change - Bank' },
						{ targets: 'RIAD4230', data: 'RIAD4230', className: 'RIAD4230 income dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 0, '$' ), searchBuilderTitle: 'Provision for Credit Losses - Bank' },


						{ targets: 'UBPRE027', data: 'UBPRE027', className: 'UBPRE027 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Net Loans & Leases 12-month growth rate - Bank' },
						{ targets: 'UBPKE027', data: 'UBPKE027', className: 'UBPKE027 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Net Loans & Leases 12-month growth rate - %ile' },
						{ targets: 'UBPR7414', data: 'UBPR7414', className: 'UBPR7414 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Noncurrent Loans & Leases to Gross Loans & Leases - Bank' },
						{ targets: 'UBPK7414', data: 'UBPK7414', className: 'UBPK7414 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Noncurrent Loans & Leases to Gross Loans & Leases - %ile' },
						{ targets: 'UBPRE601', data: 'UBPRE601', className: 'UBPRE601 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Net Loans & Leases % Core Deposits - Bank' },
						{ targets: 'UBPKE601', data: 'UBPKE601', className: 'UBPKE601 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Net Loans & Leases % Core Deposits - %ile' },
						{ targets: 'UBPRE600', data: 'UBPRE600', className: 'UBPRE600 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Net Loans & Leases % Total Deposits - Bank' },
						{ targets: 'UBPKE600', data: 'UBPKE600', className: 'UBPKE600 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Net Loans & Leases % Total Deposits - %ile' },
						{ targets: 'UBPRE023', data: 'UBPRE023', className: 'UBPRE023 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Allowance for Credit Losses on LN&LS to Total LN&LS - Bank' },
						{ targets: 'UBPKE023', data: 'UBPKE023', className: 'UBPKE023 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Allowance for Credit Losses on LN&LS to Total LN&LS - %ile' },
						{ targets: 'UBPRE141', data: 'UBPRE141', className: 'UBPRE141 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Net Loans & Leases one quarter change - Bank' },
						{ targets: 'UBPRE006', data: 'UBPRE006', className: 'UBPRE006 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Provision for Loan & Lease Losses as a percent of Average Assets - Bank' },
						{ targets: 'UBPKE006', data: 'UBPKE006', className: 'UBPKE006 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Provision for Loan & Lease Losses as a percent of Average Assets - %ile' },
						{ targets: 'UBPRE019', data: 'UBPRE019', className: 'UBPRE019 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Net Loan & Lease Charge-Offs to Average Total LN&LS - Bank' },
						{ targets: 'UBPKE019', data: 'UBPKE019', className: 'UBPKE019 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Net Loan & Lease Charge-Offs to Average Total LN&LS - %ile' },
						{ targets: 'UBPRE020', data: 'UBPRE020', className: 'UBPRE020 loan dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Earnings Coverage of Net Losses - Bank' },
						{ targets: 'UBPKE020', data: 'UBPKE020', className: 'UBPKE020 loan dt-body-right dt-head-right searchable', searchBuilderTitle: 'Earnings Coverage of Net Losses - %ile' },

						{ targets: 'UBPRD487', data: 'UBPRD487', className: 'UBPRD487 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Tier One Risk-Based Capital to Risk-Weighted Assets - Bank' },
						{ targets: 'UBPKD487', data: 'UBPKD487', className: 'UBPKD487 balance dt-body-right dt-head-right searchable', searchBuilderTitle: 'Tier One Risk-Based Capital to Risk-Weighted Assets - %ile' },
						{ targets: 'UBPRK441', data: 'UBPRK441', className: 'UBPRK441 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Fully Insured Brokered Deposits as a percent of Average Assets - Bank' },
						{ targets: 'UBPKK441', data: 'UBPKK441', className: 'UBPKK441 balance dt-body-right dt-head-right searchable', searchBuilderTitle: 'Fully Insured Brokered Deposits as a percent of Average Assets - %ile' },
						{ targets: 'UBPRE371', data: 'UBPRE371', className: 'UBPRE371 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Federal Funds Purch & Repos as a percent of Average Assets - Bank' },
						{ targets: 'UBPKE371', data: 'UBPKE371', className: 'UBPKE371 balance dt-body-right dt-head-right searchable', searchBuilderTitle: 'Federal Funds Purch & Repos as a percent of Average Assets - %ile' },
						{ targets: 'UBPRE372', data: 'UBPRE372', className: 'UBPRE372 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Total Fed Home Loan Borrowings as a percent of Avg Assets - Bank' },
						{ targets: 'UBPKE372', data: 'UBPKE372', className: 'UBPKE372 balance dt-body-right dt-head-right searchable', searchBuilderTitle: 'Total Fed Home Loan Borrowings as a percent of Avg Assets - %ile' },
						{ targets: 'UBPRE200', data: 'UBPRE200', className: 'UBPRE200 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Average Assets During quarter annual change - Bank' },
						{ targets: 'UBPRE153', data: 'UBPRE153', className: 'UBPRE153 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Average Assets During Quarter one quarter change - Bank' },
						{ targets: 'UBPR7316', data: 'UBPR7316', className: 'UBPR7316 balance dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 4, null, '%' ), searchBuilderTitle: 'Total Assets - Annual Change - Bank' },
						{ targets: 'UBPK7316', data: 'UBPK7316', className: 'UBPK7316 balance dt-body-right dt-head-right searchable', searchBuilderTitle: 'Total Assets - Annual Change - %ile' },

						{ targets: 'UBPRE088', data: 'UBPRE088', className: 'UBPRE088 efficiency dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 2, null, '%' ), searchBuilderTitle: 'Efficiency Ratio - Bank' },
						{ targets: 'UBPKE088', data: 'UBPKE088', className: 'UBPKE088 efficiency dt-body-right dt-head-right searchable', searchBuilderTitle: 'Efficiency Ratio - %ile' },
						{ targets: 'UBPRE090', data: 'UBPRE090', className: 'UBPRE090 efficiency dt-body-right dt-head-right searchable', render: $.fn.dataTable.render.number( ',', '.', 0, '$' ), searchBuilderTitle: 'Assets Per Employee ($Million) - Bank' },
						{ targets: 'UBPKE090', data: 'UBPKE090', className: 'UBPKE090 efficiency dt-body-right dt-head-right searchable', searchBuilderTitle: 'Assets Per Employee ($Million) - %ile' },


// 						{ targets: -1, defaultContent: '', className: 'dummy', orderable: false },

					],
					order: [[ 8, 'desc' ]],

				});
						
		});


		// Function to sort select options alphabetically
		function sortSelectOptions(selectElement) {
			// Only Claude AI and God know how this function works. But it works.
			// Don't waste time trying to improve it.
			
			const $select = $(selectElement);
			const $options = $select.find('option');
			
			if ($options.length <= 1) return; // Nothing to sort
			
			// Save the currently selected value
			const selectedValue = $select.val();
			
			// Find the placeholder option (usually has empty value or specific text)
			let $placeholder = $options.filter(function() {
				return $(this).val() === '' || $(this).text().includes('Select');
			}).first();
			
			// If no placeholder found, use the first option
			if ($placeholder.length === 0) {
				$placeholder = $options.first();
			}
			
			// Get all other options
			const $restOptions = $options.not($placeholder);
			
			// Sort the rest alphabetically
			const sortedOptions = $restOptions.sort(function(a, b) {
				return $(a).text().trim().localeCompare($(b).text().trim());
			});
			
			// Rebuild the select
			$select.empty().append($placeholder).append(sortedOptions);
			
			// Restore the selected value, or reset to placeholder
			if (selectedValue && selectedValue !== '') {
				$select.val(selectedValue);
			} else {
				$select.val($placeholder.val());
			}
		
		}


	</script>

	<style>
		
		#institutions thead tr th {
			vertical-align: bottom !important;
		}
		
		.mdl-navigation {
			padding-left: 8px;
		}
		
		#applyFilter {
			width: 100px;
		}

		div.ui-tooltip {
			max-width: 600px;
		}
		
		.mdl-layout__drawer {
			width: 500px;
			left: -250px;
		}
		
		.mdl-layout__drawer.is-visible {
			left: 0;
		}	
		
		input.amount {
			width: 90px;
			float: right;
			text-align: right;
		}	

		input.ratio {
			width: 75px;
			float: right;
			text-align: right;
		}	

		input.rank {
			width: 45px;
			float: right;
			text-align: right;
		}
		
		.is-invalid {
			color: red;
			background-color: yellow;
		}

		.dialogWithDropShadow {
			-webkit-box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.5);  
			-moz-box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.5); 
		}
		
		.warning {
			vertical-align: bottom;
			font-size: 48px;
			color: #e65014;
			font-weight: bold;
		}
		
		.mdl-spinner {
			width: 56px;
			height: 56px;
		}
		
		.mdl-spinner__circle {
			border-width: 6px;
		}
		
/*
		table tfoot tr td {
			float: right;
		}
*/

		table.dataTable thead th {
			vertical-align: bottom;
		}
		
		#institutions th.dummy,
		#institutions td.dummy {
		  width: 15px;
		  min-width: 15px;
		  max-width: 15px;
		}
	</style>


</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>

<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
<header class="mdl-layout__header">

	<div class="mdl-layout__header-row">
		<!-- Title -->
		<span class="mdl-layout-title"><% =title %></span>

		<div class="mdl-layout-spacer"></div>

		<div class="mdl-layout-title">Reporting Period:&nbsp;<span class="reportingPeriod"></span></div>
		
		<!-- Add spacer, to align navigation to the right -->
		<div class="mdl-layout-spacer"></div>
		
		<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

	</div>
</header>

<main class="mdl-layout__content">

	<!-- snackbar -->
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	
	<div class="page-content">
	<!-- Your content goes here -->
		
		
		<div id="multiLabel" title="Apply Labels To Multiple Institutions">
			<p><b>Replace:&nbsp;</b>Overwrites all labels for the each institution with the new value provided here<br>
			<p><b>Append:&nbsp;</b>Adds the value provided here to the end of any/all existing labels for each institution<br>
			<p><b>Clear:&nbsp;</b>Deletes any/all existing labels for each institution</p>
			<p><span class="material-symbols-outlined warning">warning</span><b>Caution:&nbsp;</b>The action selected will be applied immediately to all currently visible rows; this action cannot be undone!</p> 

			<label for="label"><b>Labels:</b></label><br>
			<input type="text" id="label" class="text ui-widget-content ui-corner-all" style="width: 98%;">
					
			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">

		</div>		

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--11-col" width="100%">

				<table id="institutions" class="compact display">
					<thead>
						<tr>
							<th class="label" rowspan="3">Labels</th>
							<th class="CERT" rowspan="3">CERT</th>
							<th class="NAME" rowspan="3">Name</th>
							<th class="STALP" rowspan="3">State</th>
							<th class="SPECGRPN" rowspan="3">SPECGRPN</th>
							<th class="WEBADDR" rowspan="3">Web</th>
							<th class="PARCERT" rowspan="3">Parent CERT</th>
							<th class="OFFICES" rowspan="3">Offices</th>
							<th class="MUTUAL" rowspan="3">Ownership</th>
							<th class="UBPR2170" title="UBPR2170" rowspan="3">Total Assets</th>

							<th rowspan="3" class="dummy deposit"></th>
							<th class="deposit" colspan="17">DEPOSIT</th>

							<th rowspan="3" class="dummy income"></th>
							<th class="income" colspan="22">INCOME</th>

							<th rowspan="3" class="dummy loan"></th>
							<th class="loan" colspan="25">LOAN</th>

							<th rowspan="3" class="dummy balance"></th>
							<th class="balance" colspan="18">BALANCE</th>

							<th rowspan="3" class="dummy efficiency"></th>
							<th class="efficiency" colspan="5">EFFICIENCY</th>

							<th rowspan="3" class="dummy misc"></th>
							<th class="Fed_RSSD misc" rowspan="3">Federal RSSD</th>
							<th class="CITY misc" rowspan="3">City</th>
							<th class="customerStatusName misc" rowspan="3">cNote Status</th>
							<th class="CB misc" rowspan="3">Community Bank?</th>
							<th class="ADDRESS misc" rowspan="3">Address</th>
							<th class="ZIP misc" rowspan="3">Zip</th>

						</tr>
						<tr>

							<!-- deposit -->
							<th colspan="1" class="deposit dt-head-right">Total Deposits ($Thousand)</th>
							<th class="dummy deposit" rowspan="2"></th>
							<th colspan="1" class="deposit dt-head-right">Total Deposits one quarter change</th>
							<th class="dummy deposit" rowspan="2"></th>
							<th colspan="2" class="deposit dt-head-right">Total Deposits Annual Change</th>							
							<th class="dummy deposit" rowspan="2"></th>
							<th class="deposit">Core Deposits Annual Change</th>
							<th class="dummy deposit" rowspan="2"></th>
							<th colspan="2" class="deposit dt-head-right">Core Deposits % Total Assets</th>
							<th class="dummy deposit" rowspan="2"></th>
							<th colspan="2" class="deposit dt-head-right">Domestic Demand Deposits % Total Deposits</th>
							<th class="dummy deposit" rowspan="2"></th>
							<th colspan="2" class="deposit dt-head-right">Memo: All Brokered Deposits % Avg Assets</th>
							<!-- deposit -->


							<!-- income -->
							<th colspan="2" class="income dt-head-right">Net Operating Income one-year growth rate</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="2" class="income dt-head-right">NIM - Net Interest Income (TE) % Avg Earning Assets</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="2" class="income dt-head-right">Noninterest Income % Avg Assets</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="2" class="income dt-head-right">ROA - Net Income % Avg Assets</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="2" class="income dt-head-right">ROE - Return on Equity</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="1" class="income dt-head-right">Provision for Credit Losses</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="1" class="income dt-head-right">Provision for Credit Losses - annual change</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="1" class="income dt-head-right">Provision for Credit Losses on all Other Assets</th>
							<th class="dummy income" rowspan="2"></th>
							<th colspan="1" class="income dt-head-right">Provision for Credit Losses on all Other Assets - annual change</th>
							<!-- income -->


							<!-- loan -->
							<th colspan="2" class="loan dt-head-right">Net Loans & Leases 12-month growth rate</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Noncurrent Loans & Leases to Gross Loans & Leases</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Net Loans & Leases % Core Deposits</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Net Loans & Leases % Total Deposits</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Allowance for Credit Losses on LN&LS to Total LN&LS</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="1" class="loan dt-head-right">Net Loans & Leases one quarter change</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Provision for Loan & Lease Losses as a percent of Average Assets</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Net Loan & Lease Charge-Offs to Average Total LN&LS</th>
							<th class="dummy loan" rowspan="2"></th>
							<th colspan="2" class="loan dt-head-right">Earnings Coverage of Net Losses</th>
							<!-- loan -->


							<!-- balance -->
							<th colspan="2" class="balance">Tier One Risk-Based Capital to Risk-Weighted Assets</th>
							<th class="dummy balance" rowspan="2"></th>
							<th colspan="2" class="balance">Fully Insured Brokered Deposits as a percent of Average Assets</th>
							<th class="dummy balance" rowspan="2"></th>
							<th colspan="2" class="balance">Federal Funds Purch & Repos as a percent of Average Assets</th>
							<th class="dummy balance" rowspan="2"></th>
							<th colspan="2" class="balance">Total Fed Home Loan Borrowings as a percent of Avg Assets</th>
							<th class="dummy balance" rowspan="2"></th>
							<th colspan="1" class="balance">Average Assets During quarter annual change</th>
							<th class="dummy balance" rowspan="2"></th>
							<th colspan="1" class="balance">Average Assets During Quarter one quarter change</th>
							<th class="dummy balance" rowspan="2"></th>
							<th colspan="2" class="balance">Total Assets - Annual Change</th>
							<!-- balance -->


							<!-- efficiency -->
							<th colspan="2" class="efficiency dt-head-right">Efficiency Ratio</th>
							<th class="dummy efficiency" rowspan="2"></th>
							<th colspan="2" class="efficiency dt-head-right">Assets Per Employee ($Million)</th>
							<!-- efficiency -->

						</tr>
						<tr>

							<!-- deposit (11 cols) -->
							<th class="UBPR2200 deposit" title="UBPR2200">Bank</th>
							<th class="UBPRE162 deposit" title="UBPRE162">Bank</th>
							<th class="UBPRE209 deposit" title="UBPRE209">Bank</th>
							<th class="UBPKE209 deposit" title="UBPKE209">%ile</th>
							<th class="UBPRK435 deposit" title="UBPRK435">Bank</th>
							<th class="UBPRE591 deposit" title="UBPRE591">Bank</th>
							<th class="UBPKE591 deposit" title="UBPKE591">%ile</th>
							<th class="UBPRM009 deposit" title="UBPRM009">Bank</th>
							<th class="UBPKM009 deposit" title="UBPKM009">%ile</th>
							<th class="UBPRE380 deposit" title="UBPRE380">Bank</th>
							<th class="UBPKE380 deposit" title="UBPKE380">%ile</th>
							<!-- deposit -->
							

							<!-- income (14 cols) -->
							<th class="UBPRE075 income" title="UBPRE075">Bank</th>
							<th class="UBPKE075 income" title="UBPKE075">%ile</th>
							<th class="UBPRE018 income" title="UBPRE018">Bank</th>
							<th class="UBPKE018 income" title="UBPKE018">%ile</th>
							<th class="UBPRE004 income" title="UBPRE004">Bank</th>
							<th class="UBPKE004 income" title="UBPKE004">%ile</th>
							<th class="UBPRE013 income" title="UBPRE013">Bank</th>
							<th class="UBPKE013 income" title="UBPKE013">%ile</th>
							<th class="UBPRE630 income" title="UBPRE630">Bank</th>
							<th class="UBPKE630 income" title="UBPKE630">%ile</th>
							<th class="RIAD4230 income" title="RIAD4230">Bank</th>
							<th class="UBPRE070 income" title="UBPRE070">Bank</th>
							<th class="UBPRKW06 income" title="UBPRKW06">Bank</th>
							<th class="UBPRKW08 income" title="UBPRKW08">Bank</th>
							<!-- income -->


							<!-- loan (17 cols) -->
							<th class="UBPRE027 loan" title="UBPRE027">Bank</th>
							<th class="UBPKE027 loan" title="UBPKE027">%ile</th>
							<th class="UBPR7414 loan" title="UBPR7414">Bank</th>
							<th class="UBPK7414 loan" title="UBPK7414">%ile</th>
							<th class="UBPRE601 loan" title="UBPRE601">Bank</th>
							<th class="UBPKE601 loan" title="UBPKE601">%ile</th>
							<th class="UBPRE600 loan" title="UBPRE600">Bank</th>
							<th class="UBPKE600 loan" title="UBPKE600">%ile</th>
							<th class="UBPRE023 loan" title="UBPRE023">Bank</th>
							<th class="UBPKE023 loan" title="UBPKE023">%ile</th>
							<th class="UBPRE141 loan" title="UBPRE141">Bank</th>
							<th class="UBPRE006 loan" title="UBPRE006">Bank</th>
							<th class="UBPKE006 loan" title="UBPKE006">%ile</th>
							<th class="UBPRE019 loan" title="UBPRE019">Bank</th>
							<th class="UBPKE019 loan" title="UBPKE019">%ile</th>
							<th class="UBPRE020 loan" title="UBPRE020">Bank</th>
							<th class="UBPKE020 loan" title="UBPKE020">%ile</th>
							<!-- loan -->


							<!-- balance (12 cols) -->
							<th class="UBPRD487 balance" title="UBPRD487">Bank</th>
							<th class="UBPKD487 balance" title="UBPKD487">%ile</th>
							<th class="UBPRK441 balance" title="UBPRK441">Bank</th>
							<th class="UBPKK441 balance" title="UBPKK441">%ile</th>
							<th class="UBPRE371 balance" title="UBPRE371">Bank</th>
							<th class="UBPKE371 balance" title="UBPKE371">%ile</th>
							<th class="UBPRE372 balance" title="UBPRE372">Bank</th>
							<th class="UBPKE372 balance" title="UBPKE372">%ile</th>
							<th class="UBPRE200 balance" title="UBPRE200">Bank</th>
							<th class="UBPRE153 balance" title="UBPRE153">Bank</th>
							<th class="UBPR7316 balance" title="UBPR7316">Bank</th>
							<th class="UBPK7316 balance" title="UBPK7316">%ile</th>
							<!-- balance -->


							<!-- efficiency (4 cols) -->
							<th class="UBPRE088 efficiency" title="UBPRE088">Bank</th>
							<th class="UBPKE088 efficiency" title="UBPKE088">%ile</th>
							<th class="UBPRE090 efficiency" title="UBPRE090">Bank</th>
							<th class="UBPKE090 efficiency" title="UBPKE090">%ile</th>
							<!-- efficiency -->

						</tr>
					</thead>
				</table>

		   </div>
			<div class="mdl-layout-spacer"></div>
   	</div>
			
	</div><!-- end of page-content -->



</main>
<!-- #include file="includes/pageFooter.asp" -->



</body>
</html>