 <!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLog.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(2)

title = session("clientID") & " - Administration" 
userLog(title)
%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->

	<style>

		table, tr {
			border-collapse: collapse;
		}
		
		li {
			font-weight: bold;
/* 			list-style-type: lower-roman; */
			list-style-type: upper-roman;
/* 			list-style-type: lower-alpha; */
/* 			list-style-type: upper-alpha; */
/* 			list-style-type: upper-circle; */
/* 			list-style-type: upper-disc; */
/* 			list-style-type: upper-square; */
		}
		
		.sectionHeader-left {
			text-align: left;
			border: solid black 1px;
			background-color: lightgrey;
			font-weight: bold;
			padding-left: 5px;
		}

		.sectionHeaderRowHeader {
			text-align: left;
			border: solid black 1px;
			background-color: lightgrey;
			font-weight: bold;
			padding-left: 5px;
		}

		.sectionHeaderDate {
			text-align: center;
			border: solid black 1px;
			background-color: lightgrey;
			font-weight: bold;
			width: 72px;
		}

		.sectionHeader-center {
			text-align: center;
			border: solid black 1px;
			background-color: lightgrey;
			font-weight: bold;
		}


		.sectionBody {
			padding-left: 25px;
		}
		
		.sectionDetailRowHeader {
			text-align: left;
			padding-left: 25px;
			border: solid black 1px;
			width: 300px;
		}
		
		.sectionDetailDate {
			text-align: center;
			padding-left: 5px;
			padding-right: 5px;
			border: solid black 1px;
			width: 72px;			
		}
		
		.sectionDetail-left {
			text-align: left;
			padding-left: 5px;
			padding-right: 5px;
			border: solid black 1px;
		}
		
		.sectionDetail-center {
			text-align: center;
			padding-left: 5px;
			padding-right: 5px;
			border: solid black 1px;
		}
		
	</style>

</head>

<body>
	<br><br>
	<div style="width: 800px; margin: auto;">

	
		<table width="100%" style="border: solid black 1px;">
			<tr><td class="sectionHeader-left">Call Info</td></tr>
			<tr><td class="sectionBody">Bank Nickname - Call Name</td></tr>
			<tr><td class="sectionBody">longDate of call</td></tr>
			<tr><td class="sectionBody">startTime - endTime timeZone</td></tr>
			<tr><td class="sectionBody">Zoom invite and login information to follow</td></tr>
			<tr><td class="sectionBody">&nbsp;</td></tr>
			<tr><td class="sectionHeader-left">Discussion Agenda</td></tr>
			<tr><td class="sectionBody">
				<ol>
					<li>Header 1</li>
					<li>Header 2</li>
					<li>Header 3</li>
					<li>Header 4</li>
				</ol>	
			</td></tr>
		</table>
		<br>

		<table>
			<tr>
				<td class="sectionHeaderRowHeader">Key Initiatives</td>
				<td class="sectionHeaderDate">Start</td>
				<td class="sectionHeaderDate">End</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Add highly-trainied Commercial Bankers</td>
				<td class="sectionDetailDate">7/1/2018</td>
				<td class="sectionDetailDate">12/31/18</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Redefine target markets based on Top 100</td>
				<td class="sectionDetailDate">7/1/2018</td>
				<td class="sectionDetailDate">12/31/18</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Adjust Strategic Plan</td>
				<td class="sectionDetailDate">7/1/2018</td>
				<td class="sectionDetailDate">12/31/18</td>
			</tr>
		</table>
		<br>
		<table>
			<tr>
				<td class="sectionHeaderRowHeader">Projects</td>
				<td class="sectionHeaderDate">Start</td>
				<td class="sectionHeaderDate">End</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Strategic Planning</td>
				<td class="sectionDetailDate">7/1/2018</td>
				<td class="sectionDetailDate">12/31/2018</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Internship Onboarding Program</td>
				<td class="sectionDetailDate">7/15/2018</td>
				<td class="sectionDetailDate">11/15/2018</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Level 4 USPs</td>
				<td class="sectionDetailDate">7/15/2018</td>
				<td class="sectionDetailDate">11/15/2018</td>
			</tr>
		</table>
		<br>
		<table>
			<tr>
				<td class="sectionHeaderRowHeader">Tasks</td>
				<td class="sectionHeaderDate">Start</td>
				<td class="sectionHeaderDate">End</td>
				<td class="sectionHeader-center">Owner</td>
				<td class="sectionHeader-center">Days Behind</td>
				<td class="sectionHeader-left">Project</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Update Names of current Level 4 USPs</td>
				<td class="sectionDetailDate">7/16/2018</td>
				<td class="sectionDetailDate">8/201/18</td>
				<td class="sectionDetail-center">Ryan Wedel</td>
				<td class="sectionDetail-center">20</td>
				<td class="sectionDetail-left">Strategic Planning</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Reestablish Top 100 List review</td>
				<td class="sectionDetailDate">7/18/2018</td>
				<td class="sectionDetailDate">8/3/18</td>
				<td class="sectionDetail-center">Michael Burns</td>
				<td class="sectionDetail-center">5</td>
				<td class="sectionDetail-left">Internship Onboarding Program</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Analyze your Top 100 Target Markets</td>
				<td class="sectionDetailDate">7/19/2018</td>
				<td class="sectionDetailDate">8/4/18</td>
				<td class="sectionDetail-center">Michael Burns</td>
				<td class="sectionDetail-center"></td>
				<td class="sectionDetail-left">Level 4 USPs</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Review & Use CEO Top 100 Script</td>
				<td class="sectionDetailDate">7/20/2018</td>
				<td class="sectionDetailDate">8/5/18</td>
				<td class="sectionDetail-center">Michael Burns</td>
				<td class="sectionDetail-center">6</td>
				<td class="sectionDetail-left"></td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Reestablish your Top 100/Top 1000 list management</td>
				<td class="sectionDetailDate">7/21/2018</td>
				<td class="sectionDetailDate">8/6/18</td>
				<td class="sectionDetail-center">Michael Burns</td>
				<td class="sectionDetail-center">1</td>
				<td class="sectionDetail-left">Internship Onboarding Program</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">TGIM U Review</td>
				<td class="sectionDetailDate">7/22/2018</td>
				<td class="sectionDetailDate">8/7/18</td>
				<td class="sectionDetail-center">Ryan Wedel</td>
				<td class="sectionDetail-center"></td>
				<td class="sectionDetail-left">Level 4 USPs</td>
			</tr>
			<tr>
				<td class="sectionDetailRowHeader">Register for ABP 2019</td>
				<td class="sectionDetailDate">7/23/2018</td>
				<td class="sectionDetailDate">8/8/18</td>
				<td class="sectionDetail-center">Michael Burns</td>
				<td class="sectionDetail-center"></td>
				<td class="sectionDetail-left"></td>
			</tr>
		</table>
	

	</div>
</body>
</html>