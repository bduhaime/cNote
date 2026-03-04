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


title = session("clientID") & " - Alchemer Survey Respondents" 
userLog(title)

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->


	<!-- 	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script> -->

	<script>

		const params = new URLSearchParams(window.location.search);
		const surveyID = params.get('surveyID');


		//--------------------------------------------------------------------------------
		function updateRelationship( input, surveyID, responseID, key ) {
		//--------------------------------------------------------------------------------
			// Example AJAX call to update the server on changes

			var notification = document.querySelector('.mdl-js-snackbar');
			notification.MaterialSnackbar.showSnackbar({ message: 'Updating...' });

			$.ajax({
				url: `${apiServer}/api/survey/respondents/update?surveyID=${surveyID}&responseID=${responseID}&key=${key}&relationship=${encodeURIComponent(input.value)}`,
				method: 'POST',
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				success: function(response) {
					notification.MaterialSnackbar.showSnackbar({ message: 'Relationship updated' });
				},
				error: function(error) {
					notification.MaterialSnackbar.showSnackbar({ message: 'Update failed' });
					console.error('Update failed', error);
				}
			});

		}
		//--------------------------------------------------------------------------------


		//--------------------------------------------------------------------------------
		$(document).ready(function() {
		//--------------------------------------------------------------------------------

			let selectTemplate;
			$( document ).tooltip();
			
			const uniqueTimestamp = new Date().getTime(); // Gets the current time in milliseconds
			
			
				
			var table = $( '#respondents' )
				.DataTable({
					ajax: {
						url: `${apiServer}/api/survey/respondents`,
						data: {
							surveyID: surveyID,
							cacheBust: uniqueTimestamp,
						},
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					deferRender: true,
					height: 37,
					scrollY: 630,
					scroller: {
						rowHeight: 30,
					},
					scrollCollapse: true,
					columnDefs: [
						{ targets: 'DT_RowId', data: 'DT_RowId', className: 'DT_RowId dt-body-left', searchable: true },
						{ targets: 'status', data: 'status', className: 'status dt-body-left', searchable: true, visible: true },
						{ 
							targets: 'isTestData', 
							data: 'isTestData', 
							className: 'isTestData dt-body-left', 
							visible: false,
							render: function( data, type, row ) {
							   if (data === "1") {
							       return `<span class="material-symbols-outlined">check_box</span>`;
							   } else {
							       return `<span class="material-symbols-outlined">check_box_outline_blank</span>`;
							   }
							},
							
						},
						{ targets: 'key', data: 'key', className: 'key dt-body-left', searchable: true, visible: false },
						{ 
							targets: 'relationship', 
							data: 'relationship', 
							className: 'relationship dt-body-left', 
							searchable: true, 
							render: function(data, type, row) {
								// Return input box with current data as value
								if ( data === "yourself" || row.status !== "Complete" ) {
									return data 
								} else {
									return `<input type="text" class="form-control" value="${data}" onchange="updateRelationship(this, surveyID, '${row.DT_RowId}', '${row.key}' ) ">`;
								}
							}
						},
					],
				});
				


		});


	</script>
	
	<style>

		.merge.material-symbols-outlined {
			cursor: pointer;
		}
		
		.surveyTitle {
			text-align: center;
			font-size: 18px;
			font-weight: bold;
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
			<div class="mdl-cell mdl-cell--7-col surveyTitle"><% =request.querystring("title") %></div>
			<div class="mdl-layout-spacer"></div>
		</div>
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--3-col">
		
				<table id="respondents" class="compact display">
					<thead>
						<tr>
							<th class="DT_RowId">ID</th>
							<th class="status">Status</th>
							<th class="isTestData">Test?</th>
							<th class="key">Key</th>
							<th class="relationship">Relationship</th>
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