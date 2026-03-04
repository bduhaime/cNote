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
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(5)


title = session("clientID") & " - Customers" 
userLog(title)


SQL = "select * from userCustomers where customerID = 1 and userID = " & session("userID") & " " 
set rsIU = dataconn.execute(SQL)
if not rsIU.eof then 
	internalUser = true 
	session("internalUser") = 1
else
	internalUser = false 
	session("internalUser") = -1
end if
rsIU.close 
set rsIU = nothing 



%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script>
<!--
	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>
-->

	<link rel="stylesheet" href="dialog-polyfill.css" />

	<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
	<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>


	<script src="sha256.min.js"></script>
	<script src="customerEdit.js"></script>

	<script>

		//--------------------------------------------------------------------------------
		function ConfirmCustomerDelete( htmlElement ) {
		//--------------------------------------------------------------------------------

			const row 	= $( htmlElement ).closest('TR');
			const data 	= $( '#tbl_customers' ).DataTable().row( row ).data();
		
			$( '#dialog-confirm' ).find( 'input#id' ).val( data[ 'DT_RowId' ] );
		
			$( '#dialog-confirm' ).dialog( 'open' );
		
		}
		//--------------------------------------------------------------------------------


		//--------------------------------------------------------------------------------
		function ToggleActionIcons( htmlElement ) {
		//--------------------------------------------------------------------------------

			const actionIcons = htmlElement.querySelectorAll( 'td.actions i' );
			
			if ( actionIcons ) {
				for ( var i = 0; i < actionIcons.length; ++i ) {
					if ( actionIcons[i].style.visibility == 'visible' ) {
						actionIcons[i].style.visibility = 'hidden';
					} else {
						actionIcons[i].style.visibility = 'visible';
					}
				}
			}
			
			
		}
		//--------------------------------------------------------------------------------


		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------
			
			$( document ).tooltip();
			$( '#switch-1' ).tooltip();
			
			$("#progressBar").progressbar({
				value: false // Indeterminate state
			});

			$( "#contractStartDate" ).datepicker({
				changeYear: true,
				changeMonth: true,
				onClose: function( dateText ) {

					if ( dateText ) {
						
						if ( !dayjs( dateText ).isValid() ) {
							alert( 'Contract start date is not a valid date' );
							$( this ).focus();
						} else {
							
							const minYear = dayjs( dateText ).year();
							const minMonth = dayjs( dateText ).month();
							const minDate = dayjs( dateText ).date();
							const endMinDate = new Date( minYear, minMonth, minDate );
							$( "#contractEndDate" ).datepicker( "option", "minDate", endMinDate );

							if ( dayjs( $( '#contractEndDate' ).val() ).isValid() ) {
								
								if ( dayjs( dateText ).isAfter( dayjs( $( '#contractEndDate' ).val() ) ) ) {
									alert( 'Contract start date must precede contract end date' );
									$( this ).focus();
								}
								
							} else {
								
								const computedEndDate = dayjs( dateText ).add( 3, 'year' ).format( 'M/D/YYYY' );
								$( '#contractEndDate' ).val( computedEndDate );
								
							}
							
							
						}
						
					}
				}
			});


			$( "#contractEndDate" ).datepicker({
				changeYear: true,
				changeMonth: true,
				onClose: function( dateText ) {

					if ( dateText ) {
						
						if ( !dayjs( dateText ).isValid() ) {
							alert( 'Contract end date is not a valid date' );
							$( this ).focus();
						} else {

							const maxYear = dayjs( dateText ).year();
							const maxMonth = dayjs( dateText ).month();
							const maxDate = dayjs( dateText ).date();
							const startMaxDate = new Date( maxYear, maxMonth, maxDate );
							$( "#contractStartDate" ).datepicker( "option", "maxDate", startMaxDate );
							
							if ( dayjs( $( '#contractStartDate' ).val() ).isValid() ) {
								
								if ( dayjs( dateText ).isBefore( dayjs( $( '#contractStartDate' ).val() ) ) ) {
									alert( 'Contract end date must follow contract start date' );
									$( this ).focus();
								}
								
							}
							
						}
						
					}
				}
			});
			
			
			$( '#form_lsvtCustomerName' ).on( 'change', function() {
				
				if ( this.value ) {
					
					const lsvtCustomerName = this.value;
					
// 					$.get( 'https://webservices.lightspeedvt.net/REST/v1/locations'  )
					
					$.ajax({
						beforeSend: function (xhr) {
						    xhr.setRequestHeader ("Authorization", "Basic " + btoa("6444E140:lsvt"));
						},
						url: 'https://webservices.lightspeedvt.net/REST/v1/locations',
						data: { isActive: true, name: lsvtCustomerName },
						success: function( data ) {
							if ( data.length <= 0 ) {
								$( '#form_lsvtCustomerName' ).parent().addClass( 'is-dirty is-invalid' );
								$( '#form_lsvtCustomerName' ).focus().select();
								alert( 'No matching locations found in Lightspeed VT' );
								return false;
							}
						},
						dataType: 'json'
					});





//					$.get( 'https://webservices.lightspeedvt.net/REST/v1/locations?isActive=true&itemsPerpage=200&page=1&name='+lsvtCustomerName )
					
				}
				
				
			});
			
			
			
			var handle = $( '#custom-handle' );
			$( '#customerGradeID' ).slider({
				value: 0,
				min: 0,
				max: 10,
				step: 1,
				create: function() {
					handle.text( $( this ).slider( 'value' ) );
				},
				slide: function( event, ui ) {
					handle.text( ui.value );
		      }
			});

			const dialog_customerPriority = $( '#dialog_customerPriority' ).dialog({
				autoOpen: false,
				resizable: false,
				height: 'auto',
				width: 350,
				modal: true,
				buttons: {
					Save: function() {
						
						const formData = {
							customerID: $( '#customerID' ).val(),
							customerGradeID: $( '#customerGradeID' ).slider( 'value' ),
							customerGradeNarrative: $( '#customerGradeNarrative' ).val(),
							anomoliesNarrative: $( '#anomoliesNarrative' ).val()
						}
						
						$.ajax({
							type: 'PUT',
							url: `${apiServer}/api/customerPriorities`,
							data: JSON.stringify( formData ),
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							contentType: 'application/json',
							success: function() {
								$( '#dialog_customerPriority' ).dialog( 'close' );
								var notification = document.querySelector('.mdl-js-snackbar');
								notification.MaterialSnackbar.showSnackbar({ message: 'Customer priority updated' });
								table.ajax.reload( null, false );
							},
							error: function( err ) {
								$( '#dialog_customerPriority' ).dialog( 'close' );
								alert( 'error while saving customer priority priority!' );
							}
						})
					},				
					Cancel: function() {
						$( this ).dialog( 'close' );
					}
				}
			});

			var dialog_contractDates = $( '#dialog_contractDates' ).dialog({
				autoOpen: false,
		      resizable: false,
		      height: "auto",
		      width: 350,
		      modal: true,
				buttons: {
					Save: function() {
						
						const formData = {
							customerID: $( this ).data().customerID,
							customerGradeID: $( this ).data().customerGradeID,
							customerGradeNarrative: $( this ).data().customerGradeNarrative
						}
						
						$.ajax({
							type: 'PUT',
							url: `${apiServer}/api/customerContracts/dates`,
							data: JSON.stringify( formData ),
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							contentType: 'application/json',
							success: function() {
								$( '#dialog_contractDates' ).dialog( 'close' );
								var notification = document.querySelector('.mdl-js-snackbar');
								notification.MaterialSnackbar.showSnackbar({ message: 'Contract dates updated' });
								table.ajax.reload( null, false );
							},
							error: function() {
								$( '#dialog_contractDates' ).dialog( 'close' );
								alert( 'error while saving dates!' );
							}
						})
					},				
					Cancel: function() {
						$( this ).dialog( 'close' );
					}
				}				
			});


			$( "#dialog-confirm" ).dialog({
				autoOpen: false,
		      resizable: false,
		      height: "auto",
		      width: 350,
		      modal: true,
		      buttons: {
					"Delete Customer": async function() {

						const form 			= 'id='+$( '#dialog-confirm' ).find( 'input#id' ).val();
						const apiResponse = await fetch( 'ajax/customers.asp', {
							method: 'DELETE',
							headers: { 'Content-type': 'application/x-www-form-urlencoded' },
							body: form 
						})

						if (apiResponse.status !== 200) {
							return generateErrorResponse('Failed to delete customer; ' + apiResponse.status);
						}

						var apiResult = await apiResponse.json();
						
						const notification = $( '.mdl-js-snackbar' ).get(0);		
						notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

						$( '.ui-tooltip-content' ).parents( 'div' ).remove()

						$( this ).dialog( 'close' );
						
						$( '#tbl_customers' ).DataTable().ajax.reload();

		        },
		        Cancel: function() {
		          $( this ).dialog( 'close' );
		        }
		      }
		    });			
			
			
		// Define the autocomplete widget
		$("#institutionsList").autocomplete({

			source: function (request, response) {

				$("#progressBar").show();
				$("#noResultsMessage").hide(); // Hide the message initially
				
				const term = request.term;
				const active = $("#switch-1").is(":checked") ? 1 : 0;
				
				const payload = {
					term: term,
					active: active // Use "active" instead of "actie"
		   	};
		
			   $.ajax({
			       url: `${apiServer}/api/institutions`,
			       method: "GET",
			       headers: { Authorization: "Bearer " + sessionJWT },
			       dataType: "json",
			       data: payload,
			       success: function (data) {
			           console.log("get success");
			           $("#progressBar").hide();
			           
			           response(data);
			       },
			       error: function (err) {
			           console.log(`get error: ${err}`);
			           $("#progressBar").hide();
			           response([]); // Return an empty array on error
			       }
			   });
			},
			response: function (event, ui) {
				
				if (ui.content.length === 0) {
	
	            // Show "No matches found" as a disabled option
					ui.content.push({
					label: "No matches found",
					value: "",
					disabled: true
					});
				}
        
  			},

			select: function (event, ui) {
				// Populate the field with the name instead of the ID
				event.preventDefault(); // Prevent default behavior (populating with value)
				if ( ui.item.value === '' ) {				
					$("#institutionsList").val( '' ); // Set the input to the name
				} else {
					$("#institutionsList").val(ui.item.label); // Set the input to the name
				}
			},

			minLength: 3,			
			delay: 300
		});



			var table = $( '#tbl_customers' )
				.on( 'click', 'tbody > tr', function(event) {
					var customerID = this.id;
					window.location.href = 'customerOverview.asp?id='+customerID;
				})
				.on( 'click', 'i.contracts', function( event ) {
					event.stopPropagation();
					var customerID = this.closest( 'tr' ).id;
					window.location.href = '/customerContracts.asp?id='+customerID;
				})
				.on( 'click', 'i.customerGrade', function( event) {
					event.stopPropagation();
					
					// populate the slider and its custom handle...
					const customerID = $( this ).closest( 'tr' ).attr( 'id' );
					$( '#customerID' ).val( customerID );
					
					const handle = $( '#custom-handle' );
					const customerGradeID = $( '#tbl_customers' ).DataTable().row( $(this).closest('tr') ).data().customerGradeID;
					const valueToShow = customerGradeID ? customerGradeID : 0;
					handle.text( valueToShow );
					$( '#customerGradeID' ).slider( 'value', valueToShow );
					
					// populate the grade/status narrative <textarea>
					const customerGradeNarrative = $( '#tbl_customers' ).DataTable().row( $(this).closest('tr') ).data().customerGradeNarrative;
					$( '#customerGradeNarrative' ).val( customerGradeNarrative );
					
					// populate the anomolies narrative <textarea>
					const anomoliesNarrative = $( '#tbl_customers' ).DataTable().row( $(this).closest('tr') ).data().anomoliesNarrative;
					$( '#anomoliesNarrative' ).val( anomoliesNarrative );
					
					
					$( '#dialog_customerPriority' ).dialog( 'open' );
				})
				.on( 'click', 'i.edit', function( event ) {
					event.stopPropagation();
					EditCustomer_onClick( this );					
				})
				.on( 'click', 'i.delete', function( event ) {
					event.stopPropagation();
					ConfirmCustomerDelete( this );
				})
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'mouseout', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/customers`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					scrollY: 630,
					deferRender: true,
					scroller: { rowHeight: 35 },
					scrollCollapse: true,
					columnDefs: [
						{targets: 'name', 					data: 'name', 					className: 'name dt-body-left dt-head-left' },
						{targets: 'rssdID', 					data: 'rssdID', 				className: 'rssdID dt-body-center dt-head-center' },
						{targets: 'cert', 					data: 'cert', 					className: 'cert dt-body-center dt-head-center' },
						{targets: 'city', 					data: 'city',					className: 'city dt-body-left dt-head-left' },
						{targets: 'stalp', 					data: 'stalp',					className: 'stalp dt-body-center dt-head-center' },
						{targets: 'status', 					data: 'status', 				className: 'status dt-body-center dt-head-center' },
						{
							targets: 'validDomains', 		
							data: 'validDomains', 	
							className: 'validDomains dt-body-center dt-head-center',
							defaultContent: '',
							render: function( data, type, row ) {
								if ( data.length > 0 ) {
									return '<i class="material-symbols-outlined" title="' + data + '">language</i>';
								} 
							}
						},

						{
							targets: 'actions', 	
							data: null,			
							orderable: false, 
							className: 'actions dt-body-center dt-head-center',
							defaultContent: '',
							render: function( data, type, row ) {

								let actions = '';
								if ( data.userPermissions.status ) actions += '<i class="material-symbols-outlined customerGrade" title="View/Edit customer prioritization">outlined_flag</i>';
								if ( data.userPermissions.delete ) actions += '<i class="material-symbols-outlined delete" title="Delete customer">delete_outline</i>';
								if ( data.userPermissions.edit ) actions += '<i class="material-symbols-outlined edit" title="Edit customer">mode_edit</i>';
								
								return actions;
								
							}
						},

  						{targets: 'nickName', 						data: 'nickname', 						visible: false },
						{targets: 'cProfitApiKey', 				data: 'cProfitApiKey', 					visible: false },
						{targets: 'cProfitURI', 					data: 'cProfitURI', 						visible: false },
						{targets: 'lsvtCustomerName', 			data: 'lsvtCustomerName', 				visible: false },
						{targets: 'secretShopperLocationName', data: 'secretShopperLocationName', 				visible: false },
						{targets: 'customerGradeID', 				data: 'customerGradeID', 				visible: false },
						{targets: 'customerGradeNarrative', 	data: 'customerGradeNarrative', 		visible: false, searchable: false },
						{targets: 'anomoliesNarrative', 			data: 'anomoliesNarrative', 			visible: false, searchable: false },
						{targets: 'optOutOfMCCCalls', 			data: 'optOutOfMCCCalls', 				className: 'optOutOfMCCCalls', visible: false },
						{targets: 'defaultTimezone', 				data: 'defaultTimezone', 				className: 'defaultTimezone', visible: false },
					],
					search: {search: 'Active'}
				});




			// ****************************************************************************************/
			// Add Event Listener for Dialog SAVE button
			// ****************************************************************************************/
			
			$( '#dialog_addCustomer' ).find( '.save' ).on( 'click', function() {
	
				const customerID 			= $( '#form_customerID' ).val();
				const institutionInd 	= $( '#fdic' ).prop( 'checked' );
				const statusID				= $( '#form_customerStatus' ).val();
				const nickname				= $( '#form_nickname' ).val();
				const validDomains		= $( '#form_validDomains' ).val();
				const optOutOfMCCCalls	= $( '#optOutOfMCCCalls' ).is( ':checked' );
				const defaultTimezone	= $( '#form_defaultTimezone' ).val();
				
				if ( institutionInd ) {
					
					if ( $( '#form_customerName' ).val() ) {

						customerName = $( '#form_customerName' ).val();

					} else {
						
						hyphenAt = $( '#institutionsList' ).val().indexOf( '-' );
						commaAt = $( '#institutionsList' ).val().lastIndexOf( ',' );
						
						customerName 	= $( '#institutionsList' ).val().substring( 0, hyphenAt - 1 );
						city				= $( '#institutionsList' ).val().substring( hyphenAt + 2, commaAt ); 
						state				= $( '#institutionsList' ).val().substr( commaAt + 2, 2 ); 

					}
					
					
				} else {
					customerName = $( '#form_customerName' ).val();
					city				= '';
					state				= '';
				}
				
				
				let methodType, successMsg;
				let data = {};
				
				if ( customerID ) {

					methodType = 'PUT';		// update

					data = {
						institutionInd: institutionInd,
						customerID: customerID,
						customerName: customerName,
						nickname: nickname,
						statusID: statusID,
						validDomains: validDomains,
						lsvtCustomerName: $( '#form_lsvtCustomerName' ).val(),
						cProfitURI: $( '#form_cProfitURI' ).val(),
						cProfitAPIKey: $( '#form_cProfitAPIKey' ).val(),
						optOutOfMCCCalls: optOutOfMCCCalls,
// 						secretShopperLocationName: $( '#form_secretShopperLocationName' ).val().trim(),
						defaultTimezone: defaultTimezone,
					}
					
					successMsg = 'Customer updated';
					
				} else {
					
					methodType = 'POST';		// insert
					
					data = {
						institutionInd: institutionInd,
						customerName: customerName,
						statusID: statusID,
						nickname: nickname,
						validDomains: validDomains,
						city: city,
						state: state,
						optOutOfMCCCalls: optOutOfMCCCalls,
						defaultTimezone: defaultTimezone,
					}
					
					successMsg = "Customer added"

				}
				
				$.ajax({
					type: methodType,
					url: `${apiServer}/api/customers`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: data,
				}).done( function() {
					const notification = document.querySelector('.mdl-js-snackbar');
					notification.MaterialSnackbar.showSnackbar({ message: successMsg });
					table.ajax.reload( null, false );
				}).fail( function() {
					console.log( 'an error occurred while updating/inserting customer' );
				}).always( function () {
					dialog_addCustomer.close();
				})


				
				
			}) //end of callback


			
		    // Listen for toggle change
		    $("#switch-1").on("change", function () {
		        // Trigger autocomplete search with the current value
		        const currentValue = $("#institutionsList").val(); // Get current input value
		        $("#institutionsList").autocomplete("search", currentValue);
		    });
		


			// ****************************************************************************************/
			// Add Event Listener for New Customer button
			// ****************************************************************************************/
			
			var button_newCustomer = document.querySelector('#button_newCustomer');
			if (button_newCustomer) {
				button_newCustomer.addEventListener('click', function() {
					CustomerAdd_onClick();
				});
			}
			
			$( '#form_cProfitURI' ).on( 'keyup', function() {

				if ( $( this ).val() ) {
					
					$.ajax({
						type: 'PUT',
						url: `${apiServer}/api/customers/cprofitAccessInfo`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						data: { 
							customerID: $( '#form_customerID' ).val(), 
							cProfitURL: $( this ).val() 
						}
					}).done( function( res ) {
						$( '#form_cProfitAPIKey' ).val( res.apiKey );
					}).fail( function() {
						console.error( 'Error while generating new API key' );
					})
					
				} else {
					
					$( '#form_cProfitAPIKey' ).val( '' );
					
				}

			});
		


		} );
		
		
	</script>
	
	<style>

		/* for jQuery UI */
		label, input { display:block; }
		input.text { margin-bottom:12px; width:95%; padding: .4em; }
		fieldset { padding:0; border:0; margin-top:25px; }
		h1 { font-size: 1.2em; margin: .6em 0; }
		div#users-contain { width: 350px; margin: 20px 0; }
		div#users-contain table { margin: 1em 0; border-collapse: collapse; width: 100%; }
		div#users-contain table td, div#users-contain table th { border: 1px solid #eee; padding: .6em 10px; text-align: left; }
		.ui-dialog .ui-state-error { padding: .3em; }
		.validateTips { border: 1px solid transparent; padding: 0.3em; }

		.ui-autocomplete {
			max-height: 400px;
			overflow-y: auto;
			/* prevent horizontal scrollbar */
			overflow-x: hidden;
		}


		.ui-menu-item-wrapper[aria-disabled="true"] {
			color: #999;
			font-style: italic;
		}

			/* END for jQuery UI */
		
		input.contractDate {
			width: 100px;
		}
		
		table.contractDates {
			margin-left: auto;
			margin-right: auto;
		}
		
		table.contractDates td {
			padding: 10px;
		}
		
		table.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
		i.delete, i.edit, i.customerGrade, i.editDates {
			visibility: hidden;
		}
		
		textarea.customerGradeNarrative {
			width: 98%;
		}
		
		label.dialogLabel {
			font-weight: bold;
		}

		#custom-handle {
			width: 3em;
			height: 1.6em;
			top: 50%;
			margin-top: -.8em;
			text-align: center;
		}		
		
		#customerGradeID {
			width: 80%;
			text-align: center; 
			position: relative; 
			margin: 0 auto;
		}
		
		#customerGradeNarrative, #anomoliesNarrative {
			width: 98%;
		}
		

		
	</style>

</head>
	
<body>

		
	
<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">

    <div id="tbl_customerList" class="page-content">
    <!-- Your content goes here -->
    
		<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>


		<!-- Customer Priority Dialog -->
		<div id="dialog_customerPriority" title="Customer Alert / Anomolies" style="position: relative; display: none;">

			<br>

			<label for="customerGradeID" class="dialogLabel">Alert Level</label>
			<div id="customerGradeID">
				<div id="custom-handle" class="ui-slider-handle"></div>
			</div>

			<br>

			<label for="customerGradeNarrative" class="dialogLabel">Alert Comments</label>
			<textarea id="customerGradeNarrative" class="text ui-widget-content ui-corner-all" rows="5"></textarea>
			
			<br>

			<label for="anomoliesNarrative" class="dialogLabel">Anomolies</label>
			<textarea id="anomoliesNarrative" class="text ui-widget-content ui-corner-all" rows="5"></textarea>
			

			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
			
			<input type="hidden" id="customerID">
			
		</div>



	
	
		<!-- Confirm DELETE Dialog -->
		<div id="dialog-confirm" style="display: none;" title="Delete the customer?">
			<p><span class="ui-icon ui-icon-alert" style="float:left; margin:12px 12px 20px 0;"></span>The customer will be deleted and can only be recovered by a system administrator.<br><br>Are you sure?</p>
			<input type="hidden" name="id" id="id">
		</div>
	

		<!-- DIALOG: Add/Edit Customer -->
		<dialog id="dialog_addCustomer" class="mdl-dialog" style="width: 750px;">
			<h4 id="formTitle" class="mdl-dialog__title">New Customer</h4>
			<div class="mdl-dialog__content">

				<form id="form_customer">
						
					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="fdic">
					  <input type="radio" id="fdic" class="mdl-radio__button" name="fdicInd" value="1" onclick="InstitutionSwitch_onClick(this)">
					  <span class="mdl-radio__label">FDIC Institution</span>
					</label>
					<br>
					<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="nonFdic">
					  <input type="radio" id="nonFdic" class="mdl-radio__button" name="fdicInd" value="2" onclick="InstitutionSwitch_onClick(this)">
					  <span class="mdl-radio__label">Non FDIC Institution</span>
					</label>					
					
					<br><br>
					
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
					    <input class="mdl-textfield__input apiKeyComponent" type="text" id="form_customerName" value="" autocomplete="off"  title="test">
					    <label class="mdl-textfield__label" for="form_customerName">Customer name...</label>
					</div>


					<div id="institutionsGroup" style="display: inline-block; width: 100%; white-space: nowrap;">
						<!-- Input Field -->
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: inline-block; width: 80%;">
							<input class="mdl-textfield__input" type="text" id="institutionsList" />
							<label class="mdl-textfield__label" for="institutionsList">Institutions (start typing to search, min. 3 characters)...</label>
							<div id="progressBar" style="display: none; width: 100%;"></div>
							<div id="noResultsMessage" style="display: none; color: red;">No matches found</div>
						</div>
					
						<!-- Switch -->
						<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="switch-1" style="display: inline-block; margin-left: 16px; vertical-align: middle;" title="Toggle to include all institutions">
							<input type="checkbox" id="switch-1" class="mdl-switch__input" checked >
							<span class="mdl-switch__label">Active only</span>
						</label>
					    
					</div>
					
					
					<!-- Status -->
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
						<select class="mdl-textfield__input apiKeyComponent" id="form_customerStatus">
							<option></option>
							<%
							SQL = "select id, name " &_
									"from customerStatus " &_
									"where (active = 1 or active is null) " &_
									"and (deleted = 0 or deleted is null) " &_
									"order by name " 
							dbug(SQL)
							set rsStatus = dataconn.execute(SQL)
							while not rsStatus.eof 
								response.write("<option value=""" & rsStatus("id") & """>" & rsStatus("name") & "</option>")
								rsStatus.movenext 
							wend
							rsStatus.close
							set rsStatus = nothing
							%>
							</select>
						<label class="mdl-textfield__label" for="form_customerStatus">Status...</label>
						<span class="mdl-textfield__error">Select a status</span>
					</div>
					
					
					<!-- Nickname -->
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none">
					    <input class="mdl-textfield__input apiKeyComponent" type="text" id="form_nickname" value="" maxlength="15" autocomplete="off">
					    <label class="mdl-textfield__label" for="form_nickname">Nickname...</label>
					</div>
	

					<!-- Default Timezone -->
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						<select class="mdl-textfield__input apiKeyComponent" id="form_defaultTimezone">
							<option></option>
							<%
							SQL = "select id, name, fullName " &_
									"from timezones " &_
									"where enabled = 1 " &_
									"order by fullName " 
							dbug(SQL)
							set rsTZ = dataconn.execute(SQL)
							while not rsTZ.eof 
								response.write("<option value=""" & rsTZ("id") & """>" & rsTZ("fullName") & "</option>")
								rsTZ.movenext 
							wend
							rsTZ.close
							set rsTZ = nothing
							%>
							</select>
						<label class="mdl-textfield__label" for="form_defaultTimezone">Default time zone identifier...</label>
						<span class="mdl-textfield__error">Select a time zone identifier</span>
					</div>


					<!-- Valid Domains -->
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 650px; display: none;">
						<textarea class="mdl-textfield__input apiKeyComponent" type="text" rows= "3" id="form_validDomains"></textarea>
						<label class="mdl-textfield__label" for="form_validDomains">Customer domains (separated with a comma)...</label>
					</div>

					<% 
					toggleLSVT = systemControls( "Use LSVT manual location/customer mapping" )
					dbug("toggleLSVT: " & toggleLSVT )
					if toggleLSVT = "false" then 
						if userPermitted(127) then 
							displayLSVT = "block"
						else 
							displayLSVT = "none"
						end if
					else 
						displayLSVT = "none"
					end if
					dbug("displayLSVT: " & displayLSVT)
					%>
					<!-- Lightspeed Customer Name -->
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 650px; display: <% =displayLSVT %>;">
					    <input class="mdl-textfield__input" type="text" id="form_lsvtCustomerName" value="" autocomplete="off">
					    <label class="mdl-textfield__label" for="form_lsvtCustomerName">Lightspeed VT Customer Name...</label>
					     <span id="id_msg" class="mdl-textfield__error">No matching locations found</span>
					</div>


					<% 
					if userPermitted(138) then 
						displaySS = "block"
					else 
						displaySS = "none"
					end if
					%>


					<% 
					if userPermitted( 134 ) then 
						disabled = ""
					else 
						disabled = "disabled" 
					end if 
					%>
					<br>
					<!-- OPt Out of MCC Calls -->					
					<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="optOutOfMCCCalls" />
						<input type="checkbox" id="optOutOfMCCCalls" class="mdl-checkbox__input" <% =disabled %>>
						<span class="mdl-checkbox__label">Customer opts out of MCCs</span>
					</label>
					<br><br>

					<% if userPermitted( 136 ) then %>
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 650px;">
						    <input class="mdl-textfield__input" type="text" id="form_cProfitURI" value="" autocomplete="off">
						    <label class="mdl-textfield__label apiKeyComponent" for="form_cProfitURI">cProfit PII server address...</label>
						</div>
	
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 650px;">
						    <input class="mdl-textfield__input" type="text" id="form_cProfitAPIKey" value="" autocomplete="off" disabled>
						    <label class="mdl-textfield__label" for="form_cProfitAPIKey">cProfit API Key...</label>
						</div>
					<% end if %>

					

					
					<input id="form_customerID" type="hidden" value=""/>
					<input id="form_cert" type="hidden" value=""/>
					
				</form>
				
				
			</div>
			<div id="dialog_buttons" class="mdl-dialog__actions" style="display: none">
				<button type="button" class="mdl-button save">Save</button>
				<button type="button" class="mdl-button cancel">Cancel</button>
			</div>
		</dialog>
  
			
		<!-- New Customer Button -->
   	<div class="mdl-grid" style="padding-bottom: 0px;">
			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--8-col" style="margin-bottom: 0px; position: relative;">
				<% if userPermitted(100) then %>
				<button id="button_newCustomer" 	class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" >
				  New Customer
				</button>
				<% end if %>
			</div>
			
			<div class="mdl-layout-spacer"></div>
		</div>

		<!-- Primary Grid & DataTable -->
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--9-col">
			
				<table id="tbl_customers" class="compact display">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="rssdID">RSSD ID</th>
							<th class="cert">Cert</th>
							<th class="city">City</th>
							<th class="stalp">State</th>
							<th class="status">Status</th>
							<th class="validDomains">Valid<br>Domains</th>
							<th class="lsvtCustomerName">Lightspeed<br>Name</th>
							<th class="secretShopperLocationName">Secret Shopper<br>Location Name</th>
							<th class="actions">Actions</th>
							<th class="nickName">Nick Name</th>
							<th class="cProfitApiKey">Key</th>
							<th class="cProfitURI">URI</th>
							<th class="customerGradeID">Grade</th>
							<th class="customerGradeNarrative">Grade Narrative</th>
							<th class="anomoliesNarrative">anomoliesNarrative</th>
							<th class="optOutOfMCCCalls">optOutOfMCCCalls</th>
							<th class="defaultTimezone">defaultTimezone</th>
 						</tr>
					</thead>
				</table>
				

				</div>
			<div class="mdl-layout-spacer"></div>
			
   	</div>
	
    
  </main>
  <!-- #include file="includes/pageFooter.asp" -->


 <script src="dialog-polyfill.js"></script>  
 <script src="datalist-polyfill.js"></script>  
 <script>
	 
	 var searchField = document.getElementById('search');
	 if (searchField) {
		 searchField.addEventListener('click', function() {
			 this.select();
		 });
	 }
	 
	 	
	// ****************************************************************************************/
	// Register the add/edit dialog
	// ****************************************************************************************/
	
	var dialog_addCustomer = document.querySelector('#dialog_addCustomer');
	if (! dialog_addCustomer.showModal) {
		dialogPolyfill.registerDialog(dialog_addCustomer);
	}
	
	
	// ****************************************************************************************/
	// Add Event Listener for Dialog CANCEL button
	// ****************************************************************************************/
	
	dialog_addCustomer.querySelector('.cancel').addEventListener('click', function() {


		$( '#dialog_addCustomer' ).css( 'width', '750px' );
		
		$( 'input[name="fdicInd"]' ).prop( 'checked', false );
		
		$( '#form_customerID' ).val( '' );
		$( '#institutionsList' ).val( '' );
		$( '#form_customerStatus' ).val( '' );
		$( '#form_nickname' ).val( '' );
		$( '#form_validDomains' ).val( '' );
		$( '#form_defaultTimezone' ).val( '' );
// 		$( '#form_secretShopperLocationName' ).val( '' );
		$( '#form_cProfitURI' ).val( '' );
		$( '#form_cProfitAPIKey' ).val( '' );

		dialog_addCustomer.close();
		
	});
	
		
	// ****************************************************************************************/
	// Add Event Listeners for Row (selecting a customer, toggle edit/delete buttons
	// ****************************************************************************************/
	
	var selectCustomers = document.querySelectorAll('.selectCustomer');
	if (selectCustomers) {
		
		for (i = 0; i < selectCustomers.length; ++i) {

			selectCustomers[i].addEventListener('click', function(event) {
				GoToCustomer(this);
			})

			selectCustomers[i].addEventListener('mouseover', function(event) {
				ToggleActions(this);
			})
			
			selectCustomers[i].addEventListener('mouseout', function(event) {
				ToggleActions(this);
			})
			

		}
		
	}
	
	
	//****************************************************************************************/
	// Add Event Listeners for Delete buttons
	//****************************************************************************************/
	
	var deleteCustomerButtons = document.querySelectorAll('.deleteCustomerButton'), i;
	if (deleteCustomerButtons != null) {
		
		for (i = 0; i < deleteCustomerButtons.length; ++i) {
			deleteCustomerButtons[i].addEventListener('click', function(event) {

				event.stopPropagation()
				CustomerDelete_onClick(this);

			})
		}
		
	}
		
		
  </script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>