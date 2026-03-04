<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

customerID 		= request("customerID")
centile			= request("centile") 
decile			= request("decile") 
ninetyNine		= request("ninetyNine") 
profitability 	= request("profitability")
grade				= uCase(request("accountHolderGrade"))
flagID			= request("flagID") 
allStar			= request("allStar")
service			= request("service")

account			= request("account") 
accountHolder	= request("accountHolder") 
branch			= request("branch") 
officer			= request("officer") 
product			= request("product") 

if len(customerID) <= 0 then 
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
	end if
end if			

if len(decile) > 0 then 
	
	if not isNumeric(decile) then 
		json = "{""error"":""decile is not valid (1)""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		if ( cInt(decile) <= 0 or cInt(decile) > 100 ) then 
			json = "{""error"":""decile is not valid (2)""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if 
	end if 
	
	decilePredicate = "and ( decile = " & decile & " ) " 

else 
	
	decilePredicate = "" 
	
end if 
dbug("decilePredicate: " & decilePredicate)
	
	
if len(centile) > 0 then 
	
	if not isNumeric(centile) then 
		json = "{""error"":""centile is not valid (1)""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		if ( cInt(centile) <= 0 or cInt(centile) > 100 ) then 
			json = "{""error"":""centile is not valid (2)""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if 
	end if 
	
	centilePredicate = "and ( centile = " & centile & " ) " 

else 
	
	centilePredicate = "" 
	
end if 
dbug("centilePredicate: " & centilePredicate)
	
	
if len(ninetyNine) > 0 then  
	dbug("len(ninetyNine > 0")
	
	if not isNumeric(ninetyNine) then 
		dbug("ninetyNine is NOT numeric")
		json = "{""error"":""ninetyNine is not valid (1)""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		dbug("ninetyNine is numeric")
		if cInt(ninetyNine) = 1 then 
			ninetyNinePredicate = "and ( centile = 1 ) " 
		elseif cInt(ninetyNine = 99) then 
			ninetyNinePredicate = "and ( centile between 2 and 100 ) " 
		else 
			dbug("ninetyNine not 1 or 99")
			json = "{""error"":""ninetyNine is not valid (2)""}"
			response.status = "400 Bad Request"
			response.write json
			response.end()
		end if 
	end if 
	
else 
	
	ninetyNinePredicate = "" 
	
end if 
dbug("ninetyNinePredicate: " & ninetyNinePredicate)
	

if len(flagID) > 0 then 
	dbug("len(flagID) > 0")
	
	if not isNumeric(flagID) then 
		dbug("flagID is NOT numeric") 
		json = "{""error"":""flagID is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	else 
		flagPredicate = "and exists (select * from pr_accountHolderAddenda j where j.[account holder number] = archive.[account holder number] and type = 1 and flagID = " & flagID & ") " 
	end if 
else 
	flagPredicate = "" 
end if 


if len(profitability) > 0 then 
	if profitability = "profitable" then 
		profitabilityPredicate = "HAVING sum(archive.Profit) > 0 "
	elseif profitability = "unprofitable" then 
		profitabilityPredicate = "HAVING sum(archive.Profit) <= 0 "
	else 
		profitabilityPredicate = ""
	end if 
else 
	profitabilityPredicate = ""
end if 		
dbug("profitabilityPredicate: " & profitabilityPredicate)
	
	
if len(grade) > 0 then 
	dbug("uCase('grade'): " & uCase(grade))
	if (uCase(grade) = "A" OR uCase(grade) = "B" OR uCase(grade) = "C" OR uCase(grade) = "D") then 
		gradePredicate = "and archive.[Account Holder Grade] = '" & uCase(grade) & "' " 
	else 
		gradePredicate = ""
	end if 
else 
	gradePredicate = "" 
end if 


dbug("allStar: " & allStar)
' dbug("isEmpty(allStar): " isEmpty(allStar))
if len(allStar) > 0 then 
	allStarJoin = "join pr_accountHolderAddenda yy on (yy.customerID = archive.customerID AND yy.[account holder number] = archive.[account holder number] AND yy.type = 3) "
else 
	allStartJoin = ""
end if		


dbug("service: " & service)
if len(service) > 0 then 
	servicePredicate = "and archive.[service] = '" & service & "' " 
else 
	servicePredicate	 = "" 
end if 



dbug("account: " & account)
if len(account) > 0 then 
	accountPredicate = "and archive.[account number] = '" & account & "' " 
else 
	accountPredicate = "" 
end if 

dbug("accountHolder: " & accountHolder)
if len(accountHolder) > 0 then 
	accountHolderPredicate = "and archive.[account holder number] = '" & accountHolder & "' " 
else 
	accountHolderPredicate = "" 
end if 

dbug("branch: " & branch)
if len(branch) > 0 then 
	branchPredicate = "and archive.[branch description] = '" & branch & "' " 
else 
	branchPredicate = "" 
end if 

dbug("officer: " & officer)
if len(officer) > 0 then 
	officerPredicate = "and archive.[officer name] = '" & officer & "' " 
else 
	officerPredicate = "" 
end if 

dbug("product: " & product)
if len(product) > 0 then 
	productPredicate = "and archive.[product code] = '" & product & "' " 
else 
	productPredicate = "" 
end if 

%>