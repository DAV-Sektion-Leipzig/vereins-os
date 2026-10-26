// Datenformen der Planungshilfe (spec.md TK 2), wie tk_get_plan und tk_list_plans sie liefern.

export type PlanType = 'guided_tour' | 'course' | 'community_tour'
export type PlanStatus = 'draft' | 'submitted' | 'query' | 'approved' | 'published' | 'done' | 'closed' | 'cancelled'
export type LeaderRole = 'lead' | 'co_lead' | 'helper'
export type RateKind = 'trainer' | 'helper'
export type Transport = 'rail_long' | 'rail_regional' | 'coach' | 'local_bus' | 'tram' | 'car' | 'ecar' | 'van' | 'flight' | 'bike'
export type Accommodation = 'none' | 'hut' | 'self_catering' | 'hotel' | 'camping'
export type CostGroup = 'leader' | 'fixed' | 'per_participant' | 'self_paid'
export type Prebriefing = 'none' | 'online' | 'office'
export type PublicTransport = 'together' | 'possible' | 'not_possible'
export type ImageSource = 'own' | 'referat'
export type Fitness = 'low' | 'medium' | 'high' | 'very_high'
export type Technique = 'easy' | 'medium' | 'hard' | 'very_hard'
export type YolawoBy = 'referat' | 'leader'

/** Felder der Planung, die das Formular bearbeitet (Spaltennamen von tk_plans). */
export type PlanFields = {
  plan_type: PlanType
  title: string
  community_reason: string | null
  sport: string | null
  target_groups: string[]
  region: string | null
  base: string | null
  teaser: string | null
  programme: string | null
  image_source: ImageSource | null
  image_credit: string | null
  start_date: string | null
  end_date: string | null
  meet_time: string | null
  end_time: string | null
  meeting_point: string | null
  meeting_coords: string | null
  prebriefing: Prebriefing
  prebriefing_at: string | null
  public_transport: PublicTransport | null
  travel_notes: string | null
  accommodation: Accommodation
  nights: number | null
  co2_persons: number | null
  meeting_near_pt: boolean
  max_walk_hours: number | null
  max_ascent: number | null
  max_descent: number | null
  max_distance_km: number | null
  fitness: Fitness | null
  technique: Technique | null
  grade: string | null
  requirements: string | null
  equipment: string | null
  non_members_allowed: boolean
  non_members_reason: string | null
  min_participants: number | null
  max_participants: number | null
  registration_deadline: string | null
  waitlist: boolean
  accommodation_cancellation: string | null
  registration_questions: string[]
  custom_question: string | null
  days_full: number | null
  days_half: number | null
  teaching_hours: number | null
  org_days: number | null
  car_reason: string | null
  no_fee: boolean
  price_member: number | null
  price_non_member: number | null
  yolawo_by: YolawoBy
  notes_for_referat: string | null
  confirm_license: boolean
  confirm_calculation: boolean
  confirm_ul_declaration: boolean
  confirm_emergency_card: boolean
  feedback_form: boolean
  touched: string[]
}

export type Plan = PlanFields & {
  id: string
  referat_id: string
  referat_name: string
  status: PlanStatus
  rates_frozen_on: string | null
  yolawo_ref: string | null
  ez_event_id: string | null
  cancelled_at: string | null
  cancel_reason: string | null
  contacts_purged_at: string | null
  row_version: number
  updated_by_name: string | null
  created_by_name: string | null
}

export type Leader = {
  person_id: string
  name: string
  role: LeaderRole
  rate_kind: RateKind | null
  license_name: string | null
  license_valid_from: string | null
  license_valid_until: string | null
}

export type Contact = {
  person_id: string
  email: string | null
  mobile: string | null
  emergency_name: string | null
  emergency_phone: string | null
}

export type Leg = {
  mode: Transport
  label: string | null
  km_one_way: number
  persons: number
  vehicles: number
  round_trip: boolean
}

export type Cost = {
  cost_group: CostGroup
  label: string
  quantity: number
  unit_price: number
  is_car: boolean
  is_overnight: boolean
  is_hut_half_board: boolean
}

export type Rate = {
  label: string
  value: number | null
  percent: number | null
  fixed: number | null
  active: boolean
  valid_from: string
}
export type Rates = Record<string, Rate>

export type Results = {
  days: number | null
  hours_day1: number | null
  fee_total: number | null
  org_total: number | null
  leader_costs: number | null
  fixed_costs: number | null
  per_participant_costs: number | null
  self_paid_per_participant: number | null
  total_costs: number | null
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
  section_bears: number | null
  co2_mobility_kg: number | null
  co2_stay_kg: number | null
  co2_food_kg: number | null
  co2_tour_kg: number | null
  co2_all_kg: number | null
  co2_per_person_kg: number | null
  co2_per_person_day_kg: number | null
  climate_budget_eur: number | null
  co2_status: 'missing' | 'mostly_pt' | 'mixed' | 'mostly_car_flight'
  fitness_suggested: Fitness | null
  rates_valid_on: string | null
  missing: string[]
  warnings: string[]
}

export type HistoryEntry = {
  at: string
  by_name: string | null
  event: string
  from_status: PlanStatus | null
  to_status: PlanStatus | null
  comment: string | null
  changed_fields: string[] | null
}

export type PlanDetail = {
  plan: Plan
  leaders: Leader[]
  contacts?: Contact[]
  legs: Leg[]
  costs: Cost[]
  results: Results | null
  rates: Rates
  rates_frozen: boolean
  history: HistoryEntry[]
  can_write: boolean
  can_change_status: boolean
  can_approve: boolean
  can_manage: boolean
  can_read_contacts: boolean
}
