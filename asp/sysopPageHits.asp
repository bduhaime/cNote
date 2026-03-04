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

userLog("Customer Statuses")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Customer Statuses" 
%>

<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	jQuery -->
	<script type="text/javascript" src="jQuery/jquery-3.5.1.js"></script>


	<!-- 	jQuery UI -->
	<script type="text/javascript" src="jquery-ui-1.12.1/jquery-ui.js"></script>
	<link rel="stylesheet" href="jquery-ui-1.12.1/jquery-ui.css" />


	<!-- 	DataTables -->
	<script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.10.21/b-1.6.3/b-colvis-1.6.3/b-html5-1.6.3/b-print-1.6.3/fh-3.1.7/sc-2.0.2/datatables.min.js"></script>
	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.10.21/b-1.6.3/b-colvis-1.6.3/b-html5-1.6.3/b-print-1.6.3/fh-3.1.7/sc-2.0.2/datatables.min.css"/>


	<!-- DataTables Editor -->
	<script type="text/javascript" src="Editor-2.5.1/js/dataTables.editor.js"></script>
	<script type="text/javascript" src="Editor-2.5.1/js/editor.jqueryui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="Editor-2.5.1/css/editor.dataTables.css">



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


				$.fn.dataTable.Editor.display.jqueryui.modalOptions = {
					width: 700,
					modal: true
				}


				var editor = new $.fn.dataTable.Editor( {
					ajax: {
						url: `${apiServer}/api/customerStatuses`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT }
					},
					formOptions: {
						main: {
							onEsc: 'none'
						}
					},
					table: '#tbl_customerStatuses',
					display: 'jqueryui',
					fields: [
						{ label: 'Name:', 									name: 'name', 					type: 'text' },
						{ label: 'Active?:', 								name: 'active',				type: 'checkbox' },
						{ label: 'Default:', 								name: 'default',				type: 'checkbox' },
						{ label: 'Include in interim FDIC loads?:', 	name: 'interimFdicLoad',	type: 'checkbox' },
						{ label: 'Select by default?:', 					name: 'selectByDefault',	type: 'checkbox' },
					]
// 				}).on( 'edit', function() {
// 					snackBarNotification( 'Manager updated' );
// 					buildChart_customerManagerTimeLine();
// 				}).on( 'create', function() {
// 					snackBarNotification( 'Manager added' );
// 					buildChart_customerManagerTimeLine();
// 				}).on( 'remove', function() {
// 					snackBarNotification( 'Manager deleted' );
// 					buildChart_customerManagerTimeLine();
				});


			let table = $( '#tbl_customerStatuses' ).DataTable({
				dom: 'Bfrtip',
				buttons: [
// 					{ extend: 'create', editor: editor },
// 					{ extend: 'edit',   editor: editor },
// 					{ extend: 'remove', editor: editor }
				],
				rowId: 'id',
				paging: false,
				searching: false,
				ajax: { 
					url: `${apiServer}/api/customerStatuses`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: '',
				},
				columnDefs: [
					{ targets: 'name', data: 'name', className: 'name' },
					{ targets: 'active', data: 'active', className: 'active dt-center',
						render: function( data, type, row ) {
							return renderCheckmark( data );
						}
					},
					{ targets: 'default', data: 'default', className: 'default dt-center',
						render: function( data, type, row ) {
							return renderCheckmark( data );
						}
					},
					{ targets: 'interimFdicLoad', data: 'interimFdicLoad', className: 'interimFdicLoad dt-center', 
						render: function( data, type, row ) {
							return renderCheckmark( data );
						}
					},
					{ targets: 'selectByDefault', data: 'selectByDefault', className: 'selectByDefault dt-center', 
						render: function( data, type, row ) {
							return renderCheckmark( data );
						}
					},
				],
			});
			
			
			function renderCheckmark( data ) {
				
				if ( data ) {
					return '<i class="material-icons">done</i>';
				} else {
					return '';
				}
	
			}

			
		});


	</script>

	<style>
		
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
	
	<div class="page-content">
	<!-- Your content goes here -->
		<br>
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--4-col">

				<table id="tbl_customerStatuses" class="compact display">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="active">Active?</th>
							<th class="default">Default?</th>
							<th class="interimFdicLoad">Include In<br>Interim Loads?</th>
							<th class="selectByDefault">Select By<br>Default?</th>
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