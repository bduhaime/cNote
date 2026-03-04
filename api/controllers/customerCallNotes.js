// ----------------------------------------------------------------------------------------
// Copyright 2017-2022, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.post('/api/customerCallnotes', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.noteID ) return res.status( 400 ).send( 'noteID parameter missing' )
		if ( !req.body.contents ) return res.status( 400 ).send( 'contents parameter missing' )
		if ( !req.body.html ) return res.status( 400 ).send( 'html parameter missing' )

		let SQL 	=	`update customerCallNotes set `
					+		`updatedBy = @userID, `
					+		`updatedDateTime = CURRENT_TIMESTAMP, `
					+		`narrative = @narrative, `
					+		`narrativeHTML = @narrativeHTML `
					+	`where id = @noteID `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'noteID', sql.BigInt, req.body.noteID )
				.input( 'userID', sql.BigInt, req.session.userID )
				.input( 'narrative', sql.VarChar( sql.MAX ), req.body.contents )
				.input( 'narrativeHTML', sql.VarChar( sql.MAX ), req.body.html )
				.query( SQL )

		}).then( result => {

			return res.status( 200 ).send( 'Customer call note saved' )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/customerCallnotes', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================

	//====================================================================================
	https.get('/api/customerCallNotes/byCall', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.callID ) return res.status( 400 ).send( 'callID parameter missing' )

		let SQL 	=	`select  `
					+		`cn.id, `
					+		`cn.name, `
					+		`cn.noteTypeID, `
					+		`cn.quillID, `
					+		`cn.narrative, `
					+		`cn.updatedDateTime, `
					+		`ct.includeWithEmails, `
					+		`cnh.callNoteHistoryCount `
					+	`from customerCallNotes cn `
					+	`left join noteTypes ct on (ct.id = cn.noteTypeID) `
					+	`left join ( `
					+		`select id, count(*) as callNoteHistoryCount `
					+		`from customerCallNotes_history `
					+		`group by id `
					+	`) as cnh on (cnh.id = cn.id) `
					+	`where cn.customerCallID = @callID `
					+	`order by cn.seq `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'callID', sql.BigInt, req.query.callID )
				.query( SQL )

		}).then( result => {

			finalResults = []
			for ( row of result.recordset ) {

				finalResults.push({
					id: row.id,
					name: row.name,
					noteTypeID: row.noteTypeID,
					quillID: row.quillID,
					narrative: utilities.filterSpecialCharacters( row.narrative ),
					udpatedDateTime: row.updatedDateTime,
					includeWithEmails: row.includeWithEmails,
					callNoteHistoryCount: row.callNoteHistoryCount
				})

			}

			res.json( finalResults )

		}).catch( err => {
			console.error( err )
			logger.log({ level: 'error', label: 'customerCalls/:callID/callNotes', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/customerCallNotes/currentNote', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.noteID ) return res.status( 400 ).send( 'noteID parameter missing' )

		let SQL 	=	`select  `
					+		`cn.id, `
					+		`cn.name, `
					+		`cn.noteTypeID, `
					+		`cn.quillID, `
					+		`cn.narrative, `
					+		`cn.updatedDateTime, `
					+		`ct.includeWithEmails `
					+	`from customerCallNotes cn `
					+	`left join noteTypes ct on (ct.id = cn.noteTypeID) `
					+	`where cn.id = @noteID `

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'noteID', sql.BigInt, req.query.noteID )
				.query( SQL )

		}).then( result => {

			finalResults = []
			for ( row of result.recordset ) {

				finalResults.push({
					id: row.id,
					name: row.name,
					noteTypeID: row.noteTypeID,
					quillID: row.quillID,
					narrative: utilities.filterSpecialCharacters( row.narrative ),
					udpatedDateTime: row.updatedDateTime,
					includeWithEmails: row.includeWithEmails,
					callNoteHistoryCount: row.callNoteHistoryCount
				})

			}

			res.json( finalResults )

		}).catch( err => {

			logger.log({ level: 'error', label: 'customerCalls/:callID/callNotes', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


}
