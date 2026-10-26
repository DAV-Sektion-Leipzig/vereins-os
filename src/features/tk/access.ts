// Zugriff auf die Planungshilfe (spec.md TK 3): „TK lesen“ in irgendeiner Reichweite ist Voraussetzung.
// Die Datenbank prüft beim Lesen und Schreiben erneut (RLS, Funktionen); das Frontend blendet nur aus.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { requireSession } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type TkAccess = {
  /** TK ≥ bearbeiten in irgendeiner Reichweite: „Neue Planung“, Kopieren. */
  canEdit: boolean
  /** TK = verwalten (Geschäftsstelle): Löschen, Abschließen, CSV. */
  canManage: boolean
  /** Referate mit TK ≥ bearbeiten (Referent:in, Freigabe). */
  editReferate: string[]
  canEditAll: boolean
}

async function rpcBool(name: string, args: Record<string, unknown>): Promise<boolean> {
  const { data, error } = await supabase.rpc(name, args)
  return !error && data === true
}

/** Ohne TK ≥ lesen → /kein-zugriff, bevor Daten abgefragt werden. */
export async function loadTkAccess(): Promise<TkAccess> {
  await requireSession()
  if (!(await rpcBool('ad_has_any_level', { p_module: 'TK', p_min: 'read' }))) throw redirect('/kein-zugriff')
  const [canEditAll, refs, canManage] = await Promise.all([
    rpcBool('ad_has_level', { p_module: 'TK', p_min: 'edit' }),
    supabase.rpc('ad_my_referate', { p_module: 'TK', p_min: 'edit' }),
    rpcBool('ad_has_level', { p_module: 'TK', p_min: 'manage' }),
  ])
  const editReferate = !refs.error && Array.isArray(refs.data) ? (refs.data as string[]) : []
  return { canEdit: canEditAll || editReferate.length > 0, canManage, editReferate, canEditAll }
}

export async function requireTkEdit(): Promise<TkAccess> {
  const access = await loadTkAccess()
  if (!access.canEdit) throw redirect('/kein-zugriff')
  return access
}

export function useTkAccess(): TkAccess {
  return (
    (useRouteLoaderData('tk') as TkAccess | undefined) ?? { canEdit: false, canManage: false, editReferate: [], canEditAll: false }
  )
}
