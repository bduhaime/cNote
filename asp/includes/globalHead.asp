<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->
	
	<!-- 	jQuery (minified) -->
	<script   src="https://code.jquery.com/jquery-3.7.1.min.js"   integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo="   crossorigin="anonymous"></script>	

	<!-- 	jQuery UI -->
	<script type="text/javascript" src="jquery-ui-1.14.1/jquery-ui.js"></script>
	<link rel="stylesheet" href="jquery-ui-1.14.1/jquery-ui.css" />


	<!-- 	DataTables -->
	<link href="https://cdn.datatables.net/v/dt/dt-2.3.4/b-3.2.5/b-colvis-3.2.5/b-html5-3.2.5/b-print-3.2.5/date-1.6.1/fh-4.0.4/sc-2.4.3/sb-1.8.4/sl-3.1.3/datatables.min.css" rel="stylesheet" integrity="sha384-11SAXs6TuBJq7tMTvVvb6kM4WK0aGFiJFkOpqBXfwQP8sppNQ7ATmBV3yQh16QQc" crossorigin="anonymous">
	<script src="https://cdn.datatables.net/v/dt/dt-2.3.4/b-3.2.5/b-colvis-3.2.5/b-html5-3.2.5/b-print-3.2.5/date-1.6.1/fh-4.0.4/sc-2.4.3/sb-1.8.4/sl-3.1.3/datatables.min.js" integrity="sha384-CI9J1d8PK5nYWzjUAofhQxboeoKsBQZZza2MeqaVUCduxNoWYawXF1DIBFFoHiri" crossorigin="anonymous"></script>


	<!-- 	MDL Fonts -->
	<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700/" type="text/css">
	<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
	
	<!-- 	MDL Symbols -->	
	<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@48,400,0,0" />	
	

	
	<% 
	dbug("globalHead - determining background color...")
	scriptName 	= request.serverVariables("script_name")
	serverName 	= request.serverVariables("SERVER_NAME")
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

	<!-- 	MDL -->
	<!-- 	<script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script> -->
	<script defer src="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.3.0/material.min.js"></script>

	<script>
		// this is in includes/globalHead.asp
		const sessionJWT			= '<% =sessionJWT %>';
		if ( typeof aspServer === 'undefined' ) var aspServer = '<% =aspServer %>';
		if ( typeof apiServer === 'undefined' ) var apiServer = '<% =apiServer %>';
		const scriptName			= '<% =scriptName %>';
		if ( typeof userID === 'undefined' ) var userID = '<% =session("userID") %>';
		const checkTimeoutFreq	= 10000; 							// in miliseconds -- 10000 = 10 seconds
		let sessionTimeout 	= <% =Session.Timeout %>;
		let lastActivity = new Date( '<% =session("lastActivity") %>' );
			
// 		console.log({ sessionTimeout });
// 		console.log({ sessionTimeout, checkTimeoutFreq, lastActivity });

		// add page-level spinner
		$( '.mdl-spinner' ).addClass( 'is-active' );
		
		$(function() {

			// remove page-level spinner
			$( '.mdl-spinner' ).removeClass( 'is-active' );
			
			function logoff( cmd ) {
				
				console.log( 'logging off with cmd: ' + cmd );
				
				$.ajax({
					url: `${aspServer}/ajax/session.asp?cmd=${cmd}&userID=${userID}`,
					type: 'DELETE',
				}).done( function( response ) {
					const url = ( !!response.redirectURL ) ? response.redirectURL + '?msg=' + response.redirectMsg : 'login.asp';
					window.location.href = url;
				}).fail( function( err ) {
					console.error( 'Could not extend session' );
					console.error( err );
					window.location.href = 'login.asp?msg=Error extending session" ';
					
				});
				
			}


			let finalCountdownInterval, masterTimeoutIntervalID;
			$( "#dialog-sessionTimeout" ).dialog({
				autoOpen: false,
				resizable: false,
				height: "auto",
				width: 400,
				modal: true,
				buttons: {
					"Log Off": function() {
						logoff( 'manual' );
					},
					"Continue Session": function() {
						
						clearInterval( finalCountdownInterval );
						finalCountdownInterval = null;
												
						clearInterval( masterTimeoutIntervalID );
						masterTimeoutIntervalID = null;
						
						$.ajax({
							url: `${aspServer}/ajax/session.asp`,
							type: 'POST',
							async: false,
						}).done( function( response ) {

							console.log( 'session extended' );
// 							sessionTimeout = response.sessionTimeout;
							lastActivity = new Date( response.lastActivity );
							masterTimeoutIntervalID = setInterval( checkSessionTime, checkTimeoutFreq );

						}).fail( function( err ) {
							console.error( err );
						});

						$( this ).dialog( "close" );

					}
				},
				open: function() {

					let secondsRemaining = Math.floor((sessionTimeout * 60) - ((new Date() - lastActivity) / 1000));
					
// 					secondsRemaining -= 60;
					
					console.log( `within dialog open function`, { secondsRemaining });
					
					finalCountdownInterval = setInterval( function() {
						
						console.log( 'top of finalCountdownInterval loop, secondsRemaining: ' + secondsRemaining );
						
						if ( secondsRemaining <= 0 ) {
							console.log( 'interval in open dialog function: <= 0 secs remaining, logging off...' );
							logoff( 'timeout' );
						}
						
						let minutes = parseInt( secondsRemaining / 60, 10 );
						let seconds = parseInt( secondsRemaining % 60, 10 );
						
						minutes = minutes < 10 ? "0"+minutes : minutes;
						seconds = seconds < 10 ? "0"+seconds : seconds;
											
						$( '#countdownTimer' ).html( minutes + ":" + seconds );
						
						if ( secondsRemaining <= 0 ) {
							secondsRemaining = 0;
						} else {
							secondsRemaining = secondsRemaining - 1;
						}
						
						console.log( 'bottom of finalCountdownInterval loop, secondsRemaining: ' + secondsRemaining );

					}, 1000 );
					
				}

			});
			

		});		
		
		
		function checkSessionTime() {
			
			console.log( 'top of checkSessionTime() interval loop' );
			
			let secondsRemaining = Math.floor((sessionTimeout * 60) - ((new Date() - lastActivity) / 1000));
			
			console.log({ secondsRemaining, sessionTimeout, lastActivity });

 			console.log( `within checkSessionTime()`, { secondsRemaining } );

			if ( secondsRemaining < 120 ) {

				console.log( '< 120 secs remaining, there should be no more .logs from checkSessionTime()' );
				
				clearInterval( masterTimeoutIntervalID );
				
				if ( !$( "#dialog-sessionTimeout" ).dialog( "isOpen" ) ) {
					$( "#dialog-sessionTimeout" ).dialog( "open" );
				}
								
			}

			console.log( 'bottom of checkSessionTime() interval loop' );

		}

//		if ( scriptName !== '/login.asp' ) masterTimeoutIntervalID = setInterval( checkSessionTime, checkTimeoutFreq );	

	</script>		
	
	
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	
