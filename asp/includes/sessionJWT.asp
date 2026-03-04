<% 

jwtUserID			= session("userID") 
jwtUsername			= session("username")
jwtDbName			= session("dbName")
jwtClientNbr		= session("clientNbr")
jwtInternalUser	= session("internalUser")
sessionJWT = getJWT( jwtUserID, jwtUsername, jwtDbName, jwtClientNbr, jwtInternalUser )

%>
<script language="javascript" runat="server">

	function getJWT( userID, username, dbName, clientNbr, internalUser ) {

		var expiry	 		= new Date().getTime() / 1000 + ( 60 * 90 ); // 90 minutes

		var sessionInfo	= '"userID": ' 		+ userID 		+ ', ' 
								+ '"username": "' 	+ username 		+ '", '
								+ '"dbName": "' 		+ dbName 		+ '", '
								+ '"clientNbr": ' 	+ clientNbr 	+ ', '
								+ '"internalUser": ' + internalUser + ', '
								+ '"exp": ' 			+ expiry;
								
		var token 			= new jwt.WebToken( '{ '+sessionInfo+' }', '{ "typ":"JWT", "alg":"HS256" }' );
		var signed 			= token.serialize( "secretkey" );

		return signed;

	}

</script>
