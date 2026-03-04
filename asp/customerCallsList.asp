<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/metrics/dt_daysSinceLastContactByCustomer.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysSinceLastCallByCallType.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysSinceLastCallByPrimaryManager.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysSinceLastMCCByAcctMgr.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallType.asp" -->
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeAllCustomers.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(115)

title = session("clientID") & " - Customer Calls List" 
userLog(title)
chartHeight = 200

startDate = dateAdd("yyyy", -1, date())


'===================================================================================================
'= this first section of code get the short names for call types, and sets up the primary query(ies)
'= as well as the summation done in the Google Visualization sections below
'===================================================================================================
'
SQL = "select case when len(shortName) > 0 then shortName else name end as shortName " &_
		"from customerCallTypes " &_
		"order by 1 desc " 

sqlProjection			= ""

googleGroupByOffset 	= 15
googleGroupby 			= ""

		
set rsCCT = dataconn.execute(SQL) 
while not rsCCT.eof 
		
' 	sqlProjection = sqlProjection & "case when endDateTime is null then case when cct.shortName = '" & rsCCT("shortName") & "' then datediff(minute, cc.startDateTime, cc.endDateTime)/60.0 else 0 end as [" & rsCCT("shortName") & "]"
	sqlProjection = 	sqlProjection &_
							"case when cct.shortName = '" & rsCCT("shortName") & "' then " &_
								"case when endDateTime is null then " &_
									"datediff(minute, cc.scheduledStartDatetime, cc.scheduledEndDateTime)/60.0 " &_
								"else " &_
									"datediff(minute, cc.startDateTime, cc.endDateTime)/60.0 " &_
								"end " &_
							"else " &_
								"0.0 " &_
							"end " &_
							"as [" & rsCCT("shortName") & "] "


	googleGroupby = googleGroupby & "{column: " & googleGroupByOffset & ", 'aggregation': google.visualization.data.sum, type: 'number', label: '" & rsCCT("shortName") & "'}"

	rsCCT.movenext 
	
	if not rsCCT.eof then 
		
		sqlProjection 			= sqlProjection & ", "
		googleGroupby 			= googleGroupby & ", "
		googleGroupByOffset 	= googleGroupByOffset + 1

	end if
	
wend 
rsCCT.close 
set rsCCT = nothing 

dbug("sqlProjection: " & sqlProjection)
dbug("googleGroupby: " & googleGroupby)

SQL = "select " &_
			"cc.id as [Call ID], " &_
			"c.id as [Customer ID], " &_
			"case " &_
				"when endDateTime is null then " &_
					"convert(date, cc.scheduledStartDateTime) " &_
				"else " &_
					"convert(date, cc.startDateTime) " &_
				"end as [Call Date], " &_
			"case " &_
				"when endDateTime is null then " &_
					"format(cc.scheduledStartDateTime, 'hh:mm') " &_
				"else " &_
					"format(cc.startDateTime, 'hh:mm') " &_
				"end as [Time], " &_
			"c.name as [Customer], " &_
			"concat(ul.firstName, ' ', ul.lastName) as [Call Lead], " &_
			"cs.name as [Customer Status], " &_
			"cct.shortName as [Call Type], " &_
			"case " &_
				"when endDateTime is null then " &_
					"datediff(minute, cc.scheduledStartDateTime, cc.scheduledEndDateTime) " &_
				"else " &_
					"dateDiff(minute, cc.startDateTime, cc.endDateTime) " &_
				"end as [Call Duration], " &_
			"case " &_
				"when endDateTime is null then " &_
					"'Scheduled' " &_
				"else " &_
					"'Completed' " &_
				"end as [Call Status] " &_
		"from customerCalls cc " &_
		"left join customer_view c on (c.id = customerID) " &_
		"left join dateDimension sd on (sd.id = CONVERT(date, cc.scheduledStartDateTime)) " &_
		"left join dateDimension ed on (ed.id = CONVERT(date, cc.endDateTime)) " &_
		"left join customerStatus cs on (cs.id = c.customerStatusID) " &_	
		"left join customerCallTypes cct on (cct.id = cc.calltypeID) " &_
		"left join csuite..users ul on (ul.id = cc.callLead) " &_
		"where (cc.deleted = 0 or cc.deleted is null) " &_
		"and (c.deleted = 0 or c.deleted is null) " &_
		"order by 3, 4 "

dbug("customerCalls: " & SQL)
customerCalls = jsonDataTable(SQL)

		

' SQL = "select " &_
' 			"case when endDateTime is null then convert(date, cc.scheduledStartDateTime) else convert(date, endDateTime) end as callDate, " &_
' 			"sd.yearNo, " &_
' 			"sd.MonthName, " &_
' 			"sd.weekNo, " &_
' 			"sd.dayOfWeekName, " &_
' 			"ed.id as endDate, " &_
' 			"cc.id as customerCallID, " &_
' 			"cc.startDateTime, " &_
' 			"cc.endDateTime, " &_
' 			"c.name as customerName, " &_
' 			"case when cca.attendeeID is not null then concat(ua.firstName, ' ', ua.lastName) else 'Unknown' end as attendeeFullName, " &_
' 			"concat(ul.firstName, ' ', ul.lastName) as leaderFullName, " &_
' 			"cs.name as customerStatusName, " &_
' 			"cc.name as customerCallName, " &_
' 			"cct.shortName as customerCallType, " &_
' 			sqlProjection & ", " &_
' 			"cc.description as customerCallDescription, " &_
' 			"cct.name as callTypeName, " &_
' 			"case when endDateTime is null then datediff(minute, cc.scheduledStartDateTime, cc.scheduledEndDateTime)/60.0 else dateDiff(minute, cc.startDateTime, cc.endDateTime) end as callDurationMinutes, " &_
' 			"case when endDateTime is null then 'Scheduled' else 'Completed' end as callStatus " &_
' 		"from customerCalls cc " &_
' 		"left join customer_view c on (c.id = customerID) " &_
' 		"left join dateDimension sd on (sd.id = CONVERT(date, cc.startDateTime)) " &_
' 		"left join dateDimension ed on (ed.id = CONVERT(date, cc.endDateTime)) " &_
' 		"left join customerStatus cs on (cs.id = c.customerStatusID) " &_	
' 		"left join customerCallTypes cct on (cct.id = cc.calltypeID) " &_
' 		"left join customerCallAttendees cca on (cca.customerCallID = cc.id) " &_
' 		"left join csuite..users ul on (ul.id = cc.callLead) " &_
' 		"left join csuite..users ua on (ua.id = cca.attendeeID) " &_
' 		"where (cc.deleted = 0 or cc.deleted is null) " &_
' 		"and (c.deleted = 0 or c.deleted is null) " &_
' 		"and (cca.attendeeID <> cc.callLead) " &_
' 		"and (cca.deleted = 0 or cca.deleted is null) " &_
' 		"and cca.attendeeType = 'user' " &_
' 		"and cca.attendedIndicator = 1 " 
' 
' dbug("attendeeCalls: " & SQL)
' attendeeCalls = jsonDataTable(SQL)



'***************************************************************************************************
'***************************************************************************************************
'***************************************************************************************************
'***************************************************************************************************
'***************************************************************************************************

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

    <script type="text/javascript">

		google.charts.load('current', {'packages':['table', 'gauge', 'corechart', 'calendar', 'controls']});
		
 		google.charts.setOnLoadCallback(buildDashboards);
 		
 		
 		var chartHeight = 250
 		
 		
		//================================================================================================ 
 		function buildDashboards() {
		//================================================================================================ 

			//---- Control Wrapper for Customer Status ----//
		   var statusPicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'statusPicker',
		      <% if len(request.querystring("customerStatuses")) > 0 then %>
		      	state: { selectedValues: [
			      <%
		      	custStatusArray = split(request.querystring("customerStatuses"), "|")
		      	for each item in custStatusArray
		      		response.write("'" & item & "',") 
		      	next 
		      	%>
		      	]},
				<% end if %>
		      
		      options: {
		         filterColumnLabel: 'Customer Status',
		         ui: {
			         allowMultiple: true,
		            selectedValuesLayout: 'belowStacked',
		            labelSeparator: ':',
		            label: 'Customer Status',
		         },
		      },
		   });	




			//---- Control Wrapper for Customer Name ----//
		   var customerPicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'customerPicker',
		      <% if len(request.querystring("customers")) > 0 then %>
		      	state: { selectedValues: [
			      	<%
			      	selectedCustomerArray = split(request.querystring("customers"), "|")
			      	for each item in selectedCustomerArray 
			      		response.write("'" & item & "',")
			      	next
			      	%>
			      ]},
			   <% end if %>
		      options: {
		         filterColumnLabel: 'Customer',
		         ui: {
		            selectedValuesLayout: 'belowStacked',
		            allowTyping: true, 
		            labelSeparator: ':',
		            label: 'Customer',
		         },
		      },
		   });
		   



			//---- Control Wrapper for Call Type ----//
		   var callTypePicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'callTypePicker',
		      <% if len(request.querystring("callTypes")) > 0 then %>
	      		state: { selectedValues: [
		      		<%
		      		callTypesArray = split(request.querystring("callTypes"), "|")
		      		for each item in callTypesArray 
		      			response.write("'" & item & "',")
		      		next 
		      		%>
		      	]},
			     <% end if %>
		      options: {
		         filterColumnLabel: 'Call Type',
		         ui: {
		            selectedValuesLayout: 'belowStacked',
		            allowTyping: true, 
		            labelSeparator: ':',
		            label: 'Call Type',
		         },
		      },
		   });
		   



			//---- Control Wrapper for Call Status ----//
		   var callStatusPicker = new google.visualization.ControlWrapper({
		      controlType: 'CategoryFilter',
		      containerId: 'callStatusPicker',
		      <% if len(request.querystring("callStatuses")) > 0 then %>
		      	state: { selectedValues: [
			      	<%
			      	callStatusesArray = split(request.querystring("callStatuses"), "|")
			      	for each item in callStatusesArray
			      		response.write("'" & item & "',")
			      	next 
						%>
			      ]},
			   <% end if %>
		      options: {
		         filterColumnLabel: 'Call Status',
		         ui: {
		            selectedValuesLayout: 'belowStacked',
		            allowTyping: true, 
		            labelSeparator: ':',
		            label: 'Call Status',
		         },
		      },
		   });
		   



			//---- Control Wrapper for Call Lead ----//
			var callLeadPicker = new google.visualization.ControlWrapper({
				controlType: 'CategoryFilter',
				containerId: 'callLeadPicker',
				<% if len(request.querystring("callLeads")) then %>
					state: { selectedValues: [
						<%
						callLeadsArray = split(request.querystring("callLeads"), "|")
						for each item in callLeadsArray 
							response.write("'" & item & "',")
						next 
						%>
					]},
				<% end if %>
				options: {
					filterColumnLabel: 'Call Lead',
					ui: {
						selectedValuesLayout: 'belowStacked',
						allowTyping: true, 
						labelSeparator: ':',
						label: 'Call Lead',
					},
				},
			});
			
			


			//---- Control Wrapper for Call Date ----//		   
		   var startDateSlider = new google.visualization.ControlWrapper({
			   controlType: 'DateRangeFilter',
			   containerId: 'dateRangeSlider',
			   <% if (len(request.querystring("callDateMin")) > 0 OR len(request.querystring("callDateMax")) > 0) then %>
				   state: {
					   <% if len(request.querystring("callDateMin")) > 0 then %>
						   lowValue: moment('<% =request.querystring("callDateMin") %>'),
						<% end if %>
						<% if len(request.querystring("callDateMax")) > 0 then %>
						   highValue: moment('<% =request.querystring("callDateMax") %>'),	
						<% end if %>
				   },
				<% end if %>
			   options: {
				   filterColumnLabel: 'Call Date',
				   ui: {
					   labelSeparator: ':',
					   label: 'Date',
					   labelStacking: 'vertical',
					   format: {
						   formatType: 'short',
						},
				   },
			   },
		   });
		



			//---- ChartWrappers for All Data -- this table is not shown to the user, but all the charts rely on these ----//
			
			//----------------------------------------------------			
			// ChartWrappers for All Data -- this table is not shown to the user, but all the charts rely on these
			//----------------------------------------------------						
			var table = new google.visualization.ChartWrapper({
				chartType: 'Table',
				containerId: 'customerCalls',
			});
			table.setView({columns: [2,3,4,5,6,7,8,9]});
							   
			var data = new google.visualization.DataTable(<% =customerCalls %>);
			

			//---- DEFINE & DRAW the "customer" dashboards ----//
		   var dashboard = new google.visualization.Dashboard(document.getElementById('dashboard')).
				bind([statusPicker], 		[customerPicker, 		callTypePicker, 	callStatusPicker, callLeadPicker, 	startDateSlider, 	table]).
				bind([customerPicker], 		[callTypePicker, 		callStatusPicker, callLeadPicker, 	startDateSlider, 	table]).
				bind([callTypePicker], 		[callStatusPicker,	callLeadPicker, 	startDateSlider, 	table]).
				bind([callStatusPicker], 	[callLeadPicker, 		startDateSlider, 	table]).
				bind([callLeadPicker], 		[startDateSlider, 	table]).
				bind([startDateSlider], 	[table]);
				
			dashboard.draw(data);


			//-----------------------------------------------------------------------------------------------
			google.visualization.events.addListener(table, 'ready', function() {
			//-----------------------------------------------------------------------------------------------				

				google.visualization.events.addListener(table, 'select', function() {
					
					// get selected date from chart and update the startDateSlider...
					var selectedItem 	= table.getChart().getSelection()[0];
					
					var callID 			= table.getDataTable().getValue(selectedItem.row, 0);
					var customerID 	= table.getDataTable().getValue(selectedItem.row, 1);
					
					window.location.href = 'annotateCalls.asp?customerID=' + customerID + '&callID=' + callID;

				});
	
				

			});


		}  // end of "buildDashboards"




		//================================================================================================ 
		//================================================================================================ 


  </script>

	<style>

		div.controlContainer {
			margin: 15px;
		}
		
		div.hideThis {
			display: none;	
		}
		
		label.google-visualization-controls-label {
			width: 125px;
		}
		
	</style>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	
	<div id="dashboard" class="page-content">
	<!-- Your content goes here -->
	
		<div class="mdl-grid"><!-- start of primary mdl-grid
			<!-- new row of grids... -->
	
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">
			
				<h5 style="margin-left: 15px;">Filters:</h5>

				<div id="statusPicker" 			class="controlContainer"></div>

				<div id="customerPicker" 		class="controlContainer"></div>

				<div id="callTypePicker" 		class="controlContainer"></div>

				<div id="callStatusPicker" 	class="controlContainer"></div>

				<div id="callLeadPicker" 		class="controlContainer"></div>

				<div id="dateRangeSlider" 		class="controlContainer"></div>
					

			</div>
			
			
			<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp">
				
				<div class="mdl-tabs mdl-js-tabs mdl-js-ripple-effect"><!-- start of tabs -->
				
						<div class="mdl-grid"><!-- new row of grids... -->
		
							<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">		
								<div id="customerCalls">customerCalls</div>
							</div>
						
						</div>
				
				</div>
				
			</div><!-- end of 9-col secondary grid -->
			
		</div><!-- end of primary mdl-grid -->
	
	

	</div><!-- end of dashboard -->



</main>
<!-- #include file="includes/pageFooter.asp" -->
</div><!--end of dashboard -->



</body>

</html>