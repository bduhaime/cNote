// ----------------------------------------------------------------------------------------
// Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;
	const utilities 	= require( '../utilities' );
	const dayjs 		= require( 'dayjs' );


	//====================================================================================
	https.get('/api/eventRegistrationsByEvent', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const eventID = Number( req.query.eventID );
			if ( !Number.isInteger( eventID ) || eventID <= 0 ) {
				return res.status( 400 ).json({ message: 'Invalid eventDays id' });
			}

			const SQL = `
				select
					r.id,
					r.eventID,
					r.customerID,
					c.name as customerName,
					cs.name as customerStatusName,
					r.title,
					r.fullName,
					r.learnerProfileID,
					lp.name as learnerProfileName,
					r.registrationDate,
					r.curriculumPlanID,
					r.payTypeID,
					pt.name as paymentTypeName,
					r.certificateCount,
					r.registrationStatusID,
					r.notes,
					r.hubspot_object_id,
					r.taggedInHubspotInd,
					r.prerequisiteOverrideReason,
					r.prerequisiteOverrideAuthorizedBy
				from events.dbo.registrations r
				left join events.dbo.learnerProfiles lp on (lp.id = r.learnerProfileID)
				left join events.dbo.registrationPaymentTypes pt on (pt.id = r.payTypeID)
				left join customer c on (c.id = r.customerID )
				left join customerStatus cs on (cs.id = c.customerStatusID )
				where eventID = @eventID;
			`;

			const results = await pool
				.request()
				.input( 'eventID', sql.BigInt, eventID )
				.query( SQL );

			return res.json( results.recordsets[0] );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/eventRegistrationsByEvent', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		}

	});
	//====================================================================================

	//====================================================================================
	https.get('/api/eventRegistrations/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const id = Number( req.params.id );

			if ( !Number.isInteger( id ) || id <= 0 ) {
				return res.status( 400 ).json({ message: 'Invalid eventDays id' });
			}

			const SQL = `
				select
					r.id,
					r.eventID,
					r.customerID,
					r.title,
					r.fullName,
					r.learnerProfileID,
					lp.name as learnerProfileName,
					r.registrationDate,
					r.curriculumPlanID,
					r.payTypeID,
					pt.name as paymentTypeName,
					r.certificateCount,
					r.registrationStatusID,
					r.notes,
					r.hubspot_object_id,
					r.taggedInHubspotInd,
					r.prerequisiteOverrideReason,
					r.prerequisiteOverrideAuthorizedBy
				from events.dbo.registrations r
				left join events.dbo.learnerProfiles lp on (lp.id = r.learnerProfileID)
				left join events.dbo.registrationPaymentTypes pt on (pt.id = r.payTypeID)
				where r.id = @id;
			`;

			const results = await pool
				.request()
				.input( 'id', sql.BigInt, id )
				.query( SQL );

			const event = results.recordset?.[ 0 ];

			if ( !event ) {
				return res.sendStatus( 404 );
			}

			return res.json( event );


		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/eventRegistrations', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		}

	});
	//====================================================================================


	//====================================================================================
	https.post('/api/eventRegistrations', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const SQL = `
				insert into events.dbo.registrations (
					eventID,
					customerID,
					title,
					fullName,
					learnerProfileID,
					registrationDate,
					curriculumPlanID,
					payTypeID,
					certificateCount,
					registrationStatusID,
					notes,
					hubspot_object_id_str,
					taggedInHubspotInd,
					prerequisiteOverrideReason,
					prerequisiteOverrideAuthorizedBy,
					updatedDateTime,
					updatedBy
				) values (
					@eventID,
					@customerID,
					@title,
					@fullName,
					@learnerProfileID,
					@registrationDate,
					@curriculumPlanID,
					@payTypeID,
					@certificateCount,
					@registrationStatusID,
					@notes,
					@hubspot_object_id_str,
					@taggedInHubspotInd,
					@prerequisiteOverrideReason,
					@prerequisiteOverrideAuthorizedBy,
					CURRENT_TIMESTAMP,
					@updatedBy
				)
			`;

			const results = await pool.request()
				.input( 'eventID', sql.BigInt, req.body.eventID )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.input( 'title', sql.VarChar(50), req.body.title )
				.input( 'fullName', sql.VarChar(255), req.body.fullName )
				.input( 'learnerProfileID', sql.BigInt, req.body.learnerProfileID )
				.input('registrationDate', sql.Date, dayjs( req.body.registrationDate ).toDate() )
				.input( 'curriculumPlanID', sql.BigInt, req.body.curriculumPlanID )
				.input( 'payTypeID', sql.BigInt, req.body.payTypeID )
				.input( 'certificateCount', sql.BigInt, req.body.certificateCount )
				.input( 'registrationStatusID', sql.BigInt, req.body.registrationStatusID )
				.input( 'notes', sql.VarChar( sql.Max ), req.body.notes )
				.input( 'hubspot_object_id_str', sql.VarChar( 20 ), req.body.hubspot_object_id_str )
				.input( 'taggedInHubspotInd', sql.Bit, req.body.taggedInHubspotInd )
				.input( 'prerequisiteOverrideReason', sql.VarChar( 50 ), req.body.prerequisiteOverrideReason )
				.input( 'prerequisiteOverrideAuthorizedBy', sql.BigInt, req.body.prerequisiteOverrideAuthorizedBy )
				.input( 'updatedBy', sql.BigInt, req.session.userID )
				.query( SQL );

			return res.status( 200 ).json({ ok: true, message: 'Event registrations inserted' });

		} catch( err ) {

			logger.log({ level: 'error', label: 'POST:api/eventRegistrations', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		}

	});
	//====================================================================================


	//====================================================================================
	https.put('/api/eventRegistrations/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.params.id ) return res.status( 400 ).json({ ok: false, error: 'Missing ID parameter' });

			const SQL = `
				update events.dbo.registrations set
					eventID = @eventID,
					customerID = @customerID,
					title = @title,
					fullName = @fullName,
					learnerProfileID = @learnerProfileID,
					registrationDate = @registrationDate,
					curriculumPlanID = @curriculumPlanID,
					payTypeID = @payTypeID,
					certificateCount = @certificateCount,
					registrationStatusID = @registrationStatusID,
					notes = @notes,
					hubspot_object_id_str = @hubspot_object_id_str,
					taggedInHubspotInd = @taggedInHubspotInd,
					prerequisiteOverrideReason = @prerequisiteOverrideReason,
					prerequisiteOverrideAuthorizedBy = @prerequisiteOverrideAuthorizedBy,
					updatedDateTime = CURRENT_TIMESTAMP,
					updatedBy = @updatedBy
				where id = @id;
			`;

			const results = await pool.request()
				.input( 'eventID', sql.BigInt, req.body.eventID )
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.input( 'title', sql.VarChar(50), req.body.title )
				.input( 'fullName', sql.VarChar(255), req.body.fullName )
				.input( 'learnerProfileID', sql.BigInt, req.body.learnerProfileID )
				.input('registrationDate', sql.Date, dayjs( req.body.registrationDate ).toDate() )
				.input( 'curriculumPlanID', sql.BigInt, req.body.curriculumPlanID )
				.input( 'payTypeID', sql.BigInt, req.body.payTypeID )
				.input( 'certificateCount', sql.BigInt, req.body.certificateCount )
				.input( 'registrationStatusID', sql.BigInt, req.body.registrationStatusID )
				.input( 'notes', sql.VarChar( sql.Max ), req.body.notes )
				.input( 'hubspot_object_id_str', sql.VarChar( 20 ), req.body.hubspot_object_id_str )
				.input( 'taggedInHubspotInd', sql.Bit, req.body.taggedInHubspotInd )
				.input( 'prerequisiteOverrideReason', sql.VarChar( 50 ), req.body.prerequisiteOverrideReason )
				.input( 'prerequisiteOverrideAuthorizedBy', sql.BigInt, req.body.prerequisiteOverrideAuthorizedBy )
				.input( 'updatedBy', sql.BigInt, req.session.userID )
				.input( 'id', sql.BigInt, req.params.id )
				.query( SQL );

			return res.status( 200 ).json({ ok: true, message: 'Event Day updated' });

		} catch( err ) {

			logger.log({ level: 'error', label: 'PUT:api/eventRegistrations', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		}

	});
	//====================================================================================


	//====================================================================================
	https.delete('/api/eventRegistrations/:id', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.params.id ) return res.status( 400 ).json({ ok: false, error: 'Missing ID parameter' });

			const SQL = `
				delete from events.dbo.registrations
				where id = @id;
			`;

			const results = await pool.request()
				.input( 'id', sql.BigInt, req.params.id )
				.query( SQL );

			return res.status( 200 ).json({ ok: true, message: 'Event day deleted' });

		} catch( err ) {

			logger.log({ level: 'error', label: 'DELETE:api/eventRegistrations', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		}

	});
	//====================================================================================

}
