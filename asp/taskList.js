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
function ToggleActionIcons( htmlElement ) {
/*****************************************************************************************/
	
	const actionIcon = htmlElement.querySelector( 'td.actions > i' );
	
	if ( actionIcon ) {

		const currentVisibility = actionIcon.style.visibility;
		
		if ( currentVisibility == 'visible' ) {
			actionIcon.style.visibility = 'hidden';
		} else {
			actionIcon.style.visibility = 'visible';		
		}
	
	}
	
	
}

/*****************************************************************************************/
function OpenUpdateStatusDialog(htmlElement) {
/*****************************************************************************************/
	
	updateStatusDialog.style.width = '600px';
	updateStatusDialog.showModal();
	
	var projectID = htmlElement.getAttribute('data-projectID');


	var requestUrl 	= "ajax/projectMaintenance.asp?cmd=getProjectStatusAndPermissions"
															+ "&projectID=" + projectID 

// 	console.log(requestUrl);
																
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_getProjectStatus;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_getProjectStatus() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_getProjectStatus(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}


/*****************************************************************************************/
function Complete_getProjectStatus(xml) {
/*****************************************************************************************/

	const projectID			 	= xml.getElementsByTagName('projectID')[0].textContent;
	document.getElementById('projectID').value = projectID;
	
	

	var ontimeState		 		= xml.getElementsByTagName('ontimeState')[0].textContent;
	var escalateState		 		= xml.getElementsByTagName('escalateState')[0].textContent;
	var rescheduleState	 		= xml.getElementsByTagName('rescheduleState')[0].textContent;
	var completeState		 		= xml.getElementsByTagName('completeState')[0].textContent;

	var projectCompletable 		= xml.getElementsByTagName('projectCompletable')[0].textContent;
	var projectUncompletable 	= xml.getElementsByTagName('projectUncompletable')[0].textContent;
	var msg							= xml.getElementsByTagName('msg')[0].textContent;
	
	
	
	
	var completeOption			= document.getElementById('statusType_complete');
	var completableInfo			= document.getElementById('completableInfo');
	
// 	if (projectCompletable) {
// 		if (projectCompletable == 'True') {
// 			completeOption.parentElement.MaterialRadio.enable();
// 		} else {
// 			completeOption.parentElement.MaterialRadio.disable();
// 		}
// 	}
	
// 	completableInfo.setAttribute('title', msg);
	

	if (ontimeState == 'enabled') {
		document.getElementById('statusType_onTime').parentNode.MaterialRadio.enable();
	} else {
		document.getElementById('statusType_onTime').parentNode.MaterialRadio.disable();
	}
	
	if (escalateState == 'enabled') {
		document.getElementById('statusType_escalate').parentNode.MaterialRadio.enable();
	} else {
		document.getElementById('statusType_escalate').parentNode.MaterialRadio.disable();
	}
	
	if (rescheduleState == 'enabled') {
		document.getElementById('statusType_reschedule').parentNode.MaterialRadio.enable();
	} else {
		document.getElementById('statusType_reschedule').parentNode.MaterialRadio.disable();
	}
	
	if (completeState == 'enabled') {
		document.getElementById('statusType_complete').parentNode.MaterialRadio.enable();
	} else {
		document.getElementById('statusType_complete').parentNode.MaterialRadio.disable();		
	}
	
	completableInfo.setAttribute('title', msg);


	if (projectUncompletable == 'True') {
		
		document.getElementById('statusType_onTime').parentNode.classList.remove('is-disabled');
		document.getElementById('statusType_onTime').disabled = false;
		
		document.getElementById('statusType_escalate').parentNode.classList.remove('is-disabled');
		document.getElementById('statusType_escalate').disabled = false;
		
		document.getElementById('statusType_reschedule').parentNode.classList.remove('is-disabled');
		document.getElementById('statusType_reschedule').disabled = false;

		document.getElementById('projectStatusDate').parentNode.classList.remove('is-disabled');
		document.getElementById('projectStatusDate').disabled = false; 
		
	} else {
		
		document.getElementById('statusType_onTime').parentNode.classList.add('is-disabled');
		document.getElementById('statusType_onTime').disabled = true;
		
		document.getElementById('statusType_escalate').parentNode.classList.add('is-disabled');
		document.getElementById('statusType_escalate').disabled = true;;

		document.getElementById('statusType_reschedule').parentNode.classList.add('is-disabled');
		document.getElementById('statusType_reschedule').disabled = true;

		document.getElementById('projectStatusDate').parentNode.classList.add('is-disabled');
		document.getElementById('projectStatusDate').disabled = true;

	}
	
	var statusDateElem = document.getElementById('projectStatusDate');
	
	statusDateElem.value = moment().format('YYYY-MM-DD');
	statusDateElem.parentNode.classList.add('is-dirty');
	

}



/*****************************************************************************************/
function TaskStartDate_onBlur(htmlElement) {
/*****************************************************************************************/

// this function defaults the task end date to 30 days after the start date or the project
// endDate, which ever is sooner.

	if (htmlElement.value) {
	
		var dString 			= htmlElement.value;
		var projectEndDate 	= document.getElementById('projectEndDate').value;
		var defaultDueDate;
		
		if (dString) {
			
			if (!moment(dString).isValid()) {
			
				alert('Start date is not a valid date');
				return false;
			
			} else {
				
				if(moment(dString).add(30, 'd').isAfter(projectEndDate)) {
					defaultDueDate = projectEndDate;
				} else {
					defaultDueDate = moment(dString).add(30, 'd');
				}
				
				
				
				
			} 
	
		}
		
		var dueDateElement = document.getElementById('dueDate');
		dueDateElement.setAttribute('min', moment(dString).format('YYYY-MM-DD'));
		dueDateElement.value = moment(defaultDueDate).format('YYYY-MM-DD');
		dueDateElement.parentNode.classList.remove('is-invalid');
			
	}
	
}


/*****************************************************************************************/
function TaskDueDate_onBlur(htmlElement) {
/*****************************************************************************************/

// this function set the max attribute of the startDate to the new dueDate value.

	var dString 			= htmlElement.value;
	var projectStartDate 	= document.getElementById('projectStartDate').value;
	
	
	if (dString) {
		
		if (!moment(dString).isValid()) {
			
			alert('Due date is not a valid date');
			htmlElement.parentNode.classList.add('is-invalid');
			
		} else {
			
			htmlElement.parentNode.classList.remove('is-invalid');
			var startDateElement = document.getElementById('startDate');
			startDateElement.setAttribute('max', moment(dString).format('YYYY-MM-DD'));
			
		}
		
	}
	
	
}



/*****************************************************************************************/
function formatDate(date) {
/*****************************************************************************************/

    var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join('-');

}



/*****************************************************************************************/
function UpdateStatus_onOkay(dialog) {
/*****************************************************************************************/

	$( '.statusType' ).parent().css( 'color', '' );

	let projectStatusType;

	switch ( true ) {
		
		case $( '#statusType_onTime' ).is( ':checked' ):
			projectStatusType = 'On Time';
			break;
			
		case $( '#statusType_escalate' ).is( ':checked' ):
			projectStatusType = 'Escalate';
			break;
			
		case $( '#statusType_reschedule' ).is( ':checked' ):
			projectStatusType = 'Reschedule';
			break;
			
		case $( '#statusType_complete' ).is( ':checked' ):
			projectStatusType = 'Complete'
			break;

		default:
			$( '.statusType' ).parent().css( 'color', 'crimson' );
			alert( 'Project status required' );
			return false;
	}
	
	
	const projectStatusDate = $( '#projectStatusDate' ).val();
	if ( !moment( projectStatusDate ).isValid() ) {
		alert( 'Project status date is not valid' );
		$( '#projectStatusDate' ).focus().parent().addClass( 'is-invalid is dirty' );
		return false;
	} else { 
		if ( moment( projectStatusDate ).isAfter( moment() ) ) {
			alert( 'Project status date cannot be in the future' );
			$( '#projectStatusDate' ).focus().parent().addClass( 'is-invalid is dirty' );
			return false;
		}
	}
	
	const projectStatusComments = $( '#projectStatusComments' ).val();
	const data = {
		projectID: $( '#projectID' ).val(), 
		projectStatusDate: projectStatusDate,
		projectStatusComments: projectStatusComments,
		projectStatusType: projectStatusType
	}
	
	$.ajax({
		type: 'PUT',
		data: data,
		url: `${apiServer}/api/projects/updateStatus`,
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
	}).done( function () {



		$( '#projectStatusComments' ).val( '' );
	
		let statusMessage;
		
		if (projectStatusType == "On Time") {
			statusMessage = "On Time as of " + projectStatusDate;
		} else if (projectStatusType == "Escalate") {
			statusMessage = "Escalation requested on " + projectStatusDate;
		} else  if (projectStatusType == "Reschedule") {
			statusMessage = "Reschedule requested on " + projectStatusDate;
		} else {
			statusMessage = "Project complete on " + projectStatusDate;
		}
		
		$( '#projectStatus' ).attr( 'title', projectStatusComments );	
		$( '#projectStatus' ).text( statusMessage );
		

		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({
			message: 'Status updated'
		});
		
		location = location;



	}).fail( function( req, status, err ) {
		alert( 'problem encountered updating project status', err );
	});
		

}

/*****************************************************************************************/
function Complete_updateStatus(urNode) {
/*****************************************************************************************/

// **** NOTE: This code needs to be kept in sync with the analogous code in taskList.asp, text displayed below the "Update Status" button

	document.getElementById('projectStatusComments').value = "";

	var statusDate 		= GetInnerText(urNode.getElementsByTagName('statusDate')[0]);
	var msg 					= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var statusType 		= GetInnerText(urNode.getElementsByTagName('projectStatusType')[0]);
	var statusComments 	= GetInnerText(urNode.getElementsByTagName('statusComments')[0]);
	var statusMessage;
	
	if (statusType == "On Time") {
		statusMessage = "On Time as of " + statusDate;
	} else if (statusType == "Escalate") {
		statusMessage = "Escalation requested on " + statusDate;
	} else  if (statusType == "Reschedule") {
		statusMessage = "Reschedule requested on " + statusDate;
	} else {
		statusMessage = "Project complete on " + statusDate;
	}
	
	document.getElementById('projectStatus').title 			= statusComments;	
	document.getElementById('projectStatus').innerText 	= statusMessage;
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}



/*****************************************************************************************/
function AddATask_onSave( dialog ) {
/*****************************************************************************************/

	const taskName 				= $( '#taskName' ).val();
	const taskDescription		= $( '#taskDescription' ).val();
	const taskOwnerID 			= $( '#taskOwnerID' ).val();
	const customerID				= $( '#customerID' ).val();
	const projectStartDate 		= $( '#projectStartDate' ).val();
	const projectEndDate 		= $( '#projectEndDate' ).val();
	const projectID				= $( '#projectID' ).val();
	
	
	const taskStartDate			= $( '#startDate' ).val();
	const taskDueDate			= $( '#dueDate' ).val();
// 	const taskStartDateString;
// 	const taskDueDateString;
debugger
	if ( !moment(taskStartDate).isValid() ) {
		alert( 'Start date is missing or invalid' );
		return false;
	} else {
		if ( !moment(taskStartDate).isSameOrAfter(projectStartDate) ) {
			alert( 'Task cannot start before the project start date' );
			return false;
		} else {
			if ( !moment(taskStartDate).isSameOrBefore(projectEndDate) ) {
				alert( 'Task cannot end after the project end date' );
				return false;
			}
		}
	}
	
	if (!moment(taskDueDate).isValid()) {
		alert("Due date is missing or invalid");
		return false;
	} else {
		if (!moment(taskDueDate).isSameOrAfter(projectStartDate)) {
			alert('Task cannot be due before the project starts');
			return false;
		} else {
			if (!moment(taskDueDate).isSameOrBefore(projectEndDate)) {
				alert('Task cannot be due after the project ends');
				return false;
			}
		}
	}

	if ( moment(taskStartDate).isAfter(taskDueDate) )	{
		alert('Due date must be later than start date');
		return false;
	}
	
	
// 	taskDueDate 			= dialog.querySelector('#dueDate').value;
// 	taskStartDate 			= dialog.querySelector('#startDate').value;
// 	var taskProject		= dialog.querySelector('#projectID').value;
	
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=add"
														+ "&projectID=" + projectID 
														+ "&name=" + encodeURIComponent(taskName) 
														+ "&description=" + encodeURIComponent(taskDescription) 
														+ "&owner=" + taskOwnerID 
														+ "&start=" + encodeURIComponent(taskStartDate)
														+ "&due=" + encodeURIComponent(taskDueDate)
														+ "&customerID=" + customerID;

// 	console.log(requestUrl);

	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateStatus;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_updateStatus() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_addATask(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}

/*****************************************************************************************/
function Complete_addATask(urNode) {
/*****************************************************************************************/

// 	var statusDate = GetInnerText(urNode.getElementsByTagName('statusDate')[0]);
	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]) + "; refreshing page...";
	
// 	document.getElementById('projectStatus').innerText = "Updated as of " + statusDate;
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	if(status == "error") {
// 		document.getElementById('firstName').focus();
// 		document.getElementById('username').focus();
// 	}

	location = location;
}


/*****************************************************************************************/
function TaskDelete_onClick(task) {
/*****************************************************************************************/
	
	if (confirm('Are you sure you want to delete this task (this cannot be un-done)?')) {

		var projectID 		= document.getElementById('projectID').value; 
		var requestUrl 	= "ajax/taskMaintenance.asp?cmd=delete"
												+ "&task=" + task
												+ "&project=" + projectID;
												
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_taskDelete;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
		
		function StateChangeHandler_taskDelete() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					TaskDelete_status(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
		
	}

}

/*****************************************************************************************/
function TaskDelete_status(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
		
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

	location = location;

}






// is anything after this comment even used???!!!


/*****************************************************************************************/
function userAttribute_onChange(attributeNode,user) {
/*****************************************************************************************/

	var attributeName 	= attributeNode.name;
	var attributeValue
	
	if(attributeName == "customerID" || attributeName == "deleted") {
		attributeValue = attributeNode.getAttribute('data-val');
	} else {
		attributeValue 	= attributeNode.value;
	}
	
	var requestUrl 	= "ajax/userMaintenance.asp?cmd=update&user=" + user + "&attribute=" + attributeName + "&value=" + attributeValue;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_userAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function userRole_onClick(user,role) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=role&user=" + user + "&role=" + role;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_userAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function userPermission_onClick(user,permission) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=permission&user=" + user + "&permission=" + permission;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_userAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function rolePermission_onClick(role,permission) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=rolePermission&role=" + role + "&permission=" + permission;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_userAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
function userCompany_onClick(attributeNode,user) {
/*****************************************************************************************/

	var requestUrl;
	requestUrl = "ajax/userMaintenance.asp?cmd=update&attribute=permission&user=" + user + "&permission=" + permission;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_userAttribute;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

}


/*****************************************************************************************/
//
// used for all attributes related to the "users" table; toasts the user
//
/*****************************************************************************************/
function StateChangeHandler_userAttribute() {
/*****************************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			userAttribute_status(request.responseXML);
		} else {
			alert("problem retrieving data from the server, status code: "  + request.status);
		}
	}

}



/*****************************************************************************************/
function uniqueUser_status(unNode) {
/*****************************************************************************************/

	var username = unNode.getElementsByTagName('username')[0].getAttribute('value');
	var feedback = GetInnerText(unNode.getElementsByTagName('username')[0]);
	
	if(feedback == "duplicate") {

		var usernameField = document.getElementById('username');

		alert("The user name '" + username + "' is already in use.");
		usernameField.value = "";
		document.getElementById('firstName').focus();
		usernameField.focus();
		
	}
	
}


/*****************************************************************************************/
//
// this produces an MDL "toast" component (i.e. there is no action)
//
/*****************************************************************************************/
function userAttribute_status(urNode) {
/*****************************************************************************************/

	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	var status = GetInnerText(urNode.getElementsByTagName('status')[0]);
	
	if(urNode.getElementsByTagName('deleted').length > 0) {
		var userID = urNode.getElementsByTagName('user')[0].id;
		var rowID = document.getElementById('deleted-'+userID);
		var imageToToggle = document.getElementById('imgDeleted-'+userID);
		
		if(GetInnerText(urNode.getElementsByTagName('deleted')[0]) == "False") {
			document.getElementById('imgDeleted-'+userID).src = '/images/ic_delete_black_24dp_1x.png';
		} else {
			document.getElementById('imgDeleted-'+userID).src = '/images/ic_delete_forever_black_24dp_1x.png';			
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


/*******************************************************************************/
function IsDate(sInput)	{
/*******************************************************************************/

	var inputDate = sInput;
	
	if (inputDate == "") {
		return true;
	} else {
		if (inputDate.toString().match(/^\d{1,2}\/\d{1,2}\/\d{2,4}$/)) {
			
			var sMonth	= inputDate.split("/")[0];
			var sDay 	= inputDate.split("/")[1];
			var sYear 	= inputDate.split("/")[2];
			
			if (sYear.length == 2) {
				sYear = "20" + sYear 
			}
			
			var oDate	= new Date(sYear, sMonth-1, sDay);
			if ((oDate.getMonth()+1 != sMonth) || (oDate.getDate() != sDay) || (oDate.getFullYear() != sYear)) {
				return false;
			} else {
				return true;
			}
		} else {
			return false;
		}
	}
}



/*******************************************************************************/
function String2Date(sInput)	{
/*******************************************************************************/

	var inputDate = sInput;
	
	var sMonth	= inputDate.split("/")[0];
	var sDay 	= inputDate.split("/")[1];
	var sYear 	= inputDate.split("/")[2];
	var oDate	= new Date(sYear, sMonth-1, sDay);
	return oDate;

}



