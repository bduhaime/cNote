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

title = "Add A Metric" 

if request.querystring("cmd") = "add" then
	dbug("cmd = 'add'")
	
	inputValidationError = false
	
	if len(request.form("metricName")) > 0 then
		metricName = request.form("metricName")
		SQL = "select name from metric where name = '" & metricName & "' "
		set rs = dataconn.execute(SQL)
		if rs.eof then
			dbug("metric is unique")
		else 
			dbug("duplicate metric name entered: " & metricName)
			inputValidationError = true 
		end if
	else
		dbug("metricName missing")
		inputValidationError = true
	end if
	
	dbug("inputValidationError=" & inputValidationError)
	if not inputValidationError then
		
		metricName = request.form("metricName")
		scaleMin = request.form("scaleMin")
		scaleMax = request.form("scaleMax")
		weight = request.form("weight")
		
		dbug("finding new id value...")
		SQL = "select max(id) as maxID from metric "
		
		set rs = dataconn.execute(SQL)
		if not rs.eof then
			newID = cInt(rs("maxID")) + 1
		else
			newID = 1
		end if
		rs.close
		dbug("new id found: " & newID)
		
		SQL = 	"insert into metric (id, [name], updatedDateTime, updatedBy, scaleMax, scaleMin, deleted, weight) " &_
				"values (" & newID & ",'" & metricName & "','" & updateDate & "'," & session("userID") & "," & scaleMax & "," & scaleMin & ",0," & weight & ") "
		dbug("inserting new metric: " & SQL)
		set rs = dataconn.execute(SQL)
		dbug("new metric inserted")	
' 		rs.close 
		set rs = nothing
		session("msg") = "metric " & trim(metricName) & " added"
		
		dbug("insert of new metric complete, executing server.transfer...")
		server.transfer "metricList.asp"
		dbug("post server.transfer...")

	else
		
		dbug("required fields missing...")
		session("msg") = "Required fields missing"
		
	end if

	
end if

userID = 0

dbug("end of top-logic")
%>





<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<script type="text/javascript" src="metricEdit.js"></script>

</head>

<body>

<form action="metricAdd.asp?cmd=add" method="POST" name="metricEdit" id="metricEdit">

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
				    <input class="mdl-textfield__input" type="text" id="metricName" name="metricName" value="" pattern="[A-Z,a-z,\-, ]*">
				    <label class="mdl-textfield__label" for="metricName">Name...</label>
				    <span class="mdl-textfield__error">Letters, spaces, and hyphens only</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="scaleMin" name="scaleMin" value="" pattern="-?[0-9]*(\.[0-9]+)?" >
				    <label class="mdl-textfield__label" for="scaleMin">Scale Minimum...</label>
				    <span class="mdl-textfield__error">Input must be numeric</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="scaleMax" name="scaleMax" value="" pattern="-?[0-9]*(\.[0-9]+)?" >
				    <label class="mdl-textfield__label" for="scaleMax">Scale Maximum...</label>
				    <span class="mdl-textfield__error">Input must be numeric</span>
				</div>
				<br>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input" type="text" id="weight" name="weight" value="" pattern="-?[0-9]*(\.[0-9]+)?" >
				    <label class="mdl-textfield__label" for="weight">Weight...</label>
				    <span class="mdl-textfield__error">Input must be numeric</span>
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

	</div>

</main>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>