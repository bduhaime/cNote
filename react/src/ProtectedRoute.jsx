import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthContext';

export default function ProtectedRoute( { children } ) {

  const { me, loading } = useAuth();

  if ( loading ) return null;

  if ( !me ) return <Navigate to="/login" replace />;

  return children;

}
