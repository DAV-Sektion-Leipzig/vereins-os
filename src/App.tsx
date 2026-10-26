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
import { AbrechnungsartenPage } from '@/features/ad/abrechnungsarten/AbrechnungsartenPage'
import { loadRemuneration } from '@/features/ad/abrechnungsarten/data'
import { AuszahlungPage } from '@/features/ad/auszahlung/AuszahlungPage'
import { loadPayoutAdmin } from '@/features/ad/auszahlung/data'
import { loadRates } from '@/features/ad/saetze/data'
import { SaetzePage } from '@/features/ad/saetze/SaetzePage'
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
import { loadDsAccess } from '@/features/ds/access'
import { DashboardPage } from '@/features/ds/budget/DashboardPage'
import { loadDashboard, loadItem, loadVerein } from '@/features/ds/budget/data'
import { PostenPage } from '@/features/ds/budget/PostenPage'
import { VereinPage } from '@/features/ds/budget/VereinPage'
import { loadPflege } from '@/features/ds/pflege/data'
import { PflegePage } from '@/features/ds/pflege/PflegePage'
import { DsLayout } from '@/features/ds/DsLayout'
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
import { AufnahmenPage } from '@/features/gr/aufnahme/AufnahmenPage'
import { AufnahmePage } from '@/features/gr/aufnahme/AufnahmePage'
import { loadAdmission, loadPendingAdmissions } from '@/features/gr/aufnahme/data'
import { GrLayout } from '@/features/gr/GrLayout'
import { loadGroupOverview } from '@/features/gr/gruppen/data'
import { loadGroupDetail } from '@/features/gr/gruppen/detail'
import { loadPersonPage } from '@/features/gr/personen/data'
import { PersonPage } from '@/features/gr/personen/PersonPage'
import { GruppeDetailPage } from '@/features/gr/gruppen/GruppeDetailPage'
import { GruppeNeuPage } from '@/features/gr/gruppen/GruppeFormular'
import { GruppenPage } from '@/features/gr/gruppen/GruppenPage'
import { loadStammdaten } from '@/features/ea/stammdaten/data'
import { loadEzAccess } from '@/features/ez/access'
import { loadEventDetail } from '@/features/ez/detail/data'
import { EinsatzDetailPage } from '@/features/ez/detail/EinsatzDetailPage'
import { EinsatzBearbeitenPage } from '@/features/ez/erfassen/EinsatzBearbeitenPage'
import { EinsatzNeuPage } from '@/features/ez/erfassen/EinsatzNeuPage'
import { loadEditEvent, loadNewEvent } from '@/features/ez/erfassen/data'
import { loadReport } from '@/features/ez/kletterhalle/data'
import { KletterhallePage } from '@/features/ez/kletterhalle/KletterhallePage'
import { EzLayout } from '@/features/ez/EzLayout'
import { EinsaetzePage } from '@/features/ez/liste/EinsaetzePage'
import { loadEventList } from '@/features/ez/liste/data'
import { loadFiAccess } from '@/features/fi/access'
import { AuszahlungenPage } from '@/features/fi/auszahlungen/AuszahlungenPage'
import { AuszahlungsrundePage } from '@/features/fi/auszahlungen/AuszahlungsrundePage'
import { loadRun, loadRuns } from '@/features/fi/auszahlungen/data'
import { AbrechnungDetailPage } from '@/features/fi/detail/AbrechnungDetailPage'
import { loadSettlement } from '@/features/fi/detail/data'
import { loadCollectionRun, loadCollectionRuns } from '@/features/fi/einzug/data'
import { EinzugLaufPage } from '@/features/fi/einzug/EinzugLaufPage'
import { EinzugPage } from '@/features/fi/einzug/EinzugPage'
import { FiLayout } from '@/features/fi/FiLayout'
import { loadClimbing } from '@/features/fi/kletterhalle/data'
import { KletterhallePage as FiKletterhallePage } from '@/features/fi/kletterhalle/KletterhallePage'
import { AbrechnungenPage } from '@/features/fi/liste/AbrechnungenPage'
import { loadSettlementList } from '@/features/fi/liste/data'
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
        // Dashboard mit DS ≥ lesen in irgendeiner Reichweite; Budgetpflege nur mit „darf Budget pflegen“
        // (spec.md DS v0.2 Abschnitte 3 und 6).
        id: 'ds',
        path: 'dashboard',
        loader: loadDsAccess,
        element: <DsLayout />,
        handle: { moduleName: 'Dashboard' } satisfies RouteHandle,
        children: [
          { index: true, loader: loadDashboard, element: <DashboardPage /> },
          { path: 'verein', loader: loadVerein, element: <VereinPage /> },
          { path: 'budget/posten/:id', loader: loadItem, element: <PostenPage /> },
          { path: 'budget/pflege', loader: loadPflege, element: <PflegePage /> },
          { path: '*', loader: () => redirect('/dashboard') },
        ],
      },
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
          { path: 'saetze', loader: loadRates, element: <SaetzePage /> },
          { path: 'abrechnungsarten', loader: loadRemuneration, element: <AbrechnungsartenPage /> },
          { path: 'auszahlung', loader: loadPayoutAdmin, element: <AuszahlungPage /> },
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
          { path: 'aufnahmen', loader: loadPendingAdmissions, element: <AufnahmenPage /> },
          { path: 'gruppen/neu', loader: requireGrEdit, element: <GruppeNeuPage /> },
          { path: 'gruppen/:id', loader: loadGroupDetail, element: <GruppeDetailPage /> },
          {
            path: 'gruppen/:id/aufnehmen',
            loader: async (args) => (await requireGrEdit(), loadAdmission(args)),
            element: <AufnahmePage />,
          },
          { path: 'personen/:id', loader: loadPersonPage, element: <PersonPage /> },
          { path: '*', loader: () => redirect('/gr') },
        ],
      },
      {
        // EZ mit EZ ≥ lesen in irgendeiner Reichweite; sonst /kein-zugriff ohne Datenabfrage (EZ spec.md 3,
        // contracts/routes.md). Weitere Seiten folgen je Story auf eigenen Branches (plan.md „Branches“).
        id: 'ez',
        path: 'ez',
        loader: loadEzAccess,
        element: <EzLayout />,
        handle: { moduleName: 'Anwesenheitserfassung' } satisfies RouteHandle,
        children: [
          { index: true, loader: loadEventList, element: <EinsaetzePage /> },
          { path: 'neu', loader: loadNewEvent, element: <EinsatzNeuPage /> },
          { path: 'kletterhalle', loader: loadReport, element: <KletterhallePage /> },
          { path: ':id', loader: loadEventDetail, element: <EinsatzDetailPage /> },
          { path: ':id/bearbeiten', loader: loadEditEvent, element: <EinsatzBearbeitenPage /> },
          { path: '*', loader: () => redirect('/ez') },
        ],
      },
      {
        // FI mit FI ≥ lesen in irgendeiner Reichweite; Auszahlungsrunden und Kletterhalle nur mit „FI verwalten“
        // (spec.md FI 3, Routenschutz).
        id: 'fi',
        path: 'fi',
        loader: loadFiAccess,
        element: <FiLayout />,
        handle: { moduleName: 'Finanzen' } satisfies RouteHandle,
        children: [
          { index: true, loader: loadSettlementList, element: <AbrechnungenPage /> },
          { path: 'abrechnung/:id', loader: loadSettlement, element: <AbrechnungDetailPage /> },
          { path: 'auszahlungen', loader: loadRuns, element: <AuszahlungenPage /> },
          { path: 'auszahlungen/:id', loader: loadRun, element: <AuszahlungsrundePage /> },
          { path: 'einzug', loader: loadCollectionRuns, element: <EinzugPage /> },
          { path: 'einzug/:id', loader: loadCollectionRun, element: <EinzugLaufPage /> },
          { path: 'kletterhalle', loader: loadClimbing, element: <FiKletterhallePage /> },
          { path: '*', loader: () => redirect('/fi') },
        ],
      },
    ],
  },
  { path: '*', loader: () => redirect('/') },
])
