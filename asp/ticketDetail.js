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
function TicketAttribute_onChange(htmlNode,id) {
/*****************************************************************************************/

	var attributeToUpdate = htmlNode.id;
	var attributeValue = encodeURIComponent(htmlNode.value);
		
	var requestUrl 	= "ajax/ticketMaintenance.asp?cmd=mod&id=" + id + "&attribute=" + attributeToUpdate + "&value=" + attributeValue;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_modTicket;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_modTicket() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_modTicket(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_modTicket(urNode) {
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
function DeleteSupportNote_onClick(htmlNode,note) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/ticketMaintenance.asp?cmd=deleteNote&id=" + note;
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

