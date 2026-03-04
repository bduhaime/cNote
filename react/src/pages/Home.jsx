import { useAuth } from '../AuthContext';

export default function Home() {

  const { me, refresh } = useAuth();

  return (
	 <div style={{ padding: 24 }}>
		<h2 style={{ marginTop: 0 }}>Home</h2>

		<div style={{ marginTop: 12 }}>
		  <div><strong>User:</strong> { me?.username }</div>
		  <div><strong>UserID:</strong> { me?.userID }</div>
		  <div><strong>DB:</strong> { me?.dbName }</div>
		  <div><strong>Client:</strong> { me?.clientNbr }</div>
		</div>

		<button
		  style={{
			 marginTop: 18,
			 padding: '10px 14px',
			 borderRadius: 10,
			 border: '1px solid rgba( 255, 255, 255, 0.18 )',
			 background: 'rgba( 255, 255, 255, 0.08 )',
			 color: 'rgba( 255, 255, 255, 0.9 )',
			 cursor: 'pointer'
		  }}
		  onClick={ refresh }
		>
		  Refresh /api/auth/me
		</button>
	 </div>
  );

}
