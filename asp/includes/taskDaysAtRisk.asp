<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'***********************************************************************************
function taskDaysAtRisk (taskID)
'***********************************************************************************
'*
'*		After Start Date, if Task not Complete, the number of work days from Start 
'*		Date to the earlier of today's date or Due Date (otherwise zero). 
'*
'***********************************************************************************


	SQL = "select " &_
				"startDate, " &_
				"dueDate, " &_
				"completionDate " &_
			"from tasks " &_
			"where id = " & taskID & " " 
	
	set rsWDR = dataconn.execute(SQL)
	if not rsWDR.eof then
		
		if isNull(rsWDR("completionDate")) then 

			if cDate(rsWDR("startDate")) < date() then
				if cDate(rsWDR("dueDate")) < date() then 
					returnValue = workDaysBetween (cDate(rsWDR("startDate")), cDate(rsWDR("dueDate")))
				else 
					returnValue = workDaysBetween (cDate(rsWDR("startDate")), date())
				end if 
			else 
				returnValue = 0
			end if

		else 
			returnValue = 0
		end if
	else 
		returnValue = 0
	end if
			
	rsWDR.close 
	set rsWDR = nothing 

	taskDaysAtRisk = returnValue
	
end function 
%>