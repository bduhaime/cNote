//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

"use strict";
var request = null;

/*****************************************************************************************/
async function RemoveTaskKeyInitiative(keyInitiativeID, taskID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/taskKeyInitiatives.asp';
	const form 	= 'keyInitiativeID=' + keyInitiativeID
							+ '&taskID=' + taskID;
	
	const response = await fetch(url, {
		method: 'DELETE',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to disassociate task and KI; response: ' + response.status);
	}
	
	var result = await response.json();
	
	if ( result.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});
	}


}


/*****************************************************************************************/
async function AddTaskKeyInitiative(keyInitiativeID, taskID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/taskKeyInitiatives.asp';
	const form 	= 'keyInitiativeID=' + keyInitiativeID
							+ '&taskID=' + taskID;
	
	const response = await fetch(url, {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to associate task and KI; response: ' + response.status);
	}
	
	var result = await response.json();
	
	if ( result.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});
	}


}

	
/*****************************************************************************************/
async function AddProjectKeyInitiative(keyInitiativeID, projectID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/projectKeyInitiatives.asp';
	const form 	= 'keyInitiativeID=' + keyInitiativeID
							+ '&projectID=' + projectID;
	
	const response = await fetch(url, {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to associate project and KI; response: ' + response.status);
	}
	
	var result = await response.json();
	
	// update UI here...
	
	if ( result.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});
	}


}

	
/*****************************************************************************************/
async function RemoveProjectKeyInitiative(keyInitiativeID, projectID) {
/*****************************************************************************************/
	
	const url 	= 'ajax/projectKeyInitiatives.asp';
	const form 	= 'keyInitiativeID=' + keyInitiativeID
							+ '&projectID=' + projectID;
	
	const response = await fetch(url, {
		method: 'DELETE',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (response.status !== 200) {
		return generateErrorResponse('Failed to disassociate project and KI; response: ' + response.status);
	}
	
	var result = await response.json();
	
	// update UI here...
	
	if ( result.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: result.msg});
	}


}


/*****************************************************************************************/
function kiDelete_OnClick( htmlElement ) {
/*****************************************************************************************/
	
	const row 	= $( htmlElement ).closest('TR');
	const data 	= $( '#tbl_keyInitiatives' ).DataTable().row( row ).data();

	$( '#dialog-confirm' ).find( 'p' ).text( 'The key initiative, "' + data[ 'kiName' ] + '," will be permanently deleted and cannot be recovered. Are you sure?' );
	$( '#dialog-confirm' ).find( 'input#id' ).val( data[ 'DT_RowId' ] );
	$( '#dialog-confirm' ).find( 'input#customerID' ).val( data[ 'customerID' ] );

	$( '#dialog-confirm' ).dialog( 'open' );


}


/*****************************************************************************************/
async function DeleteKI( dialog ) {
/*****************************************************************************************/

	$( '.ui-state-error' ).removeClass( 'ui-state-error' );
	$( dialog ).dialog( 'close' );


	var id				= dialog.querySelector( '#id' ).value;
	var customerID		= dialog.querySelector( '#customerID' ).value;

	const url 	= 'ajax/keyInitiatives.asp';
	const body 	= 'customerID=' + customerID + '&id=' + id;

	const apiResponse = await fetch( url, {
		method: 'DELETE',
		headers: { 'Content-type': 'application/x-www-form-urlencoded' },
		body: body
	});
	
	if ( apiResponse.status != 200 ) {
		return generateErrorResponse('failed to DELETE key initiative, ' + apiResponse.status);	
	}

	const apiResult = await apiResponse.json();
	
	const notification = $( '.mdl-js-snackbar' ).get(0);
	
	notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

	$( '#tbl_keyInitiatives' ).DataTable().ajax.reload();		
	

	
}


/*****************************************************************************************/
function ToggleActionIcons(trElement) {
/*****************************************************************************************/


	var editButton = trElement.querySelector('i.edit');
	if ( editButton ) {
		if ( editButton.style.visibility == 'visible' ) {
			editButton.style.visibility = 'hidden';
		} else {
			editButton.style.visibility = 'visible';			
		}
	}

	var deleteButton = trElement.querySelector('i.delete');
	if ( deleteButton ) {
		if ( deleteButton.style.visibility == 'visible' ) {
			deleteButton.style.visibility = 'hidden';
		} else {
			deleteButton.style.visibility = 'visible';			
		}
	}


}


/*****************************************************************************************/
async function AddKeyInitiative_OnSave( jQuery_dialog ) {
/*****************************************************************************************/
	
	var dialog, form, 
		id					= $( '#id' ),
		customerID		= $( '#customerID' ),
		name				= $( '#name' ),
		description		= $( '#description' ),
		startDate		= $( '#startDate' ),
		endDate			= $( '#endDate' ),
		completeDate	= $( '#completeDate' ),
		allFields		= $( [] ).add( name ).add( description ).add( startDate ).add( endDate ).add( completeDate ),
		tips				= $( '.validateTips' );


	//-----------------------------------------------------------------------//
	function UpdateTips( t ) {
	//-----------------------------------------------------------------------//

		tips
			.text( tips.text() + ' ' + t )
			.addClass( "ui-state-highlight" );

		setTimeout(function() {
			tips.removeClass( "ui-state-highlight", 1500 );
		}, 500 );

	}
   
   
	//-----------------------------------------------------------------------//
   function CheckRequiredField( object, name, type ) {
	//-----------------------------------------------------------------------//
	   
	 	if ( object.val() ) {

		   if ( type === 'date' ) {

			   if ( !moment( object.val() ).isValid() ) {
				   object.addClass( 'ui-state-error' );
				   UpdateTips( name + ' must be a valid date. ' );
				   return false;
			   } else {
			   	return true;
			   }

		   } else {

			   return true;

		   }

		} else {

		   object.addClass( 'ui-state-error' );
		   UpdateTips( name + ' is required. ' );
		   return false;

		}
	   
	}
   
   
	//-----------------------------------------------------------------------//
   function CheckOptionalField( object, name, type ) {
	//-----------------------------------------------------------------------//

		if ( object.val() ) {
		   if ( type === 'date' ) {
			   if ( !moment( object.val() ).isValid() ) {
				   object.addClass( 'ui-state-error' );
				   UpdateTips( name + ' must be a valid date. ' );
				   return false;
			   } else {
			   	return true;
			   }
		   } else {
			   return true;
		   }
		} else {
			return true;
		}
	}


	//-----------------------------------------------------------------------//
   function CheckStartEndDates( objStartDate, objEndDate ) {
	//-----------------------------------------------------------------------//

	   if ( moment( objStartDate.val() ).isAfter( moment( objEndDate.val() ) ) ) {
		   objStartDate.addClass( 'ui-state-error' );
		   objEndDate.addClass( 'ui-state-error' );
		   UpdateTips( 'Start date must proceed end date. ' );
		   return false;
	   } else {
	   	return true;
	   }
    
	}

	$( '.ui-state-error' ).removeClass( 'ui-state-error' );
	tips.text('');
	
	var reqNameValid 				= CheckRequiredField( name, 'Name', 'text' );
	var reqStartDateValid 		= CheckRequiredField( startDate, 'Start Date', 'date' );
	var reqEndDateValid			= CheckRequiredField( endDate, 'End Date', 'date' );
	var reqDatesValid				= CheckStartEndDates( startDate, endDate );
	var optCompleteDateValid	= CheckOptionalField( completeDate, 'Complete Date', 'date' );
	
	var valid = true;
	
	valid = valid && reqNameValid;
	valid = valid && reqStartDateValid;
	valid = valid && reqEndDateValid;
	valid = valid && reqDatesValid;
	valid = valid && optCompleteDateValid;
	
	if ( !valid ) {		
		return valid;
	}
	
	
	const url 	= 'ajax/keyInitiatives.asp';
	const body 	= 'cmd=addKeyInitiative'
							+ '&customerID=' + customerID.val()
							+ '&id=' + id.val()
							+ '&name=' + encodeURIComponent( name.val() )
							+ '&description=' + encodeURIComponent (description.val() )
							+ '&startDate=' + startDate.val()
							+ '&endDate=' + endDate.val()
							+ '&completeDate=' + completeDate.val();

	const apiResponse = await fetch( url, {
		method: 'POST',
		headers: { 'Content-type': 'application/x-www-form-urlencoded' },
		body: body
	});
	
	if ( apiResponse.status != 200 ) {
		return generateErrorResponse('failed to POST Key Initiative, ' + apiResponse.status);	
	}

	const apiResult = await apiResponse.json();
	
	const notification = $( '.mdl-js-snackbar' ).get(0);
	
	notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});

	$( jQuery_dialog ).dialog( 'close' );

	$( '.ui-state-error' ).removeClass( 'ui-state-error' );
	$( 'input' ).val( '' );	
	$( 'textarea' ).val( '' );	
	$( '#startDate' ).datepicker( 'option', 'maxDate', null );
	$( '#endDate' ).datepicker( 'option', 'minDate', null );

	$( '#tbl_keyInitiatives' ).DataTable().ajax.reload();
	
}


/*****************************************************************************************/
function generateErrorResponse(message) {
/*****************************************************************************************/

	return {
		status : 'error',
		message
	};

}


/*****************************************************************************************/
function GetInnerText (node) {
/*****************************************************************************************/

	return (node.textContent || node.innerText || node.text) ;

}
