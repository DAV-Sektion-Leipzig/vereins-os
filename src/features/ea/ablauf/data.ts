// Stichtagsliste (US-EA-12; T047): Lizenzen und Qualifikationen, deren „gültig bis“ im gewählten Jahr liegt (R11).
// Sichtbarkeit über die RLS von ea_v_expiry (security invoker); Referate aus ea_volunteer_list (research.md R-EA-06).
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadEaAccess } from '@/features/ea/access'
import type { ExpiryStatus } from '@/features/ea/shared/AblaufBadge'
import { supabase } from '@/lib/supabase'

export type ExpiryListRow = {
  propertyId: string
  personId: string
  firstName: string
  preferredName: string | null
  lastName: string
  referate: string[]
  code: string | null
  qualificationName: string
  validUntil: string
  status: ExpiryStatus
}

export type ExpiryListResult = {
  year: number
  years: number[]
  rows: ExpiryListRow[]
  canExport: boolean
  failed: boolean
}

type ViewRow = {
  property_id: string
  person_id: string
  qualification_code: string | null
  qualification_name: string | null
  valid_until: string
  expiry_status: ExpiryStatus
}

type ListRow = { id: string; first_name: string; preferred_name: string | null; last_name: string; referate: string[]; total_count: number }

const LIST_PAGE = 200

/** Aktuelles Jahr bis +3; Standard Folgejahr (spec.md EA Abschnitt 6). */
export function selectableYears(now = new Date()): number[] {
  const y = now.getFullYear()
  return [y, y + 1, y + 2, y + 3]
}

/** Personen mit Referaten seitenweise zu je 200 (ea_volunteer_list begrenzt auf 200). */
async function loadPersons(): Promise<Map<string, ListRow> | null> {
  const persons = new Map<string, ListRow>()
  for (let offset = 0; ; offset += LIST_PAGE) {
    const { data, error } = await supabase.rpc('ea_volunteer_list', { p_limit: LIST_PAGE, p_offset: offset })
    if (error || !Array.isArray(data)) return null
    const rows = data as ListRow[]
    rows.forEach((r) => persons.set(r.id, r))
    if (rows.length < LIST_PAGE || persons.size >= (rows[0]?.total_count ?? 0)) return persons
  }
}

export async function loadExpiryList({ request }: LoaderFunctionArgs): Promise<ExpiryListResult> {
  // Rechte vor jeder Datenabfrage (US-EA-01 AK4)
  const access = await loadEaAccess()
  const years = selectableYears()
  const requested = Number.parseInt(new URL(request.url).searchParams.get('jahr') ?? '', 10)
  const year = years.includes(requested) ? requested : years[1]

  const [expiry, persons] = await Promise.all([
    supabase
      .from('ea_v_expiry')
      .select('property_id, person_id, qualification_code, qualification_name, valid_until, expiry_status')
      .in('kind', ['license', 'qualification'])
      .gte('valid_until', `${year}-01-01`)
      .lte('valid_until', `${year}-12-31`),
    loadPersons(),
  ])
  if (expiry.error || !persons) return { year, years, rows: [], canExport: access.canManage, failed: true }

  const rows = (expiry.data as ViewRow[])
    .flatMap((e) => {
      const p = persons.get(e.person_id)
      if (!p) return []
      return [
        {
          propertyId: e.property_id,
          personId: e.person_id,
          firstName: p.first_name,
          preferredName: p.preferred_name,
          lastName: p.last_name,
          referate: p.referate,
          code: e.qualification_code,
          qualificationName: e.qualification_name ?? '',
          validUntil: e.valid_until,
          status: e.expiry_status,
        },
      ]
    })
    // sortiert nach gültig bis, dann Name (US-EA-12 AK1)
    .sort(
      (a, b) =>
        a.validUntil.localeCompare(b.validUntil) ||
        a.lastName.localeCompare(b.lastName, 'de') ||
        (a.preferredName ?? a.firstName).localeCompare(b.preferredName ?? b.firstName, 'de'),
    )

  return { year, years, rows, canExport: access.canManage, failed: false }
}
