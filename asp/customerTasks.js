//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

/*****************************************************************************************/
async function AddTaskKeyInitiative(keyInitiativeID, taskID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/taskKeyInitiatives.asp';
	const form 	= 'taskID=' + taskID
					+ '&keyInitiativeID=' + keyInitiativeID;
	
	const response = await fetch(url, {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to associate key initiative and task; response: ' + response.status);
	}
	
	var result = await response.json();
	
	// update UI here...

	
	if ( result.msg ) {
		
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});

		// toggle the "orphan" indicator on the main DataTable...
		const datatable 	= $( '#tbl_tasks' ).DataTable();
		const orphanCell 	= datatable.cell( '#'+taskID + ' td.orphan' );
		if ( result.taskIsOrphan ) {
			orphanCell.data( '<i class="material-icons">check</i>' );
		} else {
			orphanCell.data( '' );
		}

	}


}

	
/*****************************************************************************************/
async function RemoveTaskKeyInitiative(keyInitiativeID, taskID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/taskKeyInitiatives.asp';
	const form 	= 'taskID=' + taskID
					+ '&keyInitiativeID=' + keyInitiativeID;
	
	const response = await fetch(url, {
		method: 'DELETE',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to disassociate key initiative and task; response: ' + response.status);
	}
	
	var result = await response.json();
	
	// update UI here...
	
	if ( result.msg ) {
		
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});

		// toggle the "orphan" indicator on the main DataTable...
		const datatable 	= $( '#tbl_tasks' ).DataTable();
		const orphanCell 	= datatable.cell( '#'+taskID + ' td.orphan' );
		if ( result.taskIsOrphan ) {
			orphanCell.data( '<i class="material-icons">check</i>' );
		} else {
			orphanCell.data( '' );
		}

		
	}


}

	
/*****************************************************************************************/
async function AddTaskProject(customerID, projectID, taskID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/taskProjects.asp';
	const form 	= 'taskID=' + taskID
							+ '&projectID=' + projectID
							+ '&customerID=' + customerID;
	
	const response = await fetch(url, {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to associate project and task; response: ' + response.status);
	}
	
	var result = await response.json();
	
	// update UI here...
	
	if ( result.msg ) {
		const notification = document.querySelector( '.mdl-js-snackbar' );
		notification.MaterialSnackbar.showSnackbar( {message: result.msg} );
		
		if ( result.msg == 'Task added to project' ) {
			document.querySelector( '#projectsForTask_'+taskID ).setAttribute( 'data-currProjectID', projectID );
		}

		// toggle the "orphan" indicator on the main DataTable...
		const datatable 	= $( '#tbl_tasks' ).DataTable();
		const orphanCell 	= datatable.cell( '#'+taskID + ' td.orphan' );
		if ( result.taskIsOrphan ) {
			orphanCell.data( '<i class="material-icons">check</i>' );
		} else {
			orphanCell.data( '' );
		}


	}


}

	
/*****************************************************************************************/
async function RemoveTaskProject(customerID, projectID, taskID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/taskProjects.asp';
	const form 	= 'taskID=' + taskID
							+ '&projectID=' + projectID
							+ '&customerID=' + customerID;
							
	const response = await fetch(url, {
		method: 'DELETE',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to disassociate project and task; response: ' + response.status);
	}
	
	var result = await response.json();
	
	// update UI here...
	
	if ( result.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});
		
		if ( result.msg == 'Task removed from project' ) {
			document.querySelector( '#projectsForTask_'+taskID ).setAttribute('data-currProjectID', '');
		}

		// toggle the "orphan" indicator on the main DataTable...
		const datatable 	= $( '#tbl_tasks' ).DataTable();
		const orphanCell 	= datatable.cell( '#'+taskID + ' td.orphan' );
		if ( result.taskIsOrphan ) {
			orphanCell.data( '<i class="material-icons">check</i>' );
		} else {
			orphanCell.data( '' );
		}

		
	}


}




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
function StartDate_onBlur(htmlElement) {
/*****************************************************************************************/
	
	// the 'min' for the end date is the greater of the projectStartDate or the taskStartDate
	
	var startDate = htmlElement.value;
	var currMin = document.getElementById('dueDate').getAttribute('min');
	
	if (moment(startDate).isValid()) {
		if (moment(currMin).isValid()) {
			if (moment(startDate).isBefore(moment(currMin))) {
				document.getElementById('dueDate').setAttribute('min', moment(startDate).format('YYYY-MM-DD'));
			}
		} else {
			document.getElementById('dueDate').setAttribute('min', moment(startDate).format('YYYY-MM-DD'));			
		}
	}


}


/*****************************************************************************************/
function DueDate_onBlur(htmlElement) {
/*****************************************************************************************/
	
	// the 'max' for the start date is the lesser of the projectEndDate or the taskEndDate
	
	var dueDate = htmlElement.value;
	var currMax = document.getElementById('startDate').getAttribute('min');
	
	if (moment(dueDate).isValid()) {
		if (moment(currMax).isValid()) {
			if (moment(dueDate).isAfter(moment(currMax))) {
				document.getElementById('startDate').setAttribute('max', moment(dueDate).format('YYYY-MM-DD'));
			}
		} else {
			document.getElementById('startDate').setAttribute('max', moment(dueDate).format('YYYY-MM-DD'));			
		}
	}


}


/*****************************************************************************************/
function AddTask_onSave(dialog) {
/*****************************************************************************************/

	var taskName 				= document.getElementById('taskName').value;
	var taskDescription		= document.getElementById('taskDescription').value;
	var taskOwnerID 			= document.getElementById('taskOwnerID').value;
	var taskStartDate			= document.getElementById('startDate').value;
	var taskDueDate			= document.getElementById('dueDate').value;
	var taskCustomerID		= document.getElementById('add_customerID').value;
	var taskStartDateString;
	var taskDueDateString;
	

	// validate dates....
	var validationMsg		= '';
	
	if (taskStartDate) {
		if (!moment(taskStartDate).isValid()) {
			validationMsg += 'Start date is invalid\n';
			document.getElementById('startDate').parentNode.classList.add('is-invalid');
			document.getElementById('startDate').parentNode.classList.add('is-dirty');
		} 
	} else {
		validationMsg += 'Start date is missing\n';
		document.getElementById('startDate').parentNode.classList.add('is-invalid');
		document.getElementById('startDate').parentNode.classList.add('is-dirty');
	}
	
	if (taskDueDate) {
		if (!moment(taskDueDate).isValid()) {
			validationMsg += 'Due date is invalid\n';
			document.getElementById('dueDate').parentNode.classList.add('is-invalid');
			document.getElementById('dueDate').parentNode.classList.add('is-dirty');
		} 
	} else {
		validationMsg += 'Due date is missing\n';
		document.getElementById('dueDate').parentNode.classList.add('is-invalid');
		document.getElementById('dueDate').parentNode.classList.add('is-dirty');
	}
	
	if (moment(taskStartDate).isValid() && moment(taskDueDate).isValid()) {
		if (moment(taskDueDate).isBefore(moment(taskStartDate))) {
			validationMsg += 'Due date cannot preceed start date.\n';
			document.getElementById('startDate').parentNode.classList.add('is-invalid');
			document.getElementById('startDate').parentNode.classList.add('is-dirty');
			document.getElementById('dueDate').parentNode.classList.add('is-invalid');
			document.getElementById('dueDate').parentNode.classList.add('is-dirty');
		}
	}

	if (validationMsg) {
		alert(validationMsg);
		return false;
	}	
	

	
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=add"
														+ "&name=" + encodeURIComponent(taskName) 
														+ "&description=" + encodeURIComponent(taskDescription) 
														+ "&owner=" + taskOwnerID 
														+ "&start=" + encodeURIComponent(taskStartDate)
														+ "&due=" + encodeURIComponent(taskDueDate)
														+ "&customerID=" + taskCustomerID;

	console.log(requestUrl);

	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_AddOrphanTask;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_AddOrphanTask() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				location = location;
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function ToggleActionIcons(htmlElement) {
/*****************************************************************************************/
	
	var deleteIcon = htmlElement.querySelector('i.delete');
	if (deleteIcon) {
		if (deleteIcon.style.visibility == 'visible') {
			deleteIcon.style.visibility = 'hidden';
		} else {
			deleteIcon.style.visibility = 'visible';
		}
	}

}


/*****************************************************************************************/
function taskDelete_OnClick(htmlElement) {
/*****************************************************************************************/
	
	if (!confirm('Are you sure you want to delete this task?')) {
		return false;
	}

	var taskID = htmlElement.closest( 'TR' ).id;

	var requestUrl = "ajax/taskMaintenance.asp?cmd=delete"
														+ "&task=" + taskID; 
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_DeleteTask;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


	function StateChangeHandler_DeleteTask() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				location = location;
// 				Complete_DeleteKeyInitiative(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function ToggleProjectsKIs(htmlElement) {
/*****************************************************************************************/

// 	var rowToToggle = htmlElement.parentElement.nextSibling.nextSibling.nextSibling.nextSibling;
	var rowToToggle = htmlElement.parentNode.nextSibling;
	var arrowToToggle = htmlElement.childNodes[1];
	
	if (rowToToggle.style.display == 'none') {
		rowToToggle.style.display = '';
		arrowToToggle.innerText = 'keyboard_arrow_down';
	} else {
		rowToToggle.style.display = 'none';
		arrowToToggle.innerText = 'keyboard_arrow_right';
	}
	
}


/*****************************************************************************************/
function associateProjectWithTask_onChange(htmlElement) {
/*****************************************************************************************/

	var customerID = htmlElement.getAttribute('customerID');
	var taskID = htmlElement.getAttribute('taskID');
		
	var selectedProjectName 	= htmlElement.options[htmlElement.selectedIndex].innerText;
	var selectedProjectValue 	= htmlElement.options[htmlElement.selectedIndex].value;

	if (selectedProjectValue == 'Add a new project...') {

		// link to 'customerProjects.asp?id='+customerID;
		window.location.href='customerProjects.asp?id=' + customerID;

	} else {

		var requestUrl 	= "ajax/projectMaintenance.asp?cmd=addTaskProject"
													+ "&customerID=" + customerID
													+ "&projectID=" + selectedProjectValue
													+ "&taskID=" + taskID;

		console.log(requestUrl); 

		var payload = "customerID=" + customerID 
						+ "&projectID=" + selectedProjectValue
						+ "&taskID=" + taskID;

		
		CreateRequest();

		if(request) {
			request.onreadystatechange = StateChangeHandler_associateProjectWithTask;
// 			request.open("POST", "ajax/projectMaintenance.asp?cmd=addTaskProject", true);
// 			request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
// 			request.send(payload);
			request.open("GET", requestUrl,  true);
			request.send(null);		
	}
	
		function StateChangeHandler_associateProjectWithTask() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {

					var taskID = request.responseXML.getElementsByTagName('taskID')[0].textContent;
					var customerID = request.responseXML.getElementsByTagName('customerID')[0].textContent;
					window.location.href = 'customerTasks.asp?id=' + customerID + '&taskID=' + taskID;
	
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
							
	}
	
}


/*****************************************************************************************/
function AddKeyInitiativeToTask_onChange(htmlElement, taskID, customerID) {
/*****************************************************************************************/
		
	var selectedKiName 	= htmlElement.options[htmlElement.selectedIndex].innerText;
	var selectedKiValue 	= htmlElement.options[htmlElement.selectedIndex].value;

	if (selectedKiValue == 'Add new key initiative...') {

		// link to 'customerProjects.asp?id='+customerID;
		window.location.href='customerKeyInitiatives.asp?id=' + customerID;

	} else {

		var requestUrl 	= "ajax/projectMaintenance.asp?cmd=addTaskKeyInitiative"
													+ "&customerID=" + customerID
													+ "&keyInitiativeID=" + selectedKiValue
													+ "&taskID=" + taskID ;
		console.log(requestUrl); 

		var payload = "customerID=" + customerID 
						+ "&projectID=" + selectedKiValue
						+ "&taskID=" + taskID;
		
		CreateRequest();

		if(request) {
			request.onreadystatechange = StateChangeHandler_AddKeyInitiativeToTask;
// 			request.open("POST", "ajax/projectMaintenance.asp?cmd=addTaskKeyInitiative", true);
// 			request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
// 			request.send(payload);
			request.open("GET", requestUrl,  true);
			request.send(null);		
	}
	
		function StateChangeHandler_AddKeyInitiativeToTask() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					
					var taskID = request.responseXML.getElementsByTagName('taskID')[0].textContent;
					var customerID = request.responseXML.getElementsByTagName('customerID')[0].textContent;
					window.location.href = 'customerTasks.asp?id=' + customerID + '&taskID=' + taskID;
					
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
							
	}
	
}


/*****************************************************************************************/
function ToggleRemoveIcons(htmlElement) {
/*****************************************************************************************/

	var removeIcon;
	if (htmlElement.classList.contains('project')) {
		removeIcon = htmlElement.querySelector('i.removeProj');
	} else if (htmlElement.classList.contains('ki')) {
		removeIcon = htmlElement.querySelector('i.removeKI');
	} else {
		return false;
	}
	
	if (removeIcon) {
		if (removeIcon.style.display == 'none') {
			removeIcon.style.display = 'inline-block';
		} else {
			removeIcon.style.display = 'none';
		}
	}
	
}



/*****************************************************************************************/
function RemoveProjFromTask(taskID, customerID) {
/*****************************************************************************************/

	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=removeProject"
												+ "&customerID=" + customerID 
												+ "&taskID=" + taskID;
												
	console.log(requestUrl);

// 	var payload = "keyInitiativeID=" + keyInitiativeID 
// 					+ "&taskID=" + taskID;

	CreateRequest();

	if(request) {
		request.onreadystatechange = StateChangeHandler_RemoveProjectFromTask;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
	
	function StateChangeHandler_RemoveProjectFromTask() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				var taskID = request.responseXML.getElementsByTagName('taskID')[0].textContent;
				var customerID = request.responseXML.getElementsByTagName('customerID')[0].textContent;
				window.location.href = 'customerTasks.asp?id=' + customerID + '&taskID=' + taskID;

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function RemoveTaskFromKeyInitiative(htmlElement,customerID) {
/*****************************************************************************************/
	
	var keyInitiativeID 	= htmlElement.getAttribute('data-ki');
	var taskID			= htmlElement.getAttribute('data-task');
	
	var requestUrl 	= "ajax/projectMaintenance.asp?cmd=removeKeyInitiativeTask"
												+ "&customerID=" + customerID
												+ "&keyInitiativeID=" + keyInitiativeID
												+ "&taskID=" + taskID ;
	console.log(requestUrl);

// 	var payload = "keyInitiativeID=" + keyInitiativeID 
// 					+ "&taskID=" + taskID;

	CreateRequest();

	if(request) {
		request.onreadystatechange = StateChangeHandler_RemoveKeyInitiativeProject;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
	
	function StateChangeHandler_RemoveKeyInitiativeProject() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
	
				var taskID = request.responseXML.getElementsByTagName('taskID')[0].textContent;
				var customerID = request.responseXML.getElementsByTagName('customerID')[0].textContent;
				window.location.href = 'customerTasks.asp?id=' + customerID + '&taskID=' + taskID;

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

		
	
	
}



//-- ------------------------------------------------------------------ -->
function generateErrorResponse(message) {
//-- ------------------------------------------------------------------ -->

	return {
		status : 'error',
		message
	};

}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}
