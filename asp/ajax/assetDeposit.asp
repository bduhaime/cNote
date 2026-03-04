<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2019, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------


json = "["
json = json & "[""Quarter"",""Assets"",""Deposits"",""Ratio""]"

' SQL = "select repdte, asset, dep from fdic.dbo.institutions where cert = " & request("cert") & " order by repdte "
SQL = "select repdte, asset, dep, dep/asset*100 as [d/a] from fdic.dbo.institutions where cert = 17308 order by repdte "

set rs = dataconn.execute(SQL)
while not rs.eof 
' 	json = json & ",['" & rs("repdte") & "'," & rs("asset") & "," & rs("dep") & "]"
	json = json & ",[""" & rs("repdte") & """," & rs("asset") & "," & rs("dep") & "," & rs("d/a") & "]"
	rs.movenext 
wend

rs.close 
set rs = nothing 

json = json & "]"

response.write(json)
%>