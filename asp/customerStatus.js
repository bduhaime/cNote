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
	
	var customerStatusID = htmlElement.getAttribute('data-val');
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;
	
	var customerStatusName = currTableRow.children[0].innerHTML;
	var customerStatusDesc = currTableRow.children[1].innerHTML;
	
	document.getElementById('customerStatusName').value = customerStatusName;
	document.getElementById('customerStatusName').parentElement.classList.add('is-dirty');

	document.getElementById('customerStatusDesc').value = customerStatusDesc;
	document.getElementById('customerStatusDesc').parentElement.classList.add('is-dirty');
	
	document.getElementById('customerStatusID').value = customerStatusID;
// 	document.getElementById('callTypeID').parentElement.classList.add('is-dirty');

	dialog_customerStatus.showModal();
	
// 	return false;
	
}


/*****************************************************************************************/
function addCustomerStatus(dialog) {
/*****************************************************************************************/

	var customerStatusID		= document.getElementById('customerStatusID').value;
	var customerStatusName 	= document.getElementById('customerStatusName').value;
	var customerStatusDesc 	= document.getElementById('customerStatusDesc').value;
	
	
	var requestUrl 	= "ajax/customerStatus.asp?cmd=maintain"
											+ "&customerStatusID=" + customerStatusID
											+ "&customerStatusName=" + encodeURIComponent(customerStatusName)
											+ "&customerStatusDesc=" + encodeURIComponent(customerStatusDesc);
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addCustomerStatus;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_addCustomerStatus() {
	
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
function cctDelete_onClick(htmlElement) {
/*****************************************************************************************/

	var cctID = htmlElement.getAttribute('data-val');
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=delCustomerCallType"
											+ "&id=" + cctID;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_deleteCCT;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_deleteCCT() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Notify_deleteCCT(request.responseXML);
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
	
	dialog_addCCT.close();

	location = location;


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



