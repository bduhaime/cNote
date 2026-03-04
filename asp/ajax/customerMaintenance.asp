<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/getNextID.asp" -->
<!-- #include file="../includes/escapeQuotes.asp" -->
<!-- #include file="../includes/validContactDomain.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

'***** CUSTOMER MAINTENANCE *****
dbug("start customerMaintenance.asp...")
response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<customerMaintenance>"

msg = ""


'***********************************************************
sub toggleIndicator(id, indicator)
'***********************************************************
	
	SQL = "update customer set " & indicator & " = case when " & indicator & " = 1 then 0 else 1 end where id = " & id & " "
	set rs = dataconn.execute(SQL)
	
	SQL = "select " & indicator & " as updatedValue from customer_view where id = " & id & " "
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
	
	msg = indicator & " indicator updated"
	xml = xml & "<customer id=""" & id & """><" & indicator & ">" & updatedValue & "</" & indicator & "></customer>"
	xml = xml & "<msg>" & msg & "</msg>"
	xml = xml & "<status>success</status>"

	dbug("xml: " & xml)
end sub


'***********************************************************
'***********************************************************
'***********************************************************
'***********************************************************

dbug("about to evaluate 'cmd'...")
select case request.querystring("cmd")
	
	'**************************************************************************************************
	case "add"
	'**************************************************************************************************
	
		dbug("add detected")
		
		if len(request.querystring("name")) > 0 then 
			customerName = request.querystring("name")
		else 
			error = true 
		end if
		
' 		if len(request.querystring("RSSDID")) > 0 then 
			
		
		
	'**************************************************************************************************
	case "delete"
	'**************************************************************************************************

		dbug("delete detected")
		call toggleIndicator(request.querystring("customer"),"deleted")



	'**************************************************************************************************
	case "addClientManager"
	'**************************************************************************************************
	
		dbug("addClientManager detected")
		
		userID 			= request.querystring("userID")
		typeID 			= request.querystring("type")
		startDate		= request.querystring("start")
		endDate			= request.querystring("end")
		customerID		= request.querystring("customer")
		
		if len(typeID) > 0 then 

			insertTypeID = typeID

			SQL = "select name from customerManagerTypes where id = " & typeID & " " 
			set rsType = dataconn.execute(SQL)
			if not rsType.eof then 
				cmType = trim(rsType("name")) 
			else 
				cmType = ""
			end if
			rsType.Close
			set rsType = nothing 

		else 

			insertTypeID = "NULL"
			cmType = ""
			
		end if
		
		if len(startDate) > 0 then 
			if isDate(startDate) then 
				insertStartDate = "'" & startDate & "'" 
			else 
				insertStartDate = "NULL" 
			end if
		else 
			insertStartDate = "NULL"
		end if
		
		if len(endDate) > 0 then 
			if isDate(endDate) then 
				insertEndDate = "'" & endDate & "'"
			else 
				insertEndDate = "NULL"
			end if
		else 
			insertEndDate = "NULL" 
		end if 
		

		newID = getNextID("customerManagers")
		
		SQL = "insert into customerManagers (id, customerID, userID, startDate, endDate, updatedBy, updatedDateTime, managerTypeID	) " &_
				"values (" &_
				newID & ", " &_
				customerID & ", " &_
				userID & ", " &_
				insertStartDate & ", " &_
				insertEndDate & ", " &_
				session("userID") & ", " &_
				"CURRENT_TIMESTAMP, " &_
				insertTypeID & " " &_
				") " 
		
		dbug(SQL)
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		dbug("insert complete...")
		xml = xml & "<id>" & newID & "</id>"
		
		msg = "Client manager added"
		
		SQL = "select firstName, lastName from cSuite..users where id = " & userID & " "
		set rsUser = dataconn.execute(SQL)
		if not rsUser.eof then 
			userName = trim(rsUser("firstName")) & " " & trim(rsUser("lastName")) 
		else 
			userName = ""
		end if
		rsUser.close 
		set rsUser = nothing 
		xml = xml & "<userID>" & userID & "</userID>"
		xml = xml & "<userName>" & userName & "</userName>"
		
		dbug("userName retrieved....")
		
		xml = xml & "<typeID>" & typeID & "</typeID>"
		xml = xml & "<typeName>" & cmType & "</typeName>"
		
		dbug("typeName retrieved...")
		
		
		xml = xml & "<startDate>" & startDate & "</startDate>"
		xml = xml & "<endDate>" & endDate & "</endDate>"
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<msg>" & msg & "</msg>"
		
		dbug("addClientManager complete")



	'**************************************************************************************************
	case "deleteClientManager"
	'**************************************************************************************************
	
		dbug("deleteClientManager detected")
		
		id = request.querystring("id")
		
		SQL = "delete from customerManagers where id = " & id & " "
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing
		
		msg = "Client manager deleted"

		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"

	
	
	'**************************************************************************************************
	case "updatePrimaryClientManager" 
	'**************************************************************************************************
	
		dbug("updatePrimaryClientManager detected")
	
		primaryClientManager = request.querystring("id")
		effectiveDate 			= request.querystring("effectiveDate")
		customerID 				= request.querystring("customerID")
		
		' first figure out if there is already a primary customer manager....
		SQL = "select id from customerManagers where customerID = " & customerID & " and managerTypeID = 0 and active = 1 " 
		dbug(SQL)
		set rsFindExisting = dataconn.execute(SQL)
		' if an existing is found, then update the endDate and primary indicator...
		if not rsFindExisting.eof then 
			' existing found, so update that customerManager row...
			' CONVERT (date, SYSDATETIME()) ?
			oldPrimaryManager = rsFindExisting("id")
			SQL = "update customerManagers set " &_
						"endDate = '" & effectiveDate & "', " &_
						"active = 0, " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = CURRENT_TIMESTAMP " &_
					"where customerID = " & customerID & " " &_
					"and managerTypeID = 0 " &_
					"and active = 1 "
' 			SQL = "update customerManagers set " &_
' 						"active = 0, " &_
' 						"updatedBy = " & session("userID") & ", " &_
' 						"updatedDateTime = CURRENT_TIMESTAMP " &_
' 					"where customerID = " & customerID & " " &_
' 					"and managerTypeID = 0 " &_
' 					"and active = 1 "
			dbug(SQL)
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing 
		else 
			oldPrimaryManager = ""
		end if
		rsFindExisting.close 
		set rsFindExisting = nothing 
		
		' now add the new manager info...
		newID = getNextID("customerManagers")
		SQL = "insert into customerManagers (id, customerID, userID, managerTypeID, startDate, active, updatedBy, updatedDateTime) " &_
				"values ( " &_
					newID & ", " &_
					customerID & ", " &_
					primaryClientManager & ", " &_
					"0, " &_
					"'" & effectiveDate & "', " &_
					"1, " &_
					session("userID") & ", " &_
					"CURRENT_TIMESTAMP) " 
		dbug(SQL)
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		msg = "Primary manager updated"
		
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<oldPrimaryManager>" & oldPrimaryManager & "</oldPrimaryManager>"
		xml = xml & "<newPrimaryManager>" & primaryClientManager & "</newPrimaryManager>"
		xml = xml & "<effectiveDate>" & effectiveDate & "</effectiveDate>"
		xml = xml & "<msg>" & msg & "</msg>"
				


	'**************************************************************************************************
	case "updateClientManager"
	'**************************************************************************************************
	
		dbug("updateClientManager detected....")
		
		clientManagerID 	= request.querystring("id")
		managerTypeID 		= request.querystring("managerTypeID")
		effectiveDate		= request.querystring("effectiveDate")
		customerID 			= request.querystring("customerID")
		
		SQL = "select id, active, startDate, endDate from customerManagers " &_
				"where customerID = " & customerID & " " &_
				"and userID = " & clientManagerID & " " &_
				"and managerTypeID = " & managerTypeID & " " &_
				"and (active = 1 or active is null) " 
				
		dbug(SQL)
		
		set rsCM = dataconn.execute(SQL) 
		if not rsCM.eof then 

			newActive = "0"
			endDate = "'" & date() & "'" 

			SQL = "update customerManagers set " &_
						"active = " & newActive & ", " &_
						"endDate = '" & effectiveDate & "', " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = CURRENT_TIMESTAMP " &_
					"where id = " & rsCM("id") & " " 

			msg = "Customer manager deleted"
			
		else 

			newID = getNextID("customerManagers")
			SQL = "insert into customerManagers (id, customerID, userID, managerTypeID, startDate, active, updatedBy, UpdatedDateTime) " &_
					"values ( " &_
						newID & ", " &_
						customerID & ", " &_
						clientManagerID & ", " &_
						managerTypeID & ", " &_
						"'" & effectiveDate & "', " &_
						"1, " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP) " 

			msg = "Customer manager added"

		end if
		
		rsCM.close 
		set rsCM = nothing 
					
		dbug(SQL)
		set rs = dataconn.execute(SQL)
		set rs = nothing 
			
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<clientManagerID>" & clientManagerID & "</clientManagerID>"
		xml = xml & "<managerTypeID>" & managerTypeID & "</managerTypeID>"
		xml = xml & "<effectiveDate>" & effectiveDate & "</effectiveDate>"
		xml = xml & "<msg>" & msg & "</msg>"
		


	'**************************************************************************************************
	case "addCustomerContact"
	'**************************************************************************************************
	
		dbug("addCustomerContact detected....")
		
		companyID 					= request.querystring("contactCustomerID")
		gender		 				= request.querystring("gender")
		firstName	 				= escapeQuotes(request.querystring("firstName"))
		lastName		 				= escapeQuotes(request.querystring("lastName"))

		contactTitle 				= escapeQuotes(request.querystring("contactTitle"))
		contactTitle				= replace( contactTitle, "&", "&amp;" )

		contactEmail				= escapeQuotes(request.querystring("contactEmail"))
		contactPhone				= escapeQuotes(request.querystring("contactPhone"))
		contactGrade 				= request.querystring("contactGrade")
		
		callAttendeeInd 			= request.querystring("contactCallAttendeeInd")
		if len(callAttendeeInd) > 0 then 
			dbug("len(callAttendeeInd) > 0")
			if isNumeric(callAttendeeInd) then 
				dbug("isNumer(callAttendeeInd) is true")
				if callAttendeeInd = 1 then 
					dbug("callAttendeeInd = 1")
					callAttendeeInd = 1
				else 
					dbug("callAttendeeInd <> 1")
					callAttendeeInd = 0
				end if 
			else 
				dbug("isNumer(callAttendeeInd) is false")
				callAttendeeInd = 0
			end if 
		else 
			dbug("len(callAttendeeInd) <= 0")
			callAttendeeInd = 0
		end if
		dbug("callAttendeeInd: " & callAttendeeInd)
		
		contactID					= request.querystring("contactID")
		
		if request.querystring("assignedRoles") <> "undefined" then 
			if len(request.querystring("assignedRoles")) > 0 then 
				assignedRoles				= split(request.querystring("assignedRoles"),",")
			else 
				assignedRoles = array()
			end if
		else 
			assignedRoles = array()
		end if 
		
		dbug("contactID: " & contactID)
		
		
		
		
		if len(contactID) > 0 then 
			
			dbug("updating...")
			newID = contactID 
			SQL = "update customerContacts set " &_
						"firstName = '" & firstName & "', " &_
						"lastName = '" & lastName & "', " &_
						"title = '" & contactTitle & "', " &_
						"email = '" & contactEmail & "', " &_
						"phone = '" & contactPhone & "', " &_
						"zeroRiskGrade = '" & contactGrade & "', " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = CURRENT_TIMESTAMP, " &_
						"callAttendee = " & callAttendeeInd & ", " &_
						"gender = '" & gender & "' " &_
					"where id = " & newID & " " 

	
			dbug("add/edit customerContact: " & SQL)
			set rs = dataconn.execute(SQL)
			set rs = nothing 
					
			msg = "Contact updated"
					
		else 

			dbug("inserting...")

			set rsNew = server.createobject("ADODB.Recordset")
			with rsNew
				
				.open "customerContacts",dataconn,adOpenKeyset,adLockOptimistic,adCmdTableDirect
				.addNew
				.fields("customerID") 			= companyID
				.fields("firstName")				= firstName
				.fields("lastName")				= lastName
				.fields("title")					= contactTitle
				.fields("zeroRiskGrade")		= contactGrade
				.fields("updatedBy")				= session("userID")
' 				.fields("updatedDateTime")		= now()
				.fields("callAttendee")			= callAttendeeInd
				.fields("gender")					= gender
				.fields("email")					= contactEmail
				.fields("phone")					= contactPhone
				.update
				newID = .fields("id") 
				.close 
				
			end with 
			set rsNew = nothing

			msg = "Contact added"

		end if 
		
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<companyID>" & companyID & "</companyID>"
		xml = xml & "<firstName>" & firstName & "</firstName>"
		xml = xml & "<lastName>" & lastName & "</lastName>"
		xml = xml & "<title><![CDATA[" & contactTitle & "]]></title>"
		xml = xml & "<email>" & contactEmail & "</email>"
		xml = xml & "<phone>" & contactPhone & "</phone>"
		xml = xml & "<grade>" & contactGrade & "</grade>"
		xml = xml & "<callAttendeeInd>" & callAttendeeInd & "</callAttendeeInd>"

		
		' always delete all contactRoleXref rows, then re-add the ones the user just selected....
		SQL = "delete from contactRoleXref where contactID = " & newID & " "
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 

		xml = xml & "<roles>"

		if uBound(assignedRoles) >= 0 then 

			for each item in assignedRoles
				
				SQL = "insert into contactRoleXref (contactID, roleID) " &_
						"values ( " & newID & "," & item & ") "
				dbug(SQL)
				set rsInsert = dataconn.execute(SQL) 
				set rsInsert = nothing			
				xml = xml & "<role>" & item & "</role>"
			
			next 

		end if
		
		xml = xml & "</roles>"








		xml = xml & "<msg>" & msg & "</msg>"
		
		
		
	'**************************************************************************************************
	case "deleteClientContact"
	'**************************************************************************************************
	
		dbug("deleteClientContact detected")
		
		id = request.querystring("id")
		
' 		SQL = "delete from customerContacts where id = " & id & " "
		SQL = "update customerContacts set deleted = 1 where id = " & id & " " 
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing
		
		msg = "Client contact deleted"

		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"

	
	
	'**************************************************************************************************
	case "toggleContact"
	'**************************************************************************************************
	
		dbug("toggleContact detected")
		
		contactID = request.querystring("id")
		attr = request.querystring("attr")

		SQL = "update customerContacts set " & attr & " = case when " & attr & " = 1 then 0 else 1 end where id = " & contactID & " "
		dbug(SQL)
		
		set rsToggle = dataconn.execute(SQL)
		set rsToggle = nothing 
		
		xml = xml & "<id>" & contactID & "</id>"
		xml = xml & "<attr>" & attr & "</attr>"
		xml = xml & "<attrName>callAttendee</attrName>"
		msg = attrName & " updated"
		xml = xml & "<msg>Call attendee indicator updated</msg>"
	
	
		
	'**************************************************************************************************
	case "addAnnotation"
	'**************************************************************************************************
	
		dbug("addAnnotation detected")
		
		attributeTypeId 		= request.querystring("attributeTypeId")
		annotationMetricID 	= request.querystring("annotationMetricID")
		attributeDate 			= request.querystring("attributeDate")
		annotationNarrative	= request.querystring("annotationNarrative")
		metricValue				= request.querystring("metricValue")
		customerID				= request.querystring("customerID")
		attainByDate			= request.querystring("attainByDate")
		newID 					= getNextID("customerAnnotations")
		
		if attributeTypeID = 1 then 
' 			Metric Note" Selected (insert NULL for metricValue)....
			SQL = "insert into customerAnnotations (id, attributeDate, attributeValue, customerID, narrative, addedBy, updatedDate, metricID, attributeTypeID, attainByDate) " &_
					"values ( " &_
						newID & ", " &_
						"'" & attributeDate & "', " &_
						"NULL, " &_
						customerID & ", " &_
						"'" & annotationNarrative & "', " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						annotationMetricID & ", " &_
						attributeTypeID & ", " &_
						"'" & attainByDate & "' " &_
						") " 
		else 
' 			something other than "Metric Note" selected (insert metricValue from dialog)...
			SQL = "insert into customerAnnotations (id, attributeDate, attributeValue, customerID, narrative, addedBy, updatedDate, metricID, attributeTypeID, attainByDate) " &_
					"values ( " &_
						newID & ", " &_
						"'" & attributeDate & "', " &_
						"'" & metricValue & "', " &_
						customerID & ", " &_
						"'" & annotationNarrative & "', " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						annotationMetricID & ", " &_
						attributeTypeID & ", " &_
						"'" & attainByDate & "' " &_
						") " 
		end if
				
		dbug(SQL)
		
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<attributeTypeID>" & attributeTypeID & "</attributeTypeID>"

		SQL = "select name from attributeTypes where id = " & attributeTypeID & " " 
		set rsAttr = dataconn.execute(SQL) 
		if not rsAttr.eof then
			attributeTypeName = rsAttr("name")
		else 
			attributeTypeName = ""
		end if
		rsAttr.close 
		set rsAttr = nothing 
		xml = xml & "<attributeTypeName>" & attributeTypeName & "</attributeTypeName>"
		
		xml = xml & "<attributeDate>" & formatDateTime(attributeDate,2) & "</attributeDate>"
		xml = xml & "<metricValue>" & metricValue & "</metricValue>"
		xml = xml & "<customerID>" & customerID & "</customerID>"
		xml = xml & "<annotationNarrative>" & annotationNarrative & "</annotationNarrative>"
		xml = xml & "<annotationMetricID>" & annotationMetricID & "</annotationMetricID>"
		xml = xml & "<attainByDate>" & attainByDate & "</attainByDate>"

		SQL = "select name from metric where id = " & annotationMetricID & " " 
		set rsMtr = dataconn.execute(SQL)
		if not rsMtr.eof then 
			metricName = rsMtr("name") 
		else 
			metricName = ""
		end if 
		xml = xml & "<metricName>" & metricName & "</metricName>"
		rsMtr.close 
		set rsMtr = nothing 
		
		msg = "Annotation added"
			
		xml = xml & "<addedBy>" & session("firstName") & " " & session("lastName") & "</addedBy>"
		xml = xml & "<msg>" & msg & "</msg>"
				
			
				
	'**************************************************************************************************
	case "deleteAnnotation"
	'**************************************************************************************************
	
		dbug("delete annotation detected...")
		
		id = request.querystring("id")
		
		SQL = "delete from customerAnnotations where id = " & id & " "
		dbug(SQL)
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing
		
		msg = "Annotation deleted"

		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"
		
		
		
	'**************************************************************************************************
	case "query"
	'**************************************************************************************************
	
		dbug("query detected")
		
		SQL = "select c.*, cs.name as statusName from customer_view c left join customerStatus cs on (cs.id = c.customerStatusID) where c.id =" & request.querystring("id")
		set rsQuery = dataconn.execute(SQL)
		if not rsQuery.eof then 
			for each item in rsQuery.fields
				xml = xml & "<" & item.name & ">" 
				xml = xml & "<![CDATA[" & item.value & "]]>"
				xml = xml & "</" & item.name & ">"
			next 
			msg = "Customer retreived"
		else 
			msg = "Customer not found"
		end if

		xml = xml & "<msg>" & msg & "</msg>"
		
		
	
	'**************************************************************************************************
	case "addInstitution"
	'**************************************************************************************************
	
		dbug("addInstitution detected")

		id						= request.querystring("id")		
		name 					= request.querystring("name")
		city 					= request.querystring("city")
		state 				= request.querystring("state")

		if len(request.querystring("customerStatusID")) then 
			customerStatusID = "'" & request.querystring("customerStatusID") & "'"
		else 
			customerStatusID = "NULL"
		end if		
		
		if len(request.querystring("customerNickname")) > 0 then  	
			nickname				= "'" & request.querystring("customerNickname") & "'"
		else 
			nickname = "null" 
		end if
		
		validDomains		= "'" & request.querystring("validDomains") & "'"
		lsvtCustomerName	= "'" & request.querystring("lsvtCustomerName") & "'"
		
		cProfitURI			= "'" & request.querystring("cProfitURI") & "'"
		cProfitAPIKey		= "'" & request.querystring("cProfitAPIKey") & "'"
		defaultTimezone	= "'" & request.querystring("defaultTimezone") & "'"
		
				
		if len(id) > 0 then 
			
			newID = id
			
			dbug("id is > 0, so update existing customer")
			
			' update existing customer 
			
			SQL = "update customer set " 		&_
						"customerStatusID = " 	& customerStatusID 		& ", " 	&_
						"nickname = " 				& nickname 					& ", " 	&_
						"updatedBy = " 			& session("userID") 		& ", " 	&_
						"updatedDateTime = CURRENT_TIMESTAMP"				& ", " 	&_
						"validDomains = " 		& validDomains 			& ", " 	&_
						"lsvtCustomerName = " 	& lsvtCustomerName 		& ", " 	&_
						"cProfitURI = " 			& cProfitURI 				& ", " 	&_
						"cProfitAPIKey = " 		& cProfitAPIKey 			& ", " 	&_
						"defaultTimezone = " 	& defaultTimezone 		& " " 	&_
					"where id = " & newID & " " 
						
			msg = "Institutional customer updated"			
			
		else 
			
			dbug("id is 0, so add a new customer...")
			
			' add a new customer...

			' find the cert and rssdid for the institution....
			SQL = "select cert, fed_rssd from fdic.dbo.institutions " &_
					"where name = '" & name & "' " &_
					"and stalp = '" & state & "' " &_
					"and city = '" & city & "' " 
		
			dbug(SQL) 
			
			set rsInst = dataconn.execute(SQL)
			
			if not rsInst.eof then 
				
				cert = rsInst("cert")
				rssdid = rsInst("fed_rssd")
				newID = getNextID("customer") 
				SQL = "insert into customer (id, cert, rssdid, name, nickname, updatedDateTime, updatedBy, customerStatusID, validDomains, lsvtCustomerName, cProfitURI, cProfitAPIKey) " &_
						"values ( " &_
							newID 						& ", " 	&_
							"'" & cert 					& "', " 	&_
							"'" & rssdid 				& "', " 	&_
							"'" & name 					& "', " 	&_
							nickname 					& ", " 	&_
							"CURRENT_TIMESTAMP" 		& ", " 	&_
							session("userID") 		& ", " 	&_
							customerStatusID 			& ", " 	&_ 
							validDomains				& ", " 	&_
							lsvtCustomerName			& ", " 	&_
							cProfitURI					& ", " 	&_
							cProfitAPIKey				& ", " 	&_
							defaultTimezone			& " " 	&_
						") " 

				msg = "Institutional customer added"

			else 
				
				msg = "Error: Inst. not found"
				
			end if

			rsInst.close 
			set rsInst = nothing 
					
			
		end if 
		
		dbug(SQL)
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<cert>" & cert & "</cert>"
		xml = xml & "<rssdid>" & rssdid & "</rssdid>"
		xml = xml & "<name>" & name & "</name>"
		xml = xml & "<customerStatusID>" & customerStatusID & "</customerStatusID>"
		xml = xml & "<validDomains>" & validDomains & "</validDomains>"
		xml = xml & "<lsvtCustomerName><![CDATA[" & lsvtCustomerName & "]]></lsvtCustomerName>"
		xml = xml & "<msg>" & msg & "</msg>"
						
		
			

	'**************************************************************************************************
	case "addNonInstitution"
	'**************************************************************************************************
	
		dbug("addNonInstitution detected")
		
		id							= request.querystring("id")
		name 						= request.querystring("name")
		
		if len(request.querystring("customerStatusID")) > 0 then
			customerStatusID 		= request.querystring("customerStatusID")
		else 
			customerStatusID = "NULL"
		end if
		
		nickname					= request.querystring("customerNickname")

		validDomains 		= request.querystring("validDomains")
		lsvtCustomerName 	= request.querystring("lsvtCustomerName")
		
		if len(id) > 0 then 
			
			dbug("updating an existing non-institution customer...")
			
			newID = id
			
			SQL = "update customer set " &_
						"name = '" & name & "', " &_
						"customerStatusID = " & customerStatusId & ", " &_
						"nickname = '" & nickname & "', " &_
						"validDomains = '" & validDomains & "', " &_
						"lsvtCustomerName = '" & lsvtCustomerName & "', " &_
						"defaultTimezone = " & defaultTimezone & " " &_
					"where id = " & newID & " " 
					
			msg = "Non-institution customer updated"
			runSQL = true
			
		else 

			dbug("add a new non-institution customer...")

			SQL = "select id, deleted, nickname from customer_view where name = '" & name & "' " 
			dbug(SQL)
			
			set rsCust = dataconn.execute(SQL)
			if rsCust.eof then 
			
				newID = getNextID("customer")
				
				SQL = "insert into customer (id, name, nickname, updatedDateTime, updatedBy, customerStatusID, validDomains, lsvtCustomerName, defaultTimezone ) " &_
						"values ( " &_
							newID & ", " &_
							"'" & name & "', " &_
							"'" & nickname & "', " &_
							"CURRENT_TIMESTAMP, " &_
							session("userID") & ", " &_
							customerStatusID & ", " &_
							"'" & validDomains & "', " &_
							"'" & lsvtCustomerName & "', " &_
							lsvtCustomerName & " " &_
						") " 

				msg = "Non-institutional customer added"
				runSQL = true

			else 
				
				newID = rsCust("id")
				
				dbug("customer.deleted: " & rsCust("deleted"))
				if rsCust("deleted") then 
					deleted = "1"
				else 
					deleted = "0"
				end if
				
				dbug("determined that this customer already exists, so not running SQL")
				msg = "Customer already exists"
				runSQL = false 
				
			end if 
			rsCust.close 
			set rsCust = nothing 
							
		end if 

		if runSQL then

			dbug(SQL)
		
			set rsInsert = dataconn.execute(SQL)
			set rsInsert = nothing 
		else 
			
			dbug("SQL NOT RUN: " & SQL)

		end if 

		xml = xml & "<id>" & newID & "</id>"
		xml = xml & "<name><![CDATA[" & name & "]]></name>"
		xml = xml & "<customerStatusID>" & customerStatusID & "</customerStatusID>"
		xml = xml & "<nickname><![CDATA[" & nickname & "]]></nickname>"
		xml = xml & "<deleted>" & deleted & "</deleted>"
		xml = xml & "<msg>" & msg & "</msg>"

		
	
	'**************************************************************************************************
	case "updateCopyUtopia","updateCopyProject","updateCopyKeyInitiatives"
	'**************************************************************************************************
	
		cmd 			= request.querystring("cmd")
		noteTypeID 	= request.querystring("noteTypeID")
		callTypeID 	= request.querystring("callTypeID")
		newState		= request.querystring("newState") 
			
		if cmd = "updateCopyUtopia" then 

			sqlClear = "update noteTypes set utopiaInd = 0 where callTypeID = " & callTypeID & " " 
			dbug(sqlClear)
			set rsClear = dataconn.execute(sqlClear)
			set rsClear = nothing 

			SQL = "update noteTypes set utopiaInd = " & newState & ", keyInitiativeInd = 0, projectInd = 0 where callTypeID = " & callTypeID & " and id = " & noteTypeID & " "
			dbug(SQL)
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing 

			msg = "Copy utopias updated"
			
		elseif cmd = "updateCopyKeyInitiatives" then 

			sqlClear = "update noteTypes set keyInitiativeInd = 0 where callTypeID = " & callTypeID & " " 
			dbug(sqlClear)
			set rsClear = dataconn.execute(sqlClear)
			set rsClear = nothing 

			SQL = "update noteTypes set utopiaInd = 0, keyInitiativeInd = " & newState & ", projectInd = 0 where callTypeID = " & callTypeID & " and id = " & noteTypeID & " "
			dbug(SQL)
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing 

			msg = "Copy key initiatives updated"
			
		else 
			
			sqlClear = "update noteTypes set projectInd = 0 where callTypeID = " & callTypeID & " " 
			dbug(sqlClear)
			set rsClear = dataconn.execute(sqlClear)
			set rsClear = nothing 

			SQL = "update noteTypes set utopiaInd = 0, keyInitiativeInd = 0, projectInd = " & newState & " where callTypeID = " & callTypeID & " and id = " & noteTypeID & " "
			dbug(SQL)
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing 
			
			msg = "Copy projects updated"

		end if 
	
		xml = xml & "<msg>" & msg & "</msg>"
				
	
	
	'**************************************************************************************************
	case "deleteCall"
	'**************************************************************************************************
	
		dbug("deleteCall detected...")
		
		callID = request.querystring("id")
		
		SQL = "update customerCalls set deleted = 1 where id = " & callID & " "	
		
		dbug(SQL)
		
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		msg = "Call deleted"
		xml = xml & "<id>" & callID & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"
	

	'**************************************************************************************************
	case "addKeyInitiative"	
	'**************************************************************************************************
	
		dbug("addKeyInitiative detected...")
		
		id					= request.form("id")
		name 				= replace(replace(request.form("name"), "'", "''"), "&quot;", chr(34))
		description 	= replace(replace(request.form("description"), "'", "''"), "&quot;", chr(34))
		startDate 		= request.form("startDate")
		
		if len(request.form("endDate")) > 0 then 
			endDate 			= "'" & request.form("endDate") & "'" 
		else
			endDate			= "NULL"
		end if 
		
		if len(request.form("completeDate")) > 0 then 
			completeDate 			= "'" & request.form("completeDate") & "'" 
		else
			completeDate			= "NULL"
		end if 
		
		customerID 		= request.form("customerID")
		
		newID = getNextID("keyInitiatives")
		
		if len(id) > 0 then 
			
			SQL = "update keyInitiatives set " &_
						"[name] = '" & name & "', " &_
						"description = '" & description & "', " &_
						"startDate = '" & startDate & "', " &_
						"endDate = " & endDate & ", " &_
						"completeDate = " & completeDate & ", " &_
						"updatedBy = " & session("userID") & ", " &_
						"updatedDateTime = CURRENT_TIMESTAMP, " &_
						"customerID = " & customerID & " " &_
					"where id = " & id & " " 
			
			msg = "Key initiative updated"

		else 

			SQL = "insert into keyInitiatives (id, name, description, startDate, endDate, completeDate, updatedBy, updatedDateTime, customerID) " &_
					"values ( " &_
						newID & ", " &_
						"'" & name & "', " &_
						"'" & description & "', " &_
						"'" & startDate & "', " &_
						endDate & ", " &_
						completeDate & ", " &_
						session("userID") & ", " &_
						"CURRENT_TIMESTAMP, " &_
						customerID & ") " 

			msg = "Key initiative added"
		
		end if
					
		dbug(SQL) 
		
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		
		xml = xml & "<msg>" & msg & "</msg>"		
	
	
	
	'**************************************************************************************************
	case "deleteKeyInitiative"
	'**************************************************************************************************
	
		dbug("deleteKeyInitiative detected...")
		
		id = request.form("id")
		
		SQL = "delete from keyInitiatives where id = " & id & " " 
		
		dbug(SQL)
		
		set rsDeleteKI = dataconn.execute(SQL)
		set rsDeleteKI = nothing 
		
		SQL = "delete from keyInitiativeProjects where keyInitiativeID = " & id & " " 
		
		set rsDeleteKIP = dataconn.execute(SQL)
		set rsDeleteKIP = nothing
		
		SQL = "delete from keyInitiativeTasks where keyInitiativeID = " & id & " " 
		
		set rsDeleteKIT = dataconn.execute(SQL)
		set rsDeleteKIT = nothing
		
		
		msg = "Key initiative deleted"
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"		



	'**************************************************************************************************
	case "addKeyInitiativeProject"
	'**************************************************************************************************
	
		xml = xml & "<addKeyInitiativeProject>"
		
		keyInitiativeID 	= request.form("keyInitiativeID")
		projectID 			= request.form("projectID")
		
		SQL = "insert into keyInitiativeProjects (keyInitiativeID, projectID, updatedBy, updatedDateTime) " &_
				"values ( " &_
				keyInitiativeID & ", " &_
				projectID & ", " &_
				session("userID") & ", " &_
				"CURRENT_TIMESTAMP) " 
				
		dbug(SQL)
		set rsInsert = dataconn.execute(SQL)
		set rsInsert = nothing 
		
		xml = xml & "<msg>Project associated with Key Initiative</msg>"		
	
		xml = xml & "</addKeyInitiativeProject>"
		
		
	'**************************************************************************************************
	case "removeKeyInitiativeProject"
	'**************************************************************************************************
	
		xml = xml & "<removeKeyInitiativeProject>"
		
		keyInitiativeID 	= request.form("keyInitiativeID")
		projectID 			= request.form("projectID")
		customerID			= request.form("customerID")
		
		SQL = "delete from keyInitiativeProjects " &_
				"where keyInitiativeID = " & keyInitiativeID & " " &_
				"and projectID = " & projectID & " "
				
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 

		msg = "Project removed from Key Initiative"
		xml = xml & "<msg>" & msg & "</msg>"		

		xml = xml & "</removeKeyInitiativeProject>"
	
	
		
	'**************************************************************************************************
	case "updateCustomerManager"
	'**************************************************************************************************
	
		dbug("updateCustomerManager detected")

		id 				= request("customerManagerID")
		customerID		= request("customerID")
		userID			= request("userID")
		managerTypeID 	= cInt(request("managerTypeID"))
		startDate 		= request("startDate")
		
		if len(request("startDate")) then 
			startDate 		= "'" & request("startDate") & "'"
		else 
			startDate		= "NULL"
		end if
		
		if len(request("endDate")) then 
			endDate 		= "'" & request("endDate") & "'"
		else 
			endDate		= "NULL"
		end if
		
		if managerTypeID = 0 then 
			' determine if there is an overlapping primary manager...
				
			SQL = "select count(*) as primaryCount " &_
					"from customerManagers " &_
					"where managerTypeID = 0 " &_
					"and customerID = " & customerID & " " &_
					"and ( " &_
						"(" & endDate & ") is not null and  (  " &_
							"startDate >= " & startDate & " and startDate <= " & endDate & " " &_
							"OR " &_
							"(startDate <= " & startDate & " and endDate >= " & startDate & " and endDate <= " & endDate & ") " &_
							"OR " &_
							"(startDate <= " & startDate & " and endDate is null) " &_
						") " &_
						"or (" & endDate & ") is null and ( " &_
							"(startDate >= " & startDate & " and (endDate >= " & startDate & " or endDate is null)) " &_
							"OR " &_
							"(startDate <= " & startDate & " and endDate >= " & startDate & ") " &_
							"OR " &_
							"(startDate <= " & startDate & " and endDate is null) " &_
						") " &_
					") "
						
			
			if len(id) then 
				SQL = SQL & "and id <> " & id & " " 
			end if



			dbug("primary validation: " & SQL)
			set rs = dataconn.execute(SQL) 
			if rs("primaryCount") > 0 then 
				msg = "primary manager will overlap an existing primary manager"
				primaryAllowed = "false"
			else 
				primaryAllowed = "true"
			end if
			rs.close 
			set rs = nothing 
		
		else 

			primaryAllowed = "true"
			
		end if

		if primaryAllowed = "true" then 		
			
			dbug("at this point should allow update of customerManagers...")
			dbug("id=" & id)
			dbug("len(id)=" & len(id))
			
			if len(id) > 0 then 
				SQL = "update customerManagers set " &_
							"managerTypeID = " & managerTypeID & ", " &_
							"startDate = " & startDate & ", " &_
							"endDate = " & endDate & " " &_
						"where id = " & id & " " 
						
				msg = "Customer manager updated"
	
			else 
	
				newID = getNextID("customerManagers")
						
				SQL = "insert into customerManagers (id, customerID, userID, managerTypeID, startDate, endDate, active, updatedBy, updatedDateTime) " &_
						"values ( " &_
							newID & ", " &_
							customerID & ", " &_
							userID & ", " &_
							managerTypeID & ", " &_
							startDate & ", " &_
							endDate & ", " &_
							"1, " &_
							session("userID") & ", " &_
							"CURRENT_TIMESTAMP) " 
							
				msg = "Customer manager added"
	
			end if 
			
			dbug("udpateCustomerManager SQL: " & SQL)
	
			set rsUpdate = dataconn.execute(SQL)
			set rsUpdate = nothing 

		end if			
		 
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<startDate>" & startDate & "</startDate>"
		xml = xml & "<endDate>" & endDate & "</endDate>"
		xml = xml & "<primaryAllowed>" & primaryAllowed & "</primaryAllowed>"		
		xml = xml & "<msg>" & msg & "</msg>"		
		



	'**************************************************************************************************
	case "deleteCustomerManager"
	'**************************************************************************************************
	
		dbug("deleteCustomerManager detected")

		id = request("customerManagerID")
		
		SQL = "delete from customerManagers where id = " & id & " " 
		
		dbug(SQL)
		
		set rsDelete = dataconn.execute(SQL)
		set rsDelete = nothing 
		
		msg = "Customer Manager deleted"
		xml = xml & "<id>" & id & "</id>"
		xml = xml & "<msg>" & msg & "</msg>"		
		


	'**************************************************************************************************
	case "validContactDomain"
	'**************************************************************************************************

		dbug("validContactDomain detected...")
		
		customerID = request.querystring("customerID") 
		contactEmail = request.querystring("contactEmail") 
		
		xml = xml & "<contactEmail>" & contactEmail & "</contactEmail>"		
		xml = xml & "<customerID>" & customerID & "</customerID>"

		if validContactDomain(contactEmail, customerID) then 
			xml = xml & "<isValid>true</isValid>"
		else 
			xml = xml & "<isValid>false</isValid>"
		end if		



	'**************************************************************************************************
	case else 
	'**************************************************************************************************

		dbug("unexpected directive encountered: " & request.querystring("cmd"))


end select 
'**************************************************************************************************
'**************************************************************************************************
'**************************************************************************************************

userLog(msg)
dbug("operation complete")

dataconn.close
set dataconn = nothing
%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</customerMaintenance>"
dbug(xml)
response.write(xml)
%>