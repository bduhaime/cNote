<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/randomString.asp" -->
<!-- #include file="includes/md5.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<% 
dbug("start of top-logic")

title = session("clientID") & " - Edit Customer Info" 

id = request("id")
'*****************************************************************************************
sub validateInput
'*****************************************************************************************
dbug("start validateInput")

	inputValidationError = false
	
	if request.querystring("cmd") <> "add" then 
		if len(id) > 0 then 
			dbug("request('id'): " & request("id"))
			id = request("id") 
		else 
			dbug("customer ID missing")
			inputValidationError = true 
		end if
	end if
	
	if len(request.form("customerName")) > 0 then
		customerName = request.form("customerName")
		SQL = "select id from cSuite..users where username = '" & customerName & "' "
		set rs = dataconn.execute(SQL)
		if rs.eof then
			dbug("customerName is unique")
		else 
			dbug("duplicate customerName entered: " & customerName)
			inputValidationError = true 
		end if
	else
		dbug("customerName missing")
		inputValidationError = true
	end if
	
	if len(request.form("certID")) > 0 then 
		if isNumeric(request.form("certID")) then 
			certID = request.form("certID")
		else 
			inputValidationError = true 
			dbug("certID is present, but not numeric")
		end if
	else 
		certID = "null"
	end if
	
	if len(request.form("rssdID")) > 0 then 
		if isNumeric(request.form("rssdID")) then 
			rssdID = request.form("rssdID")
		else 
			inputValidationError = true 
			dbug("rssdID is present, but not numeric")
		end if 			
	else 
		rssdID = "null"
	end if
	
	if len(request.form("customerStatusID")) > 0 then
		customerStatusID = request.form("customerStatusID")
	else 
		dbug("customerStatusID missing")
		inputValidationError = true
	end if


	dbug("end of validateInput...")
	dbug("customerName: " & customerName)
	dbug("certID: " & certID)
	dbug("rssdID: " & rssdID)
	dbug("customerStatusID: " & customerStatusID)
	
	dbug("inputValidationError=" & inputValidationError)


dbug("end validateInput")
end sub


'*****************************************************************************************
function convertDate(inputDate)
'*****************************************************************************************

	if isNull(inputDate) then 
		convertDate = ""
	else 
' 		if isDate(iputDate) then 
			convertDate = cDate(inputDate)
' 		else 
' 			convertDate = ""
' 		end if 
	end if 

end function 



'*****************************************************************************************
function managerActive(startDate, endDate)
'*****************************************************************************************

	if not isNull(startDate) and not isNull(endDate) then 
		
		if isDate(startDate) and isDate(endDate) then 
			
			dtStartDate = cDate(startDate)
			dtEndDate = cDate(endDate)
			
			if dtStartDate <= date() and date() <= dtEndDate then 
				
				managerActive = true 
			
			else 
				
				managerActive = false 
				
			end if 
			
		else 
			
			managerActive = false 
			
		end if
		
		
	else 
	
		managerActive = false
		
	end if 

end function

'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************
'*****************************************************************************************

dim id, customerName, certID, rssdID, customerStatusID, inputValidationError


select case request.querystring("cmd")
case "add"
	dbug("cmd = 'add'")
	
	validateInput 
	
	if not inputValidationError then
		
		dbug("finding new id value...")
		SQL = "select max(id) as maxID from customer_view "
		
		set rs = dataconn.execute(SQL)
		if not rs.eof then
			newID = cInt(rs("maxID")) + 1
		else
			newID = 1
		end if
		rs.close
		dbug("new id found: " & newID)
		
		SQL = "insert into customer (id, cert, rssdID, name, customerStatusID, deleted, updatedBy, updatedDateTime) " &_
				"values (" & newID & "," & certID & "," & rssdID & ",'" & customerName & "'," & customerStatusID & ",0," & session("userID") & ",current_timestamp) "
		dbug("inserting new customer: " & SQL)
		set rs = dataconn.execute(SQL)
		dbug("new customer inserted")	
' 		rs.close 
		set rs = nothing
		session("msg") = "customer " & trim(customerName) & " added"
		
		dbug("insert of new customer complete, executing server.transfer...")
		server.transfer "customerList.asp"
		dbug("post server.transfer...")

	else
		
		dbug("required fields missing...")
		session("msg") = "Required fields missing"
		
	end if

case "update"
	dbug("case udpate")

	validateInput 
	
	dbug("right after 'validateInput'...")
	dbug("id: " & id)
	dbug("customerName: " & customerName)
	dbug("certID: " & certID)
	dbug("rssdID: " & rssdID)
	dbug("customerStatusID: " & customerStatusID)
	
	if not inputValidationError then 
		
		SQL = "update customer set " &_
				"	cert = " & certID & ", " &_
				"	rssdID = " & rssdID & ", " &_
				"	name = '" & customerName & "', " &_
				"	customerStatusID = " & customerStatusID & ", " &_
				"	updatedBy = " & session("userID") & ", " &_
				"	updatedDateTime = current_timestamp " &_
				"WHERE ID = " & id 
				
		dbug("updating: " & SQL)
		set rs = dataconn.execute(SQL)
		set rs = nothing
		session("msg") = "customer " & trim(customerName) & " updated"
		
		server.transfer "customerList.asp"

	end if
	
case "edit"
	dbug("case edit")

	directive = "update"
	
	SQL = "select c.id, c.cert, c.rssdID, c.name, c.customerStatusID, cs.name as csName " &_
			"from customer_view c " &_
			"left join customerStatus cs on (cs.id = c.customerStatusID) " &_
			"where c.id = " & request.querystring("id")
	dbug(SQL)
	set rs = dataconn.execute(SQL)
	
	if not rs.eof then 
		id 					= rs("id")
		customerName 		= rs("name")
		certID 				= rs("cert")
		rssdID 				= rs("rssdID")
		customerStatusID 	= rs("customerStatusID")
		csName 				= rs("csName")
	else 
		id 					= request.querystring("id")
		customerName 		= ""
		certID 				= ""
		rssdID 				= ""
		customerStatusID 	= ""
		csName 				= ""
	end if 
			
	
case else 
	dbug("case else")

	directive = "add" 
	
	id 						= ""
	customerName 			= ""
	certID 					= ""
	rssdID 					= ""
	customerStatusID 		= ""
	csName 					= ""

end select 

dbug("end of top-logic")
%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<!--getmdl-select-->   
	<link rel="stylesheet" href="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.css">
	<script defer src="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.js"></script>	

	<script type="text/javascript" src="customerEdit.js"></script>

</head>
<% dbug("completed 'HTML <head>' ") %>
<body>

<form action="customerAdd.asp?cmd=<% =directive %>" method="POST" name="customerAdd" id="customerAdd">

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
		<!-- Your content goes here -->

		<div class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button type="button" class="mdl-snackbar__action"></button>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--9-col">
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="customerName" name="customerName" value="<% =customerName %>" >
				    <label class="mdl-textfield__label" for="customerName">Customer name...</label>
				</div>
<!-- 				<br> -->
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="certID" name="certID" value="<% =certID %>" pattern="-?[0-9]*(\.[0-9]+)?">
				    <label class="mdl-textfield__label" for="certID">Cert ID...</label>
				    <span class="mdl-textfield__error">Numbers only</span>
				</div>
<!-- 				<br> -->
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="rssdID" name="rssdID" value="<% =rssdID %>" pattern="-?[0-9]*(\.[0-9]+)?">
				    <label class="mdl-textfield__label" for="rssdID">RSSDID...</label>
				    <span class="mdl-textfield__error">Numbers only</span>
				</div>
<!-- 				<br> -->
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label getmdl-select getmdl-select__fullwidth">
					<input class="mdl-textfield__input" id="customerStatus" name="customerStatus" value="<% =csName %>" type="text" readonly data-val="<% =customerStatusID %>" onchange="captureCustomerStatusID_onchange(this)"/>
					<label class="mdl-textfield__label" for="customerStatus">Customer Status...</label>
					<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu" for="customerStatus">
						<%
						SQL = "select id, name from customerStatus order by name "
						set rsComp = dataconn.execute(SQL)
						while not rsComp.eof
							%>
							<li class="mdl-menu__item" data-val="<% =rsComp("id") %>"><% =rsComp("name") %></li>
							<%
							rsComp.movenext 
						wend
						rsComp.close 
						set rsComp = nothing
						%>
					</ul>
					<input type="hidden" id="id" name="id" value="<% =id %>">
					<input type="hidden" id="customerStatusID" name="customerStatusID" value="<% =customerStatusID %>">
				</div>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
		
		
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--9-col">
				<%
				SQL = "select u.id, firstName, cm.startDate, cm.endDate " &_
						"from cSuite..users u  " &_
						"join customerManagers cm on (cm.userID = u.id and cm.customerID = " & request.querystring("id") & " )  " &_
						"where u.customerID = 1  " &_
						"and managerType = 'account' " &_
						"and cm.startDate <= getdate() and getdate() <= cm.endDate "
				set currAM = dataconn.execute(SQL)
				if not currAM.eof then 
					acctMgrID = currAM("id")
					acctMgrName = currAM("firstName")
				else 
					acctMgrID = ""
					acctMgrName = ""
				end if
				currAM.close 
				set currAM = nothing 
				%>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label getmdl-select getmdl-select__fullwidth">
					<input class="mdl-textfield__input" id="accountManager" name="accountManager" value="<% =acctMgrName %>" type="text" readonly data-val="<% =accMgrID %>" onchange="captureCustomerStatusID_onchange(this)"/>
					<label class="mdl-textfield__label" for="customerStatus">Account manager...</label>
					<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu" for="accountManager">
						<%
						SQL = "select u.id, firstName, cm.startDate, cm.endDate " &_
								"from cSuite..users u " &_
								"left join customerManagers cm on (cm.userID = u.id and cm.customerID = " & request.querystring("id") & " and managerType = 'account') " &_
								"where u.customerID = 1 " &_
								"order by firstName"
						set rsAM = dataconn.execute(SQL)
						while not rsAM.eof
							%>
							<li class="mdl-menu__item" data-val="<% =rsAM("id") %>"><% =rsAM("firstName") %></li>
							<%
							rsAM.movenext 
						wend
						rsAM.close 
						set rsAM = nothing
						%>
					</ul>
				</div>

				<%
				SQL = "select u.id, firstName, cm.startDate, cm.endDate " &_
						"from cSuite..users u  " &_
						"join customerManagers cm on (cm.userID = u.id and cm.customerID = " & request.querystring("id") & " )  " &_
						"where u.customerID = 1  " &_
						"and managerType = 'relationship' " &_
						"and cm.startDate <= getdate() and getdate() <= cm.endDate "
				set currAM = dataconn.execute(SQL)
				if not currAM.eof then 
					acctMgrID = currAM("id")
					acctMgrName = currAM("firstName")
				else 
					acctMgrID = ""
					acctMgrName = ""
				end if
				currAM.close 
				set currAM = nothing 
				%>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label getmdl-select getmdl-select__fullwidth">
					<input class="mdl-textfield__input" id="relationshipManager" name="relationshipManager" value="<% =acctMgrName %>" type="text" readonly data-val="<% =accMgrID %>" onchange="captureCustomerStatusID_onchange(this)"/>
					<label class="mdl-textfield__label" for="relationshipManager">Relationship manager...</label>
					<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu" for="relationshipManager">
						<%
						SQL = "select u.id, firstName, cm.startDate, cm.endDate " &_
								"from cSuite..users u " &_
								"left join customerManagers cm on (cm.userID = u.id and cm.customerID = " & request.querystring("id") & " and managerType = 'relationship') " &_
								"where u.customerID = 1 " &_
								"order by firstName"
						set rsAM = dataconn.execute(SQL)
						while not rsAM.eof
							%>
							<li class="mdl-menu__item" data-val="<% =rsAM("id") %>"><% =rsAM("firstName") %></li>
							<%
							rsAM.movenext 
						wend
						rsAM.close 
						set rsAM = nothing
						%>
					</ul>
				</div>

			
			
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="rssdID" name="rssdID" value="" pattern="-?[0-9]*(\.[0-9]+)?">
				    <label class="mdl-textfield__label" for="rssdID">Number of employees...</label>
				    <span class="mdl-textfield__error">Numbers only</span>
				</div>
	
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="rssdID" name="rssdID" value="" pattern="-?[0-9]*(\.[0-9]+)?">
				    <label class="mdl-textfield__label" for="rssdID">Monthly recurring revenue...</label>
				    <span class="mdl-textfield__error">Numbers only</span>
				</div>

			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
	
		
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">

				<div align="right">
					<!-- Flat button with ripple -->
					<button class="mdl-button mdl-js-button mdl-js-ripple-effect">
					CANCEL
					</button>
					<!-- Flat button with ripple -->
					<button class="mdl-button mdl-js-button mdl-js-ripple-effect" type="submit">
					SAVE
					</button>
				</div>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

		
		
		<hr>
					
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">
				<div style="vertical-align: bottom; display: inline-block;">
					<span class="mdl-typography--title">Client Managers</span>
				</div>
				<div style="vertical-align: bottom; display: inline-block;">
					<button class="mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored mdl-js-ripple-effect" onclick="parent.location='customerClientMangers.asp?id=<% =request.querystring("id") %>';">
						<i class="material-icons">add</i>
					</button>					
				</div>
				
				<table class="mdl-data-table mdl-js-data-table">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">Name</th>
							<th class="mdl-data-table__cell--non-numeric">Type</th>
							<th class="mdl-data-table__cell--non-numeric">Start Date</th>
							<th class="mdl-data-table__cell--non-numeric">End Date</th>
						</tr>
					</thead>
			  		<tbody> 
				  	<%
					SQL = "select u.id, firstName, cm.managerType, cm.startDate, cm.endDate " &_
							"from customerManagers cm " &_
							"left join cSuite..users u on (u.id = cm.userID) " &_
							"where cm.startDate <= getdate() and getdate() <= cm.endDate " &_
							"and cm.customerID = " & request.querystring("id") & " " 
							
					set rsCM = dataconn.execute(SQL)
					while not rsCM.eof 		
					  	%>
						<tr>
							<td class="mdl-data-table__cell--non-numeric"><% =rsCM("firstName") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rsCM("managerType") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rsCM("startDate"),2) %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rsCM("endDate"),2) %></td>
						</tr>
						<%
						rsCM.movenext 
					wend 
					rsCM.close 
					set rsCM = nothing 
					%>
			  		</tbody>
				</table>
							
			</div>
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col">

				<span class="mdl-typography--title">Customer Contacts</span>

				<table class="mdl-data-table mdl-js-data-table">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">Name</th>
							<th class="mdl-data-table__cell--non-numeric">Title</th>
							<th class="mdl-data-table__cell--non-numeric">Deposit?</th>
							<th class="mdl-data-table__cell--non-numeric">Loan?</th>
							<th class="mdl-data-table__cell--non-numeric" style="width: 50px">ZeroRisk</th>
							<th class="mdl-data-table__cell--numeric">Actions</th>
						</tr>
					</thead>
			  		<tbody> 
		
						<tr>
							<td class="mdl-data-table__cell--non-numeric">
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 200px">
								    <input class="mdl-textfield__input" type="text" id="contactName-add" name="contactName-add" value="" pattern="[A-Z,a-z,\-, ]*">
								    <label class="mdl-textfield__label" for="contactName-add">Add a contact name...</label>
								    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
								</div>
	   					</td>
							<td class="mdl-data-table__cell--non-numeric">
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 200px">
								    <input class="mdl-textfield__input" type="text" id="contactTitle-add" name="contactTitle-add" value="" pattern="[A-Z,a-z,\-, ]*">
								    <label class="mdl-textfield__label" for="contactTitle-add">Add a contact title...</label>
								    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
								</div>
	   					</td>

							<td class="mdl-data-table__cell--non-numeric">
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="contactDepositInd-add">
									<input type="checkbox" id="contactDepositInd-add" class="mdl-checkbox__input" <% =checked %> onclick="customerContact_onClick(this)" />
								</label>
							</td>
							<td class="mdl-data-table__cell--non-numeric">
								<span class="mdl-list__item-secondary-action">
									<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="contactLoanInd-add">
										<input type="checkbox" id="contactLoanInd-add" class="mdl-checkbox__input" <% =checked %> onclick="customerContact_onClick(this)" />
										</label>
								</span>
							</td>
							<td class="mdl-data-table__cell--non-numeric">
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 50px">
								    <input class="mdl-textfield__input" type="text" id="contactName-add" name="contactName-add" value="" pattern="[A-Z,a-z,\-, ]*" style="width: 50px">
								    <label class="mdl-textfield__label" for="contactName-add">Grade...</label>
								    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
								</div>
							</td>
	   					<td class="mdl-data-table__cell--non-numeric">
								<button class="mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored mdl-js-ripple-effect" onclick="parent.location='customerAdd.asp';">
									<i class="material-icons">add</i>
								</button>					
	   					</td>
						</tr>
						<% dbug("completed header and 'add row' for customer contacts") %>
						<%
						SQL = "select id, name, title, depositInd, loanInd, zeroRiskGrade from customerContacts where customerID = " & request.querystring("id") & " "
						set rsCC = dataconn.execute(SQL)
						while not rsCC.eof 
							dbug("there are customerContact rows to display...")
							%>
							
							
							<tr>
								<td class="mdl-data-table__cell--non-numeric"><% =rsCC("name") %>
		   					</td>
								<td class="mdl-data-table__cell--non-numeric"><% =rsCC("title") %>
		   					</td>
	
								<td class="mdl-data-table__cell--non-numeric">
									<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="contactDepositInd-<% =rsCC("id") %>">
										<input type="checkbox" id="contactDepositInd-<% =rsCC("id") %>" class="mdl-checkbox__input" <% =checked %> onclick="customerContact_onClick(this)" />
									</label>
								</td>
								<td class="mdl-data-table__cell--non-numeric">
									<span class="mdl-list__item-secondary-action">
										<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="contactLoanInd-<% =rsCC("id") %>">
											<input type="checkbox" id="contactLoanInd-<% =rsCC("id") %>" class="mdl-checkbox__input" <% =checked %> onclick="customerContact_onClick(this)" />
											</label>
									</span>
								</td>
								<td class="mdl-data-table__cell--non-numeric" style="width: 100px"><% =rsCC("zeroRiskGrade") %>
								</td>
		   					<td class="mdl-data-table__cell--non-numeric">
									<img name="deleted" id="imgDeleted-<% =rsCC("id") %>" data-val="<% =rsCC("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer" onclick="customerContactDelete_onClick(this)">
		   					</td>
							</tr>


							
							<%
							rsCC.movenext 

						wend 
						rsCC.close 
						set rsCC = nothing 
						%>

			  		</tbody>
				</table>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

	</div>

</main>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>