import { Outlet, Link } from 'react-router-dom';
import { useAuth } from './AuthContext';

export default function App() {

  const { me, loading } = useAuth();

  const shell = {
    minHeight: '100vh',
    color: 'rgba( 255, 255, 255, 0.92 )',
    background: 'radial-gradient( circle at 20% 0%, #2a2a2a, #0f0f10 60% )',
    fontFamily: 'system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial'
  };

  const topbar = {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '18px 22px',
    borderBottom: '1px solid rgba( 255, 255, 255, 0.10 )',
    background: 'rgba( 0, 0, 0, 0.25 )',
    backdropFilter: 'blur( 8px )',
    position: 'sticky',
    top: 0
  };

  const badge = {
    padding: '6px 10px',
    borderRadius: 999,
    border: '1px solid rgba( 255, 255, 255, 0.14 )',
    background: 'rgba( 255, 255, 255, 0.06 )',
    fontSize: 13,
    opacity: 0.9
  };

  return (
    <div style={ shell }>

      <div style={ topbar }>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.5 }}>cNote UI</div>
          <Link to="/" style={{ color: 'rgba( 255, 255, 255, 0.85 )', textDecoration: 'none' }}>Home</Link>
          <Link to="/customers" style={{ color: 'rgba( 255, 255, 255, 0.85 )', textDecoration: 'none' }}>Customers</Link>
          <Link to="/events" style={{ color: 'rgba( 255, 255, 255, 0.85 )', textDecoration: 'none' }}>Events</Link>
        </div>

        <div style={ badge }>
          { loading ? 'Auth: checking…' : me ? `Auth: ${me.username}` : 'Auth: none' }
        </div>
      </div>

      <Outlet />

    </div>
  );

}
