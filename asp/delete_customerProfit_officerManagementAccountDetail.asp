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


' cpature the six items that control this report...
customerID 			= request.querystring("id")
accountHolder		= request.querystring("accountHolder")

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title

subtitle = "Profitability: Officer Management" 
userLog(title)

mgmtSQL =	"select * " &_
				"from pr_pqwebarchive " &_
				"where [Account Holder Number] not in ('0', 'Manually Added Accounts') " &_
				"and [Branch Description] <> 'Treasury' " &_
				"and [Officer Name] <> 'Treasury' " &_
				"and [loan deposit other] = 'Loan' " &_
				"and [account holder number] = '" & accountHolder & "' " 
				"and customerID = " & customerID & " " 
		
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
	<!-- #include file="includes/globalHead.asp" -->

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="customerProfit.js"></script>

	<script type="text/javascript" src="sorttable.js"></script>

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
			width: 250px;
			font-weight: bold;
		}
	
		.cNoteAttrValue{
			width: 180px;
		}
	
	</style>

</head>

<body>
	
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
  
  
	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
		<!-- Your content goes here -->
	
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" style="padding: 15px;">
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: block; text-align: center; background-color: rgb(228, 233, 244); width: 100%">
						<h9><b>Account: <% =accountNumber %></b></h9>
					</div>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>					
			<%
			set rsTop = dataconn.execute(mgmtSQL)
			if not rsTop.eof then 
				%>
				<div class="mdl-grid">
					<div class="mdl-layout-spacer"></div>
					
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="padding: 15px;">
						<table class="cNoteTable"> 
							<thead>
								<tr>
									<th class="cNoteRowHeader">Attribute</th>
									<th class="cNoteAttrValue alignCenter">Value</th>
								</tr>
							</thead>
							<tbody>
								<tr>
									<td class="cNoteRowHeader">Account Holder</td>
									<td class="alignLeft">
										<%
										address = trim(rsTop("first_name") & " " & rsTop("middle_name") & " " & rsTop("last_name") & " " & rsTop("suffix"))
										if len(rsTop("address_1")) then 
											address = address & "<br>" & rsTop("address_1")
										end if
										if len(rsTop("address_2")) then 
											address = address & "<br>" & rsTop("address_2")
										end if
										if len(rsTop("city")) then 
											address = address & "<br>" & rsTop("city")
										end if
										if len(rsTop("state")) then 
											address = address & ",&nbsp;" & rsTop("state")
										end if
										if len(rsTop("zip_code")) then 
											address = address & "&nbsp;" & rsTop("zip_code")
										end if
										response.write(address)
										%>									
									</td>
								</tr>
								<tr><td class="cNoteRowHeader">Account Holder Number</td><td class="cNoteAttrValue alignLeft"><% =rsTop("account holder number") %></td></tr>
								<tr><td class="cNoteRowHeader">Account Number</td><td class="cNoteAttrValue alignLeft"><% =rsTop("account number") %></td></tr>
								<tr><td class="cNoteRowHeader">Phone</td><td class="cNoteAttrValue alignLeft"><% =rsTop("phone") %></td></tr>
								<tr><td class="cNoteRowHeader">Email</td><td class="cNoteAttrValue alignLeft"><% =rsTop("e-mail") %></td></tr>
								<tr><td class="cNoteRowHeader">Process Date</td><td class="cNoteAttrValue alignLeft"><% =formatDateTime(rsTop("process date")) %></td></tr>
								<tr><td class="cNoteRowHeader">Account Holder Grade</td><td class="cNoteAttrValue alignLeft"><% =rsTop("account holder grade") %></td></tr>
								<tr><td class="cNoteRowHeader">Age</td><td class="cNoteAttrValue alignLeft"><% =rsTop("age") %></td></tr>
								<tr><td class="cNoteRowHeader">Service Propensity</td><td class="cNoteAttrValue alignLeft"><% =rsTop("service propensity") %></td></tr>
								<tr><td class="cNoteRowHeader">Account Type Propensity</td><td class="cNoteAttrValue alignLeft"><% =rsTop("account type propensity") %></td></tr>
								<tr><td class="cNoteRowHeader">Maturity Date</td><td class="cNoteAttrValue alignLeft"><% =formatDateTime(rsTop("maturity date")) %></td></tr>
								<tr><td class="cNoteRowHeader">Business Line</td><td class="cNoteAttrValue alignLeft"><% =rsTop("business line") %></td></tr>
								<tr><td class="cNoteRowHeader">LDO</td><td class="cNoteAttrValue alignLeft"><% =rsTop("loan deposit other") %></td></tr>
								<tr><td class="cNoteRowHeader">Service</td><td class="cNoteAttrValue alignLeft"><% =rsTop("service") %></td></tr>
								<tr><td class="cNoteRowHeader">Product</td><td class="cNoteAttrValue alignLeft"><% =rsTop("product code and product description") %></td></tr>
								<tr><td class="cNoteRowHeader">Opened</td><td class="cNoteAttrValue alignLeft"><% =formatDateTime(rsTop("open date")) %></td></tr>
								<tr><td class="cNoteRowHeader">Branch Code</td><td class="cNoteAttrValue alignLeft"><% =rsTop("branch code") %></td></tr>
								<tr><td class="cNoteRowHeader">Branch Description</td><td class="cNoteAttrValue alignLeft"><% =rsTop("branch description") %></td></tr>
								<tr><td class="cNoteRowHeader">Officer Code</td><td class="cNoteAttrValue alignLeft"><% =rsTop("officer code") %></td></tr>
								<tr><td class="cNoteRowHeader">Officer Name</td><td class="cNoteAttrValue alignLeft"><% =rsTop("officer name") %></td></tr>
								<tr><td class="cNoteRowHeader">Decile</td><td class="cNoteAttrValue alignLeft"><% =rsTop("Decile") %></td></tr>
								<tr><td class="cNoteRowHeader">Centile</td><td class="cNoteAttrValue alignLeft"><% =rsTop("centile") %></td></tr>
							</tbody>
						</table>
					</div>

					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="padding: 15px;">
						<table class="cNoteTable"> 
							<thead>
								<tr>
									<th class="cNoteRowHeader">Attribute</th>
									<th class="cNoteAttrValue alignCenter">Value</th>
								</tr>
							</thead>
							<tbody>
								<tr><td class="cNoteRowHeader">Interest Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsTop("interest rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">FTP Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsTop("ftp rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Provision Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsTop("provision rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Maturity Month x Balance</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("maturity month x balance"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Net Interest Income</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("net interest income"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Non-interest Income</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("non-interest income"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Non-interest Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("non-interest expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Incremental Non-interest Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("incremental non-interest expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Provision Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("provision expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Incremental Provision Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("incremental provision expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Profit</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("profit"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Incremental Profit</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("incremental profit"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Default Risk Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsTop("default risk rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Capital Requirement</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsTop("capital requirement")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Balance</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsTop("balance"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 1</td><td class="cNoteAttrValue alignLeft"><% =rsTop("user_field1") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 2</td><td class="cNoteAttrValue alignLeft"><% =rsTop("user_field2") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 3</td><td class="cNoteAttrValue alignLeft"><% =rsTop("user_field3") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 4</td><td class="cNoteAttrValue alignLeft"><% =rsTop("user_field4") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 5</td><td class="cNoteAttrValue alignLeft"><% =rsTop("user_field5") %></td></tr>
							</tbody>
						</table>
					</div>

					
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="padding: 15px;">
						<table class="cNoteTable"> 
							<thead>
								<tr>
									<th class="cNoteRowHeader">Component Name</th>
									<th class="cNoteCurrency">Actual</th>
									<th class="cNotePercent">Factor</th>
								</tr>
							</thead>
							<tbody>
								<tr>
									<td class="cNoteRowHeader">Retail & Marketing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("retail and marketing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("retail and marketing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Product Specific</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("product specific"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("product specific factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan Servicing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("loan servicing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("loan servicing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan Collection</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("loan collection"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("loan collection factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan & Credit Services</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("loan and credit services"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("loan and credit services factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan Administration</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("loan admin"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("loan admin factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Deposit Insurance</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("deposit insurance"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("deposit insurance factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">ATM & Debit Cards</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("atm and debit cards"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("atm and debit cards factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Bank Charges</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("bank charges"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("bank charges factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Phone & VRU Charges</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("phone and vru charges"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("phone and vru charges factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Armored Car & Courier</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("armored car and courier"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("armored car and courier factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Postage</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("postage"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("postage factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Central Support Ops</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("central support ops"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("central support ops factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Teller Processing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("teller processing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("teller processing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Check Processing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("check processing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("check processing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">ACH Proof & Bookkeeping</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("ach proof and bookkeeping"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("ach proof and bookkeeping factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Cash Over/Short</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("cash over and short"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("cash over and short factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Data Processing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("data processing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("data processing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Accounting</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("accounting"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("accounting factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Overhead</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsTop("overhead"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsTop("overhead factor")/100,4) %></td>
								</tr>
							</tbody>
						</table>
					</div>

					<div class="mdl-layout-spacer"></div>
				</div>					

				<%
			end if
			rsTop.close 
			set rsTop = nothing
			%>



						
				
				<div class="mdl-layout-spacer"></div>
		
			</div>
			
		</div>
	        
	</main>
<!-- #include file="includes/pageFooter.asp" -->
</div>


</body>
</html>