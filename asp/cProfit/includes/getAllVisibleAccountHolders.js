//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->
window.addEventListener('load', function() {
//-- ------------------------------------------------------------------ -->
	
	// get names for all visible account holders...
	GetAllVisibleAccountHolders(<% =customerID %>);

	// when scrolling has stopped (for 180 ms), get names for all visible account holders...
	
	
	var cNoteTableBodies = document.querySelectorAll('table.cNoteTable tbody');
	if (cNoteTableBodies) {
		
		for (i = 0; i < cNoteTableBodies.length; ++i) {
			
			cNoteTableBodies[i].addEventListener('scroll', function(event) {
				
				var cNoteTableBody_isScrolling;
				window.clearTimeout(cNoteTableBody_isScrolling);
				cNoteTableBody_isScrolling = setTimeout( function () {
					GetAllVisibleAccountHolders(<% =customerID %>);
				},180)
				
				
			},false);
			
		}

	}
	
	
	
	
	
	
// 	var cNoteTableBody_isScrolling;	
// 	var cNoteTableBody = document.querySelector('table.cNoteTable tbody');
// 	cNoteTableBody.addEventListener('scroll', function(event) {
// 		window.clearTimeout( cNoteTableBody_isScrolling );
// 		cNoteTableBody_isScrolling = setTimeout( function() {
// 			GetAllVisibleAccountHolders(<% =customerID %>);
// 		},180)
// 	},false);
	

});
