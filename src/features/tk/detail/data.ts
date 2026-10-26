// Planung mit allen Teilen über tk_get_plan (spec.md TK 2); Entwurf der Oberfläche und Speichern über tk_save_plan.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { calculate, type CalcInput } from '@/features/tk/calc'
import { tkRpc } from '@/features/tk/rpc'
import type { Contact, Cost, Leader, Leg, PlanDetail, PlanFields, Results } from '@/features/tk/types'
import type { TkError } from '@/features/tk/errors'

export type DetailResult = { detail: PlanDetail | null; error: TkError | null }

export async function loadPlan({ params }: LoaderFunctionArgs): Promise<DetailResult> {
  const res = await tkRpc<PlanDetail>('tk_get_plan', { p_id: params.id })
  return res.error ? { detail: null, error: res.error } : { detail: res.data, error: null }
}

export type DraftLeader = Pick<Leader, 'person_id' | 'name' | 'role' | 'rate_kind' | 'license_name' | 'license_valid_from' | 'license_valid_until'>

export type Draft = {
  fields: PlanFields
  leaders: DraftLeader[]
  contacts: Record<string, Contact>
  legs: Leg[]
  costs: Cost[]
}

const FIELD_KEYS: (keyof PlanFields)[] = [
  'plan_type', 'title', 'community_reason', 'sport', 'target_groups', 'region', 'base', 'teaser', 'programme',
  'image_source', 'image_credit', 'start_date', 'end_date', 'meet_time', 'end_time', 'meeting_point', 'meeting_coords',
  'prebriefing', 'prebriefing_at', 'public_transport', 'travel_notes', 'accommodation', 'nights', 'co2_persons',
  'meeting_near_pt', 'max_walk_hours', 'max_ascent', 'max_descent', 'max_distance_km', 'fitness', 'technique', 'grade',
  'requirements', 'equipment', 'non_members_allowed', 'non_members_reason', 'min_participants', 'max_participants',
  'registration_deadline', 'waitlist', 'accommodation_cancellation', 'registration_questions', 'custom_question',
  'days_full', 'days_half', 'teaching_hours', 'org_days', 'car_reason', 'no_fee', 'price_member', 'price_non_member',
  'yolawo_by', 'notes_for_referat', 'confirm_license', 'confirm_calculation', 'confirm_ul_declaration',
  'confirm_emergency_card', 'feedback_form', 'touched',
]

const NUMERIC = new Set(['max_walk_hours', 'max_distance_km', 'price_member', 'price_non_member'])

export function toDraft(detail: PlanDetail): Draft {
  const fields = {} as Record<string, unknown>
  for (const k of FIELD_KEYS) {
    const v = (detail.plan as unknown as Record<string, unknown>)[k]
    fields[k] = NUMERIC.has(k) && v !== null && v !== undefined ? Number(v) : typeof v === 'string' && k.endsWith('_time') ? v.slice(0, 5) : v
  }
  if (typeof fields.prebriefing_at === 'string') fields.prebriefing_at = (fields.prebriefing_at as string).slice(0, 16)
  const contacts: Record<string, Contact> = {}
  for (const c of detail.contacts ?? []) contacts[c.person_id] = c
  return {
    fields: fields as PlanFields,
    leaders: detail.leaders.map((l) => ({
      person_id: l.person_id,
      name: l.name,
      role: l.role,
      rate_kind: l.rate_kind,
      license_name: l.license_name,
      license_valid_from: l.license_valid_from,
      license_valid_until: l.license_valid_until,
    })),
    contacts,
    legs: detail.legs.map((g) => ({ ...g, km_one_way: Number(g.km_one_way) })),
    costs: detail.costs.map((c) => ({ ...c, quantity: Number(c.quantity), unit_price: Number(c.unit_price) })),
  }
}

/** Argumente für tk_save_plan: ganze Planung, Unterlisten ersetzen; Kontaktdaten nur mit Recht. */
export function savePayload(planId: string, draft: Draft, rowVersion: number, withContacts: boolean) {
  return {
    p_plan: { id: planId, ...draft.fields },
    p_leaders: draft.leaders.map((l) => ({ person_id: l.person_id, role: l.role })),
    p_contacts: withContacts
      ? draft.leaders.map((l) => ({ ...(draft.contacts[l.person_id] ?? {}), person_id: l.person_id }))
      : null,
    p_legs: draft.legs,
    p_costs: draft.costs.filter((c) => c.label.trim() !== ''),
    p_row_version: rowVersion,
  }
}

export function calcInput(draft: Draft): CalcInput {
  const f = draft.fields
  return {
    plan_type: f.plan_type, start_date: f.start_date, end_date: f.end_date, meet_time: f.meet_time, end_time: f.end_time,
    accommodation: f.accommodation, nights: f.nights, co2_persons: f.co2_persons, min_participants: f.min_participants,
    max_participants: f.max_participants, days_full: f.days_full, days_half: f.days_half, teaching_hours: f.teaching_hours,
    org_days: f.org_days, no_fee: f.no_fee, target_groups: f.target_groups, non_members_allowed: f.non_members_allowed,
    price_member: f.price_member, price_non_member: f.price_non_member, max_walk_hours: f.max_walk_hours,
    max_ascent: f.max_ascent, max_descent: f.max_descent, touched: f.touched,
    rate_kinds: draft.leaders.map((l) => l.rate_kind), legs: draft.legs, costs: draft.costs.filter((c) => c.label.trim() !== ''),
  }
}

export { calculate }
export type SaveResult = { id: string; row_version: number; status: string; warning: string | null; results: Results }
