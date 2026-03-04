<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

response.ContentType = "text/xml"
xml = "<?xml version='1.0' encoding='UTF-8'?>"
' xml = "<?xml version=""1.0""?>"

xml = xml & "<instDetail>"

if len(request("rssdid")) > 0 then

	SQL = "select name, stalp, city, asset, cb, mutual, offdom, specgrpn from fdic.dbo.institutions a where fed_rssd = " & request("rssdid") & " and repdte = (select max(repdte) from fdic.dbo.institutions b where b.fed_rssd = a.fed_rssd) " 
	dbug("SQL: " & SQL)
	set rs = dataconn.execute(SQL)
	if not rs.eof then
		xml = xml & "<header"
		xml = xml & " rssdid=""" & request("rssdid") & """"
		xml = xml & " name=""" & trim(rs("name")) & """"
		xml = xml & " state=""" & rs("stalp") & """"
		xml = xml & " city=""" & trim(rs("city")) & """"
		xml = xml & " assets=""" & formatCurrency(rs("asset"),0) & """"
		xml = xml & " cb=""" & rs("cb") & """"
		xml = xml & " mutual=""" & rs("mutual") & """"
		xml = xml & " offices=""" & rs("offdom") & """"
		xml = xml & " specgrpn=""" & trim(rs("specgrpn")) & """"
		xml = xml & ">"
	else
		xml = xml & "RSSDID NOT FOUND"
	end if
	xml = xml & "</header>"
	
	rs.Close	
	set rs = Nothing



	xml = xml & "<assetDeposit>"

	json = "["
	json = json & "[""Quarter"",""Assets"",""Deposits"",""Ratio""]"
	
	' SQL = "select repdte, asset, dep from fdic.dbo.institutions where cert = " & request("cert") & " order by repdte "
	SQL = "select repdte, asset, dep, dep/asset*100 as [d/a] from fdic.dbo.institutions where fed_rssd = " & request("rssdid") & " order by repdte "
	
	set rs = dataconn.execute(SQL)
	while not rs.eof 
	' 	json = json & ",['" & rs("repdte") & "'," & rs("asset") & "," & rs("dep") & "]"
		json = json & ",[""" & rs("repdte") & """," & rs("asset") & "," & rs("dep") & "," & rs("d/a") & "]"
		rs.movenext 
	wend
	
	rs.close 
	set rs = nothing 
	
	json = json & "]"

	xml = xml & json 
	xml = xml & "</assetDeposit>"
	
end if

dataconn.close
set dataconn = nothing

%>
<!-- #include file="apiQuerystring.asp" -->
<%
xml = xml & "</instDetail>"

response.write(xml)
%>