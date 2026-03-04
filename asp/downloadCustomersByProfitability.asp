<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<% 

select case request.querystring("direction")
	case "top"
		sort = "desc"
	case "bottom"
		sort = "asc"
	case else 
		dbug("'direction' parameter missing, degfaulting to 'top' ")
		sort = "desc"
end select 

retrievalLimit = systemControls("Profitability Retrieval Limit")
if retrievalLimit <> "" then 
	limiter = "top " & retrievalLimit & " "
else 
	limiter = ""
end if

limitSQL = "select **limiter** " &_
			"[Account Holder Number], " &_
			"[Total Loans] as [$&nbsp;Loans], " &_
			"[Total Deposits] as [$&nbsp;Deposits], " &_
			"sum(Balance) as [$&nbsp;Balance], " &_
			"sum(Profit) as [$&nbsp;Profit], " &_
			"[Account Holder Grade], " &_
			"[Service Propensity], " &_
			"[Account Type Propensity], " &_
			"case when isDate([DOB]) = 1 then datediff(yy,[DOB],[Process Date]) else null end as Age, " &_
			"min([Branch Description]) as Branch, " &_
			"min([Officer Name]) as Officer, " &_
			"first_name as [First&nbsp;Name], " &_
			"middle_name as [Middle&nbsp;Name], " &_
			"last_name as [Last&nbsp;Name], " &_
			"suffix as Suffix, " &_
			"address_1 as [Address&nbsp;1], " &_
			"address_2 as [Address&nbsp;2], " &_
			"city as City, " &_
			"state as State, " &_
			"zip_Code as [Zip], " &_
			"phone as Phone, " &_
			"[e-mail] as [E-mail] " &_
		"from  pr_PQwebArchive  " &_
		"where [Account Holder Number] <> '0' " &_
		"and [Account Holder Number] <> 'Manually Added Accounts' " &_
		"and customerID = " & customerID & " " &_
		"group by " &_
			"[Account Holder Number], " &_
			"[Total Loans], " &_
			"[Total Deposits], " &_
			"[Account Holder Grade], " &_
			"[Service Propensity], " &_
			"[Account Type Propensity], " &_
			"[Process Date] " &_
		"having sum(Profit) >= 0 " &_
		"order by sum(Profit) **sequence** "

SQL = replace(replace(limitSQL,"**limiter**",limiter),"**sequence**",sort)
dbug(SQL)
set rs = dataconn.execute(SQL)

if not rs.eof then
	
	response.ContentType = "text/csv"
	Response.AddHeader "Content-Disposition", "attachment;filename=profitabilityExport.csv"

	txtDelimiter = """"
	txtSeparator = ","
	
	firstField = true
	for each item in rs.fields 
		if firstField then
			firstField = false
		else
			response.write(txtSeparator)
		end if
		response.write(txtDelimiter & item.name & txtDelimiter)
	next
	response.write(vbCrLf)
	
	while not rs.eof
		firstField = true
		for each item in rs.fields
			if firstField then
				firstField = false
			else
				response.write(txtSeparator)
			end if
			select case item.type
				case adCurrency, adDouble, adSmallInt, adBigInt, adDecimal, adInteger, adNumeric, adSingle, adTinyInt, adUnsignedBigInt, adUnsignedInt, adUnsignedSmallInt, adUnsignedTinyInt, adVarnumeric
					txtDelimiter = ""
				case else 
					txtDelimiter = """"
			end select
			response.write(txtDelimiter & item.value & txtDelimiter)
		next
		response.write(vbCrLf)
		rs.movenext
	wend
	
	rs.close
	set rs = nothing
	
else
	
	response.write("nothing to extract")
	
end if
	

dataconn.close
set dataconn = nothing

%>