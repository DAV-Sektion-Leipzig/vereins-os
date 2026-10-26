// Planungshilfe T022 (US-TK-15, R11, R14): Eingabeblatt, Ausschreibungstext und Zusammenfassung (Prototyp 7.1–7.3)
// ohne Stornoregel; Kontaktdaten nur mit Recht. Nur fiktive Daten.
import assert from 'node:assert/strict'
import { test } from 'node:test'
import { calculate } from '../../src/features/tk/calc.ts'
import * as texts from '../../src/features/tk/ausgaben/texts.ts'
import type { TextInput } from '../../src/features/tk/ausgaben/texts.ts'

// Beträge enthalten ein geschütztes Leerzeichen vor „€“ (Intl); für die Prüfung normalisieren
const nb = (x: string) => x.replace(/\u00a0/g, ' ')
const dayLabel = texts.dayLabel
const descText = (t: TextInput) => nb(texts.descText(t))
const summaryText = (t: TextInput, m: string[]) => nb(texts.summaryText(t, m))
const yolawoFields = (t: TextInput) => texts.yolawoFields(t).map((y) => ({ ...y, value: y.value === null ? null : nb(y.value) }))
import type { PlanFields, Rates } from '../../src/features/tk/types.ts'

const r = (value: number): Rates[string] => ({ label: '', value, percent: null, fixed: null, active: true, valid_from: '2026-01-01' })
const fee = (percent: number, fixed: number): Rates[string] => ({ label: '', value: null, percent, fixed, active: true, valid_from: '2026-01-01' })
const RATES: Rates = {
  rTL: r(50), rTLh: r(25), rH: r(40), rHh: r(20), rOrg: r(10), rLE: r(15), rNM: r(30), rRund: r(5), rVat: r(19), rCO2: r(140),
  ef_rail_long: r(26), ef_local_bus: r(90), ef_stay_hut: r(9.32), ef_food_overnight: r(4.7), ef_food_day: r(1.6),
  fee_sepa: fee(1.5, 0.35), fee_card: fee(2.9, 0.25), fee_paypal: fee(4.5, 0.58),
}

const FIELDS: PlanFields = {
  plan_type: 'guided_tour', title: 'Hüttentour Stubaier Alpen (Test)', community_reason: null, sport: 'Bergwandern',
  target_groups: [], region: 'Stubaier Alpen, Tirol', base: 'Sulzenauhütte', teaser: 'Fünf Tage unterwegs (Test).',
  programme: null, image_source: 'own', image_credit: 'Foto: Test', start_date: '2027-07-12', end_date: '2027-07-16',
  meet_time: '11:00', end_time: '15:00', meeting_point: 'Talstation (Test)', meeting_coords: null, prebriefing: 'online',
  prebriefing_at: '2027-06-14T19:00', public_transport: 'together', travel_notes: null, accommodation: 'hut', nights: null,
  co2_persons: null, meeting_near_pt: true, max_walk_hours: 7, max_ascent: 1000, max_descent: 1000, max_distance_km: 14,
  fitness: 'high', technique: 'medium', grade: 'T2–T3', requirements: 'Trittsicherheit', equipment: 'Bergschuhe',
  non_members_allowed: false, non_members_reason: null, min_participants: 5, max_participants: 8,
  registration_deadline: '2027-05-15', waitlist: true, accommodation_cancellation: null,
  registration_questions: ['DAV-Mitgliedschaft (Sektion Leipzig / andere Sektion / kein Mitglied)', 'Mobilnummer'],
  custom_question: null, days_full: 5, days_half: 0, teaching_hours: null, org_days: 5, car_reason: null, no_fee: false,
  price_member: null, price_non_member: null, yolawo_by: 'referat', notes_for_referat: null, confirm_license: true,
  confirm_calculation: true, confirm_ul_declaration: true, confirm_emergency_card: true, feedback_form: false,
  touched: ['days_full', 'days_half', 'org_days'],
}

function input(fields: PlanFields, withContacts: boolean): TextInput {
  const legs = [
    { mode: 'rail_long' as const, label: 'Leipzig–Innsbruck', km_one_way: 650, persons: 9, vehicles: 0, round_trip: true },
    { mode: 'local_bus' as const, label: null, km_one_way: 30, persons: 9, vehicles: 0, round_trip: true },
  ]
  const costs = [
    { cost_group: 'leader' as const, label: 'Bahnfahrt', quantity: 2, unit_price: 105, is_car: false, is_overnight: false, is_hut_half_board: false },
    { cost_group: 'leader' as const, label: 'Halbpension', quantity: 5, unit_price: 45, is_car: false, is_overnight: false, is_hut_half_board: false },
    { cost_group: 'self_paid' as const, label: 'Hütte Ü+HP', quantity: 4, unit_price: 63.5, is_car: false, is_overnight: false, is_hut_half_board: true },
  ]
  const calc = calculate({ ...fields, rate_kinds: ['trainer'], legs, costs }, RATES)
  return {
    fields,
    leaders: [{ name: 'Bernd Berg', role: 'lead', license_name: 'Trainer*in C Bergwandern', license_valid_until: '2027-10-30', rate_kind: 'trainer' }],
    leaderIds: ['p1'],
    contacts: withContacts ? { p1: { person_id: 'p1', email: 'leitung.test@example.test', mobile: null, emergency_name: 'Notfall Test', emergency_phone: '0151 0000001' } } : undefined,
    legs, costs, calc, co2Price: 140, efs: { ef_rail_long: 26, ef_local_bus: 90 }, missing: [], today: '2026-10-27',
  }
}

test('Wochentag', () => {
  assert.equal(dayLabel('2027-07-12'), 'Mo., 12.07.2027')
  assert.equal(dayLabel('2027-07-16'), 'Fr., 16.07.2027')
})

test('Eingabeblatt: Tarif, nur Mitglieder, Fragen ohne „kein Mitglied“, keine Stornoregel', () => {
  const fields = yolawoFields(input(FIELDS, false))
  const get = (f: string) => fields.find((x) => x.field === f)?.value
  assert.equal(get('Beginn'), 'Mo., 12.07.2027, 11:00 Uhr')
  assert.match(get('DAV-Mitglied') ?? '', /^160,00 €/)
  assert.equal(get('Nichtmitglied'), 'nicht anlegen (nur Mitglieder)')
  assert.match(get('Zusätzliche Fragen') ?? '', /DAV-Mitgliedschaft \(Sektion Leipzig \/ andere Sektion\)/)
  assert.equal(get('Kategorien'), 'Führungstour, Bergwandern')
  assert.ok(!fields.some((x) => /Storno/i.test(x.field)), 'keine Stornoregel (R11)')
})

test('Ausschreibungstext nach 7.2 ohne Stornozeile', () => {
  const text = descText(input(FIELDS, false))
  assert.match(text, /Termin: Mo\., 12\.07\.2027 bis Fr\., 16\.07\.2027/)
  assert.match(text, /Teilnahmebeitrag: 160,00 € für DAV-Mitglieder/)
  assert.match(text, /Mitgliedschaft im DAV/)
  assert.match(text, /Bernd Berg \(Trainer C Bergwandern\)/)
  assert.match(text, /Online-Vorbesprechung am Mo\., 14\.06\.2027, 19:00 Uhr\./)
  assert.ok(!/Stornierung/.test(text), 'keine Stornozeile (R11)')
})

test('Gemeinschaftstour: Kosten tragen die Teilnehmenden', () => {
  const text = descText(input({ ...FIELDS, plan_type: 'community_tour' }, false))
  assert.match(text, /Gemeinschaftstour ohne Teilnahmebeitrag\. Alle Kosten tragen die Teilnehmenden selbst\./)
  assert.ok(!/Mindestteilnehmerzahl/.test(text))
})

test('Zusammenfassung: Kontaktdaten nur mit Recht', () => {
  assert.match(summaryText(input(FIELDS, true), []), /Notfallkontakt Tourenleitung: Notfall Test/)
  const without = summaryText(input(FIELDS, false), ['Treffpunkt'])
  assert.ok(!/Notfallkontakt Tourenleitung/.test(without))
  assert.match(without, /Noch unvollständig\. Es fehlen: Treffpunkt/)
  assert.match(without, /Gesamtkosten \(fix\): 735,00 €/)
  assert.match(without, /Unterkunft: 336 kg \(4 Nächte, DAV-Hütte/)
  assert.match(without, /bei 9 Personen/)
  assert.match(without, /Abrechnung bestätigt/)
})
