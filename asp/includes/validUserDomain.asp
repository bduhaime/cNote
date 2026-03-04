<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

function validUserDomain(username, customerID, client)
	
	dbug(" ")
	dbug("validUserDomain -- username: '" & username & "'")
	dbug("validUserDomain -- customerID: " &  customerID)
	dbug("validUserDomain -- client: '" & client & "'")

	userDomainStart = inStr(trim(username), "@") + 1
	
	dbug("validUserDomain -- userDomainStart = " & userDomainStart)
	
	if userDomainStart <= 0 then 
		
		dbug("validUserDomain -- '@' not found in username; returning false")
		validUserDomain = false 
		
	else 
		
		if len(customerID) > 0 then 
		
			usernameLength = len(trim(username)) 
			dbug("validUserDomain -- usernameLength = " & usernameLength)
			
			userDomain = mid(trim(username),userDomainStart,usernameLength)
			
			dbug("validUserDomain -- userDomain = '" & userDomain & "'")
			
			if lCase(client) <> "csuite" then 
				SQL = "select count(*) as userDomainCount " &_
						"from " & client & "..customer " &_
						"where id = " & customerID & " " &_
						"and validDomains like '%" & userDomain & "%' " 
			else 
				SQL = "select count(*) as userDomainCount " &_
						"from csuite..clients " &_
						"where databaseName = '" & client & "' " &_
						"and validDomains like '%" & userDomain & "%' " 
			end if					
								
			dbug("validUserDomain -- " & SQL)
	
			set rsUD = dataconn.execute(SQL)
			
			if not rsUD.eof then 
				dbug("validUserDomain -- userDomainCount = " & userDomainCount) 
				if cInt(rsUD("userDomainCount")) > 0 then 
					validUserDomain = true 
				else 
					validUserDomain = false 
				end if 
			else 
				validUserDomain = false 
			end if 
			
			rsUD.close 
			set rsUD = nothing 
		
		else 

			if lCase(client) = "csuite" then 
				
				' since there is not customer table in csuite, any domain is valid
				validUserDomain = true
	
			else 
				
				' since there is no customerID, the domain cannot be validated, so return false
				validUserDomain = false
				
			end if
			
		end if
		
	end if
	
end function
%>