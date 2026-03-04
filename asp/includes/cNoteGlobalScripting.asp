<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->


<!-- 	Material Design Lite -->
<script defer src="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.3.0/material.min.js"></script>

<!-- 	jQuery (minified) -->
<script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>

<!-- 	jQuery UI -->
<script type="text/javascript" src="jquery-ui-1.14.1/jquery-ui.js"></script>
<link rel="stylesheet" href="jquery-ui-1.14.1/jquery-ui.css" />


<!-- 	DataTables -->
<script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.11.5/b-2.2.2/b-colvis-2.2.2/b-html5-2.2.2/b-print-2.2.2/date-1.1.2/fh-3.2.2/sc-2.0.5/sl-1.3.4/datatables.min.js"></script>


<!-- 	Dayjs -->
<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>
<script src="https://unpkg.com/dayjs@1.8.21/plugin/quarterOfYear.js"></script>
<script>dayjs.extend(window.dayjs_plugin_quarterOfYear)</script>

<!-- 	Google Visualizations -->
<script src="https://www.gstatic.com/charts/loader.js"></script>

	
<script>
	// this is in includes/cNoteGlobalScripting.asp

	if ( typeof aspServer === 'undefined' ) var aspServer = '<% =aspServer %>';
	if ( typeof apiServer === 'undefined' ) var apiServer = '<% =apiServer %>';
	if ( typeof userID === 'undefined' ) var userID = '<% =session("userID") %>';

	/*******************************************************************************/
	window.addEventListener('load', function() {
	/*******************************************************************************/
		
		<% 
		scriptArray = split(request.serverVariables("SCRIPT_NAME"),"/")
		currentScript = scriptArray(uBound(scriptArray))
		dbug("currentScript: " & currentScript)
		if currentScript = "userEdit.asp" then 
			%>
			var popupMessage = '<% =popupMessage %>';
			if (popupMessage.length > 1) {
				alert(popupMessage);
			}
			<%
		end if 
		%>
		
		var spinner = document.querySelector('.mdl-spinner');
		if ( spinner ) spinner.classList.remove('is-active'); 

	});


	
	/*******************************************************************************/
	window.addEventListener('beforeunload', function() {
	/*******************************************************************************/

		var spinner = document.querySelector('.mdl-spinner');
		if ( spinner ) spinner.classList.add('is-active'); 

	});



</script>		

