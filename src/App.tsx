import { createBrowserRouter, redirect } from 'react-router-dom'
import { LoadingScreen } from '@/components/layout/LoadingScreen'
import { PlaceholderPage } from '@/components/layout/PlaceholderPage'
import { ProtectedLayout } from '@/components/layout/ProtectedLayout'
import type { RouteHandle } from '@/components/layout/AppHeader'
import { LoginPage } from '@/features/auth/LoginPage'
import { KeinZugriffPage } from '@/features/start/KeinZugriffPage'
import { loadMyModules } from '@/features/start/modules'
import { StartPage } from '@/features/start/StartPage'
import { loadMe, requireLevel, requireSession } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

// Routen nach spec.md AD Abschnitt 6 und contracts/routes.md. Noch nicht umgesetzte Seiten sind Platzhalter.
export const router = createBrowserRouter([
  {
    path: '/login',
    loader: async () => {
      const { data } = await supabase.auth.getSession()
      if (data.session) throw redirect('/')
      return null
    },
    element: <LoginPage />,
    HydrateFallback: LoadingScreen,
  },
  { path: '/passwort-vergessen', element: <PlaceholderPage title="Passwort vergessen" /> },
  { path: '/passwort-setzen', element: <PlaceholderPage title="Passwort setzen" /> },
  {
    // Geschützter Bereich: ohne Sitzung → /login (US-AD-02 AK5)
    id: 'protected',
    loader: async () => {
      await requireSession()
      return { me: await loadMe() }
    },
    element: <ProtectedLayout />,
    HydrateFallback: LoadingScreen,
    children: [
      { index: true, loader: loadMyModules, element: <StartPage /> },
      { path: 'kein-zugriff', element: <KeinZugriffPage /> },
      {
        // AD nur mit AD ≥ lesen; sonst /kein-zugriff ohne Datenabfrage (US-AD-05 AK3)
        path: 'ad',
        loader: () => requireLevel('AD', 'read').then(() => null),
        handle: { moduleName: 'Administration' } satisfies RouteHandle,
        children: [
          { index: true, element: <PlaceholderPage title="Administration" /> },
          { path: '*', element: <PlaceholderPage title="Administration" /> },
        ],
      },
    ],
  },
  { path: '*', loader: () => redirect('/') },
])
