import { useAuth } from '../AuthContext';

export default function Login() {

  const { error } = useAuth();

  return (
	 <div style={{ padding: 24 }}>
		<h2 style={{ marginTop: 0 }}>Login</h2>

		<div style={{ opacity: 0.8, maxWidth: 720 }}>
		  For now, login is “dev token mode”.
		  If you see this page, <code>/api/auth/me</code> returned 401.
		</div>

		{ error && (
		  <div style={{ marginTop: 14, padding: 12, borderRadius: 10, background: 'rgba( 239, 68, 68, 0.14 )', border: '1px solid rgba( 239, 68, 68, 0.35 )' }}>
			 <strong>Auth error:</strong> { error }
		  </div>
		)}

		<div style={{ marginTop: 14, opacity: 0.8 }}>
		  Fix your token in <code>.env.local</code> (VITE_DEV_JWT), restart Vite, then refresh.
		</div>
	 </div>
  );

}
