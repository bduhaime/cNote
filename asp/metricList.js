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
function EditMetric_onSave(htmlDialog) {
/*****************************************************************************************/

		
	var metricID 				= htmlDialog.querySelector('#metricID').value;
	var metricName 			= htmlDialog.querySelector('#metricName').value;
	var ubprSection 			= htmlDialog.querySelector('#ubprSection').value;
	var ubprLine 				= htmlDialog.querySelector('#ubprLine').value;
	var financialCtgy 		= htmlDialog.querySelector('#financialCtgy').value;
	var ranksColumnName 		= htmlDialog.querySelector('#ranksColumnName').value;
	var ratiosColumnName 	= htmlDialog.querySelector('#ratiosColumnName').value;
	var statsColumnName 		= htmlDialog.querySelector('#statsColumnName').value;
	var sourceTableNameRoot = htmlDialog.querySelector('#sourceTableNameRoot').value;
	var dataType 				= htmlDialog.querySelector('#dataType').value;
	var displayUnitsLabel 	= htmlDialog.querySelector('#displayUnitsLabel').value;
	var annualChangeColumn 	= htmlDialog.querySelector('#annualChangeColumn').value;
	
	var requestUrl 	= "ajax/metricMaintenance.asp?cmd=adminUpdateMetric"
											+ "&metricID=" 				+ metricID
											+ "&metricName=" 				+ encodeURIComponent(metricName)
											+ "&ubprSection=" 			+ encodeURIComponent(ubprSection)
											+ "&ubprLine=" 				+ encodeURIComponent(ubprLine)
											+ "&financialCtgy=" 			+ encodeURIComponent(financialCtgy)
											+ "&ranksColumnName=" 		+ encodeURIComponent(ranksColumnName)
											+ "&ratiosColumnName=" 		+ encodeURIComponent(ratiosColumnName)
											+ "&statsColumnName=" 		+ encodeURIComponent(statsColumnName)
											+ "&sourceTableNameRoot=" 	+ encodeURIComponent(sourceTableNameRoot)
											+ "&dataType=" 				+ encodeURIComponent(dataType)
											+ "&displayUnitsLabel=" 	+ encodeURIComponent(displayUnitsLabel)
											+ "&annualChangeColumn=" 	+ encodeURIComponent(annualChangeColumn);
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_editMetric;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_editMetric() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {

				ShowSnackbarMessage(request.responseXML);
// 				htmlDialog.close();				
				location = location;

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}



/*****************************************************************************************/
function ShowSnackbarMessage(xml) {
/*****************************************************************************************/

	var msg = xml.getElementsByTagName('msg')[0].textContent;
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar({
		message: msg
	});
	

}
