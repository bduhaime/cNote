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
<!-- #include file="../includes/jsonDataTable.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(43)

customerID 						= request.querystring("id")
className						= request.querystring("class")
service							= request.querystring("service")
product							= request.querystring("product")

server.scriptTimeout=200 
title = "Profitability: " & service & " Service Products Overview" 
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)

productSQL = "Select " &_
					"[Product Code], " &_
					"Count([Product Code]) as numaccts, " &_
					"Sum([Balance]) as sumBal, " &_
					"Sum(Balance)/Count([Product Code]) as avgBal, " &_
					"Case when sum([Balance]) <> 0 Then Sum([Interest Rate x Balance])/sum(Balance) else 0 End as avgInterestRate, " &_
					"Case when sum([Balance]) <> 0 Then Sum([FTP Rate x Balance])/sum(Balance) else 0 End as avgFTP, " &_
					"sum([Incremental Non-interest Expense]) as sumIncNonIntExp, " &_
					"Sum([Net Interest Income]) as sumnetIntInc, " &_
					"Sum([Non-interest Income]) as sumnonIntInc, " &_
					"Sum([Provision Expense]) as sumProvExp, " &_
					"Sum([Incremental Profit]) as sumIncProfit, " &_
					"[Product Code] as prodcode, " &_
					"[Product Description] as proddesc, " &_
					"[Default Risk Rate] as riskrate, " &_
					"[Loan Deposit Other] as ldo, " &_
					"[Service] as Service, " &_
					"case when count([product code]) <> 0 then Sum([Net Interest Income]) / count([product code]) else 0 end as avgNetIntInc, " &_
					"case when count([product code]) <> 0 then Sum([Non-interest Income]) / count([product code]) else 0 end as avgFee, " &_
					"case when count([product code]) <> 0 then sum ([Incremental Non-interest Expense]) / count([product code]) else 0 end as avgIncCost, " &_
					"case when Sum([Balance]) <> 0 then sum([Provision Expense]) / Sum([Balance]) else 0 end as avgRiskRate, " &_
					"case when count([product code]) <> 0 then Sum([Provision Expense]) / count([product code]) else 0 end as avgIncProvExp, " &_
					"case when count([product code]) <> 0 then Sum([Incremental Profit]) / count([product code]) else 0 end as avgIncProfit " &_
				"from pr_pqwebarchive " &_
				"where [Product Code and Product Description] = '" & product & "' " &_
				"and customerID = " & customerID & " " &_
				"group by [Default Risk Rate], [Product Code] , [Product Description] , [Loan Deposit Other] ,[Service] "


set rs = dataconn.execute(productSQL)

function numericStyle(numericValue)
	
	if isNumeric(numericValue) then 
		if numericValue < 0 then 
			numericStyle = "style=""color: crimson;"""
		else 
			numericStyle = ""
		end if
	else 
		numericStyle = ""
	end if 
	
	
end function


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<!-- 	jQuery -->
	<script type="text/javascript" src="../jQuery/jquery-3.5.1.js"></script>

	<script type="text/javascript" src="../moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

	<script type="text/javascript">

		google.charts.load('current', {'packages':['table','bar','corechart']});
		
		google.charts.setOnLoadCallback(drawVisualization);
		
		function drawVisualization() {
			
			var currencyFormatter = new google.visualization.NumberFormat({
				prefix: '$', 
				fractionDigits: 0,
				negativeColor: 'red', 
				negativeParens: true,
			});
		
			const chartHeight = 300;
		
			var data = new google.visualization.DataTable({ 
				cols: [
					{id: 'metric', type: 'string'},
					{id: 'value', type: 'number'},
					{type: 'string', role: 'style'}
				],
				rows: [
					{c:[{v: 'Average Net Interest Income'},{v: <% =rs("avgNetIntInc") %>},{v: 'color: darkblue'}]},
					{c:[{v: 'Average Fee'},{v: <% =rs("avgFee") %>},{v: 'color: yellow'}]},
					{c:[{v: 'Average Incremental Cost'},{v: <% =rs("avgIncCost") %>},{v: 'color: darkmagenta'}]},
					{c:[{v: 'Average Provision	Expense'},{v: <% =rs("avgIncProvExp") %>},{v: 'color: orange'}]},
					{c:[{v: 'Average Incremental Profit'},{v: <% =rs("avgIncProfit") %>},{v: 'color: green'}]}
				]
			});
		   currencyFormatter.format(data,1);
		   
							
			// CHART: Column Chart...   
		   var columnChart = new google.visualization.ColumnChart(document.getElementById('columnChart'));
		
		   var columnChartOptions = {
			   title: '<% =className %> -- <% =service %>: <% =product %> Overview',
			   legend: {
				   position: 'none',
				},
				width: 1020,
				height: 300,
				hAxis: {
					gridlines: {
						count: 0,
						color: 'transparent',
					},
				},
				vAxis: {
					format: 'short',
				}
		   };
		

			columnChart.draw(data, columnChartOptions);
			
			
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
  
		<div class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>
		
	
	<div class="page-content">
	<!-- Your content goes here -->

		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 15px;">
				<div id="columnChart" style="display: inline-block;"><!-- columnChart --></div>
			</div>
	
			<div class="mdl-layout-spacer"></div>
		
		</div>
	
		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="padding: 15px; text-align: center">
				<%
				rs.movefirst 
				if not rs.eof then 
					%>

					<table class="mdl-data-table mdl-js-data-table" style="display: inline-block;">
					  <thead>
					    <tr>
					      <th class="mdl-data-table__cell--non-numeric" colspan="2">Overview</th>
					    </tr>
					  </thead>
					  <tbody>
<!--
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Loan / Deposit / Other</td>
					      <td><% =className %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Service</td>
					      <td><% =serviceName %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Product Code</td>
					      <td><% =rs("prodcode") %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Product Description</td>
					      <td><% =rs("proddesc") %></td>
					    </tr>
-->
					    <tr onclick="window.location.href='/cProfit/accountSummary.asp?customerID=<% =customerID %>&product=<% =product %>'" style="cursor: pointer;">
					      <td class="mdl-data-table__cell--non-numeric">Number of Accounts</td>
					      <td><% =formatNumber(rs("numaccts"),0) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Balance</td>
					      <td><% =formatCurrency(rs("sumBal"),2) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Balance</td>
					      <td><% =formatCurrency(rs("avgBal"),2) %></td>
					    </tr>
					  </tbody>
					</table>
			</div>
			
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="padding: 15px; text-align: center">


					<table class="mdl-data-table mdl-js-data-table" style="display: inline-block;">
					  <thead>
					    <tr>
					      <th class="mdl-data-table__cell--non-numeric" colspan="2">Profitability Averages Per Account</th>
					    </tr>
					  </thead>
					  <tbody>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Interest Rate</td>
					      <td <% =numericStyle(rs("avgInterestRate")) %>><% =FormatPercent(rs("avgInterestRate")/100,4) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average FTP Rate</td>
					      <td <% =numericStyle(rs("avgFTP")) %>><% =FormatPercent(rs("avgFTP")/100,4) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Spread</td>
					      <td <% =numericStyle((rs("avgFTP")/100)-(rs("avgInterestRate")/100)) %>><% =FormatPercent((rs("avgFTP")/100)-(rs("avgInterestRate")/100),4) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Net Interest Income</td>
					      <td <% =numericStyle(rs("avgNetIntInc")) %>><% =formatCurrency(rs("avgNetIntInc"),2) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Fee</td>
					      <td <% =numericStyle(rs("avgFee")) %>><% =formatCurrency(rs("avgFee"),0) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Incremental Cost</td>
					      <td <% =numericStyle(rs("avgIncCost")) %>><% =formatCurrency(rs("avgIncCost"),0) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Provision Risk Rate</td>
					      <td <% =numericStyle(rs("avgRiskRate")) %>><% =formatPercent(rs("avgRiskRate")/100,4) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Provision Expense</td>
					      <td <% =numericStyle(rs("avgIncProvExp")) %>><% =formatCurrency(rs("avgIncProvExp"),0) %></td>
					    </tr>
					    <tr>
					      <td class="mdl-data-table__cell--non-numeric">Average Incremental Profit</td>
					      <td <% =numericStyle(rs("avgIncProfit")) %>><% =formatCurrency(rs("avgIncProfit"),0) %></td>
					    </tr>
					  </tbody>
					</table>
					
					<%
				end if 
				rs.close 
				set rs = Nothing
				%>

			</div>
	
			<div class="mdl-layout-spacer"></div>
		
		</div>
	
	</div>
        
</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>