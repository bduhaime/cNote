//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

var request = null;


/*******************************************************************************/
function CreateRequest() {
/*******************************************************************************/

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
/*******************************************************************************/



/*******************************************************************************/
function CallStartTime_onChange(callStartTimeElement) {
/*******************************************************************************/
	
	var timeIncrement = 15;

	var startTime = moment(callStartTimeElement.options[callStartTimeElement.selectedIndex].value);
	
	// endTime starts out 30 minutes after the initial startTime....
	var endTime = moment(startTime).add(timeIncrement,'minutes');

	// populate the endTime <select> with <option>'s for each 30-minute increment until end-of-day....
	var add_callEndTime = document.getElementById('add_callEndTime');
	add_callEndTime.options.length = 0;
	var maxEndTime = moment().add(1,'days').startOf('day');
	while (endTime < maxEndTime) {
		var opt = document.createElement('option');
		opt.value = endTime.format('YYYY-MM-DDTHH:mm:ss');
		opt.innerHTML = endTime.format('h:mm A');
// 		console.log(opt.innerHTML);	
		endTime.add(timeIncrement,'minutes');
		add_callEndTime.appendChild(opt);
	}
	add_callEndTime.parentNode.classList.add('is-dirty');

	
	
}
/*******************************************************************************/



/*******************************************************************************/
function UpdateCallDate_onBlur(callDateElement) {
/*******************************************************************************/
	
	var timeIncrement = 15;
	var callDate = moment(callDateElement.value);

	if (!callDate.isValid()) {
		alert('Call date is not a valid date');
		return false;
	}


	// startTime is first 30-minute increment after current time, or 12:00 AM of later dates.....
	var startTime;
	if (callDate.isSame(moment(),'day')) {

		startTime = moment().startOf('hour').add(30,'minutes');
		if (startTime.isBefore(moment())) {
			startTime.add(timeIncrement,'minutes');
		}

	} else {
		
		startTime = moment().startOf('day');
		
	}
	
	// endTime starts out 30 minutes after the initial startTime....
	var endTime = moment(startTime).add(30,'minutes');


	// populate the startTime <select> with <options>'s for each 30-minute increment until end-of-day...
	var add_callStartTime = document.getElementById('add_callStartTime');
	add_callStartTime.options.length = 0;
	var maxStartTime = moment().endOf('day');
	while (startTime.isBefore(maxStartTime)) {
		var opt = document.createElement('option');
		opt.value = startTime.format('YYYY-MM-DDTHH:mm:ss');
		opt.innerHTML = startTime.format('h:mm A');
// 		console.log(opt.innerHTML);	
		startTime.add(timeIncrement,'minutes');
		add_callStartTime.appendChild(opt);
	}
	add_callStartTime.parentNode.classList.add('is-dirty');


	// populate the endTime <select> with <option>'s for each 30-minute increment until end-of-day....
	var add_callEndTime = document.getElementById('add_callEndTime');
	add_callEndTime.options.length = 0;
	var maxEndTime = moment().add(1,'days').startOf('day');
	while (endTime < maxEndTime) {
		var opt = document.createElement('option');
		opt.value = endTime.format('YYYY-MM-DDTHH:mm:ss');
		opt.innerHTML = endTime.format('h:mm A');
// 		console.log(opt.innerHTML);	
		endTime.add(timeIncrement,'minutes');
		add_callEndTime.appendChild(opt);
	}
	add_callEndTime.parentNode.classList.add('is-dirty');


	
}
/*******************************************************************************/



/*******************************************************************************/
function callType_onChange(htmlElement) {
/*******************************************************************************/

// 	alert('callType changed');

	var callTypeID = htmlElement.value;
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=getNoteTypes&callTypeID=" + callTypeID;

	console.log(requestUrl);
					
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_getNoteTypes;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


	function StateChangeHandler_getNoteTypes() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				UpdateDialogWithNoteTypeIndicators(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}
/*******************************************************************************/



/*******************************************************************************/
function UpdateDialogWithNoteTypeIndicators(xml) {
/*******************************************************************************/
	
	var utopiaInd 			= xml.getElementsByTagName('utopiaInd')[0].innerHTML;
	var projectInd 		= xml.getElementsByTagName('projectInd')[0].innerHTML;
	var keyInitiativeInd = xml.getElementsByTagName('keyInitiativeInd')[0].innerHTML;
	var showDetails = false;
	
	if (utopiaInd) {
		var copyUtopiasControl = document.getElementById('copyUtopias');
		if (utopiaInd == 'true') {
			copyUtopiasControl.parentNode.style.display = 'block';
			copyUtopiasControl.parentNode.classList.remove('is-disabled');
			copyUtopiasControl.parentNode.MaterialSwitch.on();
		} else {
			copyUtopiasControl.parentNode.style.display = 'none';
			copyUtopiasControl.parentNode.classList.add('is-disabled');
			copyUtopiasControl.parentNode.MaterialSwitch.off();
		}
		showDetails = true;
	}
	
	if (keyInitiativeInd) {
		var copyKIsControl = document.getElementById('copyKeyInitiatives');
		if (keyInitiativeInd == 'true') {
			copyKIsControl.parentNode.style.display = 'block';
			copyKIsControl.parentNode.classList.remove('is-disabled');
			copyKIsControl.parentNode.MaterialSwitch.on();
		} else {
			copyKIsControl.parentNode.style.display = 'none';
			copyKIsControl.parentNode.classList.add('is-disabled');
			copyKIsControl.parentNode.MaterialSwitch.off();
		}
		showDetails = true;
	}
	
	if (projectInd) {
		var copyProjectsControl = document.getElementById('copyProjects');
		if (projectInd == 'true') {
			copyProjectsControl.parentNode.style.display = 'block';
			copyProjectsControl.parentNode.classList.remove('is-disabled');
			copyProjectsControl.parentNode.MaterialSwitch.on();
		} else {
			copyProjectsControl.parentNode.style.display = 'none';
			copyProjectsControl.parentNode.classList.add('is-disabled');
			copyProjectsControl.parentNode.MaterialSwitch.off();
		}
		showDetails = true;
	}
	
	var hiddenItems = document.querySelectorAll('.is-hidden')
	if (hiddenItems) {
		
		for (i = 0; i < hiddenItems.length; ++i) {
			
			if (showDetails) {
				hiddenItems[i].classList.remove('is-hidden');
				hiddenItems[i].classList.add('is-shown');
				document.querySelector('button.save').disabled = false;
			} else {
				hiddenItems[i].classList.add('is-hidden');
				hiddenItems[i].classList.remove('is-shown');
				document.querySelector('button.save').disabled = true;
			}
			
		}
		
		
	}
	

	if (showDetails) {
	}

}
/*******************************************************************************/
