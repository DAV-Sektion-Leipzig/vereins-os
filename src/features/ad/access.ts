// Zugriff auf AD (T032): lesen ist Voraussetzung, bearbeiten schaltet Schreibknöpfe frei.
// Die Datenbank prüft beim Schreiben erneut (RLS); das Frontend blendet nur aus.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { hasLevel, requireLevel } from '@/lib/rights'

export type AdAccess = { canEdit: boolean }

export async function loadAdAccess(): Promise<AdAccess> {
  await requireLevel('AD', 'read')
  return { canEdit: await hasLevel('AD', 'edit') }
}

/** Für Seiten, die nur zum Schreiben da sind (z. B. „Neu“): ohne bearbeiten → /kein-zugriff. */
export async function requireAdEdit() {
  if (!(await hasLevel('AD', 'edit'))) throw redirect('/kein-zugriff')
}

export function useAdAccess(): AdAccess {
  return (useRouteLoaderData('ad') as AdAccess | undefined) ?? { canEdit: false }
}
