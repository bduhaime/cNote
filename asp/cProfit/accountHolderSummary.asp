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
<!-- #include file="../includes/apiServer.asp" -->
<!-- #include file="../includes/jwt.all.asp" -->
<!-- #include file="../includes/sessionJWT.asp" -->
<!-- #include file="includes/getAccountHolderAddenda.asp" -->
<!-- #include file="includes/getDrilldownParameters.asp" -->
<% 
call checkPageAccess(43)

customerID = request.querystring("customerID")
if ( len(customerID) <= 0  OR  not isNumeric(customerID) ) then 
	dbug("customerID is missing or invalid: " & customerID & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
end if 

SQL = "select cProfitURI, cProfitApiKey from customer where id = " & customerID & " " 
set rsAPI = dataconn.execute(SQL)
if not rsAPI.eof then 
	cProfitURL = rsAPI("cProfitURI")	
	cProfitApiKey = rsAPI("cProfitApiKey")
else 
	cProfitURL = ""
	cProfitApiKey = ""
end if 
rsAPI.close 
set rsAPI = nothing 	

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


	<!-- 	jQuery -->
	<script src="../jQuery/jquery-3.5.1.js"></script>

	<!-- 	jQuery UI -->
	<script type="text/javascript" src="../jquery-ui-1.12.1/jquery-ui.js"></script>
	<link rel="stylesheet" href="../jquery-ui-1.12.1/jquery-ui.css" />




	<!-- 	DataTables -->
	<link rel="stylesheet" href="../datatables/DataTables.css" />
	<script src="../DataTables/datatables.js"></script>


	<!-- 	DataTables Extensions: Buttons -->
	<link rel="stylesheet" href="https://cdn.datatables.net/buttons/1.6.2/css/buttons.dataTables.min.css" />
	<script src="https://cdn.datatables.net/buttons/1.6.2/js/dataTables.buttons.min.js"></script>


	<!-- 	DataTables Extensions: Buttons / Column Visibility Control -->
	<script src="https://cdn.datatables.net/buttons/1.6.2/js/buttons.colVis.min.js"></script>
	
	<!-- 	DataTables Extensions: Buttons / HTML5 export buttons -->
	<script src="https://cdn.datatables.net/buttons/1.6.2/js/buttons.html5.min.js"></script>
	
	<!-- 	DataTables Extensions: Buttons / Flash export buttons -->
	<script src="https://cdn.datatables.net/buttons/1.6.2/js/buttons.flash.min.js"></script>
	
	<!-- 	DataTables Extensions: Buttons / Print button -->
	<script src="https://cdn.datatables.net/buttons/1.6.2/js/buttons.print.min.js"></script>
	
	<!-- 	DataTables Extensions: Search Panes -->
	<link rel="stylesheet" href="https://cdn.datatables.net/searchpanes/1.1.1/css/searchPanes.dataTables.min.css" />
	<script src="https://cdn.datatables.net/searchpanes/1.1.1/js/dataTables.searchPanes.min.js"></script>
	
	


	<!-- 	jQuery UI -->
	<link rel="stylesheet" href="../jquery-ui-1.12.1/jquery-ui.min.css" />
	<script src="../jquery-ui-1.12.1/jquery-ui.min.js"></script>


	<link rel="stylesheet" href="cProfitStyle.css" />

	<script src="../moment.min.js"></script>


	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		var direction = 'desc';
		
		const customerID 				= <% =customerID %>;
		const centile 					= <% =centile %>;
		const decile					= <% =decile %>;
		const ninetyNine				= <% =ninetyNine %>;
		const profitability 			= <% =profitability %>;
		const accountHolderGrade 	= <% =accountHolderGrade %>;
		const flagID					= <% =flagID %>;
		const allStar					= <% =allStar %>;
		const cProfitURL				= '<% =cProfitURL %>';
		const cProfitApiKey			= '<% =cProfitApiKey %>';

		var drillDownParms = {
			account: <% =account %>,
			accountHolder: <% =accountHolder %>,
			branch: <% =branch %>,
			officer: <% =officer %>,
			product: <% =product %>,
		}
		
		window.addEventListener('load', function() {

			window.onkeyup = function(e) {
				if ( e.keyCode === 27 ) {
					$('.context-menu').removeClass('context-menu--active').off();
				}
			}
			
			document.addEventListener('click', function() {
				$('.context-menu').removeClass('context-menu--active').off();
			});
										
						
		});
		
		
		$(document).ready(function() {

			$( document ).tooltip();
			
			$( '#dialog-comments' ).dialog({
				autoOpen: false,
				modal: false,
				height: 450,
				resizable: false,
				open: function () {
					$( '#newComment' ).focus();
				},
				width: 650,
				buttons: [
					{
						text: 'Save',
						disabled: true,
						click: function() {

							SaveAccountHolderComment(this)

						}
					},
					{
						text: 'Cancel',
						autoFocus: false,
						click: function() {
							$( this ).dialog('close');
						}
					}
				]
			});
			
			
			$( '#dialog-addFlag' ).dialog({
				autoOpen: false,
				modal: true,
				height: 'auto',
				resizable: false,
				buttons: [
					{
						text: 'Save',
// 						autoFocus: true,
						click: function() {
							$(this).dialog('close');
						}
					},
					{
						text: 'Cancel',
// 						autoFocus: true,
						click: function() {
							$(this).dialog('close');
						}
					}
				]
			});


			$( '#dialog-context' ).dialog({
				autoOpen: false,
				modal: true,
				height: 'auto',
				resizable: false,
				width: 300,
			});

			
			$( '#dialog-flags' ).dialog({
				resizable: false,
				height: 'auto',
				autoOpen: false,
				modal: true,
				buttons: [
					<% if userPermitted(124) then %>
					{
						text: 'Manage Flags',
						disabled: false,
						autoFocus: false,
						click: function() {
							
							window.location.href = '\accountHolderFlagList.asp?customerID=<% =customerID %>';

						}
					},
					<% end if %>
					{
						text: 'Close',
						autoFocus: true,
						click: function() {
							$(this).dialog('close');
						}
					}
				]
			});


			$( '#dialog-confirm' ).dialog({
				resizable: false,
				height: 'auto',
				width: 650,
				autoOpen: false,
				modal: true,
				buttons: [
					{
						text: 'Update Firmographics',
						click: function() {
							const ahn = $( '#ahn' ).val();
							window.location.href = '\customerTop100Survey.asp?customerID=<% =customerID %>&accountHolder='+ahn+'&surveyType=1';
						}
					},
					{
						text: 'Update Psychographics',
						click: function() {
							const ahn = $( '#ahn' ).val();
							window.location.href = '\customerTop100Survey.asp?customerID=<% =customerID %>&accountHolder='+ahn+'&surveyType=2';
						}
					},
					{
						text: 'Remove from "Top 100"',
						click: function() {
							$(this).dialog('close');
							const accountHolderNumber = $('#dialog-confirm').data('clickedOn').closest('tr').id;
							RemoveTargetIndicator(accountHolderNumber);
						}
					},
					{
						text: 'Cancel',
						autoFocus: true,
						class: 'cancel',
						click: function() {
							$(this).dialog('close');
						},
					}
				]
				
			});


			var table = $('#cNoteTableTop')
			
				.on( 'draw.dt', function() {

					GetAllAccountHoldersInDatatable(table,customerID);

					var cNoteMoney = $('.cNoteMoney');
					if ( cNoteMoney ) {
						for (i = 0; i < cNoteMoney.length; ++i) {
							MakeNegativeValueRed(cNoteMoney[i]);
						}
					}
					
					
				})

				.on( 'mouseover', 'td.flag, td.target, td.note', function() {
					ToggleAddButton(this);
				})

				.on( 'mouseout', 'td.flag, td.target, td.note', function() {
					ToggleAddButton(this);
				})

				.on( 'click', 'button.target', function(e) {
					
					e.preventDefault();
					e.stopPropagation();
					$( '#ui-dialog-content' ).dialog('close');

					ToggleTargetIndicator(this);
					
				})
				
				.on( 'click', 'button.flag', function(e) {

					e.preventDefault();
					e.stopPropagation();
					
					// close all open dialogs...
					$( '#ui-dialog-content' ).dialog('close');

					// open this dialog...
					$( '#dialog-flags' ).dialog('option', 'position', { my: 'left top', at: 'left bottom', of: this });
					$( '#dialog-flags' ).data('clickedOn', this).dialog('open');

					// populate this dialog...
					GetAccountHolderFlags(this);
					

				})

				.on( 'click', 'button.note', function(e) {

					e.preventDefault();
					e.stopPropagation();
					$( '#ui-dialog-content' ).dialog('close');

					// open this dialog...
					$( '#dialog-comments' ).dialog( 'option', 'position', { my: 'left top', at: 'left bottom', of: this });
// 					$( '#dialog-comments' ).data( 'clickedOn', this ).dialog( 'open' );

					const accountHolderNumber = this.closest( 'tr' ).id;
					GetAccountHolderNotes(accountHolderNumber,e);

					$( '#dialog-comments' ).dialog( 'close' );
					$( '#dialog-comments' ).dialog( 'open' );

					$( '#newComment' ).focus();

				})
				
				.on( 'contextmenu', 'tbody tr', function(e) {
// 					const accountHolder = this.id;
// 					BuildContextMenu( customerID, 'accountHolder', accountHolder, drillDownParms, event  );

					e.preventDefault();
					e.stopPropagation();
					$( '#ui-dialog-content' ).dialog('close');

					const accountHolderNumber = this.id;
				
					$( '#ahn1' ).val(accountHolderNumber);
	
					$( '#dialog-context' ).dialog('option', 'position', { my: 'left top', at: 'left bottom', of: e });
					$( '#dialog-context' ).data('clickedOn', this).dialog('open');
	
					const drillDownLIs = document.querySelectorAll('#dialog-context li');
					for ( i = 0; i < drillDownLIs.length; ++i ) {
						
						drillDownLIs[i].innerHTML = drillDownLIs[i].innerHTML.replace( 'ahn', accountHolderNumber );
						
					}
	
					$( '#dialog-context ul li:first-child a' ).focus();
	
				})
				
				.DataTable({
//					dom parameters:
// 					B - [B]uttons
// 					l - [l]ength changing input control
//						f - [f]iltering input
//						r - p[r]ocessing display element
//						t - the [t]able
//						i - table [i]nformation summary
//						p - [p]agination control
					dom: 'Blrtip',
					buttons: [
						{
							text: 'Toggle Token',
							action: function( e, dt, node, config) {
								if ( dt.column( '.accountHolderToken' ).visible() === true ) {
									dt.column( '.accountHolderToken' ).visible( false );
								} else {
									dt.column( '.accountHolderToken' ).visible( true );
								}
							}
						}
					],
  					paging: true,
					info: true,
					searching: false,
					processing: true,
					serverSide: true,
					stateSave: true,
					ajax: {url: '/cProfit/ajax/accountHolders.asp',
						type: 'post',
						data: {
							customerID: customerID,
							centile: centile,
							decile: decile,
							ninetyNine: ninetyNine,
							profitability: profitability,
							accountHolderGrade: accountHolderGrade,
							flagID: flagID,
							allStar: allStar,
							account: drillDownParms.account,
							accountHolder: drillDownParms.accountHolder,
							branch: drillDownParms.branch,
							officer: drillDownParms.officer,
							product: drillDownParms.product,
						}
					},
					columnDefs: [
						{targets: 'accountHolderToken', 	data: 'accountHolderNumber', 	className: 'accountHolderToken dt-body-left', orderable: false, searchable: false, visible: false },
						{targets: 'accountHolderNumber', data: 'accountHolderNumber', 	className: 'accountHolderNumber dt-body-left', orderable: false, searchable: false },
						{targets: 'accountHolderName',	data: 'accountHolderName',		className: 'accountHolderName dt-body-left', orderable: false, searchable: false, visible: false },
						{targets: 'target',					data: 'target',					className: 'target dt-body-center'},
						{targets: 'flag',						data: 'addenda',					className: 'flag dt-body-center'},
						{targets: 'note',						data: 'note',						className: 'note dt-body-center'},
						{targets: 'accounts',				data: 'accounts', 				className: 'dt-body-right'},
						{targets: 'loans', 					data: 'loans', 					className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'deposits', 				data: 'deposits', 				className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'balance', 				data: 'balance', 					className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'profit', 					data: 'profit', 					className: 'cNoteMoney dt-body-right', type: 'num-fmt', render: $.fn.dataTable.render.number(',', '.', 0, '$')},
						{targets: 'grade', 					data: 'grade', 					className: 'dt-body-center'},
						{targets: 'branch', 					data: 'branch', 					className: 'dt-body-left'},
						{targets: 'officer', 				data: 'officer', 					className: 'dt-body-left'}
					],
					order: [[ 10, direction ]]
				});


			});
			
			//------------------------------------------------------------------------>
			async function SaveAccountHolderComment(htmlElement) {
			//------------------------------------------------------------------------>
	
				const notification 			= document.querySelector('.mdl-js-snackbar');
				const customerID				= <% =customerID %>;			
				const accountHolderNumber 	= $( '#dialog-comments' ).find( 'input.accountHolderNumber' ).val();
				const content 					= $( '#newComment	' ).val();
				
				const url 				= 'ajax/accountHolderComments.asp';
				const form 				= 'customerID='+customerID+'&accountHolderNumber='+accountHolderNumber+'&content='+content;
				
				const apiResponse = await fetch(url, {
					method: 'POST',
					headers: {
						'Content-type': 'application/x-www-form-urlencoded'
					},
					body: form
				});
	
				if ( apiResponse.status != 200 ) {
					return generateErrorResponse('failed to save comment. Status: ' + apiResponse.status);
				}						
				
				var apiResult = await apiResponse.json();
				
				if ( apiResult.msg ) {
	
					const newComment = $( '#newComment' );
					const updatedWhen = moment().fromNow();
	
					var comment	= 	'<div class="commentContainer" data-commentID="'+apiResult.newID+'">'
										+	'<div class="header">'
											+ 	'<div class="upatedBy"><b><% =session("firstName") & " " & session("lastName") %></b></div>'
											+ 	'<div class="updatedWhen">'+updatedWhen+'</div>'
											+	'<div class="material-icons delete">delete</div>'
										+	'</div>'
										+	'<div class="detail">'
											+	'<div class="comment">'+content+'</div>'
										+	'</div>'
									+	'</div>'
									+	'<hr>';
	
					$( comment ).insertBefore( newComment );
					$( newComment ).val('');
					
					const targetRow = $( '#'+accountHolderNumber ).find( 'td.note' ).html( '<button class="mdl-button mdl-js-button mdl-button--icon note"><i class="material-icons">notes</i></button>' );
	
	
					const notification = document.querySelector( '.mdl-js-snackbar' );
					notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
	
				}
			}
			//------------------------------------------------------------------------>

		
			//------------------------------------------------------------------------>
			async function GetAccountHolderNotes(accountHolderNumber) {
			//------------------------------------------------------------------------>
				
				const notification = document.querySelector('.mdl-js-snackbar');
				const	apiResponse = await fetch('/cProfit/ajax/accountHolderComments.asp?customerID='+customerID+'&accountHolderNumber='+accountHolderNumber);
				
				if ( apiResponse.status != 200 ) {
					return generateErrorResponse('failed to get account holder comments. Status: ' + apiResponse.status);
				}						
				
				var apiResult = await apiResponse.json();
				const commentList = $( '#commentList' );
				commentList.empty();
				
				$( '#dialog-comments' ).find( 'input.accountHolderNumber' ).val( accountHolderNumber );
				
	
				for ( i = 0; i < apiResult.data.length; ++i ) {
	
					var updatedWhen = moment(apiResult.data[i].updatedDateTime).fromNow();
					
					var comment	= 	'<div class="commentContainer" data-commentID="'+apiResult.data[i].DT_RowId+'">'
										+	'<div class="header">'
											+ 	'<div class="upatedBy"><b>'+apiResult.data[i].updatedBy+'</b></div>'
											+ 	'<div class="updatedWhen">'+updatedWhen+'</div>'
											+	'<div class="material-icons delete">delete</div>'
										+	'</div>'
										+	'<div class="detail">'
											+	'<div class="comment">'+apiResult.data[i].content+'</div>'
										+	'</div>'
									+	'</div>'
									+	'<hr>';
	
					commentList.append( comment );
	
				}
	
				commentList.append( '<textarea id="newComment" class="newComment" style="width: 99%; font-size: 13px;" rows= "4" placeholder="Add a comment..." ></textarea>' )
				
				commentList.scrollTop(commentList[0].scrollHeight);
				
				const headers = document.querySelectorAll( 'div.commentContainer' );
				if ( headers ) {
					for ( i = 0; i < headers.length; ++i ) {
	
						headers[i].addEventListener('mouseover', function() {
							this.querySelector('div.delete').style.visibility = 'visible';
						});
	
						headers[i].addEventListener('mouseout', function() {
							this.querySelector('div.delete').style.visibility = 'hidden';
						});
						
						headers[i].querySelector( 'div.delete' ).addEventListener('click', function() {
							DeleteAccountHolderComment(this);
						});
	
					}
				}
	
				const textarea = document.querySelector( '#dialog-comments textarea' );
				if ( textarea ) {
					textarea.addEventListener('input', function() {
						
						const dialog = this.closest( 'div.ui-dialog' );
						const button = dialog.querySelector( 'button.ui-button-disabled' );
						
						$ ( button ).button( 'enable' );	
			
					})
				}
	
			}	
			//------------------------------------------------------------------------>

		
			//------------------------------------------------------------------------>
			async function DeleteAccountHolderComment(htmlElement) {
			//------------------------------------------------------------------------>
				
				if ( confirm( 'Are you sure you want to delete this comment? This action cannot be undone.' ) ) {
					
					const commentID 				= htmlElement.closest( 'DIV.commentContainer' ).getAttribute( 'data-commentID' );
					const customerID 				= <% =customerID %>;
					const accountHolderNumber 	= $( '#dialog-comments' ).find( 'input.accountHolderNumber' ).val();
					
					const notification 	= document.querySelector('.mdl-js-snackbar');
					const url 				= 'ajax/accountHolderComments.asp';
					const form 				= 'customerID='+customerID+'&accountHolderNumber='+accountHolderNumber+'&commentID='+commentID;
					
					const apiResponse = await fetch(url, {
						method: 'DELETE',
						headers: {
							'Content-type': 'application/x-www-form-urlencoded'
						},
						body: form
					});
					
					if ( apiResponse.status != 200 ) {
						return generateErrorResponse( 'Failed to delete account holder comment, status: ' + apiResponse.status );
					}
					
					var apiResult = await apiResponse.json();
					
					if ( apiResult.msg ) {
	
						$( '[data-commentID="'+commentID+'"]' ).next().remove();
						$( '[data-commentID="'+commentID+'"]' ).remove();
	
						const notification = document.querySelector( '.mdl-js-snackbar' );
						notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
					}
	
					if ( $( 'div.commentContainer' ).length <= 0 ) {
					
						$( '#'+accountHolderNumber ).find( 'td.note' ).html( '<button class="mdl-button mdl-js-button mdl-button--icon add"><i class="material-icons">add</i></button>' );
	
						
					}
	
					
				} else {
					
					return false;
					
				}
				
			}
			//------------------------------------------------------------------------>

			
			//------------------------------------------------------------------------>
			async function RemoveTargetIndicator(accountHolderNumber) {
			//------------------------------------------------------------------------>
	
				const notification = document.querySelector('.mdl-js-snackbar');
				const apiResponse = await fetch('/cProfit/ajax/toggleAccountHolderStar.asp?customerID='+customerID+'&accountHolderNumber='+accountHolderNumber);
				
				if (apiResponse.status != 200) {
					return generateErrorResponse('failed to toggle account holder star indicator, ' + apiResponse.status);
				}
				
				var apiResult = await apiResponse.json();
	
				var dtTable = $('#cNoteTableTop').DataTable();			
				
				message = 'Top 100 removed';
				dtTable.cell('#'+accountHolderNumber, '.target').data(
					'<button class="mdl-button mdl-js-button mdl-button--icon target add" style="font-size: 24px;"><i class="material-icons">add</i></button>'
					);
	
				notification.MaterialSnackbar.showSnackbar({message: message});
	
			}
			//------------------------------------------------------------------------>


			//------------------------------------------------------------------------>
			async function GetAccountHolderFlags(htmlElement) {
			//------------------------------------------------------------------------>
	
				const accountHolderNumber = htmlElement.closest( 'TR ').id;
				const notification = document.querySelector('.mdl-js-snackbar');
	
				const apiResponse = await fetch('/cProfit/ajax/accountHolderFlags.asp?customerID='+customerID+'&accountHolderNumber='+accountHolderNumber);
				
				if ( apiResponse.status != 200 ) {
					return generateErrorResponse('Failed to get account holder flags, ' + apiResponse.status);
				}			
				
				var apiResult = await apiResponse.json();
				
				$( '#ahn-flags' ).val(accountHolderNumber);
	
				$( 'ul.flags' ).empty();			
				for ( i = 0; i < apiResult.data.length; ++i ) {
	
	
					var li 	= 	'<li>'
									+ '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="'+apiResult.data[i].DT_RowId+'">'
										+ '<input type="checkbox" id="'+apiResult.data[i].DT_RowId+'" class="mdl-checkbox__input" '+ apiResult.data[i].checked +'>'
										+ '<span class="mdl-checkbox__label"><i class="material-icons" style="color: '+apiResult.data[i].flagColor+'; vertical-align: middle;">flag</i>' + apiResult.data[i].flagName + '</span>'
									+ '</label>'
								+	'</li>';
										
					$( 'ul.flags' ).append( li );
	
				}
				
				componentHandler.upgradeAllRegistered();
	
				// add onClick eventHandlers for the checkboxes...
				$( 'ul.flags > li input[type=checkbox]' ).on('click', function() {
	
					const accountHolderNumber = this.closest('div.ui-dialog-content').querySelector('#ahn-flags').value;
					const flagID = this.id;
	
					UpdateAccountHolderFlag(accountHolderNumber, <% =customerID %>, flagID);
					
					// determine what to show on the main DataTable...
					const UL = this.closest('UL');
					const LIs = UL.querySelectorAll('LI');
					
					var liContent 	= '<button class="mdl-button mdl-js-button mdl-button--icon flag add"><i class="material-icons">add</i></button>';
	
	
					if ( LIs ) {
						for ( i = 0; i < LIs.length; ++i ) {
							if ( LIs[i].querySelector('input').checked ) {
								const flagColor = LIs[i].querySelector('i').style.color;
								liContent = '<button class="mdl-button mdl-js-button mdl-button-icon flag" style="color: '+flagColor+'"><i class="material-icons">flag</i></button>';
								break;
							}
						}
					}
					
					// update the flag shown on the DataTable...
					const row = document.getElementById(accountHolderNumber);
					var cell = row.querySelector('.flag');
					cell.innerHTML = liContent;
	
				});
	
			}
			//------------------------------------------------------------------------>


			//------------------------------------------------------------------------>
			async function ToggleTargetIndicator(htmlElement) {
			//------------------------------------------------------------------------>
				
				if ( htmlElement.classList.contains('add') ) {			
				
					const accountHolderNumber = htmlElement.closest('tr').id;
					const notification = document.querySelector('.mdl-js-snackbar');
					const apiResponse = await fetch('/cProfit/ajax/toggleAccountHolderStar.asp?customerID='+customerID+'&accountHolderNumber='+accountHolderNumber);
					
					if (apiResponse.status != 200) {
						return generateErrorResponse('failed to toggle account holder star indicator, ' + apiResponse.status);
					}
					
					var apiResult = await apiResponse.json();
		
					var domTable = htmlElement.closest('TABLE');
					var dtTable = $(domTable).DataTable();			
					
					message = 'Top 100 added';
					dtTable.cell('#'+accountHolderNumber, '.target').data(
						'<button class="mdl-button mdl-js-button target" style="font-size: 24px;">&#128175;</button>'
						);
		
					notification.MaterialSnackbar.showSnackbar({message: message});
	
				} else {
					
					const accountHolderNumber = htmlElement.closest('TR').id;
					
					$( '#ahn' ).val(accountHolderNumber);
	
					$( '#dialog-confirm' ).dialog('option', 'position', { my: 'left top', at: 'left bottom', of: htmlElement });
					$( '#dialog-confirm' ).data('clickedOn', htmlElement).dialog('open');
	
					$(	'#dialog-confirm').closest('div.ui-dialog').first('button.cancel').focus();
					
				}
					
			}
			//------------------------------------------------------------------------>


			//------------------------------------------------------------------------>
			function ToggleAddButton( tdElement ) {
			//------------------------------------------------------------------------>
				
				var addButton = tdElement.querySelector('button.add');
				if ( addButton ) {
					if ( addButton.style.visibility == 'visible' ) {
						addButton.style.visibility = 'hidden';
					} else {
						addButton.style.visibility = 'visible';
					}
				}
				
			}
			//------------------------------------------------------------------------>
		

	</script>

	<style>
		

		div.header {
			display: grid;
			grid-template-columns: 10fr 10fr 1fr;
			grid-gap: 1px;
		}
		
/*
		div.detail i {
			float: right;
			vertical-align: middle;
		}
		
*/
		

		
		button.add {
			visibility: hidden;
		}
		
		#dialog-context ul, #dialog-flags ul {
			list-style: none;
			padding-left: 0px;
		}
		
		
		div.updatedBy {
			float: left;
			font-weight: bold;
			vertical-align: middle;
		}
		
		div.updatedWhen {
			float: right;
			font-weight: bold;
			vertical-align: middle;
			text-align: right;
		}
		
		div.delete {
			vertical-align: middle;
			text-align: right;
			visibility: hidden;
		}
		


		div.commentListContainer {
			overflow: hidden;
		}
		
		div.commentList {
			height: 100%;
			max-height: 50%;
			overflow-y: scroll;
		}
		
		div.dataTables_length {
			margin-left: 10px;
		}
		
		
	</style>
	
</head>

<body>

<div id="dialog-comments" title="Account Holder Comments">
	<input class="accountHolderNumber" type="hidden">
	<div class="commentListContainer">
		<div id="commentList"></div>
	</div>
</div>	

<div id="dialog-confirm" title="What would you like to do?">
	<input id="ahn" type="hidden">
  <p><span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>You can update firmographics, update psychographics, or remove this account holder from the "Top100" list.</p>
</div>


<div id="dialog-flags" title="Select flags for this account holder">
	<input id="ahn-flags" type="hidden">
	<ul class="flags">
	</ul>
</div>


<div id="dialog-context" title="What would you like to drill into?">
	<input id="ahn1" type="hidden">
	<ul>
		<li><a href="/cProfit/accountSummary.asp?customerID=<% =customerID %>&accountHolder=ahn">Accounts...</a></li>
		<li><a href="/cProfit/accountHolderSummary.asp?customerID=<% =customerID %>&accountHolder=ahn">Account Holders...</a></li>
		<li><a href="/cProfit/branchSummary.asp?customerID=<% =customerID %>&accountHolder=ahn">Branches...</a></li>
		<li><a href="/cProfit/officerSummary.asp?customerID=<% =customerID %>&accountHolder=ahn">Officers...</a></li>
		<li><a href="/cProfit/productSummary.asp?customerID=<% =customerID %>&accountHolder=ahn">Products...</a></li>
	</ul>
</div>



<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
	<header class="mdl-layout__header fh-fixedHeader">
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



			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--9-col reportTitle">Account Holder Summary<br><% =subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--11-col mdl-shadow--2dp" style="padding: 15px;">

					<table id="cNoteTableTop" class="compact display">
						<thead>
							<tr>
								<th class="accountHolderToken">Token</th>
								<th class="accountHolderNumber">Account Holder</th>
								<th class="accountHolderName">Account Holder Name</th>
								<th class="target"><span style='font-size:24px;'>&#128175;</span></th>
								<th class="flag"><i class="material-icons">flag</i></th>
								<th class="note"><i class="material-icons">comment</i></th>
								<th class="accounts">Accts</th>
								<th class="loans">Loans</th>
								<th class="deposits">Deposits</th>
								<th class="balance">Balance</th>
								<th class="profit">Profit</th>
								<th class="grade">Grade</th>
								<th class="branch">Branch</th>
								<th class="officer">Officer</th>
							</tr>
						</thead>
					</table>

				</div>
		
				<div class="mdl-layout-spacer"></div>
		
			</div>


		</div>

		<!-- #include file="includes/contextMenu.asp" -->
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>