<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->


function createDisconnectedRecordset(byVal strSQL, byRef objDataconn)

	on error resume next
	
	set objRS = server.createObject("ADODB.Recordset")
	objRS.cursorLocation = adUseClient
	objRS.open strSQL, objDataconn, adOpenStatic, adLockReadOnly
		
	If dataconn.Errors.Count > 0 Then
		%>
		<TABLE BORDER=1 align="center" width="50%">
			<tr>
				<td colspan="2"><% =strSQL %></td>
			</tr>
			<tr>
				<td colspan="2">One or more database errors detected</td>
			</tr>
		<%
		For each objError in dataconn.Errors
		
			If dataconn.number <> 0 then
				%>
				<br />
					<TR>
						<TD style="reportDetailColHeader">Error Property</TD>
						<TD style="reportDetailColHeader">Contents</TD>
					</TR>
					<TR>
						<TD class="ReportDetailRowHeader">Number</TD>
						<TD class="ReportDetail"><% =objError.Number %></TD>
					</TR>
					<TR>
						<TD class="ReportDetailRowHeader">NativeError</TD>
						<TD class="ReportDetail"><% =objError.NativeError %></TD>
					</TR>
					<TR>
						<TD class="ReportDetailRowHeader">SQLState</TD>
						<TD class="ReportDetail"><% =objError.SQLState %></TD>
					</TR>
					<TR>
						<TD class="ReportDetailRowHeader">Source</TD>
						<TD class="ReportDetail"><% =objError.Source %></TD>
					</TR>
					<TR>
						<TD class="ReportDetailRowHeader">Description</TD>
						<TD class="ReportDetail"><% =objError.Description %></TD>
					</TR>
				</TABLE>
				<%
			End If
		
		Next
		
		set objRS.activeConnection = nothing
		on error goto 0
		response.end()
		
	else

		on error goto 0
		set objRS.activeConnection = nothing
		set createDisconnectedRecordset = objRS
	
	end if
	
	
'	objRS.close
	set objRS = nothing

end function
%>