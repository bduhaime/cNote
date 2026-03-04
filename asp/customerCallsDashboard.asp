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
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(115)

title = session("clientID") & " - Customer Calls Dashboard" 
userLog(title)
chartHeight = 200

startDate = dateAdd("yyyy", -1, date())

arrStatusList = split( request.querystring("statusList"), "," )

function valuePresent( arrayValue, arrayName ) 
	
	present = false
	
	for i = lBound( arrayName ) to uBound( arrayName ) 
		if cStr(arrayName(i)) = cStr(arrayValue) then 
			present = true 
			exit for 
		end if 
	next 
	
	valuePresent = present 
	
	
end function 


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

'***************************************************************************************************
'***************************************************************************************************
'***************************************************************************************************
'***************************************************************************************************
'***************************************************************************************************

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- 	Moment JS -->
	<script type="text/javascript" src="moment.min.js"></script>

	<!-- 	Google Visualizations -->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>


    <script type="text/javascript">

		google.charts.load('current', {'packages':['table', 'gauge', 'corechart', 'calendar', 'controls']});
		
 		google.charts.setOnLoadCallback(buildDashboards);
 		
 		
 		var chartHeight = 250
 		
		//====================================================================================
 		function NEWcustomerStatusList() {
		//================================================================================================ 

			let statusList = ''
			
			$( 'input.customerStatus' ).each( function() {

				if ( $( this ).is( ':checked' ) ) {
					elemID = $(this).attr('id');
					customerStatusID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
					if ( statusList.length > 0 ) statusList += ',';
					statusList += customerStatusID;
				}

			});

			return statusList;


 		}
		//====================================================================================

 		
		//================================================================================================ 
 		function customerStatusList() {
		//================================================================================================ 

			let customerStatusList = []

			$( 'input.customerStatus' ).each( function() {

				if ( $( this ).is( ':checked' ) ) {
					elemID = $(this).attr('id');
					customerStatusID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
					customerStatusList.push( customerStatusID );
				}

			});

			return JSON.stringify( customerStatusList );

 		}
		//================================================================================================ 

 		
		//====================================================================================
 		function NEWcallTypeList() {
		//================================================================================================ 

			let callTypeList = ''
			
			$( 'input.callType' ).each( function() {

				if ( $( this ).is( ':checked' ) ) {
					elemID = $(this).attr('id');
					callTypeID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
					if ( callTypeList.length > 0 ) callTypeList += ',';
					callTypeList += callTypeID;
				}

			});

			return callTypeList;


 		}
		//====================================================================================

 		
		//================================================================================================ 
 		function callTypeList() {
		//================================================================================================ 

			let callTypeList = []

			$( 'input.callType' ).each( function() {

				if ( $( this ).is( ':checked' ) ) {
					elemID = $(this).attr('id');
					callTypeID = elemID.substring( elemID.indexOf('-')+1, elemID.length )
					callTypeList.push( callTypeID );
				}

			});

			return JSON.stringify( callTypeList );

 		}
		//================================================================================================ 

 		
		//================================================================================================ 
 		function buildChart_NumberOfCallsByTimeOfDay() {
		//================================================================================================ 

			// Number of Calls By Time Of Day

			$.ajax({

				beforeSend: function() {
					$( '#timeOfDay_progressbar' ).progressbar({ value: false });
					$( '#timeOfDay' ).text( '' );
				},
				dataType: "json",
				url: `${apiServer}/api/customerCalls/callsByTimeOfDay`,
				data: { 
					statusList: NEWcustomerStatusList(),
					callTypeList: NEWcallTypeList(),
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT },

			}).done( function( data ) {
				
				let chart = new google.visualization.ColumnChart(document.getElementById( 'timeOfDay' ));
				let dataTable = new google.visualization.DataTable( data );
				chart.draw( dataTable, {
		         animation: {startup: true, duration: 500, easing: 'out'},
			      hAxis: {
				      ticks: [
				      	{v: 0, f: '12a'}, 
				      	{v: 4, f: '4a'}, 
				      	{v: 8, f: '8a'}, 
				      	{v: 12, f: '12p'}, 
				      	{v: 16, f: '4p'}, 
				      	{v: 20, f: '8p'}, 
				      	{v: 24, f: '12a'}
				      ],
			      },
		         height: '200',
			      legend: {
				      position: 'none',
			      },
			      series: {
				      0: {color: 'orange'},
			      },
		         title: 'Completed Calls By Time Of Day',
		         vAxis: {
			         title: '# Calls'
		         }
				});
				$( '#timeOfDay_progressbar' ).progressbar('destroy');

			}).fail( function( jqXHR, textStatus, errorThrown ) {

				console.error({
					message: 'Error in buildChart_NumberOfCallsByTimeOfDay()',
					status: textStatus,
					error: errorThrown
				});

			});

 		}
		//================================================================================================ 
 		
 		
		//================================================================================================ 
		function buildChart_NumberOfCallsByDayOfWeek() {
		//================================================================================================ 
			
			// Number of Calls By Day Of Week
			$.ajax({

				beforeSend: function() {
					$( '#dayOfWeek_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/customerCalls/callsByDayOfWeek`,
				data: { 
					statusList: NEWcustomerStatusList(),
					callTypeList: NEWcallTypeList(),
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT },

			}).done( function( data ) {

				let chart = new google.visualization.ColumnChart(document.getElementById( 'dayOfWeek' ));
				let dataTable = new google.visualization.DataTable( data );
				chart.draw( dataTable, {
		         animation: { startup: true, duration: 500, easing: 'out' },
		         height: '200',
			      legend: { position: 'none' },
			      hAxis: {
				      ticks: [
				      	{ v: 1, f: 'Sun' }, 
							{ v: 2, f: 'Mon' }, 
							{ v: 3, f: 'Tue' }, 
							{ v: 4, f: 'Wed' }, 
							{ v: 5, f: 'Thu' }, 
							{ v: 6, f: 'Fri' }, 
							{ v: 7, f: 'Sat' }
						],
			      },
			      series: { 0: { color: 'blue' } },
		         title: 'Completed Calls By Day Of Week',
		         vAxis: { title: '# Calls' },
				});
				$( '#dayOfWeek_progressbar' ).progressbar('destroy');
				
			}).fail( function( jqXHR, textStatus, errorThrown ) {

				console.error({
					message: 'Error in buildChart_NumberOfCallsByDayOfWeek()',
					status: textStatus,
					error: errorThrown
				});

			});

	
		}
		//================================================================================================ 
		
		
		//================================================================================================ 
		function buildChart_CompletedCallDurationByCustomerCallType() {
		//================================================================================================ 

			// Completed Call Duration By Customer and Call Type
			
			$.ajax({

				beforeSend: function() {
					$( '#callDurationCustomer_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/customerCalls/completeCallDurationByCustomerType`,
				data: { 
					statusList: NEWcustomerStatusList(),
					callTypeList: NEWcallTypeList(),
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT },

			}).done( function( data ) {

				let chart = new google.visualization.ColumnChart(document.getElementById( 'callDurationCustomer' ));
				let dataTable = new google.visualization.DataTable( data );
				chart.draw( dataTable, {
		         animation: { startup: true, duration: 500, easing: 'out' },
					chartArea: {
						left: 55,
						top: 50,
						width: '85%',
						height: '70%'
					},
					hAxis: { 
						textPosition: 'none',
						title: 'Customers'
					},
		         height: chartHeight,
		         isStacked: true,
			      legend: { position: 'none' },
		         vAxis: { title: 'Duration (minutes)' },
					title: 	'Completed Call Duration By Customer & Call Type',
				});
				$( '#callDurationCustomer_progressbar' ).progressbar('destroy');
				
			}).fail( function( jqXHR, textStatus, errorThrown ) {

				console.error({
					message: 'Error in buildChart_CompletedCallDurationByCustomerCallType()',
					status: textStatus,
					error: errorThrown
				});

			});
				 
	
	
		}
		//================================================================================================ 
		
		
		//================================================================================================ 
		function buildChart_CallDurationByCallLeadType() {
		//================================================================================================ 

			// Completed Call Duration By Call Lead and Call Type
			$.ajax({

				beforeSend: function() {
					$( '#callDurationCallLead_progressbar' ).progressbar({ value: false });
				},
				dataType: "json",
				url: `${apiServer}/api/customerCalls/completeCallDurationByCallLeadType`,
				data: { 
					statusList: NEWcustomerStatusList(),
					callTypeList: NEWcallTypeList(),
					startDate: $( '#startDate' ).val(),
					endDate: $( '#endDate' ).val(),
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT },

			}).done( function( data ) {
				
				let chart = new google.visualization.ColumnChart(document.getElementById( 'callDurationCallLead' ));
				let dataTable = new google.visualization.DataTable( data );
				chart.draw( dataTable, {
		         animation: {startup: true, duration: 500, easing: 'out'},
					chartArea: {
						left: 55,
						top: 50,
						width: '85%',
						height: '70%'
					},
					hAxis: { 
						textPosition: 'none',
						title: 'Call Leads'
					},
		         height: chartHeight,
		         isStacked: true,
			      legend: {
				      position: 'none',
			      },
		         vAxis: {
			         title: 'Duration (minutes)',
		         },
					title: 	'Completed Call Duration By Call Lead & Call Type',
				});
				$( '#callDurationCallLead_progressbar' ).progressbar('destroy');

			}).fail( function( jqXHR, textStatus, errorThrown ) {

				console.error({
					message: 'Error in buildChart_CallDurationByCallLeadType()',
					status: textStatus,
					error: errorThrown
				});

			});

		}
		//================================================================================================ 
		
		
		//================================================================================================ 
		function reloadChartsAndDataTables() {
		//================================================================================================ 

			buildChart_NumberOfCallsByTimeOfDay();
			buildChart_NumberOfCallsByDayOfWeek();
			buildChart_CompletedCallDurationByCustomerCallType();
			buildChart_CallDurationByCallLeadType();
			
			$( '#customersNoCompeltedCalls' ).DataTable().ajax.reload();
			$( '#scheduledCalls' ).DataTable().ajax.reload();
			$( '#missedCalls' ).DataTable().ajax.reload();
			$( '#completedCalls' ).DataTable().ajax.reload();

		}
		//================================================================================================ 

		
		//================================================================================================ 
 		function buildDashboards() {
		//================================================================================================ 


			$( function() {
	
				$( document ).tooltip();

				$( 'input.customerStatus' ).checkboxradio();
				$( 'input.customerStatus' ).on( 'click', function() {
					$( '#customerSummary' ).DataTable().ajax.reload();
				});

				$( 'input.callType' ).checkboxradio();
				$( 'input.callType' ).on( 'click', function() {
					$( '#customerSummary' ).DataTable().ajax.reload();
				});
				
				$( "#startDate" ).datepicker({
					changeMonth: true,
					changeYear: true,
					maxDate: $( '#endDate' ).val(),
					minDate: $( '#startDate' ).val(),
					onClose: function( startDate ) {
						$( '#endDate' ).datepicker( 'option', 'minDate', startDate );
						reloadChartsAndDataTables();
					},
				});
				
				$( "#endDate" ).datepicker({
					changeMonth: true,
					changeYear: true,
					maxDate: $( '#endDate' ).val(),
					minDate: $( '#startDate' ).val(),
					onClose: function( endDate ) {
						$( '#startDate' ).datepicker( 'option', 'maxDate', endDate );
						reloadChartsAndDataTables();
					},
				});
				
				
				buildChart_NumberOfCallsByTimeOfDay();
				buildChart_NumberOfCallsByDayOfWeek();
				buildChart_CompletedCallDurationByCustomerCallType();
				buildChart_CallDurationByCallLeadType();
	
				// Customer without completed calls...
				$( '#customersNoCompeltedCalls' ).DataTable({
					ajax: {
						url: `${apiServer}/api/customerCalls/customersNoCompletedCalls`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: function( data ) { 
							data.statusList = NEWcustomerStatusList();
							data.callTypeList = NEWcallTypeList();
							data.startDate = $( '#startDate' ).val();
							data.endDate = $( '#endDate' ).val();
						},
					},
					columnDefs: [
						{targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
						{targets: 'customerStatusName', data: 'customerStatusName', className: 'customerStatusName dt-body-center' },
					],
					info: false,
					processing: true,
					rowId: 'customerID',
					scrollCollapse: true,
					scrollX: true,
					scrollY: chartHeight - 50,
					scroller: true,
					searching: false,
				});
				
				
				$('#customersNoCompeltedCalls tbody').on('click', 'tr', function () {
					location.href = 'customerCalls.asp?id=' + this.id;
				});
	

				// scheduled calls...
				$( '#scheduledCalls' ).DataTable({
					ajax: {
						url: `${apiServer}/api/customerCalls/scheduledCalls`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: function( data ) { 
							data.statusList = NEWcustomerStatusList();
							data.callTypeList = NEWcallTypeList();
							data.endDate = $( '#endDate' ).val();
						},
					},
					columnDefs: [
						{targets: 'scheduledStartDateTime', data: 'scheduledStartDateTime', className: 'scheduledStartDateTime dt-body-center' },
						{targets: 'callType', data: 'callType', className: 'callType dt-body-center' },
						{targets: 'customerID', data: 'customerID', className: 'customerID', visible: false },
						{targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
						{targets: 'customerStatus', data: 'customerStatus', className: 'customerStatus dt-body-center' },
						{targets: 'callLead', data: 'callLead', className: 'callLead dt-body-left' },
					],
					info: false,
					order: ([ 0, 'desc' ]),
					processing: true,
					rowId: 'callID',
					scrollCollapse: true,
					scrollX: true,
					scrollY: chartHeight - 50,
					scroller: true,
					searching: false,
				});
	
				$( '#scheduledCalls tbody' ).on( 'click', 'td.customerName', function( event ) {
					event.stopPropagation();
					const currentRow = $( this ).closest( 'tr' );
					const data = $( '#scheduledCalls' ).DataTable().row( currentRow ).data();
					const customerID = data.customerID;
					location.href = 'customerCalls.asp?id=' + customerID;
				});

				$('#scheduledCalls tbody').on('click', 'tr', function () {
					const callID = this.id;
					const currentRow = $( this );
					const data = $( '#scheduledCalls' ).DataTable().row( currentRow ).data();
					const customerID = data[ 'customerID' ];
					location.href = 'annotateCalls.asp?customerID=' + customerID + '&callID=' + callID;
				});
	


				// missed calls...
				$( '#missedCalls' ).DataTable({
					ajax: {
						url: `${apiServer}/api/customerCalls/missedCalls`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: function( data ) { 
							data.statusList = NEWcustomerStatusList();
							data.callTypeList = NEWcallTypeList();
							data.startDate = $( '#startDate' ).val();
						},
					},
					columnDefs: [
						{targets: 'scheduledStartDateTime', data: 'scheduledStartDateTime', className: 'scheduledStartDateTime dt-body-center' },
						{targets: 'callType', data: 'callType', className: 'callType dt-body-center' },
						{targets: 'customerID', data: 'customerID', className: 'customerID', visible: false },
						{targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
						{targets: 'customerStatus', data: 'customerStatus', className: 'customerStatus dt-body-center' },
						{targets: 'callLead', data: 'callLead', className: 'callLead dt-body-left' },
					],
					info: false,
					order: ([ 0, 'desc' ]),
					processing: true,
					rowId: 'callID',
					scrollCollapse: true,
					scrollX: true,
					scrollY: chartHeight - 50,
					scroller: true,
					searching: false,
				});
	
				$( '#missedCalls tbody' ).on( 'click', 'td.customerName', function( event ) {
					event.stopPropagation();
					const currentRow = $( this ).closest( 'tr' );
					const data = $( '#missedCalls' ).DataTable().row( currentRow ).data();
					const customerID = data.customerID;
					location.href = 'customerCalls.asp?id=' + customerID;
				});

				$('#missedCalls tbody').on('click', 'tr', function () {
					const callID = this.id;
					const currentRow = $( this );
					const data = $( '#missedCalls' ).DataTable().row( currentRow ).data();
					const customerID = data[ 'customerID' ];
					location.href = 'annotateCalls.asp?customerID=' + customerID + '&callID=' + callID;
				});
	


				// completed calls...
				$( '#completedCalls' ).DataTable({
					ajax: {
						url: `${apiServer}/api/customerCalls/completedCalls`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: '',
						data: function( data ) { 
							data.statusList = NEWcustomerStatusList();
							data.callTypeList = NEWcallTypeList();
							data.startDate = $( '#startDate' ).val();
							data.endDate = $( '#endDate' ).val();
						},
					},
					columnDefs: [
						{targets: 'scheduledStartDateTime', data: 'scheduledStartDateTime', className: 'scheduledStartDateTime dt-body-center' },
						{targets: 'callType', data: 'callType', className: 'callType dt-body-center' },
						{targets: 'customerID', data: 'customerID', className: 'customerID', visible: false },
						{targets: 'customerName', data: 'customerName', className: 'customerName dt-body-left' },
						{targets: 'customerStatus', data: 'customerStatus', className: 'customerStatus dt-body-center' },
						{targets: 'callLead', data: 'callLead', className: 'callLead dt-body-left' },
					],
					info: false,
					order: ([ 0, 'desc' ]),
					processing: true,
					rowId: 'callID',
					scrollCollapse: true,
					scrollX: true,
					scrollY: chartHeight - 50,
					scroller: true,
					searching: false,
				});
	
				$( '#completedCalls tbody' ).on( 'click', 'td.customerName', function( event ) {
					event.stopPropagation();
					const currentRow = $( this ).closest( 'tr' );
					const data = $( '#completedCalls' ).DataTable().row( currentRow ).data();
					const customerID = data.customerID;
					location.href = 'customerCalls.asp?id=' + customerID;
				});

				$('#completedCalls tbody').on('click', 'tr', function () {
					const callID = this.id;
					const currentRow = $( this );
					const data = $( '#completedCalls' ).DataTable().row( currentRow ).data();
					const customerID = data[ 'customerID' ];
					location.href = 'annotateCalls.asp?customerID=' + customerID + '&callID=' + callID;
				});
	



				$( 'input.customerStatus' ).on( 'click', function() {
					reloadChartsAndDataTables();
				});
				
				$( 'input.callType' ).on( 'click', function() {
					reloadChartsAndDataTables();
				});
				
	

			}); // end of $( function()... )


		}  // end of "buildDashboards"
			


		//================================================================================================ 
		//================================================================================================ 


  </script>

	<style>

		div.controlContainer {
			margin: 15px;
		}
		
		div.alwaysHide {
			display: none;	
		}
		
		div.hideThis {
			display: none;	
		}
		
		div.showThis {
			display: block;	
		}
		
		label.google-visualization-controls-label {
			width: 125px;
		}
		
/*
		.google-visualization-controls-categoryfilter {
			display: table-row;
		}
		
		ul.google-visualization-controls-categoryfilter-selected {
			display: table-row;
		}
		
			ul.google-visualization-controls-categoryfilter-selected.li {
			display: table-cell;
		}
*/

		.ui-checkboxradio-label {
			width: 300px;
			white-space: nowrap;
			text-align: left;
			overflow: hidden;
			text-overflow: ellipsis;
		}
		
		.datePicker {
			display: block;
		}
		
		table {
			width: 90%;
			margin-left: auto;
			margin-right: auto;
		}
		
		.startDate {
			text-align: left;
		}
		
		.endDate {
			text-align: left;
		}
		
		.dataTableTitle {
			font-family: 'Arial';
			font-size: 12px;
			font-weight: 700;
			line-height: 20px;
			margin: 15px 0px 0px 15px;
		}
		
		table tr.missed {
			color: crimson;
		}
		
		th.selectionHeader {
			text-align: left;
			padding-left: 60px;
		}
		
		
	</style>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	

	<div class="mdl-grid">
		<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp">

			<table id="customerStatusList">
				<thead>
					<th class="selectionHeader">Customer Statuses</th>
				</thead>
				<tbody>
				<%
				SQL = "select " &_
							"s.id, " &_
							"s.name, " &_
							"s.selectByDefault, " &_
							"count(*) as custCount " &_
						"from customerStatus s " &_
						"join customer c on (c.customerStatusID = s.id) " &_
						"where (c.deleted = 0 or c.deleted is null) " &_
						"group by s.id, s.name, s.selectByDefault " &_
						"order by s.name  "
				dbug(SQL)
				set rsCS = dataconn.execute(SQL) 
				while not rsCS.eof
					label = rsCS("name") & " (" & rsCS("custCount") & ")"

					if uBound(arrStatusList) >= 0 then 

						if ( valuePresent( rsCS("id"), arrStatusList ) ) then 
							checked = "checked"
						else 
							checked = ""
						end if 

					else 
						
						if rsCS("selectByDefault") then 
							checked = "checked"
						else 
							checked = ""
						end if 

					end if

					%>
					<tr>
						<td>
							<label for="cs-<% =rsCS("id") %>"><% =label %></label>
							<input class="customerStatus" type="checkbox" id="cs-<% =rsCS("id") %>" <% =checked %>>
						</td>
					</tr>
					<%
					rsCS.movenext 
				wend 
				rsCS.close 
				set rsCS = nothing 
				%>
				</tbody>
			</table>
			<br>
			<table id="callTypeList">
				<thead>
					<th class="selectionHeader">Call Types</th>
				</thead>
				<tbody>
				<%
				SQL = "select id, name " &_
						"from customerCallTypes " &_
						"order by name  "
				dbug(SQL)
				set rsCT = dataconn.execute(SQL) 
				while not rsCT.eof
					%>
					<tr>
						<td>
							<label for="ct-<% =rsCT("id") %>"><% =rsCT("name") %></label>
							<input class="callType" type="checkbox" id="ct-<% =rsCT("id") %>" checked>
						</td>
					</tr>
					<%
					rsCT.movenext 
				wend 
				rsCT.close 
				set rsCT = nothing 
				%>
				</tbody>
			</table>
			<br>

			
			<table>
				<tr>
					<th class="startDate">Start Date</th>
					<th class="endDate">End Date</th>
				</tr>
				<tr>
					<%
					SQL = "select " &_
								"format( min( scheduledStartDatetime ), 'MM/dd/yyyy' ) as startDate, " &_
								"format( min( scheduledStartDatetime ), 'yyyy-MM-dd' ) as minEndDate, " &_
								"format( max( scheduledStartDatetime ), 'MM/dd/yyyy' ) as endDate, " &_
								"format( max( scheduledStartDatetime ), 'yyyy-MM-dd' ) as maxStartDate " &_
							"from customerCalls " &_
							"where (deleted = 0 or deleted is null) "
							
					set rsDT = dataconn.execute(SQL) 					
					
					%>
					<td class="startDate"><input id="startDate" type="text" class="datepicker" value="<% =rsDT("startDate") %>" readonly="readonly"></td>
					<td class="endDate"><input id="endDate" type="text" class="datepicker" value="<% =rsDT("endDate") %>" readonly="readonly"></td>
					<%
					rsDT.close 
					set rsDT = nothing 
					%>
				</tr>
			</table>			
			<br>

		</div>

		<div class="mdl-cell mdl-cell--9-col mdl-shadow--2dp">
			<div class="mdl-grid">

				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="timeOfDay_progressbar"></div>
					<div id="timeOfDay"># Calls By Time Of Day</div>
				</div>

				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="dayOfWeek_progressbar"></div>
					<div id="dayOfWeek"># Calls By Day Of Week</div>
				</div>

			</div>

			<div class="mdl-grid">

				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="callDurationCustomer_progressbar"></div>
					<div id="callDurationCustomer">Call Duration By Customer And Call Type</div>
				</div>

				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp">
					<div id="callDurationCallLead_progressbar"></div>
					<div id="callDurationCallLead">Call Duration By Call Lead And Call Type</div>
				</div>

			</div>
		</div>

		<div class="mdl-cell mdl-cell--12-col mdl-shadow--2dp">

			<div class="mdl-grid">
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div class="dataTableTitle">Completed Calls</div>
					<table id="completedCalls" class="compact display" style="width: 100%;">
						<thead>
							<tr>
								<th class="scheduledStartDateTime">Sched. Start</th>
								<th class="callType">Type</th>
								<th class="customerID">Customer ID</th>
								<th class="customerName">Customer Name</th>
								<th class="customerStatus">Status</th>
								<th class="callLead">Call Lead</th>
							</tr>
						</thead>
					</table>
				</div>
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div class="dataTableTitle">Missed Calls</div>
					<table id="missedCalls" class="compact display" style="width: 100%;">
						<thead>
							<tr>
								<th class="scheduledStartDateTime">Sched. Start</th>
								<th class="callType">Type</th>
								<th class="customerID">Customer ID</th>
								<th class="customerName">Customer Name</th>
								<th class="customerStatus">Status</th>
								<th class="callLead">Call Lead</th>
							</tr>
						</thead>
					</table>
				</div>
				<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
					<div class="dataTableTitle">Scheduled Calls</div>
					<table id="scheduledCalls" class="compact display" style="width: 100%;">
						<thead>
							<tr>
								<th class="scheduledStartDateTime">Sched. Start</th>
								<th class="callType">Type</th>
								<th class="customerID">Customer ID</th>
								<th class="customerName">Customer Name</th>
								<th class="customerStatus">Status</th>
								<th class="callLead">Call Lead</th>
							</tr>
						</thead>
					</table>
				</div>
			</div>
		</div>
	</div>


</main>
<!-- #include file="includes/pageFooter.asp" -->
</div><!--end of dashboard -->



</body>

</html>