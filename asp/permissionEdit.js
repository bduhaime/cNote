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
function EditAttribute(attributeNode,permissionID) {
/*****************************************************************************************/

	var attributeName 	= attributeNode.id;
	var attributeValue;
	
	if (attributeName == 'deleted' || attributeName == 'csuiteOnly' || attributeName == 'customerUserAllowed' || attributeName == 'nonCsuiteOnly') {
		if (attributeNode.parentNode.classList.contains('is-checked')) {
			attributeValue = 'on';
		} else {
			attributeValue = 'off';
		}
	} else {
		attributeValue	= attributeNode.value;
	}
	
	
	var requestUrl 	= "ajax/permissionMaintenance.asp?cmd=update"
													+ "&id=" + permissionID 
													+ "&attribute=" + encodeURIComponent(attributeName)
													+ "&value=" + encodeURIComponent(attributeValue);
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_permissionAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}



/*****************************************************************************************/
function UserPermission_onClick(user,permission) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=permission&user=" + user + "&permission=" + permission;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_userPermission;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_userPermission() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				permissionAttribute_status(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}




/*****************************************************************************************/
function RolePermission_onClick(role,permission) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=rolePermission&role=" + role + "&permission=" + permission;

	console.log(requestUrl);

	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_permissionAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}







/*****************************************************************************************/
//
// used for all attributes related to the "permissions" table; toasts the user
//
/*****************************************************************************************/
function StateChangeHandler_permissionAttribute() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			permissionAttribute_status(request.responseXML);
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
function permissionAttribute_status(xml) {
/*****************************************************************************************/

	var msg 			= xml.getElementsByTagName('msg')[0].textContent
	var attribute 	= xml.getElementsByTagName('attribute')[0].textContent
	var value 		= xml.getElementsByTagName('value')[0].textContent
	
	if (attribute == 'csuiteOnly') {
		if (value == '1') {
			document.getElementById('nonCsuiteOnly').parentNode.MaterialSwitch.off();
		}
		
	} else if (attribute == 'nonCsuiteOnly') {
		if (value == '1') {
			document.getElementById('csuiteOnly').parentNode.MaterialSwitch.off();
		}
	}
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	if(status == "error") {
// 		document.getElementById('firstName').focus();
// 		document.getElementById('username').focus();
// 	}

}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}
