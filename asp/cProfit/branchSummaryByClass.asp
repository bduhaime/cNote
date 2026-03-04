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

customerID 			= request.querystring("id") 
selectedSummary 	= request.querystring("summary")


select case selectedSummary
	case "officer"
		summaryColumn 			= "[officer name]" 
		summaryColumnHeader 	= "Officer"
		reportTitle 			= "Officer Overview"
		pluralName 				= "officers"
	case else 
		summaryColumn 			= "[branch description]"
		summaryColumnHeader 	= "Branch"
		reportTitle 			= "Branch Overview"
		pluralName 				= "branches"
end select 
		
	

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

suntitle = "Class Overview by Branch" 
userLog(title)

SQL = "select " &_
			summaryColumn & ", " &_
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
				summaryColumn & ", " &_
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
			"and customerID = " & customerID & " " &_
			") as x " &_
		"group by " & summaryColumn & " "
		
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
	
	formatTD = "<td class=""" & cssClass & """ style=""cursor: pointer;"" onclick=""DrillDownOnLDO(" & customerID & ",this,this.parentNode.rowIndex,this.cellIndex)"">" & outputValue & "</td>"
	
end function 


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<script type="text/javascript" src="../list.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="/cProfit/customerProfit.js"></script>

	
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
		
		
		function ClassBranchContextMenu(element) {
// 			alert('you invoked a context menu');
			element.preventDefault();
			
			var menu = document.getElementById('ldoContextMenu');
			var newTop = MouseEvent.clientX;
			var newLeft = MouseEvent.clientY;
			
			menu.classList.add('cNoteShowContextMenu');
			menu.style.top = newTop;
			menu.style.left = newLeft;
			
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
		
		.cNoteShowContextMenu {
			z-index:1000;
			position: absolute;
			background-color:#ffffff;
			border: 1px solid #b3b8f8;
			padding-top: 2px; padding-left: 15px; padding-right: 15px; padding-bottom: 2px;
			display: block;
			margin: 0px;
			list-style-type: none;
			list-style: none;
		}

		.cNoteShowContextMenu li {
			padding-left: 50;
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
	
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div id="cNoteTableParent" class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b><% =reportTitle %> For All Classifications (L-D-O)</b></h9>
					</div>
					<br>
					
					<%
					if not rs.eof then 
						%>

						<table class="cNoteTable" align="center" style="border: 0px">
							<thead>
								<tr>
									<th class="alignLeft cNoteFixedCell"><div style="width: 150px;">&nbsp;</div></th>
									<th class="alignCenter cNoteFixedCell"><div style="width: 333px;">LOAN</div></th>
									<th class="alignCenter cNoteFixedCell"><div style="width: 333px;">DEPOSIT</div></th>
									<th class="alignCenter cNoteFixedCell"><div style="width: 333px;">OTHER</div></th>
									<th class="alignCenter cNoteFixedCell"><div style="width: 252px;">TOTAL</div></th>
								</tr>
							</thead>
						</table>

						<table id="ldoTable" class="cNoteTable sortable" align="center" style="border: 0px;">
							<thead>
								<tr>
									<th class="alignLeft  cNoteFixedCellLarge sort" data-sort="summaryColumnHeader"><div style="width: 150px;"><% =summaryColumnHeader %></div></th>
									<th class="alignRight cNoteFixedCellSmall sort" data-sort="loanCount"><div># Accts</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="loanBalance"><div>Balance</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="loanProfit"><div>Profit</div></th>
									<th class="alignRight cNoteFixedCellMedium sort" data-sort="loanInterest"><div>Interest</div></th>
									<th class="alignRight cNoteFixedCellSmall sort" data-sort="depositCount"><div># Accts</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="depositBalance"><div>Balance</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="depositProfit"><div>Profit</div></th>
									<th class="alignRight cNoteFixedCellMedium sort" data-sort="depositInterest"><div>Interest</div></th>
									<th class="alignRight cNoteFixedCellSmall sort" data-sort="otherCount"><div># Accts</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="otherBalance"><div>Balance</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="otherProfit"><div>Profit</div></th>
									<th class="alignRight cNoteFixedCellMedium sort" data-sort="otherInterest"><div>Interest</div></th>
									<th class="alignRight cNoteFixedCellSmall sort" data-sort="totalCount"><div># Accts</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="totalBalance"><div>Balance</div></th>
									<th class="alignRight cNoteFixedCellLarge sort" data-sort="totalProfit"><div>Profit</div></th>
								</tr>
							</thead>
							<tbody class="list" style="height: 550px;">
								<% while not rs.eof %>
									<tr id="<% =rs(0) %>"> 
										
										<td class="alignLeft cNoteFixedCell summaryColumnHeader"><div style="width: 150px;"><% =rs(0) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldo loan count loanCount"><div><% =formatNumber(rs("loanCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo loan balance loanBalance"><div><% =formatCurrency(rs("loanBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo loan profit loanProfit"><div><% =formatCurrency(rs("loanProfit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellMedium ldo loan interest loanInterest"><div><% =formatPercent(rs("loanInterest"),4) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldo deposit count depositCount"><div><% =formatNumber(rs("depositCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo deposit balance depositBalance"><div><% =formatCurrency(rs("depositBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo deposit profit depositProfit"><div><% =formatCurrency(rs("depositProfit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellMedium ldo deposit interest depositInterest"><div><% =formatPercent(rs("depositInterest"),4) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldo other count otherCount"><div><% =formatNumber(rs("otherCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo other balance otherBalance"><div><% =formatCurrency(rs("otherBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldo other profit otherProfit"><div><% =formatCurrency(rs("otherProfit"),0) %></div></td>
										<td class="alignRight cNoteFixedCellMedium ldo other interest otherInterest"><div><% =formatPercent(rs("otherInterest"),4) %></div></td>
										<td class="alignRight cNoteFixedCellSmall ldoTotal totalCount"><div><% =formatNumber(rs("totalCount"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldoTotal totalBalance"><div><% =formatCurrency(rs("totalBalance"),0) %></div></td>
										<td class="alignRight cNoteFixedCellLarge ldoTotal totalProfit"><div><% =formatCurrency(rs("totalProfit"),0) %></div></td>

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
	        
		<ul id="ldoContextMenu" style="display: none;" class="cNoteContextMenu">
			<li class="cNoteCM" onclick="window.location.href='accountHolderList.asp?id=<% =customerID %>&group=[group]&<% =summaryColumnHeader %>=[summary]'">Account Holders w/ [group] Accounts by [summary]</li>
			<li class="cNoteCM" onclick="window.location.href='officerList.asp?id=<% =customerID %>&group=[group]&<% =summaryColumnHeader %>=[summary]'">Officers w/ [group] Accounts by [summary]</li>
			<li class="cNoteCM" onclick="window.location.href='serviceList.asp?id=<% =customerID %>&group=[group]&<% =summaryColumnHeader %>=[summary]'">[group] Services by [summary]</li>
			<li class="cNoteCM" onclick="window.location.href='categorySummary.asp?id=<% =customerID %>&summary=<% =summaryColumnHeader %>&metric=[metric]'">[metric] summary for all <% =pluralName %></li>

			<li><hr></li>
			<li>FUTURE:</li>
			<li class="cNoteCM">[group] [metric] summary for [summary]</li>
			<li class="cNoteCM">[group] summary by account holder for [summary]</li>
			<li class="cNoteCM">[group] summary by account holder for all branches</li>
			<li class="cNoteCM">[group] service summary for [summary]</li>
			<li class="cNoteCM">[group] accounts for [summary]</li>

		</ul>
		
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>

<script>
	
	var cNoteTable = document.getElementById('cNoteTable');
	if (cNoteTable) {
	
		var listOptions = {
			valueNames: [ 
				'summaryColumnHeader', 'loanCount', 'loanBalance', 'loanProfit', 'loanInterest', 'depositCount', 'depositBalance', 'depositProfit', 
				'depositInterest', 'otherCount', 'otherBalance', 'otherProfit', 'otherInterest', 'totalCount', 'totalBalance', 'totalProfit' 
			]
		}
		var reportList = new List ('cNoteTableParent', listOptions);

	}

// 	document.querySelectorAll('.ldo')
// 	.forEach (e => e.addEventListener('mouseover', HighlightGroup ));
// 	
// 	document.querySelectorAll('.ldo')
// 	.forEach (e => e.addEventListener('mouseout', HighlightGroup ));
// 	
	document.querySelectorAll('.cNoteCM')
	.forEach(e => e.addEventListener('mouseover', HightLightCMItem));
	
	document.querySelectorAll('.cNoteCM')
	.forEach(e => e.addEventListener('mouseout', HightLightCMItem));
	

	document.querySelectorAll('.ldo')
	.forEach (e => e.addEventListener('mouseover', HighlightItem ));
	
	document.querySelectorAll('.ldo')
	.forEach (e => e.addEventListener('mouseout', HighlightItem ));
	
// 	document.querySelectorAll('.ldo')
// 	.forEach (e => e.addEventListener('contextmenu', ClassBranchContextMenu ));
		
	var allContextMenuCells = document.getElementsByClassName('ldo');
	for (i = 0; i < allContextMenuCells.length; i++) {
		
		allContextMenuCells[i].addEventListener('contextmenu', function(ev) {

						
			ev.preventDefault();
						
			// find existing context menu; if found, remove it!
			var existingMenu = document.querySelector('.contextMenu');
			if (existingMenu) {
				existingMenu.parentNode.removeChild(existingMenu);
			}
			

			// clone the template menu....
			var menuTemplate = document.getElementById('ldoContextMenu');
			var menu = menuTemplate.cloneNode(true);
			menu.classList.add('contextMenu');

			menu.querySelectorAll('.cNoteCM')
			.forEach(e => e.addEventListener('mouseover', HightLightCMItem));
			
			menu.querySelectorAll('.cNoteCM')
			.forEach(e => e.addEventListener('mouseout', HightLightCMItem));
	



			// apend the menu to the MDL "page-content" <div>...		
			document.querySelector('.page-content').appendChild(menu);
			
			var selectedGroup;
			if (this.classList.contains('loan')) {
				selectedGroup = 'Loan';
			} else if (this.classList.contains('deposit')) {
				selectedGroup = 'Deposit';
			} else {
				selectedGroup = 'Other';
			}
			
			var selectedMetric;
			if (this.classList.contains('count')) {
				selectedMetric = '# Accounts';
			} else if (this.classList.contains('balance')) {
				selectedMetric = 'Balance';
			} else if (this.classList.contains('profit')) {
				selectedMetric = 'Profit';
			} else {
				selectedMetric = 'Interest';
			}
			
			var selectedSummary = this.parentNode.id;
			

			var onclickTemp;
			var menuItems = menu.querySelectorAll('li');
			for (i = 0; i < menuItems.length; i++) {

				menuItems[i].innerHTML = menuItems[i].innerHTML.replace(/\[summary\]/g,selectedSummary);
				menuItems[i].innerHTML = menuItems[i].innerHTML.replace(/\[group\]/g,selectedGroup);
				menuItems[i].innerHTML = menuItems[i].innerHTML.replace(/\[metric\]/g,selectedMetric);
// 				menuItems[i].innerHTML = menuItems[i].innerHTML.replace(/\[summaries\]/g,pluralSummary);

				onclickTemp = menuItems[i].getAttribute('onclick');
				if (onclickTemp) {
					menuItems[i].setAttribute('onclick', menuItems[i].getAttribute('onclick').replace(/\[summary\]/g, selectedSummary));
					menuItems[i].setAttribute('onclick', menuItems[i].getAttribute('onclick').replace(/\[group\]/g, selectedGroup));
					menuItems[i].setAttribute('onclick', menuItems[i].getAttribute('onclick').replace(/\[metric\]/g, selectedMetric));
				}
				
			}
			
			
			
			
			menu.style.display = 'block';
			var newTop = ev.screenY;
// 			if (newTop < 850) {
// 				newTop = newTop + 115;
// 			} else {
// 				newTop = newTop - 200;
// 			}
			var newLeft = ev.screenX;
			
			menu.classList.add('cNoteShowContextMenu');
			menu.style.top = (newTop - 200) + 'px';
			menu.style.left = newLeft + 'px';


			
		}, false);

		
	}
	
	
	document.querySelectorAll('.ldo')
	.forEach (e => e.addEventListener('click', DrillDown_ClassBranch ));
	
	document.querySelectorAll('.ldo')
	.forEach (e => MakeNegativeValueRed(e));
	
	document.querySelectorAll('.ldoTotal')
	.forEach (e => MakeNegativeValueRed(e));
	
	document.addEventListener('click', function(evt) {
		
		// find existing context menu; if found, remove it!
		var existingMenu = document.querySelector('.contextMenu');
		if (existingMenu) {
			existingMenu.parentNode.removeChild(existingMenu);
		}
		
	}, false);
	
// 	MakeNegativeValuesRed();
	
	
</script>



</body>
</html>