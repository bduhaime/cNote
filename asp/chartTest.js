//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";

var request = null;

// window.onload = PopulateGoogleCharts();



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
function DrawTGIMUtilization1() {
/*****************************************************************************************/

	// need to figure out how to parameterize the value needed for c.id...
/*
	var sql = "select d.id as metricDate, x.metricValue as metricValue  " 
				+"from dateDimension d " 
				+"left join " 
				+"	( " 
				+"	select cim.metricDate, cim.metricValue, cim.rssdid " 
				+"	from customerInternalMetrics cim "
				+"	join customer_view c on (c.rssdid = cim.rssdid) " 
				+"	and cim.metricID = 6 " 
				+"	and c.id = 8 " 
				+"	) x on (x.metricDate = d.id) " 
				+"where d.id between '8/1/16' and '8/1/17' " 
				+"group by d.yearNo, d.monthNo " 
				+"order by d.yearNo, d.monthNo "
*/
	var timestamp = new Date().getUTCMilliseconds();
	
	var sql = "select cim.metricDate, cim.metricValue " 
				+"from customerInternalMetrics cim "
				+"join customer_view c on (c.rssdid = cim.rssdid) " 
				+"and cim.metricID = 6 " 
				+"and c.id = 8 " 
				+"where cim.metricDate between '8/1/16' and '8/1/17' " 
				+"order by cim.metricDate "
	
	var requestUrl 	= "ajax/jsonDataTable.asp?sql=" + encodeURIComponent(sql) + "&time=" + timestamp;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_DrawTGIMUtilization1;
		request.open("GET", requestUrl,  false);
		request.send(null);		
	}

	function StateChangeHandler_DrawTGIMUtilization1() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_DrawTGIMUtilization1(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
}


/*****************************************************************************************/
function Complete_DrawTGIMUtilization1(json) {
/*****************************************************************************************/

	var jsonEval = eval("("+json+")");
	var data = new google.visualization.DataTable(jsonEval);
	
	var options = {
		title: 'TGIM Utilization',
		legend: {position: 'none'},
		pointSize: 6,
		height: 200,
		hAxis: {slantedText: true},
	};

	var chart = new google.visualization.LineChart(document.getElementById('tgimUtilitization1'));
	chart.draw(data, options);

}



/*****************************************************************************************/
function DrawTGIMUtilization2() {
/*****************************************************************************************/

	// need to figure out how to parameterize the value needed for c.id...
/*
	var sql = "select d.id as metricDate, x.metricValue as metricValue  " 
				+"from dateDimension d " 
				+"left join " 
				+"	( " 
				+"	select cim.metricDate, cim.metricValue, cim.rssdid " 
				+"	from customerInternalMetrics cim "
				+"	join customer_view c on (c.rssdid = cim.rssdid) " 
				+"	and cim.metricID = 6 " 
				+"	and c.id = 8 " 
				+"	) x on (x.metricDate = d.id) " 
				+"where d.id between '8/1/16' and '8/1/17' " 
				+"group by d.yearNo, d.monthNo " 
				+"order by d.yearNo, d.monthNo "
*/
	var timestamp = new Date().getUTCMilliseconds();
	
	var sql = "select cim.metricDate, cim.metricValue " 
				+"from customerInternalMetrics cim "
				+"join customer_view c on (c.rssdid = cim.rssdid) " 
				+"and cim.metricID = 6 " 
				+"and c.id = 8 " 
				+"where cim.metricDate between '8/1/16' and '8/1/17' " 
				+"order by cim.metricDate "
	
	var requestUrl 	= "ajax/jsonDataTable.asp?sql=" + encodeURIComponent(sql) + "&time=" + timestamp;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_DrawTGIMUtilization2;
		request.open("GET", requestUrl,  false);
		request.send(null);		
	}

	function StateChangeHandler_DrawTGIMUtilization2() {
	
		if(request.readyState == 4) {
			if(request.status == 200) {
				Complete_DrawTGIMUtilization2(request.responseText);
			} else {
				alert("problem retrieving data from the server, status code: "  + request.status);
			}
		}
	
	}
	
}


/*****************************************************************************************/
function Complete_DrawTGIMUtilization2(json) {
/*****************************************************************************************/

	var jsonEval = eval("("+json+")");
	var data = new google.visualization.DataTable(jsonEval);
	
	var options = {
		title: 'TGIM Utilization',
		legend: {position: 'none'},
		pointSize: 6,
		height: 200,
		hAxis: {slantedText: true},
	};

	var chart = new google.visualization.LineChart(document.getElementById('tgimUtilitization2'));
	chart.draw(data, options);

}



/*****************************************************************************************/
function DrawChart2() {
/*****************************************************************************************/

	// need to figure out how to parameterize the value needed for c.id...
	var sql = "select cim.id, m.name, cim.metricDate, cim.metricValue "
				+"from customerInternalMetrics cim "
				+"left join metric m on (m.id = cim.metricID) " 
				+"join customer_view c on (c.rssdid = cim.rssdid) "
				+"where c.id = 8 " 
				+"order by metricDate desc ";
	
	var requestUrl 	= "ajax/jsonDataTable.asp?sql=" + sql;
	CreateRequest();
 
	if(request) {
		request.onreadystatechange = StateChangeHandler_drawChart2;
		request.open("GET", requestUrl,  false);
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

	var jsonEval = eval("("+json+")");
	var data = new google.visualization.DataTable(jsonEval);

	var options = {
		height: '100%',
		page: 'enable',
		pageSize: 10,
		width: '100%',
	};

	var chart = new google.visualization.Table(document.getElementById('valuesTable'));
	chart.draw(data, options);

}



/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}
