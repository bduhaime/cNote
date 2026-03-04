<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'*****************************************************************************************
function formatDate(inputDate)
'*****************************************************************************************
	
	if not isNull(inputDate) then 
		formatDate = formatDateTime(inputDate)
	else 
		formatDate = NULL
	end if 
	
end function 


%>