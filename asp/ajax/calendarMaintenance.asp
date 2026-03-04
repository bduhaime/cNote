<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/usersWithPermission.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<calendarMaintenance>"

msg = ""

select case request.querystring("cmd")

	case "query"
	
		xml = xml & "<query>"
	
		userLog("calendar query")
		SQL = "select * from dateDimension where id = '" & request.querystring("id") & "' "

' 		dbug(SQL)
		set rsDD = dataconn.execute(SQL)
		
		if not rsDD.eof then 
			dbug("not rsDD.eof")
			xml = xml & "<dateID>" & rsDD("id") & "</dateID>"
			xml = xml & "<yearNo>" & rsDD("yearNo") & "</yearNo>"
			xml = xml & "<quarterNo>" & rsDD("quarterNo") & "</quarterNo>"
			xml = xml & "<monthNo>" & rsDD("monthNo") & "</monthNo>"
			xml = xml & "<monthName>" & rsDD("monthName") & "</monthName>"
			xml = xml & "<weekNo>" & rsDD("weekNo") & "</weekNo>"
			xml = xml & "<dayOfMonth>" & rsDD("dayOfMonth") & "</dayOfMonth>"
			xml = xml & "<dayOfWeekNo>" & rsDD("dayOfWeekNo") & "</dayOfWeekNo>"
			xml = xml & "<dayOfWeekName>" & rsDD("dayOfWeekName") & "</dayOfWeekName>"
			xml = xml & "<dayNo>" & rsDD("dayNo") & "</dayNo>"
			xml = xml & "<fiscalYearNo>" & rsDD("fiscalYearNo") & "</fiscalYearNo>"
			xml = xml & "<fiscalQuarterNo>" & rsDD("fiscalQuarterNo") & "</fiscalQuarterNo>"
			xml = xml & "<fiscalMonthNo>" & rsDD("fiscalMonthNo") & "</fiscalMonthNo>"
			xml = xml & "<fiscalMonthName>" & rsDD("fiscalMonthName") & "</fiscalMonthName>"
			xml = xml & "<fiscalWeekNo>" & rsDD("fiscalWeekNo") & "</fiscalWeekNo>"
			xml = xml & "<fiscalDayOfMonth>" & rsDD("fiscalDayOfMonth") & "</fiscalDayOfMonth>"
			xml = xml & "<fiscalDayNo>" & rsDD("fiscalDayNo") & "</fiscalDayNo>"
			xml = xml & "<seasonName>" & rsDD("seasonName") & "</seasonName>"
			xml = xml & "<weekdayInd>" & rsDD("weekdayInd") & "</weekdayInd>"
			xml = xml & "<usaHolidayInd>" & rsDD("usaHolidayInd") & "</usaHolidayInd>"
			xml = xml & "<canHolidayInd>" & rsDD("canHolidayInd") & "</canHolidayInd>"
			xml = xml & "<usaHolidayName>" & rsDD("usaHolidayName") & "</usaHolidayName>"
			xml = xml & "<canHolidayName>" & rsDD("canHolidayName") & "</canHolidayName>"
		
			msg = "Date Found"
		
		else 
			
' 			dbug("rsDD.eof")
			msg = "Date Not Found"
		
		end if
		
		rsDD.close 
		set rsDD = nothing 
			
		xml = xml & "</query>"

	case "holidays"
	
		xml = xml & "<holidays>"
	
' 		dbug("holidays detected")
		SQL = "select id, usaHolidayName from dateDimension where yearNo = " & request.querystring("year") & " and usaHolidayInd = 1 " 
' 		dbug(SQL)
		set rsHolidays = dataconn.execute(SQL)
		while not rsHolidays.eof 
			xml = xml & "<holiday id=""" & rsHolidays("id") & """>" & rsHolidays("usaHolidayName") & "</holiday>"
			rsHolidays.movenext 
		wend 
		rsHolidays.close 
		set rsHolidays = nothing 
		
		xml = xml & "</holidays>"
			

	case else 

		xml = xml & "<unknown>"

' 		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"

		xml = xml & "</unknown>"

end select 

dataconn.close
set dataconn = nothing


xml = xml & "<msg>" & msg & "</msg>"

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</calendarMaintenance>"

response.write(xml)
%>