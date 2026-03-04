<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/customerTitle.asp" -->
<!-- #include file="../includes/jsonDataTable.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<!-- #include file="includes/getAccountHolderAddenda.asp" -->
<% 
call checkPageAccess(43)

customerID = request.querystring("id")





title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)


'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->

%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->


	<link rel="stylesheet" href="../datatables/DataTables.css" />
	<link rel="stylesheet" href="https://cdn.datatables.net/fixedheader/3.1.7/css/fixedHeader.dataTables.min.css" />


	<script src="../jQuery/jquery-3.5.1.js"></script>

	<script src="../DataTables/datatables.js"></script>
	<script src="https://cdn.datatables.net/fixedheader/3.1.7/js/dataTables.fixedHeader.min.js"></script>

	<script src="../moment.min.js"></script>

	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		//-- ------------------------------------------------------------------ -->
		window.addEventListener('load', function() {
		//-- ------------------------------------------------------------------ -->
			
			var searchButton = document.getElementById('searchButton');
			if (searchButton) {
				searchButton.addEventListener('click', function() {
					var currentLabel = this.textContent;
					var table = $('#cNoteDataTable').DataTable();
					if ( currentLabel.trim() == 'Show All Prospects' ) {
						table.column(0).search('').draw();
						searchButton.textContent = 'Hide Non-💯 Prospects';
					} else {
						table.column(0).search( '💯', true, false ).draw();
						searchButton.textContent = 'Show All Prospects';
					}
				});
				
			}
		
		});


		
		const customerID = <% =customerID %>;
		
		
		$(document).ready(function() {

			var table = $('#cNoteDataTable')
				.on( 'draw.dt', function() {

					

					var cNoteMoney = $('.cNoteMoney');
					if ( cNoteMoney ) {
						for (i = 0; i < cNoteMoney.length; ++i) {
							MakeNegativeValueRed(cNoteMoney[i]);
						}
					}
					
				})
				.on( 'click', 'tbody td.loans', function(e) {
					e.preventDefault();
					const branchDescription = this.closest('tr').id;
					alert('Loans for branch: ' + branchDescription);
// 					window.location.href = '/cProfit.officerSummary.asp?customerID=' + customerID + '&officerName=' + officerName + '&ctgy=loans';
				})
				.on( 'click', 'tbody td.deposits', function(e) {
					e.preventDefault();
					const branchDescription = this.closest('tr').id;
					alert('Deposits for branch: ' + branchDescription);
// 					window.location.href = '/cProfit.officerSummary.asp?customerID=' + customerID + '&officerName=' + officerName + '&ctgy=deposits';
				})
				.on( 'click', 'tbody td.other', function(e) {
					e.preventDefault();
					const branchDescription = this.closest('tr').id;
					alert('Other for branch: ' + branchDescription);
// 					window.location.href = '/cProfit.officerSummary.asp?customerID=' + customerID + '&officerName=' + officerName + '&ctgy=other';
				})
				.on( 'click', 'tbody td.total', function(e) {
					e.preventDefault();
					const branchDescription = this.closest('tr').id;
					alert('Total for branch: ' + branchDescription);
// 					window.location.href = '/cProfit.officerSummary.asp?customerID=' + customerID + '&officerName=' + officerName + '&ctgy=total';
				})
				.DataTable({
					paging: true,
					info: true,
					searching: true,
					scrollX: true,
					processing: true,
					serverSide: false,
					ajax: {url: '/cProfit/ajax/prospects.asp',
						type: 'post',
						data: {customerID: customerID}
					},
					columnDefs: [
						{targets: 'top100Ind',					data: 'top100Ind', 				className: 'dt-body-center'},
						{targets: 'businessName',				data: 'businessName', 			className: 'dt-body-left'},
						{targets: 'industry',					data: 'industry', 				className: 'industry dt-body-left'},
						{targets: 'fullName',					data: 'fullName', 				className: 'dt-body-left'},
						{targets: 'give1Date',					data: 'give1Date', 				className: 'dt-body-center'},
						{targets: 'give2Date',					data: 'give2Date', 				className: 'dt-body-center'},
						{targets: 'give3Date',					data: 'give3Date', 				className: 'dt-body-center'},
						{targets: 'handraiseInd',				data: 'handraiseInd', 			className: 'dt-body-center'},
						{targets: 'call1Ind',					data: 'call1Ind', 				className: 'dt-body-center'},
						{targets: 'meeting1Scheduled',		data: 'meeting1Scheduled', 	className: 'dt-body-center'},
						{targets: 'meeting1Completed',		data: 'meeting1Completed', 	className: 'dt-body-center'},
						{targets: 'ace1',							data: 'ace1', 						className: 'dt-body-center'},
						{targets: 'ace2',							data: 'ace2', 						className: 'dt-body-center'},
						{targets: 'ace3',							data: 'ace3', 						className: 'dt-body-center'},
						{targets: 'ace4',							data: 'ace4', 						className: 'dt-body-center'},
						{targets: 'ace5',							data: 'ace5', 						className: 'dt-body-center'},
						{targets: 'dealPotential',				data: 'dealPotential', 			className: 'dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'dealClosedInd',				data: 'dealClosedInd', 			className: 'dt-body-center'},
						{targets: 'dealValue',					data: 'dealValue', 				className: 'dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'crossSalesCount',			data: 'crossSalesCount', 		className: 'dt-body-center'},
						{targets: 'funnelAmount',				data: 'funnelAmount', 			className: 'dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'weightedFunnelAmount',	data: 'weightedFunnelAmount', className: 'dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')}
					],
					order: [[ 0, 'desc' ], [ 7, 'desc' ], [ 4, 'desc' ], [ 5, 'desc'], [ 6, 'desc' ]],
								searchCols: [
									{ search: '💯' },
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
									null,
								],
					footerCallback: function( row, data, start, end, display ) {
						
						var api = this.api(), data;
						
						// remove any formatting...
						var intVal = function ( i ) {
							return typeof i === 'string' ?
								i.replace(/[\$,]/g, '')*1 :
								typeof i === 'number' ?
									i : 0;
						};

						var top100Count = api
							.column( 0 )
							.data()
							.reduce( function ( a,b ) {
								if ( b !== '' ) {
									return a + 1;
								} else {
									return a;
								}
							}, 0 );
							
						var handRaiseCount = api
							.column( 7 )
							.data()
							.reduce( function ( a,b ) {
								if ( b !== '' ) {
									return a + 1;
								} else {
									return a;
								}
							}, 0 );
							
						var call1Count = api
							.column( 8 )
							.data()
							.reduce( function ( a,b ) {
								if ( b !== '' ) {
									return a + 1;
								} else {
									return a;
								}
							}, 0 );
							
						var mtg1SchedCount = api
							.column( 9 )
							.data()
							.reduce( function ( a,b ) {
								if ( b !== '' ) {
									return a + 1;
								} else {
									return a;
								}
							}, 0 );
							
						var mtg1ComplCount = api
							.column( 10 )
							.data()
							.reduce( function ( a,b ) {
								if ( b !== '' ) {
									return a + 1;
								} else {
									return a;
								}
							}, 0 );
							
// 						var ace1Count = api
// 							.column( 11 )
// 							.data()
// 							.reduce( function ( a,b ) {
// 								if ( b !== '' ) {
// 									return a + 1;
// 								} else {
// 									return a;
// 								}
// 							}, 0 );
// 							
// 						var ace2Count = api
// 							.column( 12 )
// 							.data()
// 							.reduce( function ( a,b ) {
// 								if ( b !== '' ) {
// 									return a + 1;
// 								} else {
// 									return a;
// 								}
// 							}, 0 );
// 							
// 						var ace3Count = api
// 							.column( 13 )
// 							.data()
// 							.reduce( function ( a,b ) {
// 								if ( b !== '' ) {
// 									return a + 1;
// 								} else {
// 									return a;
// 								}
// 							}, 0 );
// 							
// 						var ace4Count = api
// 							.column( 14 )
// 							.data()
// 							.reduce( function ( a,b ) {
// 								if ( b !== '' ) {
// 									return a + 1;
// 								} else {
// 									return a;
// 								}
// 							}, 0 );
// 							
// 						var ace5Count = api
// 							.column( 15 )
// 							.data()
// 							.reduce( function ( a,b ) {
// 								if ( b !== '' ) {
// 									return a + 1;
// 								} else {
// 									return a;
// 								}
// 							}, 0 );
							
						var dealPotentialTotal = api
							.column( 16 )
							.data()
							.reduce( function ( a,b ) {
								return intVal(a) + intVal(b);
							}, 0 );
							
						var dealClosedCount = api
							.column( 17 )
							.data()
							.reduce( function ( a,b ) {
								if ( b !== '' ) {
									return a + 1;
								} else {
									return a;
								}
							}, 0 );
							
						var dealValueTotal = api
							.column( 18 )
							.data()
							.reduce( function ( a,b ) {
								return intVal(a) + intVal(b);
							}, 0 );
							
						var crossSalesTotal = api
							.column( 19 )
							.data()
							.reduce( function ( a,b ) {
								return intVal(a) + intVal(b);
							}, 0 );
							
						var funnelTotal = api
							.column( 20 )
							.data()
							.reduce( function ( a,b ) {
								return intVal(a) + intVal(b);
							}, 0 );
							
						var weightedFunnelTotal = api
							.column( 21 )
							.data()
							.reduce( function ( a,b ) {
								return intVal(a) + intVal(b);
							}, 0 );
							
						
						$( api.column( 7 ).footer() ).html(
							formatNumber( handRaiseCount ) + '<br>&nbsp;'
						);
						
						$( api.column( 8 ).footer() ).html(
							formatNumber( call1Count ) + '<br>&nbsp;'
						);
						
						$( api.column( 9 ).footer() ).html(
							formatNumber( mtg1SchedCount ) + '<br>&nbsp;'
						);
						
						$( api.column( 10 ).footer() ).html(
							formatNumber( mtg1ComplCount ) + '<br>&nbsp;'
						);
						
// 						$( api.column( 11 ).footer() ).html(
// 							formatNumber(ace1Count) + '<br>&nbsp;'
// 						);
// 						
// 						$( api.column( 12 ).footer() ).html(
// 							formatNumber( ace2Count ) + '<br>&nbsp;'
// 						);
// 						
// 						$( api.column( 13 ).footer() ).html(
// 							formatNumber( ace3Count ) + '<br>&nbsp;'
// 						);
// 						
// 						$( api.column( 14 ).footer() ).html(
// 							formatNumber( ace4Count ) + '<br>&nbsp;'
// 						);
// 						
// 						$( api.column( 15 ).footer() ).html(
// 							formatNumber( ace5Count ) + '<br>&nbsp;'
// 						);
						
						if ( top100Count != 0 ) {
							const dealPotentialAvg = Math.floor(dealPotentialTotal / top100Count);
							$( api.column( 16 ).footer() ).html(
									formatter.format(dealPotentialTotal) +'<br>'+ formatter.format(dealPotentialAvg)
							);
						}
						
						$( api.column( 17 ).footer() ).html(
							formatNumber( dealClosedCount ) + '<br>&nbsp;'
						);
						
						if ( dealClosedCount != 0 ) {
							const dealValueAvg = Math.floor(dealValueTotal / dealClosedCount);
							$( api.column( 18 ).footer() ).html(
								formatter.format(dealValueTotal) +'<br>'+ formatter.format(dealValueAvg)
							);
						}
						
						if ( dealClosedCount != 0 ) {
							const crossSalesAvg = Math.round(crossSalesTotal / dealClosedCount * 10) / 10;
							$( api.column( 19 ).footer() ).html(
								formatNumber(crossSalesTotal) +'<br>'+ formatNumber(crossSalesAvg)
							);
						}
						
						const dealsNotClosedCount = top100Count - dealClosedCount;
						
						if ( dealsNotClosedCount != 0 ) {
							const funnelAvg = Math.floor(funnelTotal / dealsNotClosedCount);
							$( api.column( 20 ).footer() ).html(
								formatter.format(funnelTotal) +'<br>&nbsp;'
// 								+ formatter.format(funnelAvg)
							);
						}
						
						if ( dealsNotClosedCount != 0 ) {
							const weightedFunnelAvg = Math.floor(weightedFunnelTotal / dealsNotClosedCount);
							$( api.column( 21 ).footer() ).html(
								formatter.format(weightedFunnelTotal) +'<br>&nbsp;'
// 								+ formatter.format(weightedFunnelAvg)
							);
						}
												
					},
				});

			});
			
			const formatter = new Intl.NumberFormat('en-US', {
			  style: 'currency',
			  currency: 'USD',
			  minimumFractionDigits: 0
			}); 

			function formatNumber(num) {
				return num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
			}			
			
// 			function formatMoney(number, decPlaces, decSep, thouSep) {
// 
// 				decPlaces = isNaN(decPlaces = Math.abs(decPlaces)) ? 2 : decPlaces,
// 				decSep = typeof decSep === "undefined" ? "." : decSep;
// 				thouSep = typeof thouSep === "undefined" ? "," : thouSep;
// 
// 				var sign = number < 0 ? "-" : "";
// 				var i = String(parseInt(number = Math.abs(Number(number) || 0).toFixed(decPlaces)));
// 				var j = (j = i.length) > 3 ? j % 3 : 0;
// 			
// 				return sign +
// 					(j ? i.substr(0, j) + thouSep : "") +
// 					i.substr(j).replace(/(\decSep{3})(?=\decSep)/g, "$1" + thouSep) +
// 					(decPlaces ? decSep + Math.abs(number - i).toFixed(decPlaces).slice(2) : "");
// 
// 			}
			
			
	</script>

	<style>
		
		.reportTitle {
			text-align: center;
			font-size: large;
			font-weight: bold;
		}
		
		td.accountHolderNumber, td.accountHolderName, td.addenda, td.industry {
			max-width: 180px;
			text-overflow: ellipsis;
			white-space: nowrap;
			overflow: hidden;		
		}
				
		table.dataTable tbody tr:hover {
			cursor: pointer;
		}
		
		table.dataTable tbody td.cNoteCM:hover {
			cursor: context-menu;
		}
		
		table.dataTable thead th.leftGroupEdge {
			border-left: solid #111 1px;
		}
		
	</style>

	
</head>

<body>

<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
	<header class="mdl-layout__header">
		<div class="mdl-layout__header-row">

			<!-- Title -->
			<span class="mdl-layout-title"><% =title %></span>
			<!-- Add spacer, to align navigation to the right -->
			<div class="mdl-layout-spacer"></div>
		
			<!-- #include file="../includes/mdlLayoutNavLarge.asp" -->

		</div>
		<!-- #include file="../includes/customerTabs.asp" -->
  </header>
  
  
<!--
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>
-->

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
				
			<!-- Your content goes here -->

			<!-- SNACKBAR -->
			<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
			    <div class="mdl-snackbar__text"></div>
			    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
			</div>


			<!-- #include file="includes/accountHolderPopup.asp" -->


			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--9-col reportTitle">Prospects Overview<br><% =subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--11-col mdl-shadow--2dp" style="padding: 15px;">
					<div style="float: right; display: inline-block; margin-bottom: 15px;">
						<button id="searchButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
							Show All Prospects
						</button>					
					</div>
					<br>
					<table id="cNoteDataTable" class="compact display nowrap">
						<thead>
							<tr>	
								<th class="top100Ind" 								rowspan="2"><span style='font-size:24px;'>&#128175;</span></th>
								<th class="businessName" 							rowspan="2">Organization</th>
								<th class="industry	" 								rowspan="2">Industry</th>
								<th class="fullName" 								rowspan="2">CEO</th>
								<th class="leftGroupEdge" 							colspan="3">Gives Date Sent</th>
								<th class="handraiseInd leftGroupEdge" 		rowspan="2"><i class="material-icons">pan_tool</i></th>
								<th class="call1Ind" 								rowspan="2">CEO<br>Set<br>Appt</th>
								<th class="leftGroupEdge" 							colspan="2">1st Mtg</th>
								<th class="leftGroupEdge" 							colspan="5">Aces</th>
								<th class="leftGroupEdge" 							colspan="4">Deal</th>
								<th class="leftGroupEdge" 							colspan="2">Sales</th>
							</tr>
							<tr>
								<th class="give1Date leftGroupEdge">#1</th>
								<th class="give2Date">#2</th>
								<th class="give3Date">#3</th>
								<th class="meeting1Scheduled leftGroupEdge"><i class="material-icons">insert_invitation</i></th>
								<th class="meeting1Completed"><i class="material-icons">event_available</i></th>
								<th class="ace1 leftGroupEdge" title="Pains">1</th>
								<th class="ace2" title="Money">2</th>
								<th class="ace3" title="Competition">3</th>
								<th class="ace4" title="Decision Making &amp; Evaluation Process">4</th>
								<th class="ace5" title="Commitment">5</th>
								<th class="dealPotential leftGroupEdge">Potential</th>
								<th class="dealClosedInd">Closed</th>
								<th class="dealValue">Value</th>
								<th class="crossSalesCount ">Cross Sales</th>
								<th class="funnelAmount leftGroupEdge" title="Sum of 20% of Potential for each Ace obtained">Funnel</th>
								<th class="weightedFunnelAmount" title="$0 until at least 3 Aces are obtained and then is the sum of 20% of Potential for each Ace obtained">Weighted Funnel</th>
							</tr>
						</thead>
						<tfoot>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th colspan="3" style="text-align: right;">Total:<br>Average:</th>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th></th>
							<th style="text-align: right;"></th>
							<th></th>
							<th style="text-align: right;"></th>
							<th></th>
							<th style="text-align: right;"></th>
							<th style="text-align: right;"></th>
						</tfoot>
					</table>

				</div>
		
				<div class="mdl-layout-spacer"></div>
		
			</div>


		</div>
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>