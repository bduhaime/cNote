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


/*****************************************************************************************/
function EditImplementation_onClick(htmlElement) {
/*****************************************************************************************/
	
		var selectedRow = htmlElement.closest('tr');
		
		var startDate		= selectedRow.querySelector('.startDate').textContent;
		var name				= selectedRow.querySelector('.name').textContent;
		var endDate			= selectedRow.querySelector('.endDate').textContent;
		var implementID	= selectedRow.id;

		dialog_addImplementation.showModal();				

		document.getElementById('add_implStartDate').value = moment(startDate).format('YYYY-MM-DD');
		document.getElementById('add_implStartDate').parentNode.classList.add('is-dirty');
		document.getElementById('add_implStartDate').parentNode.classList.remove('is-invalid');
		
		document.getElementById('add_implName').value = name;
		document.getElementById('add_implName').parentNode.classList.add('is-dirty');
		document.getElementById('add_implName').parentNode.classList.remove('is-invalid');
		
		document.getElementById('add_implEndDate').value = moment(endDate).format('YYYY-MM-DD');
		document.getElementById('add_implEndDate').parentNode.classList.add('is-dirty');
		document.getElementById('add_implEndDate').parentNode.classList.remove('is-invalid');
		
		document.getElementById('add_implementationID').value = implementID;

		event.stopPropagation();
		
}


/*****************************************************************************************/
function deleteImplementation_onClick(htmlElement) {
/*****************************************************************************************/

	event.stopPropagation();

	if (confirm("This action will delete this Intention AND all associated Utopias and Opportunities?\n\nThis can only be undone by a DBA.\n\nAre you sure you want to proceed?")) {
		
		var selectedRow 	= htmlElement.parentNode.parentNode.parentNode;
		var implementID	= htmlElement.getAttribute('data-val');
			
		var requestUrl 	= "ajax/customerImplementations.asp?cmd=deleteImplementation"
												+ "&id=" + implementID;
												
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_deleteImplementation;
			request.open("GET", requestUrl, true);
			request.send(null);		
		}
		
	} else {
		
		return false;
		
	}

	function StateChangeHandler_deleteImplementation() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				location = location;

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
	
}


		
/*****************************************************************************************/
function EditCustomerImplementation_onSave(htmlDialog) {
/*****************************************************************************************/

	var implementationID 		= document.getElementById('add_implementationID').value;
	var startDate 	 				= document.getElementById('add_implStartDate').value;
	var add_implName 	 			= document.getElementById('add_implName').value;
	var endDate 	 				= document.getElementById('add_implEndDate').value;
	var customerID					= document.getElementById('add_implCustomerID').value;


	if (startDate) {
		if (! moment(startDate).isValid()) {
			alert('Implementation start date is not a valid date');
			return false;
		}
	} else {
		alert('Implementation start date is required');
		return false;
	}

	if (endDate) {
		if (! moment(endDate).isValid()) {
			alert('Implementation end date is not a valid date');
			return false;
		}
	} else {
		alert('Implementation end date is required');
		return false;
	}
	
	if (!moment(startDate).isBefore(moment(endDate))) {
		alert("Implemention start date must preceed endDate");
		return false;
	}
	
	if (!add_implName) {
		alert("Implementation name is required");
		return false;
	}


		
	var payload = "implementationID="	+ implementationID
					+ "&startDate="			+ startDate 
					+ "&name="					+ encodeURIComponent(add_implName)
					+ "&endDate=" 				+ endDate
					+ "&customerID="			+ customerID;
		
	console.log(payload);
		
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_AddImplementation;
		request.open("POST", "ajax/customerImplementations.asp?cmd=updateImplementation", true);
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
		request.send(payload);
	}

	function StateChangeHandler_AddImplementation() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				location = location;
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}



/*****************************************************************************************/
function UpdateImplEndDate_onBlur(htmlElement) {
/*****************************************************************************************/

	var startDate = htmlElement.value;
	var endDate = document.getElementById('add_implEndDate');
	
	if (moment(startDate).isValid()) {
		
		endDate.setAttribute('min',moment(startDate).format('YYYY-MM-DD'));
		endDate.value = moment(startDate).add(3, 'years').format('YYYY-MM-DD');
		
	}
	


}



/*****************************************************************************************/
function UpdateImplStartDate_onBlur(htmlElement) {
/*****************************************************************************************/

	var endDate = htmlElement.value;
	var startDate = document.getElementById('add_implStartDate');
	
	if (moment(endDate).isValid()) {
		
		startDate.setAttribute('max',moment(endDate).format('YYYY-MM-DD'));
		
	}
	


}




/*****************************************************************************************/
function ToggleImplActionIcons(implementationID) {
/*****************************************************************************************/

	var implementationIcons = document.getElementById('implementationIcons-'+implementationID);
	
	if (implementationIcons.style.visibility == 'hidden') {
		implementationIcons.style.visibility 	= 'visible';
	} else {
		implementationIcons.style.visibility 	= 'hidden';
	}
	
	
}


