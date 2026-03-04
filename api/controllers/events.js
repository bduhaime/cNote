// ----------------------------------------------------------------------------------------
// Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

  dbConfig = require('../config/database.json').mssql;
  const utilities = require( '../utilities' );

  //====================================================================================
  https.get( '/api/events', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const SQL = `
		  select
			 e.id,
			 e.name,
			 convert( varchar(33), edAgg.startDate, 126 ) as startDate,
			 convert( varchar(33), edAgg.endDate, 126 ) as endDate,
			 e.location,
			 e.isVirtual,
			 e.prerequisiteNotes,
			 e.repeatAttendancePolicy,
			 e.whoShouldAttend,
			 e.timezoneID,
			 tz.shortName as timezoneShortName,
			 e.updatedBy,
			 e.updatedDateTime
		  from events.dbo.events e
		  left join timezones tz on ( tz.id = e.timezoneID )
		  outer apply (
			 select
				min( ed.startDateTime ) as startDate,
				max( ed.startDateTime ) as endDate
			 from events.dbo.eventDays ed
			 where ed.eventID = e.id
		  ) edAgg;
		`;

		const results = await pool.request().query( SQL );

		return res.json( results.recordset );

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'GET:api/events', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.get( '/api/events/:id', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const id = Number( req.params.id );

		if ( !Number.isInteger( id ) || id <= 0 ) {
		  return res.status( 400 ).json({ message: 'Invalid event id' });
		}

		const SQL = `
		  select
			 e.id,
			 e.name,
			 convert( varchar(33), edAgg.startDate, 126 ) as startDate,
			 convert( varchar(33), edAgg.endDate, 126 ) as endDate,
			 e.location,
			 e.isVirtual,
			 e.prerequisiteNotes,
			 e.repeatAttendancePolicy,
			 e.whoShouldAttend,
			 e.timezoneID,
			 tz.shortName as timezoneShortName,
			 e.updatedBy,
			 e.updatedDateTime
		  from events.dbo.events e
		  left join timezones tz on ( tz.id = e.timezoneID )
		  outer apply (
			 select
				min( ed.startDateTime ) as startDate,
				max( ed.startDateTime ) as endDate
			 from events.dbo.eventDays ed
			 where ed.eventID = e.id
		  ) edAgg
		  where e.id = @id;
		`;

		const results = await pool
		  .request()
		  .input( 'id', sql.BigInt, id )
		  .query( SQL );

		const event = results.recordset?.[ 0 ];

		if ( !event ) return res.sendStatus( 404 );

		return res.json( event );

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'GET:api/events/:id', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.post( '/api/events', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const SQL = `
		  INSERT INTO events.dbo.events (
			 name,
			 location,
			 isVirtual,
			 prerequisiteNotes,
			 repeatAttendancePolicy,
			 whoShouldAttend,
			 updatedBy,
			 updatedDateTime
		  )
		  OUTPUT INSERTED.id
		  VALUES (
			 @name,
			 @location,
			 @isVirtual,
			 @prerequisiteNotes,
			 @repeatAttendancePolicy,
			 @whoShouldAttend,
			 @updatedBy,
			 CURRENT_TIMESTAMP
		  )
		`;

		const results = await pool.request()
		  .input( 'name', sql.VarChar( 255 ), req.body.name )
		  .input( 'location', sql.VarChar( 255 ), req.body.location || null )
		  .input( 'isVirtual', sql.Bit, req.body.isVirtual || null )
		  .input( 'prerequisiteNotes', sql.VarChar( sql.Max ), req.body.prerequisiteNotes || null )
		  .input( 'repeatAttendancePolicy', sql.VarChar( 255 ), req.body.repeatAttendancePolicy || null )
		  .input( 'whoShouldAttend', sql.VarChar( 255 ), req.body.whoShouldAttend || null )
		  .input( 'updatedBy', sql.BigInt, req.session.userID )
		  .query( SQL );

		const newId = results?.recordset?.[ 0 ]?.id;

		if ( !newId ) {
		  logger.log({ level: 'error', label: 'POST:api/events', message: 'Insert succeeded but no id returned', user: req.session.userID });
		  return res.status( 500 ).json({ ok: false, message: 'Insert succeeded but no id returned' });
		}

		return res.status( 201 )
		  .location( `/api/events/${newId}` )
		  .json({ ok: true, id: newId });

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'POST:api/events', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  // Keep THIS one (your React uses PUT /api/events/:id for event fields)
  //====================================================================================
  https.put( '/api/events/:id', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const id = Number( req.params.id );

		if ( !Number.isInteger( id ) || id <= 0 ) {
		  return res.status( 400 ).json({ ok: false, error: 'Invalid ID parameter' });
		}

		const SQL = `
		  UPDATE events.dbo.events SET
			 name = @name,
			 location = @location,
			 isVirtual = @isVirtual,
			 prerequisiteNotes = @prerequisiteNotes,
			 repeatAttendancePolicy = @repeatAttendancePolicy,
			 whoShouldAttend = @whoShouldAttend,
			 timezoneID = @timezoneID,
			 updatedBy = @updatedBy,
			 updatedDateTime = CURRENT_TIMESTAMP
		  WHERE id = @id;

		  SELECT @@ROWCOUNT AS rowsAffected;
		`;

		const results = await pool.request()
		  .input( 'id', sql.BigInt, id )
		  .input( 'name', sql.VarChar( 255 ), req.body.name )
		  .input( 'location', sql.VarChar( 255 ), req.body.location ?? null )
		  .input( 'isVirtual', sql.Bit, req.body.isVirtual )
		  .input( 'prerequisiteNotes', sql.VarChar( sql.Max ), req.body.prerequisiteNotes ?? null )
		  .input( 'repeatAttendancePolicy', sql.VarChar( 255 ), req.body.repeatAttendancePolicy ?? null )
		  .input( 'whoShouldAttend', sql.VarChar( 255 ), req.body.whoShouldAttend ?? null )
		  .input( 'timezoneID', sql.BigInt, req.body.timezoneID ?? null )
		  .input( 'updatedBy', sql.BigInt, req.session.userID )
		  .query( SQL );

		const rowsAffected = results?.recordset?.[ 0 ]?.rowsAffected ?? 0;
		if ( rowsAffected === 0 ) {
		  return res.status( 404 ).json({ ok: false, error: 'Event not found' });
		}

		return res.status( 200 ).json({ ok: true, message: 'Event updated', id });

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'PUT:api/events/:id', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.delete( '/api/events/:id', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const id = Number( req.params.id );

		if ( !Number.isInteger( id ) || id <= 0 ) {
		  return res.status( 400 ).json({ ok: false, error: 'Invalid ID parameter' });
		}

		const SQL = `
		  delete from events.dbo.events
		  where id = @id;
		`;

		await pool.request()
		  .input( 'id', sql.BigInt, id )
		  .query( SQL );

		return res.status( 200 ).json({ ok: true, message: 'Event deleted' });

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'DELETE:api/events/:id', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================

};
