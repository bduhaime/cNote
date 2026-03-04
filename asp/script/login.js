//================================================================================
// COPYRIGHT (C) 2017-2023, POLARIS CONSULTING, LLC -- ALL RIGHTS RESERVED
//================================================================================

//================================================================================
$(document).ready( function() {
//================================================================================

	$( '#loginForm' ).submit( function( event ) {
		
		event.preventDefault();
		
		const payload = {
			username: $( '#username' ).val(),
			password: $( '#password' ).val()
		}

		$.ajax({
			type: 'POST',
			url: `${apiServer}/api/login`,
			data: JSON.stringify( payload ),
			contentType: 'application/json'
		}).done( function( data ) {

			console.log( data );
			window.location = data.redirect;

		}).fail(  function( err ) {

			console.log( 'validation failed' );
			$( '#password' ).val( '' );

		}); 

		
	});

		
});
//================================================================================


