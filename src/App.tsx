import { createBrowserRouter, redirect } from 'react-router-dom'
import { LoadingScreen } from '@/components/layout/LoadingScreen'
import { PlaceholderPage } from '@/components/layout/PlaceholderPage'
import { ProtectedLayout } from '@/components/layout/ProtectedLayout'
import type { RouteHandle } from '@/components/layout/AppHeader'
import { loadAdAccess, requireAdEdit } from '@/features/ad/access'
import { AdLayout } from '@/features/ad/AdLayout'
import {
  loadNewPropertyType,
  loadPropertyType,
  loadPropertyTypes,
  newPropertyTypeLoader,
  propertyTypeLoader,
  propertyTypesLoader,
} from '@/features/ad/eigenschaftsarten/data'
import { EigenschaftsartBearbeiten } from '@/features/ad/eigenschaftsarten/EigenschaftsartBearbeiten'
import { EigenschaftsartenListe } from '@/features/ad/eigenschaftsarten/EigenschaftsartenListe'
import { loadPersonDetail, loadPersonOverview } from '@/features/ad/personen/data'
import { PersonDetail } from '@/features/ad/personen/PersonDetail'
import { PersonenUebersicht } from '@/features/ad/personen/PersonenUebersicht'
import { PersonNeu } from '@/features/ad/personen/PersonNeu'
import { loadAuditLog } from '@/features/ad/protokoll/data'
import { ProtokollPage } from '@/features/ad/protokoll/ProtokollPage'
import {
  loadNewQualificationType,
  loadQualificationType,
  loadQualificationTypes,
  newQualificationTypeLoader,
  qualificationTypeLoader,
  qualificationTypesLoader,
} from '@/features/ad/qualifikationsarten/data'
import { QualifikationsartenListe } from '@/features/ad/qualifikationsarten/QualifikationsartenListe'
import { QualifikationsartFormular } from '@/features/ad/qualifikationsarten/QualifikationsartFormular'
import { loadNewTemplate, loadTemplate, loadTemplateList } from '@/features/ad/rechtevorlagen/data'
import { RechtevorlageBearbeiten } from '@/features/ad/rechtevorlagen/RechtevorlageBearbeiten'
import { RechtevorlagenListe } from '@/features/ad/rechtevorlagen/RechtevorlagenListe'
import { LoginPage } from '@/features/auth/LoginPage'
import { PasswortSetzenPage } from '@/features/auth/PasswortSetzenPage'
import { PasswortVergessenPage } from '@/features/auth/PasswortVergessenPage'
import { loadEaAccess } from '@/features/ea/access'
import { AblaufPage } from '@/features/ea/ablauf/AblaufPage'
import { loadExpiryList } from '@/features/ea/ablauf/data'
import { AktivePage } from '@/features/ea/aktive/AktivePage'
import { loadNewVolunteer, loadVolunteerDetail, loadVolunteers } from '@/features/ea/aktive/data'
import { PersonDetailPage } from '@/features/ea/aktive/PersonDetailPage'
import { PersonNeuPage } from '@/features/ea/aktive/PersonNeuPage'
import { EaLayout } from '@/features/ea/EaLayout'
import { loadGremien } from '@/features/ea/gremien/data'
import { GremienPage } from '@/features/ea/gremien/GremienPage'
import { loadGrAccess, requireGrEdit } from '@/features/gr/access'
import { GrLayout } from '@/features/gr/GrLayout'
import { loadGroupOverview } from '@/features/gr/gruppen/data'
import { GruppenPage } from '@/features/gr/gruppen/GruppenPage'
import { loadStammdaten } from '@/features/ea/stammdaten/data'
import { StammdatenPage } from '@/features/ea/stammdaten/StammdatenPage'
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
  { path: '/passwort-vergessen', element: <PasswortVergessenPage /> },
  { path: '/passwort-setzen', element: <PasswortSetzenPage /> },
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
          { path: 'eigenschaftsarten', loader: loadPropertyTypes, element: <EigenschaftsartenListe /> },
          { path: 'eigenschaftsarten/neu', loader: loadNewPropertyType, element: <EigenschaftsartBearbeiten /> },
          { path: 'eigenschaftsarten/:id', loader: loadPropertyType, element: <EigenschaftsartBearbeiten /> },
          { path: 'qualifikationsarten', loader: loadQualificationTypes, element: <QualifikationsartenListe /> },
          { path: 'qualifikationsarten/neu', loader: loadNewQualificationType, element: <QualifikationsartFormular /> },
          { path: 'qualifikationsarten/:id', loader: loadQualificationType, element: <QualifikationsartFormular /> },
          { path: 'protokoll', loader: loadAuditLog, element: <ProtokollPage /> },
          { path: '*', element: <PlaceholderPage title="Administration" /> },
        ],
      },
      {
        // EA mit EA ≥ lesen in irgendeiner Reichweite; sonst /kein-zugriff ohne Datenabfrage (US-EA-01 AK4)
        id: 'ea',
        path: 'ea',
        loader: loadEaAccess,
        element: <EaLayout />,
        handle: { moduleName: 'Ehrenamtsmanagement' } satisfies RouteHandle,
        children: [
          { index: true, loader: () => redirect('/ea/aktive') },
          { path: 'aktive', loader: loadVolunteers, element: <AktivePage /> },
          { path: 'aktive/neu', loader: loadNewVolunteer, element: <PersonNeuPage /> },
          { path: 'aktive/:id', loader: loadVolunteerDetail, element: <PersonDetailPage /> },
          { path: 'ablauf', loader: loadExpiryList, element: <AblaufPage /> },
          // nur mit verwalten (US-EA-01 AK5)
          { path: 'gremien', loader: loadGremien, element: <GremienPage /> },
          // Seiten der Administration unter /ea (US-EA-15, T052)
          { path: 'eigenschaftsarten', loader: propertyTypesLoader('EA'), element: <EigenschaftsartenListe basePath="/ea/eigenschaftsarten" /> },
          { path: 'eigenschaftsarten/neu', loader: newPropertyTypeLoader('EA'), element: <EigenschaftsartBearbeiten basePath="/ea/eigenschaftsarten" /> },
          { path: 'eigenschaftsarten/:id', loader: propertyTypeLoader('EA'), element: <EigenschaftsartBearbeiten basePath="/ea/eigenschaftsarten" /> },
          { path: 'qualifikationsarten', loader: qualificationTypesLoader('EA'), element: <QualifikationsartenListe basePath="/ea/qualifikationsarten" /> },
          { path: 'qualifikationsarten/neu', loader: newQualificationTypeLoader('EA'), element: <QualifikationsartFormular basePath="/ea/qualifikationsarten" /> },
          { path: 'qualifikationsarten/:id', loader: qualificationTypeLoader('EA'), element: <QualifikationsartFormular basePath="/ea/qualifikationsarten" /> },
          { path: 'stammdaten', loader: loadStammdaten, element: <StammdatenPage /> },
          { path: '*', loader: () => redirect('/ea/aktive') },
        ],
      },
      {
        // GR mit GR ≥ lesen; sonst /kein-zugriff ohne Datenabfrage (GR spec.md 3, contracts/routes.md).
        // Seiten folgen je Story auf eigenen Branches (plan.md „Branches“); bis dahin Platzhalter.
        id: 'gr',
        path: 'gr',
        loader: loadGrAccess,
        element: <GrLayout />,
        handle: { moduleName: 'Gruppen' } satisfies RouteHandle,
        children: [
          { index: true, loader: loadGroupOverview, element: <GruppenPage /> },
          { path: 'aufnahmen', element: <PlaceholderPage title="Aufnahmen offen" /> },
          { path: 'gruppen/neu', loader: requireGrEdit, element: <PlaceholderPage title="Gruppe anlegen" /> },
          { path: 'gruppen/:id', element: <PlaceholderPage title="Gruppe" /> },
          { path: 'gruppen/:id/aufnehmen', loader: requireGrEdit, element: <PlaceholderPage title="Teilnehmer:in aufnehmen" /> },
          { path: 'personen/:id', element: <PlaceholderPage title="Person" /> },
          { path: '*', loader: () => redirect('/gr') },
        ],
      },
    ],
  },
  { path: '*', loader: () => redirect('/') },
])
