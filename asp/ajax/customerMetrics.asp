<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

response.contentType = "text/xml"
xml = "<?xml version='1.0' encoding='UTF-8'?>"

select case request.querystring("cmd")

	'====================================================================================================================
	case "updateMetricValue"
	'====================================================================================================================

		dbug("updateMetricValue")
		
		xml = xml & "<updateMetricValue>"
		
		if request("id") = "null" then 
			id					= ""
		else 
			id 				= request("id") 
		end if 
		
		metricID			= request("metricID")
		metricDate 		= request("date") 
		metricValue 	= request("value")
		rssdID			= request("rssdid")
		
		if request("objectiveID") = "null" then 
			objectiveID		= ""
		else 
			objectiveID		= request("objectiveID")
		end if 

		if len(id) > 0 then 		
			SQL = "update customerInternalMetrics set " 					&_
						"metricValue 	= " & metricValue 		& ", " 	&_
						"metricDate 	= '" & metricDate 		& "', " 	&_
						"updatedBy 		= " & session("userID") & ", " 	&_
						"updatedDateTime = CURRENT_TIMESTAMP " 			&_
					"where id = " & id & " " 
			msg = "Customer metric updated"
		else 
			SQL = "insert into customerInternalMetrics (rssdID, metricID, metricValue, metricDate, updatedBy, updatedDateTime) " &_
					"values ( " 							&_
						rssdID 					& ", " 	&_
						metricID					& ", " 	&_
						metricValue 			& ", " 	&_
						"'" & metricDate 		& "', "	&_
						session("userID") 	& ", " 	&_
						"CURRENT_TIMESTAMP " 			&_
					") "
			msg = "Customer metric added"
		end if
						
		dbug(SQL) 
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<rssdID>" & rssdID & "</rssdID>"
		xml = xml & "<metricID>" & metricID & "</metricID>"
		xml = xml & "<metricDate>" & formatDateTime(metricDate,2) & "</metricDate>"
		xml = xml & "<metricValue>" & metricValue & "</metricValue>"
		xml = xml & "<objectiveID>" & objectiveID & "</objectiveID>"
		xml = xml & "<msg>" & msg & "</msg>" 
		
		xml = xml & "</updateMetricValue>"
		

	'====================================================================================================================
	case "deleteCustomerInternalMetric" 
	'====================================================================================================================

		dbug("deleteCustomerInternalMetric")
		
		xml = xml & "<deletedInternalMetricValue>"
		
		id = request("id") 
		
		SQL = "delete from customerInternalMetrics where id = " & id & " " 
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>customerInternalMetrics value successfully deleted</msg>"

		xml = xml & "</deletedInternalMetricValue>"


	'====================================================================================================================
	case "getCustomerInternalMetrics"
	'====================================================================================================================

		dbug("getCustomerInternalMetrics")

		xml = xml & "<internalMetricValues>"
		
		rssdID = request("rssdID")
		objectiveID = request("objectiveID")
		metricID		= request("metricID")

		xml = xml & "<objectiveID>" & objectiveID & "</objectiveID>"
		xml = xml & "<metricID>" & metricID & "</metricID>"
		
		SQL = "select * " &_
				"from customerInternalMetrics " &_
				"where rssdID = " & rssdID & " " &_
				"and metricID = (select metricID from customerObjectives where id = " & objectiveID & ") " &_
				"order by metricDate desc "
				
		set rsValues = dataconn.execute(SQL)
		if not rsValues.eof then 
			
			while not rsValues.eof 
	
				xml = xml & "<metricValue>"
	
					xml = xml & "<id>" & rsValues("id") & "</id>"
					xml = xml & "<date>" & formatDateTime(rsValues("metricDate")) & "</date>"
					xml = xml & "<value>" & rsValues("metricValue") & "</value>"
					xml = xml & "<updatedBy>" & rsValues("updatedBy") & "</updatedBy>"
					xml = xml & "<updatedDateTime>" & rsValues("updatedDateTime") & "</updatedDateTime>"
	
				xml = xml & "</metricValue>"
				
				rsValues.movenext 
			
			wend 	
		
		end if 
		
		rsValues.close 
		set rsValues = nothing 


		xml = xml & "</internalMetricValues>"

	'====================================================================================================================
	case "deleteCustomerObjective" 
	'====================================================================================================================
	
		dbug("deleteCustomerObjective")
		
		xml = xml & "<transaction>"
		
		id = request("id")
		
		if len(id) > 0 then 

			xml = xml = "<customerObjectiveID>" & id & "</customerObjectiveID>"
			
			SQL = "delete from customerObjectives where id = " & id & " " 
			
			dbug(SQL)
			
			set rsDelete = dataconn.execute(SQL)
			set rsDelete = nothing 
			
			msg = "Customer objective deleted"
			
		else 
			
			msg = "customerObjectiveID missing; no action taken"
			
		end if 
		
		xml = xml & "<msg>" & msg & "</msg>"
		xml = xml & "</transaction>"
		

	'====================================================================================================================
	case "updateCustomerOpportunity" 
	'====================================================================================================================
	
		dbug("updateCustomerOpportunity....")
		
		xml = xml & "<transaction>"
		
		opportunityID 				= request("opportunityID")
		implementationID			= request("implementationID")
		narrative					= replace(request("narrative"),"'", "''")
		
		if len(request("startDate")) > 0 then 
			if isDate(request("startDate")) then 
				startDate				= "'" & request("startDate") & "'"
			else 
				startDate				= "NULL"
			end if 
		else 
			startDate					= "NULL"
		end if

		if len(request("endDate")) > 0 then 
			if isDate(request("endDate")) then 
				endDate				= "'" & request("endDate") & "'"
			else 
				endDate				= "NULL"
			end if 
		else 
			endDate					= "NULL"
		end if

		if len(request("value")) > 0 then 
			if isNumeric(request("value")) then 
				annualEcomonicValue			= request("value")
			else 
				annualEcomonicValue			= "NULL"		
			end if 
		else 
			annualEcomonicValue			= "NULL"
		end if
		
		if len(opportunityID) > 0 then 
			
			xml = xml & "<opportunityID>" & opportunityID & "</opportunityID>"
			
			SQL = "update customerOpportunities set " &_
						"implementationID = " 				& implementationID 		& ", " 	&_
						"narrative = '" 						& narrative			 		& "', " 	&_
						"startDate = " 						& startDate			 		& ", " 	&_
						"endDate = " 							& endDate			 		& ", " 	&_
						"annualEconomicValue = " 			& annualEcomonicValue	& ", "	&_
						"updatedBy = " 						& session("userID") 		& ", "	&_
						"updatedDateTime = CURRENT_TIMESTAMP " 									&_
					"where id = " & opportunityID 		& " " 
					
			msg = "Customer opportunity updated"
						
			
		else 
			
			opportunityID = getNextID("customerOpportunities") 
			
			xml = xml & "<opportunityID>" & opportunityID & "</opportunityID>"

			SQL = "insert into customerOpportunities (id, implementationID, narrative, startDate, endDate, annualEconomicValue, updatedBy, updatedDateTime) " &_
					"values ( " &_
						opportunityID & ", " &_
						implementationID & ", " &_
						"'" & narrative & "', " &_
						startDate & ", " &_
						endDate & ", " &_
						annualEcomonicValue & ", " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP ) "
						
			msg = "Customer objective added"
						
			
		end if

		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<opportunityID>" & opportunityID & "</opportunityID>"
		xml = xml & "<narrative>" & narrative & "</narrative>"
		xml = xml & "<startDate>" & startDate & "</startDate>"
		xml = xml & "<endDate>" & endDate & "</endDate>"
		xml = xml & "<annualEconomicValue>" & annualEcomonicValue & "</annualEconomicValue>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</transaction>"
						
		
		
	
	'====================================================================================================================
	case "deleteCustomerOpportunity" 
	'====================================================================================================================
	
		dbug("deleteCustomerOpportunity...")
						
						
		xml = xml & "<transaction>"
		
		opportunityID = request("id")
		
		SQL = "delete from customerOpportunities where id = " & opportunityID & " " 

		dbug(SQL)
		
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 
		
		SQL = "delete from customerObjectives where opportunityID = " & opportunityID & " " 
		
		dbug(SQL)
		
		set rsDelete = dataconn.execute(SQL) 
		set rsDelete = nothing 
		
		xml = xml & "<opportunityID>" & opportunityID & "</opportunity>" 
		xml = xml & "<msg>Opportunity and corresponding objectives deleted</msg>"
		
		xml = xml & "</transaction>"
		
		
	
	'====================================================================================================================
	case "updateCustomerObjective" 
	'====================================================================================================================
	
		dbug(" ")
		dbug("updateCustomerObjective...")
		
		dbug("objectiveMetricName: " & request("objectiveMetricName"))
		
		xml = xml & "<transaction>"
		
		objectiveType				= request("objectiveType") ' 1::internal-standard; 2::internal-custom; 3::FDIC
		dbug("objectiveType: " & objectiveType)
		
		objectiveMetricID			= request("objectiveMetricID")
		dbug("objectiveMetricID: " & objectiveMetricID)
		
		objectiveMetricName		= replace(request("objectiveMetricName"),"'","''")
		dbug("objectiveMetricName: " & objectiveMetricName)
		
		showAnnualChangeInd		= request("showAnnualChangeInd")
		dbug("showAnnualChangeInd: " & showAnnualChangeInd) 
		
		peerGroupTypeID			= request("peerGroupTypeID")
		dbug("peerGroupTypeID: " & peerGroupTypeID)
		
		objectiveNarrative 		= replace(replace(request("objectiveNarrative"), "<hr>", ""),"'","''")
		dbug("objectiveNarrative: " & objectiveNarrative) 

		' start/end date are further handled below
		objectiveStartDate		= request("objectiveStartDate") 
		objectiveEndDate			= request("objectiveEndDate") 

		' start/end value are handled below
		
		
		objectiveTypeID			= request("objectiveTypeID") ' 1::Utopia; 2::Opportunity
		dbug("objectiveTypeID: " & objectiveTypeID)
		
		objectiveID					= request("objectiveID") ' PK for customerObjectives table
		dbug("objectiveID: " & objectiveID)
		
		opportunityID				= request("opportunityID")
		dbug("opportunityID: " & opportunityID)
		
		implementationID			= request("implementationID")
		dbug("implementationID: " & implementationID)
		
		customerID					= request("customerID") 
		dbug("customerID: " & customerID)


		dbug("objectiveType: " & objectiveType)
		select case cInt(objectiveType)
			case 1		' internal-standard 
			
				dbug("Internal-standard")
			
				objectiveMetricID 		= request("objectiveMetricID")
				objectiveMetricName		= "NULL"
				showAnnualChangeInd		= "NULL"
				peerGroupTypeID			= "NULL"
				customerID					= "NULL"
				
				
			case 2		' internal-custom

				dbug("Internal-custom")
			
				if len(request("objectiveMetricID")) <= 0 then 
					
					// insert the customer-specific metric into the metrics table....
					objectiveMetricID 		= getNextID("metric")
					dbug("new objectiveMetricID for internal-custom metric: " & objectiveMetricID)
					dbug("new objectiveMetricName for internal-customermetric: " & objectiveMetricName)		
		
					SQL = "insert into metric (" 						&_
								"id, " 										&_
								"name, " 									&_
								"active, " 									&_
								"type, " 									&_
								"internalMetricInd, " 					&_
								"customerID," 								&_
								"updatedBy, " 								&_
								"updatedDateTime" 						&_
							") " 												&_
							"values (" 										&_
								objectiveMetricID & ", " 				&_
								"'" & objectiveMetricName & "', " 	&_
								"1, " 										&_
								"'B', " 										&_
								"1, " 										&_
								customerID & ", " 						&_
								session("userID") & ", "				&_
								"CURRENT_TIMESTAMP" 						&_
							") "
					
					dbug(SQL)
					set rsInsert = dataconn.execute(SQL)
					set rsInsert = nothing 			
		
					xml = xml & "<metric id=""" & objectiveMetricID & """ customerID=""" & customerID & """><![CDATA[" & objectiveMetricName & "]]></metric>"

				else 

					objectiveMetricID = request("objectiveMetricID")

				end if 
				
				showAnnualChangeInd		= "NULL"
				peerGroupTypeID			= "NULL"

			case 3		' FDIC

				dbug("FDIC")
			
				objectiveMetricID 		= request("objectiveMetricID")
				objectiveMetricName		= "NULL"
				customerID					= "NULL"

			case else 
			
				dbug("ERROR: Unexpected metricType encountered: " & metricType)
				response.end()
				

		end select 
		
		
		if isNumeric(request("objectiveStartValue")) then 
			objectiveStartValue			= replace(request("objectiveStartValue"), "$", "")
			objectiveStartValue			= replace(objectiveStartValue, ",", "")
			objectiveStartValue			= replace(objectiveStartValue, "%", "")
		else 
			objectiveStartValue			= "NULL" 
		end if 
		
		if isNumeric(request("objectiveEndValue")) then 
			objectiveEndValue				= replace(request("objectiveEndValue"), "$", "")
			objectiveEndValue				= replace(objectiveEndValue, ",", "")
			objectiveEndValue				= replace(objectiveEndValue, "%", "")
		else 
			objectiveEndValue				= "NULL"
		end if
		
		' if startDate is present, determine the end date for quarter in which startDate falls
		if len(objectiveStartDate) > 0 then 
			if isDate(objectiveStartDate) then 
				eoqSQL = "select id from dateDimension where quarterEndInd = 1 and id >= '" & objectiveStartDate & "' "
				dbug(eoqSQL)
				set rsEOQ = dataconn.execute(eoqSQL) 
				if not rsEOQ.eof then 
					startQuarterEndDate = "'" & rsEOQ("id") & "'"
				else 
					dbug("startQuarterEndDate: null because no endOfQuarter found on dateDimension")
					startQuarterEndDate = "NULL"
				end if
				objectiveStartDate = "'" & objectiveStartDate & "'" 
			else 
				dbug("startQuarterEndDate: null because objectiveStartDate is not a date")
				startQuarterEndDate = "NULL"				
				objectiveStartDate = "NULL"
			end if
		else 
			dbug("startQuarterEndDate: null because objectiveStartDate not present")
			startQuarterEndDate = "NULL"				
			objectiveStartDate = "NULL"
		end if 
		dbug("startQuarterEndDate: " & startQuarterEndDate)

		' if end is present, determine the end date for quarter in which startDate falls
		if len(objectiveEndDate) > 0 then 
			if isDate(objectiveEndDate) then 
				
				eoqSQL = "select id from dateDimension where quarterEndInd = 1 and id >= '" & objectiveEndDate & "' "
				set rsEOQ = dataconn.execute(eoqSQL) 
				if not rsEOQ.eof then 
					endQuarterEndDate = "'" & rsEOQ("id") & "'"
				else 
					endQuarterEndDate = "NULL"
				end if
				objectiveEndDate = "'" & objectiveEndDate & "'" 
			else 
				endQuarterEndDate = "NULL"				
				objectiveEndDate = "NULL" 
			end if
		else 
			endQuarterEndDate = "NULL"				
			objectiveEndDate = "NULL" 
		end if 
		dbug("endQuarterEndDate: " & endQuarterEndDate)
		
		dbug("request('opportunityID'): " & request("opportunityID"))
		if len(request("opportunityID")) > 0 then 
			opportunityID = request("opportunityID") 
			msg = "Customer opportunity objective"
		else 
			opportunityID = "NULL"
			msg = "Customer objective"
		end if
			

		dbug("objectiveID: " & objectiveID)
		if len(objectiveID) > 0 then 
			
			xml = xml & "<objectiveID>" & objectiveID & "</objectiveID>"
			
			SQL = "update customerObjectives set " &_
						"implementationID = " 			& implementationID 			& ", " 	&_
						"narrative = '" 					& objectiveNarrative 		& "', " 	&_
						"startDate = " 					& objectiveStartDate 		& ", " 	&_
						"endDate = " 						& objectiveEndDate 			& ", " 	&_
						"objectiveTypeID = " 			& objectiveTypeID	 			& ", " 	&_
						"updatedBy = " 					& session("userID") 			& ", " 	&_
						"updatedDateTime = CURRENT_TIMESTAMP, " 									&_
						"metricID = " 						& objectiveMetricID 			& ", " 	&_
						"customName = '" 					& objectiveMetricName		& "', " 	&_
						"showAnnualChangeInd = " 		& showAnnualChangeInd 		& ", " 	&_
						"peerGroupTypeID = " 			& peerGroupTypeID 			& ", " 	&_
						"startValue = " 					& objectiveStartValue 		& ", " 	&_
						"endValue = " 						& objectiveEndValue 			& ", " 	&_
						"startQuarterEndDate = "		& startQuarterEndDate		& ", " 	&_
						"endQuarterEndDate = " 			& endQuarterEndDate			& ", "	&_
						"opportunityID = "				& opportunityID				& " " 	&_
					"where id = " & objectiveID 		& " " 
					
			msg = msg & " updated"
						
		else 
			
			newID = getNextID("customerObjectives") 
			
			xml = xml & "<objectiveID>" & newID & "</objectiveID>"

			SQL = "insert into customerObjectives (" &_
						"id, " &_
						"implementationID, " &_
						"narrative, " &_
						"startDate, " &_
						"endDate, " &_
						"objectiveTypeID, " &_
						"updatedBy, " &_
						"updatedDateTime, " &_
						"metricID, " &_
						"customName, " &_
						"showAnnualChangeInd, " &_
						"peerGroupTypeID, " &_
						"startValue, " &_
						"endValue, " &_
						"startQuarterEndDate, " &_
						"endQuarterEndDate, " &_
						"opportunityID" &_
					") " &_
					"values ( " &_
						newID & ", " &_
						implementationID 				& ", " 	&_
						"'" & objectiveNarrative 	& "', "	&_
						objectiveStartDate 			& ", " 	&_
						objectiveEndDate 				& ", " 	&_
						objectiveTypeID 				& ", " 	&_
						session("userID") 			& ", " 	&_
						"CURRENT_TIMESTAMP, "					&_
						objectiveMetricID 			& ", " 	&_
						"'" & objectiveMetricName	& "', " 	&_
						showAnnualChangeInd 			& ", " 	&_
						peerGroupTypeID 				& ", " 	&_
						objectiveStartValue			& ", "	&_
						objectiveEndValue				& ", "	&_
						startQuarterEndDate			& ", " 	&_
						endQuarterEndDate				& ", "	&_
						opportunityID					& ") " 
						
			msg = msg & " added"
						
		end if 
		
		dbug("updateCustomerObjective: " & SQL)
		
		set rsUpdate = dataconn.execute(SQL) 
		set rsUpdate = nothing 
		
		xml = xml & "<implementationID>" & implementationID & "</implementationID>"
		xml = xml & "<objectiveNarrative>" & objectiveNarrative & "</objectiveNarrative>"
		xml = xml & "<objectiveStartDate>" & objectiveStartDate & "</objectiveStartDate>"
		xml = xml & "<objectiveEndDate>" & objectiveEndDate & "</objectiveEndDate>"
		
		xml = xml & "<objectiveStartValue>" & objectiveStartValue & "</objectiveStartValue>"
		xml = xml & "<objectiveEndValue>" & objectiveEndValue & "</objectiveEndValue>"
		
		xml = xml & "<objectiveTypeID>" & objectiveType & "</objectiveTypeID>"
		xml = xml & "<objectiveMetricType>" & metricType & "</objectiveMetricType>"
		xml = xml & "<objectiveMetricID>" & objectiveMetricID & "</objectiveMetricID>"
		xml = xml & "<objectiveMetricName>" & objectiveMetricName & "</objectiveMetricName>"
		xml = xml & "<msg>" & msg & "</msg>"

		xml = xml & "</transaction>"
						
		

	'====================================================================================================================
	case "getMetrics"
	'====================================================================================================================
	
		dbug("getMetrics...")

		xml = xml & "<metrics>"
		
		dbug("ctgy: " & request.querystring("ctgy"))
		dbug("section: " & request.querystring("section"))
		
		SQL = "select distinct id, name, ubprLine, ubprSection, financialCtgy from metric "
		
		if len(request.querystring("ctgy")) > 0 then 
			SQL = SQL & "where financialCtgy = '" & request.querystring("ctgy") & "' " 
			if len(request.querystring("section")) > 0 then 
				SQL = SQL & "and ubprSection = '" & request.querystring("section") & "' " 
			end if
		else 
			if len(request.querystring("section")) > 0 then 
				SQL = SQL & "where ubprSection = '" & request.querystring("section") & "' " 
			end if
		end if
		
		SQL = SQL & "order by name " 
		
		dbug(SQL)
		
		set rsMetrics = dataconn.execute(SQL)
		
		while not rsMetrics.eof 
			metricName 		= replace(rsMetrics("name"), "&", "&amp;")
			metricSection 	= replace(rsMetrics("ubprSection"), "&", "&amp;")
			metricCategory = rsMetrics("financialCtgy")
			xml = xml & "<metric id=""" & rsMetrics("id") & """ data-line=""" & rsMetrics("ubprLine") & """ data-section=""" & metricSection & """ data-ctgy=""" & metricCategory & """>" & metricName & "</metric>"
			rsMetrics.movenext 
		wend 
		rsMetrics.close 
		set rsMetrics = nothing 
		
		xml = xml & "</metrics>"
		
		

	'====================================================================================================================
	case "getSectionsMetrics"
	'====================================================================================================================
	
		dbug("getSectionsMetrics...")
		
		SQL = "select distinct ubprSection from metric where financialCtgy = '" & request.querystring("ctgy") & "' order by 1 "
		dbug(SQL)
		
		xml = xml & "<sectionsMetrics>"
		set rsSections = dataconn.execute(SQL)
		
		while not rsSections.eof 
			xml = xml & "<section>" & replace(rsSections("ubprSection"), "&", "&amp;") & "</section>"
			rsSections.movenext 
		wend 
		rsSections.close 
		set rsSection = nothing 
		
		
		SQL = "select distinct id, name, ubprLine, ubprSection, financialCtgy from metric where financialCtgy = '" & request.querystring("ctgy") & "' order by 1 "
		dbug(SQL)
		
		set rsMetrics = dataconn.execute(SQL)
		
		while not rsMetrics.eof 
			metricName 		= replace(rsMetrics("name"), "&", "&amp;")
			metricSection 	= replace(rsMetrics("ubprSection"), "&", "&amp;")
			metricCategory = rsMetrics("financialCtgy")
			xml = xml & "<metric id=""" & rsMetrics("id") & """ data-line=""" & rsMetrics("ubprLine") & """ data-section=""" & metricSection & """ data-ctgy=""" & metricCategory & """>" & metricName & "</metric>"
			rsMetrics.movenext 
		wend 
		rsMetrics.close 
		set rsMetrics = nothing 
		
		xml = xml & "</sectionsMetrics>"
		
		

	'====================================================================================================================
	case "getAllFdicSelectors"
	'====================================================================================================================
	
		dbug("getAllFdicSelectors detected...")
		
		if request.querystring("value") <> "all" then 
			searchCriteria = "where " & request.querystring("searchField") & " = '" & request.querystring("value") & "' and internalMetricInd = 0 "		
		else 
			searchCriteria = "where internalMetricInd = 0 "
		end if

		xml = xml & "<searchResults>"
		
		xml = xml & "<financialCategories>"
		sql = "select distinct financialCtgy from metric " & searchCriteria & " order by 1 " 
		dbug(SQL)
		set rsSearch = dataconn.execute(SQL)
		while not rsSearch.eof
			name = replace(rsSearch("financialCtgy"), "&", "&amp;") 
			xml = xml & "<financialCategory>" & name & "</financialCategory>"
			rsSearch.movenext 
		wend 
		rsSearch.close 
		xml = xml & "</financialCategories>"
		
		
		xml = xml & "<ubprSections>"
		sql = "select distinct ubprSection from metric " & searchCriteria & " order by 1 " 
		dbug(SQL)
		set rsSearch = dataconn.execute(SQL)
		while not rsSearch.eof
			name = replace(rsSearch("ubprSection"), "&", "&amp;")
			xml = xml & "<ubprSection>" & name & "</ubprSection>"
			rsSearch.movenext 
		wend 
		rsSearch.close 
		xml = xml & "</ubprSections>"
		
		
		xml = xml & "<ubprLines>"
		sql = "select distinct cast(ubprLine as decimal(3,1)) as ubprLine from metric " & searchCriteria & " order by 1 " 
		dbug(SQL)
		set rsSearch = dataconn.execute(SQL)
		while not rsSearch.eof
			name = replace(rsSearch("ubprLine"), "&", "&amp;")
			xml = xml & "<ubprLine>" & name & "</ubprLine>"
			rsSearch.movenext 
		wend 
		rsSearch.close 
		xml = xml & "</ubprLines>"
		
		
		xml = xml & "<metrics>"
		sql = "select distinct id, name from metric " & searchCriteria & " order by 1 " 
		dbug(SQL)
		set rsSearch = dataconn.execute(SQL)
		while not rsSearch.eof
			name = replace(rsSearch("name"), "&", "&amp;")
			xml = xml & "<metric id=""" & rsSearch("id") & """>" & name & "</metric>"
			rsSearch.movenext 
		wend 
		rsSearch.close 
		xml = xml & "</metrics>"
		
		xml = xml & "</searchResults>"


	'====================================================================================================================
	case "getInternalMetricList"
	'====================================================================================================================
		
		dbug("getInternalMetricList detected")

		customerID 	= request.querystring("customerID")
		typeID		= request.querystring("type") 
			
			
		SQL = "select distinct " &_
					"id, " &_
					"name " &_
				"from metric " &_
				"where internalMetricInd = 1 " &_
				"and type = '" & typeID & "' " 
			
		if typeID = "B" then 

			SQL = SQL & "and customerID = " & customerID & " "
		
		end if

				
		dbug(SQL)
		 
		SQL = SQL & "order by name " 		
		dbug(SQL)

		set rsIM = dataconn.execute(SQL)
		
		xml = xml & "<metrics type=""" & typeID & """ customerID=""" & customerID & """>"
		while not rsIM.eof 
			xml = xml & "<metric id=""" & rsIM("id") & """>" & rsIM("name") & "</metric>"
			rsIM.movenext
		wend 
		xml = xml & "</metrics>"


		rsIM.close 
		set rsIM = nothing 


	'====================================================================================================================
	case "getFDICCategoriesSections"
	'====================================================================================================================
	
		dbug("getFDICCategoriesSections detected")
		
		xml = xml & "<fdic>"
		
		' get the list of categories....
		xml = xml & "<categories>"
		SQL = "select distinct financialCtgy from metric where internalMetricInd = 0 order by financialCtgy "
		dbug(SQL)
		set rsCtgy = dataconn.execute(SQL)
		while not rsCtgy.eof 
			xml = xml & "<category>" & rsCtgy("financialCtgy") & "</category>"
			rsCtgy.movenext 
		wend 
		rsCtgy.close 
		set rsCtgy = nothing 
		xml = xml & "</categories>"
		
		' get the list of UBPR Sections....
		xml = xml & "<sections>"
		SQL = "select distinct ubprSection from metric where internalMetricInd = 0 order by ubprSection " 
		dbug(SQL)
		set rsSect = dataconn.execute(SQL)
		while not rsSect.eof 
			xml = xml & "<section>" & replace(rsSect("ubprSection"),"&","&amp;") & "</section>"
			rsSect.movenext 
		wend 
		rsSect.close 
		set rsSect = nothing 
		xml = xml & "</sections>"
		
		xml = xml & "</fdic>"
		
		
	'====================================================================================================================
	case "getFDICMetricList"
	'====================================================================================================================
	
		dbug("getFDICMetricList detected")
		
		xml = xml & "<metrics>"

		SQL = "select id, name, ubprLine, ubprSection, financialCtgy, displayUnitsLabel, dataType, correspondingAnnualChangeID from metric where internalMetricInd = 0 "
		
		if len(request.querystring("category")) > 0 then 
			if request.querystring("category") <> "Make a selection..." then 
				SQL = SQL & "and financialCtgy = '" & request.querystring("category") & "' "
			end if 
		end if 
		
		if len(request.querystring("section")) > 0 then 
			if request.querystring("section") <> "Make a selection..." then 
				SQL = SQL & "and ubprSection = '" & request.querystring("section") & "' "
			end if 
		end if 
		
		SQL = SQL & "order by name "

		dbug(SQL)
		set rsMetrics = dataconn.execute(SQL) 
		while not rsMetrics.eof 

			metricName 							= replace(rsMetrics("name"), "&", "&amp;")
			ubprSection 						= replace(rsMetrics("ubprSection"), "&", "&amp;")
			displayUnitsLabel 				= lCase(rsMetrics("displayUnitsLabel"))
			dataType								= lCase(rsMetrics("dataType"))
			correspondingAnnualChangeID	= rsMetrics("correspondingAnnualChangeID")
			
			xml = xml & "<metric id=""" & rsMetrics("id") & """ data-line=""" & rsMetrics("ubprLine") & """ data-ctgy=""" & rsMetrics("financialCtgy") & """ data-section=""" & ubprSection & """ data-type=""" & dataType & """ data-label=""" & displayUnitsLabel & """ data-changeID=""" & correspondingAnnualChangeID & """>" & metricName & "</metric>"

			rsMetrics.movenext 

		wend 
		rsMetrics.close 
		set reMetrics = nothing 
		
		xml = xml & "</metrics>"
	

	'====================================================================================================================
	case "addMetric"
	'====================================================================================================================
	
		dbug("addMetric detected")
		
		customerID 			= request.querystring("customerID")
		
		if len(request.querystring("attributeDate")) > 0 then 
			attributeDate 		= "'" & request.querystring("attributeDate") & "'" 
		else 
			attributeDate = "NULL"
		end if 
		
		if len(request.querystring("attributeValue")) > 0 then 
			attributeValue 	= request.querystring("attributeValue")
		else 
			attributeValue		= "NULL"
		end if 
		
		if len(request.querystring("narrative")) > 0 then 
			
			narrative			= replace(request.querystring("narrative"), "'", "''")
			narrative			= replace(narrative, """", "&quot;")
			narrative 			= "'" & narrative & "'"

		else 
			narrative			= "NULL"
		end if
		
		if len(request.querystring("attrName")) > 0 then 
			
			attributeName		= replace(request.querystring("attrName"), "'", "''")
			attributeName		= replace(attributeName, """", "&quot;")
			attributeName 		= "'" & attributeName & "'"
			
		else 
			attributeName		= "NULL"
		end if
		
		if request.querystring("metricID") = "Make a selection..." then 
			metricID				= "NULL"
		else 
			if len(request.querystring("metricID")) > 0 then 
				metricID 			= request.querystring("metricID")
			else 
				metricID				= "NULL"
			end if 
		end if
		
		if len(request.querystring("attributeTypeID")) > 0 then 
			attributeTypeID 	= request.querystring("attributeTypeID")
		else 
			attributeTypeID	= "NULL"
		end if
		
		if len(request.querystring("attainByDate")) > 0 then 
			attainByDate 		= "'" & request.querystring("attainByDate") & "'" 
		else 
			attainByDate		= "NULL"
		end if 
		
		if len(request.querystring("attributeSource")) > 0 then 
			attributeSource	= "'" & request.querystring("attributeSource") & "'" 
		else 
			attributeSource	= "NULL"
		end if 
		
		if len(request.querystring("startValue")) > 0 then 
			startValue 			= "'" & request.querystring("startValue") & "'" 
		else 
			startValue 			= "NULL"
		end if
		
		if len(request.querystring("startValueDate")) > 0 then 
			startValueDate 	= "'" & request.querystring("startValueDate") & "'" 
		else 
			startValueDate		= "NULL"
		end if 
		
		if len(request.querystring("economicValue")) > 0 then 
			economicValue 		= request.querystring("economicValue") 
		else 
			economicValue		= "NULL" 
		end if
		
		newID = getNextID("customerAnnotations")

		SQL = "insert into customerAnnotations (id, attributeDate, attributeValue, customerID, narrative, addedBy, updatedDate, metricID, attributeTypeID, attainByDate, customName, attributeSource, startValue, startValueDate, annualEconomicValue) " &_
				"values ( " &_
					newID & ", " &_
					attributeDate & ", " &_
					attributeValue & ", " &_
					customerID & ", " &_
					narrative & ", " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP, " &_
					metricID & ", " &_
					attributeTypeID & ", " &_
					attainByDate & ", " &_
					attributeName & ", " &_
					attributeSource & ", " &_
					startValue & ", " &_
					startValueDate & ", " &_
					economicValue &_ 
				") " 
					
		dbug(SQL)
		
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		msg = "Attribute added"
		
		xml = xml & "<transaction>"
		xml = xml & "<attributeDate>" & attributeDate & "</attributeDate>"
		xml = xml & "<attributeValue>" & attributeValue & "</attributeValue>"
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<narrative>" & narrative & "</narrative>"
		xml = xml & "<metricID>" & metricID & "</metricID>"
		xml = xml & "<attributeTypeID>" & attributeTypeID & "</attributeTypeID>"
		xml = xml & "<attainByDate>" & attainByDate & "</attainByDate>"
		xml = xml & "<customName>" & attributeName & "</customName>"
		xml = xml & "<startValue>" & startValue & "</startValue>"
		xml = xml & "<startValueDate>" & startValueDate & "</startValueDate>"
		xml = xml & "<economicValue>" & economicValue & "</economicValue>"
		xml = xml & "<msg>" & msg & "</msg>"
		xml = xml & "</transaction>"

							
	'====================================================================================================================
	case "updateMetric" 
	'====================================================================================================================
	
		dbug("updateMetric detected...")
		
		customerID 			= request.querystring("customerID")
		
		if len(request("attributeDate")) > 0 then 
			attributeDate 		= "'" & request("attributeDate") & "'" 
		else 
			attributeDate = "NULL"
		end if 
		
		if len(request("attributeValue")) > 0 then 
			attributeValue 	= "'" & request("attributeValue") & "'"
		else 
			attributeValue		= "NULL"
		end if 
		
		if len(request("narrative")) > 0 then 
			narrative			= replace(request("narrative"), "'", "''") 
' 			narrative			= replace(narrative, """", "&quot;")
			narrative 			= "'" & narrative & "'"
		else 
			narrative			= "NULL"
		end if
		
		if len(request("attrName")) > 0 then 
			customName		= replace(request("attrName"), "'", "''")
' 			customName		= replace(customName, """", "&quot;")
			customName		= "'" & customName & "'"
		else 		
			customName		= "NULL"
		end if 
			
		if request("metricID") = "Make a selection..." then 
			metricID			= "NULL"
		else 
			metricID 			= request("metricID")
		end if
		
		if len(request("attributeTypeID")) > 0 then 
			attributeTypeID 	= request("attributeTypeID")
		else 
			attributeTypeID	= "NULL"
		end if
		
		if len(request("attainByDate")) > 0 then 
			attainByDate 		= "'" & request("attainByDate") & "'" 
		else 
			attainByDate		= "NULL"
		end if 
		
		if len(request("attributeSource")) > 0 then 
			attributeSource	= "'" & request("attributeSource") & "'" 
		else 
			attributeSource	= "NULL"
		end if 
		
		if len(request("active")) > 0 then 
			active = cInt(request("active"))
		else 
			active = "NULL"
		end if
		
		id = request("annotationID")
				
		SQL = "update customerAnnotations set " &_
					"customName = " & customName & ", " &_
					"narrative = " & narrative & ", " &_
					"attributeDate = " & attributeDate & ", " &_
					"attributeValue = " & attributeValue & ", " &_
					"attainByDate = " & attainByDate & ", " &_
					"addedBy = " & session("userID") & ", " &_
					"updatedDate = CURRENT_TIMESTAMP, " &_
					"active = " & active & " " &_
				"where id = " & id & " " 
				
		dbug(SQL)
		
		set rsUpdate = dataconn.execute(SQL)
		set rsUpdate = nothing 
		
		msg = "Attribute updated" 
		
		xml = xml & "<transaction>"
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<attributeDate>" & attributeDate & "</attributeDate>"
		xml = xml & "<attributeValue>" & attributeValue & "</attributeValue>"
		xml = xml & "<customName>" & customName & "</customName>"
		xml = xml & "<narrative>" & narrative & "</narrative>"
		xml = xml & "<attainByDate>" & attainByDate & "</attainByDate>"
		xml = xml & "<active>" & active & "</active>"
		xml = xml & "<msg>" & msg & "</msg>"
		xml = xml & "</transaction>"
		
	
	'====================================================================================================================
	case "deleteCustomerAnnotation"
	'====================================================================================================================
	
		dbug("deleteCustomerAnnotation detected...")
		
		id = request("id")
		
		SQL = "delete from customerAnnotations where id = " & id & " " 
		
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		msg = "Attribute deleted"
		xml = xml & "<transaction>"
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"
		xml = xml & "</transaction>"


	'====================================================================================================================
	case else 
	'====================================================================================================================
	
		dbug("else detected")
	
		xml = xml & "<metrics>"
		
		if len(request("id")) > 0 then
		
			xml = xml & "<crossSales customer=""" & request("id") & """>"
		
		 	json = "["
			json = json & "[""Date"",""Value""]"
			
			SQL =	"select d.id, cm.value " &_
					"from dateDimension d " &_
					"left join customerMetric cm on (cm.updatedDate = d.id and cm.metricID = 1) " &_
					"where d.id between '9/26/2016' and '9/25/2017' " &_
					"order by d.id asc "
			
			set rs = dataconn.execute(SQL)
			while not rs.eof 
				if isNull(rs("value")) then
					varValue = "null"
				else
					varValue = rs("value")
				end if
			' 	json = json & ",['" & rs("repdte") & "'," & rs("asset") & "," & rs("dep") & "]"
				json = json & ",[""" & rs("id") & """," & varValue & "]"
				rs.movenext 
			wend
			
			rs.close 
			set rs = nothing 
			
			json = json & "]"
		
			xml = xml & json 
			xml = xml & "</crossSales>"
			
		end if
	
		dataconn.close
		set dataconn = nothing

		xml = xml & "</metrics>"
		

end select 

userLog(msg)


dataconn.close
set dataconn = nothing

response.write(xml)	

%>