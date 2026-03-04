<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
'!-- ------------------------------------------------------------------ -->

'*****************************************************************************************
function checkPageAccess(permID) 
'*****************************************************************************************
'
' should be called using 'call checkPageAccess(permissionID)' at the top of every
' primary page.
'

	select case permID 
	
		case 99,101,110 

			if lCase(session("dbName")) <> "csuite" then
	
				session("403") = permID
				response.status = "403"
				response.clear()
				response.end() 
				
			end if 
		
		case else 
	
	end select 
	 

	if not userPermitted(permID) then 
	
		session("403") = permID
		response.status = "403"
		response.clear()
		response.end() 
		
	end if

	
end function  	
%>