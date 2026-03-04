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

' cpature the items that control this report...
customerID			= request.querystring("id")
accountHolder		= request.querystring("accountHolder")
product			= request.querystring("product")

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
			"[account number] as account, " &_
			"format(balance,'##;##-') as balance, " &_
			"[interest rate], " &_
			"format(profit, '##;(##)') as profit, " &_
			"[branch code and branch description] as branch, " &_
			"[officer name] as officer " &_
		"FROM pr_pqwebarchive  " &_
		"WHERE [Account Holder Number] = '" & accountHolder & "' " &_
		"AND customerID = " & customerID & " " &_
		"and [product code and product description] = '" & product & "' " &_
		"ORDER BY 4 desc "

dbug(SQL)
set rs = CreateObject("ADODB.Recordset")
rs.cursorLocation = adUseClient
rs.open SQL, dataconn
' set rs = dataconn.execute(SQL)


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<script type="text/javascript" src="../moment.min.js"></script>
	<script type="text/javascript" src="../list.min.js"></script>

	<script type="text/javascript" src="customerProfit.js"></script>
	<script type="text/javascript" src="makeNegativeValueRed.js"></script>

	
	<script>

		<!-- #include file="includes/getAllAccountHolders.js" -->
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
	
		.cNoteShowAddendaContextMenu {
			z-index:1000;
			position: absolute;
			background-color:#ffffff;
			border: 1px solid #b3b8f8;
			display: block;
			margin: 0px;
			list-style-type: none;
			list-style: none;
		}

		th.sort {
			cursor: url('../images/baseline_import_export_black_18dp.png'), auto;
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
					
					<br>
					<div id="<% =accountHolder %>" style="text-align: center; font-size: 16px; ">
						<span><% =getAccountHolderAddenda(accountHolder) %></span>
						<b>Account Holder #:</b>&nbsp;<span class="accountHolderNumber"><i class="material-icons" style="vertical-align: middle;">fingerprint</i></span>
						&nbsp;&nbsp;&nbsp;
						<b>Account Holder Name:</b>&nbsp;<span class="accountHolderName"><i class="material-icons" style="vertical-align: middle;">portrait</i></span>
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
									
									<th class="alignLeft cNoteFixedCellLarge " data-sort="accountNumber">Account</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="balance">Balance</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="interest">Interest</th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="profit">Profit</th>
									<th class="alignLeft cNoteFixedCellHuge sort" data-sort="branch">Branch</th>
									<th class="alignLeft cNoteFixedCellHuge sort" data-sort="officer">Officer</th>

								</tr>
							</thead>
							<tbody style="height: <% =bodyHeight %>px;" class="list">
								<% 
								while not rs.eof 
									for i = 1 to 3
										totalsArray(i) = totalsArray(i) + rs(i)
										dbug("totalsArray(" & i & "): " & totalsArray(i))
									next 	
									%>
									<tr id="<% =rs("account") %>" class="cNoteRow" onclick="window.location.href='accountDetail.asp?id=<% =customerID %>&account=<% =rs("account") %>'"> 
										
										<td class="alignLeft cNoteFixedCellLarge accountNumber"><i class="material-icons">credit_card</i></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney balance" data-balance="<% =rs("balance") %>"><% =formatCurrency(rs("balance"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNotePercent interest" data-interest="<% =rs("interest rate") %>"><% =formatPercent(rs("interest rate")/100,3) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney profit" data-profit="<% =rs("profit") %>"><% =formatCurrency(rs("profit"),0) %></td>
										<td class="alignLeft cNoteFixedCellHuge branch"><% =rs("branch") %></td>
										<td class="alignLeft cNoteFixedCellHuge officer"><% =rs("officer") %></td>

									</tr>
									<% rs.movenext %>
								<% wend %>
							</tbody>
							<tfoot>
									<tr> 
										
										<td class="alignLeft cNoteFixedCellLarge">&nbsp;</td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><% =formatCurrency(totalsArray(1),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"></td>
										<td class="alignRight cNoteFixedCellLarge cNotePercent"><% =formatCurrency(totalsArray(3),0) %></td>
										<td class="alignLeft cNoteFixedCellHuge"></td>
										<td class="alignLeft cNoteFixedCellHuge"></td>

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

	document.querySelectorAll('.cNoteRow')
	.forEach(e => e.addEventListener('mouseover', HighlightRow));
	
	document.querySelectorAll('.cNoteRow')
	.forEach(e => e.addEventListener('mouseout', HighlightRow));
	

	document.querySelectorAll('.cNoteMoney')
	.forEach (e => MakeNegativeValueRed(e));

	var listOptions = {
		valueNames: [
			{name: 'balance', attr: 'data-balance'},
			{name: 'interest', attr: 'data-interest'},
			{name: 'profit', attr: 'data-profit'},
			'branch',
			'officer'
		]
	};
	
	var list = new List('cNoteTableParent', listOptions);
	
	list.on('sortComplete', function() {
		GetAllVisibleAccounts(<% =customerID %>);
	})
	
</script>	

</body>
</html>