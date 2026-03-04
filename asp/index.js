//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

var request = null;


/*******************************************************************************/
function createRequest() {
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


/*******************************************************************************/
function instState_OnChange(id) {
/*******************************************************************************/

	document.getElementById("instHeader").style.display = "none"

	var selectedState = id.options[id.selectedIndex].value;
	var requestUrl;
	requestUrl = "../ajax/institutions.asp?state=" + encodeURIComponent(selectedState);
	createRequest();

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
			populateInstitutionList(request.responseXML);
		} else {
			alert("problem retrieving fdic.dbo.institutions data from the server, status code: "  + request.status);
		}
	}
}


/*******************************************************************************/
function populateInstitutionList(columnNode) {
/*******************************************************************************/

	var institutionList = document.getElementById("institutionList");

	// delete all items from institutionList, even if none exist yet...
	for (var count = institutionList.options.length-1; count >-1; count--) {
		institutionList.options[count] = null;
	}

	// re-populate with fresh list...
	var institutionNodes = columnNode.getElementsByTagName('institution');

	var idValue;
	var textValue; 
	var optionItem;
	
	optionItem = new Option( 'Make a selection...', 0, false, false);
	institutionList.options[0] = optionItem;

	for (var count = 0; count < institutionNodes.length; count++) {
		idValue		= institutionNodes[count].getAttribute("rssdid");
		textValue 	= institutionNodes[count].textContent;
		optionItem 	= new Option( textValue, idValue,  false, false);
		institutionList.options[institutionList.length] = optionItem;
	}
}




/*******************************************************************************/
function instList_onChange(id) {
/*******************************************************************************/

	var selectedInst = id.options[id.selectedIndex].value;
	var requestUrl;

	requestUrl = "../ajax/instDetail.asp?rssdid=" + encodeURIComponent(selectedInst);
	createRequest();

	if(request) {
		request.onreadystatechange = InstChangeHandlerState;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}
	
}


/*******************************************************************************/
function InstChangeHandlerState() {
/*******************************************************************************/

	if(request.readyState == 4) {
		if(request.status == 200) {
			populateInstDetails(request.responseXML);
		} else {
			alert("problem retrieving institution detail data from the server, status code: "  + request.status);
		}
	}
}


/*******************************************************************************/
function populateInstDetails(columnNode) {
/*******************************************************************************/


	// populate header information 
	var headerNode = columnNode.getElementsByTagName('header');
	
	document.getElementById("instCity").innerHTML 		= headerNode[0].getAttribute("city");
	document.getElementById("instAsset").innerHTML 		= headerNode[0].getAttribute("assets");
	
	if(headerNode[0].getAttribute("cb") == "1") {
		document.getElementById("instCB").innerHTML = '<img src="../images/ic_check_box_black_24dp_1x.png">';
	} else {
		document.getElementById("instCB").innerHTML = '<img src="../images/ic_check_box_outline_blank_black_24dp_1x.png">';
	}
	
	if(headerNode[0].getAttribute("mutual") == "1") {
		document.getElementById("instMutual").innerHTML = '<img src="../images/ic_check_box_black_24dp_1x.png">';
	} else {
		document.getElementById("instMutual").innerHTML = '<img src="../images/ic_check_box_outline_blank_black_24dp_1x.png">';
	}
	
	document.getElementById("instOffdom").innerHTML 	= headerNode[0].getAttribute("offices");
	document.getElementById("instSpecgrpn").innerHTML	= headerNode[0].getAttribute("specgrpn");
	
	document.getElementById("instHeader").style.display = "table"



	// populate chart...
	var chartNode = columnNode.getElementsByTagName('assetDeposit');
	jsArray = JSON.parse(chartNode[0].innerHTML);


	var data = google.visualization.arrayToDataTable(jsArray);
	
	var options = {
		animation: {duration: 1000, startup: true, easing: 'out'},
		title : 'Quarterly Assets & Deposits',
		seriesType: 'bars',
		series: 
			{
			0: {targetAxisIndex: 0, type: 'bar', color: 'black'},
			1: {targetAxisIndex: 0, type: 'bar', color: 'green'},
			2: {targetAxisIndex: 1, type: 'line', color: 'red'},
			},
// 		hAxis: {slantedText: true},
		hAxis: {textPosition: 'none'},
		vAxis:
			{
			0: {format: 'currency'},
			1: {format: 'percent', color: 'red'},
			}
	};

	var chart = new google.visualization.ComboChart(document.getElementById('chart_div'));
	chart.draw(data, options);

}
	



