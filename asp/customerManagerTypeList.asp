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
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/validUserDomain.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(113)


title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Customer Manager Types"
userLog(title)

%>

<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->

	<script src="list.min.js"></script>
	<script type="text/javascript" src="customerManagerTypeList.js"></script>
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />

<body>
	

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div class="page-content">
    <!-- Your content goes here -->

		<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>



		<dialog id="dialog_newCMT" class="mdl-dialog">

			<h4 id="dialogTitle" class="mdl-dialog__title">New Customer Manager Type</h4>
			<div class="mdl-dialog__content">

				<!-- Name -->
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<input class="mdl-textfield__input" type="name" id="cmtName">
					<label class="mdl-textfield__label" for="mgrStartDate">Name...</label>
				</div>
	
			</div>

			<!-- Dialog Buttons -->				
			<div class="mdl-dialog__actions mdl-dialog__actions">
				<button type="button" class="mdl-button cancel">Cancel</button>
				<button type="button" class="mdl-button save">Save</button>
			</div>

		</dialog>




   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>

		   <div class="mdl-cell mdl-cell--2-col" style="text-align: center;">

				<!-- Accent-colored raised button with ripple -->
				<button class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent newCMT" style="width: 100%;">
				  New Customer Manager Type
				</button>

		   </div>
		   <div class="mdl-cell mdl-cell mdl-cell--5-col" style="text-align: center;">&nbsp;</div>
			<div class="mdl-layout-spacer"></div>
   	</div>
   	

   	<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>

		   <div id="tbl_customerManagerTypesList" class="mdl-cell mdl-cell--2-col" style="text-align: center;">

				<table id="tbl_customerManagerTypes" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="margin-left: auto;">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric sort" data-sort="name">Name</th>
							<th class="mdl-data-table__cell--non-numeric" style="text-align: center;">Actions</th>
						</tr>
					</thead>
					<tbody class="list"> 

						<%
						SQL = "select * " &_
								"from customerManagerTypes " &_
								"where (deleted = 0 or deleted is null) " &_
								"order by name "
						
						dbug(SQL)
						set rsCMT = dataconn.execute(SQL)
						while not rsCMT.eof
							%>
							<tr class="cmtRow" data-id="<% =rsCMT("id") %>" style="cursor: pointer">
								<td class="mdl-data-table__cell--non-numeric name">
									<% =rsCMT("name") %>
									<% if cInt(rsCMT("id")) = 0 then %>
										<i class="material-icons primaruyCMT" title="This is the 'Primary' manager type; only one manager allowed at any point in time. This manager type cannot be deleted." style="vertical-align: middle;">info</i>
									<% end if %>
								</td>
								<td class="mdl-data-table__cell--non-numeric" style="text-align: center;">
									<div class="actionIcons" style="float: right; vertical-align: middle; align-content: center;">
										<i class="material-icons viewMgrs" data-id="<% =rsCMT("id") %>" 	style="visibility: hidden; cursor: pointer; vertical-align: middle;" title="View customer managers of this type">double_arrow</i>
										<% if rsCMT("id") <> "0" then %>
											<i class="material-icons deleteCMT" data-id="<% =rsCMT("id") %>" 	style="visibility: hidden; cursor: pointer; vertical-align: middle;" title="Delete customer manager type"li>delete_outline</i>
										<% end if %>
										<i class="material-icons editCMT" data-id="<% =rsCMT("id") %>" 	style="visibility: hidden; cursor: pointer; vertical-align: middle;" title="Edit customer manager type">edit</i>
									</div>
								</td>
							</tr>			
							<%
							rsCMT.movenext 
						wend
						rsCMT.close 
						set rsCMT = nothing
						%>
				
					</tbody>
				</table>				
				

			</div><!-- this <div> is also a container for list.js -->
			
		   <div class="mdl-cell mdl-cell mdl-cell--5-col" style="text-align: center;">
			
				<div id="cmPlaceholderText" style="text-align: center; margin-top: auto; margin-bottom: auto;">Click on a Customer Manager Type to<br>see a list of Customer Managers here</div>
				
				<table id="customerManagers" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="display: none;">
					<thead>
						<tr>
							<th class="mdl-data-table__cell--non-numeric">Manager Name</th>
							<th class="mdl-data-table__cell--non-numeric">Customer Name</th>
							<th class="mdl-data-table__cell--non-numeric">Start Date</th>
							<th class="mdl-data-table__cell--non-numeric">End Date</th>
						</tr>
					</thead>
					<tbody></tbody>
				</table>
				
		   </div>
				
			<div class="mdl-layout-spacer"></div>
			
   	</div>
	
	</div>
    
  </main>
  <!-- #include file="includes/pageFooter.asp" -->


 <script src="dialog-polyfill.js"></script>  
 <script src="datalist-polyfill.js"></script>  
 <script>

	var dialog_newCMT 	= document.querySelector('#dialog_newCMT');
	var button_newCMT		= document.querySelector('button.newCMT');	

	// register all dialogs
	if (! dialog_newCMT.showModal) {
		dialogPolyfill.registerDialog(dialog_newCMT);
	}	


	if (button_newCMT) {
		button_newCMT.addEventListener('click', function() {
			
			var cmtName = dialog_newCMT.querySelector('#cmtName');
			cmtName.value = '';

			dialog_newCMT.showModal();
			
		});
	}

	dialog_newCMT.querySelector('.cancel').addEventListener('click', function() {
		dialog_newCMT.close();
	});

	dialog_newCMT.querySelector('.save').addEventListener('click', function() {
		SaveCMT(dialog_newCMT);		
	});
	


	//****************************************************************************************
	// add event listeners for mouseover, mouseout, and click on each <tr>
	//****************************************************************************************
	
	var cmtRows = document.querySelectorAll('.cmtRow');
	if (cmtRows) {
		for (i = 0; i < cmtRows.length; ++i) {

			cmtRows[i].addEventListener('mouseover', function() {
				ToggleActionIcons(this);
			});

			cmtRows[i].addEventListener('mouseout', function() {
				ToggleActionIcons(this);
			});
			
			cmtRows[i].addEventListener('click', function() {
				GetCustomerManagers(this);
			});

		}
	}



	//****************************************************************************************
	// add event listeners for clicking on the edit (pencil) icon for an manager type
	//****************************************************************************************

	var editCMTs = document.querySelectorAll('.editCMT');
	if (editCMTs) {
		for (i = 0; i < editCMTs.length; ++i) {
			editCMTs[i].addEventListener('click', function(e) {
				e.cancelBubble = true;
				EditCustomerManagerType(this);
			});
		}
	}


	//****************************************************************************************
	// add event listeners for clicking on the delete (trash can) icon for an manager type
	//****************************************************************************************

	var deleteCMTs = document.querySelectorAll('.deleteCMT');
	if (deleteCMTs) {
		for (i = 0; i < deleteCMTs.length; ++i) {
			deleteCMTs[i].addEventListener('click', function(e) {
				e.cancelBubble = true;
				DeleteCustomerManagerType(this);
			});
		}
	}


 </script>
<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>