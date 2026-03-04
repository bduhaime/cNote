<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(47)

if lCase(session("dbName")) <> "csuite" then  
	session.abandon()
	response.redirect "login.asp?msg=Access invalid for current client"
end if 

title = session("clientID") & " - " & "Home" 
userLog(title)
%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	
	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="moment-timezone.js"></script>

	<!-- Square card -->
	<style>
	.demo-card-square.mdl-card {
	  width: 320px;
	  height: 320px;
	}
	.demo-card-square > .mdl-card__title {
	  color: #fff;
	  background: rgb(70, 182, 172);
	}
	</style>


</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">

	<div class="page-content">
	<!-- Your content starts here -->

	<!-- 	ROW ONE  -->
   <div class="mdl-grid">

		<div class="mdl-layout-spacer"></div>

		<!-- 	ROW ONE, COLUMN ONE  -->
		<% if userPermitted(101) then %>
		<div class="mdl-cell mdl-cell--3-col">
			<div class="demo-card-square mdl-card mdl-shadow--2dp">
				<div class="mdl-card__title mdl-card--expand">
					<img src="images/baseline_business_center_black_48dp.png">
					<h2 class="mdl-card__title-text">Clients</h2>
				</div>
				<div class="mdl-card__supporting-text">
					View and manage cSuite clients.
				</div>
				<div class="mdl-card__actions mdl-card--border">
					<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="clientList.asp">
						View Clients
					</a>
				</div>
			</div>
		</div>
		<% end if %> 


		<!-- 	ROW ONE, COLUMN TWO  -->
		<% if userPermitted(99) then %>
		<div class="mdl-cell mdl-cell--3-col">
			<div class="demo-card-square mdl-card mdl-shadow--2dp">
				<div class="mdl-card__title mdl-card--expand">
					<img src="images/ic_dashboard_black_48dp_2x.png">
					<h2 class="mdl-card__title-text">SysOp Dashboard</h2>
				</div>
				<div class="mdl-card__supporting-text">
					View system metrics.
				</div>
				<div class="mdl-card__actions mdl-card--border">
					<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="csuiteSysopDashboard.asp">
						View Dashboard
					</a>
				</div>
			</div>
		</div>
		<% end if %>


		<div class="mdl-layout-spacer"></div>
	    

	</div>
	<!-- END ROW ONE -->


	</div>


</main>

	<!-- #include file="includes/pageFooter.asp" -->

</body>
</html>