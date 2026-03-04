<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
function jsonEscapeSpecialChars(strValue)
	
' 	dbug("jsonEscapeSpecialChars - strValue: " & strValue)
	
	strTemp = replace(strValue,"'","\'")
	strTemp = replace(strTemp,"""","\""")
	strTemp = replace(strTemp,"â„¢","\u2122")
	
' 	dbug("jsonEscapeSpecialChars - returning: " & strTemp)

	jsonEscapeSpecialChars = strTemp
	
end function


function jsonDataTable(sequel)
	
	
	dbugTemp = application("dbug") 
	application("dbug") = false


' 	dbug(" ")
' 	dbug(string(80,"-"))
' 	dbug("jsonDataTable: start...")
' 	dbug(string(80,"-"))

	
	if not len(sequel) > 0 then 
		json = "terminating response, no SQL on request"
' 		dbug("jsonDataTable: " & json)
		jsonDataTable = json 
		return  
	else
		SQL = sequel
	end if 
' 	dbug("jsonDataTable: " & SQL)
	
	set rs = dataconn.execute(SQL)
	if not rs.eof then 
		
		json = "{ cols: ["
			
		firstTime = true 	
		for each field in rs.fields
			
' 			dbug("field.name: " & field.name & ", field.type: " & field.type)
			if firstTime then firstTime = false else json = json & "," end if
			
			select case field.type
				case 2, 3, 5, 6, 20, 131
					dataType = "number"
				case 7, 133, 135
' 					dbug("column is a date/time...")
					if field.name = "Time" then 
						dataType = "timeofday"
					else 
						dataType = "date"
					end if
				case 129,130,200,201,203
					dataType = "string"
				case 202
					if isDate(field.value) then 
						if field.name = "Time" then 
							dataType = "timeofday"
						else 
							dataType = "date"
						end if
					else 
						dataType = "string"
					end if
				case else 
' 					dbug("unrecognized datatype encountered: " & field.type)
					dataType = "string(" & field.type & ")"
			end select 
			
			json = json & "{id: '" & field.name & "', label: '" & field.name & "', type: '" & dataType & "'}" 
	
		next 
			
		json = json & "],"
		
		json = json & "rows: [" 
		
		while not rs.eof 
' 			dbug("jsonDataTable: starting a row...")
			json = json & "{c: ["
	
			firstTime = true 
			for each field in rs.fields 
				
				dbug("jsonDataTable: field.name: " & field.name)
				dbug("jsonDataTable: field.type: " & field.type)
				dbug("jsonDataTable: field.value: " & field.value)
				dbug("jsonDataTable: starting a column value for col: " & field.name & ", .type: " & field.type & ", .value: " & field.value )
				
				if firstTime then firstTime = false else json = json & "," end if
				
' 				dbug("len(field.value): " & len(field.value))
	
				if isNull(field.value) then 
' 					dbug("field.value is null")
					dataValue = "null"
				else 
' 					dbug("field.value is NOT null")
' 					dbug("jsonDataTable: field is of type: " & field.type & " with a value of: " & field.value)
					select case field.type 

						' numeric data types
						case 2, 3, 5, 6, 20, 131

							dataValue = field.Value

						' dates and timestamps
						case 7, 133, 135

' 							dbug("handling date or timestamp field...")						
						
							if lCase(trim(field.name)) = "time" then 
								
' 								dbug("handling a 'time' field...")

								dataValue = "[" &_
													datePart("h",field.value) & ", " &_ 
													datePart("n",field.value) & ", " &_ 
													datePart("s",field.value) &_
												 "]"
																	
							else 
								
								' special handling for dates prior to 1/1/010...
								if cInt(left(field.value,4)) < 100 then 
									convertedYear = cInt(left(field.value,4))
								else 
									convertedYear = datePart("yyyy",cDate(field.value))
								end if 

								dataValue = "new Date(" & 	convertedYear 							& ", " &_
																	datePart("m",field.value) - 1 	& ", " &_
																	datePart("d",field.value) 			& ", " &_ 
																	datePart("h",field.value) 			& ", " &_ 
																	datePart("n",field.value) 			& ", " &_ 
																	datePart("s",field.value) 			& ")"
							
							end if 
							
							
						' string or char values
						case 129,130,200,201,203
						
' 							dbug("handling string/char value...")
						
							if field.name = "Time" then 
								
' 								dbug("handling a 'time' string...")

								dataValue = "[" &_
													mid(field.value, 1, 2) & ", " &_ 
													mid(field.value, 4, 2) & ", " &_ 
													mid(field.value, 7, 2) & ", " &_ 
												 "]"
																	
							else 
								
' 								dbug("handling a string that is not 'time'...")
						
								dataValue = "'" & jsonEscapeSpecialChars(field.value) & "'"
								
							end if

						
						' a null-terminated unicode character string?
						case 202
						
							if IsDate(field.value) then 
						

								if lCase(trim(field.name)) = "time" then 
									
	' 								dbug("handling a 'time' field...")
	' 								dbug("handling as time: field.name: " & field.name & ", field.value: " & field.value)
	
									dataValue = "[" &_
														datePart("h",field.value) & ", " &_ 
														datePart("n",field.value) & ", " &_ 
														datePart("s",field.value) &_
													 "]"
																		
	' 								dbug("resulting time value: " & dataValue)		
	' 								dbug(" ")
																								
	
								else 
									
									' special handling for dates prior to 1/1/010...
' 									dbug("is year < 100?: " & left(field.value,4))
									if cInt(left(field.value,4)) < 100 then 
										convertedYear = cInt(left(field.value,4))
									else 
										convertedYear = datePart("yyyy",cDate(field.value))
									end if 
	
									dataValue = "new Date(" & 	convertedYear 							& ", " &_
																		datePart("m",field.value) - 1 	& ", " &_
																		datePart("d",field.value) 			& ", " &_ 
																		datePart("h",field.value) 			& ", " &_ 
																		datePart("n",field.value) 			& ", " &_ 
																		datePart("s",field.value) 			& ")"
								
								end if 
								
							else 
								
								dataValue = "'" & jsonEscapeSpecialChars(field.value) & "'"
								
							end if
							
						case else 

' 							dbug("jsonDataTable: unrecognized datatype encountered: " & field.type)
							dataValue = "'" & jsonEscapeSpecialChars(field.value) & "'"

					end select 
				end if
	
				json = json & "{v: " & dataValue & "}"
	
' 				dbug("jsonDataTable: ending a column value for col: " & field.name & ", value: " & dataValue)
			next 
	
			json = json & "]}"
			
			rs.movenext 
			if not rs.eof then json = json & "," end if
			
' 			dbug("jsonDataTable: ended a row.")
		wend 			
	
		json = json & "]}"
	
	end if 
	
	rs.close 
	set rs = nothing 
	
	if systemControls("Send jsonDataTable output to log") = true then 
' 		dbug("jsonDataTable: json=" & json)
	else 
' 		dbug("systemControls('Send jsonDataTable output to log') is false, so output is NOT written to dbug.log")
	end if
	
	jsonDataTable = json 
	
' 	dbug(string(80,"-"))
' 	dbug("jsonDataTable: end")
' 	dbug(string(80,"-"))
' 	dbug(" ")

	application("dbug") = dbugTemp
	
	
end function
%>