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
call checkPageAccess(97)
	
title = session("clientID") & " - " & "Home" 
userLog(title)
%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	
	<script>


		//======================================================================================
		// get badge count for executive dashboard selector
		//======================================================================================
		$.ajax({
			url: `${apiServer}/api/exec/getExecBadgeCount`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {

			if ( data.badgeCount > 0 ) {
				
				let badge = $( '<span>' )
					.addClass( 'mdl-badge mdl-badge--overlap' )
					.attr( 'id', 'badgeCount' )
					.attr( 'data-badge', data.badgeCount );
					
				$( '.execBadge' ).append( badge );
				
			} else {
				
				$( '#execBadge' ).remove();
				
			}

		}).fail(  function( err ) {
			
			console.error( 'error while getting exec bade count!' );
			
		}); 
		//======================================================================================
		
		


	</script>
	
	<style>

		.demo-card-square.mdl-card {
		  width: 320px;
		  height: 320px;
		}

		.demo-card-square > .mdl-card__title {
		  color: #fff;
		  background: rgb(70, 182, 172);
		}
		
		.bigIcon {
			font-size: 96px; 
			color: black;
		}

		.mdl-badge[data-badge]:after {
			color: white;
			background-color: crimson;
		}
		
		.center {
			margin-left: auto;
			margin-right: auto;
		}
		
	</style>		
	
</head>

<body>


<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">

		<div class="page-content">
		<!-- Your content goes here -->

			<!-- 	ROW ONE  -->
		   <div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
			    
				<!-- 	CUSTOMERS  -->
			    <% if userPermitted(5) then %>
			    <div class="mdl-cell mdl-cell--3-col">

					<div class="demo-card-square mdl-card mdl-shadow--2dp center">
						<div class="mdl-card__title mdl-card--expand">
		<!-- 					<i class="material-icons bigIcon">list_alt</i> -->
							<span class="material-symbols-outlined bigIcon">account_balance</span>
		
							<h2 class="mdl-card__title-text">Customers</h2>
						</div>
						<div class="mdl-card__supporting-text">
							View/edit customer information, including project and task status.
						</div>
						<div class="mdl-card__actions mdl-card--border">
							<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="customerList.asp">
							View Customers
							</a>
						</div>
					</div>

			    </div>
			    <% end if %>
		
		
				<!-- 	EXECUTIVE DASHBOARD  -->
				<% if userPermitted(36) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		
								<span class="material-symbols-outlined bigIcon">supervisor_account</span>						
								
								<h2 class="mdl-card__title-text">Executive Dashboard</h2>
							</div>
							<div class="mdl-card__supporting-text">
								View executive-level metric performance.
							</div>
							<div class="mdl-card__actions mdl-card--border execBadge">
								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="executiveDashboard.asp" >
									View Executive Dashboard
								</a>
								<!-- 	badge count goes here programmatically -->
							</div>
						</div>
					</div>
				<% end if %>
		
				<!-- 	CUSTOMER CALL METRICS  -->
				<% if userPermitted(115) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		<!-- 						<i class="material-icons bigIcon">phone</i> -->
								<span class="material-symbols-outlined bigIcon">call</span>
		
								<h2 class="mdl-card__title-text">Customer Calls Metrics</h2>
							</div>
							<div class="mdl-card__supporting-text">
								View metrics based upon customer calls.
							</div>
							<div class="mdl-card__actions mdl-card--border">
								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="customerCallsDashboard.asp">
									View Customer Calls Metrics
								</a>
							</div>
						</div>
					</div>
				<% end if %>
		
		
				<!-- 	EVENTS & CERTIFICATES  -->
				<% if userPermitted( 146 ) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		<!-- 						<i class="material-icons bigIcon">phone</i> -->
								<span class="material-symbols-outlined bigIcon">event</span>
		
								<h2 class="mdl-card__title-text">Events</h2>
							</div>
							<div class="mdl-card__supporting-text">
								Manage Events
							</div>
							<div class="mdl-card__actions mdl-card--border">
<!-- 								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="events.asp"> -->
								
								<a href="https://react.bill.local/events" target="_blank" rel="noopener noreferrer">Events (React)</a>
								
									
									Manage Events
								</a>
							</div>
						</div>
					</div>
				<% end if %>
		
		
			    
				<div class="mdl-layout-spacer"></div>
			    
		
			</div><!-- END ROW ONE -->
		    
		    
		    
			<!-- 	ROW TWO  -->
		   <div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<!-- 	SYSOP DASHBOARD  -->
				<% if userPermitted(42) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		<!-- 						<i class="material-icons bigIcon" style="color: crimson;">admin_panel_settings</i> -->
								<span class="material-symbols-outlined bigIcon" style="color: crimson;">admin_panel_settings</span>
		
								<h2 class="mdl-card__title-text">SysOp Dashboard</h2>
							</div>
							<div class="mdl-card__supporting-text">
								View system-level metrics.
							</div>
							<div class="mdl-card__actions mdl-card--border">
								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="sysopDashboard.asp">
									View SysOp Dashboard
								</a>
							</div>
						</div>
					</div>
				<% end if %>
		
				<!-- 	CUSTOMER METRICS  -->
				<% if userPermitted(118) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		<!-- 						<i class="material-icons bigIcon">business</i> -->
								<span class="material-symbols-outlined bigIcon">domain</span>						
								
								<h2 class="mdl-card__title-text">Customer Metrics</h2>
							</div>
							<div class="mdl-card__supporting-text">
								View customer-level metrics.
							</div>
							<div class="mdl-card__actions mdl-card--border">
								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="customerMetricsDashboard.asp">
									View Customer Metrics
								</a>
							</div>
						</div>
					</div>
				<% end if %>
		
				<!-- 	COACH METRICS  -->
				<% if userPermitted(128) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		<!-- 						<i class="material-icons bigIcon">sports</i> -->
								<span class="material-symbols-outlined bigIcon">sports</span>
		
								<h2 class="mdl-card__title-text">Coach Metrics</h2>
							</div>
							<div class="mdl-card__supporting-text">
								View coach-level metrics.
							</div>
							<div class="mdl-card__actions mdl-card--border">
								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="coachMetricsDashboard.asp">
									View Coach Metrics
								</a>
							</div>
						</div>
					</div>
				<% end if %>

				<!-- 	Marketing  -->
				<% if userPermitted( 144 ) then %>
					<div class="mdl-cell mdl-cell--3-col">
						<div class="demo-card-square mdl-card mdl-shadow--2dp center">
							<div class="mdl-card__title mdl-card--expand">
		<!-- 						<i class="material-icons bigIcon" style="color: crimson;">admin_panel_settings</i> -->
								<span class="material-symbols-outlined bigIcon" style="color: crimson;">biotech</span>
		
								<h2 class="mdl-card__title-text">Marketing Research</h2>
							</div>
							<div class="mdl-card__supporting-text">
								View FDIC Institutions for "Top 100" analysis.
							</div>
							<div class="mdl-card__actions mdl-card--border">
								<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="marketingResearch.asp">
									Marketing Research
								</a>
							</div>
						</div>
					</div>
				<% end if %>
		
		
				<div class="mdl-layout-spacer"></div>
			    
		
			</div><!-- END ROW TWO -->
		    

		</div><!-- end page content -->

	</main>
  <!-- #include file="includes/pageFooter.asp" -->


</body>


<%
dataconn.close 
set dataconn = nothing 
%>

</html>