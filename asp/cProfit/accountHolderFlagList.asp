<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/customerTitle.asp" -->
<!-- #include file="../includes/jsonDataTable.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(43)

customerID = request.querystring("customerID")
if ( len(customerID) <= 0  OR  not isNumeric(customerID) ) then 
	dbug("customerID is missing or invalid: " & customerID & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
end if 

title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)


'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->

%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<link rel="stylesheet" href="../datatables/DataTables.css" />
	<link rel="stylesheet" href="https://cdn.datatables.net/fixedheader/3.1.7/css/fixedHeader.dataTables.min.css" />
	<link rel="stylesheet" href="../jquery-ui-1.12.1/jquery-ui.min.css" />
	<link rel="stylesheet" href="cProfitStyle.css" />

	<script src="../jQuery/jquery-3.5.1.js"></script>
	<script src="../DataTables/datatables.js"></script>
	<script src="https://cdn.datatables.net/fixedheader/3.1.7/js/dataTables.fixedHeader.min.js"></script>
	<script src="../jquery-ui-1.12.1/jquery-ui.min.js"></script>
	<script src="../moment.min.js"></script>
	
	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		$(document).ready(function() {
						
			//-- ------------------------------------------------------------------ -->
			$( '#button_newFlag' ).on('click', function() {
			//-- ------------------------------------------------------------------ -->

				$( '#dialog-newFlag' ).data('clickedOn', this).dialog('open');

			});
			

			//-- ------------------------------------------------------------------ -->
			$( '#dialog-newFlag' ).dialog({
			//-- ------------------------------------------------------------------ -->
				autoOpen: false,
				modal: true,
				width: 350,
				resizable: false,
				buttons: [
					{
						text: 'Save',
						disabled: true,
						click: function() {

							SaveFlag(this)

							var flagColor = $( '#flagColor' );
							flagColor[0].selectedIndex = 0;
							flagColor.selectmenu( 'refresh' )

							$( '#flagName' ).val( '' );

							$( this ).dialog('close');

							$( '#cNoteDataTable' ).DataTable().ajax.reload();	

						}
					},
					{
						text: 'Cancel',
						autoFocus: true,
						click: function() {
							
							$( 'button.ui-button:contains("Save")' ).button( 'disable' );

							var flagColor = $( '#flagColor' );
							flagColor[0].selectedIndex = 0;
							flagColor.selectmenu( 'refresh' )

							$( '#flagName' ).val( '' );

							$( this ).dialog('close');

						}
					}
				]
			});
			
			
			//-- ------------------------------------------------------------------ -->
			$( '#dialog-confirmFlagDelete' ).dialog({
			//-- ------------------------------------------------------------------ -->
				modal: true,
				autoOpen: false,
				resizable: false,
				width: 600,
				buttons: {
					'Delete Flag': function() {
						const flagID = $( this ).find( '.flagID' ).val();
						DeleteFlag(flagID);
					},
					'Cancel': function () {
						$( this ).dialog( 'close' );
					}
				}
			})
			

			//-- ------------------------------------------------------------------ -->
			$( '#flagName' ).on('input', function() {
			//-- ------------------------------------------------------------------ -->
				$( 'button.ui-button:contains("Save")' ).button( 'enable' );
			});


			//-- ------------------------------------------------------------------ -->
			$( "#flagColor" ).selectmenu({
			//-- ------------------------------------------------------------------ -->
				change: function( event, ui) {
					$( 'button.ui-button:contains("Save")' ).button( 'enable' );
				}
			});
			

			//-- ------------------------------------------------------------------ -->
			var table = $('#cNoteDataTable')
			//-- ------------------------------------------------------------------ -->
				.DataTable({
					paging: false,
					scrollY: 600,
					info: false,
					searching: false,
					processing: true,
					rowReorder: {
						dataSrc: 'priority'
					},
					createdRow: function( row, data, index ) {
					
						row.addEventListener('mouseover', function() {
							this.querySelector( 'i.delete' ).style.visibility = 'visible';
						});
						
						row.addEventListener('mouseout', function() {
							$( this ).find( 'i.delete' ).css('visibility','hidden');
						});
						
					},
					serverSide: false,
					ajax: {
						url: '/cProfit/ajax/flags.asp',
						type: 'get'
					},
					columnDefs: [
						{targets: 'priority',	data: 'priority', orderable: false, className: 'reorder dt-body-center'},
						{targets: 'name',			data: 'name', 		orderable: false, className: 'dt-body-left'},
						{targets: 'color',		data: 'color', 	orderable: false, className: 'dt-body-left'},
						{
							targets: 'actions', 	
							data: null,			
							orderable: false, 
							className: 'actions dt-body-center',
							defaultContent: '',
							render: function() {
								return '<i class="material-icons delete" onClick="ConfirmFlagDelete(this)">delete</i>';
							}
						}
					],
					order: [[ 0, 'asc' ]],
				});


			//-- ------------------------------------------------------------------ -->
			table.on( 'row-reorder', async function ( e, diff, edit ) {
			//-- ------------------------------------------------------------------ -->
				
				var arrReorderedRows = [];
				
				for ( var i=0, ien=diff.length ; i<ien ; i++ ) {
					var rowData = table.row( diff[i].node ).data();
					diff[i].newData+' (was '+diff[i].oldData+')\n';
					if ( arrReorderedRows.length > 0 ) {
						arrReorderedRows += '|';
					}
					arrReorderedRows += rowData.DT_RowId + ',' + diff[i].newData;
				}
				
				const apiResponse = await fetch('/cProfit/ajax/accountHolderFlagReorder.asp?arrReorderedRows='+JSON.stringify(arrReorderedRows));

				if (apiResponse.status != 200) {
					return generateErrorResponse('failed to reorder flags, ' + apiResponse.status);
				}
				const apiResult = await apiResponse.json();

				const notification = $('.mdl-js-snackbar').get(0);
				notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
				
			});
			
			
			
							
		});


		//-- ------------------------------------------------------------------ -->
		async function DeleteFlag( flagID ) {
		//-- ------------------------------------------------------------------ -->

			const url 			= '/cProfit/ajax/flags.asp';
			const form 			= 'customerID=<% =customerID %>&flagID='+flagID;
			
			const apiResponse = await fetch(url, {
				method: 'DELETE',
				headers: { 'Content-type': 'application/x-www-form-urlencoded' },
				body: form
			});

			if (apiResponse.status != 200) {
				return generateErrorResponse('failed to reorder flags, ' + apiResponse.status);
			}
			const apiResult = await apiResponse.json();

			const notification = $('.mdl-js-snackbar').get(0);
			notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

			$( '#cNoteDataTable').DataTable().ajax.reload();
			
			$( '#dialog-confirmFlagDelete' ).dialog( 'close' );

		}


		//-- ------------------------------------------------------------------ -->
		async function SaveFlag( htmlElement ) {
		//-- ------------------------------------------------------------------ -->

			const flagID 		= $( '#flagID' ).val();
			const flagName 	= $( '#flagName' ).val();
			const flagColor 	= $( '#flagColor' ).val();
			
			const url 	= '/cProfit/ajax/flags.asp';
			const form 	= 'flagID='+flagID+'&flagName='+flagName+'&flagColor='+flagColor;
			
			const apiResponse = await fetch(url, {
				method: 'POST',
				headers: { 'Content-type': 'application/x-www-form-urlencoded' },
				body: form
			});
			
			if (apiResponse.status != 200) {
				return generateErrorResponse('failed to POST flag info, ' + apiResponse.status);
			}
			
			const apiResult = await apiResponse.json();
			
			const notification = $('.mdl-js-snackbar').get(0);
			
			notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

		}


		//-- ------------------------------------------------------------------ -->
		function ConfirmFlagDelete(deleteIcon) {
		//-- ------------------------------------------------------------------ -->

			const flagID = deleteIcon.closest( 'TR' ).id;
			$( '#dialog-confirmFlagDelete' ).find( '.flagID' ).val(flagID);			
			$( '#dialog-confirmFlagDelete' ).dialog( 'open' );
			
		}
			
			

	</script>

	<style>

		table.dataTable tbody tr:hover {
			cursor: default;
		}

		td.responseValues {
			max-width: 450px;
			text-overflow: ellipsis;
			white-space: nowrap;
			overflow: hidden;		
		}
		
		i.delete {
			visibility: hidden;
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
		
			<!-- #include file="../includes/mdlLayoutNavLarge.asp" -->

		</div>
		<!-- #include file="../includes/customerTabs.asp" -->
  </header>

	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
				
			<!-- Your content goes here -->

			<!-- SNACKBAR -->
			<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
			    <div class="mdl-snackbar__text"></div>
			    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
			</div>


			<div id="dialog-confirmFlagDelete" class="dialog" title="Delete Flag?">
				<input type="hidden" class="flagID">
				<p>
					<span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>
					This flag will be permanently deleted and removed from all account holders; this cannot be recovered. Are you sure?
				</p>
			</div>  
		  


			<div id="dialog-newFlag" title="New Flag">

				<input type="hidden" id="flagID">

				<div style="margin-top: 15px;">
					<label for="flagName">Name:</label>
					<input type="text" id="flagName" style="width: 250px; height: 23px;">
				</div>

				<div style="margin-top: 15px;">
					<label for="flagColor">Color:</label>
					<select id="flagColor">
						<option></option>
						<option value="crimson">Red</option>
						<option value="deeppink">Pink</option>
						<option value="orange">Orange</option>
						<option value="yellow">Yellow</option>
						<option value="purple">Purple</option>
						<option value="green">Green</option>
						<option value="blue">Blue</option>
						<option value="brown">Brown</option>
						<option value="gray">Gray</option>
					</select>
				</div>

			</div>



			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--1-col">
					<button id="button_newFlag" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
						New Flag
					</button>
				</div>
				<div class="mdl-cell mdl-cell--2-col reportTitle">Account Holder Flags</div>
				<div class="mdl-cell mdl-cell--1-col"></div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" style="padding: 15px;">

					<table id="cNoteDataTable" class="compact display nowrap">
						<thead>
							<tr>
								<th class="priority">Seq</th>
								<th class="name">Name</th>
								<th class="color">Color</th>
								<th class="actions">Actions</th>
							</tr>
						</thead>
					</table>

				</div>
		
				<div class="mdl-layout-spacer"></div>
		
			</div>


		</div>

	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>