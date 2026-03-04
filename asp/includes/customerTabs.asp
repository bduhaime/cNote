<%	
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

SQL = "select cProfitURI, cProfitApiKey, secretShopperLocationName from customer where id = " & customerID & " " 
dbug("cProfit SQL: " & SQL)
set rsURI = dataconn.execute(SQL) 
if not rsURI.eof then 
	cProfitURL 						= rsURI("cProfitURI")	
	cProfitApiKey 					= rsURI("cProfitApiKey")
	secretShopperLocationName 	= rsURI("secretShopperLocationName")
else 
	cProfitURL 						= ""
	cProfitApiKey 					= ""
	secretShopperLocationName 	= ""
end if 
rsURI.close 
set rsURI = nothing 

SQL = "select showClassicCustomerMenu from csuite..users where id = " & session( "userID" ) & " " 
set rsUser = dataconn.execute( SQL ) 
if not rsUser.eof then 
	if rsUser( "showClassicCustomerMenu" ) then 
		showClassicCustomerMenu = true 
	else 
		showClassicCustomerMenu = false 
	end if 
else 
	showClassicCustomerMenu = false 
end if 


%>
<script>
	
	const apiUrl = '<% =cProfitURL %>';
	const apiKey = '<% =cProfitApiKey %>';

	$( function() {

		$.ajax({
			url: `${apiUrl}/ping`,
			headers: { 'apikey': apiKey }
		}).then( function( response ) {
			if ( sessionStorage.getItem( 'apiStatus' ) === 'disabled' ) {
				$( '.cProfitIcon' ).html( 'money_off' );
			} else {
				$( '.cProfitIcon' ).html( 'monetization_on' );
			}
		}).fail( function( req, status, err ) {
			$( '.cProfitIcon' ).html( 'money_off' );
		});

	});
		
</script>

<script src="includes/customerTabs.js"></script>

<%

dbug("start of customerTabs.asp; customerID: " & customerID)
dbug("request.serverVariables('SCRIPT_NAME'): " & request.serverVariables("SCRIPT_NAME"))
select case request.serverVariables("SCRIPT_NAME")

	case "/customerCalls.asp"

		callsIsActive = "is-active"

	case 	"/customerImplementations.asp", _
			"/customerImplementationDetail.asp"

		implementationsIsActive = "is-active"
		commitmentsIsActive = "is-active"
		
	case "/customerUtopias.asp" 

		utopiasIsActive = "is-active"

	case 	"/customerKeyInitiatives.asp"

		keyInitiativesIsActive = "is-active"
		commitmentsIsActive = "is-active"

	case 	"/customerProjects.asp"

		projectsIsActive = "is-active"
		commitmentsIsActive = "is-active"

	case 	"/customerAttributes.asp"

		attributesIsActive = "is-active"

	case 	"/customerValues.asp"

		valuesIsActive = "is-active"

	case 	"/customerManagers.asp"

		managersIsActive = "is-active"

	case 	"/customerContacts.asp"

		contactsIsActive = "is-active"

	case 	"/customerTasks.asp"

		tasksIsActive = "is-active"
		commitmentsIsActive = "is-active"

	case "/customerReview.asp"

		reviewIsActive = "is-active"
		
	case "/customerUsers.asp" 
	
		usersIsActive = "is-active"

	case "/customerContracts.asp" 
	
		contractsIsActive = "is-active"

	case "/customerCultureSurveys.asp" 
	
		cultureSurveysIsActive = "is-active"

	case "/customerKPIs.asp" 
	
		kpiIsActive = "is-active"
		
	case "/customerMysteryShopping.asp", _
		  "/customerMysteryShoppingBankers.asp", _
		  "/customerMysteryShoppingBranches.asp", _
		  "/customerMysteryShoppingLocationList.asp", _
		  "/customerMysteryShoppingMsBanksNoCustomer.asp", _
		  "/customerMysteryShoppingShopDetail.asp", _ 
		  "/customerMysteryShoppingShopListByLocation.asp", _
		  "/customerMysteryShoppingShops.asp", _
		  "/customerMysteryShoppingSupervisors.asp" 
	
		msIsActive = "is-active"

	case else ' default = customerOverview.asp

		prefix = mid(request.serverVariables("SCRIPT_NAME"),1,9)
		
		if prefix = "/cProfit/" then 
			profitIsActive = "is-active"
		else 
			overviewIsActive = "is-active"
		end if

end select 



%>
 <style>
	 
	 a.mdl-layout__tab {
		 text-transform: none; 
		 font-size: 18px; 
		 padding: 0px 18px 0px 18px;
	 }
	 
	 .dda {
		 vertical-align: middle;
	 }
	 
	 .cProfitIcon {
		 vertical-align: middle;
	 }
	 
 </style>
	 
 <%' if showClassicCustomerMenu then %>
 <% if true then %>
 	<div class="mdl-layout__tab-bar mdl-js-ripple-effect">
 
   <% if userPermitted(48) then %>
   	<a id="tab_overview" href="/customerOverview.asp?id=<% =customerID %>" class="mdl-layout__tab <% =overviewIsActive %>">Overview </a>
   <% end if %>
   
	<% if cInt(customerID) <> 1 then %>
		<% if userPermitted(49) then %><a id="tab_calls" 				href="/customerCalls.asp?id=<% =customerID %>" 				class="mdl-layout__tab <% =callsIsActive %>">Calls</a><% end if %>
		<% if userPermitted(46) then %><a id="tab_implementations"	href="/customerImplementations.asp?id=<% =customerID %>" 	class="mdl-layout__tab <% =implementationsIsActive %>">Intentions</a><% end if %>
   <% end if %>
   
   <% if userPermitted(50) then %><a id="tab_keyInitiatives"		href="/customerKeyInitiatives.asp?id=<% =customerID %>" 	class="mdl-layout__tab <% =keyInitiativesIsActive %>">Key Initiatives</a><% end if %>

   <% if userPermitted(51) then %><a id="tab_projects" 				href="/customerProjects.asp?id=<% =customerID %>" 			class="mdl-layout__tab <% =projectsIsActive %>">Projects</a><% end if %>

	<% if userPermitted(52) then %><a id="tab_tasks" 					href="/customerTasks.asp?id=<% =customerID %>" 				class="mdl-layout__tab <% =tasksIsActive %>">Tasks</a><% end if %>
   
	<% if customerID <> 1 then %><!-- suppress the "Managers" tab for company = TEG -->
		<% if userPermitted(53) then %><a id="tab_managers" 			href="/customerManagers.asp?id=<% =customerID %>" 			class="mdl-layout__tab <% =managersIsActive %>">Managers</a><% end if %>
   <% end if %>
   
	<% if userPermitted(54) then %><a id="tab_contacts" 				href="/customerContacts.asp?id=<% =customerID %>" 	 		class="mdl-layout__tab <% =contactsIsActive %>">Contacts</a><% end if %>



	<% if userPermitted(43) then %>
		<a id="tab_profit" href="/cProfit/customerProfit.asp?id=<% =customerID %>" class="mdl-layout__tab <% =profitIsActive %>">
			cProfit<i class="material-icons cProfitIcon">attach_money</i>
		</a>
	<% end if %>





	<% if userPermitted(55) then %><a id="tab_review" 					href="/customerReview.asp?id=<% =customerID %>" 	 		class="mdl-layout__tab <% =reviewIsActive %>">Review</a><% end if %>
   
	<% if userPermitted(111) then %><a id="tab_users"	 				href="/customerUsers.asp?id=<% =customerID %>" 	 			class="mdl-layout__tab <% =usersIsActive %>">Users</a><% end if %>
   
	<% if userPermitted(129) then %><a id="tab_contracts"	 			href="/customerContracts.asp?id=<% =customerID %>" 	 	class="mdl-layout__tab <% =contractsIsActive %>">Contracts</a><% end if %>

	<% if userPermitted(131) then %><a id="tab_kpis"	 				href="/customerKPIs.asp?id=<% =customerID %>" 	 			class="mdl-layout__tab <% =kpiIsActive %>">KPIs</a><% end if %>

	<% if userPermitted(139) AND secretShopperLocationName > "" then %>
		<a id="tab_ms" href="/customerMysteryShopping.asp?id=<% =customerID %>" class="mdl-layout__tab <% =msIsActive %>">Mystery Shopping</a>
	<% end if %>

	<% if userPermitted(142) then %>
		<a id="tab_cultureSurvey" href="/customerCultureSurveys.asp?id=<% =customerID %>" class="mdl-layout__tab <% =cultureSurveysIsActive %>">Culture Surveys</a>
	<% end if %>

   
 </div>
 <% else %>
 
	<div class="mdl-layout__tab-bar mdl-js-ripple-effect">
		
		
		<% if userPermitted(48) then %>
			<a id="tab_overview" href="/customerOverview.asp?id=<% =customerID %>" class="mdl-layout__tab <% =overviewIsActive %>" >
				Overview
<!-- 				<span class="icon material-icons">account_balance</span> -->
			</a>
		<% end if %>
		
		
		<% if cInt(customerID) <> 1 then %>
			<% if userPermitted(49) then %>
				<a id="tab_calls" href="/customerCalls.asp?id=<% =customerID %>" class="mdl-layout__tab <% =callsIsActive %>" >
<!-- 					<span class="material-icons" title="Calls">call</span>  -->
					Calls
				</a>
			<% end if %>
		<% end if %>
		
		
		<% if userPermitted(46) OR userPermitted(50) OR userPermitted(51) or userPermitted(52) then %>
		
			<span style="overflow: visible;">
			<a id="tab_commitments" href="#" class="mdl-layout__tab <% =commitmentsIsActive %>" onclick="buildDropdownMenu( event )" >
				Commitments<span class="material-icons dda">arrow_drop_down</span>
			</a>

			<div>
				<ul>
					<li>Intentions...</li>
					<li>Key Initiative...</li>
					<li>Projects...</li>
					<li>Tasks...</li>
				</ul>
			</div>
			
			</span>
			
				



<!--
			<button id="commitmentMenu" class="mdl-button mdl-js-button mdl-button--icon <% =commitmentsIsActive %>">
				<span class="material-icons" title="Commitments">diamond</span>
			</button>

			<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect" for="commitmentMenu">
				<% if userPermitted(46) then %><li class="mdl-menu__item" onclick="location='/customerImplementations.asp'">Intentions...</li><% end if %>
				<% if userPermitted(50) then %><li class="mdl-menu__item" onclick="location='/customerKeyInitiatives.asp'">Key Initiatives...</li><% end if %>
				<% if userPermitted(51) then %><li class="mdl-menu__item" onclick="location='/customerProjects.asp'">Projects...</li><% end if %>
				<% if userPermitted(52) then %><li class="mdl-menu__item" onclick="location='/customerTasks.asp'">Tasks...</li><% end if %>
			</ul>
-->


		<% end if %>
		
		
		<% if userPermitted(139) then %>
			<a id="tab_mysteryShopping" href="/customerMysteryShopping.asp?id=<% =customerID %>" class="mdl-layout__tab <% =mysteryShoppingIsActive %>" title="Mystery Shopping">
<!-- 				<span class="material-icons">shopping_cart</span> -->
				Mystery Shopping
			</a>
		<% end if %>
		
		
		<% if userPermitted(142) then %>
			<a id="tab_cultureSurvey" href="/customerCultureSurveys.asp?id=<% =customerID %>" class="mdl-layout__tab <% =cultureSurveysIsActive %>" title="Culture Survey">
<!-- 				<span class="material-icons">poll</span> -->
				Culture Survey
			</a>
		<% end if %>
		
		
		<% if userPermitted(131) OR userPermitted(129) then %>
			<a id="tab_reference" href="/customerOverview.asp?id=<% =customerID %>" class="mdl-layout__tab <% =referenceIsActive %>" title="Reference (FDIC Performance Stats, Contracts)">
<!-- 				<span class="material-icons">query_stats</span> -->
				Reference<span class="material-icons dda">arrow_drop_down</span>
			</a>
		<% end if %>
		
		
		<% if userPermitted(54) OR userPermitted(53) OR userPermitted(111) then %>
			<a id="tab_team" href="/customerOverview.asp?id=<% =customerID %>" class="mdl-layout__tab <% =teamIsActive %>" title="Team (Customer Contacts, TEG Managers, cNote Access">
<!-- 				<span class="material-icons">groups</span> -->
				Team<span class="material-icons dda">arrow_drop_down</span>
			</a>
		<% end if %>

		
		<% if userPermitted(43) then %>
			<a id="tab_profit" href="/cProfit/customerProfit.asp?id=<% =customerID %>" class="mdl-layout__tab <% =profitIsActive %>" Title="cProfit">
				<span class="material-icons cProfitIcon">attach_money</span>
			</a>
		<% end if %>

	</div>




 <% end if %>
