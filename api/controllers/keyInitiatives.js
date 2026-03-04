// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/keyInitiatives/byCustomer', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Customer parameter missing' )
		if ( !req.query.projectID ) return res.status( 400 ).send( 'Customer parameter missing' )


		const customerID = req.query.customerID
		const customerPredicate = `where ki.customerID = ${customerID} `
		const projectID = req.query.projectID


	})
	//====================================================================================


	//====================================================================================
	https.get('/api/keyInitiatives/byProject', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.projectID ) return res.status( 400 ).send( 'Project parameter missing' )

		sql.connect(dbConfig).then( pool => {

			let SQL	= 	`select `
						+		`ki.id, `
						+		`ki.name, `
						+		`ki.description, `
						+		`format( ki.startDate, 'M/d/yyyy' ) as startDate, `
						+		`format( ki.endDate, 'M/d/yyyy' ) as endDate, `
						+		`format( ki.completeDate, 'M/d/yyyy' ) as completeDate, `
						+		`kip.projectID `
						+	`from keyInitiatives ki `
						+	`join keyInitiativeProjects kip on (kip.keyInitiativeId = ki.id and kip.projectID = @projectID )  `

			return pool.request()
				.input( 'projectID', sql.BigInt, req.query.projectID )
				.query( SQL )

		}).then( results => {

			finalResults = []
			for ( row of results.recordset ) {

				finalResults.push({
					id: row.id,
					name: utilities.filterSpecialCharacters( row.name ),
					description: utilities.filterSpecialCharacters( row.description ),
					startDate: row.startDate,
					endDate: row.endDate,
					completeDate: row.completeDate,
					projectID: row.projectID
				})

			}

			res.json( finalResults )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/tasks/', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/keyInitiatives/byTask', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.query.taskID ) return res.status( 400 ).send( 'Task parameter missing' )

		sql.connect(dbConfig).then( pool => {

			let SQL	= 	`select `
						+		`ki.id, `
						+		`ki.name, `
						+		`format( ki.completeDate, 'MM/dd/yyyy' ) as completeDate `
						+	`from keyInitiativeTasks kit `
						+	`left join keyInitiatives ki on (ki.id = kit.keyInitiativeID) `
						+	`where kit.taskID = @taskID `

			return pool.request()
				.input( 'taskID', sql.BigInt, req.query.taskID )
				.query( SQL )

		}).then( results => {

			finalResults = []

			for ( row of results.recordset ) {
				finalResults.push({
					id: row.id,
					name: utilities.filterSpecialCharacters( row.name ),
					completeDate: row.completeDate,
				})
			}

			res.json( finalResults )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/tasks/', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


}
