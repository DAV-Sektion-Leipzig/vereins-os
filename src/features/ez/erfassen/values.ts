// Formularwerte für Erfassen und Bearbeiten (T023–T028); im Entwurf nur Feldwerte und Person-IDs (US-EZ-18).
import type { FormPerson } from '@/features/ez/erfassen/Anwesenheit'
import type { FormContext } from '@/features/ez/erfassen/data'
import type { EventDetail } from '@/features/ez/detail/data'
import { fixedSpan, hasGroup, type DayCategory, type EventKind, type Span } from '@/features/ez/labels'
import { hhmm } from '@/features/ez/dates'

export type FormValues = {
  clientRequestId: string
  kind: EventKind
  span: Span
  groupId: string
  additionalGroupIds: string[]
  referatId: string
  title: string
  organizerId: string
  startDate: string
  startTime: string
  endDate: string
  endTime: string
  dayCategory: DayCategory | ''
  locationId: string
  remark: string
  /** Abrechnungsart ('' = keine Vergütung); gilt erst nach eigener Wahl, sonst die Vorbelegung (R32). */
  remunerationKindId: string
  remunerationTouched: boolean
  persons: FormPerson[]
  /** Vertretungen bzw. Personen außerhalb der Gruppenliste (bleiben beim Datumswechsel). */
  substituteIds: string[]
  trials: string[]
}

/** Leeres Formular einer Einsatzart; bei genau einer eigenen Gruppe bzw. einem Referat vorausgewählt (R18, spec.md 6). */
export function emptyValues(kind: EventKind, context: FormContext, today: string): FormValues {
  const mine = context.groups.filter((g) => g.mine)
  return {
    clientRequestId: crypto.randomUUID(),
    kind,
    span: fixedSpan(kind) ?? 'single',
    groupId: hasGroup(kind) && mine.length === 1 ? mine[0].id : '',
    additionalGroupIds: [],
    referatId: !hasGroup(kind) && context.referate.length === 1 ? context.referate[0].id : '',
    title: '',
    organizerId: '',
    startDate: today,
    startTime: '',
    endDate: '',
    endTime: '',
    dayCategory: '',
    locationId: '',
    remark: '',
    remunerationKindId: '',
    remunerationTouched: false,
    persons: [],
    substituteIds: [],
    trials: [],
  }
}

/** Werte eines gespeicherten Einsatzes für /ez/:id/bearbeiten. */
export function valuesFromDetail(detail: EventDetail): FormValues {
  const e = detail.event
  return {
    clientRequestId: '',
    kind: e.kind,
    span: e.span,
    groupId: e.group_id ?? '',
    additionalGroupIds: detail.groups.filter((g) => !g.is_primary).map((g) => g.id),
    referatId: e.referat_id,
    title: e.title ?? '',
    organizerId: e.organizer_person_id ?? '',
    startDate: e.start_date,
    startTime: hhmm(e.start_time),
    endDate: e.end_date ?? '',
    endTime: hhmm(e.end_time),
    dayCategory: (e.day_category ?? '') as DayCategory | '',
    locationId: e.location_id ?? '',
    remark: e.remark ?? '',
    remunerationKindId: e.remuneration_kind_id ?? '',
    remunerationTouched: true,
    persons: detail.attendances.map((a) => ({ person_id: a.person_id, role: a.role, status: a.status })),
    substituteIds: detail.attendances.filter((a) => a.is_substitute).map((a) => a.person_id),
    trials: detail.trials.map((t) => t.first_name),
  }
}
