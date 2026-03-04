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
serviceName						= request.querystring("service")
productName						= request.querystring("product")

server.scriptTimeout=200 
title = "Profitability: " & productName 
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)

productSQL = 	"select " &_
						"[Product Code and Product Description], " &_
						"COUNT([Product Code and Product Description]) as svccnt, " &_
						"SUM([Balance])/count([Product Code and Product Description]) as bal, " &_
						"SUM([Incremental Profit])/count([Product Code and Product Description]) as profit " &_
					"from pr_pqwebArchive " &_
					"where Service = '" & serviceName & "' " &_
					"and [Product Code] not Like '%999' " &_
					"and customerID = " & customerID & " " &_
					"group by [Product Code and Product Description] " &_
					"order by SUM([Incremental Profit])/count([Product Code and Product Description]) desc "


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
		   currencyFormatter.format(data,2);
		   currencyFormatter.format(data,3);
			
			var columnChartView 	= new google.visualization.DataView(data);
			columnChartView.setColumns([
				0,
				3,
				{
					calc: function(data,row) {
						var val = data.getValue(row,3);
						if (val >= 0.00) {
							return  'green';
						} 
						return 'crimson';
					},
					type: 'string',
					role: 'style'
				}
			]);
			
			
			// CHART: Column Chart...   
		   var columnChart = new google.visualization.BarChart(document.getElementById('columnChart'));
		
		   var columnChartOptions = {
			   title: '<% =className %>: <% =serviceName %> Profit Overview',
			   legend: {
				   position: 'none',
				},
				width: 1000,
				chartArea: {left: 300, width: 700},
				height: 400,
				animation: {
					duration: 1000,
					easing: 'out',
				},
// 				vAxis: {
// 					gridlines: {
// 						count: 0,
// 						color: 'transparent',
// 					},
// 				},
// 				hAxis: {
// 					gridlines: {
// 						count: ,
// 						color: 'transparent',
// 					},
				};
		
			google.visualization.events.addListener(columnChart, 'select', function() {
								
				var selectedItem = columnChart.getSelection()[0];
				if(selectedItem) {
					var product = data.getValue(selectedItem.row, 0);
					window.location.href = "/cProfit/productProfitability.asp?id=<% =customerID %>&class=<% =className %>&service=<% =serviceName %>&product=" + product;
				}

			});


			columnChart.draw(columnChartView, columnChartOptions);
			
			
		   var dataTableView		= new google.visualization.DataView(data);
		   dataTableView.setColumns([
			   {sourceColumn: 0, type: 'string', label: 'Service'},
			   {sourceColumn: 1, type: 'number', label: '# of Accounts'},
			   {sourceColumn: 2, type: 'number', label: 'Average Balance'},
			   {sourceColumn: 3, type: 'number', label: 'Incremental Profit'},
		   ]);

		   var dataTableChart = new google.visualization.Table(document.getElementById('dataTableChart'));
		
		   var dataTableChartOptions = {
			   title: 'Profitability <% =service %> Services Overview',
		   };

			dataTableChart.draw(dataTableView, dataTableChartOptions);

// 	      var topComponents = [
// 	          {type: 'csv', datasource: 'downloadCustomersByProfitability.asp?direction=top'},
// 	      ];
// 	      var topToolbar = document.getElementById('topToolbar');
// 			google.visualization.drawToolbar(topToolbar, topComponents);
	
		

			

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

			<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 15px; text-align: center">
				<%
				set rs = dataconn.execute(productSQL)
				if not rs.eof then 
					%>
					<table class="mdl-data-table mdl-js-data-table" style="display: inline-block;">
					  <thead>
					    <tr>
					      <th class="mdl-data-table__cell--non-numeric">Service</th>
					      <th class="mdl-data-table__cell"># of Accounts</th>
					      <th class="mdl-data-table__cell">Average Balance</th>
					      <th class="mdl-data-table__cell">Incremental Profit</th>
					    </tr>
					  </thead>
					  <tbody>
						  <%
						  while not rs.eof 
						  	  %>
						    <tr onclick="window.location.href = '/cProfit/productProfitability.asp?id=<% =customerID %>&class=<% =className %>&service=<% =serviceName %>&product=<% =rs("Product Code and Product Description") %>'" style="cursor: pointer;">
						      <td class="mdl-data-table__cell--non-numeric"><% =rs("Product Code and Product Description") %></td>
						      <td class="mdl-data-table__cell" <% =numericStyle(rs("svccnt")) %>><% =formatNumber(rs("svccnt"),0) %></td>
						      <td class="mdl-data-table__cell" <% =numericStyle(rs("bal")) %>><% =formatCurrency(rs("bal"),0) %></td>
						      <td class="mdl-data-table__cell" <% =numericStyle(rs("profit")) %>><% =formatCurrency(rs("profit"),0) %></td>
						    </tr>
							 <%
							rs.movenext 
						wend 
						%>						
					  </tbody>
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