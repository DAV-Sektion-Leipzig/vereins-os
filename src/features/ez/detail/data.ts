// Einsatz mit Anwesenheit (US-EZ-10, -12, -13, -15, -22, -23; T029, T031) aus ez_get_event; Namen über ea_person_names.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadEzAccess } from '@/features/ez/access'
import { ezError } from '@/features/ez/errors'
import type { AttendanceStatus, DayCategory, EventKind, Role, Span } from '@/features/ez/labels'
import { loadPersonNames, type PersonNames } from '@/features/ez/shared/rpc'
import { supabase } from '@/lib/supabase'

export type EzEvent = {
  id: string
  kind: EventKind
  span: Span
  referat_id: string
  group_id: string | null
  title: string | null
  organizer_person_id: string | null
  start_date: string
  start_time: string | null
  end_date: string | null
  end_time: string | null
  day_category: DayCategory | null
  location_id: string | null
  remark: string | null
  tk_plan_id: string | null
  cancelled_at: string | null
  cancelled_by_person_id: string | null
  cancel_reason: string | null
  created_at: string
  created_by_person_id: string | null
  updated_at: string | null
  updated_by_person_id: string | null
  is_cancelled: boolean
  from_planning: boolean
  /** v0.6 (R32, R34): Abrechnungsart (null = keine Vergütung) und Kennzeichen „abgerechnet“. */
  remuneration_kind_id: string | null
  remuneration_kind_name: string | null
  is_settled: boolean
}

export type Attendance = {
  id: string
  person_id: string
  role: Role
  status: AttendanceStatus
  is_substitute: boolean
  from_plan: boolean
  is_settled: boolean
}

export type EventDetail = {
  event: EzEvent
  groups: { id: string; name: string; is_primary: boolean }[]
  referat_name: string
  location_name: string | null
  can_write: boolean
  can_delete: boolean
  attendances: Attendance[]
  trials: { id: string; first_name: string }[]
}

export type EventDetailResult = { detail: EventDetail; names: PersonNames } | { detail: null; names: PersonNames; notFound: boolean }

export async function fetchEventDetail(id: string): Promise<EventDetailResult> {
  const { data, error } = await supabase.rpc('ez_get_event', { p_id: id })
  if (error || !data) return { detail: null, names: {}, notFound: !error || ezError(error).code === 'EZ_NOT_FOUND' }
  const detail = data as EventDetail
  const e = detail.event
  const names = await loadPersonNames([
    ...detail.attendances.map((a) => a.person_id),
    e.organizer_person_id,
    e.created_by_person_id,
    e.updated_by_person_id,
    e.cancelled_by_person_id,
  ])
  return { detail, names }
}

export async function loadEventDetail({ params }: LoaderFunctionArgs): Promise<EventDetailResult> {
  await loadEzAccess()
  return fetchEventDetail(params.id ?? '')
}

/** Kopf des Einsatzes als Eingabe für ez_save_event (unverändert, ohne weitere Gruppen: bleiben gespeichert). */
export function eventHead(e: EzEvent): Record<string, unknown> {
  return {
    id: e.id,
    kind: e.kind,
    span: e.span,
    referat_id: e.referat_id,
    group_id: e.group_id,
    title: e.title,
    organizer_person_id: e.organizer_person_id,
    start_date: e.start_date,
    start_time: e.start_time,
    end_date: e.end_date,
    end_time: e.end_time,
    day_category: e.day_category,
    location_id: e.location_id,
    remark: e.remark,
  }
}

/** Anwesenheiten als Eingabe für ez_save_event. */
export function attendanceInput(list: Pick<Attendance, 'person_id' | 'role' | 'status'>[]) {
  return list.map(({ person_id, role, status }) => ({ person_id, role, status }))
}
