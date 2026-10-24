// Bezeichnungen der Anwesenheitserfassung (spec.md EZ 2, R10) und Form je Einsatzart (Check ez_events_shape).

export type EventKind =
  | 'training'
  | 'day_trip'
  | 'multi_day_trip'
  | 'training_trip'
  | 'competition'
  | 'work_assignment'
  | 'course'
  | 'tour'
  | 'training_camp'
export type Span = 'single' | 'multi'
export type DayCategory = 'under_8h' | 'at_least_8h'
export type Role = 'trainer' | 'helper' | 'participant'
export type AttendanceStatus = 'registered' | 'present' | 'absent'

/** Reihenfolge wie die Schaltflächen in /ez/neu (spec.md 6). */
export const KINDS: EventKind[] = [
  'training',
  'day_trip',
  'multi_day_trip',
  'training_trip',
  'competition',
  'training_camp',
  'work_assignment',
  'course',
  'tour',
]

export const KIND_LABELS: Record<EventKind, string> = {
  training: 'Training',
  day_trip: 'Tagesausflug',
  multi_day_trip: 'Mehrtagesfahrt',
  training_trip: 'Ausbildungsfahrt',
  competition: 'Wettkampfbetreuung',
  work_assignment: 'Arbeitseinsatz',
  course: 'Kurs',
  tour: 'Tour',
  training_camp: 'Trainingslager',
}

export const ROLE_LABELS: Record<Role, string> = { trainer: 'Trainer:in', helper: 'Helfer:in', participant: 'Teilnehmer:in' }

export const STATUS_LABELS: Record<AttendanceStatus, string> = {
  registered: 'eingetragen',
  present: 'anwesend',
  absent: 'nicht erschienen',
}

export const DAY_LABELS: Record<DayCategory, string> = { under_8h: 'unter 8 Stunden', at_least_8h: 'mindestens 8 Stunden' }

/** Einsatzarten mit Gruppe; Arbeitseinsatz, Kurs und Tour haben ein Referat statt einer Gruppe. */
export function hasGroup(kind: EventKind): boolean {
  return kind !== 'work_assignment' && kind !== 'course' && kind !== 'tour'
}

/** Organisierende Person (R11): Fahrten, Trainingslager, Kurs, Tour. */
export function needsOrganizer(kind: EventKind): boolean {
  return ['day_trip', 'multi_day_trip', 'training_trip', 'training_camp', 'course', 'tour'].includes(kind)
}

/** Feste Dauer je Einsatzart; null = „eintägig“/„mehrtägig“ wählbar. */
export function fixedSpan(kind: EventKind): Span | null {
  if (kind === 'training' || kind === 'day_trip') return 'single'
  if (kind === 'multi_day_trip' || kind === 'training_camp') return 'multi'
  return null
}

/** Stände „eingetragen / anwesend / nicht erschienen“ nur bei Arbeitseinsatz, Kurs und Tour (R21). */
export function usesStatus(kind: EventKind): boolean {
  return !hasGroup(kind)
}

/** Kurzform der Anwesenden je Rolle für die Liste, z. B. „2 T · 1 H · 9 TN“ (spec.md 6). */
export function presentSummary(trainer: number, helper: number, participant: number): string {
  const parts = [trainer > 0 && `${trainer} T`, helper > 0 && `${helper} H`, participant > 0 && `${participant} TN`].filter(Boolean)
  return parts.length > 0 ? parts.join(' · ') : '–'
}
