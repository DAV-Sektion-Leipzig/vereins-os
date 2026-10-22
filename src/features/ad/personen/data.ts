// Personenübersicht (US-AD-06, US-AD-15, US-AD-24; T071, T072) aus ad_v_person_overview.
// Welche Personen sichtbar sind, entscheidet die RLS (R32); das Frontend filtert nur innerhalb davon.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { requireLevel, type AccessStatus } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type VolunteerStatus = 'active' | 'dormant' | 'left'
export type PersonKind = 'human' | 'function'

export type PersonRow = {
  person_id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  kind: PersonKind
  created_in: string
  volunteer_status: VolunteerStatus | null
  volunteer_status_since: string | null
  login_email: string | null
  access_status: AccessStatus
  has_group_relation: boolean
  templates: string[]
}

export const VOLUNTEER_STATUS_LABELS: Record<VolunteerStatus, string> = {
  active: 'aktiv',
  dormant: 'ruhend',
  left: 'ausgeschieden',
}

/** Filter „Zugehörigkeit“ (spec.md AD Abschnitt 6 [ANNAHME v0.7], research.md R-28). */
export const MEMBERSHIP_FILTERS = {
  zugang: 'mit Zugang',
  funktionsperson: 'Funktionsperson',
  ehrenamt: 'Ehrenamtsmanagement',
  gruppen: 'nur Gruppen',
  ohne: 'ohne Zugehörigkeit',
} as const

export type MembershipFilter = keyof typeof MEMBERSHIP_FILTERS

export type PersonFilter = {
  q: string
  status: AccessStatus | ''
  membership: MembershipFilter | ''
  page: number
}

export type EmergencyNotice = { count: number; last_at: string | null }

export type OverviewResult = {
  filter: PersonFilter
  rows: PersonRow[]
  total: number
  failed: boolean
  emergency: EmergencyNotice | null
}

export function readFilter(url: URL): PersonFilter {
  const p = url.searchParams
  const status = p.get('status') ?? ''
  const membership = p.get('zugehoerigkeit') ?? ''
  const page = Number.parseInt(p.get('seite') ?? '1', 10)
  return {
    q: (p.get('q') ?? '').trim(),
    status: (['none', 'invited', 'active', 'locked'] as string[]).includes(status) ? (status as AccessStatus) : '',
    membership: membership in MEMBERSHIP_FILTERS ? (membership as MembershipFilter) : '',
    page: Number.isFinite(page) && page > 0 ? page : 1,
  }
}

export function filterHref(filter: PersonFilter, page = filter.page): string {
  const p = new URLSearchParams()
  if (filter.q) p.set('q', filter.q)
  if (filter.status) p.set('status', filter.status)
  if (filter.membership) p.set('zugehoerigkeit', filter.membership)
  if (page > 1) p.set('seite', String(page))
  const s = p.toString()
  return s ? `/ad?${s}` : '/ad'
}

// PostgREST-Filterwerte: Anführungszeichen schützen Kommas und Klammern; eigene Anführungszeichen entfallen
function quote(value: string) {
  return `"${value.replace(/["\\]/g, '')}"`
}

export async function loadPersonOverview({ request }: LoaderFunctionArgs): Promise<OverviewResult> {
  await requireLevel('AD', 'read')
  const filter = readFilter(new URL(request.url))
  const from = (filter.page - 1) * PAGE_SIZE

  let query = supabase
    .from('ad_v_person_overview')
    .select('*', { count: 'exact' })
    .order('last_name')
    .order('first_name')
    .range(from, from + PAGE_SIZE - 1)

  if (filter.q) {
    const like = quote(`%${filter.q}%`)
    query = query.or(`first_name.ilike.${like},preferred_name.ilike.${like},last_name.ilike.${like}`)
  }
  if (filter.status) query = query.eq('access_status', filter.status)
  switch (filter.membership) {
    case 'zugang':
      query = query.neq('access_status', 'none')
      break
    case 'funktionsperson':
      query = query.eq('kind', 'function')
      break
    case 'ehrenamt':
      query = query.not('volunteer_status', 'is', null)
      break
    case 'gruppen':
      query = query.eq('has_group_relation', true).is('volunteer_status', null).eq('access_status', 'none')
      break
    case 'ohne':
      query = query
        .eq('kind', 'human')
        .eq('has_group_relation', false)
        .is('volunteer_status', null)
        .eq('access_status', 'none')
      break
  }

  const [result, emergency] = await Promise.all([query, supabase.rpc('ad_pending_emergency_logins')])

  if (result.error) return { filter, rows: [], total: 0, failed: true, emergency: null }

  const notice = !emergency.error && Array.isArray(emergency.data) && emergency.data.length > 0
    ? (emergency.data[0] as EmergencyNotice)
    : null

  return {
    filter,
    rows: (result.data ?? []) as PersonRow[],
    total: result.count ?? 0,
    failed: false,
    emergency: notice && notice.count > 0 ? notice : null,
  }
}

export async function acknowledgeEmergency() {
  const { error } = await supabase.rpc('ad_acknowledge_emergency')
  return error ?? null
}
