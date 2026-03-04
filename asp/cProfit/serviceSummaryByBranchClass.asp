<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(43)



server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title

suntitle = "Class Overview by Branch" 
userLog(title)

SQL = "select " &_
			"branch, " &_
			"sum(loanCount) 		as loanCount, " &_
			"sum(loanBalance) 	as loanBalance, " &_
			"sum(loanProfit) 		as loanProfit, " &_
			"case when sum(loanBalance) <> 0 then sum(loanInterest) / sum(loanBalance) / 100 else 0 end as loanInterest, " &_
			"sum(depositCount) 	as depositCount, " &_
			"sum(depositBalance) as depositBalance, " &_
			"sum(depositProfit) 	as depositProfit, " &_
			"case when sum(depositBalance) <> 0 then sum(depositInterest) / sum(depositBalance) / 100 else 0 end as depositInterest, " &_
			"sum(otherCount) 		as otherCount, " &_
			"sum(otherBalance) 	as otherBalance, " &_
			"sum(otherProfit) 	as otherProfit, " &_
			"case when sum(otherBalance) <> 0 then sum(otherInterest) / sum(otherBalance) / 100 else 0 end as otherInterest, " &_
			"sum(loanCount) + sum(depositCount) + sum(otherCount) as totalCount, " &_
			"sum(loanBalance) + sum(depositBalance) + sum(otherBalance) as totalBalance, " &_
			"sum(loanProfit) + sum(depositProfit) + sum(otherProfit) as totalProfit " &_
		"from ( " &_
			"select " &_
				"[branch description] as branch, " &_
				"case when [loan deposit other] = 'Loan' 		then 1 									else 0 end as loanCount, " &_
				"case when [loan deposit other] = 'Loan' 		then balance							else 0 end as loanBalance, " &_
				"case when [loan deposit other] = 'Loan' 		then profit								else 0 end as loanProfit, " &_
				"case when [loan deposit other] = 'Loan' 		then [interest rate x balance] 	else 0 end as loanInterest, " &_
				"case when [loan deposit other] = 'Deposit' 	then 1 									else 0 end as depositCount, " &_
				"case when [loan deposit other] = 'Deposit' 	then balance							else 0 end as depositBalance, " &_
				"case when [loan deposit other] = 'Deposit' 	then profit								else 0 end as depositProfit, " &_
				"case when [loan deposit other] = 'Deposit' 	then [interest rate x balance] 	else 0 end as depositInterest, " &_
				"case when [loan deposit other] = 'Other' 	then 1 									else 0 end as otherCount, " &_
				"case when [loan deposit other] = 'Other' 	then balance							else 0 end as otherBalance, " &_
				"case when [loan deposit other] = 'Other' 	then profit								else 0 end as otherProfit, " &_
				"case when [loan deposit other] = 'Other' 	then [interest rate x balance] 	else 0 end as otherInterest " &_
			"from pr_pqwebarchive " &_
			"where [Account Holder Number] not in ('0','Manually Added Accounts') " &_
			"and [Branch Description] <> 'Treasury' " &_
			"and [Officer Name] <> 'Treasury' " &_
			") as x " &_
		"group by branch "
		
dbug(SQL)
set rs = dataconn.execute(SQL)



function formatTD(value,datatype)
	
	select case datatype 
	
		case "currency"
		
			if IsNumeric(value) then 
				if value < 0 then 
					cssClass = cssClass & "cNoteCurrencyNegative "
				else 
					cssClass = cssClass & "cNoteCurrency "
				end if
			end if 
			
			outputValue = formatCurrency(value,0)			
		
		case "percent"
		
			cssClass = cssClass & "cNotePercent "
			outputValue = formatPercent(value/100,4)
		
		case "integer"
		
			cssClass = cssClass & "cNoteInteger "
			outputValue = formatNumber(value,0)
			
		case else 
		
			outputValue = value
		
	end select 
	
	formatTD = "<td class=""" & cssClass & """ style=""cursor: pointer;"" sorttable_customkey=""" & value & """ onclick=""DrillDownOnLDO(" & customerID & ",this,this.parentNode.rowIndex,this.cellIndex)"">" & outputValue & "</td>"
	
end function 


%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="customerProfit.js"></script>

	<script type="text/javascript" src="sorttable.js"></script>
	
	<script>
		
		function MakeNegativeValueRed (element) {
			
			var temp = element.childNodes[0].innerHTML;
			if (temp) {
				if (!isNaN(temp)) {
					console.log('value is numeric: ' + temp);
					if (temp < 0) {
						console.log('value is negative: ' + temp);
						element.childNodes[0].style.color = 'crimson';
					}
				} else {
					console.log('value is NOT numeric: ' + temp);
					if (temp.indexOf('$') > - 1 || temp.indexOf('%') > -1) {
						if ((temp.indexOf('(') > - 1 && temp.indexOf(')') > - 1) || temp.indexOf('-')  > - 1) {
							console.log('value is likely a negative numeric value: ' + temp);
							element.childNodes[0].style.color = 'crimson';
						} else {
							console.log('value is likely numeric, but not negative: ' + temp);
						}
					} else {
						console.log('value is likely not numeric: ' + temp);
					}
				}
			} else {
				console.log('value is empty: ' + temp);
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
				
		.cNoteStackedTblHdrTop {
			border-bottom: 0px;
		}
				
		.cNoteStackedTblHdrTopAlt {
			border-bottom: 0px;
			background-color: #8ea5eb;
		}
				
		.cNoteStackedTblHdrBot {
			top-bottom: 0px;
		}
		
		.cNoteStackedTblHdrBotAlt {
			top-bottom: 0px;
			background-color: #8ea5eb;
		}
		
		.cNoteFixedCellSmall div {
			display: block;
			width: 50px;
		}
	
		.cNoteFixedCellMedium div {
			display: block;
			width: 70px;
		}
	
		.cNoteFixedCellLarge div {
			display: block;
			width: 90px;
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
		
			<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

		</div>
		<!-- #include file="includes/customerTabs.asp" -->
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
						<h9><b>Class Overview by Branch</b></h9>
					</div>
					<br>
					
					<%
					if not rs.eof then 
						%>

						<table class="cNoteTable" align="center" style="border: 0px">
							<thead>
								<tr>
									<th class="alignLeft cNoteStackedTblHdrTopAlt cNoteFixedCell">		<div style="width: 150px;">&nbsp;</div></th>
									
									<th class="alignCenter cNoteStackedTblHdrTop cNoteFixedCell">		<div style="width: 333px;">LOAN</div></th>
									<th class="alignCenter cNoteStackedTblHdrTopAlt cNoteFixedCell">	<div style="width: 333px;">DEPOSIT</div></th>
									<th class="alignCenter cNoteStackedTblHdrTop cNoteFixedCell">		<div style="width: 333px;">OTHER</div></th>
									<th class="alignCenter cNoteStackedTblHdrTopAlt cNoteFixedCell">	<div style="width: 252px;">TOTAL</div></th>
								</tr>
							</thead>
						</table>

						<table id="ldoTable" class="cNoteTable sortable" align="center" style="border: 0px;">
							<thead>
								<tr>
									<th class="alignLeft cNoteStackedTblHdrBotAlt cNoteFixedCellLarge"><div style="width: 150px;">Branch</div></th>
									
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellSmall"><div># Accts</div></th>
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellLarge"><div>Balance</div></th>
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellLarge"><div>Profit</div></th>
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellMedium"><div>Interest</div></th>

									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellSmall"><div># Accts</div></th>
									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellLarge"><div>Balance</div></th>
									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellLarge"><div>Profit</div></th>
									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellMedium"><div>Interest</div></th>

									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellSmall"><div># Accts</div></th>
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellLarge"><div>Balance</div></th>
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellLarge"><div>Profit</div></th>
									<th class="alignRight cNoteStackedTblHdrBot cNoteFixedCellMedium"><div>Interest</div></th>

									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellSmall"><div># Accts</div></th>
									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellLarge"><div>Balance</div></th>
									<th class="alignRight cNoteStackedTblHdrBotAlt cNoteFixedCellLarge"><div>Profit</div></th>

								</tr>
							</thead>
							<tbody style="height: 550px;">
								<% while not rs.eof %>
									<tr id="<% =rs("branch") %>"> 
										
										<td class="alignLeft cNoteFixedCell" ><div style="width: 150px;"><% =rs("branch") %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldo loan"><div><% =formatNumber(rs("loanCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo loan"><div><% =formatCurrency(rs("loanBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo loan"><div><% =formatCurrency(rs("loanProfit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellMedium ldo loan"><div><% =formatPercent(rs("loanInterest"),4) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldo deposit"><div><% =formatNumber(rs("depositCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo deposit"><div><% =formatCurrency(rs("depositBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo deposit"><div><% =formatCurrency(rs("depositProfit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellMedium ldo deposit"><div><% =formatPercent(rs("depositInterest"),4) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldo other"><div><% =formatNumber(rs("otherCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo other"><div><% =formatCurrency(rs("otherBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo other"><div><% =formatCurrency(rs("otherProfit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellMedium ldo other"><div><% =formatPercent(rs("otherInterest"),4) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldoTotal"><div><% =formatNumber(rs("totalCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldoTotal"><div><% =formatCurrency(rs("totalBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldoTotal"><div><% =formatCurrency(rs("totalProfit"),0) %></div></td>

									</tr>
									<% rs.movenext %>
								<% wend %>
							</tbody>
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
<!-- #include file="includes/pageFooter.asp" -->
</div>

<script>


	document.querySelectorAll('.ldo')
	.forEach (e => e.addEventListener('mouseover', HighlightGroup ));
	
	document.querySelectorAll('.ldo')
	.forEach (e => e.addEventListener('mouseout', HighlightGroup ));
	
	document.querySelectorAll('.ldo')
	.forEach (e => e.addEventListener('click', DrillDown_ClassBranch ));
	
	document.querySelectorAll('.ldo')
	.forEach (e => MakeNegativeValueRed(e));
	
	document.querySelectorAll('.ldoTotal')
	.forEach (e => MakeNegativeValueRed(e));
	
// 	MakeNegativeValuesRed();
	
	
</script>



</body>
</html>