import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { apiFetch } from './api';

const AuthContext = createContext( null );

export function AuthProvider( { children } ) {

  const [ me, setMe ] = useState( null );
  const [ loading, setLoading ] = useState( true );
  const [ error, setError ] = useState( null );

  const refresh = async () => {

	 setLoading( true );
	 setError( null );

	 try {

		const res = await apiFetch( '/api/auth/me' );

		let json = null;
		try { json = await res.json(); } catch ( e ) { json = null; }

		if ( !res.ok ) {
		  setMe( null );
		  setError( json?.error ?? json?.message ?? `AUTH HTTP ${res.status}` );
		  return;
		}

		setMe( json );

	 } catch ( err ) {

		setMe( null );
		setError( err?.message ?? String( err ) );

	 } finally {

		setLoading( false );

	 }

  };

  useEffect( () => { refresh(); }, [] );

  const value = useMemo( () => ({
	 me,
	 loading,
	 error,
	 refresh
  }), [ me, loading, error ] );

  return (
	 <AuthContext.Provider value={ value }>
		{ children }
	 </AuthContext.Provider>
  );

}

export function useAuth() {

  const ctx = useContext( AuthContext );
  if ( !ctx ) throw new Error( 'useAuth must be used within <AuthProvider>' );
  return ctx;

}
