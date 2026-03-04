<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess( 146 )

userLog("Events")
title = session("clientID") & " - Events"
%>
<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<script src="https://cdn.jsdelivr.net/npm/dayjs@1/dayjs.min.js"></script>

	<script>

		//============================================================================
		const dateRenderer = function ( data, type, row ) {
		//-----------------------------------------------------------------------------------
		
			if ( !data ) return '';
		
			const d = dayjs( data ); // your API returns ISO like 2026-05-12T15:00:00.000Z
		
			// what users see
			if ( type === 'display' || type === 'filter' ) {
				return d.format( 'M/D/YYYY' );
			}
		
			// what DataTables uses to sort
			return d.valueOf(); // number

		};
		//============================================================================


		//============================================================================
		const dateTimeRenderer = function ( data, type, row, meta ) {
		//============================================================================
		
			// Sorting/filtering: return something stable
			if ( type !== 'display' && type !== 'filter' ) {
				return data ? dayjs( data ).valueOf() : -Infinity; // null sorts first
			}
			
			// Display: ALWAYS render an input
			const idPrefix = ( meta.col === 0 ) ? 'start' : 'end';
			
			const val = data
				? dayjs( data ).format( 'YYYY-MM-DDTHH:mm' )
				: '';
			
			return (
				`<input type="datetime-local" ` +
				`class="dateTime ed-${idPrefix}" ` +
				`data-row-id="${row.id ?? ''}" ` +
				`value="${val}">`
			);
			
			
		};
		//============================================================================
	

		//============================================================================
		const booleanRenderer = function ( data, type ) {
		//============================================================================
		
			// sorting + filtering should use raw boolean
			if ( type !== 'display' ) {
				return data ? 1 : 0;
			}
		
			return data
				? '<span class="material-symbols-outlined is-virtual-icon">check</span>'
				: '';
		};			
		//============================================================================

		
		//============================================================================
		const actionRenderer = function ( data, type, row, meta ) {
		//============================================================================
		
		
			let actions = '';
			
			if ( meta.settings.sInstance === 'eventDaysTable') {
				if ( !data.id ) {
					actions += '<i class="material-symbols-outlined save" title="Save event date/time">save</i>';
				} else {
					actions += '<i class="material-symbols-outlined delete" title="Delete event date/time">delete_outline</i>';			
				}
				return actions;
			}
				
			actions += '<i class="material-symbols-outlined delete" title="Delete event date/time">delete_outline</i>';			
			actions += '<i class="material-symbols-outlined edit" title="Edit event">mode_edit</i>';
			
			return actions;

		};
		//============================================================================


		//============================================================================
		function ToggleActionIcons( htmlElement ) {
		//============================================================================

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
		//============================================================================


		//============================================================================
		async function openEventDialog( eventID ) {
		//============================================================================
			
			try {

				if ( eventID ) {
					const eventDetails = await getEventDetails( eventID );
					populateEventDialog( eventDetails );
				} else {
					resetEventDialog();
				}
				
				return $( "#dialog_event" )
					.data( 'eventID', eventID )
					.dialog( 'open' );
			
			} catch( err ) {

				throw new Error( err );

			}
			
		}
		//============================================================================
		
		
		//============================================================================
		async function populateTimezoneSelectmenu( selectedValue ) {
		//================================================================================

			try {
				
				$( '#event_timezone' ).find('option').remove().end();
				let options = [] 
				
				const data = await $.ajax({
					url: `${apiServer}/api/timezones`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT }
				});
		
				options.push( `<option disabled selected>Make a selection...</option>` );
				for ( row of data ) {
					const selected = ( row.id == selectedValue ) ? 'selected' : '';
					options.push( `<option value="${row.id}" ${selected}>${row.displayName}</option>` )
				}

				$( '#event_timezone' )
					.append( options.join( '' ) )
					.selectmenu( 'refresh' );	
						
				return;
	
			} catch( err ) {

				console.error( 'error retrieving timezone data', err );
				throw new Error( err );

			}

		}
		//============================================================================
		

		//============================================================================
		function populateEventDialog( eventDetails ) {
		//============================================================================
		
		
			$( '#dialog_event' ).dialog( 'option', { title: 'Edit Event' } );
			
			$( '#event_id' ).val( eventDetails.id );
			$( '#event_name' ).val( eventDetails.name );
			$( '#event_location' ).val( eventDetails.location );
			$( '#event_isVirtual' ).prop( 'checked', eventDetails.isVirtual );
			$( '#event_isVirtual' ).checkboxradio( 'refresh' );
			$( '#event_repeatAttendancePolicy' ).val( eventDetails.repeatAttendancePolicy );
			$( '#event_whoShouldAttend' ).val( eventDetails.whoShouldAttend );
			$( '#event_prerequisiteNotes' ).val( eventDetails.prerequisiteNotes );
			
			populateTimezoneSelectmenu( eventDetails.timezoneID );
			
			$( '#eventDaysTable' )
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'mouseout', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'click', 'i.save', async function( event ) {

					event.stopPropagation();

					let msg;
					const $tr = $( this ).closest( 'tr' );
					const eventDayID = $tr.prop( 'id' );
					const eventID = $( '#event_id' ).val();
					const startLocal = $tr.find( 'input.ed-start' ).val(); // "YYYY-MM-DDTHH:mm"
					const endLocal   = $tr.find( 'input.ed-end' ).val();
					
					const payload = {
						id: eventDayID,
						eventID: eventID,
						startDateTime: startLocal,
						endDateTime: endLocal
					}
					
					if ( eventDayID ) {

						const result = await $.ajax({
							url: `${apiServer}/api/eventDays`,
							method: "PUT",
							headers: { Authorization: "Bearer " + sessionJWT },
							dataType: "json",
							data: payload
						});
						
						msg = 'Event day udpated';
						

					} else {
						
						const result = await $.ajax({
							url: `${apiServer}/api/eventDays`,
							method: "POST",
							headers: { Authorization: "Bearer " + sessionJWT },
							dataType: "json",
							data: payload
						});
						
						msg = 'Event day added';
						
					}

					$( '#eventDaysTable' ).DataTable().ajax.reload();
										
					const notification = document.querySelector('.mdl-js-snackbar');
					notification.MaterialSnackbar.showSnackbar({ message: msg });

				})
				.on( 'click', 'i.delete', async function( event ) {
					
					event.stopPropagation();

					const eventDayID = $( this ).closest( 'tr' ).prop( 'id' );
					if ( confirm( `Delete event day?"\n\nThis action cannot be undone.` ) ) {
						deleteEventDay( eventDayID );
					}
					
				})

				.DataTable({
					ajax: {
						url: `${apiServer}/api/eventDaysByEvent?eventID=${eventDetails.id}`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columns: [
						{ data: 'startDateTime', className: 'startDateTime dt-body-center dt-head-center', render: dateTimeRenderer },
						{ data: 'endDateTime', className: 'startDateTime dt-body-center dt-head-center', render: dateTimeRenderer },
						{ data: null, className: 'actions dt-body-center dt-head-center', orderable: false, defaultContent: '', render: actionRenderer },
					],
					deferRender: true,
					rowId: 'id',
					scrollY: '350px',
					scroller: true,
					scrollCollapse: true,
					searching: false,
	
				});			
			
		}
		//============================================================================


		//============================================================================
		function resetEventDialog() {
		//============================================================================


			$( '#dialog_event' ).dialog( 'option', { title: 'Add Event' } );
			
			$( this ).removeData( 'eventID' );
			$( '#event_id' ).val( null );
			$( '#event_name' ).val( null );
			$( '#event_location' ).val( null );
			$( '#event_startDate' ).datepicker( 'setDate', null );
			$( '#event_endDate' ).datepicker( 'setDate', null );
			$( '#event_isVirtual' ).prop( 'checked', false );
			$( '#event_isVirtual' ).checkboxradio( 'refresh' );
			$( '#event_repeatAttendancePolicy' ).val( null );
			$( '#event_whoShouldAttend' ).val( null );
			$( '#event_prerequisiteNotes' ).val( null );
			
			$( '#eventDaysTable' ).DataTable().destroy();
// 	      $( '#eventDaysTable' ).empty(); // important

		}
		//============================================================================


		//============================================================================
		async function getEventDetails( eventID ) {
		//============================================================================

			try {

				return await $.ajax({
					url: `${apiServer}/api/events/${eventID}`,
					method: "GET",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json"
				});
								
			} catch ( err ) {

				console.error( 'Unexpected error retrieving event details' );
				throw new Error( err );
		
			}

		}
		//============================================================================
	
		
		//============================================================================
		async function deleteEvent( eventID ) {
		//============================================================================

			try {

				await $.ajax({
					url: `${apiServer}/api/events/${eventID}`,
					method: "DELETE",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json"
				});
				
				$('#eventsTable').DataTable().ajax.reload( null, false );

				const notification = document.querySelector('.mdl-js-snackbar');
				notification.MaterialSnackbar.showSnackbar({ message: 'Event deleted' });
				
				return;
								
			} catch ( err ) {

				console.error( 'Unexpected error deleting event' );
				throw new Error( err );
		
			}

		}
		//============================================================================


		//============================================================================
		async function deleteEventDay( eventDayID ) {
		//============================================================================

			try {

				await $.ajax({
					url: `${apiServer}/api/eventDays/${eventDayID}`,
					method: "DELETE",
					headers: { Authorization: "Bearer " + sessionJWT },
					dataType: "json"
				});
				
				const notification = document.querySelector('.mdl-js-snackbar');
				notification.MaterialSnackbar.showSnackbar({ message: 'Event day deleted' });
				
				$('#eventDaysTable').DataTable().ajax.reload( null, false );

				return;
								
			} catch ( err ) {

				console.error( 'Unexpected error deleting event dayt' );
				throw new Error( err );
		
			}

		}
		//============================================================================


		//============================================================================
		function addNewEventDayRow( dt ) {
		//============================================================================
		
		  const newRow = {
		    id: null,
		    startDateTime: null,
		    endDateTime: null
		  };
		
		  // add + draw without resetting paging
		  const rowApi = dt.row.add( newRow ).draw( false );
		
		  // make sure the row is visible (works with scrollY)
		  const node = rowApi.node();
		
		  if ( node && node.scrollIntoView ) {
		    node.scrollIntoView({ block: 'nearest' });
		  }
		  
		}
		//============================================================================
	
		
		//============================================================================
		function getEventDaysPayload( dt ) {
		//============================================================================
		
			const eventDays = [];

			dt.rows().every( function() {
			
				const rowData = this.data();   // { id, startDateTime, endDateTime, ... }
				const $tr = $( this.node() );  // <tr> for this row
				
				const startLocal = $tr.find( 'input.ed-start' ).val(); // "YYYY-MM-DDTHH:mm"
				const endLocal   = $tr.find( 'input.ed-end' ).val();
				
				eventDays.push({
					id: rowData.id,                 // null => insert, non-null => update
					startDateTime: startLocal || null,
					endDateTime: endLocal || null
				});

			});
			
			return eventDays;

		}
		//============================================================================


		//============================================================================
		$(document).ready(function() {
		//============================================================================
		
			const eventID = new URLSearchParams( window.location.search ).get( 'eventID' );

			$( document ).tooltip();


			//-----------------------------------------------------------------------------------
			const registrationsTable = $('#registrationsTable')
			//-----------------------------------------------------------------------------------
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'mouseout', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/eventRegistrationsByEvent?eventID=${eventID}`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columns: [
						{ data: 'title', className: 'title dt-body-left dt-head-left' },
						{ data: 'fullName', className: 'fullName dt-body-left dt-head-left' },
						{ data: 'customerName', className: 'customerName dt-body-left dt-head-left' },
						{ data: 'customerStatusName', className: 'customerStatusName dt-body-left dt-head-left' },
						{ data: 'learnerProfileID', className: 'learnerProfileID dt-body-center dt-head-center', visible: false },
						{ data: 'learnerProfileName', className: 'learnerProfileName dt-body-left dt-head-left' },
						{ data: 'registrationDate', className: 'registrationDate dt-body-center dt-head-center', render: dateRenderer },
						{ data: 'curriculumPlanID', className: 'curriculumPlanID dt-body-center dt-head-center' },
						{ data: 'payTypeID', className: 'payTypeID dt-body-center dt-head-center',visible: false },
						{ data: 'paymentTypeName', className: 'paymentTypeName dt-body-center dt-head-center' },
						{ data: 'certificateCount', className: 'certificateCount dt-body-center dt-head-center' },
						{ data: 'registrationStatusID', className: 'registrationStatusID dt-body-center dt-head-center' },
						{ data: 'notes', className: 'notes dt-body-center dt-head-center', visible: false },
						{ data: 'hubspot_object_id', className: 'hubspot_object_id dt-body-center dt-head-center' },
						{ data: 'taggedInHubspotInd', className: 'taggedInHubspotInd dt-body-center dt-head-center', render: booleanRenderer },
						{ data: 'prerequisiteOverrideReason', className: 'prerequisiteOverrideReason dt-body-center dt-head-center' },
						{ data: 'prerequisiteOverrideAuthorizedBy', className: 'prerequisiteOverrideAuthorizedBy dt-body-center dt-head-center' },

						{ data: null, className: 'actions dt-body-center dt-head-center', orderable: false, defaultContent: '', render: actionRenderer },
					],
					deferRender: true,
					rowId: 'id',
					scrollY: 630,
					scroller: { rowHeight: 35 },
					scrollCollapse: true,
	
				});
			//-----------------------------------------------------------------------------------


			//-----------------------------------------------------------------------------------
			$( '#button_newEvent' ).on( 'click', function( event ) {
			//-----------------------------------------------------------------------------------

				openEventDialog( null );

			});
			//-----------------------------------------------------------------------------------

			
			//-----------------------------------------------------------------------------------
			$( '#newEventDateTime' ).on( 'click', function( event ) {
			//-----------------------------------------------------------------------------------
				
				addNewEventDayRow( $('#eventDaysTable' ).DataTable() );
				
			});
			//-----------------------------------------------------------------------------------



		});		
		//============================================================================
		
	</script>
	
	
	<style>
	
/*
		.is-virtual-icon {
			font-size: 20px;
			line-height: 1;
			vertical-align: middle;
			color: #2e7d32;
		}
*/

		i.delete, i.edit {
			visibility: hidden;
		}


	.event-form-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 16px 24px;
	}

	.event-col .field-row {
		margin-bottom: 12px;
	}

/*
	.field-row label {
		display: block;
		margin-bottom: 4px;
		font-weight: 600;
	}
*/

	.field-row .text {
		width: 100%;
		box-sizing: border-box;
		padding: 6px 8px;
	}

	.field-row-wide {
		margin-top: 8px;
	}

	.field-hint {
		margin-top: 4px;
		font-size: 12px;
		opacity: 0.8;
	}

	.req {
		color: #b00020;
	}

	.event-audit {
		margin-top: 12px;
		padding-top: 10px;
		border-top: 1px solid #ddd;
		font-size: 12px;
		opacity: 0.9;
	}

	.audit-row {
		display: grid;
		grid-template-columns: 90px 1fr;
		gap: 8px;
		margin-top: 4px;
	}
	
	.field-row > label,
	.field-row > .label {
		font-weight: bold;
	}

	/* wrapper around the table so this doesn't affect other DataTables */
	#eventDaysWrap .dt-scroll-body {
		height: 115px !important;
		max-height: 115px !important;
	}
	
#eventDaysWrap > .field-row {
  display: flex;
  align-items: center;
}

#eventDaysWrap .event_timezone {
  margin-left: auto;
}

#eventDaysWrap .event_timezone label {
	font-weight: bold;
}	
	</style>

</head>

<body>

	<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content">
		<!-- Your content goes here -->




<!-- ========================================================================= -->
<!-- jQuery UI Dialog: Add/Edit Event                                          -->
<!-- ========================================================================= -->


		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col" align="left">
				<button id="button_newEvent" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Event Registration
				</button>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
			
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--10-col" align="center">


				<table id="registrationsTable" class="compact display">
					<thead>
						<tr>
							<th class="title">Title</th>
							<th class="fullName">Full Name</th>
							<th class="customerName">Customer</th>
							<th class="customerStatusName">Customer<br>Status</th>
							<th class="learnerProfileID">Learner Profile ID</th>
							<th class="learnerProfileName">Learner Profile</th>
							<th class="registrationDate">Registration<br>Date</th>
							<th class="curriculumPlanID">curriculumPlanID</th>
							<th class="payTypeID">payTypeID</th>
							<th class="paymentTypeName">Payment Type</th>
							<th class="certificateCount">Cert #</th>
							<th class="registrationStatusID">Registration Status</th>
							<th class="hubspot_object_id">HubSpot ID</th>
							<th class="taggedInHubspotInd">HubSpot?</th>
							<th class="prerequisiteOverrideReason">Prerequisite Override Reason</th>
							<th class="actions">Actions</th>
						</tr>
					</thead>
				</table>


			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
	</div>
		


</main>

<!-- #include file="includes/pageFooter.asp" -->
<%
dataconn.close 
set dataconn = nothing
%>
</body>
</html>