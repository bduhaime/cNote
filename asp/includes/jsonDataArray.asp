<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

function jsonDataArray(sequel, headersInd)
	
	if not len(sequel) > 0 then 
		json = "terminating response, no SQL on request"
' 		dbug(json)
		jsonDataTable = json 
		return  
	else
		SQL = sequel
	end if 
' 	dbug(SQL)
	
	set rs = dataconn.execute(SQL)
	if not rs.eof then 
		
		json = "["
		
		if headersInd then 
			
			json = json & "["
			
			firstTime = true 	
			for each field in rs.fields
				if firstTime then firstTime = false else json = json & "," end if
				json = json & "'" & field.name & "'" 
			next 
			json = json & "],"
			
		end if 
		
		while not rs.eof 
	
			json = json & "["
			firstTime = true 
			for each item in rs.fields 
				if firstTime then firstTime = false else json = json & ", " end if


				select case item.type 

					case 7,202
						dataValue = "new Date(" & year(item.value) & ", " & month(item.value)-1 & ", " & day(item.value) & ")"
					
					case 20,6,3 
						dataValue = item.value
					
					case else 
' 						dbug("item.type: " & item.type & " should not be treated as text")
						dataValue = "'" & item.value & "'"
						
				end select 

				json = json & dataValue


			next 
			rs.movenext 
			json = json & "]"
			if not rs.eof then json = json & "," end if
			
		wend 			
	
		json = json & "]"

	end if 
	
	rs.close 
	set rs = nothing 
	
	dbug(json)
	
	jsonDataArray = json 
	
end function
%>