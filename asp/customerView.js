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
function ToggleCallActionIcons(callID) {
/*****************************************************************************************/

// 	var deleteIcon = htmlElement.childNodes[11].childNodes[3];
// 	
// 	if (deleteIcon.style.display == 'none') {
// 		deleteIcon.style.display = 'block';
// 	} else {
// 		deleteIcon.style.display = 'none';
// 	}
// 	
	var deleteIcon = document.getElementById('callDelete-'+callID);
	
	if (deleteIcon) {
	
		if (deleteIcon.style.display == 'none') {
			deleteIcon.style.display = 'inline-block';
		} else {
			deleteIcon.style.display = 'none';
		}

	}
	
}


/*****************************************************************************************/
function UpdateEndDateTime_onBlur(htmlElement) {
/*****************************************************************************************/
	
	var startDateTime 		= moment(htmlElement.value);
	var defaultEndDateTime 	= startDateTime.add(1, 'hours').format('YYYY-MM-DDTHH:mm');
	
	document.getElementById('add_callEndDateTime').value = defaultEndDateTime;
	document.getElementById('add_callEndDateTime').focus();
	document.getElementById('add_callEndDateTime').select();
		
	
	
}


/*****************************************************************************************/
function CreateProjectFromTemplate_onSave(dialog) {
/*****************************************************************************************/

	var templateSelector 			= document.getElementById('add_projectSourceTemplate');
	var projectTemplateID			= templateSelector.options[templateSelector.selectedIndex].value;
	var newProjectName				= encodeURIComponent(document.getElementById('add_projectNameFromTemplate').value);
	var anchorDateType;
	if (document.getElementById('anchorType-start').checked) {
		anchorDateType 				= 'start';
	} else {
		anchorDateType 				= 'finish';
	}
	var anchorDate 					= document.getElementById('add_anchorDate').value;
	var projectManagerSelector 	= document.getElementById('add_projectManagerFromTemplate');
	var projectManagerID 			= projectManagerSelector.options[projectManagerSelector.selectedIndex].value;
	var customerID						= document.getElementById('projectFromTemplateCustomerID').value;


	var requestUrl 	= "ajax/projectMaintenance.asp?cmd=projectFromTemplate"
																+ "&projectTemplateID=" + projectTemplateID 
																+ "&newProjectName=" + newProjectName
																+ "&anchorDateType=" + anchorDateType
																+ "&anchorDate=" + anchorDate
																+ "&projectManagerID=" + projectManagerID
																+ "&customerID=" + customerID;
	
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_CloneProject;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_CloneProject () {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				// consider automatically navigating to the new template at this point...
				Complete_CloneProject(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

	
}


/*****************************************************************************************/
function TemplateSourceSelect_onChange(htmlElement) {
/*****************************************************************************************/
		
	var selectedTemplate = htmlElement.options[htmlElement.selectedIndex].innerHTML;
	var selectedTemplateID = htmlElement.options[htmlElement.selectedIndex].value;
	
	document.getElementById('add_projectNameFromTemplate').value = selectedTemplate;
	document.getElementById('add_projectNameFromTemplate').parentNode.classList.add('is-dirty');
	document.getElementById('add_projectNameFromTemplate').focus();
	document.getElementById('add_projectNameFromTemplate').select();
	
	CheckTemplateFinishDate();
	
// 	location = location;
	
}


/*****************************************************************************************/
function CheckTemplateFinishDate() {
/*****************************************************************************************/
	
// 	var templateSelector 	= document.getElementById('add_projectSourceTemplate');
	var templateSelector 	= document.getElementById('add_projectProduct');
	var selectedTemplate 	= templateSelector.options[templateSelector.selectedIndex].innerHTML;
	var selectedTemplateID 	= templateSelector.options[templateSelector.selectedIndex].value;
	
	var finishByRadioButton = document.getElementById('anchorType-finish');
	
	if (finishByRadioButton.checked) {
		
		var requestUrl 	= "ajax/projectMaintenance.asp?cmd=queryMinFinishDate"
																	+ "&templateID=" + selectedTemplateID;
		
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_CloneProject;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_CloneProject () {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					// consider automatically navigating to the new template at this point...
					Complete_TemplateSourceSelect(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}
	
	} else {
		
		var minDate = moment().format('YYYY-MM-DD');
		document.getElementById('add_anchorDate').min = minDate;
		document.getElementById('anchorDate_label').innerHTML = 'Start date (min: ' + minDate + ')...';

	}
	
}


/*****************************************************************************************/
function Complete_TemplateSourceSelect(xml) {
/*****************************************************************************************/
	
	var minDate = 	GetInnerText(xml.getElementsByTagName('minFinishDate')[0]);
	
	document.getElementById('add_anchorDate').min = minDate;
	document.getElementById('anchorDate_label').innerHTML = 'Finish date (min: ' + minDate + ')...';
	
}


/*****************************************************************************************/
function AnchorType_onChange(htmlElement) {
/*****************************************************************************************/
	
	var minDate;
	
	if (htmlElement.value == '1') {
// 		minDate = moment().format('YYYY-MM-DD');
		minDate = moment().format('MM/DD/YYYY');
		document.getElementById('add_anchorDate').min = minDate;
		document.getElementById('anchorDate_label').innerHTML = 'Start date (min: ' + moment(minDate).format('MM/DD/YYYY') + ')...';
	} else {
		CheckTemplateFinishDate();
		minDate = document.getElementById('add_anchorDate').min;
		document.getElementById('anchorDate_label').innerHTML = 'Finish date (min: ' + moment(minDate).format('MM/DD/YYYY') + ')...';
	}
	
}


/*****************************************************************************************/
function CreateTemplate_onSave(htmlDialog) {
/*****************************************************************************************/

	let sourceProjectID = $('#clone_sourceProjectID').val();
	let targetTemplateName = $('#clone_projectName').val();

	// Check the server for existing templates before proceeding
	$.ajax({
		url: `${apiServer}/api/projectTemplates`,
		type: 'GET',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }
	}).done((templates) => {

		const exists = templates.some(t => t.name === targetTemplateName);

		if (exists) {
			if (!confirm('A template with this name already exists. It will be overwritten. Continue?')) {
				const notification = document.querySelector('.mdl-js-snackbar');
				notification.MaterialSnackbar.showSnackbar({ message: 'Save cancelled' });
				return;
			}
		}

		// Proceed to POST the new template
		$.ajax({
			url: `${apiServer}/api/projectTemplates`,
			type: 'POST',
			data: { 
				sourceProjectID: sourceProjectID,
				targetTemplateName: targetTemplateName
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }
		}).done(() => {
			console.log('template created');
			const notification = document.querySelector('.mdl-js-snackbar');
			notification.MaterialSnackbar.showSnackbar({ message: 'Template created' });
		}).fail((jqXHR, textStatus, err) => {
			console.error('error while creating template', textStatus, err);
			const notification = document.querySelector('.mdl-js-snackbar');
			notification.MaterialSnackbar.showSnackbar({ message: 'Template creation failed' });
		});

	}).fail((jqXHR, textStatus, err) => {
		console.error('error while checking for existing templates', textStatus, err);
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({ message: 'Unable to check for duplicates' });
	});
}



/*****************************************************************************************/
function Complete_CloneProject(urNode) {
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



/*****************************************************************************************/
function createTemplate_onClick(htmlElement) {
/*****************************************************************************************/
	
	var currTableRow 				= htmlElement.closest( 'TR' );	

	var sourceProjectID 			= currTableRow.id;
	var sourceProjectName 		= currTableRow.querySelector( 'TD.projectName' ).textContent;

	
	document.getElementById('clone_sourceProjectName').value = sourceProjectName;
	document.getElementById('clone_sourceProjectName').parentNode.classList.add('is-dirty');
	
	document.getElementById('clone_projectName').value = sourceProjectName;
	document.getElementById('clone_projectName').parentNode.classList.add('is-dirty');
	document.getElementById('clone_projectName').select();

	var projectNameSelector = document.getElementById('clone_projectNameSelect');
	projectNameSelector.parentNode.classList.add('is-dirty');
	if (projectNameSelector.length <= 5) {
		projectNameSelector.size = projectNameSelector.length;
	} else {
		projectNameSelector.size = 5;
	}
	
	
	document.getElementById('clone_sourceProjectID').value = sourceProjectID;
	
	dialog_cloneProject.showModal();
	
}



/*****************************************************************************************/
function TemplateNameSelect_onChange(htmlElement) {
/*****************************************************************************************/
	
	
	var templateName = document.getElementById('clone_projectName');
	
	templateName.value = htmlElement.options[htmlElement.selectedIndex].innerHTML;
	
	templateName.focus();
	templateName.select();
	
	
}


/*****************************************************************************************/
function EditProject_onClick(htmlElement) {
/*****************************************************************************************/
	
	var edit_projectID = htmlElement.getAttribute('data-val');
	document.getElementById('add_projectID').value = edit_projectID;
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;	
	
	
	var edit_projectName						= currTableRow.children[0].innerHTML;
	var edit_productName 					= currTableRow.children[1].innerHTML;
	var edit_projectManager					= currTableRow.children[2].innerHTML;
	var edit_projectStartDate				= currTableRow.children[3].innerHTML;
	var edit_projectEndDate					= currTableRow.children[4].innerHTML;
	var edit_projectStatus					= currTableRow.children[5].innerHTML;
	var edit_projectCompleted				= currTableRow.children[6].innerHTML;

	// selec the current product...
	var selectProduct = document.getElementById('add_projectProduct');
	for(var i = 0;i < selectProduct.options.length;i++){
		if(selectProduct.options[i].innerHTML == edit_productName){
			selectProduct.options[i].selected = true;
		}
	}	
	document.getElementById('add_projectProduct').parentNode.classList.add('is-dirty');
	
	document.getElementById('add_projectName').value 					= edit_projectName;
	document.getElementById('add_projectName').parentNode.classList.add('is-dirty');
	
	// selec the current project manager...
	var selectPM = document.getElementById('add_projectManager');
	for(var i = 0;i < selectPM.options.length;i++){
		if(selectPM.options[i].innerHTML == edit_projectManager){
			selectPM.options[i].selected = true;
		}
	}	
	document.getElementById('add_projectManager').parentNode.classList.add('is-dirty');
	
	document.getElementById('add_projectStartDate').value 					= formatDate(edit_projectStartDate);
	
	document.getElementById('add_projectStartDate').parentNode.classList.add('is-dirty');
	
	document.getElementById('add_projectEndDate').value 					= formatDate(edit_projectEndDate);
	document.getElementById('add_projectEndDate').parentNode.classList.add('is-dirty');
	
// 	var select = document.getElementById('add_projectStatus');
// 	for(var i = 0;i < select.options.length;i++){
// 		if(select.options[i].innerHTML == edit_projectStatus){
// 			select.options[i].selected = true;
// 		}
// 	}	
// 	document.getElementById('add_projectStatus').parentElement.classList.add('is-dirty');
// 
// 
// 	if (edit_projectCompleted) {
// 		document.getElementById('add_projectStatus').parentNode.MaterialSwitch.on();
// 	} else {
// 		document.getElementById('add_projectStatus').parentNode.MaterialSwitch.off();
// 	}
// 	document.getElementById('add_projectStatus').parentElement.classList.add('is-dirty');


	dialog_addProject.showModal();
	
	event.stopPropagation();	
	
// 	return false;
	
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
function drawChart2() {
/*****************************************************************************************/

	// need to figure out how to parameterize the value needed for c.id...
	var sql = "select cim.id, m.name, cim.metricDate, cim.metricValue "
				+"from customerInternalMetrics cim "
				+"left join metric m on (m.id = cim.metricID) " 
				+"join customer_view c on (c.rssdid = cim.rssdid) "
				+"where c.id = 8 " 
				+"order by metricDate desc ";
	console.log(sql);
	
	var requestUrl 	= "ajax/jsonDataTable.asp?sql=" + sql;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_drawChart2;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_drawChart2() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_drawChart2(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
}


/*****************************************************************************************/
function Complete_drawChart2(json) {
/*****************************************************************************************/

	var data = new google.visualization.DataTable(json);

	var options = {
		height: '100%',
		page: 'enable',
		pageSize: 20,
		width: '100%',
	};

	var chart = new google.visualization.Table(document.getElementById('valuesTable'));
	chart.draw(data, options);

}



/*****************************************************************************************/
function ProductName_onChange(htmlNode) {
/*****************************************************************************************/
	
	if (editMode == 'add') {

		var productName = htmlNode.options[htmlNode.selectedIndex].innerText;
		var productField = document.getElementById('add_projectName');
		
		productField.value = productName;
		var parentProductField = productField.parentElement;
		parentProductField.classList.add('is-dirty');

	}
	
}



/*****************************************************************************************/
function CallDelete_onClick(htmlNode) {
/*****************************************************************************************/
	
	if (!confirm('Are you sure you want to delete this call and its notes?')) {
		return false;
	}

	var callID = htmlNode.getAttribute('data-val');
	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=deleteCall&id=" + callID;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_deleteCall;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_deleteCall() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_deleteCall(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}

		}
	
	}
	
}


/*****************************************************************************************/
function Complete_deleteCall(urNode) {
/*****************************************************************************************/

	var id = GetInnerText(urNode.getElementsByTagName('id')[0]);
	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	//delete row from table here.....	
	var deletedItemImg = document.getElementById('callDelete-'+id);
	var deletedTD = deletedItemImg.parentNode;
	var deletedTR = deletedTD.parentNode;
	var deletedRow = deletedTR.rowIndex;
	
	document.getElementById('tbl_clientCalls').deleteRow(deletedRow);
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	location = location;

}



/*****************************************************************************************/
function ClientManagerDelete_onClick(htmlNode) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this client manager?')) {

		var clientManagerID = htmlNode.getAttribute("data-val");
		
		var requestUrl 	= "ajax/customerMaintenance.asp?cmd=deleteClientManager&id=" + clientManagerID;
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_deleteClientManager;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_deleteClientManager() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					Complete_deleteClientManager(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	}
	
}


/*****************************************************************************************/
function Complete_deleteClientManager(urNode) {
/*****************************************************************************************/

	var id = GetInnerText(urNode.getElementsByTagName('id')[0]);
	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	//delete row from table here.....	
	var deletedItemImg = document.getElementById('managerDelete-'+id);
	var deletedTD = deletedItemImg.parentNode;
	var deletedTR = deletedTD.parentNode;
	var deletedRow = deletedTR.rowIndex;
	
	document.getElementById('tbl_clientManagers').deleteRow(deletedRow);
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	location = location;

}




/*****************************************************************************************/
function ProjectDelete_onClick(htmlNode) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this project?')) {

		var projectID = htmlNode.getAttribute("data-val");
		
		var requestUrl 	= "ajax/projectMaintenance.asp?cmd=delete&id=" + projectID;
		
		console.log(requestUrl);
		
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_deleteProject;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_deleteProject() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					location = location;
// 					Complete_deleteProject(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	}

	event.stopPropagation();	
	
}


/*****************************************************************************************/
function Complete_deleteProject(urNode) {
/*****************************************************************************************/

	var id = GetInnerText(urNode.getElementsByTagName('id')[0]);
	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	//delete row from table here.....	
	var deletedItemImg 	= document.getElementById('projectDelete-'+id);
	var deletedTD 			= deletedItemImg.parentNode;
	var deletedTR 			= deletedTD.parentNode;
	var deletedRow 		= deletedTR.rowIndex;
	
	document.getElementById('tbl_clientProjects').deleteRow(deletedRow);
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	location = location;

}




/*****************************************************************************************/
function Complete_addProject(urNode) {
/*****************************************************************************************/

	var id				= GetInnerText (urNode.getElementsByTagName('id')[0]);
	var name				= GetInnerText (urNode.getElementsByTagName('name')[0]);
	var customerID		= GetInnerText (urNode.getElementsByTagName('customer')[0]);
	var productID		= GetInnerText (urNode.getElementsByTagName('product')[0]);
	var productName	= GetInnerText (urNode.getElementsByTagName('productName')[0]);
	var startDate		= GetInnerText (urNode.getElementsByTagName('startDate')[0]);
	var endDate			= GetInnerText (urNode.getElementsByTagName('endDate')[0]);
	var msg 				= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	var tableRef = document.getElementById('tbl_clientProjects').getElementsByTagName('tbody')[0];
	var newRow = tableRef.insertRow(tableRef.rows.length);

	// column for name...
	var newCell = newRow.insertCell(0);
	var newText = document.createTextNode(name);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for product...
	var newCell = newRow.insertCell(1);
	var newText = document.createTextNode(productName);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for startDate...
	var newCell = newRow.insertCell(2);
	var newText = document.createTextNode(startDate);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for endDatae...
	var newCell = newRow.insertCell(3);
	var newText = document.createTextNode(endDate);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for status...
	// NOTE: because the project was just added there is no way it can have a status, so no value
	//       is returned in the XML. Likewise, and empty cell is added to the HTML table here.
	var newCell = newRow.insertCell(4);
	var newText = document.createTextNode('');
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for complete...
	// NOTE: because the project was just added there is no way it can be "complete" so no value
	//       is returned in the XML. Likewise, and empty cell is added to the HTML table here.
	var newCell = newRow.insertCell(5);
	var newText = document.createTextNode('');
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for actions
	var newCell = newRow.insertCell(6);
	
	var editImg = document.createElement("img");
	editImg.src = "/images/ic_edit_black_24dp_1x.png";
	var editLink = document.createElement("a");
	editLink.setAttribute('href', 'projectEdit.asp?id='+id);
	editLink.appendChild(editImg);
	newCell.appendChild(editLink);
	
	var viewImg = document.createElement("img");
	viewImg.src = "/images/ic_arrow_forward_black_24dp_1x.png";
	var viewLink = document.createElement("a");
	viewLink.setAttribute('href', 'taskList.asp?customerID='+customerID+'projectID='+id);
	viewLink.appendChild(viewImg);
	newCell.appendChild(viewLink);
	
	var deleteImg = document.createElement("img");
	deleteImg.name = "deleted";
	deleteImg.id = "projectDelete-"+id;
	deleteImg.setAttribute("data-val", id);
	deleteImg.src = "/images/ic_delete_black_24dp_1x.png";
	deleteImg.style = "cursor: pointer";
	deleteImg.setAttribute("onclick", "ProjectDelete_onClick(this)");
	newCell.appendChild(deleteImg);

	newCell.className = "mdl-data-table__cell--non-numeric";




	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	location = location;

}


/*****************************************************************************************/
function AddClientManager_onSave(dialog) {
/*****************************************************************************************/

	var userID			= encodeURIComponent(document.getElementById('add_clientManagerUserID').value);
	var typeID			= encodeURIComponent(document.getElementById('add_clientManagerType').value);
	var startDate		= encodeURIComponent(document.getElementById('add_clientManagerStartDate').value);
	var endDate			= encodeURIComponent(document.getElementById('add_clientManagerEndDate').value);
	var customerID		= encodeURIComponent(document.getElementById('add_clientManagerCustomerID').value);
	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=addClientManager"
																			+ "&userID=" + userID 
																			+ "&type=" + typeID 
																			+ "&start=" + startDate 
																			+ "&end=" + endDate 
																			+ "&customer=" + customerID;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addClientManager;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addClientManager() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_addClientManager(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_addClientManager(urNode) {
/*****************************************************************************************/

	var id 				= GetInnerText(urNode.getElementsByTagName('id')[0]);
	var userID 			= GetInnerText(urNode.getElementsByTagName('userID')[0]);
	var userName 		= GetInnerText(urNode.getElementsByTagName('userName')[0]);
	var typeID 			= GetInnerText(urNode.getElementsByTagName('typeID')[0]);
	var typeName 		= GetInnerText(urNode.getElementsByTagName('typeName')[0]);
	var startDate 		= GetInnerText(urNode.getElementsByTagName('startDate')[0]);
	var endDate 		= GetInnerText(urNode.getElementsByTagName('endDate')[0]);
	var customerID 	= GetInnerText(urNode.getElementsByTagName('customerID')[0]);
	var msg 				= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	
	//add a row to the table here. Don't forget to upgrade all the elements?!!
	//
	//		componentHandler.upgradeDom()
	//
	//		- or - 
	//	
	//		componentHandler.upgradeElement()
	//
	
	var tableRef = document.getElementById('tbl_clientManagers').getElementsByTagName('tbody')[0];
	var newRow = tableRef.insertRow(tableRef.rows.length);
	
		
	// column for name...
	var newCell = newRow.insertCell(0);
	var newText = document.createTextNode(userName);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for type...
	var newCell = newRow.insertCell(1);
	var newText = document.createTextNode(typeName);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for start date
	var newCell = newRow.insertCell(2);
	var newText = document.createTextNode(startDate);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	//column for end date
	var newCell = newRow.insertCell(3);
	var newText = document.createTextNode(endDate);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for primary radio buton
	var newCell = newRow.insertCell(4);
	var primaryButton = document.createElement("input");
	primaryButton.setAttribute("name", "primary");
	primaryButton.setAttribute("id", "primary-"+id);
	primaryButton.setAttribute("data-val", id);
	primaryButton.setAttribute("type", "radio");
	primaryButton.setAttribute("onclick", "ClientManagerUpdatePrimary_onClick(this,"+customerID+")");
	primaryButton.className = "mdl-radio__button";
	newCell.appendChild(primaryButton);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for actions
	var newCell = newRow.insertCell(5);
	
	var actionButton = document.createElement("img");
	actionButton.name = "deleted";
	actionButton.id = "managerDelete-" + id;
	actionButton.setAttribute("data-val", id);
	actionButton.src = "/images/ic_delete_black_24dp_1x.png";
	actionButton.style = "cursor: pointer";
	actionButton.setAttribute("onclick","ClientManagerDelete_onClick(this)");
	newCell.appendChild(actionButton);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
// 	componentHandler.upgradeAllRegistered();
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}


/*******************************************************************************/
function drawMetricsVisualizations(customerID) {
/*******************************************************************************/

	var requestUrl;
	requestUrl = "../ajax/customerMetrics.asp?id=" + encodeURIComponent(customerID);
	CreateRequest();

	if(request) {
		request.onreadystatechange = StateChangeHandlerState;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
}


/*******************************************************************************/
function StateChangeHandlerState() {
/*******************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			populateMetrics(request.responseXML);
		} else {
			alert("problem retrieving fdic.dbo.institutions data from the server, status code: "  + request.status);
		}
	}
}


/*******************************************************************************/
function populateMetrics(metricsNode) {
/*******************************************************************************/

	// populate chart...
	var chartNode = metricsNode.getElementsByTagName('crossSales');
	jsArray = JSON.parse(chartNode[0].innerHTML);


	var data = google.visualization.arrayToDataTable(jsArray);
	
	var options = {
		animation: {duration: 1000, startup: true, easing: 'out'},
		title : 'Cross Sales By Date',
		seriesType: 'bars',
		series: 
			{
			0: {targetAxisIndex: 0, type: 'bar', color: 'black'},
			},
// 		hAxis: {slantedText: true},
		hAxis: {textPosition: 'none'},
		vAxis:
			{
			0: {format: 'number'},
			}
	};

	var chart = new google.visualization.ComboChart(document.getElementById('metric1'));
	chart.draw(data, options);

}
	


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}



