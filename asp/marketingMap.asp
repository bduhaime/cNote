<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess( 144 )

title = session("clientID") & " - Marketing Map" 
userLog(title)
%>

<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

<!--
	<script type="text/javascript" src="https://cdn.datatables.net/searchbuilder/1.4.0/js/dataTables.searchBuilder.min.js"></script>
	<link rel="stylesheet" href="https://cdn.datatables.net/searchbuilder/1.4.0/css/searchBuilder.dataTables.min.css" />
-->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script>

		google.charts.load( 'current', { 
			'packages': [ 'map' ],
			'mapsApiKey': 'AIzaSyC37tiNRX6JojgZmofQ5Q8s9xohBn83gxo'
		});
		
		google.charts.setOnLoadCallback(drawMapChart);				


		//================================================================================
		function showTransientMessage( msg ) {
		//================================================================================

			let notification = document.querySelector('.mdl-js-snackbar');
			
			console.log( 'toast!' );
			
			notification.MaterialSnackbar.showSnackbar({ message: msg });
			

		}
		//================================================================================

		

		//================================================================================
		function drawMapChart() {
		//================================================================================
			
			const certList = sessionStorage.getItem( 'certsToMap' );
			
			$.ajax({

				url: `${apiServer}/api/marketing/institutions/map`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { certList: certList },

			}).then( response => {

			var options = {
				mapType: 'styledMap',
// 				zoomLevel: 12,
				showTooltip: true,
				showInfoWindow: true,
				useMapTypeControl: true,
				maps: {
					// Your custom mapTypeId holding custom map styles.
					styledMap: {
						name: 'Styled Map', // This name will be displayed in the map type control.
						styles: [
							{ 
								featureType: 'poi.attraction',
								stylers: [{color: '#fce8b2'}]
							},
							{ 
								featureType: 'road.highway',
								stylers: [{hue: '#0277bd'}, {saturation: -50}]
							},
							{ 
								featureType: 'road.highway',
								elementType: 'labels.icon',
								stylers: [{hue: '#000'}, {saturation: 100}, {lightness: 50}]
							},
							{ 
								featureType: 'landscape',
								stylers: [{hue: '#259b24'}, {saturation: 10}, {lightness: -22}]
							}
						]
					}
				}
			};
      

				let chart = new google.visualization.Map( document.getElementById( 'map' ) );
				let data = new google.visualization.arrayToDataTable( response );
				chart.draw( data, options );

			}).fail( err => {
				$( '#fdicROA_progressbar' ).progressbar('destroy');
				$(' #fdicROA' ).text( err.status + ' (' + err.responseText + ') ' );
			});
			
		}
		//--------------------------------------------------------------------------------



		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------
			
			$( '.mdl-spinner' ).addClass( 'is-active' );

			$( 'input' ).tooltip();
			
			$( document ).tooltip();
			
			drawMapChart();				
						
			$( '.mdl-spinner' ).removeClass( 'is-active' );

		});


	</script>

	<style>
		
		#institutions thead tr th {
			vertical-align: bottom !important;
		}
		
		.mdl-navigation {
			padding-left: 8px;
		}
		
		#applyFilter {
			width: 100px;
		}

		div.ui-tooltip {
			max-width: 600px;
		}
		
		.mdl-layout__drawer {
			width: 500px;
			left: -250px;
		}
		
		.mdl-layout__drawer.is-visible {
			left: 0;
		}	
		
		input.amount {
			width: 90px;
			float: right;
			text-align: right;
		}	

		input.ratio {
			width: 75px;
			float: right;
			text-align: right;
		}	

		input.rank {
			width: 45px;
			float: right;
			text-align: right;
		}
		
		.is-invalid {
			color: red;
			background-color: yellow;
		}

		.dialogWithDropShadow {
			-webkit-box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.5);  
			-moz-box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.5); 
		}
		
		.warning {
			vertical-align: bottom;
			font-size: 48px;
			color: #e65014;
			font-weight: bold;
		}
		
		.mdl-spinner {
			width: 56px;
			height: 56px;
		}
		
		.mdl-spinner__circle {
			border-width: 6px;
		}
		
/*
		table tfoot tr td {
			float: right;
		}
*/

	</style>


</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>

<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
<header class="mdl-layout__header">

	<div class="mdl-layout__header-row">
		<!-- Title -->
		<span class="mdl-layout-title"><% =title %></span>

		<!-- Add spacer, to align navigation to the right -->
		<div class="mdl-layout-spacer"></div>
		
		<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

	</div>
</header>

<main class="mdl-layout__content">

	<!-- snackbar -->
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	
	<div class="page-content">
	<!-- Your content goes here -->

   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--11-col" width="100%">
			   <div id="map" style="height: 800px;"></div>
		   </div>
	
			<div class="mdl-layout-spacer"></div>
			
   	</div>
			
	</div><!-- end of page-content -->



</main>
<!-- #include file="includes/pageFooter.asp" -->



</body>
</html>