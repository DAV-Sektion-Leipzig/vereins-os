// Einsatzliste (US-EZ-14, -15; T021) aus ez_list_events; welche Einsätze sichtbar sind, entscheidet die Datenbank.
// Filter (Zeitraum, Referat, Gruppe, Einsatzart) und Seite stehen in der URL.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { loadEzAccess } from '@/features/ez/access'
import { KINDS, type DayCategory, type EventKind, type Span } from '@/features/ez/labels'
import { todayIso } from '@/features/ez/dates'
import { supabase } from '@/lib/supabase'

export type EventRow = {
  id: string
  kind: EventKind
  span: Span
  referat_id: string
  referat_name: string
  group_id: string | null
  group_name: string | null
  title: string | null
  start_date: string
  start_time: string | null
  end_date: string | null
  end_time: string | null
  day_category: DayCategory | null
  location_name: string | null
  is_cancelled: boolean
  cancel_reason: string | null
  from_planning: boolean
  present_trainer: number
  present_helper: number
  present_participant: number
  registered_count: number
  absent_count: number
  trial_count: number
  remuneration_kind_id: string | null
  remuneration_kind_name: string | null
  is_settled: boolean
  total_count: number
}

export type Option = { id: string; name: string }

/** Zeitraum: Halbjahr „JJJJ-1“ bzw. „JJJJ-2“ oder frei mit von/bis. */
export type EventFilter = { period: string; from: string; to: string; referat: string; group: string; kind: EventKind | '' }

export type EventListResult = {
  filter: EventFilter
  page: number
  rows: EventRow[]
  total: number
  referate: Option[]
  groups: Option[]
  failed: boolean
}

/** Aktuelles Halbjahr als „JJJJ-1“ bzw. „JJJJ-2“ (Standard der Liste, spec.md 6). */
export function currentHalfYear(today = todayIso()): string {
  const [year, month] = today.split('-').map(Number)
  return `${year}-${month <= 6 ? 1 : 2}`
}

export function halfYearRange(period: string): { from: string; to: string } | null {
  const match = /^(\d{4})-([12])$/.exec(period)
  if (!match) return null
  const year = match[1]
  return match[2] === '1' ? { from: `${year}-01-01`, to: `${year}-06-30` } : { from: `${year}-07-01`, to: `${year}-12-31` }
}

/** Halbjahre zur Auswahl: aktuelles, zwei vorherige und das nächste. */
export function halfYearOptions(today = todayIso()): { value: string; label: string }[] {
  const [year, half] = currentHalfYear(today).split('-').map(Number)
  const options: { value: string; label: string }[] = []
  for (let i = 1; i >= -2; i--) {
    const index = year * 2 + (half - 1) + i
    const y = Math.floor(index / 2)
    const h = (index % 2) + 1
    options.push({ value: `${y}-${h}`, label: `${h}. Halbjahr ${y}` })
  }
  return options
}

export function readEventFilter(url: URL): EventFilter {
  const p = url.searchParams
  const kind = p.get('art') ?? ''
  return {
    period: p.get('zeitraum') ?? currentHalfYear(),
    from: p.get('von') ?? '',
    to: p.get('bis') ?? '',
    referat: p.get('referat') ?? '',
    group: p.get('gruppe') ?? '',
    kind: (KINDS as string[]).includes(kind) ? (kind as EventKind) : '',
  }
}

export function eventFilterHref(filter: EventFilter, page = 1): string {
  const p = new URLSearchParams()
  if (filter.period !== currentHalfYear()) p.set('zeitraum', filter.period)
  if (filter.period === 'frei') {
    if (filter.from) p.set('von', filter.from)
    if (filter.to) p.set('bis', filter.to)
  }
  if (filter.referat) p.set('referat', filter.referat)
  if (filter.group) p.set('gruppe', filter.group)
  if (filter.kind) p.set('art', filter.kind)
  if (page > 1) p.set('seite', String(page))
  const query = p.toString()
  return query ? `/ez?${query}` : '/ez'
}

/** Referate, deren Einsätze der Nutzer lesen darf (Filter „nur lesbare“, spec.md 6). */
async function loadReadableReferate(readAll: boolean): Promise<Option[]> {
  const { data, error } = await supabase.from('ea_referate').select('id, name').order('sort_order').order('name')
  if (error || !data) return []
  if (readAll) return data as Option[]
  const { data: mine } = await supabase.rpc('ad_my_referate', { p_module: 'EZ', p_min: 'read' })
  const ids = new Set(Array.isArray(mine) ? (mine as string[]) : [])
  return (data as Option[]).filter((r) => ids.has(r.id))
}

async function loadGroups(): Promise<Option[]> {
  const { data, error } = await supabase.rpc('gr_groups_for_attendance', { p_date: todayIso() })
  if (error || !Array.isArray(data)) return []
  return (data as { group_id: string; group_name: string }[]).map((g) => ({ id: g.group_id, name: g.group_name }))
}

export async function loadEventList({ request }: LoaderFunctionArgs): Promise<EventListResult> {
  const access = await loadEzAccess()
  const url = new URL(request.url)
  const filter = readEventFilter(url)
  const page = Math.max(1, Number(url.searchParams.get('seite')) || 1)
  const range = filter.period === 'frei' ? { from: filter.from, to: filter.to } : halfYearRange(filter.period)

  const [list, referate, groups] = await Promise.all([
    supabase.rpc('ez_list_events', {
      p_from: range?.from || null,
      p_to: range?.to || null,
      p_referat: filter.referat || null,
      p_group: filter.group || null,
      p_kind: filter.kind || null,
      p_limit: PAGE_SIZE,
      p_offset: (page - 1) * PAGE_SIZE,
    }),
    loadReadableReferate(access.canReadAll),
    loadGroups(),
  ])
  if (list.error || !Array.isArray(list.data)) return { filter, page, rows: [], total: 0, referate, groups, failed: true }
  const rows = list.data as EventRow[]
  return { filter, page, rows, total: rows[0]?.total_count ?? 0, referate, groups, failed: false }
}
