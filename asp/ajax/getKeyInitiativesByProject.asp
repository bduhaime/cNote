<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/escapeJSON.asp" -->

<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

dbug("starting getKeyInitiativesByProject.asp")
response.contentType = "application/json"
json 	= ""
msg 	= ""


'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->

dbug("REQUEST_METHOD: " & request.servervariables("REQUEST_METHOD"))

select case request.servervariables("REQUEST_METHOD") 

	case "GET"
	
		customerID = request.querystring("customerID") 
		projectID = request.querystring("projectID")


		SQL = "select " &_
					"ki.id, " &_
					"ki.name, " &_
					"ki.description, " &_
					"format(ki.startDate,'yyyy-MM-dd') as startDate, " &_
					"format(ki.endDate,'yyyy-MM-dd') as endDate, " &_
					"format(ki.completeDate,'yyyy-MM-dd') as completeDate " &_
				"from keyInitiatives ki " &_
				"join keyInitiativeProjects kip on (kip.keyInitiativeID = ki.id and kip.projectID = " & projectID & ") " &_
				"where ki.customerID = " & customerID & " "

		dbug("rsAssoc: " & SQL)
		set rsAssoc = dataconn.execute(SQL)
		if not rsAssoc.eof then 
			
			json = """associated"":["
			
			while not rsAssoc.eof 
			
				json = json & "{"
				json = json & 	"""id"":""" & rsAssoc("id") & ""","
				json = json & 	"""name"":""" & escapeJSON(rsAssoc("name")) & ""","
				json = json & 	"""description"":""" & escapeJSON(rsAssoc("description")) & ""","
				json = json & 	"""startDate"":""" & rsAssoc("startDate") & ""","
				json = json & 	"""endDate"":""" & rsAssoc("endDate") & ""","
				json = json & 	"""completeDate"":""" & rsAssoc("completeDate") & """"
				json = json & "}"

				rsAssoc.movenext 
				
				if not rsAssoc.eof then json = json & "," end if
			
			wend 
			
			json = json & "]"
			
		end if 
		rsAssoc.close 
		set rsAssoc = nothing 
			 

		SQL = "select " &_
					"ki.id, " &_
					"ki.name, " &_
					"ki.description, " &_
					"format(ki.startDate,'yyyy-MM-dd') as startDate, " &_
					"format(ki.endDate,'yyyy-MM-dd') as endDate, " &_
					"format(ki.completeDate,'yyyy-MM-dd') as completeDate " &_
				"from keyInitiatives ki " &_
				"where ki.id not in (select keyInitiativeID from keyInitiativeProjects where projectID = " & projectID& ") " &_
				"and ki.customerID = " & customerID & " "

		dbug("rsUnAssoc: " & SQL)
		set rsUnAssoc = dataconn.execute(SQL) 
		if not rsUnAssoc.eof then 
			
			if len(json) then json = json & "," end if
			
			json = json & """unassociated"":["

			while not rsUnAssoc.eof 
			
				json = json & "{"
				json = json & 	"""id"":""" & rsUnAssoc("id") & ""","
				json = json & 	"""name"":""" & escapeJSON(rsUnAssoc("name")) & ""","
				json = json & 	"""description"":""" & escapeJSON(rsUnAssoc("description")) & ""","
				json = json & 	"""startDate"":""" & rsUnAssoc("startDate") & ""","
				json = json & 	"""endDate"":""" & rsUnAssoc("endDate") & ""","
				json = json & 	"""completeDate"":""" & rsUnAssoc("completeDate") & """"
				json = json & "}"

				rsUnAssoc.movenext 
				
				if not rsUnAssoc.eof then json = json & "," end if
			
			wend 
			
			json = json & "]"
			
		end if 
		rsUnAssoc.close 
		set rsUnAssoc = nothing 

		responseStatus = "200 OK"
			
	case else 
		
		dbug("REQUEST_METHOD NOT RECOGNIZED: " & request.servervariables("REQUEST_METHOD"))

		responseStatus = "405 Method Not Allowed"
				
end select 

dataconn.close 
set dataconn = nothing 



json = "{" & json & "}"

dbug("json: " & json)
dbug("ending getKeyInitiativesByProject.asp")
dbug(" ")

response.status = responseStatus
response.write json 
%>