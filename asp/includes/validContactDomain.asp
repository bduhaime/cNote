<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

function validContactDomain(email, customerID)
	
	dbug("validContactDomain('" & email & "'," & customerID & ")")
	
	if inStr(trim(email), "@") > 0 then 

		emailDomainStart = inStr(trim(email), "@") + 1
		
		dbug("validContactDomain: emailDomainStart = " & emailDomainStart)
		
		if isNull(emailDomainStart) OR emailDomainStart <= 0 then 
			
			dbug("contactDomainStart: '@' not found in email; returning false")
			validContactDomain = false 
			
		else 
			
			emailLength = len(trim(email)) 
			dbug("validContactDomain: emailLength = " & emailLength)
			
			emailDomain = mid(trim(email),emailDomainStart,emailLength)
			
			dbug("validContactDomain: emailDomain = '" & emailDomain & "'")
			
			SQL = "select count(*) as emailDomainCount " &_
					"from customer_view c " &_
					"where id = " & customerID & " " &_
					"and validDomains like '%" & emailDomain & "%' " 
				
			dbug(SQL)
	
			set rsED = dataconn.execute(SQL)
			
			if not rsED.eof then 
				dbug("validContactDomain: emailDomainCount = " & rsED("emailDomainCount")) 
				if cInt(rsED("emailDomainCount")) > 0 then 
					validContactDomain = true 
				else 
					validContactDomain = false 
				end if 
			else 
				validContactDomain = false 
			end if 
			
			rsED.close 
			set rsED = nothing 
			
		end if

	else 
		
		dbug("validContactDomain: '@' not found, so returning false") 
		validContactDomain = false
		
	end if
		
end function
%>