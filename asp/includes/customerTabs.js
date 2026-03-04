//-- ------------------------------------------------------------------ -->
function buildDropdownMenu( e ) {
//-- ------------------------------------------------------------------ -->
//-- 
//-- this function builds a sub-menu from the customerTabs, which is
//-- implemented as navigation menu across the top of all customer pages.
//--
//-- e: is the click event
//-- ------------------------------------------------------------------ -->
	
	e.preventDefault();	
	
	debugger
	
	const clickedTab = $( e.target ).parent().attr( 'id' );
	
	$( '.context-menu' ).removeClass( 'context-meny--active' );
	switch ( clickedTab ) {
		case 'tab_commitments':
			$( '#commitments' ).addClass( 'context-menu--active' );
			break;
		case 'tab_reference':
			$( '#reference' ).addClass( 'context-menu--active' );
			break;
		case 'tab_team':
			$( '#team' ).addClass( 'context-menu--active' );
			break;
		default:
			return false;
	}
		
	
							
	var posX, posY;
	
	if (e.clientX || e.clientY) {
		posX = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
		posY = e.clientY + document.body.scrollTop  + document.documentElement.scrollTop - 112;
		console.log('Using client coordinates of '+posX+','+posY);
	} else {
		posX = 0;
		posY = 0;
		console.log('Using default coordinates of '+posX+','+posY);
	}


// 	
// 	menu.querySelector('.context-menu__title').textContent = 'Drilldown on ' + entityID + ' by:';
// 	menu.classList.add('context-menu--active');
// 	var menuWidth 		= $(menu).width();
// 	var menuHeight 	= $(menu).height();
// 	var screenWidth 	= $(window).width();
// 	var screenHeight 	= $(window).height();
// 	console.log('screenWidth: ' + screenWidth + '; screenHeight: ' + screenHeight);
// 	
// 	if ( menuWidth + posX > screenWidth ) {
// 		console.log('menu would be off the right of the screen, so shifting left');
// 		menu.style.left = posX - menuWidth + 'px';
// 	} else {
// 		menu.style.left = posX + 'px';
// 	}
// 
// 	if ( menuHeight + posY > screenHeight ) {
// 		console.log('menu would be off the bottom of the screen so shifting up');
// 		menu.style.top  = posY - menuHeight + 'px';
// 	} else {
// 		menu.style.top  = posY + 'px';
// 	}
// 	
	
	
	
// 	// remove all existing events...
// 	$('li.accounts').off('click');
// 	$('li.accountHolders').off('click');
// 	$('li.branches	').off('click');
// 	$('li.officers').off('click');
// 	$('li.products').off('click');					
// 
// 	// convert "parms" object to string for the querystrings...
// 	var querystringParms = '';
// 	if ( parms.account != null) {
// 		querystringParms += '&account='+parms.account;
// 	}
// 	if ( parms.accountHlolder != null) {
// 		querystringParms += '&accountHolder='+parms.accountHolder;
// 	}
// 	if ( parms.branch != null) {
// 		querystringParms += '&branch='+parms.branch;
// 	}
// 	if ( parms.officer != null) {
// 		querystringParms += '&officer='+parms.officer;
// 	}
// 	if ( parms.product != null) {
// 		querystringParms += '&product='+parms.product;
// 	}
// 	
// 	// add new event listeners...
// 	$('li.accounts').on('click', function() {
// 		window.location.href = '/cProfit/accountSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
// 	});
// 	$('li.accountHolders').on('click', function() {
// 		window.location.href = '/cProfit/accountHolderSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
// 	});
// 	$('li.branches').on('click', function() {
// 		window.location.href = '/cProfit/branchSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
// 	});
// 	$('li.officers').on('click', function() {
// 		window.location.href = '/cProfit/officerSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
// 	});
// 	$('li.products').on('click', function() {
// 	window.location.href = '/cProfit/productSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
// 	});
// 	
// 	// hide the LI for the current drillDownType...
// 
// 	if ( drillDownType == 'account') {
// 		$('li.accounts').hide();
// 	}
// 	if ( drillDownType == 'accountHolder') {
// 		$('li.accountHolders').hide();
// 	}
// 	if ( drillDownType == 'branch') {
// 		$('li.branches').hide();
// 	}
// 	if ( drillDownType == 'officer') {
// 		$('li.officers').hide();
// 	}
// 	if ( drillDownType == 'product') {
// 		$('li.products').hide();
// 	}
// 	
	
	
}
//-- ------------------------------------------------------------------ -->
