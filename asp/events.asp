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
		//-----------------------------------------------------------------------------------
		
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
		//-----------------------------------------------------------------------------------
		
		
			let actions = '';
			
			if ( meta.settings.sInstance === 'eventDaysTable') {
				if ( !data.id ) {
					// actions += '<i class="material-symbols-outlined save" title="Save event date/time">save</i>';
				} else {
					actions += '<i class="material-symbols-outlined delete" title="Delete event date/time">delete_outline</i>';			
				}
				return actions;
			}
				
			actions += '<i class="material-symbols-outlined delete" title="Delete event">delete_outline</i>';			
			actions += '<i class="material-symbols-outlined addDays" title="Add days to event">calendar_add_on</i>';			
			actions += '<i class="material-symbols-outlined edit" title="Edit event">mode_edit</i>';
			
			return actions;

		};
		//============================================================================


		//============================================================================
		function setNewEventDateTimeEnabled( enabled ) {
		//============================================================================

			const $icon = $( "#newEventDateTime" );
			
			$icon
				.toggleClass( "is-disabled", !enabled )
				.attr( "aria-disabled", String( !enabled ) );

		}
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
		async function openEventDaysDialog( eventID ) {
		//============================================================================
			
			try {

				if ( eventID ) {
					const eventDetails = await getEventDetails( eventID );
					populateEventDaysDialog( eventDetails );
				} else {
					resetEventDaysDialog();
				}
				
				return $( "#dialog_eventDays" )
					.data( 'eventID', eventID )
					.dialog( 'open' );
			
			} catch( err ) {

				throw new Error( err );

			}
			
		}
		//============================================================================
		
		
		//================================================================================
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
		//================================================================================
		

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
			
		}
		//============================================================================


		//============================================================================
		function populateEventDaysDialog( eventDetails ) {
		//============================================================================
		
		
			$( '#dialog_eventDays' ).dialog( 'option', { title: 'Edit Event Days' } );
			
			$( '#event_id_days' ).val( eventDetails.id );

			populateTimezoneSelectmenu( eventDetails.timezoneID );
			
			if ( !eventDetails.timezoneID ) {
				setNewEventDateTimeEnabled( false );  // disable
			} else {
				setNewEventDateTimeEnabled( true );  // enable
			}
			
			const eventDaysDt = $( '#eventDaysTable' )
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
					
					event.preventDefault();
					event.stopPropagation();

					deleteEventDayRow( eventDaysDt, this );				
				
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
		function resetEventDaysDialog() {
		//============================================================================


			$( '#dialog_eventDays' ).dialog( 'option', { title: 'Add Event' } );
			
			$( this ).removeData( 'eventID' );
			$( '#event_id_days' ).val( null );

			$( '#eventDaysTable' ).DataTable().destroy();

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
		function deleteEventDayRow( dt, clickedEl ) {
		//============================================================================

			// clickedEl = the delete icon element the user clicked (e.g., `this`)
			
			// find the row that contains the clicked icon
			let $tr = $( clickedEl ).closest( 'tr' );
			
			// if DataTables Responsive is in play, clicks may come from a "child" row
			if ( $tr.hasClass( 'child' ) ) {
				$tr = $tr.prev();
			}
			
			// remove + draw without resetting paging
			dt.row( $tr ).remove().draw( false );

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
		
		
			$( document ).tooltip();
			$( '#event_isVirtual' ).checkboxradio();


			$( '#event_timezone' ).selectmenu({
				appendTo: '#dialog_eventDays',
				position: { my: 'left top', at: 'left bottom' },
				width: 350
			});

			const $menu = $( '#event_timezone' ).selectmenu({
				change: function( event, ui ) {
					if ( $( this ).val() ) {
						setNewEventDateTimeEnabled( true );  // enable
					} else {
						setNewEventDateTimeEnabled( false );  // disable
					}
				}
			});
			$menu.css({
			  'max-height': '13em',     // tweak until it shows ~7 items
			  'overflow-y': 'auto',
			  'overflow-x': 'hidden'
			});


			$( '#dialog_event' ).dialog({
				modal: true,
				autoOpen: false,
				width: 800,
				close: function() {
					resetEventDialog();
				},
				buttons: {
					save: async function() {
						
						try {
							const eventID = $( this ).dialog().data( 'eventID' );
							
							const eventDays = getEventDaysPayload( $('#eventDaysTable' ).DataTable() );

							const payload = {
								id: eventID,
								name: $( '#event_name' ).val(),
								location: $( '#event_location' ).val(),
								isVirtual: $( '#event_isVirtual' ).prop( 'checked' ),
								prerequisiteNotes: $( '#event_prerequisiteNotes' ).val(),
								repeatAttendancePolicy: $( '#event_repeatAttendancePolicy' ).val(),
								whoShouldAttend: $( '#event_whoShouldAttend' ).val(),
								eventTimezone: $( '#event_timezone' ).val(),
								eventDays: eventDays
							}

							if ( eventID ) {
								
								const result = await $.ajax({
									url: `${apiServer}/api/events`,
									method: "PUT",
									headers: { Authorization: "Bearer " + sessionJWT },
									dataType: "json",
									data: payload
								});
								
								const notification = document.querySelector('.mdl-js-snackbar');
								notification.MaterialSnackbar.showSnackbar({ message: 'Event updated' });

							} else {
								
								const result = await $.ajax({
									url: `${apiServer}/api/events`,
									method: "POST",
									headers: { Authorization: "Bearer " + sessionJWT },
									dataType: "json",
									data: payload
								});
								
								const notification = document.querySelector('.mdl-js-snackbar');
								notification.MaterialSnackbar.showSnackbar({ message: 'Event added' });

							}
							
							$('#eventsTable').DataTable().ajax.reload( null, false );
							
							return $( this ).dialog( 'close' );

						} catch( err ) {
							console.error( err );
						}

					},
					cancel: function() {
						$( this ).dialog( 'close' );
					}
				},
				open: function() {
					// 🔑 force recalculation after dialog is visible
					setTimeout( function () {
						$( '#eventDaysTable' ).DataTable().columns.adjust().draw( false );
					}, 0 );
				},

			});
			
			$( '#dialog_eventDays' ).dialog({
				modal: true,
				autoOpen: false,
				width: 515,
				close: function() {
					resetEventDialog();
				},
				buttons: {


					save: async function() {
					
						try {
						
							const dialog = $( this );
							const eventID = $( '#event_id_days' ).val();
							const timezoneID = $( '#event_timezone' ).val();
							
							const eventDays = getEventDaysPayload( $( '#eventDaysTable' ).DataTable() );
							
							// Save eventDays via the NEW endpoint (full replace; empty array means delete all)
							await $.ajax({
								url: `${apiServer}/api/events/${eventID}/days`,
								method: 'PUT',
								headers: { Authorization: 'Bearer ' + sessionJWT },
								contentType: 'application/json; charset=utf-8',
								dataType: 'json',
								data: JSON.stringify({ timezoneID: timezoneID, eventDays: eventDays })
							});
							
							// UI feedback
							const notification = document.querySelector( '.mdl-js-snackbar' );
							notification.MaterialSnackbar.showSnackbar({
								message: 'Event Days updated'
							});
							
							$( '#eventsTable' ).DataTable().ajax.reload( null, false );
							
							return dialog.dialog( 'close' );
						
						} catch ( err ) {
						
							console.error( err );
							
							const notification = document.querySelector( '.mdl-js-snackbar' );
							if ( notification?.MaterialSnackbar ) {
								notification.MaterialSnackbar.showSnackbar({ message: 'Save failed. Check console.' });
							}
							
						}
						
					},

				},


				open: function() {
					// 🔑 force recalculation after dialog is visible
					setTimeout( function () {
						$( '#eventDaysTable' ).DataTable().columns.adjust().draw( false );
					}, 0 );
				},

			});
			
			
			
			$( '#event_startDate' ).datepicker();
			$( '#event_endDate' ).datepicker();
			


			//-----------------------------------------------------------------------------------
			const eventsTable = $('#eventsTable')
			//-----------------------------------------------------------------------------------
				.on( 'mouseover', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'mouseout', 'tbody tr', function() {
					ToggleActionIcons( this );
				})
				.on( 'click', 'i.edit', function( event ) {
					event.stopPropagation();
					const eventID = $( this ).closest( 'tr' ).prop( 'id' );
					openEventDialog( eventID );
				})
				.on( 'click', 'i.addDays', function( event ) {
					event.stopPropagation();
					const eventID = $( this ).closest( 'tr' ).prop( 'id' );
					openEventDaysDialog( eventID );
				})
				.on( 'click', 'i.delete', function( event ) {

					event.stopPropagation();
					const eventID = $( this ).closest( 'tr' ).prop( 'id' );
					const eventName = $( this ).closest( 'tr' ).find( 'td.name' ).text();
					if ( confirm( `Delete event "${eventName}?"\n\nThis action cannot be undone.` ) ) {
						deleteEvent( eventID );
					}
					
				})
				.on( 'click', 'tbody tr', function( event) {

					event.stopPropagation();
					
					// ignore clicks on action icons (belt + suspenders)
					if ( $( event.target ).closest( 'i.edit, i.addDays, i.delete, td.actions' ).length ) return;
					
					const eventID = this.id; // because rowId: 'id'
					
					if ( eventID ) {
						window.location.href = `/eventRegistrations.asp?eventID=${encodeURIComponent( eventID )}`;
					// or if you want querystring style:
					// window.location.href = `/eventRegistrations.asp?eventID=${encodeURIComponent( eventID )}`;
					}

					
				})
				.DataTable({
					ajax: {
						url: `${apiServer}/api/events`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					columns: [
						{ data: 'name', className: 'name dt-body-left dt-head-left' },
						{ data: 'startDate', className: 'startDate dt-body-center dt-head-center', render: dateRenderer },
						{ data: 'endDate', className: 'endDate dt-body-center dt-head-center', render: dateRenderer },
						{ data: 'timezoneShortName', className: 'timezoneShortName dt-body-left dt-head-left' },
						{ data: 'location', className: 'location dt-body-left dt-head-left' },
						{ data: 'isVirtual', className: 'isVirtual dt-body-center dt-head-center', render: booleanRenderer },
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

		i.delete, i.edit, i.addDays {
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
	  margin-right: auto;
	}
	
	#eventDaysWrap .event_timezone label {
		font-weight: bold;
	}	
	
	#newEventDateTime.is-disabled {
	  opacity: 0.35;
	  cursor: default;
	  pointer-events: none; /* makes it unclickable */
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

<div id="dialog_event" title="Add Event" style="display:none;">

	<form id="form_event" autocomplete="off">

		<!-- Primary key (hidden) -->
		<input type="hidden" id="event_id" name="event_id" value="" />

		<div class="event-form-grid">

			<!-- ===================== Left Column ===================== -->
			<div class="event-col">

				<div class="field-row">
					<label for="event_name">Event Name <span class="req">*</span></label>
					<input type="text" id="event_name" name="event_name" maxlength="255" class="text ui-widget-content ui-corner-all" />
				</div>

				<div class="field-row">
					<label for="event_location">Location</label>
					<input type="text" id="event_location" name="event_location" maxlength="255" class="text ui-widget-content ui-corner-all" />
					<div class="field-hint">For virtual events, use Zoom/Teams/Webex, etc.</div>
				</div>

				<div class="field-row">
					<label for="event_isVirtual">Virtual?</label>
					<input type="checkbox" id="event_isVirtual" name="isVirtual" value="1" />
				</div>


			</div>

			<!-- ===================== Right Column ===================== -->
			<div class="event-col">

				<div class="field-row">
					<label for="event_repeatAttendancePolicy">Repeat Attendance Policy</label>
					<input type="text" id="event_repeatAttendancePolicy" name="repeatAttendancePolicy" maxlength="255" class="text ui-widget-content ui-corner-all" />
				</div>

				<div class="field-row">
					<label for="event_whoShouldAttend">Who Should Attend</label>
					<input type="text" id="event_whoShouldAttend" name="whoShouldAttend" maxlength="255" class="text ui-widget-content ui-corner-all" />
				</div>

			</div>

		</div>

		<!-- ===================== Notes ===================== -->
		<div class="field-row field-row-wide">
			<label for="event_prerequisiteNotes">Prerequisite Notes</label>
			<textarea id="event_prerequisiteNotes" name="event_prerequisiteNotes" rows="3" class="text ui-widget-content ui-corner-all"></textarea>
		</div>

	</form>

</div>


<div id="dialog_eventDays" title="Add Event Days" style="display:none;">

	<form id="form_eventDays" autocomplete="off">

		<!-- Primary key (hidden) -->
		<input type="hidden" id="event_id_days" name="event_id_days" value="" />

<!-- 		<div class="event-form-grid"> -->


			<div id="eventDaysWrap" class="field-row field-row-wide">
	
				<div class="field-row field-row-wide">
					<span class="event_timezone">
						<label for="event_timezone">Time Zone:</label>
						<select id="event_timezone"></select>
					</span>
					<span class="label">
						<span id="newEventDateTime" class="material-symbols-outlined" style="vertical-align: top;" title="Add a date to the event">calendar_add_on</span>
					</span>
					
				</div>
				<table id="eventDaysTable" class="compact display">
	
					<thead>
						<tr>
							<th>Start</th>
							<th>End</th>
							<th class="actions">Actions</th>
						</tr>
					</thead>
				</table>
	
			</div>

<!-- 		</div> -->

	</form>

</div>








		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col" align="left">
				<button id="button_newEvent" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
				  New Event
				</button>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>
			
		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col" align="center">


				<table id="eventsTable" class="compact display">
					<thead>
						<tr>
							<th class="name">Event Name</th>
							<th class="startDate">Start Date</th>
							<th class="endDate">End Date</th>
							<th class="timezoneShortName">Time Zone</th>
							<th class="Location">Location</th>
							<th class="isVirtual">Virtual?</th>
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