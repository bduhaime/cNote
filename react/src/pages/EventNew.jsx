import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiFetch } from '../api';

export default function EventNew() {

  const navigate = useNavigate();

  const [ form, setForm ] = useState({
	 name: '',
	 location: '',
	 isVirtual: false,
	 prerequisiteNotes: '',
	 repeatAttendancePolicy: '',
	 whoShouldAttend: ''
  });

  const [ saving, setSaving ] = useState( false );
  const [ error, setError ] = useState( null );

  const set = ( key, value ) => {
	 setForm( ( prev ) => ( { ...prev, [ key ]: value } ) );
  };

  const trimmed = useMemo( () => ( {
	 name: form.name.trim(),
	 location: form.location.trim(),
	 isVirtual: !!form.isVirtual,
	 prerequisiteNotes: form.prerequisiteNotes.trim(),
	 repeatAttendancePolicy: form.repeatAttendancePolicy.trim(),
	 whoShouldAttend: form.whoShouldAttend.trim()
  } ), [ form ] );

  const validation = useMemo( () => {

	 const errs = {};

	 if ( !trimmed.name ) errs.name = 'Name is required.';
	 if ( trimmed.name && trimmed.name.length > 255 ) errs.name = 'Max 255 characters.';

	 if ( trimmed.location && trimmed.location.length > 255 ) errs.location = 'Max 255 characters.';
	 if ( trimmed.repeatAttendancePolicy && trimmed.repeatAttendancePolicy.length > 255 ) errs.repeatAttendancePolicy = 'Max 255 characters.';
	 if ( trimmed.whoShouldAttend && trimmed.whoShouldAttend.length > 255 ) errs.whoShouldAttend = 'Max 255 characters.';

	 return errs;

  }, [ trimmed ] );

  const canSave = Object.keys( validation ).length === 0 && !saving;

  const onSave = async () => {

	 setError( null );

	 if ( !canSave ) {
		setError( 'Fix validation errors first.' );
		return;
	 }

	 try {

		setSaving( true );

		const payload = {
		  name: trimmed.name,
		  location: trimmed.location || null,
		  isVirtual: !!trimmed.isVirtual,
		  prerequisiteNotes: trimmed.prerequisiteNotes || null,
		  repeatAttendancePolicy: trimmed.repeatAttendancePolicy || null,
		  whoShouldAttend: trimmed.whoShouldAttend || null
		};

		const res = await apiFetch( '/api/events', {
		  method: 'POST',
		  headers: {
			 'Content-Type': 'application/json'
		  },
		  body: JSON.stringify( payload )
		});

		let json = null;
		try { json = await res.json(); } catch ( e ) { json = null; }

		if ( !res.ok ) throw new Error( json?.error ?? json?.message ?? `HTTP ${res.status}` );

		const newId = json?.id ?? null;
		if ( !newId ) throw new Error( 'Event created, but no id was returned by the API.' );

		navigate( `/events/${newId}` );

	 } catch ( err ) {

		setError( err?.message ?? String( err ) );

	 } finally {

		setSaving( false );

	 }

  };

  // Luxury: Cmd/Ctrl+Enter submits the form
  useEffect( () => {

	 const onKeyDown = ( e ) => {

		if ( e.key !== 'Enter' ) return;

		const isSubmitChord = ( e.metaKey || e.ctrlKey );
		if ( !isSubmitChord ) return;

		// Don’t fire if disabled; also avoid accidental browser/system shortcuts
		if ( saving ) return;

		e.preventDefault();
		onSave();

	 };

	 window.addEventListener( 'keydown', onKeyDown );
	 return () => window.removeEventListener( 'keydown', onKeyDown );

  }, [ saving, canSave, trimmed, validation ] ); // keep handler current

  // ---- styles ----
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
	 cursor: saving ? 'not-allowed' : 'pointer',
	 opacity: saving ? 0.7 : 1,
	 whiteSpace: 'nowrap'
  } );

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

  return (
	 <div style={ cardStyle }>

		<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 12, flexWrap: 'wrap' }}>
		  <div>
			 <div style={{ opacity: 0.7, fontSize: 13 }}>Events</div>
			 <h2 style={{ margin: 0 }}>New Event</h2>
			 <div style={{ marginTop: 6, opacity: 0.65, fontSize: 13 }}>
				Tip: ⌘+Enter (or Ctrl+Enter) to create.
			 </div>
		  </div>

		  <div style={{ display: 'flex', gap: 10 }}>
			 <button
				style={ buttonStyle( false ) }
				onClick={ () => navigate( '/events' ) }
				disabled={ saving }
			 >
				Cancel
			 </button>

			 <button
				style={ buttonStyle( true ) }
				onClick={ onSave }
				disabled={ !canSave }
				title={ Object.keys( validation ).length ? 'Fix validation errors first' : '' }
			 >
				{ saving ? 'Saving…' : 'Create Event' }
			 </button>
		  </div>
		</div>

		{ error && (
		  <div style={ errorBoxStyle }>
			 <strong>Error:</strong> { error }
		  </div>
		)}

		<div style={ gridStyle }>

		  <div style={ col( 8 ) }>
			 <div style={ labelStyle }>Name *</div>
			 <input
				style={ inputStyle }
				value={ form.name }
				onChange={ ( e ) => set( 'name', e.target.value ) }
				placeholder="Event name"
				maxLength={ 255 }
				disabled={ saving }
				autoFocus
			 />
			 { validation.name && fieldError( validation.name ) }
		  </div>

		  <div style={ col( 4 ) }>
			 <div style={ labelStyle }>Virtual</div>
			 <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 12, border: '1px solid rgba( 255, 255, 255, 0.14 )', background: 'rgba( 0, 0, 0, 0.25 )' }}>
				<input
				  type="checkbox"
				  checked={ !!form.isVirtual }
				  onChange={ ( e ) => set( 'isVirtual', e.target.checked ) }
				  disabled={ saving }
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
				placeholder={ form.isVirtual ? 'e.g., Zoom / Teams link (or leave blank)' : 'City, State (or address)' }
				maxLength={ 255 }
				disabled={ saving }
			 />
			 { validation.location && fieldError( validation.location ) }
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Who Should Attend</div>
			 <input
				style={ inputStyle }
				value={ form.whoShouldAttend }
				onChange={ ( e ) => set( 'whoShouldAttend', e.target.value ) }
				placeholder="e.g., Junior Developers, Database Engineers…"
				maxLength={ 255 }
				disabled={ saving }
			 />
			 { validation.whoShouldAttend && fieldError( validation.whoShouldAttend ) }
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Repeat Attendance Policy</div>
			 <input
				style={ inputStyle }
				value={ form.repeatAttendancePolicy }
				onChange={ ( e ) => set( 'repeatAttendancePolicy', e.target.value ) }
				placeholder="e.g., May attend once per calendar year…"
				maxLength={ 255 }
				disabled={ saving }
			 />
			 { validation.repeatAttendancePolicy && fieldError( validation.repeatAttendancePolicy ) }
		  </div>

		  <div style={ col( 12 ) }>
			 <div style={ labelStyle }>Prerequisite Notes</div>
			 <textarea
				style={ textareaStyle }
				value={ form.prerequisiteNotes }
				onChange={ ( e ) => set( 'prerequisiteNotes', e.target.value ) }
				placeholder="Optional prerequisites, preparation notes, etc."
				disabled={ saving }
			 />
		  </div>

		</div>

	 </div>
  );

}
