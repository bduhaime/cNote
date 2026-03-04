 <!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="../includes/security.asp" -->
<!-- #include file="../includes/dbug.asp" -->
<!-- #include file="../includes/dataconnection.asp" -->
<!-- #include file="../includes/userLog.asp" -->
<!-- #include file="../includes/createDisconnectedRecordset.asp" -->
<!-- #include file="../includes/userPermitted.asp" -->
<!-- #include file="../includes/systemControls.asp" -->
<!-- #include file="../includes/checkPageAccess.asp" -->
<% 
call checkPageAccess(121)
customerID = request.querystring("customerID")
	
title = session("clientID") & " - " & "cProfit Settings" 
userLog(title)

SQL = "select cProfitURI, cProfitApiKey from customer where id = " & customerID & " " 
dbug("cProfit SQL: " & SQL)
set rsURI = dataconn.execute(SQL) 
if not rsURI.eof then 
	cProfitURI = rsURI("cProfitURI")	
	cProfitApiKey = rsURI("cProfitApiKey")
else 
	cProfitURI = ""
	cProfitApiKey = ""
end if 
rsURI.close 
set rsURI = nothing 


%>
<html>

<head>
	<!-- #include file="../includes/globalHead.asp" -->

	<link rel="stylesheet" href="../jquery-ui-1.12.1/jquery-ui.min.css" />
	<link rel="stylesheet" href="cProfitStyle.css" />

	<script src="../jQuery/jquery-3.5.1.js"></script>
	<script src="../jquery-ui-1.12.1/jquery-ui.min.js"></script>
	
	<script>
		
		
		$(document).ready(function() {

			
			//--------------------------------------------------------------------------------------------
			$( 'button.cProfitPiiStatus' ).click( async function( event ) {
			//--------------------------------------------------------------------------------------------

				event.preventDefault();
				
				const cProfitURI 		= '<% =cProfitURI %>';
				const cProfitApiKey 	= '<% =cProfitApiKey %>';
				const cProfitAlive 	=  await ping_cProfit( cProfitURI, cProfitApiKey );

				const apiStatus		= sessionStorage.getItem( 'apiStatus' );

				if ( cProfitAlive ) {

					if ( apiStatus === 'disabled' ) {
						
						// Enabled radiobutton is clickable
						// Disabled radiobutton is checked and clickable
						// Save button is clickable

						$( '#piiRadio-1' ).prop( 'checked', false ).button( 'refresh' );
						$( '#piiRadio-2' ).prop( 'checked', true ).button( 'refresh' );
						$( '.piiStatusRadioButton' ).checkboxradio({ disabled: false });
						$( '.ui-dialog-buttonpane button:contains("Save")' ).button( 'enable' );
						
						
					} else {
						
						// Enabled radiobutton is checked and clickable
						// Disabled button is clickable
						// Save button is clickable

						$( '#piiRadio-1' ).prop( 'checked', true ).button( 'refresh' );
						$( '#piiRadio-2' ).prop( 'checked', false ).button( 'refresh' );
						$( '.piiStatusRadioButton' ).checkboxradio({ disabled: false });
						$( '.ui-dialog-buttonpane button:contains("Save")' ).button( 'enable' );
					}
					
				} else {
					
					// Enabled radiobutton is not clickable
					// Disabled radiobutton is checked and is not clicable
					// Save button is not clickable

					$( '#piiRadio-1' ).prop( 'checked', false ).button( 'refresh' );
					$( '#piiRadio-2' ).prop( 'checked', true ).button( 'refresh' );
					$( '.piiStatusRadioButton' ).checkboxradio({ disabled: true });
					$( '.ui-dialog-buttonpane button:contains("Save")' ).button( 'disable' );
					
				}
								
				$( '#dialog-cProfitPiiStatus' ).dialog('open');


			});


			
			//--------------------------------------------------------------------------------------------
			$( '#dialog-cProfitPiiStatus' ).dialog({
			//--------------------------------------------------------------------------------------------
				autoOpen: false,
				modal: false,
// 				height: 450,
				resizable: false,
				width: 450,
				buttons: [
					{
						text: 'Save',
						class: 'save',
						click: async function() {

							var updatedStatus = await SavePiiServerStatus();
							$( this ).dialog('close');

						}
					},
					{
						text: 'Cancel',
						autoFocus: false,
						click: function() {
							$( this ).dialog('close');
						}
					}
				]
			});
			
			

			//--------------------------------------------------------------------------------------------
			$( 'button.accountHolderDisplayOptions' ).click( function( event ) {
			//--------------------------------------------------------------------------------------------

				event.preventDefault();
				
				const systemControlName = 'cProfit Account Holder Display Options';
				
				GetAccountHolderDisplayOptions( systemControlName );

				$( '#dialog-accountHolderDisplayOptions' ).dialog('open');

			});


			
			//--------------------------------------------------------------------------------------------
			$( '#dialog-accountHolderDisplayOptions' ).dialog({
			//--------------------------------------------------------------------------------------------
				autoOpen: false,
				modal: false,
// 				height: 450,
				resizable: false,
				width: 450,
				buttons: [
					{
						text: 'Save',
						click: function() {

							const leadingOption 	= $(this).find( '#leadingCharacters' ).val()
							const trailingOption 	= $(this).find( '#trailingCharacters' ).val();
							
							SaveAccountHolderDisplayOptions( leadingOption, trailingOption );

						}
					},
					{
						text: 'Cancel',
						autoFocus: false,
						click: function() {
							$( this ).dialog('close');
						}
					}
				]
			});
			
			

			$( '#leadingCharacters' ).selectmenu();
			$( '#trailingCharacters' ).selectmenu();
			$( "input" ).checkboxradio();
			
			
		});


		
		//--------------------------------------------------------------------------------------------
		async function SaveAccountHolderDisplayOptions( leading, trailing ) {
		//--------------------------------------------------------------------------------------------
			
			const url 	= 'ajax/systemControls.asp';
			
			const form 	= 'name=cProfit_Account_Holder_Display_Options'
									+ '&value=' + leading + ',' + trailing;
			
			const apiResponse = await fetch( url, {
				method: 'POST',
				headers: { 'Content-type': 'application/x-www-form-urlencoded' },
				body: form
			});
			
			if (apiResponse.status !== 200) {
				return generateErrorResponse('Failed to save system controls; ' + apiResponse.status);
			}
			
			var apiResult = await apiResponse.json();
			
			const notification = $( '.mdl-js-snackbar' ).get(0);		
			notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
			
		}
		

		//--------------------------------------------------------------------------------------------
		async function SavePiiServerStatus() {
		//--------------------------------------------------------------------------------------------
			
			var value;
			if ( $( '#piiRadio-1' ).prop( 'checked' ) ) {
				value = 'enabled';
			} else {
				value = 'disabled';
			}
			
			sessionStorage.setItem( 'apiStatus', value );


// 			const url 	= 'ajax/systemControls.asp';
// 			
// 			const form 	= 'name=cProfit_PII_Server_Status_Emulation'
// 									+ '&value=' + value;
// 			
// 			const apiResponse = await fetch( url, {
// 				method: 'POST',
// 				headers: { 'Content-type': 'application/x-www-form-urlencoded' },
// 				body: form
// 			});
// 			
// 			if (apiResponse.status !== 200) {
// 				return generateErrorResponse('Failed to save system controls; ' + apiResponse.status);
// 			}
// 			
// 			var apiResult = await apiResponse.json();
			
			const notification = $( '.mdl-js-snackbar' ).get(0);		
			notification.MaterialSnackbar.showSnackbar({ message: 'cProfit PII API status saved to session' });
			
		}
		

		//--------------------------------------------------------------------------------------------
		async function GetPiiServerStatus() {
		//--------------------------------------------------------------------------------------------

			const apiResponse = await fetch( 'ajax/systemControls.asp?name=cProfit PII Server Status Emulation' );
			if ( apiResponse.status != 200 ) {
				return generateErrorResponse('Failed to get PII Server Status, ' + apiResponse.status);
			}			
			const apiResult = await apiResponse.json();
			
			const responseName = apiResult.name;
			const responseValue = apiResult.value;
			
			return responseValue;
			
						
		}



		//--------------------------------------------------------------------------------------------
		async function GetAccountHolderDisplayOptions( systemControlName ) {
		//--------------------------------------------------------------------------------------------

			const apiResponse = await fetch( 'ajax/systemControls.asp?name='+systemControlName );
			if ( apiResponse.status != 200 ) {
				return generateErrorResponse('Failed to get account holder flags, ' + apiResponse.status);
			}			
			const apiResult = await apiResponse.json();
			
			const responseName = apiResult.name;
			const responseValues = apiResult.value.split(',');
			
			$( '#leadingCharacters' ).val( responseValues[0] );
			$( '#leadingCharacters' ).selectmenu( 'refresh' );

			$( '#trailingCharacters' ).val( responseValues[1] ).change();
			$( '#trailingCharacters' ).selectmenu( 'refresh' );
			
		}



		//-- ------------------------------------------------------------------ -->
		function generateErrorResponse(message) {
		//-- ------------------------------------------------------------------ -->
		
			return {
				status : 'error',
				message
			};
		
		}


		//-- ------------------------------------------------------------------ -->
		async function ping_cProfit( uri, apikey ) {
		//-- ------------------------------------------------------------------ -->

			try {	
						
				let responseValue = false;
				
				await $.ajax({
					url: `${uri}/ping`,
					headers: { 'apikey': apikey }
				}).then( function( response ) {
					responseValue = true;
				}).fail( function( req, status, err ) {
					responseValue = false;
				});
				
				return responseValue;

			} catch ( err ) {
				
				return false;
				
			}

		}	
		
		
			
					
	</script>
	

	<style>
	.demo-list-icon {
	  width: 300px;
	}

	.not-active {
	  pointer-events: none;
	  cursor: default;
	  text-decoration: none;
	  color: black;
	}
	
	ul.cprofitSettings {
		width: 100%;
	}

	</style>

</head>

<body>

<!-- Always shows a header, even in smaller screens. -->
<!-- #include file="../includes/mdlLayoutHeader.asp" -->


<!-- DIALOG: For virtually toggling PII Server Status -->
<div id="dialog-cProfitPiiStatus" title="PII Server Status">
	<p class="validateTips">Enable/disable cProfit's demo PII server</p>
	<hr>
	<p>
		<label for="piiRadio-1">Enabled</label>
		<input type="radio" name="piiRadio" id="piiRadio-1" class="piiStatusRadioButton">
		<label for="piiRadio-2">Disabled</label>
		<input type="radio" name="piiRadio" id="piiRadio-2" class="piiStatusRadioButton">
	</p>
</div>


<!-- DIALOG: For Setting Account Holder Display Options -->
<div id="dialog-accountHolderDisplayOptions" title="Account Holder Display Options">
	<p class="validateTips">Indicate how account holder tokens should be displayed for users that don't have permission or access to see account holders PII.</p>
	<hr>
	<p>
		<label for="leadingCharacters">Leading:</label>
		<select id="leadingCharacters">
			<option value="0">None</option>
			<option value="4">4 Characters</option>
			<option value="6">6 Characters</option>
			<option value="8">8 Characters</option>
		</select>
	</p>
	
	<p>
		<label for="trailingCharacters">Trailing:</label>
		<select id="trailingCharacters">
			<option value="0">None</option>
			<option value="4">4 Characters</option>
			<option value="6">6 Characters</option>
			<option value="8">8 Characters</option>
		</select>
	</p>
		
</div>

	
	

<main class="mdl-layout__content">
	<div class="page-content">
	<!-- Your content goes here -->

		<div id="mdl-snackbar-container" class="mdl-snackbar mdl-js-snackbar">
		    <div class="mdl-snackbar__text"></div>
		    <button id="mdl-show-snackbar" type="button" class="mdl-snackbar__action"></button>
		</div>

	 	 
   	<div class="mdl-grid">

			<div class="mdl-layout-spacer"></div>

			<div class="mdl-cell mdl-cell--3-col">
			 
				<ul class="demo-list-icon mdl-list cprofitSettings">
	
					<% if userPermitted(125) then %>
						<li class="mdl-list__item">
							<span class="mdl-list__item-primary-content">
								<i class="material-icons mdl-list__item-icon">enhanced_encryption</i>
								<button class="ui-button ui-widget ui-corner-all accountHolderDisplayOptions">Account Holder Display Options...</button>
							</span>
						</li>
					<% end if %>

					<% if userPermitted(126) then %>
						<li class="mdl-list__item">
							<span class="mdl-list__item-primary-content">
								<i class="material-icons mdl-list__item-icon">lock</i>
								<button class="ui-button ui-widget ui-corner-all cProfitPiiStatus">cProfit PII Server...</button>
							</span>
						</li>
					<% end if %>
	
					<% if userPermitted(124) then %>
						<li class="mdl-list__item">
							<span class="mdl-list__item-primary-content">
								<i class="material-icons mdl-list__item-icon">flag</i>
								<a href="accountHolderFlagList.asp?customerID=<% =customerID %>" nowrap>Account&nbsp;Holder&nbsp;Flags</a>
							</span>
						</li>
					<% end if %>
	
					<% if userPermitted(122) then %>
						<li class="mdl-list__item">
							<span class="mdl-list__item-primary-content">
								<i class="material-icons mdl-list__item-icon">business</i>
								<a href="cProfitTop100SurveyQuestions.asp?customerID=<% =customerID %>&surveyType=1">Firmographic Questions</a>
							</span>
						</li>
					<% end if %>
	
					<% if userPermitted(123) then %>
						<li class="mdl-list__item">
							<span class="mdl-list__item-primary-content">
							<i class="material-icons mdl-list__item-icon">portrait</i>
							<a href="cProfitTop100SurveyQuestions.asp?customerID=<% =customerID %>&surveyType=2">Psychographic Questions</a>
							</span>
						</li>
					<% end if %>

				</ul>		    			    

			</div>

			<div class="mdl-layout-spacer"></div>

		</div> <!-- end grid -->

	   
</main>
<!-- #include file="../includes/pageFooter.asp" -->


</body>
</html>