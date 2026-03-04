import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { apiFetch } from '../api';

export default function EventDetail() {

  const { id } = useParams();
  const navigate = useNavigate();

  // =============================================================================
  // If your POST/PUT/DELETE endpoints differ, change them here (one-stop shop).
  // =============================================================================
  const REG_ENDPOINTS = {
	 listByEvent: ( eventID ) => `/api/eventRegistrationsByEvent?eventID=${encodeURIComponent( eventID )}`,
	 create: () => `/api/eventRegistrations`,                                       // POST
	 update: ( regID ) => `/api/eventRegistrations/${encodeURIComponent( regID )}`, // PUT
	 remove: ( regID ) => `/api/eventRegistrations/${encodeURIComponent( regID )}`  // DELETE
  };

  const [ event, setEvent ] = useState( null );
  const [ loading, setLoading ] = useState( true );
  const [ error, setError ] = useState( null );
  const [ notFound, setNotFound ] = useState( false );

  const [ eventDays, setEventDays ] = useState( [] );
  const [ daysLoading, setDaysLoading ] = useState( true );
  const [ daysError, setDaysError ] = useState( null );

  const [ registrations, setRegistrations ] = useState( [] );
  const [ regsLoading, setRegsLoading ] = useState( true );
  const [ regsError, setRegsError ] = useState( null );

  const [ editingRegID, setEditingRegID ] = useState( null ); // null | 'new' | existing id
  const [ regDraft, setRegDraft ] = useState( null );
  const [ regSaving, setRegSaving ] = useState( false );

  const [ isWide, setIsWide ] = useState( false );

  // ---- registrations sorting ----
  const [ regSort, setRegSort ] = useState({ key: 'registrationDate', dir: 'desc' }); // key: string, dir: 'asc'|'desc'

  // ---- customers for dropdown ----
  const [ customers, setCustomers ] = useState( [] );
  const [ customersLoading, setCustomersLoading ] = useState( true );
  const [ customersError, setCustomersError ] = useState( null );

  // ---- learner profiles for dropdown ----
  const [ learnerProfiles, setLearnerProfiles ] = useState( [] );
  const [ learnerProfilesLoading, setLearnerProfilesLoading ] = useState( true );
  const [ learnerProfilesError, setLearnerProfilesError ] = useState( null );

  // =============================================================================
  // Responsive breakpoint
  // =============================================================================
  useEffect( () => {

	 const mq = window.matchMedia( '( min-width: 1100px )' );

	 const apply = () => setIsWide( !!mq.matches );
	 apply();

	 if ( mq.addEventListener ) mq.addEventListener( 'change', apply );
	 else mq.addListener( apply );

	 return () => {
		if ( mq.removeEventListener ) mq.removeEventListener( 'change', apply );
		else mq.removeListener( apply );
	 };

  }, [] );

  const tzDisplay = ( v ) => String( v ?? '' ).trim();

  const clip = ( s, n = 80 ) => {
	 const t = String( s ?? '' );
	 if ( t.length <= n ) return t;
	 return `${t.slice( 0, n - 1 )}…`;
  };

  const toIntOrNull = ( v ) => {
	 const s = String( v ?? '' ).trim();
	 if ( !s ) return null;
	 const n = Number( s );
	 if ( !Number.isFinite( n ) ) return null;
	 if ( !Number.isInteger( n ) ) return null;
	 return n;
  };

  const toBool = ( v ) => {
	 if ( v === true || v === 1 || v === '1' ) return true;
	 if ( typeof v === 'string' && v.toLowerCase() === 'true' ) return true;
	 return false;
  };

  const regDateText = ( iso ) => {
	 const s = String( iso ?? '' ).trim();
	 if ( !s ) return '';
	 const m = s.match( /^(\d{4}-\d{2}-\d{2})/ );
	 return m ? m[ 1 ] : '';
  };

  const todayYmd = () => {

	 const d = new Date();
	 const y = d.getFullYear();
	 const m = String( d.getMonth() + 1 ).padStart( 2, '0' );
	 const day = String( d.getDate() ).padStart( 2, '0' );

	 return `${y}-${m}-${day}`;

  };

  const apiJson = async ( url, init ) => {

	 const res = await apiFetch( url, init );

	 let json = null;
	 try { json = await res.json(); } catch ( e ) { json = null; }

	 return { res, json };

  };

  // =============================================================================
  // Customers lookup
  // =============================================================================
  const normalizeCustomer = ( c ) => {

	 const rawID = c?.DT_RowId ?? c?.dt_rowid ?? c?.id ?? c?.customerID ?? null;
	 const idStr = rawID == null ? '' : String( rawID );

	 const name = String(
		c?.name ?? c?.customerName ?? c?.customer ?? c?.displayName ?? ''
	 ).trim();

	 return { id: idStr, name };

  };

  useEffect( () => {

	 ( async () => {

		setCustomersLoading( true );
		setCustomersError( null );
		setCustomers( [] );

		try {

		  const { res, json } = await apiJson( '/api/customers' );

		  if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		  const list = Array.isArray( json ) ? json : [];
		  const normalized = list
			 .map( normalizeCustomer )
			 .filter( ( c ) => c.id && c.name );

		  normalized.sort( ( a, b ) => a.name.localeCompare( b.name ) );

		  setCustomers( normalized );

		} catch ( err ) {

		  setCustomersError( err?.message ?? String( err ) );

		} finally {

		  setCustomersLoading( false );

		}

	 })();

  }, [] );

  // =============================================================================
  // Learner Profiles lookup
  // =============================================================================
  const normalizeLearnerProfile = ( lp ) => {

	 const idStr = lp?.id == null ? '' : String( lp.id );
	 const name = String( lp?.name ?? '' ).trim();
	 return { id: idStr, name };

  };

  useEffect( () => {

	 ( async () => {

		setLearnerProfilesLoading( true );
		setLearnerProfilesError( null );
		setLearnerProfiles( [] );

		try {

		  const { res, json } = await apiJson( '/api/learnerProfiles' );

		  if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		  const list = Array.isArray( json ) ? json : [];
		  const normalized = list
			 .map( normalizeLearnerProfile )
			 .filter( ( x ) => x.id && x.name );

		  normalized.sort( ( a, b ) => a.name.localeCompare( b.name ) );

		  setLearnerProfiles( normalized );

		} catch ( err ) {

		  setLearnerProfilesError( err?.message ?? String( err ) );

		} finally {

		  setLearnerProfilesLoading( false );

		}

	 })();

  }, [] );

  // -----------------------------------------------------------------------------
  // ISO-local parsing/formatting (NO timezone conversion)
  // -----------------------------------------------------------------------------
  const parseIsoLocalParts = ( iso ) => {

	 const s = String( iso ?? '' ).trim();
	 if ( !s ) return null;

	 const noZ = s.endsWith( 'Z' ) ? s.slice( 0, -1 ) : s;

	 if ( noZ.length < 16 ) return null;

	 const datePart = noZ.slice( 0, 10 );
	 const timePart = noZ.slice( 11, 16 );

	 if ( !/^\d{4}-\d{2}-\d{2}$/.test( datePart ) ) return null;
	 if ( !/^\d{2}:\d{2}$/.test( timePart ) ) return null;

	 const year = Number( datePart.slice( 0, 4 ) );
	 const month = Number( datePart.slice( 5, 7 ) );
	 const day = Number( datePart.slice( 8, 10 ) );

	 const hour = Number( timePart.slice( 0, 2 ) );
	 const minute = Number( timePart.slice( 3, 5 ) );

	 if ( !Number.isInteger( year ) || year < 1 ) return null;
	 if ( !Number.isInteger( month ) || month < 1 || month > 12 ) return null;
	 if ( !Number.isInteger( day ) || day < 1 || day > 31 ) return null;
	 if ( !Number.isInteger( hour ) || hour < 0 || hour > 23 ) return null;
	 if ( !Number.isInteger( minute ) || minute < 0 || minute > 59 ) return null;

	 return { year, month, day, hour, minute };

  };

  const monthNames = [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ];
  const weekdayNames = [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ];

  const weekdayIndex = ( y, m, d ) => {
	 return new Date( Date.UTC( y, m - 1, d, 0, 0, 0, 0 ) ).getUTCDay();
  };

  const pad2 = ( n ) => String( n ).padStart( 2, '0' );

  const formatDate = ( iso ) => {

	 const p = parseIsoLocalParts( iso );
	 if ( !p ) return '';

	 const wd = weekdayNames[ weekdayIndex( p.year, p.month, p.day ) ];
	 const mo = monthNames[ p.month - 1 ] ?? '';

	 return `${wd}, ${mo} ${pad2( p.day )}, ${p.year}`;

  };

  const formatTime = ( iso ) => {

	 const p = parseIsoLocalParts( iso );
	 if ( !p ) return '';

	 const ampm = p.hour >= 12 ? 'PM' : 'AM';
	 const h12 = ( p.hour % 12 ) === 0 ? 12 : ( p.hour % 12 );

	 return `${h12}:${pad2( p.minute )} ${ampm}`;

  };

  const toUtcMsFromParts = ( iso ) => {

	 const p = parseIsoLocalParts( iso );
	 if ( !p ) return null;

	 return Date.UTC( p.year, p.month - 1, p.day, p.hour, p.minute, 0, 0 );

  };

  const durationText = ( startIso, endIso ) => {

	 const s = toUtcMsFromParts( startIso );
	 const e = toUtcMsFromParts( endIso );

	 if ( s === null || e === null ) return '';

	 const mins = Math.max( 0, Math.round( ( e - s ) / 60000 ) );
	 const h = Math.floor( mins / 60 );
	 const m = mins % 60;

	 if ( h === 0 ) return `${m}m`;
	 if ( m === 0 ) return `${h}h`;
	 return `${h}h ${m}m`;

  };

  const normalizeReg = ( r ) => ( {
	 id: r?.id ?? null,
	 eventID: r?.eventID ?? id,

	 customerID: r?.customerID ?? null,
	 customerName: r?.customerName ?? null,
	 customerStatusName: r?.customerStatusName ?? null,

	 title: r?.title ?? null,
	 fullName: r?.fullName ?? null,

	 learnerProfileID: r?.learnerProfileID ?? null,
	 learnerProfileName: r?.learnerProfileName ?? null,

	 registrationDate: r?.registrationDate ?? null,

	 curriculumPlanID: r?.curriculumPlanID ?? null,

	 payTypeID: r?.payTypeID ?? null,
	 paymentTypeName: r?.paymentTypeName ?? null,

	 certificateCount: r?.certificateCount ?? null,
	 registrationStatusID: r?.registrationStatusID ?? null,

	 notes: r?.notes ?? null,

	 hubspot_object_id: r?.hubspot_object_id ?? null,
	 taggedInHubspotInd: toBool( r?.taggedInHubspotInd ),

	 prerequisiteOverrideReason: r?.prerequisiteOverrideReason ?? null,
	 prerequisiteOverrideAuthorizedBy: r?.prerequisiteOverrideAuthorizedBy ?? null
  } );

  // =============================================================================
  // Registrations refresh (single source of truth)
  // =============================================================================
  const loadRegistrations = async ( eventID = id ) => {

	 setRegsLoading( true );
	 setRegsError( null );

	 try {

		const { res, json } = await apiJson( REG_ENDPOINTS.listByEvent( eventID ) );

		if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		const list = Array.isArray( json ) ? json : [];
		setRegistrations( list.map( normalizeReg ) );

	 } catch ( err ) {

		setRegsError( err?.message ?? String( err ) );

	 } finally {

		setRegsLoading( false );

	 }

  };

  // =============================================================================
  // Load: event + days + registrations
  // =============================================================================
  useEffect( () => {

	 ( async () => {

		setLoading( true );
		setError( null );
		setNotFound( false );

		setDaysLoading( true );
		setDaysError( null );
		setEventDays( [] );

		setEditingRegID( null );
		setRegDraft( null );
		setRegSaving( false );
		setRegistrations( [] );
		setRegsError( null );
		setRegsLoading( true );

		try {

		  const [ eventResPack, daysResPack ] = await Promise.all([
			 apiJson( `/api/events/${id}` ),
			 apiJson( `/api/eventDaysByEvent?eventID=${encodeURIComponent( id )}` )
		  ]);

		  if ( eventResPack.res.status === 404 ) {
			 setNotFound( true );
			 setEvent( null );
			 return;
		  }

		  if ( !eventResPack.res.ok ) {
			 throw new Error( eventResPack.json?.error ?? eventResPack.json?.message ?? `HTTP ${eventResPack.res.status}` );
		  }

		  setEvent( eventResPack.json );

		  if ( !daysResPack.res.ok ) {
			 setDaysError( daysResPack.json?.error ?? daysResPack.json?.message ?? `HTTP ${daysResPack.res.status}` );
		  } else {
			 setEventDays( Array.isArray( daysResPack.json ) ? daysResPack.json : [] );
		  }

		  loadRegistrations( id );

		} catch ( err ) {

		  setError( err?.message ?? String( err ) );

		} finally {

		  setLoading( false );
		  setDaysLoading( false );

		}

	 })();

	 // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ id ] );

  const sortedDays = useMemo( () => {

	 const list = [ ...eventDays ];

	 list.sort( ( a, b ) => {

		const av = toUtcMsFromParts( a?.startDateTime ) ?? Number.POSITIVE_INFINITY;
		const bv = toUtcMsFromParts( b?.startDateTime ) ?? Number.POSITIVE_INFINITY;

		return av - bv;

	 } );

	 return list;

  }, [ eventDays ] );

  // ---- sortable registrations list ----
  const regValueForSort = ( r, key ) => {

	 switch ( key ) {

		case 'customer':
		  return String( r?.customerName ?? '' ).toLowerCase();

		case 'registrant':
		  return `${String( r?.fullName ?? '' ).toLowerCase()}|${String( r?.title ?? '' ).toLowerCase()}`;

		case 'registrationDate':
		  return regDateText( r?.registrationDate ) || '';

		case 'payType':
		  return Number( r?.payTypeID ?? -1 );

		case 'certificateCount':
		  return Number( r?.certificateCount ?? -1 );

		case 'tagged':
		  return r?.taggedInHubspotInd ? 1 : 0;

		case 'notes':
		  return String( r?.notes ?? '' ).toLowerCase();

		default:
		  return String( r?.id ?? '' );

	 }

  };

  const compareNullable = ( av, bv ) => {

	 const aEmpty = ( av === null || av === undefined || av === '' || ( typeof av === 'number' && !Number.isFinite( av ) ) );
	 const bEmpty = ( bv === null || bv === undefined || bv === '' || ( typeof bv === 'number' && !Number.isFinite( bv ) ) );

	 if ( aEmpty && bEmpty ) return 0;
	 if ( aEmpty ) return -1;
	 if ( bEmpty ) return 1;

	 if ( typeof av === 'number' && typeof bv === 'number' ) {
		return av === bv ? 0 : ( av < bv ? -1 : 1 );
	 }

	 return String( av ).localeCompare( String( bv ) );

  };

  const sortedRegs = useMemo( () => {

	 const list = [ ...registrations ];
	 const { key, dir } = regSort;

	 list.sort( ( a, b ) => {

		const av = regValueForSort( a, key );
		const bv = regValueForSort( b, key );

		const base = compareNullable( av, bv );
		if ( base !== 0 ) return dir === 'asc' ? base : -base;

		const ai = Number( a?.id ?? 0 );
		const bi = Number( b?.id ?? 0 );
		if ( Number.isFinite( ai ) && Number.isFinite( bi ) ) return bi - ai;

		return String( b?.id ?? '' ).localeCompare( String( a?.id ?? '' ) );

	 } );

	 return list;

  }, [ registrations, regSort ] );

  const toggleRegSort = ( key ) => {

	 setRegSort( ( prev ) => {

		if ( prev.key === key ) {
		  const nextDir = prev.dir === 'asc' ? 'desc' : 'asc';
		  return { key, dir: nextDir };
		}

		const defaultDir = ( key === 'registrationDate' ) ? 'desc' : 'asc';
		return { key, dir: defaultDir };

	 } );

  };

  // =============================================================================
  // Styles
  // =============================================================================
  const cardStyle = {
	 margin: 24,
	 padding: 18,
	 borderRadius: 16,
	 background: 'rgba( 255, 255, 255, 0.06 )',
	 border: '1px solid rgba( 255, 255, 255, 0.12 )',
	 boxShadow: '0 10px 30px rgba( 0, 0, 0, 0.35 )'
  };

  const buttonStyle = ( primary ) => ( {
	 padding: '10px 14px',
	 borderRadius: 10,
	 border: primary ? '1px solid rgba( 255, 255, 255, 0.22 )' : '1px solid rgba( 255, 255, 255, 0.14 )',
	 background: primary ? 'rgba( 59, 130, 246, 0.22 )' : 'rgba( 255, 255, 255, 0.06 )',
	 color: 'rgba( 255, 255, 255, 0.92 )',
	 cursor: 'pointer',
	 whiteSpace: 'nowrap'
  } );

  const smallBtnStyle = ( tone ) => {

	 const map = {
		neutral: {
		  border: '1px solid rgba( 255, 255, 255, 0.14 )',
		  background: 'rgba( 255, 255, 255, 0.05 )'
		},
		danger: {
		  border: '1px solid rgba( 239, 68, 68, 0.35 )',
		  background: 'rgba( 239, 68, 68, 0.14 )'
		}
	 };

	 const t = map[ tone ] ?? map.neutral;

	 return {
		padding: '8px 10px',
		borderRadius: 10,
		...t,
		color: 'rgba( 255, 255, 255, 0.92 )',
		cursor: 'pointer',
		whiteSpace: 'nowrap'
	 };

  };

  const labelStyle = {
	 fontSize: 12,
	 letterSpacing: 0.4,
	 textTransform: 'uppercase',
	 opacity: 0.65,
	 marginBottom: 6
  };

  const fieldStyle = {
	 padding: 14,
	 borderRadius: 12,
	 background: 'rgba( 0, 0, 0, 0.22 )',
	 border: '1px solid rgba( 255, 255, 255, 0.10 )',
	 lineHeight: 1.35
  };

  const inputStyle = {
	 width: '100%',
	 minWidth: 0,
	 boxSizing: 'border-box',
	 padding: '10px 12px',
	 borderRadius: 10,
	 border: '1px solid rgba( 255, 255, 255, 0.16 )',
	 background: 'rgba( 0, 0, 0, 0.22 )',
	 color: 'rgba( 255, 255, 255, 0.92 )',
	 outline: 'none'
  };

  const selectStyle = {
	 ...inputStyle,
	 appearance: 'none',
	 backgroundImage: 'linear-gradient( 45deg, transparent 50%, rgba( 255, 255, 255, 0.65 ) 50% ), linear-gradient( 135deg, rgba( 255, 255, 255, 0.65 ) 50%, transparent 50% )',
	 backgroundPosition: 'calc( 100% - 18px ) calc( 1em + 2px ), calc( 100% - 13px ) calc( 1em + 2px )',
	 backgroundSize: '5px 5px, 5px 5px',
	 backgroundRepeat: 'no-repeat',
	 paddingRight: 34
  };

  const textareaStyle = {
	 width: '100%',
	 minWidth: 0,
	 boxSizing: 'border-box',
	 minHeight: 86,
	 resize: 'vertical',
	 padding: '10px 12px',
	 borderRadius: 10,
	 border: '1px solid rgba( 255, 255, 255, 0.16 )',
	 background: 'rgba( 0, 0, 0, 0.22 )',
	 color: 'rgba( 255, 255, 255, 0.92 )',
	 outline: 'none',
	 lineHeight: 1.35
  };

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

  const pillStyle = ( kind ) => {

	 const map = {
		ok: { bg: 'rgba( 34, 197, 94, 0.14 )', br: 'rgba( 34, 197, 94, 0.30 )' },
		info: { bg: 'rgba( 59, 130, 246, 0.16 )', br: 'rgba( 59, 130, 246, 0.32 )' },
		neutral: { bg: 'rgba( 255, 255, 255, 0.06 )', br: 'rgba( 255, 255, 255, 0.14 )' }
	 };

	 const t = map[ kind ] ?? map.neutral;

	 return {
		display: 'inline-block',
		padding: '4px 10px',
		borderRadius: 999,
		fontSize: 12,
		background: t.bg,
		border: `1px solid ${t.br}`,
		opacity: 0.95,
		whiteSpace: 'nowrap'
	 };

  };

  const errorBoxStyle = {
	 marginTop: 16,
	 padding: 12,
	 borderRadius: 12,
	 background: 'rgba( 239, 68, 68, 0.14 )',
	 border: '1px solid rgba( 239, 68, 68, 0.35 )'
  };

  const topGridStyle = {
	 display: 'grid',
	 gridTemplateColumns: isWide ? '7fr 5fr' : '1fr',
	 gap: 14,
	 marginTop: 14,
	 alignItems: 'start'
  };

  const scheduleAccentWrapStyle = {
	 padding: 14,
	 borderRadius: 14,
	 border: '1px solid rgba( 59, 130, 246, 0.40 )',
	 background: 'linear-gradient( 180deg, rgba( 59, 130, 246, 0.10 ), rgba( 0, 0, 0, 0.10 ) )',
	 boxShadow: '0 0 0 1px rgba( 59, 130, 246, 0.08 ), 0 10px 30px rgba( 0, 0, 0, 0.25 )'
  };

  const regsAccentWrapStyle = {
	 marginTop: 14,
	 padding: 14,
	 borderRadius: 14,
	 border: '1px solid rgba( 34, 197, 94, 0.35 )',
	 background: 'linear-gradient( 180deg, rgba( 34, 197, 94, 0.08 ), rgba( 0, 0, 0, 0.10 ) )',
	 boxShadow: '0 0 0 1px rgba( 34, 197, 94, 0.06 ), 0 10px 30px rgba( 0, 0, 0, 0.25 )'
  };

  const sectionHeaderStyle = {
	 padding: 12,
	 borderRadius: 12,
	 background: 'rgba( 0, 0, 0, 0.18 )',
	 border: '1px solid rgba( 255, 255, 255, 0.10 )'
  };

  const sectionHeaderRowStyle = {
	 display: 'flex',
	 justifyContent: 'space-between',
	 alignItems: 'baseline',
	 gap: 12,
	 flexWrap: 'wrap'
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

  const thSortStyle = ( key ) => ( {
	 ...thStyle,
	 cursor: 'pointer',
	 userSelect: 'none',
	 opacity: regSort.key === key ? 0.98 : 0.82
  } );

  const sortGlyph = ( key ) => {
	 if ( regSort.key !== key ) return '';
	 return regSort.dir === 'asc' ? ' ▲' : ' ▼';
  };

  const tdStyle = {
	 padding: '10px 12px',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.08 )',
	 verticalAlign: 'top'
  };

  const rowStyle = ( idx ) => ({
	 background: ( idx % 2 === 0 ) ? 'rgba( 255, 255, 255, 0.02 )' : 'transparent'
  });

  const timezoneLabel = tzDisplay( event?.timezoneShortName ) || '';

  const grid12 = {
	 display: 'grid',
	 gridTemplateColumns: 'repeat( 12, minmax( 0, 1fr ) )',
	 gap: 12
  };

  const gi = ( spanWide, spanNarrow = 12 ) => ( {
	 gridColumn: `span ${isWide ? spanWide : spanNarrow}`,
	 minWidth: 0
  } );

  // =============================================================================
  // Registrations: add/edit/delete
  // =============================================================================
  const startAddReg = () => {

	 setEditingRegID( 'new' );
	 setRegsError( null );
	 setRegDraft( {
		eventID: id,
		customerID: '',
		title: '',
		fullName: '',
		learnerProfileID: '',
		registrationDate: todayYmd(),
		curriculumPlanID: '',
		payTypeID: '',
		certificateCount: '',
		registrationStatusID: '',
		notes: '',
		hubspot_object_id: '',
		taggedInHubspotInd: false,
		prerequisiteOverrideReason: '',
		prerequisiteOverrideAuthorizedBy: ''
	 } );

  };

  const startEditReg = ( r ) => {

	 setEditingRegID( String( r?.id ) );
	 setRegsError( null );
	 setRegDraft( {
		eventID: r?.eventID ?? id,
		customerID: String( r?.customerID ?? '' ),
		title: r?.title ?? '',
		fullName: r?.fullName ?? '',
		learnerProfileID: String( r?.learnerProfileID ?? '' ),
		registrationDate: regDateText( r?.registrationDate ),
		curriculumPlanID: r?.curriculumPlanID ?? '',
		payTypeID: r?.payTypeID ?? '',
		certificateCount: r?.certificateCount ?? '',
		registrationStatusID: r?.registrationStatusID ?? '',
		notes: r?.notes ?? '',
		hubspot_object_id: r?.hubspot_object_id ?? '',
		taggedInHubspotInd: !!r?.taggedInHubspotInd,
		prerequisiteOverrideReason: r?.prerequisiteOverrideReason ?? '',
		prerequisiteOverrideAuthorizedBy: r?.prerequisiteOverrideAuthorizedBy ?? ''
	 } );

  };

  const cancelReg = () => {
	 setEditingRegID( null );
	 setRegDraft( null );
	 setRegSaving( false );
  };

  const saveReg = async () => {

	 if ( !regDraft ) return;

	 const fullNameReq = String( regDraft.fullName ?? '' ).trim();
	 const regDateReq = String( regDraft.registrationDate ?? '' ).trim();

	 if ( !fullNameReq ) {
		setRegsError( 'Full Name is required.' );
		return;
	 }

	 if ( !regDateReq ) {
		setRegsError( 'Registration Date is required.' );
		return;
	 }

	 setRegSaving( true );
	 setRegsError( null );

	 try {

		const payload = {
		  eventID: toIntOrNull( regDraft.eventID ) ?? toIntOrNull( id ) ?? id,
		  customerID: toIntOrNull( regDraft.customerID ) ?? ( String( regDraft.customerID ?? '' ).trim() || null ),

		  title: String( regDraft.title ?? '' ).trim() || null,
		  fullName: fullNameReq || null,

		  learnerProfileID: toIntOrNull( regDraft.learnerProfileID ),

		  registrationDate: regDateReq || null, // YYYY-MM-DD
		  curriculumPlanID: toIntOrNull( regDraft.curriculumPlanID ),
		  payTypeID: toIntOrNull( regDraft.payTypeID ),
		  certificateCount: toIntOrNull( regDraft.certificateCount ),
		  registrationStatusID: toIntOrNull( regDraft.registrationStatusID ),
		  notes: String( regDraft.notes ?? '' ) || null,
		  hubspot_object_id: String( regDraft.hubspot_object_id ?? '' ).trim() || null,
		  taggedInHubspotInd: !!regDraft.taggedInHubspotInd,
		  prerequisiteOverrideReason: String( regDraft.prerequisiteOverrideReason ?? '' ).trim() || null,
		  prerequisiteOverrideAuthorizedBy: toIntOrNull( regDraft.prerequisiteOverrideAuthorizedBy )
		};

		if ( editingRegID === 'new' ) {

		  const { res, json } = await apiJson( REG_ENDPOINTS.create(), {
			 method: 'POST',
			 headers: { 'Content-Type': 'application/json' },
			 body: JSON.stringify( payload )
		  } );

		  if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		  await loadRegistrations( id );

		} else {

		  const { res, json } = await apiJson( REG_ENDPOINTS.update( editingRegID ), {
			 method: 'PUT',
			 headers: { 'Content-Type': 'application/json' },
			 body: JSON.stringify( payload )
		  } );

		  if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		  await loadRegistrations( id );

		}

		cancelReg();

	 } catch ( err ) {

		setRegsError( err?.message ?? String( err ) );

	 } finally {

		setRegSaving( false );

	 }

  };

  const deleteReg = async ( r ) => {

	 const regID = r?.id;
	 if ( regID == null ) return;

	 if ( !confirm( 'Delete this registration? This cannot be undone.' ) ) return;

	 setRegsError( null );

	 try {

		const { res, json } = await apiJson( REG_ENDPOINTS.remove( regID ), { method: 'DELETE' } );
		if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		await loadRegistrations( id );

	 } catch ( err ) {

		setRegsError( err?.message ?? String( err ) );

	 }

  };

  return (
	 <div style={ cardStyle }>

		<div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
		  <div>
			 <div style={{ opacity: 0.7, fontSize: 13 }}>Event</div>
			 <h2 style={{ margin: 0 }}>
				{ loading ? 'Loading…' : notFound ? 'Not Found' : ( event?.name ?? 'Event' ) }
			 </h2>
			 { !loading && !notFound && (
				<div style={{ marginTop: 6, opacity: 0.65, fontSize: 13 }}>
				  ID: <code>{ id }</code>
				</div>
			 ) }
		  </div>

		  <div style={{ display: 'flex', gap: 10 }}>
			 <button style={ buttonStyle( false ) } onClick={ () => navigate( '/events' ) }>
				← Back
			 </button>

			 { !loading && !notFound && (
				<button style={ buttonStyle( true ) } onClick={ () => navigate( `/events/${id}/edit` ) }>
				  Edit
				</button>
			 ) }
		  </div>
		</div>

		{ error && (
		  <div style={ errorBoxStyle }>
			 <strong>Error:</strong> { error }
		  </div>
		)}

		{ notFound && !error && (
		  <div style={{ marginTop: 16, opacity: 0.75 }}>
			 That event doesn’t exist (or you don’t have permission to view it).
		  </div>
		)}

		{ !loading && event && !notFound && (
		  <>

			 {/* ==============================================================
				  Top: Details + Schedule
			 ============================================================== */}
			 <div style={ topGridStyle }>

				{/* ---- Details ---- */}
				<div>
				  <div style={{
					 padding: 14,
					 borderRadius: 14,
					 border: '1px solid rgba( 255, 255, 255, 0.12 )',
					 background: 'rgba( 0, 0, 0, 0.10 )'
				  }}>
					 <div style={{ display: 'grid', gridTemplateColumns: 'repeat( 12, minmax( 0, 1fr ) )', gap: 14 }}>

						<div style={{ gridColumn: 'span 8' }}>
						  <div style={ labelStyle }>Name</div>
						  <div style={ fieldStyle }>{ event.name }</div>
						</div>

						<div style={{ gridColumn: 'span 4' }}>
						  <div style={ labelStyle }>Virtual</div>
						  <div style={ fieldStyle }>
							 <span style={ chipStyle( !!event.isVirtual ) }>
								{ event.isVirtual ? 'Virtual' : 'In person' }
							 </span>
						  </div>
						</div>

						<div style={{ gridColumn: 'span 12' }}>
						  <div style={ labelStyle }>Location</div>
						  <div style={ fieldStyle }>{ event.location ?? '' }</div>
						</div>

						<div style={{ gridColumn: 'span 12' }}>
						  <div style={ labelStyle }>Who Should Attend</div>
						  <div style={ fieldStyle }>{ event.whoShouldAttend ?? '' }</div>
						</div>

						<div style={{ gridColumn: 'span 12' }}>
						  <div style={ labelStyle }>Repeat Attendance Policy</div>
						  <div style={ fieldStyle }>{ event.repeatAttendancePolicy ?? '' }</div>
						</div>

						<div style={{ gridColumn: 'span 12' }}>
						  <div style={ labelStyle }>Prerequisite Notes</div>
						  <div style={ fieldStyle }>{ event.prerequisiteNotes ?? '' }</div>
						</div>

					 </div>
				  </div>
				</div>

				{/* ---- Schedule ---- */}
				<div>
				  <div style={ labelStyle }>Schedule</div>

				  <div style={ scheduleAccentWrapStyle }>

					 <div style={ sectionHeaderStyle }>
						<div style={ sectionHeaderRowStyle }>
						  <div style={{ opacity: 0.7, fontSize: 13 }}>
							 { daysLoading ? 'Loading…' : `${sortedDays.length} day(s)` }
						  </div>

						  <div style={{ opacity: 0.85, fontSize: 13 }}>
							 Timezone: <code>{ timezoneLabel || '( none )' }</code>
						  </div>
						</div>
					 </div>

					 { daysError && (
						<div style={ errorBoxStyle }>
						  <strong>Days Error:</strong> { daysError }
						</div>
					 )}

					 { !daysLoading && !daysError && sortedDays.length === 0 && (
						<div style={{ marginTop: 10, opacity: 0.75 }}>
						  No days have been scheduled for this event yet.
						</div>
					 )}

					 { !daysLoading && !daysError && sortedDays.length > 0 && (
						<div style={ tableWrapStyle }>
						  <table style={ tableStyle }>
							 <thead>
								<tr>
								  <th style={ thStyle }>Date</th>
								  <th style={ thStyle }>Start</th>
								  <th style={ thStyle }>End</th>
								  <th style={ thStyle }>Duration</th>
								</tr>
							 </thead>
							 <tbody>
								{ sortedDays.map( ( d, idx ) => (
								  <tr key={ d.id } style={ rowStyle( idx ) }>
									 <td style={ tdStyle }>{ formatDate( d.startDateTime ) }</td>
									 <td style={ tdStyle }>{ formatTime( d.startDateTime ) }</td>
									 <td style={ tdStyle }>{ formatTime( d.endDateTime ) }</td>
									 <td style={ tdStyle }>{ durationText( d.startDateTime, d.endDateTime ) }</td>
								  </tr>
								)) }
							 </tbody>
						  </table>
						</div>
					 ) }

				  </div>
				</div>

			 </div>

			 {/* ==============================================================
				  Registrations
			 ============================================================== */}
			 <div style={{ marginTop: 14 }}>

				<div style={ labelStyle }>Registrations</div>

				<div style={ regsAccentWrapStyle }>

				  <div style={ sectionHeaderStyle }>
					 <div style={ sectionHeaderRowStyle }>
						<div style={{ opacity: 0.7, fontSize: 13 }}>
						  { regsLoading ? 'Loading…' : `${sortedRegs.length} registration(s)` }
						</div>

						<div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
						  <button
							 style={ buttonStyle( true ) }
							 onClick={ startAddReg }
							 disabled={ regsLoading || regSaving || editingRegID != null }
						  >
							 + Add registration
						  </button>
						</div>
					 </div>

					 { editingRegID && (
						<div style={{ marginTop: 10, opacity: 0.70, fontSize: 13 }}>
						  Editing:&nbsp;
						  <span style={ pillStyle( 'info' ) }>
							 { editingRegID === 'new' ? 'New' : `ID ${editingRegID}` }
						  </span>
						  { regSaving && <span style={{ marginLeft: 10, opacity: 0.85 }}>(Saving…)</span> }
						</div>
					 ) }

					 { ( customersLoading || customersError ) && (
						<div style={{ marginTop: 10, opacity: 0.75, fontSize: 13 }}>
						  Customers:&nbsp;
						  { customersLoading ? 'Loading…' : <span style={{ color: 'rgba( 255, 255, 255, 0.90 )' }}>{ customersError }</span> }
						</div>
					 ) }

					 { ( learnerProfilesLoading || learnerProfilesError ) && (
						<div style={{ marginTop: 6, opacity: 0.75, fontSize: 13 }}>
						  Learner Profiles:&nbsp;
						  { learnerProfilesLoading ? 'Loading…' : <span style={{ color: 'rgba( 255, 255, 255, 0.90 )' }}>{ learnerProfilesError }</span> }
						</div>
					 ) }

				  </div>

				  { regsError && (
					 <div style={ errorBoxStyle }>
						<strong>Registrations Error:</strong> { regsError }
					 </div>
				  )}

				  {/* =========================
					  Registration editor
				  ========================= */}
				  { editingRegID && regDraft && (
					 <div style={{ marginTop: 12, padding: 12, borderRadius: 12, border: '1px solid rgba( 255, 255, 255, 0.12 )', background: 'rgba( 0, 0, 0, 0.14 )' }}>

						<div style={ grid12 }>

						  <div style={ gi( 6, 12 ) }>
							 <div style={ labelStyle }>Customer</div>
							 <select
								style={ selectStyle }
								value={ String( regDraft.customerID ?? '' ) }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, customerID: e.target.value } ) ) }
								disabled={ customersLoading || !!customersError }
								required
							 >
								<option value="">{ customersLoading ? 'Loading customers…' : 'Select a customer…' }</option>
								{ customers.map( ( c ) => (
								  <option key={ c.id } value={ c.id }>{ c.name }</option>
								)) }
							 </select>
						  </div>

						  <div style={ gi( 2, 6 ) }>
							 <div style={ labelStyle }>Title</div>
							 <input
								style={ inputStyle }
								value={ regDraft.title }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, title: e.target.value } ) ) }
								placeholder="Mr, Ms, Dr…"
							 />
						  </div>

						  <div style={ gi( 4, 6 ) }>
							 <div style={ labelStyle }>Full Name</div>
							 <input
								style={ inputStyle }
								value={ regDraft.fullName }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, fullName: e.target.value } ) ) }
								placeholder="Required"
								required
							 />
						  </div>

						  <div style={ gi( 6, 12 ) }>
							 <div style={ labelStyle }>Learner Profile</div>
							 <select
								style={ selectStyle }
								value={ String( regDraft.learnerProfileID ?? '' ) }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, learnerProfileID: e.target.value } ) ) }
								disabled={ learnerProfilesLoading || !!learnerProfilesError }
							 >
								<option value="">{ learnerProfilesLoading ? 'Loading learner profiles…' : '( none )' }</option>
								{ learnerProfiles.map( ( lp ) => (
								  <option key={ lp.id } value={ lp.id }>{ lp.name }</option>
								)) }
							 </select>
						  </div>

						  <div style={ gi( 3, 6 ) }>
							 <div style={ labelStyle }>Registration Date</div>
							 <input
								type="date"
								style={ inputStyle }
								value={ regDraft.registrationDate }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, registrationDate: e.target.value } ) ) }
								required
							 />
						  </div>

						  <div style={ gi( 3, 6 ) }>
							 <div style={ labelStyle }>Pay Type ID</div>
							 <input
								style={ inputStyle }
								value={ regDraft.payTypeID }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, payTypeID: e.target.value } ) ) }
								inputMode="numeric"
							 />
						  </div>

						  <div style={ gi( 3, 6 ) }>
							 <div style={ labelStyle }>Certificates</div>
							 <input
								style={ inputStyle }
								value={ regDraft.certificateCount }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, certificateCount: e.target.value } ) ) }
								inputMode="numeric"
							 />
						  </div>

						  <div style={ gi( 3, 6 ) }>
							 <div style={ labelStyle }>HubSpot object id</div>
							 <input
								style={ inputStyle }
								value={ regDraft.hubspot_object_id }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, hubspot_object_id: e.target.value } ) ) }
							 />
						  </div>

						  <div style={{ gridColumn: 'span 12', minWidth: 0, display: 'flex', alignItems: 'center', gap: 10 }}>
							 <label style={{ display: 'flex', alignItems: 'center', gap: 8, opacity: 0.85 }}>
								<input
								  type="checkbox"
								  checked={ !!regDraft.taggedInHubspotInd }
								  onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, taggedInHubspotInd: e.target.checked } ) ) }
								/>
								Tagged in HubSpot
							 </label>
						  </div>

						  <div style={{ gridColumn: 'span 12', minWidth: 0 }}>
							 <div style={ labelStyle }>Notes</div>
							 <textarea
								style={ textareaStyle }
								value={ regDraft.notes }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, notes: e.target.value } ) ) }
								placeholder="Paid at door, dietary, invoice, etc."
							 />
						  </div>

						  <div style={ gi( 8, 12 ) }>
							 <div style={ labelStyle }>Prereq Override Reason</div>
							 <input
								style={ inputStyle }
								value={ regDraft.prerequisiteOverrideReason }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, prerequisiteOverrideReason: e.target.value } ) ) }
							 />
						  </div>

						  <div style={ gi( 4, 12 ) }>
							 <div style={ labelStyle }>Authorized By</div>
							 <input
								style={ inputStyle }
								value={ regDraft.prerequisiteOverrideAuthorizedBy }
								onChange={ ( e ) => setRegDraft( ( p ) => ( { ...p, prerequisiteOverrideAuthorizedBy: e.target.value } ) ) }
								inputMode="numeric"
							 />
						  </div>

						  <div style={{ gridColumn: 'span 12', minWidth: 0, display: 'flex', gap: 10, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
							 <button style={ smallBtnStyle( 'neutral' ) } onClick={ cancelReg } disabled={ regSaving }>
								Cancel
							 </button>
							 <button
								style={ buttonStyle( true ) }
								onClick={ saveReg }
								disabled={
								  regSaving ||
								  customersLoading ||
								  !!customersError ||
								  !String( regDraft.customerID ?? '' ).trim() ||
								  !String( regDraft.fullName ?? '' ).trim() ||
								  !String( regDraft.registrationDate ?? '' ).trim()
								}
							 >
								Save registration
							 </button>
						  </div>

						</div>

					 </div>
				  ) }

				  { !regsLoading && !regsError && registrations.length === 0 && (
					 <div style={{ marginTop: 10, opacity: 0.75 }}>
						No registrations yet.
					 </div>
				  )}

				  { !regsLoading && registrations.length > 0 && (
					 <div style={ tableWrapStyle }>
						<table style={ tableStyle }>
						  <thead>
							 <tr>
								<th style={ thSortStyle( 'customer' ) } onClick={ () => toggleRegSort( 'customer' ) }>
								  Customer{ sortGlyph( 'customer' ) }
								</th>
								<th style={ thSortStyle( 'registrant' ) } onClick={ () => toggleRegSort( 'registrant' ) }>
								  Registrant{ sortGlyph( 'registrant' ) }
								</th>
								<th style={ thSortStyle( 'registrationDate' ) } onClick={ () => toggleRegSort( 'registrationDate' ) }>
								  Reg date{ sortGlyph( 'registrationDate' ) }
								</th>
								<th style={ thSortStyle( 'payType' ) } onClick={ () => toggleRegSort( 'payType' ) }>
								  Pay{ sortGlyph( 'payType' ) }
								</th>
								<th style={ thSortStyle( 'certificateCount' ) } onClick={ () => toggleRegSort( 'certificateCount' ) }>
								  Certs{ sortGlyph( 'certificateCount' ) }
								</th>
								<th style={ thSortStyle( 'tagged' ) } onClick={ () => toggleRegSort( 'tagged' ) }>
								  Tagged{ sortGlyph( 'tagged' ) }
								</th>
								<th style={ thSortStyle( 'notes' ) } onClick={ () => toggleRegSort( 'notes' ) }>
								  Notes{ sortGlyph( 'notes' ) }
								</th>
								<th style={ thStyle }></th>
							 </tr>
						  </thead>
						  <tbody>
							 { sortedRegs.map( ( r, idx ) => (
								<tr key={ r.id } style={ rowStyle( idx ) }>

								  <td style={ tdStyle }>
									 <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
										<div style={{ opacity: 0.92 }}>
										  { r.customerName ?? '' }
										</div>
										{ r.customerStatusName ? <div style={{ opacity: 0.65, fontSize: 12 }}>{ r.customerStatusName }</div> : null }
									 </div>
								  </td>

								  <td style={ tdStyle }>
									 <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
										<div style={{ opacity: 0.92 }}>
										  { r.fullName
											 ? `${r.title ? `${r.title} ` : ''}${r.fullName}`
											 : ( r.title ?? '' )
										  }
										</div>
										{ r.learnerProfileName ? <div style={{ opacity: 0.75, fontSize: 12 }}>Learner: { r.learnerProfileName }</div> : null }
									 </div>
								  </td>

								  <td style={ tdStyle }>{ regDateText( r.registrationDate ) }</td>

								  <td style={ tdStyle }>
									 <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
										<code>{ r.payTypeID ?? '' }</code>
										{ r.paymentTypeName ? <div style={{ opacity: 0.75, fontSize: 12 }}>{ r.paymentTypeName }</div> : null }
									 </div>
								  </td>

								  <td style={ tdStyle }><code>{ r.certificateCount ?? '' }</code></td>

								  <td style={ tdStyle }>
									 <span style={ pillStyle( r.taggedInHubspotInd ? 'ok' : 'neutral' ) }>
										{ r.taggedInHubspotInd ? 'Yes' : 'No' }
									 </span>
								  </td>

								  <td style={ tdStyle }>
									 <div style={{ opacity: 0.88 }}>{ clip( r.notes ?? '', 80 ) }</div>
									 { r.prerequisiteOverrideReason ? (
										<div style={{ marginTop: 6, opacity: 0.70, fontSize: 12 }}>
										  Override: { clip( r.prerequisiteOverrideReason, 60 ) }
										</div>
									 ) : null }
								  </td>

								  <td style={ tdStyle }>
									 <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
										<button
										  style={ smallBtnStyle( 'neutral' ) }
										  onClick={ () => startEditReg( r ) }
										  disabled={ editingRegID != null || regSaving }
										>
										  Edit
										</button>
										<button
										  style={ smallBtnStyle( 'danger' ) }
										  onClick={ () => deleteReg( r ) }
										  disabled={ editingRegID != null || regSaving }
										>
										  Delete
										</button>
									 </div>
								  </td>

								</tr>
							 )) }
						  </tbody>
						</table>
					 </div>
				  ) }

				</div>

			 </div>

		  </>
		) }

	 </div>
  );

}
