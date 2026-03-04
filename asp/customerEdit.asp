<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(18)

dbug("before top-logic")
title = "Edit A Customer" 

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
	
	'***** get customer header information *****
	SQL = "select c.id, c.name, i1.city, i1.stalp, s.description " &_
			"from customer_view c " &_
			"left join customerStatus s on (s.id = c.customerStatusID) " &_
			"left join fdic.dbo.institutions i1 on (i1.cert = c.cert and i1.repdte = (select max(repdte) from fdic.dbo.institutions where cert = c.cert)) " &_
			"where c.id = " & customerID & " "
	
	dbug(SQL)
	set rs = dataconn.execute(SQL)
	dbug(SQL)
	
	if not rs.eof then
		dbug("not rs.eof")
		customerName = rs("name")
		customerCity = rs("city") 
		customerState = rs("stalp") 
		customerStatus = rs("description")
	else
		dub("rs.eof")
		response.write = "Customer not found."
		customerName = ""
		customerCity = ""
		customerState = ""
		customerStatus = ""
	end if
	
	rs.close 
	set rs = nothing	

end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
%>





<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
</head>

<body>


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
			<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp" align="center">
				<h5>Edit an Existing Customer</h5>
			</div>
			<div class="mdl-layout-spacer"></div>
   	</div>
	

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="padding: 17px;">
				<%
				SQL = "select * from customer_view where id = " & customerID & " "
				dbug(SQL)
				set rs = dataconn.execute(SQL)
				%>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<input class="mdl-textfield__input" type="text" id="customerName" value="<% =rs("name") %>">
					<label class="mdl-textfield__label" for="customerName">Name...</label>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<input class="mdl-textfield__input" type="text" id="customerCert" value="<% =rs("cert") %>">
					<label class="mdl-textfield__label" for="customerCert">Cert...</label>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<input class="mdl-textfield__input" type="text" id="customerRSSDID" value="<% =rs("rssdid") %>">
					<label class="mdl-textfield__label" for="customerRSSDID">RSSD ID...</label>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<select class="mdl-textfield__input" id="customerStatus">
						<option></option>
						<%
						SQL = "select id, name " &_
								"from customerStatus " &_
								"where (active = 1 or active is null) " &_
								"and (deleted = 0 or deleted is null) " &_
								"order by name "
						dbug(SQL)
						set rsStatus = dataconn.execute(SQL)
						while not rsStatus.eof 
							if cInt(rsStatus("id")) = cInt(rs("customerStatusID")) then selected = "selected" else selected = "" end if 
							response.write("<option value=""" & rsStatus("id") & """" & selected & ">" & rsStatus("name") & "</option>")
							rsStatus.movenext 
						wend
						rsStatus.close
						set rsStatus = nothing
						%>
						</select>
					<label class="mdl-textfield__label" for="add_attributeTypeId">Status...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<input class="mdl-textfield__input" type="text" id="customerNickname" value="<% =rs("nickname") %>">
					<label class="mdl-textfield__label" for="customerNickname">Nick name...</label>
				</div>
				
				
  				<%
	  			rs.close 
	  			set rs = nothing
	  			%>
			</div>
			
			<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
				
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