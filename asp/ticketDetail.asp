<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/usersWithPermission.asp" -->
<!-- #include file="upload.asp" -->
<% 
title = "Ticket Detail" 

ticket = request.querystring("id")

select case request.querystring("cmd") 

	case "upload"
	
		dbug("upload detected")

		' Create the FileUploader
		dim Uploader, file
		set Uploader = new FileUploader
		
		dbug("uploader instantiated, starting upload...")
		
		' This starts the upload process
		Uploader.Upload()
		
		dbug("upload complete, now let's deal with those files...")
		
		if Uploader.Files.Count = 0 then
			dbug("File(s) not uploaded")
		else
			dbug("File(s) uploaded...")
			
			dbug("determine if there is a subfolder for this ticket...")
			rootDir = server.MapPath("/uploads")
			ticketDir = rootDir & "/" & request.querystring("id")
			
			dbug("rootDir: " & rootDir)
			dbug("ticketDir: " & ticketDir)
			
			set fsoUpload = server.CreateObject("Scripting.FileSystemObject")
			if fsoUpload.folderExists(ticketDir) then
				dbug("upload folder exists for this ticket, (" & ticket & ")")
			else 
				fsoUpload.createFolder(ticketDir)
				dbug("upload folder created for this ticket, (" & ticket & ")")
			end if 
			dbug("done processing a file..")
			set fsoUpload = nothing 
			
			' Loop through the uploaded files
			for each File in Uploader.Files.Items
				
				dbug("processing a file...")
					
				File.SaveToDisk ticketDir
				
				dbug("fileName: '" & File.FileName & "', size: " & File.FileSize & " bytes, type: " & File.ContentType & " saved to " & ticketDir)
				dbug(" ")

			next
			
		end if
	
	case else 
	
end select 


dbug("end of top-logic")
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************


%>

<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
<!-- 	<script type="text/javascript" src="ticketDetail.js"></script> -->
	<script type="text/javascript" src="script/taskDetail.js"></script>


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
		
<!--
		<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>
-->

				<%
				SQL = "select t.id, t.title, t.priorityID, p.name as priorityName, t.categoryID, c.name as categoryName, t.severityID, s.name as severityName, t.assignedID, t.statusID, x.name as statusName, t.reportedBy, t.narrative, t.openedDate, t.deleted " &_
						"from supportTickets t " &_
						"left join supportPriorities p on (p.id = t.priorityID) " &_
						"left join supportCategories c on (c.id = t.categoryID) " &_
						"left join supportSeverities s on (s.id = t.severityID) " &_
						"left join supportStatuses x on (x.id = t.statusID) " &_
						"where (t.deleted = 0 or t.deleted is null) " &_
						"and t.id = " & ticket & " " &_
						"order by openedDate desc " 
				dbug(SQL)
				set rsTix = dataconn.execute(SQL)

				if not rsTix.eof then 
' 					response.write("id = " & request.querystring("id") & " found, title: " & rsTix("title"))
					%>
					<div class="mdl-grid">
						<div class="mdl-layout-spacer"></div>
						<div class="mdl-cell mdl-cell--4-col">
							<a href="support.asp"><img src="/images/ic_arrow_back_black_24dp_1x.png"></a>
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label ">
							    <input class="mdl-textfield__input" type="text" id="title" name="title" value="<% =trim(rsTix("title")) %>" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
							    <label class="mdl-textfield__label" for="title">Title...</label>
							</div>
						</div>
						<div class="mdl-layout-spacer"></div>
					</div>

					<div class="mdl-grid"><!-- start basic details grid -->

						<div class="mdl-layout-spacer"></div>
						<div class="mdl-cell mdl-cell--3-col">
							
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<select class="mdl-textfield__input" id="priorityID" name="priorityID" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
									<option></option>
									<%
									SQL = "select id, name from supportPriorities order by seq " 
									set rsPriority = dataconn.execute(SQL)
									while not rsPriority.eof 
										if not isNull(rsTix("priorityID")) then
											if cInt(rsPriority("id")) = cInt(rsTix("priorityID")) then 
												selected = "selected"
											else 
												selected = ""
											end if
										else 
											selected = ""
										end if
										response.write("<option value=""" & rsPriority("id") & """ " & selected & ">" & rsPriority("name") & "</option>")
										rsPriority.movenext 
									wend
									rsPriority.close
									set rsPriority = nothing
									%>
									</select>
								<label class="mdl-textfield__label" for="priorityID">Priority...</label>
							</div>




							<br>


							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<select class="mdl-textfield__input" id="categoryID" name="categoryID" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
									<option></option>
									<%
									SQL = "select id, name from supportCategories order by seq " 
									set rsCtgy = dataconn.execute(SQL)
									while not rsCtgy.eof 
										if not isNull(rsTix("categoryID")) then
											if cInt(rsCtgy("id")) = cInt(rsTix("categoryID")) then 
												selected = "selected"
											else 
												selected = ""
											end if
										else 
											selected = ""
										end if
										response.write("<option value=""" & rsCtgy("id") & """ " & selected & ">" & rsCtgy("name") & "</option>")
										rsCtgy.movenext 
									wend
									rsCtgy.close
									set rsCtgy = nothing
									%>
									</select>
								<label class="mdl-textfield__label" for="categoryID">Category...</label>
							</div>

							<br>
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<select class="mdl-textfield__input" id="severityID" name="severityID" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
									<option></option>
									<%
									SQL = "select id, name from supportSeverities order by seq " 
									set rsSev = dataconn.execute(SQL)
									while not rsSev.eof 
										if not isNull(rsTix("severityID")) then
											if cInt(rsSev("id")) = cInt(rsTix("severityID")) then 
												selected = "selected"
											else 
												selected = ""
											end if
										else 
											selected = ""
										end if
										response.write("<option value=""" & rsSev("id") & """ " & selected & ">" & rsSev("name") & "</option>")
										rsSev.movenext 
									wend
									rsSev.close
									set rsSev = nothing
									%>
									</select>
								<label class="mdl-textfield__label" for="severityID">Severity...</label>
							</div>
							
						</div>
						<div class="mdl-cell mdl-cell--3-col">
							

							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<select class="mdl-textfield__input" id="assignedID" name="assignedID" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
									<option></option>
									<%
									SQL = "select id, firstName, lastName from cSuite..users where id in (" & usersWithPermission(28,"id") & ") order by lastName, firstName " 
									set rsAssign = dataconn.execute(SQL)
									while not rsAssign.eof 
										if not isNull(rsTix("assignedID")) then
											if cInt(rsAssign("id")) = cInt(rsTix("assignedID")) then 
												selected = "selected"
											else 
												selected = ""
											end if
										else 
											selected = ""
										end if
										response.write("<option value=""" & rsAssign("id") & """ " & selected & ">" & rsAssign("firstName") & " " & rsAssign("lastName") & "</option>")
										rsAssign.movenext 
									wend
									rsAssign.close
									set rsAssign = nothing
									%>
									</select>
								<label class="mdl-textfield__label" for="assignedID">Assigned to...</label>
							</div>

							<br>

							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
								<select class="mdl-textfield__input" id="statusID" name="statusID" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
									<option></option>
									<%
									SQL = "select id, name from supportStatuses order by seq " 
									set rsStat = dataconn.execute(SQL)
									while not rsStat.eof 
										if not isNull(rsTix("statusID")) then
											if cInt(rsStat("id")) = cInt(rsTix("statusID")) then 
												selected = "selected"
											else 
												selected = ""
											end if
										else 
											selected = ""
										end if
										response.write("<option value=""" & rsStat("id") & """ " & selected & ">" & rsStat("name") & "</option>")
										rsStat.movenext 
									wend
									rsStat.close
									set rsStat = nothing
									%>
									</select>
								<label class="mdl-textfield__label" for="statusID">Status...</label>
							</div>

						</div>
						<div class="mdl-cell mdl-cell--3-col">
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							    <input class="mdl-textfield__input" type="text" id="reportedBy" name="reportedBy" value="<% =trim(rsTix("reportedBy")) %>" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
							    <label class="mdl-textfield__label" for="reportedBy">Reported by...</label>
							</div>
							<br>
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							    <input class="mdl-textfield__input" type="text" id="openedDate" name="openedDate" value="<% =trim(rsTix("openedDate")) %>" onchange="TicketAttribute_onChange(this,<% =ticket %>)">
							    <label class="mdl-textfield__label" for="openedDate">Opened...</label>
							</div>
						</div>
						<div class="mdl-layout-spacer"></div>

					</div><!-- end basic details grid -->



					<div class="mdl-grid"><!-- start narrative grid -->

						<div class="mdl-layout-spacer"></div>

						<div class="mdl-cell mdl-cell--9-col">
							<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
								<textarea class="mdl-textfield__input" type="text" id="narrative" name="narrative" rows="3" onchange="TicketAttribute_onChange(this,<% =ticket %>)"><% =rsTix("narrative") %></textarea>
								<label class="mdl-textfield__label" for="narrative">Narrative...</label>
							</div>
						</div>
					
						<div class="mdl-layout-spacer"></div>
						
					</div><!-- end narrative grid -->




					<%
					rootDir = server.MapPath("/uploads/" & request.querystring("id"))
					set objFSO = server.CreateObject("Scripting.FileSystemObject")
			
					on error resume next
					set objFolder = objFSO.GetFolder(rootDir)
					if err.Number <> 0 then
						dbug("There is no folder for this incident: " & request.querystring("id"))
					else 
						%>
						<div class="mdl-grid"><!-- start file list grid -->
	
							<div class="mdl-layout-spacer"></div>

							<div class="mdl-cell mdl-cell--6-col">
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label" style="width: 100%;">
									<textarea class="mdl-textfield__input" type="text" id="newNote" name="newNote" rows="2" onchange="TicketAttribute_onChange(this,<% =ticket %>)"></textarea>
									<label class="mdl-textfield__label" for="newNote">Add a note...</label>
								</div>
								<br>
								<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp" style="width: 100%">
									<thead>
										<th class="mdl-data-table__cell--non-numeric" width="15%">Added</th>
										<th class="mdl-data-table__cell--non-numeric" width="60%">Note</th>
										<th class="mdl-data-table__cell--non-numeric" width="15%">By</th>
										<th class="mdl-data-table__cell--non-numeric" width="10%"></th>
									</tr>
									</thead>
									<tbody>
									<%
									SQL = "select n.id, n.addedDateTime, n.note, n.addedby, u.firstName + ' ' + u.lastName as fullName " &_
											"from supportNotes n " &_
											"left join cSuite..users u on (u.id = n.addedBy) " &_
											"where n.ticketID = " & ticket & " " &_
											"and (n.deleted <> 1 or n.deleted is null) "&_
											"order by n.addedDateTime desc "
									dbug(SQL)
									set rsNotes = dataconn.execute(SQL)
									while not rsNotes.eof 
										dbug("getting a supportNote...")
										%>
										<tr>
											<td class="mdl-data-table__cell--non-numeric"><% =rsNotes("addedDateTime") %></td>
	
											<td class="mdl-data-table__cell--non-numeric" >
												<div id="noteText_<% =rsNotes("id") %>" style="width: 400px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">
													<% =rsNotes("note") %>
												</div>
											</td>

											<td class="mdl-data-table__cell--non-numeric"><% =rsNotes("fullName") %></td>
											<td class="mdl-data-table__cell--non-numeric">

												<img name="imgDeleted-<% =rsNotes("id") %>" id="imgDeleted-<% =rsNotes("id") %>" data-val="<% =rs("id") %>" src="/images/ic_delete_black_24dp_1x.png" style="cursor: pointer" onclick="DeleteSupportNote_onClick(this,<% =rsNotes("id") %>)">

											</td>
										</tr>
										<%
										rsNotes.movenext 
									wend 
									rsNotes.close 
									set rsNotes = nothing 
									%>
									</tbody>
								</table>
								
							</div>
							
	
							<div class="mdl-cell mdl-cell--5-col">
	
								<table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
									<thead>
									<tr>
										<th class="mdl-data-table__cell--non-numeric"></th>
										<th class="mdl-data-table__cell--non-numeric">Uploaded File Name</th>
										<th class="mdl-data-table__cell--non-numeric">Type</th>
										<th class="mdl-data-table__cell">Size (bytes)</th>
										<th class="mdl-data-table__cell">Attributes</th>
										<th class="mdl-data-table__cell--non-numeric">Date/Time Created</th>
									</tr>
									</thead>
									<tbody>						
									<%
									for each item in objFolder.files
										select case lCase(trim(item.type))
											case "jpeg image","png image","bitmap image"
												mimeType = ""
												icon = "ic_photo_black_24dp_1x.png"
											case else 
												mimeType = ""
												icon = "ic_attachment_black_24dp_1x.png"
										end select 
									
										%>
										<tr>
											<td class="mdl-data-table__cell--non-numeric"><img src="images/<% =icon %>"></td>
											<td class="mdl-data-table__cell--non-numeric"><a href="uploads/<% =request.querystring("id") %>/<% =item.name %>"><% =item.name %></a></td>
											<td class="mdl-data-table__cell--non-numeric"><% =item.type %></td>
											<td class="mdl-data-table__cell"><% =formatNumber(item.size,0) %></td>
											<td class="mdl-data-table__cell"><% =item.attributes %></td>
											<td class="mdl-data-table__cell--non-numeric"><% =item.dateCreated %></td>
										</tr>
										<%
									next 
									%>
									</tbody>
								</table>

							<br>
							<div>
								<FORM METHOD="POST" ENCTYPE="multipart/form-data" ACTION="ticketDetail.asp?id=<% =ticket %>&cmd=upload">
								
								<div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
							
									<INPUT class="mdl-textfield__input" TYPE=FILE SIZE=100 NAME="FILE1">
								
								</div>
													
	
								<button id="button_newTicket" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent">
									Upload
								</button>
	
							</form>
							</div>


							</div>

							<div class="mdl-layout-spacer"></div>

						</div><!-- end file list grid -->
						<%
						set objFolder = nothing 
						set objFSO = nothing 
					end if 
					%>


					<%					
				else 
					response.write("id = " & request.querystring("id") & " found")
				end if 
				%>

			
			

<!--
			<div class="mdl-layout-spacer"></div>
		</div>
-->

	</div>
</main>
<!-- #include file="includes/pageFooter.asp" -->

<%
dataconn.close 
set dataconn = nothing
%>

</body>
</html>