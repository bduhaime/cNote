<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

function escapeHtmlCharacters(htmlString)
'--------------------------------------------------------------
'	this function replaces characters that are sensitive in HTML
' 	with their HTML equivalents:
'
'		" --> $quot;	chr(34)
'		& --> $amp;		chr(38)
'		' --> &#39;		chr(39)
'		- --> &mdash;	chr(45)
'		< --> &lt;		chr(60)
'		> --> &gt;		chr(62)
'
'
'	Example: David's present --> David$#39ls present
'	Example: He said, "Do it!" --> He said, &quot;Do it!&quot;
'--------------------------------------------------------------

	dbug("escapeHtmlCharacters: htmlString=" & htmlString)
	
	if varType(htmlString) = 8 then

		if len(cStr(htmlString)) > 0 then
			
			strEscapedString = htmlString 
' 			dbug("escapeHtmlCharacters: prior to anything, strEscapedString=" & strEscapedString)
		
			strEscapedString = replace(strEscapedString, chr(34), "&quot;")
' 			dbug("escapeHtmlCharacters: after double-quote, strEscapedString=" & strEscapedString)

			strEscapedString = replace(strEscapedString, chr(38), "&amp;")
' 			dbug("escapeHtmlCharacters: after ampersand, strEscapedString=" & strEscapedString)

			strEscapedString = replace(strEscapedString, chr(39), "&#39;")
' 			dbug("escapeHtmlCharacters: after single-quote, strEscapedString=" & strEscapedString)

			strEscapedString = replace(strEscapedString, "â€”", "&mdash;")
' 			dbug("escapeHtmlCharacters: after em dash, strEscapedString=" & strEscapedString)

			strEscapedString = replace(strEscapedString, chr(60), "&lt;")
' 			dbug("escapeHtmlCharacters: after less-than, strEscapedString=" & strEscapedString)

			strEscapedString = replace(strEscapedString, chr(62), "&gt;")
' 			dbug("escapeHtmlCharacters: after greater-than, strEscapedString=" & strEscapedString)
		
		end if

	end if

	escapeHtmlCharacters = strEscapedString

end function
%>
