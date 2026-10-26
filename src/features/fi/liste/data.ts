// Abrechnungen eines Halbjahres (US-FI-06, FT11) aus fi_list_settlements; Filter in der Adresse.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { loadFiAccess } from '@/features/fi/access'
import { currentHalf, halfKey, parseHalf, STATUSES, type Half, type SettlementStatus } from '@/features/fi/labels'
import { supabase } from '@/lib/supabase'

export type SettlementRow = {
  id: string
  person_id: string
  display_name: string
  groups: string[]
  amount: number
  status: SettlementStatus
  hints: string[]
  referate: { referat_id: string; name: string; confirmed: boolean }[] | null
  payable: boolean
  has_new_events: boolean
  total_count: number
}

export type ListFilter = {
  half: Half
  status: SettlementStatus | ''
  group: string
  withHint: boolean
  toConfirm: boolean
  deadlinePassed: boolean
  page: number
}

export type GroupOption = { id: string; name: string }

export type ListResult = { filter: ListFilter; rows: SettlementRow[]; total: number; groups: GroupOption[]; failed: boolean }

export function listHref(filter: ListFilter): string {
  const p = new URLSearchParams()
  p.set('hj', halfKey(filter.half))
  if (filter.status) p.set('zustand', filter.status)
  if (filter.group) p.set('gruppe', filter.group)
  if (filter.withHint) p.set('hinweis', '1')
  if (filter.toConfirm) p.set('bestaetigen', '1')
  if (filter.deadlinePassed) p.set('frist', '1')
  if (filter.page > 1) p.set('seite', String(filter.page))
  return `/fi?${p.toString()}`
}

/**
 * Gruppen mit Positionen im Halbjahr für den Filter: Positionen sind lesbar (RLS), die Namen nur mit
 * Leserecht auf Gruppen (GR lesen bzw. EA lesen); Gruppen ohne lesbaren Namen fehlen in der Auswahl.
 */
async function loadGroups(half: Half): Promise<GroupOption[]> {
  const { data } = await supabase
    .from('fi_settlement_items')
    .select('group_id, fi_settlements!inner(year, half)')
    .eq('fi_settlements.year', half.year)
    .eq('fi_settlements.half', half.half)
    .not('group_id', 'is', null)
  const ids = [...new Set(((data ?? []) as { group_id: string }[]).map((r) => r.group_id))]
  if (ids.length === 0) return []
  const groups = await supabase.from('gr_groups').select('id, name').in('id', ids)
  return ((groups.data ?? []) as GroupOption[]).sort((a, b) => a.name.localeCompare(b.name, 'de-DE', { numeric: true }))
}

export async function loadSettlementList({ request }: LoaderFunctionArgs): Promise<ListResult> {
  await loadFiAccess()
  const p = new URL(request.url).searchParams
  const status = p.get('zustand') as SettlementStatus | null
  const filter: ListFilter = {
    half: parseHalf(p.get('hj')) ?? currentHalf(),
    status: status && STATUSES.includes(status) ? status : '',
    group: p.get('gruppe') ?? '',
    withHint: p.get('hinweis') === '1',
    toConfirm: p.get('bestaetigen') === '1',
    deadlinePassed: p.get('frist') === '1',
    page: Math.max(1, Number(p.get('seite')) || 1),
  }
  const [list, groups] = await Promise.all([
    supabase.rpc('fi_list_settlements', {
      p_year: filter.half.year,
      p_half: filter.half.half,
      p_status: filter.status || null,
      p_group: filter.group || null,
      p_with_hint: filter.withHint ? true : null,
      p_to_confirm: filter.toConfirm || null,
      p_deadline_passed: filter.deadlinePassed || null,
      p_limit: PAGE_SIZE,
      p_offset: (filter.page - 1) * PAGE_SIZE,
    }),
    loadGroups(filter.half),
  ])
  if (list.error || !Array.isArray(list.data)) return { filter, rows: [], total: 0, groups, failed: true }
  const rows = list.data as SettlementRow[]
  return { filter, rows, total: rows[0]?.total_count ?? 0, groups, failed: false }
}
