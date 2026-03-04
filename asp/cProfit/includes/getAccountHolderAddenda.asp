<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

'!-- ------------------------------------------------------------------ -->
function getAccountHolderAddenda(accountHolder) 
'!-- ------------------------------------------------------------------ -->

	temp = "" 
	
	if len(accountHolder) then 

		SQL = "SELECT TOP 1 " &_
					"a.[account holder number], " &_
					"f.color, " &_
					"a.type, " &_
					"case when priority is null then 9999 else priority end as priority " &_
				"FROM pr_accountHolderAddenda a " &_
				"LEFT JOIN flags f ON ( f.id = a.flagID ) " &_
				"WHERE	a.[account holder number] = '" & accountHolder & "' " &_
				"AND a.type in ( 1, 2 ) " &_
				"ORDER BY 4 asc "
				
		dbug("getAccountHolderAddenda: " & SQL)
		set rsAddenda = dataconn.execute(SQL) 
		
		if not rsAddenda.eof then 
		
		
			while not rsAddenda.eof 
			
				select case cInt(rsAddenda("type"))
				
					case 1	' icon...
			
						temp = temp & "<button id=""" & accountHolder & """ class=""mdl-button mdl-js-button mdl-button--icon addenda"" style=""color:" & rsAddenda("color") & ";""><i class=""material-icons"">flag</i></button>"
				
					case 2	' comment...
			
						temp = temp & "<button id=""" & accountHolder & """ class=""mdl-button mdl-js-button mdl-button--icon addenda"" style=""color:" & rsAddenda("color") & ";""><i class=""material-icons"">notes</i></button>"
				
					case else 		' unknown type, so show question mark icon
	
						temp = temp & "<i id=""" & accountHolder & """ class=""material-icons"" title=""Unexpected type encountered"">contact_support</i>"
	
				end select
	
				rsAddenda.movenext 
			
			wend 

		else 
			
			temp = temp & "<button id=""" & accountHolder & """ class=""mdl-button mdl-js-button mdl-button--icon addenda add"" style=""visibility: hidden;""><i class=""material-icons"">add</i></button>"
			
		end if

		rsAddenda.close 
		set rsAddenda = nothing 


	end if 
	
	getAccountHolderAddenda = temp
	
end function

%>