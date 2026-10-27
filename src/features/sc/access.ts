// Zugriff auf „Schnittstellen“ (spec.md SC v0.2 Abschnitt 3): SC ≥ lesen ist Voraussetzung; bearbeiten für Vorlagen,
// Test-E-Mail und Postausgang, verwalten für Anbindung, Key, Zustand und Freigaben. Die Datenbank prüft erneut (R17).
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { hasLevel, requireSession } from '@/lib/rights'

export type ScAccess = { canEdit: boolean; canManage: boolean }

/** Ohne SC ≥ lesen → /kein-zugriff, bevor Daten abgefragt werden. */
export async function loadScAccess(): Promise<ScAccess> {
  await requireSession()
  if (!(await hasLevel('SC', 'read'))) throw redirect('/kein-zugriff')
  const [canEdit, canManage] = await Promise.all([hasLevel('SC', 'edit'), hasLevel('SC', 'manage')])
  return { canEdit, canManage }
}

export function useScAccess(): ScAccess {
  return (useRouteLoaderData('sc') as ScAccess | undefined) ?? { canEdit: false, canManage: false }
}
