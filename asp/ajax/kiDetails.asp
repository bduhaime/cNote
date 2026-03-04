
<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------
response.ContentType = "application/json"

if len(request("customerID")) <= 0 then 
	json = "{""error"": ""customerID not present""}"
	response.write(json)
	response.end()
else 
	customerID = request("customerID")
end if

if len(request("ki")) > 0 then 

	if not isNumeric(request("ki")) then 
		json = "{""error"": ""keyInitiative ID is not valid""}"
		response.write(json)
		response.end()
	end if
	
	keyInitiativeID = request("ki")
	kiSource = "join keyInitiativeProjects kip on (kip.projectID = p.id and kip.keyInitiativeID = " & keyInitiativeID & ") " 

else 

	json = "{""error"": ""keyInitiative ID not present""}"
	response.write(json)
	response.end()

end if 	

json = "{""html"": """

	html = ""
	
	SQL = "select description, startDate, endDate " &_
			"from keyInitiatives " &_
			"where customerID = " & customerID & " " &_
			"and id = " & keyInitiativeID & " " 
			
	set rski = dataconn.execute(SQL) 
	if not rsKI.eof then 
		kiDescription = replace(rsKI("description"), """", "&quot;")
		html = html & "<p>" & kiDescription & "</p>"
	end if 
	
	
	'-- ---------------------------------------------------------------------------------------
	'-- get the projects currently associate with the KI...
	'-- ---------------------------------------------------------------------------------------
		
	SQL = "select " &_
				"p.id, " &_
				"p.name, " &_
				"format(p.startDate, 'M/d/yyyy') as startDate, " &_
				"format(p.endDate, 'M/d/yyyy') as endDate, " &_
				"p.completeDate " &_
			"from projects p " &_
			"join keyInitiativeProjects kip on (kip.projectID = p.id and kip.keyInitiativeID = " & keyInitiativeID & ") " &_
			"where (p.deleted = 0 or p.deleted is null) "
			
	set rsProj = dataconn.execute(SQL) 
	if not rsProj.eof then 
		html = html & "<table id=\""projectsForKI_" & keyInitiativeID & "\"" class=\""compact display dataTable no-footer\"">"
			html = html & "<thead>"
				html = html & "<tr>"
					html = html & "<th class=\""projectName\"">Associated Projects</th>"
					html = html & "<th class=\""startDate\"">Start Date</th>"
					html = html & "<th class=\""dueDate\"">Due Date</th>"
					html = html & "<th class=\""statusDate\"">Status Date</th>"
					html = html & "<th class=\""status\"">Status</th>"
					html = html & "<th class=\""actions\""></th>"
				html = html & "</tr>"
			html = html & "</thead>"
			html = html & "</body>"

		while not rsProj.eof 

			SQL = "select top 1 " &_
						"type, " &_
						"format(updatedDateTime, 'M/d/yyyy') as statusDate " &_
					"from projectStatus " &_
					"where projectID = " & rsProj("id") & " " &_
					"order by updatedDateTime desc "

			set rsPS = dataconn.execute(SQL) 
			if not rsPS.eof then 
				projectStatusDate = formatDateTime(rsPS("statusDate"),2)
				projectStatusType = rsPS("type") 
			else 
				projectStatusDate = ""
				projectStatusType = ""
			end if
			
			rsPS.close 
			set rsPS = nothing 
				
			html = html & "<tr id=\""" & rsProj("id") & "\"">"
				html = html & "<td>" & rsProj("name") & "</td>"			
				html = html & "<td>" & rsProj("startDate") & "</td>"			
				html = html & "<td>" & rsProj("endDate") & "</td>"			
				html = html & "<td>" & projectStatusDate & "</td>"			
				html = html & "<td>" & projectStatusType & "</td>"			
				html = html & "<td></td>"
			html = html & "<tr>"
			
			rsProj.movenext 
		
		wend 
		
		rsProj.close 
		set rsProj = nothing 

		html = html & "</body>"
		html = html & "</table>"

	end if 


	'-- ---------------------------------------------------------------------------------------
	'-- get the projects that are NOT associate with the KI...
	'-- ---------------------------------------------------------------------------------------

	SQL = "select id, name, startDate, endDate " &_
			"from projects p " &_
			"where customerID = " & customerID & " " &_
			"and (deleted = 0 or deleted is null) " &_
			"and (complete = 0 or complete is null) " &_
			"and id not in (select projectID from keyInitiativeProjects where keyInitiativeID = " & keyInitiativeID & ") " &_
			"order by name " 

	set rsX = dataconn.execute(SQL) 
	
	if not rsX.eof then 
		
		html = html & "<br>"
		html = html & "<select style=\""width: 450px\"">"
			html = html & "<option>Associate additional projects...</option>"
			
			while not rsX.eof
			
				projectName = replace(rsX("name"), """", "&quot;")
			
				if rsX("startDate") < rsKI("startDate") OR rsX("endDate") > rsKI("endDate") then 
					disabled = "disabled" 
					if not isNull(rsKI("endDate")) then
						tooltipEndDate = formatDateTime(rsKI("endDate"))
					else 
						tooltipEndDate = " "
					end if
					tooltip = "Project timeframe (" & formatDateTime(rsX("startDate")) & "-" & formatDateTime(rsX("endDate")) & ") " &_
								 "does not fit within the Key Initiative timeframe (" & formatDateTime(rsKI("startDate")) & "-" & tooltipEndDate & ")"
				else
					disabled = ""
					tooltip = ""
				end if 
	
				html = html & "<option value=\""" & rsX("id") & "\""" & disabled & " title=\""" & tooltip & "\"">" & projectName & "</option>"
				rsX.movenext
			wend

			html = html & "<option>Add new project...</option>"
			
		html = html & "</select>"
		
	end if
	
	rsX.close
	set rsX = nothing


	'-- ---------------------------------------------------------------------------------------
	'-- get the TASKS tha are currently associate with the KI...
	'-- ---------------------------------------------------------------------------------------

	SQL = "select " &_
				"t.id, " &_
				"t.name, " &_
				"t.startDate, " &_
				"t.dueDate, " &_
				"t.completionDate, " &_
				"t.taskStatusID, " &_
				"ts.name as taskStatusName, " &_
				"concat(cc.firstName, ' ', cc.lastName) as ownerName " &_
			"from tasks t " &_
			"join keyInitiativeTasks kit on (kit.taskID = t.id) " &_
			"left join customerContacts cc on (cc.id = t.ownerID) " &_
			"left join taskStatus ts on (ts.id = t.taskStatusID) " &_
			"where kit.keyInitiativeID = " & keyInitiativeID & " " 
			
	set rsTasks = dataconn.execute(SQL) 
	
	if not rsTasks.eof then 

		html = html & "<br><br>"
			html = html & "<table id=\""kiTasks\"">"
				html = html & "<thead>"
					html = html & "<tr>" 
						html = html & "<th class=\""taskName\"">Associated Tasks</th>"
						html = html & "<th class=\""startDate\"">Start</th>"
						html = html & "<th class=\""dueDate\"">Due</th>"
						html = html & "<th class=\""completeDate\"">Complete</th>"
						html = html & "<th class=\""owner\"">Owner</th>"
						html = html & "<th class=\""actions\""></th>"
					html = html & "</tr>" 
				html = html & "</thead>"
				html = html & "<tbody>"
				
		while not rsTasks.eof 
		
			if not isNull(rsTasks("startDate")) then 
				startDate = FormatDateTime(rsTasks("startDate"), 2)
			else 
				startDate = ""
			end if
			
			if not isNull(rsTasks("dueDate")) then 
				dueDate = FormatDateTime(rsTasks("dueDate"), 2)
			else 
				dueDate = ""
			end if
			
			if not isNull(rsTasks("completionDate")) then 
				completionDate = FormatDateTime(rsTasks("completionDate"), 2)
			else 
				completionDate = ""
			end if
			
			html = html & "<tr id\""" & rsTasks("id") & "\"">"
				html = html & "<td>" & rsTasks("name") & "</td>"
				html = html & "<td>" & startDate & "</td>"
				html = html & "<td>" & dueDate & "</td>"
				html = html & "<td>" & completionDate & "</td>"
				html = html & "<td>" & rsTasks("ownerName") & "</td>"
				html = html & "<td></td>"
			html = html & "<tr>"
			
			rsTasks.movenext 
			
		wend 
		
		rsTasks.close 
		set rsTasks = nothing 
		
		html = html & "</body>"
		html = html & "</table>"
		
	end if



	'-- ---------------------------------------------------------------------------------------
	'-- get the TASKS that are NOT associate with the KI...
	'-- ---------------------------------------------------------------------------------------

	SQL = "select id, name, startDate, dueDate " &_
			"from tasks " &_
			"where customerID = " & customerID & " " &_
			"and (deleted = 0 or deleted is null) " &_
			"and id not in (select taskID from keyInitiativeTasks where keyInitiativeID = " & keyInitiativeID & ") " &_
			"and projectID is null " &_
			"order by name " 
		
	dbug(SQL)	
	set rsY = dataconn.execute(SQL) 
	
	if not rsY.eof then 
		html = html & "<br><br>"
		html = html & "<select style=\""width: 450px\"">"
			html = html & "<option>Associate additional tasks...</option>"

			while not rsY.eof 
			
				taskName = replace(rsY("name"), """", "&quote;")
			
				if rsY("startDate") < rsKI("startDate") OR rsY("dueDate") > rsKI("endDate") then 
					disabled = "disabled" 
					if not isNull(rsKI("endDate")) then
						tooltipEndDate = formatDateTime(rsKI("endDate"))
					else 
						tooltipEndDate = " "
					end if
					tooltip = "Task timeframe (" & formatDateTime(rsY("startDate")) & "-" & formatDateTime(rsY("dueDate")) & ") " &_
								 "does not fit within the Key Initiative timeframe (" & formatDateTime(rsKI("startDate")) & "-" & tooltipEndDate & ")"
				else
					disabled = ""
					tooltip = ""
				end if 

				html = html & "<option value=\""" & rsY("id") & "\"" " & disabled & " title=\""" & tooltip & "\"">" & taskName & "</option>"
				rsY.movenext
			wend
			html = html & "<option>Add new task...</option>"
		html = html & "</select>"
		
	end if
	
	rsY.close
	set rsY = nothing

						


	rsKI.close 
	set rsKI = nothing 


	
json = json  & html & """}"

dbug(json)
response.write(json)

%>