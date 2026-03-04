<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->
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

		<!-- #include file="includes/getAllAccountHolders.js" -->
		
		const customerID 				= <% =customerID %>;
		const centile 					= <% =centile %>;
		const decile					= <% =decile %>;
		const ninetyNine				= <% =ninetyNine %>;
		const profitability 			= <% =profitability %>;
		const accountHolderGrade 	= <% =accountHolderGrade %>;
		const flagID					= <% =flagID %>;
		const allStar					= <% =allStar %>;
		const service					= <% =service %>;

		var drillDownParms = {
			account: <% =account %>,
			accountHolder: <% =accountHolder %>,
			branch: <% =branch %>,
			officer: <% =officer %>,
			product: <% =product %>,
		}


		//-- ------------------------------------------------------------------ -->
		window.addEventListener('load', function() {
		//-- ------------------------------------------------------------------ -->
			
			var searchButton = document.getElementById('searchButton');
			if (searchButton) {
				searchButton.addEventListener('click', function() {
					var currentLabel = this.textContent;
					var table = $('#cNoteTable').DataTable();
					if ( currentLabel.trim() == 'Show All Products' ) {
						table.column(3).search('').draw();
						searchButton.textContent = 'Hide Unowned Products';
					} else {
						table.column(3).search( '[0-9]', true, false ).draw();
						searchButton.textContent = 'Show All Products';
					}
				});
				
			}

			window.onkeyup = function(e) {
				if ( e.keyCode === 27 ) {
					$('.context-menu').removeClass('context-menu--active').off();
				}
			}
			
			document.addEventListener('click', function() {
				$('.context-menu').removeClass('context-menu--active').off();
			});
										
		
		});


		$(document).ready(function() {

			var table = $('#cNoteTable')
				.on( 'draw.dt', function() {
					var cNoteMoney = $('.cNoteMoney');
					if ( cNoteMoney ) {
						for (i = 0; i < cNoteMoney.length; ++i) {
							MakeNegativeValueRed(cNoteMoney[i]);
						}
					}
				})
				.on( 'init.dt', function() {
					table.column(3).search( '[0-9]', true, false ).draw();
				})
				.on( 'contextmenu', 'tbody tr', function(event) {
					const product = this.id;
					BuildContextMenu( customerID, 'product', product, drillDownParms, event );
				})
				.DataTable({
					paging: true,
					info: true,
					searching: true,
// 					deferRender: true,
// 					deferLoading: 100,
					ajax: {url: '/cProfit/ajax/products.asp',
						data: {
							customerID: customerID,
							centile: centile,
							decile: decile,
							ninetyNine: ninetyNine,
							profitability: profitability,
							accountHolderGrade: accountHolderGrade,
							flagID: flagID,
							service: service,
							allStar: allStar,
							account: drillDownParms.account,
							accountHolder: drillDownParms.accountHolder,
							branch: drillDownParms.branch,
							officer: drillDownParms.officer,
							product: drillDownParms.product,
						}
					},
					columnDefs: [
						{targets: 'ldo', 						data: 'ldo', 						className: 'dt-body-left'},
						{targets: 'productCode',			data: 'productCode',				className: 'dt-body-left'},
						{targets: 'productDescription',	data: 'productDescription',	className: 'productDescription dt-body-left'},
						{targets: 'accounts',				data: 'accounts', 				className: 'dt-body-right'},
						{targets: 'profit', 					data: 'profit', 					className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'balance', 				data: 'balance', 					className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'netInterestIncome', 	data: 'netInterestIncome', 	className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'nonInterestIncome', 	data: 'nonInterestIncome', 	className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'nonInterestExpense', 	data: 'nonInterestExpense', 	className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
					],
					order: [[ 4, 'desc' ]],
					footerCallback: function( row, data, start, end, display ) {
						
							var api = this.api(), data;
						
						// remove any formatting...
						 var intVal = function ( i ) {
		                return typeof i === 'string' ?
		                    i.replace(/[\$,]/g, '')*1 :
		                    typeof i === 'number' ?
		                        i : 0;
		            };
						
						// total over all pages...
						accountTotal = api
							.column( 3 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 3 ).footer() ).html( accountTotal );
						
						profitTotal = api
							.column( 4 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 4 ).footer() ).html( 
							$.fn.dataTable.render.number(',', '.', 0, '$').display( profitTotal )
						);
						
						balanceTotal = api
							.column( 5 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 5 ).footer() ).html( 
							$.fn.dataTable.render.number(',', '.', 0, '$').display( balanceTotal )
						);
						
						netIntIncTotal = api
							.column( 6 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 6 ).footer() ).html( 
							$.fn.dataTable.render.number(',', '.', 0, '$').display( netIntIncTotal )
						);
						
						nonIntIncTotal = api
							.column( 7 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 7 ).footer() ).html( 
							$.fn.dataTable.render.number(',', '.', 0, '$').display( nonIntIncTotal )
						);
						
						nonIntExpTotal = api
							.column( 8 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 8 ).footer() ).html( 
							$.fn.dataTable.render.number(',', '.', 0, '$').display( nonIntExpTotal )
						);
						
					}
				});

				<!-- #include file="includes/accountHolderPopup.js" -->

			});
			



	</script>
	
	<style>
		
		tfoot th.right {
			text-align: right;
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
			<!-- Navigation. We hide it in small screens. -->
		
			<!-- #include file="../includes/mdlLayoutNavLarge.asp" -->

		</div>
		<% dbug("customerID prior to customerTabs: " & customerID) %>
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
				<div class="mdl-cell mdl-cell--9-col reportTitle">Product Summary<br><% =subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>

			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--10-col mdl-shadow--2dp" style="padding: 15px; text-align: center;">
					
					<br>
<!--
					<div id="<% =accountHolderNumber %>" style="text-align: center; font-size: 16px; display: inline-block;">
						<span><% =getAccountHolderAddenda(accountHolderNumber) %></span>
						<b>Account Holder #:</b>&nbsp;<span class="accountHolderNumber"><i class="material-icons" style="vertical-align: middle;">fingerprint</i></span>
						&nbsp;&nbsp;&nbsp;
						<b>Account Holder Name:</b>&nbsp;<span class="accountHolderName"><i class="material-icons" style="vertical-align: middle;">portrait</i></span>
					</div>
-->
					<div style="float: right; display: inline-block; margin-bottom: 15px;">
						<button id="searchButton" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
							Show All Products
						</button>					
					</div>
					<br>
					
						<table id="cNoteTable" class="compact display">
							<thead>
								<tr>
									<th class="ldo">L-D-O</th>
									<th class="productCode">Product</th>
									<th class="productDescription">Description</th>
									<th class="accounts"># Accts.</th>
									<th class="profit">Profit</th>
									<th class="balance">Balance</th>
									<th class="netInterestIncome">Net Int. Inc.</th>
									<th class="nonInterestIncome">Non-Int. Inc.</th>
									<th class="nonInterestExpense">Non-Int. Exp.</th>
								</tr>
							</thead>
							<tfoot>
									<th></th>
									<th></th>
									<th>Totals</th>
									<th class="right"></th>
									<th class="right"></th>
									<th class="right"></th>
									<th class="right"></th>
									<th class="right"></th>
									<th class="right"></th>
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