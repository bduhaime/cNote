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
<% 

%>

<html>

<head>

	<script type="text/javascript" src="formTests.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	<script type="text/javascript" src="datalist-polyfill.js"></script>

</head>
<body>

	<br><br>
	<form id="form_customer" style="border: solid black">
		
		<table align="center">


			<tr>
				<td>Institution Selector</td>
				<td>
					<input class="mdl-textfield__input" type="text" id="form_institutions" list="institutionsList" value="">
					<datalist id="institutionsList"></datalist>
				</td>
			</tr>


			<tr>
				<td>Customer Name</td>
				<td><input class="mdl-textfield__input" type="text" id="form_customerName" value=""></td>
			</tr>
			<tr>
				<td>RSSD</td>
				<td><input class="mdl-textfield__input" type="text" id="form_customerRSSDID" pattern="-?[0-9]*(\.[0-9]+)?" value=""></td>
			</tr>
			<tr>
				<td>Status</td>
				<td>
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
				</td>
			</tr>
			<tr>
				<td>Hidden Customer ID</td>
				<td><input id="form_customerID" type="hidden" value="<% =id %>"/></td>
			</tr>
		</table>
	
		<br><br>
		<div id="dialog_buttons" align="center">
			<button type="button">Save</button>
			<button type="button">Cancel</button>
		</div>

	</form>
	
</body>
</html>