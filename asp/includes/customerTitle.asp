<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'*******************************************************************************
function customerTitle(customer)
'*******************************************************************************
	
	dbug("customerTitle: start for customer=" & customer)
	
	if len(customer) then
		
		SQL = "select c.id, c.name, i1.city, i1.stalp, s.description " &_
				"from customer_view c " &_
				"left join customerStatus s on (s.id = c.customerStatusID and s.deleted <> 1) " &_
				"left join fdic.dbo.institutions i1 on (i1.cert = c.cert and i1.repdte = (select max(repdte) from fdic.dbo.institutions where cert = c.cert)) " &_
				"where c.id = " & customer & " "
		
		dbug(SQL)
		
		set rsCT = dataconn.execute(SQL)
		dbug(SQL)
		
		if not rsCT.eof then
			dbug("not rsCT.eof")
			customerName = rsCT("name")
			customerCity = rsCT("city") 
			customerState = rsCT("stalp") 
			customerStatus = rsCT("description")
		else
			dbug("rsCT.eof")
			customerName = ""
			customerCity = ""
			customerState = ""
			customerStatus = ""
		end if
		
		rsCT.close 
		set rsCT = nothing
		
		title = customerName & ": " & customerCity & ", " & customerState

	else 
		
		dbug("no customerID provided")
		
		title = ""
		
	end if 
	
	customerTitle = title 
	
end function 
%>