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
<!-- #include file="includes/checkPageAccess.asp" -->

<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(118)

title = session("clientID") & " - Coach Metrics Dashboard" 
userLog(title)

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	Dayjs -->
	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>

	<!-- 	Google Visualizations -->
	<script src="https://www.gstatic.com/charts/loader.js"></script>


	<script>

		google.charts.load( 'current', { packages: [ 'corechart', 'line', 'calendar', 'timeline' ] } );


		//====================================================================================
		google.charts.setOnLoadCallback( function() {
		//====================================================================================


			$( function() {
	
				$( document ).tooltip();
				$( 'input.customerStatus' ).checkboxradio();
				
				$( 'input.customerStatus' ).on( 'click', function() {
					$( '#coachSummary' ).DataTable().ajax.reload();
				});
				
				
				var coachSummary = $( '#coachSummary' ).DataTable({
					footerCallback: function( tfoot, data, start, end, display ) {
						var api = this.api();
						
						api.columns( '.sum' ).every( function() {
							
							let sum = this.data().reduce( function ( a, b ) {
								return a + b;
							}, 0 );
							
							
							let avg = Math.round( sum / this.data().count() );
							
							$( this.footer() ).html( sum + '<br>' + avg );
						});
						
					},
					ajax: { 
						url: `${apiServer}/api/coachMetrics/summary`,
						data: { statusList: function() {
								let array = []
								$( 'input.customerStatus' ).each( function() {
									if ( $( this ).is( ':checked' ) ) {
										elemID = $(this).attr('id');
										statusID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
										array.push( statusID );
									}
								});
								return JSON.stringify( array );
							}
						},
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
					},
					processing: true,
					rowId: 'id',
// 					scrollX: true,
					scrollY: '450px',
					scrollCollapse: true,
					paging: false,
					columnDefs: [
						{ targets: 'primaryCoach', data: 'primaryCoach', className: 'primaryCoach dt-body-left' },
						{ targets: 'customerCount', data: 'customerCount', className: 'customerCount sum avg dt-body-center' },
						{ targets: 'callCount', data: 'callCount', className: 'callCount sum avg dt-body-center' },
						{ targets: 'missedCalls', data: 'missedCalls', className: 'missedCalls sum avg dt-body-center' },
						{ targets: 'daysBehind', data: 'daysBehind', className: 'daysBehind dt-body-center' },
						{ targets: 'daysAtRisk', data: 'daysAtRisk', className: 'daysAtRisk dt-body-center' },
						{ targets: 'activeIntentionsCount', data: 'activeIntentionsCount', className: 'activeIntentionsCount sum avg dt-body-center' },
						{ targets: 'openKICount', data: 'openKICount', className: 'openKICount sum avg dt-body-center' },
						{ targets: 'pastDueKICount', data: 'pastDueKICount', className: 'pastDueKICount sum avg dt-body-center' },
						{ targets: 'nahproKICount', data: 'nahproKICount', className: 'nahproKICount sum avg dt-body-center' },
						{ targets: 'openProjectCount', data: 'openProjectCount', className: 'openProjectCount sum avg dt-body-center' },
						{ targets: 'atRiskProjectCount', data: 'atRiskProjectCount', className: 'atRiskProjectCount sum avg dt-body-center' },
						{ targets: 'pastDueProjectCount', data: 'pastDueProjectCount', className: 'pastDueProjectCount sum avg dt-body-center' },
						{ targets: 'nahproProjectCount', data: 'nahproProjectCount', className: 'nahproProjectCount sum avg dt-body-center' },
						{ targets: 'openTaskCount', data: 'openTaskCount', className: 'openTaskCount sum avg dt-body-center' },
						{ targets: 'pastDueTaskCount', data: 'pastDueTaskCount', className: 'pastDueTaskCount sum avg dt-body-center' },
						{ targets: 'orphanTaskCount', data: 'orphanTaskCount', className: 'orphanTaskCount sum avg dt-body-center' },
					],

					
				});		
				

				$( '#coachSummary' ).on( 'click', 'td.missedCalls', function() {
					coachID = $(this).closest('tr').attr('id');
					$( '#customerDrillDown' ).Datatable({
						ajax: {
							url: `${apiServer}/api/coachMetrics/missedCallsByCustomer`,
							data: { coachID: coachID },
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: '',
						},
						columns: [
							{ title: 'Customer' },
							{ title: 'Missed Calls' }
						]
					});
				});
				
										
		
			});

		});
		
	</script>


	<style>
		
		.ui-checkboxradio-label {
			width: 200px;
			text-align: left;
		}

		th.selectionHeader {
			text-align: left;
			padding-left: 60px;
		}

	</style>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	
	<div class="mdl-grid"><!-- start of primary mdl-grid
		<!-- new row of grids... -->
	
		<div class="mdl-layout-spacer"></div>
		<div class="mdl-cell mdl-cell--2-col mdl-shadow--2dp">

			<table id="customerStatusList">
				<thead>
					<th class="selectionHeader">Customer Statuses</th>
				</thead>
				<tbody>
				<%
				SQL = "select s.id, s.name, s.selectByDefault, count(*) as custCount " &_
						"from customerStatus s " &_
						"join customer c on (c.customerStatusID = s.id) " &_
						"where (c.deleted = 0 or c.deleted is null) " &_
						"group by s.id, s.name, s.selectByDefault " &_
						"order by s.name  "
				set rsCS = dataconn.execute(SQL) 
				while not rsCS.eof
					label = rsCS("name") & " (" & rsCS("custCount") & ")"
					if rsCS("selectByDefault") then 
						checked = "checked"
					else 
						checked = ""
					end if 
					%>
					<tr>
						<td>
							<label for="cs-<% =rsCS("id") %>"><% =label %></label>
							<input class="customerStatus" type="checkbox" id="cs-<% =rsCS("id") %>" <% =checked %>>
						</td>
					</tr>
					<%
					rsCS.movenext 
				wend 
				rsCS.close 
				set rsCS = nothing 
				%>
				</tbody>
			</table>
			
		</div>
		
		<div class="mdl-cell mdl-cell--10-col mdl-shadow--2dp">

			<table id="coachSummary" class="compact display nowrap">
				<thead>
					<tr>
						<th class="primaryCoach" title="Primary coach name">Primary Coach</th>
						<th class="customerCount" title="Count of customers assiged to primary coach">Customers</th>
						<th class="missedCalls" title="Count of calls scheduled in the past but never completed">Missed<br>Calls</th>
						<th class="daysBehind" title="Total work days behind">Days<br>Behind</th>
						<th class="daysAtRisk" title="Total workd days at risk">Days At<br>Risk</th>
						<th class="activeIntentionsCount" title="Count of active intentions (based on start date and end date)">Active<br>Intents</th>
						<th class="openKICount" title="Count KIs that are not complete">Open<br>KIs</th>
						<th class="pastDueKICount" title="Count of open KIs where the end date has transpired">Past Due<br>KIs</th>
						<th class="nahproKICount" title="Count of open KIs with no project(s) and no task(s)"><i>Nahpro</i><br>KIs</th>
						<th class="openProjectCount" title="Count of projects that have a status other than 'Complete'">Open Proj.</th>
						<th class="atRiskProjectCount" title="Count of projects that have a status of 'Escalate' or 'Reschedule'">At Risk<br>Projects</th>
						<th class="pastDueProjectCount" title="Count of projects that are not complete and the end date has transpired">Past Due<br>Projects</th>
						<th class="nahproProjectCount" title="Count of open projects with no task(s)"><i>Nahpro</i><br>Projects</th>
						<th class="openTaskCount" title="Count of tasks that are not complete">Open<br>Tasks</th>
						<th class="pastDueTaskCount" title="Count of tasks that are not complete and the due date has transpired">Past Due<br>Tasks</th>
						<th class="orphanTaskCount" title="Count of tasks that are not complete and not associated with a KI or project">Orphan<br>Tasks</th>
					</tr>
				</thead>
				<tfoot>
					<tr>
						<th style="text-align: right;">Totals:<br>Averages:</th><!-- primaryCoach -->
						<th style="text-align: center;"></th><!-- customers -->
						<th style="text-align: center;"></th><!-- missedCalls -->
						<th style="text-align: center;"></th><!-- daysBehind -->
						<th style="text-align: center;"></th><!-- daysAtRisk -->
						<th style="text-align: center;"></th><!-- activeIntentionsCount -->
						<th style="text-align: center;"></th><!-- openKICount -->
						<th style="text-align: center;"></th><!-- pastDueKICount -->
						<th style="text-align: center;"></th><!-- nahproKICount -->
						<th style="text-align: center;"></th><!-- openProjectCount -->
						<th style="text-align: center;"></th><!-- atRiskProjectCount -->
						<th style="text-align: center;"></th><!-- pastDueProjectcount -->
						<th style="text-align: center;"></th><!-- nahproProjectcount -->
						<th style="text-align: center;"></th><!-- openTaskCount -->
						<th style="text-align: center;"></th><!-- pastDueTaskCount -->
						<th style="text-align: center;"></th><!-- orphanTaskCount -->
					</tr>
				</tfoot>
			</table>
				
		</div>
		<div class="mdl-layout-spacer"></div>
		
	</div>


	<!-- new row of grids... -->
	<div class="mdl-grid">
	
		<div class="mdl-layout-spacer"></div>
		<div class="mdl-cell mdl-cell--11-col mdl-shadow--2dp">

			<table id="customerDrillDown" class="display compact"></table>

		</div>
		<div class="mdl-layout-spacer"></div>

	</div>
	
</main>
<!-- #include file="includes/pageFooter.asp" -->



</body>

</html>