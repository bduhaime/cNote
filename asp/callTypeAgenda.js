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
function ToggleIncludeWithEmails_onClick(htmlElement) {
/*****************************************************************************************/
	

	var noteTypeID = htmlElement.getAttribute('data-val');

	var requestUrl 	= 'ajax/customerCalls.asp?cmd=toggleIncludeWithEmails' 
												+ "&noteTypeID=" + noteTypeID;
												
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
				Complete_ToggleIncludeWithEmails(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
	
}


/*****************************************************************************************/
function Complete_ToggleIncludeWithEmails(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}









/*****************************************************************************************/
function EditCallTypeAgenda_onClick(htmlElement) {
/*****************************************************************************************/
	
	var edit_noteTypeID = htmlElement.getAttribute('data-val');
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;
	
	var edit_noteTypeName = currTableRow.children[0].innerHTML;
	var edit_noteTypeDesc = currTableRow.children[1].innerHTML;
	
	document.getElementById('add_ntName').value = edit_noteTypeName;
	document.getElementById('add_ntName').parentElement.classList.add('is-dirty');

	document.getElementById('add_ntDesc').value = edit_noteTypeDesc;
	document.getElementById('add_ntDesc').parentElement.classList.add('is-dirty');
	
	document.getElementById('add_noteTypeID').value = edit_noteTypeID;
	document.getElementById('add_noteTypeID').parentElement.classList.add('is-dirty');

	dialog_addCTA.showModal();
	
// 	return false;
	
}


/*****************************************************************************************/
function UpdateCopy_onClick(htmlNode,type,callTypeID) {
/*****************************************************************************************/

	var noteTypeID 					= htmlNode.getAttribute("data-val");
	var utopiaRadioButton 			= document.getElementById('copyUtopia-' + noteTypeID);
	var kiRadioButton 	= document.getElementById('copyKI-' + noteTypeID);
	var projectRadioButton 			= document.getElementById('copyProject-' + noteTypeID);
	
	var cmdDirective, newState; 
	
	if (htmlNode.classList.contains('is-checked')) {
		htmlNode.classList.remove('is-checked');
		htmlNode.checked = false;
		newState  = '0';
	} else {
		htmlNode.classList.add('is-checked');
		htmlNode.checked = true;
		newState = '1';
	}
	
	if (type == 'utopias') {
		
		cmdDirective = 'updateCopyUtopia';
		kiRadioButton.checked 		= false;
		projectRadioButton.checked = false;

	} else if (type == 'kis') {


		cmdDirective = 'updateCopyKeyInitiatives';
		utopiaRadioButton.checked 	= false;
		projectRadioButton.checked = false;

	} else {

		cmdDirective = 'updateCopyProject';
		utopiaRadioButton.checked 	= false;
		kiRadioButton.checked 		= false;
		
	}
	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=" + cmdDirective 
												+ "&noteTypeID=" 	+ noteTypeID
												+ "&callTypeID=" 	+ callTypeID
												+ "&newState=" 	+ newState;
												
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdateUtopia;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_UpdateUtopia() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_UpdateUtopia(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_UpdateUtopia(urNode) {
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
function UpdateSequence_onBlur(htmlElement) {
/*****************************************************************************************/

	var noteTypeID = htmlElement.getAttribute("data-val");
	var seq			= htmlElement.value;
	
	var requestUrl	= "ajax/customerCalls.asp?cmd=updateAgendaSeq"
											+ "&noteTypeID=" + noteTypeID
											+ "&seq=" + seq;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdateSequence;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_UpdateSequence() {
	
		if(request.readyState == 4) {
// 		if(request.status == 200 || 0) {
			if(request.status == 200) {
				location = location;
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
}

/*****************************************************************************************/
function AddCTA_onSave(dialog) {
/*****************************************************************************************/


	var itemName 		= document.getElementById('add_ntName').value;
	var itemDesc 		= document.getElementById('add_ntDesc').value;
	var callTypeID 	= document.getElementById('add_callTypeID').value;
	var noteTypeID 	= document.getElementById('add_noteTypeID').value;
	
	var requestUrl	= "ajax/customerCalls.asp?cmd=addNoteType"
											+ "&callTypeID=" + callTypeID 
											+ "&noteTypeID=" + noteTypeID 
											+ "&itemName=" + encodeURIComponent(itemName)
											+ "&itemDesc=" + encodeURIComponent(itemDesc);
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addCTA;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addCTA() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {
// 			if(request.status == 200) {
				location = location;
// 				Notify_addCTA(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
	location = location;	
	
}


/*****************************************************************************************/
function Notify_addCTA(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}




/*****************************************************************************************/
function AddCCT_onSave(dialog) {
/*****************************************************************************************/

	var cctName = document.getElementById('add_cctName').value;
	var cctDesc = document.getElementById('add_cctDesc').value;
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=addCustomerCallType"
											+ "&name=" + cctName
											+ "&desc=" + cctDesc;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addCCT;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addCCT() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || 0) {
				location = location;
				Notify_addCCT(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
// 	location = location;
	
}


/*****************************************************************************************/
function cctDelete_onClick(htmlElement) {
/*****************************************************************************************/

	var cctID = htmlElement.getAttribute('data-val');
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=delCustomerCallType"
											+ "&id=" + cctID;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_deleteCCT;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_deleteCCT() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Notify_deleteCCT()(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
	location = location;
	
}


/*****************************************************************************************/
function Notify_addCCT(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

}



/*****************************************************************************************/
function Notify_deleteCCT(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
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



