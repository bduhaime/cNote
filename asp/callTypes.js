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
function EditCallType_onClick(htmlElement) {
/*****************************************************************************************/
	
	var rowID = htmlElement.closest('tr').id;

	var edit_callTypeID = htmlElement.getAttribute('data-val');
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;

	const table = $('#tbl_customers').DataTable();
	const row = '#'+rowID;
	
	const edit_CallTypeName 			= currTableRow.children[0].innerHTML;
	const edit_callTypeDesc 			= currTableRow.children[1].innerHTML;
	const edit_idealFrequencyDays 	= currTableRow.children[2].innerHTML;
	const edit_shortName 				= currTableRow.children[3].innerHTML;
	const edit_weight	 					= currTableRow.children[4].innerHTML;
	const requiredForNewCustomers		= currTableRow.children[5].innerHTML;
	
	document.getElementById('add_cctName').value = edit_CallTypeName;
	document.getElementById('add_cctName').parentElement.classList.add('is-dirty');

	document.getElementById('add_cctDesc').value = edit_callTypeDesc;
	document.getElementById('add_cctDesc').parentElement.classList.add('is-dirty');
	
	document.getElementById('add_idealFrequencyDays').value = edit_idealFrequencyDays;
	document.getElementById('add_idealFrequencyDays').parentElement.classList.add('is-dirty');
	
	document.getElementById('add_shortName').value = edit_shortName;
	document.getElementById('add_shortName').parentElement.classList.add('is-dirty');
	
	document.getElementById('add_weight').value = edit_weight;
	document.getElementById('add_weight').parentElement.classList.add('is-dirty');
	
	document.getElementById('callTypeID').value = edit_callTypeID;

	document.getElementById('dialogTitle').innerHTML = 'Edit Call Type';
	
	if ( requiredForNewCustomers ) {
		document.getElementById('requiredForNewCustomers').parentNode.MaterialCheckbox.check();
	} else {
		document.getElementById('requiredForNewCustomers').parentNode.MaterialCheckbox.uncheck();
	}


	
	
	dialog_addCCT.showModal();
	
// 	return false;
	
}


/*****************************************************************************************/
function AddCCT_onSave(dialog) {
/*****************************************************************************************/

	var cctID		= document.getElementById('callTypeID').value;
	var cctName 	= document.getElementById('add_cctName').value;
	var cctDesc 	= document.getElementById('add_cctDesc').value;
	var cctFreq 	= document.getElementById('add_idealFrequencyDays').value;
	var cctShort	= document.getElementById('add_shortName').value;
	var cctWeight	= document.getElementById('add_weight').value;

	const required = $( '#requiredForNewCustomers' ).is( ':checked' ) ? 1 : 0;

	var requestUrl 	= "ajax/customerCalls.asp?cmd=addCustomerCallType"
											+ "&id=" + encodeURIComponent(cctID)
											+ "&name=" + encodeURIComponent(cctName)
											+ "&desc=" + encodeURIComponent(cctDesc)
											+ "&freq=" + cctFreq
											+ "&short=" + encodeURIComponent(cctShort)
											+ "&weight=" + cctWeight
											+ "&required=" + required;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addCCT;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_addCCT() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {
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



