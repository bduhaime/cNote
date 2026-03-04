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
function Submit_onClick (htmlElement) {
/*****************************************************************************************/

	var lsvtToken	= getCookie('lsvtToken');
	var command		= document.getElementById('command').value;

	var payload		= 'token=' + lsvtToken
						+ '&' + command;
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_getGdlrList;
		request.open("POST", "https://webservices.lightspeedvt.net/lsvt_api_v35.ashx", true);
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
		request.send(payload);
	}

	function StateChangeHandler_getGdlrList() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_getGdlrList(request.responseXML);
// 				Complete_getGdlrList(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}	
	
}


/*****************************************************************************************/
function Complete_getGdlrList (xml) {
/*****************************************************************************************/
	
	console.log(xml);

	alert('transaction complete');	

}


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}


/*****************************************************************************************/
function setCookie(cname, cvalue, exhours) {
/*****************************************************************************************/

	var d = new Date();
	d.setTime(d.getTime() + (exhours*60*60*1000));
	var expires = "expires="+ d.toUTCString();
	document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";

}


/*****************************************************************************************/
function getCookie(cname) {
/*****************************************************************************************/

	var name = cname + "=";
	var decodedCookie = decodeURIComponent(document.cookie);
	var ca = decodedCookie.split(';');
	for(var i = 0; i <ca.length; i++) {
		var c = ca[i];
		while (c.charAt(0) == ' ') {
		   c = c.substring(1);
		}
		if (c.indexOf(name) == 0) {
		   return c.substring(name.length, c.length);
		}
	}
	return "";

}
