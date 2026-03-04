<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'***********************************************************************************
function taskDaysAhead (taskID)
'***********************************************************************************
'*
'*		If Task Complete prior to Due Date, the number of work days from Complete 
'*		Date to Due Date (otherwise zero). 
'*
'***********************************************************************************

	SQL = "select " &_
				"startDate, " &_
				"dueDate, " &_
				"completionDate " &_
			"from tasks " &_
			"where id = " & taskID & " "  
	
	set rsWDA = dataconn.execute(SQL)
	if not rsWDA.eof then		
		
		if isNull(rsWDA("completionDate")) then 
			returnValue = 0
		else 
			if not isDate(rsWDA("completionDate")) then 
				returnValue = 0
			else 
				if cDate(rsWDA("completionDate")) < cDate(rsWDA("dueDate")) then 
					returnValue = workDaysBetween(cDate(rsWDA("completionDate")), cDate(rsWDA("dueDate")))
				else 
					returnValue = 0
				end if 
			end if 
		end if 

	else 
		returnValue = 0
	end if
		
	rsWDA.close 
	set rsWDA = nothing 

	taskDaysAhead = returnValue


end function 
%>