// Daten für Erfassen und Bearbeiten (T023–T028): wählbare Gruppen (R18), Referate, Orte, Anwesenheitsliste zum Stichtag.
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import { canWriteReferat, requireEzEdit, type EzAccess } from '@/features/ez/access'
import { todayIso } from '@/features/ez/dates'
import { fetchEventDetail, type EventDetail } from '@/features/ez/detail/data'
import type { EventKind, Role, Span } from '@/features/ez/labels'
import { loadLocations, type Location } from '@/features/ez/shared/locations'
import type { PersonNames } from '@/features/ez/shared/rpc'
import { supabase } from '@/lib/supabase'

export type GroupOption = { id: string; name: string; referat_id: string; referat_name: string; mine: boolean }
export type ReferatOption = { id: string; name: string }

export type RosterRole = 'group_lead' | 'trainer' | 'helper' | 'participant'
export type RosterPerson = {
  person_id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  role: RosterRole
}
export type Roster = {
  training_times: { starts_at: string; ends_at: string }[]
  persons: RosterPerson[]
}

export type RemunerationOption = { id: string; name: string; is_active: boolean }
export type RemunerationDefault = { event_kind: EventKind; span: Span; kind_id: string | null; valid_from: string }

export type FormContext = {
  access: EzAccess
  userId: string
  groups: GroupOption[]
  referate: ReferatOption[]
  locations: Location[]
  /** Abrechnungsarten und Vorbelegung je Einsatzart aus der Administration (R32). */
  remunerationKinds: RemunerationOption[]
  remunerationDefaults: RemunerationDefault[]
}

export type EditContext = FormContext & { detail: EventDetail; names: PersonNames }

/** Wählbare Gruppen: lesbar (gr_groups_for_attendance) und beschreibbar; eigene Gruppen oben (R18). */
async function loadGroups(access: EzAccess): Promise<GroupOption[]> {
  const today = todayIso()
  const [all, mine] = await Promise.all([
    supabase.rpc('gr_groups_for_attendance', { p_date: today }),
    supabase.rpc('gr_my_groups', { p_date: today }),
  ])
  const mineIds = new Set(Array.isArray(mine.data) ? (mine.data as { group_id: string }[]).map((g) => g.group_id) : [])
  const rows = Array.isArray(all.data)
    ? (all.data as { group_id: string; group_name: string; referat_id: string; referat_name: string }[])
    : []
  return rows
    .filter((g) => canWriteReferat(access, g.referat_id))
    .map((g) => ({ id: g.group_id, name: g.group_name, referat_id: g.referat_id, referat_name: g.referat_name, mine: mineIds.has(g.group_id) }))
    .sort((a, b) => Number(b.mine) - Number(a.mine) || a.name.localeCompare(b.name, 'de-DE'))
}

/** Beschreibbare, aktive Referate für Arbeitseinsatz, Kurs und Tour (R19). */
async function loadReferate(access: EzAccess): Promise<ReferatOption[]> {
  const { data, error } = await supabase.from('ea_referate').select('id, name, is_active').order('sort_order').order('name')
  if (error || !data) return []
  return (data as (ReferatOption & { is_active: boolean })[])
    .filter((r) => r.is_active && canWriteReferat(access, r.id))
    .map(({ id, name }) => ({ id, name }))
}

async function loadRemuneration(): Promise<Pick<FormContext, 'remunerationKinds' | 'remunerationDefaults'>> {
  const [kinds, defaults] = await Promise.all([
    supabase.from('ad_remuneration_kinds').select('id, name, is_active').order('name'),
    supabase.from('ad_remuneration_defaults').select('event_kind, span, kind_id, valid_from'),
  ])
  return {
    remunerationKinds: (kinds.data ?? []) as RemunerationOption[],
    remunerationDefaults: (defaults.data ?? []) as RemunerationDefault[],
  }
}

async function loadContext(): Promise<FormContext> {
  const access = await requireEzEdit()
  const { data } = await supabase.auth.getSession()
  const [groups, referate, locations, remuneration] = await Promise.all([
    loadGroups(access),
    loadReferate(access),
    loadLocations(),
    loadRemuneration(),
  ])
  return { access, userId: data.session?.user.id ?? '', groups, referate, locations, ...remuneration }
}

/** Vorbelegte Abrechnungsart wie ad_remuneration_default_at: spätestes „gültig ab“ ≤ Datum; '' = keine Vergütung. */
export function remunerationDefault(context: FormContext, kind: EventKind, span: Span, date: string): string {
  const day = date || todayIso()
  const match = context.remunerationDefaults
    .filter((d) => d.event_kind === kind && d.span === span && d.valid_from <= day)
    .sort((a, b) => b.valid_from.localeCompare(a.valid_from))[0]
  return match?.kind_id ?? ''
}

export async function loadNewEvent(): Promise<FormContext> {
  return loadContext()
}

export async function loadEditEvent({ params }: LoaderFunctionArgs): Promise<EditContext> {
  const context = await loadContext()
  const result = await fetchEventDetail(params.id ?? '')
  // Nicht lesbar, nicht beschreibbar oder abgesagt: zurück zum Einsatz (dort Meldung bzw. „Absage zurücknehmen“)
  if (!result.detail || !result.detail.can_write || result.detail.event.is_cancelled) throw redirect(`/ez/${params.id}`)
  return { ...context, detail: result.detail, names: result.names }
}

export async function loadRoster(groupId: string, date: string): Promise<Roster | null> {
  const { data, error } = await supabase.rpc('gr_group_roster', { p_group_id: groupId, p_date: date })
  if (error || !data) return null
  return data as Roster
}

const ROLE_RANK: Record<RosterRole, number> = { group_lead: 0, trainer: 1, helper: 2, participant: 3 }

export type ListPerson = RosterPerson & { defaultRole: Role; staff: boolean }

/**
 * Anwesenheitsliste aus einem oder mehreren Rostern: je Person einmal (R17, R30), Funktion vor Teilnahme (plan.md H1);
 * Gruppenleitung mit Rolle Trainer:in vorbelegt (spec.md 6).
 */
export function mergeRosters(rosters: Roster[]): ListPerson[] {
  const best = new Map<string, RosterPerson>()
  for (const roster of rosters) {
    for (const p of roster.persons) {
      const current = best.get(p.person_id)
      if (!current || ROLE_RANK[p.role] < ROLE_RANK[current.role]) best.set(p.person_id, p)
    }
  }
  return [...best.values()]
    .map((p) => ({
      ...p,
      staff: p.role !== 'participant',
      defaultRole: (p.role === 'group_lead' ? 'trainer' : p.role) as Role,
    }))
    .sort((a, b) => a.last_name.localeCompare(b.last_name, 'de-DE') || (a.preferred_name ?? a.first_name).localeCompare(b.preferred_name ?? b.first_name, 'de-DE'))
}
