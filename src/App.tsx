import { createBrowserRouter, redirect } from 'react-router-dom'
import { LoadingScreen } from '@/components/layout/LoadingScreen'
import { PlaceholderPage } from '@/components/layout/PlaceholderPage'
import { ProtectedLayout } from '@/components/layout/ProtectedLayout'
import type { RouteHandle } from '@/components/layout/AppHeader'
import { loadAdAccess, requireAdEdit } from '@/features/ad/access'
import { AdLayout } from '@/features/ad/AdLayout'
import { loadPersonDetail, loadPersonOverview } from '@/features/ad/personen/data'
import { PersonDetail } from '@/features/ad/personen/PersonDetail'
import { PersonenUebersicht } from '@/features/ad/personen/PersonenUebersicht'
import { PersonNeu } from '@/features/ad/personen/PersonNeu'
import { loadNewTemplate, loadTemplate, loadTemplateList } from '@/features/ad/rechtevorlagen/data'
import { RechtevorlageBearbeiten } from '@/features/ad/rechtevorlagen/RechtevorlageBearbeiten'
import { RechtevorlagenListe } from '@/features/ad/rechtevorlagen/RechtevorlagenListe'
import { LoginPage } from '@/features/auth/LoginPage'
import { KeinZugriffPage } from '@/features/start/KeinZugriffPage'
import { loadMyModules } from '@/features/start/modules'
import { StartPage } from '@/features/start/StartPage'
import { loadMe, requireSession } from '@/lib/rights'
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
        id: 'ad',
        path: 'ad',
        loader: loadAdAccess,
        element: <AdLayout />,
        handle: { moduleName: 'Administration' } satisfies RouteHandle,
        children: [
          { index: true, loader: loadPersonOverview, element: <PersonenUebersicht /> },
          { path: 'personen/neu', loader: requireAdEdit, element: <PersonNeu /> },
          { path: 'personen/:id', loader: loadPersonDetail, element: <PersonDetail /> },
          { path: 'rechtevorlagen', loader: loadTemplateList, element: <RechtevorlagenListe /> },
          { path: 'rechtevorlagen/neu', loader: loadNewTemplate, element: <RechtevorlageBearbeiten /> },
          { path: 'rechtevorlagen/:id', loader: loadTemplate, element: <RechtevorlageBearbeiten /> },
          { path: 'eigenschaftsarten', element: <PlaceholderPage title="Eigenschaftsarten" /> },
          { path: 'qualifikationsarten', element: <PlaceholderPage title="Qualifikationsarten" /> },
          { path: 'protokoll', element: <PlaceholderPage title="Protokoll" /> },
          { path: '*', element: <PlaceholderPage title="Administration" /> },
        ],
      },
    ],
  },
  { path: '*', loader: () => redirect('/') },
])
