
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)


response.ContentType = "application/json"
dbug("start of prospects.asp")


customerID 		= request("customerID")
if isEmpty(customerID) then 
	json = "{""error"":""CustomerID is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if not isNumeric(customerID) then 
		json = "{""error"":""CustomerID is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		dbug("customerID: " & customerID)
		customerPredicate = "WHERE customerID = " & customerID & " " 
	end if
end if 
	

SQL = "select " &_
			"id, " &_
			"businessName, " &_
			"industry, " &_
			"firstName, " &_
			"middleName, " &_
			"lastName, " &_
			"address1, " &_
			"address2, " &_
			"city, " &_
			"state, " &_
			"zip, " &_
			"phone, " &_
			"email, " &_
			"top100Ind, " &_
			"[account holder number], " &_
			"format(give1Date, 'M/d/yyyy') as give1Date, " &_
			"format(give2Date, 'M/d/yyyy') as give2Date, " &_
			"format(give3Date, 'M/d/yyyy') as give3Date, " &_
			"handraiseInd, " &_
			"call1Ind, " &_
			"meeting1Scheduled, " &_
			"meeting1Completed, " &_
			"ace1, " &_
			"ace2, " &_
			"ace3, " &_
			"ace4, " &_
			"ace5, " &_
			"meeting2Scheduled, " &_
			"dealPotential, " &_
			"dealClosedInd, " &_
			"dealValue, " &_
			"crossSalesCount " &_
		"from customerProspects " &_
		customerPredicate
		
dbug(SQL)

json = "{""data"": ["

set rsProspects = dataconn.execute(SQL)

while not rsProspects.eof

	if rsProspects("handraiseInd") then 
		handraiseInd = "<i class=\""material-icons\"">pan_tool</i>"
	else 
		handraiseInd = ""
	end if

	if rsProspects("call1Ind") then 
		call1Ind = "<i class=\""material-icons\"">check</i>"
	else 
		call1Ind = ""
	end if

	if rsProspects("meeting1Scheduled") then 
		meeting1Scheduled = "<i class=\""material-icons\"">insert_invitation</i>"
	else 
		meeting1Scheduled = ""
	end if

	if rsProspects("meeting1Completed") then 
		meeting1Completed = "<i class=\""material-icons\"">event_available</i>"
	else 
		meeting1Completed = ""
	end if

	if rsProspects("ace1") then 
		ace1 = "<i class=\""material-icons\"">check</i>"
	else 
		ace1 = ""
	end if

	if rsProspects("ace2") then 
		ace2 = "<i class=\""material-icons\"">check</i>"
	else 
		ace2 = ""
	end if

	if rsProspects("ace3") then 
		ace3 = "<i class=\""material-icons\"">check</i>"
	else 
		ace3 = ""
	end if

	if rsProspects("ace4") then 
		ace4 = "<i class=\""material-icons\"">check</i>"
	else 
		ace4 = ""
	end if

	if rsProspects("ace5") then 
		ace5 = "<i class=\""material-icons\"">check</i>"
	else 
		ace5 = ""
	end if

	if rsProspects("meeting2Scheduled") then 
		meeting2Scheduled = "<i class=\""material-icons\"">event_available</i>"
	else 
		meeting2Scheduled = ""
	end if

	if rsProspects("dealClosedInd") then 
		dealClosedInd = "<i class=\""material-icons\"">check</i>"
	else 
		dealClosedInd = ""
	end if


	if rsProspects("top100Ind") then 
		top100Ind = "<span style=\""font-size:24px;\"">&#128175;</span>"
	else 
		top100Ind = ""
	end if
	
	if rsProspects("ace1") then 
		if rsProspects("ace2") then 
			if rsProspects("ace3") then 
				if rsProspects("ace4") then 
					if rsProspects("ace5") then 
						funnelWeight = 1.00
						weightedWeight = 1.00
					else 
						funnelWeight = 0.80
						weightedWeight = 0.80
					end if 
				else 
					funnelWeight = 0.60
					weightedWeight = 0.60
				end if 
			else 
				funnelWeight = 0.40
				weightedWeight = 0.00
			end if 
		else 
			funnelWeight = 0.20
			weightedWeight = 0.00
		end if 
	else 
		funnelWeight = 0.00
		weightedWeight = 0.00
	end if
	
	if rsProspects("dealClosedInd") then
		funnelAmount = ""
		weightedFunnelAmount = ""
	else 
		if not isNull(rsProspects("dealPotential")) then 
			funnelAmount = cCur(rsProspects("dealPotential")) * funnelWeight
			weightedFunnelAmount = cCur(rsProspects("dealPotential")) * weightedWeight
		else 
			funnelAmount = ""
			weightedFunnelAmount = ""
		end if 
	end if 
	
	fullName = rsProspects("lastName") 
	if len(rsProspects("firstName")) then 
		fullName = fullName & ", " & rsProspects("firstName")
		if len(rsProspects("middleName")) then 
			fullName = fullName & " " & rsProspects("middleName") 
		end if 
	end if 


	json = json & "{"
	json = json & """DT_RowId"":""" & rsProspects("id") & ""","
	json = json & """businessName"":""" & rsProspects("businessName") & ""","
	json = json & """industry"":""" & rsProspects("industry") & ""","
	json = json & """firstName"":""" & rsProspects("firstName") & ""","
	json = json & """middleName"":""" & rsProspects("middleName") & ""","
	json = json & """lastName"":""" & rsProspects("lastName") & ""","
	json = json & """fullName"":""" & fullName & ""","
	json = json & """address1"":""" & rsProspects("address1") & ""","
	json = json & """address2"":""" & rsProspects("address2") & ""","
	json = json & """city"":""" & rsProspects("city") & ""","
	json = json & """state"":""" & rsProspects("state") & ""","
	json = json & """zip"":""" & rsProspects("zip") & ""","
	json = json & """phone"":""" & rsProspects("phone") & ""","
	json = json & """email"":""" & rsProspects("email") & ""","
	json = json & """top100Ind"":""" & top100Ind & ""","
	json = json & """accountHolderNumber"":""" & rsProspects("account holder number") & ""","
	json = json & """give1Date"":""" & rsProspects("give1Date") & ""","
	json = json & """give2Date"":""" & rsProspects("give2Date") & ""","
	json = json & """give3Date"":""" & rsProspects("give3Date") & ""","
	json = json & """handraiseInd"":""" & handraiseInd & ""","
	json = json & """call1Ind"":""" & call1Ind & ""","
	json = json & """meeting1Scheduled"":""" & meeting1Scheduled & ""","
	json = json & """meeting1Completed"":""" & meeting1Completed & ""","
	json = json & """ace1"":""" & ace1 & ""","
	json = json & """ace2"":""" & ace2 & ""","
	json = json & """ace3"":""" & ace3 & ""","
	json = json & """ace4"":""" & ace4 & ""","
	json = json & """ace5"":""" & ace5 & ""","
	json = json & """dealPotential"":""" & rsProspects("dealPotential") & ""","
	json = json & """dealClosedInd"":""" & dealClosedInd & ""","
	json = json & """dealValue"":""" & rsProspects("dealValue") & ""","
	json = json & """crossSalesCount"":""" & rsProspects("crossSalesCount") & ""","
	json = json & """funnelAmount"":""" & funnelAmount & ""","
	json = json & """weightedFunnelAmount"":""" & weightedFunnelAmount & """"
	json = json & "}"
	
	rsProspects.movenext 
	
	if not rsProspects.eof then json = json & ","
	
wend


json = json & "]}"

rsProspects.close 
set rsProspects = nothing 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


