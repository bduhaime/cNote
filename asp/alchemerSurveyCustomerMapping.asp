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
call checkPageAccess( 143 )


title = session("clientID") & " - Alchemer Survey/Customer Mapping" 
userLog(title)

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<!-- 	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script> -->

	<script>

		//--------------------------------------------------------------------------------
		function updateSurvey( elem ) {
		//--------------------------------------------------------------------------------

			let surveyID = $( elem ).closest( 'tr' ).attr( 'id' );
			let customerID = $( `#${surveyID} select.customer` ).val();
			let employeesSurveyed = $( `#${surveyID} input.employeesSurveyed` ).val();
						
			let message;
			
			$.ajax({

				url: `${apiServer}/api/surveys`,
				type: 'PUT',
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: { 
					surveyID: surveyID, 
					employeesSurveyed: employeesSurveyed,
					customerID: customerID 
				}

			}).done( function() {

				message = 'Survey updated';

			}).fail( function( err ) {

					message = 'Error while updating survey';
					console.error( err );

			}).always( function() {

				document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
					message: message
				});
				
			});

			
		}
		//--------------------------------------------------------------------------------
		
		
		
		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------


			// use ajax to get JSON of customers
			// then build a <select> element -- this will be cloned into each row of the DataTable
			//		for the user to identify which cNote customer is associated with each survey
			//	next build a <input> element -- this will also be cloned into each row of the
			//		DataTable for the user to input the total number of employees targeted for each
			//		surve. This is used to determine participation percentage
			// then build the DataTable
			//   	for the customerName column, render a clone of the <select> element
			//		for the employeesSurveyed column, render a clone of the <input> element
			// that's the plan, anyway...

			let selectTemplate;
			$( document ).tooltip();
			
			$.ajax({
				url: `${apiServer}/api/surveys/customers`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
			}).done( function( response ) {
				
				selectTemplate = document.createElement( 'select' );
				$( selectTemplate ).addClass( 'customer' );
				
				inputTemplate = document.createElement( 'input' );
				$( inputTemplate ).addClass( 'employeesSurveyed' );
				

				let firstOpt = document.createElement( 'option' );
				firstOpt.value = '';
				firstOpt.innerHTML = 'Select a customer...';
				selectTemplate.appendChild( firstOpt );
				
				for ( customer of response ) {
					let opt = document.createElement( 'option' );
					opt.value = customer.id;
					opt.innerHTML = customer.name;
					selectTemplate.appendChild( opt );
				}
				
				
				
			}).fail( function( err ) {
				alert( 'Something went wrong, contact system administrator (err: ' + err );
			}).then( function() {
				
				var table = $( '#surveys' )
					.on( 'change', 'select.customer', function() {
						updateSurvey( this ); 
					})
					.on( 'change', 'input.employeesSurveyed', function() {
						updateSurvey( this );
					})
					.DataTable({
						ajax: {
							url: `${apiServer}/api/surveys`,
							headers: { 'Authorization': 'Bearer ' + sessionJWT },
							dataSrc: ''
						},
						deferRender: true,
						rowId: 'surveyID',
						scrollY: 630,
						scroller: {
							rowHeight: 38,
						},
						scrollCollapse: true,
						columnDefs: [
							{ targets: 'title', data: 'title', className: 'title dt-body-left', searchable: true },
							{ targets: 'type', data: 'type', className: 'type dt-body-center', searchable: true, visible: true },
							{ targets: 'status', data: 'status', className: 'status dt-body-center', searchable: true },
							{ targets: 'tegType', data: 'tegType', className: 'tegType dt-body-center', visible: false },
							{
					        targets: 'merge',
					        data: null,
					        className: 'merge dt-body-center',
					        render: function( data, type, row ) {
					            if (row.type === "360Feedback") {
					                return `<span class="merge material-symbols-outlined" title="Merge Respondents" onclick="window.location.href='alchemerSurveyRespondents.asp?surveyID=${encodeURIComponent(row.surveyID)}&title= + ${encodeURIComponent(row.title)}';">merge</span>`;
					            }
					            return ''; // Return empty if not '360Survey'
					        },
					        orderable: false,
					        searchable: false
						   },
						   { 
								targets: 'employeesSurveyed', 
								data: 'employeesSurveyed', 
								className: 'employeesSurveyed dt-body-center',
								render: function( data, type, row ) {
									
									let inputValue = ( row.employeesSurveyed ) ? row.employeesSurveyed : '';
									
									return `<input class="employeesSurveyed" value="${inputValue}">`
									
								},
								searchable: false,
							},
							{ targets: 'customerID', data: 'customerID', className: 'customerID dt-body-center', visible: false },
							{
								targets: 'customerName', 	
								data: 'customerName', 	
								className: 'customerName dt-body-center', 
								orderable: false,
								render: function( data, type, row ) {

									let $newSelect = $( selectTemplate ).clone( true );
									if ( row.customerID ) {
										$newSelect.find( `option[value="${row.customerID}"]` ).attr( 'selected', true );
									}

									return $newSelect.prop( 'outerHTML' );
		
								},
								searchable: false,
							},
						],
					});


			});
			
			
// 			$( 'input.employeesSurveyed' ).change( function() {
// 				
// 				let surveyID = $( this ).closest( 'tr' ).attr( 'id' );
// 				let employeesSurveyed = $( this ).val();
// 				
// 				$.ajax({
// 					url: `${apiServer}/api/surveys`,
// 					type: 'PUT',
// 					headers: { 'Authorization': 'Bearer ' + sessionJWT },
// 					data: { surveyID: surveyID, employeesSurveyed: employeesSurveyed }
// 				}).done( function() {
// 					console.log( 'Survey updated with employeesSurveyed' );				
// 				}).fail( function() {
// 					console.error( 'update of survey failed' );
// 				})
// 
// 			})
			


			
// 			$( 'input.employeesSurveyed' ).on( 'change', function() {
// 				
// 				let surveyID = $( this ).closest( 'tr' ).attr( 'id' );
// 				let customerID = $( `#${surveyID} select.customer` ).val()
// 				let employeesSurveyed = $( `#${surveyID} input.employeesSurveyed` ).val();
// 				
// 				if ( isNaN( employeesSurveyed ) ) {
// 					$( this ).focus().select();
// 					alert( 'Number of employees surveyed must be nmeric' );
// 					return false
// 				}
// 				
// 				$.ajax({
// 					url: `${apiServer}/api/surveys`,
// 					type: 'PUT',
// 					headers: { 'Authorization': 'Bearer ' + sessionJWT },
// 					data: { 
// 						surveyID: surveyID, 
// 						employeesSurveyed: employeesSurveyed,
// 						customerID: customerID 
// 					}
// 				}).done( function() {
// 
// 					document.querySelector( '#snackbar' ).MaterialSnackbar.showSnackbar({ 
// 						message: 'Survey updated',
// 						timeout: 1250
// 					});
// 
// 				}).fail( function() {
// 					console.error( 'update of survey failed' );
// 				})
// 				
// 			});
			


		});


	</script>
	
	<style>

		.merge.material-symbols-outlined {
			cursor: pointer;
		}
		
	</style>
	
</head>
	
<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
		
		<div id="snackbar" class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>
			
		<br><br>
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--11-col">
		
				<table id="surveys" class="compact display">
					<thead>
						<tr>
							<th class="title">Title</th>
							<th class="type">Type</th>
							<th class="status">Status</th>
							<th class="tegType">TEG Type</th>
							<th class="merge">Merge<br>Respondents</th>
							<th class="employeesSurveyed"># Empl Surveyed</th>
							<th class="customerID">customerID</th>
							<th class="customerName">Customer</th>
 						</tr>
					</thead>
				</table>
				
			</div>

			<div class="mdl-layout-spacer"></div>
		
		</div><!-- end mdl-grid -->
		
	</div><!-- end page-content -->
    
	<!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>