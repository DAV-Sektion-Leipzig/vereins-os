// Kalkulation für die Live-Anzeige (spec.md TK R1–R4, R22; Prototyp 4.1–4.8; plan.md P1, P2). Gleiche Formeln wie
// tk_calculate in der Datenbank; maßgeblich ist das Ergebnis der Datenbank nach dem Speichern. Reine Funktion ohne
// Supabase (Test: scripts/tk-calc/calc.test.ts). Die Satzart der Leitung kommt aus der Datenbank (Lizenzen).
import type { Accommodation, Cost, Fitness, Leg, PlanType, RateKind, Rates } from '@/features/tk/types'

export type CalcInput = {
  plan_type: PlanType
  start_date: string | null
  end_date: string | null
  meet_time: string | null
  end_time: string | null
  accommodation: Accommodation
  nights: number | null
  co2_persons: number | null
  min_participants: number | null
  max_participants: number | null
  days_full: number | null
  days_half: number | null
  teaching_hours: number | null
  org_days: number | null
  no_fee: boolean
  target_groups: string[]
  non_members_allowed: boolean
  price_member: number | null
  price_non_member: number | null
  max_walk_hours: number | null
  max_ascent: number | null
  max_descent: number | null
  touched: string[]
  /** Satzart je Person der Leitung (unbekannt = Helfer:in, bis die Datenbank gerechnet hat). */
  rate_kinds: (RateKind | null)[]
  legs: Leg[]
  costs: Cost[]
}

export type Suggestions = {
  days_full: number
  days_half: number
  org_days: number
  teaching_hours: number | null
  nights: number
  co2_persons: number | null
}

export type CalcResult = {
  days: number
  hours_day1: number | null
  suggestions: Suggestions
  fee_total: number
  org_total: number
  leader_costs: number
  fixed_costs: number
  per_participant_costs: number
  self_paid_per_participant: number
  total_costs: number
  fee_method: string | null
  price_raw: number | null
  price_suggested: number | null
  price_member_effective: number | null
  price_non_member_suggested: number | null
  price_non_member_effective: number | null
  net_per_participant: number | null
  contribution_per_participant: number | null
  break_even: number | null
  result_min: number | null
  result_max: number | null
  fees_at_min: number | null
  is_free: boolean
  section_bears: number
  co2_mobility_kg: number
  co2_stay_kg: number
  co2_food_kg: number
  co2_tour_kg: number
  co2_all_kg: number
  co2_per_person_kg: number | null
  co2_per_person_day_kg: number | null
  climate_budget_eur: number
  co2_status: 'missing' | 'mostly_pt' | 'mixed' | 'mostly_car_flight'
  fitness_suggested: Fitness | null
}

const VEHICLES = ['car', 'ecar', 'van']
const STAY_KEYS: Record<Accommodation, string | null> = {
  none: null,
  hut: 'ef_stay_hut',
  self_catering: 'ef_stay_self_catering',
  hotel: 'ef_stay_hotel',
  camping: 'ef_stay_camping',
}

function rate(rates: Rates, key: string): number {
  const v = rates[key]?.value
  return typeof v === 'number' ? v : Number(v ?? 0) || 0
}

function n(value: number | null | undefined): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0
}

/** Beitrag aufrunden: ceil(roh / rund − 1e−9) × rund (R1). */
export function roundUp(value: number, step: number): number {
  if (step <= 0) return Math.ceil(value - 1e-9)
  return Math.ceil(value / step - 1e-9) * step
}

function round2(value: number): number {
  return Math.round(value * 100) / 100
}

function dayDiff(from: string, to: string): number {
  const a = Date.UTC(+from.slice(0, 4), +from.slice(5, 7) - 1, +from.slice(8, 10))
  const b = Date.UTC(+to.slice(0, 4), +to.slice(5, 7) - 1, +to.slice(8, 10))
  return Math.round((b - a) / 86_400_000)
}

function minutes(time: string): number {
  return +time.slice(0, 2) * 60 + +time.slice(3, 5)
}

export function calculate(input: CalcInput, rates: Rates): CalcResult {
  const isCourse = input.plan_type === 'course'
  const isCommunity = input.plan_type === 'community_tour'

  // 4.1 Tage und Stunden des ersten Tages
  const days = input.start_date && input.end_date ? Math.max(dayDiff(input.start_date, input.end_date) + 1, 0) : 0
  let hours: number | null = null
  if (input.meet_time && input.end_time && minutes(input.end_time) > minutes(input.meet_time)) {
    hours = (minutes(input.end_time) - minutes(input.meet_time)) / 60
  }

  // 4.2 Vorschläge (nur für Felder, die nicht in touched stehen)
  const touched = new Set(input.touched)
  const sDaysFull = days > 1 ? days : days === 1 ? (hours !== null && hours >= 8 ? 1 : 0) : 0
  const daysFull = touched.has('days_full') ? n(input.days_full) : sDaysFull
  const sDaysHalf = days === 1 ? 1 - daysFull : 0
  const daysHalf = touched.has('days_half') ? n(input.days_half) : sDaysHalf
  const sOrg = days > 1 ? days : 0
  const orgDays = touched.has('org_days') ? n(input.org_days) : sOrg
  const sTeaching = isCourse && days === 1 && hours !== null ? Math.max(Math.floor(hours), 0) : null
  const teaching = touched.has('teaching_hours') || sTeaching === null ? input.teaching_hours : sTeaching
  const sNights = input.accommodation === 'none' ? 0 : Math.max(days - 1, 0)
  const nights = touched.has('nights') ? n(input.nights) : sNights
  const nLeaders = input.rate_kinds.length
  const sPersons = n(input.max_participants) > 0 ? n(input.max_participants) + Math.max(nLeaders, 1) : input.co2_persons
  const persons = touched.has('co2_persons') ? input.co2_persons : sPersons

  // 4.3 Vergütung (R4 Gemeinschaftstour, R22 Kurs)
  const nTrainer = input.rate_kinds.filter((k) => k === 'trainer').length
  const nHelper = nLeaders - nTrainer
  let fee = 0
  let org = 0
  if (isCommunity) {
    org = orgDays * rate(rates, 'rOrg')
  } else if (isCourse) {
    fee = nTrainer * n(teaching) * rate(rates, 'rLE')
  } else {
    fee =
      nTrainer * (daysFull * rate(rates, 'rTL') + daysHalf * rate(rates, 'rTLh')) +
      nHelper * (daysFull * rate(rates, 'rH') + daysHalf * rate(rates, 'rHh'))
    org = orgDays * rate(rates, 'rOrg')
  }

  // 4.4 Kosten
  const sum = (group: Cost['cost_group']) =>
    input.costs.filter((c) => c.cost_group === group).reduce((s, c) => s + n(c.quantity) * n(c.unit_price), 0)
  const leaderCosts = isCommunity ? 0 : sum('leader')
  const fixed = isCommunity ? 0 : sum('fixed')
  const perParticipant = isCommunity ? 0 : sum('per_participant')
  const selfPaid = sum('self_paid')
  const total = fee + org + leaderCosts + fixed

  // 4.5 Teilnahmebeitrag
  const isFree = isCommunity || (input.no_fee && days === 1 && input.target_groups.includes('Familienwanderungen'))
  const vat = rate(rates, 'rVat') / 100
  const step = rates.rRund ? rate(rates, 'rRund') : 1
  const minTn = input.min_participants
  let method: string | null = null
  let fp = 0
  let ff = 0
  let best = -Infinity
  for (const key of Object.keys(rates).sort()) {
    const r = rates[key]
    if (!key.startsWith('fee_') || !r.active || r.percent === null) continue
    const p = (Number(r.percent) / 100) * (1 + vat)
    const f = Number(r.fixed ?? 0) * (1 + vat)
    const need = (total / Math.max(minTn ?? 1, 1) + perParticipant + f) / (1 - p)
    if (need > best) {
      best = need
      method = key
      fp = p
      ff = f
    }
  }
  const raw = minTn && minTn > 0 ? (total / minTn + perParticipant + ff) / (1 - fp) : null
  const suggested = isFree ? 0 : raw === null ? null : roundUp(raw, step)
  const pm = isFree ? 0 : (input.price_member ?? suggested)
  let pnSuggested: number | null = null
  let pn: number | null = null
  if (input.non_members_allowed && !isFree && pm !== null) {
    pnSuggested = roundUp(pm * (1 + rate(rates, 'rNM') / 100), step)
    pn = input.price_non_member ?? pnSuggested
  }
  let net: number | null = null
  let contribution: number | null = null
  let breakEven: number | null = null
  let resMin: number | null = null
  let resMax: number | null = null
  let feesMin: number | null = null
  if (pm !== null) {
    net = pm <= 0 ? 0 : pm * (1 - fp) - ff
    contribution = net - perParticipant
    if (contribution > 0) breakEven = Math.ceil(total / contribution - 1e-9)
    if (minTn !== null) {
      resMin = minTn * contribution - total
      feesMin = minTn * (pm - net)
    }
    if (input.max_participants !== null) resMax = input.max_participants * contribution - total
  }

  // 4.7 CO2
  let mob = 0
  let mobCar = 0
  for (const leg of input.legs) {
    const factor = rate(rates, `ef_${leg.mode}`)
    const count = VEHICLES.includes(leg.mode) ? n(leg.vehicles) : n(leg.persons)
    const kg = (n(leg.km_one_way) * (leg.round_trip ? 2 : 1) * count * factor) / 1000
    mob += kg
    if (VEHICLES.includes(leg.mode) || leg.mode === 'flight') mobCar += kg
  }
  const stayKey = STAY_KEYS[input.accommodation]
  const stay = stayKey ? nights * n(persons) * rate(rates, stayKey) : 0
  const food = days > 0 ? n(persons) * days * rate(rates, nights > 0 ? 'ef_food_overnight' : 'ef_food_day') : 0
  const tour = mob + food + (input.accommodation === 'hut' ? 0 : stay)
  const all = mob + stay + food
  const co2Status = !input.legs.some((l) => n(l.km_one_way) > 0)
    ? 'missing'
    : mob <= 0 || mobCar / mob < 0.25
      ? 'mostly_pt'
      : mobCar / mob < 0.5
        ? 'mixed'
        : 'mostly_car_flight'

  // 4.8 Kondition
  const g = n(input.max_walk_hours)
  const h = Math.max(n(input.max_ascent), n(input.max_descent))
  const fitness: Fitness | null =
    g > 0 || h > 0 ? (g > 8 || h > 1500 ? 'very_high' : g > 6 || h > 1000 ? 'high' : g > 4 || h > 500 ? 'medium' : 'low') : null

  return {
    days,
    hours_day1: hours === null ? null : round2(hours),
    suggestions: { days_full: sDaysFull, days_half: sDaysHalf, org_days: sOrg, teaching_hours: sTeaching, nights: sNights, co2_persons: sPersons },
    fee_total: round2(fee),
    org_total: round2(org),
    leader_costs: round2(leaderCosts),
    fixed_costs: round2(fixed),
    per_participant_costs: round2(perParticipant),
    self_paid_per_participant: round2(selfPaid),
    total_costs: round2(total),
    fee_method: method,
    price_raw: raw,
    price_suggested: suggested,
    price_member_effective: pm === null ? null : round2(pm),
    price_non_member_suggested: pnSuggested,
    price_non_member_effective: pn === null ? null : round2(pn),
    net_per_participant: net,
    contribution_per_participant: contribution,
    break_even: breakEven,
    result_min: resMin === null ? null : round2(resMin),
    result_max: resMax === null ? null : round2(resMax),
    fees_at_min: feesMin === null ? null : round2(feesMin),
    is_free: isFree,
    section_bears: isFree ? round2(total) : 0,
    co2_mobility_kg: round2(mob),
    co2_stay_kg: round2(stay),
    co2_food_kg: round2(food),
    co2_tour_kg: round2(tour),
    co2_all_kg: round2(all),
    co2_per_person_kg: n(persons) > 0 ? round2(all / n(persons)) : null,
    co2_per_person_day_kg: n(persons) > 0 && days > 0 ? round2(all / n(persons) / days) : null,
    climate_budget_eur: round2((tour / 1000) * rate(rates, 'rCO2')),
    co2_status: co2Status,
    fitness_suggested: fitness,
  }
}
