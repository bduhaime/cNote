<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/getNextID.asp" -->
<% 
if not userPermitted(30) then response.end() end if
userLog("Call types")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Lightspeed VT API Test"

dbug(" ")
dbug("start of script....")

dbug("request.querystring('cmd'): " & request.querystring("cmd"))


dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<script type="text/javascript" src="lsvt.js"></script>
		
</head>

<body>
<form id="form_addCCT" action="callTypes.asp?cmd=add" method="POST">

<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content">
		<!-- Your content goes here -->
			
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--7-col" align="center">

				<table id="tbl_clientProjects" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">Name</th>
							<th class="mdl-data-table__cell--non-numeric">Value</th>
						</tr>
					</thead>
			  		<tbody> 
						<tr>
							<td class="mdl-data-table__cell--non-numeric">Command</td>
							<td class="mdl-data-table__cell--non-numeric"><input id="command" type="text" size="50" value="getGdlrList"> </td>
						</tr>
			  		</tbody>
				</table>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--1-col" align="center">

				<div id="dialog_buttons" class="mdl-dialog__actions">
					<button type="button" class="mdl-button Submit" onclick="Submit_onClick(this)">Submit</button>
				</div>

			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
	</div>
	
		


</main>

<!-- #include file="includes/pageFooter.asp" -->



<%
dataconn.close 
set dataconn = nothing
%>
<script>
	
	
	//***************************************************************************************************************
	//
	// 	check to see if there is a valid cookie for lsvtToken. 
	// 	
	//		if one doesn't exist {
	//			go get a new token from lightspeedvt.net 
	//			store it in the cookie
	// 	}
	//
	//***************************************************************************************************************
	
	var lsvtToken = getCookie('lsvtToken');
	
	if (!lsvtToken) {

		CreateRequest();
		
		if(request) {
			request.onreadystatechange = StateChangeHandler_GetLsvtToken;
			request.open("POST", "https://webservices.lightspeedvt.net/lsvt_api_v35.ashx", true);
			request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
			request.send('command=getLGToken&authkey=6444E140');
		}

		function StateChangeHandler_GetLsvtToken() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					lsvtToken = GetInnerText(request.responseXML.getElementsByTagName('data')[0]);
					setCookie('lsvtToken', lsvtToken, 23);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}			
			
	}
	

</script>


</body>
</html>