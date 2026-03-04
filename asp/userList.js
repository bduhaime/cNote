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
	
	if (currActionButtons.style.visibility == "hidden") {
		currActionButtons.style.visibility = "visible";
	} else {
		currActionButtons.style.visibility = "hidden";
	}
	

}


/*****************************************************************************************/
function UserAdd_onClick () {
/*****************************************************************************************/
	

	document.getElementById("dialogTitle").innerHTML 		= "New User";
	
	if (clientID != 'cSuite') {

		document.getElementById('userTypeInstructions').style.display = 'block';	
		document.getElementById('userTypeSelector').style.display = 'block';	
		
		var userTypeRadioButtons = dialog_user.querySelectorAll('.userType');
		for (i = 0; i < userTypeRadioButtons.length; ++i) {
			userTypeRadioButtons[i].checked = false;
			userTypeRadioButtons[i].parentNode.classList.remove('is-checked');
		}
	
		if (document.getElementById('customerInstructions')) {
			document.getElementById('customerInstructions').style.display = 'none';	
		}
	
		if (document.getElementById('externalCustomer')) {
			document.getElementById('externalCustomer').selectedIndex = null;	
			document.getElementById('externalCustomer').parentNode.style.display = 'none';		
		}
	
		if (document.getElementById('internalCustomer')) {
			document.getElementById('internalCustomer').parentNode.style.display = 'none';		
		}
				

		if (document.getElementById('validDomains')) {
			document.getElementById('validDomains').innerHTML 	= '';	
			document.getElementById('validDomains').style.display = 'none';	
		}
		
		document.getElementById('userNameInstructions').style.display = 'none';	
	
		document.getElementById('username').value 	= '';	
		document.getElementById('username').parentNode.style.display = 'none';	
		
		document.getElementById('remainingInstructions').style.display = 'none';	
	
		document.getElementById("firstName").value 	= '';
		document.getElementById("firstName").parentNode.style.display = 'none';
	
		document.getElementById('lastName').value		= '';
		document.getElementById('lastName').parentNode.style.display = 'none';
		
		document.getElementById('title').value			= '';
		document.getElementById('title').parentNode.style.display = 'none';
		
		document.getElementById('buttonSave').style.display = 'block';
		document.getElementById('buttonSave').disabled = true;
		
		document.getElementById('buttonCancel').style.display = 'block';


	} else {
		
		document.getElementById('userNameInstructions').style.display = 'block';	
	
		document.getElementById('username').value 	= '';	
		document.getElementById('username').parentNode.style.display = 'block';	
		
		
	}
	


	dialog_user.showModal();

	
	
	
// 	document.getElementById('buttonNext').style.display = 'none';

	dialog_user.style.top 	= ((window.innerHeight/2) - (dialog_user.offsetHeight/2))+'px';
	
}


/*****************************************************************************************/
function UserType_onChange(htmlElement) {
/*****************************************************************************************/

	var userType = htmlElement.value;
	
	if (userType == 'internal') {

		dialog_user.querySelector('#userTypeInstructions').style.display = 'none';
		
		var customerInstructions = dialog_user.querySelector('#customerInstructions');
		if (customerInstructions) {
			customerInstructions.style.display = 'none';
		}
		
		var externalCustomer = dialog_user.querySelector('#externalCustomer');
		if (externalCustomer) {
			externalCustomer.parentNode.style.display = 'none';
		}
		
		var internalCustomer = dialog_user.querySelector('#internalCustomer');
		if (internalCustomer) {
			internalCustomer.parentNode.style.display = 'block';
			var validDomainsElem = dialog_user.querySelector('#validDomains');
			if (validDomainsElem) {
				var validDomains = dialog_user.querySelector("#internalCustomer").getAttribute('data-domains');
				validDomainsElem.innerHTML = '<b>Valid Domain(s):</b><br><div id="validDomainList">' + validDomains + '</div>';
				validDomainsElem.style.display 					= 'block';
			}
		}
		
		

		dialog_user.querySelector('#userNameInstructions').style.display 			= 'block';
		var userNameElem = dialog_user.querySelector('#username');
		userNameElem.parentNode.style.display 												= 'block';
		userNameElem.parentNode.classList.remove('is-invalid');
		userNameElem.value = null;
		userNameElem.focus();
		userNameElem.select();
		
		dialog_user.querySelector('#customerID').value = 1;
		

	} else if (userType == 'external') {

// 	alert('external user type selected');		

		dialog_user.querySelector('#userTypeInstructions').style.display 			= 'none';
		
		var internalCustomerElem = dialog_user.querySelector('#internalCustomer');
		if (internalCustomerElem) {
			dialog_user.querySelector('#internalCustomer').parentNode.style.display = 'none';
		}
		
		var validDomainsElem = dialog_user.querySelector('#validDomains');
		if (validDomainsElem) {
			validDomainsElem.style.display = 'none';
		}
		
		var userNameInstructionsElem = dialog_user.querySelector('#userNameInstructions');
		if (userNameInstructionsElem) {
			userNameInstructionsElem.style.display = 'none';
		}
			
		dialog_user.querySelector('#username').parentNode.style.display = 'none';

		var customerInstructionsElem = dialog_user.querySelector('#customerInstructions');
		if (customerInstructionsElem) {
			dialog_user.querySelector('#customerInstructions').style.display = 'block';
		}
		
		var customerElem = dialog_user.querySelector('#externalCustomer');
		if (customerElem) {
			customerElem.parentNode.style.display = 'block';
			customerElem.focus();
			customerElem.selectedIndex = null;
		}
		
		dialog_user.querySelector('#customerID').value = null;
		

	} else {

		alert('Unexpected user type encounterned');
		return false;

	}

	dialog_user.style.top 	= ((window.innerHeight/2) - (dialog_user.offsetHeight/2))+'px';
	
}



/*****************************************************************************************/
function Customer_onChange(htmlElement) {
/*****************************************************************************************/

// 	dialog_user.querySelector('#userTypeInsructions').style.display = 'none';
// 	dialog_user.querySelector('#customerInstructions').style.display = 'none';
	
	dialog_user.querySelector('#userTypeInstructions').style.display = 'none';
	dialog_user.querySelector('#customerInstructions').style.display = 'none';


	var customerSelector = dialog_user.querySelector('#externalCustomer');
	var validDomains = customerSelector.options[customerSelector.selectedIndex].getAttribute('data-domains');
	dialog_user.querySelector('#validDomains').innerHTML = '<b>Valid Domain(s):</b><br><div id="validDomainList">' + validDomains + '</div>';
	dialog_user.querySelector('#validDomains').style.display = 'block';


	dialog_user.querySelector('#userNameInstructions').style.display = 'block';
	var userNameElem = dialog_user.querySelector('#username');
	userNameElem.parentNode.style.display = 'block'; 
	userNameElem.parentNode.classList.remove('is-invalid'); 
	userNameElem.value = null;
	userNameElem.focus();
	userNameElem.select();

	dialog_user.querySelector('#customerID').value = customerSelector.options[customerSelector.selectedIndex].value;
	
	// 	dialog_user.querySelector('#buttonNext').style.display = 'block';
	
	dialog_user.style.top 	= ((window.innerHeight/2) - (dialog_user.offsetHeight/2))+'px';
	
	
}


/*****************************************************************************************/
function checkUniqueUsername_onChange(inputNode) {
/*****************************************************************************************/
	
	var customerID = dialog_user.querySelector('#customerID').value;
	
// 	if (customerID) {
		var username = inputNode.value;
		var requestUrl;
		
		requestUrl = 'ajax/userMaintenance.asp?cmd=uniqueUsername'
												+ '&username=' + username
												+ '&customerID=' + customerID;
												
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_uniqueUsername;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
		
		function StateChangeHandler_uniqueUsername() {
			
			if(request.readyState == 4) {
				if(request.status == 200) {
					uniqueUser_status(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
			
		}
	
// 	} else {
// 		
// 		alert('customerID expected but not found');
// 		return false;
// 	}
	
}

/*****************************************************************************************/
function uniqueUser_status(unNode) {
/*****************************************************************************************/

	var username 			= unNode.getElementsByTagName('username')[0].getAttribute('value');
	var userID 				= unNode.getElementsByTagName('username')[0].getAttribute('userID');
	var feedback 			= unNode.getElementsByTagName('username')[0].textContent;
	var validUserDomain	= unNode.getElementsByTagName('validUserDomain')[0].textContent;
	var usernameField 	= document.getElementById('username');

// 	var clientID 			= document.getElementById('clientID').value;
	var clientID			= dialog_user.querySelector('#clientID').value;
	
	var customerIDValue = customerID.value;
	
	
	
	if (validUserDomain == 'true') {
	
	
		if (feedback == "duplicate - can be added to this client") {
			// the username exists on csuite..users, but is not associated with the current clientID
	
			if (confirm("This username is already in use. \n\nClick OK to associate this user with the current client.\nClick Cancel to try a diffierent user name.\n")) {
	
	// 		alert('adding user to current client');
	
				var requestUrl;
				
				requestUrl = 'ajax/userMaintenance.asp?cmd=addUserToClient'
																+ '&username=' 	+ username
																+ '&clientID=' 	+ clientID
																+ '&userID=' 		+ userID
																+ '&customerID=' 	+ customerIDValue;
																 
				console.log(requestUrl);
				
				CreateRequest();
			 
				if(request) {
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
	
	// 		usernameField.value = '';
				usernameField.parentNode.classList.add('is-invalid');
				usernameField.select();
				usernameField.focus();
		
			}
			
		
		} else if (feedback == 'duplicate - already in this client') {
			// this condition is obsolete, sorry
			
	// 		var instructionsElem = document.getElementById('instructions');
	// 		instructionsElem.textContent = 'This username is already in use and associated with the current client. Please enter a different username and click the NEXT button.';
			
			alert('This username is already in use and associated with the current client.\n\nClick the OK button to try a differnt username.');
			usernameField.select();
			usernameField.focus();
	
		
		} else if (feedback == 'duplicate - already in this client, already an internal user') {
			// the username exists on csuite..users, is associated with the current client, and the requested customerID

			alert('This username is already in use as an internal user.\n\nClick the OK button to try a different username.');
			usernameField.select();
			usernameField.focus();
	

		} else if (feedback == 'duplicate - already in this client, already an external user associated with this customer')	{
			
			alert ('This username is already an external user associated with this customer.\n\nClick the OK button to try a different username.');
			usernameField.select();
			usernameField.focus();
		
		} else if (feedback == 'duplicate - already in this client but associated with another customer') {
			// the username exists on csuite..users, is associated with the current client, but only for other customerID's
			
		
		} else if (feedback == 'duplicate - already in this client, not associated with a customer') {
			// the username exists on cuite..users, is associated with the curent client, but has no customerID's


		} else if (feedback =='duplicate - already in this client, not associated with this customer') {
			
			alert('this username is already in use and associated with another customer.\n\nClick the OK button to try a different username.');
			usernameField.select();
			usernameField.focus();
		
		} else {
			
			document.getElementById('userNameInstructions').style.display = 'none';
			document.getElementById('remainingInstructions').style.display = 'block';
			
// 			var buttonNext = document.getElementById('buttonNext');
			var buttonSave = document.getElementById('buttonSave');
			var firstNameElem = document.getElementById('firstName');
			
			firstNameElem.parentNode.style.display = 'block';
			firstNameElem.select();
			firstNameElem.focus();
			
			document.getElementById('lastName').parentNode.style.display = 'block';
			
// 			if (clientID != 'csuite') {
// 				document.getElementById('customer').parentNode.style.display = 'block';
// 			}
			
			document.getElementById('title').parentNode.style.display = 'block';
			
// 			buttonNext.style.display = 'none';
			buttonSave.style.display = 'block';
			buttonSave.disabled = false;
	
			// resize the <dialog> after controls are displayed/hidden...
			dialog_user.style.top 	= ((window.innerHeight/2) - (dialog_user.offsetHeight/2))+'px';
	
			
			
		}
		
	} else {
		
		alert('The domain for this user is not allowed for the current client.\n\nClick the OK button to try a different username.');
		usernameField.select();
		usernameField.focus();
		usernameField.parentNode.classList.add('is-invalid');
		
	}
	
}

/*****************************************************************************************/
async function AddUser_onSave( sessionJWT ) {
/*****************************************************************************************/
	
	let isDialogValid = true;
	const $username = $( '#username' );
	if ( !$username.val() ) {
		$username.parent().addClass( 'is-invalid' ).focus().select();
		isDialogValid = false;
	}
	
	
	const $firstName = $( '#firstName' );
	if ( !$firstName.val() ) {
		$firstName.parent().addClass( 'is-invalid' ).focus().select();
		isDialogValid = false;
	}

	const $lastName = $( '#lastName' );
	if ( !$lastName.val() ) {
		$lastName.parent().addClass( 'is-invalid' ).focus().select();
		isDialogValid = false;
	}

	if ( isDialogValid ) {
	
		const $customerID = $( '#customerID' );
		const $title = $( '#title' );	
			
		await $.ajax({
	
			url: `${apiServer}/api/editUser`,
			type: 'post',
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			data: { 
				username: $username.val(),
				firstName: $firstName.val(),
				lastName: $lastName.val(),
				customerID: $customerID.val(),
				title: $title.val() 
			}
	
		}).done( function() {

			var notification = document.querySelector('.mdl-js-snackbar');
			notification.MaterialSnackbar.showSnackbar({
				message: "User saved"
			});

			return true;
	
		}).fail( function( jqXHR, textStatus, errorThrown ) {

			alert('Error encountered while saving user:\n\n' + textStatus );
			return false;
	
		});

	} else {

		return false;
		
	}

	
}



/*****************************************************************************************/
function UserDelete_onClick(htmlElement) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this user?\n\nThis will remove the user from your client; the user can be re-associated with your client at any time, but roles, permissions, and customer associations for the user will need to be recreated.\n\n')) {

		var attributeName = htmlElement.name;
		var userID			= htmlElement.getAttribute('data-val');
		
		var requestUrl 	= "ajax/userMaintenance.asp?cmd=deleteUser&user=" + userID;

		console.log(requestUrl);
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_userDelete;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}


		function StateChangeHandler_userDelete() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					userDelete_status(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
		

	}
	
}


/*****************************************************************************************/
function userDelete_status(urNode) {
/*****************************************************************************************/

	var msg = "User deleted";
	var status = urNode.getElementsByTagName('status')[0].innerText;
	
		
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	)
	
	location = location; 

}


/*****************************************************************************************/
function EditUser_onClick(htmlElement) {
/*****************************************************************************************/

	dialog_user.showModal();
	
	var userID 			= htmlElement.getAttribute('data-val');
	var userRow 		= document.getElementById('userRow-'+userID);
	var username 		= userRow.querySelector('.username').textContent.trim();
	var firstName 		= userRow.querySelector('.firstName').textContent.trim();
	var lastName 		= userRow.querySelector('.lastName').textContent.trim();
	var customerID		= userRow.querySelector('.customerName').getAttribute('data-val');
	var title 			= userRow.querySelector('.title').textContent.trim();
	
	document.getElementById('dialogTitle').textContent 				= 'Edit User';
// 	document.getElementById('instructions').textContent = 'Change values and click the SAVE button.';

	document.getElementById('userTypeInstructions').style.display = 'none';
	document.getElementById('internalUser').parentNode.style.display = 'none';
	document.getElementById('externalUser').parentNode.style.display = 'none';


	var usernameElem = document.getElementById('username');
	usernameElem.value								= username;
	usernameElem.parentNode.style.display 		= 'block';
	usernameElem.parentNode.classList.add('is-dirty');
// 	usernameElem.focus();
// 	usernameElem.select();

	
	var firstNameElem = document.getElementById('firstName');
	firstNameElem.value								= firstName;
	firstNameElem.parentNode.style.display		= 'block';
	firstNameElem.parentNode.classList.add('is-dirty');


	var lastNameElem = document.getElementById('lastName');
	lastNameElem.value								= lastName;
	lastNameElem.parentNode.style.display 		= 'block';
	lastNameElem.parentNode.classList.add('is-dirty');

	
	if (document.getElementById('customer')) {
		var customerElem = document.getElementById('customer');
		
		if (customerID) {
			for (i = 0; i <= customerElem.options.length; ++i) {
				if (customerElem.options[i].value == customerID) {
					customerElem.selectedIndex = i;
					break;
				}
			}
		}

		customerElem.parentNode.style.display 		= 'block';
		customerElem.parentNode.classList.add('is-dirty');

	}

	
	var titleElem = document.getElementById('title');
	titleElem.value									= title;
	titleElem.parentNode.style.display 			= 'block';
	titleElem.parentNode.classList.add('is-dirty');
	
// 	document.getElementById('buttonNext').style.display = 'none';
	document.getElementById('buttonSave').style.display = 'block';
	document.getElementById('buttonSave').disabled = false;
	
	if (userID) {
		document.getElementById('userID').value = userID;
	}
	
	
	dialog_user.style.top = ((window.innerHeight/2) - (dialog_user.offsetHeight/2))+'px';

	
}


/*****************************************************************************************/
function GoToUser(htmlElement) {
/*****************************************************************************************/

	var userID = htmlElement.getAttribute('data-val');
	

	window.location.href='userEdit.asp?id=' + userID;

	
}


