<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

function escapeQuotes(strQuoteText)
'--------------------------------------------------------------
'this function "escapes" single- and double-quotes found in a
'sring:
'
'	Example: David's present --> David''s present
'	Example: He said, "Do it!" --> He said, \"Do it!\"
'--------------------------------------------------------------
'
'		chr(34) ==> double-quote
'
'--------------------------------------------------------------

	if varType(strQuoteText) = 8 then

		if len(cStr(strQuoteText)) > 0 then
		
			strDequotedText = replace(strQuoteText, chr(34), chr(92) & chr(34))
			strDequotedText = escapeApostrophes(strDequotedText)
		
		end if

	end if

	escapeQuotes = strDequotedText

end function


function escapeApostrophes(strApostropheText)
'--------------------------------------------------------------
'this function "escapes" single--quotes found in a string:
'
'	Example: David's present --> David''s present
'--------------------------------------------------------------
'
'		chr(39) ==> single-quote (aka Apostrophe)
'
'--------------------------------------------------------------

	if varType(strApostropheText) = 8 then

		if len(cStr(strApostropheText)) > 0 then
		
			strDeapostrophedText = replace(strApostropheText, chr(39), chr(39) & chr(39))
		
		end if

	end if

	escapeApostrophes = strDeapostrophedText

end function
%>
