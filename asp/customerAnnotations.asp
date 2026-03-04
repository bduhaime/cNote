<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<% 
title = session("clientID") & " - " & customerTitle(request.querystring("id"))
' title = "Customer Annotations" 

%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	<script type="text/javascript" src="customerEdit.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div class="page-content">
    <!-- Your content goes here -->
	<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
	    <div class="mdl-snackbar__text"></div>
	    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
	</div>

		<!-- DIALOG: Add New Customer -->
		<dialog id="dialog_addCustomer" class="mdl-dialog">
			<h4 id="formTitle" class="mdl-dialog__title">New Customer</h4>
			<div class="mdl-dialog__content">

				<form id="form_customer">

					<label for="form_institutionSwitch" class="mdl-switch mdl-js-switch mdl-js-ripple-effect">
					  <input type="checkbox" id="form_institutionSwitch" class="mdl-switch__input" onclick="InstitutionSwitch_onClick(this)">
					  <span class="mdl-switch__label">Is the new customer an FDIC Institution?</span>
					</label>
					<br><br>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
					    <input class="mdl-textfield__input" type="text" id="form_customerName" value="">
					    <label class="mdl-textfield__label" for="form_customerName">Customer name...</label>
					</div>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
					    <input class="mdl-textfield__input" type="text" id="form_customerRSSDID" pattern="-?[0-9]*(\.[0-9]+)?" value="">
					    <label class="mdl-textfield__label" for="form_customerRSSDID">RSSD ID...</label>
						 <span class="mdl-textfield__error">RSSD ID must be numeric</span>
					</div>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
					    <input class="mdl-textfield__input" type="text" id="form_institutions" list="institutionsList" value="" onkeyup="hinter(this)" >
					    <label class="mdl-textfield__label" for="form_institutions">Start typing an institution name...</label>

						<datalist id="institutionsList">
						</datalist>

					</div>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
						<select class="mdl-textfield__input" id="form_customerStatus">
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
								response.write("<option value=""" & rsStatus("id") & """>" & rsStatus("name") & "</option>")
								rsStatus.movenext 
							wend
							rsStatus.close
							set rsStatus = nothing
							%>
							</select>
						<label class="mdl-textfield__label" for="form_customerStatus">Status...</label>
						<span class="mdl-textfield__error">Select a status</span>
					</div>
					
					<input id="form_customerID" type="hidden" value=""/>
					
				</form>
				
				
			</div>
			<div id="dialog_buttons" class="mdl-dialog__actions" style="display: none">
				<button type="button" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog>
  


   	<div class="mdl-grid">
			
			<div class="mdl-layout-spacer"></div>
			
		   <div class="mdl-cell mdl-cell--7-col">
			    
				<div align="center"><h4>Customer Annotations</h4></div>
				<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
		<!-- 	<table class="mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp"> -->
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">ID</th>
							<th class="mdl-data-table__cell--non-numeric">Attribute</th>
							<th class="mdl-data-table__cell--non-numeric">Date</th>
							<th class="mdl-data-table__cell--non-numeric">Narrative</th>
							<th class="mdl-data-table__cell--non-numeric">Added By</th>
							<th class="mdl-data-table__cell--non-numeric">Metric</th>
							<th class="mdl-data-table__cell--numeric">
								<button id="button_newCustomer" class="mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored mdl-js-ripple-effect">
									<i class="material-icons">add</i>
								</button>
							</th>
						</tr>
					</thead>
						<tbody> 
					<%
					SQL = "select ca.id, ca.attributeID, ca.attributeDate, ca.narrative, ca.addedBy, m.name, u.firstName + ' ' + u.lastName as userName  " &_
							"from customerAnnotations ca " &_
							"left join metric m on (m.id = ca.metricID) " &_
							"left join cSuite..users u on (u.id = ca.addedBy) " &_
							"where ca.customerID = " & request("id") & " " 
				
					dbug(SQL)
					set rs = dataconn.execute(SQL)
					while not rs.eof
						%>
						<tr>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("id") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("attributeID") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =formatDateTime(rs("attributeDate"),2) %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("narrative") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("userName") %></td>
							<td class="mdl-data-table__cell--non-numeric"><% =rs("name") %></td>
							<td class="mdl-data-table__cell--non-numeric">
								<% if userPermitted(18) then %>
									<img src="/images/ic_edit_black_24dp_1x.png" data-val="<% =rs("id") %>" onclick="CustomerAnnotationEdit_onClick(this)">
								<% end if %>
								<img name="deleted" id="imgDeleted-<% =rs("id") %>" data-val="<% =rs("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer" onclick="CustomerAnnotationDelete_onClick(this,<% =rs("id") %>)">
							</td>
						</tr>			
						<%
						rs.movenext 
					wend
					rs.close 
					set rs = nothing
					%>
				
						</tbody>
				</table>		    			    
	
				</div>
			<div class="mdl-layout-spacer"></div>
			
   	</div>
	
    
	</main>
	<!-- #include file="includes/pageFooter.asp" -->

	<script src="dialog-polyfill.js"></script>  
	<script>
	 
	var dialog_addCustomer = document.querySelector('#dialog_addCustomer');
	var button_newCustomer = document.querySelector('#button_newCustomer');
	
	if (! dialog_addCustomer.showModal) {
		dialogPolyfill.registerDialog(dialog_addCustomer);
	}
	
	button_newCustomer.addEventListener('click', function() {
		CustomerAdd_onClick();
	// 	dialog_addCustomer.showModal();
	});
	
	dialog_addCustomer.querySelector('.cancel').addEventListener('click', function() {
		dialog_addCustomer.close();
	});
	
	dialog_addCustomer.querySelector('.save').addEventListener('click', function() {
		AddCustomer_onSave(dialog_addCustomer)
		dialog_addCustomer.close();
	});
	 
	
	
	/*
	window.addEventListener("load", function(){
	
	    var institution_name = document.getElementById('form_institutions');
	    institution_name.addEventListener("keyup", function(event){hinter(event)});
	    window.hinterXHR = new XMLHttpRequest();
	
	});
	*/
	
	
	</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>