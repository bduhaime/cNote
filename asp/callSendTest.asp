<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/userLOg.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<!-- #include file="includes/systemControls.asp" -->
<!-- #include file="includes/customerTitle.asp" -->
<!-- #include file="includes/getNextID.asp" -->
<!-- #include file="includes/escapeQuotes.asp" -->
<!-- #include file="includes/formatHTML5Date.asp" -->
<!-- #include file="includes/checkPageAccess.asp" -->
<!-- #include file="includes/jwt.all.asp" -->

<%
customerID = 8
callID = 1433
userID = session("userID")

response.cookies("CNOTESESSION") = getJwt(userID, callID, customerID)

%>

<script language="javascript" runat="server">

	function getJwt( user, call, customer ) {

//		var token = new jwt.WebToken('{"iss": "joe", "exp": 1300819380, "http://example.com/is_root": true}', '{"typ":"JWT", "alg":"HS256"}');

		var tokenJSON = '{"userID":<% =session("userID") %>, "dbName":"<% =session("dbName") %>", "clientNbr":<% =session("clientNbr") %>, "callID":<% =callID %>, "customerID":<% =customerID %>, "exp":1300819380, "http://example.com/is_root": true}'

		var token = new jwt.WebToken(tokenJSON, '{"typ":"JWT", "alg":"HS256"}');
		var signed = token.serialize("Key");

		return signed;

	}

// '{ "callID": "'+callID+'", "customerID": "'+customerID+'". "userID": "'+userID+'" }'

</script>


<html>
	<head>
		<style>
			table {
				border-collapse: collapse;
			}
			table, th, td {
				border: solid black 1px;
			}
		</style>
		
	</head>
	<body>
		<table>
			<thead>
				<tr><th>Name</th><th>Value</th></tr>
			</thead>
			<tbody>
				<tr><td>type</td><td>Send Agenda</td></tr>
				<tr><td>to</td><td>brad@sqware1.com</td></tr>
				<tr><td>subject</td><td>test agenda</td></tr>
				<tr><td>session("userID")</td><td><% =userID %></td></tr>
				<tr><td>callID</td><td><% =callID %></td></tr>
				<tr><td>customerID</td><td><% =cutomerID %></td></tr>
				<tr><td>JWT</td><td><%  =getJwt(userID, callID, customerID) %></td></tr>
			</tbody>
		</table>
		<br>
		<button type="submit">Send</button>
	</body>
</html>