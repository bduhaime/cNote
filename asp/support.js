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
function AddTicket_onSave(dialog) {
/*****************************************************************************************/

	var ticketSeverity;
	var ticketTitle				= encodeURIComponent(document.getElementById('add_ticketTitle').value);
	var ticketReportedBy			= encodeURIComponent(document.getElementById('add_reportedBy').value);
	var ticketNarrative			= encodeURIComponent(document.getElementById('add_narrative').value);
	
	if (document.getElementById('add_severityCritical').checked) {
		ticketSeverity = 4;
	} else if (document.getElementById('add_severityHigh').checked) {
		ticketSeverity = 3;
	} else if (document.getElementById('add_severityLow').checked) {
		ticketSeverity = 1;
	} else {
		ticketSeverity = 2;  /* normal severity */
	}
	
	var requestUrl 	= "ajax/ticketMaintenance.asp?cmd=add&title=" + ticketTitle + "&severity=" + ticketSeverity + "&reportedBy=" + ticketReportedBy + "&narrative=" + ticketNarrative
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addTicket;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addTicket() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_addTicket(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_addTicket(urNode) {
/*****************************************************************************************/

	document.getElementById('add_ticketTitle').value = "";
	document.getElementById('add_reportedBy').value = "";
	document.getElementById('add_narrative').value = "";
	
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
function DeleteTicket_onClick(ticket) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/ticketMaintenance.asp?cmd=delete&id=" + ticket;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_deleteTicket;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_deleteTicket() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_deleteTicket(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_deleteTicket(urNode) {
/*****************************************************************************************/
	
	var msg 					= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	location = location;

}


/*****************************************************************************************/
function TicketDetail_onClick(ticket) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/ticketMaintenance.asp?cmd=query&id=" + ticket;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateStatus;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_updateStatus() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_updateDetails(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}

/*****************************************************************************************/
function Complete_updateDetails(urNode) {
/*****************************************************************************************/

	document.getElementById('ticketID').innerHTML 			= GetInnerText(urNode.getElementsByTagName('id')[0]);
	document.getElementById('ticketTitle').innerHTML 		= GetInnerText(urNode.getElementsByTagName('title')[0]);
	document.getElementById('ticketPriority').innerHTML 	= GetInnerText(urNode.getElementsByTagName('priorityName')[0]);
	document.getElementById('ticketCategory').innerHTML 	= GetInnerText(urNode.getElementsByTagName('categoryName')[0]);
	document.getElementById('ticketSeverity').innerHTML 	= GetInnerText(urNode.getElementsByTagName('severityName')[0]);
	document.getElementById('ticketAssignedTo').innerHTML = GetInnerText(urNode.getElementsByTagName('assignedTo')[0]);
	document.getElementById('ticketStatus').innerHTML 		= GetInnerText(urNode.getElementsByTagName('statusName')[0]);
	document.getElementById('ticketReportedBy').innerHTML = GetInnerText(urNode.getElementsByTagName('reportedBy')[0]);
	document.getElementById('ticketNarrative').innerHTML 	= GetInnerText(urNode.getElementsByTagName('narrative')[0]);
	document.getElementById('ticketOpenedDate').innerHTML	= GetInnerText(urNode.getElementsByTagName('openedDate')[0]);
	document.getElementById('ticketClosedDate').innerHTML = GetInnerText(urNode.getElementsByTagName('closedDate')[0]);
		
}


/*****************************************************************************************/
function FileUpload_onClick() {
/*****************************************************************************************/

	var uploadButton = document.getElementById('uploadButton');
	var fileSelect = document.getElementById('fileUpload');
	
	uploadButton.innerHTML = 'Uploading...';
	
	var files = fileSelect.files;
	var formData = new FormData();
	
	// Loop through each of the selected files.
	for (var i = 0; i < files.length; i++) {
		var file = files[i];
		formData.append('uploads[]', file, file.name);
	}	

	xhr = new XMLHttpRequest();
	xhr.open('POST', 'fileUploader.asp', true);
	
	xhr.onload = function () {
		if (xhr.status === 200) {
			// File(s) uploaded.
			uploadButton.innerHTML = 'Upload';
		} else {
			alert('An error occurred!');
		}
	};
	
	xhr.send(formData)



}

/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}

