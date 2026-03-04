<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>
      Google Visualization API Sample
    </title>
 	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">

	   google.charts.load('current', {'packages':['corechart', 'controls']});
		google.charts.setOnLoadCallback(drawVisualization);

    
		function drawVisualization() {
			control1 = createDashboard1();
			control2 = createDashboard2();
		
			google.visualization.events.addListener(control1, 'statechange', function() {
				control2.setState(control1.getState());
				control2.draw();
			});
		}
	  
		function createDashboard1() {

			// Prepare the data.
			var data = new google.visualization.DataTable(
				{ cols: [{id: 'ID', label: 'ID', type: 'number'},{id: 'Name', label: 'Name', type: 'string'},{id: 'Status', label: 'Status', type: 'string'}],rows: [{c: [{v: 56},{v: 'AB New Customer'},{v: 'Future'}]},{c: [{v: 55},{v: 'Abbeville First Bank, SSB'},{v: 'Active'}]},{c: [{v: 8},{v: 'Adams Community Bank'},{v: 'Active'}]},{c: [{v: 3},{v: 'American Bank of the North'},{v: 'Past'}]},{c: [{v: 4},{v: 'Athens Federal Community Bank, National Association'},{v: 'Active'}]},{c: [{v: 5},{v: 'BancCentral'},{v: 'Active'}]},{c: [{v: 6},{v: 'Bank of Tennessee'},{v: 'Active'}]},{c: [{v: 7},{v: 'Citizens & Northern Bank'},{v: 'Active'}]},{c: [{v: 10},{v: 'Citizens Bank of Lafayette'},{v: 'Active'}]},{c: [{v: 9},{v: 'Cleveland State Bank'},{v: 'Active'}]},{c: [{v: 2},{v: 'Community Financial Services Bank'},{v: 'Active'}]},{c: [{v: 11},{v: 'Cross Keys Bank'},{v: 'Future'}]},{c: [{v: 12},{v: 'Decorah Bank & Trust Company'},{v: 'Active'}]},{c: [{v: 13},{v: 'Denali State Bank'},{v: 'Active'}]},{c: [{v: 14},{v: 'Denver Savings Bank'},{v: 'Future'}]},{c: [{v: 15},{v: 'Farmers Bank, Frankfort, Indiana'},{v: 'Active'}]},{c: [{v: 16},{v: 'Farmers State Bank'},{v: 'Active'}]},{c: [{v: 17},{v: 'Farmers State Bank of Alto Pass'},{v: 'Active'}]},{c: [{v: 18},{v: 'First Arkansas Bank and Trust'},{v: 'Active'}]},{c: [{v: 19},{v: 'First Citizens National Bank of Upper Sandusky'},{v: 'Active'}]},{c: [{v: 20},{v: 'First National Bank of Carmi'},{v: 'Active'}]},{c: [{v: 21},{v: 'First National Bank of Kansas'},{v: 'Reborn'}]},{c: [{v: 54},{v: 'First National Bank of Layton'},{v: 'Active'}]},{c: [{v: 22},{v: 'First National Bank of Syracuse'},{v: 'Active'}]},{c: [{v: 23},{v: 'First Volunteer Bank'},{v: 'Active'}]},{c: [{v: 24},{v: 'Hardin County Bank'},{v: 'Active'}]},{c: [{v: 25},{v: 'Home State Bank'},{v: 'Active'}]},{c: [{v: 26},{v: 'Hoosier Heartland State Bank'},{v: 'Active'}]},{c: [{v: 27},{v: 'Iowa-Nebraska State Bank'},{v: 'Active'}]},{c: [{v: 28},{v: 'Kennebec Federal Savings and Loan Association of Waterville'},{v: 'Active'}]},{c: [{v: 29},{v: 'KS Bank, Inc.'},{v: 'Active'}]},{c: [{v: 30},{v: 'Landmark National Bank'},{v: 'Active'}]},{c: [{v: 31},{v: 'Legence Bank'},{v: 'Active'}]},{c: [{v: 32},{v: 'Libertyville Savings Bank'},{v: 'Active'}]},{c: [{v: 33},{v: 'Malvern Federal Savings'},{v: 'Future'}]},{c: [{v: 34},{v: 'Mesaba Bancshares'},{v: 'Past'}]},{c: [{v: 35},{v: 'North Star Bank'},{v: 'Future'}]},{c: [{v: 36},{v: 'Northwest Bank & Trust Company'},{v: 'Active'}]},{c: [{v: 37},{v: 'Northwestern Bank, National Association'},{v: 'Active'}]},{c: [{v: 38},{v: 'Old Mission Bank'},{v: 'Future'}]},{c: [{v: 39},{v: 'Olympia Federal Savings and Loan Association'},{v: 'Active'}]},{c: [{v: 40},{v: 'Pioneer Bank'},{v: 'Active'}]},{c: [{v: 41},{v: 'Profinium, Inc.'},{v: 'Active'}]},{c: [{v: 42},{v: 'Ramsey National Bank'},{v: 'Future'}]},{c: [{v: 43},{v: 'Regent Bank'},{v: 'Active'}]},{c: [{v: 44},{v: 'Richwood Banking Company'},{v: 'Reborn'}]},{c: [{v: 45},{v: 'Security Bank'},{v: 'Active'}]},{c: [{v: 46},{v: 'Security National Bank of Omaha'},{v: 'Active'}]},{c: [{v: 47},{v: 'Southern Bank & Trust Company'},{v: 'Future'}]},{c: [{v: 48},{v: 'Sterling Federal Bank, F.S.B.'},{v: 'Active'}]},{c: [{v: 49},{v: 'Thomaston Savings Bank'},{v: 'Active'}]},{c: [{v: 50},{v: 'Tioga State Bank'},{v: 'Active'}]},{c: [{v: 51},{v: 'Virginia Partners Bank'},{v: 'Active'}]},{c: [{v: 52},{v: 'West Plains Bank and Trust Company'},{v: 'Active'}]},{c: [{v: 53},{v: 'Wood & Huston Bank'},{v: 'Future'}]}]}
			);
			
			// Define a StringFilter control for the 'Name' column
			var stringFilter = new google.visualization.ControlWrapper({
				'controlType': 'StringFilter',
				'containerId': 'control1',
				'options': {
					'filterColumnLabel': 'Name'
				}
			});
			
			// Define a table visualization
			var table = new google.visualization.ChartWrapper({
				'chartType': 'Table',
				'containerId': 'chart1',
				'options': {'height': '13em', 'width': '20em'}
			});
			
			// Create the dashboard.
			var dashboard = new google.visualization.Dashboard(document.getElementById('dashboard')).
			
			// Configure the string filter to affect the table contents
			bind(stringFilter, table).
			
			// Draw the dashboard
			draw(data);
			
			return stringFilter;
			
		}
      
		function createDashboard2() {
			
			// Prepare the data.
			var data = new google.visualization.DataTable(
				{ cols: [{id: 'Name', label: 'Name', type: 'string'},{id: 'Type', label: 'Type', type: 'string'},{id: 'Status', label: 'Status', type: 'string'},{id: 'maxStartDate', label: 'maxStartDate', type: 'date'},{id: 'daysSinceLastCall', label: 'daysSinceLastCall', type: 'number'}],rows: [{c: [{v: 'Adams Community Bank'},{v: 'HFY'},{v: 'Active'},{v: new Date(2018, 3, 17)},{v: 3}]},{c: [{v: 'Adams Community Bank'},{v: 'MCC'},{v: 'Active'},{v: new Date(2018, 3, 3)},{v: 17}]},{c: [{v: 'Adams Community Bank'},{v: 'SAC'},{v: 'Active'},{v: new Date(2017, 7, 10)},{v: 253}]},{c: [{v: 'American Bank of the North'},{v: 'DAD'},{v: 'Past'},{v: new Date(2017, 8, 6)},{v: 226}]},{c: [{v: 'BancCentral'},{v: 'HFY'},{v: 'Active'},{v: new Date(2018, 1, 14)},{v: 65}]},{c: [{v: 'BancCentral'},{v: 'MCC'},{v: 'Active'},{v: new Date(2017, 2, 1)},{v: 415}]},{c: [{v: 'Citizens Bank of Lafayette'},{v: 'HFY'},{v: 'Active'},{v: new Date(2018, 1, 15)},{v: 64}]},{c: [{v: 'Denali State Bank'},{v: 'HFY'},{v: 'Active'},{v: new Date(2018, 2, 1)},{v: 50}]},{c: [{v: 'Denali State Bank'},{v: 'MCC'},{v: 'Active'},{v: new Date(2017, 9, 1)},{v: 201}]}]}
			);
			
			// Define a StringFilter control for the 'Name' column
			var stringFilter = new google.visualization.ControlWrapper({
				'controlType': 'StringFilter',
				'containerId': 'control2',
				'options': {
					'filterColumnLabel': 'Name'
				}
			});
			
			// Define a table visualization
			var table = new google.visualization.ChartWrapper({
				'chartType': 'Table',
				'containerId': 'chart2',
				'options': {'height': '13em', 'width': '20em'}
			});
			
			// Create the dashboard.
			var dashboard = new google.visualization.Dashboard(document.getElementById('dashboard')).
			
			// Configure the string filter to affect the table contents
			bind(stringFilter, table).
			
			// Draw the dashboard
			draw(data);
			
			return stringFilter;
			
		}      
    </script>
  </head>
  <body style="font-family: Arial;border: 0 none;">
    <div id="dashboard">
      <table>
        <tr style='vertical-align: top'>
          <td style='width: 300px; font-size: 0.9em;'>
            <div id="control1"></div>
            <div id="control2"></div>
          </td>
          <td style='width: 600px'>
            <div style="float: left;" id="chart1"></div>
            <div style="float: left;" id="chart2"></div>
          </td>
        </tr>
      </table>
    </div>
  </body>
</html>
