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
branchName			= request.querystring("branch")
serviceName			= request.querystring("service")
ldoName				= request.querystring("class")
productName			= request.querystring("product")


predicate = ""

if len(officerName) > 0 then 
	predicate = predicate & "and [officer name] = '" & officerName & "' " 
end if
if len(branchName) > 0 then 
	predicate = predicate & "and [branch description] = '" & branchName & "' " 
end if
if len(serviceName) > 0 then 
	predicate = predicate & "and [service] = '" & serviceName & "' " 
end if
if len(ldoName) > 0 then 
	predicate = predicate & "and [loan deposit other] = '" & ldoName & "' " 
end if
if len(productName) > 0 then 
	predicate = predicate & "and [product code and product description] = '" & productName & "' " 
end if
	

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

subtitle = "Profitability: Officer Management" 
userLog(title)

mgmtSQL =	"select " &_
					"[account holder number], " &_
					"count(distinct [account number]) as accountCount, " &_
					"sum([balance]) as sumBalance, " &_
					"sum([profit]) as sumProfit, " &_
					"case when sum([balance]) <> 0 then sum([Interest Rate x Balance])/sum([balance]) else 0.0000 end  as avgInterest, " &_
					"max([open date]) as maxOpenDate " &_
				"from pr_pqwebarchive " &_
				"where [Account Holder Number] not in ('0', 'Manually Added Accounts') " &_
				"and [Branch Description] <> 'Treasury' " &_
				"and [Officer Name] <> 'Treasury' " &_
				predicate &_
				"and customerID = " & customerID & " " &_
				"group by " &_
					"[account holder number] " &_
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
		
				<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b>Officer Management: <% =request.querystring("officer") %></b></h9>
						<% if len(ldoName) > 0 then %>
							<br><h9><b>Category: <% =ldoName %></b></h9>
						<% end if %>
						<% if len(serviceName) > 0 then %>
							<br><h9><b>Service: <% =serviceName %></b></h9>
						<% end if %>
					</div>
					<br>
					
					<%
					set rs = dataconn.execute(mgmtSQL)
					if not rs.eof then 
						redim columnTotals(rs.fields.count - 1)
						%>
						<table class="cNoteTable sortable" align="center">
							<thead>
								<tr>
									<th class="alignLeft cNoteFixedCellMedium">Account Holder #</th>
									<th class="alignLeft cNoteFixedCellXLarge">Account Holder</th>
									<th class="alignRight cNoteFixedCellMedium">Accounts</th>
									<th class="alignRight cNoteFixedCellLarge">Balance</th>
									<th class="alignRight cNoteFixedCellLarge">Profit</th>
									<th class="alignRight cNoteFixedCellLarge">Interest Rate</th>
									<th class="alignCenter cNoteFixedCellLarge" >Last Open</th>
								</tr>
							</thead>
							<tbody style="height: 550px;">
								<% while not rs.eof %>
									<tr id="<% =rs("account holder number") %>" style="cursor: pointer;" onclick="window.location.href='/cProfit/officerManagementAccounts.asp?id=<% =customerID %>&officer=<% =officerName %>&accountHolder=<% =rs(0) %>'"> 
										<td class="cNoteRowHeader cNoteFixedCellMedium accountHolderNumber"><i class="material-icons" style="width: 120px;">fingerprint</i></td>
										<td class="cNoteRowHeader cNoteFixedCellXLarge accountHolderName"><i class="material-icons" style="width: 120px;">portrait</i></td>
										<td class="cNoteInteger cNoteFixedCellMedium" sorttable_customkey="<% =rs("accountCount") %>"><% =formatNumber(rs("accountCount"),0) %></td>
										<td class="cNoteCurrency cNoteFixedCellLarge" sorttable_customkey="<% =rs("sumBalance") %>"><% =formatCurrency(rs("sumBalance"),0) %></td>										
										<td class="cNoteCurrency cNoteFixedCellLarge" sorttable_customkey="<% =rs("sumProfit") %>"><% =formatCurrency(rs("sumProfit"),0) %></td>										
										<td class="cNotePercent cNoteFixedCellLarge" sorttable_customkey="<% =rs("avgInterest") %>"><% =formatPercent(rs("avgInterest")/100,4) %></td>										
										<td class="cNoteDate cNoteFixedCellLarge" sorttable_customkey="<% =rs("maxOpenDate") %>"><% =formatDateTime(rs("maxOpenDate"),2) %></td>										
										
									</tr>
									<%
									rs.movenext 
								wend 
								%>
							</tbody>
						</table>							
						<%
					else 
						%>
						<div align="center">No data available</div>
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


</body>
</html>