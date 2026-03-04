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
call checkPageAccess(145)

userLog("Job Status")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Job Status" 
%>

<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script>


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


			$( "#jobNameFilter" ).selectmenu({
				change: function( event, ui ) {

					var table = $( '#jobStatus' ).DataTable();
					var searchFor = $( this ).val();
					if ( searchFor == 'All' ) {
						searchFor = '';
					}
					table.column( '.jobName' ).search( searchFor ).draw();

				}
			});



				
				
			var table = $( '#jobStatus' )

				.DataTable({

					initComplete: function() {
						var jobNameColumn = this.api().column( 0 ); // Assuming 'jobName' is column 0
						var jobNameFilter = $('#jobNameFilter');
						
						jobNameColumn.data().unique().sort().each( function (value) {
							jobNameFilter.append(new Option(value, value));
						});
					},
					rowId: 'id',
					scrollX: true,
					scrollY: 610,
					scroller: true,
					scrollCollapse: true,
					ajax: { 
						url: `${apiServer}/api/jobStatus`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
					},
					dataSrc: '',
					columnDefs: [
						{ targets: 'jobName', data: 'jobName', className: 'jobName' },

						{ targets: 'version', data: 'version', className: 'version' },
						{ targets: 'runType', data: 'runType', className: 'runType' },


						{ 
							targets: 'startDateTime', 
							data: 'startDateTime', 
							render: function(data, type) {
								if (type === 'sort') {
						      	return moment(data).valueOf();
						   	}
								return ( !!data ) ? moment(data).format('YYYY-MM-DD hh:mm A') : null;
						  	},
						  	className: 'startDateTime'
						},

						{ 
							targets: 'endDateTime', 
							data: 'endDateTime', 
							render: function(data, type) {
								if (type === 'sort') {
									return moment(data).valueOf();
						   	}
								return ( !!data ) ? moment(data).format('YYYY-MM-DD hh:mm A') : null;
							className: 'endDateTime' 
							}
						},

						{ targets: 'status', data: 'status', className: 'status' },
						{ targets: 'message', data: 'message', className: 'message' },
					],
					order: [[ 3, 'desc' ]],

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
	
	
	<div class="page-content">
	<!-- Your content goes here -->
		
		<!-- 	Filters -->
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--10-col">

				<div class="filters">
					
					<label for="jobNameFilter"><b>Job Name:</b></label>
					<select id="jobNameFilter">
						<option>All</option>
					</select>
					
				</div>

		   </div>
			<div class="mdl-layout-spacer"></div>
	   </div>

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
		   <div class="mdl-cell mdl-cell--10-col" >

				<table id="jobStatus" class="compact display" style="width: 100%;">
					<thead>
						<tr>
							<th class="jobName">Job Name</th>
							<th class="version">Version</th>
							<th class="runType">Run Type</th>
							<th class="startDateTime">Start Date/Time</th>
							<th class="endDateTime">End Date/Time</th>
							<th class="status">Status</th>
							<th class="message">Message</th>
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