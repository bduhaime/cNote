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
function ToggleDeleteIcon(htmlElement) {
/*****************************************************************************************/
	
	var projectID		= htmlElement.getAttribute('data-val');
	var deleteIcon 	= document.getElementById('project-'+projectID);
	
	if (deleteIcon.style.display == 'none') {
		deleteIcon.style.display = 'inline-block';
	} else { 
		deleteIcon.style.display = 'none';
	}
	
}


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}



