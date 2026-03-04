<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(46)
userLog("Customer Intentions Detail")

if len(request.querystring("customerID")) > 0 then
	
	customerID = request.querystring("customerID")
	implementationID = request.querystring("implementationID")
	
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
	sqlCust = 	"select cert, rssdid from customer_view where id = " & customerID & " " 
	dbug(sqlCust)
	set rsCust = dataconn.execute(sqlCust) 
	if not rsCust.eof then 
		customerCert = rsCust("cert")
		customerRSSD = rsCust("rssdid")
	else 
		response.write("customer information is missing")
		response.end()
	end if 

	sqlInst = "select inscoml, inssave, mutual " &_
				 "from fdic.dbo.institutions where cert = " & customerCert & " " 
				 
	dbug("sqlInst: " & sqlInst)
	set rsInst = dataconn.execute(sqlInst)
	if not rsInst.eof then 
		if rsInst("INSCOML") = "1" then 
			dbug("INSCOML = '1', defaultPGT set to 1 ")
			defaultPeerGroupType = 1					' Insured Commercial Bank (by peer group)
		else 
			if rsInst("INSSAVE") = "1" then 
				dbug("INSSAVE = '1'... ")
				if rsInst("MUTUAL") = "00000" then 
					dbug("MUTUAL = '00000'; defaultPGT set to 2 ")
					defaultPeerGroupType = 2			' Insured Savings Banks (by peer group)
				else 
					if rsInst("MUTUAL") = "00001" then 
						dbug("MUTUAL = '00001'; defaultPGT set to 6 ")
						defaultPeerGroupType = 6		' Supplemental Insured Saving Banks
					else 
						dbug("MUTUAL not in ('00000', '00001'); defaultPGT set to '' ")
						defaultPeerGroupType = ""
					end if 
				end if 
			else 
				dbug("INSSAVE <> '1'; defaultPGT set to '' ")
				defaultPeerGroupType = ""
			end if 
		end if
	else 
		dbug("inst not found, defaultPGT set to '' ")
		defaultPeerGroupType = ""
	end if
	
	rsInst.close 
	set rsInst = nothing 
	

	sqlImpl = 	"select * " &_
					"from customerImplementations ci " &_
					"where ci.id = " & implementationID & " "
								
	dbug(sqlImpl)
	set rsImp = dataconn.execute(sqlImpl)

else 
	dbug("'implementationID' value NOT present in request")
	response.end()
end if

dbug("prior to function definitions")
'***********************************************************************************
function metricTypeDescription( internalMetricID, metricType )
'***********************************************************************************
dbug("start of metricTypeDescription")
	if internalMetricID then 
		if metricType = "A" then 
			metricTypeDesc = "Internal - Standard"
		elseif metricType = "B" then
			metricTypeDesc = "Internal - Customer Specific"
		else 
			metricTypeDesc = "Unknown"
		end if
	else 
		metricTypeDesc = "FDIC"
	end if

	
end function
'***********************************************************************************


'***********************************************************************************
function displayObjectiveGoal( startDate, startValue, endDate, endValue, dataType, unitsLabel )
'***********************************************************************************
dbug("start of displayObjectiveGoal")
	if len(startDate) > 0 and len(startValue) > 0 and len(endDate) > 0 and len(endValue) > 0 then

			outputStartDate = formatDateTime(startDate, 2)
			outputEndDate = formatDateTime(endDate, 2)
			
			if len(unitslabel) > 0 then 
				outputUnitsLabel = " (" & unitsLabel & ")"
			else 
				poutputUnitsLabel = ""
			end if 
			
			select case lCase( dataType )
				case "currency"
' 					outputStartValue 	= formatCurrency(startValue, 0)
' 					outputEndValue 	= formatCurrency(endValue, 0)
					outputStartValue 	= "$" & startValue
					outputEndValue		= "$" & endValue
				case "date"
					outputStartValue 	= formatDateTime(startValue, 2)
					outputEndValue 	= formatDateTime(endValue, 2)
				case "number"
					outputStartValue 	= formatNumber(startValue, 1)
					outputEndValue 	= formatNumber(endValue, 1)
				case "percent"
					outputStartValue 	= formatPercent(startValue/100, 3)
					outputEndValue = formatpercent(endValue/100, 3)
				case "y/n"
					outputStartValue 	= startValue 
					outputEndValue 	= endValue 
				case else 
					outputStartValue 	= startValue
					outputEndValue = endValue
			end select 
		
' 			output = "<div>Start Date: " & outputStartDate & ", Start Value: " & outputStartValue & "</div>" &_
' 						"<div>End Date: " & outputEndDate & ", End Value: " & outputEndValue & "</div>"
			output = "<table>" &_
							"<tr>" &_
								"<td><b>Start</b>:</td>" &_
								"<td>" & outputStartDate & "</td>" &_
								"<td><b>Value</b>" & outputUnitsLabel & ":</td>" &_
								"<td>" & outputStartValue & "</td>" &_
							"</tr>" &_
							"<tr>" &_
								"<td><b>End</b>:</td>" &_
								"<td>" & outputEndDate & "</td>" &_
								"<td><b>Value</b>" & outputUnitsLabel & ":</td>" &_
								"<td>" & outputEndValue & "</td>" &_
							"<tr>" &_
						"</table>"
							
	else 
		
		output = "<i>Undefined</i>"

	end if

	displayObjectiveGoal = output 

end function 
'***********************************************************************************

dbug("end of asp function defitions")

%>


<html>

<head>
	
	<!-- #include file="includes/cNoteGlobalStyling.asp" -->
	<!-- #include file="includes/cNoteGlobalScripting.asp" -->


	
	<!-- 	jQuery UI styling -->
	<style>
		
		label, input { display:block; }
		input.text { margin-bottom:12px; width:95%; padding: .4em; }
		fieldset { padding:0; border:0; margin-top:15px; }
		h1 { font-size: 1.2em; margin: .6em 0; }
		div#users-contain { width: 350px; margin: 20px 0; }
		div#users-contain table { margin: 1em 0; border-collapse: collapse; width: 100%; }
		div#users-contain table td, div#users-contain table th { border: 1px solid #eee; padding: .6em 10px; text-align: left; }
		.ui-dialog .ui-state-error { padding: .3em; }
		.validateTips { border: 1px solid transparent; padding: 0.3em; }
		.overflow { height: 200px; }

		.ui-selectmenu-open{ max-height: 350px; overflow-y: scroll; }

		/* correct flicker of tooltips in Google Charts */
		svg > g > g:last-child {pointer-events: none}



	</style>
	
	<!-- 	cNote styling -->
	<style>
		.accordian {
			width: 90%;
			margin: auto;
		}
		
		.accordianInner {
			width: 100%;
			margin: auto;
		}
		
		table.objectiveGoal {
			margin-left: auto;
			margin-right: auto;
			border-collapse: collapse;
		}
		table.objectiveGoal td {
			border: solid black 1px;
			padding: 5px;
			white-space: nowrap;
			font-weight: 100;
		}
		table.objectiveGoal td.label.colHeader {
			width: 50px;
			text-align: center;
			font-weight: bold;
			padding: 5px;
		}
		table.objectiveGoal td.label.rowHeader {
			width: 50px;
			text-align: right;
			font-weight: bold;
			padding: 5px;
		}
		table.objectiveGoal td.date {
			width: 100px;
			text-align: center;
		}
		table.objectiveGoal td.value {
			width: 100px;
			text-align: center;
		}
		table.metric td.label {
			font-weight: bold;
			white-space: nowrap;
			text-align: left;
		}
		table.metric td {
			padding: 2px;
			vertical-align: top;
		}
		
		.formField {
			font-weight: bold;
			margin: 5px;
		}
		
		.mdl-grid {
			padding-top: 0px;
			padding-bottom: 0px;
		}
		
		.customerObjective {
			position: relative;
		}

		.actionIcons {
			position: absolute;
			right: 5px; 
			bottom: 7px;			
			display: none;
		}
		.addObjective, .addOpportunity, .editOpportunity, .deleteOpportunity {
			vertical-align: middle;
			display: none;
			
		}

		#fdicPickers, #objectiveFields {
			display: none;
		}
		
		.overflow {
			150px;
		}
		
		textarea.ui-widget {
			width: 637px;
		}
		

		#customName {
			width: 637px;
		}

		
		#mainContent {
			margin-bottom: 15px;
		}
		
		i.deleteValue, i.editValue {
			display: none;
		}
		
		
		
	</style>

	
	<script>

		//====================================================================================
		function js_Load() {
		//====================================================================================
		// 
		// the <body> of this page has in-line styling to hide it. The <body> also has an
		// in-line event handler for onload, which calls this function that makes the body
		// visible. 
		//
		// The single purpose for this is to avoid FOUC (Flash Of Unstyled Content). This
		// solution was found here: 
		//
		//	https://stackoverflow.com/questions/3221561/eliminate-flash-of-unstyled-content/43823506
		//
		//====================================================================================

			document.body.style.visibility = 'visible';

		}		
		//====================================================================================

		//====================================================================================
		var formatter = new Intl.NumberFormat('en-US', {
		//====================================================================================

		  style: 'currency',
		  currency: 'USD',
		
		  // These options are needed to round to whole numbers if that's what you want.
		  minimumFractionDigits: 0, // (this suffices for whole numbers, but will print 2500.10 as $2,500.1)
		  maximumFractionDigits: 0, // (causes 2500.99 to be printed as $2,501)

		});
		//====================================================================================

		
		//====================================================================================
		function validateDate( date, format ) {
		//====================================================================================
			return dayjs(date, format).format(format) === date;
 		}		
		//====================================================================================

		
		//====================================================================================
		function PopulateFinancialCtgySelectmenu( sect, line ) {
		//====================================================================================
			
			return new Promise( ( resolve, reject ) => {
				
				$.ajax({
					url: `${apiServer}/api/metrics/financialCtgys`,
					data: { 
						ubprSection: sect,
						ubprLine: line
					},
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					success: function( data ) {
						$( '#financialCtgy' ).find('option').remove().end().append('<option selected>All</option>');
						data.forEach( item => {
							$('#financialCtgy').append($('<option>', {
								text: item.financialCtgy 
							}));
						});
						$('#financialCtgy').selectmenu( 'refresh' );
						return resolve( true );
					},
					error: function( error ) {
						return reject( error );
					}
					
				});
				
				
			});		
			
		}
		//====================================================================================
		
		
		//====================================================================================
		function PopulateUbprSectionSelectmenu( ctgy, line ) {
		//====================================================================================
			
			return new Promise( ( resolve, reject ) => {
				
				$.ajax({
					url: `${apiServer}/api/metrics/ubprSections`,
					data: { 
						financialCtgy: ctgy,
						ubprLine: line
					},
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					success: function( data ) {
						$( '#ubprSection' ).find('option').remove().end().append('<option selected>All</option>');
						data.forEach( item => {
							$('#ubprSection').append($('<option>', {
								text: item.ubprSection 
							}));
						});
						$('#ubprSection').selectmenu( 'refresh' );
						return resolve( true );
					},
					error: function( error ) {
						return reject( error );
					}
					
				});
				
				
			});		
			
		}
		//====================================================================================
		
		
		//====================================================================================
		function PopulateUbprLineSelectmenu( ctgy, sect ) {
		//====================================================================================
			
			return new Promise( ( resolve, reject ) => {
				
				$.ajax({
					url: `${apiServer}/api/metrics/ubprLines`,
					data: { 
						financialCtgy: ctgy,
						ubprSection: sect,
					},
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					success: function( data ) {
						$( '#ubprLine' ).find('option').remove().end().append('<option selected>All</option>');
						data.forEach( item => {
							$('#ubprLine').append($('<option>', {
								text: item.ubprLine 
							}));
						});
						$('#ubprLine').selectmenu( 'refresh' );
						return resolve( true );
					},
					error: function( error ) {
						return reject( error );
					}
					
				});
				
				
			});		
			
		}
		//====================================================================================
		
		
		//====================================================================================
		function PopulateMetricNameSelectmenu( type, ctgy, sect, line, customerID ) {
		//====================================================================================

			return new Promise( (resolve, reject) => {

				$.ajax({
					url: `${apiServer}/api/metrics`,
					data: { 
						metricType:	type,
						financialCtgy: ctgy,
						ubprSection: sect,
						ubprLine: line,
						customerID: customerID 
					},
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					success: function( data ) {
						$( '#metricName' ).find('option').remove().end().append('<option disabled selected>Select an option</option>');
						data.forEach( item => {
							$( '#metricName' ).append( $( '<option>', {
								value: item.id, 
								text: item.name 
							 }));
						});
						
						// add one more option for adding a new custom metric...
						if ( type === '2' ) {
							$( '#metricName' ).append( $( '<option>', {
								value: 0, 
								text: 'Add a new custom metric' 
							 }));
						}
						

						$('#metricName').selectmenu( 'refresh' );
						return resolve( true );
					},
					error: function( error ) {
						return reject( error );
					}
					
				});
			
			});
			
		}
		//====================================================================================


		//====================================================================================
		function resetObjectiveDialog() {
		//====================================================================================

			dialog_customerObjective.dialog( 'close' );
			
			$( '#metricType' ).val( 0 );
			$( '#metricType' ).selectmenu( 'refresh' );
			
			$( '#metricName' ).val( null );
			$( '#metricName' ).selectmenu( 'refresh' );
			
			$( '#financialCtgy' ).val( null );
			$( '#financialCtgy' ).selectmenu( 'refresh' );
			
			$( '#ubprSection' ).val( null );
			$( '#ubprSection' ).selectmenu( 'refresh' );
			
			$( '#ubprLine' ).val( null );
			$( '#ubprLine' ).selectmenu( 'refresh' );
			
			$( '#narrative' ).val( null );
			$( '#objectiveStartDate' ).val( null );
			$( '#objectiveStartValue' ).val( null );
			$( '#objectiveEndDate' ).val( null );
			$( '#objectiveEndValue' ).val( null );
			

			$( '#fdicPickers' ).hide();
			$( '#objectiveFields' ).hide();			
						
		}
		//====================================================================================
		
		
		//====================================================================================
		function resetOpportunityDialog() {
		//====================================================================================
			
			dialog_opportunity.dialog( 'close' );
			
			$( '#oppNarrative' ).val( null );
			$( '#oppStartDate' ).val( null );
			$( '#oppEndDate' ).val( null );
			$( '#oppValue' ).val( null );

		}
		//====================================================================================


		//====================================================================================
		function getMaxObjectiveEndDate( implementationID ) {
		//====================================================================================

			return new Promise( async (resolve, reject) => {

				$.ajax({
	
					url: `${apiServer}/api/metrics/maxObjectiveEndDate`,
					data: { implementationID: implementationID },
					headers: { 'Authorization': 'Bearer ' + sessionJWT }
					
				}).done( function( response ) {
					
					console.log({ getMaxObjectiveEndDate: response.maxEndDate });
					resolve( response.maxEndDate );
					
				}).fail( function( err ) {
						
					console.error( 'Error in getMaxObjectiveEndDate()', err );
					reject( err );
						
				});
			
			});

		}
		//====================================================================================

		
		//====================================================================================
		function drawMetricChart( metricDiv, maxObjectiveEndDate ) {
		//====================================================================================

			const targetElement 	= metricDiv 
			const objectiveElem	= $( metricDiv ).closest( 'div.objective' );
			const objectiveID 	= $( objectiveElem ).attr( 'id' ).substring( $( objectiveElem ).attr( 'id' ).indexOf( '-' ) + 1 );
			const title 			= $( metricDiv ).attr( 'data-title' );
			const progressbar		= $( metricDiv ).parent().find( 'div.progressbar' );
			
			debugger
			
			$.ajax({

				beforeSend: function() {
					$( progressbar ).progressbar({ value: false });
				},
				url: `${apiServer}/api/metrics/chartObjective`,
				data: { 
					objectiveID: objectiveID,
					maxObjectiveEndDate: maxObjectiveEndDate
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT }

			}).done( function( response ) {

				if ( !response.error ) {
	
// 					console.log({ title: response.options.title, min: response.options.hAxis.viewWindow.min, max: response.options.hAxis.viewWindow.max });
	
					$( targetElement ).prev().hide();
					let chart = new google.visualization.ComboChart( targetElement );
					let dataTable = new google.visualization.DataTable( response.data );
					chart.draw( dataTable, response.options );
					$( targetElement ).closest( 'div.objective' ).data({ metricName: response.options.title });
	
				} else {
	
					$( targetElement ).prev().show();
	
				}
	
				$( progressbar ).progressbar('destroy');

			}).fail( function( err ) {
					
				$( progressbar ).progressbar('destroy');
				$( targetElement ).text( err.status + ' (' + err.responseText + ') ' );

			});

		}
		//====================================================================================

		
		google.charts.load( 'current', { packages: ['corechart', 'line'] } );
		
		
		const sessionJWT				= '<% =sessionJWT %>';
		const customerID 				= '<% =customerID %>';
		const serverName 				= '<% =systemControls("server name") %>';
		const scriptName				= '<% =request.serverVariables("SCRIPT_NAME") %>';
		const activityDescription 	= 'Customer Intention Detail';
		const implementationID 		= <% =implementationID %>;
		

		
		//====================================================================================
		google.charts.setOnLoadCallback( async function() {
		//====================================================================================


			$( async function() {
				
				
				$( document ).tooltip();
				

				$( '#showAnnualChangeInd' ).checkboxradio();

				
				$( '.accordian, .accordianInner' ).accordion({
					collapsible: true,
					heightStyle: 'content'
				});
				
				const maxObjectiveEndDate = await getMaxObjectiveEndDate( implementationID );
				console.log({ maxObjectiveEndDate: maxObjectiveEndDate });
				
				// this populates all the objectives on the page with metric info...
				await $( 'div.metric' ).each( async function() {
					await drawMetricChart( this, maxObjectiveEndDate );
				});
				
				// this calculates total economic value, shown on the Opportunity accordian banner...
				var totalEconomicValue = 0;
				$( '.value' ).each( function() {
					var amount = Number($( this ).text().replace(/[^0-9.-]+/g,""));
					totalEconomicValue += amount;
				});
				$( '#totalEconomicValue' ).text( formatter.format(totalEconomicValue) );
	
	
				$( 'div.customerObjective' ).on( 'mouseover', function() {
					$( this ).find( 'div.actionIcons' ).show();
				});

	
				$( 'div.customerObjective' ).on( 'mouseout', function() {
					$( this ).find( 'div.actionIcons' ).hide();
				});


				dialog_confirmDeleteValue = $( "#dialog_confirmDeleteValue" ).dialog({
					autoOpen: false,
					resizable: false,
					height: 'auto',
					width: 400,
					modal: true,
					buttons: {
						Delete: function() {
							$.ajax({
								type: 'DELETE',
								url: `${apiServer}/api/metrics/internalValues`,
								data: JSON.stringify({ id: $(this).data().metricValueID }),
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								contentType: 'application/json',
								success: function() {

									try {
										metricValueID = dialog_confirmDeleteValue.data().metricValueID;
										metricDiv = dialog_confirmDeleteValue.data().metricDiv.get(0);
										$( '#tbl_customerMetricValues' ).DataTable().row( '#'+metricValueID ).remove().draw();
										drawMetricChart( metricDiv );
										var notification = document.querySelector('.mdl-js-snackbar');
										notification.MaterialSnackbar.showSnackbar({ message: 'Value deleted' });
									} catch( err ) {
										
										console.error( err );
									}
								},
								error: function( err ) {
									$( progressbar ).progressbar('destroy');
									$( targetElement ).text( err.status + ' (' + err.responseText + ') ' );
								}
							});
							$( this ).dialog( 'close' );
						},
						Cancel: function() {
							$( this ).dialog( 'close' );
						}
					}
				});
				
				$( '#metricValueDate' ).datepicker();
				$( '#metricValueDate' ).on( 'change', function() {
					if ( $( this ).val() ) {
						if ( !dayjs( $(this).val() ).isValid() ) {
							alert ( 'Metric date is invalid' );
						}
					}
				});
				
				dialog_editMetricValue = $( '#dialog_editMetricValue' ).dialog({
					autoOpen: false,
					resizable: false,
					height: 'auto',
					width: 350,
					modal: true,
					buttons: {
						Save: function() {

							const formData = { 
								metricID: 			$( this ).data().metricID,
								metricValueID: 	$( this ).data().metricValueID,
								metricValueDate:	$( '#metricValueDate' ).val(),
								metricValueValue:	$( '#metricValueValue' ).val(),
								customerID: customerID
							};

							$.ajax({
								type: 'PUT',
								url: `${apiServer}/api/metrics/internalValues`,
								data: JSON.stringify( formData ),
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								contentType: 'application/json',
								success: function() {

									metricDiv = dialog_customerMetricValues.data().metricDiv.get(0);
									
									$( '#tbl_customerMetricValues' ).DataTable().ajax.reload( null, false );

									drawMetricChart( metricDiv );
									var notification = document.querySelector('.mdl-js-snackbar');
									notification.MaterialSnackbar.showSnackbar({ message: 'Value deleted' });
								}
							});
							$( this ).dialog( 'close' );
						},
						Cancel: function() {
							$( this ).dialog( 'close' );
						},
					}
				});

				dialog_customerMetricValues = $( '#dialog_customerMetricValues' ).dialog({
					autoOpen: false,
					modal: true,
					width: 500,
					buttons: {
						New: function() {
							dialog_editMetricValue.data().metricID = dialog_customerMetricValues.data().metricID;
							dialog_editMetricValue.data().metricValueID = null;
							dialog_editMetricValue.dialog( 'open' );
						},
						Cancel: function() {
							dialog_customerMetricValues.dialog( 'close' );			
						}
					},
					open: function() {
						

						if ( $.fn.DataTable.isDataTable('#tbl_customerMetricValues') ) {
							$('#tbl_customerMetricValues').DataTable().destroy();
						}

						
						$( '#tbl_customerMetricValues' )
							.on( 'mouseover', 'tbody tr', function() {
								$( this ).find( 'i.deleteValue, i.editValue' ).show();
							})
							.on( 'mouseout', 	'tbody tr', function() {
								$( this ).find( 'i.deleteValue, i.editValue' ).hide();
							})
							
							.on( 'click', 'i.editValue', function() {
								
								const metricValueID = $( this ).closest( 'tr' ).attr( 'id' );
								const metricValueDate = $( this ).closest( 'tr' ).find( 'td.metricDate' ).text()
								const metricValueValue = $( this ).closest( 'tr' ).find( 'td.metricValue' ).text();
								
								dialog_editMetricValue.data().metricValueID = metricValueID;
								$( '#metricValueDate' ).val( metricValueDate );
								$( '#metricValueValue' ).val( metricValueValue );
								
								dialog_editMetricValue.dialog( 'open' );
								
							})

							.on( 'click', 'i.deleteValue', function() {
								const metricValueID = $( this ).closest( 'tr' ).attr( 'id' );
								dialog_confirmDeleteValue.data().metricValueID = metricValueID;
								dialog_confirmDeleteValue.data().metricDiv = dialog_customerMetricValues.data().metricDiv;
								dialog_confirmDeleteValue.dialog( 'open' );
							})

							.DataTable({
								ajax: {
									url: `${apiServer}/api/metrics/internalValues`,
									headers: { 'Authorization': 'Bearer ' + sessionJWT },
									data: { customerID: customerID, metricID: dialog_customerMetricValues.data().metricID },
									dataSrc: '',
								},
								rowId: 'id',
								scrollY: 250,
								scroller: true,
								searching: false,
								columnDefs: [
									{
										targets: 'Date', 
										data: {
											_: 'Date', 
											sort: 'sortableDate'
										},
										class: 'metricDate dt-body-center',
									 },
									{targets: 'Value', data: 'Value', class: ' metricValue dt-body-center' },
									{
										targets: 'actions', 	
										data: null,			
										orderable: false, 
										className: 'actions dt-body-center',
										defaultContent: '',
										width: '50px',
										render: function() {
											return '<i class="material-icons deleteValue" title="Delete value">delete_outline</i><i class="material-icons editValue" title="Edit value">mode_edit</i>';
										}
									},
								],
								order: [[0, 'desc' ]],
							});
							
					}

				});
				
				$( 'i.editCustomerMetricValues' ).on( 'click', function( event ) {
					
					event.stopPropagation();

					let metricID = $( this ).closest( 'div.actionIcons' ).attr( 'data-metricID' );
					let metricName = $( this ).closest( 'div.objective' ).data().metricName; 
					let metricDiv = $(this).closest('div.objective').find('div.metric');

					dialog_customerMetricValues.data({ metricID: metricID, metricDiv: metricDiv });
					dialog_customerMetricValues.dialog({ title: 'Edit values for '+ metricName });
					dialog_customerMetricValues.dialog( 'open' );
					
				});
				
				
				dialog_customerObjective = $( "#dialog_customerObjective" ).dialog({
					autoOpen: false,
					modal: true,
					width: 675,
					buttons: {
						Save: async function() {
							
							if ( !$( '#metricType' ).val() ) {									// metricType is required
								
								await $( '#metricType' ).parent().addClass( 'ui-state-error' );
								alert( 'Metric type is required' );
								return false;
								
							} else {

								$( '#metricType' ).parent().removeClass( 'ui-state-error' );

								if ( !$( '#metricName' ).val() ) {									// metricName is required
									
									await $( '#metricName' ).parent().addClass( 'ui-state-error' );
									alert( 'Metric name is required' );
									return false;
									
								} else {

									$( '#metricName' ).parent().removeClass( 'ui-state-error' );

									if ( $( '#metricName' ).val() === '0' ) {							// if user selected "add a new custom metric" 
										if ( !$( '#customName' ).val() ) {								//		if #customName is not supplied...
											$( '#customName' ).addClass( 'ui-state-error' );		//			decorate #customerName as in error
											alert( 'Custom Name is required' );							//			alert user to problem
											return false;														//			exit
										} else {																	//		else 
											$( '#customName' ).removeClass( 'ui-state-error' );	//			remove error decoration
										}																			// 	end if
									} else {																		//	else 
										$( '#customName' ).removeClass( 'ui-state-error' );		//		remove error decoration
									}																				//	end if

								}

							}

							
							const formData = { 
								annualEconomicValue: null,
								customName: 			$( '#customName' ).val(),
								customerID:				customerID,
								endQuarterEndDate: 	null,
								implementationID: 	implementationID,
								metricID: 				$( '#metricName' ).val(),
								metricTypeID:			$( '#metricType' ).val(),
								narrative: 				$( '#narrative' ).val(),
								objectiveEndDate:		$( '#objectiveEndDate' ).val(),
								objectiveEndValue:	$( '#objectiveEndValue' ).val(),
								objectiveID: 			$( '#objectiveID' ).val(),
								objectiveStartDate:	$( '#objectiveStartDate' ).val(),
								objectiveStartValue: $( '#objectiveStartValue' ).val(),
								objectiveTypeID: 		$( '#objectiveTypeID' ).val(),
								opportunityID: 		$( this ).data().opportunityID,
								peerGroupTypeID: 		$( '#peerGroupType' ).val(),
								showAnnualChangeInd: $('#showAnnualChangeInd').is(':checked'),
								startQuarterEndDate: null
							};
														
							$.ajax({
								type: 'PUT',
								url: `${apiServer}/api/objectives`,
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								data: JSON.stringify( formData ),
								contentType: 'application/json',
								success: function() {
									location = location;
								},
								error: function( err ) {
									if ( err.status == 400 ) {
										alert( err.responseText );
									} else {
										alert( 'Something went wrong; please contact system administrator' );
									}
								}
							});

						},
						Cancel: function() {
							resetObjectiveDialog();
						}
					},
					close: function() {
						resetObjectiveDialog();
					}
				});
				
				
				dialog_confirmDeleteObjective = $( "#dialog_confirmDeleteObjective" ).dialog({
					autoOpen: false,
					resizable: false,
					height: 'auto',
					width: 400,
					modal: true,
					buttons: {
						Delete: function() {
							$.ajax({
								type: 'DELETE',
								url: `${apiServer}/api/metrics`,
								data: JSON.stringify({ id: $(this).data().objectiveID }),
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								contentType: 'application/json',
								success: function() {
									objectiveID = JSON.parse( this.data ).id;
									$( '#obj-'+objectiveID ).remove();
									var notification = document.querySelector('.mdl-js-snackbar');
									notification.MaterialSnackbar.showSnackbar({ message: 'Objective deleted' });
								}
							});
							$( this ).dialog( 'close' );
						},
						Cancel: function() {
							$( this ).dialog( 'close' );
						}
					}
				});


				dialog_opportunity = $( '#dialog_opportunity' ).dialog({
					autoOpen: false,
					modal: true, 
					width: 675,
					buttons: {
						Save: function() {
							const formData = {
								opportunityID: $( this ).data().opportunityID,
								implementationID: implementationID,
								title: $( '#oppTitle' ).val(),
								narrative: $( '#oppNarrative' ).val(),
								startDate: $( '#oppStartDate' ).val(),
								endDate: $( '#oppEndDate' ).val(),
								annualEconomicValue: Number( $( '#oppValue' ).val().replace( /[^0-9.-]+/g, "" ) )
							}

							$.ajax({
								type: 'PUT',
								url: `${apiServer}/api/opportunities`,
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								data: JSON.stringify( formData ),
								contentType: 'application/json',
							}).done( function() {
								location = location;
							}).fail( function() {
								alert( 'Something went wrong, contact system administrator' );
							});

						},
						Cancel: function() {
							resetOpportunityDialog();
						},
					},
					close: function() {
						resetOpportunityDialog();
					}
				});


				dialog_confirmDeleteOpportunity = $( "#dialog_confirmDeleteOpportunity" ).dialog({
					autoOpen: false,
					resizable: false,
					height: 'auto',
					width: 400,
					modal: true,
					buttons: {
						Delete: function() {
							$.ajax({
								type: 'DELETE',
								url: `${apiServer}/api/opportunities`,
								data: JSON.stringify({ id: $(this).data().opportunityID }),
								headers: { 'Authorization': 'Bearer ' + sessionJWT },
								contentType: 'application/json',
								success: function() {
									opportunityID = JSON.parse( this.data ).id;
									$( '#opp-'+opportunityID ).remove();
									var notification = document.querySelector('.mdl-js-snackbar');
									notification.MaterialSnackbar.showSnackbar({ message: 'Opportunity deleted' });
								}
							});
							$( this ).dialog( 'close' );
						},
						Cancel: function() {
							$( this ).dialog( 'close' );
						}
					}
				})


				$( 'span.addOpportunity' ).on( 'click', function( event ) {
					
					event.stopPropagation();

					dialog_opportunity.dialog( 'open' );
					
				});

				
				$( '#oppStartDate' ).datepicker();
				$( '#oppStartDate' ).on( 'change', function() {
					if ( $( this ).val() ) {
						if ( !dayjs( $(this).val() ).isValid() ) {
							alert ( 'Start date is invalid' );
						}
					}
				});


				$( '#oppEndDate' ).datepicker();
				$( '#oppEndDate' ).on( 'change', function() {
					if ( $( this ).val() ) {
						if ( !dayjs( $(this).val() ).isValid() ) {
							alert ('End date is invalid');
						}
					}
				});


				$( 'i.addObjective').on( 'click', function( event ) {

					event.stopPropagation();
					
					switch ( true ) {
						case $( this ).closest( 'h3' ).text().startsWith( 'Utopia' ):
							opportunityID = null;
							dialog_customerObjective.dialog( 'option', 'title', 'Add an objective to Utopia' );
							$( '#objectiveTypeID' ).val( 1 );		// Utopia
							dialog_customerObjective.data({ opportunityID: opportunityID });
							break
						case $( this ).closest( 'h3' ).text().startsWith( 'KPI' ):
							opportunityID = null;
							dialog_customerObjective.dialog( 'option', 'title', 'Add a KPI to the Intention' );
							$( '#objectiveTypeID' ).val( 3 );		// KPI
							dialog_customerObjective.data({ opportunityID: opportunityID });
							break
						default: 
							opportunityID = $( this ).closest( 'div.customerOpportunity' ).attr( 'data-opportunityID' );
							dialog_customerObjective.dialog( 'option', 'title', 'Add an objective to the Opportunity' );
							$( '#objectiveTypeID' ).val( 2 );		// Opportunity
							dialog_customerObjective.data({ opportunityID: opportunityID });
					}
					
					$( '#peerGroupType' ).selectmenu( 'refresh' );
					
					dialog_customerObjective.dialog(	'open' );

				});
				
				
				$( 'i.editObjective' ).on( 'click', function( event ) {

					if ( $( this ).closest( 'h3' ).text().startsWith( 'Utopia' ) ) {
						opportunityID = null;
						dialog_customerObjective.dialog( 'option', 'title', 'Edit an Utopia objective' );
						$( '#objectiveTypeID' ).val( 1 );		// Utopia
						dialog_customerObjective.data({ opportunityID: opportunityID });
					} else {
						opportunityID = $( this ).closest( 'div.customerOpportunity' ).attr( 'data-opportunityID' );
						dialog_customerObjective.dialog( 'option', 'title', 'Edit an Opportunity objective' );
						$( '#objectiveTypeID' ).val( 2 );		// Opportunity
						dialog_customerObjective.data({ opportunityID: opportunityID });
					}
						

				
					objectiveID = $( this ).closest( 'div.actionIcons' ).attr( 'data-objectiveID' );
					$.ajax({
						url: `${apiServer}/api/objective/${objectiveID}`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						success: function( data ) {

							dialog_customerObjective.dialog( 'open' );
							
							$( '#objectiveID' ).val( data.objectiveID );
							$( '#objectiveTypeID' ).val( data.objectiveTypeID );
							
							switch ( data.dataType ? data.dataType.toLowerCase() : null ) {
								
								case 'number':
								
									if ( data.startValue ) {
										$( '#objectiveStartValue' ).val( data.startValue.toLocaleString() );
									} else {
										$( '#objectiveStartValue' ).attr( 'placeholder', data.dataType );
									}
									if ( data.endValue ) {
										$( '#objectiveEndValue' ).val( data.endValue.toLocaleString() );
									} else {
										$( '#objectiveEndValue' ).attr( 'placeholder', data.dataType );
									}
									break
									
								case 'currency':
								
									if ( data.startValue ) {
										$( '#objectiveStartValue' ).val( formatter.format( data.startValue ) );
									} else {
										$( '#objectiveStartValue' ).attr( 'placeholder', data.dataType );	
									}
									
									if ( data.endValue ) {
										$( '#objectiveEndValue' ).val( formatter.format( data.endValue ) );
									} else {
										$( '#objectiveEndValue' ).attr( 'placeholder', data.dataType );
									}
									break 
									
								case 'percent':
									
									if ( data.startValue ) {
										$( '#objectiveStartValue' ).val( parseFloat( data.startValue ).toFixed( 3 )+'%' );
									} else {
										$( '#objectiveStartValue' ).attr( 'placeholder', data.dataType );	
									}
									
									if ( data.endValue ) {
										$( '#objectiveEndValue' ).val( parseFloat( data.endValue ).toFixed( 3 )+'%' );
									} else {
										$( '#objectiveEndValue' ).attr( 'placeholder', data.dataType );
									}
									break 
									
								case 'date':

									$( '#objectiveStartValue' ).val( dayjs( data.startValue ).format( 'M/D/YYYY' ) );
									$( '#objectiveEndValue' ).val( dayjs( data.endValue ).format( 'M/D/YYYY') );
									break 
									
								case 'text':
								case 'y/n':
								default:
								
									$( '#objectiveStartValue' ).val( data.startValue );
									$( '#objectiveEndValue' ).val( data.endValue );

							}
							
							$( '#objectiveStartValue' ).val( data.startValue );
							$( '#objectiveEndValue' ).val( data.endValue );
							
							if ( data.metricTypeID == 3 ) {
								
								$( '#metricType' ).val( '3' );
								
								$( '#financialCtgy' ).val( data.financialCtgy );
								$( '#financialCtgy' ).selectmenu( 'refresh' );
								
								$( '#ubprSection' ).val( data.ubprSection );
								$( '#ubprSection' ).selectmenu( 'refresh' );
								
								$( '#ubprLine' ).val( data.ubprLine );
								$( '#ubprLine' ).selectmenu( 'refresh' );

								$( '#peerGroupType' ).val( data.peerGroupTypeID );
								$( '#peerGroupType' ).selectmenu( 'refresh' );

								if ( data.correspondingAnnualChangeID ) {
									if ( data.showAnnualChangeInd ) {
										$( '#showAnnualChangeInd' ).prop( 'checked', true ).checkboxradio( 'refresh' );
									} else {
										$( '#showAnnualChangeInd' ).prop( 'checked', false ).checkboxradio( 'refresh' );
									}
									$( '.showAnnualChangeInd' ).show();
								} else {
									$( '.showAnnualChangeInd' ).hide();
								}

								$( '#fdicPickers' ).show();

							} else {

								$( '#fdicPickers' ).hide();

								$( '#metricType' ).val( data.metricTypeID );
												
							}

							$( '#metricType' ).selectmenu( 'refresh' );

							$( '#objectiveFields' ).show();
							

							PopulateMetricNameSelectmenu( $( '#metricType' ).val(), $( '#financialCtgy' ).val(), $( '#ubprSection' ).val(), $( '#ubprLine' ).val(), customerID )
							.then( () => {
								$( '#metricName' ).val( data.metricID );
								$( '#metricName' ).selectmenu( 'refresh' );
							})
							.catch( err => {
								throw new Error( err );
							})

							$( '#customName' ).val( data.customName );
							$( '#narrative' ).val( data.narrative );
							
							if ( data.startDate ) {
								$( '#objectiveStartDate' ).val( dayjs( data.startDate ).format( 'M/D/YYYY' ) );
							} else {
								$( '#objectiveStartDate' ).val( null );
							}
							
							if ( data.endDate ) {
								$( '#objectiveEndDate' ).val( dayjs( data.endDate ).format( 'M/D/YYYY' ) );
							} else {
								$( '#objectiveEndDate' ).val( null );
							}
							
							
						}
					})




				})			
				
				
				$( '.deleteObjective' ).on( 'click', function( event ) {
					
					event.stopPropagation();

					const objectiveID = $( this ).closest( 'div.actionIcons' ).attr( 'data-objectiveID' )
					$( "#dialog_confirmDeleteObjective" ).data({ objectiveID: objectiveID });
					$( "#dialog_confirmDeleteObjective" ).dialog( 'open' );
	
				});


				$( '.deleteOpportunity' ).on( 'click', function( event ) {
	
					event.stopPropagation();

					const opportunityID = $( this ).closest( 'div.customerOpportunity' ).attr( 'data-opportunityID' );
					$( "#dialog_confirmDeleteOpportunity" ).data({ opportunityID: opportunityID });
					$( "#dialog_confirmDeleteOpportunity" ).dialog( 'open' );
	
				});


				$( '#metricType' ).selectmenu({
					change: function( event, ui ) {

						$( '#metricType' ).parent().removeClass( 'ui-state-error' );
						
						switch ( $( '#metricType' ).val() ) {

							case '1':				//	TEG Standard
								$( '#fdicPickers' ).hide();
								$( 'div.metricName' ).show();
								$( 'div.customName' ).hide();
								break;
							case '2':				//	Custom
								$( '#fdicPickers' ).hide();
								$( 'div.metricName' ).show();
								$( 'div.customName' ).hide();
								break;
							case '3':				// FDIC
								PopulateFinancialCtgySelectmenu( null, null );
								PopulateUbprSectionSelectmenu( null, null );
								PopulateUbprLineSelectmenu( null, null );
								$( '#fdicPickers' ).show();
								$( 'div.metricName' ).show();
								$( 'div.customName' ).hide();
								break;
							case '4':				// TGIM University
								$( '#fdicPickers' ).hide();
								$( 'div.metricName' ).show();
								$( 'div.customName' ).hide();
								break;
							case '5':				// FDIC Calc
								$( '#fdicPickers' ).hide();
								$( 'div.metricName' ).show();
								$( 'div.customName' ).hide();
								break;
							default: 				// unexpected!
								alert( 'ERROR: Unexpected metric type encountered; contact your system administrator' );

						}
						
						PopulateMetricNameSelectmenu( $( this ).val(), null, null, null, customerID );
						$( '#objectiveFields' ).show();

					}
				}).addClass( 'overflow' );


				$( '#financialCtgy' ).selectmenu({
					change: function( event, ui ) {
						
						const ctgy = $( this ).val();
						const sect = null;
						const line = null;

//						PopulateUbprSectionSelectmenu( ctgy, line );
						$( '#ubprSection' ).val( 'All' );
						$( '#ubprSection' ).selectmenu( 'refresh' );
//						PopulateUbprLineSelectmenu( ctgy, sect );
						$( '#ubprLine' ).val( 'All' );
						$( '#ubprLine' ).selectmenu( 'refresh' );
						PopulateMetricNameSelectmenu( 3, ctgy, sect, line, customerID );
						
						

					}
				}).addClass( 'overflow' );


				$( '#ubprSection' ).selectmenu({
					change: function( event, ui ) {
						
						const ctgy = $( '#financialCtgy' ).val();
						const sect = $( this ).val();
						const line = $( '#ubprLine' ).val();
						
// 					PopulateFinancialCtgySelectmenu( sect, line );
// 					PopulateUbprLineSelectmenu( ctgy, sect );
						PopulateMetricNameSelectmenu( 3, ctgy, sect, line, customerID );

					}
					
				}).addClass( 'overflow' );


				$( '#ubprLine' ).selectmenu({
					width: 175,
					change: function( event, ui ) {

						const ctgy = $( '#financialCtgy' ).val();
						const sect = $( '#ubprSection' ).val() 
						const line = $( this ).val()

// 					PopulateFinancialCtgySelectmenu( sect, line );
// 					PopulateUbprSectionSelectmenu( ctgy, line );
						PopulateMetricNameSelectmenu( 3, ctgy, sect, line, customerID );

					}
					
				}).addClass( 'overflow' );
				
				
				$( '#peerGroupType' ).selectmenu({
					width: 407
				});


				$( '#metricName' ).selectmenu({
						width: 643,
						change: function( event, ui ) {

							$( '#metricName' ).parent().removeClass( 'ui-state-error' );
							
							if ( $( '#metricType' ).val() === '2' ) {
							
								if ( $( this ).val() === '0' ) {
								
									$( 'div.customName' ).show();
									$( '#customName' ).focus();
									
								} else {
									
									$( 'div.customName' ).hide();

								}
								
							} else {

								$( 'div.customName' ).hide();

								$.ajax({
									url: `${apiServer}/api/metric/${ui.item.value}`,
									headers: { 'Authorization': 'Bearer ' + sessionJWT },
									success: function( data ) {
										$( '#financialCtgy' ).val( data.financialCtgy );
										$( '#financialCtgy' ).selectmenu( 'refresh' );
										
										$( '#ubprSection' ).val( data.ubprSection );
										$( '#ubprSection' ).selectmenu( 'refresh' );
	
										$( '#ubprLine' ).val( data.ubprLine );
										$( '#ubprLine' ).selectmenu( 'refresh' );
										
										if ( data.correspondingAnnualChangeID ) {
											$( '#showAnnualChangeInd' ).prop( 'checked', false ).checkboxradio( 'refresh' );
											$( '.showAnnualChangeInd' ).show();
										} else {
											$( '.showAnnualChangeInd' ).hide();
										}
			
									},
									error: function( err ) {
										console.log( 'something bad happened, ', err )
									}
									
								});
								
							}
	
						}

				}).addClass( 'overflow' );
				

				$( '#objectiveStartDate' ).datepicker({
					dateFormat: 'm/d/yy',
					changeMonth: true,
					changeYear: true,
					onClose: function( dateText ) {

						minEndDateYear = dayjs( dateText ).year();
						minEndDateMonth = dayjs( dateText ).month();
						minEndDateDate = dayjs( dateText ).date();
						minEndDate = new Date( minEndDateYear, minEndDateMonth, minEndDateDate );
						$( '#objectiveEndDate' ).datepicker( 'option', 'minDate', minEndDate );

						if ( !$( '#objectiveEndDate' ).val() ) {
							$( '#objectiveEndDate' ).val( dayjs( dateText ).add( 3, 'year' ).format( 'M/D/YYYY') );
						}

					}
				});
				
				
				$( '#objectiveEndDate' ).datepicker({
					dateFormat: 'm/d/yy',
					changeMonth: true,
					changeYear: true,
					onClose: function( dateText ) {

						maxStartDateYear = dayjs( dateText ).year();
						maxStartDateMonth = dayjs( dateText ).month();
						maxStartDateDate = dayjs( dateText ).date();
						maxStartDate = new Date( maxStartDateYear, maxStartDateMonth, maxStartDateDate );
						$( '#objectiveStartDate' ).datepicker( 'option', 'maxDate', maxStartDate );

					}
				});
// 				$( '#objectiveEndDate' ).on( 'change', function( event ) {
// 					if ( $(this).val() ) {
// 						if ( !validateDate( $(this).val(), 'M/D/YYYY' ) ) {
// 							alert ('End data is invalid');
// 						}
// 					}
// 				});
				
				
				$( 'div.accordian > h3, div.accordianInner> h3' ).on( 'mouseover', function() {
					$( this ).find( 'i.material-icons' ).show();
				});


				$( 'div.accordian > h3, div.accordianInner > h3' ).on( 'mouseout', function() {
					$( this ).find( 'i.material-icons' ).hide();
				});
				

				$( 'i.addOpportunity' ).on( 'click', function( event ) {
				
					event.stopPropagation();

					dialog_opportunity.dialog( 'open' );
					
				});
				
				
				$( 'i.editOpportunity' ).on( 'click', function() {
					
					event.stopPropagation();
					
					$( '#oppTitle' ).val ( $(this).closest('h3').find('span.oppTitle').text().trim() );
					$( '#oppNarrative' ).val ($(this).closest('h3').next().find( 'div.narrative' ).text().trim() );
					$( '#oppStartDate' ).val( $( this ).closest( 'h3' ).find( 'span.startDate' ).text() );
					$( '#oppEndDate' ).val( $( this ).closest( 'h3' ).find( 'span.endDate' ).text() );
					$( '#oppValue' ).val( $( this ).closest( 'h3' ).find( 'span.value' ).text() );

					dialog_opportunity.data({ opportunityID: $( this ).closest( 'div.customerOpportunity' ).attr( 'data-opportunityID' ) });
					dialog_opportunity.dialog( 'open' );

				});
				
			});
			
			
		});
		//====================================================================================
		//====================================================================================
		//====================================================================================

		
	</script>

	

</head>

<!-- <body style="visibility: hidden;" onload="js_Load()"> -->
<body>

<!-- MDL Snackbar -->
<div aria-live="assertive" aria-atomic="true" aria-relevant="text" class="mdl-snackbar mdl-js-snackbar">
    <div class="mdl-snackbar__text"></div>
    <button type="button" class="mdl-snackbar__action"></button>
</div>



<!-- 	confirmation dialog for adding a customerObjective  -->
<div id="dialog_editMetricValue" title="Add a new metric value" style="display: none;">
	<form>
		<table>
			<thead>
				<tr>
					<th>Date</th>
					<th>Value</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td><input type="text" id="metricValueDate" class="ui-widget ui-state-default ui-corner-all" autocomplete="off"></td>
					<td><input type="text" id="metricValueValue" class="ui-widget ui-state-default ui-corner-all" autocomplete="off"></td>
				</tr>
			</tbody>
		</table>
	
<!-- 		<input type="submit" tabindex="-1" style="position: absolute; top: -1000px"> -->
	</form>
</div>


<!-- 	confirmation dialog for deleting a customerObjective  -->
<div id="dialog_confirmDeleteValue" title="Delete this value?" style="display: none;">
	<p>
		<i class="material-icons" style="float:left; margin:12px 12px 20px 0;">warning</i>
		The value for the metric will be permanently deleted -- this cannot be undone.
	</p>
</div>


<!-- 	confirmation dialog for deleting a customerObjective  -->
<div id="dialog_confirmDeleteObjective" title="Delete this objective?" style="display: none;">
	<p>
		<i class="material-icons" style="float:left; margin:12px 12px 20px 0;">warning</i>
		The objective will be permanently deleted -- this cannot be undone.
	</p>
</div>


<!-- 	confirmation dialog for deleting a customerOpportunity  -->
<div id="dialog_confirmDeleteOpportunity" title="Delete this opportunity?" style="display: none;">
	<p>
		<i class="material-icons" style="float:left; margin:12px 12px 20px 0;">warning</i>
		The opportunity, and all objectives associated with it, will be permanently deleted -- this cannot be undone.
	</p>
</div>


<!-- dialog for editing values for editable objectvies -->
<div id="dialog_customerMetricValues" title="Edit metric values" stype="display: none;">
	
	<form>
		<table id="tbl_customerMetricValues" class="compact display">
			<thead>
				<tr>
					<th class="Date">Date</th>
					<th class="Value">Value</th>
					<th class="actions">Actions</th>
				</tr>
			</thead>
		</table>
	
<!-- 		<input type="submit" tabindex="-1" style="position: absolute; top: -1000px"> -->
	</form>
	
</div>


<!-- add/edit dialog for customerObjectives -->
<div id="dialog_customerObjective" title="Add new opportunity" style="display: none;">
 
  <form>
    <fieldset>

		<div class="formField">
	      <label for="metricType">Type</label>
	      <select id="metricType">
		      <option value="0" selected disabled>Make a selection</option>
		      <%
			    dbug("getting metricTypes...")
				SQL = "select id, name from metricTypes order by seq "
				set rsMT = dataconn.execute(SQL) 
				while not rsMT.eof 
					response.write("<option value=""" & rsMT("id") & """>" & rsMT("name") & "</option>")
					rsMT.movenext 
				wend 
				%>
	      </select>
		</div>
		
		<div id="fdicPickers">
			<table>
				<tr>

					<td class="formField" colspan="2">
						<label for"peerGroupType">Peer group type</label>
						<select id="peerGroupType">
							<option disabled selected>Select an option</option>
							<%
							dbug("getting peerGroups...")
							SQL = "select distinct pgt.id, pgt.[description] " &_
									"from fdic_ranks.dbo.SummaryRatios k " &_
									"join fdic.dbo.peerGroup pg on (pg.id = k.[peer group]) " &_
									"join fdic.dbo.peerGroupType pgt on (pgt.id = pg.peerGroupType) " &_
									"where k.[id rssd] = " & customerRSSD & " " &_
									"order by pgt.[description] "
							dbug(SQL)
							set rsPGT = dataconn.execute(SQL) 
							dbug("about to loop through peerGroups...")
							while not rsPGT.eof 
								dbug("rsPGT('id'): " & rsPGT("id" ))
								dbug("rsPGT('description'): " & rsPGT("description" ))
								dbug("defaultPeerGroupType: " & defaultPeerGroupType )
								if isNumeric( defaultPeerGroupType ) then 
									if cInt(rsPGT("id")) = cInt(defaultPeerGroupType) then 
										selected = "selected" 
									else 
										selected = ""
									end if
								else 
									selected = ""
								end if
								
								%>
								<option value="<% =rsPGT("id") %>" <% =selected %>><% =rsPGT("description") %></option>
								<%
								rsPGT.movenext 
							wend 
							rsPGT.close 
							set rsPGT = nothing 
							dbug("done getting peerGroups")
							%>
							<option>None</option>
						</select>
					</td>
					
					<td class="formField showAnnualChangeInd">
						<div>Show Corr. Annual Change</div>
						<label for="showAnnualChangeInd">Check to show</label>
						<input type="checkbox" id="showAnnualChangeInd">
					</td>
					
				</tr>
				<tr>
				
					<td class="formField">
						<label for="financialCtgy">Category</label>
						<select id="financialCtgy">
							<option selected>All</option>
							<%
							dbug("getting financialCtgy...")
							SQL = "select distinct financialCtgy from metric where internalMetricInd = 0 order by 1 "
							set rsCtgy = dataconn.execute(SQL) 
							while not rsCtgy.eof 
								response.write("<option>" & rsCtgy("financialCtgy") & "</option>")
								rsCtgy.movenext 
							wend 
							rsCtgy.close 
							set rsCtgy = nothing 
							%>
						</select>
					</td>
					
					<td class="formField">
						<label for="ubprSection">UBPR Section</label>
						<select id="ubprSection">
							<option selected>All</option>
							<%
							dbug("getting ubprSection...")
							SQL = "select distinct ubprSection from metric where internalMetricInd = 0 order by 1 " 
							set rsSect = dataconn.execute(SQL) 
							while not rsSect.eof 
								response.write("<option>" & rsSect("ubprSection") & "</option>")
								rsSect.movenext 
							wend
							rsSect.close 
							set rsSect = nothing 
							%>
						</select>
					</td>
					
					<td class="formField">
						<label for="ubprLine">UBPR Line</label>
						<select id="ubprLine">
							<option selected>All</option>
							<%
							dbug("getting ubprLine...")
							SQL = "select distinct ubprLine from metric where internalMetricInd = 0 order by 1 " 
							set rsLine = dataconn.execute(SQL) 
							while not rsLine.eof 
								response.write("<option>" & rsLine("ubprLine") & "</option>")
								rsLine.movenext 
							wend
							rsLine.close 
							set rsLine = nothing 
							%>
						</select>
					</td>
				</tr>
			</table>
		</div>
		
		<div id="objectiveFields">
			<div class="formField metricName">
				<label for="metricName">Metric Name</label>
				<select id="metricName">
					<option selected disabled>Make a selection</option>
				</select>
			</div>
			
			<div class="formField customName">
				<label for="customName">Custom Name *</label>
				<input type="text" id="customName" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
			</div>
			
			<div class="formField objectiveNarrative">
				<label for="narrative">Narrative</label>
				<textarea id="narrative" class="ui-widget ui-state-default ui-corner-all" rows="3"></textarea>
			</div>		
			
			<table class="objectiveGoal">
				<tr>
					<td></td>
					<td class="label colHeader">Date</td>
					<td class="label colHeader">Value</td>
				</tr>
				<tr>
					<td class="label rowHeader">Start</td>
					<td>
						<div class="formField objectiveStartDate">
							<input type="text" id="objectiveStartDate" class="ui-widget ui-state-default ui-corner-all" autocomplete="off" readonly="readonly">
						</div>
					</td>
					<td>
						<div class="formField objectiveStartValue">
							<input type="text" id="objectiveStartValue" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
						</div>
					</td>
				</tr>
				<tr>
					<td class="label rowHeader">End</td>
					<td>
						<div class="formField objectiveEndDate">
							<input type="text" id="objectiveEndDate" class="ui-widget ui-state-default ui-corner-all" autocomplete="off" readonly="readonly">
						</div>
					</td>
					<td>
						<div class="formField objectiveEndValue">
							<input type="text" id="objectiveEndValue" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
						</div>
					</td>
				</tr>
			</table>	

		</div>
		
		<input type="hidden" id="objectiveID" />
		<input type="hidden" id="objectiveTypeID" />

 
      <!-- Allow form submission with keyboard without duplicating the dialog button -->
<!--       <input type="submit" tabindex="-1" style="position:absolute; top:-1000px"> -->
    </fieldset>
  </form>
</div>


<!-- add/edit dialog for opportunities -->
<div id="dialog_opportunity" title="Add new opportunity" style="display: none;">
	<form>
		<fieldset>
	
			<div class="formField opportunityTitle">
				<label for="oppTitle">Title</label>
				<input type="text" id="oppTitle" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
			</div>		
			
			<div class="formField opportunityNarrative">
				<label for="oppNarrative">Narrative</label>
				<textarea id="oppNarrative" class="ui-widget ui-state-default ui-corner-all" rows="3"></textarea>
			</div>		
			
			<table>
				<tr>
					
				<td class="formField oppStartDate">
					<label for="oppStartDate">Start date</label>
					<input type="text" id="oppStartDate" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
				</td>
				
				<td class="formField oppEndDate">
					<label for="oppEndDate">End date</label>
					<input type="text" id="oppEndDate" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
				</td>
				
				<td class="formField oppValue">
					<label for="oppValue">Value</label>
					<input type="text" id="oppValue" class="ui-widget ui-state-default ui-corner-all" autocomplete="off">
				</td>
				
				</tr>
			</table>
		
			<!-- Allow form submission with keyboard without duplicating the dialog button -->
<!-- 			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px"> -->
			
		</fieldset>
	</form>
</div>


<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
		
		<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

    </div>

	 <!-- #include file="includes/customerTabs.asp" -->

  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer Intentions</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">

		<div class="page-content">


			<!-- Intention TITLE -->
			<div class="mdl-grid title">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--9-col" align="center">
					<div class="mdl-typography--title">
						<% =rsImp("name") & ":&nbsp;" & formatDateTime(rsImp("startDate"),2) & "-" & formatDatetime(rsImp("endDate")) %>
					</div>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>

			<%
			dbug("getting customerObjectives...")
			sql 	= "select " &_
							"o.id as objectiveID, " &_
							"o.narrative, " &_
							"CASE WHEN o.customName = 'NULL' THEN null else o.customName END as customName, " &_
							"o.objectiveTypeID, " &_
							"o.opportunityID, " &_
							"o.startDate, " &_
							"o.startValue, " &_
							"o.endDate, " &_
							"o.endValue, " &_
							"pgt.description as pgtDescription, " &_
							"m.id as metricID, " &_
							"m.name as metricName, " &_
							"m.internalMetricInd, " &_
							"m.dataType, " &_
							"m.displayUnitsLabel, " &_
							"m.financialCtgy, " &_
							"m.ubprSection, " &_
							"m.ubprLine, " &_
							"m.type, " &_
							"mt.name as metricType, " &_
							"mt.allowValuesEdit " &_
						"from customerObjectives o " &_
						"left join fdic.dbo.peerGroupType pgt on (pgt.id = o.peerGroupTypeID) " &_
						"left join metric m on (m.id = o.metricID) " &_
						"left join metricTypes mt on (mt.id = m.metricTypeID) " &_
						"where implementationID = " & implementationID & " " &_
						"order by o.id " 
					
			dbug(sql)
			set rsUte = dataconn.execute(sql)
			%>			
			
			<!-- OPPORTUNITIES -->
			<div class="accordian" style="width: 90%; margin: auto;">
				<h3>
					<span>Opportunities&nbsp;&nbsp;<i class="material-icons addOpportunity" title="Add a new opportunity">add_box</i></span>
					<span style="float: right;">
						<div style="text-align: right; margin-right: 40px;">Total Economic Value:&nbsp;<span id="totalEconomicValue"></span></div>
					</span>
				</h3>
				<div>
				<%
				dbug("getting customerOpportunities")
				sql = "select * " &_
						"from customerOpportunities " &_
						"where implementationID = " & implementationID & " "
						
				dbug(sql)
				set rsOpp = dataconn.execute(sql)
				while not rsOpp.eof
					if len( rsOpp("title") ) > 0 then 
						title = rsOpp("title") 
					else 
						title = "Opportunity"
					end if
					%>	
					<div class="accordianInner customerOpportunity" data-opportunityID="<% =rsOpp("id") %>" id="opp-<% =rsOpp("id") %>">
						<h3>
							
							<span><span class="oppTitle"><% =title %></span>&nbsp;&nbsp;
								<i class="material-icons addObjective" title="Add a new objective to the opportunity">add_box</i>
								<i class="material-icons editOpportunity" title="Edit this opportunity">edit</i>
								<i class="material-icons deleteOpportunity" title="Delete this opportunity">delete</i>
							</span>
							<span style="float: right;">
								<%
								if len( rsOpp("startDate") ) > 0 then 
									startDate = formatDateTime( rsOpp( "startDate" ) )
								else 
									startDate = ""
								end if 
								if len( rsOpp("endDate") ) > 0 then 
									endDate = formatDateTime( rsOpp( "endDate" ) )
								else 
									endDate = ""
								end if 
								%>
								<div style="width: 150px; text-align: right; display: inline-block;">Start:&nbsp;<span class="startDate"><% =startDate %></span></div>
								<div style="width: 150px; text-align: right; display: inline-block;">End:&nbsp;<span class="endDate"><% =endDate %></span></div>
								<div style="width: 150px; text-align: right; display: inline-block;">Value:&nbsp;<span class="value"><% =formatCurrency(rsOpp("annualEconomicValue"),0) %></span></div>
							</span>
						</h3>
						<div>

						<div class="mdl-grid">
							<div class="mdl-cell mdl-cell--12-col narrative">
								<% =rsOpp("narrative") %>
							</div>
						</div>
						<%
						rsUte.filter = "objectiveTypeID = 2 and opportunityID = " & rsOpp("id") & " "
						while not rsUte.eof

							if rsUte("allowValuesEdit") then 
								showEditValuesButton = true
							else 
								showEditValuesButton = false
							end if
		
							%>					
							<div class="mdl-grid objective" id="obj-<% =rsUte("objectiveID") %>">
								<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp customerObjective">
									
									<table class="metric">
										<% if len(rsUte("narrative")) then %>
											<tr><td class="label">Narrative:</td><td><% =rsUte("narrative") %></td></tr>
										<% end if %>
										<tr><td class="label">Type:</td><td><% =rsUte("metricType") %></td></tr>
										<% if len(rsUte("financialCtgy")) then %>
											<tr><td class="label">Category:</td><td><% =rsUte("financialCtgy") %></td></tr>
										<% end if %>
										<% if len(rsUte("ubprSection")) then %>
											<tr><td class="label">UBPR Section:</td><td><% =rsUte("ubprSection") %></td></tr>
										<% end if %>
										<% if len(rsUte("ubprLine")) then %>
											<tr><td class="label">UBPR Line:</td><td><% =rsUte("ubprLine") %></td></tr>
										<% end if %>
										<% if len(rsUte("customName")) > 0 then %>
											<tr><td class="label">Custom Name:</td><td><% =rsUte("customName") %></td></tr>
										<% end if %> 
										<% if len(rsUte("pgtDescription")) > 0 then %>
											<tr><td class="label">Peer Group Type:</td><td><% =rsUte("pgtDescription") %></td></tr>
										<% end if %>			
										
										<tr><td class="label">Objective:</td><td><% =displayObjectiveGoal( rsUte("startDate"), rsUte("startValue"), rsUte("endDate"), rsUte("endValue"), rsUte("dataType"), rsUte("displayUnitsLabel") ) %></td></tr>
															
									</table>

									<div class="actionIcons" data-objectiveID="<% =rsUte("objectiveID") %>" data-metricID="<% =rsUte("metricID") %>">
										<% if (userPermitted(83) AND showEditValuesButton) then %><i class="material-icons editCustomerMetricValues" style="cursor: pointer;" title="Edit values for this objective">add_chart</i><% end if %>
										<% if userPermitted(82) then %><i class="material-icons deleteObjective" style="cursor: pointer;" title="Delete this objective">delete</i><% end if %>
										<% if userPermitted(81) then %><i class="material-icons editObjective" style="cursor: pointer;" title="Edit this objective" >edit</i><% end if %>
									</div>
									
								</div>
								<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp">
									<div data-title="<% =rsUte("metricName") %>" class="metric"></div>
								</div>
							</div>
							<%
							rsUte.movenext 
						wend 
						%>				



						</div>
					</div>
					<%
					rsOpp.movenext 
				wend 
				rsOpp.close 
				set rsOpp = nothing 
				%>				
				</div>

			</div>

			<!-- UTOPIA OBJECTIVES -->
			<div class="accordian" style="width: 90%; margin: auto;">
				<h3>Utopia&nbsp;&nbsp;<i class="material-icons addObjective" title="Add a new objective to Utopia">add_box</i> </h3>

				<div>
				<%
				rsUte.filter = "objectiveTypeID = 1"
				while not rsUte.eof

					if rsUte("allowValuesEdit") then 
						showEditValuesButton = true
					else 
						showEditValuesButton = false
					end if

					%>					
					<div class="mdl-grid objective" id="obj-<% =rsUte("objectiveID") %>">
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp customerObjective">
							
							<table class="metric">
								<% if len(rsUte("narrative")) then %>
									<tr><td class="label">Narrative:</td><td><% =rsUte("narrative") %></td></tr>
								<% end if %>
								<tr><td class="label">Type:</td><td><% =rsUte("metricType") %></td></tr>
								<% if len(rsUte("financialCtgy")) then %>
									<tr><td class="label">Category:</td><td><% =rsUte("financialCtgy") %></td></tr>
								<% end if %>
								<% if len(rsUte("ubprSection")) then %>
									<tr><td class="label">UBPR Section:</td><td><% =rsUte("ubprSection") %></td></tr>
								<% end if %>
								<% if len(rsUte("ubprLine")) then %>
									<tr><td class="label">UBPR Line:</td><td><% =rsUte("ubprLine") %></td></tr>
								<% end if %>
								<% if len(rsUte("customName")) > 0 then %>
									<tr><td class="label">Custom Name:</td><td><% =rsUte("customName") %></td></tr>
								<% end if %> 
								<% if len(rsUte("pgtDescription")) > 0 then %>
									<tr><td class="label">Peer Group Type:</td><td><% =rsUte("pgtDescription") %></td></tr>
								<% end if %>	
								
								<tr>
									<td class="label">Objective:</td>
									<td>
										<% =displayObjectiveGoal( rsUte("startDate"), rsUte("startValue"), rsUte("endDate"), rsUte("endValue"), rsUte("dataType"), rsUte("displayUnitsLabel") ) %>
									</td>
								</tr>
										
							</table>
							
							<div class="actionIcons" data-objectiveID="<% =rsUte("objectiveID") %>" data-metricID="<% =rsUte("metricID") %>">
								<% if (userPermitted(83) AND showEditValuesButton) then %><i class="material-icons editCustomerMetricValues" style="cursor: pointer;" title="Edit values for this objective">add_chart</i><% end if %>
								<% if userPermitted(82) then %><i class="material-icons deleteObjective" style="cursor: pointer;" title="Delete this objective">delete</i><% end if %>
								<% if userPermitted(81) then %><i class="material-icons editObjective" style="cursor: pointer;" title="Edit this objective" >edit</i><% end if %>
							</div>

						</div>
						<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp">
							<div class="progressbar"></div>
							<div data-title="<% =rsUte("metricName") %>" class="metric"></div>
						</div>
					</div>
					<%
					rsUte.movenext 
				wend 
				%>				
				</div>

			</div>
				

			<!-- KPI OBJECTIVES -->
			<div class="accordian" style="width: 90%; margin: auto;">
				<h3>KPIs&nbsp;&nbsp;<i class="material-icons addObjective addKPI" title="Add a new objective to KPIs">add_box</i> </h3>

				<div>
				<%
				rsUte.filter = "objectiveTypeID = 3"
				while not rsUte.eof

					if rsUte("allowValuesEdit") then 
						showEditValuesButton = true
					else 
						showEditValuesButton = false
					end if

					%>					
					<div class="mdl-grid objective kpi" id="obj-<% =rsUte("objectiveID") %>">
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp customerObjective">
							
							<table class="metric">
								<% if len(rsUte("narrative")) then %>
									<tr><td class="label">Narrative:</td><td><% =rsUte("narrative") %></td></tr>
								<% end if %>
								<tr><td class="label">Type:</td><td><% =rsUte("metricType") %></td></tr>
								<% if len(rsUte("financialCtgy")) then %>
									<tr><td class="label">Category:</td><td><% =rsUte("financialCtgy") %></td></tr>
								<% end if %>
								<% if len(rsUte("ubprSection")) then %>
									<tr><td class="label">UBPR Section:</td><td><% =rsUte("ubprSection") %></td></tr>
								<% end if %>
								<% if len(rsUte("ubprLine")) then %>
									<tr><td class="label">UBPR Line:</td><td><% =rsUte("ubprLine") %></td></tr>
								<% end if %>
								<% if len(rsUte("customName")) > 0 then %>
									<tr><td class="label">Custom Name:</td><td><% =rsUte("customName") %></td></tr>
								<% end if %> 
								<% if len(rsUte("pgtDescription")) > 0 then %>
									<tr><td class="label">Peer Group Type:</td><td><% =rsUte("pgtDescription") %></td></tr>
								<% end if %>	
								
								<tr>
									<td class="label">Objective:</td>
									<td>
										<% =displayObjectiveGoal( rsUte("startDate"), rsUte("startValue"), rsUte("endDate"), rsUte("endValue"), rsUte("dataType"), rsUte("displayUnitsLabel") ) %>
									</td>
								</tr>
										
							</table>
							
							<div class="actionIcons" data-objectiveID="<% =rsUte("objectiveID") %>" data-metricID="<% =rsUte("metricID") %>">
								<% if (userPermitted(83) AND showEditValuesButton) then %><i class="material-icons editCustomerMetricValues" style="cursor: pointer;" title="Edit values for this objective">add_chart</i><% end if %>
								<% if userPermitted(82) then %><i class="material-icons deleteObjective" style="cursor: pointer;" title="Delete this objective">delete</i><% end if %>
								<% if userPermitted(81) then %><i class="material-icons editObjective" style="cursor: pointer;" title="Edit this objective" >edit</i><% end if %>
							</div>

						</div>
						<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp">
							<div class="progressbar"></div>
							<div data-title="<% =rsUte("metricName") %>" class="metric"></div>
						</div>
					</div>
					<%
					rsUte.movenext 
				wend 
				%>				
				</div>

			</div>
				


		</div><!-- end of page content -->

	</main>

	<!-- #include file="includes/pageFooter.asp" -->
	
</div>


<%
rsUte.close 
set rsUte = nothing 

dataconn.close 
set dataconn = nothing
%>

</body>



</html>