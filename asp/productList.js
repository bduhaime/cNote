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
function EditProduct_onClick(htmlElement) {
/*****************************************************************************************/
	
	var productID = htmlElement.getAttribute('data-val');
	
	var currTableColumn = htmlElement.parentNode;
	var currTableRow = currTableColumn.parentNode;
	
	var productName		 			= currTableRow.children[0].innerHTML;
	var productDescription 			= currTableRow.children[1].innerHTML;
	var productType				 	= currTableRow.children[2].innerHTML;
	var productVendor 				= currTableRow.children[3].innerHTML;
	var productFocus	 				= currTableRow.children[4].innerHTML;
	var productCoreAnnualQty		= currTableRow.children[5].innerHTML;
	var productAdvAnnualQty			= currTableRow.children[6].innerHTML;
	var productEliteAnnualQty		= currTableRow.children[7].innerHTML;
	
	var productAvailableAloneInd	= document.getElementById(productID + '-availableAloneInd').checked;
	
	
	document.getElementById('productID').value = productID;

	document.getElementById('productName').value = productName;
	document.getElementById('productName').parentElement.classList.add('is-dirty');

	document.getElementById('productDescription').value = productDescription;
	document.getElementById('productDescription').parentElement.classList.add('is-dirty');
	
	document.getElementById('productType').value = productType;
	document.getElementById('productType').parentElement.classList.add('is-dirty');
	
	document.getElementById('productVendor').value = productVendor;
	document.getElementById('productVendor').parentElement.classList.add('is-dirty');
	
	document.getElementById('productFocus').value = productFocus;
	document.getElementById('productFocus').parentElement.classList.add('is-dirty');

	document.getElementById('productCoreAnnualQty').value = productCoreAnnualQty;
	document.getElementById('productCoreAnnualQty').parentElement.classList.add('is-dirty');

	document.getElementById('productAdvAnnualQty').value = productAdvAnnualQty;
	document.getElementById('productAdvAnnualQty').parentElement.classList.add('is-dirty');

	document.getElementById('productEliteAnnualQty').value = productEliteAnnualQty;
	document.getElementById('productEliteAnnualQty').parentElement.classList.add('is-dirty');

	document.getElementById('productAvailableAloneInd').checked = productAvailableAloneInd;
	
	if (productAvailableAloneInd) {
		document.getElementById('productAvailableAloneInd').parentElement.classList.add('is-checked');
	} else {
		document.getElementById('productAvailableAloneInd').parentElement.classList.remove('is-checked');		
	}
// 	document.getElementById('productAvailableAloneInd').parentElement.classList.add('is-dirty');

	dialog_product.showModal();
	
// 	return false;
	
}


/*****************************************************************************************/
function AddProduct_onSave(dialog) {
/*****************************************************************************************/

	var productID 						= document.getElementById('productID').value;
	var productName 					= document.getElementById('productName').value;
	var productDescription 			= document.getElementById('productDescription').value;
	var productType 					= document.getElementById('productType').value;
	var productVendor 				= document.getElementById('productVendor').value;
	var productFocus					= document.getElementById('productFocus').value;
	var productCoreAnnualQty		= document.getElementById('productCoreAnnualQty').value;
	var productAdvAnnualQty			= document.getElementById('productAdvAnnualQty').value;
	var productEliteAnnualQty		= document.getElementById('productEliteAnnualQty').value;

	var productAvailableAloneInd;
	if (document.getElementById('productAvailableAloneInd').checked) {
		productAvailableAloneInd = 1;
	} else {
		productAvailableAloneInd = 0;
	}
	
	
	var requestUrl 	= "ajax/products.asp?cmd=update"
											+ "&id=" + productID
											+ "&name=" + encodeURIComponent(productName)
											+ "&description=" + encodeURIComponent(productDescription)
											+ "&productType=" + encodeURIComponent(productType)
											+ "&vendor=" + encodeURIComponent(productVendor)
											+ "&focus=" + encodeURIComponent(productFocus)
											+ "&coreAnnualQty=" + encodeURIComponent(productCoreAnnualQty)
											+ "&advAnnualQty=" + encodeURIComponent(productAdvAnnualQty)
											+ "&eliteAnnualQty=" + encodeURIComponent(productEliteAnnualQty)
											+ "&availableAloneInd=" + encodeURIComponent(productAvailableAloneInd);
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_addCCT;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_addCCT() {
	
		if(request.readyState == 4) {
			if(request.status == 200 || request.status == 0) {
				Notify_addCCT(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
// 	location = location;
	
}


/*****************************************************************************************/
function cctDelete_onClick(htmlElement) {
/*****************************************************************************************/

	var cctID = htmlElement.getAttribute('data-val');
	
	var requestUrl 	= "ajax/customerCalls.asp?cmd=delCustomerCallType"
											+ "&id=" + cctID;
											
	console.log(requestUrl);
	
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_deleteCCT;
		request.open("GET", requestUrl, true);
		request.send(null);		
	}

	function StateChangeHandler_deleteCCT() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Notify_deleteCCT(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
	location = location;
	
}


/*****************************************************************************************/
function Notify_addCCT(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);
	
	dialog_addCCT.close();

	location = location;


}



/*****************************************************************************************/
function Notify_deleteCCT(xml) {
/*****************************************************************************************/

	var msg = GetInnerText(xml.getElementsByTagName('msg')[0]);
	
	var notification = document.querySelector('.mdl-js-snackbar');
	notification.MaterialSnackbar.showSnackbar(
		{
		message: msg
		}
	);

}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}



