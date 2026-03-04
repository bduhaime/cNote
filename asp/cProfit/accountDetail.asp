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
<!-- #include file="../includes/apiServer.asp" -->
<!-- #include file="../includes/jwt.all.asp" -->
<!-- #include file="../includes/sessionJWT.asp" -->
<% 
call checkPageAccess(43)


' cpature the six items that control this report...
customerID 			= request.querystring("customerID")
accountNumber		= request.querystring("accountNumber")

server.scriptTimeout=200 
title = customerTitle(customerID)
title = session("clientID") &  " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

subtitle = "Profitability: Officer Management" 
userLog(title)


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

	<!-- 	jQuery -->
	<script type="text/javascript" src="../jQuery/jquery-3.5.1.js"></script>


	<script type="text/javascript" src="../moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="customerProfit.js"></script>

	<script type="text/javascript" src="../sorttable.js"></script>

	<script>

		<!-- #include file="includes/getAccountDetails.js" -->

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

		.cNoteColHeader {
			background-color: lightgray;
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
  
  
	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
		<!-- Your content goes here -->
	
			<br>
			<div id="<% =accountNumber %>" style="text-align: center; font-size: 16px; ">
				<b>Account :</b>&nbsp;<span class="accountNumber"><i class="material-icons" style="vertical-align: middle;">credit_card</i></span>
			</div>
			<br>

			<%

			SQL =	"select * " &_
					"from pr_pqwebarchive " &_
					"where [account number] = '" & accountNumber & "' " &_
					"and customerID = " & customerID & " " 
					
			dbug(SQL)
			
			set rsDtl = dataconn.execute(SQL)
			
' 			dbug("dumping recordset fields/values...")
' 			for each item in rsDtl.fields
' 				dbug("rsDtl(" & item.name & "): " & item.value)
' 			next 
' 			dbug(" ")
			
			if not rsDtl.eof then 
				%>
				<div class="mdl-grid">
					<div class="mdl-layout-spacer"></div>
					
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="padding: 15px;">
						<table class="cNoteTable" style="border-collapse: collapse; width: 100%;"> 
							<thead class="cNoteColHeader">
								<tr>
									<th class="cNoteRowHeader">Attribute</th>
									<th class="cNoteAttrValue alignCenter">Value</th>
								</tr>
							</thead>
							<tbody>
								<tr>
									<td class="cNoteRowHeader">Account Holder Contact</td>
									<td class="alignLeft accountHolderNameAddress"><div><i class="material-icons">contact_mail</i></div></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Account Holder Number</td>
									<td class="cNoteAttrValue alignLeft accountHolderNumber"><div><i class="material-icons">fingerprint</i><div></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Phone</td>
									<td class="cNoteAttrValue alignLeft accountPhone"><div><i class="material-icons" style="width: 120px;">phone</i><div></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Email</td>
									<td class="cNoteAttrValue alignLeft accountEmail"><div><i class="material-icons" style="width: 120px;">email</i><div></td>
								</tr>

								<% 
								if isDate(rsDtl("Process Date")) then 
									processDate = formatDateTime(rsDtl("Process Date")) 
								else 
									processDate = "" 
								end if 
								%>
								<tr><td class="cNoteRowHeader">Process Date</td><td class="cNoteAttrValue alignLeft"><% =formatDateTime(rsDtl("Process Date")) %></td></tr>

								<tr><td class="cNoteRowHeader">Account Holder Grade</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("account holder grade") %></td></tr>
								<tr><td class="cNoteRowHeader">Age</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("age") %></td></tr>
								<tr><td class="cNoteRowHeader">Service Propensity</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("service propensity") %></td></tr>
								<tr><td class="cNoteRowHeader">Account Type Propensity</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("account type propensity") %></td></tr>
								<tr><td class="cNoteRowHeader">Maturity Date</td><td class="cNoteAttrValue alignLeft"><% =formatDateTime(rsDtl("maturity date")) %></td></tr>
								<tr><td class="cNoteRowHeader">Business Line</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("business line") %></td></tr>
								<tr><td class="cNoteRowHeader">LDO</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("loan deposit other") %></td></tr>
								<tr><td class="cNoteRowHeader">Service</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("service") %></td></tr>
								<tr><td class="cNoteRowHeader">Product</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("product code and product description") %></td></tr>
								<tr><td class="cNoteRowHeader">Opened</td><td class="cNoteAttrValue alignLeft"><% =formatDateTime(rsDtl("open date")) %></td></tr>
								<tr><td class="cNoteRowHeader">Branch Code</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("branch code") %></td></tr>
								<tr><td class="cNoteRowHeader">Branch Description</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("branch description") %></td></tr>
								<tr><td class="cNoteRowHeader">Officer Code</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("officer code") %></td></tr>
								<tr><td class="cNoteRowHeader">Officer Name</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("officer name") %></td></tr>
							</tbody>
						</table>
					</div>

					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="padding: 15px;">
						<table class="cNoteTable" style="border-collapse: collapse; width: 100%;"> 
							<thead class="cNoteColHeader">
								<tr>
									<th class="cNoteRowHeader">Attribute</th>
									<th class="cNoteAttrValue alignCenter">Value</th>
								</tr>
							</thead>
							<tbody>
								<tr><td class="cNoteRowHeader">Interest Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsDtl("interest rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">FTP Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsDtl("ftp rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Provision Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsDtl("provision rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Maturity Month x Balance</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("maturity month x balance"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Net Interest Income</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("net interest income"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Non-interest Income</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("non-interest income"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Non-interest Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("non-interest expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Incremental Non-interest Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("incremental non-interest expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Provision Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("provision expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Incremental Provision Expense</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("incremental provision expense"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Profit</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("profit"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Incremental Profit</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("incremental profit"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Default Risk Rate</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsDtl("default risk rate")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Capital Requirement</td><td class="cNoteAttrValue alignRight"><% =formatPercent(rsDtl("capital requirement")/100,4) %></td></tr>
								<tr><td class="cNoteRowHeader">Balance</td><td class="cNoteAttrValue alignRight"><% =formatCurrency(rsDtl("balance"),2) %></td></tr>
								<tr><td class="cNoteRowHeader">Decile</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("Decile") %></td></tr>
								<tr><td class="cNoteRowHeader">Centile</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("centile") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 1</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("user_field1") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 2</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("user_field2") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 3</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("user_field3") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 4</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("user_field4") %></td></tr>
								<tr><td class="cNoteRowHeader">User Field 5</td><td class="cNoteAttrValue alignLeft"><% =rsDtl("user_field5") %></td></tr>
							</tbody>
						</table>
					</div>

					
<!--
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
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("retail and marketing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("retail and marketing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Product Specific</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("product specific"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("product specific factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan Servicing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("loan servicing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("loan servicing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan Collection</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("loan collection"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("loan collection factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan & Credit Services</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("loan and credit services"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("loan and credit services factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Loan Administration</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("loan admin"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("loan admin factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Deposit Insurance</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("deposit insurance"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("deposit insurance factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">ATM & Debit Cards</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("atm and debit cards"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("atm and debit cards factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Bank Charges</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("bank charges"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("bank charges factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Phone & VRU Charges</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("phone and vru charges"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("phone and vru charges factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Armored Car & Courier</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("armored car and courier"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("armored car and courier factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Postage</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("postage"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("postage factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Central Support Ops</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("central support ops"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("central support ops factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Teller Processing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("teller processing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("teller processing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Check Processing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("check processing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("check processing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">ACH Proof & Bookkeeping</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("ach proof and bookkeeping"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("ach proof and bookkeeping factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Cash Over/Short</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("cash over and short"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("cash over and short factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Data Processing</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("data processing"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("data processing factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Accounting</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("accounting"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("accounting factor")/100,4) %></td>
								</tr>
								<tr>
									<td class="cNoteRowHeader">Overhead</td>
									<td class="cNoteCurrency"><% =formatCurrency(rsDtl("overhead"),2) %></td>
									<td class="cNotePercent"><% =formatPercent(rsDtl("overhead factor")/100,4) %></td>
								</tr>
							</tbody>
						</table>
					</div>
-->

					<div class="mdl-layout-spacer"></div>
				</div>					

				<%
			else 
				response.write("No account info found")
			end if
			rsDtl.close 
			set rsDtl = nothing
			%>



						
				
				<div class="mdl-layout-spacer"></div>
		
			</div>
			
		</div>
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>