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
<% 
call checkPageAccess(43)


' cpature the items that control this report...
customerID			= request.querystring("id")
groupName			= request.querystring("group")
branchName			= request.querystring("branch")
officerName			= request.querystring("officer")

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

if len(officerName) > 0 then 
	if len(predicate) > 0 then predicate = predicate & "and " end if
	predicate = predicate & "[officer name] = '" & officerName & "' " 
end if



title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title
userLog(title)

SQL = "select " &_
			"a.[service], " &_
			"count(distinct [account number]) as accountCount, " &_
			"sum(profit) as profit, " &_
			"sum(balance) as balance, " &_
			"max([total loans]) as totalLoans, " &_
			"max([total deposits]) as totalDeposits, " &_
			"sum([net interest income]) as netInterestIncome, " &_
			"sum([non-interest income]) as nonInterestIncome, " &_
			"sum([non-interest expense]) as nonInterestExpense, " &_
			"sum([incremental non-interest expense]) as incNonInterestExpense " &_
		"from pr_pqwebarchive a " &_
		"where " & predicate & " " &_
		"and customerID = " & customerID & " " &_
		"group by a.[service] " &_
		"order by profit desc "

dbug(SQL)
set rs = dataconn.execute(SQL)


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<script type="text/javascript" src="../moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="customerProfit.js"></script>

	<script type="text/javascript" src="../sorttable.js"></script>
	
	<script>

		function MakeNegativeValueRed (element) {
			
			var temp = element.childNodes[0].innerHTML;
			if (temp) {
				if (!isNaN(temp)) {
					if (temp < 0) {
						element.childNodes[0].style.color = 'crimson';
					}
				} else {
					if (temp.indexOf('$') > - 1 || temp.indexOf('%') > -1) {
						if ((temp.indexOf('(') > - 1 && temp.indexOf(')') > - 1) || temp.indexOf('-')  > - 1) {
							element.childNodes[0].style.color = 'crimson';
						}
					}
				}
			}
			
		}
		

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
	

			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b>Services</b></h9>
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
						if len(officerName) > 0 then 
							officerTitle = officerName
						else 
							officerTitle = "All"
						end if
						%>
						Branch: <% =branchTitle %>;&nbsp;&nbsp;Officer: <% =officerTitle %>;&nbsp;&nbsp;Service Class: <% =groupTitle %>
					</div>

					<br>
					
					<%
					if not rs.eof then 
						dim totalsArray()
						redim totalsArray(rs.fields.count)
						%>

						<table align="center" class="cNoteTable sortable">
							<thead>
								<tr>
									<th class="alignLeft cNoteFixedCellLarger"><div>Service</div></th>
									<th class="alignRight cNoteFixedCellSmall"><div># Accounts</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Profit</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Balance</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Total Loans</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Total Deposits</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Net Int. Inc.</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Non-Int. Inc.</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Non-Int. Exp.</div></th>
									<th class="alignRight cNoteFixedCellLarge"><div>Inc. Non-Int. Exp.</div></th>

								</tr>
							</thead>
							<tbody style="height: 550px;">
								<% 
								while not rs.eof 
								for i = 1 to 9
									totalsArray(i) = totalsArray(i) + rs(i)
								next 	
									%>
									<tr id="<% =rs("service") %>" class="cNoteRow" 
										onclick="window.location.href='productList.asp?id=<% =customerID %>&branch=<% =branchName %>&officer=<% =officerName %>&group=<% =groupName%>&service=<% =rs("service") %>'"> 
										
										<td class="alignLeft cNoteFixedCellLarger"><div><% =rs("service") %></div></td>
										<td class="alignRight cNoteFixedCellSmall cNoteMoney" sorttable_customkey="<% =rs("accountCount") %>"><div><% =formatNumber(rs("accountCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("profit") %>"><div><% =formatCurrency(rs("profit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("balance") %>"><div><% =formatCurrency(rs("balance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("totalLoans") %>"><div><% =formatCurrency(rs("totalLoans"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("totalDeposits") %>"><div><% =formatCurrency(rs("totalDeposits"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("netInterestIncome") %>"><div><% =formatCurrency(rs("netInterestIncome"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("nonInterestIncome") %>"><div><% =formatCurrency(rs("nonInterestIncome"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("nonInterestExpense") %>"><div><% =formatCurrency(rs("nonInterestExpense"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rs("incNonInterestExpense") %>"><div><% =formatCurrency(rs("incNonInterestExpense"),0) %></div></td>

									</tr>
									<% rs.movenext %>
								<% wend %>
							</tbody>
							<tfoot>
									<tr> 
										
										<td class="alignRight cNoteFixedCellLarger"><div>Totals:</div></td>
										<td class="alignRight cNoteFixedCellSmall cNoteMoney"><div><% =formatNumber(totalsArray(1),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(2),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(3),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(4),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(5),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(6),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(7),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(8),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney"><div><% =formatCurrency(totalsArray(9),0) %></div></td>

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

	document.querySelectorAll('.cNoteMoney')
	.forEach (e => MakeNegativeValueRed(e));

	document.querySelectorAll('.cNoteRow')
	.forEach(e => e.addEventListener('mouseover', HightLightService));
	
	document.querySelectorAll('.cNoteRow')
	.forEach(e => e.addEventListener('mouseout', HightLightService));
	
	
</script>	

</body>
</html>