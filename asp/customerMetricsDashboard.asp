<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->

<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(118)

title = session("clientID") & " - Customer Metrics Dashboard" 
userLog(title)
arrStatusList = split( request.querystring("statusList"), "," )

function valuePresent( arrayValue, arrayName ) 
	
	present = false
	
	for i = lBound( arrayName ) to uBound( arrayName ) 
		if cStr(arrayName(i)) = cStr(arrayValue) then 
			present = true 
			exit for 
		end if 
	next 
	
	valuePresent = present 
	
	
end function 

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	Dayjs -->
	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>

	<!-- 	Google Visualizations -->
	<script src="https://www.gstatic.com/charts/loader.js"></script>


	<script>

		const startTime	= performance.now();

		//================================================================================
		function showTransientMessage( msg ) {
		//================================================================================
		
			let notification = document.querySelector('.mdl-js-snackbar');
		
			notification.MaterialSnackbar.showSnackbar({ message: msg });
		
		
		}
		//================================================================================
		
		
		
		//====================================================================================
 		function customerStatusList( ) {
		//================================================================================================ 

			let stringStatusList = ''
			
			$( 'input.customerStatus' ).each( function() {

				if ( $( this ).is( ':checked' ) ) {
					elemID = $(this).attr('id');
					customerStatusID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
					if ( stringStatusList.length > 0 ) stringStatusList += ',';
					stringStatusList += customerStatusID;
				}

			});

			return stringStatusList;


 		}
		//====================================================================================

 		
		//====================================================================================
		function getQueryVariable( variable ) {
		//====================================================================================

			var query = window.location.search.substring( 1 );
			var vars = query.split( '&' );

			for ( var i = 0; i < vars.length; i++ ) {
				var pair = vars[i].split( '=' );
				if ( decodeURIComponent( pair[0] ) == variable ) {
					return decodeURIComponent( pair[1] );
				}
			}
	
			console.log( 'Query variable %s not found', variable );
	
		}
		//====================================================================================


		//====================================================================================
		function formatDateForSorting( dateValue, renderType ) {
		//====================================================================================

			if ( renderType == 'sort' ) {
				if ( dayjs( dateValue, 'M/D/YYYY' ).isValid() ) {
					return dayjs( dateValue ).format( 'YYYY-MM-DD' );
				} else {
					return dateValue;
				}
			} else {
				return dateValue;
			}


			
		}
		//====================================================================================
		

		google.charts.load( 'current', { packages: [ 'corechart', 'line', 'calendar', 'timeline' ] } );


		//====================================================================================
		google.charts.setOnLoadCallback( function() {
		//====================================================================================


			$( function() {
	
				$( document ).tooltip();
				$( 'input.customerStatus' ).checkboxradio();

				$( 'input.customerStatus' ).on( 'click', function() {

					$( 'input.customerStatus' ).checkboxradio( "refresh" );
					$( '#customerSummary' ).DataTable().ajax.reload();

				});
				
				$( 'input.customerReviewStatus' ).checkboxradio();
				$( 'input.customerReviewStatus' ).on( 'click', function() {
					
					debugger
					const selectedOption = $( this ).attr( 'id' );
					
					if ( selectedOption === 'customerReviewed' ) {
						customerSummary.column( '.periodicReviewComplete' ).search( 'true', false, false ).draw();
						$( '#clearFilters' ).show();						
					} else if ( selectedOption === 'customerUnreviewed' ) {
						customerSummary.column( '.periodicReviewComplete' ).search( 'false', false, false ).draw();
						$( '#clearFilters' ).show();		
					} else {
						customerSummary.column( '.periodicReviewComplete' ).search( '', false, false ).draw();
					}
					
					
				})


				let searchParams = new URLSearchParams(window.location.search);
				
				let order 	= searchParams.has( 'order' ) ? JSON.parse( searchParams.get( 'order' ) ) : [ 1, 'asc' ];
				let search 	= searchParams.has( 'search' ) ? searchParams.get( 'search' ) : '';
				
				$( '#clearFilters' ).click( function(e) {
					e.preventDefault;
					searchParams.delete( 'filter' );
					$( '#customerSummary' ).DataTable().search( '' ).columns().search( '' ).draw();
					// $( 'button.buttons-colvisGroup')[9].click();

					$( '#customerAll' ).prop( 'checked', true );
					$( 'input.customerReviewStatus' ).checkboxradio( 'refresh' );			

					$( '#clearFilters' ).hide();

				});				
				
				
				const dialog_customerPriority = $( '#dialog_customerPriority' ).dialog({
					autoOpen: false,
					resizable: false,
					height: 'auto',
					width: 350,
					modal: true,
					buttons: {
						Save: function() {
							
							const formData = {
								customerID: $( '#customerID' ).val(),
								customerGradeID: $( '#customerGradeID' ).slider( 'value' ),
								customerGradeNarrative: $( '#customerGradeNarrative' ).val(),
								anomoliesNarrative: $( '#anomoliesNarrative' ).val()
							}
							
							$.ajax({
								type: 'PUT',
								url: `${apiServer}/api/customerPriorities`,
								data: JSON.stringify( formData ),
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								contentType: 'application/json',
								success: function() {
									$( '#dialog_customerPriority' ).dialog( 'close' );
									var notification = document.querySelector('.mdl-js-snackbar');
									notification.MaterialSnackbar.showSnackbar({ message: 'Customer priority updated' });
									customerSummary.ajax.reload( null, false );
								},
								error: function() {
									$( '#dialog_customerPriority' ).dialog( 'close' );
									alert( 'error while saving customer priority priority!' );
								}
							})
						},				
						Cancel: function() {
							$( this ).dialog( 'close' );
						}
					}
				});
	

				var customerSummary = $( '#customerSummary' )
					.on( 'processing.dt', function() {
						
						if ( $( 'input.customerStatus' ).checkboxradio( 'option', 'disabled' ) ) {
							
							if ( $( 'input.customerStatus:checked' ).length > 1 ) {
								$( 'input.customerStatus' ).checkboxradio( 'option', 'disabled', false );
							} else {
								$( 'input.customerStatus:not(:checked)' ).checkboxradio( 'option', 'disabled', false );
								$( 'input.customerStatus:checked' ).checkboxradio( 'option', 'disabled', true );
							}

							$( '.datatableProcessingSpinner' ).removeClass( 'is-active' );
						} else {
							$( 'input.customerStatus' ).checkboxradio( 'option', 'disabled', true );
							$( '.datatableProcessingSpinner' ).addClass( 'is-active' );
						}
						
					})
					.on( 'order.dt', function( e, settings, ordArr ) {

						let tableOrder = [];
						for ( colSpec of ordArr ) {
							tableOrder.push([ colSpec.col, colSpec.dir ]);
						}

// 						searchParams = new URLSearchParams(window.location.search);
						searchParams.set( 'order', JSON.stringify( tableOrder ) );
						
					})
					.on( 'search.dt', function( e, settings ) {

						let search = $( this ).DataTable().search();
						searchParams.set( 'search', search );
						
					}) 
					.DataTable({
						dom: 'Bfrtip',
						buttons: [
							{
								extend: 'colvisGroup',
								text: 'Contracts',
								show: '.contract',
								hide: '.calls, .intent, .opp, .utopia, .ki, .project, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Calls',
								show: '.calls',
								hide: '.contract, .intent, .opp, .utopia, .ki, .project, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Intentions',
								show: '.intent',
								hide: '.contract, .calls, .opp, .utopia, .ki, .project, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Opportunities',
								show: '.opp',
								hide: '.contract, .calls, .intent, .utopia, .ki, .project, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Utopia',
								show: '.utopia',
								hide: '.contract, .calls, .intent, .opp, .ki, .project, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'KIs',
								show: '.ki',
								hide: '.contract, .calls, .intent, .opp, .utopia, .project, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Projects',
								show: '.project',
								hide: '.contract, .calls, .intent, .opp, .utopia, .ki, .task, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Tasks',
								show: '.task',
								hide: '.contract, .calls, .intent, .opp, .utopia, .ki, .project, .shop, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'Shops',
								show: '.shop',
								hide: '.contract, .calls, .intent, .opp, .utopia, .ki, .project, .task, .dummy'
							},
							{
								extend: 'colvisGroup',
								text: 'All',
								show: '.contract, .calls, .intent, .opp, .utopia, .ki, .project, .task, .shop, .dummy'
							}
						],
						ajax: { 
							url: `${apiServer}/api/customerMetrics/summary`,
							data: { statusList: function() {

								let stringStatusList = ''
								
								$( 'input.customerStatus' ).each( function() {
					
									if ( $( this ).is( ':checked' ) ) {
										elemID = $(this).attr('id');
										customerStatusID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
										if ( stringStatusList.length > 0 ) stringStatusList += ',';
										stringStatusList += customerStatusID;
									}
					
								});

								return stringStatusList;
	
							}},
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: '',
						},
						rowId: 'id',
						scrollX: true,
						scrollY: '450px',
						scrollCollapse: true,
						paging: false,
						columnDefs: [
							{ 
								targets: 'periodicReviewComplete', 
								data: 'periodicReviewComplete', 
								className: 'periodicReviewComplete dt-body-center',

								render: function(data, type, row) {

									if (type === 'display') {
										let isChecked = ( data === 'true' ) ? true : false;
										return '<input type="checkbox" ' + ( isChecked ? 'checked' : '') + '>';
									}

/*
									if ( type === 'filter' ) {
										
										console.log({ data });
										
										
									}
*/
									return data;
								}

								 
							},
							{ targets: 'statusName', data: 'statusName', className: 'statusName dt-body-center' },
							{ targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
							{ targets: 'primaryCoach', data: 'primaryCoach', className: 'primaryCoach dt-body-left' },
	
							{ 
								targets: 'customerGradeID', 
								data: 'customerGradeID', 
								className: 'customerGradeID dt-body-center',
								createdCell: function (td, cellData, rowData, row, col) {
									if ( rowData.customerGradeNarrative ) $( td ).prop( 'title', rowData.customerGradeNarrative );
								}
							},
	
							{ 
								targets: 'anomolies', 
								data: 'anomolies', 
								className: 'anomolies dt-body-center',
								createdCell: function (td, cellData, rowData, row, col) {
									if ( rowData.anomolies === 'true' ) {
										$( td ).html( '<span class="material-icons">flag</span>' );
										$( td ).prop( 'title', rowData.anomoliesNarrative );
									} else {
										$( td ).html( '' );
										$( td ).prop( 'title', '' );
									}
								}
							},
							{ 
								targets: 'optOutOfMCCCalls', 
								data: 'optOutOfMCCCalls', 
								className: 'optOutOfMCCCalls dt-body-center',
								createdCell: function (td, cellData, rowData, row, col) {
									if ( rowData.optOutOfMCCCalls === 'true' ) {
										$( td ).html( '<span class="material-icons">thumb_down_off_alt</span>' );
									} else {
										$( td ).html( '' );
									}
								}
							},
							{ 
								targets: 'hasOnboardingIssues', 
								data: 'hasOnboardingIssues', 
								className: 'hasOnboardingIssues dt-body-center',
								createdCell: function (td, cellData, rowData, row, col) {
									if ( rowData.hasOnboardingIssues === 'true' ) {
										$( td ).html( '<span class="material-icons">warning_amber</span>' );
									} else {
										$( td ).html( '' );
									}
								}
							},

							{ targets: 'overdueMetrics', data: 'overdueMetrics', className: 'overdueMetrics dt-body-center', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							
	
							{ targets: 'fcpContractCount', data: 'fcpContractCount', className: 'fcpContractCount dt-body-center contract', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'fcpContractExpiration', data: 'fcpContractExpiration', className: 'fcpContractExpiration dt-body-center contract', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'fcpNextRenewalType', data: 'fcpNextRenewalType', className: 'fcpNextRenewalType dt-body-center contract' },
							{ targets: 'fcpExpiring', data: 'fcpExpiring', className: 'fcpExpiring', visible: false },

							{ targets: 'msContractCount', data: 'msContractCount', className: 'msContractCount dt-body-center contract', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'msContractExpiration', data: 'msContractExpiration', className: 'msContractExpiration dt-body-center contract', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'msNextRenewalType', data: 'msNextRenewalType', className: 'msNextRenewalType dt-body-center contract' },
							{ targets: 'msExpiring', data: 'msExpiring', className: 'msExpiring', visible: false },

							{ targets: 'csContractCount', data: 'csContractCount', className: 'csContractCount dt-body-center contract', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'csContractExpiration', data: 'csContractExpiration', className: 'csContractExpiration dt-body-center contract', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'csNextRenewalType', data: 'csNextRenewalType', className: 'csNextRenewalType dt-body-center contract' },
							{ targets: 'csExpiring', data: 'csExpiring', className: 'csExpiring', visible: false },

							
							{ targets: 'callCountYear', data: 'callCountYear', className: 'callCountYear sum avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'daysSinceLastCall', data: 'daysSinceLastCall', className: 'daysSinceLastCall avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'missedCalls', data: 'missedCalls', className: 'missedCalls sum avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'callNoAgenda', data: 'callNoAgenda', className: 'callNoAgenda sum avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'callNoRecap', data: 'callNoRecap', className: 'callNoRecap sum avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'mccDaysLate', data: 'mccDaysLate', className: 'mccDaysLate sum avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'sacDaysLate', data: 'sacDaysLate', className: 'sacDaysLate sum avg dt-body-center calls', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
	
							{ targets: 'activeIntentionsCount', data: 'activeIntentionsCount', className: 'activeIntentionsCount sum avg dt-body-center intent', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'overlappingIntentions', data: 'overlappingIntentions', className: 'overlappingIntentions sum avg dt-body-center intent', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
	
							{ targets: 'oppCount', data: 'oppCount', className: 'oppCount sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'totalOppValue', data: 'totalOppValue', className: 'totalOppValue sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '$' ) },
							{ targets: 'oppNoValue', data: 'oppNoValue', className: 'oppNoValue sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'oppsWithoutGoal', data: 'oppsWithoutGoal', className: 'oppsWithoutGoal sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'oppNoObj', data: 'oppNoObj', className: 'oppNoObj sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'oppBelowObj', data: 'oppBelowObj', className: 'oppBelowObj sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'totOppObj', data: 'totOppObj', className: 'totOppObj sum avg dt-body-center opp', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
	
							{ targets: 'utopiaCount', data: 'utopiaCount', className: 'utopiaCount sum avg dt-body-center utopia', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'utopiaWithoutGoal', data: 'utopiaWithoutGoal', className: 'utopiaWithoutGoal sum avg dt-body-center utopia', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'utopiaBelowObj', data: 'utopiaBelowObj', className: 'utopiaBelowObj sum avg dt-body-center utopia', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'totUtopiaObj', data: 'totUtopiaObj', className: 'totUtopiaObj sum avg dt-body-center utopia', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							
							{ targets: 'openKICount', data: 'openKICount', className: 'openKICount sum avg dt-body-center ki', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'pastDueKICount', data: 'pastDueKICount', className: 'pastDueKICount sum avg dt-body-center ki', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'nahproKICount', data: 'nahproKICount', className: 'nahproKICount sum avg dt-body-center ki', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
	
							{ targets: 'openProjectCount', data: 'openProjectCount', className: 'openProjectCount sum avg dt-body-center project', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'atRiskProjectCount', data: 'atRiskProjectCount', className: 'atRiskProjectCount sum avg dt-body-center project', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'pastDueProjectCount', data: 'pastDueProjectCount', className: 'pastDueProjectCount sum avg dt-body-center project', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'nahproProjectCount', data: 'nahproProjectCount', className: 'nahproProjectCount sum avg dt-body-center project', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
	
							{ targets: 'daysBehind', data: 'daysBehind', className: 'daysBehind dt-body-center task', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'daysAtRisk', data: 'daysAtRisk', className: 'daysAtRisk dt-body-center task', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'openTaskCount', data: 'openTaskCount', className: 'openTaskCount sum avg dt-body-center task', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'pastDueTaskCount', data: 'pastDueTaskCount', className: 'pastDueTaskCount sum avg dt-body-center task', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'orphanTaskCount', data: 'orphanTaskCount', className: 'orphanTaskCount sum avg dt-body-center task', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },

							{ 
								targets: 'customerNoMsBank', 
								data: 'customerNoMsBank', 
								className: 'customerNoMsBank dt-body-center shop',
								createdCell: function (td, cellData, rowData, row, col) {
									if ( rowData.customerNoMsBank === 'true' ) {
										$( td ).html( '<span class="material-icons" title="There is no Mystery Shopping data for this customer">rule</span>' );
									} else {
										$( td ).html( '' );
									}
								},
								defaultContent: '',
							},
							{ targets: 'daysSinceLastShop', data: 'daysSinceLastShop', className: 'daysSinceLastShop sum avg dt-body-center shop', render: $.fn.dataTable.render.number( ',', '.', 0, '' ) },
							{ targets: 'averageScore', data: 'averageScore', className: 'averageScore sum avg dt-body-center shop' },
							{ 
								targets: 'noShops', 
								data: 'noShops', 
								className: 'noShops dt-body-center shop',
								createdCell: function (td, cellData, rowData, row, col) {
								
									if ( rowData.noShops ) {
										$( td ).html( '<span class="material-icons">remove_shopping_cart</span>' );
									} else {
										$( td ).html( '' );
									}
								}
							},
							

							{ targets: 'dummy', defaultContent: '', className: 'dummy', sortable: false }
						],
						search: { "search": search },
						order: order
						
					});
				
				$( 'button.dt-button' ).on( 'click', function() {
					$( 'button.dt-button' ).css( 'background-color', '' );
					$( 'button.dt-button' ).css( 'color', 'black' );
					$( this ).css( 'background-color', 'rgb(0, 127, 255)' );
					$( this ).css( 'color', 'white' );
				});


				<% if userPermitted( 132 ) then %>
					$( '#customerSummary' ).on( 'click', 'td.contract', function() {
						history.replaceState( null, '', window.location.pathname + '?' + searchParams );
						location = 'customerContracts.asp?id='+customerSummary.row( this ).data().id;
					});
				<% end if %>
				
				
				$( '#customerSummary' ).on( 'click', 'td.overdueMetrics', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerImplementations.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.primaryCoach', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerManagers.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.callCountYear, td.daysSinceLastCall, td.missedCalls', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerCalls.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.activeIntentionsCount, td.overlappingIntentions, td.oppCount, td.totalOppValue, td.oppNoValue, td.oppsWithoutGoal, td.oppNoObj, td.utopiaCount, td.utopiaWithoutGoal, td.oppBelowObj, td.utopiaBelowObj, td.totOppObj, td.totUtopiaObj', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerImplementations.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.openKICount, td.pastDueKICount, td.nahproKICount', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerKeyInitiatives.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.openProjectCount, td.atRiskProjectCount, td.pastDueProjectCount, td.nahproProjectCount', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerProjects.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.daysBehind, td.daysAtRisk, td.openTaskCount, td.pastDueTaskCount, td.orphanTaskCount', function() {
					history.replaceState( null, '', window.location.pathname + '?' + searchParams );
					location = 'customerTasks.asp?id='+customerSummary.row( this ).data().id;
				});
				
				$( '#customerSummary' ).on( 'click', 'td.customerName', function() {
					
					$( '#customerCallTimelineTitle' ).text( customerSummary.row( this ).data().customerName + ': Calls Completed Today + Past 12 Months or Scheduled Today + Next 6 Months' )
					
					$.ajax({
						url: `${apiServer}/api/customerMetrics/callTimeLine2`,
						data: { 
							customerID: customerSummary.row( this ).data().id
						},
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					}).done( function( response ) {

						if ( response.data.rows.length > 0 ) {
							$( '#customerCallTimeLine2' ).show();
							let chart = new google.visualization.Timeline( document.getElementById( 'customerCallTimeLine2' ) );
							let dataTable = new google.visualization.DataTable( response.data );
							chart.draw( dataTable, response.options );
						} else {
							$( '#customerCallTimeLine2' ).hide();
						}

					}).fail( function() {
						console.error( 'Something when wrong while retrieving timeline data' );
					});
					
				});
				
				
				$( '#customerSummary' ).on( 'click', 'td.periodicReviewComplete', function() {

					debugger
					let customerID = customerSummary.row( this ).data().id;
					let row = customerSummary.row( $(this).closest( 'tr' ));
					let rowData = row.data();

					// this seems backward, the intent is toggle the value in the underlying DataTable
					const newPeriodReviewComplete = ( rowData.periodicReviewComplete === 'true' ) ? 'false' : 'true';
					
					customerSummary.cell( row, 0 ).data( newPeriodReviewComplete );

					
					$.ajax({
						url: `${apiServer}/api/customers/togglePeriodicReview/${customerID}`,
						type: `PUT`,
						data: { customerID: customerID },
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					}).done( function( response ) {
						
						showTransientMessage( 'periodic review toggled' );
												
					}).fail( function( err ) {
						console.error( 'something went wrong toggling customer periodic review indicator' );
						console.error( err );
					});
					
					
				});
				
				
				$( '#resetReviews' ).click( function() {
					
					$.ajax({
						url: `${apiServer}/api/customers/resetAllPeriodicReviewIndicators`,
						type: `PUT`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					}).done( async function( response ) {
						
						await customerSummary.ajax.reload();
						
						await showTransientMessage( 'All reviews reset' );
												
					}).fail( function( err ) {
						console.error( 'something went wrong toggling customer periodic review indicator' );
						console.error( err );
					});
					

				});
				



				
				var handle = $( '#custom-handle' );
				$( '#customerGradeID' ).slider({
					value: 0,
					min: 0,
					max: 10,
					step: 1,
					create: function() {
						handle.text( $( this ).slider( 'value' ) );
					},
					slide: function( event, ui ) {
						handle.text( ui.value );
			      }
				});
	
				$( '#customerSummary' ).on( 'click', 'td.customerGradeID, td.anomolies', function() {
					
					// populate the slider and its custom handle...
					const customerID = $( this ).closest( 'tr' ).attr( 'id' );
					$( '#customerID' ).val( customerID );

					const handle = $( '#custom-handle' );
					const row = $( '#customerSummary').DataTable().row( $(this).closest('tr') );
					const customerGradeID = row.data().customerGradeID;
// 					const customerGradeID = $( 'td.customerGradeID' ).text();

					const valueToShow = customerGradeID ? customerGradeID : 0;
					handle.text( valueToShow );
					$( '#customerGradeID' ).slider( 'value', valueToShow );

					// populate the narrative <textarea>
					const customerGradeNarrative = row.data().customerGradeNarrative;
					const anomoliesNarrative = row.data().anomoliesNarrative;
					$( '#customerGradeNarrative' ).val( customerGradeNarrative );
					$( '#anomoliesNarrative' ).val( anomoliesNarrative );

					$( '#dialog_customerPriority' ).dialog( 'open' );

				});
			
				let filter = searchParams.get( 'filter' );

				switch ( filter ) {
					
					case 'optOutOfMCCCalls': // opted out of MCCs
						customerSummary.column( '.optOutOfMCCCalls' ).search( 'true', false, false ).draw();
						$( '#clearFilters' ).show();
						break;

					case 'hasOnboardingIssues': // onboarding issues
						customerSummary.column( '.hasOnboardingIssues' ).search( 'true', false, false ).draw();
						$( '#clearFilters' ).show();
						break;

					case 'callCountYear': // no completed calls
						customerSummary.column( '.callCountYear' ).search( '^0$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[1].click();
						$( '#clearFilters' ).show();
						break;

					case 'mccDaysLate': // MCC overdue ( exclude 'opted out of MCCs' )
						customerSummary
							.column( '.optOutOfMCCCalls' ).search( 'false', false, false )
							.column( '.mccDaysLate' ).search( '^[1-9]|[0-9]{9,}$', true, false )
							.draw();
						$( 'button.buttons-colvisGroup')[1].click();
						$( '#clearFilters' ).show();
						break;

					case 'sacDaysLate': // SAC overdue
						customerSummary.column( '.sacDaysLate' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[1].click();
						$( '#clearFilters' ).show();
						break;

					case 'activeIntentionsCount': // no intentions
						customerSummary.column( '.activeIntentionsCount' ).search( '^0$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[2].click();
						$( '#clearFilters' ).show();

						break;
					case 'overlappingIntentions': // overlapping intentions
						customerSummary.column( '.overlappingIntentions' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[2].click();
						$( '#clearFilters' ).show();
						break;

					case 'oppBelowObj': // overlapping intentions
						customerSummary.column( '.oppBelowObj' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[3].click();
						$( '#clearFilters' ).show();
						break;

					case 'utopiaBelowObj': // overlapping intentions
						customerSummary.column( '.utopiaBelowObj' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[4].click();
						$( '#clearFilters' ).show();
						break;
						
					case 'noOpportunities': // no active opportunities
						customerSummary.column( '.oppCount' ).search( '^0$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[3].click();
						$( '#clearFilters' ).show();
						break;
						
					case 'noKIs': // no active opportunities
						customerSummary.column( '.openKICount' ).search( '^0$', true, false ).draw();
						$( 'button.buttons-colvisGroup')[5].click();
						$( '#clearFilters' ).show();
						break;
						
					case 'overdueMetrics': // no active opportunities
						customerSummary.column( '.overdueMetrics' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'fcpContractsExpiring': // FCP (Full Culture Program) Contracts Expiring
debugger
						$( 'button.buttons-colvisGroup')[0].click();
						customerSummary.column( '.fcpExpiring' ).search( true );
						customerSummary.order( [ customerSummary.column('.fcpContractExpiration').index(), 'asc' ] );
						customerSummary.draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'msContractsExpiring': // MS (Mystery Shopping) Contracts Expiring
						$( 'button.buttons-colvisGroup')[0].click();
						customerSummary.column( '.msExpiring' ).search( true ).draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'csContractsExpiring': // CS (Culture Survey) Contracts Expiring
						$( 'button.buttons-colvisGroup')[0].click();
						customerSummary.column( '.csExpiring' ).search( true ).draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'noShops': // Mystery Shopping -- customers that have not been shopped in the last 12 months
						$( 'button.buttons-colvisGroup')[8].click();
						customerSummary.column( '.noShops' ).search( 'true', false, false ).draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'customerNoMsBank': // Mystery Shopping -- customers that have not been associated with a Mystery Shopping bank
						$( 'button.buttons-colvisGroup')[8].click();
						customerSummary.column( '.customerNoMsBank' ).search( 'true', false, false ).draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'overdueMetrics': // no active opportunities
						$( 'button.buttons-colvisGroup')[8].click();
						customerSummary.column( '.overdueMetrics' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( '#clearFilters' ).show();
						break;
						
					case 'missedCalls': // no active opportunities
						$( 'button.buttons-colvisGroup')[1].click();
						customerSummary.column( '.missedCalls' ).search( '^[1-9]|[0-9]{9,}$', true, false ).draw();
						$( '#clearFilters' ).show();
						break;
						
					default:
				}
						 
			});
			
		});
		
	</script>


	<style>
		
		.ui-checkboxradio-label {
			width: 200px;
			text-align: left;
		}
		
		.dataTable thead .groupHeader {
			padding-left: 2.2rem !important;
			padding-right: 0.75rem !important;
		}

		#customerSummary {
			margin: 0 auto;
			float: left;
		}

		label.dialogLabel {
			font-weight: bold;
		}

		#custom-handle {
			width: 3em;
			height: 1.6em;
			top: 50%;
			margin-top: -.8em;
			text-align: center;
		}		
		
		textarea.customerGradeNarrative {
			width: 98%;
		}
		
		label.dialogLabel {
			font-weight: bold;
		}

		#custom-handle {
			width: 3em;
			height: 1.6em;
			top: 50%;
			margin-top: -.8em;
			text-align: center;
		}		
		
		#customerGradeID {
			width: 80%;
			text-align: center; 
			position: relative; 
			margin: 0 auto;
		}
		
		#customerGradeNarrative, #anomoliesNarrative {
			width: 98%;
		}
		
		th.selectionHeader {
			text-align: left;
			padding-left: 30px;
		}
		
		
		#filterControls {
			position: absolute;
			width: 100%;
			bottom: 0;
		}

		#clearFilters {
			display: none;
			margin-left: 3px;
			margin-bottom: 3px;
			width: 93%;
  		}

		#resetReviews {
			margin-left: 3px;
			margin-bottom: 3px;
			width: 93%;
  		}

		
		
	</style>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">

	<!-- MDL Snackbar -->
	<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
	</div>


	<!-- Customer Priority Dialog -->
	<div id="dialog_customerPriority" title="Customer Alert / Anomolies" style="position: relative; display: none;">

		<br>

		<label for="customerGradeID" class="dialogLabel">Alert Level</label>
		<div id="customerGradeID">
			<div id="custom-handle" class="ui-slider-handle"></div>
		</div>

		<br>

		<label for="customerGradeNarrative" class="dialogLabel">Alert Comments</label>
		<textarea id="customerGradeNarrative" class="text ui-widget-content ui-corner-all" rows="5"></textarea>
		
		<br>

		<label for="anomoliesNarrative" class="dialogLabel">Anomolies</label>
		<textarea id="anomoliesNarrative" class="text ui-widget-content ui-corner-all" rows="5"></textarea>
		

		<!-- Allow form submission with keyboard without duplicating the dialog button -->
		<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
		
		<input type="hidden" id="customerID">
		
	</div>


	
	<div class="mdl-grid"><!-- start of primary mdl-grid
		<!-- new row of grids... -->
	
		<div class="mdl-layout-spacer"></div>
		<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp" style="position: relative;">

			<div style="position: relative;">
			<div class="mdl-spinner mdl-js-spinner is-active datatableProcessingSpinner" style="position: absolute; top: 50%; left: 50%; z-index: 9999;"></div>

				<table id="customerStatusList">
					<thead>
						<th class="selectionHeader">Customer Statuses</th>
					</thead>
					<tbody>
					<%
					SQL = "select " &_
								"s.id, " &_
								"s.name, " &_
								"s.selectByDefault, " &_
								"count(*) as custCount " &_
							"from customerStatus s " &_
							"join customer c on (c.customerStatusID = s.id) " &_
							"where (c.deleted = 0 or c.deleted is null) " &_
							"group by s.id, s.name, s.selectByDefault " &_
							"order by s.name  "
					dbug(SQL)
					set rsCS = dataconn.execute(SQL) 
					while not rsCS.eof
						label = rsCS("name") & " (" & rsCS("custCount") & ")"
	
						if uBound(arrStatusList) >= 0 then 
	
							if ( valuePresent( rsCS("id"), arrStatusList ) ) then 
								checked = "checked"
							else 
								checked = ""
							end if 
	
						else 
							
							if rsCS("selectByDefault") then 
								checked = "checked"
							else 
								checked = ""
							end if 
	
						end if
	
						%>
						<tr>
							<td>
								<label for="cs-<% =rsCS("id") %>"><% =label %></label>
								<input class="customerStatus" type="checkbox" id="cs-<% =rsCS("id") %>" <% =checked %>>
							</td>
						</tr>
						<%
						rsCS.movenext 
					wend 
					rsCS.close 
					set rsCS = nothing 
					%>
					</tbody>
				</table>

				<br><br>

				<table id="customerReviewStatus" style="margin-bottom: 60px;">
					<thead>
						<th class="selectionHeader">Customer Reviewed</th>
					</thead>
					<tbody>
						<tr>
							<td>
								<label for="customerReviewed">Reviewed</label>
								<input class="customerReviewStatus" type="radio" id="customerReviewed" name="customerReviewStatus">
							</td>
						</tr>
						<tr>
							<td>
								<label for="customerUnreviewed">Unreviewed</label>
								<input class="customerReviewStatus" type="radio" id="customerUnreviewed" name="customerReviewStatus">
							</td>
						</tr>
						<tr>
							<td>
								<label for="customerAll">All</label>
								<input class="customerReviewStatus" type="radio" id="customerAll" name="customerReviewStatus" checked>
							</td>
						</tr>
					</tbody>
				</table>
				
			</div>
			
			<br>
			
			<div id="filterControls">
				<button id="clearFilters" class="ui-button ui-widget ui-corner-all">Clear Filters</button>
				<button id="resetReviews" class="ui-button ui-widget ui-corner-all">Reset Review Indicators</button>
			</div>
			
		</div>
		
		<div class="mdl-cell mdl-cell--10-col mdl-shadow--2dp">

			<div style="position: relative;">
				<div class="mdl-spinner mdl-js-spinner is-active datatableProcessingSpinner" style="position: absolute; top: 50%; left: 50%; z-index: 9999;"></div>
				<table id="customerSummary" class="compact display nowrap">
					<thead>
						<tr>
							<th rowspan="2" class="periodicReviewComplete" title="Periodic review complete?"><span class="material-symbols-outlined">reviews</span></th>
							<th rowspan="2" class="customerName" title="Customer name">Customer</th>
							<th rowspan="2" class="customerGradeID" title="Customer alert level">Alert<br>Level</th>
							<th rowspan="2" class="anomolies" title="Customer Anomolies">Anomolies</th>
							<th rowspan="2" class="statusName" title="Customer status">Status</th>
							<th rowspan="2" class="optOutOfMCCCalls" title="Customer elected to opt out of Monthy Coaching Calls (MCC)">MCC<br>Opt Out</th>
							<th rowspan="2" class="hasOnboardingIssues" title="Customer has onboarding issues">Onboarding<br>Issues</th>
							<th rowspan="2" class="overdueMetrics" title="Customer has metrics with overdue values">Overdue<br>Metrics</th>
							<th rowspan="2" class="primaryCoach" title="Currently assigned primary coach">Primary Coach</th>
							<th colspan="4">Full Culture Program Contracts</th>
							<th rowspan="2" class="dummy contract"></th>
							<th colspan="4">Mystery Shopping Contracts</th>
							<th rowspan="2" class="dummy contract"></th>
							<th colspan="4">Culture Survey Contracts</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="7">Calls</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="2">Intentions</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="7">Opportunities</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="4">Utopia</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="3">KIs</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="4">Projects</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="5">Tasks</th>
							<th rowspan="2" class="dummy"></th>
							<th colspan="4">Mystery Shopping</th>
						</tr>	
						<tr>
	
							<!-- FCP (Full Culture Program) Contracts -->
							<th class="fcpContractCount" title="Count of active FCP (Full Culture Program) contracts associated with this customer">Count</th>
							<th class="fcpContractExpiration" title="Days until the next active FCP (Full Culture Program) contract expiration date for this customer">Days Till<br>Next Exp.</th>
							<th class="fcpNextRenewalType" title="Renewal type for the next active FCP (Full Culture Program) contract to expire for this customer">Next Renewal<br>Type</th>
							<th class="fcpExpiring">fcpExpiring</th>
	
							<!-- MS (Mystery Shopping) Contracts -->
							<th class="msContractCount" title="Count of active MS (Mystery Shopping) contracts associated with this customer">Count</th>
							<th class="msContractExpiration" title="Days until the next active MS (Mystery Shopping) contract expiration date for this customer">Days Till<br>Next Exp.</th>
							<th class="msNextRenewalType" title="Renewal type for the next active MS (Mystery Shopping) contract to expire for this customer">Next Renewal<br>Type</th>
							<th class="msExpiring">msExpiring</th>
	
							<!-- CS (Culture Survey) Contracts -->
							<th class="csContractCount" title="Count of active CS (Culture Survey) contracts associated with this customer">Count</th>
							<th class="csContractExpiration" title="Days until the next active CS (Culture Survey) contract expiration date for this customer">Days Till<br>Next Exp.</th>
							<th class="csNextRenewalType" title="Renewal type for the next active CS (Culture Survey)contract to expire for this customer">Next Renewal<br>Type</th>
							<th class="csExpiring">csExpiring</th>
	
	
							<!-- Calls -->
							<th class="callCountYear" title="Count of all calls scheduled and completed within the last 12 months">Completed<br>(last 12 mo.)</th>
							<th class="daysSinceLastCall" title="Days since last call of any type">Most Recent<br>(days)</th>
							<th class="missedCalls" title="Count of calls scheduled in the past but never completed">Missed</th>
							<th class="callNoAgenda" title="Count of calls for which an agenda email was never generated">No Agenda</th>
							<th class="callNoRecap" title="Count of completed calls for which a recap email was never generated ">No Recap</th>
							<th class="mccDaysLate" title="Days the customer's MCC call is overdue ">MCC Overdue<br>(days)</th>
							<th class="sacDaysLate" title="Days the customer's MCC call is overdue ">SAC Overdue<br>(days)</th>
	
							<!-- Intentions -->
							<th class="activeIntentionsCount" title="Count of active intentions (based on start date and end date)">Active</th>
							<th class="overlappingIntentions" title="Count of overlapping active intentions (based on start date and end date)">Overlapping</th>
	
							<!-- Opportunities -->
							<th class="oppCount" title="Count of opportunities within active intentions">Active</th>
							<th class="totalOppValue" title="Sum of economic value for opportunities within active intentions"> Total<br>$Value</th>
							<th class="oppNoValue" title="Count of opportunities within active intentions where economic value has not be established">No<br>$Value</th>
							<th class="oppsWithoutGoal" title="Count of objectives within opportunities for which no goal (ie, start date, start value, end date, end value) has been defined">Incomplete<br>Obj Def</th>
							<th class="oppNoObj" title="Count of opportunities within active intentions for which no objective has been defined">No Obj</th>
							<th class="oppBelowObj" title="Count of opportunity FDIC metrics with values below objective">Below Obj</th>
							<th class="totOppObj" title="Count of active objectives defined in opportunities">Total<br> # Obj</th>
							
	
							<!-- Utopia -->
							<th class="utopiaCount" title="Count of Utopia metrics within active intentions">Active</th>
							<th class="utopiaWithoutGoal" title="Count of objectives within Utopia for which no goal (ie, start date, start value, end date, end value) has been defined">Incomplete<br>Obj Def</th>
							<th class="utopiaBelowObj" title="Count of utopia FDIC metrics with values below objective">Below Obj</th>
							<th class="totUtopiaObj" title="Count of active objectives defined as part of utopia">Total<br> # Obj</th>
	
							<!-- KIs -->
							<th class="openKICount" title="Count KIs that are not complete">Open</th>
							<th class="pastDueKICount" title="Count of open KIs where the end date has transpired">Past Due</th>
							<th class="nahproKICount" title="Count of open KIs with no project(s) and no task(s)"><i>Nahpro</i></th>
	
							<!-- Projects -->
							<th class="openProjectCount" title="Count of projects that have a status other than 'Complete'">Open</th>
							<th class="atRiskProjectCount" title="Count of projects that have a status of 'Escalate' or 'Reschedule'">At Risk</th>
							<th class="pastDueProjectCount" title="Count of projects that are not complete and the end date has transpired">Past Due</th>
							<th class="nahproProjectCount" title="Count of open projects with no task(s)"><i>Nahpro</i></th>
	
							<!-- Tasks -->
							<th class="daysBehind" title="Total work days behind for tasks">Days<br>Behind</th>
							<th class="daysAtRisk" title="Total work days at risk for tasks">Days<br>At Risk</th>
							<th class="openTaskCount" title="Count of tasks that are not complete">Open</th>
							<th class="pastDueTaskCount" title="Count of tasks that are not complete and the due date has transpired">Past Due</th>
							<th class="orphanTaskCount" title="Count of tasks that are not complete and not associated with a KI or project">Orphan</th>
	
							<!-- Shops -->
							<th class="customerNoMsBank" title="Customer does not have a Mystery Shopping bank name assigned">No MS Bank</th>
							<th class="daysSinceLastShop" title="Count of days since this customer was Mystery Shopped">Last<br>Shop (days)</th>
							<th class="averageScore" title="Average score of all shops over the last 12 months (excludes 'N/A's">Avg Score<br>(12 mos)</th>
							<th class="noShops" title="Customer has not been shopped in the last 12 months">No Shops<br>(12 mos)</th>
	
						</tr>
					</thead>
				</table>
			</div>
				
		</div>
		<div class="mdl-layout-spacer"></div>
		
	</div>


	<!-- new row of grids... -->
	<div class="mdl-grid">
	
		<div class="mdl-layout-spacer"></div>
		<div class="mdl-cell mdl-cell--11-col mdl-shadow--2dp">
			<div id="customerCallTimelineTitle" style="font-weight: bold;"></div>
			<div id="customerCallTimeLine2" style="display: none;"></div>

		</div>
		<div class="mdl-layout-spacer"></div>

	</div>
	
</main>
<!-- #include file="includes/pageFooter.asp" -->



</body>

</html>