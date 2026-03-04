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
call checkPageAccess( 140 )


title = session("clientID") & " - Mystery Shopping: Question Categories" 
userLog(title)

%>
<html>

<head>
	
	<!-- #include file="includes/globalHead.asp" -->

	<!-- DataTables Editor -->
	<script type="text/javascript" src="Editor-2.5.1/js/dataTables.editor.js"></script>
	<script type="text/javascript" src="Editor-2.5.1/js/editor.jqueryui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="Editor-2.5.1/css/editor.dataTables.css">


	<!-- 	<script src="https://unpkg.com/dayjs@1.8.21/dayjs.min.js"></script> -->

	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.18.1/moment.min.js"></script>
	<script src="//cdn.datatables.net/plug-ins/1.10.21/sorting/datetime-moment.js"></script>

	<script>

		( function($) {
					 
			$( document ).ready( function() {
				
				$( document ).tooltip();
				

				var editor = new $.fn.dataTable.Editor( {
					ajax: {
						url: `${apiServer}/api/mysteryShopping/questionCategories`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					},

					formOptions: {
						main: {
							onEsc: 'none'
						}
					},

					table: "#questionCategories",
					fields: [ 
						{ label: "Name:", 		name: "name" }, 
						{ label: "Sequence:", 	name: "seq" }
					]
				});
							
	
				$('#questionCategories').DataTable( {
					<% if userPermitted( 130 ) then %>
					dom: "Bfrtip",
					<% end if %>
					ajax: { 
						url: `${apiServer}/api/mysteryShopping/questionCategories`,
						headers: { 'Authorization': 'Bearer ' + sessionJWT },
					},
					columns: [
						{ data: 'name' },
						{ data: 'seq', className: 'seq' }
					],
					scrollX: true,
					scrollY: 630,
					scroller: true,
					scrollCollapse: true,
					select: true,
					lengthChange: false,
					searching: false,
					buttons: [
						{ extend: "create", editor: editor },
						{ extend: "edit",   editor: editor },
						{ extend: "remove", editor: editor }
					],
					order: [[ 1, 'asc' ]],
				});
	
	
				editor.on( 'create', function( e, json, data, id ) {
					console.log({ 'function': 'create', e: e, json: json, data: data, id: id });
				});
	
				editor.on( 'edit',  function( e, json, data, id ) {
					console.log({ 'function': 'edit', e: e, json: json, data: data, id: id });
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

		
		table.dataTable > tbody > tr:hover {
			cursor: pointer;
		}

		i.delete, i.edit, i.contracts {
			visibility: hidden;
		}
		
		
		table {
			width: 100%;
			table-layout: fixed;
			overflow-wrap: break-word;
		}
		
		#questionCategories td.seq {
			text-align: center;
		}
		
		#questionCategories th {
			text-align: left;
		}
		
		#questionCategories th.title {
			text-align: center;
			background: lightgrey;
		}
		
		
		

		
	</style>
	
</head>
	
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
			
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--5-col">
		
				<table id="questionCategories" class="compact display" width="100%">
					<thead>
						<tr>
							<th class="name">Name</th>
							<th class="seq">Sequence</th>
						</tr>
					</thead>
				</table>
				
			</div>

			<div class="mdl-layout-spacer"></div>
		
		</div><!-- end mdl-grid -->
		
	</div><!-- end page-content -->
    
	<!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>