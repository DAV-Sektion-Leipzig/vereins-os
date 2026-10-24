// Zugriff auf GR (US-GR-01, spec T11): „Gruppen lesen“ ist Voraussetzung (GR spec.md 3, Routenschutz).
// Die Datenbank prüft beim Lesen und Schreiben erneut (RLS, Funktionen); das Frontend blendet nur aus.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { hasLevel, requireSession } from '@/lib/rights'

export type GrAccess = {
  /** Gruppen ≥ bearbeiten: Bearbeiten-Knöpfe, Abschnitt Gesundheit. */
  canEdit: boolean
  /** Gruppen = verwalten: Geburtsdatum erfassen, neue Teilnehmer:innen aufnehmen. */
  canManage: boolean
  /** Administration ≥ lesen: beendete Teilnahmen sichtbar (Pfad AD). */
  isAdmin: boolean
}

/** Ohne GR ≥ lesen → /kein-zugriff, bevor Daten abgefragt werden (spec.md 3). */
export async function loadGrAccess(): Promise<GrAccess> {
  await requireSession()
  if (!(await hasLevel('GR', 'read'))) throw redirect('/kein-zugriff')
  const [canEdit, canManage, isAdmin] = await Promise.all([hasLevel('GR', 'edit'), hasLevel('GR', 'manage'), hasLevel('AD', 'read')])
  return { canEdit, canManage, isAdmin }
}

/** Seiten nur mit bearbeiten (Gruppe anlegen, Aufnahme): sonst → /kein-zugriff. */
export async function requireGrEdit() {
  if (!(await hasLevel('GR', 'edit'))) throw redirect('/kein-zugriff')
  return null
}

export function useGrAccess(): GrAccess {
  return (useRouteLoaderData('gr') as GrAccess | undefined) ?? { canEdit: false, canManage: false, isAdmin: false }
}
