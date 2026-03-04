<%
'*****************************************************************************************
function dt_avgDaysSinceLastCallByPrimaryManager()
'*****************************************************************************************

	dbug("dt_avgDaysSinceLastCallByPrimaryManager start...")	
	
	SQL = "select distinct userID from customerManagers where managerTypeID = 0 "
	dbug(SQL) 
	set rsPM = dataconn.execute(SQL)
	xQL = ""
	while not rsPM.eof 
	
		dbug("NOT rsPM.eof...")
	
		xQL = xQL & "select " &_
							"u.firstName, " &_
							"case when lead(cc.startDate) over (order by cc.startDate desc) is null then " &_
								"dateDiff(day,cc.startDate,current_timestamp) " &_
							"else " &_
								"case when lag(cc.startDate) over (order by cc.startDate desc) is null then " &_
									"dateDiff(day,cc.startDate,current_timestamp) " &_
								"else " &_
									"dateDiff(day,lead(cc.startDate) over (order by cc.startDate desc),cc.startDate) " &_
								"end " &_
							"end as daysSinceLastCall " &_
						"from customerCalls cc " &_
						"left join customerManagers cm on (cm.customerID = cc.customerID and cm.startDate <= cc.startDate and (cm.endDate >= cc.startDate or cm.endDate is null) and cm.managerTypeID = 0) " &_
						"left join cSuite..users u on (u.id = cm.userID) " &_
						"where cm.userID = " & rsPM("userID") & " "

			dbug(xQL)
			rsPM.movenext 

			if not rsPM.eof then xQL = xQL & "UNION " end if 

	wend 
	
	rsPM.close 
	set rsPM = nothing 
	
	dbug("completed rsCT loop")
	
	if len(xQL) > 0 then 
		xQL = "select firstName, avg(daysSinceLastCall) from ( " & xQL & " ) x group by firstName " 
		dt = jsonDataTable(xQL)
	end if

	dbug("dt_avgDaysSinceLastCallByPrimaryManager: " & dt & vbCrLf)
	
	dt_avgDaysSinceLastCallByPrimaryManager = dt
	
	dbug("dt_avgDaysSinceLastCallByPrimaryManager end")	

end function 
%>