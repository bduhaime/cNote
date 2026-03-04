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

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

suntitle = "Profitability: Officer Management" 
userLog(title)

mgmtSQL =	"select " &_
					"[officer name], " &_
					"count(distinct [account number]) as accountCount, " &_
					"count(distinct [account holder number]) as accountHolderCount, " &_
					"sum([balance]) as sumBalance, " &_
					"avg([balance]) as avgBalance, " &_
					"sum([profit]) as sumProfit, " &_
					"avg([profit]) as avgProfit, " &_
					"case when sum([balance]) <> 0 then sum([Interest Rate x Balance])/sum([balance]) else 0.0000 end  as avgInterest " &_
				"from pr_pqwebarchive " &_
				"where ([Account Holder Number] not in ('0', 'Manually Added Accounts') " &_
				"and [Branch Description] <> 'Treasury' " &_
				"and [Officer Name] <> 'Treasury') " &_
				"and [loan deposit other] = 'Loan' " &_
				"and customerID = " & customerID & " " &_
				"group by [officer name] " &_
				"order by 5 desc " 
		
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
		<span class="mdl-layout-title">Officer Management</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
		<!-- Your content goes here -->
	
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp" style="padding: 15px;">
					
						
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b>Officer Management</b></h9>
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
									<th class="alignLeft" style="width: 225px">Officer Name</th>
									<th class="alignRight" style="width: 110px;">Accounts</th>
									<th class="alignRight" style="width: 110px;">Account Holders</th>
									<th class="alignRight" style="width: 110px;">Balance</th>
									<th class="alignRight" style="width: 110px;">Avg Balance</th>
									<th class="alignRight" style="width: 110px;">Profit</th>
									<th class="alignRight" style="width: 110px;">Avg Profit</th>
									<th class="alignRight" style="width: 110px;">Interest Rate</th>
								</tr>
							</thead>
							<tbody style="height: 550px;">
								<% while not rsTop.eof %>
									<tr data-rowID="<% =rsTop(0) %>"> 
										<td class="cNoteRowHeader accountHolderName" style="width: 225px"><% =rsTop(0) %></td>
										<td class="cNoteInteger" style="cursor: pointer;" sorttable_customkey="<% =rsTop(1) %>" onclick="window.location.href='officerManagementAccounts.asp?id=<% =customerID %>&officer=<% =rsTop(0) %>'"><% =formatNumber(rsTop(1),0) %></td>										
										<td class="cNoteInteger" style="cursor: pointer;" sorttable_customkey="<% =rsTop(2) %>" onclick="window.location.href='officerManagementAccountHolders.asp?id=<% =customerID %>&officer=<% =rsTop(0) %>'"><% =formatNumber(rsTop(2),0) %></td>

										<% if rsTop(3) < 0 then color = "crimson" else color = "black" end if %>			
										<td class="cNoteCurrency" style="color: <% =color %>" sorttable_customkey="<% =rsTop(3) %>"><% =formatCurrency(rsTop(3),0) %></td>										

										<% if rsTop(4) < 0 then color = "crimson" else color = "black" end if %>			
										<td class="cNoteCurrency" style="color: <% =color %>" sorttable_customkey="<% =rsTop(4) %>"><% =formatCurrency(rsTop(4),0) %></td>										

										<% if rsTop(5) < 0 then color = "crimson" else color = "black" end if %>			
										<td class="cNoteCurrency" style="color: <% =color %>" sorttable_customkey="<% =rsTop(5) %>"><% =formatCurrency(rsTop(5),0) %></td>										

										<% if rsTop(6) < 0 then color = "crimson" else color = "black" end if %>			
										<td class="cNoteCurrency" style="color: <% =color %>" sorttable_customkey="<% =rsTop(6) %>"><% =formatCurrency(rsTop(6),0) %></td>										

										<td class="cNotePercent" sorttable_customkey="<% =rsTop(7) %>"><% =formatPercent(rsTop(7)/100,4) %></td>										
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