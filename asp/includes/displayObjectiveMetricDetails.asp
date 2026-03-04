<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

dbug("displayObjectiveMetricDetails.asp...")

if not isNull(rsObj("metricID")) then 
	
	dbug("metricID: " & rsObj("metricID"))

	SQL = "select * from metric where id = " & rsObj("metricID") & " " 
	dbug(SQL)
	set rsMetric = dataconn.execute(SQL)
	if not rsMetric.eof then 
		dbug("metric found...")
		internalMetricInd 				= rsMetric("internalMetricInd")
		ranksColumnName 					= rsMetric("ranksColumnName")
		statsColumnName 					= rsMetric("statsColumnName")
		financialCtgy 						= rsMetric("financialCtgy")
		if len(rsMetric("ubprLine")) > 0 then 
			delimiterPos						= inStr(rsMetric("ubprLine"), ".")
			ubprLine 							= mid(rsMetric("ubprLine"), 1, delimiterPos-1)
			ubprCol 								= mid(rsMetric("ubprLine"), delimiterPos+1)
			dbug("delimiterPos: " & delimiterPos)
			dbug("ubprLine: " & ubprLine)
			dbug("ubprCol: " & ubprCol)
		else 
			ubprLine							= ""
			obprCol							= ""
		end if
		metricName							= rsMetric("name")
		ubprSection							= rsMetric("ubprSection")
		ubprLine								= rsMetric("ubprLine")
		correspondingAnnualChangeID	= rsMetric("correspondingAnnualChangeID")
		if internalMetricInd then 
			if rsObj("type") = "A" then 
				metricTypeDesc = "Internal - Standard"
			elseif rsObj("type") = "B" then
				metricTypeDesc = "Internal - Customer Specific"
			else 
				metricTypeDesc = "Unknown"
			end if
		else 
			metricTypeDesc = "FDIC"
		end if
	else 
		dbug("metric not found...")
		internalMetricInd 				= "Not Found"
		ranksColumnName 					= "Not Found"
		statsColumnName 					= "Not Found"
		financialCtgy 						= "Not Found"
		delimiterPos						= "Not Found"
		ubprLine 							= "Not Found"
		ubprCol 								= "Not Found"
		metricName							= "Not Found"
		metricNameCustom					= "Not Found"
		ubprSection							= "Not Found"
		ubprLine								= "Not Found"
		correspondingAnnualChangeID	= "Not Found"
		metricTypeDesc						= "Not Found"
	end if
else 
	dbug("rsObj('metricID') is nul...")
	' use info from the customerObjective table...
	internalMetricInd 				= 1
	ranksColumnName 					= "Unknown"
	statsColumnName 					= "Unknown" 
	delimiterPos						= "Unknown"
	ubprLine 							= "Unknown"
	ubprCol 								= "Unknown"
	metricName							= "Unknown"
	financialCtgy						= "Unknown" 
	ubprSection							= "Unknown" 
	ubprLine								= "Unknown" 
	correspondingAnnualChangeID	= "Unknown" 
	metricTypeDesc						= "Unknown"
	
end if 

dbug("internalMetricInd: " & internalMetricInd)
if internalMetricInd then 

	dbug("internalMetricInd is true...")

	graphType = "C" 
	
else 

	dbug("internalMetricInd is NOT true...")
	
	if isNull(ranksColumnName) AND isNull(statsColumnName) then 
		
		dbug("ranksColumnName and statsColumnName are both null...")
		
		graphType = "A"
		
									
		if ubprCol = "1" then 
			
			dbug("ubprCol is 1...")
		
			SQL = "select ratiosColumnName, sourceTableNameRoot from metric where ubprLine = '" & ubprLine & ".3' " 
			dbug(SQL)
			set rsComp = dataconn.execute(SQL) 
			if not rsComp.eof then 
				graphSeriesCount = 2
			else 
				graphSeriesCount = 1
			end if 
			rsComp.close 
			set rsComp = nothing 
		end if 
	else 
		
		dbug("ranksColumnName or statsColumnName is NOT null...")
		
		graphType = "B"
		
	end if

end if

dbug("proceeding to build HTML <table>...")
%>
	
<table style="width: 100%">
 
	<tr>
		<td style="font-weight: bold; vertical-align: top; text-align: left; border-bottom: solid lightgray 1px; padding-bottom: 10px; padding-top: 10px; width: 120px;">Narrative:</td>
		<td id="narrative-<% =rsObj("id") %>" style="vertical-align: middle; text-align: left; border-bottom: solid lightgray 1px; padding-bottom: 10px; padding-top: 10px;"><% =rsObj("narrative") %></td>
	</tr>


	<tr>
		<td style="width: 120px;"><b>Metric:</b></td>
		<td id="metricName-<% =rsObj("id") %>"><% =metricName %></td>
	</tr>
	
	<tr>
		<td><b>Type:</b></td>
		<td id="metricType-<% =rsObj("id") %>">
<!-- 		<input id="metricTypeID-<% =rsObj("id") %>" value="<% ' =rsObj("type") %>"> -->
			<% =metricTypeDesc %>
		</td>
	</tr>

	<% if NOT internalMetricInd then %>
		<tr>
			<td><b>Category:</b></td>
			<td id="category-<% =rsObj("id") %>"><% = financialCtgy %></td>
		</tr>

		<tr>
			<td nowrap><b>UBPR Section:</b></td>
			<td id="section-<% =rsObj("id") %>"><% =ubprSection %></td>
		</tr>

		<tr>
			<td nowrap><b>UBPR Line:</b></td>
			<td><% =ubprLine %></td>
		</tr>

	<% end if %>


	<% if graphType = "B" then %>
		<tr>
			<td><b>Peer Group Type:</b></td>
			<td id="peerGroupType-<% =rsObj("id") %>">
				<% =rsObj("description") %>
			</td>
		</tr>
	<% end if %>
	
</table>


<input type="hidden" id="showAnnualChangeEligible-<% =rsObj("id") %>" value="<% =correspondingAnnualChangeID %>">
<input type="hidden" id="showAnnualChangeInd-<% =rsObj("id") %>" value="<% =rsObj("showAnnualChangeInd") %>">
<input type="hidden" id="peerGroupTypeID-<% =rsObj("id") %>" value="<% =rsObj("peerGroupTypeID") %>">
<input type="hidden" id="displayUnitsLabel-<% =rsObj("id") %>" value="<% =lCase(rsObj("displayUnitsLabel")) %>">
<input type="hidden" id="dataType-<% =rsObj("id") %>" value="<% =lCase(rsObj("dataType")) %>">
<input type="hidden" id="metricID-<% =rsObj("id") %>" value="<% =rsObj("metricID") %>">

<%
dbug("HTML <table> complete and type='hidden' fields populated")
dbug("end of displayObjectiveMetricDetails.asp")
%>
