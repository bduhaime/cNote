<%
'*****************************************************************************************
function dt_daysSinceLastContactByCustomer(status)
'*****************************************************************************************

	dbug("dt_daysSinceLastContactByCustomer start...")	
	
	dbug("status = " & status)
	
	SQL =	"select c.name, datediff(d,max(cm.updatedDate),getdate()) as days " &_
		"from customerMetric cm " &_
		"join customer_view c on (c.id = cm.customerID) " &_
		"where customerStatusID = " & status & " " &_
		"group by c.name " &_
		"order by 2 desc "
	
	set rsDaysSinceLastContact = dataconn.execute(SQL)
	
	if not rsDaysSinceLastContact.eof then 
		dt = jsonDataTable(SQL)
	else 
		dt = "no data found"
	end if
	
	dbug("dt_daysSinceLastContactByCustomer: " & dt & vbCrLf)
	
	dt_daysSinceLastContactByCustomer = dt
	
	dbug("dt_daysSinceLastContactByCustomer end")	

end function 
%>