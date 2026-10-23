// Zugriff auf EA (US-EA-01, spec T10): lesen in irgendeiner Reichweite ist Voraussetzung.
// Die Datenbank prüft beim Lesen und Schreiben erneut (RLS); das Frontend blendet nur aus.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { hasAnyLevel, hasLevel, requireSession } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type EaAccess = {
  /** Geschäftsstelle und Admin: EA = verwalten (Reichweite alle). */
  canManage: boolean
  /** EA ≥ bearbeiten mit Reichweite alle. */
  canEdit: boolean
  /** Referate, in denen der Nutzer EA ≥ bearbeiten hat (Referent:in). */
  myReferate: string[]
}

async function loadMyReferate(): Promise<string[]> {
  const { data, error } = await supabase.rpc('ad_my_referate', { p_module: 'EA', p_min: 'edit' })
  return !error && Array.isArray(data) ? (data as string[]) : []
}

/** Ohne EA ≥ lesen → /kein-zugriff, bevor Personendaten abgefragt werden (US-EA-01 AK4). */
export async function loadEaAccess(): Promise<EaAccess> {
  await requireSession()
  if (!(await hasAnyLevel('EA', 'read'))) throw redirect('/kein-zugriff')
  const [canManage, canEdit, myReferate] = await Promise.all([
    hasLevel('EA', 'manage'),
    hasLevel('EA', 'edit'),
    loadMyReferate(),
  ])
  return { canManage, canEdit, myReferate }
}

/** Für Seiten nur mit verwalten (Gremien, Stammdaten, Arten): sonst → /kein-zugriff (US-EA-01 AK5). */
export async function requireEaManage() {
  if (!(await hasLevel('EA', 'manage'))) throw redirect('/kein-zugriff')
  return null
}

export function useEaAccess(): EaAccess {
  return (useRouteLoaderData('ea') as EaAccess | undefined) ?? { canManage: false, canEdit: false, myReferate: [] }
}
