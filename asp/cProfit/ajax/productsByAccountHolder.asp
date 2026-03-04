
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

customerID 				= request.querystring("customerID")
accountHolderNumber	= request.querystring("accountHolderNumber")

if len(request.querystring("aoObjects")) > 0 then 
	if lCase(request.querystring("aoObjects")) = "true" then 
		aoObjects = true 
	else 
		aoObjects = false 
	end if 
else 
	aoObjects = true 
end if 


if len(accountHolderNumber) <= 0 then 
	json = "{""error"":""accountHolderNumber is not present""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
else 
	if len(accountHolderNumber) <> 64 then 
		json = "{""error"":""accountHolderNumber is not valid""}"
		response.status = "400 Bad Request"
		response.write json
		response.end()
	end if
end if			
		


json = "{"

SQL = "SELECT DISTINCT " &_
			"pr_pqwebarchive.[Loan Deposit Other], " &_
			"pr_pqwebarchive.[Product Code], " &_
			"pr_pqwebarchive.[Product Description], " &_
			"x.numberOfAccounts, " &_
			"x.totalProfit, " &_
			"x.totalBalance, " &_
			"x.netInterestIncome, " &_
			"x.nonInterestIncome, " &_
			"x.nonInterestExpense, " &_
			"x.incNonInterestExpense " &_
		"FROM pr_pqwebarchive " &_
		"LEFT JOIN ( " &_
			"SELECT " &_
				"[Product Code], " &_
				"[Product Description], " &_
				"COUNT ( DISTINCT [account number] ) AS numberOfAccounts, " &_
				"SUM ( profit ) AS totalProfit, " &_
				"SUM ( balance ) AS totalBalance, " &_
				"SUM ( [net interest income] ) AS netInterestIncome, " &_
				"SUM ( [non-interest income] ) AS nonInterestIncome, " &_
				"SUM ( [non-interest expense] ) AS nonInterestExpense, " &_
				"SUM ( [incremental non-interest expense] ) AS incNonInterestExpense " &_
			"FROM pr_pqwebarchive " &_
			"WHERE [account holder number] = '"& accountHolderNumber & "' " &_
			"AND customerID = " & customerID & " " &_
			"GROUP BY " &_
				"[Product Code], " &_
				"[Product Description] " &_
			") AS x ON ( x.[Product Code] = pr_pqwebarchive.[Product Code] ) " &_
		"WHERE " &_
			"pr_pqwebarchive.[Account Holder Number] <> '0' " &_
		"ORDER BY " &_
			"1, " &_
			"2 "

dbug(SQL)

set rsProd = dataconn.execute(SQL) 

json = json & """data"": ["
while not rsProd.eof 


	if aoObjects then 
		

		json = json & "{"
		json = json & """DT_RowId"":""" & rsProd("product code") & ""","
		json = json & """ldo"":""" & rsProd("loan deposit other") & ""","
		json = json & """productCode"":""" & rsProd("product code") & ""","
		json = json & """productDescription"":""" & rsProd("product description") & ""","
		json = json & """accounts"":""" & rsProd("numberOfAccounts") & ""","
		json = json & """profit"":""" & rsProd("totalProfit") & ""","
		json = json & """balance"":""" & rsProd("totalBalance") & ""","
		json = json & """netInterestIncome"":""" & rsProd("netInterestIncome") & ""","
		json = json & """nonInterestIncome"":""" & rsProd("nonInterestIncome") & ""","
		json = json & """nonInterestExpense"":""" & rsProd("nonInterestExpense") & """"
		json = json & "}"

	else 

		json = json & "["
		json = json & """" & rsProd("product code") & ""","
		json = json & """" & rsProd("loan deposit other") & ""","
		json = json & """" & rsProd("product code") & ""","
		json = json & """" & rsProd("product description") & ""","
		json = json & """" & rsProd("numberOfAccounts") & ""","
		json = json & """" & rsProd("totalProfit") & ""","
		json = json & """" & rsProd("totalBalance") & ""","
		json = json & """" & rsProd("netInterestIncome") & ""","
		json = json & """" & rsProd("nonInterestIncome") & ""","
		json = json & """" & rsProd("nonInterestExpense") & """"
		json = json & "]"

	end if 
	
	rsProd.movenext 
	
	if not rsProd.eof then json = json & ","
	
wend
json = json & "]"


rsProd.close 
set rsProd = nothing 

json = json & "}"

dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


