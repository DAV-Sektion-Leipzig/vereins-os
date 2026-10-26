// Zugriff auf das Dashboard (spec.md DS v0.2 Abschnitt 3): „DS lesen“ in irgendeiner Reichweite ist Voraussetzung;
// Budgetpflege nur mit dem Kennzeichen „darf Budget pflegen“. Die Datenbank prüft beim Lesen und Schreiben erneut.
import { redirect, useRouteLoaderData } from 'react-router-dom'
import { requireSession } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type Referat = { id: string; name: string }

export type DsAccess = {
  /** DS lesen mit Reichweite „alle“ oder Budgetpflege: alle Einzelbuchungen, nicht zugeordnete Buchungen, Prüfung. */
  scopeAll: boolean
  /** Kennzeichen „darf Budget pflegen“. */
  maintain: boolean
  /** Referate aus Reichweite „Referat“ (Sicht „Mein Referat“). */
  myReferate: Referat[]
  /** Alle aktiven Referate (Namen für Sichtwahl und Gesamtbudgets). */
  referate: Referat[]
}

async function rpcBool(name: string, args: Record<string, unknown> = {}): Promise<boolean> {
  const { data, error } = await supabase.rpc(name, args)
  return !error && data === true
}

/** Ohne DS ≥ lesen → /kein-zugriff, bevor Daten abgefragt werden. */
export async function loadDsAccess(): Promise<DsAccess> {
  await requireSession()
  if (!(await rpcBool('ad_has_any_level', { p_module: 'DS', p_min: 'read' }))) throw redirect('/kein-zugriff')
  const [scopeAll, maintain, mine, referate] = await Promise.all([
    rpcBool('ad_has_level', { p_module: 'DS', p_min: 'read' }),
    rpcBool('ad_has_budget_maintain'),
    supabase.rpc('ad_my_referate', { p_module: 'DS', p_min: 'read' }),
    supabase.from('ea_referate').select('id, name').eq('is_active', true).order('sort_order'),
  ])
  const all = (referate.data ?? []) as Referat[]
  const ids = !mine.error && Array.isArray(mine.data) ? (mine.data as string[]) : []
  return {
    scopeAll: scopeAll || maintain,
    maintain,
    myReferate: all.filter((r) => ids.includes(r.id)),
    referate: all,
  }
}

/** /dashboard/budget/pflege nur mit Budgetpflege. */
export async function requireBudgetMaintain(): Promise<DsAccess> {
  const access = await loadDsAccess()
  if (!access.maintain) throw redirect('/kein-zugriff')
  return access
}

export function useDsAccess(): DsAccess {
  return (
    (useRouteLoaderData('ds') as DsAccess | undefined) ?? { scopeAll: false, maintain: false, myReferate: [], referate: [] }
  )
}
