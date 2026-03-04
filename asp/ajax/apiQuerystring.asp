<%
' ------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ------------------------------------------------------------------

xml = xml & "<request>"
xml = xml & "<querystring>"

for each item in request.querystring
	
	select case item 
		case "narrative", "narrativeHTML", "managerTypeName", "name", "desc", "description", "itemName", "itemDesc", "comments", _
				"validDomains", "callNoteNarrative", "callNoteHTML","skippedReasonString","skippedReasonHTML","lsvtCustomerName"
				
			dbug("querystring item='" & item & "', using CDATA...")
			xml = xml & "<" & item & "><![CDATA[" & request.querystring(item) & "]]></" & item & ">" 
		case else 
			dbug("querystring item='" & item & "', NOT using CDAT...")
			xml = xml & "<" & item & ">" & request.querystring(item) & "</" & item & ">" 
	end select  

next 
xml = xml & "</querystring>"

xml = xml & "<form>"

for each item in request.form 
	
	select case item 
		case "narrative", "narrativeHTML", "managerTypeName", "name", "desc", "description", "itemName", "itemDesc", "comments", _
				"validDomains", "callNoteNarrative", "callNoteHTML","skippedReasonString","skippedReasonHTML","lsvtCustomerName"
			dbug("form item='" & item & "', using CDATA...")
			xml = xml & "<" & item & "><![CDATA[" & request.form(item) & "]]></" & item & ">" 
		case else 
			dbug("form item='" & item & "', NOT using CDATA...")
			xml = xml & "<" & item & ">" & request.form(item) & "</" & item & ">" 
	end select  

next 
' dbug(xml)

xml = xml & "</form>"
xml = xml & "</request>"
%>
