// Daten des Bereichs Budget aus den Lesefunktionen ds_budget_* (spec.md DS v0.2 Abschnitt 2.3); Jahr und Sicht in der
// Adresse. Alle Summen rechnet die Datenbank.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadDsAccess } from '@/features/ds/access'
import { dsRpc } from '@/features/ds/errors'
import { supabase } from '@/lib/supabase'

export type Kind = 'income' | 'expense'
export type Visibility = 'referat' | 'all' | 'none'
export type Ampel = 'ok' | 'warn' | 'over' | 'no_plan' | null

export type OverviewItem = {
  item_id: string
  group_id: string
  group_name: string
  visibility: Visibility
  referat_id: string | null
  referat_name: string | null
  kind: Kind
  name: string
  no_booking: boolean
  plan_decided: number | null
  plan_current: number
  actual: number
  actual_prev_same_day: number | null
  actual_prev_full: number | null
  prev_found: boolean
  pct: number | null
  ampel: Ampel
  note: string | null
  note_by: string | null
  note_at: string | null
  can_see_bookings: boolean
  can_edit: boolean
  open_reallocations: number
  open_proposals: number
  preview_runs: number | null
  preview_settlements: number | null
  status_uncertain: boolean
  is_mine: boolean
}

export type Head = {
  year: number
  has_plan: boolean
  expense_plan: number
  expense_actual: number
  expense_free: number
  income_plan: number
  income_actual: number
  income_missing: number
  data_until: string | null
  imported_at: string | null
  progress: number | null
  data_stale: boolean
}

export type TodoEntry = {
  type: string
  count?: number
  deadline?: string
  data_until?: string | null
  id?: string
  status?: string
  from_name?: string
  to_name?: string
  amount?: number
  decided_at?: string | null
  decision_reason?: string | null
}

export type Group = {
  id: string
  name: string
  visibility: Visibility
  referat_id: string | null
  referat_name: string | null
  items: OverviewItem[]
}

/** Sicht: Referat (id) oder „verein“. */
export type View = { kind: 'referat'; referatId: string } | { kind: 'verein' }

export type DashboardData = {
  years: number[]
  year: number
  view: View
  head: Head | null
  items: OverviewItem[]
  todo: TodoEntry[]
  failed: boolean
}

export function currentYear(): number {
  return Number(new Intl.DateTimeFormat('sv-SE', { timeZone: 'Europe/Berlin', year: 'numeric' }).format(new Date()))
}

/** Budgetposten nach Gesamtbudget, Reihenfolge wie in der Datenbank (Finanzplan). */
export function groupItems(items: OverviewItem[]): Group[] {
  const groups: Group[] = []
  const byId = new Map<string, Group>()
  for (const item of items) {
    let g = byId.get(item.group_id)
    if (!g) {
      g = {
        id: item.group_id,
        name: item.group_name,
        visibility: item.visibility,
        referat_id: item.referat_id,
        referat_name: item.referat_name,
        items: [],
      }
      byId.set(g.id, g)
      groups.push(g)
    }
    g.items.push(item)
  }
  return groups
}

export type Totals = {
  plan: number
  planDecided: number
  actual: number
  free: number
  prevSameDay: number | null
  preview: number
  pct: number | null
  ampel: Ampel
}

/** Summen eines Gesamtbudgets bzw. einer Sicht (nur Ausgaben, R6); Vorschau getrennt (R18). */
export function expenseTotals(items: OverviewItem[]): Totals {
  const ex = items.filter((i) => i.kind === 'expense')
  const plan = ex.reduce((s, i) => s + Number(i.plan_current), 0)
  const actual = ex.reduce((s, i) => s + Number(i.actual), 0)
  const withPrev = ex.filter((i) => i.actual_prev_same_day !== null)
  const pct = plan > 0 ? Math.round((actual / plan) * 1000) / 10 : null
  return {
    plan,
    planDecided: ex.reduce((s, i) => s + Number(i.plan_decided ?? 0), 0),
    actual,
    free: plan - actual,
    prevSameDay: withPrev.length > 0 ? withPrev.reduce((s, i) => s + Number(i.actual_prev_same_day), 0) : null,
    preview: ex.reduce((s, i) => s + Number(i.preview_runs ?? 0) + Number(i.preview_settlements ?? 0), 0),
    pct,
    ampel: ampelFor(plan, actual),
  }
}

export function ampelFor(plan: number, actual: number): Ampel {
  if (plan <= 0) return actual > 0 ? 'no_plan' : null
  const ratio = actual / plan
  return ratio < 0.8 ? 'ok' : ratio <= 1 ? 'warn' : 'over'
}

export function previewOf(item: OverviewItem): number {
  return Number(item.preview_runs ?? 0) + Number(item.preview_settlements ?? 0)
}

function parseView(value: string | null, referatIds: string[], scopeAll: boolean): View {
  if (value === 'verein') return { kind: 'verein' }
  if (value && (scopeAll || referatIds.includes(value))) return { kind: 'referat', referatId: value }
  if (referatIds.length > 0) return { kind: 'referat', referatId: referatIds[0] }
  return { kind: 'verein' }
}

export function dashboardHref(year: number, view: View, path = '/dashboard'): string {
  const p = new URLSearchParams()
  if (year !== currentYear()) p.set('jahr', String(year))
  p.set('sicht', view.kind === 'verein' ? 'verein' : view.referatId)
  return `${path}?${p.toString()}`
}

export async function loadYears(): Promise<number[]> {
  const res = await dsRpc<number[]>('ds_budget_years')
  return (res.data ?? []).map(Number)
}

export async function loadOverview(year: number) {
  const [head, items] = await Promise.all([
    dsRpc<Head>('ds_budget_head', { p_year: year }),
    dsRpc<OverviewItem[]>('ds_budget_overview', { p_year: year }),
  ])
  return { head: head.data, items: items.data ?? [], failed: Boolean(head.error || items.error) }
}

export async function loadDashboard({ request }: LoaderFunctionArgs): Promise<DashboardData> {
  const access = await loadDsAccess()
  const url = new URL(request.url)
  const years = await loadYears()
  const wanted = Number(url.searchParams.get('jahr'))
  const year = years.includes(wanted) ? wanted : (years.find((y) => y <= currentYear()) ?? years[0] ?? currentYear())
  const view = parseView(url.searchParams.get('sicht'), access.myReferate.map((r) => r.id), access.scopeAll)
  const [overview, todo] = await Promise.all([loadOverview(year), dsRpc<TodoEntry[]>('ds_todo')])
  return { years, year, view, ...overview, todo: todo.data ?? [], failed: overview.failed || Boolean(todo.error) }
}

// ---------------------------------------------------------------------------------------------------------------
// Budgetposten (Detail)

export type Booking = {
  booking_id: string
  booking_date: string
  account: string
  contra_label: string | null
  booking_text: string | null
  receipt: string | null
  cost_center: string | null
  amount: number
  rekeyed: boolean
  rekey_info: string | null
  rule_id: string
  proposal_open: boolean
}

export type AccountSum = { account: string; account_label: string | null; debit: number; credit: number; amount: number; bookings: number }

export type Request = {
  request_type: 'reallocation' | 'proposal'
  id: string
  status: string
  from_item: string | null
  from_name: string | null
  to_item: string
  to_name: string
  amount: number
  booking_date: string | null
  booking_text: string | null
  reason: string
  requested_by: string | null
  requested_at: string
  decided_by: string | null
  decided_at: string | null
  decision_reason: string | null
  is_mine: boolean
  can_decide: boolean
}

export type NoteEntry = { id: string; text: string; created_at: string; valid_to: string | null }

export type ItemData = {
  item: OverviewItem | null
  year: number
  head: Head | null
  siblings: OverviewItem[]
  all: OverviewItem[]
  bookings: Booking[] | null
  accounts: AccountSum[]
  notes: NoteEntry[]
  requests: Request[]
  failed: boolean
}

export async function loadItem({ params }: LoaderFunctionArgs): Promise<ItemData> {
  await loadDsAccess()
  const id = params.id ?? ''
  const { data: row } = await supabase.from('fi_budget_items').select('year').eq('id', id).maybeSingle()
  const year = row ? Number((row as { year: number }).year) : currentYear()
  const overview = await loadOverview(year)
  const item = overview.items.find((i) => i.item_id === id) ?? null
  if (!item) {
    return { item: null, year, head: overview.head, siblings: [], all: [], bookings: null, accounts: [], notes: [], requests: [], failed: overview.failed }
  }
  const [bookings, accounts, notes, requests] = await Promise.all([
    item.can_see_bookings ? dsRpc<Booking[]>('ds_budget_bookings', { p_item: id }) : Promise.resolve(null),
    item.can_see_bookings ? dsRpc<AccountSum[]>('ds_budget_account_sums', { p_item: id }) : Promise.resolve(null),
    supabase.from('fi_budget_notes').select('id, text, created_at, valid_to').eq('item_id', id).order('created_at', { ascending: false }),
    dsRpc<Request[]>('ds_budget_requests', { p_year: year }),
  ])
  return {
    item,
    year,
    head: overview.head,
    siblings: overview.items.filter((i) => i.group_id === item.group_id),
    all: overview.items,
    bookings: bookings?.data ?? null,
    accounts: accounts?.data ?? [],
    notes: (notes.data ?? []) as NoteEntry[],
    requests: (requests.data ?? []).filter((r) => r.from_item === id || r.to_item === id),
    failed: overview.failed || Boolean(bookings?.error || accounts?.error || requests.error),
  }
}

// ---------------------------------------------------------------------------------------------------------------
// Sicht Verein

export type Unassigned = {
  booking_id: string
  booking_date: string
  account: string
  contra_label: string | null
  booking_text: string | null
  receipt: string | null
  cost_center: string | null
  amount: number
  rule_id: string
  rule_status: string
}

export type Checks = {
  import: {
    id: string
    file_name: string
    export_info: string | null
    data_until: string | null
    imported_at: string
    rows_read: number
    rows_saved: number
    rows_ignored: number
    rows_opening: number
    rows_other_year: number
    checks: { konto: string; ok: boolean | null; overview_debit: number | null; overview_credit: number | null; rows_debit: number; rows_credit: number }[]
    warnings: { type: string; konto?: string; overview?: number; rows?: number; date?: string; amount?: number; side?: string }[]
  } | null
  rekeyed: { rule_id: string; account: string; date: string | null; amount: number | null; side: string | null; item: string | null; reason: string | null; found: boolean }[]
  uncertain: { rule_id: string; account: string; status: string; item: string | null; note: string | null }[]
}

export type VereinData = {
  years: number[]
  year: number
  head: Head | null
  items: OverviewItem[]
  unassigned: Unassigned[] | null
  checks: Checks | null
  failed: boolean
}

export async function loadVerein({ request }: LoaderFunctionArgs): Promise<VereinData> {
  const access = await loadDsAccess()
  const url = new URL(request.url)
  const years = await loadYears()
  const wanted = Number(url.searchParams.get('jahr'))
  const year = years.includes(wanted) ? wanted : (years.find((y) => y <= currentYear()) ?? years[0] ?? currentYear())
  const [overview, unassigned, checks] = await Promise.all([
    loadOverview(year),
    access.scopeAll ? dsRpc<Unassigned[]>('ds_budget_unassigned', { p_year: year }) : Promise.resolve(null),
    access.scopeAll ? dsRpc<Checks>('ds_budget_checks', { p_year: year }) : Promise.resolve(null),
  ])
  return {
    years,
    year,
    ...overview,
    unassigned: unassigned?.data ?? null,
    checks: checks?.data ?? null,
    failed: overview.failed || Boolean(unassigned?.error || checks?.error),
  }
}
