import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { apiFetch } from '../api';

export default function EventEdit() {

  const { id } = useParams();
  const navigate = useNavigate();

  const EVENTS_DETAIL_URL = `/api/events/${id}`;
  const TIMEZONES_URL = '/api/timezones';
  const EVENT_DAYS_LIST_URL = `/api/eventDaysByEvent?eventID=${encodeURIComponent( id )}`;
  const EVENT_DAYS_SAVE_URL = `/api/events/${id}/days`;

  const [ loading, setLoading ] = useState( true );
  const [ error, setError ] = useState( null );

  const [ savingEvent, setSavingEvent ] = useState( false );
  const [ savingSchedule, setSavingSchedule ] = useState( false );

  const [ timezones, setTimezones ] = useState( [] );
  const [ tzLoading, setTzLoading ] = useState( true );

  const [ form, setForm ] = useState({
	 name: '',
	 location: '',
	 isVirtual: false,
	 prerequisiteNotes: '',
	 repeatAttendancePolicy: '',
	 whoShouldAttend: '',
	 timezoneID: ''
  });

  // [{ id, date, startTime, endTime, _dirty, _delete, _isNew }]
  const [ days, setDays ] = useState( [] );
  const [ scheduleError, setScheduleError ] = useState( null );

  const set = ( key, value ) => setForm( ( prev ) => ( { ...prev, [ key ]: value } ) );

  const tzDisplay = ( v ) => String( v ?? '' ).trim();

  async function safeJson( res ) {
	 try { return await res.json(); } catch { return null; }
  }

  // -------------------------
  // helpers (schedule)
  // -------------------------
  const isValidDatePart = ( s ) => typeof s === 'string' && /^\d{4}-\d{2}-\d{2}$/.test( s );
  const isValidTimePart = ( s ) => typeof s === 'string' && /^\d{2}:\d{2}$/.test( s );

  const timeToMinutes = ( hhmm ) => {
	 if ( !isValidTimePart( hhmm ) ) return null;
	 const [ h, m ] = hhmm.split( ':' ).map( ( x ) => Number( x ) );
	 if ( !Number.isInteger( h ) || !Number.isInteger( m ) ) return null;
	 if ( h < 0 || h > 23 ) return null;
	 if ( m < 0 || m > 59 ) return null;
	 return ( h * 60 ) + m;
  };

  const durationText = ( startTime, endTime ) => {

	 const s = timeToMinutes( startTime );
	 const e = timeToMinutes( endTime );

	 if ( s === null || e === null ) return '';

	 const mins = Math.max( 0, e - s );
	 const h = Math.floor( mins / 60 );
	 const m = mins % 60;

	 if ( h === 0 ) return `${m}m`;
	 if ( m === 0 ) return `${h}h`;
	 return `${h}h ${m}m`;

  };

  const splitIsoToParts = ( iso ) => {

	 const s = String( iso ?? '' ).trim();
	 if ( !s ) return { date: '', time: '' };

	 const noZ = s.endsWith( 'Z' ) ? s.slice( 0, -1 ) : s;

	 const date = noZ.slice( 0, 10 );
	 const time = noZ.length >= 16 ? noZ.slice( 11, 16 ) : '';

	 return {
		date: isValidDatePart( date ) ? date : '',
		time: isValidTimePart( time ) ? time : ''
	 };

  };

  // ✅ Always include seconds ":00"
  const buildIsoLocal = ( date, time ) => {
	 if ( !isValidDatePart( date ) ) return null;
	 if ( !isValidTimePart( time ) ) return null;
	 return `${date}T${time}:00`;
  };

  // -------------------------
  // load event + timezones + days
  // -------------------------
  useEffect( () => {

	 ( async () => {

		setLoading( true );
		setError( null );
		setScheduleError( null );
		setTzLoading( true );

		try {

		  const [ eventRes, tzRes, daysRes ] = await Promise.all([
			 apiFetch( EVENTS_DETAIL_URL ),
			 apiFetch( TIMEZONES_URL ),
			 apiFetch( EVENT_DAYS_LIST_URL )
		  ]);

		  if ( eventRes.status === 404 ) throw new Error( 'Event not found' );

		  const eventJson = await safeJson( eventRes );
		  if ( !eventRes.ok ) throw new Error( eventJson?.error ?? eventJson?.message ?? `HTTP ${eventRes.status}` );

		  const tzJson = await safeJson( tzRes );
		  if ( !tzRes.ok ) throw new Error( tzJson?.error ?? tzJson?.message ?? `HTTP ${tzRes.status}` );

		  const daysJson = await safeJson( daysRes );
		  if ( !daysRes.ok ) throw new Error( daysJson?.error ?? daysJson?.message ?? `HTTP ${daysRes.status}` );

		  const tzList = Array.isArray( tzJson ) ? tzJson : [];
		  setTimezones( tzList );

		  setForm({
			 name: eventJson?.name ?? '',
			 location: eventJson?.location ?? '',
			 isVirtual: !!eventJson?.isVirtual,
			 prerequisiteNotes: eventJson?.prerequisiteNotes ?? '',
			 repeatAttendancePolicy: eventJson?.repeatAttendancePolicy ?? '',
			 whoShouldAttend: eventJson?.whoShouldAttend ?? '',
			 timezoneID: eventJson?.timezoneID ? String( eventJson.timezoneID ) : ''
		  });

		  const list = Array.isArray( daysJson ) ? daysJson : [];
		  setDays(
			 list.map( ( d ) => {

				const s = splitIsoToParts( d.startDateTime );
				const e = splitIsoToParts( d.endDateTime );

				return {
				  id: d.id,
				  date: s.date,
				  startTime: s.time,
				  endTime: e.time,
				  _dirty: false,
				  _delete: false,
				  _isNew: false
				};

			 } )
		  );

		} catch ( err ) {

		  setError( err?.message ?? String( err ) );

		} finally {

		  setLoading( false );
		  setTzLoading( false );

		}

	 })();

  }, [ id ] );

  // -------------------------
  // timezones sorted by displayName
  // -------------------------
  const sortedTimezones = useMemo( () => {

	 const list = [ ...timezones ];

	 list.sort( ( a, b ) => {
		const av = String( a?.displayName ?? '' ).toLowerCase();
		const bv = String( b?.displayName ?? '' ).toLowerCase();
		if ( av < bv ) return -1;
		if ( av > bv ) return 1;
		return 0;
	 });

	 return list;

  }, [ timezones ] );

  // -------------------------
  // event validation
  // -------------------------
  const trimmedEvent = useMemo( () => ( {
	 name: form.name.trim(),
	 location: form.location.trim(),
	 isVirtual: !!form.isVirtual,
	 prerequisiteNotes: form.prerequisiteNotes.trim(),
	 repeatAttendancePolicy: form.repeatAttendancePolicy.trim(),
	 whoShouldAttend: form.whoShouldAttend.trim(),
	 timezoneID: form.timezoneID === '' ? null : Number( form.timezoneID )
  } ), [ form ] );

  const eventValidation = useMemo( () => {

	 const errs = {};

	 if ( !trimmedEvent.name ) errs.name = 'Name is required.';
	 if ( trimmedEvent.name && trimmedEvent.name.length > 255 ) errs.name = 'Max 255 characters.';
	 if ( trimmedEvent.location && trimmedEvent.location.length > 255 ) errs.location = 'Max 255 characters.';
	 if ( trimmedEvent.repeatAttendancePolicy && trimmedEvent.repeatAttendancePolicy.length > 255 ) errs.repeatAttendancePolicy = 'Max 255 characters.';
	 if ( trimmedEvent.whoShouldAttend && trimmedEvent.whoShouldAttend.length > 255 ) errs.whoShouldAttend = 'Max 255 characters.';

	 if ( trimmedEvent.timezoneID !== null ) {
		if ( !Number.isInteger( trimmedEvent.timezoneID ) || trimmedEvent.timezoneID <= 0 ) {
		  errs.timezoneID = 'Timezone is invalid.';
		} else {
		  const exists = sortedTimezones.some( ( t ) => Number( t?.id ) === trimmedEvent.timezoneID );
		  if ( !exists ) errs.timezoneID = 'Timezone not found in list.';
		}
	 }

	 return errs;

  }, [ trimmedEvent, sortedTimezones ] );

  // -------------------------
  // schedule validation
  // -------------------------
  const scheduleValidation = useMemo( () => {

	 const errs = [];

	 for ( const d of days ) {

		if ( d._delete ) continue;

		const date = ( d.date ?? '' ).trim();
		const startTime = ( d.startTime ?? '' ).trim();
		const endTime = ( d.endTime ?? '' ).trim();

		if ( !date ) {
		  errs.push( 'A scheduled day is missing a date.' );
		  continue;
		}

		if ( !isValidDatePart( date ) ) {
		  errs.push( `Invalid date: ${date}` );
		  continue;
		}

		if ( !startTime ) {
		  errs.push( `A scheduled day (${date}) is missing a start time.` );
		  continue;
		}

		if ( timeToMinutes( startTime ) === null ) {
		  errs.push( `Invalid start time for ${date}: ${startTime}` );
		  continue;
		}

		if ( endTime ) {

		  const s = timeToMinutes( startTime );
		  const e = timeToMinutes( endTime );

		  if ( e === null ) {
			 errs.push( `Invalid end time for ${date}: ${endTime}` );
			 continue;
		  }

		  if ( s !== null && e < s ) {
			 errs.push( `End time is before start time for ${date}.` );
		  }

		}

	 }

	 return errs;

  }, [ days ] );

  const scheduleDirty = useMemo(
	 () => days.some( ( d ) => d._dirty || d._delete || d._isNew ),
	 [ days ]
  );

  // ✅ Default new day times: 09:00–17:00
  const addDay = () => {

	 const tmpId = `new_${Date.now()}_${Math.random().toString( 16 ).slice( 2 )}`;

	 setDays( ( prev ) => ( [
		...prev,
		{
		  id: tmpId,
		  date: '',
		  startTime: '09:00',
		  endTime: '17:00',
		  _dirty: true,
		  _delete: false,
		  _isNew: true
		}
	 ] ) );

  };

  const updateDay = ( rowId, key, value ) => {
	 setDays( ( prev ) => prev.map( ( d ) => {
		if ( d.id !== rowId ) return d;
		return { ...d, [ key ]: value, _dirty: true };
	 } ) );
  };

  const toggleDeleteDay = ( rowId ) => {
	 setDays( ( prev ) => prev.map( ( d ) => {
		if ( d.id !== rowId ) return d;
		if ( d._isNew ) return null;
		return { ...d, _delete: !d._delete, _dirty: true };
	 } ).filter( Boolean ) );
  };

  const sortedDays = useMemo( () => {

	 const list = [ ...days ];

	 list.sort( ( a, b ) => {

		const ad = String( a?.date ?? '' );
		const bd = String( b?.date ?? '' );
		if ( ad < bd ) return -1;
		if ( ad > bd ) return 1;

		const at = String( a?.startTime ?? '' );
		const bt = String( b?.startTime ?? '' );
		if ( at < bt ) return -1;
		if ( at > bt ) return 1;

		return String( a?.id ?? '' ).localeCompare( String( b?.id ?? '' ) );

	 } );

	 return list;

  }, [ days ] );

  // -------------------------
  // save event (timezone saved via schedule)
  // -------------------------
  const saveEvent = async () => {

	 setError( null );

	 if ( Object.keys( eventValidation ).length ) {
		setError( 'Fix event validation errors first.' );
		return false;
	 }

	 try {

		setSavingEvent( true );

		const payload = {
		  name: trimmedEvent.name,
		  location: trimmedEvent.location || null,
		  isVirtual: !!trimmedEvent.isVirtual,
		  prerequisiteNotes: trimmedEvent.prerequisiteNotes || null,
		  repeatAttendancePolicy: trimmedEvent.repeatAttendancePolicy || null,
		  whoShouldAttend: trimmedEvent.whoShouldAttend || null
		};

		const res = await apiFetch( EVENTS_DETAIL_URL, {
		  method: 'PUT',
		  headers: { 'Content-Type': 'application/json' },
		  body: JSON.stringify( payload )
		} );

		const json = await safeJson( res );
		if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		return true;

	 } catch ( err ) {

		setError( err?.message ?? String( err ) );
		return false;

	 } finally {

		setSavingEvent( false );

	 }

  };

  // -------------------------
  // save schedule
  // -------------------------
  const saveSchedule = async () => {

	 setScheduleError( null );

	 if ( scheduleValidation.length ) {
		setScheduleError( scheduleValidation[ 0 ] );
		return false;
	 }

	 if ( Object.keys( eventValidation ).length ) {
		setScheduleError( 'Fix timezone validation errors first.' );
		return false;
	 }

	 if ( !scheduleDirty && trimmedEvent.timezoneID === null ) return true;

	 try {

		setSavingSchedule( true );

		const payload = {
		  timezoneID: trimmedEvent.timezoneID,
		  days: days.map( ( d ) => {

			 const date = ( d.date ?? '' ).trim();
			 const startTime = ( d.startTime ?? '' ).trim();
			 const endTime = ( d.endTime ?? '' ).trim();

			 const startDateTime = d._delete ? null : buildIsoLocal( date, startTime );
			 const endDateTime = d._delete ? null : ( endTime ? buildIsoLocal( date, endTime ) : null );

			 return {
				id: d._isNew ? null : d.id,
				startDateTime,
				endDateTime,
				_delete: !!d._delete
			 };

		  } )
		};

		const res = await apiFetch( EVENT_DAYS_SAVE_URL, {
		  method: 'PUT',
		  headers: { 'Content-Type': 'application/json' },
		  body: JSON.stringify( payload )
		} );

		const json = await safeJson( res );
		if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		const refreshed = await apiFetch( EVENT_DAYS_LIST_URL );
		const refreshedJson = await safeJson( refreshed );
		if ( !refreshed.ok ) throw new Error( refreshedJson?.error ?? refreshedJson?.message ?? `HTTP ${refreshed.status}` );

		const list = Array.isArray( refreshedJson ) ? refreshedJson : [];
		setDays(
		  list.map( ( d ) => {

			 const s = splitIsoToParts( d.startDateTime );
			 const e = splitIsoToParts( d.endDateTime );

			 return {
				id: d.id,
				date: s.date,
				startTime: s.time,
				endTime: e.time,
				_dirty: false,
				_delete: false,
				_isNew: false
			 };

		  } )
		);

		return true;

	 } catch ( err ) {

		setScheduleError( err?.message ?? String( err ) );
		return false;

	 } finally {

		setSavingSchedule( false );

	 }

  };

  const saveAll = async () => {

	 const okEvent = await saveEvent();
	 if ( !okEvent ) return;

	 const okSchedule = await saveSchedule();
	 if ( !okSchedule ) return;

	 navigate( `/events/${id}` );

  };

  useEffect( () => {

	 const onKeyDown = ( e ) => {

		if ( e.key !== 'Enter' ) return;
		if ( !( e.metaKey || e.ctrlKey ) ) return;
		if ( loading || tzLoading || savingEvent || savingSchedule ) return;

		e.preventDefault();
		saveAll();

	 };

	 window.addEventListener( 'keydown', onKeyDown );
	 return () => window.removeEventListener( 'keydown', onKeyDown );

  }, [ loading, tzLoading, savingEvent, savingSchedule, days, form ] );

  // -------------------------
  // styles
  // -------------------------
  const cardStyle = {
	 margin: 24,
	 padding: 18,
	 borderRadius: 16,
	 background: 'rgba( 255, 255, 255, 0.06 )',
	 border: '1px solid rgba( 255, 255, 255, 0.12 )',
	 boxShadow: '0 10px 30px rgba( 0, 0, 0, 0.35 )'
  };

  const labelStyle = {
	 fontSize: 12,
	 letterSpacing: 0.4,
	 textTransform: 'uppercase',
	 opacity: 0.65,
	 marginBottom: 6
  };

  const inputStyle = {
	 width: '100%',
	 padding: '10px 12px',
	 borderRadius: 12,
	 border: '1px solid rgba( 255, 255, 255, 0.14 )',
	 background: 'rgba( 0, 0, 0, 0.25 )',
	 color: 'rgba( 255, 255, 255, 0.92 )',
	 outline: 'none'
  };

  const textareaStyle = {
	 ...inputStyle,
	 minHeight: 110,
	 resize: 'vertical'
  };

  const selectStyle = {
	 ...inputStyle,
	 appearance: 'none'
  };

  const gridStyle = {
	 display: 'grid',
	 gridTemplateColumns: 'repeat( 12, 1fr )',
	 gap: 14,
	 marginTop: 14
  };

  const col = ( span ) => ( { gridColumn: `span ${span}` } );

  const buttonStyle = ( primary ) => ( {
	 padding: '10px 14px',
	 borderRadius: 10,
	 border: primary ? '1px solid rgba( 255, 255, 255, 0.22 )' : '1px solid rgba( 255, 255, 255, 0.14 )',
	 background: primary ? 'rgba( 59, 130, 246, 0.22 )' : 'rgba( 255, 255, 255, 0.06 )',
	 color: 'rgba( 255, 255, 255, 0.92 )',
	 cursor: ( savingEvent || savingSchedule || loading ) ? 'not-allowed' : 'pointer',
	 opacity: ( savingEvent || savingSchedule || loading ) ? 0.7 : 1,
	 whiteSpace: 'nowrap'
  } );

  const subtleButtonStyle = {
	 ...buttonStyle( false ),
	 padding: '8px 12px',
	 fontSize: 13
  };

  const errorBoxStyle = {
	 marginTop: 16,
	 padding: 12,
	 borderRadius: 12,
	 background: 'rgba( 239, 68, 68, 0.14 )',
	 border: '1px solid rgba( 239, 68, 68, 0.35 )'
  };

  const fieldError = ( msg ) => (
	 <div style={{ marginTop: 6, fontSize: 13, color: 'rgba( 248, 113, 113, 0.95 )' }}>
		{ msg }
	 </div>
  );

  const scheduleAccentWrapStyle = {
	 marginTop: 6,
	 padding: 14,
	 borderRadius: 14,
	 border: '1px solid rgba( 59, 130, 246, 0.40 )',
	 background: 'linear-gradient( 180deg, rgba( 59, 130, 246, 0.10 ), rgba( 0, 0, 0, 0.10 ) )',
	 boxShadow: '0 0 0 1px rgba( 59, 130, 246, 0.08 ), 0 10px 30px rgba( 0, 0, 0, 0.25 )'
  };

  const tableWrapStyle = {
	 marginTop: 10,
	 borderRadius: 12,
	 border: '1px solid rgba( 255, 255, 255, 0.10 )',
	 background: 'rgba( 0, 0, 0, 0.15 )',
	 overflow: 'hidden'
  };

  const tableStyle = {
	 width: '100%',
	 borderCollapse: 'separate',
	 borderSpacing: 0
  };

  const thStyle = {
	 textAlign: 'left',
	 fontSize: 12,
	 letterSpacing: 0.4,
	 textTransform: 'uppercase',
	 opacity: 0.85,
	 padding: '10px 12px',
	 background: 'rgba( 15, 15, 16, 0.65 )',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.10 )',
	 whiteSpace: 'nowrap'
  };

  const tdStyle = {
	 padding: '10px 12px',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.08 )',
	 verticalAlign: 'top'
  };

  const rowStyle = ( idx, deleted ) => ( {
	 background: deleted
		? 'rgba( 239, 68, 68, 0.10 )'
		: ( idx % 2 === 0 ) ? 'rgba( 255, 255, 255, 0.02 )' : 'transparent',
	 opacity: deleted ? 0.65 : 1
  } );

  const canSaveAll =
	 !loading &&
	 !tzLoading &&
	 !savingEvent &&
	 !savingSchedule &&
	 Object.keys( eventValidation ).length === 0 &&
	 scheduleValidation.length === 0;

  const timezoneLabel =
	 form.timezoneID
		? ( tzDisplay( sortedTimezones.find( ( t ) => String( t.id ) === String( form.timezoneID ) )?.displayName ) || '' )
		: '';

  return (
	 <div style={ cardStyle }>

		<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 12, flexWrap: 'wrap' }}>
		  <div>
			 <div style={{ opacity: 0.7, fontSize: 13 }}>Events</div>
			 <h2 style={{ margin: 0 }}>{ loading ? 'Loading…' : 'Edit Event' }</h2>
			 <div style={{ marginTop: 6, opacity: 0.65, fontSize: 13 }}>
				Tip: ⌘+Enter (or Ctrl+Enter) saves.
			 </div>
		  </div>

		  <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
			 <button
				style={ buttonStyle( false ) }
				onClick={ () => navigate( `/events/${id}` ) }
				disabled={ savingEvent || savingSchedule || loading }
			 >
				Cancel
			 </button>

			 <button
				style={ buttonStyle( true ) }
				onClick={ saveAll }
				disabled={ !canSaveAll }
				title={ !canSaveAll ? 'Fix validation errors first' : '' }
			 >
				{ ( savingEvent || savingSchedule ) ? 'Saving…' : 'Save All' }
			 </button>
		  </div>
		</div>

		{ error && (
		  <div style={ errorBoxStyle }>
			 <strong>Error:</strong> { error }
		  </div>
		) }

		<div style={ gridStyle }>

		  <div style={ col( 8 ) }>
			 <div style={ labelStyle }>Name *</div>
			 <input
				style={ inputStyle }
				value={ form.name }
				onChange={ ( e ) => set( 'name', e.target.value ) }
				maxLength={ 255 }
				disabled={ savingEvent || savingSchedule || loading }
				autoFocus
			 />
			 { eventValidation.name && fieldError( eventValidation.name ) }
		  </div>

		  <div style={ col( 4 ) }>
			 <div style={ labelStyle }>Virtual</div>
			 <div style={{
				display: 'flex',
				alignItems: 'center',
				gap: 10,
				padding: '10px 12px',
				borderRadius: 12,
				border: '1px solid rgba( 255, 255, 255, 0.14 )',
				background: 'rgba( 0, 0, 0, 0.25 )'
			 }}>
				<input
				  type="checkbox"
				  checked={ !!form.isVirtual }
				  onChange={ ( e ) => set( 'isVirtual', e.target.checked ) }
				  disabled={ savingEvent || savingSchedule || loading }
				/>
				<div style={{ opacity: 0.85 }}>This is a virtual event</div>
			 </div>
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Location</div>
			 <input
				style={ inputStyle }
				value={ form.location }
				onChange={ ( e ) => set( 'location', e.target.value ) }
				maxLength={ 255 }
				disabled={ savingEvent || savingSchedule || loading }
			 />
			 { eventValidation.location && fieldError( eventValidation.location ) }
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Who Should Attend</div>
			 <input
				style={ inputStyle }
				value={ form.whoShouldAttend }
				onChange={ ( e ) => set( 'whoShouldAttend', e.target.value ) }
				maxLength={ 255 }
				disabled={ savingEvent || savingSchedule || loading }
			 />
			 { eventValidation.whoShouldAttend && fieldError( eventValidation.whoShouldAttend ) }
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Repeat Attendance Policy</div>
			 <input
				style={ inputStyle }
				value={ form.repeatAttendancePolicy }
				onChange={ ( e ) => set( 'repeatAttendancePolicy', e.target.value ) }
				maxLength={ 255 }
				disabled={ savingEvent || savingSchedule || loading }
			 />
			 { eventValidation.repeatAttendancePolicy && fieldError( eventValidation.repeatAttendancePolicy ) }
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Prerequisite Notes</div>
			 <textarea
				style={ textareaStyle }
				value={ form.prerequisiteNotes }
				onChange={ ( e ) => set( 'prerequisiteNotes', e.target.value ) }
				disabled={ savingEvent || savingSchedule || loading }
			 />
		  </div>

		  <div style={ col( 12 ) }>

			 <div style={ labelStyle }>Schedule</div>

			 <div style={ scheduleAccentWrapStyle }>

				<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 12, flexWrap: 'wrap' }}>
				  <div style={{ opacity: 0.75, fontSize: 13 }}>
					 { loading ? 'Loading…' : `${sortedDays.filter( ( d ) => !d._delete ).length} day(s)` }
				  </div>

				  <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
					 <button
						style={ subtleButtonStyle }
						onClick={ addDay }
						disabled={ savingEvent || savingSchedule || loading }
					 >
						+ Add Day
					 </button>

					 <button
						style={ subtleButtonStyle }
						onClick={ saveSchedule }
						disabled={ savingSchedule || loading || scheduleValidation.length > 0 || !scheduleDirty }
						title={ scheduleValidation.length ? scheduleValidation[ 0 ] : '' }
					 >
						{ savingSchedule ? 'Saving Schedule…' : 'Save Schedule' }
					 </button>
				  </div>
				</div>

				<div style={{ marginTop: 12 }}>
				  <div style={ labelStyle }>Timezone</div>
				  <select
					 style={ selectStyle }
					 value={ form.timezoneID }
					 onChange={ ( e ) => set( 'timezoneID', e.target.value ) }
					 disabled={ savingEvent || savingSchedule || loading || tzLoading }
				  >
					 <option value="">( none )</option>
					 { sortedTimezones.map( ( t ) => (
						<option key={ t.id } value={ String( t.id ) }>
						  { t.displayName }
						</option>
					 ) ) }
				  </select>

				  { tzLoading && (
					 <div style={{ marginTop: 6, opacity: 0.65, fontSize: 13 }}>
						Loading timezones…
					 </div>
				  ) }

				  { eventValidation.timezoneID && fieldError( eventValidation.timezoneID ) }

				  { timezoneLabel && (
					 <div style={{ marginTop: 6, opacity: 0.65, fontSize: 13 }}>
						Selected: <span style={{ opacity: 0.95 }}>{ timezoneLabel }</span>
					 </div>
				  ) }
				</div>

				{ scheduleError && (
				  <div style={ errorBoxStyle }>
					 <strong>Schedule Error:</strong> { scheduleError }
				  </div>
				) }

				{ scheduleValidation.length > 0 && !scheduleError && (
				  <div style={ errorBoxStyle }>
					 <strong>Schedule Validation:</strong> { scheduleValidation[ 0 ] }
				  </div>
				) }

				{ !loading && sortedDays.length === 0 && (
				  <div style={{ marginTop: 10, opacity: 0.75 }}>
					 No days scheduled yet.
				  </div>
				) }

				{ sortedDays.length > 0 && (
				  <div style={ tableWrapStyle }>
					 <table style={ tableStyle }>
						<thead>
						  <tr>
							 <th style={ thStyle }>Date</th>
							 <th style={ thStyle }>Start</th>
							 <th style={ thStyle }>End</th>
							 <th style={ thStyle }>Duration</th>
							 <th style={ thStyle } />
						  </tr>
						</thead>

						<tbody>
						  { sortedDays.map( ( d, idx ) => (
							 <tr key={ d.id } style={ rowStyle( idx, d._delete ) }>

								<td style={ tdStyle }>
								  <input
									 type="date"
									 style={ inputStyle }
									 value={ d.date }
									 onChange={ ( e ) => updateDay( d.id, 'date', e.target.value ) }
									 disabled={ savingSchedule || loading || d._delete }
								  />
								</td>

								<td style={ tdStyle }>
								  <input
									 type="time"
									 step="60"
									 style={ inputStyle }
									 value={ d.startTime }
									 onChange={ ( e ) => updateDay( d.id, 'startTime', e.target.value ) }
									 disabled={ savingSchedule || loading || d._delete }
								  />
								</td>

								<td style={ tdStyle }>
								  <input
									 type="time"
									 step="60"
									 style={ inputStyle }
									 value={ d.endTime }
									 onChange={ ( e ) => updateDay( d.id, 'endTime', e.target.value ) }
									 disabled={ savingSchedule || loading || d._delete }
								  />
								</td>

								<td style={ tdStyle }>
								  { d._delete ? '' : durationText( d.startTime, d.endTime ) }
								</td>

								<td style={ tdStyle }>
								  <button
									 style={ subtleButtonStyle }
									 onClick={ () => toggleDeleteDay( d.id ) }
									 disabled={ savingSchedule || loading }
									 title={ d._delete ? 'Undo delete' : 'Delete this day' }
								  >
									 { d._delete ? 'Undo' : 'Delete' }
								  </button>
								</td>

							 </tr>
						  ) ) }
						</tbody>
					 </table>
				  </div>
				) }

			 </div>
		  </div>

		</div>

		<div style={{ marginTop: 14, opacity: 0.65, fontSize: 13 }}>
		  Event saves update event fields. Schedule saves update timezone + scheduled day rows.
		</div>

	 </div>
  );

}
