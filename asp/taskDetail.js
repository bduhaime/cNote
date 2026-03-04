//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

// this code builds an array of public holidays using the date-holidays library
const hd = new Holidays();
hd.init('US');	
const blockedTypes = [ 'public', 'bank' ];	
const currentYear = new Date().getFullYear();
const holidayList = hd.getHolidays(currentYear);

// Map holiday dates to "YYYY-MM-DD" format
const publicHolidays = holidayList
	.filter( h => blockedTypes.includes( h.type ) )
	.map(holiday => moment(holiday.date).format('YYYY-MM-DD'));



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
function ToggleEditIcon(csuiteTextfield) {
/*****************************************************************************************/

	var editIcon = csuiteTextfield.querySelector('i.edit');
	
	var textFieldsEditing = document.querySelectorAll('div.csuite-textfield.is-editing');

	if (textFieldsEditing.length == 0) {
		if (editIcon.style.visibility == 'hidden' || editIcon.style.visibility == '') {
			editIcon.style.visibility = 'visible';
		} else {
			editIcon.style.visibility = 'hidden';
		}
	}
	
}



/*****************************************************************************************/
function ToggleInfoIcon(infoFieldContainer) {
/*****************************************************************************************/

	var infoIcon = infoFieldContainer.querySelector('i.infoIcon');
	
	if (infoIcon.style.visibility == 'hidden' || infoIcon.style.visibility == '') {
		infoIcon.style.visibility = 'visible';
	} else {
		infoIcon.style.visibility = 'hidden';
	}
	
}



/************************************************************************************************/
function cSuiteHideInput(hideButton) {
/************************************************************************************************/
	
	var textField = hideButton.closest('.csuite-textfield');
	if (textField) {

		textField.querySelector('span').style.color = '';
		
		var csuiteTextfieldEditValue = textField.querySelector('.csuite-textfield-editValue');
		csuiteTextfieldEditValue.style.display = 'none';

		var csuiteTextfieldViewValue = textField.querySelector('.csuite-textfield-viewValue');
		csuiteTextfieldViewValue.style.display = 'block';

		var csuiteEditIcon = textField.querySelector('i');
		if (csuiteEditIcon) {
			csuiteEditIcon.style.display = 'inline-block';
		}

	}

	textField.classList.remove('is-editing');			
	event.cancelBubble = true;

}



/************************************************************************************************/
function cSuiteShowInput(textField) {
/************************************************************************************************/

	if (textField.classList.contains('is-editing')) {
		return false;
	} else {
		textField.classList.add('is-editing');
	}
	
	var csuiteEditIcon = textField.querySelector('i');
	if (csuiteEditIcon) {
		csuiteEditIcon.style.display = 'none';
	}
	
	var csuiteTextfieldViewValue = textField.querySelector('.csuite-textfield-viewValue');
	if (csuiteTextfieldViewValue) {
		csuiteTextfieldViewValue.style.display = 'none';
	}
	
	var csuiteTextfieldEditValue = textField.querySelector('.csuite-textfield-editValue');
	if (csuiteTextfieldEditValue) {
		csuiteTextfieldEditValue.style.display = 'block';
		var csuiteTextEditValueInput;
		csuiteTextEditValueInput = csuiteTextfieldEditValue.querySelector('input, textarea');
		if (csuiteTextEditValueInput) {
			
			
			
			if (csuiteTextEditValueInput.type == 'date') {
				csuiteTextEditValueInput.value = moment(csuiteTextfieldViewValue.textContent).format('YYYY-MM-DD');
			} else {
				csuiteTextEditValueInput.value = csuiteTextfieldViewValue.textContent;					
			}
			

			
// 			csuiteTextEditValueInput.style.color = '';
			
			
			
			csuiteTextEditValueInput.focus();
			csuiteTextEditValueInput.select();
		} else {
			csuiteTextEditValueInput = csuiteTextfieldEditValue.querySelector('select');
			if (csuiteTextEditValueInput) {
// 			csuiteTextEditValueInput.size = csuiteTextEditValueInput.length;
				csuiteTextEditValueInput.focus();


			}
		}
	}
	
	event.cancelBubble = true;

}



/************************************************************************************************/
function cSuiteSaveInput(textField) {
/************************************************************************************************/
	
	var csuiteTextFieldEditValue 		= textField.closest('.csuite-textfield-editValue');
	var csuiteTextFieldInput 			= csuiteTextFieldEditValue.querySelector('textarea, select, input');
	var task									= csuiteTextFieldInput.getAttribute('data-taskID');
	
	if (csuiteTextFieldInput.id == 'taskStatusID') {
		if (csuiteTextFieldInput.value == '3') {


			var objGenericQuillNote = new Quill('#skippedReason', {
				modules: {
					toolbar: [
						[{ header: [1, 2, false] }],
						[{ size: [ 'small', false, 'large' ]}],
						['bold',	'italic', 'underline'],
						['link'],
						[{'list': 'ordered'}],
						[{'list': 'bullet' }],
						[{'indent': '-1'}],
						[{'indent': '+1' }],
						[{'color': [] }],
						[{'background': [] }]
					],
				},		
				theme: 'snow'
			});
			
// 			objGenericQuillNote.keyboard.addBinding({ 
// 				key: '0',
// 				shiftKey: true,
// 				prefix: /(tm)/,
// 			}, function(range, context) {
// 				this.quill.deleteText(range.index-3, 4);
// 				this.quill.insertText(range.index-3, '\u2122', true);
// 			});	

				objGenericQuillNote.on('text-change', function(delta, oldDelta, source) {
					debugger
					if (source === 'user') { // Ensure the change comes from user input
						let text = objGenericQuillNote.getText(); // Get the full text
						let index = text.lastIndexOf("(tm)"); // Find the last occurrence of (tm)
						
						if (index !== -1) {
							// Remove the "(tm)" and insert the trademark symbol
							objGenericQuillNote.deleteText(index, 4);
							objGenericQuillNote.insertText(index, '\u2122', 'bold', true);
						}
					}
				});


			dialog_skippedReason.showModal();


			if (!csuiteTextFieldInput.id == 'taskStatusID') {
				if (narrative != null && narrative.length > 0) {
					objGenericQuillNote.setContents(JSON.parse(narrative));
					objGenericQuillNote.setSelection(0, narrative.length);		
				} else {
					objGenericQuillNote.setSelection(0, 0);		
				}
			}
			objGenericQuillNote.focus();
			
			
			return true;


		}

	}

	attribute_onChange(csuiteTextFieldInput,task)
	
	var csuiteParentDiv 					= textField.closest('.csuite-textfield');
	var csuiteTextFieldViewValue 		= csuiteParentDiv.querySelector('.csuite-textfield-viewValue');
	var csuiteNewValue;


	if (csuiteTextFieldInput.type == 'text' || csuiteTextFieldInput.type == 'textarea') {
		csuiteNewValue = csuiteTextFieldInput.value;
	} else if (csuiteTextFieldInput.type == 'select-one') {
		csuiteNewValue = csuiteTextFieldInput.options[csuiteTextFieldInput.selectedIndex].innerHTML;
	} else {
		csuiteNewValue = 'unknown input type updated';
	}
	csuiteTextFieldViewValue.innerHTML = csuiteNewValue;
	

	csuiteTextFieldViewValue.style.display 	= 'block';
	csuiteTextFieldEditValue.style.display 	= 'none';
	
	var csuiteEditIcon = csuiteParentDiv.querySelector('i');
	if (csuiteEditIcon) {
		csuiteEditIcon.style.display = 'inline-block';
	}
	
	csuiteParentDiv.classList.remove('is-editing');		
	event.cancelBubble = true;
	
	
}



/************************************************************************************************/
function checklistHeader_onMouseover(htmlElement) {
/*****************************************************************************************/
	
	var deleteIcon = htmlElement.childNodes[3].childNodes[3].childNodes[0];
	
	ToggleChecklistItemDeleteIcon(deleteIcon);

}


/*****************************************************************************************/
function checklistHeader_onMouseout(htmlElement) {
/*****************************************************************************************/

	var deleteIcon = htmlElement.childNodes[3].childNodes[3].childNodes[0];

	ToggleChecklistItemDeleteIcon(deleteIcon);

}
			
	
/*****************************************************************************************/
function checklistItem_onMouseover(htmlElement) {
/*****************************************************************************************/

	htmlElement.style.backgroundColor = 'lightgray';
	
	var deleteIcon = htmlElement.childNodes[1].childNodes[3].childNodes[3].childNodes[0];

	ToggleChecklistItemDeleteIcon(deleteIcon);

}


/*****************************************************************************************/
function checklistItem_onMouseout(htmlElement) {
/*****************************************************************************************/

	htmlElement.style.backgroundColor = null;
	
	var deleteIcon = htmlElement.childNodes[1].childNodes[3].childNodes[3].childNodes[0];

	ToggleChecklistItemDeleteIcon(deleteIcon);

}
			
	
/*****************************************************************************************/
function ToggleChecklistItemDeleteIcon(icon) {
/*****************************************************************************************/
	
	if (icon.style.visibility == 'hidden') {
		icon.style.visibility = 'visible';
	} else {
		icon.style.visibility = 'hidden';
	}
		
}	



/*****************************************************************************************/
function checklistAddItem_onMouseover(htmlElement) {
/*****************************************************************************************/

	htmlElement.style.backgroundColor = 'lightgray';

}


/*****************************************************************************************/
function checklistAddItem_onMouseout(htmlElement) {
/*****************************************************************************************/

	htmlElement.style.backgroundColor = null;

}
			
			

/*****************************************************************************************/
function updateDateAttribute(inputElem) {
/*****************************************************************************************/
	
	var attributeName 	= inputElem.id;
	var attributeValue 	= inputElem.value;
	var taskID				= inputElem.getAttribute('data-taskID');

	var projectStartDate = moment(document.getElementById('projectStartDate').value);
	var projectEndDate 	= moment(document.getElementById('projectEndDate').value);
	
	var attributeDate = moment(attributeValue); 
	if (attributeDate.isValid() || attributeName == 'completionDate') {

		if (attributeName == 'startDate') {
			
			var startDateMinDate = moment(inputElem.getAttribute('min'));
			if (attributeDate.isBefore(startDateMinDate)) {
				inputElem.style.color = 'crimson';
				alert('Enter a start date on or after ' + startDateMin.format('MM/DD/YYYY'));
				return false;
			}

			var startDateMaxDate = moment(inputElem.getAttribute('max'));
			if (attributeDate.isAfter(startDateMaxDate)) {
				inputElem.style.color = 'crimson';
				alert('Enter a start date on or before ' + startDateMax.format('MM/DD/YYYY'));
				return false;
			}
						
		}
		
		if (attributeName == 'dueDate') {
			
			var endDateMinDate = moment(inputElem.getAttribute('min'));
			if (attributeDate.isBefore(endDateMinDate)) {
				inputElem.style.color = 'crimson';
				alert('Enter an end date on or after ' + endDateMinDate.format('MM/DD/YYYY'));
				return false;
			}
			
			var endDateMaxDate = moment(inputElem.getAttribute('max'));
			if (attributeDate.isAfter(endDateMaxDate)) {
				inputElem.style.color = 'crimson';
				alert('Enter an end on or before ' + endDateMaxDate.format('MM/DD/YYYY'));
				return false;
			}
			
		}
		
		
		inputElem.style.color = '';
		

		var requestUrl 	= "ajax/taskMaintenance.asp?cmd=update"
												+ "&task=" + taskID 
												+ "&name=" + attributeName
												+ "&value=" + attributeValue;
	
		console.log(requestUrl);
												
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_dateAttribute;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_dateAttribute() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					attribute_status(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status + " - 1");
				}
			}
		
		}

		var inputParent 		= inputElem.closest('.csuite-textfield');
		var viewField 			= inputParent.querySelector('.csuite-textfield-viewValue');
		var newValue			= moment(attributeValue);
		viewField.innerHTML  = moment(newValue).format('M/D/YYYY');
		
		cSuiteHideInput(inputElem);
		
		
		//now adjust min/max for other dates....
		
		if (attributeName == 'startDate') {
			
			// if startDate is changed then...
			// taskDueDate.min is the greater of the projectStartDate or the new task startData...
			if (projectStartDate.isValid()) {
				if (projectStartDate.isAfter(newValue)) {
					document.getElementById('dueDate').min = projectStartDate.format('YYYY-MM-DD');
				} else {
					document.getElementById('dueDate').min = newValue.format('YYYY-MM-DD');
				}
			} else {
				document.getElementById('dueDate').min = newValue.format('YYYY-MM-DD');
			}
			
			
		} else if (attributeName == 'dueDate') {
			
			// if dueDate is changed then....
			// taskStartDate.max is the lessor of the projectEndDate or the new task dueDate
			
			if (projectEndDate.isValid()) {
				if (projectEndDate.isBefore(newValue)) {
					document.getElementById('startDate').max = projectEndDate.format('YYYY-MM-DD');
				} else {
					document.getElementById('startDate').max = newValue.format('YYYY-MM-DD');
				}
			} else {
				document.getElementById('startDate').max = newValue.format('YYYY-MM-DD');
			}
			
			
		} else if (attributeName == 'completionDate') {
			
			// if completionDate is updated then refresh the page to allow the page to correctly disable relevant attribute...
			
			location = location;
							
			
		}
		
				
	} else {
		
		alert('The date submitted for ' + attributeName + ' is not a valid date');
		inputElem.parentNode.classList.add('is-invalid');
		inputElem.style.color = 'crimson';
		inputElem.closest('.csuite-textfield').querySelector('span').style.color = 'crimson';
		
		inputElem.focus()
		inputElem.select();
		return false;
		
	}

	event.cancelBubble = true;
	
}		
	

/*****************************************************************************************/
function SaveAcceptanceCriteria_onClick(taskID) {
/*****************************************************************************************/

	var objQuill_AcceptanceCriteria = new Quill('#acceptanceCriteriaInput');	
	var quillContents			= objQuill_AcceptanceCriteria.getContents();
	var quillContentString 	= JSON.stringify(quillContents);	
	var quillContentHTML 	= objQuill_AcceptanceCriteria.root.innerHTML;
	
	var payload		= "taskID=" + taskID 
						+ "&contentString=" + encodeURIComponent(quillContentString)
						+ "&contentHTML=" + encodeURIComponent(quillContentHTML);
	
	
	console.log(payload);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_EditAnnotation;
		request.open("POST", "ajax/taskMaintenance.asp?cmd=saveAcceptanceCriteria", true);
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
		request.send(payload);
	}

	function StateChangeHandler_EditAnnotation() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_SaveAcceptanceCriteria(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status + " - 2");
			}
		}
	
	}	
	
}


/*****************************************************************************************/
function Complete_SaveAcceptanceCriteria(xml) {
/*****************************************************************************************/

	ToggleAcceptanceCriteriaOff_onClick();
	
	var msg 					= GetInnerText(xml.getElementsByTagName('msg')[0]);
	var taskID 				= GetInnerText(xml.getElementsByTagName('taskID')[0]);
	var contentString 	= GetInnerText(xml.getElementsByTagName('contentString')[0]);
	var contentHTML 		= GetInnerText(xml.getElementsByTagName('contentHTML')[0]);
	
	eval('acceptanceCriteriaPrompt').setContents(JSON.parse(contentString));
	
		
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	location = location;

}


/*****************************************************************************************/
function ToggleAcceptanceCriteriaOn_onClick(htmlElement) {
/*****************************************************************************************/

	document.getElementById('quillButton').style.display = 'none';
	document.getElementById('acceptanceCriteriaPromptContainer').style.display = 'none';
	document.getElementById('acceptanceCriteriaInputContainer').style.display = 'block';
	
	var objQuill_AcceptancePrompt 	= new Quill('#acceptanceCriteriaPrompt');

	if (typeof objQuill_AcceptanceCriteria == "undefined") {
		var objQuill_AcceptanceCriteria = new Quill('#acceptanceCriteriaInput', {
			modules: {
				toolbar: [
					[{ size: [ 'small', false, 'large' ]}],
					['bold',	'italic', 'underline'],
					['link'],
					[{'list': 'ordered'}],
					[{'list': 'bullet' }],
					[{'indent': '-1'}],
					[{'indent': '+1' }],
					[{'color': [] }],
					[{'background': [] }]
				],
				},		
				theme: 'snow'
		});
		
		objQuill_AcceptanceCriteria.keyboard.addBinding({ 
			key: '0',
			shiftKey: true,
			prefix: /(tm)/,
		}, function(range, context) {
			this.quill.deleteText(range.index-3, 4);
			this.quill.insertText(range.index-3, '\u2122', true);
		});	
		
		
	}

	var promptContents = objQuill_AcceptancePrompt.getContents(0, objQuill_AcceptancePrompt.getLength());
	objQuill_AcceptanceCriteria.setContents(promptContents);
	objQuill_AcceptanceCriteria.setSelection(0, objQuill_AcceptanceCriteria.getLength());	

}


/*****************************************************************************************/
function ToggleAcceptanceCriteriaOff_onClick(htmlElement) {
/*****************************************************************************************/

	document.getElementById('quillButton').style.display = 'inline-block';
	document.getElementById('acceptanceCriteriaPromptContainer').style.display = 'block';
	document.getElementById('acceptanceCriteriaInputContainer').style.display = 'none';
	
	document.getElementById('acceptanceCriteriaInputQuillContainer').innerHTML = '<div id="acceptanceCriteriaInput" style="border: solid lightgrey 1px"></div>';
	
}


/*****************************************************************************************/
function EditAcceptanceCriteria_onClick(htmlElement) {
/*****************************************************************************************/

// get values from htmlElement

	var taskID 	= htmlElement.getAttribute('taskID');

// get narrative (ajax)
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=getAcceptanceCriteria"
											+ "&taskID=" + taskID;

	console.log(requestUrl);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_EditXceptCriteria;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_EditXceptCriteria() {

		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {
				Complete_EditExceptCriteria(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status + " - 3");
			}
			
		}
	
	}
	
}
	
	
/*****************************************************************************************/
function Complete_EditExceptCriteria(xml) {
/*****************************************************************************************/

// setup the dialog/form

	var taskID 						= GetInnerText(xml.getElementsByTagName('taskID')[0]);
	var acceptanceCriteria 		= GetInnerText(xml.getElementsByTagName('acceptanceCriteria')[0]);
	var msg 							= GetInnerText(xml.getElementsByTagName('msg')[0]);

	dialog_editAcceptanceCriteria.showModal();

	document.getElementById('editAcceptanceCriteria_taskID').value = taskID;	

	var genericQuillNote = new Quill('#quill_acceptanceCriteria', {
		modules: {
			toolbar: [
				[{ size: [ 'small', false, 'large' ]}],
				['bold',	'italic', 'underline'],
				['link'],
				[{'list': 'ordered'}],
				[{'list': 'bullet' }],
				[{'indent': '-1'}],
				[{'indent': '+1' }],
				[{'color': [] }],
				[{'background': [] }]
			]
			},		
			theme: 'snow'
	});
	
	if (acceptanceCriteria) {
		genericQuillNote.setContents(JSON.parse(acceptanceCriteria));	
	}

}


/*****************************************************************************************/
function ResetAllPrompts() {
/*****************************************************************************************/
// resets all "prompts" to display='block' and all "inputs" to display='none'
// in other words, like the page originally loaded.	

	ToggleAcceptanceCriteriaOff_onClick();

	
//	var allNewItemInputs = document.getElementsByClassName('input'), i;
	var allPrompts = document.querySelectorAll('.checklistEdit, .checklistItemEdit, .checklistItemAddEdit	');
	for (var i = 0; i < allPrompts.length; i ++) {
		allPrompts[i].style.display = 'none';
	}

	var allDisplays = document.querySelectorAll('.checklistDisplay, .checklistItemDisplay, .checklistItemAddDisplay');
	for (var i = 0; i < allDisplays.length; i ++) {
		allDisplays[i].style.display = 'table-cell';
	}


}



/*****************************************************************************************/
function ToggleChecklistToEditMode(htmlElement) {
/*****************************************************************************************/

	var checklistID = htmlElement.getAttribute('data-val');
	
	ResetAllPrompts();
	
	document.getElementById('checklistDisplay-'+checklistID).style.display = 'none';
	document.getElementById('checklistEdit-'+checklistID).style.display = 'table-cell';
	
	// resize the textarea to match scroll size
	var textArea = document.getElementById('checklistName-'+checklistID);
	textArea.style.height = textArea.scrollHeight+'px';
	textArea.select();		
	
	
}


/*****************************************************************************************/
function ToggleChecklistItemToEditMode(htmlElement) {
/*****************************************************************************************/

	var checklistItemID = htmlElement.getAttribute('data-val');

	ResetAllPrompts();
	
	
	document.getElementById('checklistItemDisplay-'+checklistItemID).style.display = 'none';
	document.getElementById('checklistItemEdit-'+checklistItemID).style.display = 'table-cell';
	
	// resize the textarea to match scroll size
	var textArea = document.getElementById('checklistItemName-'+checklistItemID);
	textArea.style.height = textArea.scrollHeight+'px';
	textArea.select();		
	
	
}


/*****************************************************************************************/
function ToggleChecklistItemAddToEditMode(htmlElement) {
/*****************************************************************************************/

	var checklistID = htmlElement.getAttribute('data-val');

	ResetAllPrompts();
		
	document.getElementById('checklistItemAddDisplay-'+checklistID).style.display = 'none';
	document.getElementById('checklistItemAddEdit-'+checklistID).style.display = 'table-cell';
	
	var textArea = document.getElementById('checklistItemAddName-'+checklistID);
	textArea.focus();
	
	
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
	
	var checklistID = htmlElement.getAttribute('data-val');
	
	var displayDiv = document.getElementById('checklistDisplay-'+checklistID);
	var editDiv		= document.getElementById('checklistEdit-'+checklistID);
	
	// since cancelling, restore the content of the editDiv to what's in displayDiv....
	
	var originalContent = displayDiv.childNodes[1].innerText;
	editDiv.childNodes[1].childNodes[1].value = originalContent;	

	displayDiv.style.display = 'table-cell';
	editDiv.style.display = 'none';


}


/*****************************************************************************************/
function CancelChecklistItemNameUpdate_onClick(htmlElement) {
/*****************************************************************************************/
	
	var checklistItemID = htmlElement.getAttribute('data-val');
	
	var displayDiv = document.getElementById('checklistItemDisplay-'+checklistItemID);
	var editDiv		= document.getElementById('checklistItemEdit-'+checklistItemID);
	
	// since cancelling, restore the content of the editDiv to what's in displayDiv....
	
	var originalContent = displayDiv.childNodes[1].innerText;
	editDiv.childNodes[1].childNodes[1].value = originalContent;	

	displayDiv.style.display = 'table-cell';
	editDiv.style.display = 'none';


}


/*****************************************************************************************/
function CancelChecklistItemAdd_onClick(htmlElement) {
/*****************************************************************************************/
	
	var checklistID = htmlElement.getAttribute('data-val');
	
	var displayDiv = document.getElementById('checklistItemAddDisplay-'+checklistID);
	var editDiv		= document.getElementById('checklistItemAddEdit-'+checklistID);
	
	// since cancelling, restore the content of the editDiv to what's in displayDiv....
	
	editDiv.childNodes[1].childNodes[1].value = null;	

	displayDiv.style.display = 'table-cell';
	editDiv.style.display = 'none';


}


/*****************************************************************************************/
function SaveChecklistNameUpdate_onClick(htmlElement) {
/*****************************************************************************************/
	
	
	var checklistID 				= htmlElement.getAttribute('data-val');
	var newChecklistName		 	= document.getElementById('checklistName-'+checklistID).value;

	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=updatedChecklistName"
												+ "&id=" + checklistID
												+ "&name=" + encodeURIComponent(newChecklistName);
												
	console.log(requestUrl);
	
	CreateRequest();
 
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

				alert("problem retrieving data from the server, status code: "  + request.status + " - 4");

			}
		}
	
	}

	ResetAllPrompts();
	event.stopPropagation();
	
	location = location;

}


/*****************************************************************************************/
function SaveChecklistItemNameUpdate_onClick(htmlElement) {
/*****************************************************************************************/
	
	
	var checklistItemID 			= htmlElement.getAttribute('data-val');
	var newChecklistItemName	= document.getElementById('checklistItemName-'+checklistItemID).value;

	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=updateChecklistItemName"
												+ "&id=" + checklistItemID
												+ "&name=" + encodeURIComponent(newChecklistItemName);
												
	console.log(requestUrl);
	
	CreateRequest();
 
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

				alert("problem retrieving data from the server, status code: "  + request.status + " - 5");

			}
		}
	
	}

	ResetAllPrompts();
	event.stopPropagation();
	
	location = location;

}


/*****************************************************************************************/
function SaveChecklistItemAddSave_onClick(htmlElement) {
/*****************************************************************************************/
	
	
	var checklistID 				= htmlElement.getAttribute('data-val');
	var newChecklistItemName	= document.getElementById('checklistItemAddName-'+checklistID).value;

	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=addChecklistItem"
												+ "&checklistID=" + checklistID
												+ "&description=" + encodeURIComponent(newChecklistItemName);
												
	console.log(requestUrl);
	
	CreateRequest();
 
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

				alert("problem retrieving data from the server, status code: "  + request.status + " - 6");

			}
		}
	
	}

// 	ResetAllPrompts();
	event.stopPropagation();
	
}


/*****************************************************************************************/
function ChecklistNameStatus(xml) {
/*****************************************************************************************/

// 	var id 				= xml.getElementsByTagName('id')[0].innerHTML;
// 	var name				= GetInnerText(xml.getElementsByTagName('name')[0]);
	var msg				= GetInnerText(xml.getElementsByTagName('msg')[0]);

	var notification 	= document.querySelector('.mdl-js-snackbar');

// 	document.getElementById('checklistNameTextarea-'+id).innerHTML = name;

	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

	location = location;

	
}


/*****************************************************************************************/
function CompleteChecklistItem_onChange2(htmlElement) {
/*****************************************************************************************/
	
	if (htmlElement.getAttribute('disabled') == 'disabled') {
		return false;
	}
	
	var id = htmlElement.getAttribute('data-val');
	var completionType = htmlElement.parentNode.parentNode.parentNode.tagName;
	var completed;
	var cmd;
	var msg;
			
	if (completionType == 'TBODY') {

		cmd = 'updateItem';
		if (htmlElement.childNodes[0].innerText == 'check_box') {
			completed = 0;
		} else {
			completed = 1;
		}		

	} else {

		cmd = 'updateList';
		if (htmlElement.childNodes[1].innerText == 'check_box') {
			completed = 0;
		} else {
			completed = 1;
		}		

	}

	var requestUrl 	= "ajax/taskMaintenance.asp"
												+ "?cmd=" + cmd
												+ "&id=" + id
												+ "&completed=" + completed;
												
	console.log(requestUrl);
	
	CreateRequest();
 
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

				alert("problem retrieving data from the server, status code: "  + request.status + " - 7");

			}
		}
	
	}

}


// /*****************************************************************************************/
// function CompleteChecklistItem_onChange(htmlElement) {
// /*****************************************************************************************/
// 	
// 	var id = htmlElement.getAttribute('data-val');
// 	var completionType = htmlElement.parentNode.parentNode.parentNode.tagName;
// 	var completed;
// 	var cmd;
// 	var msg;
// 			
// 	if (completionType == 'TBODY') {
// 
// 		cmd = 'updateItem';
// 		if (htmlElement.MaterialCheckbox.inputElement_.checked) {
// 			completed = 0;
// 		} else {
// 			completed = 1;
// 		}		
// 
// 	} else {
// 
// 		cmd = 'updateList';
// 		if (htmlElement.MaterialCheckbox.inputElement_.checked) {
// 			completed = 1;
// 		} else {
// 			completed = 0;
// 		}		
// 
// 	}
// 
// 	var requestUrl 	= "ajax/taskMaintenance.asp"
// 												+ "?cmd=" + cmd
// 												+ "&id=" + id
// 												+ "&completed=" + completed;
// 												
// 	console.log(requestUrl);
// 	
// 	CreateRequest();
//  
// 	if(request) {
// 		request.onreadystatechange = StateChangeHandler_taskName;
// 		request.open("GET", requestUrl,  true);
// 		request.send(null);		
// 	}
// 
// 	function StateChangeHandler_taskName() {
// 	
// 		if(request.readyState == 4) {
// 			if(request.status == 200) {
// 
// 				ChecklistStatus(request.responseXML);
// 				
// 			} else {
// 
// 				alert("problem retrieving data from the server, status code: "  + request.status);
// 
// 			}
// 		}
// 	
// 	}
// 
// }


/*****************************************************************************************/
function ChecklistStatus(xml) {
/*****************************************************************************************/

	var id 						= GetInnerText(xml.getElementsByTagName('id')[0]);
	var cmd 						= GetInnerText(xml.getElementsByTagName('cmd')[0]);
	var completed				= GetInnerText(xml.getElementsByTagName('completed')[0]);
	var taskCompletable		= GetInnerText(xml.getElementsByTagName('taskCompletable')[0]);
	var msg						= GetInnerText(xml.getElementsByTagName('msg')[0]);
	

	var notification 	= document.querySelector('.mdl-js-snackbar');


	if (cmd == 'Item') {

		var checklistCompleted	= GetInnerText(xml.getElementsByTagName('checklistCompleted')[0]);

		if (completed == '1') {
			document.getElementById('checklistItem-'+id).childNodes[0].innerText = 'check_box';
		} else {
			document.getElementById('checklistItem-'+id).childNodes[0].innerText = 'check_box_outline_blank';
		}
		
		var checklistTable 			= document.getElementById('checklistItem-'+id).parentNode.parentNode.parentNode.parentNode;

		var checklistHead 			= checklistTable.childNodes[1];
		var checklistHeadTr			= checklistHead.childNodes[1];
		var checklistHeadTrTh		= checklistHeadTr.childNodes[1];
		var checklistIconTrThDiv	= checklistHeadTrTh.childNodes[1];
		var checklistIcon 			= checklistIconTrThDiv.childNodes[1];
		var refreshPage;
		
		if (checklistCompleted == '1') {
			
			if (checklistIcon.innerText == 'check_box') {
				refreshPage	= false;
			} else {
				checklistIcon.innerText = 'check_box';
				refreshPage = true;
			}
			
		} else {
			
			if (checklistIcon.innerText == 'check_box_outline_blank') {
				refreshPage = false;
			} else {
				checklistIcon.innerText = 'check_box_outline_blank';
				refreshPage = true;
			}
			
		}
		
		
	} else {

		refreshPage = true;

		var checklistItemCheckboxes = document.querySelectorAll('.checklist-'+id);
		for (i = 0; i < checklistItemCheckboxes.length; ++i) {

			if (completed == '0') {
				checklistItemCheckboxes[i].innerText = 'check_box_outline_blank';
			} else {
				checklistItemCheckboxes[i].innerText = 'check_box';
			}

		}


	}


	
	var completionDateElem = document.getElementById('completionDate');
	completionDateElem.parentNode.classList.add('is-dirty');

	if (taskCompletable == 'true') {
		completionDateElem.disabled = false;
		completionDateElem.parentNode.classList.remove('is-invalid');
	} else {
		completionDateElem.disabled = true;
		completionDateElem.parentNode.classList.add('is-invalid');
	}


	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	if (refreshPage) {
		location = location;
	}
	
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
	
	CreateRequest();
 
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
				alert("problem retrieving data from the server, status code: "  + request.status + " - 8");
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
function DeleteChecklistItem_onClick(htmlElement) {
/*****************************************************************************************/


	if (!confirm('Are you sure you want to delete this item?\nThis action is permanent and cannot be undone.\n\n')) {
		return false;
	}
	
	var itemID = htmlElement.getAttribute('data-val');
		
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=deleteItem"
												+ "&id=" + itemID;
												
	
	console.log(requestUrl);
	
	CreateRequest();
 
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
				alert("problem retrieving data from the server, status code: "  + request.status + " - 9");
			}
		}
	
	}

	
}



/*****************************************************************************************/
function DeleteChecklist_onClick(htmlElement) {
/*****************************************************************************************/


	if (!confirm('Are you sure you want to delete this checklist and all of its items?\nThis action is permanent and cannot be undone.\n\n')) {
		return false;
	}
	
	var taskChecklistID = htmlElement.getAttribute('data-val');
		
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=deleteTaskChecklist"
												+ "&id=" + taskChecklistID;
												
	
	console.log(requestUrl);
	
	CreateRequest();
 
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
				alert("problem retrieving data from the server, status code: "  + request.status + " - 10");
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
function AddChecklist_onSave(htmlElement) {
/*****************************************************************************************/

	var checklistName 	= document.getElementById('newChecklistName').value;
	var taskID				= document.getElementById('newChecklistName').getAttribute('data-taskID');
	
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=addChecklist"
													+ "&task=" + taskID 
													+ "&name=" + encodeURIComponent(checklistName);
	
	console.log(requestUrl);
	
	CreateRequest();
 
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
				alert("problem retrieving data from the server, status code: "  + request.status + " - 11");
			}
		}
	
	}

	location = location;
	
}



/*****************************************************************************************/
function SaveSkippedReason() {
/*****************************************************************************************/
	
	var taskID = dialog_skippedReason.querySelector('#skippedReasonTaskID').value;
	
	var objSkippedReason = new Quill('#skippedReason');
	
	var skippedReasonContents 	= objSkippedReason.getContents();
	var skippedReasonString 	= JSON.stringify(skippedReasonContents);	
	var skippedReasonHTML 		= objSkippedReason.root.innerHTML;

	if (!skippedReasonString.length > 0) {
		alert('Narrative explaining reason for skipping a task is required.');
		return false;
	}
	
// 	var directive	= "ajax/taskMaintenance.asp?cmd=skipTask";
	var payload		= "taskID=" + taskID 
						+ "&skippedReasonString=" 	+ encodeURIComponent(skippedReasonString)
						+ "&skippedReasonHTML=" 	+ encodeURIComponent(skippedReasonHTML);

// 	console.log(directive + '&' + payload);
	console.log(payload);
											
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_SaveSkippedReason;
		request.open("POST", "ajax/taskMaintenance.asp?cmd=skipTask");
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
		request.send(payload);
	}

	function StateChangeHandler_SaveSkippedReason() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				location = location;
// 				Complete_SaveSkippedReason(request.responseXML);
			} else {
				console.log('request.readyState: ' + request.readyState + ', request.status: ' + request.status);
				alert("problem retrieving data from the server, status code: "  + request.status + " - 12");
			}
		}
	
	}	
	
}



/*****************************************************************************************/
function Complete_SaveSkippedReason(xml) {
/*****************************************************************************************/

// 	// close the skippedReason dialog...
// 	dialog_skippedReason.close();
// 	
// 	// get data from xml...
// 	var msg 						= GetInnerText(xml.getElementsByTagName('msg')[0]);
// 	var taskStatusID			= GetInnerText(xml.getElementsByTagName('taskStatusID')[0]);
// 	var completionDate 		= GetInnerText(xml.getElementsByTagName('completionDate')[0]);
// 	
// 	
// 	
// 	var quillID 				= GetInnerText(xml.getElementsByTagName('quillID')[0]);
// 	var rawQuillID 			= GetInnerText(xml.getElementsByTagName('rawQuillID')[0]);
// 	var callNoteNarrative 	= GetInnerText(xml.getElementsByTagName('callNoteNarrative')[0]);
// 	
// 	eval(quillID).setContents(JSON.parse(callNoteNarrative));
// // 	eval(rawQuillID).setContents(JSON.parse(callNoteNarrative));
// 
// 	document.getElementById('quillContainer').innerHTML = '<div id="genericQuillNote"></div>';
// 
// 
// 	var callHistorybutton = document.getElementById('historyButton_'+quillID);
// 	if (callHistorybutton) {
// 		callHistorybutton.style.display = 'inline-block';
// 	}
// 	
// 	
// 		
// 	var notification = document.querySelector('.mdl-js-snackbar');
// 	notification.MaterialSnackbar.showSnackbar(
// 		{
// 		message: msg
// 		}
// 	);
// 	
// // 	location = location;
// 
}




/*****************************************************************************************/
function attribute_onChange(attributeNode,task) {
/*****************************************************************************************/

	var attributeName 	= attributeNode.id;
	var projectStartDate = document.getElementById('projectStartDate').value;
	var projectEndDate = document.getElementById('projectEndDate').value;
	var attributeValue;
	
	if(attributeName == "ownerID") {
		attributeValue = attributeNode.options[attributeNode.selectedIndex].value;
	} else {
		attributeValue 	= attributeNode.value.replace(String.fromCharCode(39), "\'");
		attributeValue 	= attributeValue.replace(String.fromCharCode(34), '\"');
	}
	
	if (attributeName == 'startDate') {
		
		if (attributeValue) {
			
			if (!moment(attributeValue).isValid()) {
				alert('Start date is not a valid date');
				return false;
			} else {
				
				var taskDueDate = document.getElementById('dueDate').value;

				if (projectStartDate) {				
					if (!moment(attributeValue).isSameOrAfter(projectStartDate)) {
						alert('Start date cannot be prior to project start date');
						return false;
					} else {
						if (projectEndDate) {
							if (!moment(attributeValue).isSameOrBefore(projectEndDate)) {
								alert('Start date cannot be after project end date');
								return false;
							}
						}
					}
				}
				
				if (!moment(attributeValue).isSameOrBefore(taskDueDate)) {
					alert('Start date cannot be after due date');
					return false;
				}
				
				attributeNode.parentNode.classList.remove('is-invalid');
				document.getElementById('dueDate').min = moment(attributeValue).format('YYYY-MM-DD');
				
			}
			
		} else {
			attributeNode.focus();
			attributeNode.parentNode.classList.add('is-invalid');
			attributeNode.parentNode.classList.add('is-dirty');
			attributeNode.setAttribute('min', projectStartDate);
			return false;
		}
	}
	
	if (attributeName == 'dueDate') {
		
		if (attributeValue) {
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

				attributeNode.parentNode.classList.remove('is-invalid');

			}

		} else {
			attributeNode.focus();
			attributeNode.parentNode.classList.add('is-invalid');
			attributeNode.parentNode.classList.add('is-dirty');
			attributeNode.setAttribute('max', projectEndDate);
			return false;
		}

	}
	
	if (attributeName == 'taskStatusID') {
		
		attributeValue = attributeNode.options[attributeNode.selectedIndex].value;
		
	}
	
	
	if (attributeName == 'completionDate') {
		if (attributeValue.length > 0) {
			if (!moment(attributeValue).isValid()) {
				alert('Completion date is not a valid date');
				return false;
			}
		} 
	}
	
	
	
	
	
	var requestUrl 	= "ajax/taskMaintenance.asp?cmd=update&task=" + task + "&name=" + attributeName + "&value=" + encodeURIComponent(attributeValue);
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_taskAttributeUpdate;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_taskAttributeUpdate() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
// 				attribute_status(request.responseXML);
// 				if (attributeName == 'completionDate') {
// 					attributeNode.parentNode.classList.add("is-dirty");
					location = location;
// 				}
// 				alert("post attribute_status");
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status + " - 13");
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
	document.getElementById('taskDaysAhead').value 	= taskDaysAhead;
	document.getElementById('taskDaysBehind').value = taskDaysBehind;

	var attributeName 		= urNode.getElementsByTagName('name')[0].textContent;
	var attributeValue 		= urNode.getElementsByTagName('value')[0].textContent;
	var completionDateInput	= document.getElementById('completionDate');
	var completionDateDIV 	= completionDateInput.closest('div.csuite-textfield');
	var completionDateView	= completionDateDIV.querySelector('div.csuite-textfield-viewValue');
	var currentDate			= moment();

	if (attributeName == 'taskStatusID') {
		if (attributeValue == '2' || attributeValue == '3') {
			// make the completionDate visible...
			completionDateDIV.style.visibility = 'visible';
			if (!completionDateInput.value) {
				completionDateInput.value 		= currentDate.format('YYYY-MM-DD');
				completionDateView.innerHTML 	= currentDate.format('M/D/YYYY');
			}
		} else {
			// make the completionDate hidden...
			completionDateDIV.style.visibility = 'hidden';
		}
		
	}
	
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
			alert("problem retrieving data from the server, status code: "  + request.status + " - 14");
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


