<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/customerTitle.asp" -->
<!-- #include file="../includes/jsonDataTable.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<!-- #include file="includes/getAccountHolderAddenda.asp" -->
<% 
call checkPageAccess(43)
dbug(" ")
dbug("start of customerTop100Survey.asp...")

customerID = request.querystring("customerID")
if ( len(customerID) <= 0  OR  not isNumeric(customerID) ) then 
	dbug("customerID is missing or invalid: " & customerID & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
else 
	customerPredicate = "WHERE customerID = " & customerID & " " 
end if 
dbug("customerID: " & customerID)


if ( len(request.querystring("accountHolder")) <= 0 ) then 
	dbug("accountHolderNumber is missing or invalid: " & accountHolder & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
else 
	accountHolder = "'" & request.querystring("accountHolder") & "'"
	accountHolderPredicate = "AND [account holder number] = '" & request.querystring("accountHolder") & "' " 
end if 
dbug("accountHolder: " & accountHolder)

surveyType = request.querystring("surveyType")
subtitle = ""

if ( len(surveyType) ) > 0 then 
	if ( isNumeric(surveyType) ) then 
		if ( cInt(surveyType) = 1 ) then 
			subtitle = "Customer Firmographics"
			surveyTypePredicate = "AND surveyType = 1 "
		elseif ( cInt(surveyType) = 2 ) then 
			subtitle = "Customer Psychographics"
			surveyTypePredicate = "AND surveyType = 2 "
		else 
			dbug("surveyType is missing or invalid: " & surveyType & ", status=412 returned to user")
			response.Status = "412 Precondition Failed"
			response.end()
		end if 
	else 
		dbug("surveyType is missing or invalid: " & surveyType & ", status=412 returned to user")
		response.Status = "412 Precondition Failed"
		response.end()
	end if 
else 
	dbug("surveyType is missing or invalid: " & surveyType & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
end if 
dbug("surveyType: " & surveyType)
dbug("subtitle: " & subtitle)


title = customerTitle(customerID)
title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""../images/ic_chevron_right_white_18dp_2x.png"">" & title

userLog(title)




'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->

%>

<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->



	<link rel="stylesheet" href="../datatables/DataTables.css" />
	<link rel="stylesheet" href="https://cdn.datatables.net/fixedheader/3.1.7/css/fixedHeader.dataTables.min.css" />
	<link rel="stylesheet" href="../jquery-ui-1.12.1/jquery-ui.min.css" />
	<link rel="stylesheet" href="cProfitStyle.css" />

	<script src="../jQuery/jquery-3.5.1.js"></script>
	<script src="../DataTables/datatables.js"></script>
	<script src="https://cdn.datatables.net/fixedheader/3.1.7/js/dataTables.fixedHeader.min.js"></script>
	<script src="../jquery-ui-1.12.1/jquery-ui.min.js"></script>
	<script src="../moment.min.js"></script>


	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		const customerID 				= <% =customerID %>;
		const accountHolder			= <% =accountHolder %>;
		const surveyType				= <% =surveyType %>;
		
		$( function() {
			$( 'input[type=radio]' ).checkboxradio();
		} );
		
		$(document).ready(function() {
			var table = $('#tbl_survey')
				.DataTable({
					searching: false,
					columnDefs: [
						{targets: 'prompt', 				className: 'prompt dt-body-left',		orderable: false},
						{targets: 'userPrompt', 		className: 'userPrompt dt-body-left', 	orderable: false},
						{targets: 'responseType', 		className: 'responseType', 	visible: false},
						{targets: 'responseValues', 	className: 'responseValues', 	visible: false},
					],
					order: [],
				});
		});


	</script>
	
	<style>

		table.dataTable tbody tr:hover {
			cursor: default;
		}
		
		input.text {
			height: 18px;
			padding: 3.108px 0px 3.108px 5.6px;
			font-size: 14px;
		}
		
		select {
			height: 30px;
			font-size: 14px;
		}
		
	</style> 
	
		
</head>

<body>


<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>
	
<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
	<header class="mdl-layout__header">
		<div class="mdl-layout__header-row">

			<!-- Title -->
			<span class="mdl-layout-title"><% =title %></span>
			<!-- Add spacer, to align navigation to the right -->
			<div class="mdl-layout-spacer"></div>
		
			<!-- #include file="../includes/mdlLayoutNavLarge.asp" -->

		</div>
		<!-- #include file="../includes/customerTabs.asp" -->
  </header>
  
  
	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
				
			<!-- Your content goes here -->

			<!-- SNACKBAR -->
			<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
			    <div class="mdl-snackbar__text"></div>
			    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
			</div>


			<!-- #include file="includes/accountHolderPopup.asp" -->


			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--1-col reportTitle">
					<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent" onclick="window.history.go(-1)">
						<i class="material-icons">arrow_back</i>Back
					</button>
				</div>
				<div class="mdl-cell mdl-cell--3-col reportTitle"><% =subtitle %></div>
				<div class="mdl-cell mdl-cell--1-col reportTitle">&nbsp;</div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--5-col mdl-shadow--2dp" style="padding: 15px;">

					<%
					SQL = "select distinct " &_
								"q.id, " &_
								"q.seq, " &_
								"q.prompt, " &_
								"q.responseType, " &_
								"q.responseValues, " &_
								"q.regex, " &_
								"q.source " &_
							"from customerSurveyQuestions q " &_
							customerPredicate &_
							surveyTypePredicate &_
							"order by seq asc "
					dbug(SQL)
					set rsQ = dataconn.execute(SQL) 
					if not rsQ.eof then 
						%>
	
						<table id="tbl_survey" class="compact display">
							<thead>
								<tr>
									<th class="prompt"></th>
									<th class="userPrompt"></th>
									<th class="responseType"></th>
									<th class="responseValues"></th>
								</tr>
							</thead>
							<% while not rsQ.eof %>
								<%
								SQL = "select answer " &_
										"from customerSurveyAnswers " &_
										customerPredicate &_
										accountHolderPredicate &_
										"and questionID = " & rsQ("id") & " " 	
								
								dbug(SQL)
								set rsA = dataconn.execute(SQL) 
								if not rsA.eof then 
									answer = rsA("answer") 
								else 
									answer = null 
								end if 
								rsA.close 
								set rsA = nothing 
								
								dbug("answer: " & answer)
									
									
								userControl = ""
								select case lCase(trim(rsQ("responseType")))
									case "boolean"
									
										if not isNull(answer) then 
											
											select case answer 
											
												case "true" 
													trueChecked = "checked" 
													falseChecked = ""
													unknownChecked = ""
												case "false" 
													trueChecked = "" 
													falseChecked = "checked"
													unknownChecked = ""
												case "unknown"
													trueChecked = "" 
													falseChecked = ""
													unknownChecked = "checked"
												case else 
													trueChecked = "" 
													falseChecked = ""
													unknownChecked = ""
											
											end select 
											

										else 

											trueChecked = "" 
											falseChecked = ""
											unknownChecked = ""

										end if 

										userControl = 	"<fieldset>" &_
																"<label for=""field_" & rsQ("id") & "_true"">Yes</label>" &_
																"<input data-id=""" & rsQ("id") & """ data-value=""true"" type=""radio"" name=""field_" & rsQ("id") & """ id=""field_" & rsQ("id") & "_true""" & trueChecked & ">" &_
																"<label for=""field_" & rsQ("id") & "_false"">No</label>" &_
																"<input data-id=""" & rsQ("id") & """ data-value=""false"" type=""radio"" name=""field_" & rsQ("id") & """ id=""field_" & rsQ("id") & "_false""" & falseChecked & ">" &_
																"<label for=""field_" & rsQ("id") & "_unknown"">Unknown</label>" &_
																"<input data-id=""" & rsQ("id") & """ data-value=""unknown"" type=""radio"" name=""field_" & rsQ("id") & """ id=""field_" & rsQ("id") & "_unknown""" & unknownChecked & ">" &_
															"</fieldset>"
															
										javaScript = javaScript &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "_true').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "_false').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "_unknown').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf 
										
										
									case "currency"
									
										if not isNull(answer) then 
											value = formatCurrency(answer,0)
										else 
											value = ""
										end if 
									
										userControl = 	"<label for=""field_" & rsQ("id") & """>" &_
															"<input data-regex=""" & rsQ("regex") & """ data-type=""currency"" type=""text"" id=""field_" & rsQ("id") & """ value=""" & value & """ class=""text ui-widget-content ui-corner-all"" data-id=""" & rsQ("id") & """>"

										javaScript = javaScript &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf 
										
										
									case "number"
									
										if not isNull(answer) then 
											if IsNumeric(answer) then 
												value = formatNumber(answer,0)
											else 
												value = answer
											end if
										else 
											value = ""
										end if 
									
										userControl = 	"<label for=""field_" & rsQ("id") & """>" &_
															"<input data-regex=""" & rsQ("regex") & """ data-type=""number"" type=""text"" id=""field_" & rsQ("id") & """ value=""" & value & """ class=""text ui-widget-content ui-corner-all"" data-id=""" & rsQ("id") & """>"
										
										javaScript = javaScript &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf 
										

									case "select" 
									
										options = split(rsQ("responseValues"),"|")
										userControl = 	"<label for=""field_" & rsQ("id") & """></label>" &_
															"<select id=""field_" & rsQ("id") & """ data-id=""" & rsQ("id") & """>" &_
																"<option disabled selected>Please pick one</option>" 
										
										for i = 0 to uBound(options) 
											if options(i) = answer then 
												selected = "selected" 
											else 
												selected = ""
											end if 
											
											userControl = userControl & "<option " & selected & ">" & options(i) & "</option>"
											
										next 
										
										userControl = userControl & "</select>"
										
										javaScript = javaScript &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf 
										


									case "string"

										userControl = 	"<label for=""field_" & rsQ("id") & """></label>" &_
															"<input data-regex=""" & rsQ("regex") & """ type=""text"" id=""field_" & rsQ("id") & """ value=""" & answer & """ class=""text ui-widget-content ui-corner-all"" data-id=""" & rsQ("id") & """>"
										
										javaScript = javaScript &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "').addEventListener('change',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf 
										

									case "year"

										userControl = 	"<label for=""field_" & rsQ("id") & """>" &_
															"<input id=""field_" & rsQ("id") & """ value=""" & answer & """ data-id=""" & rsQ("id") & """>"
															
										javaScript = javascript & vbCrLf &_
											vbTab & " $( function() { " & vbCrLf &_
											vbTab & vbTab & "$( '#field_" & rsQ("id") & "')" & vbCrLf &_
											vbTab & vbTab & vbTab & ".on( 'click', SetDefaultValue )" & vbCrLf &_
											vbTab & vbTab & vbTab & ".spinner({" & vbCrLf &_
											vbTab & vbTab & vbTab & vbTab & "max: currentYear, " & vbCrLf &_
											vbTab & vbTab & vbTab & vbTab & "min: 1000, " & vbCrLf &_
											vbTab & vbTab & vbTab & vbTab & "step: 1, " & vbCrLf &_
											vbTab & vbTab & vbTab & vbTab & "start: currentYear, " & vbCrLf &_
											vbTab & vbTab & vbTab & vbTab & "numberFormat: 'C' " & vbCrLf &_
											vbTab & vbTab & vbTab & "})"	& vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf &_
											vbTab & "document.querySelector('#field_" & rsQ("id") & "').addEventListener('blur',function() {" & vbCrLf &_
												vbTab & vbTab & "UpdateSurveyAnswer(this);" & vbCrLf &_
											vbTab & "}); " & vbCrLf &_
											vbCrLf 

									case else 
									
										userControl = "unknown: " & rsQ("responseType")
										
								end select 	
									
								%>
								
								<tr id="<% =rsQ("id") %>">
									<td><% =rsQ("prompt") %></td>
									<td><% =userControl %></td>
									<td><% =rsQ("responseType") %></td>
									<td><% =rsQ("responseValues") %></td>
								</tr>
								<% rsQ.movenext %>
							<% wend %>
						</table>
						
						<%
					else 
						response.write("No Questions Defined For Customer")
					end if 
					rsQ.close 
					set rsQ = nothing 
					%>


				</div>
		
				<div class="mdl-layout-spacer"></div>
		
			</div>


		</div>

		<!-- #include file="includes/contextMenu.asp" -->
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>

<script>

	const currentYear = moment().year();
	
	function SetDefaultValue() {

		var currValue = $( this ).val();
		if ( currValue ) {
			$(this).val( currValue );
		} else {
			$(this).val(currentYear);
		}
		
		$(this).off('click');
		
	}
	
	async function UpdateSurveyAnswer(htmlNode) {
		
		const id = htmlNode.id;
		const type = htmlNode.type;
		const questionID = htmlNode.getAttribute('data-id');
		const dataType = htmlNode.getAttribute('data-type');
		const regex = htmlNode.getAttribute('data-regex');
		const value = htmlNode.value;
		
		var newValue;
		
		switch ( type ) {
			case 'text':
				
				if ( regex ) {
					
					var re = new RegExp(regex);
					if ( re.test(value) ) {
						newValue = value;
					} else {
						alert( 'Value entered is not valid' );
						htmlNode.select();
						htmlNode.focus();
						return false;
					}
					
				} else {
					if ( dataType === 'currency' || dataType === 'number' ) {
						var numStr = htmlNode.value;
						var numNum = +numStr;
						if ( isNaN(numNum) ) {
							alert( 'Value entered is not a number' );
							htmlNode.select();
							htmlNode.focus();
							return false;
						} else {
							newValue = htmlNode.value;
						}
	
					}
				}
				break;

			case 'checkbox':

				if ( htmlNode.checked ) {
					newValue = 'true';
				} else {
					newValue = 'false';
				}
				break;

			case 'select-one':

				newValue = htmlNode.options[htmlNode.selectedIndex].value;
				break;

			case 'radio':

				newValue = htmlNode.getAttribute('data-value');
				break;

			default:

				alert('changed input element of unknown type: ' + id + ', questionID: ' + questionID);

		}		

		
		const url = 'ajax/customerSurveyAnswers.asp';
		const form = 'customerID=' + customerID
								+ '&accountHolderNumber=' + accountHolder
								+ '&questionID=' + questionID 
								+ '&newValue=' + newValue;
								
		console.log(url+'?'+form);
								
		const apiResponse = await fetch(url, {
			method: 'post',
			headers: {
				'Content-type': 'application/x-www-form-urlencoded'
			},
			body: form
		});

		if (apiResponse.status !== 200) {
			return generateErrorResponse('Failed to fetch API details ' + apiResponse.status);
		}
		
		var apiResult = await apiResponse.json();

		if ( apiResult.msg ) {
			const notification = document.querySelector('.mdl-js-snackbar');
			notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
		}
		
	}

<% =javaScript %>
	
// 	$( function() { 
// 		$( '#field_5')
// 		.on( 'click', SetDefaultValue ) 
// 		.spinner({
// 			max: currentYear, 
// 			min: 1000, 
// 			step: 1, 
// 			start: currentYear, 
// 			numberFormat: 'C' 
// 		})
// 	});  
	
</script>

</body>
</html>