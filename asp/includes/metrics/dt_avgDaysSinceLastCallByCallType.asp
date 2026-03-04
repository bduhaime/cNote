<%
'*****************************************************************************************
function dt_avgDaysSinceLastCallByCallType()
'*****************************************************************************************

	dbug("dt_avgDaysSinceLastCallByCallType start...")	
	
'	for this metric it is necessary to build a subquery for each customerCallType and union
'	then together kind of like this:
'
'	select callTypeName, avg(daysSinceLastCall)
'	from 
'		(
'		select name, daysSinceLastCall
'		...
'		from customerCalls
'		...
'		where callTypeID = 1
'		UNION
'		select name, daysSinceLastCall
'		...
'		from customerCalls
'		...
'		where callTypeID = 1
'		...	
'		...
'		)


	SQL = "select id from customerCallTypes"
	dbug("dt_avgDaysSinceLastCallByCallType: " & SQL) 
	set rsCT = dataconn.execute(SQL)
	xQL = ""
	while not rsCT.eof 
	
		dbug("dt_avgDaysSinceLastCallByCallType: NOT rsCT.eof...")
	
		xQL = xQL & "select " &_
							"cct.shortName as callTypeName, " &_
							"case when lead(cc.startDate) over (order by cc.startDate desc) is null then " &_
								"dateDiff(day,cc.startDate,current_timestamp) " &_
							"else " &_
								"case when lag(cc.startDate) over (order by cc.startDate desc) is null then " &_
									"dateDiff(day,cc.startDate,current_timestamp) " &_
								"else " &_
									"dateDiff(day,lead(cc.startDate) over (order by cc.startDate desc),cc.startDate) " &_
								"end " &_
							"end as daysSinceLastCall, " &_
							"cct.idealFrequencyDays " &_
						"from customerCalls cc " &_
						"left join customerCallTypes cct on (cct.id = cc.callTypeID) " &_
						"where (cc.deleted = 0 or cc.deleted is null) " &_
						"and cc.callTypeID = " & rsCT("id") & " " 
			
			dbug("dt_avgDaysSinceLastCallByCallType: xQL=" & xQL)
			
			rsCT.movenext 
			dbug("dt_avgDaysSinceLastCallByCallType: after rsCT.movenext...")
			if not rsCT.eof then xQL = xQL & "UNION " end if 
			dbug("dt_avgDaysSinceLastCallByCallType: adfter 'union' thing...")
		
		dbug("dt_avgDaysSinceLastCallByCallType: end of rsCT while loop...")
			
	wend 
	
	dbug("dt_avgDaysSinceLastCallByCallType: completed rsCT loop")
	
	if len(xQL) > 0 then 
		xQL = "select callTypeName, avg(daysSinceLastCall) as Actual, avg(idealFrequencyDays) as Goal from ( " & xQL & " ) x group by callTypeName " 
		dt = jsonDataTable(xQL)
	end if

	dbug("dt_avgDaysSinceLastCallByCallType: " & dt)
	
	dt_avgDaysSinceLastCallByCallType = dt
	
	dbug("dt_avgDaysSinceLastCallByCallType end" & vbCrLf)	

end function 
%>