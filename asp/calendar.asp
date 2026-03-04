<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(26)

userLog("Calendar")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Calendar"


dbug("start of top-logic")


if len(request.querystring("year")) > 0 then 
	currentYear = request.querystring("year")
else 
	currentDate = date()														' system date
	currentDOW = datePart("w",currentDate)								' day of week of currentDate
	currentMonth = datePart("m",currentDate)							' month of currentDate
	currentYear = datePart("yyyy",currentDate)						' year of currentDate
end if 

priorYear = currentYear - 1 
nextYear = currentYear + 1

startOfCurrentYear = cDate("1/1/" & currentYear)				' first date of currentYear
startOrCurrentYearDOW = datePart("w",startOfCurrentYear) 	' day of week of startOfCurrentYear
startDate = dateAdd("d",startOrCurrentYearDOW - 1, startOfCurrentYear)
startMonth = 1

' dbug("currentDate: " & currentDate & "<br>")
' dbug("currentDOW: " & currentDOW & "<br>")
' dbug("currentMonth: " & currentMonth & "<br>")
' dbug("currentYear: " & currentYear & "<br>")
' dbug("startOfCurrentYear: " & startOfCurrentYear & "<br>")
' dbug("startOrCurrentYearDOW: " & startOrCurrentYearDOW & "<br>")


dbug("end of top-logic")
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************


'*******************************************************************************
sub buildAMonth(forMonth)
'*******************************************************************************

	startOfBuildMonth = cDate(forMonth & "/1/" & currentYear)	
	startOfBuildMonthDOW = datePart("w",startOfBuildMonth)
	
	forDay = dateAdd("d",-startOfBuildMonthDOW + 1,startOfBuildMonth)
	dbug("startOfBuildMonth: " & startOfBuildMonth)
	dbug("startOfBuildMonthDOW: " & startOfBuildMonthDOW)
	
	%>
	<table class="calendarMonth mdl-shadow--2dp"> 
		<tr class="calendarMonth">
			<th class="calendarMonth mdl-typography--subheading" colspan="7"><% =monthName(forMonth) %></th>
		</tr>
		<tr class="calendarMonth">
			<th class="calendarMonth">S</th>
			<th class="calendarMonth">M</th>
			<th class="calendarMonth">T</th> 
			<th class="calendarMonth">W</th>
			<th class="calendarMonth">T</th>
			<th class="calendarMonth">F</th>
			<th class="calendarMonth">S</th>
		</tr>
		<% 
		dayOfCalendar = 0
		while dayOfCalendar <= 41
			response.write("<tr class=""calendarMonth"">")
			dayOfWeek = 0
			while dayOfWeek <= 6
				dbug("forDay: " & forDay)
				
				if datePart("m",forDay) = forMonth then 
					
					dayID = datePart("yyyy",forDay) & "-" & right("00" & datePart("m",forDay),2) & "-" & right("00" & datePart("d",forDay),2)
					dbug("dayID: " & dayID)
					className = "date calendarSameMonth"
					
					if cDate(forDay) = date() then 
						className = className & " currentDay"
					end if
					
				else 
					dayID = ""
					className = "calendarDiffMonth"
					onclick = ""
					onhover = ""
				end if
				
				if dayOfWeek = 0 or dayOfWeek = 6 then 
					className = className & " calendarWeekend"
				end if
								
				response.write("<td id=""" & dayID & """ & class=""" & className & """" & ">" & datePart("d",forDay) & "</td>")

				dayOfCalendar = dayOfCalendar + 1
				dayOfWeek = dayOfWeek + 1
				forDay = dateAdd("d",1,forDay)
			wend
			response.write("</tr>")
		wend 
		%>
	</table>
	<%

end sub
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************


%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- #include file="includes/calendarStyling.asp" -->

	<script src="https://cdn.jsdelivr.net/npm/dayjs@1/dayjs.min.js"></script>
	<!-- 1) Load the *UMD* build for v3 (pin exact version) -->



	<script src="https://cdn.jsdelivr.net/npm/date-holidays@3/dist/umd.min.js"></script>
	
	<script>
	
		// Find the real constructor no matter how the UMD wrapped it
		const HolidaysCtor =
			( window.Holidays && ( window.Holidays.default || window.Holidays ) ) ||
			( window.DateHolidays && ( window.DateHolidays.default || window.DateHolidays ) );
		
		if ( typeof HolidaysCtor !== 'function' ) {
			console.error( 'date-holidays v3 UMD loaded but no constructor found:', window.Holidays );
		} else {
			// expose for later code on the page
			window.hd = new HolidaysCtor( 'US' ); // or 'US-MN'
		}
	
	</script>
	
	<script>
	
		// now this works
		const blockedTypes = [ 'public', 'bank' ];
		const currentYear = new Date().getFullYear();
		const holidayList = hd.getHolidays( currentYear );
		const publicHolidays = holidayList
			.filter( h => blockedTypes.includes( h.type ) )
			.map( h => dayjs( h.date ).format( 'YYYY-MM-DD' ) );
	
	</script>


	<script>
		
		$(document).ready( function() {
			
			
// 			$( "input" ).checkboxradio();
// 			$( ".input" ).checkboxradio( "option", "disabled" );
			
			const params = new URLSearchParams(window.location.search);
			let year = params.get( 'year' );
			
			if ( !year ) {
				year = dayjs().year();
			} else {
				year = parseInt(year, 10);
			}


			var dateFormat = 'mm/dd/yy',

				isWorkdayTester = $( '#isWorkdayTester' )
					.datepicker({
						defaultDate: '+1w',
						changeMonth: true,
						changeYear: true,
						onSelect: function(dateText, inst) {

							$.ajax({
								url: `${apiServer}/api/calendar/isWorkday`,
								data: { date: dateText },
								success: function( data ) {
									$( '#isItAWorkDay' ).text( data.isWorkday );
								},
								error: function( err ) {
									console.error( "AJAX Error calling api/calendar/isWorkday", err );
								}
							});

						}

					}),

				workDaysAddDateTester = $( '#workDaysAddDateTester' )
					.datepicker({
						defaultDate: '+1w',
						changeMonth: true,
						changeYear: true,
					}),

				startDate = $( '#startDate' )
					.datepicker({
						defaultDate: '+1w',
						changeMonth: true,
						changeYear: true,
						beforeShowDay: function( date ) {
		
							// Disable weekends: 0 = Sunday, 6 = Saturday							
							if (date.getDay() === 0 || date.getDay() === 6) {
								return [false, "", "Weekends are disabled"];
							}
	
							// Format date with dayjs to "YYYY-MM-DD"
							var formattedDate = dayjs(date).format("YYYY-MM-DD");
							
							// Check if the date is a holiday
							if (publicHolidays.indexOf(formattedDate) !== -1) {
								return [false, "holiday", "Holiday is disabled"];
							}
	
							return [true, ""];
	
						},
						onSelect: function(dateText, inst) {
							var selectedDate = $(this).datepicker('getDate');
							$( '#endDate' ).datepicker('option', 'minDate', selectedDate);
							// Optionally force close:
							$.datepicker._hideDatepicker();					
						},
					}),

				endDate = $( '#endDate' )
					.datepicker({
						defaultDate: '+1w',
						changeMonth: true,
						changeYear: true,
						beforeShowDay: function( date ) {
		
							// Disable weekends: 0 = Sunday, 6 = Saturday							
							if (date.getDay() === 0 || date.getDay() === 6) {
								return [false, "", "Weekends are disabled"];
							}
	
							// Format date with dayjs to "YYYY-MM-DD"
							var formattedDate = dayjs(date).format("YYYY-MM-DD");
							
							// Check if the date is a holiday
							if (publicHolidays.indexOf(formattedDate) !== -1) {
								return [false, "holiday", "Holiday is disabled"];
							}
	
							return [true, ""];
	
						},
						onSelect: function(dateText, inst) {
							var selectedDate = $(this).datepicker('getDate');
							$( '#startDate' ).datepicker('option', 'maxDate', selectedDate);
							// Optionally force close:
							$.datepicker._hideDatepicker();					
						},
					})

			;





			$( '#testWorkDaysAddButton' ).on( 'click', function() {
				
				date = $( '#workDaysAddDateTester' ).val();
				days = $( '#workDaysAddNbrTester' ).val();

				$.ajax({
					url: `${apiServer}/api/calendar/workDaysAdd`,
					data: { 
						date: date,
						days: days
					},
					success: function( data ) {
						$( '#newDate' ).text( dayjs( data.newDate ).format( 'M/D/YYYY' ) );
					},
					error: function( err ) {
						console.error( "AJAX Error calling api/calendar/workDaysAdd", err );
					}
				});

			});


			$( '#testDaysBetween' ).on( 'click', function() {
				
				startDate = $( '#startDate' ).val();
				endDate = $( '#endDate' ).val();

				$.ajax({
					url: `${apiServer}/api/calendar/workDaysBetweenv2`,
					data: { 
						startDate: startDate,
						endDate: endDate
					},
					success: function( data ) {
						$( '#daysBetween' ).text( data.daysBetween);
					},
					error: function( err ) {
						console.error( "AJAX Error calling api/calendar/workDaysBetweenv2", err );
					}
				});

			});




			//-------------------------------------------------------------------------------------
			// HOLIDAYS -- highlight days that are public holidays
			//-------------------------------------------------------------------------------------
			$.ajax({
				url: `${apiServer}/api/calendar/holidays`,
				data: { year: year },
				success: function( data ) {
					for ( let item of data ) {
						$( '#'+item.date ).css( 'color', 'red' );
					}
				},
				error: function( err ) {
					console.error( "AJAX Error calling api/calendar/holidays", err );
				}
			});
			//-------------------------------------------------------------------------------------

			
			//-------------------------------------------------------------------------------------
			$( '.date' ).on( 'click', function(e){

				$( "#progressbar" ).progressbar({
					value: false
				});
				$( '#displayDate' ).text( '' );
				$( '#yearNo' ).text( '' );
				$( '#monthNo' ).text( '' );
				$( '#monthName' ).text( '' );
				$( '#weekNo' ).text( '' );
				$( '#dayOfMonth' ).text( '' );
				$( '#dayOfWeekNo' ).text( '' );
				$( '#dayOfWeekName' ).text( '' );
				$( '#dayNo' ).text( '' );
				$( '#isWeekday' ).prop('checked', false );
				$( '#isUSHoliday' ).prop('checked', false );
				$( '#holidayName' ).text( '' );
				$( '#holidayType' ).text( '' );
						
				$.ajax({
					url: `${apiServer}/api/calendar/date-info`,
					data: { date: this.id }
				}).done( function( data ) {
					
					const calendarDate = dayjs( data.date );
				
					$( '#displayDate' ).text( calendarDate.format( 'M/D/YYYY' ) );
					$( '#yearNo' ).text( calendarDate.year() );
					$( '#monthNo' ).text( calendarDate.month() );
					$( '#monthName' ).text( data.monthName );
					$( '#weekNo' ).text( data.weekNumber );
					$( '#dayOfMonth' ).text( data.dayOfMonth );
					$( '#dayOfWeekNo' ).text( data.dayOfWeek );
					$( '#dayOfWeekName' ).text( data.dayOfWeekName );
					$( '#dayNo' ).text( data.dayOfYear );
					
					if ( data.isWeekday ) {
						$( '#isWeekday' ).prop('checked', true );
					} else {
						$( '#isWeekday' ).prop('checked', false );
					}
					
					if ( data.isWorkday ) {
						$( '#isWorkday' ).prop('checked', true );
					} else {
						$( '#isWorkday' ).prop('checked', false );
					}
					
					if ( data.isUSHoliday ) {
						$( '#isUSHoliday' ).prop('checked', true );
					} else {
						$( '#isUSHoliday' ).prop('checked', false );
					}
					
					if ( data.holidayDetails.length > 0 ) {
						$( '#holidayName' ).text( 'Holiday Name: ' + data.holidayDetails[0].name );
// 						$( '#holidayType' ).text( 'Holiday Type: ' + data.holidayDetails[0].type );
						$('#holidayType').text(
							'Holiday Types: ' + data.holidayDetails.map( h => h.type ).join(', ')
						);
					} else {
						$( '#holidayName' ).text( '' );
						$( '#holidayType' ).text( '' );
					}
											
				}).fail( function( err ) {
					console.error( 'AJAX Error calling api/calendar/date-info', err );
				}).always( function() {
					$( "#progressbar" ).progressbar( "destroy" );
				});

			});
			//-------------------------------------------------------------------------------------


		});
		
	</script>
	
</head>

<body>



<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->


	<main class="mdl-layout__content">
		<div class="page-content">
			<!-- Your content goes here -->


			<div class="mdl-snackbar mdl-js-snackbar">
			    <div class="mdl-snackbar__text"></div>
			    <button type="button" class="mdl-snackbar__action"></button>
			</div>
				

			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--9-col">
					

					<% firstTime = true %>
					<table class="calendarYear" style="margin-left: auto; margin-right: auto;">
						<tr>
							<td colspan="4" align="center" class="mdl-typography--display-1">
								<a href="calendar.asp?year=<% =datePart("yyyy",date()) %>"><img src="images/ic_today_black_24dp_2x.png"></a>
								<a href="calendar.asp?year=<% =priorYear %>"><img src="images/ic_chevron_left_black_24dp_2x.png"></a>
								<% =currentYear %>
								<a href="calendar.asp?year=<% =nextYear %>"><img src="images/ic_chevron_right_black_24dp_2x.png"></a>
							</td>
							<td align="center" class="mdl-typography--display-1" >
								Details
							</td>
						</tr>
						<% buildMonth = startMonth %>
						<% for q = 1 to 3 %>
							<tr class="calendarYear">
								
								<% for m = 1 to 4 %>
								<td class="calendarYear">
																			
									<% 
									buildAMonth(buildMonth) 
									buildMonth = buildMonth + 1 
									%>
										
								</td>
								<% next %>
								
								<% if firstTime then %>
									<td id="dateDetails" rowspan="4" valign="top" class="mdl-shadow--2dp">
										
										<div id="container" style="position: relative;">

											<div id="progressbar"></div>

											<table class="calendarYear" style="width: 400px;">
												<tr><td nowrap="nowrap">Date:</td><td id="displayDate" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Year:</td><td id="yearNo" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Quarter:</td><td id="quarterNo" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Month No:</td><td id="monthNo" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Month Name:</td><td id="monthName" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Week No:</td><td id="weekNo" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Day Of Month:</td><td id="dayOfMonth" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Day Of Week No:</td><td id="dayOfWeekNo" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Day Of Week Name:</td><td id="dayOfWeekName" nowrap="nowrap"></td></tr>										
												<tr><td nowrap="nowrap">Day Of Year:</td><td id="dayNo" nowrap="nowrap"></td></tr>										
												<tr>
													<td nowrap="nowrap" colspan="2">
														<input type="checkbox" name="isWeekday" id="isWeekday">
														<label for="isWeekday">Weekday?</label>
													</td>
												</tr>		
												<tr>
													<td nowrap="nowrap" colspan="2">
														<input type="checkbox" name="isWorkday" id="isWorkday">
														<label for="isWorkday">Workday?</label>
													</td>
												</tr>		
												<tr>
													<td nowrap="nowrap" colspan="2">
														<input type="checkbox" name="isUSHoliday" id="isUSHoliday">
														<label for="isUSHoliday">US Holiday?</label>
													</td>
												</tr>	
												<tr id="holidayDetails">
													<td nowrap="nowrap" colspan="2">
														<div id="holidayName"></div>
														<div id="holidayType"></div>
													</td>
												</tr>
												
											</table>	

											<br>
											<hr>
											<br>
											<div>
												<div>
													<label for="isWorkdayTester">Test isWorkday</label>
													<input style="width: 75px;" type="text" name="isWorkdayTester" id="isWorkdayTester" class="ui-widget-content ui-corner-all" />
												</div>
												<span>is it a workday?</span>
												<span id="isItAWorkDay"></span>
											</div>
											<br><br>
											<div>
												<div>
													<label for="workDaysAddTester">Test workDaysAddv2</label>
													<input style="width: 75px;" type="text" name="workDaysAddDateTester" id="workDaysAddDateTester" class="ui-widget-content ui-corner-all" />
													<input style="width: 30px;" type="text" name="workDaysAddNbrTester" id="workDaysAddNbrTester" class="ui-widget-content ui-corner-all" />
													<button id="testWorkDaysAddButton">Test</button>
												</div>
												<span>New Date:</span>
												<span id="newDate"></span>
											</div>
										
											<br><br>
											<div>
												<div>
													<label for="startDate">Start Date</label>
													<input style="width: 75px;" type="text" name="startDate" id="startDate" class="ui-widget-content ui-corner-all" />
													<label for="endDate">End Date</label>
													<input style="width: 75px;" type="text" name="endDate" id="endDate" class="ui-widget-content ui-corner-all" />
													<button id="testDaysBetween">Test</button>
												</div>
												<span>Work Days Between:</span>
												<span id="daysBetween"></span>
											</div>

										</div>
<!--
										<div style="text-align: center; padding: 20px;">
											<button id="edit-date" style="margin: auto;">Edit Date</button>
										</div>
-->
															
									</td>
									<%  firstTime = false %>
								<% end if %>
									
								
							</tr>
						<% next %>
					</table>							


				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
		</div>
	</main>
<!-- #include file="includes/pageFooter.asp" -->
<%
dataconn.close 
set dataconn = nothing
%>


</body>
</html>