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
function SaveCMT(htmlDialog) {
/*****************************************************************************************/
	
	var cmtName = htmlDialog.querySelector('#cmtName').value;
		
	var requestUrl = 'ajax/adminMaintenance.asp?cmd=newCMT'
											+ '&name=' + encodeURIComponent(cmtName);
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_GetCustomerManagers;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
	function StateChangeHandler_GetCustomerManagers() {
		
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_SaveEditCustomerManagerType(request.responseXML);
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
	
	var currActionButtons = htmlElement.querySelector('.actionIcons');
	var currEditCMT		= currActionButtons.querySelector('.editCMT');
	var currDeleteCMT		= currActionButtons.querySelector('.deleteCMT');
	
	if (currEditCMT) {

		if (currEditCMT.style.visibility == "hidden") {
			
			currEditCMT.style.visibility 		= "visible";
			currDeleteCMT.style.visibility 	= "visible";
			
		} else {
			
			currEditCMT.style.visibility 		= "hidden";
			currDeleteCMT.style.visibility 	= "hidden";
			
		}
		
	}

}



/*****************************************************************************************/
function GetCustomerManagers(htmlElement) {
/*****************************************************************************************/

	var managerTypeID = htmlElement.getAttribute('data-id');
	
	// hide all the action icons...
	var customerManagerTypeTable = htmlElement.closest('table');
	var allChevrons = customerManagerTypeTable.querySelectorAll('.viewMgrs');
	if (allChevrons) {
		for (i = 0; i < allChevrons.length; ++i) {
			allChevrons[i].style.visibility = 'hidden';
		}
	}
	
	// now unhide the selected view chevron...
	var selectedChevron = htmlElement.querySelector('.viewMgrs');
	if (selectedChevron) {
		selectedChevron.style.visibility = 'visible';
	}
	
	
	var requestUrl = 'ajax/userMaintenance.asp?cmd=getCustomerManagers'
											+ '&managerTypeID=' + managerTypeID;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_GetCustomerManagers;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
	function StateChangeHandler_GetCustomerManagers() {
		
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_GetCustomerManagers(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
		
	}


	
}



/*****************************************************************************************/
function Complete_GetCustomerManagers(xml) {
/*****************************************************************************************/

	var cmPlaceholderText			= document.getElementById('cmPlaceholderText');
	cmPlaceholderText.style.display = 'none';

	var customerManagerTable 		= document.getElementById('customerManagers');
	customerManagerTable.style.display = 'inline-block';
	
	
	var customerManagerTableTbody = customerManagerTable.querySelector('tbody');
	
	if (customerManagerTableTbody) {
		customerManagerTableTbody.innerHTML = '';
	}
	
	var userID, userName;
	var customerID, customerName;
	var startDate, endDate;
	
	var customerManagers = xml.getElementsByTagName('customerManager');
	if (customerManagers) {
		for (i = 0; i < customerManagers.length; ++i) {
			
			userID 			= customerManagers[i].getElementsByTagName('user')[0].getAttribute('id');
			userName 		= customerManagers[i].getElementsByTagName('user')[0].textContent;

			customerID 		= customerManagers[i].getElementsByTagName('customer')[0].getAttribute('id');
			customerName 	= customerManagers[i].getElementsByTagName('customer')[0].textContent;

			startDate 		= customerManagers[i].getElementsByTagName('startDate')[0].textContent;
			endDate	 		= customerManagers[i].getElementsByTagName('endDate')[0].textContent;
			
			var newRow = customerManagerTableTbody.insertRow(-1);
			newRow.style.cursor = 'pointer';
			newRow.setAttribute('data-customerID', customerID);
			newRow.setAttribute('data-userID', userID);
			newRow.addEventListener('click', function() {
				var customerID = this.closest('tr').getAttribute('data-customerID');
				location = 'customerManagers.asp?id=' + customerID;
			})
			
			var newCell0 			= newRow.insertCell(0);
			newCell0.id 			= userID;
			newCell0.innerHTML 	= userName;
			newCell0.classList.add('mdl-data-table__cell--non-numeric');
			
			var newCell1			= newRow.insertCell(1);
			newCell1.id				= customerID;
			newCell1.innerHTML	= customerName;
			newCell1.classList.add('mdl-data-table__cell--non-numeric');
			
			var newCell2			= newRow.insertCell(2);
			newCell2.innerHTML	= startDate;
			newCell2.classList.add('mdl-data-table__cell--non-numeric');
			
			var newCell3			= newRow.insertCell(3);
			newCell3.innerHTML	= endDate;
			newCell3.classList.add('mdl-data-table__cell--non-numeric');
			
		}
		
		
	}

	componentHandler.upgradeAllRegistered();


}



/*****************************************************************************************/
function EditCustomerManagerType(htmlElement) {
/*****************************************************************************************/
	
	var rowToEdit = htmlElement.closest('tr');

	// hide all other edit buttons.....
	var editButtons = document.querySelectorAll('.editCMT');
	for (i = 0; i < editButtons.length; ++i) {
		editButtons[i].style.display = 'none';
	}
	// hide all other delete buttons.....
	var deleteButtons = document.querySelectorAll('.deleteCMT');
	for (i = 0; i < deleteButtons.length; ++i) {
		deleteButtons[i].style.display = 'none';
	}
	
	// hide all view buttons.....
// 	var viewButtons = document.querySelectorAll('.viewMgrs');
// 	for (i = 0; i < viewButtons.length; ++i) {
// 		viewButtons[i].style.display = 'none';
// 	}
// 	
	var editNameElem = rowToEdit.querySelector('.name');
	var editName = editNameElem.textContent;
	editNameElem.innerHTML	=	'<input type="text" id="cmtName" data-orig="' + editName + '" style="font-size: 13px; font-weight: 400;" value="' + editName + '">'
	editNameElem.style.paddingLeft = '18px';

	var actionIconsElem		= rowToEdit.querySelector('.actionIcons');
	actionIconsElem.innerHTML 	= 	'<div class="cmtEditIcons" style="float: right; vertical-align: middle; align-content: center;">'
										+		'<i class="material-icons cancelEdit" title="Cancel changes" style="cursor: pointer; vertical-align: middle;">close</i>'
										+		'<i class="material-icons saveEdit" title="Save changes" style="cursor: pointer; vertical-align: middle;">check</i>'
										+	'</div>'

	var newCancelButton = rowToEdit.querySelector('.cancelEdit');
	newCancelButton.addEventListener('click', function(e) {
		e.stopPropagation();
		CancelEditCustomerManagerType(this);
	});
	
	var newSaveButton = rowToEdit.querySelector('.saveEdit');
	newSaveButton.addEventListener('click', function(e) {
		e.stopPropagation();
		SaveEditCustomerManagerType(this);
	});
	
	var nameInput = rowToEdit.querySelector('#cmtName');
	nameInput.addEventListener('click', function(e) {
		e.stopPropagation();
	});
	nameInput.select();
	nameInput.focus();
	
	
}



/*****************************************************************************************/
function SaveEditCustomerManagerType(htmlElement) {
/*****************************************************************************************/

	var managerTypeTR				= htmlElement.closest('tr');
	var managerTypeID 			= managerTypeTR.getAttribute('data-id');
	
	var managerTypeInputElem	= managerTypeTR.querySelector('#cmtName');
	var managerTypeName 			= managerTypeInputElem.value;

	var requestURL = 'ajax/adminMaintenance.asp?cmd=updateCustomerManagerType'
												+ '&managerTypeID=' + managerTypeID
												+ '&managerTypeName=' + encodeURIComponent(managerTypeName);
											
	console.log(requestURL);
	CreateRequest();
	
	if (request) {
		request.onreadystatechange = StateChangeHandler_SaveEditCustomerManagerType;
		request.open("GET", requestURL, true);
		request.send(null);
	}

	function StateChangeHandler_SaveEditCustomerManagerType() {

		if (request.readyState == 4) {
			if (request.status == 200) {

				Complete_SaveEditCustomerManagerType(request.responseXML);

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status + '\n\nGetCustomerInternalMetricValues()');
			}
		}
		
	}

	
}



/*****************************************************************************************/
function Complete_SaveEditCustomerManagerType(xml) {
/*****************************************************************************************/

	var msg = xml.getElementsByTagName('msg')[0].textContent;
	
	if (msg == 'Customer manager type updated') {
		
		var cmtID			= xml.getElementsByTagName('managerTypeID')[0].textContent;
		var cmtName			= xml.getElementsByTagName('managerTypeName')[0].textContent;
	
		var updatedTable 	= document.getElementById('tbl_customerManagerTypes');
		var updatedTR		= updatedTable.querySelector('tr[data-id="' + cmtID + '"] ');
		var updatedTD		= updatedTR.querySelector('td.name');
		updatedTD.innerHTML = cmtName;

		
		var controlTR		= updatedTR.querySelectorAll('td')[1];
		controlTR.innerHTML	= '<div class="actionIcons" style="float: right; vertical-align: middle; align-content: center;">'
										+ '<i class="material-icons viewMgrs" data-id="' + cmtID + '" style="visibility: hidden; cursor: pointer; vertical-align: middle;" title="View customer managers of this type">double_arrow</i>'
										+ '<i class="material-icons deleteCMT" data-id="' + cmtID + '" 	style="visibility: hidden; cursor: pointer; vertical-align: middle;" title="Delete customer manager type"li>delete_outline</i>'
										+ '<i class="material-icons editCMT" data-id="' + cmtID + '" 	style="visibility: hidden; cursor: pointer; vertical-align: middle;" title="Edit customer manager type">edit</i>'
									+ '</div>';

		var newDeleteIcon = controlTR.querySelector('i.deleteCMT');
		newDeleteIcon.addEventListener('click', function(e) {
			e.cancelBubble = true;
			DeleteCustomerManagerType(this);
		});
		
		var newDeleteIcon = controlTR.querySelector('i.editCMT');
		newDeleteIcon.addEventListener('click', function(e) {
			e.cancelBubble = true;
			EditCustomerManagerType(this);
		});
		
		// un-hide all other edit buttons.....
		var editButtons = document.querySelectorAll('.editCMT');
		for (i = 0; i < editButtons.length; ++i) {
			editButtons[i].style.display = 'inline-block';
		}
		// un-hide all other delete buttons.....
		var deleteButtons = document.querySelectorAll('.deleteCMT');
		for (i = 0; i < deleteButtons.length; ++i) {
			deleteButtons[i].style.display = 'inline-block';
		}
		
		
	}

	// show a message...
	ShowSnackbar(msg);


}



/*****************************************************************************************/
function CancelEditCustomerManagerType(htmlElement) {
/*****************************************************************************************/

	var editRowElem 		= htmlElement.closest('tr');
	var targetTable 		= htmlElement.closest('table');
	var targetTableBody	= targetTable.querySelector('tbody');
	
	var originalName		= editRowElem.querySelector('#cmtName').getAttribute('data-orig');

	var targetTableRows	= targetTableBody.querySelectorAll('tr');
	var rowCount 			= targetTableRows.length;
	

	var editCellElem		= editRowElem.querySelector('.name');
	if (editCellElem) {
		editCellElem.innerHTML = '';
	}
	
	var newNameElem = document.createTextNode(originalName);
	editCellElem.appendChild(newNameElem);
	
	
	
	var actionButtonsTD = editRowElem.querySelector('.actionIcons').closest('td');
	if (actionButtonsTD) {
		actionButtonsTD.innerHTML = '';
	}

	var editRowDataID = editRowElem.getAttribute('data-id');
	if (editRowDataID) {

		var newActionIconsDiv = document.createElement('div');
		newActionIconsDiv.classList.add('actionIcons');
		newActionIconsDiv.style.float = 'right';
		newActionIconsDiv.style.verticalAlign = 'middle';
		newActionIconsDiv.style.alignContent = 'center';

		var newViewMgrsIcon = document.createElement('i');
		newViewMgrsIcon.classList.add('material-icons');
		newViewMgrsIcon.classList.add('viewMgrs');
		newViewMgrsIcon.setAttribute('data-id', editRowDataID);
		newViewMgrsIcon.style.visibility = 'hidden';
		newViewMgrsIcon.style.cursor = 'pointer';
		newViewMgrsIcon.style.verticalAlign = 'middle';
		newViewMgrsIcon.title = 'View customer managers of this type';
		newViewMgrsIcon.innerHTML = 'double_arrow';
		newActionIconsDiv.appendChild(newViewMgrsIcon);
		
		var newDeleteCmtIcon = document.createElement('i');
		newDeleteCmtIcon.classList.add('material-icons');
		newDeleteCmtIcon.classList.add('deleteCMT');
		newDeleteCmtIcon.setAttribute('data-id', editRowDataID);
		newDeleteCmtIcon.style.visibility = 'hidden';
		newDeleteCmtIcon.style.cursor = 'pointer';
		newDeleteCmtIcon.style.verticalAlign = 'middle';
		newDeleteCmtIcon.title = 'Delete customer manager type';
		newDeleteCmtIcon.innerHTML = 'delete_outline';
		newActionIconsDiv.appendChild(newDeleteCmtIcon);
		
		var newEditCmtIcon = document.createElement('i');
		newEditCmtIcon.classList.add('material-icons');
		newEditCmtIcon.classList.add('editCMT');
		newEditCmtIcon.setAttribute('data-id', editRowDataID);
		newEditCmtIcon.style.visibility = 'hidden';
		newEditCmtIcon.style.cursor = 'pointer';
		newEditCmtIcon.style.verticalAlign = 'middle';
		newEditCmtIcon.title = 'Edit customer manager type';
		newEditCmtIcon.innerHTML = 'edit';
		newEditCmtIcon.addEventListener('click', function(e) {
			e.cancelBubble = true;
			EditCustomerManagerType(this);
		});
		
		newActionIconsDiv.appendChild(newEditCmtIcon);
		
		actionButtonsTD.appendChild(newActionIconsDiv);

	}


	// unhide all edit buttons.....
	var editButtons = document.querySelectorAll('.editCMT');
	for (i = 0; i < editButtons.length; ++i) {
		editButtons[i].style.display = 'inline-block';
	}
	// unhide all delete buttons.....
	var deleteButtons = document.querySelectorAll('.deleteCMT');
	for (i = 0; i < deleteButtons.length; ++i) {
		deleteButtons[i].style.display = 'inline-block';
	}
	
	// unhide view buttons.....
	var viewButtons = document.querySelectorAll('.viewMgrs');
	for (i = 0; i < viewButtons.length; ++i) {
		viewButtons[i].style.display = 'inline-block';
	}
	
	
}



/*****************************************************************************************/
function DeleteCustomerManagerType(htmlElement) {
/*****************************************************************************************/

	var managerTypeID = htmlElement.getAttribute('data-id');
	
	if (managerTypeID == "0") {
		alert('This customer mananager type cannot be deleted due to associated special logic (i.e., "one CMT per customer per day")');
		return false;
	}
	
	
	if(confirm('Are you sure you want to permanently delete this Customer Manager Type?\n\nThis action cannot be undone.\n\n')) {


		var requestURL = 'ajax/adminMaintenance.asp?cmd=deleteCustomerManagerType'
												+ '&managerTypeID=' + managerTypeID;
												
		console.log(requestURL);
		CreateRequest();
		
		if (request) {
			request.onreadystatechange = StateChangeHandler_DeleteInternalMetricValue;
			request.open("GET", requestURL, true);
			request.send(null);
		}
	
		function StateChangeHandler_DeleteInternalMetricValue() {
	
			if (request.readyState == 4) {
				
				if (request.status == 200) {

					var msg = request.responseXML.getElementsByTagName('msg')[0].textContent;

					if (msg == 'Customer Manager Type in use') {
						
						alert('Customer Manager Type is in use and cannot be deleted');
						
					} else {

						// remove deleted from <table>....
						var targetRow		= htmlElement.closest('tr');
						targetRow.parentNode.removeChild(targetRow);
						
						// show a message...
						ShowSnackbar(msg)
					
					}

				} else {
					
					alert("problem retrieving data from the server, status code: "  + request.status + '\n\nGetCustomerInternalMetricValues()');
					
				}
				
			}
			
		}
	
	} else {

		return false;

	}
		
}



/*****************************************************************************************/
function ShowSnackbar(msg) {
/*****************************************************************************************/

	var snackbarElem = document.querySelector('.mdl-js-snackbar');
	snackbarElem.MaterialSnackbar.showSnackbar({
		message: msg
	});
	
}
