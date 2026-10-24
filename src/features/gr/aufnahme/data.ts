// Aufnahme-Assistent (US-GR-06–10, US-GR-12; T035) und offene Aufnahmen (T036).
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadGrAccess } from '@/features/gr/access'
import { loadGrPerson, UUID, type GrPerson } from '@/features/gr/personen/data'
import { supabase } from '@/lib/supabase'

export const STEPS = ['Person', 'Erziehungsberechtigte', 'Notfallkontakte', 'Einwilligungen', 'Teilnahme und Vertrag'] as const

export type AdmissionResult =
  | { state: 'not_found' | 'failed' }
  | { state: 'ok'; group: { id: string; name: string; dissolved_on: string | null }; person: GrPerson | null; step: number }

export async function loadAdmission({ params, request }: LoaderFunctionArgs): Promise<AdmissionResult> {
  await loadGrAccess()
  const groupId = params.id ?? ''
  if (!UUID.test(groupId)) return { state: 'not_found' }
  const url = new URL(request.url)
  const personId = url.searchParams.get('person')
  const requested = Number.parseInt(url.searchParams.get('schritt') ?? '', 10)

  const group = await supabase.from('gr_groups').select('id, name, dissolved_on').eq('id', groupId).maybeSingle()
  if (group.error) return { state: 'failed' }
  if (!group.data || group.data.dissolved_on) return { state: 'not_found' }
  if (!personId) return { state: 'ok', group: group.data, person: null, step: 1 }

  const person = await loadGrPerson(personId)
  if (person.state !== 'ok') return { state: person.state }
  const step = Number.isFinite(requested) && requested >= 2 && requested <= STEPS.length ? requested : 2
  return { state: 'ok', group: group.data, person: person.data, step }
}

export type PendingRow = {
  person_id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  group_id: string
  group_name: string
  created_at: string
  created_by_name: string | null
  needs_guardian: boolean | null
}

export type PendingResult = { rows: PendingRow[]; failed: boolean }

export async function loadPendingAdmissions(): Promise<PendingResult> {
  await loadGrAccess()
  const { data, error } = await supabase.from('gr_v_pending_admissions').select('*').order('created_at', { ascending: false })
  return error ? { rows: [], failed: true } : { rows: (data ?? []) as PendingRow[], failed: false }
}

export function continueHref(row: Pick<PendingRow, 'group_id' | 'person_id'>, step = 2): string {
  return `/gr/gruppen/${row.group_id}/aufnehmen?person=${row.person_id}&schritt=${step}`
}
