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
title = session("clientID") & " - Terms & Conditions" 
userLog(title)
%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

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

  
			
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>

				<h5>Terms & Conditions</h5>

			<div class="mdl-layout-spacer"></div>
			
   	</div>
	
    
  </main>
  <!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>