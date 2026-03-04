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
<% 
call checkPageAccess(43)

' capture the required items that control this report...
customerID				= request.querystring("id")
accountHolderNumber	= request.querystring("accountHolderNumber")

productCode				= request.querystring("productCode")
productDesc				= request.querystring("productDesc")
subtitle = "Product: (" & productCode & ") " & productDesc



title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title
userLog(title)

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

		<!-- #include file="includes/getAllAccountHolders.js" -->
		
		const customerID 				= <% =customerID %>;
		const productCode				= '<% =productCode %>';
		const accountHolderNumber 	= '<% =accountHolderNumber %>';
		

		$(document).ready(function() {

			var table = $('#cNoteTable')
				.on( 'draw.dt', function() {

					const tempDT = $('#cNoteTable').DataTable();
					GetAllAccountsInDatatable(tempDT,customerID);

					var cNoteMoney = $('.cNoteMoney');
					if ( cNoteMoney ) {
						for (i = 0; i < cNoteMoney.length; ++i) {
							MakeNegativeValueRed(cNoteMoney[i]);
						}
					}

				})
				.on( 'click', 'tbody tr', function() {
					var accountNumber = this.id;
					window.location.href = '/cProfit/accountDetail.asp?id=<% =customerID %>&accountNumber=' + accountNumber;
				})
				.DataTable({
					paging: true,
					info: true,
					searching: true,
					ajax: {url: '/cProfit/ajax/accounts.asp',
						data: {
							customerID: customerID,
							accountHolderNumber: accountHolderNumber,
							productCode: productCode
						}
					},
					columnDefs: [
						{targets: 'accountNumber',				data: 'accountNumber', 				className: 'accountNumber dt-body-left'},
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
					order: [[ 1, 'desc' ]],
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
						profitTotal = api
							.column( 1 )
							.data()
							.reduce( function ( a, b ) {
								return intVal(a) + intVal	(b);
							}, 0 );
						$( api.column( 1 ).footer() ).html( 
							$.fn.dataTable.render.number(',', '.', 0, '$').display( profitTotal )
						);
						
					}
				});

				<!-- #include file="includes/accountHolderPopup.js" -->

			});
			



	</script>

	<style>
		
		.reportTitle {
			text-align: center;
			font-size: large;
			font-weight: bold;
		}
		
		td.accountHolderNumber, td.accountHolderName, td.addenda, td.accountNumber {
			max-width: 120px;
			text-overflow: ellipsis;
			white-space: nowrap;
			overflow: hidden;		
		}
				
		table.dataTable tr:hover {
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
				<div class="mdl-cell mdl-cell--12-col reportTitle">Accounts By Product<br><% = subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>

			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--10-col mdl-shadow--2dp" style="padding: 15px; text-align: center;">
					
					<br>
					<div id="<% =accountHolderNumber %>" style="text-align: center; font-size: 16px; display: inline-block;">
						<span><% =getAccountHolderAddenda(accountHolderNumber) %></span>
						<b>Account Holder #:</b>&nbsp;<span class="accountHolderNumber"><i class="material-icons" style="vertical-align: middle;">fingerprint</i></span>
						&nbsp;&nbsp;&nbsp;
						<b>Account Holder Name:</b>&nbsp;<span class="accountHolderName"><i class="material-icons" style="vertical-align: middle;">portrait</i></span>
					</div>

					<br>
					
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
								<th</th>
								<th</th>
								<th</th>
								<th</th>
								<th</th>
								<th</th>
								<th</th>
								<th</th>
								<th</th>
								<th</th>
							</tr>
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