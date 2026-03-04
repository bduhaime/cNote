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
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(7)

userLog("Metrics")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Metrics" 
%>

<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<link rel="stylesheet" href="dialog-polyfill.css" />

	<script type="text/javascript" src="metricList.js"></script>

	<script>

		//--------------------------------------------------------------------------------
		function EditMetric( htmlElement ) {
		//--------------------------------------------------------------------------------

			event.stopPropagation();
			
			const rowID = htmlElement.closest('tr').id;
			const table = $('#tbl_metrics').DataTable();
			const row = '#'+rowID;

			$( '#metricName' ).val( table.cell( row, '.metricName' ).data() );
			$( '#ubprSection' ).val( table.cell( row, '.ubprSection' ).data() );
			$( '#ubprLine' ).val( table.cell( row, '.ubprLine' ).data() );
			$( '#financialCtgy' ).val( table.cell( row, '.financialCtgy' ).data() );
			$( '#ranksColumnName' ).val( table.cell( row, '.ranksColumnName' ).data() );
			$( '#ratiosColumnName' ).val( table.cell( row, '.ratiosColumnName' ).data() );
			$( '#statsColumnName' ).val( table.cell( row, '.statsColumnName' ).data() );
			$( '#sourceTableNameRoot' ).val( table.cell( row, '.sourceTableNameRoot' ).data() );
			$( '#dataType' ).val( table.cell( row, '.dataType' ).data() );
			$( '#displayUnitsLabel' ).val( table.cell( row, '.displayUnitsLabel' ).data() );
			$( '#annualChangeColumn' ).val( table.cell( row, '.annualChangeColumn' ).data() );
			
			$( '#dialog-form' ).dialog( 'open' );
			

		}
		
		
	 	
		//--------------------------------------------------------------------------------
		function ConfirmDeleteMetric( htmlElement ) {
		//--------------------------------------------------------------------------------

			event.stopPropagation();

			$( '#metricID' ).val( htmlElement.closest('tr').id );
			$( '#dialog-confirm' ).dialog( 'open' );


		}
		
		
		
		//--------------------------------------------------------------------------------
		function ToggleActionIcons( htmlElement ) {
		//--------------------------------------------------------------------------------

			var icons = htmlElement.querySelectorAll( '.actions i' );
			
			if (icons) {
				
				for ( i = 0; i < icons.length; ++i ) {
					if ( icons[i].style.visibility == 'visible' ) {
						icons[i].style.visibility = 'hidden';
					} else {
						icons[i].style.visibility = 'visible';
					}
				}			

			}
				
		}
		


		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------
			
			$( document ).tooltip();


			$( "#ubprSectionFilter" ).selectmenu({
				change: function( event, ui ) {

					var table = $( '#tbl_metrics' ).DataTable();
					var searchFor = $( this ).val();
					if ( searchFor == 'All' ) {
						searchFor = '';
					}
					table.column( '.ubprSection' ).search( searchFor ).draw();

				}
			});


			$( "#ubprLineFilter" ).selectmenu({
				change: function( event, ui ) {

					var table = $( '#tbl_metrics' ).DataTable();
					var searchFor = $( this ).val();
					if ( searchFor == 'All' ) {
						searchFor = '';
					}
					table.column( '.ubprLine' ).search( searchFor ).draw();

				}
			});


			$( "#financialCategoryFilter" ).selectmenu({
				change: function( event, ui ) {

					var table = $( '#tbl_metrics' ).DataTable();
					var searchFor = $( this ).val();
					if ( searchFor == 'All' ) {
						searchFor = '';
					}
					table.column( '.financialCtgy' ).search( searchFor ).draw();

				}
			});


			$( "#dialog-confirm" ).dialog({
				resizable: false,
				height: 'auto',
				autoOpen: false,
				width: 400,
				modal: true,
				buttons: {
					'Delete the metric': function() {
						alert( 'Delete is not currenctly enabled -- contact your system administrator' );
						$( this ).dialog( 'close' );
					},
					Cancel: function() {
						$( this ).dialog( 'close' );
					}
				}
			});				
				
				
			$( "#dialog-form" ).dialog({
				resizable: false,
				height: 'auto',
				autoOpen: false,
				width: 800,
				modal: true,
				buttons: {
					Save: function() {
						alert( 'Edit is not currently enabled -- contact your system administrator' );
						$( this ).dialog( 'close' );
					},
					Cancel: function() {
						$( this ).dialog( 'close' );
					}
				},
				close: function() {
// 					form[ 0 ].reset();
// 					allFields.removeClass( 'ui-state-error' );
				}
			});
				
				
			var table = $( '#tbl_metrics' )

				.on( 'click', 		'i.edit', function(event) {
					EditMetric( this );					
				})
				.on( 'click', 		'i.delete', function( event ) {
					ConfirmDeleteMetric( this );
				})
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'mouseout', 	'tbody tr', function() {
					ToggleActionIcons( this );
				})

				.DataTable({

					initComplete: function( setting, json ) {

						var sectionList = $( this ).DataTable().cells( '.ubprSection' ).data().unique().sort();
						var ubprSectionFilter = $( '#ubprSectionFilter' );
						for ( i = 0; i < sectionList.length; ++i ) {
							ubprSectionFilter.append( new Option( sectionList[i] ) );
						}


						var lineList = $( this ).DataTable().cells( '.ubprLine' ).data().unique().sort();
						var lineFilter = $( '#ubprLineFilter' );
						for ( i = 0; i < lineList.length; ++i ) {
							lineFilter.append( new Option( lineList[i] ) );
						}

						var categoryList = $( this ).DataTable().cells( '.financialCtgy' ).data().unique().sort();
						var categoryFilter = $( '#financialCategoryFilter' );
						for ( i = 0; i < categoryList.length; ++i ) {
							categoryFilter.append( new Option( categoryList[i] ) );
						}

					},
					rowId: 'id',
					scrollX: true,
					scrollY: 610,
					scroller: true,
					ajax: { 
						url: `${apiServer}/api/metrics`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
					},
					dom: 'Bfrtip',
					buttons: [
						{
							extend: 'csv',
							filename: 'metrics',
							text: 'Download'
						}
					],
					columnDefs: [
						{ targets: 'name', data: 'name', className: 'name' },
						{ targets: 'ubprSection', data: 'ubprSection', className: 'ubprSection' },
						{ targets: 'ubprLine', data: 'ubprLine', className: 'ubprLine dt-body-center' },
						{ targets: 'financialCtgy', data: 'financialCtgy', className: 'financialCtgy' },
						{ targets: 'ranksColumnName', data: 'ranksColumnName', className: 'dt-body-center' },
						{ targets: 'ratiosColumnName', data: 'ratiosColumnName', className: 'dt-body-center' },
						{ targets: 'statsColumnName', data: 'statsColumnName', className: 'dt-body-center' },
						{ targets: 'sourceTableNameRoot', data: 'sourceTableNameRoot' },
						{ targets: 'dataType', data: 'dataType' },
						{ targets: 'displayUnitsLabel', data: 'displayUnitsLabel' },
						{ targets: 'correspondingAnnualChangeID', data: 'correspondingAnnualChangeID' },
						{ targets: 'metricType', data: 'metricType' },
						{ targets: 'frequency', data: 'frequency', className: 'dt-body-center' },
					],

				});
		});


	</script>

	<style>
		
		div.filters  {
			text-align: center;
		}
		

		i.delete, i.edit {
			visibility: hidden;
			cursor: pointer;
		}

		.ui-selectmenu-open{
			max-height: 350px;
			overflow-y: scroll;
		}


		label, input { display: inline-block; }
		label { font-weight: bold }
		input.text { margin-bottom:12px; width:95%; padding: .4em; }
		fieldset { padding:0; border:0; margin-top:25px; }
		h1 { font-size: 1.2em; margin: .6em 0; }
		div#users-contain { width: 350px; margin: 20px 0; }
		div#users-contain table { margin: 1em 0; border-collapse: collapse; width: 100%; }
		div#users-contain table td, div#users-contain table th { border: 1px solid #eee; padding: .6em 10px; text-align: left; }
		.ui-dialog .ui-state-error { padding: .3em; }
		.validateTips { border: 1px solid transparent; padding: 0.3em; }
		

	</style>


</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">

	<!-- snackbar -->
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	
	<!-- 	delete metric confirmation dialog -->
	<div id="dialog-confirm" title="Delete the metric?">
		<input type="hidden" id="metricID">
		<p><span class="material-icons" style="float:left; margin:12px 12px 20px 0;">warning</span>The metric will be permanently deleted and cannot be recovered. Are you sure?</p>
	</div>

	<!-- 	dialog for editing a metric -->
	<div id="dialog-form" title="Edit the metric">
		<p class="validateTips">All form fields are required.</p>
		
		<form>
			<fieldset>
				<label for="metricName">Metric Name</label>
				<input type="text" name="metricName" id="metricName" class="text ui-widget-content ui-corner-all">

				<div style="display: block;">

					<div style="display: inline-block;">
						<label for="ubprSection" style="display: block;">UBPR Section</label>
						<input type="text" name="ubprSection" id="ubprSection" class="text ui-widget-content ui-corner-all" style="width: 393px;">
					</div>
		
					<div style="display: inline-block;">
						<label for="ubprLine" style="display: block;">UBPR Line</label>
						<input type="text" name="ubprLine" id="ubprLine" class="text ui-widget-content ui-corner-all" style="width: 150px;">
					</div>
		
					<div style="display: inline-block;">
						<label for="financialCtgy" style="display: block;">Finanical Category</label>
						<input type="text" name="financialCtgy" id="financialCtgy" class="text ui-widget-content ui-corner-all" style="width: 150px;">
					</div>

				</div>

				<div style="display: block;">

					<div style="display: inline-block;">
						<label for="ranksColumnName" style="display: block;">Ranks Column</label>
						<input type="text" name="ranksColumnName" id="ranksColumnName" class="text ui-widget-content ui-corner-all" style="width: 231px;">
					</div>
	
					<div style="display: inline-block;">
						<label for="ratiosColumnName" style="display: block;">Ratios Column</label>
						<input type="text" name="ratiosColumnName" id="ratiosColumnName" class="text ui-widget-content ui-corner-all" style="width: 231px;">
					</div>
	
					<div style="display: inline-block;">
						<label for="statsColumnName" style="display: block;">Stats Column</label>
						<input type="text" name="statsColumnName" id="statsColumnName" class="text ui-widget-content ui-corner-all" style="width: 231px;">
					</div>

				</div>
				
				
				<div style="display: block;">

					<div style="display: inline-block;">
						<label for="sourceTableNameRoot" style="display: block;">Source Table Name Root</label>
						<input type="text" name="sourceTableNameRoot" id="sourceTableNameRoot" class="text ui-widget-content ui-corner-all" style="width: 393px;">
					</div>
		
					<div style="display: inline-block;">
						<label for="dataType" style="display: block;">Data Type</label>
						<input type="text" name="dataType" id="dataType" class="text ui-widget-content ui-corner-all" style="width: 150px;">
					</div>
		
					<div style="display: inline-block;">
						<label for="displayUnitsLabel" style="display: block;">Display Units Label</label>
						<input type="text" name="displayUnitsLabel" id="displayUnitsLabel" class="text ui-widget-content ui-corner-all" style="width: 150px;">
					</div>
				
				</div>

				<label for="annualChangeColumn">Annual Change Column</label>
				<input type="text" name="annualChangeColumn" id="annualChangeColumn" class="text ui-widget-content ui-corner-all">

				<!-- Allow form submission with keyboard without duplicating the dialog button -->
				<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">

			</fieldset>
		</form>
	</div>

	
	<div class="page-content">
	<!-- Your content goes here -->
		
		<!-- 	Filters -->
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--10-col">

				<div class="filters">
					
					<label for="ubprSectionFilter"><b>UBPR Section:</b></label>
					<select id="ubprSectionFilter">
						<option>All</option>
					</select>
					
					<label for="ubprLineFilter">&nbsp;<b>UBPR Line:</b></label>
					<select id="ubprLineFilter">
						<option>All</option>
					</select>
					
					<label for="financialCategoryFilter">&nbsp;<b>Financial Category:</b></label>
					<select id="financialCategoryFilter">
						<option>All</option>
					</select>
					
				</div>

		   </div>
			<div class="mdl-layout-spacer"></div>
	   </div>

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--11-col" width="100%">

				<table id="tbl_metrics" class="compact display">
					<thead>
						<tr>
							<th class="name">Metric Name</th>
							<th class="metricType">Metric Type</th>
							<th class="ubprSection">UBPR Section</th>
							<th class="ubprLine">UBPR Line</th>
							<th class="financialCtgy">Financial Ctgy</th>
							<th class="ranksColumnName">Ranks Col</th>
							<th class="ratiosColumnName">Ratios Col</th>
							<th class="statsColumnName">Stats Col</th>
							<th class="sourceTableNameRoot">Source Table Root</th>
							<th class="dataType">Data Type</th>
							<th class="displayUnitsLabel">Display Units Label</th>
							<th class="correspondingAnnualChangeID">Annual Chg Col</th>
							<th class="frequency">Frequency</th>
						</tr>
					</thead>
				</table>

		   </div>
			<div class="mdl-layout-spacer"></div>
   	</div>
			
	</div><!-- end of page-content -->



</main>
<!-- #include file="includes/pageFooter.asp" -->



</body>
</html>