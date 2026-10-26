// Planungshilfe T017 (spec T20, plan.md P1): calc.ts gegen dieselben Werte wie pgTAP 820_tk_calculate
// (Planungen aus spec.md TK Abschnitt 9; Werte Prototyp 4.5, 4.7). Sätze wie der Startbestand ab 01.01.2026.
import assert from 'node:assert/strict'
import { test } from 'node:test'
import { calculate, roundUp, type CalcInput } from '../../src/features/tk/calc.ts'
import type { Rates } from '../../src/features/tk/types.ts'

function r(value: number): Rates[string] {
  return { label: '', value, percent: null, fixed: null, active: true, valid_from: '2026-01-01' }
}
function fee(percent: number, fixed: number, active: boolean): Rates[string] {
  return { label: '', value: null, percent, fixed, active, valid_from: '2026-01-01' }
}

const RATES: Rates = {
  rTL: r(50), rTLh: r(25), rH: r(40), rHh: r(20), rOrg: r(10), rLE: r(15), rNM: r(30), rRund: r(5), rVat: r(19),
  rCO2: r(140), rKmTag1: r(150), rKmTagN: r(100),
  ef_rail_long: r(26), ef_rail_regional: r(44), ef_coach: r(30), ef_local_bus: r(90), ef_tram: r(42), ef_car: r(230),
  ef_ecar: r(98), ef_van: r(232), ef_flight: r(290), ef_bike: r(0), ef_stay_hut: r(9.32), ef_stay_self_catering: r(9.32),
  ef_stay_hotel: r(16.8), ef_stay_camping: r(4.5), ef_food_overnight: r(4.7), ef_food_day: r(1.6),
  fee_sepa: fee(1.5, 0.35, true), fee_card: fee(2.9, 0.25, true), fee_paypal: fee(4.5, 0.58, true),
  fee_klarna: fee(4.3, 0.35, false), fee_transfer: fee(1.9, 0.35, false),
}

const BASE: CalcInput = {
  plan_type: 'guided_tour', start_date: null, end_date: null, meet_time: null, end_time: null, accommodation: 'none',
  nights: null, co2_persons: null, min_participants: null, max_participants: null, days_full: null, days_half: null,
  teaching_hours: null, org_days: null, no_fee: false, target_groups: [], non_members_allowed: false, price_member: null,
  price_non_member: null, max_walk_hours: null, max_ascent: null, max_descent: null, touched: [], rate_kinds: [], legs: [],
  costs: [],
}

const cost = (cost_group: CalcInput['costs'][number]['cost_group'], quantity: number, unit_price: number) => ({
  cost_group, label: 'x', quantity, unit_price, is_car: false, is_overnight: false, is_hut_half_board: false,
})

test('Planung 1: Beispiel des Prototyps (4.5, 4.7)', () => {
  const res = calculate({
    ...BASE, start_date: '2027-07-12', end_date: '2027-07-16', meet_time: '11:00', end_time: '15:00', accommodation: 'hut',
    min_participants: 5, max_participants: 8, days_full: 5, days_half: 0, org_days: 5,
    touched: ['days_full', 'days_half', 'org_days'], max_walk_hours: 7, max_ascent: 1000, max_descent: 1000,
    rate_kinds: ['trainer'],
    legs: [
      { mode: 'rail_long', label: null, km_one_way: 650, persons: 9, vehicles: 0, round_trip: true },
      { mode: 'local_bus', label: null, km_one_way: 30, persons: 9, vehicles: 0, round_trip: true },
    ],
    costs: [cost('leader', 2, 105), cost('leader', 5, 45), cost('leader', 5, 0), cost('self_paid', 4, 63.5),
      cost('self_paid', 1, 210), cost('self_paid', 5, 15)],
  }, RATES)
  assert.equal(res.fee_total, 250)
  assert.equal(res.org_total, 50)
  assert.equal(res.total_costs, 735)
  assert.equal(res.fee_method, 'fee_paypal')
  assert.equal(res.price_suggested, 160)
  assert.equal(res.break_even, 5)
  assert.equal(res.result_min, 18.71)
  assert.equal(res.result_max, 470.93)
  assert.equal(res.fees_at_min, 46.29)
  assert.equal(res.self_paid_per_participant, 539)
  assert.equal(res.suggestions.nights, 4)
  assert.equal(res.suggestions.co2_persons, 9)
  assert.equal(res.co2_mobility_kg, 352.8)
  assert.equal(res.co2_stay_kg, 335.52)
  assert.equal(res.co2_food_kg, 211.5)
  assert.equal(res.co2_tour_kg, 564.3)
  assert.equal(res.co2_per_person_kg, 99.98)
  assert.equal(res.co2_per_person_day_kg, 20)
  assert.equal(res.climate_budget_eur, 79)
  assert.equal(res.co2_status, 'mostly_pt')
  assert.equal(res.fitness_suggested, 'high')
})

test('Nichtmitglieder aus dem (eigenen) Mitgliederbeitrag', () => {
  const input: CalcInput = {
    ...BASE, start_date: '2027-07-12', end_date: '2027-07-16', min_participants: 5, days_full: 5, org_days: 5,
    touched: ['days_full', 'org_days'], rate_kinds: ['trainer'], non_members_allowed: true,
    costs: [cost('leader', 2, 105), cost('leader', 5, 45)],
  }
  assert.equal(calculate(input, RATES).price_non_member_effective, 210)
  assert.equal(calculate({ ...input, price_member: 150 }, RATES).price_non_member_effective, 195)
})

test('Planung 2: eintägiger Kurs, 8 Lehreinheiten × 15 €', () => {
  const res = calculate({ ...BASE, plan_type: 'course', start_date: '2027-10-15', end_date: '2027-10-15', meet_time: '09:00',
    end_time: '17:00', rate_kinds: ['trainer'] }, RATES)
  assert.equal(res.suggestions.teaching_hours, 8)
  assert.equal(res.fee_total, 120)
  assert.equal(res.org_total, 0)
})

test('Planung 5: Gemeinschaftstour, Organisationspauschale 3 × 10 €, trägt die Sektion', () => {
  const res = calculate({ ...BASE, plan_type: 'community_tour', start_date: '2027-09-10', end_date: '2027-09-12',
    min_participants: 4, rate_kinds: ['helper'], costs: [cost('leader', 600, 0.2)] }, RATES)
  assert.equal(res.fee_total, 0)
  assert.equal(res.org_total, 30)
  assert.equal(res.leader_costs, 0)
  assert.equal(res.is_free, true)
  assert.equal(res.section_bears, 30)
  assert.equal(res.price_member_effective, 0)
})

test('Planung 7: Familienwanderung ohne Beitrag (Halbtagessatz + 40 €)', () => {
  const input: CalcInput = { ...BASE, start_date: '2027-04-18', end_date: '2027-04-18', meet_time: '10:00', end_time: '15:00',
    no_fee: true, target_groups: ['Familienwanderungen'], min_participants: 4, rate_kinds: ['trainer'],
    costs: [cost('fixed', 1, 40)] }
  const res = calculate(input, RATES)
  assert.equal(res.is_free, true)
  assert.equal(res.total_costs, 65)
  assert.equal(res.section_bears, 65)
  assert.equal(calculate({ ...input, target_groups: [] }, RATES).is_free, false)
})

test('Planung 9: mehrtägiger Kurs ohne Vorschlag, 20 Lehreinheiten nur für Trainer:in (R22)', () => {
  const input: CalcInput = { ...BASE, plan_type: 'course', start_date: '2027-07-01', end_date: '2027-07-03',
    meet_time: '08:00', end_time: '18:00', rate_kinds: ['trainer', 'helper'] }
  assert.equal(calculate(input, RATES).suggestions.teaching_hours, null)
  assert.equal(calculate(input, RATES).fee_total, 0)
  const res = calculate({ ...input, teaching_hours: 20, touched: ['teaching_hours'] }, RATES)
  assert.equal(res.fee_total, 300)
  assert.equal(res.org_total, 0)
})

test('Planung 4: Helfersatz, 9 Stunden = Tagessatz', () => {
  const res = calculate({ ...BASE, start_date: '2027-11-02', end_date: '2027-11-02', meet_time: '08:00', end_time: '17:00',
    rate_kinds: ['helper'] }, RATES)
  assert.equal(res.fee_total, 40)
})

test('Aufrunden auf 5 €', () => {
  assert.equal(roundUp(156.05, 5), 160)
  assert.equal(roundUp(155, 5), 155)
  assert.equal(roundUp(155.0000000001, 5), 155)
})
