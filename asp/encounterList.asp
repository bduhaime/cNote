<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(6)

title = "Events" 
%>
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

	    <div class="mdl-cell mdl-cell--3-col">
		    
				


	<table class="mdl-data-table mdl-js-data-table">
<!-- 	<table class="mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp"> -->
		<thead>
			<tr>
				<th class="mdl-data-table__cell--non-numeric">Name</th>
				<th class="mdl-data-table__cell--non-numeric"></th>
			</tr>
		</thead>
  		<tbody> 
		<%
		SQL = "select id, name from encounter order by name "
		dbug(SQL)
		set rs = dataconn.execute(SQL)
		while not rs.eof
			%>
			<tr>
				<td class="mdl-data-table__cell--non-numeric"><% =rs("name") %></td>
				<td class="mdl-data-table__cell--non-numeric"><a href="#"><img src="/images/ic_edit_black_24dp_1x.png"></a></td>
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
	
    
  </main>
</div>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>