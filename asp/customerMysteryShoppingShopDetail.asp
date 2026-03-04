<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/dateValidationPattern.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="includes/jsonDataTable.asp" -->
<!-- #include file="includes/jsonDataArray.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(139)


dbug(" ")
userLog("Customer Mystery Shopping")

customerID 	= request.querystring("customerID")
locationID 	= request.querystring("locationID")
shopID		= request.querystring("shopID")

%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

chartEndDate = date()
chartStartDate = dateAdd("yyyy",-2,chartEndDate)
dbug("chartStartDate: " & chartStartDate & ", chartEndDate: " & chartEndDate)


'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

dbug("before top-logic")

if len(request.querystring("customerID")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("customerID")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

chartHeight = 200

dbug("systemControls('Number of months shown on Customer Overview charts'): " & systemControls("Number of months shown on Customer Overview charts"))
if systemControls("Number of months shown on Customer Overview charts") = "" then
	monthsOnCharts = 12
else 
	monthsOnCharts = trim(systemControls("Number of months shown on Customer Overview charts"))
end if
dbug("monthsOnCharts: " & monthsOnCharts)

hAxisFormat = "yyyy"


'***************************************************************************************************

tempDate = dateAdd("yyyy", -1, date())
dbug("tempDate: " & tempDate)
startYear = year(tempDate)
startMonth = month(tempDate)
startDay = day(tempDate)
startDate = dateSerial(startYear, startMonth, 1)

endDate = date()
' endDate = dateSerial(2018, 11, 4)	' for testing only

dbug("startDate: " & startDate & ", endDate: " & endDate)

%>


<html>

<head>

	<!-- #include file="includes/cNoteGlobalStyling.asp" -->

	<!-- #include file="includes/cNoteGlobalScripting.asp" -->

			
	<script type="text/javascript">
			
		const customerID	= '<% =customerID %>';
		const locationID	= '<% =locationID %>';
		const shopID		= '<% =shopID %>';
		const sessionJWT	= '<% =sessionJWT %>';
		
		//====================================================================================
		function getLocationDetail( locationID ) {
		//====================================================================================

			// get info for location "header"
			$.ajax({
				url: `${apiServer}/api/mysteryShopping/locations/${locationID}`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
			}).then( function( response ) {

				$( 'td.locationID' ).html( response.locationID );
				$( 'td.name' ).html( response.name );
				$( 'td.address' ).html( response.address );
				$( 'td.city' ).html( response.city );
				$( 'td.state' ).html( response.stateAbbreviation );
				$( 'td.zipCode' ).html( response.zipCode );
				$( 'td.phoneNumber' ).html( response.phoneNumber );
				$( 'td.grouperRegion' ).html( response.grouperRegion );
				$( 'td.grouperDistrict' ).html( response.grouperDistrict );
				$( 'td.grouperArea' ).html( response.grouperArea );
				$( 'td.bankerName' ).html( response.bankerName );
				$( 'td.bankerTitle' ).html( response.bankerTitle );
				$( 'td.bankName' ).html( response.bankName );
				$( 'td.bankerFirstName' ).html( response.bankerFirstName );
				$( 'td.bankerLastName' ).html( response.bankerLastName );


				if ( response.notesForShopper ) {
					let shopperDoc =  new DOMParser().parseFromString( response.notesForShopper, 'text/html');
					let notesForShopper = shopperDoc.body.textContent || '';
					$( 'td.notesForShopper' ).html( notesForShopper );
				} else {
					$( 'td.notesForShopper' ).closest( 'tr' ).remove();
				}
				
				if ( response.notesForCoordinator ) {
					let coordinatorDoc =  new DOMParser().parseFromString( response.notesForCoordinator, 'text/html');
					let notesForShopper = coordinatorDoc.body.textContent || '';
					$( 'td.notesForCoordinator' ).html( notesForCoordinator );
				} else {
					$( 'td.notesForCoordinator' ).closest( 'tr' ).remove();
				}				
				

			}).fail( function( req, status, err ) {
				console.error( `Something went wrong (${status}) in api/mysteryShopping/locations/:locationID, please contact your system administrator.` );
				throw new Error( err );
			});

			
		}
		//====================================================================================


				
		//====================================================================================
		$( function() {
		//====================================================================================
			
			$( document ).tooltip();
			
			// get info for shop detail
			$.ajax({
				url: `${apiServer}/api/mysteryShopping/shops/${shopID}`,
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
			}).then( function( response ) {

				getLocationDetail( response.locationID );
				
				const sectionScores = JSON.parse( response.sectionScores );
				let htmlSectionScores = '';
				for ( sectionScore of sectionScores ) {
					htmlSectionScores += `<div class="overallScore">Overall Score: ${sectionScore.Score} (${sectionScore.ScorePoints})</div><br>`
				}
				$( '.sectionScores' ).html( htmlSectionScores );

				const sections = JSON.parse( response.sections );
				let htmlSections = '';
				let shopDate, shopTime, shopTimeZone;

				for ( section of sections ) {
					

					htmlSections += `<table class="section">`;
					htmlSections += 	`<thead>`;
					htmlSections += 		`<tr>`;
					htmlSections += 			`<th class="sectionHeader" colspan="2"><span class="sectionName">${section.Name}</span> -- <span class="sectionScore">${section.Score} (${section.ScorePoints})</span></th>`;
					htmlSections += 		`</tr>`;
					htmlSections += 	`</thead>`;
					htmlSections += 	`<body>`;


					for ( question of section.Questions ) {
						
						

						// The "recordedQuestions" array contains all known "questions" that indicate a voice-recording of the call is present.
						// This array is subsequently checked using .includes() 
						const recordedQuestions = [ 
							'Recorded phone call (wav or mp3 format)', 
							'Upload the audio file of your recording (wav or mp3 format preferred)' 
						]
						if ( recordedQuestions.includes( question.Question ) ) {
								question.Answer = `<audio id="recording" controls>
														 	 <source src="${question.Answer}" type="audio/mpeg">
														 </audio>`
						}

						
						if ( question.Question == 'Date [mm/dd/yyyy]' ) {
							shopDate = question.Answer;
							continue;
						}
						
						if ( question.Question == 'Time [hh:mm:ss AM/PM]' ) {
							shopTime = question.Answer;
							continue;
						}
						
						if ( question.Question == 'Time Zone' ) {
							shopTimeZone = question.Answer;
							continue;
						}

						if ( question.Question == 'Date and time of Unsuccessful Call(s) (N/A if not applicable)' ) {
							question.Answer = question.Answer.replace( /\r\n/g, '<br>' )

						}
						
// 						console.log({ question: question.Question });
						if ( question.Question != 'Mark N/A and skip this section if the call is not completed in 5 attempts' ) {
// 							console.log( 'checking answer...' );
							if ( question.Answer.toLowerCase() == 'yes' ) {
								question.Answer = `<span class="material-icons" style="color: green;">check</span>`;	
							} else if ( question.Answer.toLowerCase() == 'no' ) {
								question.Answer = `<span class="material-icons" style="color: crimson;">close</span>`;	
							} 
							
						}
						
						if ( question.Answer.toLowerCase() == 'n/a' ) {
							question.Answer = 'N/A'
						}

						htmlSections += 	`<tr>`;
						htmlSections += 		`<td class="question">${question.Question}</td>`;
						htmlSections += 		`<td class="answer">${question.Answer}</td>`;
						htmlSections += 	`</tr>`;

					}

	
					htmlSections += 	`</body>`;
					htmlSections += `</table><br><br>`;
					
				}
			

				
				$( '.sections' ).html( htmlSections )
				
				
				// prepend the date and time info...
				if ( shopDate && shopTime ) {
					let shopDateTime = `<tr>
													<td class="question">Date and time</td>
													<td class="answer">${shopDate}  ${shopTime} ${ shopTimeZone}</td>
											  </tr>`;
					
					$( '#shopDetail > tbody > tr > td > table:nth-child(1) > tbody > tr:nth-child(1)' ).before( shopDateTime );
				}
				

			}).fail( function( req, status, err ) {
				console.error( `Something went wrong (${status}) in api/mysteryShopping/shops/:shopID, please contact your system administrator.` );
				throw new Error( err );
			});

						
														
		});
		//====================================================================================

			
	</script>		 

	<style>
		/* prevent Google Chart Tooltips from flashing... */
		svg > g:last-child > g:last-child { pointer-events: none }
		div.google-visualization-tooltip { pointer-events: none }

		#tgim_progressbar .ui-progressbar-value {
			background-color: #ccc;
		}
	
		#projectSummary.dataTable > tbody > tr:hover {
			cursor: pointer;
		}
		
		.page-content {
			padding-top: 1rem;
		}
		
		.accordian {
			margin-left: 1rem;
			margin-right: 1rem;
		}
		
		h3.ui-accordion-header {
			padding-top: 0rem !important;
			padding-bottom: 0rem !important;
		}
		
		div.ui-accordion-content {
			padding-left: 1rem !important;
			padding-right: 1rem !important;
		}
		
		span.peerGroupType {
			float: right;
			vertical-align: middle;
		}

		#locationDetail {
			margin-left: auto;
			margin-right: auto;			
		}
		
		#locationDetail th {
			text-align: left;
			white-space: nowrap; 
		}
		
		#locationDetail td {
			padding-right: 15px;
		}
		
		table.section {
			table-layout: fixed;
			width: 100%;
			border-collapse: collapse;
		}
		
		table.section td {
			border: solid rgba(72, 71, 71, 0.27) 1px;
			padding: 5px;
		}
		
		table.section tbody tr:nth-child(odd) {
			background-color: #f1f1f1;
		}
		
	</style>
	


</head>

<body>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
		
		<!-- #include file="includes/mdlLayoutNavLarge.asp" -->

    </div>
    
    
<!-- #include file="includes/customerTabs.asp" -->


  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer Mystery Shopping</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>
		
	
		<div class="page-content">
			<!-- Your content goes here -->
			
		<!-- Primary Grid & DataTable -->
   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--7-col">
			   
				<table id="locationDetail">
					
					<tr>
						<th>Banker:</th><td class="bankerName"></td>
						<th>&nbsp;</th>
						<th>Title:</th><td class="bankerTitle"></td>
						<th>&nbsp;</th>
						<th>Branch:</th><td class="grouperDistrict"></td>
						<th>&nbsp;</th>
						<th>Supervisor:</th><td class="grouperArea"></td>
					</tr>
					<tr>
						<th>Shopper Notes:</th><td class="notesForShopper" colspan="11"></td>
					</tr>
					<tr>
						<th>Coordinator Notes:</th><td class="notesForCoordinator" colspan="11"></td>
					</tr>
				</table>
				   
					   
			   
		   </div>

			<div class="mdl-layout-spacer"></div>

	   </div>
	   
	   
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--9-col">
			
				<table id="shopDetail">
					<thead>
						<tr>
							<th class="sectionScores"></th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td class="sections"></td>
						</tr>
					</tbody>
				</table>
				
			</div>

			<div class="mdl-layout-spacer"></div>
			
   	</div>
	
    
  </main>

	<!-- #include file="includes/pageFooter.asp" -->
	
</div>



<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>