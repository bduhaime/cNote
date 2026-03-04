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
function UpdateDefaultClient(radioButtonElem) {
/*****************************************************************************************/
	
	
	var userID = radioButtonElem.getAttribute('data-userID');
	var clientID = radioButtonElem.getAttribute('data-clientID');
	
	
	var requestUrl;
	
	requestUrl = 'ajax/userMaintenance.asp?cmd=updateDefaultClient'
													+ '&userID=' 	+ userID
													+ '&clientID=' 	+ clientID;
													 
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdateDefaultClient;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
	
	function StateChangeHandler_UpdateDefaultClient() {
		
		if(request.readyState == 4) {
			if(request.status == 200) {

				var notification = document.querySelector('.mdl-js-snackbar');
				var msg = request.responseXML.getElementsByTagName('msg')[0].textContent;
				 
				notification.MaterialSnackbar.showSnackbar({
					message: msg
				});

			} else {
				
				alert("problem retrieving data from the server, status code: "  + request.status);
				
			}
		}
		
	}
	
	
}



/*****************************************************************************************/
function UpdateParentCheckbox(parentCheckbox) {
/*****************************************************************************************/

	var childClass 				= parentCheckbox.getAttribute('data-childClass');
	var childCheckboxes 			= document.querySelectorAll('.' + childClass);
	var childCheckboxesCount 	= childCheckboxes.length;
	var childCheckboxesChecked = 0;	
	var i;
	
	for (i = 0; i < childCheckboxes.length; ++i) {
		if (childCheckboxes[i].checked) {
			childCheckboxesChecked++;
		}
	};
	
	if (childCheckboxesChecked >= childCheckboxesCount) {
		
		if (parentCheckbox.parentNode.classList.contains('is-upgraded')) {
			parentCheckbox.parentNode.MaterialCheckbox.check();
		} else {
			parentCheckbox.checked = true;
		}
		
	} else {
		
		if (parentCheckbox.parentNode.classList.contains('is-upgraded')) {
			parentCheckbox.parentNode.MaterialCheckbox.uncheck();
		} else {
			parentCheckbox.checked = false;
		}
		
	}


}




/*****************************************************************************************/
function ToggleParentCheckbox(childCheckbox) {
/*****************************************************************************************/

	var parentCheckboxID			= childCheckbox.getAttribute('data-parentID');
	var parentCheckbox 			= document.getElementById(parentCheckboxID);
	
	UpdateParentCheckbox(parentCheckbox);
	
}
	
	
	
/*****************************************************************************************/
function ToggleChildCheckboxes(parentCheckbox) {
/*****************************************************************************************/
	
	var childClass = parentCheckbox.getAttribute('data-childClass');
	
	var childCheckboxes = document.querySelectorAll('.' + childClass);
	if (childCheckboxes) {
		for (i = 0; i < childCheckboxes.length; ++i) {
			
			if (parentCheckbox.checked) {
				childCheckboxes[i].parentNode.MaterialCheckbox.check();
			} else {
				childCheckboxes[i].parentNode.MaterialCheckbox.uncheck();
			}

		};
		
	}

}	
	
	


/*****************************************************************************************/
function SelectCustomer_onClick(htmlElement,userID) {
/*****************************************************************************************/
	
	var customerID = htmlElement.getAttribute('data-id');
	var requestUrl;
	
	requestUrl = 'ajax/userMaintenance.asp?cmd=customerUser'
														+ '&userID=' + userID
														+ '&customerID=' + customerID;
											
	console.log(requestUrl);
	
	createRequest();
 
	if (request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
		
}



/*****************************************************************************************/
function ToggleInternalUser_onClick(htmlElement, userID) {
/*****************************************************************************************/
	
	var proceed = true;
	
	if (htmlElement.checked) {
		
		if (!confirm('Changing a user to "Internal" will remove all customer associations. This cannot be undone.\n\nAre you sure you want to proceed?')) {

			proceed= false;
			htmlElement.parentNode.MaterialSwitch.off();

		}
		
	}
	
	if (proceed) {

		var requestUrl = 'ajax/userMaintenance.asp?cmd=toggleInternalUser&userID=' + userID;
		console.log(requestUrl);
		
		createRequest();
		
		if(request) {
// 			request.onreadystatechange = StateChangeHandler;
			request.onreadystatechange = StateChangeHandler_toggleInternalUser;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
		
		function StateChangeHandler_toggleInternalUser() {
			
			if(request.readyState == 4) {
				if(request.status == 200) {
					
					
					var internalUserStatus 	= request.responseXML.getElementsByTagName('status')[0].textContent;
					var internalUserElem 	= document.getElementById('internalUser');
					
					if (internalUserStatus == 'true') {
						internalUserElem.parentNode.MaterialSwitch.on();	
	
						document.getElementById('customersContainer').style.display = 'none';
						var allCustomers = document.getElementById('allCustomers');
						ToggleChildCheckboxes(allCustomers);				
	
					} else {
						internalUserElem.parentNode.MaterialSwitch.off();					
						document.getElementById('customersContainer').style.display = 'block';
					}
					
				} else {
					alert("problem toggling internal user status, status code: "  + request.status);
				}
			}
			
		}
	

	} else {

		return false;

	}
	
}



/*****************************************************************************************/
function ToggleMenu(htmlTableRow) {
/*****************************************************************************************/
	
	var currMenu = htmlTableRow.childNodes[13].childNodes[3];
	
	if (currMenu.style.display == "none") {
		currMenu.style.display = "block";
	} else {
		currMenu.style.display = "none";
	}	
	
	
}


/*****************************************************************************************/
function CustomerName_onInput(htmlElement) {
/*****************************************************************************************/
	
	var selectedCustomerName = htmlElement.value;

	if (selectedCustomerName.length > 0) {

		var customerList = document.getElementById('customerList');
		var dataListOptions = customerList.options;
		var customerID = dataListOptions.namedItem(selectedCustomerName).getAttribute("data-id");	

	} else {

		var customerID = "";

	}

	document.getElementById('customerID').value = customerID; 		
	
}



/*****************************************************************************************/
function checkUniqueUsername_onChange(inputNode) {
/*****************************************************************************************/
	
	var username = inputNode.value;
	var requestUrl;
	
	requestUrl = "ajax/userMaintenance.asp?cmd=uniqueUsername&username=" + username;
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
}


/*****************************************************************************************/
function UserDelete(htmlElement) {
/*****************************************************************************************/
	
	if (confirm('Are you sure you want to delete this user?')) {

		var user					= htmlElement.getAttribute('data-val');
		var attributeName 	= 'deleted';	
		var attributeValue	= '1';

// 	var requestUrl = "ajax/userMaintenance.asp?cmd=update&user=" + user + "&attribute=" + attributeName + "&value=" + attributeValue;
		var requestUrl = "ajax/userMaintenance.asp?cmd=deleteUser&user=" + user;

		console.log(requestUrl);

		createRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
		
		location = location; 

	}
	
}


/*****************************************************************************************/
function userAttribute_onChange(attributeNode,user) {
/*****************************************************************************************/

	var attributeName 	= attributeNode.name;
	var attributeValue

	if (attributeName == "deleted") {
		if (!confirm('Are you sure you want to delete this item?')) {
			return;
		}
	}

	
	
		
// 	if(attributeName == "customerID" || attributeName == "deleted") {
	if(attributeName == "deleted") {
		attributeValue = attributeNode.getAttribute('data-val');
	} else {
		attributeValue 	= attributeNode.value;
	}
	
	var requestUrl 	= "ajax/userMaintenance.asp?cmd=update&user=" + user + "&attribute=" + attributeName + "&value=" + attributeValue;
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function ToggleAllUserRoles(htmlElement, userID) {
/*****************************************************************************************/
	
	var cmd;
	if (htmlElement.checked) {
		cmd = 'addAllRoles'; 
	} else {
		cmd = 'removeAllRoles';
	}
	
	var requestUrl;
	requestUrl = 'ajax/userMaintenance.asp?cmd=' + cmd + '&userID=' + userID;
	console.log(requestUrl);
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
// 		request.onreadystatechange = StateChangeHandler_userAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


}


/*****************************************************************************************/
function ToggleAllUserPermissions(htmlElement, userID) {
/*****************************************************************************************/
	
	var cmd;
	if (htmlElement.checked) {
		cmd = 'addAllPermissions'; 
	} else {
		cmd = 'removeAllPermissions';
	}
	
	var requestUrl;
	requestUrl = 'ajax/userMaintenance.asp?cmd=' + cmd + '&userID=' + userID;
	console.log(requestUrl);
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


}


/*****************************************************************************************/
function ToggleAllUserCustomers(htmlElement, userID) {
/*****************************************************************************************/
	
	var cmd;
	if (htmlElement.checked) {
		cmd = 'addAllCustomers'; 
	} else {
		cmd = 'removeAllCustomers';
	}
	
	var requestUrl;
	requestUrl = 'ajax/userMaintenance.asp?cmd=' + cmd + '&userID=' + userID;
	console.log(requestUrl);
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


}


/*****************************************************************************************/
function ToggleAllUserClients(htmlElement, userID) {
/*****************************************************************************************/
	
	var cmd;
	if (htmlElement.checked) {
		cmd = 'addAllClients'; 
	} else {
		cmd = 'removeAllClients';
	}
	
	var userConfirmed = true;
	if (cmd == 'removeAllClients') {
		userConfirmed = confirm('Removing all clients from this user will also remove customers, roles, and permissions in all clients. This cannot be undone.\n\nAre you sure you want to remove all clients from this user?')
	}



	if (userConfirmed) {

		var requestUrl;
		requestUrl = 'ajax/userMaintenance.asp?cmd=' + cmd + '&userID=' + userID;
		console.log(requestUrl);
		createRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
	} else {

		return false;

	}

}


/*****************************************************************************************/
function StateChangeHandler_userClients() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			userClients_status(request.responseXML);
		} else {
			alert("problem retrieving data from the server, status code: "  + request.status);
		}
	}

}



/*****************************************************************************************/
function userClients_status(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var status = GetInnerText(urNode.getElementsByTagName('status')[0]);

	var roleParentCheckbox = document.getElementById('allRoles');
	roleParentCheckbox.parentNode.MaterialCheckbox.uncheck();
	ToggleChildCheckboxes(roleParentCheckbox);
	
	
	var permParentCheckbox = document.getElementById('allPermissions')
	permParentCheckbox.parentNode.MaterialCheckbox.uncheck();
	ToggleChildCheckboxes(permParentCheckbox);

	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}






/*****************************************************************************************/
function userClient_onClick(htmlElement, userID) {
/*****************************************************************************************/

	var proceed = true;

	if (!htmlElement.checked) {
		if (!confirm('Removing a client will also remove all customers, roles, and permissions from the user for the client. This cannot be undone. \n\nAre you sure you want to proceed?')) {

			proceed = false;

		} else {

			proceed = true;
			
			var clientID = htmlElement.getAttribute('data-id');
			
			if (clientID == 1) {

				var roleParentCheckbox = document.getElementById('allRoles');
				roleParentCheckbox.parentNode.MaterialCheckbox.uncheck();
				ToggleChildCheckboxes(roleParentCheckbox);
				
				
				var permParentCheckbox = document.getElementById('allPermissions')
				permParentCheckbox.parentNode.MaterialCheckbox.uncheck();
				ToggleChildCheckboxes(permParentCheckbox);
				
			}

		}

	}

	
	if (proceed) {

		var clientID = htmlElement.getAttribute('data-id');
	
		var requestUrl;
		requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=client&user=" + userID + "&client=" + clientID;
		console.log(requestUrl);
		createRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
				
		
	} else {
		
		return false;
		
	}

}


/*****************************************************************************************/
function UserRole_onClick(htmlElement,userID) {
/*****************************************************************************************/

	var roleID = htmlElement.getAttribute('data-id');


	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=role&user=" + userID + "&role=" + roleID;
	console.log(requestUrl);
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function RolePermission_onClick(role,permission) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=rolePermission&role=" + role + "&permission=" + permission;
	createRequest();
 
	if (request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}



/*****************************************************************************************/
function UserPermission_onClick(htmlElement,userID) {
/*****************************************************************************************/

	var permissionID = htmlElement.getAttribute('data-id');
	
	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=permission&user=" + userID + "&permission=" + permissionID;
	console.log(requestUrl);
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function userCompany_onClick(attributeNode,user) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=permission&user=" + user + "&permission=" + permission;
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function uniqueUser_status(unNode) {
/*****************************************************************************************/

	var username 	= unNode.getElementsByTagName('username')[0].getAttribute('value');
	var clientID 	= unNode.getElementsByTagName('username')[0].getAttribute('clientID');
	var userID 		= unNode.getElementsByTagName('username')[0].getAttribute('userID');
	var feedback 	= GetInnerText(unNode.getElementsByTagName('username')[0]);
	
	var customerIDElem = document.getElementById('customerID');
	var customerID = customerIDElem.options[customerIDElem.selectedIndex].value;
	
	
	if(feedback == "duplicate") {

		var usernameField = document.getElementById('username');

		if (confirm("The user name '" + username + "' is already in use. \n\nClick OK to associate this user with the current client  (" + clientID + ").\nClick Cancel to try a diffierent user name.\n")) {

// 			alert('adding user to current client');

			var requestUrl;
			
			requestUrl = 'ajax/userMaintenance.asp?cmd=addUserToClient'
															+ '&username=' 	+ username
															+ '&clientID=' 	+ clientID
															+ '&userID=' 		+ userID
															+ '&customerID=' 	+ customerID;
															 
			console.log(requestUrl);
			
			createRequest();
		 
			if(request) {
// 				request.onreadystatechange = StateChangeHandler;
				request.onreadystatechange = StateChangeHandler_addUserToClient;
				request.open("GET", requestUrl,  true);
				request.send(null);		
			}
			
			function StateChangeHandler_addUserToClient() {
				
				if(request.readyState == 4) {
					if(request.status == 200) {
// 					uniqueUser_status(request.responseXML);
						location = 'userList.asp';
						
					} else {
						alert("problem retrieving data from the server, status code: "  + request.status);
					}
				}
				
			}

		} else {

			usernameField.value = null;
			usernameField.select();
			usernameField.focus();
	
		}
		
	}
	
}


/*****************************************************************************************/
function StateChangeHandler() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			userAttribute_status(request.responseXML);
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
function userAttribute_status(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var status = GetInnerText(urNode.getElementsByTagName('status')[0]);
	
	if(urNode.getElementsByTagName('deleted').length > 0) {
		var userID = urNode.getElementsByTagName('user')[0].id;
		var rowID = document.getElementById('deleted-'+userID);
		var imageToToggle = document.getElementById('imgDeleted-'+userID);
		
		if(GetInnerText(urNode.getElementsByTagName('deleted')[0]) == "False") {
			document.getElementById('imgDeleted-'+userID).src = '/images/ic_delete_black_24dp_1x.png';
		} else {
			document.getElementById('imgDeleted-'+userID).src = '/images/ic_delete_forever_black_24dp_1x.png';			
		}
	}
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	if(status == "error") {
		document.getElementById('firstName').focus();
		document.getElementById('username').focus();
	}

}


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}


/*****************************************************************************************/
function captureCustomerID_onchange(selectElement) {
/*****************************************************************************************/	
	
	document.getElementById('custID').value = selectElement.getAttribute('data-val');
	
}
