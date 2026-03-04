 <!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/systemControls.asp" -->

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<style>
	.demo-list-icon {
	  width: 300px;
	}
	</style>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
<header class="mdl-layout__header">
	<div class="mdl-layout__header-row">

		<div class="mdl-layout-spacer"></div>

		<span class="mdl-layout-title">403 - Forbidden</span>
		
		<div class="mdl-layout-spacer"></div>

	</div>
</header>



<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
   
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col" style="text-align: center; display: table-cell; vertical-align: middle;">
				You do not have permission to access the requested resource<br>Request has been logged.<br><br>If you think you have received this message in error please contact your system administrator.
			</div>
			<div class="mdl-layout-spacer"></div>
		</div> <!-- end grid -->

		<br>

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col">
				<table style="margin-left: auto; margin-right: auto;">
					<tr>
						<td><b>Username:</b></td><td><% =session("username") %></td>
					</tr>
					<tr>
						<td><b>Client:</b></td><td><% =session("clientID") %></td>
					</tr>
					<tr>
						<td><b>ResourceID:</b></td><td><% =session("403") %></td>
					</tr>
				</table>
			</div>
			<div class="mdl-layout-spacer"></div>
   	</div>
   	
		<br><br>

   	
   	
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--1-col">
				<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect" onclick="location='login.asp'">
					Login
				</button>
			</div>
			<div class="mdl-cell mdl-cell--1-col">
				<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect" onclick="window.history.back()">
					Go Back
				</button>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div> <!-- end grid -->

  	</div> <!-- end page-content -->
	   
</main>
<!-- #include file="includes/pageFooter.asp" -->
<% session.contents.remove("403") %>

</body>
</html>