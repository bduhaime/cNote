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
<% 
logID = request.querystring("logID")

SQL = "select l.id, l.addedDateTime, l.addedBy, l.subject, l.toList, l.ccList, l.html, concat(u.firstName, ' ', u.lastName) as userName " &_
		"from customerCallEmailLog l " &_
		"left join cSuite..users u on (u.id = l.addedBy) " &_
		"where l.id = " & logID & " " 
		
dbug(SQL)

set rsLog = dataconn.execute(SQL)

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************



%>

<html>

<head>
	<meta charset="UTF-8">
	<!-- #include file="includes/globalHead.asp" -->


	<!-- 	Quill Rich Text Editor 1.3.5 -->
	<link href="https://cdn.quilljs.com/1.3.5/quill.snow.css" rel="stylesheet">
	<script src="https://cdn.quilljs.com/1.3.5/quill.js"></script>

	<script type="text/javascript" src="annotateCalls.js"></script>

</head>

<body>


<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->


<main class="mdl-layout__content">
	<div class="page-content">
		<!-- Your content goes here -->

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col">
				<table style="border: none; width: auto;">
					<tr><th style="border: none; text-align: left;">Date/Time</th><td style="border: none;"><% =rsLog("addedDateTime") %></td></tr>
					<tr><th style="border: none; text-align: left;">Sender</th><td style="border: none;"><% =rsLog("userName") %></td></tr>
					<tr><th style="border: none; text-align: left;">Subject</th><td style="border: none;"><% =rsLog("subject") %></td></tr>
					<tr><th style="border: none; text-align: left;">To:</th><td style="border: none;"><% =rsLog("toList") %></td></tr>
					<tr><th style="border: none; text-align: left;">Cc:</th><td style="border: none;"><% =rsLog("ccList") %></td></tr>
				</table>
				<br>
				<table style="border: none; width: 100%">
					<tr>
						<td class="htmlContainer" colspan="2" style="border: none;"><% =rsLog("html") %></td>
					</tr>
					</tbody>
				</table>
					
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
	</div>
</main>
<!-- #include file="includes/pageFooter.asp" -->

<%
rsLog.close 
set rsLog = nothing 

dataconn.close 
set dataconn = nothing
%>

</body>
</html>