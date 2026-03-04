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
function addNewMetric_onClick (htmlElement) {
/*****************************************************************************************/
	

	var values_dialog = document.getElementById('metricValue')	
	
// 	var targetTable = document.getElementById('customerInternalValuesTable');
// 	var newRow = targetTable.insertRow(1);
// 
// 	var newCellDate 		= newRow.insertCell(0);
// 	newCellDate.innerHTML = 'DATE';
// 
// 	var newCellValue 		= newRow.insertCell(1);
// 	newCellValue.innerHTML = 'VALUE';
// 	
// 	var newCellActions 	= newRow.insertCell(2);
// 	newCellActions.innerHTML = 'ACTIONS';

	
	
}


/*****************************************************************************************/
function ObjectiveField_onblur(htmlElement) {
/*****************************************************************************************/
	

	var startDateElem = document.getElementById('objectiveStartDate');
	var startValueElem = document.getElementById('objectiveStartValue');
	var endDateElem = document.getElementById('objectiveEndDate');
	var endValueElem = document.getElementById('objectiveEndValue');

	if (startDateElem.value || startValueElem.value || endDateElem.value || endValueElem.value) {
			
		if (!startDateElem.value) {
			startDateElem.parentNode.classList.add('is-invalid');
		} else {
			startDateElem.parentNode.classList.remove('is-invalid');
		}

		if (!startValueElem.value) {
			startValueElem.parentNode.classList.add('is-invalid');
		} else {
			startValueElem.parentNode.classList.remove('is-invalid');
		}
		
		if (!endDateElem.value) {
			endDateElem.parentNode.classList.add('is-invalid');
		} else {
			endDateElem.parentNode.classList.remove('is-invalid');
		}
		
		if (!endValueElem.value) {
			endValueElem.parentNode.classList.add('is-invalid');
		} else {
			endValueElem.parentNode.classList.remove('is-invalid');
		}
		
	} else {

		startDateElem.parentNode.classList.remove('is-invalid');
		startValueElem.parentNode.classList.remove('is-invalid');
		endDateElem.parentNode.classList.remove('is-invalid');
		endValueElem.parentNode.classList.remove('is-invalid');

	}

	startDateElem.parentNode.classList.add('is-dirty');
	endDateElem.parentNode.classList.add('is-dirty');
	
	
}


/*****************************************************************************************/
function GetCustomerInternalMetricValues(dialog, rssdID, objectiveID, metricID) {
/*****************************************************************************************/


	if (!dialog.open) {
		dialog.showModal();
	}
	
	var requestURL = 'ajax/customerMetrics.asp?cmd=getCustomerInternalMetrics'
											+ '&rssdID=' 		+ rssdID 
											+ '&objectiveID=' + objectiveID
											+ '&metricID='		+ metricID;
											
	console.log(requestURL);
	CreateRequest();
	
	if (request) {
		request.onreadystatechange = StateChangeHandler_GetCustomerInternalMetricValues;
		request.open("GET", requestURL, true);
		request.send(null);
	}

	function StateChangeHandler_GetCustomerInternalMetricValues() {

		if (request.readyState == 4) {
			if (request.status == 200) {
				Complete_GetCustomerInternalMetricValues(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status + '\n\nGetCustomerInternalMetricValues()');
			}
		}
		
	}

	
}


/*****************************************************************************************/
function Complete_GetCustomerInternalMetricValues(xml) {
/*****************************************************************************************/
	
	var targetTable 		= document.getElementById('customerInternalValuesTable');


	var targetTableBody	= targetTable.getElementsByTagName('tbody');
	var targetTableRows	= targetTableBody[0].getElementsByTagName('tr');
	var rowCount 			= targetTableRows.length;
	
	var objectiveID		= xml.getElementsByTagName('objectiveID')[0].innerHTML;
	
	
	
	// insert the objectiveID into the save action button at the bottom of the dialog...
	actionButton = customerInternalMetrics.querySelector('button, .save');
	actionButton.setAttribute('data-id', objectiveID);
	
	
	// insert the objectiveID into the hidden field on the dialog. Also.
	var dialog_customerInternalMetrics = document.getElementById('customerInternalMetrics');
	if (dialog_customerInternalMetrics) {
		var objectiveIDElem = dialog_customerInternalMetrics.querySelector('#objectiveID');
		if (objectiveIDElem) {
			objectiveIDElem.value = objectiveID;
		}
	}
		
		
	// delete all the <tr>'s from the <body>...
	for (i = targetTableRows.length-1; i >= 0; --i) {
		targetTableBody[0].removeChild(targetTableRows[i]);
	}

	// add new <tr>'s based on the data in the xml...

	var metricValues 		= xml.getElementsByTagName('metricValue');
	
	for (i = 0; i < metricValues.length; ++i) {
		
		var customerInternalMetricID = metricValues[i].getElementsByTagName('id')[0].innerHTML;
		
		// add a new row...
		var newRow = targetTableBody[0].insertRow(i);
		newRow.classList.add('internalMetricValue');
		newRow.setAttribute('id', 'customerInternalMetricID-'+customerInternalMetricID);
		newRow.setAttribute('data-metricID', customerInternalMetricID);
		newRow.addEventListener('mouseover', function() {
			ToggleMetricValueActionIcons(this)
		});
		newRow.addEventListener('mouseout', function() {
			ToggleMetricValueActionIcons(this)
		});
		
		
		// add a new cell for date...
		var newDateCell 			= newRow.insertCell(0);
		newDateCell.classList.add('mdl-data-table__cell--non-numeric');	
		newDateCell.classList.add('metricDate');	
		newDateCell.style.width = '200px';
		var newDateText			= document.createTextNode(metricValues[i].getElementsByTagName('date')[0].innerHTML);
		newDateCell.appendChild(newDateText);

		
		// add a new cell for value...
		var newValueCell 			= newRow.insertCell(1);
		newValueCell.classList.add('mdl-data-table__cell--non-numeric');	
		newValueCell.classList.add('metricValue');	
		newValueCell.style.width = '120px';
		var newValueText			= document.createTextNode(metricValues[i].getElementsByTagName('value')[0].innerHTML);
		newValueCell.appendChild(newValueText);

		
		// add a new cell for action icons...
		var newActionIconsCell = newRow.insertCell(2);
		newActionIconsCell.classList.add('mdl-data-table__cell--non-numeric');	
		newActionIconsCell.classList.add('metricButtons');	
		newActionIconsCell.style.width = '100px';
		var newActionIconDiv	= document.createElement('div');
		newActionIconDiv.setAttribute('id', 'internalMetricValue-'+customerInternalMetricID);
		newActionIconDiv.style.visibility = 'hidden';
		newActionIconDiv.style.float = 'right';
		newActionIconDiv.style.verticalAlign = 'middle';
		newActionIconDiv.style.align = 'center';
		newActionIconDiv.classList.add('internalMetricValueAciontIcons');

		var newDeleteIcon = document.createElement('i');
		newDeleteIcon.setAttribute('data-id', customerInternalMetricID)
		newDeleteIcon.classList.add('material-icons');
		newDeleteIcon.classList.add('deleteInternalMetric');
		newDeleteIcon.style.cursor = 'pointer';
		newDeleteIcon.style.verticalAlign = 'middle';
		newDeleteIcon.innerHTML = 'delete_outline';
		newDeleteIcon.addEventListener('click', function() {
			DeleteInteralMetricValue(this);
		});
		newActionIconDiv.appendChild(newDeleteIcon);

		var newEditIcon = document.createElement('i');
		newEditIcon.setAttribute('data-id', customerInternalMetricID)
		newEditIcon.classList.add('material-icons');
		newEditIcon.classList.add('editInternalMetric');
		newEditIcon.style.cursor = 'pointer';
		newEditIcon.style.verticalAlign = 'middle';
		newEditIcon.innerHTML = 'edit';
		newEditIcon.addEventListener('click', function() {
			EditInternalMetricValue(this);
		});
		newActionIconDiv.appendChild(newEditIcon);

		newActionIconsCell.appendChild(newActionIconDiv);

	}
	
	
	// metricID is the same across all results; save the metricID in the dialog....
	var metricID = xml.getElementsByTagName('metricID')[0].innerHTML
	document.getElementById('metricID').value = metricID;
	
		
	
// 	// add a row for "add an item"
// 	var newRow 		= targetTableBody[0].insertRow(metricValues.length);
// 	var newCell 	= newRow.insertCell(0);
// 	newCell.classList.add('mdl-data-table__cell--non-numeric');	
// 	newCell.setAttribute('colspan', 3);
// 	newCell.style.paddingLeft = '16px';
// 	newCell.style.fontWeight = 'bold';
// 	
// 	var newAddIcon = document.createElement('i');
// 	newAddIcon.classList.add("material-icons");
// 	newAddIcon.classList.add("addInternalMetric");
// 	newAddIcon.style.cursor = 'pointer';
// 	newAddIcon.style.verticalAlign = 'middle';
// 	newAddIcon.style.paddingRight = '8px';
// 	newAddIcon.setAttribute('data-objectiveID', objectiveID)
// 	newAddIcon.innerHTML = 'add';
// 	newAddIcon.addEventListener('click', function() {
// 		AddInternalMetricValue(this);
// 	});
// 	newCell.appendChild(newAddIcon);
// 		
// 	var newText		= document.createTextNode('Add a new item');
// 	newCell.appendChild(newText);

}



/*****************************************************************************************/
function PopulateNewMetricValueRow(tableIndex, metricID) {
/*****************************************************************************************/
	
	
	
	
}


/*****************************************************************************************/
function AddInternalMetricValue(htmlElement) {
/*****************************************************************************************/
	
	var metricID				= document.getElementById('metricID').value;
	var objectiveID			= htmlElement.getAttribute('data-objectiveid');
	var editRowElem 			= htmlElement.parentNode.parentNode;

	// hide all other edit buttons.....
	var editButtons = document.querySelectorAll('.editInternalMetric');
	for (i = 0; i < editButtons.length; ++i) {
		editButtons[i].style.display = 'none';
	}
	// hide all other delete buttons.....
	var deleteButtons = document.querySelectorAll('.deleteInternalMetric');
	for (i = 0; i < deleteButtons.length; ++i) {
		deleteButtons[i].style.display = 'none';
	}
	

	editRowElem.innerHTML = '';	
	
	var newDateCell = editRowElem.insertCell(0);
	newDateCell.style.width = '200px';
	newDateCell.style.paddingLeft = '18px';
	newDateCell.classList.add('metricDate');

	var newMetricDate = document.createElement('input');
	newMetricDate.type = 'date';
	newMetricDate.setAttribute('id', 'metricDate');
	newMetricDate.style.fontSize = '13px';
	newMetricDate.style.fontWeight = '400';
	newMetricDate.style.float = 'left';	
	newDateCell.appendChild(newMetricDate);
	
	
	
	var newValueCell = editRowElem.insertCell(1);
	newValueCell.style.width = '120px';
	newValueCell.style.paddingLeft = '15px';
	newValueCell.classList.add('metricValue');

	var newMetricValue = document.createElement('input');
	newMetricValue.type = 'text';
	newMetricValue.setAttribute('id', 'metricValue');
	newMetricValue.style.fontSize = '13px';
	newMetricValue.style.fontWeight = '400';
	newMetricValue.style.width = '75px';
	newMetricValue.style.float = 'left';
	newValueCell.appendChild(newMetricValue);
	



	var newButtonCell = editRowElem.insertCell(2);
	newButtonCell.style.width = '100px';
	newButtonCell.innerHTML 	= 	'<div class="editMetricValueAciontIcons" style="float: right; vertical-align: middle; align-content: center;">'
										+		'<i class="material-icons cancelEdit" title="Cancel changes" style="cursor: pointer; vertical-align: middle;">close</i>'
										+		'<i class="material-icons saveEdit" title="Save changes" data-objectiveid="' + objectiveID + '" style="cursor: pointer; vertical-align: middle;">check</i>'
										+	'</div>'
	
	
	var newCancelButton = editRowElem.querySelector('.cancelEdit');
	newCancelButton.addEventListener('click', function() {
		CancelInteralMetricValue(this);
	});
	
	var newSaveButton = editRowElem.querySelector('.saveEdit');
	newSaveButton.addEventListener('click', function() {
		SaveInteralMetricValue(this);
	});
	
	editRowElem.querySelector('#metricDate').focus();
	
	
}


/*****************************************************************************************/
function DeleteInteralMetricValue(htmlElement) {
/*****************************************************************************************/
	
	if(confirm('Are you sure you want to delete this metric value? This action cannot be undone.\n\n')) {

		var customerInternalMetricID = htmlElement.getAttribute('data-id');

		var requestURL = 'ajax/customerMetrics.asp?cmd=deleteCustomerInternalMetric'
												+ '&id=' + customerInternalMetricID;
												
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
					Complete_DeleteInteralMetricValue(request.responseXML);
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
function Complete_DeleteInteralMetricValue(xml) {
/*****************************************************************************************/
	
	var customerInternalMetricID 	= xml.getElementsByTagName('id')[0].innerHTML;
	var editRowElem 					= document.getElementById('customerInternalMetricID-'+customerInternalMetricID)
	var editTable						= editRowElem.parentNode.parentNode;
	
	editTable.deleteRow(editRowElem.rowIndex);
	

	
}


/*****************************************************************************************/
function EditInternalMetricValue	(htmlElement) {
/*****************************************************************************************/
		
	var editRowElem 			= htmlElement.closest('tr');
	
	// hide all other edit buttons.....
	var editButtons = document.querySelectorAll('.editInternalMetric');
	for (i = 0; i < editButtons.length; ++i) {
		editButtons[i].style.display = 'none';
	}
	// hide all other delete buttons.....
	var deleteButtons = document.querySelectorAll('.deleteInternalMetric');
	for (i = 0; i < deleteButtons.length; ++i) {
		deleteButtons[i].style.display = 'none';
	}
	
	
	var editDateElem 			= editRowElem.querySelector('.metricDate');
	var editDate	 			= editDateElem.innerText;
	editDateElem.innerHTML	=	'<input type="date" id="metricDate" data-orig="' + editDate + '" style="font-size: 13px; font-weight: 400;" value="' + moment(editDate).format('YYYY-MM-DD') + '">'
	editDateElem.style.paddingLeft = '18px';  // originally 24px
	
	var editValueElem			= editRowElem.querySelector('.metricValue');
	var editValue 				= editValueElem.innerText;
	editValueElem.innerHTML	=	'<input type="text" id="metricValue" data-orig="' + editValue + '" style="font-size: 13px; font-weight: 400; width: 75px;" value="' + editValue + '">'
	editValueElem.style.paddingLeft = '15px';  // originally 18px

	var editButtonsElem		= editRowElem.querySelector('.metricButtons');
	editButtonsElem.innerHTML 	= 	'<div class="editMetricValueAciontIcons" style="float: right; vertical-align: middle; align-content: center;">'
										+		'<i class="material-icons cancelEdit" title="Cancel changes" style="cursor: pointer; vertical-align: middle;">close</i>'
										+		'<i class="material-icons saveEdit" title="Save changes" style="cursor: pointer; vertical-align: middle;">check</i>'
										+	'</div>'
	
	var newCancelButton = editRowElem.querySelector('.cancelEdit');
	newCancelButton.addEventListener('click', function() {
		CancelInteralMetricValue(this);
	});
	
	var newSaveButton = editRowElem.querySelector('.saveEdit');
	newSaveButton.addEventListener('click', function() {
		SaveInteralMetricValue(this);
	});
	
	var dateInput = editRowElem.querySelector('#metricDate');
// 	editRowElem.querySelector('#metricDate').focus();
	dateInput.focus();
	
}


/*****************************************************************************************/
function CancelInteralMetricValue(htmlElement) {
/*****************************************************************************************/

	var editRowElem 					= htmlElement.closest('tr');

	var targetTable 		= document.getElementById('customerInternalValuesTable');
	var targetTableBody	= targetTable.getElementsByTagName('tbody');
	var targetTableRows	= targetTableBody[0].getElementsByTagName('tr');
	var rowCount 			= targetTableRows.length;
	
	if (editRowElem.rowIndex == rowCount) { // last row!

		editRowElem.parentNode.removeChild(editRowElem);
		rowCount = rowCount - 1;
		
		// add a row for "add an item"
	
		var newRow 		= targetTableBody[0].insertRow(rowCount);
		var newCell 	= newRow.insertCell(0);
		newCell.classList.add('mdl-data-table__cell--non-numeric');	
		newCell.setAttribute('colspan', 3);
		newCell.style.paddingLeft = '16px';
		newCell.style.fontWeight = 'bold';
		
		var newAddIcon = document.createElement('i');
		newAddIcon.classList.add("material-icons");
		newAddIcon.classList.add("addInternalMetric");
		newAddIcon.style.cursor = 'pointer';
		newAddIcon.style.verticalAlign = 'middle';
		newAddIcon.style.paddingRight = '8px';
		newAddIcon.setAttribute('data-objectiveID', objectiveID)
		newAddIcon.innerHTML = 'add';
		newAddIcon.addEventListener('click', function() {
			AddInternalMetricValue(this);
		});
		newCell.appendChild(newAddIcon);
			
		var newText		= document.createTextNode('Add a new item');
		newCell.appendChild(newText);		
		
	} else {
		
		var editDateElem 		= editRowElem.querySelector('.metricDate');
		var origDate		 	= editDateElem.childNodes[0].getAttribute('data-orig');
		var editValueElem		= editRowElem.querySelector('.metricValue');
		var origValue			= editValueElem.childNodes[0].getAttribute('data-orig');


		var editDateElem 		= editRowElem.querySelector('.metricDate');
		var origDate		 	= editDateElem.childNodes[0].getAttribute('data-orig');
	
		editDateElem.innerHTML = '';
		editDateElem.style.paddingLeft = '24px';
		var newDateText			= document.createTextNode(origDate);
		editDateElem.appendChild(newDateText);
		
	
		var editValueElem		= editRowElem.querySelector('.metricValue');
		var origValue			= editValueElem.childNodes[0].getAttribute('data-orig');
		
		editValueElem.innerHTML = '';
		editValueElem.style.paddingLeft = '18px';
		var newValueText		= document.createTextNode(origValue);
		editValueElem.appendChild(newValueText);
		
		var editButtonsElem	= editRowElem.querySelector('.metricButtons');
		if (editButtonsElem) {
			editButtonsElem.innerHTML = '';
		}

		if (editRowElem.getAttribute('id')) {
	
			var customerInternalMetricID 	= editRowElem.getAttribute('id').substring(editRowElem.getAttribute('id').indexOf('-')+1);
		
		
			var newActionIconDiv	= document.createElement('div');
			newActionIconDiv.setAttribute('id', 'internalMetricValue-'+customerInternalMetricID);
			newActionIconDiv.style.visibility = 'hidden';
			newActionIconDiv.style.float = 'right';
			newActionIconDiv.style.verticalAlign = 'middle';
			newActionIconDiv.style.align = 'center';
			newActionIconDiv.classList.add('internalMetricValueAciontIcons');
		
			var newDeleteIcon = document.createElement('i');
			newDeleteIcon.setAttribute('data-id', customerInternalMetricID)
			newDeleteIcon.classList.add('material-icons');
			newDeleteIcon.classList.add('deleteInternalMetric');
			newDeleteIcon.style.cursor = 'pointer';
			newDeleteIcon.style.verticalAlign = 'middle';
			newDeleteIcon.innerHTML = 'delete_outline';
			newDeleteIcon.addEventListener('click', function() {
				DeleteInteralMetricValue(this);
			});
			newActionIconDiv.appendChild(newDeleteIcon);
		
			var newEditIcon = document.createElement('i');
			newEditIcon.setAttribute('data-id', customerInternalMetricID)
			newEditIcon.classList.add('material-icons');
			newEditIcon.classList.add('editInternalMetric');
			newEditIcon.style.cursor = 'pointer';
			newEditIcon.style.verticalAlign = 'middle';
			newEditIcon.innerHTML = 'edit';
			newEditIcon.addEventListener('click', function() {
				EditInternalMetricValue(this);
			});
			newActionIconDiv.appendChild(newEditIcon);
		
			editButtonsElem.appendChild(newActionIconDiv);
		
		}

		
	}


	// un-hide all other edit buttons.....
	var editButtons = document.querySelectorAll('.editInternalMetric');
	for (i = 0; i < editButtons.length; ++i) {
		editButtons[i].style.display = 'inline-block';
	}
	//un-hide all other delete buttons.....
	var deleteButtons = document.querySelectorAll('.deleteInternalMetric');
	for (i = 0; i < deleteButtons.length; ++i) {
		deleteButtons[i].style.display = 'inline-block';
	}
	
}


/*****************************************************************************************/
function SaveInteralMetricValue(htmlElement) {
/*****************************************************************************************/

	var internalMetricValueElem = htmlElement.closest('.internalMetricValue');
	
	if (internalMetricValueElem) {
		customerInternalMetricID = internalMetricValueElem.getAttribute('data-metricID');
	} else {
		customerInternalMetricID = null;
	}
		

	var metricIdElem		= dialog_internalMetrics.querySelector('#metricID');
	var metricID			= metricIdElem.value; 


	if (htmlElement.classList.contains('saveEdit')) {
		
		var editDateElem 		= dialog_internalMetrics.querySelector('#metricDate');
		var editDate		 	= editDateElem.value;	
	
		var editValueElem		= dialog_internalMetrics.querySelector('#metricValue');
		var editValue			= editValueElem.value;
		
		var objectiveIdElem	= dialog_internalMetrics.querySelector('.add'); 
		var objectiveID 		= objectiveIdElem.getAttribute('data-id');

	} else {

		var editDateElem 		= dialog_newValue.querySelector('#addDate');
		var editDate		 	= editDateElem.value;	
	
		var editValueElem		= dialog_newValue.querySelector('#addValue');
		var editValue			= editValueElem.value;

		var objectiveIdElem	= dialog_newValue.querySelector('#objectiveID'); 
		var objectiveID 		= objectiveIdElem.value;

	}
	
	var rssdIdElem			= dialog_internalMetrics.querySelector('#rssdID');
	var rssdID				= rssdIdElem.value; 
	
	if (!metricID) {
		alert('Metric ID is missing!');
		return false;
	}
	

	if (!editDate) {
		alert('Metric date is required.');
		editDateElem.focus();
		return false;
	} else {
		if (!moment(editDate).isValid()) {
			alert('Metric date is invalid');
			editDateElem.focus();
			return false
		}
	}
	
	if (!editValue) {
		alert('Metric value required!');
		editValueElem.style.borderColor = 'crimson';
		editValueElem.focus();
		editValueElem.select();
		return false;
	}


	if (!rssdID) {
		alert('RSSD ID is missing!');
		return false;
	}
	
	if (!objectiveID) {
		alert('Objective ID is missing!');
		return false;
	}

	
	var requestURL = 'ajax/customerMetrics.asp?cmd=updateMetricValue'
										+ '&id='				+ customerInternalMetricID
										+ '&metricID='		+ metricID 
										+ '&date='			+ editDate 
										+ '&value='			+ editValue
										+ '&rssdid='		+ rssdID
										+ '&objectiveID='	+ objectiveID;
										
	console.log(requestURL);
	CreateRequest();
	
	if (request) {
		request.onreadystatechange = StateChangeHandler_SaveInternalMetricValue;
		request.open("GET", requestURL, true);
		request.send(null);
	}

	function StateChangeHandler_SaveInternalMetricValue() {
		
		if (request.readyState == 4) {
			if (request.status == 200) {
				Complete_SaveInternalMetricValue(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	}
	
	



}


/*****************************************************************************************/
function Complete_SaveInternalMetricValue(xml) {
/*****************************************************************************************/
	
	var customerInternalMetricID 	= xml.getElementsByTagName('id')[0].innerHTML;
	var metricDate 					= xml.getElementsByTagName('metricDate')[0].innerHTML;
	var metricValue 					= xml.getElementsByTagName('metricValue')[0].innerHTML;
	var objectiveID 					= xml.getElementsByTagName('objectiveID')[0].innerHTML;
	var metricID	 					= xml.getElementsByTagName('metricID')[0].innerHTML;
	
	var editRowElem;
	var editDateElem;
	if (customerInternalMetricID != 'null' && customerInternalMetricID.length > 0) {
		editRowElem 					= document.getElementById('customerInternalMetricID-'+customerInternalMetricID)
		editDateElem 					= editRowElem.querySelector('.metricDate');

		editDateElem.innerHTML = '';
		editDateElem.style.paddingLeft = '24px';
		var newDateText			= document.createTextNode(metricDate);
		editDateElem.appendChild(newDateText);
		
	
		var editValueElem		= editRowElem.querySelector('.metricValue');
		
		editValueElem.innerHTML = '';
		editValueElem.style.paddingLeft = '18px';
		var newValueText		= document.createTextNode(metricValue);
		editValueElem.appendChild(newValueText);
		
		var editButtonsElem	= editRowElem.querySelector('.metricButtons');
		editButtonsElem.innerHTML = '';
	
		var newActionIconDiv	= document.createElement('div');
		newActionIconDiv.setAttribute('id', 'internalMetricValue-'+customerInternalMetricID);
		newActionIconDiv.style.visibility = 'hidden';
		newActionIconDiv.style.float = 'right';
		newActionIconDiv.style.verticalAlign = 'middle';
		newActionIconDiv.style.align = 'center';
		newActionIconDiv.classList.add('internalMetricValueAciontIcons');
	
		var newDeleteIcon = document.createElement('i');
		newDeleteIcon.setAttribute('data-id', customerInternalMetricID)
		newDeleteIcon.classList.add('material-icons');
		newDeleteIcon.classList.add('deleteInternalMetric');
		newDeleteIcon.style.cursor = 'pointer';
		newDeleteIcon.style.verticalAlign = 'middle';
		newDeleteIcon.innerHTML = 'delete_outline';
		newDeleteIcon.addEventListener('click', function() {
			DeleteInteralMetricValue(this);
		});
		newActionIconDiv.appendChild(newDeleteIcon);
	
		var newEditIcon = document.createElement('i');
		newEditIcon.setAttribute('data-id', customerInternalMetricID)
		newEditIcon.classList.add('material-icons');
		newEditIcon.classList.add('editInternalMetric');
		newEditIcon.style.cursor = 'pointer';
		newEditIcon.style.verticalAlign = 'middle';
		newEditIcon.innerHTML = 'edit';
		newEditIcon.addEventListener('click', function() {
			EditInternalMetricValue(this);
		});
		newActionIconDiv.appendChild(newEditIcon);
	
		editButtonsElem.appendChild(newActionIconDiv);
	
		// un-hide all other edit buttons.....
		var editButtons = document.querySelectorAll('.editInternalMetric');
		for (i = 0; i < editButtons.length; ++i) {
			editButtons[i].style.display = 'inline-block';
		}
		//un-hide all other delete buttons.....
		var deleteButtons = document.querySelectorAll('.deleteInternalMetric');
		for (i = 0; i < deleteButtons.length; ++i) {
			deleteButtons[i].style.display = 'inline-block';
		}
		
	} else {

		var internalMetricDialog = document.querySelector('#customerInternalMetrics');
		var customerRSSDID			= document.getElementById('rssdID').value;

		GetCustomerInternalMetricValues(internalMetricDialog, customerRSSDID, objectiveID, metricID)
	}


	
	
}


/*****************************************************************************************/
function ObjectiveMetricName_onChange(metric) {
/*****************************************************************************************/
	
	var selectedMetricCtgy 		= metric.options[metric.selectedIndex].getAttribute('data-ctgy');
	var selectedMetricSection 	= metric.options[metric.selectedIndex].getAttribute('data-section');
	
	if ( metric.options[metric.selectedIndex].getAttribute('data-label') ) {
		var selectedMetricLabel		= metric.options[metric.selectedIndex].getAttribute('data-label').toLowerCase();
	} else {
		var selectedMetricLabel = null;
	}
	
	var selectedDataType			= metric.options[metric.selectedIndex].getAttribute('data-type');
	var selectedAnnualChangeID	= metric.options[metric.selectedIndex].getAttribute('data-annualchangeid');
	var selectedValue				= metric.options[metric.selectedIndex].value;
	
	var ubprLine 					= metric.options[metric.selectedIndex].getAttribute('data-line');
	var ubprLineElem 				= document.getElementById('objectiveUbprLine');
	
	
	if (selectedValue == 'Add new...') {
		document.getElementById('metricNameInput').parentNode.style.display = 'block';
		document.getElementById('metricNameInput').parentNode.classList.add('is-invalid');
		document.getElementById('metricNameInput').parentNode.classList.add('is-dirty');
		document.getElementById('metricNameInput').focus();
	} else {
		document.getElementById('metricNameInput').parentNode.style.display = 'none';
		document.getElementById('metricNameInput').parentNode.classList.remove('is-invalid');
		document.getElementById('metricNameInput').parentNode.classList.remove('is-dirty');
	}
	
	if (ubprLine) {
		if (ubprLine != 'null') {
			ubprLineElem.innerHTML = 'UBPR Line: ' + ubprLine;
		}
	} else {
		ubprLineElem.innerHTML = '';
	}
	
	// set the category selector to match the category of the selected metric...
	if (selectedMetricCtgy && selectedMetricCtgy != 'null') {
		var objectiveCategoryElem = document.getElementById('objectiveCategory');
		for (i = 0; objectiveCategoryElem.options.length; i++) {
	
			if (objectiveCategoryElem.options[i].innerText.trim()) {
				if (objectiveCategoryElem.options[i].innerText.trim() == selectedMetricCtgy) {
					objectiveCategoryElem.options[i].selected = true;
					objectiveCategoryElem.parentNode.classList.add('is-dirty');
					break;
				}
			}
		}
	}

	// display or hide the "corresponding annual change switch....
	if(selectedAnnualChangeID && selectedAnnualChangeID != 'null') {
		document.getElementById('showAnnualChangeEligible').style.display = 'block';
	} else {
		document.getElementById('showAnnualChangeEligible').style.display = 'none';
		
	}

	
	// set the upbrSection selector to match the section of the selected metric...
	if (selectedMetricSection && selectedMetricSection != 'null') {
		var objectiveSectionElem = document.getElementById('objectiveUbprSection');
		for (i = 0; objectiveSectionElem.options.length; i++) {
			
			if (objectiveSectionElem.options[i].innerText.trim()) {
				if (objectiveSectionElem.options[i].innerText.trim() == selectedMetricSection) {
					objectiveSectionElem.options[i].selected = true;
					objectiveSectionElem.parentNode.classList.add('is-dirty');
					break;
				}
			}
			
		}	
	}
	
	// set the labels for the start and end values....
	if (selectedMetricLabel && selectedMetricLabel != 'null') {
		document.getElementById('attributeStartValueLabel').innerHTML	= 'Start value (' + selectedMetricLabel + ')...';
		document.getElementById('attributeEndValueLabel').innerHTML 	= 'End value (' + selectedMetricLabel + ')...';
	} else {
		document.getElementById('attributeStartValueLabel').innerHTML = 'Start value...';
		document.getElementById('attributeEndValueLabel').innerHTML 	= 'End value...';
	}
	

	// set the pattern for different kinds of input datatypes...
	var regex;
	if (selectedDataType == 'currency') {
	
		regex = '^[+-]?[0-9]{1,3}(?:[0-9]*(?:[.,][0-9]{2})?|(?:,[0-9]{3})*(?:\\.[0-9]{2})?|(?:\\.[0-9]{3})*(?:,[0-9]{2})?)$';
	
	} else if (selectedDataType == 'percent') {

		regex = '[0-9]+(\\.[0-9]{0,2})?%?';

	} else {

		regex = null;

	}
	document.getElementById('objectiveStartValue').setAttribute('pattern', regex);
	document.getElementById('objectiveEndValue').setAttribute('pattern', regex);
	
	
	
		
	
}



/*****************************************************************************************/
function ObjectiveType_onChange(typeList, customerID) {
/*****************************************************************************************/
	
	var selectedType = typeList.options[typeList.selectedIndex].value;
	var requestURL = 'ajax/customerMetrics.asp';
	
	var objectiveCategoryElem 				= document.getElementById('objectiveCategory');
	var objectiveUbprSectionElem 			= document.getElementById('objectiveUbprSection');
	var objectiveUbprLineElem				= document.getElementById('objectiveUbprLine');
	var metricNameSelectElem 				= document.getElementById('metricNameSelect');
	var metricNameInputElem 				= document.getElementById('metricNameInput');
	var showAnnualChangeEligibleElem 	= document.getElementById('showAnnualChangeEligible');
	var peerGroupTypeIDElem 				= document.getElementById('peerGroupTypeID');
	var objectiveNarrativeElem 			= document.getElementById('objectiveNarrative');
	

	objectiveCategoryElem.value 			= null;
	objectiveUbprSectionElem.value 		= null;
	metricNameSelectElem.value 			= null;
	metricNameInputElem.value 				= null;
	peerGroupTypeIDElem.vaue 				= null;
	objectiveNarrativeElem.value 			= null;
	objectiveUbprLineElem.innerHTML		= null;

		
	if (selectedType == 1 ) { 		// Internal - Standard...
		
		typeList.parentNode.classList.remove('is-invalid');
		objectiveCategoryElem.parentNode.style.display 			= 'none';
		objectiveUbprSectionElem.parentNode.style.display 		= 'none';

		metricNameSelectElem.parentNode.style.display 			= 'block';
		metricNameSelectElem.selectedIndex 							= null;
		metricNameSelectElem.parentNode.classList.add('is-invalid');
		metricNameInputElem.parentNode.style.display 			= 'none';

		showAnnualChangeEligibleElem.style.display				= 'none';
		peerGroupTypeIDElem.parentNode.style.display 			= 'none';
		objectiveUbprLineElem.style.display 						= 'none';
		objectiveNarrative.parentNode.style.display 				= 'block';
		
		url = '/api/metrics/internal/standard';
		params = {}
		requestURL += '?cmd=getInternalMetricList&type=A';
		
		
	} else if (selectedType == 2) { 		// Internal - Customer Specific...
		
		typeList.parentNode.classList.remove('is-invalid');
		objectiveCategoryElem.parentNode.style.display 			= 'none';
		objectiveUbprSectionElem.parentNode.style.display 		= 'none';
		objectiveUbprLineElem.style.display 						= 'none';

		metricNameSelectElem.parentNode.style.display 			= 'block';
		metricNameInputElem.parentNode.style.display 			= 'none';

		showAnnualChangeEligibleElem.style.display				= 'none';
		peerGroupTypeIDElem.parentNode.style.display 			= 'none';
		objectiveUbprLineElem.style.display 						= 'none';
		objectiveNarrative.parentNode.style.display 				= 'block';

		url = '/api/metrics/internal/customer';
		params = { customerID: customerID };
		requestURL += '?cmd=getInternalMetricList&type=B&customerID=' + customerID;
		
		
	} else if (selectedType == 3) { 		// FDIC...
		
		typeList.parentNode.classList.remove('is-invalid');
		objectiveCategoryElem.parentNode.style.display 			= 'block';
		objectiveUbprSectionElem.parentNode.style.display 		= 'block';
		objectiveUbprLineElem.style.display 						= 'inline-blockl';

		metricNameSelectElem.parentNode.style.display 			= 'block';
		metricNameSelectElem.selectedIndex 							= null;
		metricNameSelectElem.parentNode.classList.add('is-invalid');

		objectiveUbprLineElem.style.display 						= 'inline-block';


		metricNameInputElem.parentNode.style.display 			= 'none';

		showAnnualChangeEligibleElem.style.display				= 'block';

		peerGroupTypeIDElem.parentNode.style.display 			= 'block';
		if (peerGroupTypeIDElem.value) {
			peerGroupTypeIDElem.parentNode.classList.remove('is-invalid');
		} else {
			peerGroupTypeIDElem.parentNode.classList.add('is-invalid');
		}

		objectiveNarrative.parentNode.style.display 				= 'block';

		url = '/api/metrics/fdic'
		params = {}
		requestURL += '?cmd=getFDICMetricList&source=2';
		
	} else { 		// Unknown...
		
		typeList.parentNode.classList.add('is-invalid');
		objectiveCategoryElem.parentNode.style.display 			= 'none';
		objectiveUbprSectionElem.parentNode.style.display 		= 'none';
		metricNameSelectElem.parentNode.style.display 			= 'none';
// 		metricNameInputElem.parentNode.style.display 			= 'none';
		showAnnualChangeEligibleElem.style.display				= 'none';
		peerGroupTypeIDElem.parentNode.style.display 			= 'none';
		objectiveNarrative.parentNode.style.display 				= 'none';
		return false;
		
	}
	
	$.ajax({
		url: 'http://' + serverName + ':3000' + url,
		data: params,
		success: function( json ) {
			
			$( '#metricNameSelect' )
				.find('option')
				.remove()
				.end();
				
			json.data.forEach( metric => {

				$( '#metricNameSelect' )
					.append( $('<option >')
						.val( metric.id )
						.text( metric.name )
						.attr({
							'data-line': metric.ubprLine,
							'data-ctgy': metric.financialCtgy,
							'data-section': metric.ubprSection,
							'data-label': metric.displayUnitsLabel,
							'data-type': metric.dataType,
							'data-annualChangeID': metric.correspondingAnnualChangeID
						})
					);
					

			});
			
			customerObjectiveDialog = document.getElementById('customerObjective');
			customerObjectiveDialog.style.top 	= ((window.innerHeight/2) - (customerObjectiveDialog.offsetHeight/2))+'px';

			if (selectedType == 2 ) {
				$( '#metricNameSelect' )
					.append( $('<option >')
					.text('Add new...')
				);
			}
			
		}
			
	})
	
	
/*
	// resize the <dialog> after controls are displayed/hidden...
*/

	
}


/*****************************************************************************************/
function Complete_GetMetrics(xml) {
/*****************************************************************************************/


/*
	var metricNameSelect 	= document.getElementById('metricNameSelect');
	
	metricNameSelect.options.length = 0;

	if (xml) {
		
		var type = xml.getElementsByTagName('metrics')[0].getAttribute('type');
		
		var searchResults = xml.getElementsByTagName('metric');
		var metricID, metricName, metricLine, metricCategory, metricSection, metricLabel, metricDataType;
		
		
	   metricNameSelect.innerHTML = metricNameSelect.innerHTML + '<option value="all"></option>';
		for (var i = 0; i < searchResults.length; i++) {
			metricID 						= searchResults[i].id;
			metricName 						= GetInnerText(searchResults[i]);
			metricLine 						= searchResults[i].getAttribute('data-line');
			metricCategory 				= searchResults[i].getAttribute('data-ctgy');
			metricSection					= searchResults[i].getAttribute('data-section');
			metricLabel						= searchResults[i].getAttribute('data-label');
			metricDataType					= searchResults[i].getAttribute('data-type');
			metricAnnualChangeID			= searchResults[i].getAttribute('data-changeID');
			
	      metricNameSelect.innerHTML = metricNameSelect.innerHTML + '<option value="' + metricID 
	      																		  + '" data-line="' + metricLine 
	      																		  + '" data-ctgy="' + metricCategory 
	      																		  + '" data-section="' + metricSection 
	      																		  + '" data-label="' + metricLabel 
	      																		  + '" data-type="' + metricDataType 
	      																		  + '" data-annualChangeID="' + metricAnnualChangeID 
	      																		  + '">' + metricName + '</option>';
		}
		
	}

	if (type == 'B') {
		metricNameSelect.innerHTML = metricNameSelect.innerHTML + '<option data-line="" data-ctgy="" data-section="" data-label="" data-type="" data-annualChangeInd="">Add new...</option>';
	}
*/
		
	
}


/*****************************************************************************************/
function UpdateAllFdicSelectors_onChange(htmlElement) {
/*****************************************************************************************/

	var selector = htmlElement.getAttribute('id');
	var selectedValue = htmlElement.options[htmlElement.selectedIndex].value;	
	
	
	
	var requestURL 	= "ajax/customerMetrics.asp?cmd=getAllFdicSelectors";
	
	if (selector == 'objectiveCategory') {
		requestURL += '&searchField=financialCtgy&value=' + selectedValue; 
	} else if (selector == 'objectiveUbprSection') {
		requestURL += '&searchField=ubprSection&value=' + selectedValue; 
	} else if (selector == 'objectiveUbprLine') {
		requestURL += '&searchField=ubprLine&value=' + selectedValue; 
	} else if (selector == 'objectiveMetricName') {
		requestURL += '&searchField=id&value=' + selectedValue; 
	} else {
		alert('Unknown FDIC selector encountered');
		return false;
	}
	
	if (selectedValue == 'all') {
		selector = 'all';
	}
	
	console.log(requestURL);
	CreateRequest();
	
	if (request) {
		request.onreadystatechange = StateChangeHandler_UpdateFdicSelectors;
		request.open("GET", requestURL, true);
		request.send(null);
	}

	function StateChangeHandler_UpdateFdicSelectors() {
		
		if (request.readyState == 4) {
			if (request.status == 200) {
				UpdateFdicSelectors(request.responseXML, selector, selectedValue);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	}


}



/*****************************************************************************************/
function UpdateFdicSelectors(xml, controlUsed, valueUsed) {
/*****************************************************************************************/

	if (controlUsed != 'objectiveCategory') {
	
		// Financial Categories...
		//
		var financialCategories	= xml.getElementsByTagName('financialCategory');
		var categoriesSelector 	= document.getElementById('objectiveCategory');
		var selectedCategory		= categoriesSelector.options[categoriesSelector.selectedIndex].value;
		var categoryName;
		
		categoriesSelector.options.length = 0;
		
		categoriesSelector.innerHTML = categoriesSelector.innerHTML + '<option value="all"></option>';
		for (var i = 0; i < financialCategories.length; i++) {
			categoryName 						= GetInnerText(financialCategories[i]);
	      categoriesSelector.innerHTML 	= categoriesSelector.innerHTML + '<option value="' + categoryName + '">' + categoryName + '</option>';
		}
		
		if (selectedCategory && selectedCategory != 'all') {
			for (var i = 0; categoriesSelector.options.length; i++) {
				if (categoriesSelector.options[i].value == selectedCategory) {
					categoriesSelector.options[i].selected = true;
					break;
				}
			}
		} else {
			categoriesSelector.parentNode.classList.remove('is-dirty');
		}
		
	}		
	
	
	if (controlUsed != 'objectiveUbprSection') {

		// UBPR sections...
		//
		var ubprSections				= xml.getElementsByTagName('ubprSection');
		var ubprSectionsSelector 	= document.getElementById('objectiveUbprSection');
		var selectedSection			= ubprSectionsSelector.options[ubprSectionsSelector.selectedIndex].value;
		var ubprSectionName;
		
		ubprSectionsSelector.options.length = 0;
		
	   ubprSectionsSelector.innerHTML = ubprSectionsSelector.innerHTML + '<option value="all"></option>';

		for (var i = 0; i < ubprSections.length; i++) {
			ubprSectionName 						= GetInnerText(ubprSections[i]);
	      ubprSectionsSelector.innerHTML = ubprSectionsSelector.innerHTML + '<option value="' + ubprSectionName + '">' + ubprSectionName + '</option>';
		}
		
		if (selectedSection && selectedSection != 'all') {
			for (var i = 0; ubprSectionsSelector.options.length; i++) {
				if (ubprSectionsSelector.options[i].value == selectedSection) {
					ubprSectionsSelector.options[i].selected = true;
					break;
				}
			}
		} else {
			ubprSectionsSelector.parentNode.classList.remove('is-dirty');
		}
	
	}
	
	
	if (controlUsed != 'objectiveUbprLine') {
	
		// UBPR lines...
		//
		var ubprLines				= xml.getElementsByTagName('ubprLine');
		var ubprLinesSelector 	= document.getElementById('objectiveUbprLine');
		var selectedLine			= ubprLinesSelector.options[ubprLinesSelector.selectedIndex].value;
		var ubprLine;
		
		ubprLinesSelector.options.length = 0;
		
		ubprLinesSelector.innerHTML = ubprLinesSelector.innerHTML + '<option value="all"></option>';		
		for (var i = 0; i < ubprLines.length; i++) {
			ubprLine 						= GetInnerText(ubprLines[i]);
	      ubprLinesSelector.innerHTML = ubprLinesSelector.innerHTML + '<option value="' + ubprLine + '">' + ubprLine + '</option>';
		}
		
		if (selectedLine && selectedLine != 'all') {
			for (var i = 0; ubprLinesSelector.options.length; i++) {
				if (ubprLinesSelector.options[i].value == selectedLine) {
					ubprLinesSelector.options[i].selected = true;
					break;
				}
			}
		} else {
			ubprLinesSelector.parentNode.classList.remove('is-dirty');
		}
	
	}
	
	
	if (controlUsed != 'objectiveMetricName') {
	
		// Metric name...
		//
		var metrics				= xml.getElementsByTagName('metric');
		var metricSelector 	= document.getElementById('objectiveMetricName');
		var selectedMetric	= metricSelector.options[metricSelector.selectedIndex].value;
		var metric;
		var metricID;
		
		metricSelector.options.length = 0;
		
		metricSelector.innerHTML = '<option value="all"></option>';
			
		for (var i = 0; i < metrics.length; i++) {
			metricID 						= metrics[i].id;
			metric 							= GetInnerText(metrics[i]);
	      metricSelector.innerHTML 	+= '<option value="' + metricID + '">' + metric + '</option>';
		}
		
		if (selectedMetric && selectedMetric != 'all') {
			for (var i = 0; metricSelector.options.length; i++) {
				if (metricSelector.options[i].value == selectedMetric) {
					metricSelector.options[i].selected = true;
					break;
				}
			}
		} else {
			metricSelector.parentNode.classList.remove('is-dirty');
		}
	
	}
	
	
}



/*****************************************************************************************/
function ObjectUbprSection_onChange(sectionList) {
/*****************************************************************************************/


	var categorySelector = document.getElementById('objectiveCategory');

	var selectedCategory;
	if (categorySelector.selectedIndex >= 0) {
		selectedCategory = categorySelector[categorySelector.selectedIndex].value;
	} else {
		selectedCategory = '';
	}

	var selectedSectyion;
	if (sectionList.selectedIndex >= 0) {	 
		selectedSection = sectionList.options[sectionList.selectedIndex].value;
	} else {
		selectedSection = '';
	}
	
	var requestUrl = "ajax/customerMetrics.asp?cmd=getMetrics&ctgy=" + selectedCategory + "&section=" + encodeURIComponent(selectedSection);
	
	console.log(requestUrl);
					
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdateMetrics;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


	function StateChangeHandler_UpdateMetrics() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				
				Complete_UpdateMetrics(request.responseXML);

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}


/*****************************************************************************************/
function Complete_UpdateMetrics(xml) {
/*****************************************************************************************/
	
	var metrics					= xml.getElementsByTagName('metric');
	var metricsSelector		= document.getElementById('metricNameSelect');
	var metricID, metricName, metricLine, metricCategory, metricSection;	
	
	metricsSelector.options.length = 0;
   metricsSelector.innerHTML = metricsSelector.innerHTML + '<option></option>';
	for (var i = 0; i < metrics.length; i++) {
		metricID 						= metrics[i].id;
		metricName 						= GetInnerText(metrics[i]);
		metricLine 						= metrics[i].getAttribute('data-line');
		metricCategory 				= metrics[i].getAttribute('data-ctgy');
		metricSection					= metrics[i].getAttribute('data-section');
      metricsSelector.innerHTML = metricsSelector.innerHTML + '<option value="' + metricID + '" data-line="' + metricLine + '" data-ctgy="' + metricCategory + '" data-section="' + metricSection + '">' + metricName + '</option>';
	}
	
	document.getElementById('objectiveUbprLine').innerHTML = '';

	
}




/*****************************************************************************************/
function ObjectiveCategory_onChange(ctgyList) {
/*****************************************************************************************/
	
	var selectedCategory = ctgyList.options[ctgyList.selectedIndex].value;
	
	// update UBPR Section...
	var requestUrl 	= "ajax/customerMetrics.asp?cmd=getSectionsMetrics&ctgy=" + selectedCategory;

	console.log(requestUrl);
					
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_UpdateSections;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


	function StateChangeHandler_UpdateSections() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				
				Complete_UpdateSections(request.responseXML);

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}


}



/*****************************************************************************************/
function Complete_UpdateSections(xml) {
/*****************************************************************************************/
	
	var ubprSections			= xml.getElementsByTagName('section');
	var sectionsSelector 	= document.getElementById('objectiveUbprSection');
	var ubprSectionName;
	
	var metrics					= xml.getElementsByTagName('metric');
	var metricsSelector		= document.getElementById('objectiveMetricName');
	var metricID, metricName, metricLine, metricSection, metricCategory;	
	
	sectionsSelector.options.length = 0;
   sectionsSelector.innerHTML = sectionsSelector.innerHTML + '<option></option>';
	for (var i = 0; i < ubprSections.length; i++) {
		ubprSectionName 				= GetInnerText(ubprSections[i]);
      sectionsSelector.innerHTML = sectionsSelector.innerHTML + '<option value="' + ubprSectionName + '">' + ubprSectionName + '</option>';
	}
	
	metricsSelector.options.length = 0;
   metricsSelector.innerHTML = metricsSelector.innerHTML + '<option></option>';
	for (var i = 0; i < metrics.length; i++) {
		metricID					= metrics[i].getAttribute('id');
		metricName 				= GetInnerText(metrics[i]);
		metricLine				= metrics[i].getAttribute('data-line');
		metricSection			= metrics[i].getAttribute('data-section');
		metricCategory			= metrics[i].getAttribute('data-ctgy');
      metricsSelector.innerHTML 	= metricsSelector.innerHTML + '<option value="' + metricID + '" data-line="' + metricLine + '" data-section="' + metricSection + '" data-ctgy="' + metricCategory + '">' + metricName + '</option>';
	}
	
	document.getElementById('objectiveUbprLine').innerHTML = '';
	
	
}


/*****************************************************************************************/
function formatMoney(amount, decimalCount = 2, decimal = ".", thousands = ",") {
/*****************************************************************************************/

  try {

    decimalCount = Math.abs(decimalCount);
    decimalCount = isNaN(decimalCount) ? 2 : decimalCount;

    const negativeSign = amount < 0 ? "-$" : "$";

    let i = parseInt(amount = Math.abs(Number(amount) || 0).toFixed(decimalCount)).toString();
    let j = (i.length > 3) ? i.length % 3 : 0;

    return negativeSign + (j ? i.substr(0, j) + thousands : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousands) + (decimalCount ? decimal + Math.abs(amount - i).toFixed(decimalCount).slice(2) : "");

  } catch (e) {

    console.log(e)

  }

}


/*****************************************************************************************/
function EditCustomerObjective_onClick(htmlElement, type) {
/*****************************************************************************************/

	var formatter = new Intl.NumberFormat('en-US', {
		style: 'currency',
		currency: 'USD',
		minimumFractionDigits: 0,
	})

	if (type == 'utopia') {
		document.getElementById('objectiveDialogTitle').innerHTML = 'Edit Utopia Objective';
		document.getElementById('objectiveTypeID').value	= 1;
	} else {
		document.getElementById('objectiveDialogTitle').innerHTML = 'Edit Opportunity Objective';
		document.getElementById('objectiveTypeID').value	= 2;
	}

	// show the modal dialog early for debugging/development...
	dialog_objective.showModal();
	

	/*-----------------------------------------------------------------------------*/
	// this onChange function will display/hide the controls based un the metricType
	// (eg, FDIC, Standard, Custom). After that, populate the fields
	/*-----------------------------------------------------------------------------*/
	var objectiveID 				= htmlElement.getAttribute('data-id');
	var objectiveType				= document.getElementById('metricType-'+objectiveID).innerText;
	var objectiveTypeElem	 	= document.getElementById('objectiveType');
	if (!objectiveType) {
		alert("Unexpected objective type encountered; contact your your system administrator.");
		return false;
	}
	for (var i = 0; objectiveTypeElem.options.length; i++) {
		if (objectiveTypeElem.options[i].innerText.trim() == objectiveType) {
			objectiveTypeElem.options[i].selected = true;
			break;
		}
	}
// 	var objectiveMetricName			= document.getElementById('metricName-'+objectiveID).innerText;
// 	ObjectiveType_onChange(objectiveTypeElem,objectiveMetricName); 







	
	// these values come from the row that was clicked; use these values to populate the dialog...

	var objectiveMetricName			= document.getElementById('metricName-'+objectiveID).innerText;
	var showAnnualChangeEligible	= document.getElementById('showAnnualChangeEligible-'+objectiveID).value;
	var showAnnualChangeInd			= document.getElementById('showAnnualChangeInd-'+objectiveID).value;
	var peerGroupTypeID				= document.getElementById('peerGroupTypeID-'+objectiveID).value;
	var objectiveNarrative			= document.getElementById('narrative-'+objectiveID).innerHTML.replace('<hr>','');
	var objectiveStartDate			= document.getElementById('startDate-'+objectiveID).innerHTML;
	var objectiveEndDate				= document.getElementById('endDate-'+objectiveID).innerHTML;
	var objectiveStartValue			= document.getElementById('startValue-'+objectiveID).innerHTML.replace('$','').replace(',','').replace('%','');
	var objectiveEndValue			= document.getElementById('endValue-'+objectiveID).innerHTML.replace('$','').replace(',','').replace('%','');
	
// 	var objectiveTypeID;
// 	if (type.toLowerCase() == 'utopia') {
// 		objectiveTypeID  				= 1;
// 	} else {
// 		objectiveTypeID				= 2;
// 	}
	
	var opportunityID					= htmlElement.getAttribute('data-opp');
	var implementationID				= htmlElement.getAttribute('data-impl');
	var customerID;					/* this one is needed! */
	var objectiveMetricID;			/* don't know about this one */
	var dataType;
	var displayUnitsLabel;


	// now populate the dialog....
	var objectiveMetricNameElem			= document.getElementById('metricNameSelect');
	var objectiveMetricNameCustomElem	= document.getElementById('metricNameInput');
	var objectiveCategoryElem				= document.getElementById('objectiveCategory');
	var objectiveUbprSectionElem			= document.getElementById('objectiveUbprSection');
	var objectiveUbprLineElem				= document.getElementById('objectiveUbprLine');
	var showAnnualChangeEligibleElem		= document.getElementById('showAnnualChangeEligible');
	var peerGroupTypeIDElem					= document.getElementById('peerGroupTypeID');

	if (objectiveType == 'Internal - Standard') {

		for (var i = 0; objectiveMetricNameElem.options.length; i++) {
			if (objectiveMetricNameElem.options[i].innerText.trim() == objectiveMetricName) {
				objectiveMetricNameElem.options[i].selected = true;
				break;
			}
		}
		objectiveMetricNameElem.parentNode.classList.add('is-dirty');
		objectiveMetricNameElem.parentNode.classList.remove('is-invalid');
		objectiveMetricNameCustomElem.value = objectiveMetricName;
		
		objectiveCategoryElem.parentNode.style.display = 'none';
		objectiveUbprSectionElem.parentNode.style.display = 'none';
		objectiveUbprLineElem.style.display = 'none';
		showAnnualChangeEligibleElem.style.display = 'none';
		peerGroupTypeIDElem.parentNode.style.display = 'none';


	} else if (objectiveType == 'Internal - Customer Specific') {

		for (var i = 0; objectiveMetricNameElem.options.length; i++) {
			if (objectiveMetricNameElem.options[i].innerText.trim() == objectiveMetricName) {
				objectiveMetricNameElem.options[i].selected = true;
				break;
			}
		}
		objectiveMetricNameCustomElem.value = objectiveMetricName;
		objectiveMetricNameCustomElem.parentNode.classList.add('is-dirty');
		objectiveMetricNameCustomElem.parentNode.classList.remove('is-invalid');
		objectiveMetricNameCustomElem.parentNode.style.display = 'block';
		
		objectiveMetricNameElem.parentNode.style.display = 'none';
		
		objectiveCategoryElem.parentNode.style.display = 'none';
		objectiveUbprSectionElem.parentNode.style.display = 'none';
		objectiveUbprLineElem.style.display = 'none';
		showAnnualChangeEligibleElem.style.display = 'none';
		peerGroupTypeIDElem.parentNode.style.display = 'none';


	} else if (objectiveType == 'FDIC') {

		for (var i = 0; objectiveMetricNameElem.options.length; i++) {
			if (objectiveMetricNameElem.options[i].innerText.trim() == objectiveMetricName) {
				objectiveMetricNameElem.options[i].selected = true;
				break;
			}
		}
		
		
		objectiveMetricNameElem.parentNode.classList.add('is-dirty');
		objectiveMetricNameElem.parentNode.classList.remove('is-invalid');
		objectiveMetricNameElem.parentNode.style.display = 'block';
		
		objectiveMetricNameCustomElem.value = objectiveMetricName;
		objectiveMetricNameCustomElem.parentNode.style.display = 'none';

		objectiveCategoryElem.parentNode.style.display = 'block';
		objectiveUbprSectionElem.parentNode.style.display = 'block';
		objectiveUbprLineElem.style.display = 'inline-block';
		showAnnualChangeEligibleElem.style.display = 'block';
		peerGroupTypeIDElem.parentNode.style.display = 'block';



	} else {
		
		alert('Unexpected objective type encountered; contact system administrator');
		return false;
		
	}
	
	var objectiveNarrativeElem = document.getElementById('objectiveNarrative');
	objectiveNarrativeElem.innerHTML = objectiveNarrative;
	objectiveNarrativeElem.parentNode.style.display = 'block';
	objectiveNarrativeElem.parentNode.classList.remove('is-invalid');
	
	if (objectiveNarrative) {
		objectiveNarrativeElem.parentNode.classList.add('is-dirty');
	} else {
		objectiveNarrativeElem.parentNode.classList.remove('is-dirty');
	}
	
	

	if (moment(objectiveStartDate).isValid()) {
		document.getElementById('objectiveStartDate').value = moment(objectiveStartDate).format('YYYY-MM-DD');
	} else {
		document.getElementById('objectiveStartDate').value = null;		
	}
	document.getElementById('objectiveStartDate').parentNode.classList.remove('is-invalid');		
	document.getElementById('objectiveStartDate').parentNode.classList.add('is-dirty');
	
	
	if (moment(objectiveEndDate).isValid()) {
		document.getElementById('objectiveEndDate').value = moment(objectiveEndDate).format('YYYY-MM-DD');
	} else {
		document.getElementById('objectiveEndDate').value = null;
	}
	document.getElementById('objectiveEndDate').parentNode.classList.remove('is-invalid');		
	document.getElementById('objectiveEndDate').parentNode.classList.add('is-dirty');
	

	// set the regular expression for the pattern="" attribute of the <input> element
	// remember that back-slashes need to be doubled up in a string..

	var regex;

	if (dataType) {
		if (dataType == 'currency') {
			// regex = '^\\$?\\d*(\\.\\d{0}$)?';
			regex = '^[+-]?[0-9]{1,3}(?:[0-9]*(?:[.,][0-9]{2})?|(?:,[0-9]{3})*(?:\\.[0-9]{2})?|(?:\\.[0-9]{3})*(?:,[0-9]{2})?)$';
		} else if (dataType == 'percent') {
			regex = '[0-9]+(\\.[0-9]{0,2})?%?';
		} else {
			regex = null;
		}
	} else {
		regex = null;
	}
	document.getElementById('objectiveStartValue').setAttribute('pattern', regex);
	document.getElementById('objectiveEndValue').setAttribute('pattern', regex);
	

	// format the startValue and update the input elements on the dialog...
	var startValue;
	if (objectiveStartValue) {
		
		if (!isNaN(objectiveStartValue)) {
			if (dataType == 'currency') {
				if (displayUnitsLabel == 'millions') {
					startValue = formatMoney(objectiveStartValue, 3);
				} else {
					startValue = formatMoney(objectiveStartValue, 2);
				}
			} else if (dataType == 'percent') {
				startValue = parseFloat(objectiveStartValue).toFixed(3)+'%'
			} else { /* else leave startValue as-is */
				startValue = objectiveStartValue;
			}
		}
		document.getElementById('objectiveStartValue').parentNode.classList.add('is-dirty');
		
	} else {

		startValue = null;
		document.getElementById('objectiveStartValue').parentNode.classList.remove('is-dirty');
		
	}

	document.getElementById('objectiveStartValue').value = startValue;
	
	
	// format the endValue and update the input elements on the dialog...
	var endValue;
	if (objectiveEndValue) {
		
		if (!isNaN(objectiveEndValue)) {
			if (dataType == 'currency') {
				if (displayUnitsLabel == 'millions') {
					endValue = formatMoney(objectiveEndValue, 3);
				} else {
					endValue = formatMoney(objectiveEndValue, 2);
				}
			} else if (dataType == 'percent') {
				endValue = parseFloat(objectiveEndValue).toFixed(3)+'%'
			} else { /* else leave startValue as-is */
				endValue = objectiveEndValue;
			}
		}
		document.getElementById('objectiveEndValue').parentNode.classList.add('is-dirty');
		
	} else {

		endValue = null;
		document.getElementById('objectiveEndValue').parentNode.classList.remove('is-dirty');
		
	}

	document.getElementById('objectiveEndValue').value = endValue;
	

	document.getElementById('objectiveID').value 		= objectiveID;
	document.getElementById('opportunityID').value		= opportunityID;
	document.getElementById('implementationID').value 	= implementationID;
	

	if (displayUnitsLabel) {
		document.getElementById('attributeStartValueLabel').innerHTML = 'Start value (' + displayUnitsLabel + ')...';
		document.getElementById('attributeEndValueLabel').innerHTML	 = 'End value (' + displayUnitsLabel + ')...';
	}


	return;



//========================================================================================
//========================================================================================
//========================================================================================
//========================================================================================
//========================================================================================



	// populate/format dialog controls with values from row...

	var categorySelector						= document.getElementById('objectiveCategory');
	var sectionSelector						= document.getElementById('objectiveUbprSection');
	var ubprLineElem							= document.getElementById('objectiveUbprLine');
	var objectiveMetricNameElem			= document.getElementById('objectiveMetricName');
	var objectiveMetricNameCustomElem	= document.getElementById('objectiveMetricNameCustom');
	var peerGroupTypeIDSelector 			= document.getElementById('peerGroupTypeID');
	var objectiveNarrativeElem				= document.getElementById('objectiveNarrative');
	var objectiveUbprLine					= document.getElementById('objectiveUbprLine');
	var objectiveNarrativeElem				= document.getElementById('objectiveNarrative');
	

	if (objectiveType == 'Internal - Standard') {
		
		categorySelector.parentNode.style.display 								= 'none';
		sectionSelector.parentNode.style.display									= 'none';
		peerGroupTypeIDSelector.parentNode.style.display 						= 'none';
		ubprLineElem.style.display 													= 'none';	
		document.getElementById('showAnnualChangeEligible').style.display = 'none';

		ObjectiveType_onChange(objectiveTypeSelector);

		for (var i = 0; objectiveMetricNameElem.options.length; i++) {
			if (objectiveMetricNameElem.options[i].innerText.trim() == metricName) {
				objectiveMetricNameElem.options[i].selected = true;
				break;
			}
		}
		objectiveMetricNameElem.parentNode.style.display 						= 'block';

		objectiveMetricNameCustomElem.parentNode.style.display 				= 'none';


	} else if (objectiveType == 'Internal - Customer Specific') {
		
		categorySelector.parentNode.style.display 				= 'none';
		sectionSelector.parentNode.style.display					= 'none';
		peerGroupTypeIDSelector.parentNode.style.display 		= 'none';
		ubprLineElem.style.display 									= 'none';	
		document.getElementById('showAnnualChangeEligible').style.display = 'none';
		
		for (var i = 0; objectiveMetricNameElem.options.length; i++) {
			if (objectiveMetricNameElem.options[i].innerText.trim() == metricName) {
				objectiveMetricNameElem.options[i].selected = true;
				break;
			}
		}
		objectiveMetricNameElem.parentNode.style.display = 'none';
		
		objectiveMetricNameCustomElem.value = metricName;
		objectiveMetricNameCustomElem.parentNode.style.display = 'block';
		objectiveMetricNameCustomElem.parentNode.classList.add('is-dirty');
		objectiveMetricNameCustomElem.parentNode.classList.remove('is-invalid');

		
	} else {
		
		ObjectiveType_onChange(objectiveTypeSelector);

		for (var i = 0; categorySelector.options.length; i++) {
			if (categorySelector.options[i].value == category) {
				categorySelector.options[i].selected = true;
				break;
			}
		}
		categorySelector.parentNode.style.display = 'block';
		categorySelector.parentNode.classList.add('is-dirty');;
		

		for (var i = 0; sectionSelector.options.length; i++) {
			if (sectionSelector.options[i].value == section) {
				sectionSelector.options[i].selected = true;
				break;
			}
		}
		sectionSelector.parentNode.style.display = 'block';
		sectionSelector.parentNode.classList.add('is-dirty');;


		if (showAnnualChangeEligible) {
			document.getElementById('showAnnualChangeEligible').style.display = 'block';
			peerGroupTypeIDSelector.parentNode.style.display = 'none';

			if (showAnnualChangeInd == true || showAnnualChangeInd == 'True') {
				document.getElementById('showAnnualChangeInd').parentNode.classList.add('is-checked');
			} else {
				document.getElementById('showAnnualChangeInd').parentNode.classList.remove('is-checked');				
			}

		} else {

			document.getElementById('showAnnualChangeEligible').style.display = 'none';
			peerGroupTypeIDSelector.parentNode.style.display = 'block';
			peerGroupTypeIDSelector.parentNode.classList.add('is-dirty');
			
			for (i = 0; peerGroupTypeIDSelector.options.length; i++) {
				if (peerGroupTypeIDSelector.options[i].value == peerGroupTypeID) {
					peerGroupTypeIDSelector.options[i].selected = true;
					peerGroupTypeIDSelector.parentNode.classList.remove('is-invalid');
					break;
				}
			}
			
		}


		peerGroupTypeIDSelector.parentNode.style.display 		= 'block';

		for (var i = 0; objectiveMetricNameElem.options.length; i++) {
			if (objectiveMetricNameElem.options[i].innerText.trim() == metricName) {
				objectiveMetricNameElem.options[i].selected = true;
				ubprLineElem.style.display = 'block';		
				ubprLineElem.innerHTML = 'UBPR Line: ' + objectiveMetricNameElem.options[i].getAttribute('data-line');
				break;
			}
		}
		objectiveMetricNameElem.parentNode.style.display = 'block';
		objectiveMetricNameElem.parentNode.classList.add('is-dirty');

	}

	objectiveNarrativeElem.innerHTML 							= objectiveNarrative;
	objectiveNarrativeElem.parentNode.style.display 		= 'block';		
	objectiveNarrativeElem.parentNode.classList.add('is-dirty');
	objectiveNarrativeElem.parentNode.classList.remove('is-invalid');

	

	
	
	
// 	dialog_objective.showModal();

	
}



/*****************************************************************************************/
function deleteCustomerObjective_onClick(htmlElement, type) {
/*****************************************************************************************/
	
	if (confirm('Are you sure you want to delete this Utopia?\n\nThis action cannot be undone.')) {

		var customerObjectiveID = htmlElement.getAttribute('data-id');

		var requestUrl	= 'ajax/customerMetrics.asp?cmd=deleteCustomerObjective&id=' + customerObjectiveID;
		
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_DeleteCustomerObjective;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_DeleteCustomerObjective() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {


					location = location;


				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
	
	} else {
		
		return false;
		
	}
	
	
}


/*****************************************************************************************/
function EditCustomerOpportunity_onClick(htmlElement) {
/*****************************************************************************************/
	
	// show the modal dialog early for debugging/development...
	dialog_opportunity.showModal();

	document.getElementById('opportunityDialogTitle').innerHTML = 'Edit Opportunity';
	
	// get values from "row"...
	var oppID			 				= htmlElement.getAttribute('data-opp');
	var oppNarrative					= document.getElementById('oppNarrative-'+oppID).innerHTML;
	var oppStartDate					= document.getElementById('oppStartDate-'+oppID).innerHTML;
	var oppEndDate						= document.getElementById('oppEndDate-'+oppID).innerHTML
	var oppValue						= document.getElementById('oppValue-'+oppID).innerHTML;


	// populate/format dialog controls with values from row...
	
	if (oppID) {
		document.getElementById('opportunityID').value = oppID;
	} else {
		alert('Opportunity ID missing; unexpected condition');
		return false;
	}
		

	if (oppNarrative) {
		document.getElementById('opportunityNarrative').value = oppNarrative;
		document.getElementById('opportunityNarrative').parentNode.classList.remove('is-invalid');
		document.getElementById('opportunityNarrative').parentNode.classList.add('is-dirty');
	} else {
		document.getElementById('opportunityNarrative').parentNode.classList.add('is-invalid');
		document.getElementById('opportunityNarrative').parentNode.classList.remove('is-dirty');
	}

	
	if (moment(oppStartDate).isValid()) {
		document.getElementById('opportunityStartDate').value = moment(oppStartDate).format('YYYY-MM-DD');
		document.getElementById('opportunityStartDate').parentNode.classList.remove('is-invalid');
	} else {
		document.getElementById('opportunityStartDate').parentNode.classList.add('is-invalid');		
	}
	document.getElementById('opportunityStartDate').parentNode.classList.add('is-dirty');
	

	if (moment(oppEndDate).isValid()) {
		document.getElementById('opportunityEndDate').value = moment(oppEndDate).format('YYYY-MM-DD');
		document.getElementById('opportunityEndDate').parentNode.classList.remove('is-invalid');
	} else {
		document.getElementById('opportunityEndDate').parentNode.classList.add('is-invalid');
	}
	document.getElementById('opportunityEndDate').parentNode.classList.add('is-dirty');
	

	if (oppValue) {
		document.getElementById('opportunityValue').value = Number(oppValue.replace(/[^0-9.-]+/g,""));
		document.getElementById('opportunityValue').parentNode.classList.add('is-dirty');
		document.getElementById('opportunityValue').parentNode.classList.remove('is-invalid');
	} else {
		document.getElementById('opportunityValue').parentNode.classList.remove('is-dirty');
		document.getElementById('opportunityValue').parentNode.classList.add('is-invalid');
	}

	
}



/*****************************************************************************************/
function EditCustomerOpportunity_onSave(htmlDialog) {
/*****************************************************************************************/
	
	
	var opportunityID 			= document.getElementById('opportunityID').value;
	var implementationID 		= document.getElementById('oppImplementationID').value;
	var narrative				 	= document.getElementById('opportunityNarrative').value;
	var startDate 	 				= document.getElementById('opportunityStartDate').value;
	var endDate						= document.getElementById('opportunityEndDate').value;
	var value						= document.getElementById('opportunityValue').value;

	if (!narrative) {
		alert('Narrative is required');
		document.getElementById('opportunityNarrative').focus();
		return false;	
	}
	
	
	if (startDate) {
		if (! moment(startDate).isValid()) {
			alert('Opportunity start date is not a valid date');
			document.getElementById('opportunityStartDate').focus();
			return false;
		}
	} else {
		alert('Opportunity start date is required');
		document.getElementById('opportunityStartDate').focus();
		return false;
	}

	if (endDate) {
		if (! moment(endDate).isValid()) {
			alert('Opportunity end date is not a valid date');
			document.getElementById('opportunityEndDate').focus();
			return false;
		}
	} else {
		alert('Opportunity end date is required');
		document.getElementById('opportunityEndDate').focus();
		return false;
	}

	if (!value) {
		alert('Value is required');
		document.getElementById('opportunityValue').focus();
		return false;
	}

		
	var payload = "opportunityID="				+ opportunityID
					+ "&implementationID="			+ implementationID 
					+ "&narrative="					+ encodeURIComponent(narrative)
					+ "&startDate=" 				+ encodeURIComponent(startDate)
					+ "&EndDate=" 					+ encodeURIComponent(endDate)
					+ "&value=" 						+ value;
		
	console.log(payload);
		
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_AddMetric;
		request.open("POST", "ajax/customerMetrics.asp?cmd=updateCustomerOpportunity", true);
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
		request.send(payload);
	}

	function StateChangeHandler_AddMetric() {
	
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
function deleteCustomerOpportunity_onClick(htmlElement) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this Opportunity?\n\nThis action cannot be undone.')) {

		var opportunityID = htmlElement.getAttribute('data-opp');

		var requestUrl	= 'ajax/customerMetrics.asp?cmd=deleteCustomerOpportunity&id=' + opportunityID;
		
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_DeleteCustomerOpportunity;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_DeleteCustomerOpportunity() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {


					location = location;


				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
	
	} else {
		
		return false;
		
	}
	
	
}




/*****************************************************************************************/
function ToggleActionIcons(iconsID) {
/*****************************************************************************************/
	
	var iconsToToggle = document.getElementById(iconsID);
	
	if (iconsToToggle.style.display == 'block') {
		iconsToToggle.style.display = 'none';
	} else {
		iconsToToggle.style.display = 'block';
	}	
	
	
}


/*****************************************************************************************/
function ToggleMetricValueActionIcons(htmlElement) {
/*****************************************************************************************/
	
	var iconsToToggle = htmlElement.querySelector('.internalMetricValueAciontIcons');
	
	
	if (iconsToToggle) {

		if (iconsToToggle.style.visibility == 'visible') {
			iconsToToggle.style.visibility = 'hidden';
		} else {
			iconsToToggle.style.visibility = 'visible';
		}	
	
	}
	
}


/*****************************************************************************************/
function ToggleOpportunityIcons(iconsID) {
/*****************************************************************************************/
	
	var iconsToToggle = document.getElementById(iconsID);
	
	if (iconsToToggle.style.display == 'block') {
		iconsToToggle.style.display = 'none';
	} else {
		iconsToToggle.style.display = 'block';
	}	
	
	
}


/*****************************************************************************************/
function ToggleSection_onClick(divID) {
/*****************************************************************************************/
	

	var divToToggle = document.getElementById(divID);

	var rvlToToggle;	
	if (divID == 'utopias') {
		rvlToToggle = document.getElementById('utopiasRevealer');
	} else {
		rvlToToggle = document.getElementById('opportunitiesRevealer');
	}
	
	if (divToToggle.style.display == 'none') {
		divToToggle.style.display = 'block';
		rvlToToggle.innerHTML = 'keyboard_arrow_down';
	} else {
		divToToggle.style.display = 'none';
		rvlToToggle.innerHTML = 'keyboard_arrow_right';
	}
	

}


/*****************************************************************************************/
function ToggleOpportunity_onClick(oppID) {
/*****************************************************************************************/
	

	var oppToToggle = document.getElementById('opportunity-' + oppID);

	var rvlToToggle = document.getElementById('opportunityRevealer-' + oppID);
		
	
	if (oppToToggle.style.display == 'none') {
		oppToToggle.style.display = 'block';
		rvlToToggle.innerHTML = 'keyboard_arrow_down';
	} else {
		oppToToggle.style.display = 'none';
		rvlToToggle.innerHTML = 'keyboard_arrow_right';
	}
	

}


/*****************************************************************************************/
function SetMinimumAttainDate(htmlElement) {
/*****************************************************************************************/
	
	var startDate = htmlElement.value;
	
	if (moment(startDate).isValid()) {
		document.getElementById('edit_attainByDate').min = moment(startDate).format('YYYY-MM-DD');
	}
	
}
	

/*****************************************************************************************/
function SetMaximumStartDate(htmlElement) {
/*****************************************************************************************/
	
	var attainDate = htmlElement.value;
	
	if (moment(attainDate).isValid()) {
		document.getElementById('edit_annotationDate').max = moment(attainDate).format('YYYY-MM-DD');
	}
	
}

	
/*****************************************************************************************/
function EditCustomerObjective_onSave(htmlDialog) {
/*****************************************************************************************/

	/*--------------------------------------------------------------------------*/
	// first, retrieve all data from the dialog...
	/*--------------------------------------------------------------------------*/
		
	// objectiveType indicates: 1-internal standard; 2-internal custom; 3-FDIC
	var objectiveType					= htmlDialog.querySelector('#objectiveType').value;
	
	var metricNameSelectElem		= htmlDialog.querySelector('#metricNameSelect')
	var metricNameInputElem 		= htmlDialog.querySelector('#metricNameInput');
	var metricNameInput 				= metricNameInputElem.value;
	
	var showAnnualChangeIndElem	= htmlDialog.querySelector('#showAnnualChangeInd');
	var peerGroupTypeID				= htmlDialog.querySelector('#peerGroupTypeID').value;
	var objectiveNarrative			= htmlDialog.querySelector('#objectiveNarrative').value;
	var objectiveStartDate			= htmlDialog.querySelector('#objectiveStartDate').value;
	var objectiveStartValue			= htmlDialog.querySelector('#objectiveStartValue').value.replace('$','').replace(',','').replace('%','');
	var objectiveEndDate				= htmlDialog.querySelector('#objectiveEndDate').value;
	var objectiveEndValue			= htmlDialog.querySelector('#objectiveEndValue').value.replace('$','').replace(',','').replace('%','');

	// these fields are hidden input fields on the dialog...	
	//  objectiveTypeID  indicates "Utopia (1)" or "Opportunity" (2)
	var objectiveTypeID 				= htmlDialog.querySelector('#objectiveTypeID').value;
	var objectiveID 					= htmlDialog.querySelector('#objectiveID').value;
	var opportunityID					= htmlDialog.querySelector('#opportunityID').value;
	var implementationID				= htmlDialog.querySelector('#implementationID').value;
	var customerID						= htmlDialog.querySelector('#customerID').value;
	
		
	/*--------------------------------------------------------------------------*/
	// second, validate all these values...
	/*--------------------------------------------------------------------------*/
		
	if (!objectiveTypeID) {
		if (! objectiveTypeID == '1' && objectiveTypeID == '2' && objectiveTypeID == '3') {
			alert("Invalid objective type encountered");
			htmlDialog.querySelector('#objectiveTypeID').parentNode.classList.add('is-invalid');
			return false;
		}
		alert('Objective type is required');
		htmlDialog.querySelector('#objectiveTypeID').parentNode.classList.add('is-invalid');
		return false;
	}	

	/*--------------------------------------------------------------------------*/
	// for each objectiveTypeID...	
	//		slightly different validations are required for objectiveMetricName,
	//		shownAnnualChangeInd, peerGroupTypeID, and customerID...
	/*--------------------------------------------------------------------------*/
	var objectiveMetricName;
	var objectiveMetricID;
	var showAnnualChangeInd;
	var peerGroupTypeID;
	
	if (objectiveType == '1') { /* internal - standard */		
				
		// metricName selector...
		if (metricNameSelectElem.selectedIndex < 0) {
			alert('A metric name must be selected');
			metricNameSelectElem.parentNode.classList.add('is-invalid');
			return false;
		} else {
			objectiveMetricName 	= metricNameSelectElem.options[metricNameSelectElem.selectedIndex].innerText.trim();
			objectiveMetricID		= metricNameSelectElem.options[metricNameSelectElem.selectedIndex].value;
		}
		
		showAnnualChangeInd 	= '';
		peerGroupTypeID 		= '';
		customerID				= '';
		
		
	} else if (objectiveType == '2') { /* internal - customer specific */
		
		// metricName selector or input...
		
		if (metricNameSelectElem.selectedIndex < 0) {
			alert('Metric name selection missing; contact system administrator');
			metricNameInputElem.parentNode.classList.add('is-invalid');
			return false;
		} else {
			if (metricNameSelectElem.options[metricNameSelectElem.selectedIndex].value == 'Add new...') {
				// adding a new customer-specific metric...
				if (!metricNameInput || metricNameInput == '') {
					alert('Metric name is missing; contact system administrator');
					metricNameInputElem.parentNode.classList.add('is-invalid');
					return false;
				} else {
					objectiveMetricName = metricNameInput;
					objectiveMetricID		= '';
				}
			} else {
				// selecting an existing customer-specific metric...
				objectiveMetricName 			= metricNameSelectElem.options[metricNameSelectElem.selectedIndex].innerText;
				metricNameInput 				= objectiveMetricName;
				objectiveMetricID				= metricNameSelectElem.options[metricNameSelectElem.selectedIndex].value;
			}
		}
		
		
// 		if (!metricNameInput || metricNameInput == '') {
// 			alert('Metric name is missing; contact system administrator');
// 			metricNameInputElem.parentNode.classList.add('is-invalid');
// 			return false;
// 		} else {
// 			objectiveMetricName = metricNameInput;
// 			objectiveMetricID		= '';
// 		}

		showAnnualChangeInd 	= '';
		peerGroupTypeID 		= '';

		if (!customerID || customerID == '') {
			alert('customerID is missing; contact your system administrator');
			return false;
		}


	} else if (objectiveType == '3') {	/* FDIC */

		// note that "UBPR Section," "Financial Category," and "UBPR Line" don't need validation -- they are only present/displayed
		// to help users make a selection in the metricName <select> control

		// metricName text input (not a selector)...
		if (metricNameSelectElem.selectedIndex < 0) {
			alert('Metric name is required');
			metricNameSelectElem.parentNode.classList.add('is-invalid');
			return false;
		} else {
			objectiveMetricName 	= metricNameSelectElem.options[metricNameSelectElem.selectedIndex].innerText.trim();
			objectiveMetricID		= metricNameSelectElem.options[metricNameSelectElem.selectedIndex].value;
		}
			

		if (!peerGroupTypeID || peerGroupTypeID == '') {
			alert('Peer group type is required');
			htmlDialog.querySelector('#peerGroupType').parentNode.classList.add('is-invalid');
			return false;
		}

		if (showAnnualChangeIndElem.checked) {
			showAnnualChangeInd = 1;
		} else {
			showAnnualChangeInd = 0;
		}
		customerID				= '';


	} else {
		
		alert('Unexpected objective type encountred; contact system administrator');
		return false;
		
	}

	// narrative is next on the dialog, but it is not a required field, so no validation here

	// startDate," "startValue," "endDate," and "endValue" are validated for all metricTypeID's...



	/* when any one of starDate, startValue, endDate, endValue are entered, then all four of them are required. */
	if (objectiveStartDate || objectiveStartValue || objectiveEndDate || objectiveEndValue) {
		
		if ( !(objectiveStartDate && objectiveStartValue && objectiveEndDate && objectiveEndValue) ) {
			
			var objectiveStartDateElem = document.getElementById('objectiveStartDate');
			if (!objectiveStartDate) {
				objectiveStartDateElem.parentNode.classList.add('is-invalid');
			} else {
				objectiveStartDateElem.parentNode.classList.remove('is-invalid');
			}

			var objectiveStartValueElem = document.getElementById('objectiveStartValue');
			if (!objectiveStartValue) {
				objectiveStartValueElem.parentNode.classList.add('is-invalid');
			} else {
				objectiveStartValueElem.parentNode.classList.remove('is-invalid');
			}
			
			var objectiveEndDateElem = document.getElementById('objectiveEndDate');
			if (!objectiveEndDate) {
				objectiveEndDateElem.parentNode.classList.add('is-invalid');
			} else {
				objectiveEndDateElem.parentNode.classList.remove('is-invalid');
			}
			
			var objectiveEndValueElem = document.getElementById('objectiveEndValue');
			if (!objectiveEndValue) {
				objectiveEndValueElem.parentNode.classList.add('is-invalid');
			} else {
				objectiveEndValueElem.parentNode.classList.remove('is-invalid');
			}
			
			objectiveStartDateElem.parentNode.classList.add('is-dirty');
			objectiveEndDateElem.parentNode.classList.add('is-dirty');
			

			alert('Objective incomplete, please supply all values (or remove all values)');
			return false;
			
		}
		
		
	}

	if (objectiveStartDate) {
		if (! moment(objectiveStartDate).isValid()) {
			alert('Start date is not a valid date');
			return false;
		}
	}
	
	
	if (objectiveEndDate) {
		if (! moment(objectiveEndDate).isValid()) {
			alert('End date is not a valid date');
			return false;
		}
	}

	
	/*--------------------------------------------------------------------------*/
	// finally, everything is validated so construct an AJAX call to update/insert
	// the objective and/or customer-specific metric...
	/*--------------------------------------------------------------------------*/

	var payload = "objectiveType=" 				+ objectiveType
					+ "&objectiveMetricID=" 		+ objectiveMetricID
					+ "&objectiveMetricName="		+ encodeURIComponent(objectiveMetricName)
					+ "&showAnnualChangeInd="		+ showAnnualChangeInd
					+ "&peerGroupTypeID="			+ peerGroupTypeID
					+ "&objectiveNarrative="		+ encodeURIComponent(objectiveNarrative)
					+ "&objectiveStartDate=" 		+ encodeURIComponent(objectiveStartDate)
					+ "&objectiveStartValue=" 		+ objectiveStartValue
					+ "&objectiveEndDate=" 			+ encodeURIComponent(objectiveEndDate)
					+ "&objectiveEndValue=" 		+ objectiveEndValue 	
					+ "&objectiveTypeID="			+ objectiveTypeID
					+ "&objectiveID="					+ objectiveID
					+ "&opportunityID="				+ opportunityID
					+ "&implementationID="			+ implementationID 
					+ "&customerID="					+ customerID;
			
	console.log(payload);
		
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_AddMetric;
		request.open("POST", "ajax/customerMetrics.asp?cmd=updateCustomerObjective", true);
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
		request.send(payload);
	}

	function StateChangeHandler_AddMetric() {
	
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
function AddAnnotation_onSave(htmlDialog) {
/*****************************************************************************************/
	
	var attrSourceElem 		= document.getElementById('attributeSource');
	var attrSourceSelected	= attrSourceElem.options[attrSourceElem.selectedIndex].value;
	
	if (attrSourceSelected == 'attrSourceInternalStandard') {
		attrSource = 1;
	} else if (attrSourceSelected == 'attrSourceInternalCustom') {
		attrSource = 2;
	} else if (attrSourceSelected == 'attrSourceFDIC') {
		attrSource = 3;
	} else {
		attrSource = 2;
	}
			
	var attributeTypeID = 3;
	
	var attributeDate		= document.getElementById('add_annotationDate').value;
	var attainByDate		= document.getElementById('add_attainByDate').value;


	if (moment(attributeDate).isValid) {
		if (moment(attainByDate).isValid) {
			if (moment(attainByDate).isBefore(attributeDate)) {
				alert('Attain by date must be the same of later than start date');
				return false;
			}
		}
	}	
	
	var customerStartValue 		= document.getElementById('add_startValue').value;
	var customerStartValueDate = document.getElementById('add_startValueDate').value;
	var customerEconomicValue 	= document.getElementById('add_economicValue').value;
	
	if (!moment(customerStartValueDate).isValid) {
		alert('Customerprovided value date is not valid');
		return false;
	}

	
	
// var attrCategory;
// var attrUBPRSection;
	var metricID 			= document.getElementById('add_annotationMetricID').value;
	var attrName 			= document.getElementById('add_annotationName').value;
	var narrative 			= document.getElementById('add_annotationNarrative').value;
	var attributeValue	= document.getElementById('add_metricValue').value;
	var customerID			= document.getElementById('customerID').value;
	
	var requestUrl = "ajax/customerMetrics.asp?cmd=addMetric"
												+ "&attributeDate=" 		+ encodeURIComponent(attributeDate)
												+ "&attributeValue=" 	+ attributeValue 
												+ "&customerID=" 			+ customerID 
												+ "&narrative=" 			+ encodeURIComponent(narrative)
												+ "&metricID=" 			+ metricID 
												+ "&attributeTypeID=" 	+ attributeTypeID
												+ "&attainByDate=" 		+ encodeURIComponent(attainByDate)
												+ "&attrName="				+ encodeURIComponent(attrName)
												+ "&attributeSource="	+ attrSource
												+ "&startValue="			+ customerStartValue 
												+ "&startValueDate="		+ customerStartValueDate 
												+ "&economicValue="		+ customerEconomicValue;
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_AddMetric;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_AddMetric() {
	
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
function UbprCategorySection_onChange () {
/*****************************************************************************************/

	var categoryList 		= document.getElementById('add_ubprCategory');
	var selectedCategory = categoryList.options[categoryList.selectedIndex].value;

	var sectionList 		= document.getElementById('add_ubprSection');
	
	var selectedSection 	= sectionList.options[sectionList.selectedIndex].value;

	var requestUrl	= "ajax/customerMetrics.asp?cmd=getFDICMetricList"
												+ "&category=" + selectedCategory
												+ "&section=" + selectedSection;
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_GetInternalAttributes;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_GetInternalAttributes() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_GetInternalAttributes(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function AttrSource_onClick(htmlElement) {
/*****************************************************************************************/
	

	document.getElementById("add_ubprSection").parentNode.style.display = 'none';
	document.getElementById("add_ubprCategory").parentNode.style.display = 'none';
	document.getElementById("add_annotationMetricID").parentNode.style.display = 'none';
	document.getElementById("add_annotationDate").parentNode.style.display = 'none';
	document.getElementById("add_annotationName").parentNode.style.display = 'none';
	document.getElementById("add_annotationNarrative").parentNode.style.display = 'none';
	document.getElementById("add_metricValue").parentNode.style.display = 'none';
	document.getElementById("add_attainByDate").parentNode.style.display = 'none';

	
// 	var selectedSource = htmlElement.id
	var selectedSource 	= htmlElement.options[htmlElement.selectedIndex].value;
	
	switch (selectedSource) {

		case 'attrSourceInternalStandard':
			document.getElementById("add_annotationMetricID").parentNode.style.display = 'block';
			document.getElementById("add_annotationNarrative").parentNode.style.display = 'block';
			document.getElementById("add_annotationDate").parentNode.style.display = 'block';
			document.getElementById("add_metricValue").parentNode.style.display = 'block';
			document.getElementById("add_attainByDate").parentNode.style.display = 'block';
			
			GetInternalAttributes();
			
			break;
			
		case 'attrSourceInternalCustom':
			document.getElementById("add_annotationName").parentNode.style.display = 'block';
			document.getElementById("add_annotationNarrative").parentNode.style.display = 'block';
			document.getElementById("add_annotationDate").parentNode.style.display = 'block';
			document.getElementById("add_metricValue").parentNode.style.display = 'block';
			document.getElementById("add_attainByDate").parentNode.style.display = 'block';
		
			GetInternalAttributes();

			break;
			
		case 'attrSourceFDIC':
			document.getElementById("add_ubprSection").parentNode.style.display = 'block';
			document.getElementById("add_ubprCategory").parentNode.style.display = 'block';
			document.getElementById("add_annotationMetricID").parentNode.style.display = 'block';
			document.getElementById("add_annotationNarrative").parentNode.style.display = 'block';
			document.getElementById("add_annotationDate").parentNode.style.display = 'block';
			document.getElementById("add_metricValue").parentNode.style.display = 'block';
			document.getElementById("add_attainByDate").parentNode.style.display = 'block';

			GetFDICCategoriesSections();
			
			break;
		
		default:
			console.log('Unexpected condition encountered: attributeSource has an unexpected value.');
			alert('Unexpected condition encountered');
			
	}
	
	document.getElementById('add_startValue').parentNode.style.display = 'block';
	document.getElementById('add_startValueDate').parentNode.style.display = 'block';
	document.getElementById('add_economicValue').parentNode.style.display = 'block';

}


/*****************************************************************************************/
function GetFDICCategoriesSections (htmlElement) {
/*****************************************************************************************/

	
	var requestUrl	= "ajax/customerMetrics.asp?cmd=getFDICCategoriesSections";
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_GetFDICCategoriesSections;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_GetFDICCategoriesSections() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_GetFDICCategoriesSections(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_GetFDICCategoriesSections (xml) {
/*****************************************************************************************/

	var searchResults 		= xml.getElementsByTagName('category');
	var categorySelectList 	= document.getElementById('add_ubprCategory');
	var categoryName;
	
	categorySelectList.options.length = 0;
	
   categorySelectList.innerHTML 	= '<option value="all"></option>';
	for (var i = 0; i < searchResults.length; i++) {
		categoryName 						 =  GetInnerText(searchResults[i]);
      categorySelectList.innerHTML 	+= '<option value="' + categoryName + '">' + categoryName + '</option>';
	}
	

	searchResults 				= xml.getElementsByTagName('section');
	var sectionSelectList 	= document.getElementById('add_ubprSection');
	var sectionName;
	
	sectionSelectList.options.length = 0;
	
   sectionSelectList.innerHTML 	= '<option value="all"></option>';
	for (var i = 0; i < searchResults.length; i++) {
		sectionName 						 = GetInnerText(searchResults[i]);
      sectionSelectList.innerHTML 	+= '<option value="' + sectionName + '">' + sectionName + '</option>';
	}
	

	document.getElementById('add_annotationMetricID').length = 0;
	
}



/*****************************************************************************************/
function GetInternalAttributes (htmlElement) {
/*****************************************************************************************/

	
	var requestUrl	= "ajax/customerMetrics.asp?cmd=getInternalMetricList";
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_GetInternalAttributes;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_GetInternalAttributes() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_GetInternalAttributes(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_GetInternalAttributes (xml) {
/*****************************************************************************************/

	var searchResults 		= xml.getElementsByTagName('metric');
	var metricSelectList 	= document.getElementById('add_annotationMetricID');
	var currentSelectLength = metricSelectList.options.length;
	var metricID;
	var metricName;
	
	metricSelectList.options.length = 0;
	
   metricSelectList.innerHTML = metricSelectList.innerHTML + '<option value="all"></option>';
	for (var i = 0; i < searchResults.length; i++) {
		metricID 						= searchResults[i].id;
		metricName 						= GetInnerText(searchResults[i]);
      metricSelectList.innerHTML = metricSelectList.innerHTML + '<option value="' + metricID + '">' + metricName + '</option>';
	}
	
	
}


// /*****************************************************************************************/
// function Complete_GetInternalAttributes (xml) {
// /*****************************************************************************************/
// 
// 	var searchResults = xml.getElementsByTagName('metric');
// 	var metricSelectList = document.getElementById('add_annotationMetricID');
// 	var currentSelectLength = metricSelectList.options.length;
// 	
// 	metricSelectList.options.length = 0;
// 	
//    metricSelectList.innerHTML = metricSelectList.innerHTML + '<option>Make a selection...</option>';
// 	for (var i = 0; i < searchResults.length; i++) {
// 		if (searchResults[i][2] == "") {
// 			metricName = searchResults[i][1];
// 		} else {
// 			metricName = searchResults[i][1] + '  ( Line ' + searchResults[i][2] + ' )';
// 		}
//       metricSelectList.innerHTML = metricSelectList.innerHTML + '<option value="' + searchResults[i][0] + '">' + metricName + '</option>';
// 	}
// 	
// 	
// 	metricSelectList.parentElement.classList.add('is-dirty');
// 	
// }


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}



