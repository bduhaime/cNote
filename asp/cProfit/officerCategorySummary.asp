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

customerID = request.querystring("id")
selectedClass = request.querystring("class")
selectedService = request.querystring("service")


if len(request.querystring("metric")) > 0 then 
	selectedMetric = request.querystring("metric")
else 
	selectedMetric = "Profit"
end if

if len(request.querystring("summary")) > 0 then 
	selectedSummary = request.querystring("summary")
else 
	selectedSummary = "Officer"
end if

select case selectedSummary
	case "Branch"
		summaryColumn = "[Branch Description]"
	case "Officer"
		summaryColumn = "[Officer Name]"
	case else 
		summaryColumn = "[Officer Name]"
end select 


select case selectedMetric
	case "Profit"
		metricColumn = "[profit]"
		metricFormatterName = "currencyFormatter"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
	case "Balance"
		metricColumn = "[balance]"
		metricFormatterName = "currencyFormatter"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
	case "Interest Rate"
		metricColumn = "case when sum([balance]) <> 0 then sum([interest rate x balance]) / sum([balance]) else 0 end "
		metricFormatterName = "percentFormatter"
		metricSummaryFunction = "avg"
		metricSummaryRowTitle = "Average"
		metricSummaryGroupby = "group by " & summaryColumn & ", [loan deposit other] "
		dataViewColumns = "[0,1,2,3]"
	case "Number of Accounts"
		metricColumn = "1"
		metricFormatterName = "integerFormatter"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
	case else 
		metricColumn = "[profit]"
		metricFormatterName = "currencyFormatter"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
end select 


server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title

suntitle = "Profitability: Officer Classification Overview" 
userLog(title)

SQL = "select pivotColumnName " &_
		"from " &_
			"( " &_
			"select distinct quotename([loan deposit other]) as pivotColumnName, [classification order] " &_
			"from pr_pqWebArchive " &_
			"where [loan deposit other] <> 'Net Investments' " &_
			"and customerID = " & customerID & " " &_
			") as x " &_
		"order by [classification order] "
		
set rsPC = dataconn.execute(SQL)

if metricSummaryFunction = "sum" then 
	strRowTotal = "Total = sum("
else 
	strRowTotal = "Average = avg("
end if

while not rsPC.eof
	strPivotColumns 	= strPivotColumns & rsPC("pivotColumnName")
	
	strSumColumns 		= strSumColumns & rsPC("pivotColumnName") & " = isNull("& metricSummaryFunction & "(" & rsPC("pivotColumnName") & "),0)"
	
	strRowTotal			= strRowTotal & " isNull(" & rsPC("pivotColumnName") & ",0) "

	rsPC.movenext 
	if not rsPC.eof then 
		strPivotColumns = strPivotColumns & ", "  
		strSumColumns = strSumColumns & ", " 
		strRowTotal = strRowTotal & " + "
	end if
wend 
strRowTotal = strRowTotal & ")"

rsPC.close 
set rsPC = nothing 

officerSQL = "select " &_
			summaryColumn & " = isNull(" & summaryColumn & ", '" & metricSummaryRowTitle & "'), " &_
			strSumColumns & ", " &_
			strRowTotal & " " &_
		"from " &_
			"( " &_
			"select " &_
				summaryColumn & ", " &_
				"[loan deposit other], " &_
				metricColumn & " as metric " &_
			"from pr_pqWebArchive " &_
			"where [Account Holder Number] <> '0' " &_
			"and not ([Branch Description] = 'Treasury' OR [Officer Name] = 'Treasury') " &_
			"and [Account Holder Number] <> 'Manually Added Accounts' " &_
			"and customerID = " & customerID & " " &_
			metricSummaryGroupby &_
			") as x " &_
		"pivot ( " &_
			metricSummaryFunction & "(metric) " &_
			"for [loan deposit other] in (" & strPivotColumns & ") " &_
		") as y " &_
		"group by rollup(" & summaryColumn & ") " 
		
dbug(officerSQL)

officerSummary = jsonDataTable(officerSQL)

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="customerProfit.js"></script>

	<script type="text/javascript">

		google.charts.load('current', {'packages':['table','bar','corechart']});
		
		google.charts.setOnLoadCallback(drawVisualization);
		
		function drawVisualization() {
			
			const chartHeight = 300;
		
			var currencyFormatter = new google.visualization.NumberFormat({
				prefix: '$', 
				negativeColor: 'crimson', 
				negativeParens: true,
				fractionDigits: 0,
			});
		
			var percentFormatter = new google.visualization.NumberFormat({
				suffix: '%', 
				negativeColor: 'crimson', 
				negativeParens: true,
				fractionDigits: 4,
			});
		
			var integerFormatter = new google.visualization.NumberFormat({
				negativeColor: 'crimson', 
				negativeParens: true,
				fractionDigits: 0,
			});
		
			var tableOptions = {
				height: 600,
				allowHtml: true,
				cssClassNames: {
					tableCell: 'googleTableCell',
				},
			};
			

			// DATATABLE / CHART: Top Data...   
		   var dataTable = new google.visualization.DataTable(<% =officerSummary %>);
		   
		   dataTable.setColumnProperty(0, 'className', 'googleLeft');
		   dataTable.setColumnProperty(1, 'className', 'googleNumericRight');
		   dataTable.setColumnProperty(2, 'className', 'googleNumericRight');
		   dataTable.setColumnProperty(3, 'className', 'googleNumericRight');
		   dataTable.setColumnProperty(4, 'className', 'googleNumericRight');

		   <% =metricFormatterName %>.format(dataTable,1);
		   <% =metricFormatterName %>.format(dataTable,2);
		   <% =metricFormatterName %>.format(dataTable,3);
		   <% =metricFormatterName %>.format(dataTable,4);

		   <% if selectedMetric = "Interest Rate" then %>
		   	var numberOfColumns = dataTable.getNumberOfColumns();
		   	dataTable.removeColumn(numberOfColumns - 1);
		   <% end if %>		   
		   
			var lastRowOfDataTable = dataTable.getNumberOfRows() - 1;
			var totals = [];
			for (i = 0; i < dataTable.getNumberOfColumns(); i++) {
				var values = [];
				values[0] = dataTable.getValue(lastRowOfDataTable,i);
				values[1] = dataTable.getFormattedValue(lastRowOfDataTable,i);
				totals.push(values);
			}
			dataTable.removeRow(lastRowOfDataTable);



		   var officerCategorySummaryTable = new google.visualization.Table(document.getElementById('dataTableDiv'));

			google.visualization.events.addListener(officerCategorySummaryTable, 'select', function() {
				var selectedItem = officerCategorySummaryTable.getSelection()[0];
				var selectedEntityName 	= dataTable.getValue(selectedItem.row, 0);

				if (selectedItem) {	
					
					if (selectedEntityName == 'None') {
						alert('Sorry, drill-down is not available on that officer.');
					} else {
					
	
						var href = "/customerProfit_accountHolderCategorySummary.asp?name=" + selectedEntityName + "&id=<% =customerID %>";
	
						var selectedClass 	= <% if len(selectedClass) then response.write("'" & selectedClass & "'") else response.write("null") end if %>;
						var selectedService 	= <% if len(selectedService) then response.write("'" & selectedService & "'") else response.write("null") end if %>;
						var selectedMetric 	= <% if len(selectedMetric) then response.write("'" & selectedMetric & "'") else response.write("null") end if %>;
						var selectedSummary 	= <% if len(selectedSummary) then response.write("'" & selectedSummary & "'") else response.write("null") end if %>;					
						
						if (selectedClass) 	{href += '&class=' + selectedClass}
						if (selectedService)	{href += '&service=' + selectedService}
						if (selectedMetric) 	{href += '&metric=' + selectedMetric}
						if (selectedSummary) {href += '&summary' + selectedSummary}
	
						window.location.href = href;

					}

				}
			});

			officerCategorySummaryTable.draw(dataTable, tableOptions);
			


		   
			var googleTable 	= document.getElementsByClassName('google-visualization-table-table')[0];

			var footer 			= googleTable.createTFoot();

			var footerRow 		= footer.insertRow(0);
			var cell;
			
			for (i = 0; i < dataTable.getNumberOfColumns(); i++) {
				
				cell = footerRow.insertCell(i);
				cell.innerHTML = totals[i][1];
				if (i == 0) {
					cell.classList.add('googleLeft');
				} else {
					cell.classList.add('googleNumericRight');
					if (totals[i][0] < 0) {
						cell.style.color = 'red';
					}
				}
				cell.classList.add('google-visualization-table-th');
				cell.classList.add('gradient');
			}

	  }
	 
	</script>
  
	<style>
	
		.googleTableCell {
			white-space: nowrap;
		}
		
		.googleNumericRight {
			text-align: right;
			width: 150px;
		}
		
		.googleLeft {
			text-align: left;
			width: 200px !important;
		}
				
			
		.google-visualization-table-tr-head {
			display: inline-block;
			position: relative;
			vertical-align: bottom;
			text-align: center;			
		}

		tbody {
			display: block;
			overflow: auto;
			height: 550px;
		}
		
		tfoot {
			display: block;
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
		
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b><% =selectedSummary %> Overview</b></h9>
					</div>
					
					<div style="float: left;">
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="float: left; width: 150px;">
							<select id="entityType" class="mdl-textfield__input" style="display: inline-block" onchange="SelectSummary(<% =customerID %>,<% ="'" & selectedClass & "'" %>,<% ="'" & selectedService & "'" %>,<% ="'" & selectedMetric & "'" %>,this)">
								<option <% if selectedSummary = "Branch" 					then response.write("selected") end if %>>Branch</option>
								<option <% if selectedSummary = "Officer" 					then response.write("selected") end if %>>Officer</option>
							</select>
							<label class="mdl-textfield__label" for="drilldown">Branch or officer...</label>
						</div>
						&nbsp;
						&nbsp;
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="float: left; width: 200px;">
							<select id="metricType" class="mdl-textfield__input" style="display: inline-block" onchange="SelectMetric(<% =customerID %>,<% ="'" & selectedClass & "'" %>,<% ="'" & selectedService & "'" %>,this,<% ="'" & selectedSummary & "'" %>)">
								<option <% if selectedMetric = "Balance" 					then response.write("selected") end if %>>Balance</option>
								<option <% if selectedMetric = "Interest Rate" 			then response.write("selected") end if %>>Interest Rate</option>
								<option <% if selectedMetric = "Number of Accounts" 	then response.write("selected") end if %>>Number of Accounts</option>
								<option <% if selectedMetric = "Profit" 					then response.write("selected") end if %>>Profit</option>
							</select>
							<label class="mdl-textfield__label" for="drilldown">Metric...</label>
						</div>
					</div>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="float: right">
						<select id="drilldown" class="mdl-textfield__input" style="display: inline-block" onchange="SelectClassificationDrilldown(<% =customerID %>,this,<% ="'" & selectedSertvice & "'" %>,<% ="'" & selectedMetric & "'" %>,<% ="'" & selectedSummary & "'" %>)">
							<option>Select a classification...</option>
							<option>Loan</option>
							<option>Deposit</option>
							<option>Other</option>
						</select>
						<label class="mdl-textfield__label" for="drilldown">Navigation...</label>
					</div>
						

					<div id="dataTableDiv" style="display: inline-block; text-align: center; padding: 15px; vertical-align: top">
						<!-- dataTable -->
					</div>

				</div>
						
				
				<div class="mdl-layout-spacer"></div>
		
			</div>
			
		</div>
	        
	</main>
<!-- #include file="includes/pageFooter.asp" -->
</div>


</body>
</html>