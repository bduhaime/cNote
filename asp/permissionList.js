//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

function CreateRequest() {

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
	
	if (currActionButtons) {
		if (currActionButtons.style.visibility == "hidden") {
			currActionButtons.style.visibility = "visible";
		} else {
			currActionButtons.style.visibility = "hidden";
		}
	}

}


/*****************************************************************************************/
function GoToPermission(htmlElement) {
/*****************************************************************************************/

	var permID = htmlElement.id;
	
	window.location.href='permissionEdit.asp?id=' + permID;

	
}


/*****************************************************************************************/
function PermDelete_onClick(htmlElement) {
/*****************************************************************************************/
	
	var currentIcon = htmlElement.textContent;
	var command;
	var proceed;
	
	if (currentIcon == 'delete_forever') {
		if (confirm("Are you sure you want to permanently delete this item?\n\nThis action cannot be undone.")) {
			command = 'physicalDelete';
			proceed = true;
		} else {
			proceed = false;
			return false;
		}
	} else if (currentIcon == 'delete_outline') {
		if(confirm("Are you sure you want to delete this item?\n\nThis can only be undone by a system administrator.")) {
			command = 'logicalDelete';
			proceed = true;
		} else {
			proceed = false;
			return false;
		}
	} else {
		console.log('Unexpected value found in deleteIcon: ' + currentIcon);
		alert("Unexpected condition encountered. No action taken.");
		proceed = false;
		return false;
	}
	
	if (proceed) {
		
		var permissionID = htmlElement.getAttribute('data-val');

		var requestUrl = 'ajax/permissionMaintenance.asp?cmd=' + command 
												+ '&permissionID=' + permissionID;
												
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_permDelete;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
		
		function StateChangeHandler_permDelete() {
			
			if(request.readyState == 4) {
				if(request.status == 200) {
					Generic_Status(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
			
		}

	}		
	
}



/*****************************************************************************************/
function Generic_Status(xml) {
/*****************************************************************************************/

	var msg = xml.getElementsByTagName('msg')[0].textContent;
	var notification = document.querySelector('.mdl-js-snackbar');

	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	)

	location = location;
	
}



