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
<!-- #include file="includes/getDrilldownParameters.asp" -->
<% 
call checkPageAccess(43)

customerID = request.querystring("customerID")
if ( len(customerID) <= 0  OR  not isNumeric(customerID) ) then 
	dbug("customerID is missing or invalid: " & customerID & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
end if 

surveyType = request.querystring("surveyType") 
if ( surveyType <> 1 AND surveyType <> 2 ) then 
	dbug("surveyType is missing or invalid: " & surveyType & ", status=412 returned to user")
	response.Status = "412 Precondition Failed"
	response.end()
else 
	if surveyType = 1 then 
		subtitle = "Firmographic Questions"
	elseif surveyType = 2 then 
		subtitle = "Psychographic Questions"
	else 
		dbug("surveyType is missing or invalid: " & surveyType & ", status=412 returned to user")
		response.Status = "412 Precondition Failed"
		response.end()
	end if 
end if 


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

	<link rel="stylesheet" href="../DataTables/datatables.min.css" />
	<link rel="stylesheet" href="cProfitStyle.css" />

	<script src="../jQuery/jquery-3.5.1.min.js"></script>
	<script src="../DataTables/datatables.min.js"></script>
	<script src="../moment.min.js"></script>

	<script src="customerProfit.js"></script>
	<script src="makeNegativeValueRed.js"></script>

	<script>

		const customerID = <% =customerID %>;
		const surveyType = <% =surveyType %>;
		
		$(document).ready(function() {

			var table = $('#cNoteDataTable')
				.DataTable({
					paging: false,
					scrollY: 600,
					info: false,
					searching: true,
					processing: true,
					rowReorder: {
						dataSrc: 'seq'
					},
					serverSide: false,
					ajax: {
						url: '/cProfit/ajax/firmographics.asp',
						type: 'post',
						data: {
							customerID: customerID,
							surveyType: surveyType,
						}
					},
					columnDefs: [
						{targets: 'seq',					data: 'seq', 				orderable: true, 	className: 'reorder dt-body-center'},
						{targets: 'prompt',				data: 'prompt', 			orderable: false, className: 'dt-body-left'},
						{targets: 'responseType',		data: 'responseType', 	orderable: false, className: 'dt-body-center	'},
						{targets: 'responseValues',	data: 'responseValues', orderable: false, className: 'responseValues dt-body-left'},
						{targets: 'regex',				data: 'regex', 			orderable: false, className: 'dt-body-center'},
						{targets: 'source',				data: 'source', 			orderable: false, className: 'dt-body-left'}
					]
// 					order: [[ 0, 'asc' ]],
				});

				table.on( 'row-reorder', async function ( e, diff, edit ) {
					
					var result = 'Reorder started on row: '+edit.triggerRow.data()[1]+'\n';
					var arrReorderedRows = [];
					
					for ( var i=0, ien=diff.length ; i<ien ; i++ ) {
						var rowData = table.row( diff[i].node ).data();
						
						result += '['+rowData.DT_RowId+'] ' + rowData.prompt+' updated to be in position '+
						diff[i].newData+' (was '+diff[i].oldData+')\n';
						
// 						arrReorderedRows.push({
// 							id: rowData.DT_RowId, 
// 							newSeq: diff[i].newData
// 						});

						if ( arrReorderedRows.length > 0 ) {
							arrReorderedRows += '|';
						}
						arrReorderedRows += rowData.DT_RowId + ',' + diff[i].newData;
						
					}
					
					const notification = document.querySelector('.mdl-js-snackbar');
					const apiResponse = await fetch('/cProfit/ajax/customerSurveyReorder.asp?customerID='+customerID+'&surveyType='+surveyType+'+&arrReorderedRows='+JSON.stringify(arrReorderedRows));
					if (apiResponse.status != 200) {
						return generateErrorResponse('failed to toggle account holder star indicator, ' + apiResponse.status);
					}
					var apiResult = await apiResponse.json();
					notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

					
														
					
				} );
				
			});
			
			

	</script>

	<style>

		table.dataTable tbody tr:hover {
			cursor: default;
		}

		td.responseValues {
			max-width: 450px;
			text-overflow: ellipsis;
			white-space: nowrap;
			overflow: hidden;		
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
  
  
	<div class="mdl-layout__drawer">
		<span class="mdl-layout-title">Customer View</span>
	</div>

	<main id="mainContent" class="mdl-layout__content">
  
		<div class="page-content">
				
			<!-- Your content goes here -->

			<!-- SNACKBAR -->
			<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
			    <div class="mdl-snackbar__text"></div>
			    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
			</div>



			<div class="mdl-grid">
				<div class="mdl-layout-spacer"></div>
				<div class="mdl-cell mdl-cell--10-col reportTitle"><% =subtitle %></div>
				<div class="mdl-layout-spacer"></div>
			</div>
			
			<div class="mdl-grid">
		
				<div class="mdl-layout-spacer"></div>
		
				<div class="mdl-cell mdl-cell--8-col mdl-shadow--2dp" style="padding: 15px;">

					<table id="cNoteDataTable" class="compact display nowrap">
						<thead>
							<tr>
								<th class="seq">Seq</th>
								<th class="prompt">Prompt</th>
								<th class="responseType">Type</th>
								<th class="responseValues">Values</th>
								<th class="regex">Pattern</th>
								<th class="source">Source</th>
							</tr>
						</thead>
					</table>

				</div>
		
				<div class="mdl-layout-spacer"></div>
		
			</div>


		</div>

		<!-- #include file="includes/contextMenu.asp" -->
	        
	</main>
<!-- #include file="../includes/pageFooter.asp" -->
</div>


</body>
</html>