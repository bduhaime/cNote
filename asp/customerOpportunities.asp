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
<!-- #include file="includes/metrics/dt_avgDaysBetweenCallsByCallTypeByCustomer.asp" -->

<% 
'***********************************************************************************

dbug("before top-logic")
if not userPermitted(37) then response.end() end if

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	
	SQL = "select ca.id, " &_
				"a.name as attributeType, " &_
				"a.description as attributeDescription, " &_
				"ca.attributeDate, " &_
				"ca.attainByDate, " &_
				"ca.customName, " &_
				"ca.narrative, " &_
				"ca.addedBy, " &_
				"replace(replace(replace(replace(m.name, ' ', ''), '-', ''), '(', ''), ')', '') as internalMetricName, " &_
				"ca.attributeValue, " &_
				"u.firstName + ' ' + u.lastName as userName, " &_
				"ca.attributeSource, " &_
				"ca.active, " &_
				"ca.startValue, " &_
				"ca.startValueDate, " &_
				"ca.economicValue, " &_
				"m.id as metricID, " &_
				"m.ubprSection, " &_
				"m.name as metricName " &_
			"from customerAnnotations ca " &_
			"left join metric m on (m.id = ca.metricID) " &_
			"left join cSuite..users u on (u.id = ca.addedBy) " &_
			"left join attributeTypes a on (a.id = ca.attributeTypeID) " &_
			"where ca.customerID = " & customerID & " " &_
			"and attributeTypeID = 3 "

	dbug(SQL)
	set rsOpp = dataconn.execute(SQL)



else 
	dbug("'id' value NOT present in request")
	response.end()
end if

dbug("after top-logic")
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

%>


<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->
	
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
	<script type="text/javascript" src="moment.min.js"></script>
	<script type="text/javascript" src="list.min.js"></script>
	<script type="text/javascript" src="customerOpportunities.js"></script>

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
      <!-- Navigation. We hide it in small screens. -->
      <nav class="mdl-navigation mdl-layout--large-screen-only">
        <a class="mdl-navigation__link" href="home.asp">Home</a>
        <% if userPermitted(2) then %><a class="mdl-navigation__link" href="admin.asp">Admin</a><% end if %>
        <a class="mdl-navigation__link" href="login.asp?cmd=logout">Logout</a>
      </nav>
    </div>

<!-- #include file="includes/customerTabs.asp" -->

  </header>
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer Opportunities</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	




		<div class="page-content">
	
			<!-- DIALOG: New Opportunity -->
			<dialog id="dialog_addAttribute" class="mdl-dialog" style="width: 700px;">
				<h4 class="mdl-dialog__title">New Opportunity</h4>
				<div class="mdl-dialog__content">

					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						<select class="mdl-textfield__input" id="attributeSource" onchange="AttrSource_onClick(this)">
							<option></option>
							<option value="attrSourceInternalStandard">Internal - Standard</option>
							<option value="attrSourceInternalCustom">Internal - Custom</option>
							<option value="attrSourceFDIC">FDIC</option>
						</select>
						<label class="mdl-textfield__label" for="attributeSource">Opportunity source...</label>
					</div>


					<hr>
	
					
					<table style="border: none;">
						<tr>
							<td style="border: none; width: 50%; vertical-align: top;">

								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
									<input class="mdl-textfield__input" type="text" id="add_annotationName"></textarea>
									<label class="mdl-textfield__label" for="add_annotationName">Name</label>
								</div>
		
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
									<select class="mdl-textfield__input" id="add_ubprCategory" onchange="UbprCategorySection_onChange()">
										<option></option>
											<%
											SQL = "select distinct financialCtgy from metric where internalMetricInd = 0 order by financialCtgy " 
											dbug(SQL)
											set rsCtgy = dataconn.execute(SQL)
											while not rsCtgy.eof 
												response.write("<option value=""" & rsCtgy("financialCtgy") & """>" & rsCtgy("financialCtgy") & "</option>")
												rsCtgy.movenext 
											wend 
											rsCtgy.close 
											set rsCtgy = nothing 
											%>
										</select>
									<label class="mdl-textfield__label" for="add_ubprCategory">UBPR category...</label>
								</div>
		
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
									<select class="mdl-textfield__input" id="add_ubprSection" onchange="UbprCategorySection_onChange()">
										<option></option>
											<%
											SQL = "select distinct ubprSection from metric where internalMetricInd = 0 order by ubprSection " 
											dbug(SQL)
											set rsSect = dataconn.execute(SQL)
											while not rsSect.eof 
												response.write("<option value=""" & rsSect("ubprSection") & """>" & rsSect("ubprSection") & "</option>")
												rsSect.movenext 
											wend 
											rsSect.close 
											set rsSect = nothing 
											%>
										</select>
									<label class="mdl-textfield__label" for="add_ubprSection">UBPR section...</label>
								</div>
		
		
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
									<select class="mdl-textfield__input" id="add_annotationMetricID">
										<option></option>
										</select>
									<label class="mdl-textfield__label" for="add_annotationMetricID">Associated metric...</label>
								</div>
		
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
									<textarea class="mdl-textfield__input" type="text" rows="3" id="add_annotationNarrative"></textarea>
									<label class="mdl-textfield__label" for="add_AnnotationNarrative">Narrative</label>
								</div>
							
								<div id="addMetricValueContainer" class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
								    <input class="mdl-textfield__input" type="number" id="add_metricValue">
								    <label class="mdl-textfield__label" for="add_metricValue">Target metric value...</label>
								</div>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
								    <input class="mdl-textfield__input" type="date" id="add_annotationDate" onblur="SetMinimumAttainDate(this);">
								    <label id="attributeDateLabel" class="mdl-textfield__label" for="add_annotationDate">Start date...</label>
								</div>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
								    <input class="mdl-textfield__input" type="date" id="add_attainByDate" onblur="SetMaximumStartDate(this);">
								    <label id="attributeDateLabel" class="mdl-textfield__label" for="add_attainByDate">Attain by date...</label>
								</div>
				
		


							</td>
							<td style="width: 5%;"></td>
							<td style="border: none; vertical-align: top;">
	
	
		
		
								<div id="addMetricValueContainer" class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
								    <input class="mdl-textfield__input" type="number" id="add_startValue">
								    <label class="mdl-textfield__label" for="add_startValue">Customer provided start value...</label>
								</div>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
								    <input class="mdl-textfield__input" type="date" id="add_startValueDate" onblur="SetMinimumAttainDate(this);">
								    <label id="attributeDateLabel" class="mdl-textfield__label" for="add_startValueDate">Customer provided value date...</label>
								</div>
				
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="display: none;">
								    <input class="mdl-textfield__input" type="number" id="add_economicValue">
								    <label id="attributeDateLabel" class="mdl-textfield__label" for="add_economicValue">Economic value...</label>
								</div>
				
		
	
	
							</td>
						</tr>
					</table>
					
					
					<input id="customerID" type="hidden" value="<% =customerID %>">
			
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	
			<!-- DIALOG: Edit Opportunity -->
			<dialog id="dialog_editAttribute" class="mdl-dialog">
				<h4 class="mdl-dialog__title">Edit Opportunity</h4>
				<div class="mdl-dialog__content">
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<input class="mdl-textfield__input" type="text" id="edit_annotationName"></textarea>
							<label class="mdl-textfield__label" for="edit_annotationName">Name</label>
						</div>
					
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<textarea class="mdl-textfield__input" type="text" rows="3" id="edit_annotationNarrative"></textarea>
							<label class="mdl-textfield__label" for="edit_annotationNarrative">Narrative</label>
						</div>
					
						<div id="addMetricValueContainer" class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="text" id="edit_metricValue">
						    <label class="mdl-textfield__label" for="edit_metricValue">Target metric value...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="date" id="edit_annotationDate" onblur="SetMinimumAttainDate(this);">
						    <label id="attributeDateLabel" class="mdl-textfield__label" for="edit_annotationDate">Start date...</label>
						</div>
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						    <input class="mdl-textfield__input" type="date" id="edit_attainByDate" onblur="SetMaximumStartDate(this);">
						    <label id="attributeDateLabel" class="mdl-textfield__label" for="edit_attainByDate">Attain by date...</label>
						</div>
			
						<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="edit_active">
							<input type="checkbox" id="edit_active" class="mdl-checkbox__input">
							<span class="mdl-checkbox__label">Active</span>
						</label>
			
						<input type="hidden" id="edit_annotationID" value="">
				</div>
		
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
		
			</dialog><!-- END DIALOG -->
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--8-col" align="left">
					<button id="button_newAttribute" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Opportunity
					</button>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
	
<!-- START -->	
	
	<%
	rsOpp.movefirst 
	if not rsOpp.eof then 
		
		dbug("NOT rsOpp.eof, so creating MDL grid...")
	
		while not rsOpp.eof 
			metricID = rsOpp("internalMetricName") & rsOpp("id")
			dbug("creating MDL cells for metric: " & metricID)
			
			if not isNull(rsOpp("attainByDate")) then 
				attainByDate = formatDateTime(rsOpp("attainByDate"),2)
			else 
				attainByDate = ""
			end if
			%>
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="left">
					<table>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Attain By:</b></td>
							<td valign="top"><% =attainByDate %></td>
						</tr>
						<% if len(rsOpp("customName")) > 0 then %>
							<tr>
								<td style="vertical-align: top; text-align: right;"><b>Name:</b>
								<td valign="top">
									<% if not isNull(rsOpp("customName")) then response.write(server.htmlEncode(rsOpp("customName"))) %>
								</td>
							</tr>
						<% end if %>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Description:</b>
							<td valign="top">
								<% if not isNull(rsOpp("narrative")) then response.write(server.htmlEncode(rsOpp("narrative"))) %>
							</td>
						</tr>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Metric:</b></td>
							<td valign="top"><% =rsOpp("metricName") %></td>
						</tr>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>UBPR Section:</b></td>
							<td valign="top"><% =rsOpp("ubprSection") %></td>
						</tr>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Goal Value:</b></td>
							<td valign="top"><% =rsOpp("attributeValue") %></td>
						</tr>




						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Start Value:</b></td>
							<td valign="top"><% =rsOpp("startValue") %></td>
						</tr>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Start Value Date:</b></td>
							<td valign="top"><% =formatDateTime(rsOpp("startValueDate"),2) %></td>
						</tr>
						<tr>
							<td style="vertical-align: top; text-align: right;"><b>Economic Value:</b></td>
							<td valign="top"><% =formatCurrency(rsOpp("economicValue"),0) %></td>
						</tr>



					</table>
				</div>
				<div class="mdl-cell mdl-cell--6-col mdl-shadow--2dp" align="center">
					<div id="<% =metricID %>" style="vertical-align: middle">
						<% if isNull(rsOpp("metricID")) then response.write("<br>Customer Rated, no data to chart at this time") end if %>
					</div>
				</div>
				<div class="mdl-layout-spacer"></div>
				
			</div><!-- end grid -->
			<%
			rsOpp.movenext 
		wend

	else 
		dbug("rsOpp.eof, no opportunites for this customer so displaying signage")
		%>

			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--3-col mdl-shadow--2dp" align="center">No "Opportunities" found for this customer</div>
				<div class="mdl-layout-spacer"></div>
			</div>

		<%
	end if			
	
	rsOpp.close 
	set rsOpp = nothing 
	%>

	
<!-- END -->
	

			
		</div>
		


	</main>
	
</div>

<!-- #include file="includes/pageFooter.asp" -->

<script src="dialog-polyfill.js"></script>  
<script>
	
// add Attribute Dialog Controls
	var dialog_addAttribute = document.querySelector('#dialog_addAttribute');
	var button_newAttribute = document.querySelector('#button_newAttribute');	
	if (! dialog_addAttribute.showModal) {
		dialogPolyfill.registerDialog(dialog_addAttribute);
	}	
	button_newAttribute.addEventListener('click', function() {
		dialog_addAttribute.showModal();
		document.getElementById('add_annotationDate').parentNode.classList.add('is-dirty');
		document.getElementById('add_attainByDate').parentNode.classList.add('is-dirty');
		document.getElementById('add_startValueDate').parentNode.classList.add('is-dirty');
	});
	dialog_addAttribute.querySelector('.cancel').addEventListener('click', function() {
		dialog_addAttribute.close();
	});
	dialog_addAttribute.querySelector('.save').addEventListener('click', function() {
		AddAnnotation_onSave(dialog_addAttribute)
		dialog_addAttribute.close();
	});
	
	
// edit Attribute Dialog Controls
	var dialog_editAttribute = document.querySelector('#dialog_editAttribute');
	if (! dialog_editAttribute.showModal) {
		dialogPolyfill.registerDialog(dialog_editAttribute);
	}	
	dialog_editAttribute.querySelector('.cancel').addEventListener('click', function() {
		dialog_editAttribute.close();
	});
	dialog_editAttribute.querySelector('.save').addEventListener('click', function() {
		EditAnnotation_onSave(dialog_editAttribute)
		dialog_editAttribute.close();
	});
	


//****************************************************************************************/
// Add Event Listeners for Edit buttons
//****************************************************************************************/
//
	var attrEditButtons = document.querySelectorAll('.attrEditButton'), i;
	if (attrEditButtons != null) {
		
		for (i = 0; i < attrEditButtons.length; ++i) {
			attrEditButtons[i].addEventListener('click', function(event) {
				CustomerAnnotationEdit_onClick(this);
				event.cancelBubble = true;
			})
		}
		
	}
	
	
//****************************************************************************************/
// Add Event Listeners for Delete buttons
//****************************************************************************************/
//
	var attrDeleteButtons = document.querySelectorAll('.attrDeleteButton'), i;
	if (attrDeleteButtons != null) {
		
		for (i = 0; i < attrDeleteButtons.length; ++i) {
			attrDeleteButtons[i].addEventListener('click', function(event) {
				DeleteAnnotation_OnClick(this);
				event.cancelBubble = true;
			})
		}
		
	}
	
	


</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>