
<!-- #include file="../../includes/security.asp" -->
<!-- #include file="../../includes/dbug.asp" -->
<!-- #include file="../../includes/dataconnection.asp" -->
<!-- #include file="../../includes/userLog.asp" -->
<!-- #include file="../../includes/userPermitted.asp" -->
<!-- #include file="../../includes/checkPageAccess.asp" -->
<!-- #include file="../../includes/getNextID.asp" -->
<% 
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

' call checkPageAccess(43)
dbug("customerFlagsReorder.asp started")

response.ContentType = "application/json"


arrReorderedRows 	= request("arrReorderedRows") 

dbug("arrReorderedRows: " & arrReorderedRows)

' strip leading and trailing double-quotes...
if left(arrReorderedRows,1) = """" then 
	arrReorderedRows = mid(arrReorderedRows,2,len(arrReorderedRows))
end if 
if right(arrReorderedRows,1) = """" then 
	arrReorderedRows = mid(arrReorderedRows,1,len(arrReorderedRows)-1)
end if
dbug("arrReorderedRows (after stripping double-quotes: " & arrReorderedRows)


tempAll = split(arrReorderedRows, "|")


if isArray(tempAll) then 
	
	dbug("tempAll is an array")


	if UBound(tempAll) > 0 then 

		for i = 0 to uBound(tempAll) 
			
			temp = split(tempAll(i),",")
			SQL = "update flags set " &_
						"priority = " & temp(1) & " " &_
						"where id = " & temp(0) & " " 
						
			dbug(SQL) 
			
			set rsUpdate = dataconn.execute(SQL) 
			set rsUpdate = nothing 
			
		next 

		msg = "Sequence Updated"

	else 
		
		msg = "tempAll array has not contents"

	end if 		


else 

	dbug("tempAll is NOT an array")

	json = "{""error"":""arrReorderRows is not valid""}"
	response.status = "400 Bad Request"
	response.write json
	response.end()
end if 



json = "{""msg"":""" & msg & """}"

dbug(json)
dbug("customerFlagsReorder.asp ended")

response.status = "200 Okay"
response.write json 
%>			

		
	


