//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

/*****************************************************************************************/
function CreateRequest() {
/*****************************************************************************************/

	try {
		request = new XMLHttpRequest();
	} catch (trymicrosoft) {
		try {
			request = new ActiveXObject("Msxml2.XMLHTTP");
		} catch (othermicrosoft) {
			try {
				request = new ActiveXObject("Microsoft.XMLHTTP");
			} catch (failed) {
				request = null;
			}
		}
	}

	if (request == null)
		alert("Error creating request object!");

}



/*****************************************************************************************/
function updateDateTimeAttribute(inputElem) {
/*****************************************************************************************/
	
	var csuiteParentDiv	= inputElem.closest('div.csuite-textfield');
	var csuiteInput		= csuiteParentDiv.querySelector('input, select');
	

	var attributeName 	= csuiteInput.id;
	var callID				= csuiteInput.getAttribute('data-callID');
	var attributeValue, cmd;
	
	var scheduledCallDate				= moment(document.getElementById('scheduledCallDate').value, 'YYYY-MM-DD');
	var actualCallDate 					= moment(document.getElementById('actualCallDate').value, 'YYYY-MM-DD');
	
	var scheduledCallStartTime			= moment(document.getElementById('scheduledCallStartTime').value, 'HH:mm');
	var scheduledCallStartTimeMin		= moment(document.getElementById('scheduledCallStartTime').getAttribute('min'), 'HH:mm');
	var scheduledCallStartTimeMax		= moment(document.getElementById('scheduledCallStartTime').getAttribute('max'), 'HH:mm');

	var scheduledCallEndTime			= moment(document.getElementById('scheduledCallEndTime').value, 'HH:mm');
	var scheduledCallEndTimeMin		= moment(document.getElementById('scheduledCallEndTime').getAttribute('min'), 'HH:mm');
	var scheduledCallEndTimeMax		= moment(document.getElementById('scheduledCallEndTime').getAttribute('max'), 'HH:mm');

	var actualCallStartTime 			= moment(document.getElementById('actualCallStartTime').value, 'HH:mm');
	var actualCallStartTimeMin			= moment(document.getElementById('actualCallStartTime').getAttribute('min'), 'HH:mm');
	var actualCallStartTimeMax			= moment(document.getElementById('actualCallStartTime').getAttribute('max'), 'HH:mm');
	
	var actualCallEndTime 				= moment(document.getElementById('actualCallEndTime').value, 'HH:mm');
	var actualCallEndTimeMin			= moment(document.getElementById('actualCallEndTime').getAttribute('min'), 'HH:mm');
	var actualCallEndTimeMax			= moment(document.getElementById('actualCallEndTime').getAttribute('max'), 'HH:mm');

	var timezoneID 						= document.getElementById('scheduledCallTimeZone').value;

	var scheduledCallStartDateTime, scheduledCallEndDateTime;
	var actualCallStartDateTime, actualCallEndDateTime;


	switch (attributeName) {
		
		case 'scheduledCallDate':
		
			if ( scheduledCallDate.isValid() ) {
				
				if ( actualCallDate.isValid() ) {
			
					if ( scheduledCallDate.isSameOrBefore(actualCallDate) ) {
						
						attributeValue = scheduledCallDate.format('YYYY-MM-DD');
						document.getElementById('actualCallDate').min = attributeValue;
						csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = scheduledCallDate.format('M/D/YYYY');
						csuiteInput.style.color = '';		
						
					} else {
						
						alert('Scheduled date must precede actual date');
						csuiteInput.style.color = 'crimson';
						csuiteInput.focus();
						csuiteInput.select();
						return false;
		
					}
					
				} else {
					
					attributeValue = scheduledCallDate.format('YYYY-MM-DD');
					document.getElementById('actualCallDate').min = attributeValue;
					csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = scheduledCallDate.format('M/D/YYYY');
					csuiteInput.style.color = '';		
										
				}
				
			
			} else {
				
				alert('Scheduled date is not valid');
				csuiteInput.style.color = 'crimson';
				csuiteInput.focus();
				csuiteInput.select();
				return false;
				
			}

			break;


		
		case 'scheduledCallStartTime':

			if (scheduledCallStartTime.isValid()) {
				
				if (scheduledCallStartTime.isBetween(scheduledCallStartTimeMin, scheduledCallStartTimeMax, null, '(]')) {

					attributeValue = scheduledCallStartTime.format('HH:mm');
					document.getElementById('scheduledCallEndTime').min = attributeValue;
					csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = scheduledCallStartTime.format('h:mm A');
					csuiteInput.style.color = '';
					
				} else {
					
					alert('Scheduled start time must be after midnight and before the scheduled end time');
					csuiteInput.style.color = 'crimson';
					csuiteInput.focus();
					csuiteInput.select();
					return false;
	
				}
				
			} else {
				
				alert('Scheduled start time is not valid');
				csuiteInput.style.color = 'crimson';
				csuiteInput.focus();
				csuiteInput.select();
				return false;

			}

			break;
			
			
		
		case 'scheduledCallEndTime':

			if (scheduledCallEndTime.isValid()) {
				
				if (scheduledCallEndTime.isBetween(scheduledCallEndTimeMin, scheduledCallEndTimeMax, null, '[]')) {
					
					attributeValue = scheduledCallEndTime.format('HH:mm');
					document.getElementById('scheduledCallStartTime').max = attributeValue;
					csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = scheduledCallEndTime.format('h:mm A');
					csuiteInput.style.color = '';
					
				} else {
					
					alert('Scheduled end time must be after the scheduled start time and before midnight');
					csuiteInput.style.color = 'crimson';
					csuiteInput.focus();
					csuiteInput.select();
					return false;
	
				}
				
			} else {
				
				alert('Scheduled end time is not valid');
				csuiteInput.style.color = 'crimson';
				csuiteInput.focus();
				csuiteInput.select();
				return false;
	
			}

			break;


		
		case 'scheduledCallTimeZone':

			attributeValue = scheduledCallTimeZone.value;
			var selectControl = document.getElementById('scheduledCallTimeZone');
			csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = selectControl.options[selectControl.selectedIndex].textContent;
			cmd = 'updateScheduledDateTime';

			break;


		
		case 'actualCallDate':
		
			if ( actualCallDate.isValid() ) {
				
				if ( actualCallDate.isSameOrAfter(scheduledCallDate) ) {
				
					attributeValue = actualCallDate.format('YYYY-MM-DD');
					document.getElementById('scheduledCallDate').max = attributeValue;
					csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = actualCallDate.format('M/D/YYYY');
					csuiteInput.style.color = '';
					
				} else {
					
					alert('Actual date must be the same or after the scheduled date');
					csuiteInput.style.color = 'crimson';
					csuiteInput.focus();
					csuiteInput.select();
					return false;
					
				}
				
			} else {
		
				alert('Actual date is not valid');
				csuiteInput.style.color = 'crimson';
				csuiteInput.focus();
				csuiteInput.select();
				return false;

			}
			
			break;
			
			
			
		case 'actualCallStartTime':
		
			if (actualCallStartTime.isValid()) {
				
				var errorMessage;
				if (actualCallDate.isSame(scheduledCallDate)) {
					
					actualCallStartTimeMin = scheduledCallStartTime;
					errorMessage = 'Actual start time must be after scheduled start time and before the actual end time';
					
				} else {
					
					errorMessage = 'Actual start time must be after midnight and before the actual end time';
					
				}
				

				if (actualCallStartTime.isBetween(actualCallStartTimeMin, actualCallStartTimeMax, null, '(]')) {
					
					attributeValue = actualCallStartTime.format('HH:mm');
					document.getElementById('actualCallEndTime').min = attributeValue;
					csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = actualCallStartTime.format('h:mm A');
					csuiteInput.style.color = '';

				} else {
					
					alert(errorMessage);
					csuiteInput.style.color = 'crimson';
					csuiteInput.focus();
					csuiteInput.select();
					return false;
					
				}
			
			} else {
				
				alert('Actual start time is not valid');
				csuiteInput.style.color = 'crimson';
				csuiteInput.focus();
				csuiteInput.select();
				return false;
				
			}

			break;


		
		case 'actualCallEndTime':
		
			if (actualCallEndTime.isValid()) {
				
				if (actualCallEndTime.isBetween(actualCallEndTimeMin, actualCallEndTimeMax, null, '[]')) {
					
					attributeValue = actualCallEndTime.format('HH:mm');
					document.getElementById('actualCallStartTime').max = attributeValue;
					csuiteParentDiv.querySelector('.csuite-textfield-viewValue').innerHTML = actualCallEndTime.format('h:mm A');
					csuiteInput.style.color = '';
					
					$( '#sendTitleBody' ).html( 'Send<br>Recap' );					
					
				} else {
					
					alert('Actual end time must be after actual start time and prior to midnight');
					csuiteInput.style.color = 'crimson';
					csuiteInput.focus();
					csuiteInput.select();
					return false;

				}
				
			} else {
				
				if ( csuiteInput.value == '' ) {
					
					if (confirm('Removing the end time will place the call "in process," are you sure you want to proceed?')) {


						attributeValue = 'NULL';
						document.getElementById('actualCallStartTime').max = '23:30';
						csuiteParentDiv.querySelector('div.csuite-textfield-viewValue').innerHTML = '';
						csuiteInput.style.color = '';
						
						$( '#sendTitleBody' ).html( 'Send<br>Agenda' );


					} else {
						
						csuiteInput.style.color = 'crimson';
						csuiteInput.focus();
						csuiteInput.select();
						return false;
						
					}
					
				} else {
			
					alert('Actual end time is not valid');
					csuiteInput.style.color = 'crimson';
					csuiteInput.focus();
					csuiteInput.select();
					return false;
				}
			
			}

			break;
			

		default:

			alert('Unexpected attribute name encountered, please contact your system administrator');

	}



		var requestUrl 	= 'ajax/customerCalls.asp?cmd=updateCallDateTimes' 
												+ '&callID=' 		+ callID 
												+ '&attribute=' 	+ attributeName
												+ '&value=' 		+ attributeValue;
	
// 		console.log(requestUrl);
												
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_dateAttribute;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_dateAttribute() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
	
					var msg = request.responseXML.getElementsByTagName('msg')[0].textContent;
					var notification = document.querySelector('.mdl-js-snackbar');
					notification.MaterialSnackbar.showSnackbar({
						message: msg
					});
	
				} else {
					
					alert("problem retrieving data from the server, status code: "  + request.status);
					
				}
			}
		
		}

		cSuiteHideInput(inputElem);
		

	event.cancelBubble = true;
	
}		
	

/************************************************************************************************/
function cSuiteHideInput(hideButton) {
/************************************************************************************************/
	
	var textField = hideButton.closest('.csuite-textfield');
	if (textField) {

		textField.querySelector('span').style.color = '';
		
		var csuiteTextfieldEditValue = textField.querySelector('.csuite-textfield-editValue');
		csuiteTextfieldEditValue.style.display = 'none';

		var csuiteTextfieldViewValue = textField.querySelector('.csuite-textfield-viewValue');
		csuiteTextfieldViewValue.style.display = 'block';

		var csuiteEditIcon = textField.querySelector('i');
		if (csuiteEditIcon) {
			csuiteEditIcon.style.visibility = 'visible';
		}

	}

	textField.classList.remove('is-editing');			
	event.cancelBubble = true;

}



/************************************************************************************************/
function cSuiteShowInput(textField) {
/************************************************************************************************/

	var textFieldsEditing = document.querySelectorAll('div.csuite-textfield.is-editing');
	if (textFieldsEditing.length > 0) {
		return false;
	}				

	if (textField.classList.contains('is-editing')) {
		return false;
	} else {
		textField.classList.add('is-editing');
	}
	
	var csuiteEditIcon = textField.querySelector('i');
	if (csuiteEditIcon) {
		csuiteEditIcon.style.visibility = 'hidden';
	}
	
	var csuiteTextfieldViewValue = textField.querySelector('.csuite-textfield-viewValue');
	if (csuiteTextfieldViewValue) {
		csuiteTextfieldViewValue.style.display = 'none';
	}
	
	var csuiteTextfieldEditValue = textField.querySelector('.csuite-textfield-editValue');
	if (csuiteTextfieldEditValue) {
		csuiteTextfieldEditValue.style.display = 'block';
		var csuiteTextEditValueInput;
		csuiteTextEditValueInput = csuiteTextfieldEditValue.querySelector('input, select, textarea');
		if (csuiteTextEditValueInput) {
			
			
			
			if (csuiteTextEditValueInput.type == 'date') {
				csuiteTextEditValueInput.value = moment(csuiteTextfieldViewValue.textContent).format('YYYY-MM-DD');
				csuiteTextEditValueInput.focus();
				csuiteTextEditValueInput.select();
			} else if (csuiteTextEditValueInput.type == 'time') {
				csuiteTextEditValueInput.value = moment(csuiteTextfieldViewValue.textContent, 'HH:mm A').format('HH:mm');
				csuiteTextEditValueInput.focus();
				csuiteTextEditValueInput.select();
			} else if (csuiteTextEditValueInput.type == 'select-one') {
				// do nothing, the correct option should already be selected from the initial .asp page
				csuiteTextEditValueInput.focus();
			} else {
				csuiteTextEditValueInput.value = csuiteTextfieldViewValue.textContent;					
			}
			
// 			csuiteTextEditValueInput.style.color = '';

		} else {
			csuiteTextEditValueInput = csuiteTextfieldEditValue.querySelector('select');
			if (csuiteTextEditValueInput) {

				csuiteTextEditValueInput.size = csuiteTextEditValueInput.length;
				csuiteTextEditValueInput.focus();


			}
		}
	}
	
	event.cancelBubble = true;

}



/*****************************************************************************************/
function ToggleEditIcon(csuiteTextfield) {
/*****************************************************************************************/

	var editIcon = csuiteTextfield.querySelector('i.edit');
	
	var textFieldsEditing = document.querySelectorAll('div.csuite-textfield.is-editing');

	if (textFieldsEditing.length == 0) {
		if (editIcon.style.visibility == 'hidden' || editIcon.style.visibility == '') {
			editIcon.style.visibility = 'visible';
		} else {
			editIcon.style.visibility = 'hidden';
		}
	}
	
}



/*****************************************************************************************/
function ToggleQuillEditIcon(quillEditField) {
/*****************************************************************************************/

	var editIcon = quillEditField.querySelector('button.editQuill');
	
	if (editIcon.style.visibility == 'hidden' || editIcon.style.visibility == '') {
		editIcon.style.visibility = 'visible';
	} else {
		editIcon.style.visibility = 'hidden';
	}
	
}



/*****************************************************************************************/
function UpdateScheduledDateTime(scheduledDateTimeElem) {
/*****************************************************************************************/
	
	var attribute 	= scheduledDateTimeElem.id;
	var value		= scheduledDateTimeElem.value;
	var callID		= scheduledDateTimeElem.getAttribute('data-callID');
	
	var requestUrl	= 'ajax/customerCalls.asp?cmd=updateScheduledDateTime'
										+ '&callID=' + callID
										+ '&attribute=' + attribute 
										+ '&value=' + encodeURIComponent(value);
										
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_startCall;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_startCall() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				var msg = request.responseXML.getElementsByTagName('msg')[0].textContent;
				var notification = document.querySelector('.mdl-js-snackbar');
				notification.MaterialSnackbar.showSnackbar({
					message: msg
				});

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
}



/*****************************************************************************************/
function ActualEndTime_onChange(actualEndTimeElem) {
/*****************************************************************************************/
	
	var endTime = moment(actualEndTimeElem.value, 'HH:mm');
	var minEndTime = moment(actualEndTimeElem.getAttribute('min'), 'HH:mm');

	if (actualEndTimeElem.parentNode.classList.contains('is-invalid')) {
		
		if (endTime < minEndTime) {
			alert('End time must follow start time.');
		} else {
			alert('End time is invalid.');
		}
		
		return false;
		
	}

	var actualDateElem 	=  document.getElementById('actualDate');
	var actualDate 		= moment(actualDateElem.value);
	
	var tempEndDateTime = moment([
				actualDate.year(), 
				actualDate.month(), 
				actualDate.date(), 
				endTime.hour(), 
				endTime.minute()
			]);
	

	var callID = actualEndTimeElem.getAttribute('data-callID');

	UpdateCallTimes(callID, 'updateEndTime', 'endDateTime', tempEndDateTime);
	
	
}


/*****************************************************************************************/
function ActualStartTime_onChange(actualStartTimeElem) {
/*****************************************************************************************/

	var startTime = moment(actualStartTimeElem.value, 'HH:mm');
	var maxStartTime = moment(actualStartTimeElem.getAttribute('max'), 'HH:mm');

	if (actualStartTimeElem.parentNode.classList.contains('is-invalid')) {
		
		if (startTime > maxStartTime) {
			alert('Start time must preceed end time.');
		} else {
			alert('Start time is invalid.');
		}
		
		return false;
		
	}


	var actualDateElem =  document.getElementById('actualDate');
	var actualDate = moment(actualDateElem.value);
	
	var tempStartDateTime = moment([
				actualDate.year(), 
				actualDate.month(), 
				actualDate.date(), 
				startTime.hour(), 
				startTime.minute()
			]);
	

	var callID = actualStartTimeElem.getAttribute('data-callID');

	UpdateCallTimes(callID, 'updateStartTime', 'startDateTime', tempStartDateTime);
	
	
}



/*****************************************************************************************/
function StartCall(startCallButton) {
/*****************************************************************************************/
	

	var tempStartDateTime = moment();
	
	// hide startCallButton
	var startCall = document.getElementById('startCall');
	startCall.style.display = 'none';
	
	
	// populate startDate with date portion of tempStartDateTime
	var actualCallDate 			= document.getElementById('actualCallDate');
	var csuiteActualCallDate 	= actualCallDate.closest('div.csuite-textfield');


	actualCallDate.value = tempStartDateTime.format('YYYY-MM-DD');
	actualCallDate.parentNode.classList.add('is-dirty');
	// populate the corresponding viewValue of the csuite controls
	var actualCallDateView = csuiteActualCallDate.querySelector('.csuite-textfield-viewValue');
	actualCallDateView.innerHTML = tempStartDateTime.format('M/D/YYYY');
	
	// display startDate
	csuiteActualCallDate.style.display = 'block';
	
	// populate startTime with current time
	var actualCallStartTime 		= document.getElementById('actualCallStartTime');
	var csuiteActualCallStartTime = actualCallStartTime.closest('div.csuite-textfield');
	
	actualCallStartTime.value = tempStartDateTime.format('HH:mm');
	actualCallStartTime.parentNode.classList.add('is-dirty');
	// populate corresponding viewValud of the csuite controls....
	var actualCallStartTimeView = csuiteActualCallStartTime.querySelector('.csuite-textfield-viewValue');
	actualCallStartTimeView.innerHTML = tempStartDateTime.format('h:mm A');
	
	// set MINimum endTime equal to startTime
	var actualCallEndTime = document.getElementById('actualCallEndTime');
	actualCallEndTime.setAttribute('min', tempStartDateTime.format('HH:mm'))	
	
	// display actualDateTime container
	var actualDateTime = document.getElementById('actualDateTime');
	actualDateTime.style.display = 'inline-block';
	
	var callID = startCallButton.getAttribute('data-callID');
	
	UpdateCallTimes(callID, 'startCall', 'startDateTime', tempStartDateTime);
	
	
	// hide actualEndTime csuite-textfield
	var endCallTime 			= document.getElementById('actualCallEndTime');
	var endCallParentDiv 	= endCallTime.closest('div.csuite-textfield');
	endCallParentDiv.style.display = 'none';
	endCallTime.style.color = '';			

	// reveal "end call" control
	var endCallControl = document.getElementById('endCall');
	endCallControl.style.display = 'inline-block';
	
	
}



/*****************************************************************************************/
function EndCall(endCallButton) {
/*****************************************************************************************/

// var tempEndCallDateTime = moment();
	var endCallDate			= document.getElementById('actualCallDate');
	var tempEndCallDateTime = moment(endCallDate.value + ' ' + moment().format('HH:mm'));
	
	// hide endCallButton...
	endCallButton.closest('div').style.display = 'none';
	
	//populate and display endTime with current time...
	var actualCallEndTime = document.getElementById('actualCallEndTime');
	var csuiteCallEndTime = actualCallEndTime.closest('div.csuite-textfield');
	
	actualCallEndTime.value = tempEndCallDateTime.format('HH:mm');
	actualCallEndTime.parentNode.classList.add('is-dirty');
	// 	actualCallEndTime.parentNode.style.display = 'inline-block';
	// populate corresponding viewValue of the csuite control....
	var actualCallEndTimeView = csuiteCallEndTime.querySelector('.csuite-textfield-viewValue');
	actualCallEndTimeView.innerHTML = tempEndCallDateTime.format('h:mm A');
	
	// set MAX startTime same as endTime...
	var actualCallStartTime = document.getElementById('actualCallStartTime');
	actualCallStartTime.setAttribute('max', tempEndCallDateTime.format('HH:mm'))	
	
	
	var callID = startCallButton.getAttribute('data-callID');

	// display actualCallEndTime container...
	csuiteCallEndTime.style.display = 'inline-block';
	
	$( '#sendTitleBody' ).html( 'Send<br>Recap' );

	UpdateCallTimes(callID, 'endCall', 'endDateTime', tempEndCallDateTime);
	
}



/*****************************************************************************************/
function UpdateCallTimes(callID, cmd, dateTimeElement, dateTimeValue) {
/*****************************************************************************************/
	
	var requestUrl	= 'ajax/customerCalls.asp?cmd=' + cmd
										+ '&callID=' + callID
										+ '&' + dateTimeElement +'=' + encodeURIComponent(dateTimeValue.format('YYYY-MM-DD HH:mm'));
										
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateCallTimes;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_updateCallTimes() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				var msg = request.responseXML.getElementsByTagName('msg')[0].textContent;
				var notification = document.querySelector('.mdl-js-snackbar');
				notification.MaterialSnackbar.showSnackbar({
					message: msg
				});

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
}



/*****************************************************************************************/
function SaveCallAttendees() {
/*****************************************************************************************/
	
	var titleElem 				= dialog_editAttendees.querySelector('#editAttendeesTitle');		
	var editAttendeesTable 	= document.getElementById('editAttendeesTable');
	var customerID				= dialog_editAttendees.querySelector('#customerID').value;
	var customerCallID 		= dialog_editAttendees.querySelector('#customerCallID').value;
	var attendeeType;
	
	if (titleElem.textContent.includes('Customer')) {
		attendeeType = 'contact';
	} else {
		attendeeType = 'user';
	}


	var attendees	 			= editAttendeesTable.querySelectorAll('input[type=checkbox]');	
	var attendeesToAdd;
	
	if (attendees) {
		for (i = 0; i < attendees.length; ++i) {
			
			if (attendees[i].checked) {
				
				if (attendeesToAdd) {
					attendeesToAdd += ',' + attendees[i].getAttribute('data-id');
				} else {
					attendeesToAdd = attendees[i].getAttribute('data-id');					
				}
				
				
			}
			
		}
		
	}
	
	dialog_editAttendees.close();
	

	var requestUrl	= "ajax/customerCalls.asp?cmd=addAttendees"
										+ "&customerID=" + customerID 
										+ "&customerCallID=" + customerCallID
										+ "&attendeeType=" + attendeeType
										+ "&attendeesToAdd=" + attendeesToAdd;
										
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_addAttendees;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addAttendees() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_Attendee(request.responseXML);
				location = location;
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
}



/*****************************************************************************************/
function GetAttendees(fab) {
/*****************************************************************************************/

	var titleElem 			= dialog_editAttendees.querySelector('#editAttendeesTitle');
	var customerID			= dialog_editAttendees.querySelector('#customerID').value;
	var customerCallID 	= fab.getAttribute('data-id');
	var attendeeType;
	
	if (fab.classList.contains('clientAttendees')) {
	
		titleElem.innerHTML = 'Add Attendees';
		attendeeType = 'user';
	
	} else if (fab.classList.contains('customerAttendees')) {
	
		titleElem.innerHTML = 'Add Customer Attendees';
		attendeeType = 'contact';
	
	} else {
	
		alert('Attendee type could not be determined');
		return false;
	}

	var requestUrl	= "ajax/customerCalls.asp?cmd=getAttendees"
										+ "&customerID=" + customerID 
										+ "&customerCallID=" + customerCallID
										+ "&attendeeType=" + attendeeType;
										
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_getAttendees;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_getAttendees() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_getAttendees(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
}



/*****************************************************************************************/
function Complete_getAttendees(xml) {
/*****************************************************************************************/
	
	var attendees 				= xml.getElementsByTagName('attendee');
	var editAttendeesTable 	= document.getElementById('editAttendeesTable');
	
	var attendeeID, attendeeName;
	
	if (attendees) {
		
		// remove all existing rows from the table body...
		var editAttendeesTableBody = editAttendeesTable.querySelector('tbody');
		if (editAttendeesTableBody) {
			editAttendeesTableBody.innerHTML = '';
		}
		
		for (i = 0; i < attendees.length; ++i) {
			
			attendeeID = attendees[i].getAttribute('id');
			attendeeName = attendees[i].textContent;
			
			var newRow 	= editAttendeesTable.insertRow(-1);
			var newCell0 = newRow.insertCell(0);
			
			newCell0.innerHTML 	= '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="attendee-' + attendeeID + '">'
											+ '<input type="checkbox" id="attendee-' + attendeeID + '" data-id="' + attendeeID + '" class="mdl-checkbox__input">'
										+ '</label>';

			var newCell1 = newRow.insertCell(1);
			newCell1.innerHTML = attendeeName;
											
		}
		
		componentHandler.upgradeAllRegistered();

		
	}
	
	dialog_editAttendees.showModal();

	
}



/*****************************************************************************************/
function PrepSendDialog (callName, scheduledStartDateTime, startDatetime,timezoneName) {
/*****************************************************************************************/
	
	debugger
	var sendTitleDialog 	= document.getElementById('sendTitleDialog');
	sendTitleDialog.innerHTML = callName;
	
	var sendCall_subject = document.getElementById('sendCall_subject');
	var callSubject = sendCall_subject.value;
	
	var endDateTime = document.getElementById('actualCallEndTime').value;
	if (endDateTime) {
		callSubject = callSubject.replace('Agenda','Recap');
	}
	

	// BUILD THE LIST OF CLIENT ATTENDEES
	var clientAttendeesTable = document.getElementById('clientAttendees');
	var clientAttendeesTRs = clientAttendeesTable.querySelectorAll('tr.callAttendeeRow');
	if (clientAttendeesTRs) {
		
		// get <table> that contains the clientManagers and delete the contents of <tbody> ...
		var sendClientManagersTable 		= document.getElementById('sendClientManagers');
		var sendClientManagersTableBody 	= sendClientManagersTable.querySelector('tbody');
		if (sendClientManagersTableBody) {
			sendClientManagersTableBody.innerHTML = '';
		}
		
		// now populate the <tbody> ...
		for (i = 0; i < clientAttendeesTRs.length; ++i) {
			
			// collect information needed to populate table...
			var clientAttendeeInputElem 	= clientAttendeesTRs[i].querySelector('input[type=checkbox]');
			var clientAttendeeID 			= clientAttendeeInputElem.getAttribute('data-val');
			var clientAttendeeEmail			= clientAttendeeInputElem.getAttribute('data-email');
			var clientAttendeeName			= clientAttendeesTRs[i].querySelector('span.mdl-chip__text').textContent;
						
			var clientAttendeeChecked;
			if (clientAttendeeInputElem.checked) {
				clientAttendeeChecked = 'checked';
			} else {
				clientAttendeeChecked = '';
			}

			
			// now insert that data into new rows in the table...
			var newRow = sendClientManagersTable.insertRow(-1);
			var newCell0 = newRow.insertCell(0);
			
			newCell0.innerHTML = '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="clientMgr-' + clientAttendeeID + '">'
											+ '<input type="checkbox" id="clientMgr-' + clientAttendeeID + '" data-email="' + clientAttendeeEmail + '" class="mdl-checkbox__input tegRcpt" ' + clientAttendeeChecked + '>'
									 + '</label>';

			var newCell1 = newRow.insertCell(1);
			newCell1.innerHTML = clientAttendeeName;
			
		}
		
	}
	

	// BUILD THE LIST OF CUSTOMER ATTENDEES
	var customerAttendeesTable = document.getElementById('customerAttendees');
	var customerAttendeesTRs = customerAttendeesTable.querySelectorAll('tr.callAttendeeRow');
	if (customerAttendeesTRs) {
		
		// get <table> that contains the clientManagers and delete the contents of <tbody> ...
		var sendCustomerContactsTable 		= document.getElementById('sendCustomerContacts');
		var sendCustomerContactsTableBody 	= sendCustomerContactsTable.querySelector('tbody');
		if (sendCustomerContactsTableBody) {
			sendCustomerContactsTableBody.innerHTML = '';
		}
		
		// now populate the <tbody> ...
		for (i = 0; i < customerAttendeesTRs.length; ++i) {
			
			// collect information needed to populate table...
			var customerAttendeeInputElem	= customerAttendeesTRs[i].querySelector('input[type=checkbox]');
			var customerAttendeeID 			= customerAttendeeInputElem.getAttribute('data-val');
			var customerAttendeeEmail		= customerAttendeeInputElem.getAttribute('data-email');
			var customerAttendeeName		= customerAttendeesTRs[i].querySelector('span.mdl-chip__text').textContent;
			var customerAttendeeDisabled;
			
			if (customerAttendeeEmail) {
				customerAttendeeDisabled = '';
				var customerAttendeeChecked;
				if (customerAttendeeInputElem.checked) {
					customerAttendeeChecked = 'checked';
				} else {
					customerAttendeeChecked = '';
				}
			} else {
				customerAttendeeDisabled = 'disabled';
				customerAttendeeChecked = '';
			}
						
			
			// now insert that data into new rows in the table...
			var newRow = sendCustomerContactsTable.insertRow(-1);
			var newCell0 = newRow.insertCell(0);
			
			newCell0.innerHTML = '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="custContact-' + customerAttendeeID + '">'
											+ '<input type="checkbox" id="custContact-' + customerAttendeeID 
													+ '" data-email="' + customerAttendeeEmail 
													+ '" class="mdl-checkbox__input tegRcpt" ' + customerAttendeeChecked + ' ' + customerAttendeeDisabled 
											+ '>'
									 + '</label>';

			var newCell1 = newRow.insertCell(1);
			newCell1.innerHTML = customerAttendeeName;
			
		}
		
	}
	




	
	sendCall_subject.value = callSubject;

	componentHandler.upgradeAllRegistered();
	
	dialog_sendCall.showModal();
	
}


/*****************************************************************************************/
function UpdateTimeZone_onChange(htmlElement,customerCallID) {
/*****************************************************************************************/
	
	var attributeName = htmlElement.id;
	var attributeValue = htmlElement.options[htmlElement.selectedIndex].value;
	
	var requestUrl	= "ajax/customerCalls.asp?cmd=updateTimezone"
										+ "&customerCallID=" + customerCallID
										+ "&name=" + attributeName
										+ "&value=" + attributeValue;
										
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateTimeZone;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_updateTimeZone() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_updateTimezone(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_updateTimezone(xml) {
/*****************************************************************************************/

	var msg 						= GetInnerText(xml.getElementsByTagName('msg')[0]);

	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

}



/*****************************************************************************************/
function CallLead_onChange(htmlElement) {
/*****************************************************************************************/
	
	var customerCallID		= document.getElementById("customerCallID").value;
	var callLead 				= htmlElement.value;
	
	var requestUrl = "ajax/customerCalls.asp?cmd=updateCallLead"
										+ "&id=" + customerCallID 
										+ "&callLead=" + callLead;
										
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateCallLead;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_updateCallLead() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_updateCallLead(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_updateCallLead(xml) {
/*****************************************************************************************/

	var msg 						= GetInnerText(xml.getElementsByTagName('msg')[0]);

	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

}



/*****************************************************************************************/
function SendCall(customerCallID, customerID, sessionJWT, cbFunction ) {
/*****************************************************************************************/

// get the customerContact emails and concatonate into a comma-seperated string...
	var sendCall_to;
	var toList = document.getElementsByClassName('CustMgrRcpt');
	for (var i = 0; i < toList.length; i++) {
		if ( toList[i].checked && toList[i].getAttribute('data-email').length > 0 ) {
			if (sendCall_to) {
				sendCall_to += ',' + toList[i].getAttribute('data-email').trim();
			} else {
				sendCall_to = toList[i].getAttribute('data-email').trim();
			}
		}
	}
// 	console.log('sendCall_to: ' + sendCall_to);
	

// get the customerManager emails and concatonate into a comma-seperated string...
	var sendCall_cc = '';
	var ccList = document.getElementsByClassName('tegRcpt');
	for (var i = 0; i < ccList.length; i++) {
		if ( ccList[i].checked && ccList[i].getAttribute('data-email') ) {
			if (sendCall_cc) {
				sendCall_cc += ',' + ccList[i].getAttribute('data-email').trim();
			} else {
				sendCall_cc = ccList[i].getAttribute('data-email').trim();
			}
		}
	}
	
	if (!sendCall_to) {
		sendCall_to = sendCall_cc;
		sendCall_cc = '';
	}
	
// 	console.log('sendCall_cc: ' + sendCall_cc + ', sendCall_to: ' + sendCall_to);


// NOTE: If 'sendAdditional' addresses will be added to "to:" if there are no other addressed already present in "to:",
//       else they will be added to "cc:"
//
	var sendAdditional = document.getElementById('sendCall_to').value;
	if (sendAdditional) {
		if (sendCall_to) {
			if (sendCall_cc) {
				sendCall_cc += ',' + sendAdditional.trim();
			} else {
				sendCall_cc += sendAdditional.trim();
			}
		} else {
				sendCall_to = sendAdditional.trim();
		}
	}	
// 	console.log('sendCall_cc: ' + sendCall_cc);

	
	var sendCall_subject 	= document.getElementById("sendCall_subject").value;
	var sendCall_comments	= document.getElementById("sendCall_comments").value; 
	

	$.ajax({
		url: apiServer + '/api/customerCalls/emailCall',
		type: 'post',
		data: JSON.stringify({ 
			callID: customerCallID,
			customerID: customerID,
			to: sendCall_to,
			cc: sendCall_cc,
			subject: sendCall_subject,
			comments: sendCall_comments 
		}),
		contentType: "application/json; charset=utf-8",
		dataType   : "json",
		headers: {
			'Authorization': 'Bearer ' + sessionJWT
		},
	});
	
	cbFunction();

}


/*****************************************************************************************/
function Complete_SendCallxxx(xml) {
/*****************************************************************************************/

	var msg 						= GetInnerText(xml.getElementsByTagName('msg')[0]);
	var callID 					= GetInnerText(xml.getElementsByTagName('callID')[0]);
	var customerID				= GetInnerText(xml.getElementsByTagName('customerID')[0]);

	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

	location.href = 'annotateCalls.asp?customerID='+customerID+'&callID='+callID+'&tab=calls';
	
}



/*****************************************************************************************/
function UpdateDateTime_onClick(type,customerCallID) {
/*****************************************************************************************/


	var currentDateTime = moment();

	if (type == 'start') {
		
		document.getElementById("startDateTime").value = currentDateTime.format('YYYY-MM-DDTHH:mm');
		document.getElementById("timerStartIcon").style.display = 'none';
		document.getElementById("timerEndIcon").style.display = 'block';
		
		var timezoneName = moment.tz.guess();
		
		
	} else {
		
		document.getElementById("endDateTime").value = currentDateTime.format('YYYY-MM-DDTHH:mm');
		document.getElementById("timerEndIcon").style.display = 'none';
				
	}
	
	
	var requestUrl = "ajax/customerCalls.asp?cmd=" + type + "DateTime"
											+ "&id=" + customerCallID
											+ "&timezone=" + timezoneName
											+ "&value=" + encodeURIComponent(currentDateTime.format('YYYY-MM-DD HH:mm'));
											
// 	console.log(requestUrl);
	
	CreateRequest();
	
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdateDateTime;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_UpdateDateTime() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_CallDate(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
}

/*****************************************************************************************/
function EditQuill_onClick(htmlElement) {
/*****************************************************************************************/

// get values from htmlElement

	var customerCallID 	= htmlElement.getAttribute('customerCallID');
	var callNoteTypeID 	= htmlElement.getAttribute('callNoteTypeID');
	var updatedDateTime	= htmlElement.getAttribute('data-ts');

// get narrative (ajax)
	var requestUrl 	= "ajax/customerCalls.asp?cmd=getQuill"
											+ "&customerCallID=" + customerCallID 
											+ "&callNoteTypeID=" + callNoteTypeID;

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_EditQuill;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_EditQuill() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_EditQuill(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
		
}
	
	
/*****************************************************************************************/
function Complete_EditQuill(xml) {
/*****************************************************************************************/

// setup the dialog/form

	var id 					= xml.getElementsByTagName('id')[0].textContent;
	var msg 					= xml.getElementsByTagName('msg')[0].textContent;
	var narrative 			= xml.getElementsByTagName('narrative')[0].textContent;
	var noteTypeID 		= xml.getElementsByTagName('noteTypeID')[0].textContent;
	var noteTypeName 		= xml.getElementsByTagName('noteTypeName')[0].textContent;
	var quillID 			= xml.getElementsByTagName('quillID')[0].textContent;
	var updatedDatetime	= xml.getElementsByTagName('updatedDateTime')[0].textContent;

	document.getElementById('editAnnotationTitle').innerHTML = noteTypeName;
	document.getElementById('genericCustomerCallNoteID').value = id;
	document.getElementById('genericNoteTypeID').value = noteTypeID;
	document.getElementById('genericQuillID').value = quillID;
	document.getElementById('genericTimeStamp').value = updatedDatetime;
	
	const MSwordMatcher = function (node, delta) {

		const _build = [];
		while (true) {
			if (node) {
				if (node.tagName === 'P') {
					const content = node.querySelectorAll('span'); //[0] index contains bullet or numbers, [1] index contains spaces, [2] index contains item content
					const _nodeText = content[2].innerText.trim();
					//const _listType = content[0].innerText.match(/[0-9]/g) ? 'ordered' : 'bullet'; //@TODO: implement ordered lists
					_build.push({ insert: `${_nodeText}\n`, attributes: { 'bullet': true } });
					if (node.className === 'MsoListParagraphCxSpLast') {
						break;
					}
				}
			}	
			node = node.nextSibling;
		}
		return new Delta(_build);

	};
	
	const matcherNoop = (node, delta) => ({ ops: [] });



	var objGenericQuillNote = new Quill('#genericQuillNote', {
		modules: {
			toolbar: [
				[{ header: [1, 2, false] }],
				[{ size: [ 'small', false, 'large' ]}],
				['bold',	'italic', 'underline'],
				['link'],
				[{'list': 'ordered'}],
				[{'list': 'bullet' }],
				[{'indent': '-1'}],
				[{'indent': '+1' }],
				[{'color': [] }],
				[{'background': [] }]
			],
		},		
		theme: 'snow'
	});
	
	objGenericQuillNote.keyboard.addBinding({ 
		key: '0',
		shiftKey: true,
		prefix: /(tm)/,
	}, function(range, context) {
		this.quill.deleteText(range.index-3, 4);
		this.quill.insertText(range.index-3, '\u2122', true);
	});	



/*
	var genericQuillNote = new Quill('#genericQuillNote', {
		modules: {
			toolbar: toolbarOptions
			},		
			theme: 'snow'
	});
*/

// Would it be better to generate a "raw" quilljs string instead of using the JSON.parse() method?

// open the dialog
	dialog_editAnnotation.showModal();


	if (narrative != null && narrative.length > 0) {
		objGenericQuillNote.setContents(JSON.parse(narrative));
		objGenericQuillNote.setSelection(0, narrative.length);		
	} else {
		objGenericQuillNote.setSelection(0, 0);		
	}
	objGenericQuillNote.focus();
	

// 	dialog_editAnnotation.style.top 	= ((window.innerHeight/2) - (dialog_objective.offsetHeight/2))+'px';



}


/*****************************************************************************************/
function showCallNoteHistory(showHistoryButton) {
/*****************************************************************************************/
	
	var customerCallID		= showHistoryButton.getAttribute('data-customerCallID');
	var callNoteTypeID		= showHistoryButton.getAttribute('data-callNoteTypeID');
	
// get call note history....
	var requestUrl 	= 'ajax/customerCalls.asp?cmd=getCallNoteHistory'
											+ '&customerCallID=' + customerCallID 
											+ '&callNoteTypeID=' + callNoteTypeID;

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_getCallNoteHistory;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_getCallNoteHistory() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_getCallNoteHistory(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
		
}
	
	
/*****************************************************************************************/
function Complete_getCallNoteHistory(xml) {
/*****************************************************************************************/

	var customerCallID 				= xml.getElementsByTagName('customerCallID')[0].textContent;
	var callNoteTypeID 				= xml.getElementsByTagName('callNoteTypeID')[0].textContent;
	var callNoteTypeName				= xml.getElementsByTagName('noteTypeName')[0].textContent;
	var callNoteHistory 				= xml.getElementsByTagName('customerCallNote');

	var dialog_callNoteHistory 	= document.getElementById('dialog_callNoteHistory');
	var dialogTitleElem				= dialog_callNoteHistory.querySelector('#callNoteHistoryTitle');
	dialogTitleElem.innerHTML 		= 'Call Note History for ' + callNoteTypeName;

	var updatedByTable =  dialog_callNoteHistory.querySelector('#updatedByTable');

	var userFullName, updatedBy, updatedDateTime; 
	
	dialog_callNoteHistory.showModal();

	for (i = 0; i < callNoteHistory.length; ++i){

		userFullName 		= callNoteHistory[i].getElementsByTagName('userFullName')[0].textContent;
		updatedBy 			= callNoteHistory[i].getElementsByTagName('updatedBy')[0].textContent;
		updatedDateTime 	= callNoteHistory[i].getElementsByTagName('updatedDateTime')[0].textContent;
		
		var newRow = updatedByTable.insertRow(-1);
		var newCell = newRow.insertCell(-1);
		newCell.classList.add('mdl-data-table__cell--non-numeric');
		newCell.style.cursor = 'pointer';
		newCell.style.verticalAlign = 'middle';

		newCell.innerHTML = '<div style="float: left;"><b>' + userFullName + '</b><br>' + updatedDateTime +'</div>'
								+ '<div class="controlIcons" style="display: inline-block; float: right; visibility: hidden;">'
									+ '<i class="material-icons" title="Make this note the &quot;current&quot; note">double_arrow</i>'
								+ '</div>';

		newCell.setAttribute('data-customerCallID', customerCallID);
		newCell.setAttribute('data-callNoteTypeID', callNoteTypeID);
		newCell.setAttribute('data-updatedBy', updatedBy);
		newCell.setAttribute('data-updatedDateTime', updatedDateTime);
		newCell.addEventListener('click', function() {

			var allControlIcons = dialog_callNoteHistory.querySelectorAll('.controlIcons');
			for (i = 0; i < allControlIcons.length; ++i) {
				allControlIcons[i].style.visibility = 'hidden';
			}

			var thisControlIcon = this.querySelector('.controlIcons');
			if (thisControlIcon) {
				thisControlIcon.style.visibility = 'visible';
			}
			showThisHistoricalNote(this);			

		});
		
		// if the note represents the current note, then display it's contents on the dialog. This should always be the 
		// the first note in the XLM...
		var noteType = xml.getElementsByTagName('type')[i].textContent;
		if (noteType == 'current') {
			showThisHistoricalNote(newCell);
			newCell.querySelector('.controlIcons').style.visibility = 'visible';
		}

	}

	dialog_callNoteHistory.style.top = ((window.innerHeight/2) - (dialog_callNoteHistory.offsetHeight/2))+'px';

}




/*****************************************************************************************/
function EditAnnotation_onSave() {
/*****************************************************************************************/
	
	var scrollPosition		= $( '#genericQuillNote' ).scrollTop();

	var objGenericQuillNote = new Quill( '#genericQuillNote' );
	var quillContents			= objGenericQuillNote.getContents();
	var quillContentString 	= JSON.stringify( quillContents );	
	var quillContentHTML 	= objGenericQuillNote.root.innerHTML;
	

	$.post('ajax/customerCalls.asp?cmd=saveQuill', {
			callID: 					$( '#genericCustomerCallID' ).val(),
			callNoteTypeId: 		$( '#genericNoteTypeID' ).val(),
			genericTimeStamp: 	$( '#genericTimeStamp' ).val(),
			callNoteNarrative: 	quillContentString,
			callNoteHTML: 			quillContentHTML
		},
		function( xml, status ) {

			Complete_EditAnnotation( xml, scrollPosition );
			
		}
	);


}


/*****************************************************************************************/
function Complete_EditAnnotation( xml, scrollPosition ) {
/*****************************************************************************************/

	
	var msg 						= GetInnerText( xml.getElementsByTagName( 'msg' )[0]) ;
	var quillID 				= GetInnerText( xml.getElementsByTagName( 'quillID' )[0] );
	var rawQuillID 			= GetInnerText( xml.getElementsByTagName( 'rawQuillID' )[0] );
	var callNoteNarrative 	= GetInnerText( xml.getElementsByTagName( 'callNoteNarrative' )[0]) ;
	
	eval(quillID).setContents(JSON.parse(callNoteNarrative));

	var callHistorybutton = $( '#historyButton_'+quillID ).get(0);
	if (callHistorybutton) {
		callHistorybutton.style.display = 'inline-block';
	}
	
	$( '#genericQuillNote' ).scrollTop( scrollPosition );
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar({
		message: msg
	});
	
}


/*****************************************************************************************/
function showThisHistoricalNote(htmlElement) {
/*****************************************************************************************/
	
	var customerCallID 	= htmlElement.getAttribute('data-customercallid');
	var callNoteTypeID 	= htmlElement.getAttribute('data-callnotetypeid');
	var updatedBy 			= htmlElement.getAttribute('data-updatedBy');
	var updatedDateTime 	= htmlElement.getAttribute('data-updatedDatetime');
	
	// get a specific historical note...
	var requestUrl 	= 'ajax/customerCalls.asp?cmd=getHistoricalNote'
											+ '&customerCallID=' 	+ customerCallID 
											+ '&callNoteTypeID=' 	+ callNoteTypeID
											+ '&updatedBy=' 			+ updatedBy 
											+ '&updatedDateTime=' 	+ updatedDateTime;

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_showThisHistoricalNote;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_showThisHistoricalNote() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_showThisHistoricalNote(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}


/*****************************************************************************************/
function Complete_showThisHistoricalNote(xml) {
/*****************************************************************************************/


	var dialog_callNoteHistory = document.getElementById('dialog_callNoteHistory');
	var historyQuillNoteElem	= dialog_callNoteHistory.querySelector('#historyQuillNote');
	
	if (xml) {
	
		var narrativeElem		= xml.getElementsByTagName('narrative')[0];	
		var narrativeContent = GetInnerText(narrativeElem);
		
		if (narrativeContent) {

			var historyQuillNote = new Quill('#historyQuillNote', {
				modules: {
					toolbar: false
					},		
				readOnly: true,
				theme: 'snow'
			});
			
			historyQuillNote.setContents(JSON.parse(narrativeContent));
			
			if (historyQuillNote.getLength() <= 1) {
				historyQuillNoteElem.innerHTML = '<i>This version is empty.</i>';
			}

		} else {

			historyQuillNoteElem.innerHTML = '<i>This version is empty.</i>';

		}

	} else {
		
		historyQuillNoteElem.innerHTML = '<i>This version is empty.</i>';
		
	}
	
	var historyType = GetInnerText(xml.getElementsByTagName('historyType')[0]);
	
	if (historyType == 'current') {
		
		dialog_callNoteHistory.querySelector('#makeCurrent').style.display = 'none';
		
	} else {
		
		var makeCurrentButton 	= dialog_callNoteHistory.querySelector('#makeCurrent');
		var customerCallID 		= GetInnerText(xml.getElementsByTagName('customerCallID')[0]);
		var callNoteTypeID 		= GetInnerText(xml.getElementsByTagName('callNoteTypeID')[0]);
		var updatedBy 				= GetInnerText(xml.getElementsByTagName('updatedBy')[0]);
		var updatedDateTime 		= GetInnerText(xml.getElementsByTagName('updatedDateTime')[0]);
		
		makeCurrentButton.setAttribute('data-customerCallID', customerCallID);
		makeCurrentButton.setAttribute('data-callNoteTypeID', callNoteTypeID);
		makeCurrentButton.setAttribute('data-updatedBy', updatedBy);
		makeCurrentButton.setAttribute('data-updatedDateTime', updatedDateTime);
		makeCurrentButton.style.display = 'block';
		
	}

	
}


/*****************************************************************************************/
function makeThisNoteCurrent(makeCurrentButton) {
/*****************************************************************************************/
	
	var customerCallID 		= makeCurrentButton.getAttribute('data-customerCallID');
	var callNoteTypeID 		= makeCurrentButton.getAttribute('data-callNoteTypeID');
	var updatedBy 				= makeCurrentButton.getAttribute('data-updatedBy');
	var updatedDateTime 		= makeCurrentButton.getAttribute('data-updatedDateTime');
	
	var requestUrl 	= 'ajax/customerCalls.asp?cmd=makeThisNoteCurrent'
											+ '&customerCallID=' 	+ customerCallID 
											+ '&callNoteTypeID=' 	+ callNoteTypeID
											+ '&updatedBy=' 			+ updatedBy 
											+ '&updatedDateTime=' 	+ updatedDateTime;

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_makeThisNoteCurrent;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_makeThisNoteCurrent() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_makeThisNoteCurrent(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}



/*****************************************************************************************/
function Complete_makeThisNoteCurrent(xml) {
/*****************************************************************************************/


	var msg 							= xml.getElementsByTagName('msg')[0].textContent;
	var notification 				= document.querySelector('.mdl-js-snackbar');
	var dialog_callNoteHistory = document.querySelector('#dialog_callNoteHistory');
	
	if (msg == 'Narrative replaced')	{

		notification.MaterialSnackbar.showSnackbar(
			{
			message: msg
			}
		);

	} else {
		
		alert('Replacement of narrative failed; contact your system administrator');
		
	}

	dialog_callNoteHistory.close();
	
	location = location;
	
	
}



/*****************************************************************************************/
function StateChangeHandler_UpdateNarrative(xml) {
/*****************************************************************************************/

	var msg 						= GetInnerText(xml.getElementsByTagName('msg')[0]);

	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}



/*****************************************************************************************/
function CallDate_onBlur( htmlElement ) {
/*****************************************************************************************/

	var customerCallID = htmlElement.getAttribute("customercallid");
	var originalCallDateTime = htmlElement.getAttribute("data-val");
	var customerCallDateTime = htmlElement.value;
	var customerCallDateType = htmlElement.id;
	
	if (originalCallDateTime == customerCallDateTime) {
		return false;
	}
	
	// validate date here
	
	var requestUrl = "ajax/customerCalls.asp?cmd=callDate"
											+ "&customerCallID=" + customerCallID
											+ "&customerCallDateType=" + customerCallDateType
											+ "&customerCallDateTime=" + encodeURIComponent(customerCallDateTime);

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_CallDate;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_CallDate() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_CallDate(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}	
	
}


/*****************************************************************************************/
function Complete_CallDate(xml) {
/*****************************************************************************************/

	var msg 			= GetInnerText(xml.getElementsByTagName('msg')[0]);
	var dateType 	= GetInnerText(xml.getElementsByTagName('customerCallDateType')[0]);
	
	if (dateType == 'scheduledEndDateTime') {

		//calculate new scheduled duration
		var startTime 	= moment(document.getElementById('scheduledStartDateTime').value);
		var endTime		= moment(document.getElementById('scheduledEndDateTime').value);
		var duration	= endTime.diff(startTime,'minutes');
		document.getElementById('scheduledDuration').innerHTML = duration.toString() + ' min';

	} else if (dateType == 'endDateTime') {
			
		//calculate new actual duration
		var startTime 	= moment(document.getElementById('startDateTime').value);
		var endTime		= moment(document.getElementById('endDateTime').value);
		var duration	= endTime.diff(startTime,'minutes');
		var actualDuration 				= document.getElementById('actualDuration');
		actualDuration.innerHTML 		= duration.toString() + ' min';
		actualDuration.style.display 	= 'block';

		var timerEndIcon = document.getElementById('timerEndIcon');
		timerEndIcon.style.display = 'none';
		
		var sendTitleDialog 			= document.getElementById('sendTitleDialog');
		sendTitleDialog.innerHTML 	= "Send Recap"
		var sendTitleBody 			= document.getElementById('sendTitleBody');
		sendTitleBody.innerHTML 	= "Send Recap"

	} else if (dateType == "startDateTime") {

		document.getElementById('timerStartIcon').style.display = 'none';
		document.getElementById('timerEndIcon').style.display = 'block';
		
		var timezoneID = GetInnerText (xml.getElementsByTagName('timezoneID')[0]);
		document.getElementById('timeZone').value = timezoneID;

	}
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	


}


/*****************************************************************************************/
function CallType_onChange( htmlElement ) {
/*****************************************************************************************/

	var callID = htmlElement.getAttribute("customercallid");
	var callTypeID = htmlElement.value;
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=callType"
											+ "&callID=" + callID 
											+ "&callTypeID=" + callTypeID;

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_CallType;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_CallType() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_CallType(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}	
	
}


/*****************************************************************************************/
function Complete_CallType(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	



}



// /*****************************************************************************************/
// function DeleteCallAttendee_onClick(htmlElement) {
// /*****************************************************************************************/
// 	
// 	if (!confirm('Are you sure you want to delete this attendee from the call?\n\nThis will not affect any other calls, past or future.\n')) {
// 		return false;
// 	}
// 	
// 	var closestTD 		= htmlElement.closest('td');
// 	var previousTD 	= closestTD.previousElementSibling;
// 	var inputElem 		= previousTD.querySelector('input');
// 	var attendeeID 	= inputElem.getAttribute('data-val');	
// 	
// 	var requestUrl = 'ajax/customerCalls.asp?cmd=deleteAttendee&attendeeID=' + attendeeID;
// 
// // 	console.log(requestUrl);
// 											
// 	CreateRequest();
//  
// 	if(request) {
// 		request.onreadystatechange = StateChangeHandler_deleteAttendee;
// 		request.open("GET", requestUrl,  true);
// 		request.send(null);		
// 	}
// 
// 	function StateChangeHandler_deleteAttendee() {
// 	
// 		if(request.readyState == 4) {
// 			if(request.status == 200) {
// 				
// 				var rowToDelete = htmlElement.closest('tr');
// 				rowToDelete.parentNode.removeChild(rowToDelete);
// 				Complete_Attendee(request.responseXML);
// 				location = location;				
// 			} else {
// 				alert("problem retrieving data from the server, status code: "  + request.status);
// 			}
// 		}
// 	
// 	}	
// 	
// 	
// }




// /*****************************************************************************************/
// function Attendee_onClick(htmlElement) {
// /*****************************************************************************************/
// 	
// 	var attendeeID = htmlElement.getAttribute("data-val");
// // 	var attendeeID = htmlElement.querySelector('input[type=checkbox]').getAttribute('data-val');	
// 	
// 	
// 	var requestUrl 	= "ajax/customerCalls.asp?cmd=attendee&attendeeID=" + attendeeID;
// 											
// // 	console.log(requestUrl);
// 											
// 	CreateRequest();
//  
// 	if(request) {
// 		request.onreadystatechange = StateChangeHandler_Attendee;
// 		request.open("GET", requestUrl,  true);
// 		request.send(null);		
// 	}
// 
// 	function StateChangeHandler_Attendee() {
// 	
// 		if(request.readyState == 4) {
// 			if(request.status == 200) {
// 				Complete_Attendee(request.responseXML);
// 			} else {
// 				alert("problem retrieving data from the server, status code: "  + request.status);
// 			}
// 		}
// 	
// 	}	
// 	
// }


/*****************************************************************************************/
function Complete_Attendee(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	


}



/*****************************************************************************************/
function SaveQuill_onClick( quillID, htmlElement) {
/*****************************************************************************************/
		
// 	console.log(quillID.root.innerHTML);
// 	var strNarrative = quillID.root.innerHTML;

	var quillContent 			= quillID.getContents();
	var quillContentString 	= JSON.stringify(quillContent);
	var callID 					= htmlElement.getAttribute("callID");
	var callNoteTypeID 		= htmlElement.getAttribute("callNoteTypeID");
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=saveQuill"
											+ "&callID=" + callID 
											+ "&callNoteTypeID=" + callNoteTypeID
											+ "&callNoteNarrative=" + encodeURIComponent(quillContentString);

// 	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_CallNarrative;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_CallNarrative() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_CallNarrative(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}	
	
}


/*****************************************************************************************/
function Complete_CallNarrative(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);

	var quillID 				= GetInnerText(xml.getElementsByTagName('quillID')[0]);
	var rawQuillID 			= GetInnerText(xml.getElementsByTagName('rawQuillID')[0]);
	var callNoteNarrative 	= GetInnerText(xml.getElementsByTagName('callNoteNarrative')[0]);
	
	eval(quillID).setContents(JSON.parse(callNoteNarrative));
	eval(rawQuillID).setContents(JSON.parse(callNoteNarrative));
	
		
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	


}



/*****************************************************************************************/
function CustomerCallNotesUpdate_onBlur(htmlElement) {
/*****************************************************************************************/

	var e = htmlElement 
	var customerID = e.getAttribute("data-val").value;
	var noteTypeID = e.id;
	var narrative = e.value;
	
	
		
	var requestUrl 	= "ajax/customerCalls.asp?customerID=" + customerID
											+ "&noteTypeID=" + noteTypeID
											+ "&narrative=" + narrative;
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_drawChart2;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_CustomerCallNotesUpdate() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_CustomerCallNotesUpdate(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
}


/*****************************************************************************************/
function Complete_CustomerCallNotesUpdate(json) {
/*****************************************************************************************/

	var data = new google.visualization.DataTable(json);

	var options = {
		height: '100%',
		page: 'enable',
		pageSize: 20,
		width: '100%',
	};

	var chart = new google.visualization.Table(document.getElementById('valuesTable'));
	chart.draw(data, options);

}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}



