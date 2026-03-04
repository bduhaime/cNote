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
if not userPermitted(37) then response.end() end if
dbug(" ")
userLog("customer attributes")
templateFromIncompleteProj = systemControls("Allow template generation from incomplete projects")


customerID = request.querystring("id")

'***********************************************************************************
'***********************************************************************************
'***********************************************************************************

dbug("before top-logic")

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	customerID = request.querystring("id")
	title = customerTitle(customerID)
	title = session("clientID") &  " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	

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
	<script type="text/javascript" src="customerAttributes.js"></script>

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
		<span class="mdl-layout-title">Customer Attributes</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	




		<div class="page-content">
	
			<!-- DIALOG: New Annotation -->
			<dialog id="dialog_addAttribute" class="mdl-dialog">
				<h4 class="mdl-dialog__title">New Attribute</h4>
				<div class="mdl-dialog__content">
					<form id="form_addAnnotation">
		
						<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							<select class="mdl-textfield__input" id="add_attributeTypeID" required>
								<%
								SQL = "select id, name " &_
										"from attributeTypes " &_
										"order by name desc "
								dbug(SQL)
								set rsAttr = dataconn.execute(SQL)
								while not rsAttr.eof 
									response.write("<option value=""" & rsAttr("id") & """>" & rsAttr("name") & "</option>")
									rsAttr.movenext 
								wend
								rsAttr.close
								set rsAttr = nothing
								%>
								</select>
							<label class="mdl-textfield__label" for="add_attributeTypeId">Attribute type...</label>
						</div>
						<br>
						
						
						<fieldset>

							<legend><b>Source</b></legend>
						
							<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="attrSourceInternalStandard">
								<input type="radio" id="attrSourceInternalStandard" name="attributeSource" class="mdl-radio__button" onclick="AttrSource_onClick(this)">
								<span class="mdl-radio__label">Internal - Standard</span>
							</label>
							<br>
							<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="attrSourceInternalCustom">
								<input type="radio" id="attrSourceInternalCustom" name="attributeSource" class="mdl-radio__button" onclick="AttrSource_onClick(this)">
								<span class="mdl-radio__label">Internal - Custom</span>
							</label>
							<br>
							<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect" for="attrSourceFDIC">
								<input type="radio" id="attrSourceFDIC" name="attributeSource" class="mdl-radio__button" onclick="AttrSource_onClick(this)">
								<span class="mdl-radio__label">FDIC</span>
							</label>
						
						</fieldset>
						<br>

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
							<input class="mdl-textfield__input" type="text" id="add_annotationName"></textarea>
							<label class="mdl-textfield__label" for="add_annotationName">Name</label>
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
		
	
						<input id="customerID" type="hidden" value="<% =customerID %>">
			
					</form>
				</div>
				<div class="mdl-dialog__actions">
					<button type="button" class="mdl-button save">Save</button>
					<button type="button" class="mdl-button cancel">Cancel</button>
				</div>
			</dialog><!-- END DIALOG -->
	
	
			<!-- DIALOG: Edit Annotation -->
			<dialog id="dialog_editAttribute" class="mdl-dialog">
				<h4 class="mdl-dialog__title">Edit Attribute</h4>
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
				<div class="mdl-cell mdl-cell--2-col" align="left">
					<button id="button_newAttribute" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
					  New Attribute
					</button>
				</div>
				<div class="mdl-cell mdl-cell--3-col" align="left">
				</div>
				<div class="mdl-cell mdl-cell--1-col" align="left">
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
						<select class="mdl-textfield__input" id="filterType" onchange="FilterType_onChange(this.value)">
							<option value="Utopia" selected="">Utopia</option>
							<option value="Metric Note">Metric Note</option>
						</select>
						<label class="mdl-textfield__label" for="filterType">Show attribute of type...</label>
					</div>
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
	
	
			<div class="mdl-grid">
	
				<div class="mdl-layout-spacer"></div>
				
				<div class="mdl-cell mdl-cell--9-col" align="center">
					
					<table id="tbl_customerAnnotations" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
						<thead>
							<tr>
								<th class="mdl-data-table__cell--non-numeric" style="display: none;"></th>
								<th class="mdl-data-table__cell--non-numeric">Type</th>
								<th class="mdl-data-table__cell--non-numeric">Dates</th>
								<th class="mdl-data-table__cell--non-numeric">Name/<br><i>Narrative</i></th>
								<th class="mdl-data-table__cell--non-numeric">Metric</th>
								<th class="mdl-data-table__cell--non-numeric">Goal Value</th>
								<th class="mdl-data-table__cell--non-numeric">Active</th>
								<th class="mdl-data-table__cell--non-numeric">Actions</th>
							</tr>
						</thead>
						<tbody class="list"> 
						<%
						SQL = "select ca.id, " &_
									"a.name as attributeType, " &_
									"a.description as attributeDescription, " &_
									"ca.attributeDate, " &_
									"ca.attainByDate, " &_
									"ca.customName, " &_
									"ca.narrative, " &_
									"ca.addedBy, " &_
									"m.name as metricName, "&_
									"ca.attributeValue, " &_
									"u.firstName + ' ' + u.lastName as userName, " &_
									"ca.attributeSource, " &_
									"ca.active " &_
								"from customerAnnotations ca " &_
								"left join metric m on (m.id = ca.metricID) " &_
								"left join cSuite..users u on (u.id = ca.addedBy) " &_
								"left join attributeTypes a on (a.id = ca.attributeTypeID) " &_
								"where ca.customerID = " & request("id") & " " 
					
						dbug(SQL)
						set rs = dataconn.execute(SQL)
						while not rs.eof

							if not isNull(rs("attainByDate")) then 
								attainByDate = formatDatetime(rs("attainByDate"),2)
							else 
								attainByDate = ""
							end if

							if not isNull(rs("attributeDate")) then 
								attributeDate = formatDatetime(rs("attributeDate"),2)
							else 
								attributeDate = ""
							end if

							%>
							<tr onmouseover="ToggleActionIcons(this)" onmouseout="ToggleActionIcons(this)">
 								<td class="mdl-data-table__cell--non-numeric attributeType" style="display: none;"><% =rs("attributeType") %></td>
 								<td class="mdl-data-table__cell--non-numeric attributeType">
	 								<% if rs("attributeType") = "Utopia" then %>
	 									<i class="material-icons">timeline</i>
	 								<% else %>
	 									<i class="material-icons">notes</i>
	 								<% end if %>
 								</td>
 								<td class="mdl-data-table__cell--non-numeric">
	 								<b>Start:</b> 		<div style="display: inline-block"><% =attributeDate %></div><br>
		 							<b>Attain By:</b> <div style="display: inline-block"><% =attainByDate %></div>
		 						</td>
								<td class="mdl-data-table__cell--non-numeric">
									<% if not isNull(rs("customName")) then response.write("<div class=""customName"" style=""display: inline-block"">" & rs("customName")) & "</div><br>" end if %>
									<div id="narrative-<% =rs("id") %>" class="narrative" style="width: 300px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis" title="<% =rs("narrative") %>">
										<i><% =rs("narrative") %></i>
									</div>
								</td>
								<td class="mdl-data-table__cell--non-numeric">
									<%
									if isNull(rs("customName")) then 
										response.write(rs("metricName"))
									else 
										response.write("Customer Rated")
									end if
									%>
								</td>
								<td class="mdl-data-table__cell--non-numeric"><% =rs("attributeValue") %></td>
								<td class="mdl-data-table__cell--non-numeric" style="text-align: center !important;">
									
									<% 
									if rs("active") then 
										checked = " checked " 
									else 
										checked = ""  
									end if
									%>
									
									<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="active">
										<input type="checkbox" id="active" class="mdl-checkbox__input" <% =checked %> disabled>
									</label>



								</td>
								<td class="mdl-data-table__cell--non-numeric">
									<% if userPermitted(18) then %>
										<i id="taskEdit-<% =rs("id") %>" class="material-icons attrEditButton" data-val="<% =rs("id") %>" style="float: right; vertical-align: text-bottom; display: none; cursor: pointer">edit</i>
									<% end if %>
									<i id="taskDelete-<% =rs("id") %>" class="material-icons attrDeleteButton" data-val="<% =rs("id") %>" style="float: right; vertical-align: text-bottom; display: none; cursor: pointer">delete_outline</i>
								</td>
							</tr>			
							<%
							rs.movenext 
						wend
						rs.close 
						set rs = nothing
						%>
					
							</tbody>
					</table>		    			    
								
				</div>
				
				<div class="mdl-layout-spacer"></div>
				
			</div><!-- end grid -->
			
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
	
	


//****************************************************************************************/
// Filter the Attribute Table...
//****************************************************************************************/
//
	var listOptions = {
			valueNames: ['attributeType']
	};

	var attributeList = new List('tbl_customerAnnotations', listOptions);
		
	function FilterType_onChange(filterValue) {
	
		attributeList.filter(function(item) {

			if (item.values().attributeType == filterValue) {
				return true;
			} else {
				return false;
			}
			
		});

	}
	    

	document.addEventListener('DOMContentLoaded', function() {
	   FilterType_onChange('Utopia');
	}, false);

</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>



</html>