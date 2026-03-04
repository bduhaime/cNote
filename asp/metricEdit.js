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
function metricAttribute_onChange(htmlNode,id) {
/*****************************************************************************************/

	var fieldToUpdate = htmlNode.name;
	var valueToUpdate = htmlNode.value;	
	
	var requestUrl 	= "ajax/metricMaintenance.asp?cmd=update&id="+id+"&attribute="+fieldToUpdate+"&value="+valueToUpdate;
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_metricDelete;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function metricDelete_onClick(attributeNode,metric) {
/*****************************************************************************************/
	
	
	if (confirm('Are you sure you want to delete this item?')) {
		var requestUrl 	= "ajax/metricMaintenance.asp?cmd=delete&metric=" + metric;
		createRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_metricDelete;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	}
}


/*****************************************************************************************/
function StateChangeHandler_metricDelete() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			metricDelete_status(request.responseXML);
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
function metricDelete_status(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var status = GetInnerText(urNode.getElementsByTagName('status')[0]);
	
	if(urNode.getElementsByTagName('deleted').length > 0) {
		var metricID = urNode.getElementsByTagName('metric')[0].id;
// 		var rowID = document.getElementById('deleted-'+metricID);
		var imageToToggle = document.getElementById('imgDeleted-'+metricID);
		
		if(GetInnerText(urNode.getElementsByTagName('deleted')[0]) == "False") {
			document.getElementById('imgDeleted-'+metricID).src = '/images/ic_delete_black_24dp_1x.png';
		} else {
			document.getElementById('imgDeleted-'+metricID).src = '/images/ic_delete_forever_black_24dp_1x.png';			
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
function metricActive_onChange(attributeNode,metric) {
/*****************************************************************************************/
	
	var requestUrl 	= "ajax/metricMaintenance.asp?cmd=active&metric=" + metric;
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_metricActive;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function StateChangeHandler_metricActive() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			metricActive_status(request.responseXML);
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
function metricActive_status(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var status = GetInnerText(urNode.getElementsByTagName('status')[0]);
	
	if(urNode.getElementsByTagName('deleted').length > 0) {
		var metricID = urNode.getElementsByTagName('metric')[0].id;
// 		var rowID = document.getElementById('deleted-'+metricID);
		var imageToToggle = document.getElementById('imgDeleted-'+metricID);
		
		if(GetInnerText(urNode.getElementsByTagName('deleted')[0]) == "False") {
			document.getElementById('imgDeleted-'+metricID).src = '/images/ic_delete_black_24dp_1x.png';
		} else {
			document.getElementById('imgDeleted-'+metricID).src = '/images/ic_delete_forever_black_24dp_1x.png';			
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
