//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

/*****************************************************************************************/
function createRequest() {
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
function RoleAttribute_onChange(htmlElement) {
/*****************************************************************************************/

	var roleID				= document.getElementById('roleID').value;
	
	var attributeName 	= htmlElement.id;
	var attributeValue

	if (attributeName == "deleted") {
		
		if (htmlElement.checked) {
			attributeValue = '1';
		} else {
			attributeValue = '0';
		}

	} else {
		
		attributeValue = htmlElement.value;
	
	}		
		
	
	var requestUrl 	= 'ajax/adminMaintenance.asp?cmd=updateRole'
													+ '&roleID=' + roleID 
													+ '&attribute=' + attributeName 
													+ '&value=' + encodeURIComponent(attributeValue);
																	
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = Generic_StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}





/*****************************************************************************************/
function Generic_StateChangeHandler() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			Generic_toaster(request.responseXML);
		} else {
			alert("problem retrieving data from the server, status code: "  + request.status);
		}
	}

}



/*****************************************************************************************/
//
// this produces an MDL "toast" component (i.e. there is no action)
//
/*****************************************************************************************/
function Generic_toaster(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar({
		message: msg
	});
	
}

