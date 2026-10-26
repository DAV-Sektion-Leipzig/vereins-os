// T022 (US-TK-15, -21; spec.md TK 6 „Ausgaben“, R11, R14): Yolawo-Eingabeblatt, Ausschreibungstext und Zusammenfassung
// nach Prototyp 7.1–7.3, ohne Stornoregel und ohne eingebettete Daten. Reine Funktionen (Test: scripts/tk-calc/texts.test.ts).
// Kontakt- und Notfalldaten nur, wenn sie übergeben werden (Recht tk_can_read_contacts).
import type { CalcResult } from '@/features/tk/calc'
import {
  ACCOMMODATION_LABELS, FITNESS_LABELS, formatMoney, PAYMENT_LABELS, ROLE_LABELS, TECHNIQUE_LABELS, TRANSPORT_LABELS,
} from '@/features/tk/labels'
import type { Contact, Cost, LeaderRole, Leg, PlanFields, PlanType } from '@/features/tk/types'

export type TextLeader = { name: string; role: LeaderRole; license_name: string | null; license_valid_until: string | null; rate_kind: string | null }

export type TextInput = {
  fields: PlanFields
  leaders: TextLeader[]
  /** nur mit Recht; sonst undefined */
  contacts?: Record<string, Contact>
  leaderIds?: string[]
  legs: Leg[]
  costs: Cost[]
  calc: CalcResult
  co2Price: number | null
  efs: Record<string, number>
  missing: string[]
  /** heute als YYYY-MM-DD (für „Erstellt am“) */
  today: string
}

export type YolawoField = { group: string; field: string; value: string | null }

/** Felder mit Vorschlag: ohne eigene Eingabe gilt der Vorschlag der Kalkulation (Prototyp 4.2). */
function effective(t: TextInput): PlanFields {
  const f = t.fields
  const sg = t.calc.suggestions
  const pick = (key: 'days_full' | 'days_half' | 'org_days' | 'nights', value: number) => (f.touched.includes(key) ? f[key] : value)
  return {
    ...f,
    days_full: pick('days_full', sg.days_full),
    days_half: pick('days_half', sg.days_half),
    org_days: pick('org_days', sg.org_days),
    nights: pick('nights', sg.nights),
    teaching_hours: f.touched.includes('teaching_hours') || sg.teaching_hours === null ? f.teaching_hours : sg.teaching_hours,
    co2_persons: f.touched.includes('co2_persons') ? f.co2_persons : (sg.co2_persons ?? f.co2_persons),
  }
}

const WEEKDAY = ['So.', 'Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.']

/** „Mo., 12.07.2027“ */
export function dayLabel(date: string): string {
  const [y, m, d] = date.split('-').map(Number)
  const wd = new Date(Date.UTC(y, m - 1, d)).getUTCDay()
  return `${WEEKDAY[wd]}, ${String(d).padStart(2, '0')}.${String(m).padStart(2, '0')}.${y}`
}

function plainDate(date: string): string {
  const [y, m, d] = date.split('-')
  return `${d}.${m}.${y}`
}

function eur(value: number | null | undefined): string {
  return formatMoney(value)
}

function kg(value: number | null | undefined): string {
  if (value === null || value === undefined) return '–'
  return `${Math.round(value).toLocaleString('de-DE')} kg`
}

/** Kategorien für Yolawo (Prototyp 4.2a). */
export function categories(f: PlanFields): string[] {
  const type = f.plan_type === 'course' ? ['Führungstour', 'Kurs'] : [f.plan_type === 'community_tour' ? 'Gemeinschaftstour' : 'Führungstour']
  return [...type, ...(f.sport ? [f.sport] : []), ...f.target_groups]
}

const TYPE_TEXT: Record<PlanType, string> = {
  guided_tour: 'Führungstour',
  course: 'Führungstour / Kurs',
  community_tour: 'Gemeinschaftstour',
}

/** Termin für Texte: „Mo., 12.07.2027 bis Fr., 16.07.2027“ bzw. eintägig nur das Datum. */
export function termText(f: PlanFields): string {
  if (!f.start_date) return '–'
  if (!f.end_date || f.end_date === f.start_date) return dayLabel(f.start_date)
  return `${dayLabel(f.start_date)} bis ${dayLabel(f.end_date)}`
}

function perParticipantLabels(costs: Cost[]): string[] {
  return costs.filter((c) => c.cost_group === 'per_participant' && c.label.trim()).map((c) => c.label.trim())
}

function tariffDescription(costs: Cost[]): string {
  const extra = perParticipantLabels(costs)
  return `Beschreibung: Im Tarif enthalten sind: Touren-/Kursleitung, Organisation${extra.length ? `, ${extra.join(', ')}` : ''}`
}

// 7.1 Yolawo-Eingabeblatt (ohne Stornoregeln, R11)
export function yolawoFields(t: TextInput): YolawoField[] {
  const f = effective(t)
  const c = t.calc
  const time = (date: string | null, clock: string | null) => (date ? `${dayLabel(date)}${clock ? `, ${clock.slice(0, 5)} Uhr` : ''}` : null)
  const questions = [...f.registration_questions.map((q) =>
    !f.non_members_allowed && q.startsWith('DAV-Mitgliedschaft') ? q.replace(' / kein Mitglied', '') : q), ...(f.custom_question ? [f.custom_question] : [])]
  return [
    { group: 'Angebot', field: 'Angebotstyp', value: 'Ausfahrt, Reise, Tour' },
    { group: 'Angebot', field: 'Titel', value: f.title || null },
    { group: 'Angebot', field: 'Kategorien', value: categories(f).join(', ') },
    {
      group: 'Angebot',
      field: 'Titelbild',
      value: f.image_source === 'own' ? `Foto der Tourenleitung (Anhang), ${f.image_credit ?? 'Bildrechte fehlen'}` : f.image_source === 'referat' ? 'Referat wählt ein Bild' : null,
    },
    { group: 'Angebot', field: 'Beschreibung', value: '→ Ausschreibungstext (Überschriften fett setzen)' },
    { group: 'Buchungsoption', field: 'Typ', value: 'Einzeltermin' },
    { group: 'Termin', field: 'Beginn', value: time(f.start_date, f.meet_time) },
    { group: 'Termin', field: 'Ende', value: time(f.end_date, f.end_time) },
    { group: 'Termin', field: 'Ort', value: [f.meeting_point, f.meeting_coords].filter(Boolean).join('\n') || null },
    { group: 'Buchungsoption', field: 'Kapazität', value: f.max_participants !== null ? String(f.max_participants) : null },
    { group: 'Buchungsoption', field: 'Buchungszeitraum Ende', value: f.registration_deadline ? `${plainDate(f.registration_deadline)}, 23:59 Uhr` : null },
    { group: 'Buchungsoption', field: 'Warteliste', value: f.waitlist ? 'aktiv' : 'aus' },
    {
      group: 'Tarif',
      field: 'DAV-Mitglied',
      value: c.is_free ? 'kein Tarif nötig (kostenlos)' : c.price_member_effective !== null ? `${eur(c.price_member_effective)}\n${tariffDescription(t.costs)}` : null,
    },
    {
      group: 'Tarif',
      field: 'Nichtmitglied',
      value: !f.non_members_allowed || c.is_free ? 'nicht anlegen (nur Mitglieder)' : c.price_non_member_effective !== null ? `${eur(c.price_non_member_effective)}\n${tariffDescription(t.costs)}` : null,
    },
    { group: 'Zahlung', field: 'Zahlungsart', value: c.is_free ? 'entfällt' : 'Onlinezahlung' },
    { group: 'Anmeldeformular', field: 'Zusätzliche Fragen', value: questions.length ? questions.join('\n') : '–' },
    {
      group: 'Intern, kein Yolawo-Feld',
      field: 'Mindestanzahl',
      value: f.min_participants !== null
        ? `${f.min_participants} (steht im Beschreibungstext${f.registration_deadline ? `; Absage prüfen am ${plainDate(f.registration_deadline)}` : ''})`
        : null,
    },
  ]
}

function leaderLine(l: TextLeader): string {
  const qual = l.license_name ? l.license_name.replace(/\*in\b/g, '') : null
  return `${l.name}${qual ? ` (${qual})` : ''}${l.role !== 'lead' ? `, ${ROLE_LABELS[l.role]}` : ''}`
}

function joinBlocks(blocks: (string | null | false | undefined)[]): string {
  return blocks.filter((b): b is string => !!b && b.trim() !== '').join('\n\n').replace(/\n{3,}/g, '\n\n')
}

function lines(...items: (string | null | false | undefined)[]): string | null {
  const rest = items.filter((x): x is string => !!x)
  return rest.length ? rest.join('\n') : null
}

// 7.2 Ausschreibungstext (ohne Stornozeile, R11)
export function descText(t: TextInput): string {
  const f = effective(t)
  const c = t.calc
  const isCommunity = f.plan_type === 'community_tour'
  const stage = [
    f.max_walk_hours ? `bis ${f.max_walk_hours.toLocaleString('de-DE')} h Gehzeit` : null,
    f.max_ascent ? `${f.max_ascent.toLocaleString('de-DE')} Hm ↑` : null,
    f.max_descent ? `${f.max_descent.toLocaleString('de-DE')} Hm ↓` : null,
    f.max_distance_km ? `${f.max_distance_km.toLocaleString('de-DE')} km` : null,
  ].filter(Boolean)
  const selfPaid = t.costs.filter((x) => x.cost_group === 'self_paid' && x.label.trim())
  const extra = perParticipantLabels(t.costs)
  const transport =
    f.public_transport === 'together' ? 'Eine gemeinsame Anreise mit öffentlichen Verkehrsmitteln ist vorgesehen.'
      : f.public_transport === 'possible' ? 'Die Anreise mit öffentlichen Verkehrsmitteln ist möglich.'
        : f.public_transport === 'not_possible' ? 'Eine Anreise mit öffentlichen Verkehrsmitteln ist nicht sinnvoll möglich. Fahrgemeinschaften könnt ihr über Moobly bilden.'
          : null
  const pb = f.prebriefing_at ? ` am ${dayLabel(f.prebriefing_at.slice(0, 10))}, ${f.prebriefing_at.slice(11, 16)} Uhr` : ''
  return joinBlocks([
    f.teaser,
    f.programme && `Ablauf\n${f.programme}`,
    lines(
      'Tourdaten (Kurzinfo)',
      `Termin: ${termText(f)}`,
      f.sport && `Tourenart: ${f.sport}`,
      `Tourtyp: ${TYPE_TEXT[f.plan_type]}`,
      f.fitness && `Schwierigkeit Kondition: ${FITNESS_LABELS[f.fitness]}`,
      f.technique && `Schwierigkeit Technik: ${TECHNIQUE_LABELS[f.technique]}${f.grade ? ` (${f.grade})` : ''}`,
      stage.length > 0 && `Etappen: ${stage.join(', ')} pro Tag`,
      (!!f.min_participants || !!f.max_participants) && `Teilnehmende: ${f.min_participants ?? '?'} bis ${f.max_participants ?? '?'}`,
      c.co2_per_person_kg !== null &&
        `Klimabilanz: ca. ${kg(c.co2_per_person_kg)} CO2e pro Person (An- und Abreise ${kg(c.co2_mobility_kg)}, Unterkunft und Verpflegung ${kg(c.co2_stay_kg + c.co2_food_kg)})`,
      f.region && `Gebiet: ${f.region}${f.base ? `, Stützpunkt ${f.base}` : ''}`,
    ),
    (f.requirements || !f.non_members_allowed) && lines('Voraussetzungen', f.requirements, !f.non_members_allowed && 'Mitgliedschaft im DAV'),
    f.equipment && `Ausrüstung\n${f.equipment}`,
    lines(
      'Kosten',
      isCommunity ? 'Gemeinschaftstour ohne Teilnahmebeitrag. Alle Kosten tragen die Teilnehmenden selbst.'
        : c.is_free ? 'Für die Teilnahme wird kein Beitrag erhoben.'
          : `Teilnahmebeitrag: ${eur(c.price_member_effective)} für DAV-Mitglieder${f.non_members_allowed && c.price_non_member_effective !== null ? ` / ${eur(c.price_non_member_effective)} für Nichtmitglieder` : ''}`,
      !c.is_free && `Im Beitrag enthalten: Leitung und Organisation${extra.length ? `, ${extra.join(', ')}` : ''}`,
      selfPaid.length > 0 && `Zusätzlich selbst zu zahlen (ca.): ${selfPaid.map((x) => `${x.label}${x.quantity * x.unit_price > 0 ? ` ca. ${eur(x.quantity * x.unit_price)}` : ''}`).join('; ')}`,
      !c.is_free && !!f.min_participants && `Mindestteilnehmerzahl: ${f.min_participants}. Wird sie bis zum Anmeldeschluss nicht erreicht, sagen wir die Tour ab und erstatten bereits gezahlte Beiträge.`,
      f.registration_deadline && `Anmeldeschluss: ${plainDate(f.registration_deadline)}`,
    ),
    t.leaders.length > 0 && lines('Leitung', ...t.leaders.map(leaderLine)),
    lines(
      'Vorbesprechung',
      f.prebriefing === 'online' ? `Online-Vorbesprechung${pb}.`
        : f.prebriefing === 'office' ? `Vorbesprechung in der Geschäftsstelle${pb}.`
          : 'Eine Vorbesprechung ist nicht erforderlich. Alle wichtigen Informationen erhaltet ihr rechtzeitig vor der Tour per E-Mail.',
    ),
    lines('Treffpunkt', `Treffpunkt: ${f.meeting_point ?? '…'}`, `Treffzeit: ${f.meet_time ? `${f.meet_time.slice(0, 5)} Uhr` : '…'}`),
    transport && lines('Öffentliche Anreise & Fahrgemeinschaften', transport, f.travel_notes),
    f.image_source === 'own' && f.image_credit,
  ])
}

function costLines(costs: Cost[], group: Cost['cost_group']): string[] {
  return costs.filter((c) => c.cost_group === group && c.label.trim()).map((c) => `- ${c.label}: ${c.quantity.toLocaleString('de-DE')} × ${eur(c.unit_price)} = ${eur(c.quantity * c.unit_price)}`)
}

// 7.3 Zusammenfassung (ohne Storno; Kontaktdaten nur mit Recht)
export function summaryText(t: TextInput, missingLabels: string[]): string {
  const f = effective(t)
  const c = t.calc
  const isCommunity = f.plan_type === 'community_tour'
  const helpers = t.leaders.filter((l) => l.rate_kind !== 'trainer').length
  const firstLeadIdx = t.leaders.findIndex((l) => l.role === 'lead')
  const firstLeadId = firstLeadIdx >= 0 ? t.leaderIds?.[firstLeadIdx] : undefined
  const contact = firstLeadId ? t.contacts?.[firstLeadId] : undefined
  const fee = isCommunity
    ? 'Gemeinschaftstour: keine Vergütung, keine Erstattung; Organisationspauschale trägt die Sektion'
    : `Vergütung Leitung: ${eur(c.fee_total)} (${f.plan_type === 'course' ? `${f.teaching_hours ?? 0} Lehreinheiten` : `${f.days_full ?? 0} Tagessätze, ${f.days_half ?? 0} Halbtagessätze`}${helpers ? `, davon ${helpers} mit Helfersatz` : ''})`
  const legs = t.legs.map((l) => {
    const factor = t.efs[`ef_${l.mode}`] ?? 0
    const vehicle = ['car', 'ecar', 'van'].includes(l.mode)
    const amount = (l.km_one_way * (l.round_trip ? 2 : 1) * (vehicle ? l.vehicles : l.persons) * factor) / 1000
    return `- ${TRANSPORT_LABELS[l.mode]}${l.label ? ` (${l.label})` : ''}: ${l.km_one_way.toLocaleString('de-DE')} km ${l.round_trip ? 'hin und zurück' : 'einfach'}, ${vehicle ? `${l.vehicles} Fahrzeug(e), ` : ''}${l.persons} Personen = ${kg(amount)}`
  })
  const confirms = [
    !isCommunity && `Lizenz ${f.confirm_license ? 'bestätigt' : 'nicht bestätigt'}`,
    !isCommunity && `Abrechnung ${f.confirm_calculation ? 'bestätigt' : 'nicht bestätigt'}`,
    !isCommunity && `ÜL-Erklärung ${f.confirm_ul_declaration ? 'bestätigt' : 'nicht bestätigt'}`,
    `Notfallkarte ${f.confirm_emergency_card ? 'bestätigt' : 'nicht bestätigt'}`,
  ].filter(Boolean)
  return joinBlocks([
    lines(
      `TOURENKONZEPT: ${f.title || '(ohne Titel)'}`,
      `Erstellt am ${plainDate(t.today)}`,
      `Yolawo-Eingabe durch: ${f.yolawo_by === 'leader' ? 'Tourenleitung (selbst)' : 'Tourenreferat'}`,
      missingLabels.length ? `Noch unvollständig. Es fehlen: ${missingLabels.join(', ')}` : 'Vollständig ausgefüllt.',
    ),
    lines(
      'LEITUNG',
      ...t.leaders.map((l) => `- ${l.name}, ${l.license_name ?? 'ohne Lizenz'}, ${ROLE_LABELS[l.role]}${l.license_valid_until ? `, Lizenz bis ${plainDate(l.license_valid_until)}` : ''}`),
      t.contacts !== undefined && `Kontakt: ${[contact?.email, contact?.mobile].filter(Boolean).join(', ') || 'FEHLT'}`,
      t.contacts !== undefined && `Notfallkontakt Tourenleitung: ${contact?.emergency_name ? `${contact.emergency_name}, ${contact.emergency_phone ?? ''}` : 'FEHLT'}`,
      isCommunity && f.community_reason && `Begründung Gemeinschaftstour: ${f.community_reason}`,
    ),
    lines('YOLAWO-FELDER', ...yolawoFields(t).map((y) => `${y.group} · ${y.field}: ${(y.value ?? 'FEHLT').replace(/\n/g, ' / ')}`)),
    lines(
      'KALKULATION',
      fee,
      !isCommunity && t.costs.some((x) => x.cost_group === 'leader' && x.is_car) && `PKW-Begründung: ${f.car_reason ?? 'FEHLT'}`,
      `Organisationspauschale: ${eur(c.org_total)} (${f.org_days ?? 0} Tage)`,
      !isCommunity && costLines(t.costs, 'leader').length > 0 && `Kosten der Leitung: ${eur(c.leader_costs)}\n${costLines(t.costs, 'leader').join('\n')}`,
      !isCommunity && costLines(t.costs, 'fixed').length > 0 && `Sonstige Tourkosten: ${eur(c.fixed_costs)}\n${costLines(t.costs, 'fixed').join('\n')}`,
      !isCommunity && costLines(t.costs, 'per_participant').length > 0 && `Leistungen je TN: ${eur(c.per_participant_costs)}\n${costLines(t.costs, 'per_participant').join('\n')}`,
      `Gesamtkosten (fix): ${eur(c.total_costs)}`,
      isCommunity ? null
        : c.is_free ? 'Teilnahmebeitrag: ohne Beitrag (Familienwanderung als Tagestour)'
          : lines(
              `Kostendeckender Beitrag bei ${f.min_participants ?? '?'} TN: ${eur(c.price_suggested)}${c.price_raw !== null ? ` (rechnerisch ${eur(c.price_raw)} inkl. Zahlungsgebühren${c.fee_method ? `, ${PAYMENT_LABELS[c.fee_method] ?? c.fee_method}` : ''})` : ''}`,
              `Gewählter Beitrag: ${eur(c.price_member_effective)} Mitglieder${f.non_members_allowed ? ` / ${eur(c.price_non_member_effective)} Nichtmitglieder` : ''}`,
              `Kostendeckung ab ${c.break_even ?? '?'} TN; Ergebnis bei ${f.min_participants ?? '?'} TN: ${eur(c.result_min)}, bei ${f.max_participants ?? '?'} TN: ${eur(c.result_max)}`,
            ),
      isCommunity && `Sektion trägt: ${eur(c.section_bears)}`,
    ),
    lines(
      'CO2-BILANZ (Planung)',
      ...legs,
      `An- und Abreise: ${kg(c.co2_mobility_kg)}`,
      f.accommodation !== 'none' && `Unterkunft: ${kg(c.co2_stay_kg)} (${f.nights ?? 0} Nächte, ${ACCOMMODATION_LABELS[f.accommodation]}${f.accommodation === 'hut' ? ', wird der Hütten-Sektion zugerechnet' : ''})`,
      `Verpflegung: ${kg(c.co2_food_kg)}`,
      `Tour gesamt (Sektionsbilanz): ${kg(c.co2_tour_kg)}; je Person ${kg(c.co2_per_person_kg)} bei ${f.co2_persons ?? '?'} Personen`,
      `Klimaschutzbudget${t.co2Price !== null ? ` bei ${t.co2Price.toLocaleString('de-DE')} €/t` : ''}: ${eur(c.climate_budget_eur)}`,
      `Treffpunkt ≤ 1,5 km von ÖPV-Haltestelle: ${f.meeting_near_pt ? 'ja' : 'nein'}`,
    ),
    lines(
      'INTERN',
      f.non_members_allowed ? `Ausnahme Nichtmitglieder: ${f.non_members_reason ?? 'Begründung FEHLT'}` : 'Teilnahme: nur DAV-Mitglieder',
      `Stornobedingungen Unterkunft: ${f.accommodation_cancellation ?? '–'}`,
      `Hinweise: ${f.notes_for_referat ?? '–'}`,
      `Bestätigungen: ${confirms.join(', ')}`,
      `Feedbackbogen nach der Tour: ${f.feedback_form ? 'ja' : 'nein'}`,
    ),
    `––– AUSSCHREIBUNGSTEXT –––\n${descText(t)}`,
  ])
}
