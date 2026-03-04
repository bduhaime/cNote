import React from 'react';
import ReactDOM from 'react-dom/client';
import { createBrowserRouter, RouterProvider } from 'react-router-dom';

import App from './App.jsx';
import { AuthProvider } from './AuthContext.jsx';
import ProtectedRoute from './ProtectedRoute.jsx';

import Home from './pages/Home.jsx';
import Login from './pages/Login.jsx';
import Customers from './pages/Customers.jsx';
import Events from './pages/Events.jsx';
import EventDetail from './pages/EventDetail.jsx';
import EventNew from './pages/EventNew.jsx';
import EventEdit from './pages/EventEdit.jsx';

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      {
        index: true,
        element: (
          <ProtectedRoute>
            <Home />
          </ProtectedRoute>
        )
      },
      {
        path: 'customers',
        element: (
          <ProtectedRoute>
            <Customers />
          </ProtectedRoute>
        )
      },
      {
        path: 'events',
        element: (
          <ProtectedRoute>
            <Events />
          </ProtectedRoute>
        )
      },
      {
        path: 'events/new',
        element: (
          <ProtectedRoute>
            <EventNew />
          </ProtectedRoute>
        )
      },
      {
        path: 'events/:id/edit',
        element: (
          <ProtectedRoute>
            <EventEdit />
          </ProtectedRoute>
        )
      },
      {
        path: 'events/:id',
        element: (
          <ProtectedRoute>
            <EventDetail />
          </ProtectedRoute>
        )
      },
      {
        path: 'login',
        element: <Login />
      }
    ]
  },
  {
    path: 'customers',
    element: (
      <ProtectedRoute>
        <Customers />
      </ProtectedRoute>
    )
  }
]);

ReactDOM.createRoot( document.getElementById( 'root' ) ).render(
  <React.StrictMode>
    <AuthProvider>
      <RouterProvider router={ router } />
    </AuthProvider>
  </React.StrictMode>
);
