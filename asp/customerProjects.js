//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->
console.log('customerProjects.js loaded');

"use strict";

/*****************************************************************************************/
function ConfirmProjectDelete_onClick( htmlElement ) {
/*****************************************************************************************/
	
	
	const row 	= $( htmlElement ).closest('TR');
	const data 	= $( '#tbl_projects' ).DataTable().row( row ).data();

	$( '#dialog-confirm' ).find( 'p' ).text( 'The project, "' + data[ 'projectName' ] + '," its tasks, checklists, and checklist items will be permanently deleted and cannot be recovered. Are you sure?' );
	$( '#dialog-confirm' ).find( 'input#id' ).val( data[ 'DT_RowId' ] );
	$( '#dialog-confirm' ).find( 'input#customerID' ).val( data[ 'customerID' ] );

	$( '#dialog-confirm' ).dialog( 'open' );


}
/*****************************************************************************************/


/*****************************************************************************************/
async function DeleteProject( dialog ) {
/*****************************************************************************************/

	$( dialog ).dialog( 'close' );


	var id				= dialog.querySelector( '#id' ).value;
	var customerID		= dialog.querySelector( '#customerID' ).value;

	const url 	= 'ajax/projects.asp';
	const body 	= 'customerID=' + customerID + '&id=' + id;

	const apiResponse = await fetch( url, {
		method: 'DELETE',
		headers: { 'Content-type': 'application/x-www-form-urlencoded' },
		body: body
	});
	
	if ( apiResponse.status != 200 ) {
		return generateErrorResponse('failed to DELETE project, ' + apiResponse.status);	
	}

	const apiResult = await apiResponse.json();
	
	const notification = $( '.mdl-js-snackbar' ).get(0);
	
	notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

	$( '#tbl_projects' ).DataTable().ajax.reload();		
	

	
}
/*****************************************************************************************/



/*****************************************************************************************/
async function toggleTaskProject( taskID, customerID, projectID ) {
/*****************************************************************************************/


	try {
		
		const response = await $.ajax({
			url: `${apiServer}/api/tasks/taskProject`,
			type: 'PUT',
			data: { 
				taskID: taskID,
				customerID: customerID, 
				projectID: projectID
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
		});

		if ( !response || !response.success ) {
			throw new Error( 'Unnexpected response format' );
		}
		
		return response;
		
	} catch( err ) {
		
		console.error( 'Error toggling task/project', err );
		throw err;
		
	}


}
/*****************************************************************************************/

	

/*****************************************************************************************/
async function addTaskKeyInitiative( keyInitiativeID, projectID ) {
/*****************************************************************************************/

	return $.ajax({
		url: `${apiServer}/api/tasks/taskKeyInitiative`,
		type: 'POST',
		data: { 
			keyInitiativeID: keyInitiativeID,
			projectID: projectID
		},
		headers: { 'Authorization': 'Bearer ' + sessionJWT }
	});


}
/*****************************************************************************************/

	

/*****************************************************************************************/
async function deleteTaskKeyInitiative( keyInitiativeID, projectID ) {
/*****************************************************************************************/
	
	return $.ajax({
		url: `${apiServer}/api/tasks/taskKeyInitiative`,
		type: 'DELETE',
		data: { 
			keyInitiativeID: keyInitiativeID,
			projectID: projectID
		},
		headers: { 'Authorization': 'Bearer ' + sessionJWT }
	});


}
/*****************************************************************************************/




//-- ------------------------------------------------------------------ -->
async function GetAssociatedKIs(customerID,projectID) {
//-- ------------------------------------------------------------------ -->
	

	// if this project is already open, just close it...
	var requestedProjectRow = document.getElementById(projectID);
	var requestedTogglerCell = requestedProjectRow.querySelector('td.toggleKI');
	var requestedTogglerIcon = requestedTogglerCell.querySelector('i.material-icons');
	
	if ( requestedTogglerIcon.textContent = 'unfold_less' ) {
		
		var rowToDelete = requestedProjectRow.nextSibling;
		if (rowToDelete.classList.contains('kiProjectRow')) {
			rowToDelete.remove();
			requestedTogglerIcon.textContent = 'unfold_more';
			return;
		}
		
	}

	// now get the KI info for the project...	
	var url 	= '/ajax/getKeyInitiativesByProject.asp'
							+ '?customerID=' + customerID
							+ '&projectID=' + projectID;

	const response = await fetch(url);
	if (response.status !== 200) {
		return generateErrorResponse('Failed to fetch KIs by project ' + response.status);
	}
	const result = await response.json();

	const projectRow 			= document.getElementById(projectID);
	const projectStartDate 	= moment(projectRow.querySelector('td.start').textContent, 'M-D-YYYY');
	const projectEndDate		= moment(projectRow.querySelector('td.end').textContent, 'M-D-YYYY');
	
	const revealerCell = projectRow.querySelector('td.toggleKI');
	const revealerIcon = revealerCell.querySelector('i');
	const projectTable = projectRow.closest('table');

	var kiProjectRow = projectTable.insertRow(projectRow.rowIndex + 1);
	kiProjectRow.classList.add('kiProjectRow');

	var kiProjectCell = document.createElement('td');
	kiProjectRow.appendChild(kiProjectCell);
	kiProjectCell.colSpan = 9;


	if ( result.associated ) {

		var kiTable				= document.createElement('table');
		kiTable.classList.add('mdl-data-table');
		kiTable.classList.add('mdl-js-data-table');
		kiTable.classList.add('mdl-shadow--2dp');
		kiTable.classList.add('cNoteScrollable');
		kiTable.style.width = 'auto';
		kiTable.style.marginLeft = 'inherit';
		kiProjectCell.appendChild(kiTable);

		
		var kiTableHead		= document.createElement('thead');
		kiTable.appendChild(kiTableHead);
		
		var kiHeaderRow 		= document.createElement('tr');
		kiTableHead.appendChild(kiHeaderRow);


		var kiNameHead			= document.createElement('th');
		kiHeaderRow.appendChild(kiNameHead);
		kiNameHead.classList.add('mdl-data-table__cell--non-numeric');
		kiNameHead.classList.add('cNoteFixedCellGiant');
		var kiNameText	= document.createTextNode('Associated Key Initiatives');
		kiNameHead.appendChild(kiNameText);

		var kiStartHead 		= document.createElement('th');
		kiHeaderRow.appendChild(kiStartHead);
		kiStartHead.classList.add('mdl-data-table__cell--non-numeric');
		kiStartHead.classList.add('cNoteFixedCellLarger');
		var kiStartText = document.createTextNode('Start');
		kiStartHead.appendChild(kiStartText);
	

		var kiEndHead 			= document.createElement('th');
		kiHeaderRow.appendChild(kiEndHead)
		kiEndHead.classList.add('mdl-data-table__cell--non-numeric');
		kiEndHead.classList.add('cNoteFixedCellLarger');
		var kiEndText = document.createTextNode('End');
		kiEndHead.appendChild(kiEndText);
		

		var kiCompleteHead 	= document.createElement('th');
		kiHeaderRow.appendChild(kiCompleteHead);
		kiCompleteHead.classList.add('mdl-data-table__cell--non-numeric');
		kiCompleteHead.classList.add('cNoteFixedCellLarger');
		var kiCompleteText = document.createTextNode('Complete');
		kiCompleteHead.appendChild(kiCompleteText);
		

		var kiRemoveHead 		= document.createElement('th');
		kiHeaderRow.appendChild(kiRemoveHead);
		
		var kiBody = document.createElement('tbody');
		kiBody.style.height = 'auto';
		kiTable.appendChild(kiBody);
		
		for (i = 0; i < result.associated.length; ++i) {
			
			var kiRow = document.createElement('tr');
			kiBody.appendChild(kiRow);
			
			var kiName = document.createElement('td');
			kiName.classList.add('mdl-data-table__cell--non-numeric');
			kiName.classList.add('cNoteFixedCellGiant');
			kiName.innerHTML = result.associated[i].name;
			kiRow.appendChild(kiName);
			
			var kiStart = document.createElement('td');
			kiStart.classList.add('mdl-data-table__cell--non-numeric');
			kiStart.classList.add('cNoteFixedCellLarger');
			kiStart.innerHTML = moment(result.associated[i].startDate).format('M/D/YYYY');
			kiRow.appendChild(kiStart);
			
			var kiEnd = document.createElement('td');
			kiEnd.classList.add('mdl-data-table__cell--non-numeric');
			kiEnd.classList.add('cNoteFixedCellLarger');
			kiEnd.innerHTML = moment(result.associated[i].enddate).format('M/D/YYYY');
			kiRow.appendChild(kiEnd);
			
			var kiComplete = document.createElement('td');
			kiComplete.classList.add('mdl-data-table__cell--non-numeric');
			kiComplete.classList.add('cNoteFixedCellLarger');
			if ( moment(result.associated[i].completeDate).isValid() ) {
				kiComplete.innerHTML = moment(result.associated[i].completeDate).format('M/D/YYYY');
			}
			kiRow.appendChild(kiComplete);
			
			var kiRemove = document.createElement('td');
			kiRow.appendChild(kiRemove);
			
			var kiRemoveIcon = document.createElement('i');
			kiRemoveIcon.id = result.associated[i].id;
			kiRemoveIcon.classList.add('material-icons');
			kiRemoveIcon.classList.add('cNoteFixedCellSmall');
			kiRemoveIcon.classList.add('removeKI');
			kiRemoveIcon.setAttribute('data-proj', projectID);
			kiRemoveIcon.setAttribute('data-ki', result.associated[i].id);
			kiRemoveIcon.textContent = 'remove_circle_outline';
			kiRemoveIcon.style.display = 'none';
			kiRemove.appendChild(kiRemoveIcon);
			
			
			kiRow.addEventListener('mouseover', function() {
				ToggleRemoveIcons(this);
			});
			
			kiRow.addEventListener('mouseout', function() {
				ToggleRemoveIcons(this)
			});
			
		}
		
	}
	
	if ( result.unassociated ) {
		
		var hardBread = document.createElement('br');
		kiProjectCell.appendChild(hardBread);
		
		var selectUnAssociateKIs = document.createElement('select');
		selectUnAssociateKIs.style.display = 'block';
		selectUnAssociateKIs.style.width = '500px';
		selectUnAssociateKIs.classList.add('mdl-textfield__input');
		selectUnAssociateKIs.addEventListener('change', function() {
			AddKeyInitiativeToProject(this,projectID,customerID);
		});
		kiProjectCell.appendChild(selectUnAssociateKIs);

		
		var defaultOption = document.createElement('option');
		defaultOption.textContent = 'Associate additional key initiatives...';
		selectUnAssociateKIs.appendChild(defaultOption);
		
		for (i = 0; i < result.unassociated.length; ++i) {
						
			var newOption = document.createElement('option');
			newOption.value = result.unassociated[i].id;
			newOption.textContent = result.unassociated[i].name;
			
			if ( projectStartDate.isAfter(moment(result.unassociated[i].startDate)) || projectEndDate.isBefore(moment(result.unassociated[i].endDate)) ) {
				newOption.disabled = 'true';
				newOption.title = 'Project timeframe (' 
												+ projectStartDate.format('M/D/YYYY')
												+ '-'
												+ projectEndDate.format('M/D/YYYY')
												+ ') does not fit into the KI timeframe ('
												+ moment(result.unassociated[i].startDate).format('M/D/YYYY')
												+ '-'
												+ moment(result.unassociated[i].endDate).format('M/D/YYYY')
												+ ')';
			}

			selectUnAssociateKIs.appendChild(newOption);
			
		}
		
		var addOption = document.createElement('option');
		newOption.textContent = 'Add new key initiative...';
		selectUnAssociateKIs.appendChild(newOption);
		
		
	}

	
	revealerIcon.textContent = 'unfold_less';
	
	




/*
	if (result.associated.length > 0) {
	
		
		
		
// 		var kiName 				= document.createElement('td');
// 		var kiStartDate 		= document.createElement('td');
// 		var kiEndDate 			= document.createElement('td');
// 		var kiCompleteDate 	= document.createElement('td');
// 		var kiRemove 			= document.createElement('td');
// 	
// 		var kiDataRow			= document.createElement('tr');
// 		
// 	
// 	
// 		
// 		
// 		
// 		
// 		kiRemoveHead.classList.add('mdl-data-table__cell--non-numeric');
// 		
// 	
// 		kiHeaderRow.appendChild(kiNameHead);
// 		kiHeaderRow.appendChild(kiStartHead);
// 		kiHeaderRow.appendChild(kiEndHead);
// 		kiHeaderRow.appendChild(kiCompleteHead);
// 		kiHeaderRow.appendChild(kiRemoveHead);
// 		
// 		
// 		
	
	}
	
	if (result.unassociated.length > 0) {
		
	}	
*/


}
//-- ------------------------------------------------------------------ -->



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


/*****************************************************************************************/
function ProjectStartDate_onBlur(htmlElement) {
/*****************************************************************************************/
	
	if (htmlElement.parentNode.classList.contains('is-invalid')) {
		alert(htmlElement.parentNode.querySelector('span.mdl-textfield__error').innerHTML);
		DialogDateInvalid(htmlElement);
		return false;
	}

	var startDate 				= moment(htmlElement.value);
	var currStartDateMax 	= moment(htmlElement.getAttribute('max'));
	var startDateLabelElem 	= htmlElement.parentNode.querySelector('span.mdl-textfield__error');
	
	var endDateElem 			= document.getElementById('add_projectEndDate');
	var endDate					= moment(endDateElem.value);
	var currEndDateMin		= moment(endDateElem.getAttribute('min'));
	var dueDateLabelElem		= endDateElem.parentNode.querySelector('span.mdl-textfield__error')


	if (startDate.isValid()) {
		
		if (currStartDateMax.isValid()) {

			if (startDate.isAfter(currStartDateMax)) {
				alert('Start date must preceed end date.');
				DialogDateInvalid(htmlElement);
				return false;
			}

		}

		endDateElem.setAttribute('min', startDate.format('YYYY-MM-DD'));
		dueDateLabelElem.innerHTML = 'Enter an end date after ' + startDate.format('MM/DD/YYYY');
		DialogDateValid(htmlElement);

	} else {
		
		alert('Value entered for start date is not valid.');
		DialogDateInvalid(htmlElement);
		return false;

	}


}



/*****************************************************************************************/
function ProjectEndDate_onBlur(htmlElement) {
/*****************************************************************************************/
	
	
	if (htmlElement.parentNode.classList.contains('is-invalid')) {
		alert(htmlElement.parentNode.querySelector('span.mdl-textfield__error').innerHTML);
		DialogDateInvalid(htmlElement);
		return false;
	}

	var endDate 				= moment(htmlElement.value);
	var endDateLabelElem 	= htmlElement.parentNode.querySelector('span.mdl-textfield__error');


	var startDateElem			= document.getElementById('add_projectStartDate');
	var startDateLabelElem 	= startDateElem.parentNode.querySelector('span.mdl-textfield__error');
	var startDate				= moment(startDateElem.value);

	var currStartDateMax = moment(startDateElem.getAttribute('max'));
	var currEndDateMin 	= moment(htmlElement.getAttribute('min'));

	
	if (endDate.isValid()) {

		if (currEndDateMin.isValid()) {

			if (endDate.isBefore(currEndDateMin)) {
				alert('Due date cannot preceed start date.');
				DialogDateInvalid(htmlElement);
				return false;
			}

		}

		startDateElem.setAttribute('max', endDate.format('YYYY-MM-DD'));
		startDateLabelElem.innerHTML = 'Enter a start date before ' + endDate.format('MM/DD/YYYY');
		DialogDateValid(htmlElement)

	} else {
		
		alert('Value entered for due date is not a valid date.');
		DialogDateInvalid(htmlElement);
		return false;
		
	}
	
		
}


/*****************************************************************************************/
function DialogDateInvalid(dateElement) {
/*****************************************************************************************/
	
	var dialog 				= dateElement.closest('dialog');
	var dialogSaveButton = dialog.querySelector('button.save');
	dialogSaveButton.disabled = true;

// 	dateElement.parentNode.classList.add('is-invalid');
// 	dateElement.focus();
// 	dateElement.select();
			
}



/*****************************************************************************************/
function DialogDateValid(dateElement) {
/*****************************************************************************************/
	
	var dialog 				= dateElement.closest('dialog');
	var dialogSaveButton = dialog.querySelector('button.save');
	dialogSaveButton.disabled = false;

	dateElement.parentNode.classList.remove('is-invalid');

}


/*****************************************************************************************/
function ProjectCompleteDate_onBlur(htmlElement) {
/*****************************************************************************************/
	
	if (htmlElement.value) {

		var completeDate = moment(htmlElement.value);
		
		if (completeDate.isValid()) {
			htmlElement.parentNode.classList.remove('is-invalid');
		} else {
			htmlElement.parentNode.classList.add('is-invalid');
			alert("Project complete date is not a valid date");
		}

	}
	
	htmlElement.parentNode.classList.add("is-dirty");

}



/*****************************************************************************************/
function ProductName_onBlur(htmlElement) {
/*****************************************************************************************/

	if (htmlElement.selectedIndex == 0) {
		htmlElement.parentNode.classList.add('is-invalid');
	} else {
		htmlElement.parentNode.classList.remove('is-invalid');
		document.getElementById('add_projectName').parentNode.classList.add('is-dirty');
		document.getElementById('add_projectName').focus();
	}
	
}



/*****************************************************************************************/
function ProductName_onChange(htmlElement) {
/*****************************************************************************************/
	
// 	var projectTemplate 	= document.getElementById('add_projectProduct').parentNode;
// 	var projectName 		= document.getElementById('add_projectName').parentNode;
// 	var existingProjects = document.getElementById('existingProjects').parentNode;
// 	var projectManger 	= document.getElementById('add_projectManagers').parentNode;

	var anchorType 		= document.getElementById('add_anchorType');
	var anchorDate 		= document.getElementById('add_anchorDate').parentNode;
	var startDate 			= document.getElementById('add_projectStartDate').parentNode;
	var endDate 			= document.getElementById('add_projectEndDate').parentNode;
	var projectName		= document.getElementById('add_projectName');

	var selectedTemplateName = htmlElement.options[htmlElement.selectedIndex].text;
	var selectedTemplateValue = htmlElement.value;
	
	if (selectedTemplateValue == 0) {

		// creating project from scratch...

		startDate.style.display = 'block';
		startDate.classList.add('is-dirty');
		startDate.classList.remove('is-invalid');
		
		endDate.style.display = 'block';
		endDate.classList.add('is-dirty');
		endDate.classList.remove('is-invalid');

		anchorType.style.display = 'none';
		anchorDate.style.display = 'none';
				
	} else {
		
		// creating project from template...
		
		projectName.value = selectedTemplateName;
		projectName.parentNode.classList.add('is-dirty');
		projectName.parentNode.classList.remove('is-invalid');
		

		startDate.style.display = 'none';
		endDate.style.display = 'none';

		anchorType.style.display = 'block';
		anchorDate.style.display = 'block';
		anchorDate.classList.add('is-dirty');
		anchorDate.classList.add('is-invalid');
		
	}
	
	
	
}


/*****************************************************************************************/
function EditProject_onClick(htmlElement) {
/*****************************************************************************************/

	let isWeekend, isHoliday;
	
	const row 		= $( htmlElement ).closest('TR');
	const data 		= $( '#tbl_projects' ).DataTable().row( row ).data();
	const $validationTips = $( '#dialog-form' ).find( 'p.validateTips' );
	$validationTips.html( '<div>Name, start date, and end date are required.</div>' );
	
	$( '#id' ).val( data[ 'id' ] );
	$( '#customerID' ).val( data[ 'customerID' ] );
	$( '#name' ).val(
		( data['name'] || '' )
			.replace( /&quot;/gi, '"' )
			.replace( /&trade;/gi, '\u2122' )
			.replace( /\(tm\)/gi, '\u2122' )
			.replace( /â„¢/gi, '\u2122' )
			.replace( /<br>/gi, '\n' )
	);

// 	console.log('projectManagerID: ' + data[ 'projectManagerID' ] + ', projectManagerName: '+ data[ 'projectManagerName' ]);

	if ( data[ 'projectManagerID' ] !== '0' ) {	
	
		$( '#projectManager' ) 		.selectmenu();
		$( '#projectManager' ) 		.val( data[ 'projectManagerID' ]);
		$( '#projectManager' ) 		.selectmenu( 'refresh' );
	
	}
	
	const mStartDate = moment( data[ 'startDate' ]).toDate();
	
	const mStart = moment.utc( data[ 'startDate' ] ).local();	
	isWeekend = (mStart.day() === 0 || mStart.day() === 6);
	isHoliday = publicHolidays.includes(mStart.format('YYYY-MM-DD'));
	
	if ( data[ 'taskCount' ] > 0 ) {
		$( '#startDate' ).datepicker( 'disable' );
		$( '#endDate' ).datepicker( 'disable' );
		$validationTips.html( $validationTips.html() + '<div style="color: red;">Adjust project start/end dates by editing the task(s) in the project.</div>' );
	} else {
		$( '#startDate' ).datepicker( 'enable' );
		$( '#endDate' ).datepicker( 'enable' );
	}

	if ( isWeekend || isHoliday ) {
		$( '#startDate' ).css( 'color', 'red' );
		if ( !data[ 'isTemplatable' ] ) {
			$validationTips.html( $validationTips.html() + '<div class="startDateTip" style="color: red;">Start Date is not a workday.</div>' );
		}
// 		$( '#startDate' ).addClass('is-invalid');
	} else {
		$( '#startDate' ).css( 'color', '' );
// 		$( '#startDate' ).removeClass('is-invalid');
	}

								
	const mEndDate = moment( data[ 'endDate' ]).toDate();
	
	const mEnd = moment.utc( data[ 'endDate' ] ).local();	
	isWeekend = (mEnd.day() === 0 || mEnd.day() === 6);
	isHoliday = publicHolidays.includes(mEnd.format('YYYY-MM-DD'));


	if ( isWeekend || isHoliday ) {
		$( '#endDate' ).css( 'color', 'red' );
		if ( !data[ 'isTemplatable' ] ) {
			$validationTips.html( $validationTips.html() + '<div class="endDateTip" style="color: red;">End Date is not a workday.</div>' );
		}
// 		$( '#endDate' ).addClass('is-invalid');
	} else {
		$( '#endDate' ).css( 'color', '' );
// 		$( '#endDate' ).removeClass('is-invalid');
	}

	$( '#nameFieldset' ).show();
	$( '#projectManagerFieldset' ).show();
	$( '#addDatesFieldset' ).show();		
	
// 	$( '#startDate' ).val( data[ 'startDate' ]);
	$( '#startDate' ).datepicker( 'setDate', mStartDate );
	$( '#startDate' ).datepicker( 'option', 'maxDate', mEndDate );

// 	$( '#endDate' ).val( data[ 'endDate' ]);
	$( '#endDate' ).datepicker( 'setDate', mEndDate );
	$( '#endDate' ).datepicker( 'option', 'minDate', mStartDate );

	// Hide "process" selector -- it's only needed when adding a new project...
	$( '#processFieldset' ).hide();
	
	// Show "startDate" and "endDate"...
	$( '#scratch' ).show();
	
	// Hide "anchorDate" -- it's only needed when adding a new project from template...
	$( '#template' ).hide();
	

	$( '#dialog-form' ).dialog( {
		title: 'Edit Project'
	} );

	$( '#dialog-form' ).dialog( 'open' );

}


/*****************************************************************************************/
async function AddProject_onSave( dialog) {
/*****************************************************************************************/


	let form, 
		id					= $( '#id' ),
		customerID		= $( '#customerID' ),
		process 			= $( '#process' ),
		name				= $( '#name' ),
		projectManager = $( '#projectManager' ),
		startDate		= $( '#startDate' ),
		endDate			= $( '#endDate' ),
		anchorStart		= $( '#anchorStart' ),
		anchorEnd		= $( '#anchorEnd' ),
		anchorDate		= $( '#anchorDate' ),				
		tips				= $( '.validateTips' ),
		anchorDateType,
		url,
		body;

	//-----------------------------------------------------------------------//
	function UpdateTips( t ) {
	//-----------------------------------------------------------------------//

		tips
			.text( tips.text() + ' ' + t )
			.addClass( "ui-state-highlight" );

		setTimeout(function() {
			tips.removeClass( "ui-state-highlight", 1500 );
		}, 500 );

	}
	//-----------------------------------------------------------------------//
   
   
	//-----------------------------------------------------------------------//
   function CheckRequiredField( object, name, type ) {
	//-----------------------------------------------------------------------//
	   
	 	if ( object.val() ) {

		   if ( type === 'date' ) {

			   if ( !moment( object.val() ).isValid() ) {
				   object.addClass( 'ui-state-error' );
				   UpdateTips( name + ' must be a valid date. ' );
				   return false;
			   } else {
			   	return true;
			   }

		   } else {

			   return true;

		   }

		} else {

		   object.addClass( 'ui-state-error' );
		   UpdateTips( name + ' is required. ' );
		   return false;

		}
	   
	}
	//-----------------------------------------------------------------------//
	
	
// 	//-----------------------------------------------------------------------//
//    function CheckStartEndDates( objStartDate, objEndDate ) {
// 	//-----------------------------------------------------------------------//
// 
// 	   if ( moment( objStartDate.val() ).isAfter( moment( objEndDate.val() ) ) ) {
// 		   objStartDate.addClass( 'ui-state-error' );
// 		   objEndDate.addClass( 'ui-state-error' );
// 		   UpdateTips( 'Start date must proceed end date. ' );
// 		   return false;
// 	   } else {
// 	   	return true;
// 	   }
//     
// 	}
// 	//-----------------------------------------------------------------------//


	//-----------------------------------------------------------------------//
	//-----------------------------------------------------------------------//
	//-----------------------------------------------------------------------//
	//-----------------------------------------------------------------------//
	//-----------------------------------------------------------------------//
	try {
		
		$( '.ui-state-error' ).removeClass( 'ui-state-error' );
		tips.text('');
	
		var valid = true;
		
	

		if ( !!$( '#id' ).val() ) {
			var reqNameValid 				= CheckRequiredField( name, 'Name', 'text' );
			var reqNameValid 				= CheckRequiredField( name, 'Name', 'text' );
			var reqNameValid 				= CheckRequiredField( name, 'Name', 'text' );
	
			valid = valid && reqNameValid;
	
			if ( !valid ) {		
				return valid;
			}


	    	$.ajax({
	
				url: `${apiServer}/api/projects`,
				method: 'PUT',
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
				data: {
					projectID: $( '#id' ).val(),
					name: name.val(),
					customerID: customerID.val(),
					projectManagerID: projectManager.val(),
					startDate: moment( startDate.val() ).format( 'YYYY-MM-DD' ),
					endDate: moment( endDate.val() ).format( 'YYYY-MM-DD' )
				},
				success: function( response ) {

					const notification = $( '.mdl-js-snackbar' ).get(0);
					notification.MaterialSnackbar.showSnackbar({message: `Project updated` });
					$( '#tbl_projects' ).DataTable().ajax.reload();

				},
				error: function( xhr, status, error ) {
					const notification = $( '.mdl-js-snackbar' ).get(0);
					notification.MaterialSnackbar.showSnackbar({message: `Error adding project` });
					console.error( "Error updating project:", status, error );
				}
	
			});


		} else {
	
			if ( !id.val() ) {		
				var reqProces = CheckRequiredField( process, 'Process' , 'text' );
				valid = valid && reqProces;
			}
			
			
			if ( id.val() || $( '#process' ).val() == 'scratch' ) {

				var reqNameValid 				= CheckRequiredField( name, 'Name', 'text' );
				var reqStartDateValid 		= CheckRequiredField( startDate, 'Start Date', 'date' );
				var reqEndDateValid			= CheckRequiredField( endDate, 'End Date', 'date' );
// 				var reqDatesValid				= CheckStartEndDates( startDate, endDate );
		
				valid = valid && reqNameValid;
				valid = valid && reqStartDateValid;
				valid = valid && reqEndDateValid;
// 				valid = valid && reqDatesValid;
		
				if ( !valid ) {		
					return valid;
				}
		

		    	$.ajax({
					url: `${apiServer}/api/projects/fromScratch`,
					method: 'POST',
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: {
						name: name.val(),
						customerID: customerID.val(),
						product: process.val(),
						projectManagerID: projectManager.val(),
						startDate: moment( startDate.val() ).format( 'YYYY-MM-DD' ),
						endDate: moment( endDate.val() ).format( 'YYYY-MM-DD' )
					},
					success: function( response ) {
	
						const notification = $( '.mdl-js-snackbar' ).get(0);
						notification.MaterialSnackbar.showSnackbar({message: `Project added` });
						console.log( "Success:", response );	
						$( '#tbl_projects' ).DataTable().ajax.reload();
	
					},
					error: function( xhr, status, error ) {
						const notification = $( '.mdl-js-snackbar' ).get(0);
						notification.MaterialSnackbar.showSnackbar({message: `Error adding project` });
						console.error( "Error:", status, error );
					}
		
				});
				
		
			} else {

				if ( anchorEnd.prop( 'checked' ) ) {
					anchorDateType = 'end';
				} else {
					anchorDateType = 'start';
				}
		
				var reqNameValid 				= CheckRequiredField( name, 'Name', 'text' );
				var anchorDateValid			= CheckRequiredField( anchorDate, 'Anchor Date', 'date' );
		
				valid = valid && reqNameValid;
				valid = valid && reqProces;
				valid = valid && anchorDateValid;
				
				if ( !valid ) {		
					return valid;
				}
	
				$.ajax({
	
					url: `${apiServer}/api/projects/fromTemplate`,
					method: 'POST',
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: {
						customerID: customerID.val(),
						name: name.val(),
						product: process.val(),
						projectManagerID: projectManager.val(),
						anchorDateType: anchorDateType,
						anchorDate: anchorDate.val()
					},
					success: function( response ) {
	
						const notification = $( '.mdl-js-snackbar' ).get(0);
						notification.MaterialSnackbar.showSnackbar({message: `Project added` });
						console.log( "Success:", response );	
						$( '#tbl_projects' ).DataTable().ajax.reload();
	
					},
					error: function( xhr, status, error ) {

						const notification = $( '.mdl-js-snackbar' ).get(0);
						notification.MaterialSnackbar.showSnackbar({message: `Error adding project` });
						console.error( "Error:", status, error );
					}
	
				});
		
		
			
			}
		
		}
	
		return true;

	} catch( err ) {
		
		
		console.error( "Error:", err );
		return false;
		
	}

}


/*****************************************************************************************/
function RemoveProjectFromKeyInitiative(htmlElement, customerID) {
/*****************************************************************************************/
	
	var keyInitiativeID 	= htmlElement.getAttribute('data-ki');
	var projectID			= htmlElement.getAttribute('data-proj');
	
	var payload = "keyInitiativeID=" + keyInitiativeID 
					+ "&customerID=" + customerID 
					+ "&projectID=" + projectID;
					
	console.log(payload);

	CreateRequest();

	if(request) {
		request.onreadystatechange = StateChangeHandler_RemoveKeyInitiativeProject;
		request.open("POST", "ajax/customerMaintenance.asp?cmd=removeKeyInitiativeProject", true);
		request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
		request.send(payload);
	}

	function StateChangeHandler_RemoveKeyInitiativeProject() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {

				var projectID = request.responseXML.getElementsByTagName('projectID')[0].textContent;
				var customerID = request.responseXML.getElementsByTagName('customerID')[0].textContent;
				window.location.href = 'customerProjects.asp?id=' + customerID + '&projectID=' + projectID;

			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

		
	
	
}
/*****************************************************************************************/


/*****************************************************************************************/
function AddKeyInitiativeToProject(htmlElement, projectID, customerID) {
/*****************************************************************************************/
	
	var selectedKeyInitiativeName 	= htmlElement.options[htmlElement.selectedIndex].innerText;
	var selectedKeyInitiativeValue 	= htmlElement.options[htmlElement.selectedIndex].value;
	
	if (selectedKeyInitiativeValue == 'Add new key initiative...') {
	
	// link to 'customerKeyInitiatives.asp?id='+customerID;
	window.location.href='customerKeyInitiatives.asp?id=' + customerID;

	} else {
	
		var payload = "keyInitiativeID=" + selectedKeyInitiativeValue 
									+ "&customerID=" + customerID 
									+ "&projectID=" + projectID;

		CreateRequest();

		if(request) {
			request.onreadystatechange = StateChangeHandler_AddKeyInitiativeProject;
			request.open("POST", "ajax/customerMaintenance.asp?cmd=addKeyInitiativeProject", true);
			request.setRequestHeader("Content-type", "application/x-www-form-urlencoded; charset=UTF-8");
			request.send(payload);
		}
	
		function StateChangeHandler_AddKeyInitiativeProject() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {

					var projectID = request.responseXML.getElementsByTagName('projectID')[0].textContent;
					var customerID = request.responseXML.getElementsByTagName('customerID')[0].textContent;
					window.location.href = 'customerProjects.asp?id=' + customerID + '&projectID=' + projectID;
		
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	}

}
/*****************************************************************************************/

	
/*****************************************************************************************/
function ToggleRemoveIcons(htmlElement) {
/*****************************************************************************************/

	var removeIcon = htmlElement.querySelector('i.removeKI');
	
	if (removeIcon) {
		
		if (removeIcon.style.display == 'none') {
			removeIcon.style.display = 'inline-block';
		} else {
			removeIcon.style.display = 'none';
		}

	}
	
}
/*****************************************************************************************/
	


/*****************************************************************************************/
function ToggleActionIcons(htmlElement) {
/*****************************************************************************************/

	const actionIcons = htmlElement.querySelectorAll( 'td.actions i' );
	
	if ( actionIcons ) {
		for ( var i = 0; i < actionIcons.length; ++i ) {
			if ( actionIcons[i].style.visibility == 'visible' ) {
				actionIcons[i].style.visibility = 'hidden';
			} else {
				actionIcons[i].style.visibility = 'visible';
			}
		}
	}

}
/*****************************************************************************************/


/*****************************************************************************************/
function ToggleKIs(htmlElement) {
/*****************************************************************************************/

// 	var rowToToggle = htmlElement.parentNode.nextSibling.nextSibling.nextSibling.nextSibling;
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



/*****************************************************************************************/
function generateErrorResponse(message) {
/*****************************************************************************************/

	return {
		status : 'error',
		message
	};

}
/*****************************************************************************************/


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}
/*****************************************************************************************/
