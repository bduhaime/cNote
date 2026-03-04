<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'*******************************************************************************
function getNextID(tableName)
'*******************************************************************************
	
	dbug("getNextID: start")
	
	if len(tableName) then
		
		SQL = "select max(id) as maxID from " & tableName & " " 
		dbug(SQL)
		
		set rsMax = dataconn.execute(SQL)
		
		if not rsMax.eof then 
			
			if not isNull(rsMax("maxID")) then 
				nextID = cInt(rsMax("maxID")) + 1
			else 		
				nextID = 1
			end if
			
		else 
			
			nextID = 1
			
		end if
		
		rsMax.Close
		set rsMax = nothing 
		
	else 
		
		nextID = null 
		
	end if
	
	dbug("getNextID = " & nextID)
	
	getNextID = nextID
	
end function 
%>