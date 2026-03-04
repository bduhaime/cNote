// controllers/auth.js

module.exports.set = function( app ) {

	//====================================================================================
	app.get( '/api/auth/me', utilities.jwtVerify, ( req, res ) => {
	//====================================================================================

		// jwtVerify sets req.session = sessionInfo
		// Keep the response small and safe.
		const s = req.session ?? {};

		return res.status( 200 ).json({
			ok: true,
			userID: s.userID ?? null,
			username: s.username ?? null,
			dbName: s.dbName ?? null,
			clientNbr: s.clientNbr ?? null,
			internalUser: s.internalUser ?? null,
			exp: s.exp ?? null
		});

	});
	//====================================================================================

};
