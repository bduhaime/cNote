<%  
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->
	
	if len(session("userID")) > 0 then 

		SQL = "select showFooter from csuite..users where id = " & session("userID") & " " 
		set rsSF = dataconn.execute(SQL) 
		if not rsSF.eof then 

			if not isNull(rsSF("showFooter")) then 

				if rsSF("showFooter") then 
					showFooter = true 
				else 
					showFooter = false
				end if
			else 

				if systemControls("Show Footer") = "true" then
					showFooter = true 
				else 
					showFooter = false
				end if 

			end if 

		else 

			if systemControls("Show Footer") = "true" then
				showFooter = true 
			else 
				showFooter = false
			end if 

		end if 
		rsSF.close 
		set rsSF = nothing
		
	else 

		if systemControls("Show Footer") = "true" then
			showFooter = true 
		else 
			showFooter = false
		end if 

	end if		
		
	
	if showFooter then 
		%>
		<footer class="mdl-mega-footer">
			<table style="width: 100%; border: none;">
				<tr>
					<td style="width: 30%; text-align: left; border: none;">Version: <!-- #include file="../includes/version.asp" --></td>
					<td style="width: 40%; text-align: center; border: none;">cSuite, LLC | <a href="termsAndConditions.asp">Terms & Conditions</a> | <a href="privacy.asp">Privacy</a></td>
					<td style="width: 30%; text-align: right; border: none;"><% =session("clientID") & " | " & session("userName") %></td>
				</tr>
			</table>
		</footer>
		<% 
	end if 
%>
