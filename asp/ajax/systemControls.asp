<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

'***** TASK MAINTENANCE *****
dbug("systemControls maintenance...")

response.contentType = "text/xml"

xml = "<?xml version='1.0' encoding='UTF-8'?>"
xml = xml & "<systemControls>"

msg = ""

select case request.querystring("cmd")

	case "toggle"

		select case request.querystring("control")
		
			case "dbug" 
			
				if application("dbug") then 
					application("dbug") = false
					msg = request.querystring("control") & " toggled off"
				else 
					application("dbug") = true
					msg = request.querystring("control") & " toggled on"
				end if
							
			case "showFooter" 
			
' 				dbug("showFooter detected")
				
				SQL = "select [value] from systemControls where [name] = 'Show Footer' " 
' 				dbug(SQL)
				set rsFoot = dataconn.execute(SQL)
				if not rsFoot.eof then 
					if rsFoot("value") = "true" then 
' 						dbug("row found, toggling to false")
						SQL = "update systemControls set [value] = 'false' where [name] = 'Show Footer' "
						msg = "Show Footer toggled off"
					else 
' 						dbug("row found, toggling to true")
						SQL = "update systemControls set [value] = 'true' where [name] = 'Show Footer' "
						msg = "Show Footer toggled on"
					end if
				else 
' 					dbug("row not found, inserting and defaulting to true")
					SQL = "insert into systemControls ([name],[value]) values ('Show Footer','true') "
					msg = "Show Footer toggled on"
				end if
				
				rsFoot.close 
				set rsFoot = nothing 
				
' 				dbug(SQL)
				set rsFooter = dataconn.execute(SQL)
				set rsFooter = nothing 
				
' 				dbug("msg=" & msg )
							
			case "sendEmail" 
				
				dbug("sendEmail detected") 
				SQL = "select [value] from systemControls where [name] = 'Send system generated email' "
				dbug(SQL) 
				set rsEmail = dataconn.execute(SQL) 
				if not rsEmail.eof then 
					if rsEmail("value") = "true" then 
						dbug("email row found, toggling to false")
						SQL = "update systemControls set [value] = 'false' where [name] = 'Send system generated email' "
						msg = "Email toggled off"
					else 
						dbug("email row found, toggling to true")
						SQL = "update systemControls set [value] = 'true' where [name] = 'Send system generated email' "
						msg = "Email toggled on"
					end if 
				else 
					dbug("email row not found, inserting and defaulting to true")
					SQL = "insert into systemControls ([name],[value]) values ('Send system generated email','true') "
					msg = "Email toggled on"
				end if
				
				rsEmail.close 
				set rsEmail = nothing 
				
				dbug(SQL)
				set rsEmailer = dataconn.execute(SQL) 
				set rsEmailer = nothing 
					

			case "toggleLSVT"
			
				dbug( "toggleLSVT detected" )
				SQL = "select [value] from systemControls where [name] = 'Use LSVT manual location/customer mapping' "
				dbug(SQL)
				set rsLSVT = dataconn.execute(SQL)
				if not rsLSVT.eof then
					if rsLSVT("value") = "true" then 
						dbug("LSVT row found, toggling to false")
						SQL = "update systemControls set [value] = 'false' where [name] = 'Use LSVT manual location/customer mapping' "
						msg = "LSVT toggled off"
					else 
						dbug("LSVT row found, toggling to true")
						SQL = "update systemControls set [value] = 'true' where [name] = 'Use LSVT manual location/customer mapping' "
						msg = "LSVT toggled on"
					end if 
				else 
					dbug("LSVT row not found, inserting and defaulting to true")
					SQL = "insert into systemControls ([name],[value]) values ('Use LSVT manual location/customer mapping','true') "
					msg = "LSVT toggled on"
				end if

				rsLSVT.close 
				set rsLSVT = nothing 
				
				dbug(SQL)
				set rsLSVTer = dataconn.execute(SQL) 
				set rsLSVTer = nothing 
					


			case else 
			
				dbug("unexpected toggle: " & request.querystring("control"))
			
		end select 
				
		xml = xml & "<control>" & request.querystring("control") & "</control>"

	case else 

		dbug("unexpected directive encountered")
		msg = "Unexpected directive encountered in taskMaintenance.asp"

end select 

xml = xml & "<msg>" & msg & "</msg>"
userLog(msg)

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</systemControls>"

response.write(xml)
%>