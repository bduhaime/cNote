<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

'***** USER MAINTENANCE *****
response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<metricMaintenance>"

msg = ""

'***********************************************************
sub toggleIndicator(metric, indicator)
'***********************************************************

	SQL = "update metric set " & indicator & " = case when " & indicator & " = 1 then 0 else 1 end where id = " & metric & " "
	set rs = dataconn.execute(SQL)
	
	SQL = "select " & indicator & " as updatedValue from metric where id = " & metric & " "
	dbug("toggleIndicator, secondary SQL: " & SQL)
	set rs = dataconn.execute(SQL)
	if not rs.eof then 
		updatedValue = rs("updatedValue")
	else
		updatedValue = "not found"
	end if
	dbug("updatedValue: " & updatedValue)

	rs.close
	set rs = nothing
	
	
	xml = xml & "<metric id=""" & metric & """><" & indicator & ">" & updatedValue & "</" & indicator & "></metric>"
	xml = xml & "<msg>" & indicator & " indicator updated</msg>"
	xml = xml & "<status>success</status>"

	dbug("xml: " & xml)
end sub


'***********************************************************
sub updateAttribute(id, attribute, value)
'***********************************************************

	select case attribute
		case "name", "metricName"
			textDelimitter = "'"
			attributeName = "name"
		case else
			textDelimitter = ""
			attributeName = attribute
	end select
	dbug("textDelimitter: [" & textDelimitter & "]")

	SQL = "update metric set " & attributeName & " = " & textDelimitter & value & textDelimitter & " where id = " & id & " "
	dbug(SQL)
	set rs = dataconn.execute(SQL)
	set rs = nothing
	 
	xml = xml & "<metric id=""" & id & """><" & attribute & ">" & value & "</" & attribute & "></metric>"
	xml = xml & "<msg>" & attributeName & " updated</msg>"
	xml = xml & "<status>success</status>"

	dbug("xml: " & xml)


end sub
'***********************************************************
'***********************************************************
'***********************************************************
'***********************************************************

dbug("about to evaluate cmd=" & request.querystring("cmd"))
select case request.querystring("cmd")
	case "delete"
		dbug("delete...")
		call toggleIndicator(request.querystring("metric"),"deleted")
	case "active"
		dbug("active...")
		call toggleIndicator(request.querystring("metric"),"active")
	case "update"
		dbug("update")
		call updateAttribute(request.querystring("id"),request.querystring("attribute"),request.querystring("value"))
		
	case "adminUpdateMetric" 
		xml = xml & "<adminUpdateMetric>"

		metricID					= request.querystring("metricID")
		metricName				= request.querystring("metricName")
		ubprSection				= request.querystring("ubprSection")
		ubprLine					= request.querystring("ubprLine")
		financialCtgy			= request.querystring("financialCtgy")
		ranksColumnName		= request.querystring("ranksColumnName")
		ratiosColumnName		= request.querystring("ratiosColumnName")
		statsColumnName		= request.querystring("statsColumnName")
		sourceTableNameRoot	= request.querystring("sourceTableNameRoot")
		dataType					= request.querystring("dataType")
		displayUnitsLabel		= request.querystring("displayUnitsLabel")

		if len(request.querystring("annualChangeColumn")) > 0 then 
			annualChangeColumn = "'" & request.querystring("annualChangeColumn") & "'" 
		else 
			annualChangeColumn = "NULL"
		end if 
		
		if len(metricID) > 0 then 
			
			SQL = "update metric set " &_
						"name = '" 									& metricName 				& "', " &_
						"updatedDateTime = "						& "CURRENT_TIMESTAMP"	& ", "  &_
						"updatedBy = " 							& session("userID") 		& ", "  &_
						"ubprSection = '" 						& ubprSection 				& "', " &_
						"ubprLine = '" 							& ubprLine 					& "', " &_
						"financialCtgy = '" 						& financialCtgy 			& "', " &_
						"ranksColumnName = '" 					& ranksColumnName 		& "', " &_
						"ratiosColumnName = '" 					& ratiosColumnName 		& "', " &_
						"statsColumnName 	= '" 					& statsColumnName 		& "', " &_
						"sourceTableNameRoot = '" 				& sourceTableNameRoot 	& "', " &_
						"dataType = '" 							& dataType 					& "', " &_
						"displayUnitsLabel = '"  				& displayUnitsLabel 		& "', " &_
						"correspondingAnnualChangeID = " 	& annualChangeColumn 	& " " &_
					"where id = " & metricID & " " 
			
			xml = xml & "<msg>Metric updated</msg>"
			
		else 
			
			newID = getNextID("metric") 
			SQL = "insert into metric (id, name, updatedDateTime, updatedBy, ubprSection, ubprLine, financialCtgy, ranksColumnName, ratiosColumnName, statsColumnName, sourceTableNameRoot, dataType, displauyUnitsLabel, correspondingAnnualChangeID) " &_
					"values ( " &_
						newID & ", " &_
						"'" & metricName 				& "', " &_
						"CURRENT_TIMESTAMP"			& ", "  &_
						session("userID") 			& ", "  &_
						"'" & ubprSection 			& "', " &_
						"'" & ubprLine 				& "', " &_
						"'" & financialCtgy 			& "', " &_
						"'" & ranksColumnName 		& "', " &_
						"'" & ratiosColumnName 		& "', " &_
						"'" & statsColumnName 		& "', " &_
						"'" & sourceTableNameRoot 	& "', " &_
						"'" & dataType 				& "', " &_
						"'" & displayUnitsLable 	& "', " &_
						annualChangeColumn 			& " " &_
					") " 
	
			xml = xml & "<msg>Metric added</msg>"

		end if
		
		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
	
	
		xml = xml & "</adminUpdateMetric>"
	case else 
end select 

dbug("operation complete")

dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</metricMaintenance>"

response.write(xml)
%>