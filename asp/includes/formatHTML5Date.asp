<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'*****************************************************************************************
function formatHTML5Date(inputDate)
'*****************************************************************************************
	
	if not isNull(inputDate) then 

		if isDate(inputDate) then 
			
			strYear = cStr(year(inputDate))
			strMonth = right("0" & cStr(month(inputDate)),2)
			strDay = right("0" & cStr(day(inputDate)),2)
			
			formatHTML5Date = strYear & "-" & strMonth & "-" & strDay
			
		else 
			
			formatHTML5Date = NULL
			
		end if
		
	else 
		
		formatHTML5Date = NULL 
		
	end if 

end function 
%>