
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
dbug("start of officers.asp")
	

SQL = "select " &_
			"[officer name], " &_
			"sum(loanCount) 		as loanCount, " &_
			"sum(loanBalance) 	as loanBalance, " &_
			"sum(loanProfit) 		as loanProfit, " &_
			"case when sum(loanBalance) <> 0 then sum(loanInterest) / sum(loanBalance) / 100 else 0 end as loanInterest, " &_
			"sum(depositCount) 	as depositCount, " &_
			"sum(depositBalance) as depositBalance, " &_
			"sum(depositProfit) 	as depositProfit, " &_
			"case when sum(depositBalance) <> 0 then sum(depositInterest) / sum(depositBalance) / 100 else 0 end as depositInterest, " &_
			"sum(otherCount) 		as otherCount, " &_
			"sum(otherBalance) 	as otherBalance, " &_
			"sum(otherProfit) 	as otherProfit, " &_
			"case when sum(otherBalance) <> 0 then sum(otherInterest) / sum(otherBalance) / 100 else 0 end as otherInterest, " &_
			"sum(loanCount) + sum(depositCount) + sum(otherCount) as totalCount, " &_
			"sum(loanBalance) + sum(depositBalance) + sum(otherBalance) as totalBalance, " &_
			"sum(loanProfit) + sum(depositProfit) + sum(otherProfit) as totalProfit " &_
		"from ( " &_
			"select " &_
				"[officer name], " &_
				"case when [loan deposit other] = 'Loan' 		then 1 									else 0 end as loanCount, " &_
				"case when [loan deposit other] = 'Loan' 		then balance							else 0 end as loanBalance, " &_
				"case when [loan deposit other] = 'Loan' 		then profit								else 0 end as loanProfit, " &_
				"case when [loan deposit other] = 'Loan' 		then [interest rate x balance] 	else 0 end as loanInterest, " &_
				"case when [loan deposit other] = 'Deposit' 	then 1 									else 0 end as depositCount, " &_
				"case when [loan deposit other] = 'Deposit' 	then balance							else 0 end as depositBalance, " &_
				"case when [loan deposit other] = 'Deposit' 	then profit								else 0 end as depositProfit, " &_
				"case when [loan deposit other] = 'Deposit' 	then [interest rate x balance] 	else 0 end as depositInterest, " &_
				"case when [loan deposit other] = 'Other' 	then 1 									else 0 end as otherCount, " &_
				"case when [loan deposit other] = 'Other' 	then balance							else 0 end as otherBalance, " &_
				"case when [loan deposit other] = 'Other' 	then profit								else 0 end as otherProfit, " &_
				"case when [loan deposit other] = 'Other' 	then [interest rate x balance] 	else 0 end as otherInterest " &_
			"from pr_pqwebarchive archive " &_
			"where [Account Holder Number] not in ('0','Manually Added Accounts') " &_
			"and [Branch Description] <> 'Treasury' " &_
			"and [Officer Name] <> 'Treasury' " &_
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
			") as x " &_
		"group by [officer name] "
		



dbug(SQL)

json = "{""data"": ["

set rsOff = dataconn.execute(SQL)

while not rsOff.eof

	totalCount = rsOff("loanCount") + rsOff("depositCount") + rsOff("otherCount")
	totaBalance = rsOff("loanBalance") + rsOff("depositBalance") + rsOff("otherBalance")
	totalProfit = rsOff("loanProfit") + rsOff("depositProfit") + rsOff("otherProfit")

	json = json & "{"
	json = json & """DT_RowId"":""" & rsOff("officer name") & ""","
	json = json & """officerName"":""" & rsOff("officer name") & ""","
	json = json & """loanCount"":""" & rsOff("loanCount") & ""","
	json = json & """loanBalance"":""" & rsOff("loanBalance") & ""","
	json = json & """loanProfit"":""" & rsOff("loanProfit") & ""","
	json = json & """loanInterest"":""" & formatPercent(rsOff("loanInterest"),4) & ""","
	json = json & """depositCount"":""" & rsOff("depositCount") & ""","
	json = json & """depositBalance"":""" & rsOff("depositBalance") & ""","
	json = json & """depositProfit"":""" & rsOff("depositProfit") & ""","
	json = json & """depositInterest"":""" & formatPercent(rsOff("depositInterest"),4) & ""","
	json = json & """otherCount"":""" & rsOff("otherCount") & ""","
	json = json & """otherBalance"":""" & rsOff("otherBalance") & ""","
	json = json & """otherProfit"":""" & rsOff("otherProfit") & ""","
	json = json & """otherInterest"":""" & formatPercent(rsOff("otherInterest"),4) & ""","
	json = json & """totalCount"":""" & totalCount & ""","
	json = json & """totaBalance"":""" & totaBalance & ""","
	json = json & """totalProfit"":""" & totalProfit & """"
	json = json & "}"
	
	rsOff.movenext 
	
	if not rsOff.eof then json = json & ","
	
wend


json = json & "]}"

rsOff.close 
set rsOff = nothing 


dbug(json)

response.status = "200 Okay"
response.write json 
%>			

		
	


