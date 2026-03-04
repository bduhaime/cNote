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
function ToggleActionButtons(htmlElement) {
/*****************************************************************************************/

	if (htmlElement) {
		if (htmlElement.style.visibility == 'visible') {
			htmlElement.style.visibility = 'hidden';
		} else {
			htmlElement.style.visibility = 'visible';
		}
	}
}



/*****************************************************************************************/
function AddUserFromContact(dialog) {
/*****************************************************************************************/


	var username			= dialog.querySelector('#username').value;
	var firstName 			= dialog.querySelector('#firstName').value;
	var lastName 			= dialog.querySelector('#lastName').value;
	var title		 		= dialog.querySelector('#title').value;
	var customerID 		= dialog.querySelector('#customerID').value;

	var requestUrl = 'ajax/userMaintenance.asp?cmd=addUser'
										+ '&username=' + username 
										+ '&firstName=' + encodeURIComponent(firstName)
										+ '&lastName=' + encodeURIComponent(lastName)
										+ '&customer=' + customerID 
										+ '&title=' + encodeURIComponent(title);

	console.log(requestUrl);	
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addUser;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addUser() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				
				var userID = request.responseXML.getElementsByTagName('userID')[0].textContent;

				location = 'userEdit.asp?id=' + userID;
// 			Complete_adddUser(request.responseXML);

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
	
}



/*****************************************************************************************/
function ContactEmail_onChange(htmlElement, customerID) {
/*****************************************************************************************/
	

	var contactEmail 	= htmlElement.value;
	
	if (contactEmail) {
		
		requestUrl = 'ajax/customerMaintenance.asp?cmd=validContactDomain'
													+ '&customerID=' + customerID 
													+ '&contactEmail=' + encodeURIComponent(contactEmail);
													
		console.log(requestUrl);
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_validContactDomain;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_validContactDomain() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
// 					Complete_addContact(request.responseXML);

					var domainIsValid = request.responseXML.getElementsByTagName('isValid')[0].textContent;	
					
					if (domainIsValid == 'true') {
						htmlElement.parentNode.classList.remove('is-invalid');
					} else {
						htmlElement.parentNode.classList.add('is-invalid');
					}
					
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	} else {
		
		htmlElement.parentNode.classList.remove('is-invalid');

	}
	
	
}



/*****************************************************************************************/
function EditContact_onClick(htmlElement) {
/*****************************************************************************************/
	
	dialog_addContact.querySelector( '#add_contactDialogTitle' ).textContent = 'Edit Contact';

	
	const edit_contactID = htmlElement.getAttribute( 'data-val' );
	dialog_addContact.querySelector( '#add_contactID' ).value = edit_contactID;
	
	const currTableRow = htmlElement.closest( 'TR' );	
	
	const roles = currTableRow.querySelectorAll( 'li.role' );
	if ( roles ) {
		for ( i = 0; i < roles.length; ++i ) {
			var roleID = 	roles[i].getAttribute( 'data-id' );
			dialog_addContact.querySelector( '#role-'+roleID ).checked = true;
		}
	}	
	
	const edit_gender		 					= currTableRow.querySelector( 'td.prefix' ).innerText;
	const edit_firstName	 					= currTableRow.querySelector( 'td.firstName' ).innerText;
	const edit_lastName 						= currTableRow.querySelector( 'td.lastName' ).innerText;
	const edit_contactTitle 				= currTableRow.querySelector( 'td.title' ).innerText;
	const edit_contactEmail					= currTableRow.querySelector( 'td > div.email' ).innerText;
	const edit_contactPhone					= currTableRow.querySelector( 'td > div.phone' ).innerText;
	const edit_contactZGR 					= currTableRow.querySelector( 'td.zeroRisk' ).innerText;
	const edit_contactCallAttendeeInd	= currTableRow.querySelector( '#callAttendee-' + edit_contactID ).checked;


	$( '#add_gender' ).val( edit_gender );
	$( '#add_gender' ).parent().addClass( 'is-dirty' );
	

	$( '#add_firstName' ).val( edit_firstName );
	$( '#add_firstName' ).parent().addClass( 'is-dirty' );
	if ( edit_firstName ) {
		$( '#add_firstName' ).parent().removeClass( 'is-invalid' );
	}
	

	$( '#add_lastName' ).val( edit_lastName );
	$( '#add_lastName' ).parent().addClass( 'is-dirty' );
	if ( edit_lastName ) {
		$( '#add_lastName' ).parent().removeClass( 'is-invalid' );
	}
	

	$( '#add_contactTitle' ).val( edit_contactTitle );
	$( '#add_contactTitle' ).parent().addClass( 'is-dirty' );

	
	$( '#add_contactEmail' ).val( edit_contactEmail );
	$( '#add_contactEmail' ).parent().addClass( 'is-dirty' );


	$( '#add_contactPhone' ).val( edit_contactPhone );
	$( '#add_contactPhone' ).parent().addClass( 'is-dirty' );


	$( '#add_contactGrade' ).val( edit_contactZGR );
	$( '#add_contactGrade' ).parent().addClass( 'is-dirty' );

	
	const attendee = dialog_addContact.querySelector( '#add_contactCallAttendeeInd' );
	if ( edit_contactCallAttendeeInd ) {
		attendee.parentNode.MaterialSwitch.on();
	} else {	
		attendee.parentNode.MaterialSwitch.off();
	}
	attendee.parentElement.classList.add( 'is-dirty' );


	dialog_addContact.showModal();
	
	
}




/*****************************************************************************************/
function AddContact_onSave(dialog) {
/*****************************************************************************************/

	var contactID 				= document.getElementById('add_contactID').value;
	var customerID				= encodeURIComponent(document.getElementById('add_contactCustomerID').value);
	var gender					= encodeURIComponent(document.getElementById('add_gender').value);
	var firstName				= encodeURIComponent(document.getElementById('add_firstName').value);
	var lastName				= encodeURIComponent(document.getElementById('add_lastName').value);
	var title					= encodeURIComponent(document.getElementById('add_contactTitle').value);
	var email					= encodeURIComponent(document.getElementById('add_contactEmail').value);
	var phone					= encodeURIComponent(document.getElementById('add_contactPhone').value);
	var grade					= encodeURIComponent(document.getElementById('add_contactGrade').value);
	
	var gradeElem = dialog.querySelector('#add_contactGrade');
	if (gradeElem.parentNode.classList.contains("is-invalid")) {
		alert('ZeroRisk is invalid');
		gradeElem.focus();
		return false;
	}
	
	
	var rolesCollection = dialog.querySelectorAll('.roles');
	var assignedRoles;
	for (i = 0; i < rolesCollection.length; ++i) {
		if (rolesCollection[i].checked) {
			if (assignedRoles) {
				assignedRoles = assignedRoles + ',';
			}
			if (assignedRoles) {
				assignedRoles = assignedRoles + rolesCollection[i].getAttribute('data-id');
			} else {
				assignedRoles = rolesCollection[i].getAttribute('data-id');
			}
		}
	}

	var contactCallAttendeeInd;
	if (document.getElementById('add_contactCallAttendeeInd').checked) {
		contactCallAttendeeInd = "1";
	} else {
		contactCallAttendeeInd = "0";
	}

	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=addCustomerContact"
														+ "&customer=" + customerID 
														+ "&gender=" + gender 
														+ "&firstName=" + firstName
														+ "&lastName=" + lastName 
														+ "&contactTitle=" + title
														+ "&contactEmail=" + email
														+ "&contactPhone=" + phone
														+ "&contactGrade=" + grade
														+ "&contactCallAttendeeInd=" + contactCallAttendeeInd
														+ "&contactCustomerID=" + customerID
														+ "&contactID=" + contactID
														+ "&assignedRoles=" + assignedRoles;

	console.log(requestUrl);
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addContact;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addContact() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_addContact(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_addContact	(xml) {
/*****************************************************************************************/
	
// Clear out values from dialog/form fields
	document.getElementById('add_contactCustomerID').value = "";
	document.getElementById('add_firstName').value = "";
	document.getElementById('add_lastName').value = "";
	document.getElementById('add_contactTitle').value = "";
	document.getElementById('add_contactGrade').value = "";
	document.getElementById('add_contactCallAttendeeInd').checked = false;

	location = location;
	
}


/*****************************************************************************************/
function CustomerContactDelete_onClick(htmlNode) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this contact?\n\nThis action cannot by undone.\n\n')) {

		var clientContactID = htmlNode.getAttribute("data-val");
		
		var requestUrl 	= "ajax/customerMaintenance.asp?cmd=deleteClientContact&id=" + clientContactID;
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_deleteClientContact;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_deleteClientContact() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					Complete_deleteClientContact(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
	
	}

}


/*****************************************************************************************/
function Complete_deleteClientContact(urNode) {
/*****************************************************************************************/

	var id = GetInnerText(urNode.getElementsByTagName('id')[0]);
	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	//delete row from table here.....	
	var deletedItemImg = document.getElementById('contactDelete-'+id);
	var deletedTD = deletedItemImg.parentNode.parentNode;
	var deletedTR = deletedTD.parentNode;
	var deletedRow = deletedTR.rowIndex;
	
	document.getElementById('tbl_customerContacts').deleteRow(deletedRow);
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	location = location;

}


/*****************************************************************************************/
function ClientContactToggle_onClick(htmlNode, attr) {
/*****************************************************************************************/

	var contactID = htmlNode.getAttribute("data-val");
	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=toggleContact&id=" + contactID + "&attr=" + attr;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_ClientContactToggle;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_ClientContactToggle() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_ClientContactToggle(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_ClientContactToggle (urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}




