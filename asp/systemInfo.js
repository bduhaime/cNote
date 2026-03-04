//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

function createRequest() {

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
function ToggleDbug_onClick(attributeNode) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/systemControls.asp?cmd=toggle&control=dbug";
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_dbug;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_dbug() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Status_dbug(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}




/*****************************************************************************************/
function Status_dbug(urNode) {
/*****************************************************************************************/

	var msg 					= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var control 			= GetInnerText(urNode.getElementsByTagName('control')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}



/*****************************************************************************************/
function ToggleFooter_onClick(attributeNode) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/systemControls.asp?cmd=toggle&control=showFooter";
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_footer;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_footer() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Status_footer(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function ToggleLSVT_onClick(attributeNode) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/systemControls.asp?cmd=toggle&control=toggleLSVT";
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_footer;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_footer() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Status_footer(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function ToggleEmail_onClick(attributeNode) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/systemControls.asp?cmd=toggle&control=sendEmail";
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_email;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_email() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				location = location
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}




/*****************************************************************************************/
function Status_footer(urNode) {
/*****************************************************************************************/

	location = location;
	
}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}


/*****************************************************************************************/
let nodeInfoLoaded = false;

/*****************************************************************************************/
function loadNodeInfoIntoTab() {
/*****************************************************************************************/

	// If you want it to refresh every click, delete these 2 lines.
	if ( nodeInfoLoaded ) return;
	nodeInfoLoaded = true;

	const container = document.getElementById( 'fixed-tab-nodejs' );
	if ( !container ) return;

	container.innerHTML = 'Loading Node.js info...';

	const req = new XMLHttpRequest();
	req.onreadystatechange = function () {
		if ( req.readyState !== 4 ) return;

		if ( req.status !== 200 ) {
			container.innerHTML = 'Error loading Node.js info (HTTP ' + req.status + ')';
			return;
		}

		let info;
		try {
			info = JSON.parse( req.responseText );
		} catch ( e ) {
			container.innerHTML = 'Error parsing server response';
			return;
		}

		// Render it nicely
		const summaryHtml =
			'<div style="padding:12px;">' +
				'<h5 style="margin:0 0 10px 0;">Node.js runtime</h5>' +
		
				'<div><b>Node:</b> ' + escapeHtml( info.nodeVersion ) + '</div>' +
				'<div><b>Platform:</b> ' + escapeHtml( info.platform ) + ' (' + escapeHtml( info.arch ) + ')</div>' +
				'<div><b>Exec path:</b> ' + escapeHtml( info.execPath ) + '</div>' +
				'<div><b>CWD:</b> ' + escapeHtml( info.cwd ) + '</div>' +
				'<div><b>PID:</b> ' + escapeHtml( String( info.pid ) ) + '</div>' +
		
				'<details style="margin-top:12px;">' +
					'<summary style="cursor:pointer;">Show process.versions</summary>' +
					'<pre style="white-space:pre-wrap; margin-top:8px;">' +
						escapeHtml( JSON.stringify( info.nodeVersions, null, 2 ) ) +
					'</pre>' +
				'</details>' +
			'</div>';
		
		container.innerHTML = summaryHtml;
		
	};

	// Adjust this path if your site is mounted differently
	req.open( 'GET', `${apiServer}/api/systemInfo/nodeInfo`, true );
	req.setRequestHeader( 'Authorization', 'Bearer ' + sessionJWT );
	req.send( null );
}
/*****************************************************************************************/


/*****************************************************************************************/
function escapeHtml( s ) {
/*****************************************************************************************/

	return String( s )
		.replace( /&/g, '&amp;' )
		.replace( /</g, '&lt;' )
		.replace( />/g, '&gt;' )
		.replace( /"/g, '&quot;' )
		.replace( /'/g, '&#039;' );

}
/*****************************************************************************************/


/*****************************************************************************************/
// Hook the tab click
window.addEventListener( 'load', function () {
/*****************************************************************************************/
	// MDL tabs: the clickable tab is usually an <a href="#fixed-tab-nodejs">
	const tabLink = document.querySelector( 'a[href="#fixed-tab-nodejs"]' );
	if ( tabLink ) {
		tabLink.addEventListener( 'click', loadNodeInfoIntoTab );
	}

	// Optional: also load if the user lands on that tab via hash
	if ( window.location.hash === '#fixed-tab-nodejs' ) {
		loadNodeInfoIntoTab();
	}
});
/*****************************************************************************************/

