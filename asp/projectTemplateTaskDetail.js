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
function ResetAllPrompts() {
/*****************************************************************************************/
// resets all "prompts" to display='block' and all "inputs" to display='none'
// in other words, like the page originally loaded.	
	
	var allNewItemInputs = document.getElementsByClassName('input'), i;
	for (var i = 0; i < allNewItemInputs.length; i ++) {
		allNewItemInputs[i].style.display = 'none';
	}

	var allNewItemPrompts =  document.getElementsByClassName('prompt'), j;
	for (var i = 0; i < allNewItemPrompts.length; i ++) {
		allNewItemPrompts[i].style.display = 'block';
	}


}


/*****************************************************************************************/
function UpdateChecklistName_onClick(htmlElement) {
/*****************************************************************************************/
	
	if (event.target.nodeName == 'TEXTAREA') {
		return false;
	}

	ResetAllPrompts();
	
	var checklistID 				= htmlElement.getAttribute('data-val');
	var checklistNamePrompt 	= document.getElementById('checklistNamePrompt-'+checklistID);
	var checklistNameInput  	= document.getElementById('checklistNameInput-'+checklistID);
	var checklistNameTextarea 	= document.getElementById('checklistNameTextarea-'+checklistID);
	var checklistCheckbox 		= document.getElementById('checklist-'+checklistID);
	
	checklistNamePrompt.style.display 	= 'none';
	checklistCheckbox.style.display 		= 'none';
	checklistNameInput.style.display 	= 'block';
	
	checklistNameTextarea.select();
	
	event.stopPropagation();	
		
}


/*****************************************************************************************/
function CancelChecklistNameUpdate_onClick(htmlElement) {
/*****************************************************************************************/
	
	var checklistID 				= htmlElement.parentNode.parentNode.getAttribute('data-val');
	var checklistNamePrompt 	= document.getElementById('checklistNamePrompt-'+checklistID);
	var checklistNameInput  	= document.getElementById('checklistNameInput-'+checklistID);
	var checklistNameTextarea 	= document.getElementById('checklistNameTextarea-'+checklistID);
	var checklistCheckbox 		= document.getElementById('checklist-'+checklistID);
	var originalValue				= checklistNamePrompt.childNodes[0].data.trim();
	
	checklistNameInput.style.display 	= 'none';
	checklistNamePrompt.style.display 	= 'block';
	checklistCheckbox.style.display 		= 'block';
		
	checklistNameTextarea.value = originalValue; 
	
	event.stopPropagation();	

}


/*****************************************************************************************/
function SaveChecklistNameUpdate_onClick(htmlElement) {
/*****************************************************************************************/
	
	
	var checklistID 				= htmlElement.parentNode.parentNode.getAttribute('data-val');
	var newChecklistName		 	= document.getElementById('checklistNameTextarea-'+checklistID).value;

	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=updatedChecklistName"
												+ "&id=" + checklistID
												+ "&name=" + encodeURIComponent(newChecklistName);
												
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				ChecklistNameStatus(request.responseXML);
				
			} else {

				alert("problem retrieving data from the server, status code: "  + request.status);

			}
		}
	
	}

	ResetAllPrompts();
	event.stopPropagation();
	
	location = location;

}


/*****************************************************************************************/
function ChecklistNameStatus(xml) {
/*****************************************************************************************/

	var id 				= GetInnerText(xml.getElementsByTagName('id')[0]);
	var name				= GetInnerText(xml.getElementsByTagName('name')[0]);
	var msg				= GetInnerText(xml.getElementsByTagName('msg')[0]);
	var notification 	= document.querySelector('.mdl-js-snackbar');

	document.getElementById('checklistNameTextarea-'+id).innerHTML = name;

	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}


/*****************************************************************************************/
function CompleteChecklistItem_onChange(htmlElement) {
/*****************************************************************************************/
	
	var id = htmlElement.getAttribute('data-val');
	var completionType = htmlElement.parentNode.parentNode.parentNode.tagName;
	var completed;
	var cmd;
	var msg;
			
	if (completionType == 'TBODY') {

		cmd = 'updateItem';
		if (htmlElement.MaterialCheckbox.inputElement_.checked) {
			completed = 0;
		} else {
			completed = 1;
		}		

	} else {

		cmd = 'updateList';
		if (htmlElement.MaterialCheckbox.inputElement_.checked) {
			completed = 1;
		} else {
			completed = 0;
		}		

	}

	var requestUrl 	= "ajax/taskMaintenance.asp"
												+ "?cmd=" + cmd
												+ "&id=" + id
												+ "&completed=" + completed;
												
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				ChecklistStatus(request.responseXML);
				
			} else {

				alert("problem retrieving data from the server, status code: "  + request.status);

			}
		}
	
	}

}


/*****************************************************************************************/
function ChecklistStatus(xml) {
/*****************************************************************************************/

	var id 				= GetInnerText(xml.getElementsByTagName('id')[0]);
	var cmd 				= GetInnerText(xml.getElementsByTagName('cmd')[0]);
	var completed		= GetInnerText(xml.getElementsByTagName('completed')[0]);
	var msg				= GetInnerText(xml.getElementsByTagName('msg')[0]);
	

	var notification 	= document.querySelector('.mdl-js-snackbar');


	if (cmd == 'Item') {
		if(completed == '1') {
			document.getElementById('item-'+id).MaterialCheckbox.check();
		} else {
			document.getElementById('item-'+id).MaterialCheckbox.uncheck();
		}
	} else {
		if (completed == '1') {
			document.getElementById('checklist-'+id).MaterialCheckbox.check();

			// check the boxes for all items with class of 'checklist+id'
			var checklistItems = document.getElementsByClassName('checklist-'+id), i;
			for (var i = 0; i < checklistItems.length; i ++) {
				checklistItems[i].MaterialCheckbox.check();
			}

		} else {
			document.getElementById('checklist-'+id).MaterialCheckbox.uncheck();

			// uncheck the boxes for all items with class of 'checklist+id'
			var checklistItems = document.getElementsByClassName('checklist-'+id), i;
			for (var i = 0; i < checklistItems.length; i ++) {
				checklistItems[i].MaterialCheckbox.uncheck();
			}

		}
	}


	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	
}


/*****************************************************************************************/
function AddTask_onClick(htmlElement) {
/*****************************************************************************************/

	var newItemInputDiv 		= htmlElement.parentNode.parentNode;
	var newItemInputText 	= encodeURIComponent(newItemInputDiv.childNodes[1].value);
	var checklistID 			= newItemInputDiv.getAttribute('data-val');
		
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=addChecklistItem"
												+ "&checklistID=" + checklistID
												+ "&description=" + newItemInputText;
												
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				attribute_status(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	location = location; 
		
}


/*****************************************************************************************/
function CancelAddTask_onClick(htmlElement) {
/*****************************************************************************************/
	
	
	var newItemInput = htmlElement.parentNode.parentNode;
	var checklistID = newItemInput.getAttribute('data-val');
	var newItemTextArea = newItemInput.childNodes[1];
	newItemTextArea.value = '';
	
	
	document.getElementById('newItemInput-'+checklistID).style.display = 'none';
	document.getElementById('newItemPrompt-'+checklistID).style.display = 'block';
	
	event.stopPropagation();
		
}


/*****************************************************************************************/
function DeleteItem_onClick(htmlElement) {
/*****************************************************************************************/


	if (!confirm('Are you sure you want to delete this item?\n\nThis action is permanent and cannot be undone.')) {
		return false;
	}
	
	var itemID = htmlElement.getAttribute('data-val');
		
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=deleteItem"
												+ "&id=" + itemID;
												
	
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
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
function DeleteChecklist_onClick(htmlElement) {
/*****************************************************************************************/


	if (!confirm('Are you sure you want to delete this checklist and all of its items?\nThis action is permanent and cannot be undone.')) {
		return false;
	}
	
	var taskChecklistID = htmlElement.getAttribute('data-val');
		
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=deleteTaskChecklist"
												+ "&id=" + taskChecklistID;
												
	
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				attribute_status(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	location = location; 
	
}



/*****************************************************************************************/
function ShowDeleteIcon(htmlElement) {
/*****************************************************************************************/
	
	var id			= htmlElement.getAttribute('data-val');
	var deleteIcon;
	
	if (htmlElement.parentNode.nodeName == 'TBODY') {
		deleteIcon = document.getElementById('itemDeleteIcon-'+id);
	} else {
		deleteIcon = document.getElementById('checklistDeleteIcon-'+id);
	}

	deleteIcon.style.display = 'inline-block';
	
	
}


/*****************************************************************************************/
function HideDeleteIcon(htmlElement) {
/*****************************************************************************************/
	
	var id			= htmlElement.getAttribute('data-val');
	var deleteIcon;
	
	if (htmlElement.parentNode.nodeName == 'TBODY') {
		deleteIcon = document.getElementById('itemDeleteIcon-'+id);
	} else {
		deleteIcon = document.getElementById('checklistDeleteIcon-'+id);
	}

	deleteIcon.style.display = 'none';
	
	
}


/*****************************************************************************************/
function NewItem_onMouseover(htmlElement) {
/*****************************************************************************************/
	
// 	htmlElement.parentNode.style.backgroundColor = '#ccddff';
// 	var tr_ForNewRow = htmlElement.parentNode.parentNode;
// 	tr_ForNewRow.style.backgroundColor = 'lightgrey';
// 	tr_ForNewRow.style.cursor = 'pointer';
	
	htmlElement.style.backgroundColor = 'lightgrey';
	htmlElement.style.cursor = 'pointer';
	
}


/*****************************************************************************************/
function NewItem_onMouseout(htmlElement) {
/*****************************************************************************************/
	
	htmlElement.style.backgroundColor = 'white';
	
	
}


/*****************************************************************************************/
function AddChecklistItem_onClick(htmlElement) {
/*****************************************************************************************/
	
	// prevent event bubbling when the user clicks into the textarea
	if (event.target.nodeName == 'TEXTAREA') {
		return false;
	}
	
	ResetAllPrompts();

	// first return all prompts and inputs to the initial state...
// 	var allNewItemInputs = document.getElementsByClassName('newItemInput'), i;
// 	for (var i = 0; i < allNewItemInputs.length; i ++) {
// 		allNewItemInputs[i].style.display = 'none';
// 	}
// 	
// 	var allNewItemPrompts =  document.getElementsByClassName('newItemPrompt'), j;
// 	for (var i = 0; i < allNewItemPrompts.length; i ++) {
// 		allNewItemPrompts[i].style.display = 'block';
// 	}

	
	// now show/hide for the element that was clicked...
	var newItemPrompt = htmlElement.childNodes[1];
	var newItemInput = htmlElement.childNodes[3];
	
	newItemPrompt.style.display = 'none';
	newItemInput.style.display = 'block';
	var newItemTextarea = newItemInput.childNodes[1];
	newItemTextarea.focus();
		
}

/*****************************************************************************************/
function AddChecklist_onSave(dialog) {
/*****************************************************************************************/

	var checklistName 	= document.getElementById('add_checklistName').value;
	var taskID				= document.getElementById('add_checklistTaskID').value;
	
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=addChecklist"
													+ "&task=" + taskID 
													+ "&name=" + encodeURIComponent(checklistName);
	
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				attribute_status(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	location = location;
	
}



/*****************************************************************************************/
function attribute_onChange(attributeNode,task) {
/*****************************************************************************************/

	var attributeName 	= attributeNode.name;
	var projectStartDate = document.getElementById('projectStartDate').value;
	var projectEndDate = document.getElementById('projectEndDate').value;
	var attributeValue;
	
	if(attributeName == "ownerID") {
		attributeValue = attributeNode.options[attributeNode.selectedIndex].value;
	} else {
		attributeValue 	= attributeNode.value;
	}
	
	if (attributeName == 'startDate') {
		if (!moment(attributeValue).isValid()) {
			alert('Start date is not a valid date');
			return false;
		} else {
			var taskDueDate = document.getElementById('dueDate').value;
			if (!moment(attributeValue).isSameOrAfter(projectStartDate)) {
				alert('Start date cannot be prior to project start date');
				return false;
			} else {
				if (!moment(attributeValue).isSameOrBefore(projectEndDate)) {
					alert('Start date cannot be after project end date');
					return false;
				}
			}
			if (!moment(attributeValue).isSameOrBefore(taskDueDate)) {
				alert('Start date cannot be after due date');
				return false;
			}
		}
	}
	
	if (attributeName == 'dueDate') {
		if (!moment(attributeValue).isValid()) {
			alert('Due date is not a valid date');
			return false;
		} else {
			var taskStartDate = document.getElementById('startDate').value;
			if (!moment(attributeValue).isSameOrAfter(projectStartDate)) {
				alert('Due date cannot be prior to project start date');
				return false;
			} else {
				if (!moment(attributeValue).isSameOrBefore(projectEndDate)) {
					alert('Due date cannot be after project end date');
					return false;
				}
			}
			if (!moment(attributeValue).isSameOrAfter(taskStartDate)) {
				alert('Due date cannot be before start date');
				return false;
			}
		}
	}
	
	
	
	
	
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=update&task=" + task + "&name=" + attributeName + "&value=" + encodeURIComponent(attributeValue);
	
	console.log(requestUrl);
	
	createRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskName;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskName() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				attribute_status(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}




/*****************************************************************************************/
function attribute_status(urNode) {
/*****************************************************************************************/

	var msg 						= GetInnerText(urNode.getElementsByTagName('msg')[0]);
// var status 					= GetInnerText(urNode.getElementsByTagName('status')[0]);
	var taskDaysAtRisk 		= GetInnerText(urNode.getElementsByTagName('taskDaysAtRisk')[0]);
	var taskDaysAhead 		= GetInnerText(urNode.getElementsByTagName('taskDaysAhead')[0]);
	var taskDaysBehind 		= GetInnerText(urNode.getElementsByTagName('taskDaysBehind')[0]);

	if (urNode.getElementsByTagName('estimatedWorkDays').length > 0) {
		var estimatedWorkDays 	= GetInnerText(urNode.getElementsByTagName('estimatedWorkDays')[0]);	
		document.getElementById('taskDaysDurationEst').value = estimatedWorkDays;
	}
	
	if (urNode.getElementsByTagName('actualWorkDays').length > 0) {
		var actualWorkDays 		= GetInnerText(urNode.getElementsByTagName('actualWorkDays')[0]);	
		document.getElementById('taskDaysDurationAct').value = actualWorkDays;
	}
	
	document.getElementById('taskDaysAtRisk').value = taskDaysAtRisk;
/*
	if(taskDaysAtRisk > 0) {
		document.getElementById('taskDaysAtRisk').style.color = 'red';
	}
*/
	
	document.getElementById('taskDaysAhead').value = taskDaysAhead;
/*
	if(taskDaysAhead > 0) {
		document.getElementById('taskDaysAhead').style.color = 'green';
	}
*/
	
	document.getElementById('taskDaysBehind').value = taskDaysBehind;
/*
	if(taskDaysBehind > 0) {
		document.getElementById('taskDaysBehind').style.color = 'red';
	}
*/

	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
/*
	if(status == "error") {
		document.getElementById('firstName').focus();
		document.getElementById('username').focus();
	}
*/

}



/*****************************************************************************************/
function CaptureTaskOwnerID_onChange(selectElement) {
/*****************************************************************************************/	
	
	document.getElementById('taskOwner').value = selectElement.getAttribute('data-val');
	
}







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
	createRequest();
 
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
	createRequest();
 
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
	createRequest();
 
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
	createRequest();
 
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
	createRequest();
 
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

	var nodeInnerText = (node.textContent || node.innerText || node.text);
	
	if (nodeInnerText != null) {
		return nodeInnerText;
	} else {
		return " ";
	}
	
// 	return (node.textContent || node.innerText || node.text) ;

}


