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
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(46)

customerID = request.querystring("id")
%>
<!-- #include file="includes/validateCustomerAccess.asp" -->
<%	

userLog("customer implementations")


if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	title = customerTitle(customerID)
	title = session("clientID") & " - <a href=""/customerList.asp?"">Customers</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">" & title
	

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

	<script src="moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script src="customerImplementations.js"></script>
	
	<script>
	
		$(document).ready(function() {

			$.fn.dataTable.moment( 'M/D/YYYY' );

			var table = $('#tbl_customerImplementations').DataTable({

				scrollY: 630,
				scroller: true,
				scrollCollapse: true,

				columnDefs: [
					{targets: 'name', className: 'name dt-body-left'},
					{targets: 'startDate', className: 'startDate dt-body-center'},
					{targets: 'endDate', className: 'endDate dt-body-center'},
					{targets: 'actions', className: 'dt-body-center', orderable: false}
				],

				rowCallback: function( row, data, index ) {

					console.log( 'inside rowCallBack' );

					if ( moment().isBetween( moment( data[1] ), moment( data[2] ) ) ) {
						$( row ).addClass( 'active' );
					} else {
						$( row ).addClass( 'inactive' );
					}
					
				},
				
				order: [[1, 'desc']]
			});
		} );

	</script>
	
	
	<style>

		th.sort {
			cursor: url('images/baseline_import_export_black_18dp.png'), auto;
		}
		
		tr.inactive {
			color: lightgrey;
		}
		
		.name {
			width: 3000px;
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
	
			<!-- DIALOG: New Implementation -->
			<% if userPermitted(63) then %>
				<dialog id="dialog_addImplementation" class="mdl-dialog">
					<h4 class="mdl-dialog__title">New Intention</h4>
					<div class="mdl-dialog__content">
	
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<input class="mdl-textfield__input" type="date" id="add_implStartDate" onblur="UpdateImplEndDate_onBlur(this)" required>
								<label class="mdl-textfield__label" for="add_implStartDate">Start date...</label>
								<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy)</span>
							</div>
			
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<input class="mdl-textfield__input" type="text" id="add_implName" required>
								<label class="mdl-textfield__label" for="add_implName">Name...</label>
								<span class="mdl-textfield__error">Enter a name for the implementation</span>
							</div>
	
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<input class="mdl-textfield__input" type="date" id="add_implEndDate" onblur="UpdateImplStartDate_onBlur(this)" required>
								<label class="mdl-textfield__label" for="add_implEndDate">End date...</label>
								<span class="mdl-textfield__error">Enter a validate date (mm/dd/yyyy)</span>
							</div>
	
							<input id="add_implementationID" type="hidden">
							<input id="add_implCustomerID" type="hidden" value="<% =customerID %>">
				
					</div>
					<div class="mdl-dialog__actions">
						<button type="button" class="mdl-button save">Save</button>
						<button type="button" class="mdl-button cancel">Cancel</button>
					</div>
				</dialog><!-- END DIALOG -->
			<% end if %>
	
	
			<% if userPermitted(63) then %>
				<div class="mdl-grid">
					<div class="mdl-layout-spacer"></div>
					<div class="mdl-cell mdl-cell--5-col" align="left">
						<button id="button_newImplementation" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
						  New Intention
						</button>
					</div>
					<div class="mdl-layout-spacer"></div>
				</div>
			<% end if %>
	
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--5-col" align="center">
	
	
					<table id="tbl_customerImplementations" class="compact display">
						<thead>
							<tr>
								<th class="name">Name</th>
								<th class="startDate">Start Date</th>
								<th class="endDate">End Date</th>
								<th class="actions">Actions</th>
							</tr>
						</thead>
				  		<tbody> 
					  	<%
						SQL = "select " &_
									"i.id, " &_
									"i.name, " &_
									"format(i.startDate,'yyyy-MM-dd') as startDate, " &_
									"format(i.endDate,'yyyy-MM-dd') as endDate " &_
								"from customerImplementations i " &_
								"where i.customerID = " & customerID & " " &_
								"and (i.deleted = 0 or i.deleted is null) " &_
								"order by i.name desc "
																
						dbug(SQL)
						set rsImpl = dataconn.execute(SQL)
						while not rsImpl.eof
						  	%>
							<tr id="<% =rsImpl("id") %>" onclick="window.location.href='customerImplementationDetail.asp?customerID=<% =customerID %>&implementationID=<% =rsImpl("id") %>&tab=implementations';" style="cursor: pointer" onmouseover="ToggleImplActionIcons('<% =rsImpl("id") %>')" onmouseout="ToggleImplActionIcons('<% =rsImpl("id") %>')" >
								<td><% =rsImpl("name") %></td>
								<td><% =formatDateTime(rsImpl("startDate")) %></td>
								<td><% =formatDateTime(rsImpl("endDate")) %></td>
		   					<td>
									<div id="implementationIcons-<% =rsImpl("id") %>" class="actions" style="visibility: hidden; float: right; vertical-align: middle; align-content: center;">
										<% if userPermitted(64) then %><i class="material-icons deleteImplementation" data-val="<% =rsImpl("id") %>" style="cursor: pointer; vertical-align: middle;">delete_outline</i><% end if %>
										<i class="material-icons editImplementation" data-val="<% =rsImpl("id") %>" style="cursor: pointer; vertical-align: middle;">edit</i>
									</div>
		   					</td>
							</tr>
							<%
							rsImpl.movenext 
						wend 
						rsImpl.close 
						set rsImpl = nothing 
						%>
				  		</tbody>
					</table>
	
	
				</div>
				<div class="mdl-layout-spacer"></div>
			</div>
		</div>
		




	</main>

	<!-- #include file="includes/pageFooter.asp" -->

</div>

<script src="dialog-polyfill.js"></script>  
<script>
	
	var editImplementationButtons 		= document.querySelectorAll('.editImplementation'), i;
	var deleteImplementationButtons 	= document.querySelectorAll('.deleteImplementation'), j;
	
	
// New Implementation Controls
	var dialog_addImplementation = document.querySelector('#dialog_addImplementation');
	var button_newImplementation = document.querySelector('#button_newImplementation');	

	if (! dialog_addImplementation.showModal) {
		dialogPolyfill.registerDialog(dialog_addImplementation);
	}	

	button_newImplementation.addEventListener('click', function() {
		
		var currDate = moment().format('YYYY-MM-DD');
		
		document.getElementById('add_implStartDate').value = currDate;
		document.getElementById('add_implStartDate').parentNode.classList.add('is-dirty');
		document.getElementById('add_implStartDate').parentNode.classList.remove('is-invalid');
		
		document.getElementById('add_implEndDate').value = moment(currDate).add(3, 'years').format('YYYY-MM-DD');
		document.getElementById('add_implEndDate').parentNode.classList.add('is-dirty');
		document.getElementById('add_implEndDate').parentNode.classList.remove('is-invalid');
		
		dialog_addImplementation.showModal();
		
	});

	dialog_addImplementation.querySelector('.cancel').addEventListener('click', function() {
		dialog_addImplementation.close();
	});

	dialog_addImplementation.querySelector('.save').addEventListener('click', function() {
		EditCustomerImplementation_onSave(dialog_addImplementation);
		dialog_opportunity.close();
	});


	if (editImplementationButtons != null) {
		for (i = 0; i < editImplementationButtons.length; ++i) {
			editImplementationButtons[i].addEventListener('click', function(e) {
				e.preventDefault();
				e.stopPropagation();
				EditImplementation_onClick(this);
			})
		}
	}
	
	
	if (deleteImplementationButtons != null) {
		for (j = 0; j < deleteImplementationButtons.length; ++j) {
			deleteImplementationButtons[j].addEventListener('click', function(event) {
				deleteImplementation_onClick(this);
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