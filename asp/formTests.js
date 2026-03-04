//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

window.onload = GetInstitutions();



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
function GetInstitutions() {
/*****************************************************************************************/

	var requestUrl 	= "ajax/institutions.asp?cmd=searchAll";
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_searchAllInstitutions;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_searchAllInstitutions() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_searchInstitutions(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
		

}


/*****************************************************************************************/
function UpdateDataList(htmlNode) {
/*****************************************************************************************/

	var searchString = htmlNode.value;
	const min_characters = 0;
	
	if (searchString.length < min_characters) {
		
		return;
		
	} else {
	
		var requestUrl 	= "ajax/institutions.asp?cmd=search&query=" + searchString;
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_searchInstitutions;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_searchInstitutions() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					Complete_searchInstitutions(request.responseText);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
		
	}

}


/*****************************************************************************************/
function Complete_searchInstitutions(json) {
/*****************************************************************************************/
	
	var searchResults = JSON.parse(json);
	var dataList = document.getElementById('institutionsList');
	
// dataList.innerHTML = "";
	while (dataList.firstChild) {
		dataList.removeChild(dataList.firstChild);
	}	
	
	for (var i = 0; i < searchResults.institutions.length; i++) {
	
		var option = document.createElement('option');
		option.value = searchResults.institutions[i].fed_rssd;
		option.innerHTML = searchResults.institutions[i].bankName;
		dataList.appendChild(option);
	
	}

	
}	


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}
