// Gruppendetail (US-GR-05, US-GR-13, US-GR-18; T032): Kopf, Teilnahmen (gr_v_memberships), Betreuung
// (Eigenschaften group_function), Trainingszeiten. Sichtbarkeit nach RLS (spec.md 3).
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadGrAccess } from '@/features/gr/access'
import { formatClock, todayIso, weekdayShort } from '@/lib/format'
import { supabase } from '@/lib/supabase'

export type GroupDetail = {
  id: string
  name: string
  referat_id: string
  referat_name: string
  dissolved_on: string | null
}

export type TrainingTime = {
  id: string
  weekday: number
  starts_at: string
  ends_at: string
  valid_from: string
  valid_to: string | null
}

export type MembershipRow = {
  membership_id: string
  group_id: string
  person_id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  joined_on: string
  left_on: string | null
  birth_date: string | null
  contract_id: string | null
  contract_status: ContractStatus | null
  contract_ends_on: string | null
  photo_consent: boolean
  needs_clarification: boolean
  clarify_since: string | null
  has_emergency_contact: boolean
  needs_guardian: boolean | null
}

export type ContractStatus = 'active' | 'cancelled' | 'ended'

export type GroupFunction = 'Gruppenleitung' | 'Trainer:in' | 'Helfer:in'

export const GROUP_FUNCTIONS: GroupFunction[] = ['Gruppenleitung', 'Trainer:in', 'Helfer:in']

export type FunctionRow = {
  id: string
  person_id: string
  function: GroupFunction
  valid_from: string
  valid_to: string | null
  first_name: string
  preferred_name: string | null
  last_name: string
}

export type GroupDetailResult =
  | { state: 'not_found' | 'failed' }
  | {
      state: 'ok'
      group: GroupDetail
      trainingTimes: TrainingTime[]
      memberships: MembershipRow[]
      functions: FunctionRow[]
    }

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

/** Gilt am Tag: Beginn ≤ Tag und (Ende leer oder Ende ≥ Tag) (spec.md 2, Datumskonvention). */
export function validOn(from: string, to: string | null, day: string = todayIso()): boolean {
  return from <= day && (!to || to >= day)
}

/** Laufend: noch nicht beendet (auch künftige). */
export function isRunning(to: string | null, day: string = todayIso()): boolean {
  return !to || to >= day
}

type FunctionQueryRow = {
  id: string
  person_id: string
  field_values: { function?: GroupFunction }
  valid_from: string
  valid_to: string | null
  person: { first_name: string; preferred_name: string | null; last_name: string } | null
}

export async function loadGroupDetail({ params }: LoaderFunctionArgs): Promise<GroupDetailResult> {
  await loadGrAccess()
  const id = params.id ?? ''
  if (!UUID.test(id)) return { state: 'not_found' }

  const [group, times, memberships, functions] = await Promise.all([
    supabase.from('gr_groups').select('id, name, referat_id, dissolved_on, referat:ea_referate(name)').eq('id', id).maybeSingle(),
    supabase
      .from('gr_training_times')
      .select('id, weekday, starts_at, ends_at, valid_from, valid_to')
      .eq('group_id', id)
      .order('weekday')
      .order('starts_at')
      .order('valid_from'),
    supabase.from('gr_v_memberships').select('*').eq('group_id', id),
    supabase
      .from('ea_properties')
      .select(
        'id, person_id, field_values, valid_from, valid_to, person:ea_persons(first_name, preferred_name, last_name), type:ea_property_types!inner(system_key)',
      )
      .eq('related_group_id', id)
      .eq('type.system_key', 'group_function')
      .order('valid_from'),
  ])

  if (group.error || times.error || memberships.error || functions.error) return { state: 'failed' }
  if (!group.data) return { state: 'not_found' }

  const g = group.data as unknown as GroupDetail & { referat: { name: string } | null }
  return {
    state: 'ok',
    group: { id: g.id, name: g.name, referat_id: g.referat_id, referat_name: g.referat?.name ?? '', dissolved_on: g.dissolved_on },
    trainingTimes: (times.data ?? []) as TrainingTime[],
    memberships: ((memberships.data ?? []) as MembershipRow[]).sort(
      (a, b) =>
        a.last_name.localeCompare(b.last_name, 'de-DE') ||
        (a.preferred_name ?? a.first_name).localeCompare(b.preferred_name ?? b.first_name, 'de-DE'),
    ),
    functions: ((functions.data ?? []) as unknown as FunctionQueryRow[])
      .filter((f) => f.person && f.field_values.function)
      .map((f) => ({
        id: f.id,
        person_id: f.person_id,
        function: f.field_values.function as GroupFunction,
        valid_from: f.valid_from,
        valid_to: f.valid_to,
        first_name: f.person!.first_name,
        preferred_name: f.person!.preferred_name,
        last_name: f.person!.last_name,
      })),
  }
}

/** E-Mail-Adressen der Erziehungsberechtigten (R13); null bei Fehler. */
export async function loadGuardianEmails(groupId: string): Promise<string[] | null> {
  const { data, error } = await supabase.rpc('gr_guardian_emails', { p_group: groupId })
  return error || !Array.isArray(data) ? null : (data as string[])
}

export const CONTRACT_STATUS_LABELS: Record<ContractStatus, string> = {
  active: 'aktiv',
  cancelled: 'gekündigt',
  ended: 'beendet',
}

/** „Di 16:30–18:00“ */
export function timeLabel(t: Pick<TrainingTime, 'weekday' | 'starts_at' | 'ends_at'>): string {
  return `${weekdayShort(t.weekday)} ${formatClock(t.starts_at)}–${formatClock(t.ends_at)}`
}
