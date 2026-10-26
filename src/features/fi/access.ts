// Zugriff auf Finanzen (spec.md FI 3, Routenschutz): „FI lesen“ in irgendeiner Reichweite ist Voraussetzung;
// Auszahlungsrunden und Kletterhalle nur mit „FI verwalten“. Die Datenbank prüft beim Lesen und Schreiben erneut.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { requireSession } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type FiAccess = {
  /** FI = verwalten (Reichweite alle): Geschäftsstelle. */
  canManage: boolean
  /** Referate, deren Positionen der Nutzer bestätigen darf (Aktion „freigeben“, R23). */
  confirmReferate: string[]
}

async function rpcBool(name: string, args: Record<string, unknown>): Promise<boolean> {
  const { data, error } = await supabase.rpc(name, args)
  return !error && data === true
}

/** Ohne FI ≥ lesen → /kein-zugriff, bevor Daten abgefragt werden. */
export async function loadFiAccess(): Promise<FiAccess> {
  await requireSession()
  if (!(await rpcBool('ad_has_any_level', { p_module: 'FI', p_min: 'read' }))) throw redirect('/kein-zugriff')
  const [canManage, referate] = await Promise.all([
    rpcBool('ad_has_level', { p_module: 'FI', p_min: 'manage' }),
    supabase.rpc('ad_my_approve_referate', { p_module: 'FI' }),
  ])
  const confirmReferate = !referate.error && Array.isArray(referate.data) ? (referate.data as string[]) : []
  return { canManage, confirmReferate }
}

/** /fi/auszahlungen und /fi/kletterhalle nur mit „FI verwalten“. */
export async function requireFiManage(): Promise<FiAccess> {
  const access = await loadFiAccess()
  if (!access.canManage) throw redirect('/kein-zugriff')
  return access
}

export function useFiAccess(): FiAccess {
  return (useRouteLoaderData('fi') as FiAccess | undefined) ?? { canManage: false, confirmReferate: [] }
}
