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
call checkPageAccess(131)


dbug(" ")
userLog("customer KPIs")

customerID = request.querystring("id")
SQL = "select lsvtCustomerName from customer where id = " & customerID & " "
set rsLSVT = dataconn.execute(SQL)
if not rsLSVT.eof then 
	lsvtCustomerName = rsLSVT("lsvtCustomerName") 
else 
	lsvtCustomerName = ""
end if 
rsLSVT.close 
set rsLSVT = nothing 

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

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
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

	<!-- #include file="includes/globalHead.asp" -->
	<!-- #include file="includes/cNoteGlobalScripting.asp" -->

			
	<script type="text/javascript">
			
		const lsvtCustomerName 	= '<% =lsvtCustomerName %>';
		const customerID			= '<% =customerID %>';

		const kpis = [
			
			{ id:  40,	title: 'Assets Per Employee ($Million)', 														usesPGT: true, 	annChg: false },
			{ id:  51, 	title: 'Core Deposits ($Thousand)', 															usesPGT: false, 	annChg: false },
			{ id:  52,	title: 'Core Deposits annual change', 															usesPGT: false, 	annChg: false },
			{ id:  59,	title: 'Domestic Demand Deposits as a percent of Total Deposits', 					usesPGT: true, 	annChg: false },
			{ id:  62, 	title: 'Efficiency Ratio', 																		usesPGT: true, 	annChg: false },
			{ id:  67, 	title: 'Interest Expense as a percent of Average Assets', 								usesPGT: true, 	annChg: false },
			{ id:	 70, 	title: 'Interest Income (TE) as a percent of Average Earning Assets', 				usesPGT: true, 	annChg: false },

			{ id:	 73, 	title: 'Net Income ($Thousand)', 																usesPGT: false, 	annChg: true },

			{ id:  78, 	title: 'Net Loans & Leases as a percent of Core Deposits', 								usesPGT: true, 	annChg: false },
			{ id:  79,	title: 'Net Loans & Leases as a percent of Total Deposits', 							usesPGT: true, 	annChg: false },
			{ id:  85,	title: 'NIM - Net Interest Income (TE) as a percent of Average Earning Assets', 	usesPGT: true, 	annChg: false },
			{ id:  98,	title: 'ROA - Net Income as a percent of Average Assets', 								usesPGT: true, 	annChg: false },
			{ id: 105, 	title: 'Total Assets ($Thousand)', 																usesPGT: false, 	annChg: false },
			{ id: 107,	title: 'Total Deposits ($Thousand)', 															usesPGT: false, 	annChg: false },
			{ id: 108,	title: 'Total Deposits annual change', 														usesPGT: false, 	annChg: false },
			{ id: 147,	title: 'ROE - Return on Equity', 																usesPGT: true, 	annChg: false },
// 			{ id: 149,	title: 'Fed Home Loan Bor Mat < 1 Year', 														usesPGT: true, 	annChg: false },
// 			{ id: 150,	title: 'Fed Home Loan Bor Mat > 1 Year', 														usesPGT: false, 	annChg: false },
// 			{ id: 151,	title: 'Fed Home Loan Bor Mat < 1 Year - annual change', 								usesPGT: false, 	annChg: false },
// 			{ id: 152,	title: 'Fed Home Loan Bor Mat > 1 Year - annual change', 								usesPGT: false, 	annChg: false },
			{ id: 153,	title: 'Provision for Credit Losses on all Other Assets', 								usesPGT: false, 	annChg: false },
			{ id: 154,	title: 'Provision for Loan & Lease Losses - annual change', 							usesPGT: false, 	annChg: false },
			{ id: 155,	title: 'Provision for Credit Losses on all Other Assets - annual change', 			usesPGT: false, 	annChg: false },
			{ id: 156, 	title: 'Provision for Loan & Lease Losses', 													usesPGT: false, 	annChg: false },

			{ id: 157, 	title: 'Federal Funds Purch & Repos as a percent of Average Assets', 				usesPGT: true, 	annChg: false },
			{ id: 158, 	title: 'Total Fed Home Loan Borrowings as a percent of Avg Assets', 					usesPGT: true, 	annChg: false },
			{ id: 63, 	title: 'Fully Insured Brokered Deposits as a percent of Average Assets', 			usesPGT: true, 	annChg: false },

		]


		
		google.charts.load('current', {'packages':['corechart','gantt']});
		
		google.charts.setOnLoadCallback(drawCharts);
		
		
		//================================================================================================ 
		function drawSingleChart( kpi ) {
		//================================================================================================ 

			return new Promise( (resolve, reject) => {

				const colorPrimary 		= '#512DA8';  		// purple-ish
				const colorSecondary 	= '#F52C2C';		// red-ish
				const colorTertiary		= '#20B256';		// green-ish
				
				const metricSelector			= 'metric'+kpi.id;
				const progressBarSelector	= '#metric'+kpi.id+'_progressbar';
				
				const peerGroupType = $( '#peerGroupType' ).val();
				
							
			
				$.ajax({
					beforeSend: function() {
						$( progressBarSelector ).progressbar({ value: false });
					},
					url: `${apiServer}/api/metrics/chartCustomerFDICMetric`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					data: { 
						customerID: customerID, 
						metricID: kpi.id,
						peerGroupType: peerGroupType,
						usesPGT: kpi.usesPGT,
						annChg: kpi.annChg
					 },
					success: function( data ) {
						let chartAssets = new google.visualization.ScatterChart(document.getElementById( metricSelector ));
						let dataAssets = new google.visualization.DataTable( data );
						chartAssets.draw( dataAssets, {
							explorer: 	tgim_explorer,
				         hAxis: 		tgim_hAxis,
				         vAxes:		{ 
								0: { title: "Bank & PG" },
								1: { title: 'PG Percentile', maxValue: 100, textStyle: {color: colorPrimary}, titleTextStyle: {color: colorPrimary } }
							},
							legend: 		{ position: 'top' },
							series: 		{ 
								0: { type: "line", color: colorTertiary, targetAxisIndex: 0 },
								1: { type: 'line', color: colorSecondary, targetAxisIndex: 0 },
								2: { type: 'bars', dataOpacity: .5, color: colorPrimary, targetAxisIndex: 1 }
							},
				         lineWidth: 	tgim_lineWidth,
							pointSize: 	tgim_pointSize,
							title: 		kpi.title,
							tooltip: { isHtml: true }
						});
						$( progressBarSelector ).progressbar( 'destroy' );
						return resolve();
					},
					error: function( err ) {
						$( progressBarSelector ).progressbar( 'destroy' );
						$(' #metric'+kpi.id ).text( err.status + ' (' + err.responseText + ') ' );
						return reject();
					}
				});

			});

		}
				
		
		//================================================================================================ 
		function drawCharts() {
		//================================================================================================ 

			$( function() {
				
				$( '.accordian' ).accordion({
					collapsible: true,
					heightStyle: 'content'
				});
	
				$( document ).tooltip();
				
				$( "#peerGroupType" ).selectmenu({
					position: { my: 'right top', at: 'right bottom' },
					width: 300,
					open: function ( event, ui ) {
						event.stopPropagation();
					},
					change: function ( event, ui ) {
						event.stopPropagation();
						var pgtKPIs = kpis.filter( function( el ) {
							return el.usesPGT == true
						});
						for ( kpi of pgtKPIs ) {
							$( '#metric'+kpi.id).html( '' );
							drawSingleChart( kpi );
						}
					},
					close: function ( event, ui ) {
						event.stopPropagation();
					}
				});
				
			
	// 			alert('start of drawCharts');
	
				var chartMaxDate 				= dayjs().toDate();
				var chartMinDate 				= dayjs().add( -<% =monthsOnCharts %>, 'months').toDate();
				var chartExplorerMinDate 	= dayjs().add( -10, 'years' ).toDate();
				const colorPrimary 		= '#512DA8'  	// purple-ish
				const colorSecondary 	= '#F52C2C'		// red-ish
				const colorTertiary		= '#20B256'		// green-ish
				
			
				tgim_explorer = {
					axis: 'horizontal',
					keenInBounds: true,
					maxZoomIn: 7,
					zoomDelta: 1.1,
				}
				
				tgim_hAxis = {
					format: "<% =hAxisFormat %>",
					minorGridlines: {count: 0},
	         	viewWindow: {
		         	min: chartMinDate,
		         	max: chartMaxDate,
		         },
				}
	
	         tgim_lineWidth = 3
				tgim_pointSize = 3,
				
				tgim_vAxis = {
			      viewWindow: {min: 0, max:100},
			   }
			   
			   tgim_legend = {
				   position: 'none'
				}
														
				
				const timer = ms => new Promise(res => setTimeout(res, ms))


				for ( kpi of kpis ) {
					
					drawSingleChart( kpi )
					.then( kpi => {
						console.log( kpi );
					})
					.catch( err => {
						console.error( `Unexpected error: ${err}` );
					})
						
				}			


				// get customer Last FFIEC Update...
				$.ajax({
					url: `${apiServer}/api/customers/latestFinancials/${customerID}`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
				})
				.done( result => {
					
					$( '#lastUpdate' ).html( result.maxDate );
					$( '#lastUpdateSource' ).html( result.source );
					$( '#totalAssets' ).html( result.totalAssets );
					$( '#totalROA' ).html( result.totalROA );
					$( '#totalNIM' ).html( result.totalNIM );
										
				})
				.fail( error => {
					log.error( 'unexpected error while getting Last FFIEC Update...' );
					log.error( err )
				});

				
							
															
			});
			
		}
		
		window.onload = function() {
			if ( document.getElementById('mdl-spinner') ) {
				document.getElementById('mdl-spinner').classList.remove('is-active');	
			}
		}
				
	</script>		 

	<style>
		/* precent Google Chart Tooltips from flashing... */
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
		<span class="mdl-layout-title">Customer View</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="mdl-snackbar mdl-js-snackbar">
			<div class="mdl-snackbar__text"></div>
			<button type="button" class="mdl-snackbar__action"></button>
		</div>
		
	
		<div class="page-content">
			<!-- Your content goes here -->
			
			
			

			<!-- Customer Info -->

			<%
			SQL = "select " &_
						"i.name as instName, " &_
						"i.cert as instCert, " &_
						"i.fed_rssd as instRssdId, " &_
						"i.address as instAddress, " &_
						"i.city as instCity, " &_
						"i.stname as instState, " &_
						"i.asset as instAsset, " &_
						"i.dep as instDeposit, " &_
						"i.eq as instEquity, " &_
						"i.dateupdt instLastUpdate, " &_
						"i.inscoml, " &_
						"i.inssave, " &_
						"i.mutual, " &_
						"c.validDomains " &_
					"from customer_view c " &_
					"left join fdic.dbo.institutions i on i.cert = c.cert " &_
					"where c.id = " & customerID & " " 
			set rsInfo = dataconn.execute(SQL)
			if not rsInfo.eof then 
				instName 			= rsInfo("instName")
				instCert 			= rsInfo("instCert")
				instRssdId 			= rsInfo("instRssdId")
				instAddress 		= rsInfo("instAddress")
				instCity 			= rsInfo("instCity")
				instState 			= rsInfo("instState")

				if not isNull(rsInfo("instAsset")) then 
					instAsset 		= formatCurrency(rsInfo("instAsset"),0) 
				else 
					instAsset		= ""
				end if 
				
				if not isNull(rsInfo("instDeposit")) then 
					instDeposit 	= formatCurrency(rsInfo("instDeposit"),0)
				else 
					instDepoist		= ""
				end if
				
				if not isNull(rsInfo("instEquity")) then 
					instEquity 		= formatCurrency(rsInfo("instEquity"),0) 
				else 
					instEquity		= ""
				end if
				if not isNull(rsInfo("instLastUpdate")) then 
					instLastUpdate		= formatDatetime(rsInfo("instLastUpdate"),2)
				end if
				validDomains		= rsInfo("validDomains")
				
				dbug( "INSCOML: " & rsInfo("INSCOML") & ", INSSAVE: " & rsInfo("INSSAVE") & ", MUTUAL: " & rsInfo("MUTUAL") )
				if rsInfo("INSCOML") = "1" then 
					defaultPeerGroupType = 1					' Insured Commercial Bank (by peer group)
				else 
					if rsInfo("INSSAVE") = "1" then 
' 						if rsInfo("MUTUAL") = "00000" then 
						if rsInfo("MUTUAL") = "0" then 
							defaultPeerGroupType = 2			' Insured Savings Banks (by peer group)
						else 
' 							if rsInfo("MUTUAL") = "00001" then 
							if rsInfo("MUTUAL") = "1" then 
								defaultPeerGroupType = 6		' Supplemental Insured Saving Banks
							else 
								defaultPeerGroupType = ""
							end if 
						end if 
					else 
						defaultPeerGroupType = ""
					end if 
				end if
				dbug("defaultPeerGroupType: " & defaultPeerGroupType )
				
				
				
			else 
				instName 				= ""
				instCert 				= ""
				instRssdId 				= ""
				instAddress 			= ""
				instCity 				= ""
				instState 				= ""
				instAsset 				= ""
				instDeposit 			= ""
				instEquity 				= ""
				instLastUpdate 		= ""
				validDomains			= ""
				defaultPeerGroupType = ""

			end if
			rsInfo.close 
			set rsInfo = nothing
			%>


			<!-- Customer Info  -->
			<div class="accordian">
				<h3>
					<span>Info for:&nbsp;<% =customerTitle(customerID) %></span>
					<span class="peerGroupType" title="The selected peer group type will be used for all applicable charts">
						<label for="peerGroupType">Peer Group Type:</label>
						<select id="peerGroupType">
							<%
							SQL = "select distinct pgt.id, pgt.[description] " &_
									"from fdic_ranks.dbo.SummaryRatios k " &_
									"join fdic.dbo.peerGroup pg on (pg.id = k.[peer group]) " &_
									"join fdic.dbo.peerGroupType pgt on (pgt.id = pg.peerGroupType) " &_
									"where k.[id rssd] = " & instRssdId & " " &_
									"order by pgt.[description] "
							dbug(SQL)
							set rsPGT = dataconn.execute(SQL) 
							while not rsPGT.eof 
								dbug( "about to compare rsPGT('id'): " & rsPGT("id") & " to defaultPeerGroupType: " & defaultPeerGroupType )
								if cInt(rsPGT("id")) = cInt(defaultPeerGroupType) then 
									selected = "selected" 
								else 
									selected = ""
								end if
								%>
								<option value="<% =rsPGT("id") %>" <% =selected %>><% =rsPGT("description") %></option>
								<%
								rsPGT.movenext 
							wend 
							rsPGT.close 
							set rsPGT = nothing 
							%>
						</select>
					</span>
				</h3>	
		
				<!-- 	Customer Info		 -->
				<div class="mdl-grid">
	
					<div class="mdl-layout-spacer"></div>
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
						<table>
							<tr>
								<th style="text-align: left;">FDIC Name:</th><td colspan="3"><% =instName %></td>
							</tr>
							<tr>
								<th style="text-align: left; vertical-align: top;">Address:</th><td colspan="3"><% =instAddress %><br><% =instCity %>, <% =instState %></td>
							</tr>
						</table>
					</div>
	
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
						<table>
							<tr>
								<th style="text-align: left;">Cert:</th><td><% =instCert %></td>
							</tr>
							<tr>
								<th style="text-align: left;">RSSD ID:</th><td><% =instRssdId %></td>
							</tr>
							<tr>
								<th style="text-align: left;">Domains:</th><td colspan="3"><% =validDomains %></td>
							</tr>
						</table>
					</div>
	
	
					<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp" align="center">
						<%
						SQL = "select max( cast( [reporting period] as date ) ) as maxDate " &_
								"from fdic_ratios.dbo.BalanceSheetDollar r " &_
								"join customer c ON ( c.rssdID = r.[ID RSSD] ) " &_
								"where c.id = " & customerID & " "
						dbug("SQL: " & SQL) 
						set rsMD = dataconn.execute(SQL) 
						if not rsMD.eof then 
							maxDate = rsMD("maxDate") 
							
							SQL1= "SELECT UBPR2170 as totalAssets " &_
									"FROM fdic_ratios.dbo.BalanceSheetDollar r " &_
									"JOIN customer c ON ( c.rssdID = r.[ID RSSD] ) " &_
									"where cast([reporting period] as date) = '" & maxDate & "' " &_
									"and c.id = " & customerID & " "
	
	
							dbug("SQL1: " & SQL1)
							
							set rsTA = dataconn.execute(SQL1) 
							if not rsTA.eof then 
								if not isNull( rsTA("totalAssets") ) then 
									totalAssets = formatCurrency( rsTA("totalAssets"), 0 )
								else 
									totalAssets = "$0"
								end if 
							else 
								totalAssets = "Not found" 
							end if 
							rsTA.close 
							set rsTA = nothing 
							
							SQL2= "select UBPRE013 as totalROA, UBPRE018 as totalNIM " &_
									"from fdic_ratios.dbo.SummaryRatios r " &_
									"join customer c on (c.rssdID = r.[ID RSSD]) " &_
									"where cast([reporting period] as date) = '" & maxDate & "' " &_
									"and c.id = " & customerID & " "
									
							dbug("SQL2: " & SQL2) 
							set rsRN = dataconn.execute(SQL2) 
							if not rsRN.eof then 

								if not isNull( rsRN("totalROA") ) then 
									totalROA = formatPercent( rsRN("totalROA")/100, 2 )
								else 
									totalROA = "$0"
								end if

								if not isNull( rsRN("totalNIM") ) then 
									totalNIM = formatPercent( rsRN("totalNIM")/100, 2 )
								else 
									totalNIM = "$0" 
								end if 
								
							else 

								totalROA = "Not found"
								totalNIM = "Not Found"

							end if
							rsRN.close 
							set rsRN = nothing 
	
							%>
							<table>
<!--
								<tr>
									<th style="text-align: left;">Last FFIEC Update:</th><td style="text-align: right;"><% =formatDateTime( maxDate, 2 ) %></th>
								</tr>
								<tr>
									<th style="text-align: left;">Assets ($000):</th><td style="text-align: right;"><% =totalAssets %></th>
								</tr>
								<tr>
									<th style="text-align: left;">ROA:</th><td style="text-align: right;"><% =totalROA %></th>
								</tr>
								<tr>
									<th style="text-align: left;">NIM:</th><td style="text-align: right;"><% =totalNIM %></th>
								</tr>
-->
								<tr>
									<th style="text-align: left;">Last FFIEC Update:</th><td id="lastUpdate" style="text-align: right;"></td><td id="lastUpdateSource"></td>
								</tr>
								<tr>
									<th style="text-align: left;">Assets ($000):</th><td id="totalAssets" style="text-align: right;"></td>
								</tr>
								<tr>
									<th style="text-align: left;">ROA:</th><td id="totalROA" style="text-align: right;"></td>
								</tr>
								<tr>
									<th style="text-align: left;">NIM:</th><td id="totalNIM" style="text-align: right;"></td>
								</tr>
							</table>
							<%
	
							
						else 
							
							%>
							<div style="margin-top: 15px;"><i class="material-icons" style="vertical-align: middle; color: orange;">warning</i>Balance sheet info not found</div>
							<%
							
						end if 
						%>
						
					</div>
					
					<div class="mdl-layout-spacer"></div>
	
				</div>
	





			</div>

			<!-- Loans -->			
			<div class="accordian">
				<h3>Loans</h3>
				<div>
					<div class="mdl-grid">
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric79_progressbar"></div>
							<div id="metric79"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric78_progressbar"></div>
							<div id="metric78"></div>
						</div>
					
						<div class="mdl-cell mdl-cell--4-col"></div>
	
					</div>
				</div>
			</div><!-- end of .accordion fof Loans-->

			<!-- Deposits -->			
			<div class="accordian">
				<h3>Deposits</h3>
				<div>
					<div class="mdl-grid">
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric107_progressbar"></div>
							<div id="metric107"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric108_progressbar"></div>
							<div id="metric108"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric51_progressbar"></div>
							<div id="metric51"></div>
						</div>
	
					</div>

					<div class="mdl-grid">
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric52_progressbar"></div>
							<div id="metric52"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric59_progressbar"></div>
							<div id="metric59"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col">
						</div>
						
					</div>
				
				</div>
			</div>

			<!-- Income -->			
			<div class="accordian">
				<h3>Income</h3>
				<div>
					
					<div class="mdl-grid">
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric147_progressbar"></div>
							<div id="metric147"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric98_progressbar"></div>
							<div id="metric98"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric85_progressbar"></div>
							<div id="metric85"></div>
						</div>
						
					</div>
					<div class="mdl-grid">
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric70_progressbar"></div>
							<div id="metric70"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric156_progressbar"></div>
							<div id="metric156"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric153_progressbar"></div>
							<div id="metric153"></div>
						</div>
	
					</div>
					<div class="mdl-grid">
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric154_progressbar"></div>
							<div id="metric154"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric155_progressbar"></div>
							<div id="metric155"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric73_progressbar"></div>
							<div id="metric73"></div>
						</div>
	
	
					</div>
					
				</div>
			</div>

			<!-- Expense -->			
			<div class="accordian">
				<h3>Expense</h3>
				<div>
					<div class="mdl-grid">
						
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric67_progressbar"></div>
							<div id="metric67"></div>
						</div>
						
						<div class="mdl-cell mdl-cell--4-col">
						</div>
	
						<div class="mdl-cell mdl-cell--4-col">
						</div>
	
					</div>
				</div>
			</div>

			<!-- Efficiency -->			
			<div class="accordian">
				<h3>Efficiency</h3>
				<div>
					<div class="mdl-grid">
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric62_progressbar"></div>
							<div id="metric62"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric40_progressbar"></div>
							<div id="metric40"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col"></div>
					
					</div>

				</div>
			</div>

			<!-- Balance -->			
			<div class="accordian">
				<h3>Balance</h3>
				<div>
					
					<div class="mdl-grid">
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric105_progressbar"></div>
							<div id="metric105"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric157_progressbar"></div>
							<div id="metric157"></div>
						</div>
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric158_progressbar"></div>
							<div id="metric158"></div>
						</div>
					
					</div>


					<div class="mdl-grid">
					
						<div class="mdl-cell mdl-cell--4-col mdl-shadow--2dp">
							<div id="metric63_progressbar"></div>
							<div id="metric63"></div>
						</div>
	
						<div class="mdl-cell mdl-cell--4-col">
						</div>
					
						<div class="mdl-cell mdl-cell--4-col">
						</div>
					
					</div>



				</div>
			</div>
			


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