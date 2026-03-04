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
function DateDetail_onClick(documentNode) {
/*****************************************************************************************/

	var calendarDate = documentNode.id;
	
	var requestUrl 	= "ajax/calendarMaintenance.asp?cmd=query&id=" + calendarDate;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_updateStatus;
		request.open("GET", requestUrl,  true);
		request.send(null);		
	}

	function StateChangeHandler_updateStatus() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_updateDetails(request.responseXML);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}

}

/*****************************************************************************************/
function Complete_updateDetails(urNode) {
/*****************************************************************************************/

	var displayDateVal 	= GetInnerText(urNode.getElementsByTagName('dateID')[0]);
	var displayDateElem 	= document.getElementById('displayDate');
	if (moment(displayDateVal).isValid()) {
		displayDateElem.innerHTML = moment(displayDateVal).format('M/D/YYYY');
	} else {
		displayDateElem.innerHTML = 'Invalid Date';
	}

	document.getElementById('yearNo').innerHTML 				= GetInnerText(urNode.getElementsByTagName('yearNo')[0]);
	document.getElementById('quarterNo').innerHTML 			= GetInnerText(urNode.getElementsByTagName('quarterNo')[0]);
	document.getElementById('monthNo').innerHTML 			= GetInnerText(urNode.getElementsByTagName('monthNo')[0]);
	document.getElementById('monthName').innerHTML 			= GetInnerText(urNode.getElementsByTagName('monthName')[0]);
	document.getElementById('weekNo').innerHTML 				= GetInnerText(urNode.getElementsByTagName('weekNo')[0]);
	document.getElementById('dayOfMonth').innerHTML 		= GetInnerText(urNode.getElementsByTagName('dayOfMonth')[0]);
	document.getElementById('dayOfWeekNo').innerHTML 		= GetInnerText(urNode.getElementsByTagName('dayOfWeekNo')[0]);
	document.getElementById('dayOfWeekName').innerHTML 	= GetInnerText(urNode.getElementsByTagName('dayOfWeekName')[0]);
	document.getElementById('dayNo').innerHTML				= GetInnerText(urNode.getElementsByTagName('dayNo')[0]);
/*
	document.getElementById('fiscalYearNo').innerHTML 		= GetInnerText(urNode.getElementsByTagName('fiscalYearNo')[0]);
	document.getElementById('fiscalQuarterNo').innerHTML 	= GetInnerText(urNode.getElementsByTagName('fiscalQuarterNo')[0]);
	document.getElementById('fiscalMonthNo').innerHTML 	= GetInnerText(urNode.getElementsByTagName('fiscalMonthNo')[0]);
	document.getElementById('fiscalMonthName').innerHTML 	= GetInnerText(urNode.getElementsByTagName('fiscalMonthName')[0]);
	document.getElementById('fiscalWeekNo').innerHTML 		= GetInnerText(urNode.getElementsByTagName('fiscalWeekNo')[0]);
	document.getElementById('fiscalDayOfMonth').innerHTML = GetInnerText(urNode.getElementsByTagName('fiscalDayOfMonth')[0]);
	document.getElementById('fiscalDayNo').innerHTML 		= GetInnerText(urNode.getElementsByTagName('fiscalDayNo')[0]);
*/
	document.getElementById('seasonName').innerHTML 		= GetInnerText(urNode.getElementsByTagName('seasonName')[0]);

	if (GetInnerText(urNode.getElementsByTagName('weekdayInd')[0]) == '1') {
		document.getElementById('weekdayInd').parentElement.MaterialCheckbox.check();
	} else {
		document.getElementById('weekdayInd').parentElement.MaterialCheckbox.uncheck();
	}
//	document.getElementById('weekdayInd').innerHTML 		= GetInnerText(urNode.getElementsByTagName('weekdayInd')[0]);
	
	if (GetInnerText(urNode.getElementsByTagName('usaHolidayInd')[0]) == '1') {
		document.getElementById('usaHolidayInd').parentElement.MaterialCheckbox.check();
	} else {
		document.getElementById('usaHolidayInd').parentElement.MaterialCheckbox.uncheck();
	}
// document.getElementById('usaHolidayInd').innerHTML 	= GetInnerText(urNode.getElementsByTagName('usaHolidayInd')[0]);

	document.getElementById('usaHolidayName').innerHTML 	= GetInnerText(urNode.getElementsByTagName('usaHolidayName')[0]);

	if (GetInnerText(urNode.getElementsByTagName('canHolidayInd')[0]) == '1') {
		document.getElementById('canHolidayInd').parentElement.MaterialCheckbox.check();
	} else {
		document.getElementById('canHolidayInd').parentElement.MaterialCheckbox.uncheck();
	}
//	document.getElementById('canHolidayInd').innerHTML 	= GetInnerText(urNode.getElementsByTagName('canHolidayInd')[0]);

	document.getElementById('canHolidayName').innerHTML 	= GetInnerText(urNode.getElementsByTagName('canHolidayName')[0]);
	
	var button_editCustomDate = document.getElementById('button_editCustomDate');
	if (button_editCustomDate) {
		document.getElementById('button_editCustomDate').disabled = false;
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

