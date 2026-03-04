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
<!-- #include file="../includes/apiServer.asp" -->
<!-- #include file="../includes/jwt.all.asp" -->
<!-- #include file="../includes/sessionJWT.asp" -->
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

		var direction = 'desc';

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
		
		
		window.addEventListener('load', function() {

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

					GetAllAccountsInDatatable(table,customerID);

					var cNoteMoney = $('.cNoteMoney');
					if ( cNoteMoney ) {
						for (i = 0; i < cNoteMoney.length; ++i) {
							MakeNegativeValueRed(cNoteMoney[i]);
						}
					}
					
				})
				.on( 'mouseover', 'tbody tr', function() {

					const addTargetButton = this.querySelector('td.target button.add');
					const addAddendaButton = this.querySelector('td.addenda button.add');
					
					if ( addTargetButton ) {
						addTargetButton.style.visibility = 'visible';
					}
					if ( addAddendaButton ) {
						addAddendaButton.style.visibility = 'visible';
					}
					
				})
				.on( 'mouseout', 'tbody tr', function() {

					const addTargetButton = this.querySelector('td.target button.add');
					const addAddendaButton = this.querySelector('td.addenda button.add');
					
					if ( addTargetButton ) {
						addTargetButton.style.visibility = 'hidden';
					}
					if ( addAddendaButton ) {
						addAddendaButton.style.visibility = 'hidden';
					}
					
				})
				.on( 'click', 'button.target', function(e) {
					
					e.preventDefault();
					e.stopPropagation();
					ToggleTargetIndicator(this);
					
				})
				.on( 'click', 'button.addenda', function(e) {
					e.preventDefault();
					e.stopPropagation();
					AddendaButton_onClick(this,e);
				})
				.on( 'click', 'tbody tr', function() {
					var accountNumber = this.id;
					window.location.href = '/cProfit/accountDetail.asp?customerID=<% =customerID %>&accountNumber=' + accountNumber + '&tab=cProfit';
				})
				.DataTable({
					paging: true,
					info: true,
					searching: false,
					processing: true,
					serverSide: true,
					ajax: {url: '/cProfit/ajax/accounts.asp',
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
							service: service,
							account: drillDownParms.account,
							accountHolder: drillDownParms.accountHolder,
							branch: drillDownParms.branch,
							officer: drillDownParms.officer,
							product: drillDownParms.product,
						}
					},
					columnDefs: [
						{targets: 'accountNumber',				data: 'accountNumber', 				className: 'accountNumber dt-body-left', orderable: false, searchable: false},
						{targets: 'profit', 						data: 'profit', 						className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'balance', 					data: 'balance', 						className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'interestRate', 				data: 'interestRate',				className: 'dt-body-right'},
						{targets: 'openDate', 					data: 'openDate',						className: 'dt-body-center'},
						{targets: 'ftpRate', 					data: 'ftpRate',						className: 'dt-body-right'},
						{targets: 'netInterestIncome', 		data: 'netInterestIncome', 		className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'nonInterestIncome', 		data: 'nonInterestIncome', 		className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'nonInterestExpense', 		data: 'nonInterestExpense', 		className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'incNonInterestExpense', 	data: 'incNonInterestExpense', 	className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
					],
					order: [[ 1, direction ]],
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

						var profitTotal 				= api.column( 1 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var balanceTotal 				= api.column( 2 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var netInterestIncome 		= api.column( 6 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var nonInterestIncome 		= api.column( 7 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var nonInterestExpense 		= api.column( 8 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );
						var incNonInterestExpense 	= api.column( 9 ).data().reduce( function ( a,b ) { return intVal(a) + intVal(b); }, 0 );

						$( api.column( 1 ).footer() ).html( formatter.format(profitTotal) );
						$( api.column( 2 ).footer() ).html( formatter.format(balanceTotal) );
						$( api.column( 6 ).footer() ).html( formatter.format(netInterestIncome) );
						$( api.column( 7 ).footer() ).html( formatter.format(nonInterestIncome) );
						$( api.column( 8 ).footer() ).html( formatter.format(nonInterestExpense) );
						$( api.column( 9 ).footer() ).html( formatter.format(incNonInterestExpense) );


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
		
		async function ToggleTargetIndicator(htmlElement) {
			
			const accountHolderNumber = htmlElement.closest('tr').id;
			const notification = document.querySelector('.mdl-js-snackbar');
			const apiResponse = await fetch('/cProfit/ajax/toggleAccountHolderStar.asp?customerID='+customerID+'&accountHolderNumber='+accountHolderNumber);
			
			if (apiResponse.status != 200) {
				return generateErrorResponse('failed to toggle account holder star indicator, ' + apiResponse.status);
			}
			
			var apiResult = await apiResponse.json();

			var domTable = htmlElement.closest('TABLE');
			var dtTable = $(domTable).DataTable();			
			
			if ( apiResult.msg == 'Star added' ) {
				message = 'Top 100 added';
// 				icon.textContent = 'star';
				dtTable.cell('#'+accountHolderNumber, '.target').data(
					'<button class="mdl-button mdl-js-button target" style="font-size: 24px;">&#128175;</button>'
					);
			} else {
				message = 'Top 100 removed';
// 				icon.textContent = 'star_outline';
				dtTable.cell('#'+accountHolderNumber, '.target').data(
					'<button class="mdl-button mdl-js-button target add" style="visibility: hidden;"><i class="material-icons">add</i></button>'
				);
			}

			notification.MaterialSnackbar.showSnackbar({message: message});

			
		}


	</script>

	<style>

		table.dataTable tbody tr:hover {
			cursor: pointer;
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
				<div class="mdl-cell mdl-cell--9-col reportTitle">Account Summary<br><% =subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--10-col mdl-shadow--2dp" style="padding: 15px;">

					<table id="cNoteTable" class="compact display cNoteTable">
						<thead>
								<th class="accountNumber">Account Number</th>
								<th class="profit">Profit</th>
								<th class="balance">Balance</th>
								<th class="interestRate">Interest Rate</th>
								<th class="openDate">Open Date</th>
								<th class="ftpRate">FTP Rate</th>
								<th class="netInterestIncome">Net Int. Inc.</th>
								<th class="nonInterestIncome">Non-Int. Inc.</th>
								<th class="nonInterestExpense">Non-Int. Exp.</th>
								<th class="incNonInterestExpense">Incremental<br>Non-Int. Exp.</th>
							</tr>
						</thead>
						<tfoot>
								<th class="alignRight">Total:</th>
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