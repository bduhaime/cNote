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


' cpature the six items that control this report...
customerID 			= request.querystring("id")
officerName			= request.querystring("officer")
accountHolder		= request.querystring("accountHolder")

predicate = ""
if len(officerName) > 0 then	
	predicate = predicate & "and [officer name] = '" & officerName & "' " 
end if 
if len(accountHolder) > 0 then 
	predicate = predicate & "and [account holder number] = '" & accountHolder & "' " 
end if 

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

subtitle = "Profitability: Officer Management" 
userLog(title)

mgmtSQL =	"select " &_
					"[account holder number], " &_
					"[account number], " &_
					"[balance], " &_
					"[profit], " &_
					"[interest rate], " &_
					"[open date], " &_
					"[service], " &_
					"[product code and product description], " &_
					"[ftp rate] " &_
				"from pr_pqwebarchive " &_
				"where [Account Holder Number] not in ('0', 'Manually Added Accounts') " &_
				"and [Branch Description] <> 'Treasury' " &_
				"and [Officer Name] <> 'Treasury' " &_
				"and [loan deposit other] = 'Loan' " &_
				predicate &_
				"and customerID = " & customerID & " " &_
				"order by 6 desc " 
		
dbug(mgmtSQL)


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
	
	formatTD = "<td class=""" & cssClass & """ sorttable_customkey=""" & value & """>" & outputValue & "</td>"
				
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
		
		<!-- #include file="includes/getAllVisibleAccounts.js" -->

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
		
		.cNoteDate {
			text-align: center;
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
		<span class="mdl-layout-title">Officer: <% =request.querystring("officer") %></span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
		<!-- Your content goes here -->
	
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b>Officer Management: <% =request.querystring("officer") %></b></h9>
					</div>
					<br>
					
					<%
					set rsTop = dataconn.execute(mgmtSQL)
					if not rsTop.eof then 
						redim columnTotals(rsTop.fields.count - 1)
						%>
						
						<table class="cNoteTable sortable" align="center">
							<thead>
								<tr>
									<th class="alignLeft cNoteFixedCellXLarge">Account Holder Number</th>
									<th class="alignLeft cNoteFixedCellXLarge">Account Holder</th>
									<th class="alignLeft cNoteFixedCellLarge">Account </th>
									<th class="alignRight cNoteFixedCellLarge">Balance</th>
									<th class="alignRight cNoteFixedCellLarge">Profit</th>
									<th class="alignRight cNoteFixedCellLarge">Interest Rate</th>
									<th class="alignCenter cNoteFixedCellLarge">Open Date</th>
									<th class="cNoteRowHeader cNoteFixedCellLarge">Service</th>
									<th class="cNoteRowHeader cNoteFixedCellHuge">Product</th>
									<th class="cNotePercent cNoteFixedCellLarge">FTP Rate</th>
								</tr>
							</thead>
							<tbody style="height: 550px;">
								<% while not rsTop.eof %>
								<tr id="<% =rsTop("account number") %>" onclick="window.location.href='accountDetail.asp?id=<% =customerID %>&account=<% =rsTop("account number") %>'"> 
										<td class="alignLeft cNoteFixedCellXLarge accountHolderNumber"><i class="material-icons">fingerprint</i></td>
										<td class="alignLeft cNoteFixedCellXLarge accountHolderName"><i class="material-icons">portrait</i></td>
										<td class="alignLeft cNoteFixedCellLarge accountNumber"><i class="material-icons">credit_card</i></td>
										<td class="alignRight cNoteFixedCellLarge cNoteMoney" sorttable_customkey="<% =rsTop("balance") %>"><% =formatCurrency(rsTop("balance"),0) %></td>
										<td class="alignRight cNoteFixedCellLarge cNoteCurrency" sorttable_customkey="<% =rsTop("profit") %>"><% =formatCurrency(rsTop("profit"),0) %></td>										
										<td class="alignRight cNoteFixedCellLarge cNotePercent" sorttable_customkey="<% =rsTop("interest rate") %>"><% =formatPercent(rsTop("interest rate")/100,4) %></td>										
										<td class="alignCenter cNoteFixedCellLarge cNoteDate" sorttable_customkey="<% =rsTop("open date") %>"><% '=formatDateTime(rsTop("open date"),2) %></td>										
										<td class="cNoteRowHeader cNoteFixedCellLarge"><% =rsTop("service") %></td>
										<td class="cNoteRowHeader cNoteFixedCellHuge"><% =rsTop("product code and product description") %></td>
										<td class="cNotePercent cNoteFixedCellLarge cNotePercent" sorttable_customkey="<% =rsTop("ftp rate") %>"><% =formatPercent(rsTop("ftp rate")/100,4) %></td>										
									</tr>
									<%
									rsTop.movenext 
								wend 
								%>
							</tbody>
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