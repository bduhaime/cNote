<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2020, Polaris Consulting, LLC. All Rights Reserved. -->
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
call checkPageAccess(36)

title = session("clientID") & " - Executive Dashboard" 
userLog(title)

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	Dayjs -->
	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>

	<!-- 	Google Visualizations -->
	<script src="https://www.gstatic.com/charts/loader.js"></script>


	<script>

		google.charts.load( 'current', { packages: [ 'corechart', 'gauge', 'line' ] } );
		google.charts.setOnLoadCallback( drawCharts);

 		var chartHeight = 245;

		//====================================================================================
 		function customerStatusList() {
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
 		function getSkippedTasks() {
		//====================================================================================
	 		
			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/skippedTasks`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				if ( response.length > 0 ) {
					$( '.mdl-badge.skipped' ).attr( 'data-badge', response.length ).show();
				} else {
					$( '.mdl-badge.skipped' ).attr( 'data-badge', '' ).hide();
				}

			}).fail( function( req, status, err ) {
				console.error( `Something went wrong (${status}) in getSkippedTasks(), please contact your system administrator.` );
				throw new Error( err );
			});
			
 		}
		//====================================================================================



		//====================================================================================
 		function buildKPI_overdueMCC() {
		//====================================================================================
	 		
			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/kpiOverdueCallsByType`,
				data: { 
					callTypeID: 1,
					statusList: customerStatusList()
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				$( '.kpiOverdueMCC' ).css( 'background-color', 'green' );
				$( '.kpiOverdueMCC' ).css( 'color', '#ffffff' );
				$( '.kpiOverdueMCC .kpiValue' ).html( response.overdueCalls );
				$( '.kpiOverdueMCC' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=mccDaysLate&statusList=${statusList}`;
				});
			}).fail( function( req, status, err ) {
				console.error( `Something went wrong (${status}) in buildKPI_overdueMCC(), please contact your system administrator.` );
				throw new Error( err );
			});
			
 		}
		//====================================================================================



		//====================================================================================
 		function buildKPI_overdueSAC() {
		//====================================================================================
	 		
			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/kpiOverdueCallsByType`,
				data: { 
					callTypeID: 2,
					statusList: customerStatusList()
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				$( '.kpiOverdueSAC' ).css( 'background-color', '#673ab7' );
				$( '.kpiOverdueSAC' ).css( 'color', '#ffffff' );
				$( '.kpiOverdueSAC .kpiValue' ).html( response.overdueCalls );
				$( '.kpiOverdueSAC' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=sacDaysLate&statusList=${statusList}`;
				});
			}).fail( function( req, status, err ) {
				console.error( `Something went wrong (${status}) in buildKPI_overdueMCC(), please contact your system administrator.` );
				throw new Error( err );
			});
			
 		}
		//====================================================================================



		//====================================================================================
		function buildChart_averageMCC() {
		//====================================================================================

			$.ajax({
				beforeSend: function() {
					$( '#averageMCC_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/exec/avgDaysSinceCallType`,
				data: { 
					callTypeID: 1,
					statusList: customerStatusList()
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				var chart = new google.visualization.LineChart(document.getElementById( 'averageMCC' ));
				var data = new google.visualization.DataTable( response.data );
				chart.draw( data, {
					colors: [ '#673ab7' ],
					chartArea: {
						left: 55,
						top: 50,
						width: '85%',
						height: '70%'
					},
					explorer: {
						axis: 'horizontal',
						keenInBounds: false,
						maxZoomIn: 7,
						zoomDelta: 1.1,
					},
		 			hAxis: {
			 			minValue: new Date(dayjs().subtract(1,'years').year(), dayjs().subtract(1,'years').month(), 1),
			 			format: 'MMM yy',
		 			},
		         height: chartHeight,
			      legend: {
				      position: 'top',
			      },
			      series: {
				      0: { color: 'crimson', lineWidth: 4 },
				      1: { color: 'green', lineWidth: 4 },
			      },
		         vAxis: {
			         title: 'Days',
		         },
					title: 	'Average Days Since Last MCC',
				});
				$( '#averageMCC_progressbar' ).progressbar('destroy');
				
			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in buildChart_averageMCC(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================

		
		//====================================================================================
		function buildChart_averageSAC() {
		//====================================================================================

			$.ajax({
				beforeSend: function() {
					$( '#averageSAC_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/exec/avgDaysSinceCallType`,
				data: { 
					callTypeID: 2,
					statusList: customerStatusList()
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				var chart = new google.visualization.LineChart(document.getElementById( 'averageSAC' ));
				var data = new google.visualization.DataTable( response.data );
				chart.draw( data, {
					colors: [ '#673ab7' ],
					chartArea: {
						left: 55,
						top: 50,
						width: '85%',
						height: '70%'
					},
		 			hAxis: {
			 			minValue: new Date(dayjs().subtract(1,'years').year(), dayjs().subtract(1,'years').month(), 1),
			 			format: 'MMM yy',
		 			},
		         height: chartHeight,
			      legend: {
				      position: 'top',
			      },
			      series: {
				      0: { color: 'crimson', lineWidth: 4 },
				      1: { color: '#673ab7', lineWidth: 4, curveType: 'function' },
			      },
		         vAxis: {
			         title: 'Days',
		         },
					title: 	'Average Days Since Last SAC',
				});
				$( '#averageSAC_progressbar' ).progressbar('destroy');
				
			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in buildChart_averageSAC(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================

		
		//====================================================================================
		function buildChart_managerGauges() {
		//====================================================================================

			$.ajax({
				beforeSend: function() {
					$( '#managerTypeGauges_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/exec/mgrGauges`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				$( '#managerTypeGauges' ).html( '' );
				
				for ( const row of response.data ) {
					
					let chartData = new google.visualization.DataTable();
					chartData.addColumn( 'string', 'Label' );
					chartData.addColumn( 'number', 'Value' );
					chartData.addRow([ row.cmtName, parseInt( row.cmtCount ) ]);
					
					let chartOptions = {
			         height: chartHeight-75,
			         yellowFrom: response.metaData.yellowFrom, yellowTo: response.metaData.yellowTo,
			         redFrom: response.metaData.redFrom, redTo: response.metaData.redTo,
			         max: response.metaData.customerCount
					}
					

					let container = document.createElement( 'span' );
					$( container ).addClass( 'cmtGauge' );
					$( container ).attr( 'data-cmtID', row.cmtID );
					$( '#managerTypeGauges' ).append( container );
					
					let gaugeChart = new google.visualization.Gauge( container );
					gaugeChart.draw( chartData, chartOptions );
					
				}
				
				$( '.cmtGauge' ).on( 'click', function() {

					const cmtID = $(this).attr( 'data-cmtID');
					const statusList = customerStatusList();
					window.location.href = `/customersWithoutManagers.asp?cmtID=${cmtID}&statusList=${statusList}`;	

				});



				$( '#managerTypeGauges_progressbar' ).progressbar('destroy');
				
			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in buildChart_managerGauges(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================

		
		//====================================================================================
		function getAlerts() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/alerts`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				if ( response.escalations > 0 ) {
					$( '.mdl-badge.escalate' ).attr( 'data-badge', response.escalations ).show();
				} else {
					$( '.mdl-badge.escalate' ).attr( 'data-badge', '' ).hide();
				}
				
				if ( response.reschedules > 0 ) {
					$( '.mdl-badge.reschedule' ).attr( 'data-badge', response.reschedules ).show();
				} else {
					$( '.mdl-badge.reschedule' ).attr( 'data-badge', '' ).hide();
				}
				

				$( '.internalExternalUsers .kpiValue' ).html( response.internalExternalUsers );
				$( '.internalExternalUsers' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `userExternalUserList.asp?statusList=${statusList}`;
				});

								
				$( '.internalCustomerContacts .kpiValue' ).html( response.internalCustomerContacts );
				$( '.internalCustomerContacts' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `userCustomerContactList.asp?statusList=${statusList}`;
				});

								
				$( '.missedCalls .kpiValue' ).html( response.missedCalls.customerCount );
				$( '.missedCalls .kpiFooter' ).html( `Total missed calls: ${response.missedCalls.callCount}` );
				$( '.missedCalls' ).on( 'click', function() {
// 					const statusList = customerStatusList();
// 					window.location.href = `lsvtManualLocationCustomerMapping.asp`;
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=missedCalls&statusList=${statusList}`;
				});

				
				$( '.customersNoCompletedCalls .kpiValue' ).html( response.customersNoCompletedCalls );
				$( '.customersNoCompletedCalls' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=callCountYear&statusList=${statusList}`;
				});


				$( '.fcpContractsExpiring .kpiValue' ).html( response.fcpContractsExpiring );
				$( '.fcpContractsExpiring' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=fcpContractsExpiring&statusList=${statusList}`;
				});


				$( '.msContractsExpiring .kpiValue' ).html( response.msContractsExpiring );
				$( '.msContractsExpiring' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=msContractsExpiring&statusList=${statusList}`;
				});


				$( '.csContractsExpiring .kpiValue' ).html( response.csContractsExpiring );
				$( '.csContractsExpiring' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=csContractsExpiring&statusList=${statusList}`;
				});

				$( '.noActiveIntentions .kpiValue' ).html( response.noActiveIntentions );
				$( '.noActiveIntentions' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=activeIntentionsCount&statusList=${statusList}`;
				});

				
				$( '.customersOptOutMCC .kpiValue' ).html( response.customersOptOutMCC );
				$( '.customersOptOutMCC' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=optOutOfMCCCalls&statusList=${statusList}`;
				});


			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in getAlerts(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================

				

		//====================================================================================
		function getUnmappedLsvtLocations() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/tgimu/unmappedLsvtLocations`,
				data: { 
					statusList: customerStatusList(),
					isActive: true,
					resultsAs: 'count'
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				$( '.unmappedLsvtLocations .kpiValue' ).html( response );
				$( '.unmappedLsvtLocations' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `lsvtManualLocationCustomerMapping.asp`;
				});

			}).fail( function( req, status, err ) {

				console.error( `Something went wrong (${status}) in getNewCustomersWithGaps(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================



		//====================================================================================
		function getNewCustomersWithGaps() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/newCustomersWithGaps`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				$( '.newCustomerGaps .kpiValue' ).html( response );
				$( '.newCustomerGaps' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=hasOnboardingIssues&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {

				console.error( `Something went wrong (${status}) in getNewCustomersWithGaps(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function getNoKeyInitiatives() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/noKeyInitiatives`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				$( '.noKIs .kpiValue' ).html( response[0] );
				$( '.noKIs' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=noKIs&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in getNoKeyInitiatives(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function getNoOpportunities() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/noActiveOpportunities`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {

				$( '.noOpportunities .kpiValue' ).html( response[0] );
				$( '.noOpportunities' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=noOpportunities&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in getNoOpportunities(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function getOverlappingIntentions() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/overlappingIntentions`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.overlappingIntentions .kpiValue' ).html( response[0] );
				$( '.overlappingIntentions' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=overlappingIntentions&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) in overlappingIntentions(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function getMetricsBelowObjective() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/metricsBelowObjective`,
				data: { 
					statusList: customerStatusList(),
					objectiveTypeID: 1
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				let customers = [];
				

				// get metrics that are associated with Opportunities that are below objective:
				const opportunityMetrics = response.filter( function( ele ) {
					return ( ele.objectiveTypeID === '2' && ele.belowObj );
				});
				
				// now get unique cutomers from opportunityMetrics...
				customers = opportunityMetrics.map( function( ele ) {
					return ele.customerID;
				});
				let oppCustCount = new Set( customers ).size;

				$( '.opportunityMetricsBelowObjective .kpiValue' ).html( oppCustCount );
				$( '.opportunityMetricsBelowObjective' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=oppBelowObj&statusList=${statusList}`;
				});


				// get metrics are associated with Utopia that are below objective...
				const utopiaMetrics = response.filter( function( ele ) {
					return ( ele.objectiveTypeID === '1' && ele.belowObj );
				});
				
				// now get unique customers from utopiaMetrics...
				customers = utopiaMetrics.map( function( ele ) {
					return ele.customerID;
				});
				let utopiaCustCount = new Set( customers ).size;

				$( '.utopiaMetricsBelowObjective .kpiValue' ).html( utopiaCustCount );
				$( '.utopiaMetricsBelowObjective' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=utopiaBelowObj&statusList=${statusList}`;
				});



			}).fail( function( req, status, err ) {
				
				$( '.opportunityMetricsBelowObjective .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				$( '.utopiaMetricsBelowObjective .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				console.error( `Something went wrong (${status}) in getMetricsBelowObjective(), please contact your system administrator.` );
				console.error( err );
				
			});
			
		}
		//====================================================================================


		//====================================================================================
		function getOverdueMetrics() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/getOverdueMetrics`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				const uniqueCustomers 	= [ ...new Set( response.map( x => x.customerID ) ) ];
				const customerCount 		= uniqueCustomers.length;

				$( '.overdueMetrics .kpiValue' ).html( customerCount );
				$( '.overdueMetrics' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=overdueMetrics&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) getOverdueMetrics(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function getCustomersNotShopped( months ) {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/getCustomersNotShopped`,
				data: { statusList: customerStatusList(), months: months },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.noShops .mdl-spinner' ).remove();
				$( '.noShops .kpiValue' ).html( response );
				$( '.noShops' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=noShops&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) getOverdueMetrics(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function	getCustomersWithoutMsBank() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/getCustomersWithoutMsBank`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.customerNoMsBank .mdl-spinner' ).remove();
				$( '.customerNoMsBank .kpiValue' ).html( response );
				$( '.customerNoMsBank' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMetricsDashboard.asp?filter=customerNoMsBank&statusList=${statusList}`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) getCustomersWithoutMsBank(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function	getMsBanksWithoutCustomer() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/exec/getMsBanksWithoutCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.msBankNoCustomer .mdl-spinner' ).remove();
				$( '.msBankNoCustomer .kpiValue' ).html( response );
				$( '.msBankNoCustomer' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `customerMysteryShoppingMsBanksNoCustomer.asp`;
				});

			}).fail( function( req, status, err ) {
				
				console.error( `Something went wrong (${status}) getMsBanksWithoutCustomer(), please contact your system administrator.` );
				throw new Error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function	getMostMissedQuestionCategory() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionCategory`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				$( '.msMostMissedQuestionCategory .mdl-spinner' ).remove();
				if ( response.length > 0 ) {
					$( '.msMostMissedQuestionCategory .kpiValue' ).html( response[0].categoryName );
					$( '.msMostMissedQuestionCategory' ).on( 'click', function() {
						window.location.href = `mysteryShoppingQuestions.asp?filter=${response[0].name}`;
					});
				} else {
					$( '.msMostMissedQuestionCategory .kpiValue' ).html( "None found" );
				}

			}).fail( function( req, status, err ) {
				
				$( '.msMostMissedQuestionCategory .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				console.error( `Something went wrong (${status}) getMostMissedQuestionCategory(), please contact your system administrator.` );
				console.error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function	getMostMissedQuestion() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestion`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.msMostMissedQuestion .mdl-spinner' ).remove();
				if ( response.length > 0 ) {
					$( '.msMostMissedQuestion .kpiValue' ).html( response[0].questionText );
					$( '.msMostMissedQuestion .kpiFooter' ).html( `Category: ${response[0].categoryName}` );
// 				$( '.msMostMissedQuestionCategory' ).on( 'click', function() {
// 					const statusList = customerStatusList();
// 					window.location.href = `customerMysteryShoppingMsBanksNoCustomer.asp`;
// 				});
				} else {
					$( '.msMostMissedQuestion .kpiValue' ).html( "None found" );
				}

			}).fail( function( req, status, err ) {
				
				$( '.msMostMissedQuestionCategory .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				$( '.msMostMissedQuestionCategory .kpiFooter' ).html( '' );
				console.error( `Something went wrong (${status}) getMostMissedQuestion(), please contact your system administrator.` );
				console.error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function	getUncategorizedQuestions() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/mysteryShopping/uncategorizedQuestions`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.uncategorizedQuestions .mdl-spinner' ).remove();
				$( '.uncategorizedQuestions .kpiValue' ).html( response[0].uncategorizedQuestions );

				$( '.uncategorizedQuestions' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `mysteryShoppingQuestions.asp`;
				});

			}).fail( function( req, status, err ) {
				
				$( '.uncategorizedQuestions .mdl-spinner' ).remove();
				$( '.uncategorizedQuestions .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				$( '.uncategorizedQuestions .kpiFooter' ).html( '' );
				console.error( `Something went wrong (${status}) uncategorizedQuestions(), please contact your system administrator.` );
				console.error( err );
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function	getCustomersNoSurveys() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/surveys/unassociatedCustomers`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.customersNoSurveys .mdl-spinner' ).remove();
				$( '.customersNoSurveys .kpiValue' ).html( response );

				$( '.customersNoSurveys' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `alchemerSurveyCustomerMapping.asp`;
				});

			}).fail( function( req, status, err ) {
				
				$( '.customersNoSurveys .mdl-spinner' ).remove();
				$( '.customersNoSurveys .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				$( '.customersNoSurveys .kpiFooter' ).html( '' );
				console.error( `Something went wrong (${status}) getCustomerNoSurveys(), please contact your system administrator.` );
				console.error( err );
			
			});
			
		}
		//====================================================================================



		//====================================================================================
		function	geSurveysNoCustomer() {
		//====================================================================================

			$.ajax({
				dataType: "json",
				url: `${apiServer}/api/surveys/unassociatedSurveys`,
				data: { statusList: customerStatusList() },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }
			}).then( function( response ) {
				
				$( '.surveysNoCustomer .mdl-spinner' ).remove();
				$( '.surveysNoCustomer .kpiValue' ).html( response );

				$( '.surveysNoCustomer' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `alchemerSurveyCustomerMapping.asp`;
				});

			}).fail( function( req, status, err ) {
				
				$( '.surveysNoCustomer .mdl-spinner' ).remove();
				$( '.surveysNoCustomer .kpiValue' ).html( 'Error' ).css( 'color: crimson' );
				$( '.surveysNoCustomer .kpiFooter' ).html( '' );
				console.error( `Something went wrong (${status}) geSurveysNoCustomer(), please contact your system administrator.` );
				console.error( err );
			
			});
			
		}
		//====================================================================================






		//====================================================================================
		function drawCharts() {
		//====================================================================================


			$( function() {
	
				$( document ).tooltip();
				$( 'input.customerStatus' ).checkboxradio();


				const $accordionMiscellaneous = $( '#accordionMiscellaneous' );
				$accordionMiscellaneous.accordion({
					collapsible: true,
					animate: false,
					active: false
				});				
				const accordionMiscellaneous_savedState = localStorage.getItem( 'execDashboardState_AccordionMiscellaneous' );
				if ( accordionMiscellaneous_savedState === "false" ) {
					$accordionMiscellaneous.accordion( 'option', 'active', false );
				} else {
					$accordionMiscellaneous.accordion( 'option', 'active', 0 );
				}
				$accordionMiscellaneous.accordion( 'option', 'animate', 200 );

				
				
				const $accordionMysteryShopping = $( '#accordionMysteryShopping' );
				$accordionMysteryShopping.accordion({
					collapsible: true,
					animate: false,
					active: false
				});				
				const accordionMysteryShopping_savedState = localStorage.getItem( 'execDashboardState_AccordionMysteryShopping' );
				if ( accordionMysteryShopping_savedState === "false" ) {
					$accordionMysteryShopping.accordion( 'option', 'active', false );
				} else {
					$accordionMysteryShopping.accordion( 'option', 'active', 0 );
				}
				$accordionMysteryShopping.accordion( 'option', 'animate', 200 );
				
				
				const $accordionContracts = $( '#accordionContracts' );
				$accordionContracts.accordion({
					collapsible: true,
					animate: false,
					active: false
				});				
				const accordionContracts_savedState = localStorage.getItem( 'execDashboardState_AccordionContracts' );
				if ( accordionContracts_savedState === "false" ) {
					$accordionContracts.accordion( 'option', 'active', false );
				} else {
					$accordionContracts.accordion( 'option', 'active', 0 );
				}
				$accordionContracts.accordion( 'option', 'animate', 200 );
				
				
				const $accordionIntentions = $( '#accordionIntentions' );
				$accordionIntentions.accordion({
					collapsible: true,
					animate: false,
					active: false
				});				
				const accordionIntentions_savedState = localStorage.getItem( 'execDashboardState_AccordionIntentions' );
				if ( accordionIntentions_savedState === "false" ) {
					$accordionIntentions.accordion( 'option', 'active', false );
				} else {
					$accordionIntentions.accordion( 'option', 'active', 0 );
				}
				$accordionIntentions.accordion( 'option', 'animate', 200 );
				

				const $accordionManagers = $( '#accordionManagers' );
				$accordionManagers.accordion({
					collapsible: true,
					animate: false,
					active: false
				});				
				const accordionManagers_savedState = localStorage.getItem( 'execDashboardState_AccordionManagers' );
				if ( accordionManagers_savedState === "false" ) {
					$accordionManagers.accordion( 'option', 'active', false );
				} else {
					$accordionManagers.accordion( 'option', 'active', 0 );
				}
				$accordionManagers.accordion( 'option', 'animate', 200 );
				

				const $accordionSurveys = $( '#accordionSurveys' );
				$accordionSurveys.accordion({
					collapsible: true,
					animate: false,
					active: false
				});				
				const accordionSurveys_savedState = localStorage.getItem( 'execDashboardState_accordionSurveys' );
				if ( accordionSurveys_savedState === "false" ) {
					$accordionSurveys.accordion( 'option', 'active', false );
				} else {
					$accordionSurveys.accordion( 'option', 'active', 0 );
				}
				$accordionSurveys.accordion( 'option', 'animate', 200 );
				



				buildKPI_overdueMCC();
				buildKPI_overdueSAC();

				buildChart_averageMCC();
				buildChart_averageSAC();
				buildChart_managerGauges();
				getAlerts();
				getNewCustomersWithGaps();
				getSkippedTasks();
				getNoKeyInitiatives();
				getNoOpportunities();
				getOverlappingIntentions();
				getMetricsBelowObjective();
				getOverdueMetrics();
				getCustomersNotShopped( 12 );
				getCustomersWithoutMsBank();
				getMsBanksWithoutCustomer();
				getMostMissedQuestionCategory();
				getMostMissedQuestion();
				getUncategorizedQuestions();
				getUnmappedLsvtLocations();
				getCustomersNoSurveys();
				geSurveysNoCustomer();
				

				$( 'input.customerStatus' ).on( 'click', function() {
	
					buildKPI_overdueMCC();
					buildKPI_overdueSAC();

					buildChart_averageMCC();
					buildChart_averageSAC();
					buildChart_managerGauges();
					getAlerts();
					getNewCustomersWithGaps();
					getSkippedTasks();
					getNoKeyInitiatives();
					getNoOpportunities();
					getOverlappingIntentions();
					getMetricsBelowObjective();
					getOverdueMetrics();
					getCustomersNotShopped( 12 );
					getCustomersWithoutMsBank();
					getMsBanksWithoutCustomer();
					getMostMissedQuestionCategory();
					getMostMissedQuestion();
					getUncategorizedQuestions();
					getUnmappedLsvtLocations();
					getCustomersNoSurveys();
					geSurveysNoCustomer();
					
										
				});

				$( '.projectEscalations' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `projectStatusList.asp?type=escalate&statusList=${statusList}`;
				});

				$( '.projectReschedules' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `projectStatusList.asp?type=reschedule&statusList=${statusList}`;
				});

				$( '.skippedTasks' ).on( 'click', function() {
					const statusList = customerStatusList();
					window.location.href = `skippedTaskList.asp?statusList=${statusList}`;
				});
				
				
				$( 'div.ui-accordion' ).on( 'click', function(e) {

					switch ( this.id ) {
						case 'accordionMiscellaneous':
							currentItem = 'execDashboardState_AccordionMiscellaneous';
							break;
						case 'accordionMysteryShopping':
							currentItem = 'execDashboardState_AccordionMysteryShopping';
							break;
						case 'accordionContracts':
							currentItem = 'execDashboardState_AccordionContracts';
							break;
						case 'accordionIntentions':
							currentItem = 'execDashboardState_AccordionIntentions';
							break;
						case 'accordionManagers':
							currentItem = 'execDashboardState_AccordionManagers';
							break;
						case 'accordionSurveys':
							currentItem = 'execDashboardState_AccordionSurveys';
							break;
						default:
							console.warning( 'unknown acccordian ID encountered' );
							currentItem = null;
					}
					
// 					const currentItem = this.id === 'accordionMysteryShopping' ? 'execDashboardState_AccordionMysteryShopping' : 'execDashboardState_AccordionContracts';
					const currentState = $( this ).accordion( 'option', 'active' );
					localStorage.setItem( currentItem, currentState );
				});

			});

		}
		//====================================================================================

		
	</script>


	<style>
		
		.ui-checkboxradio-label {
			width: 175px;
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
			padding-left: 50px;
		}
		
		div.leftSidebar {
			margin-left: 0px;
			margin-right: 0px;
			padding-left: 0px;
			
		}
		
		.alertIcon {
			font-size: 80px;
		}
		
		.alertHeader {
			font-family: Arial; 
			font-size: 13px; 
			stroke: none; 
			font-weight: bold; 
		}
		
		.alertContainer {
			text-align: center;
		}

		.mdl-badge[data-badge]:after {
			color: white;
			background-color: crimson;
		}
		
		.material-icons.info {
			color: black;
		}

		
		span.cmtGauge {
			display: inline-block;
		}
		
		
		.kpiContainer {
			cursor: pointer;
		}
		
		i.alertIcon {
			color: orange;
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
/* 			border: solid orange 2px; */
			display: table;
			height: 60px;
			margin: 5px;
			text-align: center;
			vertical-align: middle;
			width: 93%;
		}

		.kpiValue {
/* 			border: solid green 1px; */
			display: table-cell;
			float: right;
			font-family: Arial; 
			font-size: 50px; 
			font-weight: bold; 
			line-height: 100%;
			stroke: none; 
		}
		
		.kpiIcon {
/* 			border: solid blue 1px; */
			display: table-cell;
			height: 100%;
			float: left;
		}
		
		.kpiIcon .material-icons {
			font-size: 50px;
		}

		.kpiFooter {
			display: table-cell;
			float: right;
			font-family: Arial; 
			stroke: none; 
			margin-right: 15px;
		}
		
		div.ui-accordion > div.ui-accordion-content {
			padding: 5px 0px 5px 0px;
		}
		
		#accordionManagers > div.ui-accordion-content {
			padding: 5px 0px 5px 0px;
			height: 190px;
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


	<div class="mdl-grid"><!-- start of primary mdl-grid -->
	
		<div class="mdl-cell mdl-cell--2-col leftSidebar">

			<div class="mdl-grid">
				<div class="mdl-cell mdl-cell--12-col">
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
								if rsCS("selectByDefault") then 
									checked = "checked"
								else 
									checked = ""
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
				</div>
			</div><!-- customer statuses -->

			<div class="mdl-grid">
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">

					<div class="alertContainer projectEscalations">
						<div class="alertHeader">Project Escalations</div>
							<i class="material-icons alertIcon" >trending_up</i>
						<span class="mdl-badge mdl-badge--overlap escalate" data-badge="" style="display: none;"></span>
					</div>

				</div>
			</div><!-- project escalations -->		

			<div class="mdl-grid">
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">

					<div class="alertContainer projectReschedules">
						<div class="alertHeader">Project Reschedules</div>
							<i class="material-icons alertIcon" >update</i>
						<span class="mdl-badge mdl-badge--overlap reschedule" data-badge="" style="display: none;"></span>
					</div>

				</div>
			</div><!-- project reschedules -->		

			<div class="mdl-grid">
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">

					<div class="alertContainer skippedTasks">
						<div class="alertHeader">Skipped Tasks</div>
							<i class="material-icons alertIcon" >skip_next</i>
						<span class="mdl-badge mdl-badge--overlap skipped" data-badge="" style="display: none;"></span>
					</div>
				</div>
			</div><!-- skipped tasks -->		

		</div><!-- Left Sidebar -->
		
		<div class="mdl-cell mdl-cell--10-col">

			<div class="mdl-grid" style="padding: 0px;">
				<div class="mdl-cell mdl-cell--9-col" style="margin: 0px;">
					<div class="mdl-grid">

						<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
							<div id="averageMCC_progressbar"></div>
							<div id="averageMCC">Average Days Since Last Completed MCC</div>
						</div><!-- averageMCC -->


						<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
								<div id="averageSAC_progressbar"></div>
								<div id="averageSAC">Average Days Since Last Completed SAC</div>
						</div><!-- averageSAC -->
							
			
					</div>
				</div>
				
				<div class="mdl-cell mdl-cell--3-col" style="margin: 0px;">
					<div class="mdl-grid">
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--4dp kpiOverdueMCC kpiContainer">
					<div class="kpiTitle">Customers With Overdue MCC Calls</div>
					<div class="kpiContent">
							<div class="kpiIcon"><span class="material-icons">assignment_late</span></div>
							<div class="kpiValue"></div>
					</div>
				</div><!-- kpiOverdueMCC -->

					</div>
					<div class="mdl-grid">
						<div class="mdl-cell mdl-cell--12-col mdl-shadow--4dp kpiOverdueSAC kpiContainer">
							<div class="kpiTitle">Customers With Overdue SAC Calls</div>
							<div class="kpiContent">
								<div class="kpiIcon"><span class="material-icons">assignment_late</span></div>
								<div class="kpiValue"></div>
							</div>
						</div><!-- kpiOverdueSAC -->
					</div>
				</div>
			</div>



			<div class="mdl-grid">
				<div id="accordionMiscellaneous" style="width: 100%;">
					<h3>Miscellaneous</h3>

					<div> 
						<div class="mdl-grid">
							
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp noActiveIntentions kpiContainer" >
								<div class="kpiTitle">Customers Without Active Intentions</div>
								<div class="kpiContent">
										<div class="kpiIcon"><span class="material-icons">running_with_errors</span></div>
										<div class="kpiValue"></div>
								</div>
							</div><!-- noActiveIntentions -->
			
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp internalCustomerContacts kpiContainer" >
								<div class="kpiTitle">Active Internal Users that Are Customer Contacts</div>
								<div class="kpiContent">
										<div class="kpiIcon"><span class="material-icons">attribution</span></div>
										<div class="kpiValue"></div>
								</div>
							</div><!-- internalCustomerContacts -->
			
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp internalExternalUsers kpiContainer" >
								<div class="kpiTitle">Active Internal Users that Are External Users</div>
								<div class="kpiContent">
										<div class="kpiIcon"><span class="material-icons">social_distance</span></div>
										<div class="kpiValue"></div>
								</div>
							</div><!-- internalExternalUsers -->
			
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp customersOptOutMCC kpiContainer" >
								<div class="kpiTitle">Customers opted out of MCCs</div>
								<div class="kpiContent">
										<div class="kpiIcon"><span class="material-icons">thumb_down_off_alt</span></div>
										<div class="kpiValue"></div>
								</div>
							</div><!-- customerOptOutMCC -->
							
						</div>
						
						<div class="mdl-grid">
			
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp newCustomerGaps kpiContainer" >
								<div class="kpiTitle">Customers with Onboarding Gaps</div>
								<div class="kpiContent">
										<div class="kpiIcon"><span class="material-icons">warning_amber</span></div>
										<div class="kpiValue"></div>
								</div>
							</div><!-- newCustomerGaps -->
	
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp customersNoCompletedCalls kpiContainer" >
								<div class="kpiTitle">Customers Without Any Completed Calls</div>
								<div class="kpiContent">
	 								<div class="kpiIcon"><span class="material-icons">phone_disabled</span></div>
	 								<div class="kpiValue"></div>
								</div>
							</div><!-- customersNoCompletedCalls -->
	
	
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp missedCalls kpiContainer">
								<div class="kpiTitle">Customers With Missed Calls</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">voicemail</span></div>
									<div class="kpiValue"></div>
								</div>
								<div class="kpiFooter">&nbsp;</div>
							</div><!-- kpiOverdueSAC -->
	
	
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp unmappedLsvtLocations kpiContainer">
								<div class="kpiTitle">Active LSVT Locations Not Associated With A Customer</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">domain_disabled</span></div>
									<div class="kpiValue"></div>
								</div>
								<div class="kpiFooter">&nbsp;</div>
							</div><!-- kpiOverdueSAC -->
	
	
						</div>

					</div>
				</div>
			</div><!-- Miscellaneous -->



			<div class="mdl-grid">
				<div id="accordionMysteryShopping" style="width: 100%;">
					<h3>Mystery Shopping</h3>
					
					<div>

						<div class="mdl-grid">
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp kpiContainer customerNoMsBank" >
								<div class="kpiTitle">Customers not associated with a Mystery Shopping bank</div>
								<div class="kpiContent">
									<div class="mdl-spinner mdl-js-spinner is-active"></div>
									<div class="kpiIcon"><span class="material-icons">rule</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- Active customers that are not associated with a Mystery Shopping bank -->
			
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp kpiContainer msBankNoCustomer" >
								<div class="kpiTitle">Mystery Shopping banks not associated with a customer (all statuses)</div>
								<div class="kpiContent">
									<div class="mdl-spinner mdl-js-spinner is-active"></div>
									<div class="kpiIcon"><span class="material-icons" style="transform: rotateX( 180deg );">rule</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- Mystery Shopping banks that are not associated with a customer -->
			
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp noShops kpiContainer" >
								<div class="kpiTitle">Customers that have not been shopped in the last 12 months</div>
								<div class="kpiContent">
									<div class="mdl-spinner mdl-js-spinner is-active"></div>
									<div class="kpiIcon"><span class="material-icons">remove_shopping_cart</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- newCustomerGaps -->
							
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp uncategorizedQuestions kpiContainer" >
								<div class="kpiTitle">Uncategorized questions</div>
								<div class="kpiContent">
									<div class="mdl-spinner mdl-js-spinner is-active"></div>
									<div class="kpiIcon"><span class="material-icons">baby_changing_station</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- newCustomerGaps -->
							
						</div>
						
						<div class="mdl-grid">
							
							<div class="mdl-cell mdl-cell--4-col mdl-shadow--4dp kpiContainer msMostMissedQuestionCategory" >
								<div class="kpiTitle">Most missed question category in the last 12 months</div>
								<div class="kpiContent">
									<div class="mdl-spinner mdl-js-spinner is-active"></div>
									<div class="kpiIcon"><span class="material-icons">help_outline</span></div>
									<div class="kpiValue" style="font-size: 16px; float: left; margin-left: 15px; margin-top: 15px;"></div>
								</div>
							</div><!-- Most missed question category in the last 12 months -->
			
							<div class="mdl-cell mdl-cell--4-col mdl-shadow--4dp kpiContainer msMostMissedQuestion" >
								<div class="kpiTitle">Most missed question in the last 12 months</div>
								<div class="kpiContent">
									<div class="mdl-spinner mdl-js-spinner is-active"></div>
									<div class="kpiIcon"><span class="material-icons">help</span></div>
									<span class="kpiValue" style="font-size: 12px; text-align: left; margin-left: 15px; margin-top: 15px; width: 235px;"></span>
								</div>
								<div class="kpiFooter">&nbsp;</div>
							</div><!-- Most missed question in the last 12 months -->
			
						</div>
						
					</div>
				</div>
			</div><!-- Mystery Shopping -->


			<div class="mdl-grid">
				<div id="accordionContracts" style="width: 100%;">
					<h3>Contracts</h3>
					<div class="mdl-grid">
	
						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp fcpContractsExpiring kpiContainer" >
							<div class="kpiTitle">Customers w/ Active FCP Contracts Expiring Within 6 months</div>
							<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">article</span></div>
									<div class="kpiValue"></div>
							</div>
						</div><!-- FCP contractsExpiring -->
		
						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp msContractsExpiring kpiContainer" >
							<div class="kpiTitle">Customers w/ Active Mystery Shopping Contracts Expiring Within 6 months</div>
							<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">article</span></div>
									<div class="kpiValue"></div>
							</div>
						</div><!-- Mystery Shoppping contractsExpiring -->
		
						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp csContractsExpiring kpiContainer" >
							<div class="kpiTitle">Customers w/ Active Culture Survey Contracts Expiring Within 6 months</div>
							<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">article</span></div>
									<div class="kpiValue"></div>
							</div>
						</div><!-- Culture Survey contractsExpiring -->
		

 						<div class="mdl-cell mdl-cell--2-col" >
						</div>

 						<div class="mdl-cell mdl-cell--2-col" >
						</div>

 						<div class="mdl-cell mdl-cell--2-col" >
						</div>



					</div>

				</div>
			</div><!--contracts -->


			<div class="mdl-grid">
				<div id="accordionSurveys" style="width: 100%;">
					<h3>Surveys</h3>
					<div class="mdl-grid">
	
						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp customersNoSurveys kpiContainer" >
							<div class="kpiTitle">Customers Without Associated Culture Survey(s)</div>
							<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">article</span></div>
									<div class="kpiValue"></div>
							</div>
						</div><!-- Customers Without Associated Surveys -->
		
						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp surveysNoCustomer kpiContainer" >
							<div class="kpiTitle">Culture Surveys Not Associated With A Customer</div>
							<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">article</span></div>
									<div class="kpiValue"></div>
							</div>
						</div><!-- Surveys not Associated With A Customer -->
		
 						<div class="mdl-cell mdl-cell--2-col" >
						</div>

 						<div class="mdl-cell mdl-cell--2-col" >
						</div>

 						<div class="mdl-cell mdl-cell--2-col" >
						</div>

 						<div class="mdl-cell mdl-cell--2-col" >
						</div>



					</div>

				</div>
			</div><!--Surveys -->


			<div class="mdl-grid">
				<div id="accordionIntentions" style="width: 100%;">
					<h3>Intentions, Opportunities, Utopias, KIs</h3>
					<div>
						
						<div class="mdl-grid">
		
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp overlappingIntentions">
								<div class="kpiTitle">Customers With Overlapping Active Intentions</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">content_copy</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- customers with overlapping active intentions -->
	
							<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp noOpportunities" >
								<div class="kpiTitle">Customers Without Active Opportunities</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">try</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- customer without active opportunities -->
	
	 						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp noKIs" >
								<div class="kpiTitle">Customers Without Active KIs</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">key</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- Customers Without Active KIs -->
	
	 						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp opportunityMetricsBelowObjective" >
								<div class="kpiTitle">Customers With Opportunity Metrics Below Objective</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons" style="transform: rotate(180deg);">call_missed</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- Customers With Opportunity Metrics Below Objective -->
	
						</div>
						
						<div class="mdl-grid">
						
	 						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp utopiaMetricsBelowObjective" >
								<div class="kpiTitle">Customers With Utopia Metrics Below Objective</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons" style="transform: rotate(180deg);">call_missed</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- Customers With Utopia Metrics Below Objective -->
	
	 						<div class="mdl-cell mdl-cell--3-col mdl-shadow--4dp overdueMetrics" >
								<div class="kpiTitle">Customers With Overdue Metric Values</div>
								<div class="kpiContent">
									<div class="kpiIcon"><span class="material-icons">assignment_late</span></div>
									<div class="kpiValue"></div>
								</div>
							</div><!-- Customers With Utopia Metrics Below Objective -->
	
	
						</div>
					
					</div>
				</div>
			</div><!-- Intentions, Opportunities, Utopias, Kis -->


			<div class="mdl-grid">
				<div id="accordionManagers" style="width: 100%;">
				<h3>Customers with Missing Manager Assignments</h3>

					<div class="mdl-grid" style="height: 200px;">
					
					
						<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">
							<div id="managerTypeGauges_progressbar"></div>
							<div id="managerTypeGauges"></div>
						</div>
	
					</div><!-- Manager Type Gauges -->

				</div>
			</div>
		
		</div>
		
	</div><!-- end of primary grid -->


	
</main>
<!-- #include file="includes/pageFooter.asp" -->



</body>

</html>