<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/createDisconnectedRecordset.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/customerTitle.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(43)



customerID = request.querystring("id")
dbug("start of customerProfit; customerID: " & customerID)

title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)

limit = systemControls("Profitability Retrieval Limit")
%>
<html>

<head>

	<% dbug("prior to global head; customerID: " & customerID) %>
	
	<!-- #include file="../includes/globalHead.asp" -->

	<!-- 	jQuery -->
	<script type="text/javascript" src="../jQuery/jquery-3.5.1.js"></script>


	<!-- Square card -->
	<style>
		.demo-card-square.mdl-card {
		  width: 320px;
		  height: 320px;
		}
		.demo-card-square > .mdl-card__title {
		  color: #fff;
		  background: rgba(63, 127, 181, 1);
		}

		.material-icons.md-48 { 
			font-size: 48px; 
			vertical-align: middle;
		}



		.csuiteSideNav {
			margin: 10px 5px 10px 5px;;			
		}

		.csuiteSideNav.is-active a {
			color: rgb(255,110,64);
			font-weight: bold;
		}		
		
		.csuiteSideNav i, .csuiteSideNav a {
			color: black;
		}		
		
		.csuiteSideNav a {
			text-decoration: none;
		}
		
		.csuiteSideNav span {
			display: inline-block; 
			vertical-align: middle;
		}


	</style>

</head>

<body>

<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>

<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
		
		<% dbug("prior to mdlLayoutNavLarge; customerID: " & customerID) %>
		<!-- #include file="../includes/mdlLayoutNavLarge.asp" -->

    </div>
    
    
	<% dbug("prior to customerTabs; customerID: " & customerID) %>
	<!-- #include file="../includes/customerTabs.asp" -->


  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>


<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
   
   	<div class="mdl-grid mdl-grid--no-spacing">

			<div class="mdl-cell--1-col mdl-shadow--4dp" style="display: flex; flex-direction: column;">

				<div class="csuiteSideNav">
					<a href="branchSummary.asp?customerID=<% =customerID %>" class="mld_components__link mdl_component branches">
						<i class="material-icons md-48">account_balance</i>
						<span>Branches</span>
					</a>
				</div>

				<div class="csuiteSideNav">
					<a href="officerSummary.asp?customerID=<% =customerID %>" class="mld_components__link mdl_component officers">
						<i class="material-icons md-48">work</i>
						<span>Officers</span>
					</a>
				</div>

<!--
				<div class="csuiteSideNav">
					<a href="#badges-section" class="mld_components__link mdl_component accounts">
						<i class="material-icons md-48">account_balance_wallet</i>
						<span>Accounts</span>
					</a>
				</div>
-->

				<div class="csuiteSideNav">
					<a href="productOverview.asp?customerID=<% =customerID %>" class="mld_components__link mdl_component products">
						<i class="material-icons md-48">widgets</i>
						<span>Products</span>
					</a>
				</div>

				<div class="csuiteSideNav">
					<a href="accountHolderOverview.asp?customerID=<% =customerID %>" class="mld_components__link mdl_component account_holders">
						<i class="material-icons md-48">people</i>
						<span>Account<br>Holders</span>
					</a>
				</div>

				<div class="csuiteSideNav">
					<a href="prospectsOverview.asp?id=<% =customerID %>" class="mld_components__link mdl_component prospects">
						<i class="material-icons md-48">group_add</i>
						<span>Prospects</span>
					</a>
				</div>

				<% if userPermitted(121) then %>
				<div class="csuiteSideNav">
					<a href="cProfitSettings.asp?customerID=<% =customerID %>" class="mld_components__link mdl_component settings">
						<i class="material-icons md-48">settings</i>
						<span>Settings</span>
					</a>
				</div>
				<% end if %>


<!--
				<hr>

				<div class="csuiteSideNav">
					<a href="categorySummary.asp?id=<% =customerID %>" class="mld_components__link mdl_component account_holders">
						<i class="material-icons md-48">build</i>
						<span>Alt. 1<br>Officer</span>
					</a>
				</div>

				<div class="csuiteSideNav">
					<a href="officerManagement.asp?id=<% =customerID %>" class="mld_components__link mdl_component account_holders">
						<i class="material-icons md-48">build</i>
						<span>Alt. 2<br>Officer</span>
					</a>
				</div>
-->

			</div>
			
			<div class="mdl-cell--11-col">

		   	<div class="mdl-grid">
		
					<div class="mdl-layout-spacer"></div>
		
					<div class="mdl-cell mdl-cell--12-col">

						<img src="images/profitabilityBackground.png">
					
					</div>
		
					<div class="mdl-layout-spacer"></div>
		
				</div> <!-- end grid -->

			</div>	   	

   	</div>

  	</div> <!-- end page-content -->
  	
	<script>
		
		var csuiteSideNavs = document.querySelectorAll('div.csuiteSideNav');
		if (csuiteSideNavs) {
			for (i = 0; i < csuiteSideNavs.length; ++i) {

				csuiteSideNavs[i].addEventListener('mouseover', function() {
					this.classList.add('is-active');
				});
				
				csuiteSideNavs[i].addEventListener('mouseout', function() {
					this.classList.remove('is-active');
				});
				
			}
		}
		
	</script>	
	   
</main>
<!-- #include file="../includes/pageFooter.asp" -->


</body>
</html>