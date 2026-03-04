
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../../includes/systemControls.asp" -->
<!-- #include file="../includes/validateDrilldownParameters.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)

response.ContentType = "application/json"
dbug(" ")
dbug("start of accountHolders.asp")

accountHolderSettings = systemControls( "cProfit Account Holder Display Options" )
accountHolderSettings = split( accountHolderSettings, "," )
leadingChars				= accountHolderSettings(0)
trailingChars				= accountHolderSettings(1)
dbug("leadingChars: " & leadingChars & ", trailingChars: " & trailingChars)

'!-- ------------------------------------------------------------------ -->
sub BuildJsonOutput 
'!-- ------------------------------------------------------------------ -->

	dbug("start BuildJsonOutput...")

	if rsAH("target") = "star" then 
		target = "<button class=\""mdl-button mdl-js-button target\"" style=\""font-size:24px;\"">&#128175;</button>"
	else 
		target = "<button class=\""mdl-button mdl-js-button mdl-button--icon target add\""><i class=\""material-icons\"">add</i></button>"
	end if



' 	target = "<button class=\""mdl-button mdl-js-button mdl-button--icon target\""><i class=\""material-icons\"">" & rsAH("target") & "</i></button>"

	if not isNull(rsAH("flagType")) then 
		addenda = "<button class=\""mdl-button mdl-js-button mdl-button--icon flag\""><i class=\""material-icons\"" style=\""color: " & rsAH("flagColor") & "\"" title=\""" & rsAH("flagName") & "\"">flag</i></button>"
	else 
		addenda = "<button class=\""mdl-button mdl-js-button mdl-button--icon flag add\""><i class=\""material-icons\"">add</i></button>"
	end if
	
	if not isNull(rsAH("notePresent")) then 
		note = "<button class=\""mdl-button mdl-js-button mdl-button--icon note\""><i class=\""material-icons\"">notes</i></button>"
	else 
		note = "<button class=\""mdl-button mdl-js-button mdl-button--icon note add\""><i class=\""material-icons\"">add</i></button>"
	end if
	
	accountHolderName = left(rsAH("account holder number"), leadingChars) & "&#133;" & right(rsAH("account holder number"), trailingChars)

	json = json & "{"
	json = json & """DT_RowId"":""" & rsAH("account holder number") & ""","
	json = json & """accountHolderNumber"":""" & accountHolderName & ""","
	json = json & """accountHolderName"":""" & accountHolderName & ""","
	json = json & """target"":""" & target & ""","
	json = json & """addenda"":""" & addenda & ""","
	json = json & """note"":""" & note & ""","
	json = json & """accounts"":""" & rsAH("accounts") & ""","
	json = json & """loans"":""" & rsAH("loans") & ""","
	json = json & """deposits"":""" & rsAH("deposits") & ""","
	json = json & """balance"":""" & rsAH("balance") & ""","
	json = json & """profit"":""" & rsAH("profit") & ""","
	json = json & """grade"":""" & rsAH("grade") & ""","
	json = json & """branch"":""" & rsAH("branch") & ""","
	json = json & """officer"":""" & rsAH("officer") & """"
	json = json & "}"

	dbug("...end BuildJsonOutput")

end sub 


'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->
'!-- ------------------------------------------------------------------ -->


' accountHolderNumberDisplayOptions = systemControl("cProfit Account Holder Display Options")
' displayOptions = split(accountHolderNumberDisplayOptions)
' leadingChars	= displayOptions(0)
' trailingChars	= displayOptions(1)
' dbug("leadingChars: " & leadingChars & ", trailingChars: " & trailingChars)


dt_draw 			= request.form("draw")						' Draw counter
dt_start 		= request.form("start")						' Paging first record indicator
dt_length 		= request.form("length") 					' Number of records that the table can display in the current draw
dt_searchValue = trim(request.form("search[value]"))	' probably not usable in ADO
dt_searchRegex = request.form("search[regex]")			' probably should even try to use on a large dataset




' dbug("dumping form...") 
' for each item in request.form
' 	dbug("..." & item & ": " & request.form(item))
' next 
' dbug(" ")

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
		case 2
			sqlOrderBy = sqlOrderBy & "1 " & sortArray(1,i)
		case 3
			sqlOrderBy = sqlOrderBy & "2 " & sortArray(1,i)
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
		case 11
			sqlOrderBy = sqlOrderBy & "12 " & sortArray(1,i)
		case 12
			sqlOrderBy = sqlOrderBy & "13 " & sortArray(1,i)
	end select 



next 
if len(sqlOrderBy) then 
	sqlOrderBy = "order by " & sqlOrderBy 
end if
limit				= request.form("limit")
direction		= request.form("direction")

dbug("sqlOrderBy: " & sqlOrderBy)

if len(request.form("aoObjects")) > 0 then 
	if lCase(request.form("aoObjects")) = "true" then 
		aoObjects = true 
	else 
		aoObjects = false 
	end if 
else 
	aoObjects = false 
end if 
dbug("aoObjects: " & aoObjects)


SQL = "select " &_
			"archive.[Account Holder Number], " &_
			"case when t.[account holder number] is not null then 'star' else 'star_outline' end as target, " &_
			"x.flagType, " &_
			"x.flagName, " &_
			"x.flagColor, " &_
			"y.flagType as notePresent, " &_
			"count(archive.[Account Holder Number]) as [Accounts], " &_
			"sum(case when [loan deposit other] = 'Loan' then balance else 0 end) as [loans], " &_
			"sum(case when [loan deposit other] = 'Deposit' then balance else 0 end) as [deposits], " &_
			"sum(archive.Balance) as [balance], " &_
			"sum(archive.Profit) as [profit], " &_
			"archive.[Account Holder Grade] as grade, " &_
			"min(archive.[Branch Description]) as Branch, " &_
			"min(archive.[Officer Name]) as Officer " &_
		"from pr_PQwebArchive archive " &_
		allStarJoin &_
		"outer apply ( " &_
			"SELECT top 1 " &_
				"a.[account holder number], " &_
				"a.customerID, " &_
				"a.type as flagType, " &_
				"f.name as flagName, " &_
				"f.priority, " &_
				"f.color as flagColor " &_
			"FROM	pr_accountHolderAddenda a " &_
			"LEFT JOIN flags f ON ( f.id = a.flagID ) " &_
			"where a.customerID = archive.customerID " &_
			"and a.[account holder number] = archive.[account holder number] " &_
			"and a.type = 1 " &_
			"ORDER BY " &_
				"a.type, " &_
				"f.priority " &_
		") as x " &_
		"OUTER apply ( " &_
			"SELECT TOP 1 " &_
				"n.[account holder number], " &_
				"n.customerID, " &_
				"n.type AS flagType " &_
			"FROM pr_accountHolderAddenda n " &_
			"WHERE	n.customerID = archive.customerID " &_
			"AND n.[account holder number] = archive.[account holder number] " &_
			"and n.type = 2 " &_
			"ORDER BY	n.type " &_
		") AS y " &_
		"left join pr_accountHolderAddenda t on (t.[account holder number] = archive.[account holder number] and t.type = 3) " &_
		"where archive.[Account Holder Number] <> '0' " &_
		"and not (archive.[Branch Description] = 'Treasury' OR archive.[Officer Name] = 'Treasury') " &_
		"and not (archive.[Branch Description] = 'Manually Added Accounts') " &_
		"and archive.[Account Holder Number] <> 'Manually Added Accounts' " &_
		"and archive.customerID = " & customerID & " " &_
		centilePredicate &_
		decilePredicate &_
		ninetyNinePredicate &_
		gradePredicate &_
		flagPredicate &_
		branchPredicate &_
		officerPredicate &_
		productPredicate &_
		accountHolderPredicate &_
		"group by " &_
			"archive.[Account Holder Number], " &_
			"case when t.[account holder number] is not null then 'star' else 'star_outline' end, " &_
			"x.flagType, " &_
			"x.flagName, " &_
			"x.flagColor, " &_
			"y.flagType, " &_
			"archive.[Account Holder Grade] " &_
		profitabilityPredicate &_
		sqlOrderBy & " "

dbug(SQL)

json = """data"": ["


set rsAH = server.createObject("ADODB.Recordset")
rsAH.PageSize 			= cInt(dt_length)  	' recordset.PageSize is set to the length requested by the DataTable
rsAH.CursorLocation 	= 3 						' adUseClient  is used to enable server-side pagination
rsAH.open SQL, dataconn

dbug("recordset opened...")
if len(dt_searchValue) > 0 then 
	
	dbug("dt_searchValue: " & dt_searchValue)
	
	searchString = "[account holder number] like '*" & dt_searchValue & "*' OR " &_
						"[grade] like '*" & dt_searchValue & "*' OR " &_
						"[branch] like '*" & dt_searchValue & "*' OR " &_
						"[officer] like '*" & dt_searchValue & "*'" 
						
	dbug("searchString: " & searchString)
	
	rsAH.Filter = searchString
	
else 
	
	dbug("not search term present...")
	
end if 


recordCount = rsAH.RecordCount
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
	if absolutePage > rsAH.PageCount then 
		dbug("absolutePage > rsAH.PageCount...")
		absolutePage = rsAH.PageCount
	end if
end if 
dbug("absolutePage(2): " & absolutePage)

if absolutePage > 0 then 
	rsAH.AbsolutePage = cInt(absolutePage)
	
	dbug("about to build JSON output...")
	filteredRecords = 0
	while not ( rsAH.eof OR rsAH.AbsolutePage <> cInt(absolutePage) ) 
	
		filteredRecords = filteredRecords + 1
	
		BuildJsonOutput
		
		rsAH.movenext 
		
		if not ( rsAH.eof OR rsAH.AbsolutePage <> cInt(absolutePage) ) then json = json & ","
		
	wend
else 
	dbug("no data to return")
end if 

json = json & "]"

json = "{""draw"": " & dt_draw & ", ""recordsTotal"":" & recordCount & ",""recordsFiltered"":" & recordCount & "," & json & "}"

rsAH.close 
set rsAH = nothing 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


