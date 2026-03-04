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

dbug("dupming querystring...")
for each item in request.querystring
	dbug("request.querystring(" & item & "): " & request.querystring(item))
next 
dbug(" ")

' cpature the items that control this report...
customerID			= request.querystring("id")
groupName			= request.querystring("group")
branchName			= request.querystring("branch")
accountHolder		= request.querystring("accountHolder")
productCode			= request.querystring("product")
officer				= request.querystring("officer")

dbug("request.querystring('oficer'): " & request.querystring("officer"))

if len(groupName) > 0 then 
	if len(predicate) > 0 then predicate = predicate & "and " end if
	predicate = predicate & "[loan deposit other] = '" & groupName & "' "
end if

if len(branchName) > 0 then 
	if len(predicate) > 0 then predicate = predicate & "and " end if
	predicate = predicate & "[branch description] = '" & branchName & "' " 
end if

if len(accountHolder) > 0 then 
	if len(predicate) > 0 then predicate = predicate & "and " end if
	predicate = predicate & "[account holder number] = '" & accountHolder & "' " 
end if

if len(productCode) > 0 then 
	if len(predicate) > 0 then predicate = predicate & "and " end if
	predicate = predicate & "[product code] = '" & productCode & "' " 
end if

if len(officer) > 0 then 
	if len(predicate) > 0 then predicate = predicate & " and " end if 
	predicate = predicate & "[officer name] = '" & officer & "' " 
end if 

dbug("predicate: " & predicate)



title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title
userLog(title)

SQL = "select " &_
			"[account holder number], " &_
			"[name], " &_
			"[account number], " &_
			"profit, " &_
			"balance, " &_
			"[total loans] as totalLoans, " &_
			"[total deposits] as totalDeposits, " &_
			"[net interest income] as netInterestIncome, " &_
			"[non-interest income] as nonInterestIncome, " &_
			"[non-interest expense] as nonInterestExpense, " &_
			"[incremental non-interest expense] as incNonInterestExpense " &_
		"from pr_pqwebarchive " &_
		"where " & predicate & " " &_
		"and customerID = " & customerID & " " &_
		"order by profit desc "

dbug(SQL)
set rs = CreateObject("ADODB.Recordset")
rs.cursorLocation = adUseClient
rs.open SQL, dataconn
' set rs = dataconn.execute(SQL)


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<script src="../moment.min.js"></script>
	<script src="../list.min.js"></script>
	<script src="https://www.gstatic.com/charts/loader.js"></script>
	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		<!-- #include file="includes/getAllVisibleAccounts.js" -->
		<!-- #include file="includes/accountHolderPopup.js" -->

	</script>

	<style type="text/css">
	
		.cNoteInteger {
			text-align: right;
			width: 110px;
		}
		
		.cNotePercent {
			text-align: right;
			width: 110px;
		}
		
		.cNoteCurrency {
			text-align: right;
			width: 110px;
		}
		
		.cNoteCurrencyNegative {
			text-align: right;
			color: crimson;
			width: 110px;
		}
		
		.cNoteRowHeader {
			text-align: left;
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
		
				<div id="cNoteTableParent" class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b>Accounts</b></h9>
						<br>
						<% 
						if len(branchName) > 0 then 
							branchTitle = branchName
						else 
							branchTitle = "All"
						end if
						if len(groupName) > 0 then 
							groupTitle = groupName
						else 
							groupTitle = "All"
						end if
						if len(accountHolder) > 0 then
							accountHolderTitle = accountHolder
						else 
							accountHolderTitle = "All"
						end if
						if len(productCode) > 0 then
							productTitle = productCode
						else 
							productTitle = "All"
						end if
						if len(officer) > 0 then 
							officerTitle = officer
						else 
							officerTitle = "All"
						end if
						%>
						Branch: <% =branchTitle %>;&nbsp;&nbsp;Service Class: <% =groupTitle %>;&nbsp;&nbsp;Product Code: <% =productTitle %>;&nbsp;&nbsp;Officer Name: <% =officerTitle %>
					</div>

					<br>
					
					<%
					if not rs.eof then 
						
						dim totalsArray()
						redim totalsArray(rs.fields.count)

						rows = rs.RecordCount 
						dbug("rows: " & rows)
						if rows > 24 then 
							bodyHeight = 550
						else 
							bodyHeight = (rows) * 23
						end if
						dbug("bodyHeight: " &  bodyHeight)
						
						
						%>

						<table align="center" class="cNoteTable">
							<thead>
								<tr>
									
									<th class="alignLeft cNoteFixedCellMedium sort" data-sort="accountHolderNumber">Account Holder #</th>
									<th class="alignLeft cNoteFixedCellHuge sort" data-sort="accountHolderName">Account Holder Name</th>
									<th class="alignCenter cNoteFixedCellTiny sort" data-sort="addenda"><i class="material-icons" style="width: 32px;">comment</i></th>
									<th class="alignLeft cNoteFixedCellLarge sort" data-sort="accountNumber">Account Number</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="profit">Profit</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="balance">Balance</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="totalLoans">Total Loans</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="totalDeposits">Total Deposits</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="netInterestIncome">Net Int. Inc.</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="nonInterestIncome">Non-Int. Inc.</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="nonInterestExpense">Non-Int. Exp.</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="incNonInterestExpense">Inc. Non-Int. Exp.</th>

								</tr>
							</thead>
							<tbody style="height: <% =bodyHeight %>px;" class="list">
								<% 
								while not rs.eof 
									for i = 3 to 10
										totalsArray(i) = totalsArray(i) + rs(i)
										dbug("totalsArray(" & i & "): " & totalsArray(i))
									next 	
									%>
									<tr id="<% =rs("account number") %>" class="cNoteRow" onclick="window.location.href='accountDetail.asp?id=<% =customerID %>&account=<% =rs("account number") %>'"> 
										
										<td class="alignLeft cNoteFixedCellMedium accountHolderNumber"><i class="material-icons">fingerprint</i></td>
										<td class="alignLeft cNoteFixedCellHuge accountHolderName"><i class="material-icons">portrait</i</td>
										<td class="alignCenter cNoteFixedCellTiny addenda">
											<% =getAccountHolderAddenda(rs("Account Holder Number")) %>
										</td>
										<td class="alignLeft cNoteFixedCellLarge accountNumber"><i class="material-icons">credit_card</i></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney profit"><% =formatCurrency(rs("profit"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney balance"><% =formatCurrency(rs("balance"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney totalLoans"><% =formatCurrency(rs("totalLoans"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney totalDeposits"><% =formatCurrency(rs("totalDeposits"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney netInterestIncome"><% =formatCurrency(rs("netInterestIncome"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney nonInterestIncome"><% =formatCurrency(rs("nonInterestIncome"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney nonInterestExpense"><% =formatCurrency(rs("nonInterestExpense"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney incNonInterestExpense"><% =formatCurrency(rs("incNonInterestExpense"),0) %></td>

									</tr>
									<% rs.movenext %>
								<% wend %>
							</tbody>
							<tfoot>
									<tr> 
										
										<td class="alignRight" colspan="4" style="width: 435px">Totals:</td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(3),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(4),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(5),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(6),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(7),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(8),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(9),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(10),0) %></td>

									</tr>
							</tfoot>
						</table>							
						<%
					end if
					rs.close 
					set rs = nothing
					%>


				</div>
						
				
				<div class="mdl-layout-spacer"></div>
		
			</div>
			

		</div>
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>

<script>

	var listOptions = {
		valueNames: [ 
			'profit', 
			'balance', 
			'totalLoans',
			'totalDeposits', 
			'netInterestIncome', 
			'nonInterestIncome', 
			'nonInterestExpense', 
			'incNonInterestExpense'
		]
	}
	
	var reportList = new List(document.getElementById('cNoteTableParent'), listOptions);
	
	reportList.on('sortComplete',function() {
		GetAllVisibleAccountHolders(<% =customerID %>);
	})	


	document.querySelectorAll('.cNoteRow')
	.forEach(e => e.addEventListener('mouseover', HighlightRow));
	
	document.querySelectorAll('.cNoteRow')
	.forEach(e => e.addEventListener('mouseout', HighlightRow));
	

	document.querySelectorAll('.cNoteMoney')
	.forEach (e => MakeNegativeValueRed(e));

	document.querySelectorAll('td.addenda')
		.forEach(e => e.addEventListener('mouseover', function() {

			var addButton = this.querySelector('button.add');
			if (addButton) {
				addButton.style.visibility = 'visible';
			}
			
		}));
	
	document.querySelectorAll('td.addenda')
		.forEach(e => e.addEventListener('mouseout', function() {
			var addButton = this.querySelector('button.add');
			if (addButton) {
				addButton.style.visibility = 'hidden';
			}
		}));
	

	
</script>	

</body>
</html>