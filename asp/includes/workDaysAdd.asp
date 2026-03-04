<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'***********************************************************************************
function workDaysAdd (startDate, days)
'***********************************************************************************

	dbug("workDaysAdd('" & startDate & "," & days & "')")

	if isDate(startDate) then
		if isNumeric(cInt(days)) then
		
		
			if cInt(days) <> 0 then 
		
		
				if cInt(days) > 0 then 
					SQL = "select max(id) as resultDate " &_
							"from " &_
								"(" &_
								"select top " & days & " * " &_
								"from dateDimension " &_
								"where id > '" & startDate & "' " &_
								"and weekdayInd = 1 " &_
								"and usaHolidayInd = 0 " &_
								"order by id asc " &_
								") x "
				else  
					SQL = "select min(id) as resultDate " &_
							"from " &_
								"(" &_
								"select top " & abs(days) & " * " &_
								"from dateDimension " &_
								"where id < '" & startDate & "' " &_
								"and weekdayInd = 1 " &_
								"and usaHolidayInd = 0 " &_
								"order by id desc " &_
								") x "
				end if
	
				dbug("workdDaysAdd SQL: " & SQL)
	
				set rsWDA = dataconn.execute(SQL)
				if not rsWDA.eof then 
					tempWorkDays = rsWDA("resultDate")
				else 
					tempWorkDays = null 
				end if
				rsWDA.close 
				set rsWDA = nothing 			
			else 
				
				' if "days" is zero, then simply return the startDate...
				tempWorkDays = startDate 
		
			end if 
			
		else 
' 			dbug("workdDaysAdd days is not numeric")
			tempWorkDays = null 
		end if
	else 
' 		dbug("workdDaysAdd startDate is not a date")
		tempWorkDays = null 
	end if
	
	dbug("workDaysAdd returning: " & tempWorkDays)
	
	workDaysAdd = tempWorkDays

end function 
%>