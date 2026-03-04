//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->
window.addEventListener('load', function() {
//-- ------------------------------------------------------------------ -->
	
	// get names for all visible account holders...
	GetAllVisibleAccounts(<% =customerID %>);

	// when scrolling has stopped (for 180 ms), get names for all visible accounts...
	var cNoteTableBody_isScrolling;
	var cNoteTableBody = document.querySelector('table.cNoteTable tbody');
	cNoteTableBody.addEventListener('scroll', function(event) {
		window.clearTimeout( cNoteTableBody_isScrolling );
		cNoteTableBody_isScrolling = setTimeout( function() {
			GetAllVisibleAccounts(<% =customerID %>);
		},180)
	},false);
	

});
