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
function EditCustomerStatus_onClick(htmlElement) {
/*****************************************************************************************/
	
	var eventID = htmlElement.getAttribute('data-val');
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;
	
	var eventName = currTableRow.children[0].innerHTML;
	var eventDescription = currTableRow.children[1].innerHTML;
	
	document.getElementById('eventName').value = eventName;
	document.getElementById('eventName').parentElement.classList.add('is-dirty');

	document.getElementById('eventDescription').value = eventDescription;
	document.getElementById('eventDescription').parentElement.classList.add('is-dirty');
	
	document.getElementById('eventID').value = eventID;

	dialog_event.showModal();
		
}


/*****************************************************************************************/
function addEvent(dialog) {
/*****************************************************************************************/

	var eventID				= document.getElementById('eventID').value;
	var eventName 			= document.getElementById('eventName').value;
	var eventDescription	= document.getElementById('eventDescription').value;
	
	
	var requestUrl 	= "ajax/events.asp?cmd=maintain"
											+ "&eventID=" + eventID
											+ "&eventName=" + encodeURIComponent(eventName)
											+ "&eventDescription=" + encodeURIComponent(eventDescription);
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addEvent;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_addEvent() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {
				location = window.location.href.split('?')[0]
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
// 	location = location;
	
}


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}



