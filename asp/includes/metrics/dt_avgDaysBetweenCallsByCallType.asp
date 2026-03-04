<%
'*****************************************************************************************
function dt_avgDaysBetweenCallsByCallType()
'*****************************************************************************************

	dbug("dt_avgDaysBetweenCallsByCallType start...")	
	
	SQL = "select 	case when (nextCallDate is null) then cast(current_timestamp as date) else nextCallDate end as nextCallDate, " 

	sqlCallType = "select shortName from customerCallTypes order by shortName " 
	
	dbug("dt_avgDaysBetweenCallsByCallType: SQL = " & sqlCallType)	
	
	set rsCt = dataconn.execute(sqlCallType)
	dbug("dt_avgDaysBetweenCallsByCallType: following rsCT open")	
	while not rsCT.eof  
		SQL = SQL & "avg(case when (shortName = '" & rsCT("shortName") & "') then " &_
							"case when nextCallDate is null then " &_
								"dateDiff(day,startDate,cast(current_timestamp as date)) " &_
							"else " &_
								"dateDiff(day,startDate,nextCallDate) " &_
							"end " &_
						"end) as [" & rsCT("shortName") & "] "
		rsCT.movenext 
		if not rsCT.eof then SQL = SQL & ", " end if 
	wend
	rsCT.close 
	set rsCT = nothing

	SQL = SQL &_
			"from " &_
				"( " &_
				"select " &_ 
					"shortName, " &_
					"customerID, " &_
					"startDate, " &_
					"( " &_
					"select min(startDate) " &_
					"from customerCalls y " &_
					"where x.startDate < y.startDate " &_
					"and x.customerID = y.customerID " &_
					"and x.callTypeID = y.callTypeID " &_
					") as nextCallDate " &_
				"from customerCalls x " &_
				"left join customerCallTypes z on (z.id = x.callTypeID) " &_
				") z " &_
			"where startDate is not null " &_
			"group by nextCallDate " &_
			"order by nextCallDate "

	dbug("dt_avgDaysBetweenCallsByCallType: complete SQL = " & SQL)	

	dt = jsonDataTable(SQL)

	dbug("dt_avgDaysBetweenCallsByCallType: " & dt)
	
	dt_avgDaysBetweenCallsByCallType = dt
	
	dbug("dt_avgDaysBetweenCallsByCallType end" & vbCrLf)	

end function 
%>