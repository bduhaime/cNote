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

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->
   
		<div class="mdl-grid">
	
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--8-col">

				<table class="mdl-data-table mdl-js-data-table mdl-data-table mdl-shadow--2dp">
				  <thead>
				    <tr>
				      <th class="mdl-data-table__cell--non-numeric">Key Initiative</th>
				      <th class="mdl-data-table__cell"></th>
				    </tr>
					 </thead>
				  <tbody>
				    <tr>
				      <td id="nim" class="mdl-data-table__cell--non-numeric">Improve NIM</td>
						<!-- Multiline Tooltip -->
						<div class="mdl-tooltip" for="nim">
							Lorem ipsum dolor sit amet, orci bibendum tempor suscipit lacus quaerat a, semper wisi montes magna. Orci sed turpis. Etiam egestas nulla, augue aliquam mauris nullam potenti morbi tristique. Sed ipsum in arcu. Sagittis netus lectus elit amet ac, in molestie amet. Tortor dignissimos quis luctus. Ridiculus sit, feugiat nunc nulla exercitation diam, sem vestibulum odio feugiat tempor. Quam ad ut donec laoreet mauris wisi, quisque nec. Eget velit amet tempor blandit, tellus in dui commodo, diam nec, pede fusce sem amet nibh elit, ultricies commodo nullam in.

						</div>				      
						<td class="mdl-data-table__cell">
					      <i class="material-icons">keyboard_arrow_down</i>
				      </td>
				    </tr>
				    <tr>
						<td class="mdl-data-table--non-numeric" colspan="3" >
							<div align="left" style="width: 780px; overflow-wrap: normal; display: inline-block; white-space:normal;">
							Lorem ipsum dolor sit amet, orci bibendum tempor suscipit lacus quaerat a, semper wisi montes magna. Orci sed turpis. Etiam egestas nulla, augue aliquam mauris nullam potenti morbi tristique. Sed ipsum in arcu. Sagittis netus lectus elit amet ac, in molestie amet. Tortor dignissimos quis luctus. Ridiculus sit, feugiat nunc nulla exercitation diam, sem vestibulum odio feugiat tempor. Quam ad ut donec laoreet mauris wisi, quisque nec. Eget velit amet tempor blandit, tellus in dui commodo, diam nec, pede fusce sem amet nibh elit, ultricies commodo nullam in.
							</div>
							<br>

							<table id="tbl_clientProjects" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
								<thead>
									<tr>
										<th class="mdl-data-table__cell--non-numeric">Name</th>
										<th class="mdl-data-table__cell--non-numeric">Process</th>
										<th class="mdl-data-table__cell--non-numeric">Primary PM</th>
										<th class="mdl-data-table__cell--non-numeric">Start Date</th>
										<th class="mdl-data-table__cell--non-numeric">End Date</th>
										<th class="mdl-data-table__cell--non-numeric">Status</th>
										<th class="mdl-data-table__cell--non-numeric">Completed</th>
									</tr>
								</thead>
						  		<tbody> 
							  	
									<tr onclick="window.location.href='taskList.asp?id=1&tab=projects';" style="cursor: pointer">
										<td class="mdl-data-table__cell--non-numeric">Test Project 1</td>
										<td class="mdl-data-table__cell--non-numeric"></td>
										<td class="mdl-data-table__cell--non-numeric">Brad Duhaime</td>
										<td class="mdl-data-table__cell--non-numeric">7/10/2018</td>
										<td class="mdl-data-table__cell--non-numeric">11/1/2018</td>
										<td class="mdl-data-table__cell--non-numeric"></td>
										<td class="mdl-data-table__cell--non-numeric"></td>
									</tr>
									
									<tr onclick="window.location.href='taskList.asp?id=2&tab=projects';" style="cursor: pointer">
										<td class="mdl-data-table__cell--non-numeric">Test Project 2 from template</td>
										<td class="mdl-data-table__cell--non-numeric"></td>
										<td class="mdl-data-table__cell--non-numeric">Brad Duhaime</td>
										<td class="mdl-data-table__cell--non-numeric">7/30/2018</td>
										<td class="mdl-data-table__cell--non-numeric">11/26/2018</td>
										<td class="mdl-data-table__cell--non-numeric"></td>
										<td class="mdl-data-table__cell--non-numeric"></td>
									</tr>
									
						  		</tbody>
							</table>






						</td>
				    </tr>
				    <tr>
				      <td class="mdl-data-table__cell--non-numeric">Grow Net Assets</td>
				      <td class="mdl-data-table__cell">
					      <i class="material-icons">keyboard_arrow_right</i>
				      </td>
				    </tr>
				    <tr>
				      <td class="mdl-data-table__cell--non-numeric">Improve Employee Morale</td>
				      <td class="mdl-data-table__cell">
					      <i class="material-icons">keyboard_arrow_right</i>
				      </td>
				    </tr>
				  </tbody>
				</table>
				

			 
				
			</div>
			<div class="mdl-layout-spacer"></div>

		</div><!-- end mdl-grid -->
		
  	</div> <!-- end page-content -->
	   
</main>
<!-- #include file="includes/pageFooter.asp" -->


</body>
</html>