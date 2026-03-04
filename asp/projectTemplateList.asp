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
<!-- #include file="includes/getNextID.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(40)

userLog("Project templates")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Project Templates"

dbug(" ")
dbug("start of script....")

dbug("request.querystring('cmd'): " & request.querystring("cmd"))

' select case request.querystring("cmd")
' 
' 	case "delete"
' 	
' 		dbug("delete detected")
' 		
' 		SQL = "delete from customerCallTypes where id = " & request.querystring("id") & " " 
' 		
' 		dbug(SQL)
' 		set rsDelete = dataconn.execute(SQL)
' 		set rsDelete = nothing 
' 		
' 		SQL = "delete from noteTypes where callTypeID = " & request.querystring("id") & " " 
' 		
' 		dbug(SQL)
' 
' 		set rsDelete = dataconn.execute(SQL)
' 		set rsDelete = nothing 		
' 		
' 	case else 
' 	
' end select 


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

	<script type="text/javascript" src="projectTemplateList.js"></script>


	<script>
		
		$(document).ready(function() {

			$( document ).tooltip();
						
			$.fn.dataTable.moment( 'M/D/YYYY' );
			$.fn.dataTable.moment( 'H:mm A' );

			var table = $( '#projectTemplates' )
				.on('click', '.deleteButton', function (event) {
					const id = $(this).data('val');
					DeleteProjectTemplate_OnClick(id);
					$( '#projectTemplates' ).DataTable().ajax.reload();
					event.stopPropagation();
				})


				.on('click', 'tr', function ( event ) {
					window.location.href = `projectTemplateTaskList.asp?id=${this.id}`;
				})

				.css('width', '800px')
				.DataTable({
	
					ajax: {
						url: `${apiServer}/api/projectTemplates?ts=${Date.now()}`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
						dataSrc: ''
					},
					autoWidth: true,
					rowId: 'id',
					scrollY: 650,
					scroller: {
						rowHeight: 30
					},
					scrollCollapse: true,
					columns: [
						{ data: 'name', className: 'name dt-body-left' },
						{ data: 'updatedByName', className: 'updatedByName dt-body-left' },
						{
							data: 'updatedDateTime',
							className: 'updatedDateTime dt-body-left',
							defaultContent: '',
							render: function ( data, type ) {

								if ( !data ) return '';
								
								const d = new Date(data);
								
								if ( type === 'display' ) {
									return moment( d ).format( 'M/D/YYYY h:mm:ss A' );
								}
								
								// For sorting/search, return a numeric timestamp
								return d.getTime();


							}
						},
						{
							data: null,                           // <-- not 'id'
							className: 'actions dt-body-center',
							orderable: false,
							defaultContent: '',
							render: function (_data, _type, row) {
								const id = row && row.id ? row.id : '';
								if ( !id ) return '';
								return `<i id="project-${id}" class="material-symbols-outlined deleteButton"
									data-val="${id}" style="vertical-align:text-bottom; cursor:pointer"
									title="Click to delete this template and all of its tasks">delete</i>`;
							}
						},
	
					],
					order: [ [0, 'asc'] ],
					width: 800,
				});

		});

	</script>
	
	<style>

		
		#projectTemplates i.deleteButton { 
			display: none; 
		}
		
		#projectTemplates tbody tr:hover i.deleteButton { 
			display: inline-block; 
		}
		
	</style>

</head>

<body>

<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
  
	<div class="mdl-snackbar mdl-js-snackbar">
		<div class="mdl-snackbar__text"></div>
		<button type="button" class="mdl-snackbar__action"></button>
	</div>
	

	<div class="page-content">
		<!-- Your content goes here -->

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col">

				<br><br>
				<table id="projectTemplates" class="compact display">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="updatedByName">Creator</th>
							<th class="updatedDateTime">Creation Date/Time</th>
							<th class="actions">Actions</th>
						</tr>
					</thead>
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