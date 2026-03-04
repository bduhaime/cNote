<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'***********************************************************************************
function taskDaysBehind (taskID)
'***********************************************************************************
'*
'*		If Task not Complete by Due Date, the number of work days from Due Date to 
'*		the earlier of today's date or Complete Date. 
'*
'*		NOTE: The above description, which is presented to end users as a tooltip,
'*		does not take into account that a task can be completed and given a
'* 	a completion date that is the future. This is accounted for in the code
'*		below even though the user-facing description doesn't reference it.
'* 
'* 	A task is zero days behind until the day after its due date.
'*
'***********************************************************************************

	SQL = "select " &_
				"startDate, " &_
				"dueDate, " &_
				"completionDate " &_
			"from tasks " &_
			"where id = " & taskID & " "  
	
	set rsWDB = dataconn.execute(SQL)
	if not rsWDB.eof then
		
		firstDayLate = workDaysAdd( rsWDB("dueDate"), 1 )

		if not isNull( rsWDB("completionDate") ) then 
			if cDate( rsWDB("completionDate") ) > cDate( rsWDB("dueDate") ) then 
				returnValue = workDaysBetween( cDate(firstDayLate), cDate( rsWDB("completionDate") ) )
			else 
				returnValue = 0
			end if 
		else 
			if cDate( rsWDB("dueDate") ) < date() then 
				returnValue = workDaysBetween( cDate(firstDayLate), date() )
			else 
				returnValue = 0
			end if 
		end if 
	else 
		returnValue = 0
	end if
		
	rsWDB.close 
	set rsWDB = nothing 

	taskDaysBehind = returnValue
	
end function 
%>