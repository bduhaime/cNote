// ----------------------------------------------------------------------------------------
// Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

  dbConfig = require('../config/database.json').mssql;
  const utilities = require( '../utilities' );

  // NOTE:
  // pool, sql, logger appear to be globals in your app (as in your existing files).
  // This file assumes those are available (same as your current implementation).

  // -----------------------------
  // Helpers: ISO-local wall-clock
  // -----------------------------
  const isValidBigIntish = ( v ) => {
	 const n = Number( v );
	 return Number.isInteger( n ) && n > 0 && Number.isSafeInteger( n );
  };

  // Normalize:
  // - Accept "YYYY-MM-DDTHH:mm" OR "YYYY-MM-DDTHH:mm:ss(.fffffff)"
  // - Reject "Z" (UTC) to prevent silent conversion semantics
  // - Return string with seconds guaranteed (":00" added when missing)
  const normalizeIsoLocal = ( s ) => {

	 if ( s === null || s === undefined || s === '' ) return null;

	 const v = String( s ).trim();

	 if ( v.endsWith( 'Z' ) ) return null;

	 if ( /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test( v ) ) {
		return `${v}:00`;
	 }

	 if ( /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?$/.test( v ) ) {
		return v;
	 }

	 return null;

  };

  //====================================================================================
  https.get( '/api/eventDaysByEvent', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const eventID = Number( req.query.eventID );

		if ( !Number.isInteger( eventID ) || eventID <= 0 ) {
		  return res.status( 400 ).json({ ok: false, message: 'Invalid eventID' });
		}

		const SQL = `
		  select
			 id,
			 convert( varchar(33), startDateTime, 126 ) as startDateTime,
			 convert( varchar(33), endDateTime, 126 ) as endDateTime
		  from events.dbo.eventDays
		  where eventID = @eventID
		  order by startDateTime, id;
		`;

		const results = await pool
		  .request()
		  .input( 'eventID', sql.BigInt, eventID )
		  .query( SQL );

		return res.json( results.recordset );

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'GET:api/eventDaysByEvent', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.get( '/api/eventDays/:id', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const id = Number( req.params.id );

		if ( !Number.isInteger( id ) || id <= 0 ) {
		  return res.status( 400 ).json({ ok: false, message: 'Invalid eventDay id' });
		}

		const SQL = `
		  select
			 id,
			 eventID,
			 convert( varchar(33), startDateTime, 126 ) as startDateTime,
			 convert( varchar(33), endDateTime, 126 ) as endDateTime,
			 updatedBy,
			 updatedDateTime
		  from events.dbo.eventDays
		  where id = @id;
		`;

		const results = await pool
		  .request()
		  .input( 'id', sql.BigInt, id )
		  .query( SQL );

		const row = results.recordset?.[ 0 ];

		if ( !row ) return res.sendStatus( 404 );

		return res.json( row );

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'GET:api/eventDays/:id', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.post( '/api/eventDays', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const eventIDRaw = req.body?.eventID;
		if ( !isValidBigIntish( eventIDRaw ) ) {
		  return res.status( 400 ).json({ ok: false, error: 'Invalid eventID' });
		}
		const eventID = Number( eventIDRaw );

		const start = normalizeIsoLocal( req.body?.startDateTime );
		const end = normalizeIsoLocal( req.body?.endDateTime );

		if ( !start ) return res.status( 400 ).json({ ok: false, error: 'startDateTime must be ISO local like "YYYY-MM-DDTHH:mm" (seconds optional)' });

		if ( req.body?.endDateTime !== null && req.body?.endDateTime !== undefined && req.body?.endDateTime !== '' ) {
		  if ( !end ) return res.status( 400 ).json({ ok: false, error: 'endDateTime must be ISO local like "YYYY-MM-DDTHH:mm" (seconds optional) or null' });
		  if ( end < start ) return res.status( 400 ).json({ ok: false, error: 'endDateTime cannot be before startDateTime' });
		}

		const SQL = `
		  insert into events.dbo.eventDays (
			 eventID,
			 startDateTime,
			 endDateTime,
			 updatedBy,
			 updatedDateTime
		  )
		  OUTPUT INSERTED.id
		  values (
			 @eventID,
			 convert( datetime2(7), @startDateTime, 126 ),
			 case when @endDateTime is null then null else convert( datetime2(7), @endDateTime, 126 ) end,
			 @updatedBy,
			 current_timestamp
		  );
		`;

		const results = await pool.request()
		  .input( 'eventID', sql.BigInt, eventID )
		  .input( 'startDateTime', sql.VarChar( 40 ), start )
		  .input( 'endDateTime', sql.VarChar( 40 ), end )
		  .input( 'updatedBy', sql.BigInt, req.session.userID )
		  .query( SQL );

		const newId = results?.recordset?.[ 0 ]?.id;

		return res.status( 201 )
		  .location( `/api/eventDays/${newId}` )
		  .json({ ok: true, id: newId });

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'POST:api/eventDays', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.put( '/api/eventDays', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const idRaw = req.body?.id;
		if ( !isValidBigIntish( idRaw ) ) return res.status( 400 ).json({ ok: false, error: 'Missing/invalid ID parameter' });
		const id = Number( idRaw );

		const eventIDRaw = req.body?.eventID;
		if ( !isValidBigIntish( eventIDRaw ) ) return res.status( 400 ).json({ ok: false, error: 'Invalid eventID' });
		const eventID = Number( eventIDRaw );

		const start = normalizeIsoLocal( req.body?.startDateTime );
		const end = normalizeIsoLocal( req.body?.endDateTime );

		if ( !start ) return res.status( 400 ).json({ ok: false, error: 'startDateTime must be ISO local like "YYYY-MM-DDTHH:mm" (seconds optional)' });

		if ( req.body?.endDateTime !== null && req.body?.endDateTime !== undefined && req.body?.endDateTime !== '' ) {
		  if ( !end ) return res.status( 400 ).json({ ok: false, error: 'endDateTime must be ISO local like "YYYY-MM-DDTHH:mm" (seconds optional) or null' });
		  if ( end < start ) return res.status( 400 ).json({ ok: false, error: 'endDateTime cannot be before startDateTime' });
		}

		const SQL = `
		  update events.dbo.eventDays set
			 eventID = @eventID,
			 startDateTime = convert( datetime2(7), @startDateTime, 126 ),
			 endDateTime = case when @endDateTime is null then null else convert( datetime2(7), @endDateTime, 126 ) end,
			 updatedBy = @updatedBy,
			 updatedDateTime = current_timestamp
		  where id = @id;

		  select @@ROWCOUNT as rowsAffected;
		`;

		const results = await pool.request()
		  .input( 'id', sql.BigInt, id )
		  .input( 'eventID', sql.BigInt, eventID )
		  .input( 'startDateTime', sql.VarChar( 40 ), start )
		  .input( 'endDateTime', sql.VarChar( 40 ), end )
		  .input( 'updatedBy', sql.BigInt, req.session.userID )
		  .query( SQL );

		const rowsAffected = results?.recordset?.[ 0 ]?.rowsAffected ?? 0;
		if ( rowsAffected === 0 ) return res.status( 404 ).json({ ok: false, error: 'Event day not found' });

		return res.status( 200 ).json({ ok: true, message: 'Event day updated', id });

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'PUT:api/eventDays', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  // Bulk schedule save: timezone + full replacement of eventDays
  // Matches EventEdit.jsx payload: { timezoneID, days: [ { id, startDateTime, endDateTime, _delete } ] }
  //====================================================================================
  https.put( '/api/events/:eventID/days', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 const userID = req.session?.userID ?? req.user?.id;

	 try {

		if ( !userID ) return res.status( 401 ).json({ ok: false, error: 'Unauthorized' });

		const eventIDRaw = req.params.eventID ?? req.body.eventID;
		if ( !isValidBigIntish( eventIDRaw ) ) return res.status( 400 ).json({ ok: false, error: 'Invalid eventID' });
		const eventID = Number( eventIDRaw );

		// timezoneID is optional
		let timezoneID = null;

		if ( req.body?.timezoneID !== undefined && req.body?.timezoneID !== null && req.body?.timezoneID !== '' ) {

		  const timezoneIDraw = req.body.timezoneID;
		  if ( !isValidBigIntish( timezoneIDraw ) ) {
			 return res.status( 400 ).json({ ok: false, error: 'Invalid timezoneID' });
		  }

		  timezoneID = Number( timezoneIDraw );

		}

		const days = req.body?.days;
		if ( !Array.isArray( days ) ) {
		  return res.status( 400 ).json({ ok: false, error: 'Missing collection "days" (array required)' });
		}

		const normalized = [];

		for ( let i = 0; i < days.length; i++ ) {

		  const row = days[ i ] ?? {};

		  if ( row._delete ) continue;

		  const start = normalizeIsoLocal( row.startDateTime );
		  const end = normalizeIsoLocal( row.endDateTime );

		  if ( !start ) {
			 return res.status( 400 ).json({ ok: false, error: `days[${i}].startDateTime must be ISO local like "YYYY-MM-DDTHH:mm" (seconds optional)` });
		  }

		  if ( row.endDateTime !== null && row.endDateTime !== undefined && row.endDateTime !== '' ) {

			 if ( !end ) {
				return res.status( 400 ).json({ ok: false, error: `days[${i}].endDateTime must be ISO local like "YYYY-MM-DDTHH:mm" (seconds optional) or null` });
			 }

			 if ( end < start ) {
				return res.status( 400 ).json({ ok: false, error: `days[${i}].endDateTime must be >= startDateTime` });
			 }

		  }

		  normalized.push({
			 startDateTime: start,
			 endDateTime: end ?? null
		  });

		}

		const tx = new sql.Transaction( pool );
		await tx.begin( sql.ISOLATION_LEVEL.SERIALIZABLE );

		try {

		  if ( timezoneID !== null ) {

			 await new sql.Request( tx )
				.input( 'timezoneID', sql.BigInt, timezoneID )
				.input( 'eventID', sql.BigInt, eventID )
				.query( `
				  update events.dbo.events
				  set timezoneID = @timezoneID
				  where id = @eventID;
				` );

		  }

		  const deleteResult = await new sql.Request( tx )
			 .input( 'eventID', sql.BigInt, eventID )
			 .query( `
				delete from events.dbo.eventDays
				where eventID = @eventID;
			 ` );

		  const deletedCount = deleteResult.rowsAffected?.[ 0 ] ?? 0;

		  let insertedCount = 0;

		  if ( normalized.length > 0 ) {

			 const insertSQL = `
				insert into events.dbo.eventDays (
				  eventID,
				  startDateTime,
				  endDateTime,
				  updatedDateTime,
				  updatedBy
				)
				values (
				  @eventID,
				  convert( datetime2(7), @startDateTime, 126 ),
				  case when @endDateTime is null then null else convert( datetime2(7), @endDateTime, 126 ) end,
				  current_timestamp,
				  @updatedBy
				);
			 `;

			 for ( const row of normalized ) {

				await new sql.Request( tx )
				  .input( 'eventID', sql.BigInt, eventID )
				  .input( 'startDateTime', sql.VarChar( 40 ), row.startDateTime )
				  .input( 'endDateTime', sql.VarChar( 40 ), row.endDateTime )
				  .input( 'updatedBy', sql.BigInt, userID )
				  .query( insertSQL );

				insertedCount++;

			 }

		  }

		  await tx.commit();

		  return res.status( 200 ).json({
			 ok: true,
			 message: 'Schedule saved',
			 eventID,
			 deletedCount,
			 insertedCount
		  });

		} catch ( err ) {

		  try { await tx.rollback(); } catch ( rollbackErr ) { /* swallow */ }
		  throw err;

		}

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'PUT:/api/events/:eventID/days', message: err, user: ( req.session?.userID ?? req.user?.id ?? null ) });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================


  //====================================================================================
  https.delete( '/api/eventDays/:id', utilities.jwtVerify, async ( req, res ) => {
  //====================================================================================

	 try {

		const idRaw = req.params.id;

		if ( !isValidBigIntish( idRaw ) ) return res.status( 400 ).json({ ok: false, error: 'Missing/invalid ID parameter' });

		const SQL = `
		  delete from events.dbo.eventDays
		  where id = @id;
		`;

		await pool.request()
		  .input( 'id', sql.BigInt, Number( idRaw ) )
		  .query( SQL );

		return res.status( 200 ).json({ ok: true, message: 'Event day deleted' });

	 } catch ( err ) {

		logger.log({ level: 'error', label: 'DELETE:api/eventDays', message: err, user: req.session.userID });
		return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

	 }

  });
  //====================================================================================

};
