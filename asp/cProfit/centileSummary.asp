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
centileID 			= request.querystring("centile")

if len(request.querystring("metric")) > 0 then 
	selectedMetric = request.querystring("metric")
else 
	selectedMetric = "Profit"
end if

if len(request.querystring("summary")) > 0 then 
	selectedSummary = request.querystring("summary")
else 
	selectedSummary = "Account Holder"
end if




select case selectedMetric
	case "Profit"
		metricColumn = "[profit]"
		metricType = "currency"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
	case "Balance"
		metricColumn = "[balance]"
		metricType = "currency"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
	case "Interest Rate"
		metricColumn = "case when [balance] <> 0 then [interest rate x balance] / [balance] else 0 end "
		metricType = "percent"
		metricSummaryFunction = "avg"
		metricSummaryRowTitle = "Average"
' 		metricSummaryGroupby = "group by " & summaryColumn & ", [loan deposit other] "
		dataViewColumns = "[0,1,2,3]"
	case "Number of Accounts"
		metricColumn = "1"
		metricType = "integer"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
	case else 
		metricColumn = "[profit]"
		metricType = "currency"
		metricSummaryFunction = "sum"
		metricSummaryRowTitle = "Total"
		metricSummaryGroupby = ""
		dataViewColumns = "[0,1,2,3,4]"
end select 


server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

subtitle = "Profitability: Centile Summary" 
userLog(title)

SQL = "select pivotColumnName " &_
		"from " &_
			"( " &_
			"select distinct quotename([loan deposit other]) as pivotColumnName, [classification order] " &_
			"from pr_pqWebArchive " &_
			"where [classification order] between 1 and 3 " &_
			"and customerID = " & customerID & " " &_
			") as x " &_
		"order by [classification order], pivotColumnName "

dbug("pivot columns: " & SQL)	
set rsPC = dataconn.execute(SQL)

strRowTotal = "Total = sum("

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

categorySQL = "select " &_
						"[Account Holder Number], " &_
						strSumColumns & ", " &_
						strRowTotal & " " &_
					"from " &_
						"( " &_
						"select " &_
							"[Account Holder Number], " &_
							"[loan deposit other], " &_
							metricColumn & " as metric " &_
						"from pr_pqWebArchive " &_
						"where [Account Holder Number] <> '0' " &_
						"and not ([Branch Description] = 'Treasury' OR [Officer Name] = 'Treasury') " &_
						"and [Account Holder Number] <> 'Manually Added Accounts' " &_
						"and centile = " & centileID & " " &_
						"and customerID = " & customerID & " " &_
						") as x " &_
					"pivot ( " &_
						metricSummaryFunction & "(metric) " &_
						"for [loan deposit other] in (" & strPivotColumns & ") " &_
					") as y " &_
					"group by " &_
						"[Account Holder Number] " &_
					"order by 1, 2"

dbug(categorySQL)


function formatTD(value,datatype)
	
	standardColumnWidth = "110px"
	
	select case datatype 
	
		case "currency"
		
			cssClass 	= cssClass & "alignRight cNoteFixedCellLarge cNoteCurrency "			
			outputValue = formatCurrency(value,0)			
		
		case "percent"
		
			cssClass 	= cssClass & "alignRight cNoteFixedCellLarge cNotePercent "
			outputValue = formatPercent(value/100,4)
		
		case "integer"
		
			cssClass 	= cssClass & "alignRight cNoteFixedCellLarge cNoteInteger "
			outputValue = formatNumber(value,0)
			
		case else 
		
			cssClass 	= cssClass & "alignLeft cNoteFixedCellLarge "
			outputValue = value
		
	end select 
	
	formatTD = "<td class=""" & cssClass & """>" & outputValue & "</td>"
	
end function 


%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<script type="text/javascript" src="../moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="customerProfit.js"></script>

	<script type="text/javascript" src="../sorttable.js"></script>

	<script>
		
		<!-- #include file="includes/getAllVisibleAccountHolders.js" -->

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
		
				<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b><% =selectedSummary %> Overview, Centile = <% =centileID %></b></h9>
					</div>
					
					<div style="display: inline-block; width: 100%">					

						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="float: left; width: 200px; margin-left: 10px;">
							<select id="metricType" class="mdl-textfield__input" style="display: inline-block" onchange="SelectMetric(<% =customerID %>,<% ="'" & selectedClass & "'" %>,<% ="'" & selectedService & "'" %>,this, <% ="'" & selectedSummary & "'" %>, <% =centileID %>)">
								<option <% if selectedMetric = "Balance" 					then response.write("selected") end if %>>Balance</option>
								<option <% if selectedMetric = "Interest Rate" 			then response.write("selected") end if %>>Interest Rate</option>
								<option <% if selectedMetric = "Number of Accounts" 	then response.write("selected") end if %>>Number of Accounts</option>
								<option <% if selectedMetric = "Profit" 					then response.write("selected") end if %>>Profit</option>
							</select>
							<label class="mdl-textfield__label" for="drilldown">Metric...</label>
						</div>
						
					</div>


					<%
					set rsTop = dataconn.execute(categorySQL)
					if not rsTop.eof then 
						maxColumns = rsTop.fields.count - 1
						redim columnTotals(maxColumns)
						%>
						<table class="cNoteTable sortable" align="center">
							<thead>
								<tr>
									<th class="alignLeft cNoteFixedCellXLarge">Account Holder Number</th>
									<th class="alignLeft cNoteFixedCellHuge">Account Holder Name</th>
									<% for i = 2 to maxColumns - 1 %>
										<th class="alignRight cNoteFixedCellLarge">
											<i class="material-icons" style="vertical-align: bottom; z-index: 1000;" onclick="SelectCentileClassificationDrilldown(<% =customerID %>,'<% =rsTop.fields(i).name %>',<% ="'" & selectedMetric & "'" %>,<% =centileID %>)">subdirectory_arrow_right</i>
											<% =rsTop.fields(i).name %>
										</th>
									<% next %>

										
									<% if lCase(selectedMetric) <> "interest rate" then %>
										<th class="alignRight cNoteFixedCellLarge">Total</th>
									<% end if %>
								</tr>
							</thead>
							<tbody style="height: 550px;">
								<% while not rsTop.eof %>
									<tr id="<% =rsTop("Account Holder Number") %>"> 
										<td class="alignLeft cNoteFixedCellXLarge accountHolderNumber"><i class="material-icons">fingerprint</i></td>
										<td class="alignLeft cNoteFixedCellHuge accountHolderName"><i class="material-icons">portrait</i></td>
										<% 
										if lCase(selectedMetric) <> "interest rate" then 
											remainingColumns = maxColumns
										else 
											remainingColumns = maxColumns - 1
										end if
										
										for i = 2 to remainingColumns
											response.write(formatTD(rsTop(i), metricType))
											columnTotals(i) = columnTotals(i) + rsTop(i) 
										next 
										%>
									</tr>
									<%
									rsTop.movenext 
								wend 
								%>
							</tbody>
							<tfoot>
								<% if lCase(selectedMetric) <> "interest rate" then %>
									<tr>
										<td class="alignRight" style="width: 370px" colspan="2">Totals:</th>
										<% 
										for i = 2 to maxColumns
											response.write(formatTD(columnTotals(i), metricType))
										next 
										%>
									</tr>
								<% end if %>
							</tfoot>
						</table>
						</table>							
						<%
					end if
					rsTop.close 
					set rsTop = nothing
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