export function userActivity( server, activity, script, customer, jwt ) {

	// update userActivity table...
	
	$.ajax({
	
		type: 'POST',
		url: server + ':3000/api/users/activityLog',
		headers: { 'Authorization': 'Bearer ' + jwt },
		data: JSON.stringify({ 
			activityDescription: activity,
			scriptName: script,
			customerID: customer 
		}),
		contentType: 'application/json',
		success: function() {
			console.log('i guess that worked');
		},
		error: function( err ) {
			console.log( 'uh oh...' );
			console.log( err );
		}
	
	});
	
}
