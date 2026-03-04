<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'***********************************************************************************
function workDaysBetween (startDate, endDate)
'***********************************************************************************

	dbug("workDaysBetween('" & startDate & "," & endDate & "')")

	if isDate(startDate) then
		if isDate(endDate) then
		
			SQL = "select count(*) as workdayCount from dateDimension " &_
					"where id between '" & startDate & "' and '" & endDate & "' " &_
					"and weekdayInd = 1 " &_
					"and usaHolidayInd = 0 "
' 			dbug(SQL)
			set rsWDB = dataconn.execute(SQL)
			if not rsWDB.eof then 
				workDaysBetween = rsWDB("workdayCount")
			else 
				workDaysBetween = null 
			end if
			rsWDB.close 
			set rsWDB = nothing 			
		else 
			workDaysBetween = null 
		end if
	else 
		workDaysBetween = null 
	end if

end function 
%>