
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../includes/validateDrilldownParameters.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug("start of accounts.asp")


dt_draw 			= request.form("draw")						' Draw counter
dt_start 		= request.form("start")						' Paging first record indicator
dt_length 		= request.form("length") 					' Number of records that the table can display in the current draw
dt_searchValue = trim(request.form("search[value]"))	' probably not usable in ADO
dt_searchRegex = request.form("search[regex]")			' probably should even try to use on a large dataset

dim sortArray 
redim sortArray(2,0)

dbug("building serverSide orderBy...")
for each item in request.form 
	if left(item,5) = "order" then
		
		dbug("order found in request.form:" & item & ": " & request.form(item))
				
		indexStart = cInt(inStr(item, "[") + 1)
		indexLength = cInt(inStr(item, "]") - indexStart)

		columnStart = cInt(inStrRev(item, "[") + 1)
		columnLength = cInt(inStrRev(item, "]") - columnStart)

		index = cInt(mid(item,indexStart,indexLength))
		dbug("index: " & index)

		columnName = mid(item,columnStart,columnLength)
		dbug("columnName: " & columnName)


		dbug("just before redim")
		redim preserve sortArray(2,index)
		dbug("just after redim")

		dbug("uBound(sortArray,1): " & uBound(sortArray,1))
		dbug("uBound(sortArray,2): " & uBound(sortArray,2))

		if columnName = "column" then 
			sortArray(0,index) = request.form(item)
			dbug("sortArray(0," & i & "): " & sortArray(0,i))
		end if 
		if columnName = "dir" then 
			sortArray(1,index) = request.form(item)
			dbug("sortArray(1," & i & "): " & sortArray(1,i))
		end if
	end if 
next 

sqlOrderBy = ""
for i = 0 to uBound(sortArray,2) 
	
	dbug("sortArray ==> (0," & i & "): " & sortArray(0,i) & ", (1," & i & "): " & sortArray(1,i))
	
	if len(sqlOrderBy) then 
		sqlOrderBy = sqlOrderBy & ", "
	end if 

	select case sortArray(0,i)
		case 1
			sqlOrderBy = sqlOrderBy & "2 " & sortArray(1,i)
		case 2
			sqlOrderBy = sqlOrderBy & "3 " & sortArray(1,i)
		case 3
			sqlOrderBy = sqlOrderBy & "4 " & sortArray(1,i)
		case 4
			sqlOrderBy = sqlOrderBy & "5 " & sortArray(1,i)
		case 5
			sqlOrderBy = sqlOrderBy & "6 " & sortArray(1,i)
		case 6
			sqlOrderBy = sqlOrderBy & "7 " & sortArray(1,i)
		case 7
			sqlOrderBy = sqlOrderBy & "8 " & sortArray(1,i)
		case 8
			sqlOrderBy = sqlOrderBy & "9 " & sortArray(1,i)
		case 9
			sqlOrderBy = sqlOrderBy & "10 " & sortArray(1,i)
		case 10
			sqlOrderBy = sqlOrderBy & "11 " & sortArray(1,i)
	end select 



next 
if len(sqlOrderBy) then 
	sqlOrderBy = "order by " & sqlOrderBy 
end if
limit				= request.form("limit")
direction		= request.form("direction")

dbug("sqlOrderBy: " & sqlOrderBy)


		


SQL = "select " &_
			"[account number], " &_
			"profit, " &_
			"balance, " &_
			"[interest rate], " &_
			"[open date], " &_
			"[ftp rate], " &_
			"[Net Interest Income], " &_
			"[Non-interest Income], " &_
			"[Non-interest Expense], " &_
			"[Incremental Non-interest Expense] " &_
		"from pr_PQwebArchive archive  " &_
		"where [Account Holder Number] <> '0' " &_
		"and not ([Branch Description] = 'Treasury' OR [Officer Name] = 'Treasury') " &_
		"and not ([Branch Description] = 'Manually Added Accounts') " &_
		"and [Account Holder Number] <> 'Manually Added Accounts' " &_
		"and archive.customerID = " & customerID & " " &_
		centilePredicate &_
		decilePredicate &_
		ninetyNinePredicate &_
		gradePredicate &_
		flagPredicate &_
		branchPredicate &_
		servicePredicate &_
		officerPredicate &_
		productPredicate &_
		accountHolderPredicate &_
		sqlOrderBy

dbug(SQL)

json = """data"": ["

set rsAccts = server.createObject("ADODB.Recordset")
rsAccts.PageSize 			= cInt(dt_length)  	' recordset.PageSize is set to the length requested by the DataTable
rsAccts.CursorLocation 	= 3 						' adUseClient  is used to enable server-side pagination
rsAccts.open SQL, dataconn

dbug("recordset opened...")
if len(dt_searchValue) > 0 then 
	
	dbug("dt_searchValue: " & dt_searchValue)
	
	searchString = "[account holder number] like '*" & dt_searchValue & "*' OR " &_
						"[grade] like '*" & dt_searchValue & "*' OR " &_
						"[branch] like '*" & dt_searchValue & "*' OR " &_
						"[officer] like '*" & dt_searchValue & "*'" 
						
	dbug("searchString: " & searchString)
	
	rsAccts.Filter = searchString
	
else 
	
	dbug("no search term present...")
	
end if 

recordCount = rsAccts.RecordCount
dbug("recordCount: " & recordCount)
dbug("dt_start: " & dt_start)
dbug("dt_length: " & dt_length)

absolutePage = (cInt(dt_start) \ cInt(dt_length)) + 1 	' add +1 becaue DataTables are 0-based and ADO is 1-based

dbug("absolutePage(1): " & absolutePage)

if absolutePage <= 0 then 
	dbug("absolutePage <= 0...")
	absolutePage = 1
else
	dbug("absolutePage > 0...")
	if absolutePage > rsAccts.PageCount then 
		dbug("absolutePage > rsAccts.PageCount...")
		absolutePage = rsAccts.PageCount
	end if
end if 
dbug("absolutePage(2): " & absolutePage)

if absolutePage > 0 then 
	rsAccts.AbsolutePage = cInt(absolutePage)
	
	dbug("about to build JSON output...")
	filteredRecords = 0
	while not ( rsAccts.eof OR rsAccts.AbsolutePage <> cInt(absolutePage) ) 
	
		filteredRecords = filteredRecords + 1
	
		json = json & "{"
		json = json & """DT_RowId"":""" & rsAccts("account number") & ""","
		json = json & """accountNumber"":""" & rsAccts("account number") & ""","
		json = json & """profit"":""" & rsAccts("profit") & ""","
		json = json & """balance"":""" & rsAccts("balance") & ""","
		json = json & """interestRate"":""" & formatPercent(rsAccts("interest rate")/100,4) & ""","
		json = json & """openDate"":""" & rsAccts("open date") & ""","
		json = json & """ftpRate"":""" & formatPercent(rsAccts("ftp rate")/100,4) & ""","
		json = json & """netInterestIncome"":""" & rsAccts("Net Interest Income") & ""","
		json = json & """nonInterestIncome"":""" & rsAccts("Non-interest Income") & ""","
		json = json & """nonInterestExpense"":""" & rsAccts("Non-interest Expense") & ""","
		json = json & """incNonInterestExpense"":""" & rsAccts("Incremental Non-interest Expense") & """"
		json = json & "}"
		
		rsAccts.movenext 
		
		if not ( rsAccts.eof OR rsAccts.AbsolutePage <> cInt(absolutePage) ) then json = json & ","
		
	wend
else 
	dbug("no data to return")
end if 

json = json & "]"

json = "{""draw"": " & dt_draw & ", ""recordsTotal"":" & recordCount & ",""recordsFiltered"":" & recordCount & "," & json & "}"

dbug(json)

rsAccts.close 
set rsAccts = nothing 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


