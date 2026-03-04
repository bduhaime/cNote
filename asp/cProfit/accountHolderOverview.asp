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

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

subtitle = "Profitability: Account Holder Overview" 
userLog(title)


SQL = "select decile, round(sum(profit),0), count(distinct [account holder number]) as accountHolders " &_
		"from pr_pqwebarchive " &_
		"where decile > 0 " &_
		"and customerID = " & customerID & " " &_
		"group by decile " &_
		"order by decile "
byDecile = jsonDataTable(SQL)



SQL = "select centile, round(sum(profit),0), count(distinct [account holder number]) as accountHolders " &_
		"from pr_pqwebarchive " &_
		"where centile > 0 " &_
		"and customerID = " & customerID & " " &_
		"group by centile " &_
		"order by centile "
byCentile = jsonDataTable(SQL)



SQL = "select centile, round(sum(profit),0) as [Profit], count(distinct [account holder number]) as accountHolderCount " &_
		"from " &_
			"( " &_
			"select " &_
				"case when centile = 1 then 1 else 99 end as centile, " &_
				"profit, " &_
				"[account holder number] " &_
			"from pr_pqwebarchive " &_
			"where centile > 0 " &_
			"and customerID = " & customerID & " " &_
			") as x " &_
		"group by centile " &_
		"order by centile "
byNinetyNine = jsonDataTable(SQL)



SQL = "select " &_
			"[Profitability], " &_
			"sum(netProfit) as Profit, " &_
			"count(*) " &_
		"from " &_
			"( " &_
			"select " &_
				"[account holder number], " &_
				"case when netProfit > 0 then 'Profitable' else 'Unprofitable' end as [Profitability], " &_
				"netProfit, " &_
				"row_number() over (order by netProfit desc) as [Rank] " &_
			"from " &_
				"( " &_
				"select " &_
					"[account holder number], " &_
					"sum(profit) as netProfit " &_
				"from pr_pqwebarchive " &_
				"where centile > 0 " &_
				"and customerID = " & customerID & " " &_
				"group by [account holder number] " &_
				") as x " &_
			") as y " &_
		"group by Profitability " &_
		"order by 1 "
byProfit = jsonDataTable(SQL)



SQL = "select " &_
			"[account holder grade], " &_
			"count(distinct [account holder number]) as gradeCount " &_
		"from pr_pqwebarchive " &_
		"where [account holder grade] <> '' " &_
		"and customerID = " & customerID & " " &_
		"group by [account holder grade] " &_
		" order by 1 "
byGrade = jsonDataTable(SQL)



SQL = "select 'Top 1%', avg(relationshipAge) as avgRelationshipAge " &_
		"from ( " &_
			"select [account holder number], datediff(year,min([open date]),getDate()) as relationshipAge " &_
			"from pr_pqwebarchive " &_
			"where centile = 1 " &_
			"and customerID = " & customerID & " " &_
			"group by [account holder number] " &_
			") as x " &_
		"union all " &_
		"select 'All', avg(relationshipAge) as avgRelationshipAge " &_
		"from ( " &_
			"select [account holder number], datediff(year,min([open date]),getDate()) as relationshipAge " &_
			"from pr_pqwebarchive " &_
			"where centile between 1 and 100 " &_
			"and customerID = " & customerID & " " &_
			"group by [account holder number] " &_
			") as y " &_
		"union all " &_
		"select 'Profitable', avg(relationshipAge) as avgRelationshipAge " &_
		"from ( " &_
			"select [account holder number], sum([profit]) as netProfit, datediff(year,min([open date]),getDate()) as relationshipAge " &_
			"from pr_pqwebarchive " &_
			"where centile between 1 and 100 " &_
			"and customerID = " & customerID & " " &_
			"group by [account holder number] " &_
			"having sum([profit]) > 0 " &_
			") as z " &_
		"union all " &_
		"select 'Unprofitable', avg(relationshipAge) as avgRelationshipAge " &_
		"from ( " &_
			"select [account holder number], sum([profit]) as netProfit, datediff(year,min([open date]),getDate()) as relationshipAge " &_
			"from pr_pqwebarchive " &_
			"where centile between 1 and 100 " &_
			"and customerID = " & customerID & " " &_
			"group by [account holder number] " &_
			"having sum([profit]) <= 0 " &_
			") as w "
byAge = jsonDataTable(SQL)


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<!-- 	jQuery -->
	<script type="text/javascript" src="../jQuery/jquery-3.5.1.js"></script>



	<script type="text/javascript" src="../moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

	<script type="text/javascript">

		// this little script automatically refreshes this page is the user navigates here using browser's back arrow		
		if(!!window.performance && window.performance.navigation.type == 2) {
			window.location.reload();
		}

		window.addEventListener('load', function() {
			
			const allAccountHoldersDiv = document.querySelector('div.allAccountHolders');
			if (allAccountHoldersDiv) {
				allAccountHoldersDiv.addEventListener('click', function() {
					window.location.href = '/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>';
				});
			}
			
			const allStarAccountHoldersDiv = document.querySelector('div.allStarAccountHolders');
			if (allStarAccountHoldersDiv) {
				allStarAccountHoldersDiv.addEventListener('click', function() {
					var allStarCount = allStarAccountHoldersDiv.querySelector('div.allStarAccountHoldersCount').textContent;
					if (allStarCount) {
						if (allStarCount != '0') {
							window.location.href = '/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&allStar=true';
						}
					}
				});
			}
			
			const flaggedAccountHolders = document.querySelectorAll('table tr.accountHoldersByFlag');
			if ( flaggedAccountHolders ) {
				for ( i = 0; i < flaggedAccountHolders.length; ++i ) {
					flaggedAccountHolders[i].addEventListener('click', function() {
						
						window.location.href = '/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&flagID=' + this.id;
						
					})
				}
			}
			
		});

		google.charts.load('50', {'packages':['table','bar','corechart','controls']});
		
		google.charts.setOnLoadCallback(drawVisualization);
		
		function drawVisualization() {
			
			var currencyFormatter = new google.visualization.NumberFormat({
				prefix: '$', 
				fractionDigits: 0,
				negativeParens: true,
			});
		
			const chartHeight = 225;
			const chartWidthWide = 600;
			const chartWidthNarrow = 300
		
			var decileData 		= new google.visualization.DataTable(<% =byDecile %>);
		   currencyFormatter.format(decileData,1);

		   var decileOptions = {
			   title: 'Account Holder Profitability By Decile',
			   legend: {
				   position: 'none',
				},
				annotations: {
					alwaysOutside: true,
				},
				tooltip: {
					isHtml: true,
				},
				width: chartWidthWide,
				height: chartHeight,
				animation: {
					duration: 1000,
					startup: true,
					easing: 'out',
				},
				hAxis: {
					gridlines: {
						count: 0,
						color: 'transparent',
					},
					format: 'percent',
					ticks: [
						{v: 10, f: '10%'},
						{v: 20, f: '20%'},
						{v: 30, f: '30%'},
						{v: 40, f: '40%'},
						{v: 50, f: '50%'},
						{v: 60, f: '60%'},
						{v: 70, f: '70%'},
						{v: 80, f: '80%'},
						{v: 90, f: '90%'},
						{v: 100, f: '100%'},
					],
				},
				vAxis: {
					format: 'short',
				}
		   };
		

			// CHART: Column Chart By Decile...   
			var decileDataView 	= new google.visualization.DataView(decileData);
			decileDataView.setColumns([
				0,
				1,
				{
					calc: function(decileData,row) {
						var val = decileData.getValue(row,1);
						if (val > 0) {
							return  'green';
						} 
						return 'crimson';
					},
					type: 'string',
					role: 'style'
				},
				{
					calc: function(decileData,row) {
						var decile = decileData.getValue(row,0);
						var profitAmount = decileData.getFormattedValue(row,1);
						var accountHolderCount = decileData.getValue(row,2);
						return '<table style="border-collapse: collapse;"><tr><th align="right">Decile:</th><td>' + decile + '%</td></tr><tr><th align="right">Total Profit:</th><td>' + profitAmount+ '</td></tr><tr><th align="right"># Account Holders:</th><td>' + accountHolderCount + '</td></tr></table>';
					},
					type: 'string', 
					role: 'tooltip', 
					properties: {html: true},
				},
			]);
			
		   var byDecile = new google.visualization.ColumnChart(document.getElementById('byDecile'));

			google.visualization.events.addListener(byDecile, 'select', function() {
								
				var selectedItem = byDecile.getSelection()[0];
				if(selectedItem) {
					var decile = decileData.getValue(selectedItem.row, 0);
					window.location.href = "/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&decile=" + decile;
				}

			});

			byDecile.draw(decileDataView, decileOptions);
			
			
			
			
			// CHART: Column Chart By Centile...   
			var centileData 		= new google.visualization.DataTable(<% =byCentile %>);
		   currencyFormatter.format(centileData,1);

		   var centileOptions = {
			   title: 'Account Holder Profitability By Centile',
			   legend: {
				   position: 'none',
				},
				enableInteractivity: true,
				tooltip: {
					isHtml: true,
				},
				annotations: {
					alwaysOutside: true,
				},
				width: chartWidthWide,
				height: chartHeight,
				animation: {
					duration: 1000,
					startup: true,
					easing: 'out',
				},
				hAxis: {
					gridlines: {
						count: 0,
						color: 'transparent',
					},
					format: 'percent',
					ticks: [
						{v: 10, f: '10%'},
						{v: 20, f: '20%'},
						{v: 30, f: '30%'},
						{v: 40, f: '40%'},
						{v: 50, f: '50%'},
						{v: 60, f: '60%'},
						{v: 70, f: '70%'},
						{v: 80, f: '80%'},
						{v: 90, f: '90%'},
						{v: 100, f: '100%'},
					],
				},
				vAxis: {
					format: 'short',
				}
		   };

			var centileDataView 	= new google.visualization.DataView(centileData);
			centileDataView.setColumns([
				0,
				1,
				{
					calc: function(centileData,row) {
						var val = centileData.getValue(row,1);
						if (val > 0) {
							return  'green';
						} 
						return 'red';
					},
					type: 'string',
					role: 'style'
				},
				{
					calc: function(centileData,row) {
						var centile = centileData.getValue(row,0);
						var profitAmount = centileData.getFormattedValue(row,1);
						var accountHolderCount = centileData.getValue(row,2);
						return '<table style="border-collapse: collapse;"><tr><th align="right">Centile:</th><td>' + centile + '%</td></tr><tr><th align="right">Total Profit:</th><td>' + profitAmount+ '</td></tr><tr><th align="right"># Account Holders:</th><td>' + accountHolderCount + '</td></tr></table>';
					},
					type: 'string', 
					role: 'tooltip', 
					properties: {html: true},
				},
			]);

		   var byCentile = new google.visualization.ColumnChart(document.getElementById('byCentile'));

			google.visualization.events.addListener(byCentile, 'select', function() {
								
				var selectedItem = byCentile.getSelection()[0];
				if(selectedItem) {
					var centile = centileData.getValue(selectedItem.row, 0);
					window.location.href = "/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&centile=" + centile;
				}

			});

			byCentile.draw(centileDataView, centileOptions);


			// CHART: Column Chart By 1% vs 99%...   
			var ninetyNineData 		= new google.visualization.DataTable(<% =byNinetyNine %>);
		   currencyFormatter.format(ninetyNineData,1);

			var ninetyNineDataView 	= new google.visualization.DataView(ninetyNineData);
			ninetyNineDataView.setColumns([
				0,
				1,
				{
					calc: function(ninetyNineData,row) {
						var val = ninetyNineData.getValue(row,1);
						if (val > 0.00) {
							return  'green';
						} 
						return 'crimson';
					},
					type: 'string',
					role: 'style'
				},
				{
					calc: 'stringify',
					sourceColumn: 1,
					type: 'string',
					role: 'annotation',
				},
				{
					calc: function(ninetyNineData,row) {
						var centile = ninetyNineData.getValue(row,0);
						var profitAmount = ninetyNineData.getFormattedValue(row,1);
						var accountHolderCount = ninetyNineData.getValue(row,2);
						return '<table style="border-collapse: collapse;"><tr><th align="right">Centile:</th><td>' + centile + '%</td></tr><tr><th align="right">Total Profit:</th><td>' + profitAmount+ '</td></tr><tr><th align="right"># Account Holders:</th><td>' + accountHolderCount + '</td></tr></table>';
					},
					type: 'string', 
					role: 'tooltip', 
					properties: {html: true},
				},
			]);

		   var optionsNinetyNine = {
			   title: 'Account Holder Profit',
			   legend: {
				   position: 'none',
				},
				annotations: {
					alwaysOutside: true,
				},
				tooltip: {
					isHtml: true,
// 					ignoreBounds: true,
				},
				width: chartWidthNarrow,
				height: chartHeight,
				bar: {groupWidth: "45%"},
				hAxis: {
					baselineColor: 'transparent',
					gridlines: {
						count: 0,
						color: 'transparent',
					},
					ticks: [
						{v: 1, f: 'Top 1%'},
						{v: 99, f: 'Bottom 99%'},
					],
				},
				vAxis: {
					format: 'short',
				}
		   };
		

		   var byNinetyNine = new google.visualization.ColumnChart(document.getElementById('byNinetyNine'));

			google.visualization.events.addListener(byNinetyNine, 'select', function() {
								
				var selectedItem = byNinetyNine.getSelection()[0];
				if(selectedItem) {
					var ninetyNine = ninetyNineData.getValue(selectedItem.row, 0);
					window.location.href = "/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&ninetyNine=" + ninetyNine;
				}

			});

			byNinetyNine.draw(ninetyNineDataView, optionsNinetyNine);


			// CHART: Pie Chart By Profitability...   
			var byProfitData 		= new google.visualization.DataTable(<% =byProfit %>);
		   currencyFormatter.format(byProfitData,1);

			var byProfitDataView = new google.visualization.DataView(byProfitData);
			byProfitDataView.setColumns([
				0,
				2,
				{
					calc: function(byProfitData,row) {
						var category = byProfitData.getValue(row,0);
						var accountHolderCount = byProfitData.getValue(row,2);
						var profitAmount = byProfitData.getFormattedValue(row,1);
						return '<table style="border-collapse: collapse;"><tr><th align="center" colspan="2">' + category + '</th></tr><tr><th align="right">Total Profit:</th><td>' + profitAmount+ '</td></tr><tr><th align="right"># Account Holders:</th><td>' + accountHolderCount + '</td></tr></table>';
					},
					type: 'string', 
					role: 'tooltip', 
					properties: {html: true},
				},
			]);

		   var optionsByProfit = {
			   title: 'Number of Account Holders',
			   legend: {
				   position: 'bottom',
				},
				tooltip: {
					isHtml: true,
// 					ignoreBounds: true,
				},
				width: chartWidthNarrow,
				height: chartHeight,
				pieSliceText: 'value',
				slices: {  
					0: {offset: 0.2},
				},
				colors:['green','crimson'],
				pieStartAngle: 30,
		   };
		
			
		   var byProfit = new google.visualization.PieChart(document.getElementById('byProfit'));

			google.visualization.events.addListener(byProfit, 'select', function() {
								
				var selectedItem = byProfit.getSelection()[0];
				if(selectedItem) {
					var profitability;
					if (selectedItem.row == 0) {
						profitability = 'profitable';
					} else {
						profitability = 'unprofitable';
					}
					window.location.href = "/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&profitability=" + profitability;
				}

			});

			byProfit.draw(byProfitDataView, optionsByProfit);






			// CHART: Pie Chart By Grade...   
			var byGradeData = new google.visualization.DataTable(<% =byGrade %>);

// 			var byProfitDataView = new google.visualization.DataView(byProfitData);
// 			byProfitDataView.setColumns([
// 				0,
// 				1,
// 				{
// 					calc: function(byProfitData,row) {
// 						var category = byProfitData.getValue(row,0);
// 						var accountHolderCount = byProfitData.getValue(row,2);
// 						var profitAmount = byProfitData.getFormattedValue(row,1);
// 						return '<table style="border-collapse: collapse;"><tr><th align="center" colspan="2">' + category + '</th></tr><tr><th align="right">Total Profit:</th><td>' + profitAmount+ '</td></tr><tr><th align="right"># Account Holders:</th><td>' + accountHolderCount + '</td></tr></table>';
// 					},
// 					type: 'string', 
// 					role: 'tooltip', 
// 					properties: {html: true},
// 				},
// 			]);

		   var optionsByGrade = {
			   title: 'Account Holder Grades',
			   legend: {
				   position: 'bottom',
				},
				tooltip: {
					isHtml: true,
// 					ignoreBounds: true,
				},
				width: chartWidthNarrow,
				height: chartHeight,
				pieSliceText: 'value',
// 				slices: {  
// 					0: {offset: 0.2},
// 				},
// 				colors:['green','crimson'],
// 				pieStartAngle: 30,
		   };
		
			
		   var byGrade = new google.visualization.PieChart(document.getElementById('byGrade'));

			google.visualization.events.addListener(byGrade, 'select', function() {
								
				var selectedItem = byGrade.getSelection()[0];
				if(selectedItem) {
					var grade;
					switch (selectedItem.row) {
						case 0:
							grade = 'A';
							break;
						case 1:
							grade = 'B';
							break;
						case 2:
							grade = 'C';
							break;
						default: 
							grade = 'D';
							break;
					}
					window.location.href = "/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&grade=" + grade;
				}

			});

			byGrade.draw(byGradeData, optionsByGrade);



			// CHART: Column Chart By Age...   
			var ageData 		= new google.visualization.DataTable(<% =byAge %>);

			var ageDataView = new google.visualization.DataView(ageData);
			ageDataView.setColumns([
				0,
				1,
				{
					calc: function(ageData,row) {
						var val = ageData.getValue(row,0);
						if (val == 'Top 1%') {
							return  'royalblue';
						} else if (val == 'All') {
							return 'purple';
						} else if (val == 'Profitable') {
							return 'green';
						}
						return 'crimson';
					},
					type: 'string',
					role: 'style'
				},
			]);

		   var optionsAge = {
			   title: 'Average Length Of Relationship',
			   legend: {
				   position: 'none',
				},
				annotations: {
					alwaysOutside: true,
				},
				width: chartWidthWide,
				height: chartHeight,
				bar: {groupWidth: "45%"},
				hAxis: {
					baselineColor: 'transparent',
					gridlines: {
						count: 0,
						color: 'transparent',
					},
				},
		   };
		

		   var byAge = new google.visualization.ColumnChart(document.getElementById('byAge'));
			byAge.draw(ageDataView, optionsAge);




	  }
	 
  </script>


	<style>
	  
		div.mdl-grid {
			padding-bottom: 0px;
			padding-top: 5px;
		}

		div.chartCell {
			text-align: center;
			padding-left: 5px;
			padding-right: 5px;
			padding-top: 0px;
			padding-bottom: 0px;
		}
		
		div.chartContainer {
			display: inline-block;
		}
		
		div.findAccountHolder {
			font-size: 14px;
			font-weight: 400;
		}
		
		div.totalAccountHolders {
			height: 100%;
			position: relative;
  		}
  		
		div.totalAccountHolders div {
			margin: 0;
			position: absolute;
			top: 50%;
			left: 50%;
			-ms-transform: translate(-50%, -50%);
			transform: translate(-50%, -50%);
			font-size: 72px;
			font-weight: bolder;
		}

		div.allAccountHolders:hover, div.allStarAccountHolders {
			cursor: pointer;
		}

		/* This is a fix/hack to address "tooltip flicker" on Google Charts */
		svg > g:last-child > g:last-child { pointer-events: none }
		div.google-visualization-tooltip { pointer-events: none } 

		table tr.accountHoldersByFlag:hover {
			cursor: pointer;
			background-color: lightgrey;
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

			<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp chartCell">
				<div id="byDecile" class="chartContainer"><!-- byDecile --></div>
			</div>
	
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp chartCell">
				<div id="byNinetyNine" class="chartContainer"><!-- byNinetyNine --></div>
			</div>
	
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp chartCell">
				<div id="search" class="findAccountHolder">
					<div style="float: left;">Account Holders by Flag:</div>
					<br>
					<table style="margin-left: auto; margin-right: auto; border-collapse: collapse;">
						<%
						SQL = "SELECT f.id, f.name, f.priority, f.color, count(distinct [Account Holder Number]) as accountHolders " &_
								"FROM flags f " &_
								"left join pr_accountHolderAddenda a on (a.flagID = f.id) " &_
								"group by f.id, f.name, f.priority, f.color " &_
								"ORDER BY priority "
						set rsFlags = dataconn.execute(SQL) 
						while not rsFlags.eof 
							%>
							<tr id="<% =rsFlags("id") %>" class="accountHoldersByFlag">
								<td class="flagIcon" style="padding-top: 0; padding-bottom: 0;"><i class="material-icons" style="color: <% =rsFlags("color") %>">flag</i></td>
								<td class="flagName" style="padding-top: 0; padding-bottom: 0; text-align: left;"><% =rsFlags("name") %></td>
								<td class="accountHolderCount" style="padding-top: 0; padding-bottom: 0; text-align: right; min-width: 25px"><% =formatNumber(rsFlags("accountHolders"),0) %></td>
							</tr>
							<%
							rsFlags.movenext 
						wend 
						rsFlags.close 
						set rsFlags = nothing 						
						%>
					</table>
				</div>
			</div>
	
			<div class="mdl-layout-spacer"></div>
		
		</div>
	
		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp chartCell">
				<div id="byCentile" class="chartContainer"><!-- byCentile --></div>
			</div>
	
			<div id="byProfitDashboard" class="mdl-cell mdl-cell--3-col mdl-shadow--2dp chartCell">
				<div id="byProfit" class="chartContainer"><!-- byProfit --></div>
				<div id="byProfitRnage" class="chartContainer"><!-- byProfitRange--></div>
			</div>
	
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp chartCell allAccountHolders" style="background-color: rgb(63,81,181); color: white;">
				<div style="float: left;">All Account Holders:</div>
				<%
				SQL = "select count(distinct [account holder number]) as totalAccountHolders " &_
						"from pr_PQWebArchive " &_
						"where [Account Holder Number] <> '0' " &_
						"and not ([Branch Description] = 'Treasury' OR [Officer Name] = 'Treasury') " &_
						"and not ([Branch Description] = 'Manually Added Accounts') " &_
						"and [Account Holder Number] <> 'Manually Added Accounts' " &_
						"and customerID = " & customerID & " " 
						
				set rsAH = dataconn.execute(SQL) 
				totalAccountHolders = rsAH("totalAccountHolders") 
				rsAH.close 
				set rsAH = nothing 
				%>
				<div id="totalAccountHolders" class="totalAccountHolders">
					<div><% =formatNumber(totalAccountHolders,0) %></div>
				</div>
			</div>
			
			<div class="mdl-layout-spacer"></div>
		
		</div>
	

		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp chartCell">
				<div id="byAge" class="chartContainer"><!-- byAge --></div>
			</div>
	
			<div id="byProfitDashboard" class="mdl-cell mdl-cell--3-col mdl-shadow--2dp chartCell">
				<div id="byGrade" class="chartContainer"><!-- byGrade --></div>
			</div>

			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp chartCell allStarAccountHolders" style="background-color: rgb(63,81,181); color: white;">
				<div style="float: left;">Top 100&trade; Account Holders:</div>
				<%
				SQL = "select count(distinct x.[account holder number]) as totalAccountHolders " &_
						"from pr_PQWebArchive x " &_
						"join pr_accountHolderAddenda y on (y.customerID = x.customerID AND y.[account holder number] = x.[account holder number] AND y.type = 3) " &_
						"where x.[Account Holder Number] <> '0' " &_
						"and not (x.[Branch Description] = 'Treasury' OR x.[Officer Name] = 'Treasury') " &_
						"and not (x.[Branch Description] = 'Manually Added Accounts') " &_
						"and x.[Account Holder Number] <> 'Manually Added Accounts' " &_
						"and x.customerID = " & customerID & " " 
							
						
				set rsAH = dataconn.execute(SQL) 
				totalAccountHolders = rsAH("totalAccountHolders") 
				rsAH.close 
				set rsAH = nothing 
				%>
				<div id="totalAccountHolders" class="totalAccountHolders">
					<div class="allStarAccountHoldersCount"><% =formatNumber(totalAccountHolders,0) %></div>
				</div>
			</div>
	
			<div class="mdl-layout-spacer"></div>
		
		</div>
	

	</div>
        
</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>