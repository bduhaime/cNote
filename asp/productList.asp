<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(8)

userLog("Processes")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Processes"

dbug("start of top-logic")

select case request.querystring("cmd")
	case "add"
	
		inputValidationError = false
		if len(request.form("productName")) > 0 then
			productName = request.form("productName")
		else
			inputValidationError = true
		end if
		dbug("productName: " & productName)
		dbug("inputValidationError=" & inputValidationError)
		if not inputValidationError then
			
			dbug("finding new id value...")
			SQL = "select max(id) as maxID from products "
			
			set rs = dataconn.execute(SQL)
			if not rs.eof then
				newID = cInt(rs("maxID")) + 1
			else
				newID = 1
			end if
			rs.close
			dbug("new id found: " & newID)
			
	
		
			SQL = 	"insert into products (id, name, deleted, updatedBy, updatedDateTime) " &_
					"values (" & newID & ",'" & productName & "',0," & session("userID") & ",current_timestamp) "
			dbug("inserting new cutomerStatus: " & SQL)
			set rs = dataconn.execute(SQL)
			dbug("new product inserted")	
	' 		rs.close 
			set rs = nothing
			session("msg") = "Customer status " & trim(roleName) & " added"
			SQL = ""
		else
			
			dbug("required fields missing...")
			session("msg") = "Required fields missing"
			
		end if
	
	case "delete"
	
		productID = request.querystring("id")
		SQL = "delete from products where id = " & productID & " "
		
		dbug("SQL: " & SQL)
		set rs = dataconn.execute(SQL)
		set rs = nothing
		
	
	case else 
end select 

dbug("end of top-logic")
%>

<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	<script type="text/javascript" src="productList.js"></script>

</head>

<body>


<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
		<div class="page-content">
			<!-- Your content goes here -->
			
			<!-- DIALOG: Add/Edit Process Type -->
			<dialog id="dialog_product" class="mdl-dialog" data-role='popup' data-history='false' style="width: 660px">
				<h4 class="mdl-dialog__title">Add/Edit A Process</h4>
				<div class="mdl-dialog__content">
			
					<form id="form_product">
	
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productName" name="productName" value="" required autocomplete="off">
						    <label class="mdl-textfield__label" for="productName">Name...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productDescription" name="productDescription" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productDescription">Description...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productType" name="productType" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productType">Type...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productVendor" name="productVendor" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productVendor">Vendor...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productFocus" name="productFocus" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productFocus">Focus...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productCoreAnnualQty" name="productCoreAnnualQty" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productCoreAnnualQty">Core annual quantity...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productAdvAnnualQty" name="productAdvAnnualQty" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productAdvAnnualQty">Advanced annual quantity...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="productEliteAnnualQty" name="productEliteAnnualQty" value="" autocomplete="off">
						    <label class="mdl-textfield__label" for="productEliteAnnualQty">Elite annual quantity...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="productAvailableAloneInd">
							  <input type="checkbox" id="productAvailableAloneInd" class="mdl-switch__input">
							  <span class="mdl-switch__label">Available alone?</span>
							</label>
						</div>
		
		
						<input type="hidden" id="productID" value="">
	
					</form>
	
				</div>
				<div class="mdl-dialog__actions">
					<button type="submit" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog>
	  
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--11-col" align="left">
					<button id="button_newProduct" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Process
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
				
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--11-col">


					<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric">Name</th>
								<th class="mdl-data-table__cell--non-numeric">Description</th>
								<th class="mdl-data-table__cell--non-numeric">Type</th>
								<th class="mdl-data-table__cell--non-numeric">Vendor</th>
								<th class="mdl-data-table__cell--non-numeric">Focus</th>
								<th class="mdl-data-table__cell--non-numeric">Core Annual</th>
								<th class="mdl-data-table__cell--non-numeric">Advanced Annual</th>
								<th class="mdl-data-table__cell--non-numeric">Elite Annual</th>
								<th class="mdl-data-table__cell--non-numeric">Alone?</th>
								<th class="mdl-data-table__cell--numeric">Actions</th>
							</tr>
						</thead>
				  		<tbody> 
						<%
						SQL = "select id, name, description, productType, vendor, focus, coreAnnualQty, advAnnualQty, eliteAnnualQty, availableAloneInd, deleted " &_
								"from products " &_
								"order by name " 
						dbug(SQL)
						set rs = dataconn.execute(SQL)
						while not rs.eof
							%>
							<tr>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("name") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("description") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("productType") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("vendor") %></td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("focus") %></td>
								<td class="mdl-data-table__cell--numeric"><% =formatNumber(rs("coreAnnualQty"),0) %></td>
								<td class="mdl-data-table__cell--numeric"><% =formatNumber(rs("advAnnualQty"),0) %></td>
								<td class="mdl-data-table__cell--numeric"><% =formatNumber(rs("eliteAnnualQty"),0) %></td>
								<td class="mdl-data-table__cell--non-numeric">
									<% if rs("availableAloneInd") then checked = "checked" else checked = "" end if %>
									<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="<% =rs("id") %>-availableAloneInd">
									  <input type="checkbox" id="<% =rs("id") %>-availableAloneInd" class="mdl-switch__input" <% =checked %> disabled>
									  <span class="mdl-switch__label"></span>
									</label>

								</td>
								<%
								dbug("rs('deleted'): " & rs("deleted"))
								if isNull(rs("deleted")) or rs("deleted") = 0 then
									dbug("customerStaus is NOT deleted")
									image = "/images/ic_delete_black_24dp_1x.png"
								else
									dbug("product is deleted")
									image = "/images/ic_delete_forever_black_24dp_1x.png"
								end if
								%>		
								<td class="mdl-data-table__cell--non-numeric" align="center">

									<button type="button" id="button_editCallType" class="mdl-button mdl-js-button mdl-button--icon" data-val="<% =rs("id") %>" onclick="EditProduct_onClick(this);">
									  <i class="material-icons">mode_edit</i>
									</button>								

									<a href="productList.asp?cmd=delete&id=<% =rs("id") %>" onclick="return confirm('Are you sure you want to delete this item?');">
										<img name="deleted" id="imgDeleted-<% =rs("id") %>" data-val="<% =rs("deleted") %>" src="<% =image %>">
									</a>
									
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
		</div>
	</main>
	<!-- #include file="includes/pageFooter.asp" -->
<script src="dialog-polyfill.js"></script>  
<script>
	
// add/edit Products
	var dialog_product = document.querySelector('#dialog_product');
	var button_newProduct = document.querySelector('#button_newProduct');	
	if (! dialog_product.showModal) {
		dialogPolyfill.registerDialog(dialog_product);
	}	
	button_newProduct.addEventListener('click', function() {
		dialog_product.showModal();
	});
	dialog_product.querySelector('.cancel').addEventListener('click', function() {
		dialog_product.close();
	});

	dialog_product.querySelector('.save').addEventListener('click', function() {
		document.forms["form_product"].submit();
		AddProduct_onSave(dialog_product);
		dialog_product.close();
	});


</script>

<%
dataconn.close 
set dataconn = nothing
%>


</body>
</html>