<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'!-- ------------------------------------------------------------------ -->
function escapeJSON(string)
'!-- ------------------------------------------------------------------ -->
'!-- This function escapes JSON reserved characters as follows:
'!--
'!-- 		Backslash is replaced with \\
'!-- 		Backspace is replaced with \b
'!-- 		Form feed is replaced with \f
'!-- 		Newline is replaced with \n
'!-- 		Carriage return is replaced with \r
'!-- 		Tab is replaced with \t
'!-- 		Double quote is replaced with \"
'!-- ------------------------------------------------------------------ -->
		
	temp = replace(string,"\","\\")
	temp = replace(temp,chr(8),"\b")
	temp = replace(temp,chr(12),"\f")
	temp = replace(temp,chr(10),"\n")
	temp = replace(temp,chr(13),"\r")
	temp = replace(temp,chr(9),"\t")
	temp = replace(temp,chr(34),"\""")

	escapeJSON = temp
	
end function


%>
