<!-- METADATA TYPE="typelib" FILE="c:\program files\common files\system\ado\msado15.dll" -->

<!-- #include file="apiSecurity.asp" -->

<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<% 
' ----------------------------------------------------------------------------------------
' Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
' ----------------------------------------------------------------------------------------

select case request.querystring("cmd")

	case "searchAll"
	
		dbug("searchAll detected")
	
		response.ContentType = "application/json"
		
		SQL = "select name + ' - ' + city + ', ' + stalp as bankName, cert, fed_rssd " &_
				"from fdic.dbo.institutions " &_
				"where (active = 1 and inactive = 0) " &_	
				"order by name " &_
				"for json auto, root('institutions') "
				
		dbug(SQL)
		set rs = dataconn.execute(SQL)
			
		if not rs.eof then 
			while not rs.eof 
				json = json & rs.fields(0).value
				rs.movenext 
			wend 
		else 
			json = "null"
		end if
		rs.close 
		set rs = nothing 
		
		dbug("JSON: " & json)
		
		dataconn.close 
		set dataconn = nothing 
	
		response.write(json)
			
	case "search"
	
		dbug("search detected")

		response.ContentType = "application/json"
		if len(request.querystring("query")) > 0 then 
			
			searchString = trim(request.querystring("query"))
			
			SQL = "select name + ' - ' + city + ', ' + stalp as bankName, cert, fed_rssd " &_
					"from fdic.dbo.institutions " &_
					"where (active = 1 and inactive = 0) " &_	
					"and name like '" & searchString & "%' " &_
					"order by name " &_
					"for json auto, root('institutions') "
					
			dbug(SQL)
			set rs = dataconn.execute(SQL)
				
			if not rs.eof then 
				while not rs.eof 
					json = json & rs.fields(0).value
					rs.movenext 
				wend 
			else 
				json = "null"
			end if
			rs.close 
			set rs = nothing 
			
		else 
			
			json = "null"
			
		end if 
		
		dbug("JSON: " & json)
		
		dataconn.close 
		set dataconn = nothing 
	
		response.write(json)
			
	case else 


		response.ContentType = "text/xml"
		xml = "<?xml version='1.0' encoding='UTF-8'?>"
		' xml = "<?xml version=""1.0""?>"
		
		xml = xml & "<institutions state=""" & request("state") & """>"

		if len(request("state")) > 0 then
			SQL = "select fed_rssd, name from fdic.dbo.institutions a where stalp = '" & request("state") & "' and repdte = (select max(repdte) from fdic.dbo.institutions b where b.fed_rssd = a.fed_rssd) order by name " 
		else
			SQL = "select distinct fed_rssd, name from fdic.dbo.institutions a where repdte = (select max(repdte) from fdic.dbo.institutions b where b.fed_rssd = a.fed_rssd) order by name " 
		end if
		dbug("SQL: " & SQL)
		
		set rs = dataconn.execute(SQL)
		
		while not rs.eof
		' 	xml = xml & "<institution><cert>" & trim(rs("cert")) & "</cert><name><![CDATA[" & trim(rs("name")) & "]]</name></institution>"
			xml = xml & "<institution rssdid=""" & trim(rs("fed_rssd")) & """>" & server.htmlEncode(trim(rs("name"))) & "</institution>"
			rs.movenext
		wend

		rs.close
		set rs = nothing

		xml = xml & "</institutions>"
		
		dataconn.close
		set dataconn = nothing
		
		response.write(xml)

end select 
%>