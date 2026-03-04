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
function unhideObjects () {
/*****************************************************************************************/

	document.querySelector('.mdl-spinner').classList.remove('is-active');

	var hiddenObjects = document.querySelectorAll('.hiddenObject');
	if (hiddenObjects) {
		var i;
		for (i = 0; i < hiddenObjects.length; ++i) {
			hiddenObjects[i].style.display = 'block';
		}
	}

}



/*****************************************************************************************/
function UpdateDefaultClient(radioButton) {
/*****************************************************************************************/

	var clientID 	= radioButton.value;
	var userID		= radioButton.getAttribute('data-userID');

	var requestUrl;
	
	requestUrl = 'ajax/userMaintenance.asp?cmd=updateDefaultClient'
													+ '&userID=' 	+ userID
													+ '&clientID=' 	+ clientID;
													 
	console.log(requestUrl);
	
	CreateRequest();
 
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
function UpdatePassword(htmlDialog) {
/*****************************************************************************************/

	var oldPasswordElem 	= htmlDialog.querySelector('#oldPassword');
	var oldPassword		= oldPasswordElem.value;
	
	if (!oldPassword) {

		alert('Old password is required.');
		oldPasswordElem.focus();
		oldPasswordElem.parentNode.classList.add('is-invalid');

	} else {

		oldPasswordElem.parentNode.classList.remove('is-invalid');

	}
	
	
	var newPasswordElem 	= htmlDialog.querySelector('#newPassword');
	var newPassword		= newPasswordElem.value;
	
	if (!newPassword) {

		alert('New password is required.');
		newPasswordElem.focus();
		newPasswordElem.parentNode.classList.add('is-invalid');
		return false;

	} else {
		
		if (newPassword == oldPassword) {
			
			alert("New password must not be the same as old password")
			newPasswordElem.focus();
			newPasswordElem.parentNode.classList.add('is-invalid');
			return false;
			
		}

		newPasswordElem.parentNode.classList.remove('is-invalid');

	}
	
	
	var confirmPasswordElem 	= htmlDialog.querySelector('#confirmPassword');
	var confirmPassword			= confirmPasswordElem.value;
	
	if (!confirmPassword) {

		alert('Confirmation password is required.');
		confirmPasswordElem.focus();
		confirmPasswordElem.parentNode.classList.add('is-invalid');
		return false;

	} else {
		
		if (confirmPassword != newPassword) {
			
			alert('Confirmation password does not match');
			newPasswordElem.parentNode.classList.add('is-invalid');
			confirmPasswordElem.parentNode.classList.add('is-invalid');
			confirmPasswordElem.focus();
			return false;
			
		} else {
			
			newPasswordElem.parentNode.classList.remove('is-invalid');
			confirmPasswordElem.parentNode.classList.remove('is-invalid');
			
		}
		
	}
	
	
	var requestUrl = 'ajax/userMaintenance.asp?cmd=updatePassword'
												+ '&old=' + encodeURIComponent(md5(oldPassword))
												+ '&new=' + encodeURIComponent(md5(newPassword))
												+ '&confirm=' + encodeURIComponent(md5(confirmPassword));
												
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdatePassword;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_UpdatePassword() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_UpdatePassword(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}


/*****************************************************************************************/
function Complete_UpdatePassword(xml) {
/*****************************************************************************************/

	var msg 			= xml.getElementsByTagName('msg')[0].textContent;
	var reasonCode = xml.getElementsByTagName('reasonCode')[0].textContent;
	
	if (reasonCode.length > 0) {
		if (reasonCode == 4 || reasonCode == 5) {

			msg = 'Old password does not match our records';
			changePasswordDialog.querySelector('#oldPassword').focus();
			changePasswordDialog.querySelector('#oldPassword').parentNode.classList.add('is-invalid');

		} else { 

			if (reasonCode != 0) {
				msg = msg + ' (Reason Code: ' + reasonCode + ')';
			} 
			changePasswordDialog.close();
			
		}
		
	}
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}



/*****************************************************************************************/
function SaveUserProfile(htmlElement) {
/*****************************************************************************************/

	var firstName 	= document.getElementById('firstName').value;
	if (!firstName) {
		alert('First name is required');
		document.getElementById('firstName').parentNode.classList.add('is-invalid');
		document.getElementById('firstName').focus();
 	} else {
		document.getElementById('firstName').parentNode.classList.remove('is-invalid');
 	}
 	
 	
	var lastName 	= document.getElementById('lastName').value;
	if (!lastName) {
		alert('Last name is required');
		document.getElementById('lastName').parentNode.classList.add('is-invalid');
		document.getElementById('lastName').focus();
 	} else {
		document.getElementById('lastName').parentNode.classList.remove('is-invalid');
 	}

	
	var title 		= document.getElementById('title').value;
	
	
	
	var requestUrl = 'ajax/userMaintenance.asp?cmd=updateUserProfile'
												+ '&firstName=' + encodeURIComponent(firstName)
												+ '&lastName=' + encodeURIComponent(lastName)
												+ '&title=' + encodeURIComponent(title);
												
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_SaveUserProfile;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_SaveUserProfile() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_SaveUserProfile(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_SaveUserProfile(xml) {
/*****************************************************************************************/

	var msg = xml.getElementsByTagName('msg')[0].textContent;
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}



/*****************************************************************************************/
function ToggleUserPageFooter(htmlElement) {
/*****************************************************************************************/

	var userFooterChecked; 
	
	if (htmlElement.checked) {
		userFooterChecked = 1
	} else {
		userFooterChecked = 0
	}
	
	var requestUrl 	= 'ajax/userMaintenance.asp?cmd=ToggleUserPageFooter' 
												+ "&footerChecked=" + userFooterChecked;
												
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_ToggleIncludeWithEmails;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_ToggleIncludeWithEmails() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_ToggleUserPageFooter(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}


/*****************************************************************************************/
function Complete_ToggleUserPageFooter(xml) {
/*****************************************************************************************/

	var msg = xml.getElementsByTagName('msg')[0].textContent;
		
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}

