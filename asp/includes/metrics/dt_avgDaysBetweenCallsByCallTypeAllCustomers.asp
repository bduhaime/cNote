<%
'*****************************************************************************************
function dt_avgDaysBetweenCallsByCallTypeAllCustomers()
'*****************************************************************************************

	dbug("dt_avgDaysBetweenCallsByCallTypeAllCustomers start...")	
	
	SQL = "select * " &_
			"from ( " &_
				"select " &_
					"a.customerID, " &_
					"a.startDate, " &_
					"e.shortName, " &_
					"case when max(b.startDate) is null then " &_
						"datediff(day,d.currSignedDate,a.startDate) " &_
					"else " &_
						"datediff(day,max(b.startDate),a.startDate) " &_
					"end as days " &_
				"from customerCalls a " &_
				"left join customerCalls b on (b.customerID = a.customerID and b.callTypeID = a.callTypeID and b.startDate < a.startDate) " &_
				"left join customer_view c on (c.id = a.customerID) " &_
				"left join contracts d on (d.cert = c.cert) " &_
				"left join customerCallTypes e on (e.id = a.callTypeID) " &_
				"and (a.deleted = 0 or a.deleted is null) " &_
				"group by a.customerID, e.shortName, a.startDate, d.currSignedDate " &_
				") src " &_
			"pivot " &_
				"( " &_
				"avg(days) " &_
				"for shortName in ([HFY],[MCC],[SAC],[BJD],[DAD]) " &_
				") piv "

	dbug("dt_avgDaysBetweenCallsByCallTypeAllCustomers: SQL = " & SQL)	

	dt = jsonDataTable(SQL)

	dbug("dt_avgDaysBetweenCallsByCallTypeAllCustomers: " & dt)
	
	dt_avgDaysBetweenCallsByCallTypeByCustomer = dt
	
	dbug("dt_avgDaysBetweenCallsByCallTypeAllCustomers end" & vbCrLf)	

end function 
%>