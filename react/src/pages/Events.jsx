import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiFetch } from '../api';

export default function Events() {

  const navigate = useNavigate();

  const [ rows, setRows ] = useState( [] );
  const [ loading, setLoading ] = useState( true );
  const [ error, setError ] = useState( null );

  const [ query, setQuery ] = useState( '' );
  const [ sortKey, setSortKey ] = useState( 'startDate' );
  const [ sortDir, setSortDir ] = useState( 'asc' );

  useEffect( () => {

	 ( async () => {

		setLoading( true );
		setError( null );

		try {

		  const res = await apiFetch( '/api/events' );

		  let json = null;
		  try { json = await res.json(); } catch ( e ) { json = null; }

		  if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		  setRows( Array.isArray( json ) ? json : [] );

		} catch ( err ) {

		  setError( err?.message ?? String( err ) );

		} finally {

		  setLoading( false );

		}

	 })();

  }, [] );

  const toggleSort = ( key ) => {

	 if ( sortKey === key ) {
		setSortDir( sortDir === 'asc' ? 'desc' : 'asc' );
	 } else {
		setSortKey( key );
		setSortDir( 'asc' );
	 }

  };

  const sortIndicator = ( key ) => {

	 if ( sortKey !== key ) return '';
	 return sortDir === 'asc' ? ' ▲' : ' ▼';

  };

  // ---------- date-only helpers (NO timezone conversion) ----------
  const isoDateOnly = ( iso ) => {

	 const s = String( iso ?? '' ).trim();
	 if ( !s ) return '';

	 const noZ = s.endsWith( 'Z' ) ? s.slice( 0, -1 ) : s;
	 const date = noZ.slice( 0, 10 );

	 return /^\d{4}-\d{2}-\d{2}$/.test( date ) ? date : '';

  };

  const formatDateWithDow = ( iso ) => {

	 const date = isoDateOnly( iso );
	 if ( !date ) return '';

	 // Use UTC as a calendar formatter so the browser TZ doesn’t shift the day.
	 const [ y, m, d ] = date.split( '-' ).map( Number );
	 const dt = new Date( Date.UTC( y, m - 1, d ) );

	 const dateText = new Intl.DateTimeFormat( undefined, {
		year: 'numeric',
		month: 'short',
		day: '2-digit'
	 }).format( dt );

	 const dow = new Intl.DateTimeFormat( undefined, { weekday: 'short' } ).format( dt );

	 return `${dateText} (${dow})`;

  };

  const normalized = useMemo( () => {

	 const q = query.trim().toLowerCase();

	 const filtered = !q
		? rows
		: rows.filter( ( r ) => {

			 const name = String( r.name ?? '' ).toLowerCase();
			 const location = String( r.location ?? '' ).toLowerCase();
			 const who = String( r.whoShouldAttend ?? '' ).toLowerCase();
			 const prereq = String( r.prerequisiteNotes ?? '' ).toLowerCase();
			 const policy = String( r.repeatAttendancePolicy ?? '' ).toLowerCase();
			 const virtual = r.isVirtual ? 'virtual' : 'in person';
			 const start = String( r.startDate ?? '' ).toLowerCase();
			 const end = String( r.endDate ?? '' ).toLowerCase();

			 return (
				name.includes( q ) ||
				location.includes( q ) ||
				who.includes( q ) ||
				prereq.includes( q ) ||
				policy.includes( q ) ||
				virtual.includes( q ) ||
				start.includes( q ) ||
				end.includes( q )
			 );

		  } );

	 const dir = sortDir === 'asc' ? 1 : -1;

	 const toStr = ( v ) => String( v ?? '' ).toLowerCase();

	 // Null/blank dates sort to bottom (both asc/desc)
	 const toDate = ( v ) => {

		const date = isoDateOnly( v );
		if ( !date ) return Number.POSITIVE_INFINITY;

		const [ y, m, d ] = date.split( '-' ).map( Number );
		return Date.UTC( y, m - 1, d );

	 };

	 const sorted = [ ...filtered ].sort( ( a, b ) => {

		if ( sortKey === 'startDate' ) return ( toDate( a.startDate ) - toDate( b.startDate ) ) * dir;
		if ( sortKey === 'endDate' ) return ( toDate( a.endDate ) - toDate( b.endDate ) ) * dir;

		if ( sortKey === 'isVirtual' ) {
		  const av = a.isVirtual ? 1 : 0;
		  const bv = b.isVirtual ? 1 : 0;
		  return ( av - bv ) * dir;
		}

		const av = toStr( a[ sortKey ] );
		const bv = toStr( b[ sortKey ] );

		if ( av < bv ) return -1 * dir;
		if ( av > bv ) return 1 * dir;
		return 0;

	 } );

	 return sorted;

  }, [ rows, query, sortKey, sortDir ] );

  // ---- styles ----
  const cardStyle = {
	 margin: 24,
	 padding: 18,
	 borderRadius: 16,
	 background: 'rgba( 255, 255, 255, 0.06 )',
	 border: '1px solid rgba( 255, 255, 255, 0.12 )',
	 boxShadow: '0 10px 30px rgba( 0, 0, 0, 0.35 )'
  };

  const inputStyle = {
	 width: 420,
	 maxWidth: '100%',
	 padding: '10px 12px',
	 borderRadius: 12,
	 border: '1px solid rgba( 255, 255, 255, 0.14 )',
	 background: 'rgba( 0, 0, 0, 0.25 )',
	 color: 'rgba( 255, 255, 255, 0.92 )',
	 outline: 'none'
  };

  const buttonStyle = {
	 padding: '10px 14px',
	 borderRadius: 10,
	 border: '1px solid rgba( 255, 255, 255, 0.18 )',
	 background: 'rgba( 255, 255, 255, 0.08 )',
	 color: 'rgba( 255, 255, 255, 0.9 )',
	 cursor: 'pointer',
	 whiteSpace: 'nowrap'
  };

  const tableScrollStyle = {
	 marginTop: 14,
	 maxHeight: 'calc( 100vh - 240px )',
	 overflow: 'auto',
	 borderRadius: 12,
	 border: '1px solid rgba( 255, 255, 255, 0.10 )',
	 background: 'rgba( 0, 0, 0, 0.15 )'
  };

  const tableStyle = {
	 width: '100%',
	 minWidth: 980, // reduced since timezone column is gone
	 borderCollapse: 'separate',
	 borderSpacing: 0
  };

  const thStyle = {
	 position: 'sticky',
	 top: 0,
	 zIndex: 2,
	 background: 'rgba( 15, 15, 16, 0.95 )',
	 backdropFilter: 'blur( 8px )',

	 textAlign: 'left',
	 fontSize: 12,
	 letterSpacing: 0.4,
	 textTransform: 'uppercase',
	 opacity: 0.9,
	 padding: '10px 12px',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.10 )',
	 cursor: 'pointer',
	 userSelect: 'none',
	 whiteSpace: 'nowrap'
  };

  const tdStyle = {
	 padding: '10px 12px',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.08 )',
	 verticalAlign: 'top'
  };

  const rowStyle = ( idx ) => ({
	 background: ( idx % 2 === 0 ) ? 'rgba( 255, 255, 255, 0.02 )' : 'transparent'
  });

  const chipStyle = ( on ) => ({
	 display: 'inline-block',
	 padding: '4px 10px',
	 borderRadius: 999,
	 fontSize: 12,
	 background: on ? 'rgba( 59, 130, 246, 0.18 )' : 'rgba( 245, 158, 11, 0.18 )',
	 border: on ? '1px solid rgba( 59, 130, 246, 0.35 )' : '1px solid rgba( 245, 158, 11, 0.35 )',
	 opacity: 0.95,
	 whiteSpace: 'nowrap'
  });

  const okText = loading ? 'Loading…' : `${normalized.length} of ${rows.length}`;

  return (
	 <div style={ cardStyle }>

		<div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap' }}>
		  <div>
			 <h2 style={{ margin: 0 }}>Events</h2>
			 <div style={{ marginTop: 6, opacity: 0.7, fontSize: 13 }}>
				{ okText }
			 </div>
		  </div>

		  <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
			 <input
				value={ query }
				onChange={ ( e ) => setQuery( e.target.value ) }
				placeholder="Search name, dates, location, audience…"
				style={ inputStyle }
			 />

			 <button
				style={ buttonStyle }
				onClick={ () => navigate( '/events/new' ) }
			 >
				+ New Event
			 </button>
		  </div>
		</div>

		{ error && (
		  <div style={{ marginTop: 16, padding: 12, borderRadius: 12, background: 'rgba( 239, 68, 68, 0.14 )', border: '1px solid rgba( 239, 68, 68, 0.35 )' }}>
			 <strong>Error:</strong> { error }
		  </div>
		)}

		<div style={ tableScrollStyle }>
		  <table style={ tableStyle }>
			 <thead>
				<tr>
				  <th style={ thStyle } onClick={ () => toggleSort( 'name' ) }>Name{ sortIndicator( 'name' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'startDate' ) }>Start{ sortIndicator( 'startDate' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'endDate' ) }>End{ sortIndicator( 'endDate' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'location' ) }>Location{ sortIndicator( 'location' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'isVirtual' ) }>Virtual{ sortIndicator( 'isVirtual' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'whoShouldAttend' ) }>Audience{ sortIndicator( 'whoShouldAttend' ) }</th>
				</tr>
			 </thead>

			 <tbody>
				{ loading && (
				  <tr>
					 <td style={ tdStyle } colSpan={ 6 }>Loading…</td>
				  </tr>
				)}

				{ !loading && normalized.length === 0 && (
				  <tr>
					 <td style={ tdStyle } colSpan={ 6 }>No events found.</td>
				  </tr>
				)}

				{ !loading && normalized.map( ( r, idx ) => (
				  <tr
					 key={ r.id }
					 style={ rowStyle( idx ) }
					 onClick={ () => navigate( `/events/${r.id}` ) }
					 onMouseEnter={ ( e ) => {
						e.currentTarget.style.background = 'rgba( 255, 255, 255, 0.06 )';
						e.currentTarget.style.cursor = 'pointer';
					 } }
					 onMouseLeave={ ( e ) => {
						e.currentTarget.style.background = rowStyle( idx ).background;
					 } }
				  >
					 <td style={ tdStyle }>{ r.name }</td>
					 <td style={ tdStyle }>{ formatDateWithDow( r.startDate ) }</td>
					 <td style={ tdStyle }>{ formatDateWithDow( r.endDate ) }</td>
					 <td style={ tdStyle }>{ r.location }</td>
					 <td style={ tdStyle }>
						<span style={ chipStyle( !!r.isVirtual ) }>
						  { r.isVirtual ? 'Virtual' : 'In person' }
						</span>
					 </td>
					 <td style={ tdStyle }>{ r.whoShouldAttend }</td>
				  </tr>
				) ) }
			 </tbody>
		  </table>
		</div>

	 </div>
  );

}
