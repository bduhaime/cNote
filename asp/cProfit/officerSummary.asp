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
<!-- #include file="includes/getDrilldownParameters.asp" -->
<% 
call checkPageAccess(43)

customerID = request.querystring("customerID")
if ( len(customerID) <= 0  OR  not isNumeric(customerID) ) then 
	dbug("customerID is missing or invalid: " & customerID & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
end if 


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
	<link rel="stylesheet" href="cProfitStyle.css" />


	<script src="../jQuery/jquery-3.5.1.js"></script>

	<script src="../DataTables/datatables.js"></script>
	<script src="https://cdn.datatables.net/fixedheader/3.1.7/js/dataTables.fixedHeader.min.js"></script>

	<script src="../moment.min.js"></script>

	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		
		const customerID 				= <% =customerID %>;
		const centile 					= <% =centile %>;
		const decile					= <% =decile %>;
		const ninetyNine				= <% =ninetyNine %>;
		const profitability 			= <% =profitability %>;
		const accountHolderGrade 	= <% =accountHolderGrade %>;
		const flagID					= <% =flagID %>;
		const allStar					= <% =allStar %>;

		var drillDownParms = {
			account: <% =account %>,
			accountHolder: <% =accountHolder %>,
			branch: <% =branch %>,
			officer: <% =officer %>,
			product: <% =product %>,
		}
		
		
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
				.on( 'contextmenu', 'tbody tr', function(event) {
					const officer = this.id;
					BuildContextMenu( customerID, 'officer', officer, drillDownParms, event );
				})
				.DataTable({
					paging: true,
					info: true,
					searching: true,
					processing: true,
					serverSide: false,
					ajax: {url: '/cProfit/ajax/officers.asp',
						type: 'post',
						data: {
							customerID: customerID,
							centile: centile,
							decile: decile,
							ninetyNine: ninetyNine,
							profitability: profitability,
							accountHolderGrade: accountHolderGrade,
							flagID: flagID,
							allStar: allStar,
							account: drillDownParms.account,
							accountHolder: drillDownParms.accountHolder,
							branch: drillDownParms.branch,
							officer: drillDownParms.officer,
							product: drillDownParms.product,
						}
					},
					columnDefs: [
						{targets: 'officerName', 		data: 'officerName', 		className: 'dt-body-left'},
						{targets: 'loanCount',			data: 'loanCount',			className: 'loans dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0)},
						{targets: 'loanBalance',		data: 'loanBalance',			className: 'loans cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'loanProfit',			data: 'loanProfit',			className: 'loans cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'loanInterest',		data: 'loanInterest',		className: 'loans dt-body-right'},
						{targets: 'depositCount',		data: 'depositCount',		className: 'deposits dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0)},
						{targets: 'depositBalance',	data: 'depositBalance',		className: 'deposits cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'depositProfit',		data: 'depositProfit',		className: 'deposits cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'depositInterest',	data: 'depositInterest',	className: 'deposits dt-body-right'},
						{targets: 'otherCount',			data: 'otherCount',			className: 'other dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0)},
						{targets: 'otherProfit',		data: 'otherProfit',			className: 'other cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'totalCount',			data: 'totalCount',			className: 'total dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0)},
						{targets: 'totaBalance',		data: 'totaBalance',			className: 'total cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'totalProfit',		data: 'totalProfit',			className: 'total cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')}
					],
					order: [[ 0, 'asc' ]],
					footerCallback: function( row, data, start, end, display ) {
						
						var api = this.api(), data;
						
						// remove any formatting...
						var intVal = function ( i ) {
							return typeof i === 'string' ?
								i.replace(/[\$,]/g, '')*1 :
								typeof i === 'number' ?
									i : 0;
						};

						var decVal = function ( i ) {
							return typeof i === 'string' ?
								i.replace(/[\%,]/g, '')*1 :
								typeof i === 'number' ?
									i : 0.0000;
						};

						const rowCount = api.data().count();
						
						var loanCountTotal 		= api.column( 1 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var loanBalanceTotal 	= api.column( 2 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var loanProfitTotal 		= api.column( 3 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var loanIntTotal 			= api.column( 4 ).data().reduce( function ( a,b ) { return decVal(a) + decVal(b); }, 0 );
						var depositCountTotal 	= api.column( 5 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var depositBalanceTotal = api.column( 6 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var depositProfitTotal 	= api.column( 7 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var depositIntTotal 		= api.column( 8 ).data().reduce( function ( a,b ) { return decVal(a) + decVal(b); }, 0 );
						var otherCountTotal 		= api.column( 9 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var otherProfitTotal 	= api.column( 10 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var totalCountTotal 		= api.column( 11 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var totalBalanceTotal 	= api.column( 12 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var totalProfitTotal 	= api.column( 13 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );

						if ( rowCount != 0 ) {

							const loanCountAvg = Math.floor(loanCountTotal / rowCount);
							$( api.column( 1 ).footer() ).html( formatNumber(loanCountAvg) );

							const loanBalanceAvg = Math.floor(loanBalanceTotal / rowCount);
							$( api.column( 2 ).footer() ).html( formatter.format(loanBalanceAvg) );

							const loanProfitAvg = Math.floor(loanProfitTotal / rowCount);
							$( api.column( 3 ).footer() ).html( formatter.format(loanProfitAvg) );

							const loanIntAvg = loanIntTotal / rowCount;
							$( api.column( 4 ).footer() ).html( loanIntAvg.toFixed(4)+'%' );



							const depositCountAvg = Math.floor(depositCountTotal / rowCount);
							$( api.column( 5 ).footer() ).html( formatNumber(depositCountAvg) );

							const depositBalanceAvg = Math.floor(depositBalanceTotal / rowCount);
							$( api.column( 6 ).footer() ).html( formatter.format(depositBalanceAvg) );

							const depositProfitAvg = Math.floor(depositProfitTotal / rowCount);
							$( api.column( 7 ).footer() ).html( formatter.format(depositProfitAvg) );

							const depositIntAvg = depositIntTotal / rowCount;
							$( api.column( 8 ).footer() ).html( depositIntAvg.toFixed(4)+'%' );



							const otherCountAvg = Math.floor(otherCountTotal / rowCount);
							$( api.column( 9 ).footer() ).html( formatNumber(otherCountAvg) );

							const otherProfitAvg = Math.floor(otherProfitTotal / rowCount);
							$( api.column( 10 ).footer() ).html( formatter.format(otherProfitAvg) );



							const totalCountAvg = Math.floor(totalCountTotal / rowCount);
							$( api.column( 11 ).footer() ).html( formatNumber(totalCountAvg) );

							const totalBalanceAvg = Math.floor(totalBalanceTotal / rowCount);
							$( api.column( 12 ).footer() ).html( formatter.format(totalBalanceAvg) );

							const totalProfitAvg = Math.floor(totalProfitTotal / rowCount);
							$( api.column( 13 ).footer() ).html( formatter.format(totalProfitAvg) );

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
			
			
	</script>

	
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
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>

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
				<div class="mdl-cell mdl-cell--9-col reportTitle">Officer Overview<br><% =subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--11-col mdl-shadow--2dp" style="padding: 15px;">

					<table id="cNoteDataTable" class="compact display">
						<thead>
							<tr>
								<th class="officerName" rowspan="2">Officer Name</th>
								<th class="leftGroupEdge" colspan="4">Loans</th>
								<th class="leftGroupEdge" colspan="4">Deposits</th>
								<th class="leftGroupEdge" colspan="2">Other</th>
								<th class="leftGroupEdge" colspan="3">Total</th>
							</tr>
							<tr>
								<th class="loanCount leftGroupEdge">Count</th>
								<th class="loanBalance">Balance</th>
								<th class="loanProfit">Profit</th>
								<th class="loanInterest">Int.</th>
								<th class="depositCount leftGroupEdge">Count</th>
								<th class="depositBalance">Balance</th>
								<th class="depositProfit">Profit</th>
								<th class="depositInterest">Int.</th>
								<th class="otherCount leftGroupEdge">Count</th>
								<th class="otherProfit">Profit</th>
								<th class="totalCount leftGroupEdge">Count</th>
								<th class="totaBalance">Balance</th>
								<th class="totalProfit">Profit</th>
							</tr>
						</thead>
						<tfoot>
							<tr>
								<th class="alignRight">Average</th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
								<th class="alignRight"></th>
							</tr>
						</tfoot>
					</table>

				</div>
		
				<div class="mdl-layout-spacer"></div>
		
			</div>


		</div>

		<!-- #include file="includes/contextMenu.asp" -->
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>