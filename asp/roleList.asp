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
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->
<!-- #include file="includes/sessionJWT.asp" -->
<!-- #include file="includes/apiServer.asp" -->
<% 
call checkPageAccess(10)

userLog("Role List")
title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png""><a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">Roles"

dbug("start of top-logic")

%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<!-- DataTables Editor -->
	<script type="text/javascript" src="Editor-2.5.1/js/dataTables.editor.js"></script>
	<script type="text/javascript" src="Editor-2.5.1/js/editor.jqueryui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="Editor-2.5.1/css/editor.dataTables.css">
	

	<!-- Moment.js -->
	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.18.1/moment.min.js"></script>


	<script>

		if ( typeof apiServer === 'undefined' ) var apiServer = '<% =apiServer %>';
		
		( function($) {
					 
			$( document ).ready( function() {
				
				$( document ).tooltip();


				$.extend( $.fn.dataTable.Editor.display.jqueryui.modalOptions, {
					title: "Test Title",
					width: 600,
					modal: true,
				});
				
				var editor = new $.fn.dataTable.Editor( {
					ajax: {
						url: `${apiServer}/api/roles`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					},
					table: '#roles',
					display: 'jqueryui',
					fields: [
						{ label: 'Role Name:',	name: 'name' }
					]
				});
	
				var table = $('#roles').DataTable( {
					dom: 'Bfrtip',
					ajax: {
						url: `${apiServer}/api/roles`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					},
					columns: [
						{ data: 'name', className: 'dt-body-left dt-head-left'},
						{ 
							data: 'deleted',
							className: 'dt-body-center dt-head-center',
							render: function(data, type, row) {
								if ( !data ) {
									return '<i class="editor-active material-symbols-outlined">check</i>';
								} else {
									return '<i></i>';
								}
								return data;
							},
 						},
						{ data: 'updatedby', 		visible: false  },
						{ data: 'updateddatetime', visible: false  }
					],
					lengthChange: false,
					scrollY: 630,
					scroller: {
						rowHeight: 36,
					},
					scrollCollapse: true,
					select: { style: 'single' },
					searching: false,
					buttons: [
						{ extend: 'create', editor: editor },
						{ extend: 'editSingle',   editor: editor }
// 						{ extend: 'removeSingle', editor: editor }
					]
				});	
	
				editor.on( 'create', function( e, json, data, id ) {
					console.log({ 'function': 'create', e: e, json: json, data: data, id: id });
				});
	
				editor.on( 'edit',  function( e, json, data, id ) {
					console.log({ 'function': 'edit', e: e, json: json, data: data, id: id });
					window.location.url = 'roleEdit.asp?id='+ data.id;
				});
	
				editor.on( 'preOpen',  function( e, mode, action ) {
					
					if ( action === 'edit' ) {
						const DT_RowId = this.ids()[0];
						const id = DT_RowId.substring( DT_RowId.indexOf('_')+1, DT_RowId.length );
						window.location.href = 'roleEdit.asp?id='+ id;
						return false;
					}

				});

				editor.on('open', function() {
					editor.title( 'Create new role' );
				});
				
				editor.on( 'remove', function( e, json, data, id ) {
					console.log({ 'function': 'delete', e: e, json: json, data: data, id: id });
				});
				
			});

 
		}(jQuery));


	</script>
	
	<style>
		
		/* Customized Styling For [D]ata[T]able [E]ditor */
		.DTE_Header { display: none; 	}
		.DTE_Body { padding-top: 0px !important; padding-bottom: 0px !important; }
		.DTE_Field { padding-left: 15px !important; padding-right: 15px !important; }
		.DTE_Footer { display: none; }		
		
	</style>
	
	
</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

	<main class="mdl-layout__content">
		<div class="page-content">
			<!-- Your content goes here -->
			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--4-col">

					
					<table id="roles" class="compact display" width="100%">
						<thead>
						<tr>
							<th class="name">Role Name</th>
							<th class="deleted">Active?</th>
							<th>updatedBy</th>
							<th>updatedDateTime</th>
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