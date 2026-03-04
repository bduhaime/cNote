// ----------------------------------------------------------------------------------------
// Copyright 2017-2022, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

// 	//====================================================================================
// 	https.get('/api/customerCallNoteHistory', utilities.jwtVerify, (req, res) => {
// 	//====================================================================================
//
// 		if ( !req.query.updatedBy ) return res.status( 400 ).send( 'updatedBy parameter missing' )
// 		if ( !req.query.updatedDateTime ) return res.status( 400 ).send( 'updatedDateTime parameter missing' )
//
// 		let SQL 	=	`select narrative `
// 					+	`from customerCallNotes_history `
// 					+	`where updatedBy = @updatedBy `
// 					+	`and updatedDateTime = @updatedDateTime `
//
// 		sql.connect( dbConfig ).then( pool => {
//
// 			return pool.request()
// 				.input( 'updatedBy', sql.BigInt, req.query.updatedBy )
// 				.input( 'updatedDateTime', sql.DateTime, req.query.updatedDateTime )
// 				.query( SQL )
//
// 		}).then( result => {
//
// 			res.json( result.recordset[0] )
//
// 		}).catch( err => {
//
// 			logger.log({ level: 'error', label: 'api/customerCallNoteHistory', message: err, user: req.session.username })
// 			return res.status( 500 ).send( 'Unexpected database error' )
//
// 		})
//
// 	})
// 	//====================================================================================
//

	//====================================================================================
	https.get('/api/customerCallNoteHistory/:noteID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.noteID ) return res.status( 400 ).send( 'noteID parameter missing' )

		let SQL 	=	`select `
					+		`ccn.id, `
					+		`ccn.narrative, `
					+		`ccn.updatedBy, `
					+		`ccn.updatedDateTime, `
					+		`concat(u.firstName, ' ', u.lastName) as userFullName, `
					+		`u.username `
					+	`from customerCallNotes ccn `
					+	`left join csuite..users u on (u.id = ccn.updatedBy) `
					+	`where ccn.id = @noteID `
					+	`union all `
					+	`select `
					+		`ccn.id, `
					+		`ccn.narrative, `
					+		`ccn.updatedBy, `
					+		`ccn.updatedDateTime, `
					+		`concat(u.firstName, ' ', u.lastName) as userFullName, `
					+		`u.username `
					+	`from customerCallNotes_history ccn `
					+	`left join csuite..users u on (u.id = ccn.updatedBy) `
					+	`where ccn.id = @noteID `
					+	`order by updatedDateTime desc `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'noteID', sql.BigInt, req.params.noteID )
				.query( SQL )

		}).then( result => {

			finalResults = []
			for ( row of result.recordset ) {

				finalResults.push({
					id: row.id,
					narrative: utilities.filterSpecialCharacters( row.narrative ),
					updatedBy: row.updatedBy,
					updatedDateTime: dayjs( row.updatedDateTime ).format( 'YYYY-MM-DD hh:mm:ss A'),
					userFullName: row.userFullName,
					username: row.username
				})

			}

			res.json( finalResults )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCallNotes/:id/history', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.post( '/api/customerCallNoteHistory/makeCurrent', utilities.jwtVerify, (req, res) => {
	//====================================================================================




	});
	//====================================================================================


}
