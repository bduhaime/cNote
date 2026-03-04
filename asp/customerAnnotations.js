//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

/*****************************************************************************************/
function UbprSection_onChange(htmlElement) {
/*****************************************************************************************/
	

	var ubprSection = 	encodeURIComponent(htmlElement.options[htmlElement.selectedIndex].value);
	
	var requestUrl 	= "ajax/customerMetrics.asp?cmd=getAttributes&ubprSection=" + ubprSection;
	console.log(requestUrl);
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_getAttributes;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_getAttributes() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_getAttributes(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_getAttributes	(json) {
/*****************************************************************************************/

	var searchResults = JSON.parse(json);
	var metricSelectList = document.getElementById('add_annotationMetricID');
	var currentSelectLength = metricSelectList.options.length;
	
	metricSelectList.options.length = 0;	
	
   metricSelectList.innerHTML = metricSelectList.innerHTML + '<option>Make a selection...</option>';
	for (var i = 0; i < searchResults.length; i++) {
		if (searchResults[i][2] == "") {
			metricName = searchResults[i][1];
		} else {
			metricName = searchResults[i][1] + '  ( Line ' + searchResults[i][2] + ' )';
		}
      metricSelectList.innerHTML = metricSelectList.innerHTML + '<option value="' + searchResults[i][0] + '">' + metricName + '</option>';
	}
	
	
	metricSelectList.parentElement.classList.add('is-dirty');
}



/*****************************************************************************************/
function AttributeType_onChange(htmlElement) {
/*****************************************************************************************/
	
	var strAttrType = htmlElement.options[htmlElement.selectedIndex].value;	
	var attributeDateLabel = document.getElementById('attributeDateLabel');
	var addMetricValueContainer = document.getElementById('addMetricValueContainer');
	
	if (strAttrType == 1) {
// 	"Metric Note" Selected.... */
// 	change label for attributeDate to "Annotation date..."
// 	hide attributeValue field

		attributeDateLabel.innerHTML = "Annotation date...:";
		addMetricValueContainer.style.display = 'none';
		
	} else {
// 	something other than "Metric Note" selected.... */
// 	change label for attrivbuteDate to "Start date..."
// 	unhide attributeValue field */
		
		attributeDateLabel.innerHTML = "Start date...:";
		addMetricValueContainer.style.display = 'block';

	}
	
}


/*****************************************************************************************/
function AddAnnotation_onSave(elemDialog) {
/*****************************************************************************************/
	
	var attributeTypeID		= document.getElementById("add_attributeTypeID").value;
	
	var elemMetricID			= document.getElementById("add_annotationMetricID");
	var annotationMetricID	= elemMetricID.options[elemMetricID.selectedIndex].value;
	
	var attributeDate			= document.getElementById("add_annotationDate").value;
	var annotationNarrative = document.getElementById("add_annotationNarrative").value;
	var metricValue			= document.getElementById("add_metricValue").value;
	var attainByDate			= document.getElementById('add_attainByDate').value;
	var customerID				= document.getElementById("add_annotationCustomerID").value;
	
	var requestUrl 	= "ajax/customerMaintenance.asp?cmd=addAnnotation" 
											+ "&attributeTypeID=" + attributeTypeID
											+ "&annotationMetricID=" + annotationMetricID 
											+ "&attributeDate=" + attributeDate 
											+ "&annotationNarrative=" + encodeURIComponent(annotationNarrative)
											+ "&metricValue=" + metricValue 
											+ "&attainByDate=" + attainByDate 
											+ "&customerID=" + customerID;
	console.log(requestUrl);
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addAnnotation;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_addAnnotation() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_addAnnotation(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}


/*****************************************************************************************/
function Complete_addAnnotation(urNode) {
/*****************************************************************************************/

	var id 						= GetInnerText(urNode.getElementsByTagName('id')[0]);
	var attributeTypeID		= GetInnerText(urNode.getElementsByTagName('attributeTypeID')[0]);
	var attributeTypeName	= GetInnerText(urNode.getElementsByTagName('attributeTypeName')[0]);
	var attributeDate 		= GetInnerText(urNode.getElementsByTagName('attributeDate')[0]);
	var metricValue 			= GetInnerText(urNode.getElementsByTagName('metricValue')[0]);
	var customerID 			= GetInnerText(urNode.getElementsByTagName('customerID')[0]);
	var annotationNarrative	= GetInnerText(urNode.getElementsByTagName('annotationNarrative')[0]);
	var annotationMetricID	= GetInnerText(urNode.getElementsByTagName('annotationMetricID')[0]);
	var metricName				= GetInnerText(urNode.getElementsByTagName('metricName')[0]);
	var addedBy		 			= GetInnerText(urNode.getElementsByTagName('addedBy')[0]);
	var msg			 			= GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	
	var tableRef = document.getElementById('tbl_customerAnnotations').getElementsByTagName('tbody')[0];
	var newRow = tableRef.insertRow(tableRef.rows.length);

	// column for attribute type...
	var newCell = newRow.insertCell(0);
	var newText = document.createTextNode(attributeTypeName);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for date...
	var newCell = newRow.insertCell(1);
	var newText = document.createTextNode(attributeDate);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for narrative...
	var newCell = newRow.insertCell(2);
	var newText = document.createTextNode(annotationNarrative);
	if (newText.textContent != "undefined") {
		newCell.appendChild(newText);
	}
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for addedBy...
	var newCell = newRow.insertCell(3);
	var newText = document.createTextNode(addedBy);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for metric 
	var newCell = newRow.insertCell(4);
	var newText = document.createTextNode(metricName);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for goal value 
	var newCell = newRow.insertCell(5);
	var newText = document.createTextNode(metricValue);
	newCell.appendChild(newText);
	newCell.className = "mdl-data-table__cell--non-numeric";
	
	// column for actions
	var newCell = newRow.insertCell(6);
	
	var editImg = document.createElement("img");
	editImg.src = "/images/ic_edit_black_24dp_1x.png";
	var editLink = document.createElement("a");
	editLink.setAttribute('href', 'metricEdit.asp?id='+id);
	editLink.appendChild(editImg);
	newCell.appendChild(editLink);
	
	var deleteImg = document.createElement("img");
	deleteImg.id = "annotationDelete-"+id;
	deleteImg.setAttribute("data-val", id);
	deleteImg.src = "/images/ic_delete_black_24dp_1x.png";
	deleteImg.style = "cursor: pointer";
// deleteImg.onclick = "AnnotationDelete_onClick(this," + id + ")";
	deleteImg.setAttribute("onclick", "AnnotationDelete_onClick(this)");
	newCell.appendChild(deleteImg);
	newCell.className = "mdl-data-table__cell--non-numeric";

	// reset the input fields on the form/dialog...
	document.getElementById("add_attributeTypeID").selectedIndex = 1;
	document.getElementById("add_attributeTypeID").classList.remove("is-dirty");

	document.getElementById("add_annotationMetricID").options.length = 0;
	document.getElementById("add_annotationMetricID").classList.remove("is-dirty");

	document.getElementById("add_annotationDate").value = "";
	document.getElementById("add_annotationDate").classList.remove("is-dirty");

	document.getElementById("add_annotationNarrative").value = "";
	document.getElementById("add_annotationNarrative").classList.remove("is-dirty");

	document.getElementById("add_metricValue").value = "";
	document.getElementById("add_metricValue").classList.remove("is-dirty");



	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
}


/*****************************************************************************************/
function AnnotationDelete_onClick(htmlNode) {
/*****************************************************************************************/

	if (confirm('Are you sure you want to delete this project?')) {

		var annotationID = htmlNode.getAttribute("data-val");
	
		var requestUrl 	= "ajax/customerMaintenance.asp?cmd=deleteAnnotation&id=" + annotationID;
		CreateRequest();
	 
		if(request) {
			request.onreadystatechange = StateChangeHandler_deleteAnnotation;
			request.open("GET", requestUrl,  true);
			request.send(null);		
		}
	
		function StateChangeHandler_deleteAnnotation() {
		
			if(request.readyState == 4) {
				if(request.status == 200) {
					Complete_deleteAnnoation(request.responseXML);
				} else {
					alert("problem retrieving data from the server, status code: "  + request.status);
				}
			}
		
		}

	}
	
}


/*****************************************************************************************/
function Complete_deleteAnnoation(urNode) {
/*****************************************************************************************/

	var id = GetInnerText(urNode.getElementsByTagName('id')[0]);
	var msg = GetInnerText(urNode.getElementsByTagName('msg')[0]);
	
	//delete row from table here.....	
	var deletedItemImg = document.getElementById('annotationDelete-'+id);
	var deletedTD = deletedItemImg.parentNode;
	var deletedTR = deletedTD.parentNode;
	var deletedRow = deletedTR.rowIndex;
	
	document.getElementById('tbl_customerAnnotations').deleteRow(deletedRow);
	
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
// 	location = location;

}




