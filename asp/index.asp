<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<% dbug("top of index") %>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
	<script type="text/javascript" src="index.js"></script>
</head>

<body>
<% title = session("clientID") & " - Analytics" %>
<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

  <main class="mdl-layout__content">
    <div class="page-content">
    <!-- Your content goes here -->
   	<div class="mdl-grid">

	    <div class="mdl-cell mdl-cell--6-col">
		    
				
			<table>
				<tr>
					<td align="right">State:</td>
					<td>
						<select id="selectInstState" class="browser-default" onChange="return instState_OnChange(this);">
							<option value="" disabled selected>Make a selection...</option>
							<%
							SQL = "select distinct stalp from fdic.dbo.institutions order by stalp "
							set rs = dataconn.execute(SQL)
							while not rs.eof
								%>    
								<option value="<% =rs("stalp") %>"><% =rs("stalp") %></option>
								<%
								rs.movenext
							wend
							rs.close 
							set rs = nothing
							%>
							
						</select>
					</td>
				</tr>
				<tr>
					<td align="right">Institution:</td>
					<td>
						<select id="institutionList" class="browser-default" onChange="return instList_onChange(this);">
						</select>
					</td>
				</tr>
			</table>
			
	    </div>
	    <div class="mdl-cell mdl-layout-spacer">

			<table id="instHeader" style="display: none;">
				<tr>
					<td align="right">City:</td><td id="instCity"></td>
					<td align="right">Assets:</td><td id="instAsset"></td>
					<td align="right">CB:</td><td id="instCB"></td>
				</tr>
				<tr>
					<td align="right">Specialty:</td><td id="instSpecgrpn"></td>
					<td align="right">Offices:</td><td id="instOffdom"></td>
					<td align="right">Mutual:</td><td id="instMutual"></td>
				</tr>
			</table>
									
	    </div>
		    			    
	</div>
	<hr>
   	<div class="mdl-grid">
		<div id="chart_div" style="width: 900px; height: 500px;"></div>	   	
   	</div>

	
    
  </main>
</div>


</body>
<script type="text/javascript">
	
	google.charts.load('current', {'packages':['corechart']});
// 	google.charts.setOnLoadCallback(drawVisualization);
	google.charts.setOnLoadCallback(populateInstDetails);

</script>
</html>