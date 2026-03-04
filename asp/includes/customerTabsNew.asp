<script>


	
	//================================================================================
	$(document).ready(function() {
	//================================================================================

	  
		$( document ).tooltip();

		//--------------------------------------------------------------------------
		$.ajax({
		//--------------------------------------------------------------------------
			url: `${apiServer}/api/users/profile/CustomerMenuOptions`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
		}).done( response => {
			
			switch ( response.newMenuStyle ) {
			
				case 1:
					$( '.customerTabIcon' ).show();
					$( '.customerTabText' ).hide();
					break;
				case 2:
					$( '.customerTabIcon' ).hide();
					$( '.customerTabText' ).show();
					break;
				default: 	
					$( '.customerTabIcon' ).show();
					$( '.customerTabText' ).show();

			}
			
		}).fail( err => {
			console.log( 'an error occurred while getting customer menu options' );
			$( '.customerTabIcon' ).show();
			$( '.customerTabText' ).show();
		});
		//--------------------------------------------------------------------------


		const mutationObserver = new MutationObserver(function (mutations) {
			mutations.forEach(function (mutation) {

				console.log( 'something about the commitmentsMenu changes' );
// 				if (mutation.type === 'attributes' ) {
// 					console.log( `attribute that changed is ${mutation.attributeName}` );
// 				} else if ( mutation.type === 'style' ) {
// 					console.log( `style changed` );
// 				} else {
// 					console.log( `something else changed of type: ${mutation.type}` );
// 				}
	
			});
	
		});
		
		const animes = $( '#commitmentsMenu' ).parent().get(0);
		mutationObserver.observe(animes, {
			childList: true,
			attributes: true
		});


			
	});
	//================================================================================
	//================================================================================
		
</script>

<style>

	.mdl-layout__tab {
		text-transform: none; 
		font-size: 18px; 
/* 		padding: 0px 18px 0px 18px; */
	}
	
	.material-symbols-outlined {
		vertical-align: text-bottom;
	}

</style>
	 
<ul id="commitmentsMenu" class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect" for="tab_commitments"> 
	<li class="mdl-menu__item" onclick="location='/customerImplementations.asp?id=<% =customerID %>'">Intentions...</li>
	<li class="mdl-menu__item">Key Initiatives...</li>
	<li class="mdl-menu__item">Projects...</li>
	<li class="mdl-menu__item">Tasks...</li>
</ul>


<ul id="referenceMenu" class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect" for="tab_reference">
	<li class="mdl-menu__item">FDIC Performance Stats...</li>
	<li class="mdl-menu__item">Contracts...</li>
</ul>


<ul id="teamMenu" class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect" for="tab_team">
	<li class="mdl-menu__item">Customer Contacts...</li>
	<li class="mdl-menu__item">TEG Managers...</li>
	<li class="mdl-menu__item">cNote Access...</li>
</ul>


<div class="mdl-layout__tab-bar mdl-js-ripple-effect" style="height: 50px;">
	
	<a id="tab_overview" title="Overview" href="/customerOverview.asp?id=<% =customerID %>" class="mdl-layout__tab is-active">
   	<span class="material-symbols-outlined customerTabIcon">house</span>
   	<span class="customerTabText">Overview</span>
   </a>
	<a id="tab_calls" title="Calls" href="/customerCalls.asp?id=<% =customerID %>" class="mdl-layout__tab">
   	<span class="material-symbols-outlined customerTabIcon">call</span>
   	<span class="customerTabText">Calls</span>
	</a>




	<span id="tab_commitments" class="mdl-layout__tab dropDownMenu">
   	<span class="material-symbols-outlined customerTabIcon">handshake</span>
   	<span class="customerTabText">Commitments</span>
   	<span class="material-symbols-outlined customerTabIcon">arrow_drop_down</span>
	</span>




<!--
	<button id="tab_commitments" class="mdl-button mdl-js-button">
		<i class="material-symbols-outlined customerTabIcon">handshake</i>
		<span>Commitment</span>
	</button>
-->



<!--
	<button id="tab_commitments" title="Commitments" href="" 				class="mdl-layout__tab">
   	<span class="material-symbols-outlined customerTabIcon" style="transform: scaleX(-1);">handshake</span>
   	<span class="customerTabText">Commitments</span>	   	
	</button>
-->
	
	
	<a id="tab_ms" title="Mystery Shopping" href="/customerMysteryShopping.asp?id=<% =customerID %>" class="mdl-layout__tab">
   	<span class="material-symbols-outlined customerTabIcon">shopping_cart</span>
   	<span class="customerTabText">Mystery Shopping</span>
	</a>
	<a id="tab_cultureSurvey" title="Culture Surveys" href="/customerCultureSurveys.asp?id=<% =customerID %>" 	class="mdl-layout__tab">
   	<span class="material-symbols-outlined customerTabIcon">content_paste</span>
   	<span class="customerTabText">Culture Surveys</span>
	</a>
	<span id="tab_reference" title="Reference" class="mdl-layout__tab dropDownMenu">
   	<span class="material-symbols-outlined customerTabIcon">local_library</span>
   	<span class="customerTabText">Reference</span>
   	<span class="material-symbols-outlined customerTabIcon">arrow_drop_down</span>
	</span>
	<span id="tab_team" title="Team" class="mdl-layout__tab dropDownMenu">
   	<span class="material-symbols-outlined customerTabIcon">diversity_3</span>
   	<span class="customerTabText">Team</span>
   	<span class="material-symbols-outlined customerTabIcon">arrow_drop_down</span>
	</span>
	<a id="tab_profit" title="cProfit" href="/cProfit/customerProfit.asp?id=<% =customerID %>" 	class="mdl-layout__tab">
   	<span class="material-symbols-outlined customerTabIcon" style="width: 18px; height: 24px;">attach_money</span>
   	<span class="customerTabText">cProfit</span>
	</a>
	
</div>
