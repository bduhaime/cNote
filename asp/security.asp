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
call checkPageAccess(3)

userLog("Security")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Security" 
%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div class="page-content">
    <!-- Your content goes here -->


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
			
   	<div class="mdl-grid">

		<div class="mdl-layout-spacer"></div>
		
		<% if userPermitted(9) then %>
	    <div class="mdl-cell mdl-cell--3-col">
			<div class="demo-card-square mdl-card mdl-shadow--2dp">
			  <div class="mdl-card__title mdl-card--expand">
				<img src="images/ic_person_black_48dp_2x.png">
				<h2 class="mdl-card__title-text">Users</h2>
			  </div>
			  <div class="mdl-card__supporting-text">
			    Determine who has access to what.
			  </div>
			  <div class="mdl-card__actions mdl-card--border">
			    <a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="userList.asp">
			      View Users
			    </a>
			  </div>
			</div>
	    </div>
	    <% end if %>
		
<!-- 		<div class="mdl-layout-spacer"></div> -->
		
		<% if userPermitted(10) then %>
	    <div class="mdl-cell mdl-cell--3-col">
			<div class="demo-card-square mdl-card mdl-shadow--2dp">
			  <div class="mdl-card__title mdl-card--expand">
				<img src="images/ic_group_black_48dp_2x.png">
			    <h2 class="mdl-card__title-text">Roles</h2>
			  </div>
			  <div class="mdl-card__supporting-text">
			    Group users and permissions together for easier maintenance.
			  </div>
			  <div class="mdl-card__actions mdl-card--border">
			    <a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="roleList.asp">
			      View Roles
			    </a>
			  </div>
			</div>	
	    </div>
	    <% end if %>
	    
<!-- 		<div class="mdl-layout-spacer"></div> -->
		
		<% if userPermitted(11) then %>
			<div class="mdl-cell mdl-cell--3-col">
				<div class="demo-card-square mdl-card mdl-shadow--2dp">
					<div class="mdl-card__title mdl-card--expand">
						<img src="images/ic_assignment_turned_in_black_48dp_2x.png">
						<h2 class="mdl-card__title-text">Permissions</h2>
					</div>
					<div class="mdl-card__supporting-text">
						This is the master list of permissions.
					</div>
					<div class="mdl-card__actions mdl-card--border">
						<a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect" href="permissionList.asp">
							View Permissions
						</a>
					</div>
				</div>
			</div>
		<% end if %>
	    
		<div class="mdl-layout-spacer"></div>


	</div>
    
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col"><img src="images/securityEntities.png"></div>
			<div class="mdl-layout-spacer"></div>
			
		</div>



  </main>
	<!-- #include file="includes/pageFooter.asp" -->
</div>


</body>
</html>