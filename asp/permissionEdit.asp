<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(14)

userLog("Permission Edit, mode=" & mode)
dbug("before top-logic, mode=" & mode)

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""permissionList.asp?"">Permissions</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Edit A Permission" 

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	permissionID = request.querystring("id")
	
	SQL = "select id, name, deleted, description, csuiteOnly, nonCsuiteOnly, script_name, defaultParentScript, customerUserAllowed " &_
			"from cSuite..permissions " &_
			"where id = " & permissionID & " "
	
	dbug(SQL)
	set rs = dataconn.execute(SQL)
	dbug("rs objected successfully created")
	
	if not rs.eof then
		dbug("not rs.eof")
	else
		dub("rs.eof")
		response.write = "Permission not found."
	end if

end if

dbug("after top-logic")
%>

<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<!--getmdl-select-->   
	<link rel="stylesheet" href="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.css">
	<script defer src="https://cdn.rawgit.com/CreativeIT/getmdl-select/master/getmdl-select.min.js"></script>	

	<script type="text/javascript" src="permissionEdit.js"></script>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="includes/mdlLayoutHeader.asp" -->

<main class="mdl-layout__content">
	<div class="page-content">
		<!-- Your content goes here -->

		<div class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button type="button" class="mdl-snackbar__action"></button>
		</div>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 500px;">
				    <input class="mdl-textfield__input attribute" type="text" id="name" value="<% =trim(rs("name")) %>" <% =disabled %>>
				    <label class="mdl-textfield__label" for="permissionName">Permission name...</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 500px;">
					<textarea class="mdl-textfield__input attribute" type="text" rows="4" id="description" <% =disabled %>><% =rs("description") %></textarea>
					<label class="mdl-textfield__label" for="description">Description...</label>
				</div>							

			</div>
			<div class="mdl-cell mdl-cell--2-col">

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="deleted">
						<input type="checkbox" id="deleted" class="mdl-switch__input attribute" <% if rs("deleted") then response.write("checked") end if %> <% =disabled %>>
						<span class="mdl-switch__label">Deleted?</span>
					</label>
				</div>

				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="customerUserAllowed">
						<input type="checkbox" id="customerUserAllowed" class="mdl-switch__input attribute" <% if rs("customerUserAllowed") then response.write("checked") end if %> <% =disabled %>>
						<span class="mdl-switch__label">Customer User Allowed?</span>
					</label>
				</div>
					
			</div>
			<div class="mdl-cell mdl-cell--2-col">
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="csuiteOnly">
						<input type="checkbox" id="csuiteOnly" class="mdl-switch__input attribute" <% if rs("csuiteOnly") then response.write("checked") end if %> <% =disabled %>>
						<span class="mdl-switch__label">cSuite Only?</span>
					</label>
				</div>
				
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="nonCsuiteOnly">
						<input type="checkbox" id="nonCsuiteOnly" class="mdl-switch__input attribute" <% if rs("nonCsuiteOnly") then response.write("checked") end if %> <% =disabled %>>
						<span class="mdl-switch__label">Non-cSuite Only?</span>
					</label>
				</div>
					
			</div>
			
			
			<% if cInt(session("userID")) = 0 then %>
			<div class="mdl-cell mdl-cell--2-col">

					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					    <input class="mdl-textfield__input" type="text" id="scriptName" value="<% =rs("script_name") %>" disabled>
					    <label class="mdl-textfield__label" for="permissionName">Script name...</label>
					</div>

					<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" >
					    <input class="mdl-textfield__input" type="text" id="defaultParentScript" value="<% =rs("defaultParentScript") %>" disabled>
					    <label class="mdl-textfield__label" for="defaultParentScript">Default parent script...</label>
					</div>

			</div>
			<% end if %>

			<div class="mdl-layout-spacer"></div>
		</div>

		<hr>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">
				<div class="mdl-typography--title"><% =session("dbName") %> Users</div>
				<hr>
				<ul class="demo-list-control mdl-list">
					<%
					DBUG("prior to SQL")
					SQL = "select u.id, u.username, rtrim(u.firstName)+' '+rtrim(u.lastName) as name, up.permissionID " &_
							"from cSuite..users u " &_
							"join cSuite..clientUsers cu on (cu.userID = u.id and cu.clientID = " & session("clientNbr") & ") " &_
							"left join userPermissions up on (up.userID = u.id and up.permissionID = " & permissionID & ") " &_
							"order by username "
							
' 					SQL = "select u.id, u.username, rtrim(u.firstName)+' '+rtrim(u.lastName) as name, u.permissionID " &_
' 							"from cSuite..users u " &_
' 							"join cSuite..clientUsers cu on (cu.userID = u.id and cu.clientID = " & session("clientNbr") & " " &_
' 							"left join userPermissions on (userPermissions.userID = users.id and userPermissions.permissionID = " & permissionID & ") order by username "
					dbug(SQL)
					set rsUP = dataconn.execute(SQL)
					
					while not rsUP.eof	

						if not isNull(rsUP("permissionID")) then
							if cInt(rsUP("permissionID")) = cInt(permissionID) then 
								checked = "checked"
							else
								checked = ""
							end if
						else
							checked = ""
						end if
						
						%>
						<li class="mdl-list__item mdl-list__item--two-line">
							<span class="mdl-list__item-secondary-action">
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox-up-<% =permissionID %>-<% =rsUP("id") %>">
									<input type="checkbox" id="checkbox-up-<% =permissionID %>-<% =rsUP("id") %>" data-id="<% =rsUP("id") %>" class="mdl-checkbox__input userPermission" <% =checked %> />
								</label>
							</span>
							
							<span class="mdl-list__item-primary-content">
								<span><% =rsUP("username") %></span>
									<span class="mdl-list__item-sub-title"><% =rsUP("name") %></span>
							</span>
							
							
						</li>
						<%
						rsUP.movenext 
					wend
					rsUP.close 
					set rsUP = nothing 
					%>						
				</ul>

			</div>
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">
				<div class="mdl-typography--title"><% =session("dbName") %> Roles</div>
				<hr>
				<ul class="demo-list-control mdl-list">
					<%
					SQL = "select id, name, permissionID " &_
							"from roles " &_
							"left join rolePermissions on (rolePermissions.roleID = roles.id and rolePermissions.permissionID = " & permissionID & ") " &_
							"order by name "
					dbug("roles: " & SQL)
					set rsRP = dataconn.execute(SQL)
					while not rsRP.eof					

						if not isNull(rsRP("permissionID")) then
							if cInt(rsRP("permissionID")) = cInt(permissionID) then 
								checked = "checked"
							else
								checked = ""
							end if
						else
							checked = ""
						end if
						
						%>
						<li class="mdl-list__item">
							<span class="mdl-list__item-secondary-action">
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox-rp-<% =permissionID %>-<% =rsRP("id") %>">
									  <input type="checkbox" id="checkbox-rp-<% =permissionID %>-<% =rsRP("id") %>" data-id="<% =rsRP("id") %>" class="mdl-checkbox__input rolePermission" <% =checked %> />
								</label>
							</span>

							<span class="mdl-list__item-primary-content">
								<span><% =rsRP("name") %></span>
<!-- 								<span class="mdl-list__item-sub-title">RolePermission</span> -->
							</span>
							
						</li>
						<%
						rsRP.movenext 
					wend
					rsRP.close 
					set rsRP = nothing 
					dbug("done with roles")
					%>						
				</ul>

			</div>

			<div class="mdl-layout-spacer"></div>
		</div>
	</div>

</main>

	<!-- #include file="includes/pageFooter.asp" -->

 <script>
	 	
	// ****************************************************************************************/
	// Add Event Listeners for the attributes...
	// ****************************************************************************************/
	
	var attributes = document.querySelectorAll('.attribute');
	if (attributes) {
		
		for (i = 0; i < attributes.length; ++i) {

			attributes[i].addEventListener('change', function(event) {
				EditAttribute(this, <% =permissionID %>);
			})

		}
		
	}
	
	
	var userPermissions = document.querySelectorAll('.userPermission');
	if (userPermissions) {
		
		for (i = 0; i < userPermissions.length; ++i) {

			userPermissions[i].addEventListener('click', function(event) {
				UserPermission_onClick(this.getAttribute('data-id'),<% =permissionID %>);
			})

		}
		
	}
	
	
	var rolePermissions = document.querySelectorAll('.rolePermission');
	if (rolePermissions) {
		
		for (i = 0; i < rolePermissions.length; ++i) {

			rolePermissions[i].addEventListener('click', function(event) {
				RolePermission_onClick(this.getAttribute('data-id'),<% =permissionID %>);
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