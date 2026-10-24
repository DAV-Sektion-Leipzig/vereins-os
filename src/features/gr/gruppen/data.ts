// Gruppenübersicht (US-GR-02, T025) aus gr_group_overview; welche Gruppen sichtbar sind, entscheidet die RLS.
// Suche (Namensteil), Referat und „aufgelöst“ stehen in der URL.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadGrAccess } from '@/features/gr/access'
import { supabase } from '@/lib/supabase'

export type GroupOverviewRow = {
  id: string
  name: string
  referat_id: string
  referat_name: string
  dissolved_on: string | null
  training_times_today: string | null
  active_count: number
  clarify_count: number
  no_emergency_count: number
  pending_count: number
}

export type GroupFilter = { q: string; referat: string; dissolved: boolean }

export type Option = { id: string; name: string }

export type GroupOverviewResult = {
  filter: GroupFilter
  rows: GroupOverviewRow[]
  referate: Option[]
  failed: boolean
}

export function readGroupFilter(url: URL): GroupFilter {
  const p = url.searchParams
  return { q: (p.get('q') ?? '').trim(), referat: p.get('referat') ?? '', dissolved: p.get('aufgeloest') === '1' }
}

export function groupFilterHref(filter: GroupFilter): string {
  const p = new URLSearchParams()
  if (filter.q) p.set('q', filter.q)
  if (filter.referat) p.set('referat', filter.referat)
  if (filter.dissolved) p.set('aufgeloest', '1')
  const query = p.toString()
  return query ? `/gr?${query}` : '/gr'
}

/** Suche ohne Groß-/Kleinschreibung im Gruppennamen; Referat als Filter. */
export function applyGroupFilter(rows: GroupOverviewRow[], filter: GroupFilter): GroupOverviewRow[] {
  const q = filter.q.toLocaleLowerCase('de-DE')
  return rows.filter(
    (row) => (!q || row.name.toLocaleLowerCase('de-DE').includes(q)) && (!filter.referat || row.referat_id === filter.referat),
  )
}

export async function loadGroupOverview({ request }: LoaderFunctionArgs): Promise<GroupOverviewResult> {
  await loadGrAccess()
  const filter = readGroupFilter(new URL(request.url))
  const { data, error } = await supabase.rpc('gr_group_overview', { p_include_dissolved: filter.dissolved })
  if (error || !Array.isArray(data)) return { filter, rows: [], referate: [], failed: true }
  const rows = data as GroupOverviewRow[]
  // Referatsfilter nur mit Referaten, die in der Übersicht vorkommen
  const referate = [...new Map(rows.map((r) => [r.referat_id, { id: r.referat_id, name: r.referat_name }])).values()].sort((a, b) =>
    a.name.localeCompare(b.name, 'de-DE'),
  )
  return { filter, rows, referate, failed: false }
}
