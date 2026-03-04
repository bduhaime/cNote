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
call checkPageAccess(13)

userLog("Role Edit")
dbug("before top-logic")

title = session("clientID") & " - <a href=""admin.asp?"">Administration</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""security.asp?"">Security</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "<a href=""roleList.asp?"">Roles</a><img src=""images/ic_chevron_right_white_18dp_2x.png"">"
title = title & "Edit A Role" 

if len(request.querystring("id")) > 0 then
	dbug("'id' value present in querystring")
	
	roleID = request.querystring("id")
	
	SQL = 	"select id, name, deleted " &_
			"from roles " &_
			"where id = " & roleID & " "
	
	dbug(SQL)
	set rs = dataconn.execute(SQL)
	dbug("rs objected successfully created")
	
	if not rs.eof then
		dbug("not rs.eof")
	else
		dub("rs.eof")
		response.write = "Role not found."
	end if

end if

dbug("after top-logic")
%>

<html>

<head>

	<!-- #include file="includes/globalHead.asp" -->
	
	<!--getmdl-select-->   
	<script src="list.min.js"></script>
	<script src="roleEdit.js"></script>
	<script src="userEdit.js"></script>

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
			
			<input type="hidden" id="roleID" value="<% =roleID %>">
			
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--6-col">
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
				    <input class="mdl-textfield__input roleAttribute" type="text" id="name" value="<% =server.htmlEncode(trim(rs("name"))) %>" >
				    <label class="mdl-textfield__label" for="name">Role name...</label>
				</div>
				<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
					<label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="deleted">
						<input type="checkbox" id="deleted" class="mdl-switch__input roleAttribute" <% if rs("deleted") then response.write("checked") end if %> >
						<span class="mdl-switch__label">Deleted?</span>
					</label>
				</div>
			</div>
			<div class="mdl-layout-spacer"></div>
		</div>

		<hr>

		<div class="mdl-grid">
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--3-col">
				<div class="mdl-typography--title">Users</div>
				<hr>
				<ul class="demo-list-control mdl-list">
					<%
					DBUG("prior to SQL")
					SQL = 	"select id, username, rtrim(firstName)+' '+rtrim(lastName) as name, roleID " &_
							"from cSuite..users " &_
							"left join userRoles on (userRoles.userID = users.id and userRoles.roleID = " & roleID & ") order by username "
					dbug(SQL)
					set rsUR = dataconn.execute(SQL)
					
					while not rsUR.eof	

						if not isNull(rsUR("roleID")) then
							if cInt(rsUR("roleID")) = cInt(roleID) then 
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
								<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox-ur-<% =roleID %>-<% =rsUR("id") %>">
									  <input type="checkbox" id="checkbox-ur-<% =roleID %>-<% =rsUR("id") %>" data-id="<% =roleID %>" class="mdl-checkbox__input" <% =checked %> onclick="UserRole_onClick(this,<% =rsUR("id") %>)" />
								</label>
							</span>
							
							<span class="mdl-list__item-primary-content">
								<span><% =rsUR("username") %></span>
									<span class="mdl-list__item-sub-title"><% =rsUR("name") %></span>
							</span>
							
							
						</li>
						<%
						rsUR.movenext 
					wend
					rsUR.close 
					set rsUR = nothing 
					%>						
				</ul>

			</div>
			<div class="mdl-layout-spacer"></div>
			<div class="mdl-cell mdl-cell--4-col">
				
<!-- 				<div id="permissionListContainer" style="border: solid red 1px; position: relative;"> -->

				<div id="permissionListContainer" style="position: relative;">
					<div class="mdl-typography--title" style="width: 300px;">Permissions</div>
	
					<!-- Expandable Textfield -->
					<div class="mdl-textfield mdl-js-textfield mdl-textfield--expandable" style="position: absolute; top: 0px; right: 0px; padding-top: 0px;">
						<label class="mdl-button mdl-js-button mdl-button--icon" for="search" style="top: 0px;">
							<i class="material-icons">search</i>
						</label>
						<div class="mdl-textfield__expandable-holder" style="top: 0px; ">
							<input id="search" class="mdl-textfield__input search" type="text" autocomplete="off">
						</div>
					</div>
	
	
					<hr>
					<ul class="demo-list-control mdl-list list">
						<%
						if cInt(session("clientNbr")) <> 1 then 
							SQL = "select p.id, p.name, rp.roleID, p.description " &_
									"from cSuite..permissions p " &_
									"left join rolePermissions rp on (rp.permissionID = p.id and rp.roleID = " & roleID & ") " &_
									"where (p.deleted = 0 or p.deleted is null) " &_
									"and (p.csuiteOnly = 0 or p.csuiteOnly is null) " &_
									"order by name "
						else  
							SQL = "select p.id, p.name, rp.roleID, p.description " &_
									"from cSuite..permissions p " &_
									"left join rolePermissions rp on (rp.permissionID = p.id and rp.roleID = " & roleID & ") " &_
									"where (p.deleted = 0 or p.deleted is null) " &_
									"order by name "
						end if 
	
						dbug("permissions: " & SQL)
						set rsUP = dataconn.execute(SQL)
						while not rsUP.eof					
	
							if not isNull(rsUP("roleID")) then
								if cInt(rsUP("roleID")) = cInt(roleID) then 
									checked = "checked"
								else
									checked = ""
								end if
							else
								checked = ""
							end if
							
							%>
							<li class="mdl-list__item <% if userPermitted(12) then response.write("mdl-list__item--two-line") end if %>">
								<span class="mdl-list__item-secondary-action">
									<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect" for="checkbox-up-<% =rsUP("id") %>-<% =roleID %>">
										<input type="checkbox" id="checkbox-up-<% =rsUP("id") %>-<% =roleID %>" class="mdl-checkbox__input" <% =checked %> onclick="RolePermission_onClick(<% =roleID %>,<% =rsUP("id") %>)" />
									</label>
								</span>
								<span class="mdl-list__item-primary-content">
									<span class="permissionName"><% =rsUP("name") %></span>
									<% if userPermitted(12) then %>
										<span class="mdl-list__item-sub-title">permissionID=<% =rsUP("id") %></span>
									<% end if %>
								</span>
							</li>
							<%
							rsUP.movenext 
						wend
						rsUP.close 
						set rsUP = nothing 
						dbug("done with permissions")
						%>						
					</ul>
					
<!-- 				</div> -->

				</div>
				
			</div>

			<div class="mdl-layout-spacer"></div>
		</div>
	</div>

</main>
<!-- #include file="includes/pageFooter.asp" -->
<script>
	
	var roleAttributes = document.querySelectorAll('.roleAttribute');
	if (roleAttributes) {
		for (i = 0; i < roleAttributes.length; ++i) {
			roleAttributes[i].addEventListener('change', function() {
				RoleAttribute_onChange(this);
			})
		}
	}
	

	 var searchField = document.getElementById('search');
	 if (searchField) {
		 searchField.addEventListener('click', function() {
			 this.select();
		 });
	 }
	 

	var options = {
		valueNames: [
			'permissionName' 
		]
	};
	
	var permList = new List('permissionListContainer', options);
	
	var searchElem = document.getElementById('search');
	permList.on('searchStart', function() {

		// for all non-first time searches, first clear the filter and start over
		permList.filter();

	});

</script>

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>