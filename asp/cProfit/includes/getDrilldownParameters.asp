<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

subtitle = ""
// CENTILE...
if len(request.querystring("centile")) > 0 then 
	dbug("centile present in querystring...")
	centile = request.querystring("centile") 
	if isNumeric(centile) then 
		if cInt(centile) = 0 then 
			dbug("centile in querystring is zero; not included in the SQL predicate")
			centile = "null"
		else 
			subtitle = "Centile = " & centile
		end if
	else 
		dbug("centile in querystring is not numeric; not included in SQL predicate")
		centile = "null"
	end if 
else 
	centile = "null"
end if 
dbug("centile: " & centile)


// DECILE...
if len(request.querystring("decile")) > 0 then 
	dbug("decile present in querystring...")
	decile = request.querystring("decile") 
	if isNumeric(decile) then 
		if cInt(decile) = 0 then 
			dbug("decile in querystring is zero; not included in the SQL predicate")
			decile = "null"
		else 
			if len(subtitle) > 0 then subtitle = subtitle & "<br>"
			subtitle = subtitle & "Decile = " & decile 
		end if
	else 
		dbug("decile in querystring is not numeric; not included in SQL predicate")
		decile = "null"
	end if 
else 
	decile = "null"
end if 
dbug("decile: " & decile)


// NINETYNINE...
if len(request.querystring("ninetyNine")) > 0 then 
	dbug("ninetyNine present in querystring...") 
	if IsNumeric(request.querystring("ninetyNine")) then 
		if ( cInt(request.querystring("ninetyNine")) = 1 or cInt(request.querystring("ninetyNine")) = 99 ) then 
			ninetyNine = cInt(request.querystring("ninetyNine")) 
			if ninetyNine = 1 then 
				subsubtitle = "Top 1% Account Holders"
			else 
				subsubTitle = "Bottom 99% Account Holders" 
			end if 
			if len(subtitle) > 0 then subtitle = subtitle & "<br>"
			subtitle = subtitle & subsubTitle
		else 
			dbug("ninetyNine in querystring is not valid; not included in SQL predicate")
			ninetyNine = "null" 
		end if 
	else 
		dbug("ninetyNine in querystring is not valid; not included in SQL predicate (1)")
	end if 
else 
	ninetyNine = "null"
end if 
dbug("ninetyNine: " & ninetyNine)


// PROFITABILITY...
if len(request.querystring("profitability")) > 0 then 
	dbug("profitability present in querystring...") 
	if ( request.querystring("profitability") = "profitable" or request.querystring("profitability") = "unprofitable") then 
		profitability = "'" & request.querystring("profitability") & "'"
		if profitability = "'profitable'" then 
			subsubTitle = "Profitable Account Holders"
		else 
			subsubTitle = "Unprofitable Account Holders" 
		end if
		if len(subtitle) > 0 then subtitle = subtitle & "<br>"
		subtitle = subtitle & subsubTitle
	else 
		dbug("Profitability in querystring is not valid; not included in SQL predicate")
		profitability = "null" 
	end if 
else 
	profitability = "null"
end if 
dbug("profitability: " & profitability)


// GRADE...
if len(request.querystring("grade")) > 0 then 
	dbug("grade present in querystring...")
	accountHolderGrade = "'" & request.querystring("grade") & "'"
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "Account Holder Grade = " & accountHolderGrade
else 
	accountHolderGrade = "null"
end if
dbug("accountHolderGrade: " & accountHolderGrade) 


// FLAG...
if len(request.querystring("flagID")) > 0 then 
	dbug("flagID present in querystring...") 
	flagID = request.querystring("flagID") 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "By Requested Flag"
else 
	flagID = "null" 
end if 
dbug("flagID: " & flagID)


// ALL STAR...
if len(request.querystring("allStar")) > 0 then 
	dbug("allStar present in querystring...")
	allStar = "'" & request.querystring("allStar") & "'"
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "Top 100&trade; Account Holders"
else 
	allStar = "null"
end if
dbug("allStar: " & allStar)


// Service...
if len(request.querystring("service")) > 0 then 
	dbug("serivce present in querystring...") 
	service = "'" & request.querystring("service") & "'" 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "Service = " & service
else 
	service = "null" 
end if 
dbug("service: " & service)


// Account...
if len(request.querystring("account")) > 0 then 
	dbug("account present in querystring...") 
	account = "'" & request.querystring("account") & "'" 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "By Selected Account"
else 
	account = "null" 
end if 
dbug("account: " & account)


// Account Holder...
if len(request.querystring("accountHolder")) > 0 then 
	dbug("accountHolder present in querystring...") 
	accountHolder = "'" & request.querystring("accountHolder") & "'" 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "By Selected Account Holder"
else 
	accountHolder = "null" 
end if 
dbug("accountHolder: " & accountHolder)


// Branch
if len(request.querystring("branch")) > 0 then 
	dbug("branch present in querystring...") 
	branch = "'" & request.querystring("branch") & "'" 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "Branch = " & branch
else 
	branch = "null" 
end if 
dbug("branch: " & branch)


// Officer...
if len(request.querystring("officer")) > 0 then 
	dbug("officer present in querystring...") 
	officer = "'" & request.querystring("officer") & "'" 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"
	subtitle = subtitle & "Officer = " & officer
else 
	officer = "null" 
end if 
dbug("officer: " & officer)


// Product...
if len(request.querystring("product")) > 0 then 
	dbug("product present in querystring...") 
	product = "'" & request.querystring("product") & "'" 
	if len(subtitle) > 0 then subtitle = subtitle & "<br>"

	SQL = "select top 1 [product description] from pr_PQWebArchive where [product code] = " & product & " " 
	dbug(SQL)
	set rsProd = dataconn.execute(SQL) 
	if not rsProd.eof then 
		subtitle = subtitle & "Product = " & product & " - " & rsProd("product description") 
	else 
		subtitle = subtitle & "Product = " & product
	end if 
	rsProd.close 
	set rsProd = nothing 
else 
	product = "null" 
end if 
dbug("product: " & product)

%>