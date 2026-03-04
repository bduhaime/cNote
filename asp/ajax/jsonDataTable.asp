<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

response.ContentType = "application/json"

if not len(request.querystring("sql")) > 0 then 
	dbug("terminating response, no SQL on request")
	response.end 
else
	SQL = request.querystring("sql")
end if 
dbug(SQL)

set rs = dataconn.execute(SQL)
if not rs.eof then 
	
	json = "{ cols: ["
		
	firstTime = true 	
	for each field in rs.fields
		
		if firstTime then firstTime = false else json = json & "," end if
		
		select case field.type 
			case 20, 6
				dataType = "number"
			case 7,202
				dataType = "date"
			case 129,200,201,203,202,130
				dataType = "string"
			case else 
				dataType = "string(" & field.type & ")"
		end select 
		
		json = json & "{id: '" & field.name & "', label: '" & field.name & "', type: '" & dataType & "'}" 

	next 
		
	json = json & "],"
	
	json = json & "rows: [" 
	
	while not rs.eof 
		dbug("starting a row...")
		json = json & "{c: ["

		firstTime = true 
		for each field in rs.fields 
			dbug("starting a column value for col: " & field.name )
			
			if firstTime then firstTime = false else json = json & "," end if

			select case field.type 
				case 7,202
					dataValue = "new Date(" & year(field.value) & ", " & month(field.value)-1 & ", " & day(field.value) & ")"
				case else 
					dataValue = "'" & field.value & "'"
			end select 

			json = json & "{v: " & dataValue & "}"

			dbug("ending a column value for col: " & field.name & ", value: " & dataValue)
		next 

		json = json & "]}"
		
		rs.movenext 
		if not rs.eof then json = json & "," end if
		
		dbug("ended a row.")
	wend 			

	json = json & "]}"

end if 

rs.close 
set rs = nothing 


dataconn.close 
set dataconn = nothing 


response.write(json)
%>