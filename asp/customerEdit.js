//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

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
function GoToCustomer(htmlElement) {
/*****************************************************************************************/

	var customerID = htmlElement.id;

	window.location.href='customerOverview.asp?id=' + customerID;

	
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
function EditCustomer_onClick(htmlElement) {
/*****************************************************************************************/



// 	dialog_addCustomer.showModal();

	document.getElementById("formTitle").innerHTML = "Edit A Customer";
	
// get values from HTML table...

	var rowID = htmlElement.closest('tr').id;
	
	const table = $('#tbl_customers').DataTable();
	const row = '#'+rowID;
	
	const customerID 						= rowID;
	const cert 								= table.cell( row, '.cert' ).data();
	const name 								= table.cell( row, '.name' ).data();
	const status 							= table.cell( row, '.status' ).data();
	const nickName 						= table.cell( row, '.nickName' ).data();
	const validDomains 					= table.cell( row, '.validDomains' ).data();
	const lsvtCustomerName 				= table.cell( row, '.lsvtCustomerName' ).data();
	const secretShopperLocationName 	= table.cell( row, '.secretShopperLocationName' ).data();

	const cProfitURI 						= table.cell( row, '.cProfitURI' ).data();
	const cProfitApiKey					= table.cell( row, '.cProfitApiKey' ).data();
	
	const optOutOfMCCCalls				= table.cell( row, '.optOutOfMCCCalls' ).data();
	const defaultTimezone				= table.cell( row, '.defaultTimezone' ).data();
	

// populate dialog's form fields...

//	set the FDIC/non-FDIC radio button...
	if ( cert.length ) {
		document.getElementById( 'fdic' ).parentNode.MaterialRadio.check();
	} else {
		document.getElementById( 'nonFdic' ).parentNode.MaterialRadio.check();
	}

	if ( optOutOfMCCCalls ) {
		document.getElementById('optOutOfMCCCalls').parentNode.MaterialCheckbox.check();
	} else {
		document.getElementById('optOutOfMCCCalls').parentNode.MaterialCheckbox.uncheck();
	}


	document.getElementById('form_customerName').value = name;
	document.getElementById('form_customerName').parentElement.style.display = 'block';
	document.getElementById('form_customerName').parentElement.classList.add('is-dirty');

	var select = document.getElementById('form_customerStatus');
	for(var i = 0;i < select.options.length;i++){
		if(select.options[i].innerHTML == status){
			select.options[i].selected = true;
			break;
		}
	}	
	document.getElementById('form_customerStatus').parentElement.style.display = 'block';
	document.getElementById('form_customerStatus').parentElement.classList.add('is-dirty');





	var tzSelect = document.getElementById('form_defaultTimezone');
	tzSelect.options[0].selected = true;
	for(var i = 0;i < tzSelect.options.length;i++){
		if(tzSelect.options[i].value == defaultTimezone){
			tzSelect.options[i].selected = true;
			break;
		}
	}	
	document.getElementById('form_defaultTimezone').parentElement.style.display = 'block';
	document.getElementById('form_defaultTimezone').parentElement.classList.add('is-dirty');




	$( '#startDate').parent().show();

	$( '#form_nickname' ).val( nickName );
	$( '#form_nickname' ).parent()
		.css( 'display', 'block' )
		.addClass( 'is-dirty' );
	
	$( '#endDate').parent().show();


	if (validDomains) {
		document.getElementById('form_validDomains').value = validDomains;
		document.getElementById('form_validDomains').parentNode.classList.add('is-dirty');
	} else {
		document.getElementById('form_validDomains').value = null;
		document.getElementById('form_validDomains').parentNode.classList.remove('is-dirty');
	}
	document.getElementById('form_validDomains').parentNode.style.display = 'block';


	var lsvtCustomerNameElem = document.getElementById('form_lsvtCustomerName');
	if (lsvtCustomerNameElem) {
		lsvtCustomerNameElem.value = lsvtCustomerName;
		lsvtCustomerNameElem.parentElement.classList.add('is-dirty');
	}


	var secretShopperLocationNameElem = document.getElementById('form_secretShopperLocationName');
	if (secretShopperLocationNameElem) {
		secretShopperLocationNameElem.value = secretShopperLocationName;
		secretShopperLocationNameElem.parentElement.classList.add('is-dirty');
	}



	$( '#form_cProfitURI' ).val( cProfitURI ).parent().addClass( 'is-dirty' );
	$( '#form_cProfitAPIKey' ).val( cProfitApiKey ).parent().addClass( 'is-dirty' );


// 	var cProfitUriElem = document.getElementById('form_cProfitURI');
// 	if (cProfitUriElem) {
// 		cProfitUriElem.value = cProfitURI;
// 		cProfitUriElem.parentElement.classList.add('is-dirty');
// 	}
// 
// 	var cProfitApiElem = document.getElementById('form_cProfitAPIKey');
// 	if (cProfitApiElem) {
// 		var cProfitApiKey		= sha256(customerID+nickName+cert+name+status+validDomains+cProfitURI);
// 		cProfitApiElem.value = cProfitApiKey;
// 		cProfitApiElem.parentElement.classList.add('is-dirty');
// 	}



	document.getElementById('form_customerID').value = customerID;

	document.getElementById('dialog_buttons').style.display = "block";


	dialog_addCustomer.showModal();		 
	dialog_addCustomer.style.top 	= ((window.innerHeight/2) - (dialog_addCustomer.offsetHeight/2))+'px';

	$( "#startDate" ).datepicker();
	$( "#endDate" ).datepicker();



}


/*****************************************************************************************/
function InstitutionSwitch_onClick(htmlNode) {
/*****************************************************************************************/
	
// 	var institution 		= htmlNode.checked;

	var htmlNodeID = htmlNode.id;

	var institutions 			= document.getElementById('institutionsGroup');
	var customerName 			= document.getElementById('form_customerName').parentElement;
	var customerStatus 		= document.getElementById('form_customerStatus').parentElement;
	var customerNickname		= document.getElementById('form_nickname').parentElement;
	
	var buttons					= document.getElementById('dialog_buttons');
	
	
	if (htmlNodeID == "fdic") {
		
		document.getElementById('dialog_addCustomer').style.width = '750px';

		institutions.style.display = "block";
// 		newInstitutions.style.display = "block";

		customerName.style.display = "none";
		customerName.value = "";

		customerStatus.style.display = "block";
		customerStatus.value = "";		
		
	} else {

		document.getElementById('dialog_addCustomer').style.width = '';

		institutions.style.display = "none";
		institutions.value = "";
// 		newInstitutions.style.display = "none";
// 		newInstitutions.value = "";

		customerName.style.display = "block";

		customerStatus.style.display = "block";
		customerStatus.value = "";

	}

	customerNickname.style.display = "block";
	customerName.value = "";			
	
	buttons.style.display = "block";
	
}


/*****************************************************************************************/
function hinter(htmlNode) {
/*****************************************************************************************/

//     huge_list.innerHTML = "";
    window.hinterXHR = new XMLHttpRequest();

    // retireve the input element
//     var input = event.target;
	 var input = htmlNode.value;

    // retrieve the datalist element
    var huge_list = document.getElementById('oldInstitutionsList');

    // minimum number of characters before we start to generate suggestions
    var min_characters = 0;

//     if (input.value.length < min_characters ) { 
    if (input.length < min_characters ) { 
        return;
    } else { 

        // abort any pending requests
        window.hinterXHR.abort();

        window.hinterXHR.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {

                // We're expecting a json response so we convert it to an object
                var response = JSON.parse( this.responseText ); 

                // clear any previously loaded options in the datalist
                huge_list.innerHTML = "";

					 for (var i = 0; i < response.institutions.length; i++) {
						 
						 var option = document.createElement('option');
						 option.value = response.institutions[i].bankName;
						 huge_list.appendChild(option);
						 
					 }

            }
        };

//         window.hinterXHR.open("GET", "ajax/institutions.asp?cmd=search&query=" + input.value, true);
        window.hinterXHR.open("GET", "ajax/institutions.asp?cmd=search&query=" + input, true);
        window.hinterXHR.send()
    }
}




var request = null;




/*****************************************************************************************/
function AddCustomer_onSave(elemDialog) {
/*****************************************************************************************/
	
	var customerID 		= document.getElementById('form_customerID').value;
	var institutionInd 	= document.getElementById('fdic').checked;
	
	if (institutionInd) {
				
		// get the state from the end of the input by finding the last comma...
		var institutionFullName 	= document.getElementById('institutionsList').value;		
		var indexOfLastComma 		= institutionFullName.lastIndexOf(",");
		var lengthOfFullName 		= institutionFullName.length;
		var stateAbbr 					= institutionFullName.substring(indexOfLastComma+2, lengthOfFullName);
		
		// get the city by getting the last hyphen from what's left when you remove the last comma and state...
		var institutionNameAndCity = institutionFullName.substring(0, indexOfLastComma);
		var indexOfLastHyphen 		= institutionNameAndCity.lastIndexOf('-');
		var lengthOfNameAndCity 	= institutionNameAndCity.length;
		var cityName 					= institutionNameAndCity.substring(indexOfLastHyphen+2, lengthOfNameAndCity);
		
		// get the institution name from what's left when you remove last hyphen and city...
		var instName 					= institutionNameAndCity.substring(0, indexOfLastHyphen-1);
		
		var customerStatusID 		= document.getElementById("form_customerStatus").value;
		var customerNickname 		= document.getElementById("form_nickname").value;
		
		var customerValidDomains	= document.getElementById('form_validDomains').value;
		
		var lsvtCustomerName			= document.getElementById('form_lsvtCustomerName').value;
		
		var cProfitURI					= document.getElementById('form_cProfitURI').value;
		var cProfitAPIKey				= document.getElementById('form_cProfitAPIKey').value;
		

		var requestUrl = "ajax/customerMaintenance.asp?cmd=addInstitution"
															+ "&id=" 					+ customerID
															+ "&name=" 					+ encodeURIComponent(instName)
															+ "&city=" 					+ encodeURIComponent(cityName)
															+ "&state=" 				+ encodeURIComponent(stateAbbr)
															+ "&customerNickname=" 	+ encodeURIComponent(customerNickname)
															+ "&customerStatusID=" 	+ encodeURIComponent(customerStatusID)
															+ "&validDomains=" 		+ encodeURIComponent(customerValidDomains)
															+ "&lsvtCustomerName="	+ encodeURIComponent(lsvtCustomerName)
															+ "&cProfitURI=" 			+ encodeURIComponent(cProfitURI)
															+ "&cProfitAPIKey=" 		+ encodeURIComponent(cProfitAPIKey)
															+ "&defaultTimezone=" 	+ encodeURIComponent(defaultTimezone);
		
	} else {

		var customerName 				= document.getElementById("form_customerName").value;
		var customerStatusID 		= document.getElementById("form_customerStatus").value;
		var customerNickname 		= document.getElementById("form_nickname").value;
		var customerValidDomains	= document.getElementById('form_validDomains').value;

		var requestUrl = "ajax/customerMaintenance.asp?cmd=addNonInstitution"
															+ "&id=" 					+ customerID
															+ "&name=" 					+ encodeURIComponent(customerName)
															+ "&customerNickname=" 	+ encodeURIComponent(customerNickname)
															+ "&customerStatusID=" 	+ encodeURIComponent(customerStatusID)
															+ "&validDomains=" 		+ encodeURIComponent(customerValidDomains)
															+ "&lsvtCustomerName="	+ encodeURIComponent(lsvtCustomerName)
															+ "&defaultTimezone=" 	+ encodeURIComponent(defaultTimezone);
				
	}
	
	console.log(requestUrl);	
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addCustomer;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addCustomer() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_adddCustomer(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_adddCustomer(urNode) {
/*****************************************************************************************/

	var id 						= GetInnerText(urNode.getElementsByTagName('id')[0]);
	var name 					= GetInnerText(urNode.getElementsByTagName('name')[0]);
	var customerStatusID		= GetInnerText(urNode.getElementsByTagName('customerStatusID')[0]);
	var nickName				= GetInnerText(urNode.getElementsByTagName('nickName')[0]);
	var deleted					= GetInnerText(urNode.getElementsByTagName('deleted')[0]);
	var msg						= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	if (msg == 'Customer already exists') {
		if (deleted = '1') {
			alert("Customer already exists but is logically deleted.\n\nContact your system administrator to resolve this issue.\n\n");
			return false;
		} else {
			alert("Customer already exists");
			return false;
		}
		
	}

	location = location;

	

}



/*****************************************************************************************/
function CustomerAdd_onClick () {
/*****************************************************************************************/
	
	document.getElementById('formTitle').innerHTML 				= 'New Customer';
	
	document.getElementById('form_customerName').value 		= '';	
	document.getElementById('form_customerID').value 			= '';
	document.getElementById('form_nickname').value				= '';
	document.getElementById('form_validDomains').value			= '';
	document.getElementById('form_lsvtCustomerName').value	= '';
	
	var fdicSelectors = document.getElementsByName('fdicInd');
	for (i = 0; i < fdicSelectors.length; ++i) {
		fdicSelectors[i].checked = false;
	}

	var customerNameElem = document.getElementById("form_customerName");
	customerNameElem.parentNode.classList.remove('is-dirty');
	customerNameElem.parentNode.style.display = 'none';
	
	var institutionsElem = document.getElementById('institutionsGroup');
	institutionsElem.style.display = 'none';
	
	var customerStatusElem = document.getElementById('form_customerStatus');
	customerStatusElem.parentNode.style.display = 'none'
	
	var nicknameElem = document.getElementById('form_nickname');
	nicknameElem.parentNode.style.display = 'none';
	
	var selectStatus = document.getElementById("form_customerStatus");
	SelectOptionByValue( selectStatus, "" );
	var parentStatus = document.getElementById("form_customerStatus").parentElement;
	parentStatus.classList.remove('is-dirty');


	document.getElementById('optOutOfMCCCalls').parentNode.MaterialCheckbox.uncheck();
	
	
	dialog_addCustomer.showModal();
	
}


	
/*****************************************************************************************/
function CustomerEdit_onClick (htmlNode) {
/*****************************************************************************************/
	
	document.getElementById("formTitle").innerHTML = "Edit Customer";
	var customerID = htmlNode.getAttribute("data-val");
	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=query&id=" + customerID;
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_editCustomer;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_editCustomer() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_editCustomer(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_editCustomer(urNode) {
/*****************************************************************************************/

	var id 						= GetInnerText(urNode.getElementsByTagName('id')[0]);
	var cert 					= GetInnerText(urNode.getElementsByTagName('cert')[0]);
	var rssdid 					= GetInnerText(urNode.getElementsByTagName('rssdid')[0]);
	var name 					= GetInnerText(urNode.getElementsByTagName('name')[0]);
	var customerStatusID		= GetInnerText(urNode.getElementsByTagName('customerStatusID')[0]);
	var deleted 				= GetInnerText(urNode.getElementsByTagName('deleted')[0]);
	var statusName 			= GetInnerText(urNode.getElementsByTagName('statusName')[0]);
	var msg 						= GetInnerText(urNode.getElementsByTagName('msg')[0]);

	document.getElementById("form_customerName").value 		= name;	
	var parentCustomerName = document.getElementById("form_customerName").parentElement;
	parentCustomerName.classList.add('is-dirty');
	
	document.getElementById("form_customerRSSDID").value 		= rssdid;
	var parentRSSDID = document.getElementById("form_customerRSSDID").parentElement;
	parentRSSDID.classList.add('is-dirty');

	var selectStatus = document.getElementById("form_customerStatus");
	SelectOptionByValue( selectStatus, customerStatusID );
	var parentStatus = document.getElementById("form_customerStatus").parentElement;
	parentStatus.classList.add('is-dirty');
	
	document.getElementById("form_customerID").value = id;
	
	dialog_addCustomer.showModal();
	
}





/*****************************************************************************************/
function CustomerDelete_onClick(htmlElement) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this customer?\n\nThis can only be undone by a system administrator.\n\n')) {

		var attributeName 	= htmlElement.name;
		var customerID			= htmlElement.getAttribute('data-val');
		
		var requestUrl 	= "ajax/customerMaintenance.asp?cmd=delete&customer=" + customerID;

		console.log(requestUrl);
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_customerDelete;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}

	}
	
}


/*****************************************************************************************/
function StateChangeHandler_customerDelete() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			customerDelete_status(request.responseXML);
		} else {
			alert("problem retrieving data from the server, status code: "  + request.status);
		}
	}

}


/*****************************************************************************************/
function customerDelete_status(urNode) {
/*****************************************************************************************/

// 	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var msg = "Customer deleted";
	var status = GetInnerText(urNode.getElementsByTagName('status')[0]);
	
// 	if(urNode.getElementsByTagName('deleted').length > 0) {
// 		var id = urNode.getElementsByTagName('customer')[0].id;
// 		
// 		if(GetInnerText(urNode.getElementsByTagName('deleted')[0]) == "False") {
// 			document.getElementById('imgDeleted-'+id).src = '/images/ic_delete_black_24dp_1x.png';
// 		} else {
// 			document.getElementById('imgDeleted-'+id).src = '/images/ic_delete_forever_black_24dp_1x.png';			
// 		}
// 	}
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	)
	
	location = location; 

}


/*****************************************************************************************/
function captureCustomerStatusID_onchange(selectElement) {
/*****************************************************************************************/	
	
	document.getElementById('customerStatusID').value = selectElement.getAttribute('data-val');
	
}


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	if (node) {
		return (node.textContent || node.innerText || node.text);
	}

}


/*****************************************************************************************/
function SelectOptionByValue( elem, value ) {
/*****************************************************************************************/

	var opt, i = 0;	
	while( opt = elem.options[i++] ) {
		if ( opt.value == value ) {
			opt.selected = true;
			return;
		}
	}

}


//-- ------------------------------------------------------------------ -->
function generateErrorResponse(message) {
//-- ------------------------------------------------------------------ -->

	return {
		status : 'error',
		message
	};

}


