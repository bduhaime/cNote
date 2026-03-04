import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../api';

export default function Customers() {

  const [ rows, setRows ] = useState( [] );
  const [ loading, setLoading ] = useState( true );
  const [ error, setError ] = useState( null );

  const [ query, setQuery ] = useState( '' );
  const [ sortKey, setSortKey ] = useState( 'name' );
  const [ sortDir, setSortDir ] = useState( 'asc' );

  useEffect( () => {

	 ( async () => {

		setLoading( true );
		setError( null );

		try {

		  const res = await apiFetch( '/api/customers' );

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

  const normalized = useMemo( () => {

	 const q = query.trim().toLowerCase();

	 const filtered = !q
		? rows
		: rows.filter( ( r ) => {
			 const name = ( r.name ?? '' ).toLowerCase();
			 const city = ( r.city ?? '' ).toLowerCase();
			 const st = ( r.stalp ?? '' ).toLowerCase();
			 const status = ( r.status ?? '' ).toLowerCase();
			 const cert = String( r.cert ?? '' ).toLowerCase();
			 const rssd = String( r.rssdID ?? '' ).toLowerCase();

			 return (
				name.includes( q ) ||
				city.includes( q ) ||
				st.includes( q ) ||
				status.includes( q ) ||
				cert.includes( q ) ||
				rssd.includes( q )
			 );
		  });

	 const dir = sortDir === 'asc' ? 1 : -1;

	 const toStr = ( v ) => String( v ?? '' ).toLowerCase();
	 const toNum = ( v ) => {
		const n = Number( v );
		return Number.isFinite( n ) ? n : Number.NEGATIVE_INFINITY;
	 };

	 const sorted = [ ...filtered ].sort( ( a, b ) => {

		if ( sortKey === 'rssdID' ) return ( toNum( a.rssdID ) - toNum( b.rssdID ) ) * dir;
		if ( sortKey === 'cert' ) return ( toNum( a.cert ) - toNum( b.cert ) ) * dir;

		const av = toStr( a[ sortKey ] );
		const bv = toStr( b[ sortKey ] );

		if ( av < bv ) return -1 * dir;
		if ( av > bv ) return 1 * dir;
		return 0;

	 });

	 return sorted;

  }, [ rows, query, sortKey, sortDir ] );

  const toggleSort = ( key ) => {

	 if ( sortKey === key ) {
		setSortDir( sortDir === 'asc' ? 'desc' : 'asc' );
	 } else {
		setSortKey( key );
		setSortDir( 'asc' );
	 }

  };

  const thStyle = {
	 textAlign: 'left',
	 fontSize: 12,
	 letterSpacing: 0.4,
	 textTransform: 'uppercase',
	 opacity: 0.75,
	 padding: '10px 12px',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.10 )',
	 cursor: 'pointer',
	 userSelect: 'none'
  };

  const tdStyle = {
	 padding: '10px 12px',
	 borderBottom: '1px solid rgba( 255, 255, 255, 0.08 )',
	 verticalAlign: 'top'
  };

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

  const badgeStyle = ( status ) => {

	 const s = String( status ?? '' ).toLowerCase();
	 const isActive = s === 'active' || s === 'reactive';

	 return {
		display: 'inline-block',
		padding: '4px 10px',
		borderRadius: 999,
		fontSize: 12,
		background: isActive ? 'rgba( 16, 185, 129, 0.18 )' : 'rgba( 245, 158, 11, 0.18 )',
		border: isActive ? '1px solid rgba( 16, 185, 129, 0.35 )' : '1px solid rgba( 245, 158, 11, 0.35 )',
		opacity: 0.95
	 };

  };

  const sortIndicator = ( key ) => {
	 if ( sortKey !== key ) return '';
	 return sortDir === 'asc' ? ' ▲' : ' ▼';
  };

  return (
	 <div style={ cardStyle }>

		<div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap' }}>
		  <div>
			 <h2 style={{ margin: 0 }}>Customers</h2>
			 <div style={{ marginTop: 6, opacity: 0.7, fontSize: 13 }}>
				{ loading ? 'Loading…' : `${normalized.length} of ${rows.length}` }
			 </div>
		  </div>

		  <input
			 value={ query }
			 onChange={ ( e ) => setQuery( e.target.value ) }
			 placeholder="Search name, city, state, status, cert, RSSD…"
			 style={ inputStyle }
		  />
		</div>

		{ error && (
		  <div style={{ marginTop: 16, padding: 12, borderRadius: 12, background: 'rgba( 239, 68, 68, 0.14 )', border: '1px solid rgba( 239, 68, 68, 0.35 )' }}>
			 <strong>Error:</strong> { error }
		  </div>
		)}

		<div style={{ marginTop: 14, overflowX: 'auto' }}>
		  <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 820 }}>
			 <thead>
				<tr>
				  <th style={ thStyle } onClick={ () => toggleSort( 'name' ) }>Name{ sortIndicator( 'name' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'rssdID' ) }>RSSD ID{ sortIndicator( 'rssdID' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'cert' ) }>Cert{ sortIndicator( 'cert' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'city' ) }>City{ sortIndicator( 'city' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'stalp' ) }>State{ sortIndicator( 'stalp' ) }</th>
				  <th style={ thStyle } onClick={ () => toggleSort( 'status' ) }>Status{ sortIndicator( 'status' ) }</th>
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
					 <td style={ tdStyle } colSpan={ 6 }>No customers found.</td>
				  </tr>
				)}

				{ !loading && normalized.map( ( r ) => (
				  <tr key={ r.DT_RowId ?? `${r.rssdID}-${r.cert}-${r.name}` }>
					 <td style={ tdStyle }>{ r.name }</td>
					 <td style={ tdStyle }>{ r.rssdID }</td>
					 <td style={ tdStyle }>{ r.cert }</td>
					 <td style={ tdStyle }>{ r.city }</td>
					 <td style={ tdStyle }>{ r.stalp }</td>
					 <td style={ tdStyle }><span style={ badgeStyle( r.status ) }>{ r.status }</span></td>
				  </tr>
				)) }
			 </tbody>
		  </table>
		</div>

	 </div>
  );
}
