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

customerID = request.querystring("customerID")

// Branch...
if len(request.querystring("branch")) > 0 then 
	dbug("branch present in querystring: " & request.querystring("branch")) 
	branch = "'" & request.querystring("branch") & "'" 
	branchPredicate = "and [branch description] = " & branch & " " 
else 
	branch = "null" 
	branchPredicate = "" 
end if 
if branch <> "null" then 
	subtitle = "Branch = " & branch
end if
dbug("branch: " & branch)



server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)

productSQL = "select " &_
					"1 as seq, " &_
					"[Classification Order], " &_
					"[Loan Deposit Other] as ldo, " &_
					"count([Loan Deposit Other]) as cldo, " &_
					"sum([Balance]) as bal, " &_
					"sum(Profit) as profit, " &_
					"sum(Profit) / (select sum(Profit) from pr_pqwebArchive where customerID = " & customerID & ") as percentTot " &_
				"from pr_pqwebArchive " &_
				"where  [Service] <> 'Investment & Borrowing' " &_
				"and customerID = " & customerID & " " &_
				branchPredicate &_
				"group by [Classification Order], [Loan Deposit Other] " &_
				"UNION " &_
				"select  " &_
					"2 as seq, " &_
					"[Classification Order], " &_
					"[Product Code] as ldo, " &_
					"count([Loan Deposit Other]) as cldo, " &_
					"sum([Balance]) as bal, " &_
					"sum(Profit) as profit, " &_
					"sum(Profit) / (select sum(Profit) from pr_pqwebArchive where customerID = " & customerID & ") as percentTot " &_
				"from pr_pqwebArchive " &_
				"where  [Service] = 'Investment & Borrowing' " &_
				"and customerID = " & customerID & " " &_
				branchPredicate &_
				"group by [Classification Order], [Product Code] " &_
				"order by 1, 2, 3 "

dbug(productSQL) 

data = jsonDataTable(productSQL)

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
		
			var data = new google.visualization.DataTable(<% =data %>);
		   currencyFormatter.format(data,4);
		   currencyFormatter.format(data,5);
		   currencyFormatter.format(data,6);
			
			var columnChartView 	= new google.visualization.DataView(data);
			columnChartView.setColumns([
				2,
				5,
				{
					calc: function(data,row) {
						var val = data.getValue(row,5);
						if (val >= 0.00) {
							return  'green';
						} 
						return 'crimson';
					},
					type: 'string',
					role: 'style'
				}
			]);
			columnChartView.setRows([0,1,2]);
// 			columnChartView.hideRows([3,4]);
			
			
			// CHART: Column Chart...   
		   var columnChart = new google.visualization.ColumnChart(document.getElementById('columnChart'));
		
		   var columnChartOptions = {
			   title: 'Product Profit Overview',
			   legend: {
				   position: 'none',
				},
				width: 1020,
				height: 300,
				animation: {
					duration: 1000,
					easing: 'out',
				},
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
		
			google.visualization.events.addListener(columnChart, 'select', function() {
								
				var selectedItem = columnChart.getSelection()[0];
				if(selectedItem) {
					var classification = data.getValue(selectedItem.row, 2);
					window.location.href = "/cProfit/serviceOverview.asp?id=<% =customerID %>&class=" + classification;
				}

			});


			columnChart.draw(columnChartView, columnChartOptions);
			
	  }
	 
  </script>
  
  <style>
	  
		.reportTitle {
			text-align: center;
			font-size: large;
			font-weight: bold;
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
  
		<div class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>
		
	
	<div class="page-content">
	<!-- Your content goes here -->

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--9-col reportTitle">Product Overview<br><% =subtitle %></div>
			<div class="mdl-layout-spacer"></div>
		</div>

		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 15px;">
				<div id="columnChart" style="display: inline-block;"><!-- columnChart --></div>
			</div>
	
			<div class="mdl-layout-spacer"></div>
		
		</div>
	
		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 15px; text-align: center">

				<%
				set rs = dataconn.execute(productSQL)
				if not rs.eof then 
					%>
					<table class="mdl-data-table mdl-js-data-table" style="display: inline-block;">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Classification</th>
								<th class="mdl-data-table__cell"># of Accounts</th>
								<th class="mdl-data-table__cell">Balance</th>
								<th class="mdl-data-table__cell">Profit</th>
								<th class="mdl-data-table__cell">% of Total</th>
							</tr>
						</thead>
						<tbody>
						<%
						while not rs.eof 
							%>
							<tr onclick="window.location.href = '/cProfit/serviceOverview.asp?id=<% =customerID %>&class=<% =rs("ldo") %>'" style="cursor: pointer;">
								<td class="mdl-data-table__cell--non-numeric"><% =rs("ldo") %></td>
								<td class="mdl-data-table__cell" <% =numericStyle(rs("cldo")) %>><% =formatNumber(rs("cldo"),0) %></td>
								<td class="mdl-data-table__cell" <% =numericStyle(rs("bal")) %>><% =formatCurrency(rs("bal"),0) %></td>
								<td class="mdl-data-table__cell" <% =numericStyle(rs("profit")) %>><% =formatCurrency(rs("profit"),0) %></td>
								<td class="mdl-data-table__cell" <% =numericStyle(rs("percentTot")) %>><% =formatPercent(rs("percentTot"),2) %></td>
							</tr>
							<%
							totalAccounts = totalAccounts + rs("cldo")
							totalBalance = totalBalance + rs("bal")
							totalProfit = totalProfit + rs("profit")
							rs.movenext 
						wend 
						%>						
						</tbody>
						<tfoot>
							<tr>
								<th class="mdl-data-table__cell">Total</th>
								<th class="mdl-data-table__cell" <% =numericStyle(totalAccounts) %>><% =formatNumber(totalAccounts,0) %></th>
								<th class="mdl-data-table__cell" <% =numericStyle(totalBalance) %>><% =formatCurrency(totalBalance,0) %></th>
								<th class="mdl-data-table__cell" <% =numericStyle(totalProfit) %>><% =formatCurrency(totalProfit,0) %></th>
								<th class="mdl-data-table__cell" <% =numericStyle(1) %>><% =formatPercent(1,2) %></th>
							</tr>
						</tfoot>
					</table>
					<%
				end if 
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