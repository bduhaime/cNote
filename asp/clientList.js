//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

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
function ToggleActions(htmlElement) {
/*****************************************************************************************/
	
	var currActionButtons = htmlElement.querySelector("[id^='actions']");
	
	if (currActionButtons.style.visibility == "hidden") {
		currActionButtons.style.visibility = "visible";
	} else {
		currActionButtons.style.visibility = "hidden";
	}
	

}


/*****************************************************************************************/
function EditClient_onClick(htmlElement) {
/*****************************************************************************************/


	document.getElementById("formTitle").innerHTML 			= "Edit Client";
	
// get values from HTML table...
	
	var ID = htmlElement.getAttribute('data-val');
	
	var currTableRow 				= htmlElement.parentNode.parentNode.parentNode;	
	
	
	var name							= currTableRow.children[0].innerText;
	var clientID					= currTableRow.children[1].innerText;
	var dbName						= currTableRow.children[2].innerText;
	var startDate					= currTableRow.children[3].innerText;
	var endDate						= currTableRow.children[4].innerText;
	var validDomainsIcon			= currTableRow.children[5].children[0];

	if (validDomainsIcon) {
		var validDomains			= validDomainsIcon.getAttribute('title');
	}




	
	var startDateValue, endDateValue;
	
// populate dialog's fields...

	document.getElementById('id').value = ID;

	document.getElementById('client_name').value = name;
	document.getElementById('client_name').parentElement.classList.add('is-dirty');

	document.getElementById('client_clientID').value = clientID;
	document.getElementById('client_clientID').parentElement.classList.add('is-dirty');

	if (startDate) {
		if (moment(startDate).isValid()) {
			startDateValue = moment(startDate).format('YYYY-MM-DD');
		} else {
			startDateValue = '';
		}
	} else {
		startDateValue = '';
	}
	
	document.getElementById('client_startDate').value = startDateValue;
	document.getElementById('client_startDate').parentElement.classList.add('is-dirty');

	if (endDate) {
		if (moment(endDate).isValid()) {
			endDateValue = moment(endDate).format('YYYY-MM-DD');
		} else {
			endDateValue = '';
		}
	} else {
		endDateValue = '';
	}
	
	document.getElementById('client_endDate').value = endDateValue;
	document.getElementById('client_endDate').parentNode.classList.add('is-dirty');

	document.getElementById('client_databaseName').value = dbName;
	document.getElementById('client_databaseName').parentNode.classList.add('is-dirty');
	
	if (validDomainsIcon) {
		document.getElementById('client_validDomains').value = validDomains;
		document.getElementById('client_validDomains').parentNode.classList.add('is-dirty');
		document.getElementById('client_validDomains').parentNode.style.display = 'block';
	} else {
		document.getElementById('client_validDomains').parentNode.style.display = 'none';
	}

	dialog_addClient.showModal();

		

}


/*****************************************************************************************/
function ClientAdd_onClick () {
/*****************************************************************************************/
	
	document.getElementById("formTitle").innerHTML 			= "New Client";
	
	
	document.getElementById('id').value = null;

	
	document.getElementById("client_name").value 			= null;	


	document.getElementById('client_startDate').value		= null;
	document.getElementById('client_startDate').parentNode.classList.add('is-dirty');

	document.getElementById('client_endDate').value			= null;
	document.getElementById('client_endDate').parentNode.classList.add('is-dirty');


	document.getElementById("client_clientID").value 		= null;
	document.getElementById("client_clientID").parentNode.classList.remove('is-dirty');

	document.getElementById('client_databaseName').value	= null;
	document.getElementById("client_databaseName").parentNode.classList.remove('is-dirty');
	
// 	document.getElementById('client_validDomains').value 	= null;
// 	document.getElementById("client_validDomains").parentNode.classList.remove('is-dirty');
	
	dialog_addClient.showModal();
	
}



/*****************************************************************************************/
function AddClient_onSave () {
/*****************************************************************************************/

	var id							= document.getElementById('id').value;
	var name							= document.getElementById('client_name').value;
	var startDate					= document.getElementById('client_startDate').value;
	var endDate						= document.getElementById('client_endDate').value;
	var clientID					= document.getElementById('client_clientID').value;
	var dbName						= document.getElementById('client_databaseName').value;
	var validDomains				= document.getElementById('client_validDomains').value;
	

	if (startDate) {
		if (!moment(startDate).isValid()) {
			alert('Start date is not a valid date');
			document.getElementById('client_startDate').parentNode.classList.add('is-invalid');
			document.getElementById('client_startDate').focus();
			return false;
		} else {
			document.getElementById('client_startDate').parentNode.classList.remove('is-invalid');
		}
	}
	
	if (endDate) {
		if (!moment(endDate).isValid()) {
			alert('End date is not a valid date');
			document.getElementById('client_endDate').parentNode.classList.add('is-invalid');
			document.getElementById('client_endDate').focus();
			return false;
		} else {
			document.getElementById('client_endDate').parentNode.classList.remove('is-invalid');
		}
	}
	
	if (startDate && endDate) {
		if (!moment(startDate).isSameOrBefore(moment(endDate))) {
			alert('Start date must preceed end date');
			document.getElementById('client_startDate').parentNode.classList.add('is-invalid');
			document.getElementById('client_endDate').parentNode.classList.add('is-invalid');
			document.getElementById('client_startDate').focus();
			return false;
		} else {
			document.getElementById('client_startDate').parentNode.classList.remove('is-invalid');
			document.getElementById('client_endDate').parentNode.classList.remove('is-invalid');
		}
	}
		
	
	var requestUrl 	= "ajax/clientMaintenance.asp?cmd=update"
											+ "&id=" + id
											+ "&name=" + encodeURIComponent(name)
											+ "&startDate=" + encodeURIComponent(startDate)
											+ "&endDate=" + encodeURIComponent(endDate)
											+ "&clientID=" + encodeURIComponent(clientID)
											+ "&dbName=" + encodeURIComponent(dbName)
											+ "&validDomains=" + encodeURIComponent(validDomains);
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateClient;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_updateClient() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {
				location = location
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}



/*****************************************************************************************/
function ClientDelete_onClick(htmlElement) {
/*****************************************************************************************/
	
	
	if (confirm("Are you sure you want to delete this client?\n\nThis action cannot be undone.")) {

		var ID = htmlElement.getAttribute('data-val');
	
		var requestUrl 	= "ajax/clientMaintenance.asp?cmd=delete"
												+ "&id=" + ID;
												
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_deleteClient;
			request.open("GET", requestUrl, true);
			request.send(null);		
		}
	
		function StateChangeHandler_deleteClient() {
		
			if(request.readyState == 4) {
				if(request.status == 200 || request.status == 0) {
					location = location
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
	
	}
	
	
}



