 <!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2026, Polaris Consulting, LLC. All Rights Reserved. -->
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
call checkPageAccess(2)
	
title = session("clientID") & " - " & "Administration" 
userLog(title)
%>
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
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
   
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--2-col"></div>

			<div class="mdl-cell mdl-cell--4-col">
			 
				
			<!-- Icon List -->
			
			<ul class="demo-list-icon mdl-list" style="width: 100%;">


				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(26) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">date_range</i>
							<a href="calendar.asp">Calendar</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
				
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(30) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">phone</i>
							<a href="callTypes.asp">Call Types</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
				
				<% if userPermitted(27) then %>
				<li class="mdl-list__item">
					<span class="mdl-list__item-primary-content">
						<i class="material-symbols-outlined mdl-list__item-icon">palette</i>
						<a href="colorPalette.asp">Color Palette</a>
					</span>
				</li>
				<% end if %>
				
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(132) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">widgets</i>
						<a href="customerContractProducts.asp">Customer Contract Products</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
	
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(132) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">contract</i>
						<a href="customerContracts.asp">Customer Contracts (all)</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
	
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(113) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">people</i>
							<a href="customerManagerTypeList	.asp">Customer Manager Types</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
				
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(4) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">star</i>
							<a href="customerStatusList.asp">Customer Statuses</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
				
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(6) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">event</i>
						<a href="eventList.asp">Events</a>
						</span>
					</li>
					<% end if %>
				<% end if %>


			

				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(145) then %>
						<li class="mdl-list__item">
							<span class="mdl-list__item-primary-content">
								<i class="material-symbols-outlined mdl-list__item-icon">fact_check</i>
							<a href="jobStatus.asp">Job Status</a>
							</span>
						</li>
					<% end if %>
				<% end if %>


				<li class="mdl-list__item">
					<span class="mdl-list__item-primary-content" style="align-items: flex-start;">
						<i class="material-symbols-outlined mdl-list__item-icon">sync_alt</i>
						<div>
							Mappings to External Data Sources:
							<ul>
				
								<% if lCase(session("dbName")) <> "csuite" then %>
									<li><a href="alchemerSurveyCustomerMapping.asp">Culture Survey ( Alchemer )</a></li>
								<% end if %>
				
								<% if userPermitted( 140 ) then %>
									<li>Mystery Shopping ( SecretShopper / ValidatedData ):
										<ul>
											<li><a href="mysteryShoppingLocations.asp">Locations</a></li>
											<li><a href="mysteryShoppingQuestionCategories.asp">Question Categories</a></li>
											<li><a href="mysteryShoppingQuestions.asp">Questions</a></li>
										</ul>
									</li>
								<% end if %>
								
								<% if lCase(session("dbName")) <> "csuite" then %>
									<% if systemControls( "Use LSVT manual location/customer mapping" ) = "true" then %>
										<li><a href="lsvtManualLocationCustomerMapping.asp">TGIM-U ( LIGHTSPEED VT )</a></li>
									<% end if %>
								<% end if %>
					
							</ul>
						</div>
					</span>
				</li>


			</ul>		    			    			
			</div>

			<div style="width: 15px;"><!-- this <div> simply separates the two <ul>'s --></div>

			
			<div class="mdl-cell mdl-cell--4-col">
			<!-- Icon List -->
			<ul class="demo-list-icon mdl-list" style="width: 100%;">	
				
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(7) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">show_chart</i>
						<a href="metricList.asp">Metrics</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
	







	
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(8) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
						<i class="material-symbols-outlined mdl-list__item-icon">account_tree</i>
						<a href="productList.asp">Processes</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
				
				<% if lCase(session("dbName")) <> "csuite" then %>
					<% if userPermitted(40) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
						<i class="material-symbols-outlined mdl-list__item-icon">view_timeline</i>
						<a href="projectTemplateList.asp">Project Templates</a>
						</span>
					</li>
					<% end if %>
				<% end if %>
				
				<% if userPermitted(3) then %>

					<li class="mdl-list__item">
					  <span class="mdl-list__item-primary-content" style="align-items: flex-start;">
					    <i class="material-symbols-outlined mdl-list__item-icon">security</i>
					    <div>
					      <a href="security.asp">Security:</a>
					      <ul>
					        <% if userPermitted(9) then %>
					          <li><a href="userList.asp">Users</a></li>
					        <% end if %>
					
					        <% if userPermitted(10) then %>
					          <li><a href="roleList.asp">Roles</a></li>
					        <% end if %>
					
					        <% if userPermitted(11) then %>
					          <li><a href="permissionList.asp">Permissions</a></li>
					        <% end if %>
					      </ul>
					    </div>
					  </span>
					</li>

				<% end if %>
				
				<% if userPermitted(17) then %>
				<li class="mdl-list__item">
					<span class="mdl-list__item-primary-content">
					<i class="material-symbols-outlined mdl-list__item-icon">info</i>
					<a href="systemInfo.asp">System Info</a>
					</span>
				</li>
				<% end if %>

				<% if lCase(session("dbName")) = "csuite" then %>				
					<% if userPermitted(32) then %>
					<li class="mdl-list__item">
						<span class="mdl-list__item-primary-content">
							<i class="material-symbols-outlined mdl-list__item-icon">help</i>
							<a href="support.asp">Support</a>
						</span>
					</li>
					<% end if %>
				<% end if %>			

				
				
				<% if userPermitted(33) then %>
				<li class="mdl-list__item">
					<span class="mdl-list__item-primary-content">
						<i class="material-symbols-outlined mdl-list__item-icon">view_compact</i>
						<a href="mdlGridLayout.html">MDL Grid</a>
					</span>
				</li>
				<% end if %>
			
			
			</ul>		    			    
			</div>
			<div class="mdl-layout-spacer"></div>

		</div> <!-- end grid -->

  	</div> <!-- end page-content -->
	   
</main>
<!-- #include file="includes/pageFooter.asp" -->


</body>
</html>