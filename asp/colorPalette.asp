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
call checkPageAccess(27)

userLog("Color palette")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Color Palette"

dbug("start of top-logic")





dbug("end of top-logic")
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************



%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<style>
		
		.demo-card-square.mdl-card {
		  width: 240px;
		  height: 240px;
		}
		
	</style>

	<script>
		window.onload = function() {
			document.querySelector('.mdl-spinner').classList.remove('is-active');
		};
	</script>
	
</head>

<body>
<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>

<form action="customerStatusList.asp?cmd=add" method="POST" name="userEdit" id="userEdit">

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->


	<main class="mdl-layout__content">
		<div class="page-content">
			<!-- Your content goes here -->
			<br>
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--4-col">
					
					<table width="75%" style="padding: 5px;">
						
						<tr style="padding: 5px;">
							<td width=50% style="padding: 5px;">Home Page Card Background:</td>
							<td style="padding: 5px;">

								<div class="demo-card-square mdl-card mdl-shadow--2dp">
								  <div class="mdl-card__title mdl-card--expand" style="background:  #46B6AC;">
								    <h2 class="mdl-card__title-text"></h2>
								  </div>
								  <div class="mdl-card__supporting-text">
								    Lorem ipsum...
								  </div>
								  <div class="mdl-card__actions mdl-card--border">
								    <a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect">
								      View Updates
								    </a>
								  </div>
								</div>								
								
							</td>
						</tr>
						
						<tr style="padding: 5px;">
							<td width=50% style="padding: 5px;">Security Page Card Background:</td>
							<td style="padding: 5px;">

								<div class="demo-card-square mdl-card mdl-shadow--2dp">
								  <div class="mdl-card__title mdl-card--expand" style="background:  #FF8C00;">
								    <h2 class="mdl-card__title-text"></h2>
								  </div>
								  <div class="mdl-card__supporting-text">
								    Lorem ipsum...
								  </div>
								  <div class="mdl-card__actions mdl-card--border">
								    <a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect">
								      View Updates
								    </a>
								  </div>
								</div>								
								
							</td>
						</tr>
						
						<tr style="padding: 5px;">
							<td width=50% style="padding: 5px;">Project/Task Status:</td>
							<td style="padding: 5px;">

								<table>
									<tr><td>Project:</td><td style="background: orange; width: 1200px;">Orange</td></tr>
									<tr><td>Complete:</td><td style="background: black; color: white;">Black</td></tr>
									<tr><td>Behind:</td><td style="background: red; color: white;">Red</td></tr>
									<tr><td>On Time:</td><td style="background: green; color: white;">Green</td></tr>
								</table>
								
							</td>
						</tr>
						
					</table>
					
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

</form>

</body>
</html>