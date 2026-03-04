<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------


'*****************************************************************************************/
function getLGToken ()
'*****************************************************************************************/

	if len(session("lsvtToken")) <= 0 then 
		
		URL		= "https://webservices.lightspeedvt.net/lsvt_api_v35.ashx"
		
		payload	= "command=getLGToken&authkey=6444E140"
	
		Set objHTTP = CreateObject("MSXML2.XMLHTTP") 
	
		Call objHTTP.Open("PUT", URL, TRUE) 
		objHTTP.Send(payload)

		lsvtXML = objHTTP.responseText
		
		dbug(lsvtXML)
		
		session("lsvtToken") = ""
		
	end if 
	
	getLGToken = session("lsvtToken")
	

end function 

'*****************************************************************************************/
'*****************************************************************************************/
'*****************************************************************************************/
'*****************************************************************************************/
'*****************************************************************************************/

select case request("cmd") 

	case "getLGToken"
	
		token = getLGToken()
		msg = "Token found"
		

	case else 
	
		msg = "Unrecognized command"
		
end select 

response.write(msg)

%>