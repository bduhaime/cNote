<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/createDisconnectedRecordset.asp" -->

<html>

<head>
	<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
	<link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css">
	<script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script>
</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title">Title</span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
      <!-- Navigation. We hide it in small screens. -->
      <nav class="mdl-navigation mdl-layout--large-screen-only">
        <a class="mdl-navigation__link" href="">Link</a>
        <a class="mdl-navigation__link" href="">Link</a>
        <a class="mdl-navigation__link" href="">Link</a>
        <a class="mdl-navigation__link" href="">Link</a>
      </nav>
    </div>
  </header>
  <div class="mdl-layout__drawer">
    <span class="mdl-layout-title">Title</span>
    <nav class="mdl-navigation">
      <a class="mdl-navigation__link" href="">Link</a>
      <a class="mdl-navigation__link" href="">Link</a>
      <a class="mdl-navigation__link" href="">Link</a>
      <a class="mdl-navigation__link" href="">Link</a>
    </nav>
  </div>
  <main class="mdl-layout__content">
    <div class="page-content">
    <!-- Your content goes here -->
    
	<p>Hello World!</p>
	<p> current time is: <% =time() %></p>
  
	<p>
    <%
	set rs = dataconn.execute("select count(*) as instCount from fdic.dbo.institutions")
	if not rs.eof then
	dbug("instCount: " & rs("instCount"))
	else
		dbug("rs.eof encountered unexpectedly")
	end if
	rs.close
	set rs = nothing
	
	
	%>
	</p>
	
	<p>Select an Institution:</p>
	
	<!-- Standard Select -->
	<div class="mdl-selectfield">
		<label>Select a state:</label>
		<select id="selectState" class="browser-default" onChange="return stateOnChange();">
			<option value="" disabled selected>Choose a state</option>
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
	</div>
    
    
    
    </div>
  </main>
</div>


</body>
</html>