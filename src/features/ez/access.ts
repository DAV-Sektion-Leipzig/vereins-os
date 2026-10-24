// Zugriff auf EZ (spec.md EZ 3, contracts/routes.md): „EZ lesen“ in irgendeiner Reichweite ist Voraussetzung.
// Die Datenbank prüft beim Lesen und Schreiben erneut (RLS, Funktionen); das Frontend blendet nur aus.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { requireSession } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type EzAccess = {
  /** EZ ≥ bearbeiten in irgendeiner Reichweite: „Neuer Einsatz“, Kontrolle Kletterhalle. */
  canEdit: boolean
  /** EZ ≥ bearbeiten mit Reichweite alle (Geschäftsstelle). */
  canEditAll: boolean
  /** Referate mit EZ ≥ bearbeiten (Referent:in). */
  editReferate: string[]
  /** EZ = verwalten: Löschen (R15). */
  canManage: boolean
  /** EZ ≥ lesen mit Reichweite alle (Admin, Vorstand mit „EZ lesen“): Kontrolle Kletterhalle lesen. */
  canReadAll: boolean
}

async function rpcBool(name: string, args: Record<string, unknown>): Promise<boolean> {
  const { data, error } = await supabase.rpc(name, args)
  return !error && data === true
}

async function myReferate(min: 'read' | 'edit'): Promise<string[]> {
  const { data, error } = await supabase.rpc('ad_my_referate', { p_module: 'EZ', p_min: min })
  return !error && Array.isArray(data) ? (data as string[]) : []
}

/** Ohne EZ ≥ lesen → /kein-zugriff, bevor Daten abgefragt werden (spec.md 3, Routenschutz). */
export async function loadEzAccess(): Promise<EzAccess> {
  await requireSession()
  if (!(await rpcBool('ad_has_any_level', { p_module: 'EZ', p_min: 'read' }))) throw redirect('/kein-zugriff')
  const [canEditAll, editReferate, canManage, canReadAll] = await Promise.all([
    rpcBool('ad_has_level', { p_module: 'EZ', p_min: 'edit' }),
    myReferate('edit'),
    rpcBool('ad_has_level', { p_module: 'EZ', p_min: 'manage' }),
    rpcBool('ad_has_level', { p_module: 'EZ', p_min: 'read' }),
  ])
  return { canEdit: canEditAll || editReferate.length > 0, canEditAll, editReferate, canManage, canReadAll }
}

/** Seiten nur mit bearbeiten (/ez/neu, /ez/:id/bearbeiten): sonst → /kein-zugriff. */
export async function requireEzEdit(): Promise<EzAccess> {
  const access = await loadEzAccess()
  if (!access.canEdit) throw redirect('/kein-zugriff')
  return access
}

/** Schreibrecht für ein Referat (nur Anzeige; die Datenbank prüft mit ez_can_write). */
export function canWriteReferat(access: EzAccess, referatId: string | null | undefined): boolean {
  return access.canEditAll || (!!referatId && access.editReferate.includes(referatId))
}

export function useEzAccess(): EzAccess {
  return (
    (useRouteLoaderData('ez') as EzAccess | undefined) ?? {
      canEdit: false,
      canEditAll: false,
      editReferate: [],
      canManage: false,
      canReadAll: false,
    }
  )
}
