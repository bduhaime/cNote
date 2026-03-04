//================================================================================
// COPYRIGHT (C) 2017-2023, POLARIS CONSULTING, LLC -- ALL RIGHTS RESERVED
//================================================================================

// const disableAllEdits 	= '<% =disableAllEdits %>';	// utility unknown

const querystring = window.location.search;					// querystring
const urlParams = new URLSearchParams( querystring );		// querystring
const customerID = urlParams.get( 'customerID' );			// querystring
const callID = urlParams.get( 'callID' );						// querystring

let displayAs				= 'relative';
let callLead;
let startTime;
let scheduledTimeZoneInd;
let intervalID;




/*
//================================================================================
function extendSession() {
//================================================================================

	$.ajax({
		url: `${aspServer}/ajax/session.asp`
	}).done( function( response ) {
		console.log( 'session extended' );
	}).fail( function( err ) {
		console.error( 'Unable to extend ASP session' );
		console.error( err );
	});


}
//================================================================================
*/


//================================================================================
function showTransientMessage( msg ) {
//================================================================================

	let notification = document.querySelector('.mdl-js-snackbar');

	notification.MaterialSnackbar.showSnackbar({ message: msg });


}
//================================================================================


//================================================================================
function ToggleDisplayAs() {
//================================================================================

	const anchor = $( '#displayAs' );
	if ( anchor.text() == 'Show "Sent" as timestamp' ) {
		anchor.text( 'Show "Sent" as relative' )
		displayAs = 'timestamp';
	} else {
		anchor.text( 'Show "Sent" as timestamp' )
		displayAs = 'relative';
	}

	$( '#tbl_emails' ).DataTable().ajax.reload();

}
//================================================================================


//================================================================================
function getCallDetails( callID ) {
//================================================================================

	$.ajax({
		url: `${apiServer}/api/customerCalls/callDetail`,
		data: { callID: callID },
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( function( response ) {

		const data = response.callDetail[0];

		callLead = data.callLeadID;

		$( '#callTypeName' ).html( data.callTypeName );

		$( '#scheduledStartDateTime' ).html( data.scheduledStartDateTime );
		
		if ( !!data.scheduledDuration ) {
			$( '#scheduledDuration' ).html( ', '+data.scheduledDuration+' min.' );
		} else {
			$( '#scheduledDuration' ).html( '' );
		}
	
	
		let actualStartDateTime, actualDuration
	
		if ( !!data.actualStartDateTime ) {
			// the call was started...
			
			if ( !!data.actualDuration ) {
				// the call has been completed...
				
				actualStartDateTime 	= data.actualStartDateTime;
				actualDuration 		= ', ' + data.actualDuration + ' min.'
				
// 				$( 'span.editActualStart' ).show();
				$( 'span.startCall' ).hide();
				$( 'span.endCall' ).hide();
				
				$( '#sendTitleBody' ).html( 'Send<br>Recap' );

			} else {
				// the call was started and has not completed...
				
				actualStartDateTime = data.actualStartDateTime;
				scheduledTimeZoneInd = data.scheduledTimeZoneInd;

				startTime = moment( actualStartDateTime, 'MM/DD/YYYY hh:mm:ss A Z' );
				intervalID = setInterval( updateTimer, 1000 );
				
// 				$( 'span.editActualStart' ).hide();
				$( 'span.startCall' ).hide();
				$( 'span.endCall' ).show();
				
				$( '#sendTitleBody' ).html( 'Send<br>Agenda' );

			}

			$( '#actualDuration' ).html( actualDuration );
			
		} else {
			// the call has not been started...
			
			actualStartDateTime = '';
			
// 			$( 'span.editActualStart' ).hide();
			$( 'span.startCall' ).show();
			$( 'span.endCall' ).hide();
			
			$( '#sendTitleBody' ).html( 'Send<br>Agenda' );

		}
	
		$( '#actualStartDateTime' ).html( data.actualStartDateTime );
		
	}).fail(  function( err ) {
		alert( 'error while getting call details!' );
	});

}
//================================================================================


//================================================================================
function getClientAttendees( callID ) {
//================================================================================

	$.ajax({
		url: `${apiServer}/api/customerCallAttendees/clientAttendees`,
		data: { callID: callID },
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( function( data ) {

		$( '#clientAttendeeList tbody' ).html( '' ); 		// clear the tbody of the table
		const $calTable = $( '#clientAttendeeList' );		// this is an HTML table

		const $calBody = $( '<tbody>' );

		for ( attendee of data ) {
			
			let internalUser = ( attendee.customerID === '1' ) ? true : false;

			let checked = ( attendee.attendedIndicator ) ? 'checked' : '';

			let $tr = $( '<tr>' ).addClass( 'clientAttendeeRow' )
				.attr( 'data-attendeeID', attendee.attendeeID )
				.attr( 'data-userID', attendee.userID );

			let $tdCheck = $( '<td>' );
			let $tdChip = $( '<td>' );
			
			let $check;
			if ( internalUser ) {
				$check = $( '<label>' )
					.addClass( 'mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect callAttendee' )
					.attr( 'title', `Check to show that ${attendee.fullName} attended the call`)
					.html( `<input type="checkbox" class="mdl-checkbox__input" ${checked} ${disableAllEdits}>` )
					.on( 'change', function() {
						// console.log( 'clientAttendee clicked' );
						callAttendeePresent( this );
					});
			} else {
				$check = $( '<label>' )
					.attr( 'title', `This is an external user and should be deleted` )
					.html( `<span class="material-symbols-outlined">warning</span>` );

			}


			componentHandler.upgradeElement( $check.get(0) );


			let $chip = $( '<span>' )
				.addClass( 'mdl-chip mdl-chip--deletable' )
				.html(
					`<span class="mdl-chip__text">${attendee.fullName}</span>
					 <button type="button" class="mdl-chip__action"><i class="material-icons">cancel</i></button>`
				);

			$chip.find( 'button' ).on( 'click', function( e ) {
				// console.log( 'attendee "X" clicked' );
				deleteCallAttendee( this );
			});

			componentHandler.upgradeElement( $chip.get(0) );


			$tdCheck.append( $check );			// add the checkbox to its <td>
			$tdChip.append( $chip );			// add the deletable-chip to its <td>
			$tr.append( $tdCheck )				// add the checkbox <td> to the <tr>
			$tr.append( $tdChip );				// add the deletable-chip <td> to the <tr>
			$calBody.append( $tr );				// add the <tr> to the <body>
			$calTable.append( $calBody );		// add the <body> to the <table>


		}

	}).fail(  function( err ) {
		alert( 'error while getting client attendees!' );
	});

}
//================================================================================


//================================================================================
function getAllPossibleClientAttendees() {
//================================================================================

	return new Promise( async (resolve, reject) => {

		$.ajax({
			url: `${apiServer}/api/customerCallAttendees/allPossibleClientAttendees`,
			data: { callID: callID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {

			return resolve( data );

		}).fail(  function( err ) {
			console.error( 'error while getting client attendees!' );
			return reject( 'error while getting client attendees!' )
		});

	});

}
//================================================================================


//================================================================================
function getAllPossibleCustomerAttendees() {
//================================================================================

	return new Promise( async (resolve, reject) => {

		$.ajax({
			url: `${apiServer}/api/customerCallAttendees/allPossibleCustomerAttendees`,
			data: {
				customerID: customerID,
				callID: callID
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {

			return resolve( data );

		}).fail(  function( err ) {
			console.error( 'error while getting customer attendees!' );
			return reject( 'error while getting customer attendees!' )
		});

	});


}
//================================================================================


//================================================================================
function getClientCallLead( callID, callLead ) {
//================================================================================

	$.ajax({
		url: `${apiServer}/api/customerCalls/callLead`,
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		data: { callID: callID },
		contentType: 'application/json'
	}).done( function( data ) {

		for ( clientEmp of data ) {

			let $option = $( '<option>', {
				value: clientEmp.id,
				text: `${clientEmp.firstName} ${clientEmp.lastName}`
			})

			if ( clientEmp.callLeadInd == 1 ) {
				$option.attr( 'selected', 'selected' );
			}

			$( '#clientCallLeadNew' ).append( $option );

		}

		$( "#clientCallLeadNew" ).selectmenu( "refresh" );

	}).fail(  function( err ) {
		alert( 'error while getting client attendees!' );
	});


}
//================================================================================


//================================================================================
function getCustomerAttendees( callID, customerID ) {
//================================================================================

	$.ajax({
		url: `${apiServer}/api/customerCallAttendees/customerAttendees`,
		data: { callID: callID },
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( function( data ) {

		$( '#customerAttendeeList tbody' ).html( '' ); 		// clear the tbody of the table
		const $calTable = $( '#customerAttendeeList' );		// this is an HTML table
		const $calBody = $( '<tbody>' );

		for ( attendee of data ) {

			let checked = ( attendee.attendedIndicator ) ? 'checked' : '';

			let $tr = $( '<tr>' ).addClass( 'clientAttendeeRow' )
				.attr( 'data-attendeeID', attendee.attendeeID )
				.attr( 'data-contactID', attendee.contactID );

			let $tdCheck = $( '<td>' );
			let $tdChip = $( '<td>' );

			let $check = $( '<label>' )
				.attr( 'title', `Check to show that ${attendee.fullName} attended the call`)
				.addClass( 'mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect callAttendee' )
				.html( `<input type="checkbox" id="ca-${attendee.id}" data-val=${attendee.id} data-email=${attendee.username} class="mdl-checkbox__input" ${checked} ${disableAllEdits}>` )
				.on( 'change', function() {
					// console.log( 'customerAttendee clicked' );
					callAttendeePresent( this );
				});

			componentHandler.upgradeElement( $check.get(0) );


			let $chip = $( '<span>' )
				.addClass( 'mdl-chip mdl-chip--deletable' )
				.html(
					`<span class="mdl-chip__text">${attendee.fullName}</span>
					 <button type="button" class="mdl-chip__action"><i class="material-icons">cancel</i></button>`
				);

			$chip.find( 'button' ).on( 'click', function( e ) {
				// console.log( 'attendee "X" clicked' );
				deleteCallAttendee( this );
			});

			componentHandler.upgradeElement( $chip.get(0) );


			$tdCheck.append( $check );			// add the checkbox to its <td>
			$tdChip.append( $chip );			// add the deletable-chip to its <td>
			$tr.append( $tdCheck )				// add the checkbox <td> to the <tr>
			$tr.append( $tdChip );				// add the deletable-chip <td> to the <tr>
			$calBody.append( $tr );				// add the <tr> to the <body>


		}

		$calTable.append( $calBody );		// add the <body> to the <table>

	}).fail(  function( err ) {
		alert( 'error while getting client attendees!' );
	});

}
//================================================================================


//================================================================================
function getOpenTasks( customerID ) {
//================================================================================

	var table = $( '#openTasks' ).DataTable({
		ajax: {
			url: `${apiServer}/api/tasks/openTasksByCustomer`,
			data: { customerID: customerID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			dataSrc: 'data',
		},
		columnDefs: [
			{ targets: 'ownerName', data: 'ownerName', className: 'ownerName dt-body-left' },
			{ targets: 'daysBehind', data: 'daysBehind', className: 'daysBehind dt-body-right' },
			{ targets: 'taskCount', data: 'taskCount', className: 'taskCount dt-body-right' },
		],
		info: false,
		lengthChange: false,
		order: [[ 1, 'desc' ]],
		paging: false,
		searching: false,
	});


}
//================================================================================


//================================================================================
function getCallEmails( callID ) {
//================================================================================

	var table = $('#tbl_emails')
	.on( 'init.dt', function() {
		$( this ).DataTable().cells( 'TD.sent' ).every( function() {
			if ( displayAs == 'relative' ) {
				this.node().title =  moment( this.data() ).format( 'MM/DD/YYYY HH:mm:ss' );
			}
		});
	})
	.on( 'click', 'tbody tr', function() {
// 				window.location.href = 'callLogEntry.asp?logID='+this.id;
		window.open( 'callLogEntry.asp?logID='+this.id, '_blank', 'location=yes, scrollbars=yes,status=yes' );
	})
	.DataTable({
		paging: true,
		info: true,
		searching: true,
		ajax: {
			url: `${apiServer}/api/customerCalls/callEmails`,
			data: { callID: callID },
			dataSrc: '',
			headers: {
				'Authorization': 'Bearer ' + sessionJWT
			},
		},
		columnDefs: [
			{targets: 'fullName', 		data: 'fullName', 		className: 'fullName dt-body-left', defaultContent: ''},
			{targets: 'subject', 		data: 'subject', 			className: 'subject dt-body-left', defaultContent: ''},
			{targets: 'toList', 			data: 'toList', 			className: 'toList dt-body-left', defaultContent: ''},
			{
				targets: 'addedDateTime',
				data: 'addedDateTime',
				className: 'sent dt-body-left',
				defaultContent: '',
				render: {
					display: function( data, type, row ) {
						if ( displayAs == 'relative' ) {
							return moment( data ).fromNow();
						}
						return data
					},
					sort: function( data, type, row ) {
						return moment( data ).format(' YYYY-MM-DD HH:mm:ss' );
					}
				},

			},
		],
		order: [[ 3, 'desc' ]]
	});

}
//================================================================================


//================================================================================
function updateScheduledStartDateTime() {
//================================================================================

	const params = {
		scheduledStartDate: $( '#scheduledStartDate1' ).val(),
		scheduledStartTime: $( '#scheduledStartTime1' ).val(),
		scheduledDuration: $( '#scheduledDuration1' ).val(),
		scheduledTimezone: $( '#scheduledTimezone1' ).val()
	}

	// console.log( params );

	$.ajax({
		type: 'POST',
		url: `${apiServer}/api/customerCalls/updateScheduledStartDateTime/${callID}`,
		data: JSON.stringify( params ),
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( function( data ) {

		showTransientMessage( 'Scheduled start date/time updated' );
// 		extendSession();

	}).fail(  function( err ) {
		alert( 'error while updating scheduled start date/time!' );
	});


}
//================================================================================


//================================================================================
function updateActualStartDateTime() {
//================================================================================

	const params = {
		actualStartDate: $( '#actualStartDate1' ).val(),
		actualStartTime: $( '#actualStartTime1' ).val(),
		actualDuration: $( '#actualDuration1' ).val()
	}

	// console.log( params );

	$.ajax({
		type: 'POST',
		url: `${apiServer}/api/customerCalls/updateActualStartDateTime/${callID}`,
		data: JSON.stringify( params ),
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( function( data ) {

		showTransientMessage( 'Actual start date/time updated' );
// 		extendSession();

	}).fail(  function( err ) {
		alert( 'error while updating actual start date/time!' );
	});


}
//================================================================================


//================================================================================
function getNoteHistory( noteID ) {
//================================================================================

	$.ajax({
		url: `${apiServer}/api/customerCallNoteHistory/${noteID}`,
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( async function( history ) {

		const $histTable = $( '#updatedByTable' );		// this is an HTML table
		const $histBody = $( '<tbody>' );

		for ( item of history ) {

			let $itemRow = $( '<tr>' ).addClass( 'historicalNote' );

			//--------------------------------------------------------------------------------
			$itemRow.on( 'click', function() {
			//--------------------------------------------------------------------------------

				$( 'span.historyArrow' ).css( 'visibility', 'hidden' );

				let narrative = JSON.parse( $( this ).find( 'td.narrative' ).text() );

				let newQuill = new Quill( '#historicQuillNote', {
// 					theme: 'snow'
// 					modules: {
// 						toolbar: [
// 							['bold', 'italic', 'underline', 'strike'], // Customizing the toolbar buttons
// 							[{ color: [] }, { background: [] }], // Color controls
// 							['link', 'image', 'video'], // Other toolbar buttons
// 						],
// 					},				
				});

				newQuill.setContents( narrative );
				newQuill.enable( false );

				$(this).find( 'span.historyArrow' ).css( 'visibility', 'visible' );

				if ( $(this).index() !== 0 ) {
					$( '#makeCurrent' ).prop( 'disabled', false );
				} else {
					$( '#makeCurrent' ).prop( 'disabled', true );
				}


			});
			//--------------------------------------------------------------------------------


			let narrative = item.narrative;

			let $itemNoteIDCell = $( '<td>' ).addClass( 'noteID' ).html( `${item.id}` ).css( 'display', 'none' );
			let $itemUserIdCell = $( '<td>' ).addClass( 'updatedBy' ).html( `${item.updatedBy}` ).css( 'display', 'none' );
			let $itemDateTimeCell = $( '<td>' ).addClass( 'updatedDateTime' ).html( `${item.updatedDateTime}` ).css( 'display', 'none' );
			let $itemNarrativeCell = $( '<td>' ).addClass( 'narrative' ).html( `${narrative}` ).css( 'display', 'none' );

			let $itemNameCell = $( '<td>' ).addClass( 'histName' ).css( 'text-align', 'left' )
				.html( `<b>${item.userFullName}</b><br>${item.updatedDateTime}` );

			let $itemArrowCell = $( '<td>' ).css( 'text-aign', 'right' )
				.html( `<span class="material-symbols-outlined historyArrow" style="visibility: hidden;">double_arrow</span>` );


			$itemRow.append( $itemNoteIDCell );
			$itemRow.append( $itemUserIdCell );
			$itemRow.append( $itemDateTimeCell );
			$itemRow.append( $itemNarrativeCell );
			$itemRow.append( $itemNameCell );
			$itemRow.append( $itemArrowCell );
			$histBody.append( $itemRow );


		}

		$histTable.append( $histBody );		// add the <body> to the <table>

		$( '.historyArrow' ).first().css( 'visibility', 'visible' );
		let narrative = JSON.parse( $( 'tr.historicalNote' ).first().find( 'td.narrative' ).text() );
		let newQuill = new Quill( '#historicQuillNote', {
			theme: 'snow',
		});
		newQuill.setContents( narrative );
		newQuill.enable( false );

		$( '#makeCurrent' ).attr( 'data-noteID', noteID );


	}).fail(  function( err ) {
		alert( 'error while getting call note history!' );
	});


}
//================================================================================


//================================================================================
function getCallNotes( callID ) {
//================================================================================
//
// getCallNotes (PLURAL) getsl all the notes (current version) for a given call
// and populates the page with a Quill.js editor for each note found
//
	$.ajax({
		url: `${apiServer}/api/customerCallNotes/byCall`,
		data: { callID: callID },
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json',
	}).done( function( data ) {

		let $callNotes = $( '#callNotes' );		// references an HTML table
		let $body = $( '<tbody>' );

		for ( note of data ) {

			let $headerRow = $( '<tr>' ).addClass( 'callNoteHeader' ).attr( 'id', `callNoteHeader-${note.id}`);
			let $headerCell = $( '<td style="padding-top: 20px;">' );

// 					let $tdName = $( '<td colspan="2" width="99%">' ).addClass( 'callNoteCellName mdl-typography--title' );
			let $nameDiv = $( '<div style="float: left;">' ).addClass( 'callNoteCellName mdl-typography--title' );
			$nameDiv.append( note.name );


			let $emailDiv = $( '<div class="mdl-typography--caption" style="float: right; padding-top: 12px; padding-right: 5px;">' ).addClass( 'callNoteCellEmail' );
			if ( !note.includeWithEmails ) {
				$emailDiv.append( `Excluded from Agenda/Recap` );
			}


			let $historyIconDiv = $( '<div style="float: right;">' ).addClass( 'callNoteHistory' );
			if ( note.callNoteHistoryCount ) {
				displayHistoryButton = 'inline-block';
			} else {
				displayHistoryButton = 'none';
			}


			let $historyButton = $( `<button tabindex="10" id="historyButton_${note.id}" style="float: right;" class="mdl-button mdl-js-button mdl-button--icon mdl-button--colored callHistory" data-customerCallID="${note.id}" data-callNoteTypeID="${note.noteTypeID}">` );
			$historyButton
				.css( 'display', displayHistoryButton )
				.html( '<i class="material-icons">history</i>' );


			//--------------------------------------------------------------------------------
			$historyButton.on( 'click', function() {
			//--------------------------------------------------------------------------------

				const noteID = this.id.split( '_' )[1];
				getNoteHistory( noteID );
				dialog_callNoteHistory.dialog( 'open' );

			});
			//--------------------------------------------------------------------------------


			$historyIconDiv.append( $historyButton );



			$headerCell.append( $historyIconDiv );
			$headerCell.append( $emailDiv );
			$headerCell.append( $nameDiv );

			$headerRow.append( $headerCell );


			// this is an empty container for the Quill.js editor for each note. It is populated just after this for{} loop.
			let $trDetailRow = $( '<tr>' )
				.html( `<td colspan="3" class="callNoteDetail"><div id="quill-${note.id}" class="quill"></div></td>` );


			let $trFooterRow = $( `<tr id="qlFooter-${note.id}" class="trQuillFooter">` );
			let $trFooterCell = $( '<td>' );
			let $tdFooterButton = $( `<div style="float: left">` );
			let $saveQuillButton = $(`<button id="saveQuill-${note.id}" class="mdl-button mdl-js-button mdl-button--raised mdl-button--accent" disabled>&nbsp;` );
			$saveQuillButton.html( 'Save' );
			$saveQuillButton.on( 'click', async function() {


				const noteID = this.id.split( '-' )[1];										// get the noteID from "this" button
				const container = $( `#quill-${noteID}` ).get(0);							// get the Quill editor container
				const quill = Quill.find( container );											// get a handle for "this" Quill editor instance

				const contents = quill.getContents();											// get the contents of the Quill editor
				const html = quill.root.innerHTML												// extract the HTML from the contents
				await putCallNote( noteID, contents, html );									// save the updated note
				quill.blur();																			// remove focus from the Quill editor

				console.log( `quillID: ${noteID} edit saved - release lock as part of save operation` );


			});

			let $cancelQuillButton = $(`<button id="saveQuill-${note.id}" class="mdl-button mdl-js-button mdl-button--raised">` );
			$cancelQuillButton.html( 'Cancel' );
			$cancelQuillButton.on( 'click', async function() {

				// CANCEL button clicked!
				const noteID = this.id.split( '-' )[1];										// get the noteID from "this" button
				const container = $( `#quill-${noteID}` ).get(0);							// get the Quill editor container
				const quill = Quill.find( container );											// get a handle for "this" Quill editor instance

				const narrative = await getCallNote( noteID );								//	get the old narrative for "this" note
				quill.setContents( JSON.parse( narrative ) ) ;								// set the contents of the Quill editor to the previous value
				quill.blur();																			// remove focus from the Quill editor

					$( `#quill-${noteID}` ).css( 'background', '' );							// change the background back to ''
				$( `#quill-${noteID}` ).prev().toggle();										// hide the Quill toolbar
				$( `#saveQuill-${noteID}` ).prop( 'disabled', true );						// disable the Save button
				$( `#qlFooter-${noteID} div.message` ).html( '' );							// deleted the message in the footer
				$( `#qlFooter-${noteID}` ).toggle();											// hide the footer

				// determine if there are any pending edits...
				const pendingEdits = ( localStorage.getItem( `callNote-${noteID}` ) !== null )

				if ( pendingEdits ) {																// if there are pending edits...
					// console.log( 'Pending edits removed from localStorage on CLICK of Cancel button' );

					localStorage.removeItem( `callNote-${noteID}` );							// remove the unsaved edits from localStorage
					showTransientMessage( 'Unsaved edits discarded' );							// show the user a message
					
				}

				console.log( `quillID: ${noteID} edit cancelled - release lock here` );

			});

			let $tdFooterMessage = $( `<div style="float: left" class="message">` );

			$tdFooterButton.append( $saveQuillButton );
			$tdFooterButton.append( '&nbsp;&nbsp;' );
			$tdFooterButton.append( $cancelQuillButton );
			$trFooterCell.append( $tdFooterButton );
			$trFooterCell.append( $tdFooterMessage );
			$trFooterRow.append( $trFooterCell );


			$body.append( $headerRow );
			$body.append( $trDetailRow );
			$body.append( $trFooterRow );

		}

		$callNotes.append( $body );

		let quills = document.getElementsByClassName( 'quill' );
		let quillsArray = Array.from( quills );
		
// 				const bindings = {
// 				  tmSymbol: {
// 				    key: '0',
// 				    shiftKey: true,
// 				    prefix: /(tm)/,
// 				    handler: function(range, context) {
// 					   console.log( 'finally!' );
// 						debugger
// 				    }
// 				  }
// 				};
//
// 				Quill.register('modules/keyboard/tmSymbol', bindings );
//
// 				Object.keys(bindings).forEach((name) => {
// 					Quill.register(`modules/keyboard/${name}`, bindings[name]);
// 				});


		for ( quill of quillsArray ) {
			
			const quillID = quill.id.split('-')[1];
// 					const container = $( '#quill-'+quillID ).get(0);
// 					const toolbar = container.sibling( 'div.ql-toolbar' ).get(0);
	
			try {
			
				const toolbarOptions = [
					['bold', 'italic', 'underline', 'strike'],        // toggled buttons
					['blockquote', 'code-block'],
					
					[{ 'header': 1 }, { 'header': 2 }],               // custom button values
					[{ 'list': 'ordered'}, { 'list': 'bullet' }],
					[{ 'script': 'sub'}, { 'script': 'super' }],      // superscript/subscript
					[{ 'indent': '-1'}, { 'indent': '+1' }],          // outdent/indent
					[{ 'direction': 'rtl' }],                         // text direction
					
	// 				[{ 'size': ['small', false, 'large', 'huge'] }],  // custom dropdown
	// 				[{ 'header': [1, 2, 3, 4, 5, 6, false] }],
					
					[{ 'color': [] }, { 'background': [] }],          // dropdown with defaults from theme
					[{ 'font': [] }],
					[{ 'align': [] }],
					
					['clean']                                         // remove formatting button
				];
	
	
	
				let newQuill = new Quill( `#quill-${quillID}`, {
					modules: {
						toolbar: [
							[{ header: [] }],
							['bold', 'italic', 'underline', 'link'],
							[{ color: [] }, { background: [] }],
							[{ list: 'ordered' }, { list: 'bullet' }],
							['clean']
						]
					},
					theme: 'snow',
				});
	
				newQuill.keyboard.addBinding({
					key: '0',
					shiftKey: true,
					prefix: /(tm)/,
					handler: function( range, context ) {
						this.quill.deleteText(range.index-3, 4);
						this.quill.insertText(range.index-3, '\u2122', true);
					}
				});
				newQuill.keyboard.addBinding({
					key: ' ',
					prefix: /\S\s--\s(?=\s*\S*)/,
					handler: function( range, context ) {
						const location = this.quill.getText().lastIndexOf( '--' );
						this.quill.deleteText( location, 2 );
						this.quill.insertText( location, '\u2014', true );
						this.quill.insertText( range.index-1, ' ', true );
					}
				});
				newQuill.keyboard.addBinding({
					key: ' ',
					prefix: /\S--\s(?=\s*\S*)/,
					handler: function( range, context ) {
						const location = this.quill.getText().lastIndexOf( '--' );
						this.quill.deleteText( location, 2 );
						this.quill.insertText( location, ' \u2014', true );
						this.quill.insertText( range.index-1, ' ', true );
					}
				});
				newQuill.keyboard.addBinding({
					key: ' ',
					prefix: /\S*\s--(?=\S\s*\S*)/,
					handler: function( range, context ) {
						const location = this.quill.getText().lastIndexOf( '--' );
						this.quill.deleteText( location, 2 );
						this.quill.insertText( location, '\u2014 ', true );
						this.quill.insertText( range.index-1, ' ', true );
					}
				});
				newQuill.keyboard.addBinding({
					key: ' ',
					prefix: /\S*\s-\s(?=\S*)/,
					handler: function( range, context ) {
						const location = this.quill.getText().lastIndexOf( '-' );
						this.quill.deleteText( location, 1 );
						this.quill.insertText( location, '\u2013', true );
						this.quill.insertText( range.index, ' ', true );
					}
				});
				
	
	
				const savedDelta = JSON.parse( localStorage.getItem( `callNote-${quillID}` ) );
	
				if ( savedDelta ) {
					// ====================================================================================
					// unsaved changes found in localStorage, so show delta from localStorage
					// ====================================================================================
	
					$( `#saveQuill-${quillID}` ).prop( 'disabled', false );
	
					const localStorageDate = moment( savedDelta.updatedDateTime ).format( 'YYYY-MM-DD HH:mm' );
					const databaseDate = moment( note.updatedDateTime ).format( 'YYYY-MM-DD HH:mm' );
	
					if ( moment( databaseDate ).isAfter( moment( localStorageDate ) ) ) {
						// edits in local storage pre-date note saved in the database...
						$( `#qlFooter-${quillID} div.message` ).html( `<b>This note has changed since the time of your unsaved edits.</b> <br>"Cancel" will discard your unsaved edits.`);
					} else {
						$( `#qlFooter-${quillID} div.message` ).html( `You have unsaved changes for this note.<br>"Cancel" will discard your unsaved edits.`);
					}
	
	
	// 						newQuill.setContents( JSON.parse( savedDelta ) );
					newQuill.setContents( savedDelta.delta );
					$( `#quill-${quillID}` ).css( 'background', 'pink' );
	
	
				} else {
					// NO unsaved changes in localStorage, so show delta from AJAX....
	
					let narrative = data.find( x => x.id === quillID ).narrative;
					
					// console.info( narrative );
	
					if ( narrative ) {
	
						newQuill.setContents( JSON.parse( narrative ) );
	
						let savedDelta = localStorage.getItem( `callNote-${quillID}` );
						if ( savedDelta ) {
							// console.log( 'unsaved changes detected!' );
							$( `#quill-${quillID}` ).css( 'background', 'pink' );
	
						}
	
					}
	
				}
	
				newQuill.on( 'selection-change', function( range, oldRange, source ) {
	
	// 				console.log( 'quilljs: selection-changed fired from source', {range, oldRange, source} );
					
					if ( !range ) return;
	
	
					if ( source === 'user' ) {
						
	
						if ( !!range ) {
							//	a quill-editor has been selected
							// console.log( `[${quillID}] has been selected` );
							$( `#quill-${quillID}` ).css( 'border-top', '1px solid rgb(204, 204, 204)' );
	
							$( `#quill-${quillID}` ).prev().show();
							$( `#qlFooter-${quillID}` ).show();
							
							console.log( `quillID: ${quillID} selected - set lock here` )
	
						} else {
	
							//	a quill-editor has been deselected
							// console.log( `[${quillID}] has been deselected` );
							$( `#quill-${quillID}` ).css( 'border-top', '0px none rgba(0, 0, 0, 0.87)' );
	
							$( `#quill-${quillID}` ).prev().hide();
							$( `#qlFooter-${quillID}` ).hide();
	
							console.log( `quillID: ${quillID} deselected - release lock here` )
	
						}
	
					}
	
					return true;
	
				}, quillID );
	
	
				newQuill.on( 'text-change', function( delta, oldDelta, source ) {
	
	// 				console.log( 'quilljs: text-change fired from source', {delta, oldDelta, source} );
	
					if ( source === 'user' ) {
	
						$( `#saveQuill-${quillID}` ).prop( 'disabled', false );
						$( `#quill-${quillID}` ).css( 'background', 'pink' );
						$( `#qlFooter-${quillID} div.message` ).html( `You have unsaved changes for this note.<br>"Cancel" will discard your unsaved edits.`);
	
						const item = {
							updatedDateTime: moment().toString(),
							delta: newQuill.getContents()
						}
	
						localStorage.setItem( `callNote-${quillID}`, JSON.stringify( item ) );
	
					}
	
					return true;
	
	
				}, quillID );
				
							
			} catch( err ) {
				
				console.error( `Error while populating Quill.js object, quillID: ${quillID} `);
				console.error( err );
				$( `#quill-${quillID}` ).html( '<p style="font-weight: bold; color: red;">Problem encountered while retrieving call note, contact system administrator</p>' );
				
			}
			
			console.log( 'continue' );

		}


// 				let quill = new Quill( '.quill', { theme: 'snow' } );

	}).fail(  function( err ) {
		console.error( err );
		alert( 'error while getting call notes!' );
	});

}
//================================================================================


//================================================================================
function putCallNote( noteID, contents, html ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		let encodedContents = JSON.stringify( contents )
		// console.log( encodedContents )
	
		let payload = {
			noteID: noteID,
			contents: encodedContents,
			html: html
		}
	// 			tempData.noteID = noteID
	// 			tempData.contents = encodedContents
		// console.log( payload );
	
		$.ajax({
			url: `${apiServer}/api/customerCallNotes`,
			type: 'post',
			data: JSON.stringify( payload ),
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {
	
			$( `#quill-${noteID}` ).prev().toggle();	// hide the toolbar
			$( `#qlFooter-${noteID}` ).toggle();		// hide the save button
			// console.log( 'pending edits removed from localStorage during PUT of note' );
	
			localStorage.removeItem( `callNote-${noteID}` );
			$( `#quill-${noteID}` ).css( 'background', '' );
	
			$( `#historyButton_${noteID}` ).show();
	
			showTransientMessage( 'Call note saved' );
	// 		extendSession();
	
			resolve();
	
		}).fail(  function( err ) {

			console.error( err.responseText );
			alert( 'error while saving call note!' );
			reject( 'error while saving call note!' );

		});

	});

}
//================================================================================


//================================================================================
function getCallNoteHistory( updatedBy, updatedDateTime ) {
//================================================================================
//
// getCallNote (SINGULAR) gets a specific call note -- see getCallNotes (PLURAL)
//

	return new Promise( async (resolve, reject) => {

		$.ajax({
			url: `${apiServer}/api/customerCallNoteHistory`,
			data: {
				updatedBy: updatedBy,
				updatedDateTime: updatedDateTime
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json',
		}).done( function( data ) {

			resolve( data[0].narrative );

		}).fail(  function( err ) {
			console.error( err.responseText );
			reject( 'error getting call note history!' );
		});

	});

}
//================================================================================


//================================================================================
function getCallNote( noteID ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		$.ajax({
			url: `${apiServer}/api/customerCallNotes/currentNote`,
			data: { noteID: noteID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json',
		}).done( function( data ) {

			resolve( data[0].narrative );

		}).fail(  function( err ) {
			console.error( err.responseText );
			reject( 'error getting call note history!' );
		});

	});

}
//================================================================================


//================================================================================
function getCustomerInfo( customerID ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		$.ajax({
			url: `${apiServer}/api/customers/${customerID}`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json',
		}).done( function( results ) {

			resolve( results );

		}).fail(  function( err ) {
			console.error( err.responseText );
			reject( 'error getting getCustomerInfo!' );
		});

	});

}
//================================================================================


//================================================================================
function getCallAttendeesByType( attendeeType ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		$.ajax({
			url: `${apiServer}/api/customerCalls/callInviteesByType`,
			data: {
				callID: callID,
				attendeeType: attendeeType
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json',
		}).done( function( users ) {

			resolve( users );

		}).fail(  function( err ) {
			console.error( err.responseText );
			reject( 'error getting getCallAttendeesByType()!' );
		});

	});

}
//================================================================================


//================================================================================
function callAttendeePresent( mdlCheckboxElement ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		try {

			let callAttendeeID = $( mdlCheckboxElement ).closest( 'tr' ).attr( 'data-attendeeID' );
			let attendedIndicator = ( $( mdlCheckboxElement ).hasClass( 'is-checked' ) ) ? 1 : 0;

			const params = {
				callAttendeeID: callAttendeeID,
				attendedIndicator: attendedIndicator
			}

			$.ajax({

				url: `${apiServer}/api/customerCallAttendees/attendeePresent`,
				type: 'POST',
				data: JSON.stringify( params ),
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				contentType: 'application/json',

			}).done( function( reponse ) {

				showTransientMessage( 'Attendee updated' );
// 				extendSession();
				resolve();

			}).fail(  function( err ) {

				console.error( err.responseText );
				reject( 'error in callAttendeePresent()!' );

			});


		} catch( err ) {

			reject( err );

		}

	});

}
//================================================================================


//================================================================================
function updateCallLead( jquerySelectmenu ) {
//================================================================================

	const callLead = $( jquerySelectmenu ).val();

	$.ajax({

		url: `${apiServer}/api/customerCalls/saveCallLead`,
		type: 'POST',
		data: JSON.stringify({
			callID: callID,
			callLead: callLead
		}),
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json',

	}).done( function( reponse ) {

		showTransientMessage( 'Call lead updated' );
// 		extendSession();

	}).fail(  function( err ) {

		console.error( err.responseText );
		throw new Error( 'error in updateCallLead()!' );

	});


}
//================================================================================


//================================================================================
function saveSelectedAttendees( domElement ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		const attendeeType = $( '#attendeeType' ).val();

		$dialog = $( domElement );
		$checked = $dialog.find( '.is-checked' ).closest( 'tr' );

		let attendees = [];
		for ( attendee of $checked ) {
			attendees.push(
				$( attendee ).attr( `data-${attendeeType}recipientid` )
			);
		}

		$.ajax({

			url: `${apiServer}/api/customerCallAttendees/saveCallAttendees`,
			type: 'POST',
			data: JSON.stringify({
				callID: callID,
				attendees: attendees,
				attendeeType: attendeeType
			}),
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json',

		}).done( function( reponse ) {

// 			extendSession();
			return resolve( true )

		}).fail(  function( err ) {

			console.error( err.responseText );
			return reject( 'error in updateCallLead()!' );

		});

	});

}
//================================================================================


//================================================================================
function deleteCallAttendee( domElement ) {
//================================================================================

	const attendeeID = $( domElement ).closest( 'tr' ).attr( 'data-attendeeID' );

	const payload = {
		callID: callID,
		attendeeID: attendeeID
	}

	$.ajax({
		type: 'DELETE',
		url: `${apiServer}/api/customerCallAttendees/attendees`,
		data: JSON.stringify( payload ),
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
		contentType: 'application/json'
	}).done( function( data ) {
		$( domElement ).closest( 'tr' ).remove();
		showTransientMessage( data );
	}).fail(  function( err ) {
		alert( 'error while deleting call attendee!' );
	});

}
//================================================================================


//================================================================================
async function PrepSendDialog1() {
//================================================================================

	const customerInfo = await getCustomerInfo( customerID );


	//-- populate the "subject" --//
	let customerName 	= ( customerInfo.nickname )
							? customerInfo.nickname
							: ( customerInfo.name )
							? customerInfo.name
							: customerInfo.instName;

	let callType = $( '#callTypeName' ).text();
//	let agendaRecap = $( '#actualDuration1' ).val() !== null ? 'Recap' : 'Agenda';
	let agendaRecap = ( !!$( '#actualDuration' ).text() ) ? 'Recap' : 'Agenda';

	let emailSubject = `${customerName} - ${callType} - ${agendaRecap}`;

	$( '#sendCallDialog #subject' ).val( emailSubject );

	let $targetTableTbody, attendees;
	//-- populate "user" attendees/addressees" --//
	$targetTableTbody = $( '#sendUserAttendees tbody' );
	attendees = await getAllPossibleClientAttendees();
	debugger
	buildAttendeesTable( attendees, $targetTableTbody, 'onlyInvitees', 'user' );

	//-- populate "contact" attendees/addressees" --//
	$targetTableTbody = $( '#sendContactAttendees tbody' );
	attendees = await getAllPossibleCustomerAttendees()
	buildAttendeesTable( attendees, $targetTableTbody, 'onlyInvitees', 'contact' );

	dialog_sendEmail.dialog( 'open' );

}
//================================================================================


//================================================================================
function buildAttendeesTable( attendees, $domTableTbody, inviteeType, recipientType ) {
//================================================================================

	$domTableTbody.html( '' );

	for ( attendee of attendees ) {


		// inviteeType:
		//
		//		'onlyInvitees' 	==> include only attendees that have already been invited
		//		'onlyNonInvitees'	==> include only attendees that have NOT already been invited
		//		otherwise			==> include all attendees
		//

		if ( inviteeType === 'onlyInvitees' && attendee.invitedID === null ) continue;
		if ( inviteeType === 'onlyNonInvitees' && attendee.invitedID !== null ) continue;


		let $row = $( '<tr>' )
			.attr( `data-${recipientType}RecipientID`, attendee.attendeeID );

		let $checkboxCell = $( '<td>' );


		//----------------------------
		//
		//	build the MDL checkbox...
		//
		let title 
		if ( [ 'sendContactAttendees', 'sendUserAttendees' ].includes( $domTableTbody.parent().prop( 'id' ) ) ) {
			title = `Click to send ${attendee.fullName} this email`;
		} else {
			title = `Click to make ${attendee.fullName} available for the call`;
		}
		
		
		let $checkboxLabel = $( '<label>' )
			.attr( 'title', title )
			.addClass( 'mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect userAttendee' )
			.attr( 'for', `${recipientType}_${attendee.attendeeID}` );

		let $checkboxInput = $( '<input>' )
			.attr( 'type', 'checkbox' )
			.attr( 'id', `${recipientType}_${attendee.attendeeID}` )
			.addClass( `mdl-checkbox__input` )
			.attr( 'data-email', attendee.attendeeEmail );

		let checked = ( attendee.attendedIndicator ) ? true : false;
		if ( checked ) {
			$checkboxInput.attr( 'checked', true );
		} else {
			$checkboxInput.attr( 'checked', false );
		}

		//
		//----------------------------


		$checkboxLabel.append( $checkboxInput );
		$checkboxCell.append( $checkboxLabel );


		let $chipCell = $( '<td>' );


		//----------------------------
		//
		// build the MDL chip...
		//
		let $chip = $( '<span>' )
			.addClass( 'mdl-chip mdl-chip--deletable' )
			.html( `<span class="mdl-chip__text">${attendee.fullName}</span>` );

		//
		//----------------------------


		$chipCell.append( $chip );

		$row.append( $checkboxCell ).append( $chipCell );

		$domTableTbody.append( $row );

/*
		componentHandler.upgradeElement( $checkboxLabel.get(0) );
		componentHandler.upgradeElement( $chip.get(0) );
*/

	}

	componentHandler.upgradeElements( $('label.userAttendee' ) );

}
//================================================================================


//================================================================================
function sendCall() {
//================================================================================

	let to = cc = subject = comments = '';

	$( '#sendContactAttendees tbody tr td label.is-checked' ).each( function() {
		let email = $( this ).find( 'input' ).attr( 'data-email' );
		if ( !!email ) to += ( to.length > 0 ) ? ','+email : email;
	});

	$( '#sendUserAttendees tbody tr td label.is-checked' ).each( function() {
		let email = $( this ).find( 'input' ).attr( 'data-email' );
		if ( !!email ) cc += ( to.length > 0 ) ? ','+email : email;
	});

	if ( !!$( '#additionalRecipients' ).val() ) cc += ( cc.length > 0 ) ? ','+$( '#additionalRecipients' ).val() : $( '#additionalRecipients' ).val();
debugger
	subject = $( '#subject' ).val();

	comments = $( '#additionalComments' ).val();

	$.ajax({
		url: apiServer + '/api/customerCalls/emailCall',
		type: 'post',
		data: JSON.stringify({
			callID: callID,
			customerID: customerID,
			to: to,
			cc: cc,
			subject: subject,
			comments: comments
		}),
		contentType: "application/json; charset=utf-8",
		dataType   : "json",
		headers: {
			'Authorization': 'Bearer ' + sessionJWT
		},
	}).done( function( response ) {
// 		extendSession();
	}).fail( function( err ) {
		console.error( err.responseText );
	});


}
//================================================================================


//================================================================================
function updateTimer() {
//================================================================================

	strStartime = startTime.format( 'MM/DD/YYYY HH:mm:ss A Z' );
	strCurrTime = moment.tz( scheduledTimeZoneInd ).format( 'MM/DD/YYYY HH:mm:ss A Z' )
// 	const duration = moment.duration( moment( strStartime, 'MM/DD/YYYY HH:mm:ss A' ).diff( moment( strCurrTime, 'MM/DD/YYYY HH:mm:ss A'  ) ) )
	const duration = moment.duration( moment( strCurrTime, 'MM/DD/YYYY HH:mm:ss A' ).diff( moment( strStartime, 'MM/DD/YYYY HH:mm:ss A'  ) ) )

	const hours = Math.floor( duration.asHours() );
	const minutes = duration.minutes();
	const seconds = duration.seconds();
	
	$( '#actualDuration' ).text( `, ${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}` );

//	const duration = moment.duration( moment().diff( moment(startTime) ) ).humanize();
//	const duration = moment.duration( moment().diff( moment(startTime) ) );
//	$( '#actualDuration' ).text( `, ${duration}` );


//================================================================================
}
//================================================================================


//================================================================================
$(document).ready( function() {
//================================================================================


	$( document ).tooltip();

	$.widget( "ui.timespinner", $.ui.spinner, {
			options: {
				step: 15 * 60 * 1000 	// step in 15-minute increments
		},

		_parse: function( value ) {

			if ( typeof value === "string" ) {
				// already a timestamp
				if ( Number( value ) == value ) {
					return Number( value );
				}
				return moment( value, 'hh:mm A' ).valueOf();
			}
			return value;

		},

		_format: function( value ) {

			return moment( value ).format( 'hh:mm A' );

		}

	});


	dialog_callNoteHistory = $( '#dialog_callNoteHistory' ).dialog({
		autoOpen: false,
		modal: true,
		width: 1028,
		dialogClass: 'dialogWithDropShadow',
		buttons: {
			Cancel: function() {
				dialog_callNoteHistory.dialog( 'close' );
			}
		},
		close: function() {
			// console.log( 'note history dialog closed' );
			$( '#historicQuillNote' ).html( '' );
			$( '#updatedByTable tr' ).remove();
		}
	});


	dialog_callAttendees = $( '#editAttendeesDialog' ).dialog({
		autoOpen: false,
		modal: true,
		width: 350,
		dialogClass: 'dialogWithDropShadow',
		buttons: {
			Cancel: function() {
				// console.log( 'call attendees dialog cancelled' );
				dialog_callAttendees.dialog( 'close' );
			},
			Save: async function() {
				// console.log( 'call attendees dialog saved' );

				await saveSelectedAttendees( this );

				if ( $( '#attendeeType' ).val() === 'user' ) {
					await getClientAttendees( callID );
				} else {
					await getCustomerAttendees( callID, customerID );
				}

				dialog_callAttendees.dialog( 'close' );

			}
		},
		close: function() {
			// console.log( 'call attendees dialog closed' );
			$("#editAttendeesTable > tbody").html("");
		}
	});


	dialog_sendEmail = $( '#sendCallDialog' ).dialog({
		autoOpen: false,
		modal: true,
		width: '75%',
		dialogClass: 'dialogWithDropShadow',
		buttons: {
			Cancel: function() {
				// console.log( 'sendCall dialog cancelled' );
				dialog_sendEmail.dialog( 'close' );
			},
			Send: async function() {
				// console.log( 'sendCall dialog sent' );

				await sendCall();

				await setTimeout( function() {
					
					// console.log( 'sent from location 2' );
					
					$( '#tbl_emails' ).DataTable().ajax.reload();
					
				}, 30000 ),
				




				dialog_sendEmail.dialog( 'close' );
			}
		},
		close: function() {
			// console.log( 'sendCall dialog closed' );
		}
	});


	$( "#scheduledStartDate1" ).datepicker({
		onSelect: function() {
			// console.log( 'scheduled start date changed' );
			updateScheduledStartDateTime();
		}
	});


	$( "#scheduledStartTime1" ).timespinner({
		stop: function( event, ui ) {
			// console.log( 'scheduled start stop', ui );
 			updateScheduledStartDateTime();
		},
	});


	$( "#scheduledDuration1" ).spinner({
		min: 15,
		max: 120,
		step: 15,
		stop: function( event, ui ) {
 			updateScheduledStartDateTime();
		},
	});


	$( "#scheduledTimezone1" ).selectmenu({
		width: 110,
		change: function( event, ui ) {
			// console.log( 'scheduled time zone changed' );
 			updateScheduledStartDateTime();
		}
	});


	$( "#actualStartDate1" ).datepicker({
		onSelect: function() {
			// console.log( 'schedule actual start date changed' );
			updateActualStartDateTime();
		}
	});


	$( "#actualStartTime1" ).timespinner({
		stop: function( event, ui ) {
			// console.log( 'actual start stop', ui );
 			updateActualStartDateTime();
		},
	});


	$( "#actualDuration1" ).spinner({
		min: 15,
		step: 15,
		stop: function( event, ui ) {
 			updateActualStartDateTime();
		},
	});


	$( "#clientCallLeadNew" ).selectmenu({
		width: 300,
		change: function( event, ui ) {
			updateCallLead( this );
		}
	});


	$( '#dialog_editAnnotation' ).find( 'button' ).tooltip({
		position: { my: 'right bottom', at: 'right-10 top-5' }
	});


	$( 'button.editAttendees' ).on( 'click', async function() {

		let attendees, attendeeType;
		if ( $( this ).hasClass( 'editUserAttendees' ) ) {
			attendeeType = 'user'
			dialog_callAttendees.dialog( 'option', 'title', 'Edit Your Attendees' );
			attendees = await getAllPossibleClientAttendees();
			$( '#attendeeType' ).val( 'user' );
			dialog_callAttendees.dialog( 'widget' ).find( '.ui-dialog-titlebar' )
				.css( 'color', 'rgb(66,66,66)' )
				.css( 'background-color', 'rgb(255,171,64)' );
		} else if ( $( this ).hasClass( 'editCustomerAttendees' ) ) {
			attendeeType = 'contact'
			dialog_callAttendees.dialog( 'option', 'title', 'Edit Customer Attendees' );
			attendees = await getAllPossibleCustomerAttendees();
			$( '#attendeeType' ).val( 'contact' );
			dialog_callAttendees.dialog( 'widget' ).find( '.ui-dialog-titlebar' )
				.css( 'color', 'rgb(255,255,255)' )
				.css( 'background-color', 'rgb(103,58,183)' );
		} else {
			throw new Error( 'unknown attendee type encountered' );
		}


		dialog_callAttendees.dialog( 'open' );


		dialog_callAttendees.dialog( 'widget' ).position({
			my: 'left+20',
			at: 'bottom right',
			of: $( this ),
			collision: 'fit flip'
		});

		let $targetTableTbody = $( '#editAttendeesTable tbody' );

		buildAttendeesTable( attendees, $targetTableTbody, 'onlyNonInvitees', attendeeType );


	});


	getCallDetails( callID )
	getClientAttendees( callID );
	getClientCallLead( callID );
	getCustomerAttendees( callID, customerID );
	getOpenTasks( customerID );
	getCallEmails( callID );
	getCallNotes( callID );




	//---------------------------------------------------------------------------
	$( '.callAttendee' ).click( function() {
	//---------------------------------------------------------------------------

		$.ajax({
			type: 'POST',
			url: `${apiServer}/api/customerCallAttendees/attendees`,
			data: {
				callID: callID,
				attendeeID: $( this ).attr( 'data-val' )
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {
			showTransientMessage( data );
/* 			extendSession(); */
		}).fail(  function( err ) {
			alert( 'error while saving call attendee!' );
		});

	});
	//---------------------------------------------------------------------------


	//---------------------------------------------------------------------------
	$( 'span.startCall' ).click( function() {
	//---------------------------------------------------------------------------

		$.ajax({
			type: 'POST',
			url: `${apiServer}/api/customerCalls/start/${callID}`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {

			getCallDetails( callID );
			showTransientMessage( 'Call timer started' );

		}).fail(  function( err ) {
			alert( 'error while starting call!' );
		});

	});
	//---------------------------------------------------------------------------


	//---------------------------------------------------------------------------
	$( 'span.endCall' ).click( function() {
	//---------------------------------------------------------------------------

		$.ajax({
			type: 'POST',
			url: `${apiServer}/api/customerCalls/end/${callID}`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			contentType: 'application/json'
		}).done( function( data ) {

			clearInterval( intervalID );
			getCallDetails( callID );
			showTransientMessage( 'Call timer stopped' );
// 			extendSession();

		}).fail(  function( err ) {
			alert( 'error while ending call!' );
		});

	});
	//---------------------------------------------------------------------------


	//---------------------------------------------------------------------------
	$( '#makeCurrent' ).click( async function() {
	//---------------------------------------------------------------------------

		if ( confirm('Are you sure you want to make this version the "current" version?\n\nClicking OK will update the call note, close this dialog, and refresh the page.' ) ) {

			const noteID = $( this ).attr( 'data-noteID' );
			let newQuill = new Quill( '#historicQuillNote' );
			const contents = newQuill.getContents();


			const html = newQuill.root.innerHTML												// extract the HTML from the contents

			await putCallNote( noteID, contents, html );

			location = location;

			showTransientMessage( 'Note upated' );


		}


	});
	//---------------------------------------------------------------------------


	//---------------------------------------------------------------------------
	$( 'button.sendCall' ).click( async function() {
	//---------------------------------------------------------------------------

		SendCall( callID, customerID, sessionJWT, async function() {
			// console.log( 'send from location 1' );
			await showTransientMessage( 'Call successfully emailed' );
			await setTimeout( $( '#tbl_emails' ).DataTable().ajax.reload(), 15000 )
		});

		dialog_sendCall.close();

	});
	//---------------------------------------------------------------------------


	//---------------------------------------------------------------------------
	$( '#sendCallIcon' ).click( function() {
	//---------------------------------------------------------------------------

		PrepSendDialog1();

	});
	//---------------------------------------------------------------------------


});
//================================================================================


