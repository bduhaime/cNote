<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<% 

%>

<html>

<head>

	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="chartTest.js"></script>
	<script>

		google.charts.load("visualization", "1", {packages:["corechart"]});
		google.charts.load('current', {'packages':['scatter','timeline','line','gauge','table']});
// 		google.charts.setOnLoadCallback(DrawChart2);
		google.charts.setOnLoadCallback(DrawTGIMUtilization1);
		google.charts.setOnLoadCallback(DrawTGIMUtilization2);
		
	</script>

</head>
<body>

<!--
	<div align="center" style="width: 600px; text-align: center; border: solid black;">
		<div id="valuesTable"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Values For Table</div>	
	</div>
	
-->
	<div align="center" style="width: 600px; text-align: center; border: solid blue;">
		<div id="tgimUtilitization1"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Values For TGIM Utilization</div>	
	</div>
	
	<div align="center" style="width: 600px; text-align: center; border: solid blue;">
		<div id="tgimUtilitization2"><img src="/images/ic_warning_black_24dp_2x.png"><br>No Values For TGIM Utilization</div>	
	</div>
	
</body>
</html>