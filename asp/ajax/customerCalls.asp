<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/getNExtID.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/smtpParms.asp" -->
<!-- #include file="../includes/escapeHtmlCharacters.asp" -->
<!-- #include file="../includes/workDaysBetween.asp" -->
<!-- #include file="../includes/workDaysAdd.asp" -->
<!-- #include file="../includes/taskDaysBehind.asp" -->
<% 
' Copyright (C) 2017-2020, Polaris Consulting, LLC. All Rights Reserved.

response.contentType = "text/xml"


xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<customerCalls>"

msg = ""
'===================================================================================
function unicode2html(unixString)
'===================================================================================

	dbug("unicode2html....")
	
' 	retain this in case new UTF-8 character are found in future...
' 
' for future: 
'		1. uncomment loop below and lood for resulting codes in dbug log.
' 		2. lookup code groupings usually 2 or 3 chars on this debug chart:
'			https://www.i18nqa.com/debug/utf8-debug.html
'		3. find the html entity name (or &#) by googling for the unicode string, eg: 
'			"convert U+00b7 to html"
'		 	
'
' 	for i = 1 to len(trim(narrative))  
' 		if asc(mid(narrative,i,1)) > 127 then
' 			dbug("high-order ASCII detected: at character position " & i & ": " & asc(mid(narrative,i,1)) )
' 		end if
' 	next 


	str_middot					= chr(194)+chr(183)
	str_emdash 					= chr(226)+chr(128)+chr(148)
	str_leftSingleQuote 		= chr(226)+chr(128)+chr(152)
	str_rightSingleQuote 	= chr(226)+chr(128)+chr(153)
	str_leftDoubleQuote 		= chr(226)+chr(128)+chr(156)
	str_rightDoubleQuote 	= chr(226)+chr(128)+chr(157)
	str_bullet					= chr(226)+chr(128)+chr(162)
	
	tempString = unixString
	
	tempString = replace(tempString, str_middot, "&middot;")
	tempString = replace(tempString, str_endash, "&ndash;")						
	tempString = replace(tempString, str_emdash, "&mdash;")						
	tempString = replace(tempString, str_leftSingleQuote, "&lsquo;")						
	tempString = replace(tempString, str_rightSingleQuote, "&rsquo;")						
	tempString = replace(tempString, str_leftDoubleQuote, "&ldquo;")						
	tempString = replace(tempString, str_rightDoubleQuote, "&rdquo;")						
	tempString = replace(tempString, str_bullet, "&bull;")
		
	unicode2html = tempString
	
end function


'===================================================================================
function htmlEncode(stringValue)
'===================================================================================

' 	dbug("htmlEncode - startValue: " & stringValue)
	if len(stringValue) > 0 then 
		
		tempString = stringValue
		
' 		tempString = replace(tempString, chr(38), "&#38;")		' ampersand -- always do this one first
		tempString = replace(tempString, chr(39), "&#39;")		' apostrophe/single quote
		tempString = replace(tempString, chr(34), "&#34;")		' double quote
	else
		tempString = stringValue
	end if

' 	dbug("htmlEncode - endValue: " & tempString)
	htmlEncode = tempString	
	
end function


'===================================================================================
function quill2HTML(stringValue)
'===================================================================================

	dbug("quill2HTML - startValue: " & stringValue)
	if len(stringValue) > 0 then 
		
		tempString = stringValue 

		tempString = replace(tempString, "@", "&#38;")					' ampersand -- always do this one first
		tempString = replace(tempString, "\" & chr(34), "&#34;")		' double quote
		tempString = replace(tempString, "\'", "&#39;")					' apostrophe/single quote
		tempString = replace(tempString, "'", "&#39;")					' apostrophe/single quote
		tempString = replace(tempString, "&quot;", "&#34;")			' apostrophe/single quote
		
	else
		tempString = stringValue
	end if

	dbug("quill2HTML - endValue: " & tempString)
	quill2HTML = tempString	
	
end function



'===================================================================================
'===================================================================================
'===================================================================================
'===================================================================================
'===================================================================================



select case request.querystring("cmd")


	'===================================================================================
	case "updateCallDateTimes"
	'===================================================================================
	
		xml = xml & "<updateCallDateTimes>"
		
		callID 		= request.querystring("callID") 
		attribute 	= request.querystring("attribute") 
		value 		= request.querystring("value") 
		
		select case attribute 
			case "scheduledCallDate"

				setClause = "scheduledStartDateTime = convert(datetime, stuff(convert(varchar(50), scheduledStartDateTime), 1, 10, '" & value & "')), " &_
								"scheduledEndDateTime = convert(datetime, stuff(convert(varchar(50), scheduledEndDateTime), 1, 10, '" & value & "')) "
				msg = "Scheduled date updated"
				updateDB = true

			case "scheduledCallStartTime"

				setClause = "scheduledStartDateTime = convert(datetime, stuff(convert(varchar(50), scheduledStartDateTime), 12, 5, '" & value & "')) "
				msg = "Scheduled start time updated"
				updateDB = true

			case "scheduledCallEndTime"

				setClause = "scheduledEndDateTime = convert(datetime, stuff(convert(varchar(50), scheduledEndDateTime), 12, 5, '" & value & "')) "
				msg = "Scheduled end time updated"
				updateDB = true

			case "scheduledCallTimeZone"

				setClause = "scheduledTimezone = " & value & " " 
				msg = "Scheduled time zone updated"
				updateDB = true

			case "actualCallDate"
			
				setClause = "startDateTime = convert(datetime, stuff(convert(varchar(50), startDateTime), 1, 10, '" & value & "')), " &_
								"endDateTime = convert(datetime, stuff(convert(varchar(50), endDateTime), 1, 10, '" & value & "')) "
				msg = "Actual date updated"
				updateDB = true
				
			case "actualCallStartTime"

				setClause = "startDateTime = convert(datetime, stuff(convert(varchar(50), startDateTime), 12, 5, '" & value & "')) "
				msg = "Actual start time updated"
				updateDB = true
				
			case "actualCallEndTime"
			
				if value = "NULL" then 
					setClause = "endDateTime = NULL "
				else 
					setClause = "endDateTime = convert(datetime, stuff(convert(varchar(50), startDateTime), 12, 5, '" & value & "')) "
				end if
				
				msg = "Actual end time updated"
				updateDB = true

			case else 

				msg = "Unrecognized attribute"
				updateDB = false
				
		end select 
		
		if updateDB then 
			
			SQL = "update customerCalls set " &_
						setClause &_
					"where id = " & callID & " " 
					
			dbug(SQL)
					
			set rsUpdate = dataconn.execute(SQL) 
			set rsUpdate = nothing 
			
		else 
			
			dbug("DB not updated: attribute='" & attribute)
			
		end if 
			
		xml = xml & "<msg>" & msg & "</msg>"
		
		xml = xml & "</updateCallDateTimes>"
		
		
		
	'===================================================================================
	case "endCall"
	'===================================================================================
	
		xml = xml & "<endCall>"
		
		callID = request.querystring("callID")
		endDateTime = request.querystring("endDateTime") 
		
		SQL = "update customerCalls set " &_
					"endDateTime = '" & endDateTime & "', " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & callID & " " 
				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<msg>Call ended</msg>"

		xml = xml & "</endCall>"

	
	'===================================================================================
	case "updateStartTime"
	'===================================================================================
	
		xml = xml & "<updateStartTime>"
		
		callID = request.querystring("callID")
		startDateTime = request.querystring("startDateTime") 
		
		SQL = "update customerCalls set " &_
					"startDateTime = '" & startDateTime & "', " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & callID & " " 
				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<msg>Start time updated</msg>"

		xml = xml & "</updateStartTime>"

	
	'===================================================================================
	case "updateEndTime"
	'===================================================================================
	
		xml = xml & "<updateEndTime>"
		
		callID = request.querystring("callID")
		endDateTime = request.querystring("endDateTime") 
		
		SQL = "update customerCalls set " &_
					"endDateTime = '" & endDateTime & "', " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & callID & " " 
				
		dbug("updateEndTime: " & SQL)
				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<msg>End time updated</msg>"

		xml = xml & "</updateEndTime>"

	
	'===================================================================================
	case "startCall"
	'===================================================================================
	
		xml = xml & "<startCall>"
		
		callID = request.querystring("callID")
		startDateTime = request.querystring("startDateTime") 
		
		SQL = "update customerCalls set " &_
					"startDateTime = '" & startDateTime & "', " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & callID & " " 
				
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<msg>Call started</msg>"

		xml = xml & "</startCall>"

	
'===================================================================================
	case "addAttendees"
'===================================================================================

		xml = xml & "<addAttendees>"
		
		customerID		= request.querystring("customerID") 
		customerCallID = request.querystring("customerCallID")
		attendeeType 	= "'" & request.querystring("attendeeType") & "'" 
		attendeesToAdd = split(request.querystring("attendeesToAdd"),",")
		
		dbug("uBound(attendeesToAdd): " & uBound(attendeesToAdd))
		
		for each attendeeID in attendeesToAdd
			
			dbug("top of for-each loop")
			
			newID = getNextID("customercallAttendees") 
				
			SQL = "insert into customerCallAttendees (id, customerCallID, attendeeType, attendeeID, updatedBy, updatedDateTime) " &_
					"values ( " 						 	&_
						newID						& ", " 	&_
						customerCallID			& ", " 	&_
						attendeeType			& ", " 	&_
						attendeeID				& ", " 	&_
						session("userID") 	& ", " 	&_
						"current_timestamp "  			&_
					") " 	
						
			dbug(SQL)
			
			set rsInsert = dataconn.execute(SQL) 
			set rsInsert = nothing 

			xml = xml & "<attendeeID>" & attendeeID & "</attendeeID>"
			
		next 
		
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<customerCallID>" & customerCallID & "</customerCallID>"
		xml = xml & "<attendeeType>" & attendeeType & "</attendeeType>"
		xml = xml & "<addAttendees>" & addAttendees & "</addAttendees>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</addAttendees>"



'===================================================================================
	case "getAttendees"
'===================================================================================

		xml = xml & "<getAttendees>"
		
		customerID		= request.querystring("customerID") 
		customerCallID = request.querystring("customerCallID")
		attendeeType 	= request.querystring("attendeeType") 
		
		select case attendeeType 
		
			case "user"

				SQL = "select " &_
							"u.id, " &_
							"concat(u.firstName, ' ', u.lastName) as fullName " 	&_
						"from cSuite..users u " 											&_
						"where u.id in ( " 													&_
							"select uc.userID " 												&_
							"from userCustomers uc " 										&_
							"where uc.customerID = 1) " 									&_
						"and u.active = 1 " 													&_
						"and (u.deleted = 0 or u.deleted is null) " 					&_
						"and u.id not in ( " 												&_
							"select ca.attendeeID " 										&_
							"from customerCallAttendees ca " 							&_
							"where attendeeType = 'user' " 								&_
							"and customerCallID = " & customerCallID & " " 			&_
						") " &_
						"order by 2 "
			
			case "contact" 
			
				SQL = "select " 																&_
							"cc.id, " 															&_
							"case when (cc.firstName is null and cc.lastName is null) then cc.name else concat(cc.firstName, ' ', cc.lastName) end as fullName " &_
						"from customerContacts cc " 										&_
						"where customerID = " & customerID & " " 						&_
						"and cc.id not in ( " 												&_
							"select ca.attendeeID " 										&_
							"from customerCallAttendees ca " 							&_
							"where attendeeType = 'contact' " 							&_
							"and customerCallID = " & customerCallID & " " 			&_
						") " 																		&_
						"order by 2 "

			case else 
			
				SQL = ""
				msg = "Attendee type not found"
				
			
		end select 
	
		dbug(SQL) 
		
		if len(SQL) > 0 then 
			
			xml = xml & "<attendees>"

			set rsA = dataconn.execute(SQL) 
			while not rsA.eof 
			
				xml = xml & "<attendee id=""" & rsA("id") & """>" & rsA("fullName") & "</attendee>"
				
				rsA.movenext 
				
			wend 
			
			rsA.close 
			set rsA = nothing 

			xml = xml & "</attendees>"
			
			msg = "Attendees Retreived"
			
		end if 
		
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<customerCallID>" & customerCallID & "</customerCallID>"
		xml = xml & "<attendeeType>" & attendeeType & "</attendeeType>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</getAttendees>"
	
	
'===================================================================================
' 	case "attendee" 
'===================================================================================
' 		
' 		xml = xml & "<attendee>"
' 
' 		attendeeID		= request.querystring("attendeeID")
' 		
' 		SQL = "select id, attendedIndicator " &_
' 				"from customerCallAttendees " &_
' 				"where id = " & attendeeID & " "
' 				
' 		dbug(SQL)				
' 		set rsA = dataconn.execute(SQL)
' 		
' 		if not rsA.eof then 
' 			dbug("not rsA.eof...")
' 			if not isNull(rsA("attendedIndicator")) then 
' 				dbug("not isNull(rsA('attendedIndicator'))")
' 				if rsA("attendedIndicator") then 
' 					dbug("rsA('attendedIndicator)) = true")
' 					newAttendedIndicator = 0
' 				else 
' 					dbug("cInt(rsA('attendedIndicator)) <> 1; instead: " & cInt(rsA("attendedIndicator")) )
' 					newAttendedIndicator = 1
' 				end if 
' 			else 
' 				dbug("isNull(rsA('attendedIndicator'))")
' 				newAttendedIndicator = 1
' 			end if
' 			
' 			SQL = "update customerCallAttendees set " &_
' 						"attendedIndicator = " & newAttendedIndicator & " " &_
' 					"where id = " & attendeeID & " " 
' 					
' 			dbug(SQL)
' 			set rsUpdate = dataconn.execute(SQL) 
' 			set rsUpdate = nothing 
' 			
' 			msg = "Attendee updated"
' 					
' 		else 
' 			
' 			newAttendedIndicator = "n/a"
' 			msg = "Attendance indicator cannot be found" 
' 			
' 		end if 
' 
' 		xml = xml & "<attendeeID>" & attendeeID & "</attendeeID>"
' 		xml = xml & "<attendedIndicator>" & newAttendedIndicator & "</attendedIndicator>"
' 		xml = xml & "<msg>" & msg & "</msg>"
' 
' 		xml = xml & "</attendee>"
		
		
'===================================================================================
' 	case "deleteAttendee" 
'===================================================================================
' 
' 		xml = xml & "<deleteAttendee>"
' 		
' 		attendeeID = request.querystring("attendeeID") 
' 		
' 		SQL = "delete from customerCallAttendees where id = " & attendeeID
' 		
' 		dbug(SQL) 
' 		
' 		set rsDelete = dataconn.execute(SQL) 
' 		set rsDelete = nothing 
' 		
' 		xml = xml & "<attendeeID>" & attendeeID & "</attendeeID>"
' 		xml = xml & "<msg>Attendee deleted</msg>"
' 
' 		xml = xml & "</deleteAttendee>"



'===================================================================================
	case "addCustomerCallType"
'===================================================================================
	
		xml = xml & "<addCustomerCallType>"

		cctID		= request.querystring("id")
		cctName 	= escapeQuotes(request.querystring("name"))
		cctDesc 	= escapeQuotes(request.querystring("desc"))
		
		if len(request.querystring("freq")) > 0  then
			cctFreq 	= request.querystring("freq")
		else 
			cctFreq = "NULL"
		end if 
		
		cctShort	= escapeQuotes(request.querystring("short"))
		
		if len(request.querystring("weight")) > 0 then 
			cctWeight	= escapeQuotes(request.querystring("weight"))
		else 
			cctWeight = "NULL"
		end if
		
		
		if request.querystring("required") = 1 then 
			required = 1
		else 
			required = "NULL"
		end if 
		
		if len(cctID) > 0 then 
			
			SQL = "update customerCallTypes " &_
					"set " &_
						"name = '" & cctName & "', " &_
						"description= '" & cctDesc & "', " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = CURRENT_TIMESTAMP, " &_
						"idealFrequencyDays = "  & cctFreq & ", " &_
						"shortName = '" & cctShort & "', " &_
						"weight = " & cctWeight & ", " &_
						"requiredForNewCustomers = " & required & " " &_
					"where id = " & cctID & " "

		else 
		
			newID = getNextID("customerCallTypes")
			
			SQL = "insert into customerCallTypes (id, name, description, updatedBy, updatedDateTime, idealFrequencyDays, shortName, weight, requiredForNewCustomers ) " &_
					"values ( " &_
						newID & ", " &_
						"'" & cctName & "', " &_
						"'" & cctDesc & "', " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						cctFreq & ", " &_
						"'" & cctShort & "', " &_
						cctWeight & ", " &_
						required &_ 
					") " 
						
		end if 
		
		dbug("customerCallTypes: " & SQL)
		set rs = dataconn.execute(SQL)
		set rs = nothing 
		
		msg = "Customer call type updated"
		
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<name>" & cctName & "</name>"
		xml = xml & "<description>" & cctDesc & "</description>"
		xml = xml & "<idealFrequencyDays>" & cctFreq & "</idealFrequencyDays>"
		xml = xml & "<shortName>" & cctShort & "</shortName>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</addCustomerCallType>"

	
'===================================================================================
	case "callType"
'===================================================================================
	
		xml = xml & "<callType>"
		
		customerCallID = request.querystring("callID")
		callTypeID = request.querystring("callTypeID")
		
		SQL = "update customerCalls " &_
				"set callTypeID = " & callTypeID & " " &_
				"where id = " & customerCallID & " "
		
		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = "Call type udpated"
		
		xml = xml & "<customerCallID>" & customerCallID & "</customerCallID>"
		xml = xml & "<callTypeID>" & callTypeID & "</callTypeID>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</callType>"
		


'===================================================================================
	case "delCustomerCallType" 
'===================================================================================
	
		xml = xml & "<delCustomerCallType>"

		cctID = request.querystring("id")
		
		SQL = "delete from customerCallTypes where id = " & cctID & " " 
		
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		msg = "Customer call type deleted"
		
		xml = xml & "<id>" & cctID & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</delCustomerCallType>"


		
'===================================================================================
	case "callDate"
'===================================================================================
	
		xml = xml & "<callDate>"
		
		customerCallID = request.querystring("customerCallID")
		customerCallDateType = request.querystring("customerCallDateType")
		
		if len(request.querystring("customerCallDatetime")) > 0 then 
			customerCallDateTime = "'" & replace(request.querystring("customerCallDateTime"),"T"," ") & "'" 
		else 
			customerCallDatetime = "NULL"
		end if
		
		
		SQL = "update customerCalls set " &_
					customerCallDateType & " = " & customerCallDateTime & " " &_
				"where id = " & customerCallID & " "
				
		dbug(SQL)
			
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = customerCallDateType & " updated"
		
		xml = xml & "<customerCallID>" & customerCallID & "</customerCallID>"
		xml = xml & "<customerCallDateType>" & customerCallDateType & "</customerCallDateType>"
		xml = xml & "<customerCallDateTime>" & customerCallDateTime & "</customerCallDateTime>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</callDate>"
			
			
			
'===================================================================================
	case "getQuill"
'===================================================================================
	
		xml = xml & "<getQuill>"

		customerCallID = request.querystring("customerCallID")
		callNoteTypeID = request.querystring("callNoteTypeID")
		
		SQL = "select " &_
					"id, " &_
					"narrative, " &_
					"name, " &_
					"quillID, " &_
					"updatedDatetime " &_
				"from customerCallNotes " &_
				"where customerCallID = " & customerCallID & " " &_
				"and noteTypeID = " & callNoteTypeID & " " 
		
		dbug(SQL)
		
		set rsGQ = dataconn.execute(SQL)

		dbug(" ")
		dbug("narrative before any manipulation...")
		dbug(rsGQ("narrative"))
		dbug(" ")

		if not rsGQ.eof then 
			if not isNull(rsGQ("narrative")) then 
'				narrative = replace(rsGQ("narrative"), "&", "&amp;")
				narrative = rsGQ("narrative")
			end if
			msg 					= "Narrative found"
			noteTypeName 		= rsGQ("name")
			quillID 				= rsGQ("quillID")
			updatedDateTime 	= rsGQ("updatedDateTime")
		else 
			narrative 			= ""
			msg 					= "Narrative not found"
			noteTypeName 		= ""
			quillID 				= ""
			updatedDateTime 	= ""
		end if
		rsGQ.close 
		set rsGQ = nothing 
		
		xml = xml & "<id>" & id & "</id	>"
		xml = xml & "<noteTypeName>" & noteTypeName & "</noteTypeName>"
		xml = xml & "<noteTypeID>" & callNoteTypeID & "</noteTypeID>"
		xml = xml & "<quillID>" & quillID & "</quillID>"
		xml = xml & "<updatedDateTime>" & updatedDateTime & "</updatedDateTime>"

		if len(narrative) > 0 then 
			xml = xml & "<narrative><![CDATA[" & narrative & "]]></narrative>"
		else 
			xml = xml & "<narrative></narrative>"
		end if 

		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</getQuill>"
		
		
'===================================================================================
	case "saveQuill"
'===================================================================================
	
		xml = xml & "<saveQuill>"
		
		callID 					= request("callID")
		callNoteTypeID 		= request("callNoteTypeID")
		callGenericTimeStamp = request("genericTimeStamp")
' 		callNoteNarrative		= escapeApostrophes(request("callNoteNarrative"))
' 		callNoteNarrative		= replace(request("callNoteNarrative"), "'", "'")
		callNoteNarrative		= request("callNoteNarrative")
	
		
		nowDateTime				= now()
		
		updatedDateTime 		= datePart("yyyy",nowDateTime) & "-" &_
									  datePart("m",nowDateTime) & "-" &_
									  datePart("d",nowDateTime) & " " &_
									  datePart("h",nowDateTime) & ":" &_
									  right("00" & datePart("n",nowDateTime),2) & ":" &_
									  right("00" & datePart("s",nowDateTime),2) 
									  
' 		updatedDateTime		= DateValue("1111-11-11 11:11:11")
									  
		dbug("updatedDateTime: " & updatedDateTime)							   
		
' 		' replace double-quotes -- chr(34) -- with &#34; ...
' 		callNoteHTML 			= replace(request("callNoteHTML"), chr(34), "&#34;")
		' replace double-quotes -- chr(34) -- with double double-quotes ...
		callNoteHTML 			= replace(request("callNoteHTML"), chr(34), """")

		' replace single-quotes -- chr(39) -- with &#39; ...
		callNoteHTML 			= replace(callNoteHTML, chr(39), "&#39;")
' 		' replace single-quotes -- chr(39) -- with double single-quotes ...
' 		callNoteHTML 			= replace(callNoteHTML, chr(39), "''")



		' update customerCallNotes via a recordset object with optimistic locking...
		SQL = "select * from customerCallNotes where customerCallID = " & callID & " and noteTypeID = " & callNoteTypeID & " " 
		dbug(SQL)

		set rsNotes = server.createObject("ADODB.Recordset")
		
		dbug("JUST prior to insertion...") 
		dbug("callNoteNarrative: " & callNoteNarrative) 
		dbug("callNoteHTML: " & callNoteHTML)
		
		with rsNotes
			.open SQL, dataconn, adOpenDynamic, adLockOptimistic, adCmdText
			
			if not .eof then 
				
				dbug("update existing customerCallNote...")
				.fields("updatedBy")			= session("userID")
				.fields("updatedDateTime") = cStr(updatedDateTime)
				.fields("narrative") 		= callNoteNarrative
				.fields("narrativeHTML") 	= callNoteHTML
				.update
				
				msg = "note updated"
				
			else 
				
				dbug("inserting new customerCallNote....")
				.addNew
				newID = getNextID("customerCallNotes")
				.fields("id") 					= newID
				.fields("customerCallID") 	= callID
				.fields("noteTypeID") 		= callNoteTypeID
				.fields("updatedBy") 		= session("userID")
				.fields("updatedDateTime") = updatedDateTime
				.fields("narrative") 		= callNoteNarrative
				.fields("narrativeHTML") 	= narrativeHTML
				.update 
				
				msg = "note added"
			
			end if 
			
			.close 
			set rsNotes = nothing 
			
		end with 


		SQL = "select quillID from noteTypes where id = " & callNoteTypeID & " "
		set rsQ = dataconn.execute(SQL)
		if not rsQ.eof then 
			quillID = rsQ("quillID")
		else 
			quillID = ""
		end if
		rsQ.close 
		set rsQ = nothing 

		xml = xml & "<quillID>" & quillID & "</quillID>"
		xml = xml & "<rawQuillID>" & "raw" & quillID & "</rawQuillID>"
		xml = xml & "<databaseTimeStamp>" & databaseTimeStamp & "</databaseTimeStamp>"
		xml = xml & "<updatedBy>" & updatedBy & "</updatedBy>"
		xml = xml & "<updatedDateTime>" & updatedDateTime & "</updatedDateTime>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</saveQuill>"

	
'===================================================================================
	case "updateNarrative"
'===================================================================================
	
		xml = xml & "<updateNarrative>"
		
		customerCallNoteID = request.querystring("customerCallNoteID")
		
		SQL = "select id from customerCallNotes where customerCallID = " & callID & " and noteTypeID = " & callNoteTypeID & " " 
		dbug(SQL)
		set rsN = dataconn.execute(SQL)
		if not rsN.eof then 
			SQL = "update customerCallNotes set narrative = '" & escapeApostrophes(callNoteNarrative) & "' where id = " & rsN("id") & " " 
		else 
			newID = getNextID("customerCallNotes")
			SQL = "insert into customerCallNotes (id, customerCallID, noteTypeID, updatedBy, updatedDateTime, narrative) " &_
					"values ( " &_
					newID & ", " &_
					callID & ", " &_
					callNoteTypeID & ", " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP, " &_
					"'" & escapeApostrophes(callNoteNarrative) & "') " 
		end if
		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		rsN.close 
		set rsN = nothing 

		msg = "Annotation saved"
		
		xml = xml & "<callID>" & callID & "</callID>"
		xml = xml & "<callNoteNarrative>" & callNoteNarrative & "</callNoteNarrative>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</updateNarrative>"

	
'===================================================================================
	case "updateAgendaSeq"
'===================================================================================
	
		xml = xml & "<updateAgendaSeq>"
		
		noteTypeID 	= request.querystring("noteTypeID")
		seq			= request.querystring("seq")
		
		SQL = "update noteTypes set seq = " & seq & " where id = " & noteTypeID & " " 
		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 

		xml = xml & "</updateAgendaSeq>"
		
	
'===================================================================================
	case "addNoteType" 
'===================================================================================
	
		xml = xml & "<addNoteType>"
		
		itemName 	= escapeQuotes(request.querystring("itemName"))
		itemDesc 	= escapeQuotes(request.querystring("itemDesc"))
		callTypeID 	= request.querystring("callTypeID")
		noteTypeID 	= request.querystring("noteTypeID")
		
		if len(noteTypeID) > 0 then 
			
			newID = noteTypeID
			
			SQL = "update noteTypes set " &_
						"name = '" & itemName & "', " &_
						"description = '" & itemDesc & "' " &_
					"where id = " & newID & " " 
					
			msg = "Agenda item updated"
					
		else 
			
			SQL = "select max(seq) as maxSeq from noteTypes where callTypeID = " & callTypeID & " "
			dbug(SQL)
			set rsSEQ = dataconn.execute(SQL)
			if not rsSEQ.eof then 
				if not isNull(rsSEQ("maxSeq")) then 
					newSeq = cInt(rsSEQ("maxSeq")) + 1
				else 
					newSeq = 1
				end if 
			else 
				newSeq = 1
			end if
			
			newID = getNextID("noteTypes") 
			
			quillID = "edit" & cStr(newID) 
			
			SQL = "insert into noteTypes (id, name, description, seq, updatedBy, updatedDateTime, quillID, callTypeID, includeWithEmails) " &_
					"values ( " &_
						newID & ", " &_
						"'" & itemName & "', " &_
						"'" & itemDesc & "', " &_
						newSeq & ", " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						"'" & quillID & "', " &_
						callTypeID & "," &_
						"0 ) "

			msg = "Agenda item added"

		end if 						

		dbug(SQL)
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		xml = xml & "<callTypeID>" & callTypeID & "</callTypeID>"
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<seq>" & newSeq & "</seq>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</addNoteType>"


	'===================================================================================
	case "startDateTime"
	'===================================================================================
	
		xml = xml & "<startDateTime>"

		customerCallID = request.querystring("id")
		startDateTime = request.querystring("value")
		timeZoneName = request.querystring("timezone")
		
		tzSQL = "select id from timezones where fullName = '" & timezoneName & "' " 
		dbug("tz SQL: " & tzSQL)
		set rsTZ = dataconn.execute(tzSQL)
		if not rsTZ.eof then 
			timezoneID = rsTZ("id") 
		else 
			timezoneID = NULL
		end if 
		rsTZ.close 
		set rsTZ = nothing 
		
		dbug("timezoneID: " & timezoneID)
	
		SQL = "update customerCalls set " &_
					"startDateTime = '" & startDateTime & "', " &_
					"timezone = " & timezoneID & ", " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & request.querystring("id") & " " 
		
		dbug(SQL)
			
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = "Start date/time updated"
		
		xml = xml & "<customerCallDateType>" & request.querystring("cmd") & "</customerCallDateType>"
		xml = xml & "<startDateTime>" & startDateTime & "</startDateTime>"
		xml = xml & "<timezoneID>" & timezoneID & "</timezoneID>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</startDateTime>"
	

	'===================================================================================
	case "endDateTime"
	'===================================================================================
	
		xml = xml & "<endDateTime>"

		customerCallID = request.querystring("id")
		endDateTime = request.querystring("value")
	
		SQL = "update customerCalls set " &_
					"endDateTime = '" & endDateTime & "', " &_
					"updatedBy = " & session("userID") & ", " &_
					"updatedDateTime = CURRENT_TIMESTAMP " &_
				"where id = " & request.querystring("id") & " " 
		
		dbug(SQL)
			
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = "End date/time updated"
		
		xml = xml & "<customerCallDateType>" & request.querystring("cmd") & "</customerCallDateType>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</endDateTime>"
		
		
	'===================================================================================
	case "sendCall"
	'===================================================================================
	
		dbug(" " )
		dbug("===================================================================================")
		dbug("START OF sendCall")
		dbug("===================================================================================")
		' *** NOTE: This section sends an "Agenda" or "Recap"...
	
		xml = xml & "<sendCall>"
		
		toList 		= request.querystring("to")
		ccList 		= request.querystring("cc")
		id		 		= request.querystring("id")
		customerID 	= request.querystring("customerID")
		
		
		maxEmailWidth = systemControls("Send Call Agenda Max Width (pixels)")
		if isNull(maxEmailWidth) then 
			maxEmailWidth = "800"
		else 
			if len(maxEmailWidth) > 0 then 
				if not isNumeric(maxEmailWidth) then 
					maxEmailWidth = "800"
				end if 
			else 
				maxEmailWidth = "800"
			end if
		end if 
		dbug("maxEmailWidth: " & maxEmailWidth)
		
		
		set objmail		= createobject("CDO.Message")
		smtpParms
		objmail.from		= systemControls("Generic Email From Address")

		if len(request.querystring("to")) > 0 then 
			objmail.to		= request.querystring("to")
		end if
		if len(request.querystring("cc")) > 0 then
			objmail.cc			= request.querystring("cc")
		end if
		if len(request.querystring("subject")) > 0 then 
			objmail.subject	= request.querystring("subject")			
		end if

		
		' Need to build out HTMLbody with remaining call content
		html = "<html>"

		html = html & "<head>"
		html = html & 	"<meta name=""viewport"" content=""width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"" />"
' 		html = html & 	"<meta http-equiv=""Content-Type"" content=""text/html; charset=UTF-8"" />"

		html = html & "<link href=""https://cdn.quilljs.com/1.3.5/quill.snow.css"" rel=""stylesheet"">"

		html = html & 	"<style type=""text/css"">"
		html = html & 		"ReadMsgBody { width: 100%;} "
		html = html & 		"body {-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; margin:0 !important;} "
		html = html & 		"p { margin: 1em 0;} "
		html = html & 		"@-ms-viewport { width: device-width;} "
		html = html & 	"</style>"
		
		html = html & 	"<style type=""text/css"">"
		html = html & 		"table, tr {"
		html = html & 			"border-collapse: collapse;"
		html = html & 		"}"
			
		html = html & 		"agendaLI {"
		html = html & 			"font-weight: bold;"
		html = html & 			"list-style-type: upper-roman;"
		html = html & 		"}"
			
		html = html & 		".sectionHeader-left {"
		html = html & 			"text-align: left;"
		html = html & 			"border: solid black 1px;"
		html = html & 			"background-color: lightgrey;"
		html = html & 			"font-weight: bold;"
		html = html & 			"padding-left: 5px;"
		html = html & 		"}"
	
		html = html & 		".sectionHeaderRowHeader {"
		html = html & 			"text-align: left;"
		html = html & 			"border: solid black 1px;"
		html = html & 			"background-color: lightgrey;"
		html = html & 			"font-weight: bold;"
		html = html & 			"padding-left: 5px;"
		html = html & 		"}"
	
		html = html & 		".sectionHeaderDate {"
		html = html & 			"text-align: center;"
		html = html & 			"border: solid black 1px;"
		html = html & 			"background-color: lightgrey;"
		html = html & 			"font-weight: bold;"
		html = html & 			"width: 75px;"
		html = html & 		"}"
	
		html = html & 		".sectionHeader-center {"
		html = html & 			"text-align: center;"
		html = html & 			"border: solid black 1px;"
		html = html & 			"background-color: lightgrey;"
		html = html & 			"font-weight: bold;"
		html = html & 		"}"
	
		html = html & 		".sectionBody {"
		html = html & 			"padding-left: 25px;"
		html = html & 		"}"
			
		html = html & 		".sectionDetailRowHeader {"
		html = html & 			"text-align: left;"
		html = html & 			"padding-left: 25px;"
		html = html & 			"border: solid black 1px;"
		html = html & 			"width: 250px;"
		html = html & 		"}"
			
		html = html & 		".sectionDetailDate {"
		html = html & 			"text-align: center;"
		html = html & 			"padding-left: 5px;"
		html = html & 			"padding-right: 5px;"
		html = html & 			"border: solid black 1px;"
		html = html & 			"width: 75px;"
		html = html & 		"}"
			
		html = html & 		".sectionDetail-left {"
		html = html & 			"text-align: left;"
		html = html & 			"padding-left: 5px;"
		html = html & 			"padding-right: 5px;"
		html = html & 			"border: solid black 1px;"
		html = html & 		"}"
			
		html = html & 		".sectionDetail-center {"
		html = html & 			"text-align: center;"
		html = html & 			"padding-left: 5px;"
		html = html & 			"padding-right: 5px;"
		html = html & 			"border: solid black 1px;"
		html = html & 		"}"
			
		html = html & 	"</style>"
		html = html & "</head>"


		html = html & 	"<body><div style=""width: " & maxEmailWidth & "px; margin: auto;"">"
		
		dbug("inspecting 'comments'...")
		comments = request.querystring("comments") 
		dbug("comments: " & comments)
		dbug("linStr(comments, vbCRLF): " & inStr(comments, Chr(13)&Chr(10)))
		dbug("linStr(comments, vbCR): " & inStr(comments, Chr(13)))
		dbug("linStr(comments, vbLF): " & inStr(comments, Chr(10)))

		comments = replace(comments, Chr(10)&Chr(13), "<br>")
		dbug("comments (after replacing CRLFs: " & comments)
		comments = replace(comments, Chr(10), "<br>")
		dbug("comments (after replacing LFs: " & comments)
		comments = replace(comments, Chr(13), "<br>")
		dbug("comments (after replacing CRs: " & comments)
		
		html = html & 	"<p>" & comments & "</p>"
		
		SQL = "select " &_
					"cc.scheduledStartDateTime, " &_
					"cc.scheduledEndDateTime, " &_
					"cc.startDateTime, " &_
					"cc.endDatetime, " &_
					"cc.name as callName, " &_
					"actual.name as actualTimeZone,  " &_
					"scheduled.name as scheduledTimeZone, " &_
					"c.id as customerID, " &_
					"c.name as customerName, " &_
					"c.nickName as customerNickName " &_
				"from customerCalls cc  " &_
				"left join timezones actual on (actual.id = cc.actualTimezone)  " &_
				"left join timezones scheduled on (scheduled.id = cc.scheduledTimeZone)  " &_
				"left join customer_view c on (c.id = cc.customerID) " &_
				"where cc.id = " & id & " " 
		dbug(SQL)
		dbug(" ")


		set rsCC = dataconn.execute(SQL) 
		if not rsCC.eof then 
			
			if len(rscc("endDateTime")) > 0 then 
				recap = true
			else 
				recap = false
			end if
			
			dbug("recap? " & recap)
			
			customerID = rsCC("customerID")
			if len(rsCC("customerNickName")) > 0 then 
				customerName = rsCC("customerNickName")
			else 
				customerName = rsCC("customerName")
			end if
			
			'*****************************************************************************************
			'* Header info (scheduled start, actual start, actual end
			'*****************************************************************************************
			
			dbug("email header...")
			
			html = html &	"<table style=""border: solid black 1px; width: " & maxEmailWidth & """>"
			html = html &		"<tr><td class=""sectionHeader-left"">Call Info</td></tr>"
			html = html &		"<tr><td class=""sectionBody"">" & customerName & " - " & rsCC("callname") & "</td></tr>"
			
			dbug("rsCC(startDateTime): " & rsCC("startDateTime"))
			
			if not isNull(rsCC("startDateTime")) then 
				if isDate(rsCC("startDateTime")) then 
					startDateLong = formatDateTime(rsCC("startDateTime"),1)
					if datePart("h",rsCC("startDateTime")) > 12 then 
						startTime = cInt(datePart("h",rsCC("startDateTime")) - 12) & ":" & right("00" & datePart("n", rsCC("startDateTime")),2) & " PM"
					else 
						if datePart("h",rsCC("startDateTime")) = 12 then 
							startTime = datePart("h", rsCC("startDateTime")) & ":" & right("00" & datePart("n", rsCC("startDateTime")),2)
							startTime = startTime & " PM"
						else 
							if datePart("h",rsCC("startDatetime")) = 0 then
								startTime = "12:" & right("00" & datePart("n", rsCC("startDateTime")),2)
							else 
								startTime = datePart("h", rsCC("startDateTime")) & ":" & right("00" & datePart("n", rsCC("startDateTime")),2)
							end if
							startTime = startTime & " AM"
						end if 
					end if 
				else 
					startDateLong = "?"
					startTime = "?"
				end if 
			else 
				startDateLong = ""
				startTime = ""
			end if 
			
			dbug("startDateLong: " & startDateLong)
			dbug("startTime: " & startTime)
			
			
			dbug("rsCC(endDateTime): " & rsCC("endDateTime"))

			if not isNull(rsCC("endDateTime")) then 
				if isDate(rsCC("endDateTime")) then 
					endDateLong = formatDateTime(rsCC("endDateTime"),1)
					if datePart("h",rsCC("endDateTime")) > 12 then 
						endTime = cInt(datePart("h",rsCC("endDateTime")) - 12) & ":" & right("00" & datePart("n", rsCC("endDateTime")),2) & " PM"
					else 
						dbug("datePart('h', rsCC('endDateTime')): " & datePart("h", rsCC("endDateTime")))
						endTime = datePart("h", rsCC("endDateTime")) & ":" & right("00" & datePart("n", rsCC("endDateTime")),2)
						if datePart("h",rsCC("endDateTime")) = 12 then 
							endTime = endTime & " PM"
						else 
							endTime = endTime & " AM"
						end if 
					end if 
				else 
					endDateLong = "?"
					endTime = "?"
				end if 
			else 
				endDatetime = ""
				endTime = ""
			end if 
			
			dbug("endDateLong: " & endDateLong)
			dbug("endTime: " & entTime)
			
			
			dbug("rsCC(scheduledStartDateTime): " & rsCC("scheduledStartDateTime"))

			if not isNull(rsCC("scheduledStartDateTime")) then 
				if isDate(rsCC("scheduledStartDateTime")) then 
					scheduledStartDateLong = formatDateTime(rsCC("scheduledStartDateTime"),1)
					if datePart("h",rsCC("scheduledStartDateTime")) > 12 then 
						scheduledStartTime = cInt(datePart("h",rsCC("scheduledStartDateTime")) - 12) & ":" & right("00" & datePart("n", rsCC("scheduledStartDateTime")),2) & " PM"
					else 
						scheduledStartTime = datePart("h", rsCC("scheduledStartDateTime")) & ":" & right("00" & datePart("n", rsCC("scheduledStartDateTime")),2)
						if datePart("h",rsCC("scheduledStartDateTime")) = 12 then 
							scheduledStartTime = scheduledStartTime & " PM"
						else 
							scheduledStartTime = scheduledStartTime & " AM"
						end if 
						
					end if 
				else 
					scheduledStartDateLong = "?"
					scheduledStartTime = "?"
				end if 
			else 
				scheduledStartDateLong = ""
				scheduledStartTime = ""
			end if 
			
			dbug("scheduleStartDateLong: " & scheduleStartDateLong)
			dbug("scheduledStartTime: " & scheduledStartTime)
			
			
			dbug("rsCC(scheduledEndDateTime): " & rsCC("scheduledEndDateTime"))

			if not isNull(rsCC("scheduledEndDateTime")) then 
				if isDate(rsCC("scheduledEndDateTime")) then 
					scheduledEndDateLong = formatDateTime(rsCC("scheduledEndDateTime"),1)
					if datePart("h",rsCC("scheduledEndDateTime")) > 12 then 
						scheduledEndTime = cInt(datePart("h",rsCC("scheduledEndDateTime")) - 12) & ":" & right("00" & datePart("n", rsCC("scheduledEndDateTime")),2) & " PM"
					else 
						scheduledEndTime = datePart("h", rsCC("scheduledEndDateTime")) & ":" & right("00" & datePart("n", rsCC("scheduledEndDateTime")),2)
						if datePart("h",rsCC("scheduledEndDateTime")) = 12 then 
							scheduledEndTime = scheduledEndTime & " PM"
						else 
							scheduledEndTime = scheduledEndTime & " AM"
						end if 
						
					end if 
				else 
					scheduledEndDateLong = "?"
					scheduledEndTime = "?"
				end if 
			else 
				scheduledEndDateLong = ""
				scheduledEndTime = ""
			end if 

			dbug("scheduleEndDateLong: " & scheduleEndDateLong)
			dbug("scheduledEndTime: " & scheduledEndTime)
			
			
			

			if recap then 
				html = html &		"<tr><td class=""sectionBody"">" & startDateLong & "</td></tr>"
				html = html &		"<tr><td class=""sectionBody"">" & startTime & " - " & endTime & " " & rsCC("scheduledTimeZone") & "</td></tr>"
				html = html &		"<tr><td class=""sectionBody""><br><b>Minutes: see detailed notes below</b></td></tr>"
			else 
				html = html &		"<tr><td class=""sectionBody"">" & scheduledStartDateLong & "</td></tr>"
				html = html &		"<tr><td class=""sectionBody"">" & scheduledStartTime & " - " & scheduledEndTime & " " & rsCC("scheduledTimeZone") & "</td></tr>"
			end if
			html = html &		"<tr><td class=""sectionBody"">&nbsp;</td></tr>"
			
			if not recap then 

				html = html &		"<tr><td class=""sectionHeader-left"">Discussion Agenda</td></tr>"

				SQL = "select cn.name " &_
						"from customerCallNotes cn " &_
						"join noteTypes nt on (nt.id = cn.noteTypeID) " &_
						"where cn.customerCallID = " & id & " " &_
						"and nt.includeWithEmails = 1 " &_
						"order by cn.seq " 
						
				dbug("agenda items: " & SQL)
				
				set rsAgenda = dataconn.execute(SQL)
							
				if not rsAgenda.eof then 
					html = html &		"<tr><td class=""sectionBody"">"
					html = html &			"<ol>"
					
					while not rsAgenda.eof 
						html = html &				"<li class=""agendaLI"">" & rsAgenda("name") & "</li>"
						rsAgenda.movenext 
					wend 
	
					rsAgenda.close
					set rsAgenda = nothing 
						
					html = html &			"</ol>"
					html = html &		"</td></tr>"
				
				end if
				
			else 
				 ' GET ATTENDEES
				SQL = "select " &_
							"a.attendeeID, " &_
							"a.attendeeType, " &_
							"case when attendeeType = 'user' then u.userName else c.email end as attendeeEmail, " &_
							"case when attendeeType = 'user' then concat(u.firstName, ' ', u.lastName) else concat(c.firstName, ' ', c.lastName) end as attendeeName  " &_
						"from customerCallAttendees a " &_
						"left join cSuite..users u on (u.id = a.attendeeID and attendeeType = 'user') " &_
						"left join customerContacts c on (c.id = attendeeID and attendeeType = 'contact') " &_
						"where customerCallID = 124 "
						
				set rsAttend = dataconn.execute(SQL)
				
				if not rsAttend.eof then 
	
					html = html &		"<tr><td class=""sectionHeader-left"">Attendees</td></tr>"
					html = html &		"<tr><td class=""sectionBody"">"
					html = html & 			"<ul style=""list-style-type: none;"">"
					
					while not rsAttend.eof 
						html = html & 			"<li>" & rsAttend("attendeeName")
						if len(rsAttend("attendeeEmail")) > 0 then 
							html = html & "&nbsp;(" & rsAttend("attendeeEmail") & ")"
						end if 
						html = html & 			"</li>" 
						rsAttend.movenext 
					wend 

					html = html & 			"</ul>"
					html = html & 		"</td></tr>"				

				end if 
				
				rsAttend.close
				set rsAttend = nothing 
				
				
			end if

			html = html &	"</table>"
			html = html &	"<br><br>"
			
			'*****************************************************************************************
			'* Key Initiatives...
			'*****************************************************************************************

			kiSQL = "select name, startDate, endDate from keyInitiatives where completeDate is null and customerID = " & customerID & " order by endDate " 
			
			dbug("get KIs for email: " & kiSQL)
			
			set rsKI = dataconn.execute(kiSQL)
			
			if not rsKI.eof then 		
			
	
				html = html & 	"<table>"
				html = html &		"<tr>"
				html = html &			"<td class=""sectionHeaderRowHeader"">Key Initiatives</td>"
				html = html &			"<td class=""sectionHeaderDate"">Start</td>"
				html = html &			"<td class=""sectionHeaderDate"">Due</td>"
				html = html &		"</tr>"
	
				while not rsKI.eof 
					
					if not isNull(rsKI("startDate")) then 
						startDate = formatDateTime(rsKI("startDate"),2) 
					else 
						startDate = ""
					end if
				
					if not isNull(rsKI("endDate")) then 
						endDate = formatDateTime(rsKI("endDate"),2) 
					else 
						endDate = ""
					end if
				
					html = html &		"<tr>"
					html = html &			"<td class=""sectionDetailRowHeader"">" & htmlEncode(rsKI("name")) & "</td>"
					html = html &			"<td class=""sectionDetailDate"">" & startDate & "</td>"
					html = html &			"<td class=""sectionDetailDate"">" & endDate & "</td>"
					html = html &		"</tr>"
					
					rsKi.movenext 
					
				wend 
				
				rsKI.close 
				set rsKI = nothing 
				
				html = html &	"</table>"
				html = html &	"<br>"
				
			end if
		
				
			'*****************************************************************************************
			'* Projects...
			'*****************************************************************************************
	
			dbug("get projects for email...")
	
' 			projSQL = "select name, startDate, endDate from projects where completeDate is null and customerID = " & customerID & " order by endDate " 
			projSQL = "select id, name, startDate, endDate from projects where customerID = " & customerID & " order by endDate " 
			
			set rsProj = dataconn.execute(projSQL)
			
			if not rsProj.eof then 		
			
				html = html & "<table>"
				html = html &		"<tr>"
				html = html &			"<td class=""sectionHeaderRowHeader"">Projects</td>"
				html = html &			"<td class=""sectionHeaderDate"">Start</td>"
				html = html &			"<td class=""sectionHeaderDate"">Due</td>"
				html = html &		"</tr>"
				
				while not rsProj.eof 
				
					SQL = "select type " &_
							"from projectStatus " &_
							"where updatedDateTime = ( " &_
								"select max(updatedDateTime) " &_
								"from projectStatus " &_
								"where projectID = " & rsProj("id") & " " &_
							") "
					
					dbug("projectStatus: " & SQL) 
					
					set rsPS = dataconn.execute(SQL) 
					
					if not rsPS.eof then 
						if rsPS("type") <> "Complete" then 
							includeProject = true 
						else 
							includeProject = false
						end if 
					else 
						includeProject = true 
					end if 
					
					
					if includeProject then 
				
						if not isNull(rsProj("startDate")) then 
							startDate = formatDatetime(rsProj("startDate"),2) 
						else 
							startDate = ""
						end if
						
						if not isNull(rsProj("endDate")) then 
							endDate = formatDatetime(rsProj("endDate"),2) 
						else 
							endDate = ""
						end if
									
						html = html &		"<tr>"
						html = html &			"<td class=""sectionDetailRowHeader"">" & htmlEncode(rsProj("name")) & "</td>"
						html = html &			"<td class=""sectionDetailDate"">" & startDate & "</td>"
						html = html &			"<td class=""sectionDetailDate"">" & endDate & "</td>"
						html = html &		"</tr>"

					end if 
					
					rsPS.close 
					set rsPS = nothing 
					
					rsProj.movenext 
					
				wend 
				
				rsProj.close 
				set rsProj = nothing 
				
				html = html &	"</table>"
				html = html &	"<br>"
								
			end if
			
					
			
			'*****************************************************************************************
			'* Tasks...
			'*****************************************************************************************
	
			dbug("get tasks for email...")
	
			taskSQL = 	"select " &_
								"t.id, " &_
								"t.name, " &_
								"t.startDate, " &_
								"t.dueDate, " &_
								"t.ownerID, " &_
								"concat(c.firstName, ' ', c.lastName) as ownerName, " &_
								"p.name as projectName " &_
							"from tasks t " &_
							"left join customerContacts c on (c.id = t.ownerID) " &_
							"left join projects p on (p.id = t.projectID) " &_
							"where t.completionDate is null " &_
							"and t.ownerID is not null " &_ 
							"and t.customerID = " & customerID & " " &_
							"order by t.dueDate " 
			
			set rsTask = dataconn.execute(taskSQL)
			
			if not rsTask.eof then 		
			
				html = html &	"<table>"
				html = html &		"<tr>"
				html = html &			"<td class=""sectionHeaderRowHeader"">Tasks</td>"
				html = html &			"<td class=""sectionHeaderDate"">Start</td>"
				html = html &			"<td class=""sectionHeaderDate"">Due</td>"
				html = html &			"<td class=""sectionHeader-center"">Owner</td>"
				html = html &			"<td class=""sectionHeader-center"">Work-Days<br>Behind</td>"
				html = html &			"<td class=""sectionHeader-left"">Project</td>"
				html = html &		"</tr>"
				
				while not rsTask.eof 
				
					if not isNull(rsTask("startDate")) then 
						startDate = formatDateTime(rsTask("startDate"),2)
					else 
						startDate = ""
					end if
				
					if not isNull(rsTask("dueDate")) then 
						dueDate = formatDateTime(rsTask("dueDate"),2)
					else 
						dueDate = ""
					end if
					
' 					daysBehind = workDaysBetween(startDate, date())
					daysBehind = taskDaysBehind(rsTask("id"))
				
					html = html &	"<tr>"
					html = html &		"<td class=""sectionDetailRowHeader"">" & htmlEncode(rsTask("name")) & "</td>"
					html = html &		"<td class=""sectionDetailDate"">" & startDate & "</td>"
					html = html &		"<td class=""sectionDetailDate"">" & dueDate & "</td>"
					html = html &		"<td class=""sectionDetail-center"">" & rsTask("ownerName") & "</td>"
					html = html &		"<td class=""sectionDetail-center"">" & daysBehind & "</td>"
					html = html &		"<td class=""sectionDetail-left"">" & htmlEncode(rsTask("projectName")) & "</td>"
					html = html &	"</tr>"
					
					rsTask.movenext 
					
				wend 
				
				rsTask.close 
				set rsTask = nothing 
				
				html = html &	"</table>"
				html = html & "<br>"
				
			end if
			
			rsCC.close 
			set rsCC = nothing
			
			html = html & "<br>"
			html = html & "<br>"

		end if
		
		
		if recap  then 
			
			dbug("handling as a recap (getting notes)...")
			
			' GET AGENDA HEADERS AND NOTES
				SQL = "select " &_
							"cn.name, " &_
							"narrativeHTML " &_
						"from customerCallNotes cn " &_
						"join noteTypes nt on (nt.id = cn.noteTypeID) " &_
						"where cn.customerCallID = " & id & " " &_
						"and nt.includeWithEmails = 1 " &_
						"order by cn.seq " 
						
				dbug("recap items: " & SQL)
				
				set rsRecap = dataconn.execute(SQL)
				
				while not rsRecap.eof 
				
					if not isNull(rsRecap("narrativeHTML")) then 
												
						dbug("about to call unicode2html() for " & rsRecap("name") & "...")
						
						
						dbug("rsRecap('narrativeHTML') prior to unicode2html: " & rsRecap("narrativeHTML") )
						narrative = unicode2html(rsRecap("narrativeHTML"))
						dbug("narrative after unicode2html: " & narrative )

														
					else 

						narrative = ""

					end if
									
					html = html &	"<table style=""border: solid black 1px; width: " & maxEmailWidth & """>"
					html = html &		"<tr>"
					html = html &			"<td class=""sectionHeaderRowHeader"">" & htmlEncode(rsRecap("name")) & "</td>"
					html = html &		"</tr>"
					html = html &		"<tr><td class=""sectionBody"">"
					html = html & 			"<div class=""ql-editor"" data-gramm=""false"" contenteditable=""false"">"
					html = html & 				narrative 
					html = html & 			"</div>"
					html = html &		"</td></tr>"
					html = html & 	"</table><br><br>"
				
					rsRecap.movenext 
								
				wend 
				
				rsRecap.close 
				set rsRecap = nothing 
				
			
		end if 
		
		
		dbug("HTML complete for for email, preparing to send...")
		

		html = html & "</div><p style=""text-align: center;"">##</p></body>"
		html = html & "</html>"


		objmail.HTMLbody	= html


		if systemControls("Send system generated email") = "true" then 

			on error resume next 
	
				objmail.send
				
				if err = 0 then 
						
					success = 1
					dbug("CDO send successful")
				else 
					success = 0
					dbug("CDO Send failed, err.number: " & err.number & ", err.description: " & err.description)
				end if
	
			on error goto 0
		
		else 
		
			dbug("email prepared but not sent because 'Send system generated email' is off")
				
		end if 
		
		set objmail = Nothing


		dbug("preparing to log email...")
		
		' Now insert the components of the email into customerCallEmailLog table...
		
		newID = getNextID("customerCallEmailLog")
		if len(request.querystring("to")) > 0 then 
			logFrom = "'" & request.querystring("to") & "'"
		else 
			logFrom = "NULL"
		end if 
		
		if len(request.querystring("to")) > 0 then 
			logTo = "'" & request.querystring("to") & "'"
		else 
			logTo = "NULL"
		end if 
		
		if len(request.querystring("cc")) > 0 then 
			logCc = "'" & request.querystring("cc") & "'"
		else 
			logCc = "NULL"
		end if 
		
		if len(request.querystring("subject")) > 0 then 
			logSubject = "'" & request.querystring("subject") & "'"
		else 
			logSubject = "NULL"
		end if 
		
		if len(request.querystring("body")) > 0 then 
			logBody = "'" & request.querystring("body") & "'"
		else 
			logBody = "NULL"
		end if 
		
' 		logHTML = replace(html,"--","&#45;&#45;")			' em-dash
' 		logHTML = replace(logHTML, chr(39), "&#39;")		' apostrophe
' 		logHTML = replace(logHTML, chr(34), "&#34;")		' double-quote
' 		logHTML = replace(logHTML, "&", "&#38;")			' ampersand	

' 		dbug("logHTML: " & html)
		logHTML = "'" & replace(html, chr(39), "&#39;") & "'" 
		
		dbug("logHTML ready, preparing to insert into DB...")
		
		
		insertSQL = "insert into customercallEmailLog (id, addedDateTime, addedBy, subject, toList, ccList, body, html, callID) " &_
						"values ( " &_
							newID & ", " &_
							"CURRENT_TIMESTAMP, " &_
							session("userID") & ", " &_
							logSubject & ", " &_
							logTo & ", " &_
							logCc & ", " &_
							logBody & ", " &_
							logHTML & ", " &_
							id & ") "
							
		dbug(insertSQL)
		
		set rsInsert = dataconn.execute(insertSQL)
		set rsInsert = nothing 
		
		
							
				
		
		msg = "Call agenda sent"
		
		xml = xml & "<callID>" & id & "</callID>"
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<from>" & session("userName") & "</from>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</sendCall>"

		dbug("===================================================================================")
		dbug("END OF sendCall")
		dbug("===================================================================================")
		dbug(" ")


	'===================================================================================
	case "updateCallLead"
	'===================================================================================
	
		xml = xml & "<updateCallLead>"
		
		id				= request.querystring("id")
		callLead 	= request.querystring("callLead")		
		
		SQL = "update customerCalls set callLead = " & callLead & " where id = " & id & " " 
		
		dbug(SQL)
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = "Call lead updated"
		
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</updateCallLead>"
	
	
	'===================================================================================
	case "updateTimezone"
	'===================================================================================
	
		xml = xml & "<updateTimezone>"
		
		customerCallID = request.querystring("customerCallID")
		attributeName	= request.querystring("name")
		attributeValue	= request.querystring("value")
		
		if attributeName = "actualTimezone" then
			if len(attributeValue) <= 0 then 
				attributeValue = "NULL"
			end if 
		end if
		
		SQL = "update customerCalls set " & attributeName & " = " & attributeValue & " where id = " & customercallID & " "
		
		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing
	
		msg = attributeName & " updated"
		
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</updateTimezone>"


	'===================================================================================
	case "getNoteTypes"
	'===================================================================================
	
		xml = xml & "<getNoteTypes>"
		
		callTypeID = request("callTypeID")
		
		SQL = "select utopiaInd from noteTypes where callTypeID = " & callTypeID & " and utopiaInd = 1 " 
		dbug("utopia SQL:" & SQL)
		set rsNT = dataconn.execute(SQL)
		if not rsNT.eof then 
			utopiaInd = "true" 
		else 
			utopiaInd = "false"
		end if 
		
		SQL = "select projectInd from noteTypes where callTypeID = " & callTypeID & " and projectInd = 1 " 
		dbug("project SQL:" & SQL)
		set rsNT = dataconn.execute(SQL)
		if not rsNT.eof then 
			projectInd = "true" 
		else 
			projectInd = "false" 
		end if 
		
		SQL = "select keyInitiativeInd from noteTypes where callTypeID = " & callTypeID & " and keyInitiativeInd = 1 " 
		dbug("KI SQL:" & SQL)
		set rsNT = dataconn.execute(SQL)
		if not rsNT.eof then 
			keyInitiativeInd = "true" 
		else 
			keyInitiativeInd = "false" 
		end if 
		
		rsNT.close 
		set rsNT = nothing 
		
		xml = xml & "<utopiaInd>" & utopiaInd & "</utopiaInd>"
		xml = xml & "<projectInd>" & projectInd & "</projectInd>"
		xml = xml & "<keyInitiativeInd>" & keyInitiativeInd & "</keyInitiativeInd>"
		xml = xml & "<msg>noteTypes successfully queried</msg>"

		xml = xml & "</getNoteTypes>"
	 

	'===================================================================================
	case "toggleIncludeWithEmails"
	'===================================================================================	
	
		xml = xml & "<toggleIncludeWithEmails>"

		noteTypeID = request.querystring("noteTypeID")
		
		SQL = "select includeWithEmails from noteTypes where id = " & noteTypeID & " " 
		dbug(SQL)
		set rsNT = dataconn.execute(SQL) 
		if not rsNT.eof then 
			if rsNT("includeWithEmails") then 
				toggleValue = 0
			else 
				toggleValue = 1
			end if
			SQL = "update noteTypes set includeWithEmails = " & toggleValue & " where id = " & noteTypeID & " " 
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing 
			msg = "Email indicator udpated" 
		else 
			msg = "Note type not found" 
		end if
		rsNT.close 
		set rsNT = nothing 
		
		xml = xml & "<toggleValue>" & toggleValue & "</toggleValue>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</toggleIncludeWithEmails>"



	'===================================================================================
	case "getCallNoteHistory"
	'===================================================================================
	
		xml = xml & "<getCallNoteHistory>"

		customerCallID = request.querystring("customerCallID")
		callNoteTypeID = request.querystring("callNoteTypeID")
		
		SQL = "select name from noteTypes where id = " & callNoteTypeID & " " 
		
		set rsNT = dataconn.execute(SQL) 
		if not rsNT.eof then
			noteTypeName = rsNT("name") 
		else 
			noteTypeName = "Not found"
		end if 
		rsNT.close 
		set rsNT = nothing 
		
		xml = xml & "<noteTypeName>" & noteTypeName & "</noteTypeName>"



		xml = xml & "<callNoteHistory>"
		
		SQL = "select " &_
					"'current' as type, " &_
					"ccn.id, " &_
					"ccn.updatedBy, " &_
					"ccn.updatedDateTime, " &_
					"concat(u.firstName, ' ', u.lastName) as userFullName " &_
				"from customerCallNotes ccn " &_
				"left join csuite..users u on (u.id = ccn.updatedBy) " &_
				"where customerCallID = " & customerCallID & " " &_
				"and noteTypeID = " & callNoteTypeID & " " &_
				"union all " &_
				"select " &_
					"'historical' as type, " &_
					"ccnh.id, " &_
					"ccnh.updatedBy, " &_
					"ccnh.updatedDateTime, " &_
					"concat(u.firstName, ' ', u.lastName) as userFullName " &_
				"from customerCallNotes_history ccnh " &_
				"left join csuite..users u on (u.id = ccnh.updatedBy) " &_
				"where customerCallID = " & customerCallID & " " &_
				"and noteTypeID = " & callNoteTypeID & " " &_
				"order by updatedDateTime desc "
				
		dbug(SQL) 
		set rsCNH = dataconn.execute(SQL) 

		while not rsCNH.eof 

			xml = xml & "<customerCallNote id=""" & rsCNH("id") & """>"
			xml = xml & "<type>" & rsCNH("type") & "</type>" 
			xml = xml & "<updatedBy>" & rsCNH("updatedBy") & "</updatedBy>"
			xml = xml & "<userFullName>" & rsCNH("userFullName") & "</userFullName>"
			xml = xml & "<updatedDateTime>" & rsCNH("updatedDateTime") & "</updatedDateTime>"
' 			xml = xml & "<narrative><![CDATA[" & rsCNH("narrative") & "]]></narrative>"
' 			xml = xml & "<narrativeHTML><![CDATA[" & rsCNH("narrativeHTML") & "]]></narrativeHTML>"
			xml = xml & "</customerCallNote>"

			rsCNH.movenext 

		wend 			

		rsCNH.close 
		set rsCNH = nothing 

		msg = "customer call note history retrieved successfully"
		xml = xml & "<msg>" & msg & "</msg>"
		
		xml = xml & "</callNoteHistory>"
		xml = xml & "</getCallNoteHistory>"


	'===================================================================================
	case "getHistoricalNote" 
	'===================================================================================

		xml = xml & "<getHistoricalNote>"

		customerCallID 	= request.querystring("customerCallID") 
		callNoteTypeID 	= request.querystring("callNoteTypeID")
		updatedBy 			= request.querystring("updatedBy")
		updatedDateTime 	= request.querystring("updatedDateTime")
		
		SQL = "select narrative " &_
				"from customerCallNotes " &_
				"where customerCallID = " & customerCallID & " " &_
				"and noteTypeID = " & callNoteTypeID & " " &_
				"and updatedBy = " & updatedBy & " " &_
				"and updatedDateTime = convert(datetime2, '" & updatedDateTime & "') " 
				
		dbug("SQL1: " & SQL) 
				 
		set rsCCN1 = dataconn.execute(SQL)
		if not rsCCN1.eof then 
			
			xml = xml & "<historyType>current</historyType>"
			xml = xml & "<narrative><![CDATA[" & rsCCN1("narrative") & "]]></narrative>"
' 			xml = xml & "<narrativeHTML><![CDATA[" & rsCCN1("narrativeHTML") & "]]></narrativeHTML>"
			
			msg = "Current record found"
			
		else 
			
			SQL = "select narrative " &_
					"from customerCallNotes_history " &_
					"where customerCallID = " & customerCallID & " " &_
					"and noteTypeID = " & callNoteTypeID & " " &_
					"and updatedBy = " & updatedBy & " " &_
					"and updatedDateTime = convert(datetime2, '" & updatedDateTime & "') " 
					
			dbug("SQL2: " & SQL)
			
			set rsCCN2 = dataconn.execute(SQL)
			if not rsCCN2.eof then 
				
				xml = xml & "<historyType>history</historyType>"
				xml = xml & "<narrative><![CDATA[" & rsCCN2("narrative") & "]]></narrative>"
' 				xml = xml & "<narrativeHTML><![CDATA[" & rsCCN2("narrativeHTML") & "]]></narrativeHTML>"
				
				msg = "Historical record found"
	
			else 
				
				msg = "Historical record not found"
								
			end if 
			
			rsCCN2.close 
			set rsCCN2 = nothing 
			
		end if 
		
		rsCCN1.close 
		set rsCCN1 = nothing 
			
		xml = xml & "<msg>" & msg & "</msg>"
		xml = xml & "</getHistoricalNote>"

	
	'===================================================================================
	case "makeThisNoteCurrent"
	'===================================================================================

		xml = xml & "<makeThisNoteCurrent>"

		customerCallID 	= request.querystring("customerCallID") 
		callNoteTypeID 	= request.querystring("callNoteTypeID")
		updatedBy 			= request.querystring("updatedBy")
		updatedDateTime 	= request.querystring("updatedDateTime")
		
		
		SQL = "select narrative, narrativeHTML " &_
				"from customerCallNotes_history " &_
				"where customerCallID = " & customerCallID & " " &_
				"and noteTypeID = " & callNoteTypeID & " " &_
				"and updatedBy = " & updatedBy & " " &_
				"and updatedDateTime = convert(datetime2, '" & updatedDateTime & "') "  
				
		dbug(SQL)
		
		set rsH = dataconn.execute(SQL) 
		if not rsH.eof then 
			
			if isNull(rsH("narrative")) then 
				newNarrative = "null" 
			else 
				newNarrative = "'" & replace(rsH("narrative"),"'", "''") & "'" 
			end if 
			
			if isNull(rsH("narrativeHTML")) then 
				newNarrativeHTML = "null"
			else 
				newNarrativeHTML = "'" & replace(utopiaName, chr(39), "&#39;") & "'" 
			end if 

			SQL = "update customercallNotes set " &_
						"narrative = " & newNarrative & ", " &_
						"narrativeHTML = " & newNarrativeHTML & ", " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = current_timestamp " &_
					"where customerCallID = " & customerCallID & " " &_
					"and noteTypeID = " & callNoteTypeID & " " 
					
			dbug(SQL)
					
			set rsReplace = dataconn.execute(SQL) 
			set rsReplace = nothing 
			
			msg = "Narrative replaced" 
			
		else 
			
			msg = "Source narrative not found"

		end if 
		
		rsH.close 
		set rsH = nothing 
		
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</makeThisNoteCurrent>"
		
		
	
	'===================================================================================
	case else 
	'===================================================================================

		dbug("directive not found: " & request.querystring("cmd"))	
	
		xml = xml & "<msg>No such directive</msg>"

	
end select 

userLog(msg)

dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</customerCalls>"
dbug(xml)
response.write(xml)

%>