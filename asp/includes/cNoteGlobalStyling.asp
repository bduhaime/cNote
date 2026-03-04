<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->


<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700/" type="text/css">
<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">

<% 
dbug("globalHead - determining background color...")
scriptName = request.serverVariables("script_name")
serverName = request.serverVariables("SERVER_NAME")
aspServer	= application("aspServer")
apiServer	= application("apiServer")		
			
dbug("request.serverVariables(""script_name""): " & scriptName)
dbug("request.serverVariables(""SERVER_NAME""): " & serverName)
	
	select case scriptName
	
		case "/customerProfit_productOverview.asp", "/customerProfit_serviceOverview.asp", "/customerProfit_serviceProductOverview.asp", "/customerProfit_productProfitability.asp"
			%>
			<!-- 	MDL Theme -->
			<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.3.0/material.indigo-deep_orange.min.css" />
			<%

		case else 
		
			if inStr(scriptName,"cProfit") > 1 then 
				%>
				<!-- 	MDL Theme -->
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.3.0/material.indigo-deep_orange.min.css" />
				<% 
			else 
				%>
				<!-- 	MDL Theme -->
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.3.0/material.deep_purple-orange.min.css" /> 	
				<%	
			end if 
			
	end select 
%>

<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

	<!-- 	jQuery UI -->
	<link rel="stylesheet" href="jquery-ui-1.14.1/jquery-ui.css" />

	<!-- 	DataTables -->
	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.11.5/b-2.2.2/b-colvis-2.2.2/b-html5-2.2.2/b-print-2.2.2/date-1.1.2/fh-3.2.2/sc-2.0.5/sl-1.3.4/datatables.min.css"/>
