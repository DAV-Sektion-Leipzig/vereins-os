// Budgetpflege (US-FI-22 bis -27, -29, US-DS-13, -15): Daten eines Jahres für alle Reiter. Lesen über RLS
// (fi_budget_scope_all) bzw. ds_-Funktionen; Schreiben nur über die Funktionen der Datenbank.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { requireBudgetMaintain } from '@/features/ds/access'
import { currentYear, type Kind, type Request, type Visibility } from '@/features/ds/budget/data'
import { dsRpc } from '@/features/ds/errors'
import { supabase } from '@/lib/supabase'

export const TABS = [
  { key: 'finanzplan', label: 'Finanzplan' },
  { key: 'gesamtbudgets', label: 'Gesamtbudgets' },
  { key: 'zuordnung', label: 'Zuordnung' },
  { key: 'import', label: 'Import' },
  { key: 'antraege', label: 'Anträge' },
  { key: 'protokoll', label: 'Protokoll' },
] as const

export type TabKey = (typeof TABS)[number]['key']

export type PlanRow = { year: number; source_file: string; sheet: string; sum_income: number | null; sum_expense: number | null; imported_at: string }
export type GroupRow = { id: string; name: string; visibility: Visibility; referat_id: string | null; sort_order: number }
export type ItemRow = { id: string; group_id: string; kind: Kind; name: string; plan_decided: number | null; sort_order: number; no_booking: boolean }

export type RuleRow = {
  id: string
  rule_type: 'booking' | 'account' | 'main_account' | 'range'
  account_text: string
  cost_centers: string[]
  item_id: string | null
  status: 'ok' | 'uncertain' | 'open' | 'no_booking'
  note: string | null
  account_label: string | null
  b_date: string | null
  b_receipt: string | null
  b_amount: number | null
  b_side: string | null
  b_text: string | null
  reason: string | null
  comment: string | null
  valid_from: string
  valid_to: string | null
}

export type ImportRow = {
  id: string
  file_name: string
  data_until: string | null
  rows_read: number
  rows_saved: number
  is_current: boolean
  imported_at: string
  warnings: unknown[]
}

export type PayoutRun = { run_id: string; year: number; half: number; number: number; execution_date: string; total: number; booked: boolean; marked: boolean }

export type LogRow = { id: string; year: number | null; action: string; details: Record<string, unknown>; at: string }

export type PflegeData = {
  tab: TabKey
  year: number
  years: number[]
  plan: PlanRow | null
  groups: GroupRow[]
  items: ItemRow[]
  rules: RuleRow[]
  imports: ImportRow[]
  runs: PayoutRun[]
  requests: Request[]
  log: LogRow[]
  failed: boolean
}

export function pflegeHref(tab: TabKey, year: number): string {
  const p = new URLSearchParams()
  p.set('reiter', tab)
  if (year !== currentYear()) p.set('jahr', String(year))
  return `/dashboard/budget/pflege?${p.toString()}`
}

export async function loadPflege({ request }: LoaderFunctionArgs): Promise<PflegeData> {
  await requireBudgetMaintain()
  const url = new URL(request.url)
  const tabParam = url.searchParams.get('reiter')
  const tab = (TABS.find((t) => t.key === tabParam)?.key ?? 'finanzplan') as TabKey
  const now = currentYear()
  const wanted = Number(url.searchParams.get('jahr'))
  const year = wanted >= 2026 && wanted <= now + 1 ? wanted : now

  const [plans, plan, groups, items, rules, imports, runs, requests, log] = await Promise.all([
    supabase.from('fi_budget_plans').select('year').order('year', { ascending: false }),
    supabase.from('fi_budget_plans').select('year, source_file, sheet, sum_income, sum_expense, imported_at').eq('year', year).maybeSingle(),
    supabase.from('fi_budget_groups').select('id, name, visibility, referat_id, sort_order').eq('year', year).order('sort_order'),
    supabase
      .from('fi_budget_items')
      .select('id, group_id, kind, name, plan_decided, sort_order, no_booking')
      .eq('year', year)
      .is('removed_at', null)
      .order('sort_order'),
    supabase
      .from('fi_budget_rules')
      .select('id, rule_type, account_text, cost_centers, item_id, status, note, account_label, b_date, b_receipt, b_amount, b_side, b_text, reason, comment, valid_from, valid_to')
      .eq('year', year)
      .order('valid_from', { ascending: false }),
    supabase
      .from('fi_budget_imports')
      .select('id, file_name, data_until, rows_read, rows_saved, is_current, imported_at, warnings')
      .eq('year', year)
      .order('imported_at', { ascending: false }),
    dsRpc<PayoutRun[]>('ds_budget_payout_runs', { p_year: year }),
    dsRpc<Request[]>('ds_budget_requests', { p_year: year }),
    supabase.from('fi_budget_log').select('id, year, action, details, at').order('at', { ascending: false }).limit(200),
  ])
  const years = [...new Set([now + 1, now, ...((plans.data ?? []) as { year: number }[]).map((p) => Number(p.year))])]
    .filter((y) => y >= 2026)
    .sort((a, b) => b - a)
  return {
    tab,
    year,
    years,
    plan: (plan.data as PlanRow | null) ?? null,
    groups: (groups.data ?? []) as GroupRow[],
    items: (items.data ?? []) as ItemRow[],
    rules: (rules.data ?? []) as RuleRow[],
    imports: (imports.data ?? []) as ImportRow[],
    runs: runs.data ?? [],
    requests: requests.data ?? [],
    log: (log.data ?? []) as LogRow[],
    failed: Boolean(plans.error || groups.error || items.error || rules.error || imports.error || runs.error || requests.error || log.error),
  }
}
