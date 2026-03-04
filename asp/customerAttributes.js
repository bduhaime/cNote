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
function ToggleActionIcons(htmlElement) {
/*****************************************************************************************/
	
	
	var deleteIcons 	= htmlElement.getElementsByClassName('attrDeleteButton');
	var editIcons 		= htmlElement.getElementsByClassName('attrEditButton');
	
	if (deleteIcons[0].style.display == 'none') {
		deleteIcons[0].style.display = 'inline-block';
	} else {
		deleteIcons[0].style.display = 'none';
	}
	
	if (editIcons[0].style.display == 'none') {
		editIcons[0].style.display = 'inline-block';
	} else {
		editIcons[0].style.display = 'none';
	}
	
}


/*******************************************************************************/
function CustomerAnnotationEdit_onClick(htmlElement) {
/*******************************************************************************/
	
	var annotationID = htmlElement.getAttribute('data-val');
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;
	
	var attributeDate		 			= currTableRow.children[2].children[1].innerText;
	var attainByDate		 			= currTableRow.children[2].children[4].innerText;

	var active							= currTableRow.children[6].childNodes[1].childNodes[1].checked;	
	
	var attributeCustomName;
	var attributeNarrative;

	if (currTableRow.children[3].children[0].classList.contains('customName')) {
		attributeCustomName			= currTableRow.children[3].children[0].innerText;
		document.getElementById('edit_annotationName').parentNode.style.display = 'none';
		if (currTableRow.children[3].children[2].classList.contains('narrative')) {
			attributeNarrative	 	= currTableRow.children[3].children[2].innerText;
			document.getElementById('edit_annotationName').parentNode.style.display = 'inline-block';
		} else {
			attributeNarrative	 	= '';
		}
	} else if (currTableRow.children[3].children[0].classList.contains('narrative')) {
		attributeCustomName			= '';
		document.getElementById('edit_annotationName').parentNode.style.display = 'none';
		attributeNarrative			= currTableRow.children[3].children[0].innerText;
	} else {
		attributeCustomName			= '';
		document.getElementById('edit_annotationName').parentNode.style.display = 'none';
		attributeNarrative			= '';
	}
	
	
	var metricName		 				= currTableRow.children[4].innerText;
	var metricGoal		 				= currTableRow.children[5].innerText;


	dialog_editAttribute.showModal();

	
	document.getElementById('edit_annotationID').value				= annotationID;
	
	document.getElementById('edit_annotationName').value 			= attributeCustomName;
	document.getElementById('edit_annotationName').parentNode.classList.add('is-dirty');
	
	document.getElementById('edit_annotationNarrative').value 	= attributeNarrative;
	document.getElementById('edit_annotationNarrative').parentNode.classList.add('is-dirty');

	document.getElementById('edit_metricValue').value				= metricGoal;
	document.getElementById('edit_metricValue').parentNode.classList.add('is-dirty');

	document.getElementById('edit_annotationDate').value			= moment(attributeDate).format('YYYY-MM-DD');
	document.getElementById('edit_annotationDate').parentNode.classList.add('is-dirty');

	document.getElementById('edit_attainByDate').value				= moment(attainByDate).format('YYYY-MM-DD');
	document.getElementById('edit_attainByDate').parentNode.classList.add('is-dirty');

	if (active) {
		document.getElementById('edit_active').parentNode.MaterialCheckbox.check();
	} else {
		document.getElementById('edit_active').parentNode.MaterialCheckbox.uncheck();
	}


// 	dialog_editAttribute.showModal();

}


/*****************************************************************************************/
function DeleteAnnotation_OnClick(htmlElement) {
/*****************************************************************************************/
	
	if (!confirm('Are you sure you want to delete this attribute?')) {
		return false;
	}
	
	id = htmlElement.getAttribute('data-val');
	
	var requestUrl 	= "ajax/customerMetrics.asp?cmd=deleteCustomerAnnotation&id=" + id;

	console.log(requestUrl);
					
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_deleteAnnotation;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}


	function StateChangeHandler_deleteAnnotation() {
	
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
function EditAnnotation_onSave(htmlDialog) {
/*****************************************************************************************/
	
	var annotationID		= document.getElementById('edit_annotationID').value;
	var attrName 			= document.getElementById('edit_annotationName').value;
	var narrative 			= document.getElementById('edit_annotationNarrative').value;
	var attributeValue	= document.getElementById('edit_metricValue').value;
	var attributeDate		= document.getElementById('edit_annotationDate').value;
	var attainByDate		= document.getElementById('edit_attainByDate').value;
	var edit_active		= document.getElementById('edit_active').checked;
	
	var active;
	if (edit_active) {
		active = '1';
	} else {
		active = '0';
	}
	
	var payload = "annotationID="			+ annotationID
					+ "&attrName="				+ encodeURIComponent(attrName)
					+ "&narrative=" 			+ encodeURIComponent(narrative)
					+ "&attributeDate=" 		+ encodeURIComponent(attributeDate)
					+ "&attributeValue=" 	+ attributeValue 
					+ "&attainByDate=" 		+ encodeURIComponent(attainByDate)
					+ "&active="				+ active;
		
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_AddMetric;
		request.open("POST", "ajax/customerMetrics.asp?cmd=updateMetric", true);
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
	
	var attrTypeSelector = document.getElementById('add_attributeTypeID');
	var attributeTypeID 	= attrTypeSelector.options[attrTypeSelector.selectedIndex].value;
	
	var attrSource;
	if (document.getElementById('attrSourceInternalStandard').checked == true) {
		attrSource = 1;
	} else if (document.getElementById('attrSourceInternalCustom').checked == true) {
		attrSource = 2;
	} else {
		attrSource = 3;
	}
	
	
// var attrCategory;
// var attrUBPRSection;
	var metricSelector 	= document.getElementById('add_annotationMetricID');
	var metricID;
	
	if (metricSelector.selectedIndex == 0) {
		metricID = '';
	} else {
		metricID = metricSelector.options[metricSelector.selectedIndex].value;
	}

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
												+ "&attributeSource="	+ attrSource;
	
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
	var sectionList 		= document.getElementById('add_ubprSection');
	
	var selectedCategory = categoryList.options[categoryList.selectedIndex].value;
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

	
	var selectedSource = htmlElement.id
	
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
	
   categorySelectList.innerHTML 	= categorySelectList.innerHTML + '<option>Make a selection...</option>';
	for (var i = 0; i < searchResults.length; i++) {
		categoryName 						= GetInnerText(searchResults[i]);
      categorySelectList.innerHTML 	= categorySelectList.innerHTML + '<option value="' + categoryName + '">' + categoryName + '</option>';
	}
	
	categorySelectList.parentElement.classList.add('is-dirty');


	searchResults 				= xml.getElementsByTagName('section');
	var sectionSelectList 	= document.getElementById('add_ubprSection');
	var sectionName;
	
	sectionSelectList.options.length = 0;
	
   sectionSelectList.innerHTML 	= sectionSelectList.innerHTML + '<option>Make a selection...</option>';
	for (var i = 0; i < searchResults.length; i++) {
		sectionName 						= GetInnerText(searchResults[i]);
      sectionSelectList.innerHTML 	= sectionSelectList.innerHTML + '<option value="' + sectionName + '">' + sectionName + '</option>';
	}
	
	sectionSelectList.parentElement.classList.add('is-dirty');

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
	
   metricSelectList.innerHTML = metricSelectList.innerHTML + '<option>Make a selection...</option>';
	for (var i = 0; i < searchResults.length; i++) {
		metricID 						= searchResults[i].id;
		metricName 						= GetInnerText(searchResults[i]);
      metricSelectList.innerHTML = metricSelectList.innerHTML + '<option value="' + metricID + '">' + metricName + '</option>';
	}
	
	
	metricSelectList.parentElement.classList.add('is-dirty');
	
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



