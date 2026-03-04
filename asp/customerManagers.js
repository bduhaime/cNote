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
function MgrStartDate_onChange(startDateElem) {
/*****************************************************************************************/

	var startDate 		= startDateElem.value;
	var endDateElem 	= document.getElementById('mgrEndDate');
	var endDate 		= endDateElem.value;

	if ( moment(startDate).isValid() ) {
		
		endDateElem.setAttribute( 'min', moment(startDate).format('YYYY-MM-DD') );

		if ( moment( endDate ).isValid() ) {
			
			if ( moment( startDate ).isSameOrBefore( moment( endDate ) ) ) {
				
				startDateElem.parentNode.classList.remove( 'is-invalid' );
				
			} else {

				alert( 'Start date must preceed the end date.' );
				startDateElem.parentNode.classList.add( 'is-invalid' );
				return false;
				
			}
			
		} else {
			
			if ( moment( startDate ).isSameOrBefore( moment() ) ) {
				
				startDateElem.parentNode.classList.remove( 'is-invalid' );

			} else {
				
				alert( 'Start date must preceed today.' );
				startDateElem.parentNode.classList.add( 'is-invalid' );
				return false;

			}
			
		}
		
	} else {
		
		alert( 'Start date must be a valid date.' );
		endDateElem.setAttribute( 'min', null );
		startDateElem.parentNode.classList.add( 'is-invalid' );
		return false;
		
	}

	
}



/*****************************************************************************************/
function MgrEndDate_onChange(endDateElem) {
/*****************************************************************************************/

	var endDate 		= endDateElem.value;
	var startDateElem	= document.getElementById('mgrStartDate');
	var startDate 		= startDateElem.value;

	if (moment(endDate).isValid()) {
		
		startDateElem.setAttribute('max', moment(endDate).format('YYYY-MM-DD'));

		if (moment(startDate).isValid()) {
			
			if (moment(endDate).isSameOrAfter(moment(startDate))) {
				
				endDateElem.parentNode.classList.remove('is-invalid');
				
			} else {

				alert('End date must follow the start date.');
				endDateElem.parentNode.classList.add('is-invalid');
				return false;
				
			}
			
		}
		
	} else {
		
		if (endDate) {
		
			alert('End date must be a valid date.');
			startDateElem.setAttribute('max', null);
			endDateElem.parentNode.classList.add('is-invalid');
			return false;
		
		}
		
	}

}



/*****************************************************************************************/
function UpdateTimelineEntry() {
/*****************************************************************************************/

	if (confirm('Are you sure you want to update this entry?')) {
		
		var id 				= document.getElementById('customerManagerID').value;
		var customerID		= document.getElementById('customerID').value;

		var userIDSelector 	= document.getElementById('userID');
		var userID				= userIDSelector.options[userIDSelector.selectedIndex].value;
		
		if (!userID) {
			alert("Manager is required");
			userIDSelector.parentNode.classList.add("is-dirty");
			userIDSelector.parentNOde.classList.add("is-invalid");
			return false;
		}
		

		var managerTypeSelector = document.getElementById('managerTypeID');
		var managerTypeID			= managerTypeSelector.options[managerTypeSelector.selectedIndex].value;

		if (!managerTypeID) {
			alert("Manager Type is required");
			managerTypeSelector.parentNode.classList.add('is-dirty');
			managerTypeSelector.parentNode.classList.add('is-invalid');
			return false;
		}
		
		var startDateSelector 	= document.getElementById('mgrStartDate');
		var startDate 				= startDateSelector.value;
		if (startDate) {
			if (!moment(startDate).isValid()) {
				alert("Start date is not a valid date");
				startDateSelector.parentNode.classList.add('is-dirty');
				startDateSelector.parentNode.classList.add('is-invalid');
				return false;
			}
		} else {
			alert("Start date is required");
			startDateSelector.parentNode.classList.add('is-dirty');
			startDateSelector.parentNode.classList.add('is-invalid');
			return false;
			
		}
		
		
		var endDateSelector 	= document.getElementById('mgrEndDate');
		var endDate 			= endDateSelector.value;
		if (endDate) {
			if(!moment(startDate).isValid()) {
				alert("End date is not a valid date");
				endDateSelector.parentNode.classList.add('is-dirty');
				endDateSelector.parentNode.classList.add('is-invalid');
				return false;
			}
// 		} else {
// 			alert("End date is required");
// 			endDateSelector.parentNode.classList.add('is-dirty');
// 			endDateSelector.parentNode.classList.add('is-invalid');
// 			return false;
		}
		
		
		if (moment(startDate).isAfter(moment(endDate))) {
			alert("Start date must preceed end date");
			startDateSelector.parentNode.classList.add('is-dirty');
			startDateSelector.parentNode.classList.add('is-invalid');
			endDateSelector.parentNode.classList.add('is-dirty');
			endDateSelector.parentNode.classList.add('is-invalid');
			return false;
		}
		
		
		var payload = "customerManagerID=" + id
						+ "&customerID=" + customerID
						+ "&userID=" + userID
						+ "&managerTypeID=" + managerTypeID 
						+ "&startDate=" + startDate 
						+ "&endDate=" + endDate;
	
		console.log(payload);
		
		CreateRequest();
	
		if(request) {
			request.onreadystatechange = StateChangeHandler_updateTimelineEntry;
			request.open("POST", "ajax/customerMaintenance.asp?cmd=updateCustomerManager", true);
			request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
			request.send(payload);
		}
	
		function StateChangeHandler_updateTimelineEntry() {
		
			if(request.readyState == 4) {

				if(request.status == 200) {
					Complete_updateTimelinEntry(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
				
			}
		
		}

	}

	
}


/*****************************************************************************************/
function Complete_updateTimelinEntry(urNode) {
/*****************************************************************************************/

	var primaryAllowed 	= GetInnerText(urNode.getElementsByTagName('primaryAllowed')[0]);
	var msg 					= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	if (primaryAllowed == 'n/a' || primaryAllowed == 'true') {

		var notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar(
			{
			message: msg
			}
		);
		
		location = location;
		
	} else {
		
		alert(msg);
		document.getElementById('startDate').parentNode.classList.add("is-invalid");
		document.getElementById('endDate').parentNode.classList.add("is-invalid");
		return false;
		
	}
	
	
}


/*****************************************************************************************/
function DeleteTimelineEntry() {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this entry?')) {
		
		var id = document.getElementById('customerManagerID').value;

		var payload = "customerManagerID=" + id; 
	
		CreateRequest();
	
		if(request) {
			request.onreadystatechange = StateChangeHandler_RemoveKeyInitiativeProject;
			request.open("POST", "ajax/customerMaintenance.asp?cmd=deleteCustomerManager", true);
			request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
			request.send(payload);
		}
	
		function StateChangeHandler_RemoveKeyInitiativeProject() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {

					location = location;

				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	}

	
}


/*****************************************************************************************/
function UpdateCustomerManager_onClick(htmlNode, customerID) {
/*****************************************************************************************/

// 	if (confirm('Are you sure you want to update this item?')) {

	var managerTypeID = htmlNode.getAttribute("mtid");
	var effectiveDate;
	var promptText;
	
	if (managerTypeID) {
		if (htmlNode.checked) {
			promptText = "Enter an effective start date";
		} else {
			promptText = "Enter an effective end date";
		}
	} else {
		promptText = "Enter an effective date"
	}

	effectiveDate = prompt(promptText,moment().format("MM/DD/YYYY"));

	if (moment(effectiveDate).isValid()) {

		var clientManagerID = htmlNode.getAttribute('cmID');
		var managerTypeID = htmlNode.getAttribute('mtID');

		var requestUrl 	= "ajax/customerMaintenance.asp?cmd=updateClientManager"
																+ "&id=" + clientManagerID 
																+ "&managerTypeID=" + managerTypeID 
																+ "&effectiveDate=" + effectiveDate
																+ "&customerID=" + customerID;
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_updatePrimaryClientManager;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_updatePrimaryClientManager() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					Complete_updateCustomerManager(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	} else {
		
		if (effectiveDate) {
			alert("Date entered is invalid, cancelling operation\n\nPlease try again.");
		}
		
		// this is required upon cancel because MDL automatically changes the checkbox state before
		// this function gets called.		
		
		if (htmlNode.checked) {
			htmlNode.parentNode.MaterialCheckbox.uncheck();
		} else {
			htmlNode.parentNode.MaterialCheckbox.check();
		}
		var primaryContactID = document.getElementById('primaryContactID').value;
		if (primaryContactID) {
			document.getElementById(primaryContactID).checked;
		}

		
	}
	
}



/*****************************************************************************************/
function Complete_updateCustomerManager(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	location = location;
	
}



/*****************************************************************************************/
function ClientManagerUpdatePrimary_onClick(htmlNode, customerID, currMaxDate) {
/*****************************************************************************************/

	var msg = 'Enter an effective date that is on or after ' + moment(currMaxDate).format('MM/DD/YYYY');

	var effectiveDate = prompt(msg);

	if ( moment(effectiveDate).isValid() && moment(effectiveDate).isSameOrAfter(moment(currMaxDate)) ) {
	
		var clientManagerID = htmlNode.getAttribute("data-val");
		
		var requestUrl 	= "ajax/customerMaintenance.asp?cmd=updatePrimaryClientManager"
																+ "&id=" + clientManagerID 
																+ "&effectiveDate=" + effectiveDate
																+ "&customerID=" + customerID;
		
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_updatePrimaryClientManager;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_updatePrimaryClientManager() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					Complete_updatePrimaryClientManager(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	} else {
		
		if (effectiveDate) {
			alert("Date entered is invalid, cancelling operation\n\nPlease try again.");
		}
		
		var primaryRadioButtons = document.getElementsByName('primary');
		for (var i = 0; i < primaryRadioButtons.length; i++) {
			primaryRadioButtons[i].parentElement.MaterialRadio.uncheck();
		}

		var primaryContactID = document.getElementById('primaryContactID').value;
		document.getElementById(primaryContactID).parentElement.MaterialRadio.check();

	}
	
}


/*****************************************************************************************/
function Complete_updatePrimaryClientManager(urNode) {
/*****************************************************************************************/

	var primaryContactID = document.getElementById('primaryContactID');
	var id = GetInnerText(urNode.getElementsByTagName('newPrimaryManager')[0]);

	primaryContactID.value = 'primary-' + id;


	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	location = location;
	
}





/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}


