// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

// dbConfig = require('../config/database.json').mssql;
	let db = require('../config/db.js');

	let {
		Editor,
		Field,
		Validate,
		Format,
		Options
	} = require("datatables.net-editor-server");

	//====================================================================================
	https.all('/api/roles', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		let editor = new Editor(db, 'roles').fields(
			new Field("name")
				.validator( Validate.notEmpty() )
				.validator( Validate.dbUnique(
					new Validate.Options({
						message: "Role name must be unique"
					})
				)),
			new Field("deleted")
				.setFormatter( Format.ifEmpty( null ) ),
			new Field("updatedby")
				.setFormatter( ( val, data ) => req.session.userID ),
			new Field("updateddatetime")
				.setFormatter( ( val, data ) => dayjs().format( 'YYYY-MM-DD HH:mm:ss' ) )

		);

		await editor.process( req.body );
		res.json( editor.data() );

	});
	//====================================================================================

}
