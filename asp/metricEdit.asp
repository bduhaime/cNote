<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/randomString.asp" -->
<!-- #include file="includes/md5.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(21)

userLog("Metric Edit")
dbug("before top-logic")
title = "Edit A Metric" 

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	id = request.querystring("id")
	
	SQL = "select * " &_
			"from metric " &_
			"where id = " & id & " "
	
	dbug(SQL)
	set rs = dataconn.execute(SQL)
	dbug("rs objected successfully created")
	
	if not rs.eof then
		dbug("not rs.eof")
	else
		dub("rs.eof")
		response.write = "Metric not found."
	end if

end if

dbug("after top-logic")
%>





<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<script type="text/javascript" src="metricEdit.js"></script>

</head>

<body>

<form action="metricEdit.asp?cmd=updated" method="POST" name="metricEdit" id="metricEdit">

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
			<div class="mdl-cell mdl-cell--3-col">
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="metricName" name="metricName" value="<% =rs("name") %>" pattern="[A-Z,a-z,\-, ]*" onchange="metricAttribute_onChange(this,<% =id %>)">
				    <label class="mdl-textfield__label" for="metricName">Name...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="scaleMin" name="scaleMin" value="<% =rs("scaleMin") %>" pattern="-?[0-9]*(\.[0-9]+)?" onchange="metricAttribute_onChange(this,<% =id %>)">
				    <label class="mdl-textfield__label" for="scaleMin">Scale Minimum...</label>
				    <span class="mdl-textfield__error">Input must be numeric</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="scaleMax" name="scaleMax" value="<% =rs("scaleMax") %>" pattern="-?[0-9]*(\.[0-9]+)?" onchange="metricAttribute_onChange(this,<% =id %>)">
				    <label class="mdl-textfield__label" for="scaleMax">Scale Maximum...</label>
				    <span class="mdl-textfield__error">Input must be numeric</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="weight" name="weight" value="<% =rs("weight") %>" pattern="-?[0-9]*(\.[0-9]+)?" onchange="metricAttribute_onChange(this,<% =id %>)">
				    <label class="mdl-textfield__label" for="weight">Weight...</label>
				    <span class="mdl-textfield__error">Input must be numeric</span>
				</div>

			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col"><a href="metricList.asp">Return to list</a></div>
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