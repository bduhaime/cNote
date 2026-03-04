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
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(42)

server.scriptTimeout = 300

if lCase(session("dbName")) = "csuite" then 
	server.transfer "csuiteSysopDashboard.asp"
end if
	
title = session("clientID") & " - Sysop Dashboard" 
userLog(title)

%>

<html>

<head>

	<!-- 	before include file="includes/globalHead.asp -->
	<!-- #include file="includes/globalHead.asp" -->
	<!-- 	after include file="includes/globalHead.asp -->

	<!-- 	Dayjs -->
	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>

	<!-- 	Google Visualizations -->
	<script src="https://www.gstatic.com/charts/loader.js"></script>


	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>
	<script src="https://unpkg.com/dayjs@1.8.21/plugin/relativeTime.js"></script>
	<script src="https://unpkg.com/dayjs@1.8.21/plugin/quarterOfYear.js"></script>
	<script src="https://unpkg.com/dayjs@1.8.21/plugin/toObject.js"></script>
	<script src="https://unpkg.com/dayjs@1.8.21/plugin/customParseFormat.js"></script>
	<script>
		dayjs.extend(window.dayjs_plugin_relativeTime);
		dayjs.extend(window.dayjs_plugin_quarterOfYear);
		dayjs.extend(window.dayjs_plugin_toObject);
		dayjs.extend(window.dayjs_plugin_customParseFormat);
	</script>

	<script type="text/javascript" src="script/sysopDashboard.js"></script>


	<style>
		/* correct flicker of tooltips in Google Charts */
		svg > g > g:last-child {pointer-events: none}

		.ui-checkboxradio-label {
			width: 300px;
			text-align: left;
		}
		
		label, .label {
			font-weight: bold;
		}
		
		div.user {
			margin-bottom: 3px;
		}
		


		table.filters td {
			padding-bottom: 15px;
		}


		
		
	</style>
	
</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	
	<div class="mdl-grid"><!-- new row of grids... -->

		<div class="bjd mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="padding: 20px; display: flex; flex-direction: column;">

			<table class="filters">

				<tr>
					<td colspan="2">
						<label for="dateRange">Date Range:</label>
						<select name="dateRange" id="dateRange">
							<option value="today">Today</option>
							<option value="this week">This Week</option>
							<option value="this month">This Month</option>
							<option value="this quarter">This Quarter</option>
							<option value="this year">This Year</option>
							<option value="last seven days" selected>Last Seven Days</option>
							<option value="last thirty days">Last Thirty Days</option>
							<option value="last ninety days">Last Ninety Days</option>
							<option value="custom" disabled>Custom</option>
						</select>
					</td>
				</tr>
				<tr>
					<td><label for="startDate">Start:</label><br><input type="text" id="startDate" /></td>
					<td><label for="endDate">End:</label><br><input type="text" id="endDate" /></td>
				</tr>
				<tr>
					<td colspan="2">
						<div class="label">Users</div>
						<div id="userSelectionList_progressbar" class="progressbar"></div>
						<div id="userSelectionList" class="widget"></div>
					</td>
				</tr>
			</table>


			<div class="mdl-shadow--2dp" style="margin-top: auto;">
				<div id="sessions_progressbar" class="progressbar"></div>
				<div id="sessions" class="widget">session</div>
			</div>

		</div>

		<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp">

			<div class="mdl-grid">	
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="timeOfDay_progressbar" class="progressbar"></div>
					<div id="timeOfDay" class="widget"></div>
				</div>
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="dayOfWeek_progressbar" class="progressbar"></div>
					<div id="dayOfWeek" class="widget"></div>
				</div>
			</div>

			<div class="mdl-grid">	
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="date_progressbar" class="progressbar"></div>
					<div id="date" class="widget"></div>
				</div>
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="user_progressbar" class="progressbar"></div>
					<div id="user" class="widget"></div>
				</div>
			</div>


<!--
		<% if userPermitted( 137 )  then %>
			<div style="position: absolute; top: 0; right: 0; margin-top: 20px; margin-right: 20px;" class="material-icons pageHits">view_list</div>
		<% end if %>
-->

			<div class="mdl-grid">	
<!-- 				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" style="position: relative; z-index: 0;"> -->
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
					<span class="interstitials" style="margin-left: 5px; z-index: 100; position: relative; display: none;">

						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="interstitials">
							<input type="checkbox" id="interstitials" class="mdl-switch__input" >
							<span class="mdl-switch__label">Include Interstitials</span>
						</label>

					</span>
					<div id="pageHits_progressbar" class="progressbar"></div>
					<div id="pageHits" class="widget"></div>
				</div>
					
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
					<div id="nodeEndPointHits_progressbar" class="progressbar"></div>
					<div id="nodeEndPointHits" class="widget"></div>
				</div>
		
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
					<div id="aspEndPointHits_progressbar" class="progressbar"></div>
					<div id="aspEndPointHits" class="widget"></div>
				</div>
		
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
					<div id="aspVsNodeHits_progressbar" class="progressbar"></div>
					<div id="aspVsNodeHits" class="widget"></div>
				</div>
		
			</div>
			
		</div>


	</div>

	<div class="mdl-grid"><!-- new row of grids... -->

		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
			<div id="exec_progressbar" class="progressbar"></div>
			<div id="exec" class="widget"></div>
		</div>
		
		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
			<div id="customers_progressbar" class="progressbar"></div>
			<div id="customers" class="widget"></div>
		</div>
		
		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
			<div id="calls_progressbar" class="progressbar"></div>
			<div id="calls" class="widget"></div>
		</div>
		
		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
			<div id="coaches_progressbar" class="progressbar"></div>
			<div id="coaches" class="widget"></div>
		</div>
			
	</div>



	<div class="mdl-grid"><!-- new row of grids... -->
					
		<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">

			<div class="mdl-grid"><!-- new row of grids... -->
				<div class="mdl-layout-spacer"></div>
				<!-- cell for "customers with multiple valid domains -->
				<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp">
					<div style="font-size: 12; font-weight: bold; margin-left: 35px; margin-top: 10px; margin-bottom: 10px;">Customers with multiple valid domains</div>
					<table id="customersMultipleValidDomains" class="compact display">
						<thead>
							<tr>
								<th class="name">Name</th>
								<th class="validDomains">Domains</th>
							</tr>
						</thead>
					</table>
					<br>
				</div>



				<!-- cell for "Domains Recently Updated" -->
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp" style="min-width: 0">
					<div style="font-size: 12; font-weight: bold; margin-left: 35px; margin-top: 10px; margin-bottom: 10px;">Customer Domains Updated in Last 30 Days</div>

					<table id="customersRecentlyUpdatedDomains" class="compact display">
					  <thead>
					    <tr>
					      <th>Name</th>
					      <th>Updated</th>
					      <th>Updated By</th>
					      <th>Valid Domains</th>
					    </tr>
					  </thead>
					  <tbody></tbody>
					</table>


				</div>
				<div class="mdl-layout-spacer"></div>
			</div>



		</div>
	</div>


	        
</main>
<!-- #include file="includes/pageFooter.asp" -->


</body>
</html>