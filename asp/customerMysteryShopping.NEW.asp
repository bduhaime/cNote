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

customerID = request.querystring("id")

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
		
		google.charts.load( 'current', { 'packages': ['corechart'] } );
		
		google.charts.setOnLoadCallback( drawCharts );
		

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
		function getDistinctBranches( customerID ) {
		//====================================================================================

			return new Promise( (resolve, reject) => {

				$.ajax({
					url: `${apiServer}/api/mysteryShopping/distinctBranches`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { customerID: customerID }
				}).done( data => {
					
					$( '#branchSelectMenu' ).empty();
					$( '#branchSelectMenu' ).append( `<option value="all">All Branches</options>` );

					for ( item of data ) {
						$( '#branchSelectMenu' ).append( `<option value="${item.branchName}">${item.branchName}</option>` );
					}
					
					return resolve( true );

				}).fail( err => {
					return reject( err );
				});
				
			});

		}
		//====================================================================================



		//====================================================================================
		function reloadWidgets( customerID ) {
		//====================================================================================

			getAverageGrade( customerID );
			getTotalNaShops( customerID );
			getBranchesShopped( customerID );
			getSupervisorsShopped( customerID );
			getBankersShopped( customerID );
			getMonthlyTrend( customerID );
			getAverageScoreByBranchChart( customerID );
			$( '#branches' ).DataTable().ajax.reload();
			getAverageScoreBySupervisorChart( customerID );
			$( '#supervisors' ).DataTable().ajax.reload();
			getGradeSummary( customerID );
			getMostMissedQuestionCategoryByCustomer( customerID );
			getMostMissedQuestionByCustomer( customerID );
// 			getNaShopsByBanker( customerID );
						
		}
		//====================================================================================


				
		//====================================================================================
		function getAverageGrade( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#averageGrade_progressbar' );
			const $kpiContent 	= $( '.averageGrade .kpiContent' );
			const $kpiValue		= $( '.averageGrade .kpiValue' );
			const $kpiFooter		= $( '.averageGrade .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$kpiFooter.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/averageGrade`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				let score = data.score * 100;
				score = score.toFixed(1) + '%';
				$progressBar.progressbar( 'destroy' );
				$kpiValue.html( `Grade: ${data.grade}` );
				$kpiFooter.html( `Average score: ${score}` );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});


		}
		//====================================================================================


				
		//====================================================================================
		function getTotalNaShops( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#totalNaShops_progressbar' );
			const $kpiContent 	= $( '.totalNaShops .kpiContent' );
			const $kpiValue		= $( '.totalNaShops .kpiValue' );
			const $kpiFooter		= $( '.totalNaShops .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$kpiFooter.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/totalNaShops`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				$kpiValue.html( `${data.naShops} / ${data.totalShops}` );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getBranchesShopped( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#branchesShopped_progressbar' );
			const $kpiContent 	= $( '.branchesShopped .kpiContent' );
			const $kpiValue		= $( '.branchesShopped .kpiValue' );
			const $kpiFooter		= $( '.branchesShopped .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/branchesShopped`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				$kpiValue.html( `${data.shopped} / ${data.total}` );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getSupervisorsShopped( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#supervisorsShopped_progressbar' );
			const $kpiContent 	= $( '.supervisorsShopped .kpiContent' );
			const $kpiValue		= $( '.supervisorsShopped .kpiValue' );
			const $kpiFooter		= $( '.supervisorsShopped .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/supervisorsShopped`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				$kpiValue.html( `${data.shopped} / ${data.total}` );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getBankersShopped( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#bankersShopped_progressbar' );
			const $kpiContent 	= $( '.bankersShopped .kpiContent' );
			const $kpiValue		= $( '.bankersShopped .kpiValue' );
			const $kpiFooter		= $( '.bankersShopped .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/bankersShopped`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				$kpiValue.html( `${data.shopped} / ${data.total}` );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		async function getMonthlyTrend( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#monthlyTrend_progressbar' );
			const $kpiContent 	= $( '#monthlyTrend' );
			const $kpiValue		= $( '.monthlyTrend .kpiValue' );
			const $kpiFooter		= $( '.monthlyTrend .kpiFooter' );
			
			const summarizeBy = $( '#summarizeBy' ).val();
			const minMaxDates = await getMinMaxShoppedDates( customerID );
			

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/averageScoreByPeriod`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					summarizeBy: summarizeBy,
					startDate: minMaxDates.minDate,
					endDate: minMaxDates.maxDate,
					branch: $( '#branchSelectMenu' ).val()
				}
			}).done( data => {

				$progressBar.progressbar( 'destroy' );
				
				let interpolateNulls = $( '#interpolateNulls' ).val();
				
				let dataTable = new google.visualization.DataTable( data );
				let wrapper = new google.visualization.ChartWrapper({
					chartType: 'LineChart',
					dataTable: dataTable,
					options: {
						aggregationTarget: 'none',
						interpolateNulls: $( '#interpolateNulls' ).prop( 'checked' ),
						theme: 'material',
						chartArea:{ 
							left: '12%',
							top: '25%',
							width:'75%',
							height:'67%',
						},
						explorer: 	tgim_explorer,
			         hAxis: {
							minorGridlines: {count: 0},
			         	viewWindow: {
				         	min: dayjs( $( '#startDate' ).val() ).toDate(),
				         	max: dayjs( $( '#endDate' ).val() ).toDate(),
				         },
						},
						isStacked: true,
						legend: 		{ position: 'top' },
			         lineWidth: 	5,
						pointSize: 	6,
						series: {
							0: { color: 'green', targetAxisIndex: 0 },
							1: { color: 'crimson', targetAxisIndex: 1 },
						},
						title: 'Average Shop Score By Period (all dates)',
						tootltip: { isHtml: true },
						vAxes: {
							0: { title: 'Average Score', textStyle: { color: 'green' }, minValue: 0, maxValue: 100, titleTextStyle: { color: 'green' }  },
							1: { title: '# N/As', textStyle: { color: 'crimson' }, titleTextStyle: { color: 'crimson' } },
						},
					},
					containerId: 'monthlyTrend'
				});

				google.visualization.events.addListener( wrapper, 'ready', function() {
					google.visualization.events.addListener( wrapper, 'select', function() {

						let chart 					= wrapper.getChart();
						let dataTable 				= wrapper.getDataTable();
						let summarizeBy			= $( '#summarizeBy' ).val();
						let selectedItem 			= chart.getSelection()[0];

						let startDate, endDate 
						let selectedDate			= dataTable.getValue( selectedItem.row, 0 );

						switch ( summarizeBy ) {
							
							case 'day':
								startDate 	= dayjs( selectedDate ).startOf( 'day' ).format( 'MM/DD/YYYY' );
								endDate 		= dayjs( selectedDate ).endOf( 'day' ).format( 'MM/DD/YYYY' );
								break;
							case 'week':
								startDate 	= dayjs( selectedDate ).startOf( 'week' ).format( 'MM/DD/YYYY' );
								endDate 		= dayjs( selectedDate ).endOf( 'week' ).format( 'MM/DD/YYYY' );
								break;
							case 'quarter': 
								startDate 	= dayjs( selectedDate ).startOf( 'quarter' ).format( 'MM/DD/YYYY' );
								endDate 		= dayjs( selectedDate ).endOf( 'quarter' ).format( 'MM/DD/YYYY' );
								break;
							default: 
								startDate 	= dayjs( selectedDate ).startOf( 'month' ).format( 'MM/DD/YYYY' );
								endDate 		= dayjs( selectedDate ).endOf( 'month' ).format( 'MM/DD/YYYY' );
							
						}



						window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&startDate=${startDate}&endDate=${endDate}`;
	
					});
				});

				wrapper.draw();
				
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getAverageScoreByBranchChart( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#byBranchChart_progressbar' );
			const $kpiContent 	= $( '#byBranchChart' );
			const $kpiValue		= $( '.byBranchChart .kpiValue' );
			const $kpiFooter		= $( '.byBranchChart .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/unsuccessfulShopsByBranch`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val(),
					format: 'chart'
				 }
			}).then( data => {

				$progressBar.progressbar( 'destroy' );

				const dataTable = new google.visualization.DataTable( data );
				const wrapper = new google.visualization.ChartWrapper({
					chartType: 'ColumnChart',
					dataTable: dataTable,
					options: {
						theme: 'material',
						chartArea:{ 
							left: '15%',
							top: '20%',
							width:'70%',
							height:'70%'
						},
						hAxis: { 
							textPosition: 'none',
							title: 'Branch (hover for details)' 
						},
						isStacked: true,
						legend: { position: 'none' },
						title: 'Unsuccessful & N/A Shops By Branch',
						tooltip: { isHtml: true },
						vAxis: {
					      title: 'Count of Unsuccessful Shops',
						},
					},
				   containerId: 'byBranchChart'
				});
				
				
				google.visualization.events.addListener( wrapper, 'ready', function() {
					google.visualization.events.addListener( wrapper, 'select', function() {

						let chart 			= wrapper.getChart();
						let dataTable 		= wrapper.getDataTable();
						let selectedItem 	= chart.getSelection()[0];
						let branch 			= dataTable.getValue( selectedItem.row, 0 );
						let dateRange		= $( '#dateRange' ).find(':selected').val();
						let startDate 		= $( '#startDate' ).val();
						let endDate 		= $( '#endDate' ).val();
						window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&branch=${branch}&dateRange=${dateRange}&startDate=${startDate}&endDate=${endDate}`;
	
					});
				});

				wrapper.draw();

			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getAverageScoreByBranchTable( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#byBranchTable_progressbar' );
			const $kpiContent 	= $( '.byBranchTable .kpiContent' );
			const $kpiValue		= $( '.byBranchTable .kpiValue' );
			const $kpiFooter		= $( '.byBranchTable .kpiFooter' );

			let table = $( '#branches' )

				.on( 'error.dt', function( e, settings, techNote, message ) {
					$kpiContent.text( message );
					$kpiFooter.html( '' );
					console.error( message );
				})
				.on( 'click', 'tbody > tr', function( event ) {

					let branch = $( '#branches' ).DataTable().row( this ).data().branch;
					let dateRange = $( '#dateRange' ).val();
					let startDate = $( '#startDate' ).val();
					let endDate = $( '#endDate' ).val();
					window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&branch=${branch}&dateRange=${dateRange}&startDate=${startDate}&endDate=${endDate}`;

				})
				.DataTable({
					ajax: {
						beforeSend: function() {
							
							console.log( $( '#branchSelectMenu' ).val() );
							
						},
						url: `${apiServer}/api/mysteryShopping/byBranch`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						data: { 
							customerID: customerID,
							format: 'table',
							startDate: function() {
								return $( '#startDate' ).val();
							},
							endDate: function() {
								return $( '#endDate' ).val();
							},
							branch: function() {
								return $( '#branchSelectMenu' ).val()
							},
						 },
						dataSrc: ''
					},
					info: false,
					scrollY: 335,
					searching: false,
					deferRender: true,
					scroller: true,
					scrollCollapse: true,
					columnDefs: [
						{targets: 'branch',			data: 'branch', 			className: 'branch dt-body-left' },
						{targets: 'Ace',				data: 'Ace', 				className: 'Ace dt-body-center' },
						{targets: 'A',					data: 'A', 					className: 'A dt-body-center' },
						{targets: 'B',					data: 'B', 					className: 'B dt-body-center' },
						{targets: 'C', 				data: 'C',					className: 'C dt-body-center' },
						{targets: 'D', 				data: 'D',					className: 'D dt-body-center' },
						{targets: 'NA', 				data: 'NA',					className: 'NA dt-body-center' },
						{targets: 'averageScore', 	data: 'averageScore',	className: 'averageScore dt-body-center' },
					],
					order: [ [ 7, 'desc' ], [ 0, 'asc' ] ],
				});


		}
		//====================================================================================


				
		//====================================================================================
		function getAverageScoreBySupervisorChart( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#bySupervisor_progressbar' );
			const $kpiContent 	= $( '#bySupervisor' );
			const $kpiValue		= $( '.bySupervisor .kpiValue' );
			const $kpiFooter		= $( '.bySupervisor .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/unsuccessfulShopsBySupervisor`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					format: 'chart',
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val()
				 }
			}).then( data => {

				$progressBar.progressbar( 'destroy' );

				let dataTable = new google.visualization.DataTable( data );
				let wrapper = new google.visualization.ChartWrapper({
					chartType: 'ColumnChart',
					dataTable: dataTable,
					options: {
						theme: 'material',
						chartArea:{ 
							left: '15%',
							top: '20%',
							width:'70%',
							height:'70%'
						},
						hAxis: { 
							textPosition: 'none',
							title: 'Supervisor (hover for details)' 
						},
						isStacked: true,
						legend: { position: 'none' },
						title: 'Unsuccessful & N/A Shops By Supervisor',
						tooltip: { isHtml: true },
						vAxis: {
					      title: 'Count of Unsuccessful Shops',
					   },
					},
					containerId: 'bySupervisor'
				});

				google.visualization.events.addListener( wrapper, 'ready', function() {
					google.visualization.events.addListener( wrapper, 'select', function() {

						let chart 			= wrapper.getChart();
						let dataTable 		= wrapper.getDataTable();
						let selectedItem 	= chart.getSelection()[0];
						let supervisor		= dataTable.getValue( selectedItem.row, 0 );
						let dateRange		= $( '#dateRange' ).find(':selected').val();
						let startDate 		= $( '#startDate' ).val();
						let endDate 		= $( '#endDate' ).val();
						window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&supervisor=${supervisor}&dateRange=${dateRange}&startDate=${startDate}&endDate=${endDate}`;
	
					});
				});

				wrapper.draw();



			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getAverageScoreBySupervisorTable( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#bySupervisorTable_progressbar' );
			const $kpiContent 	= $( '.bySupervisorTable .kpiContent' );
			const $kpiValue		= $( '.bySupervisorTable .kpiValue' );
			const $kpiFooter		= $( '.bySupervisorTable .kpiFooter' );

			let table = $( '#supervisors' )

				.on( 'click', 'tbody > tr', function( event ) {

					let branch 			= $( '#supervisors' ).DataTable().row( this ).data().branch;
					let supervisor 	= $( '#supervisors' ).DataTable().row( this ).data().supervisor;
					let dateRange 		= $( '#dateRange' ).val();
					let startDate 		= $( '#startDate' ).val();
					let endDate 		= $( '#endDate' ).val();
					window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&branch=${branch}&supervisor=${supervisor}&dateRange=${dateRange}&startDate=${startDate}&endDate=${endDate}`;

				})
				.on( 'error.dt', function( e, settings, techNote, message ) {
					$kpiContent.text( message );
					$kpiFooter.html( '' );
					console.error( message );
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/mysteryShopping/bySupervisor`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						data: { 
							customerID: customerID,
							format: 'table',
							startDate: function() {
								return $( '#startDate' ).val();
							},
							endDate: function() {
								return $( '#endDate' ).val();
							},
							branch: function() {
								return $( '#branchSelectMenu' ).val()
							},
						 },
						dataSrc: ''
					},
					info: false,
					scrollY: 335,
					searching: false,
					deferRender: true,
					scroller: true,
					scrollCollapse: true,
					columnDefs: [
						{targets: 'branch',			data: 'branch', 			className: 'branch dt-body-left' },
						{targets: 'supervisor',		data: 'supervisor', 		className: 'supervisor dt-body-left' },
						{targets: 'Ace',				data: 'Ace', 				className: 'Ace dt-body-center' },
						{targets: 'A',					data: 'A', 					className: 'A dt-body-center' },
						{targets: 'B',					data: 'B', 					className: 'B dt-body-center' },
						{targets: 'C', 				data: 'C',					className: 'C dt-body-center' },
						{targets: 'D', 				data: 'D',					className: 'D dt-body-center' },
						{targets: 'NA', 				data: 'NA',					className: 'NA dt-body-center' },
						{targets: 'averageScore', 	data: 'averageScore',	className: 'averageScore dt-body-center' },
					],
					order: [ [ 8, 'desc' ], [ 0, 'asc' ], [ 1, 'asc' ] ],
				});


		}
		//====================================================================================


				
		//====================================================================================
		function getGradeSummary( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#gradePie_progressbar' );
			const $kpiContent 	= $( '#gradePie' );
			const $kpiValue		= $( '.gradePie .kpiValue' );
			const $kpiFooter		= $( '.gradePie .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/gradePie`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val(),
				 }
			}).then( data => {
				$progressBar.progressbar( 'destroy' );

				let dataTable = new google.visualization.DataTable( data );
				let wrapper = new google.visualization.ChartWrapper({
					chartType: 'PieChart',
					dataTable: dataTable,
					options: {
						theme: 'material',
						chartArea:{ 
							left: '20%',
							top: '15%',
							width:'100%',
							height:'80%'
						},
						legend: { position: 'right' },
						title: 'Overall Shop Grade Distribution',
					},
					containerId: 'gradePie',
				});

				google.visualization.events.addListener( wrapper, 'ready', function() {
					google.visualization.events.addListener( wrapper, 'select', function() {

						let chart 			= wrapper.getChart();
						let dataTable 		= wrapper.getDataTable();
						let selectedItem 	= chart.getSelection()[0];
						let grade 			= dataTable.getValue( selectedItem.row, 0 );

						if ( $( '#dateRange' ).val() ) {
							queryString = `&dateRange=${ $( '#dateRange' ).val() }`
						} else {
							queryString = `&startDate=${ $( '#startDate' ).val() }&endDate=${ $( '#endDate' ).val() }`
						}
						
						window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&grade=${grade}${queryString}`;
	
					});
				});

				wrapper.draw();

			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getMostMissedQuestionCategoryByCustomer( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#mostMissedQuestionCategory_progressbar' );
			const $kpiContent 	= $( '.mostMissedQuestionCategory .kpiContent' );
			const $kpiValue		= $( '.mostMissedQuestionCategory .kpiValue' );
			const $kpiFooter		= $( '.mostMissedQuestionCategory .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionCategoryByCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				let html = ( data.length ) ? data[0].name : 'N/A';
				$kpiValue.html( html );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getMostMissedQuestionByCustomer( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#mostMissedQuestion_progressbar' );
			const $kpiContent 	= $( '.mostMissedQuestion .kpiContent' );
			const $kpiValue		= $( '.mostMissedQuestion .kpiValue' );
			const $kpiFooter		= $( '.mostMissedQuestion .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiValue.html( '' );
					$kpiFooter.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/mostMissedQuestionByCustomer`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val()
				 },
			}).then( data => {
				$progressBar.progressbar( 'destroy' );
				let html = ( data.length ) ? data[0].questionText : 'N/A';
				let footerHtml = ( data.length ) ? `Category: ${data[0].categoryName}` : '';
				$kpiValue.html( html );
				$kpiFooter.html( footerHtml );
				return;
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		function getRiskByShops( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#riskByShops_progressbar' );
			const $kpiContent 	= $( '#riskByShops' );
			const $kpiValue		= $( '.riskByShops .kpiValue' );
			const $kpiFooter		= $( '.riskByShops .kpiFooter' );

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/riskByShops`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
					branch: $( '#branchSelectMenu' ).val(),
				 }
			}).then( data => {
				$progressBar.progressbar( 'destroy' );

				let dataTable = new google.visualization.DataTable( data );
				let wrapper = new google.visualization.ChartWrapper({
					chartType: 'PieChart',
					dataTable: dataTable,
					options: {
						theme: 'material',
						chartArea:{ 
							left: '20%',
							top: '15%',
							width:'100%',
							height:'80%'
						},
						legend: { position: 'right' },
						title: 'Risk By Shop',
					},
					containerId: 'riskByShops',
				});

/*
				google.visualization.events.addListener( wrapper, 'ready', function() {
					google.visualization.events.addListener( wrapper, 'select', function() {

						let chart 			= wrapper.getChart();
						let dataTable 		= wrapper.getDataTable();
						let selectedItem 	= chart.getSelection()[0];
						let grade 			= dataTable.getValue( selectedItem.row, 0 );

						if ( $( '#dateRange' ).val() ) {
							queryString = `&dateRange=${ $( '#dateRange' ).val() }`
						} else {
							queryString = `&startDate=${ $( '#startDate' ).val() }&endDate=${ $( '#endDate' ).val() }`
						}
						
						window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}&grade=${grade}${queryString}`;
	
					});
				});
*/

				wrapper.draw();

			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//====================================================================================
		async function getRiskByPeriod( customerID ) {
		//====================================================================================

			const $progressBar 	= $( '#riskByPeriod_progressbar' );
			const $kpiContent 	= $( '#riskByPeriod' );
			const $kpiValue		= $( '.riskByPeriod .kpiValue' );
			const $kpiFooter		= $( '.riskByPeriod .kpiFooter' );
			
			const summarizeBy = $( '#summarizeBy' ).val();
			const minMaxDates = await getMinMaxShoppedDates( customerID );
			

			$.ajax({
				beforeSend: function() {
					$kpiContent.html( '' );
					$progressBar.progressbar({ value: false });
				},
				url: `${apiServer}/api/mysteryShopping/riskByMonth`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					customerID: customerID,
					summarizeBy: summarizeBy,
					startDate: minMaxDates.minDate,
					endDate: minMaxDates.maxDate,
					branch: $( '#branchSelectMenu' ).val()
				}
			}).done( data => {

				$progressBar.progressbar( 'destroy' );
				
				let interpolateNulls = $( '#interpolateNulls' ).val();
				
				let dataTable = new google.visualization.DataTable( data );
				let wrapper = new google.visualization.ChartWrapper({
					chartType: 'AreaChart',
					dataTable: dataTable,
					options: {
						isStacked: 'relative',
						legend: 		{ position: 'top' },
						series: {
							0: { color: 'green' },
							1: { color: 'orange' },
							2: { color: 'crimson' },
						},
						title: 'Risk By Period (all dates)',
					},
					containerId: 'riskByPeriod'
				});

				wrapper.draw();
				
			}).fail( err => {
				$progressBar.progressbar( 'destroy' );
				$kpiContent.text( err.status + ' (' + err.responseText + ') ' );
				$kpiFooter.html( '' );
				throw new Error( err );
			});

		}
		//====================================================================================


				
		//================================================================================================ 
		function drawCharts() {
		//================================================================================================ 

			$( async function() {

				
				$( document ).tooltip();

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

							case 'mostRecent60':

								$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 60, 'day' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;

							case 'mostRecent90':

								$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 90, 'day' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;

							case 'mostRecent12Months':

								$( '#startDate' ).val( dayjs( minMaxDates.maxDate ).subtract( 12, 'month' ).format( 'MM/DD/YYYY' ) );
								$( '#endDate' ).val( dayjs( minMaxDates.maxDate ).format( 'MM/DD/YYYY' ) );
								break;

							default: 

								console.error( 'Unexpected date range encountered' );

						}

						reloadWidgets( customerID );

					}
				});

				$( '#branchSelectMenu' ).selectmenu({
					select: function() {
						reloadWidgets( customerID );
					}
				});

				const branches = getDistinctBranches( customerID );

				
				$( '#interpolateNulls' ).checkboxradio();

				$( '#summarizeBy' ).selectmenu({
					select: function( event, ui ) {
						
						getMonthlyTrend( customerID );
						
					}
				});



				//================================================================================================ 
				//================================================================================================ 
				const minMaxShoppedDates = await getMinMaxShoppedDates( customerID );

				$( "#startDate" ).datepicker({
					changeMonth: true,
					changeYear: true,
					maxDate: minMaxShoppedDates.maxDate,
					minDate: minMaxShoppedDates.minDate,
					onClose: function( startDate ) {

						let dateRange = $( '#dateRange' );
						dateRange[0].selectedIndex = 8;
						dateRange.selectmenu( 'refresh' );

						$( '#endDate' ).datepicker( 'option', 'minDate', startDate );
						reloadWidgets( customerID );
					},
				});

				$( "#endDate" ).datepicker({
					changeMonth: true,
					changeYear: true,
					maxDate: minMaxShoppedDates.maxDate,
					minDate: minMaxShoppedDates.minDate,
					onClose: function( endDate ) {

						let dateRange = $( '#dateRange' );
						dateRange[0].selectedIndex = 8;
						dateRange.selectmenu( 'refresh' );

						$( '#startDate' ).datepicker( 'option', 'maxDate', endDate );
						reloadWidgets( customerID );
					},
				});

				$( '#startDate' ).val( dayjs( minMaxShoppedDates.maxDate ).subtract( 12, 'month' ).format( 'MM/DD/YYYY' ) );
				$( '#endDate' ).val( dayjs( minMaxShoppedDates.maxDate ).format( 'MM/DD/YYYY' ) );
				//================================================================================================ 
				//================================================================================================ 

							
				

				var chartMaxDate 				= dayjs().toDate();
				var chartMinDate 				= dayjs().add( -<% =monthsOnCharts %>, 'months').toDate();
				var chartExplorerMinDate 	= dayjs( minMaxShoppedDates.minDate ).toDate();



				const colorPrimary 		= '#512DA8'  	// purple-ish
				const colorSecondary 	= '#F52C2C'		// red-ish
				const colorTertiary		= '#20B256'		// green-ish
				
			
				tgim_explorer = {
					axis: 'horizontal',
					keenInBounds: true,
					maxZoomIn: 7,
					zoomDelta: 1.1,
				}
				
				tgim_hAxis = {
					format: "<% =hAxisFormat %>",
					minorGridlines: {count: 0},
	         	viewWindow: {
		         	min: chartMinDate,
		         	max: chartMaxDate,
		         },
				}
	

				getAverageGrade( customerID );
				getTotalNaShops( customerID );
				getBranchesShopped( customerID );
				getSupervisorsShopped( customerID );
				getBankersShopped( customerID );
// 				getMonthlyTrend( customerID );
// 				getAverageScoreByBranchChart( customerID );
				getAverageScoreByBranchTable( customerID );
				getAverageScoreBySupervisorTable( customerID );
// 				getAverageScoreBySupervisorChart( customerID );
				getGradeSummary( customerID );
// 				getMostMissedQuestionCategoryByCustomer( customerID );
// 				getMostMissedQuestionByCustomer( customerID );
// 				getNaShopsByBanker( customerID );
				getRiskByShops( customerID );		
				getRiskByPeriod( customerID );		

				


				$( '.totalNaShops' ).on( 'click', function() {
					window.location.href = `customerMysteryShoppingShops.asp?customerID=${customerID}&dateRange=${ $( '#dateRange' ).val() }&startDate=${ $( '#startDate' ).val() }&endDate=${ $( '#endDate' ).val() }`;
				});


				$( '.branchesShopped' ).on( 'click', function() {

					if ( $( '#dateRange' ).val() ) {
						queryString = `&dateRange=${ $( '#dateRange' ).val() }`
					} else {
						queryString = `&startDate=${ $( '#startDate' ).val() }&endDate=${ $( '#endDate' ).val() }`
					}
					
					window.location.href = `customerMysteryShoppingBranches.asp?customerID=${customerID}${queryString}`;
					
				});


				$( '.supervisorsShopped' ).on( 'click', function() {
					if ( $( '#dateRange' ).val() ) {
						queryString = `&dateRange=${ $( '#dateRange' ).val() }`
					} else {
						queryString = `&startDate=${ $( '#startDate' ).val() }&endDate=${ $( '#endDate' ).val() }`
					}
					window.location.href = `customerMysteryShoppingSupervisors.asp?customerID=${customerID}${queryString}`;
				});


				$( '.bankersShopped' ).on( 'click', function() {
					
					if ( $( '#dateRange' ).val() ) {
						queryString = `&dateRange=${ $( '#dateRange' ).val() }`
					} else {
						queryString = `&startDate=${ $( '#startDate' ).val() }&endDate=${ $( '#endDate' ).val() }`
					}
					window.location.href = `customerMysteryShoppingBankers.asp?customerID=${customerID}${queryString}`;
			
				});
				
				
				$( '#interpolateNulls' ).on( 'change', function() {
					getMonthlyTrend( customerID );
				});

				
															
			});
			
		}
		//================================================================================================ 

		
		window.onload = function() {
			if ( document.getElementById('mdl-spinner') ) {
				document.getElementById('mdl-spinner').classList.remove('is-active');	
			}
		}
				
	</script>		 

	<style>
		/* prevent Google Chart Tooltips from flashing... */
		svg > g:last-child > g:last-child { pointer-events: none }
		div.google-visualization-tooltip { pointer-events: none }

		#tgim_progressbar .ui-progressbar-value {
			background-color: #ccc;
		}
	
		.page-content {
			padding-top: 1rem;
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
/* 			float: right; */
			font-family: Arial; 
			font-size: 50px; 
			font-weight: bold; 
			line-height: 100%;
			stroke: none; 
		}
		
		.kpiFooter {
			display: table-cell;
			float: right;
			font-family: Arial; 
			stroke: none; 
			margin-right: 15px;
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
		
		table.control {
			margin-left: auto;
			margin-right: auto;
		}
		
		table.control th {
			text-align: right;
		}
		
		table.control td {
			text-align: left;
		}
		
		
		.dataTableTitle {
			color: #848484;
			text-anchor: start;
			font-family: Roboto;
			font-size: 16px;
			stroke: none;
			stroke-width: 0;
			fill: rgb( 117, 117, 117 );
			margin: 10px 0px 15px 0px;
			text-align: center; 
			width: 100%;
			
		}
		
		#summarizeBy-button {
			float: right;
			z-index: 10;
		}

		#interpolateNullsLabel {
			float: right !important;
			z-index: 10;
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
			
			<div class="mdl-grid">

				<div class="mdl-cell mdl-cell--12-col controls">
	
					<!-- #include file="includes/mysteryShoppingShopDates.asp" -->

				</div><!-- Controls -->

			</div>

			<!-- row one of charts -->
			<div class="mdl-grid">

				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">

					<div style="margin-top: 10px; margin-right: 10px;">					
						<select name="summarizeBy" id="summarizeBy" style="float: right;">
							<option value="day">Summarize By Day</option>
							<option value="week">Summarize By Week</option>
							<option value="month" selected>Summarize By Month</option>
							<option value="quarter">Summarize By Quarter</option>
						</select>

						<label id="interpolateNullsLabel" for="interpolateNulls" style="float: left;" title="Enabling this option connects data points with a line even if there are periods between them without a value.">Fill Gaps</label>
						<input type="checkbox" name="interpolateNulls" id="interpolateNulls" style="float: right;">
						
					</div>
					<div>
						<div id="monthlyTrend_progressbar"></div>
						<div id="monthlyTrend" style="position: relative; height: 380px;" ></div>
					</div>
				</div>


				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="riskByShops_progressbar"></div>
					<div id="riskByShops" style="height: 400px;"></div>
				</div><!-- Average Score By Branch (Chart) -->
			
			
			
			
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="riskByPeriod_progressbar"></div>
					<div id="riskByPeriod" style="height: 400px;"></div>
				</div><!-- riskByPeriod (Chart) -->


			</div><!-- row one of charts -->
			
			
			<!-- Controls and KPIs -->	
			<div class="mdl-grid">
	


				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp branchesShopped">
					<div class="kpiTitle">Branches: Shopped* / Total</div>
					<div class="kpiContent">
						<div id="branchesShopped_progressbar"></div>
						<span class="kpiValue"></span>
					</div>
					<div class="kpiFooter">* Excludes N/A Shops</div>
				</div><!-- Brances Shopped -->

		
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp supervisorsShopped">
					<div class="kpiTitle">Supervisors: Shopped* / Total</div>
					<div class="kpiContent">
						<div id="supervisorsShopped_progressbar"></div>
						<span class="kpiValue"></span>
					</div>
					<div class="kpiFooter">* Excludes N/A Shops</div>
				</div><!-- Supervisors Shopped -->

		
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp bankersShopped">
					<div class="kpiTitle">Bankers: Shopped* / Total</div>
					<div class="kpiContent">
						<div id="bankersShopped_progressbar"></div>
						<span class="kpiValue"></span>
					</div>
					<div class="kpiFooter">* Excludes N/A Shops</div>
				</div><!-- Bankers Shopped -->

		
			</div><!-- Controls and KPIs -->				


			<!-- More KPIs -->
			<div class="mdl-grid">


				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp averageGrade">
					<div class="kpiTitle">Average Shop Grade</div>
					<div class="kpiContent">
						<div id="averageGrade_progressbar"></div>
						<span class="kpiValue"></span>
					</div>
					<div class="kpiFooter"></div>
				</div><!-- Average Grade -->

				

				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp totalNaShops">
					<div class="kpiTitle">Shops: N/A Shops / Total</div>
					<div class="kpiContent">
						<div id="totalNaShops_progressbar"></div>
						<span class="kpiValue"></span>
					</div>
					<div class="kpiFooter"></div>
				</div><!-- Total N/A Shops -->

				
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp mostMissedQuestionCategory">
					<div class="kpiTitle">Most Missed Question Category</div>
					<div class="kpiContent">
						<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">engineering</span>
						<span style="margin-left: 15px;">Under Construction</span>
						<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">construction</span>
						<div id="mostMissedQuestionCategory_progressbar"></div>
						<span class="kpiValue" style="font-size: 16px;"></span>
					</div>
					<div class="kpiFooter"></div>
				</div><!-- Most Missed Question Category -->

				
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp mostMissedQuestion">
					<div class="kpiTitle">Most Missed Question</div>
					<div class="kpiContent">
						<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">engineering</span>
						<span style="margin-left: 15px;">Under Construction</span>
						<span class="material-icons" style="margin-left: 15px; color: #eb680b; font-size: 48px;">construction</span>
						<div id="mostMissedQuestion_progressbar"></div>
						<span class="kpiValue" style="font-size: 16px;"></span>
					</div>
					<div class="kpiFooter"></div>
				</div><!-- Most Missed Question -->

				
			</div><!-- More KPIs -->
			
			
			<!-- Grade Pie Chart -->
			<div class="mdl-grid">
				
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="gradePie_progressbar"></div>
					<div id="gradePie" style="height: 400px;"></div>
				</div><!-- Grade Pie Chart -->


				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div id="naShopsByBanker_progressbar"></div>
					<div id="naShopsByBanker" style="height: 400px;"></div>
				</div><!-- Grade Pie Chart -->




			</div>
						
			

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