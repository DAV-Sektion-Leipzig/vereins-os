// Bezeichnungen der Planungshilfe (spec.md TK 2 „Typen“, Prototyp Abschnitt 3 und 6). Code englisch, Oberfläche deutsch.
import type {
  Accommodation, CostGroup, Fitness, ImageSource, LeaderRole, PlanStatus, PlanType, Prebriefing, PublicTransport, Technique,
  Transport, YolawoBy,
} from '@/features/tk/types'

export const PLAN_TYPE_LABELS: Record<PlanType, string> = {
  guided_tour: 'Führungstour',
  course: 'Kurs / Ausbildungstour',
  community_tour: 'Gemeinschaftstour',
}

export const PLAN_TYPE_HINTS: Record<PlanType, string> = {
  guided_tour: 'Geführte Tour mit Teilnahmebeitrag; Referat Touren.',
  course: 'Kurs nach Lehreinheiten; Referat Ausbildung.',
  community_tour: 'Ohne Teilnahmebeitrag und Vergütung; nur Organisationspauschale.',
}

export const STATUS_LABELS: Record<PlanStatus, string> = {
  draft: 'Entwurf',
  submitted: 'eingereicht',
  query: 'Rückfrage',
  approved: 'freigegeben',
  published: 'in Yolawo angelegt',
  done: 'durchgeführt',
  closed: 'abgeschlossen',
  cancelled: 'abgesagt',
}
export const STATUSES = Object.keys(STATUS_LABELS) as PlanStatus[]

export const ROLE_LABELS: Record<LeaderRole, string> = { lead: 'Leitung', co_lead: 'Co-Leitung', helper: 'Helfer:in' }

export const TRANSPORT_LABELS: Record<Transport, string> = {
  rail_long: 'Bahn Fernverkehr',
  rail_regional: 'Bahn Nahverkehr',
  coach: 'Fernbus / Reisebus',
  local_bus: 'Linienbus Nahverkehr',
  tram: 'Straßenbahn / U-Bahn',
  car: 'PKW (Verbrenner)',
  ecar: 'PKW (Elektro)',
  van: 'Kleinbus / Sektionsbus',
  flight: 'Flug',
  bike: 'Fahrrad / zu Fuß',
}
export const VEHICLE_MODES: Transport[] = ['car', 'ecar', 'van']

export const ACCOMMODATION_LABELS: Record<Accommodation, string> = {
  none: 'keine Übernachtung',
  hut: 'DAV-Hütte',
  self_catering: 'Selbstversorgerhütte / Ferienwohnung',
  hotel: 'Pension / Hotel',
  camping: 'Zelt / Camping',
}

export const PREBRIEFING_LABELS: Record<Prebriefing, string> = {
  none: 'Nicht erforderlich, Infos per E-Mail',
  online: 'Online',
  office: 'In der Geschäftsstelle',
}

export const PUBLIC_TRANSPORT_LABELS: Record<PublicTransport, string> = {
  together: 'Gemeinsame Anreise mit Bahn/Bus geplant',
  possible: 'Möglich, jede:r reist selbst an',
  not_possible: 'Nicht sinnvoll möglich',
}

export const IMAGE_LABELS: Record<ImageSource, string> = {
  own: 'Eigenes Foto, wird mitgeschickt',
  referat: 'Referat wählt ein Bild',
}

export const FITNESS_LABELS: Record<Fitness, string> = { low: 'gering', medium: 'mittel', high: 'groß', very_high: 'sehr groß' }
export const TECHNIQUE_LABELS: Record<Technique, string> = {
  easy: 'leicht',
  medium: 'mittel',
  hard: 'schwer',
  very_hard: 'sehr schwer',
}
export const TECHNIQUE_HINTS: Record<Technique, string> = {
  easy: 'blaue Wege, T1, bis UIAA III, Klettersteig A/B',
  medium: 'rote Wege, T2–T3, bis UIAA IV, Klettersteig C, Hochtour L/WS',
  hard: 'schwarze Wege, T4, bis UIAA VI, Klettersteig D, Hochtour ZS',
  very_hard: 'alpine Routen, T5–T6, darüber, Klettersteig E, S und schwerer',
}

export const YOLAWO_LABELS: Record<YolawoBy, string> = {
  referat: 'Das Tourenreferat',
  leader: 'Ich selbst, mit eigenem Yolawo-Zugang',
}

export const COST_GROUP_LABELS: Record<CostGroup, string> = {
  leader: 'Kosten der Leitung',
  fixed: 'Sonstige Tourkosten',
  per_participant: 'Im Beitrag enthaltene Leistungen je Teilnehmer:in',
  self_paid: 'Selbst zu zahlen',
}

export const SPORTS = [
  'Wandern', 'Sport- und Langstreckenwandern', 'Bergwandern', 'Bergsteigen', 'Klettersteig', 'Klettern', 'Alpinklettern',
  'Bouldern', 'Hochtour', 'Skitour', 'Schneeschuhtour', 'Skilanglauf', 'Ski alpin', 'Mountainbike', 'Sonstiges',
]

export const TARGET_GROUPS: { value: string; label: string }[] = [
  { value: 'Familienwanderungen', label: 'Familie' },
  { value: 'Flinke Füße', label: 'Flinke Füße' },
  { value: 'Einsteiger', label: 'Einsteiger:innen' },
  { value: 'FLINTA*', label: 'FLINTA*' },
]

export const REGISTRATION_QUESTIONS: { value: string; label: string }[] = [
  { value: 'DAV-Mitgliedschaft (Sektion Leipzig / andere Sektion / kein Mitglied)', label: 'DAV-Mitgliedschaft' },
  { value: 'Mitgliedsnummer', label: 'Mitgliedsnummer' },
  { value: 'Mobilnummer', label: 'Mobilnummer' },
  { value: 'Notfallkontakt (Name, Telefon)', label: 'Notfallkontakt' },
  { value: 'Geburtsdatum', label: 'Geburtsdatum' },
  { value: 'Hinweise an die Tourenleitung (z. B. gesundheitlich)', label: 'Hinweise an die Leitung' },
  { value: 'Verpflegungswunsch (z. B. vegetarisch)', label: 'Verpflegung' },
  { value: 'Bahn-Ermäßigung (BahnCard, Deutschlandticket)', label: 'Bahn-Ermäßigung' },
  { value: 'Einwilligung: Kontaktdaten für Fahrgemeinschaften weitergeben', label: 'Fahrgemeinschaften' },
  { value: 'Einwilligung: Ausschreibung und Voraussetzungen gelesen', label: 'Voraussetzungen gelesen' },
  {
    value: 'Tourenerfahrung: bisherige Touren mit Ziel, Schwierigkeit, geführt/selbst organisiert (Textfeld)',
    label: 'Tourenerfahrung',
  },
]

export const PAYMENT_LABELS: Record<string, string> = {
  fee_sepa: 'SEPA-Lastschrift',
  fee_card: 'Kredit- / Debitkarte',
  fee_paypal: 'PayPal',
  fee_klarna: 'Klarna',
  fee_transfer: 'Überweisung',
}

/** Schritte 1–7 (Prototyp Abschnitt 3) mit den Pflichtangaben (Schlüssel aus tk_plan_results.missing). */
export const STEPS: { n: number; title: string; keys: string[] }[] = [
  { n: 1, title: 'Leitung', keys: ['leader', 'community_reason', 'contact_email', 'emergency_name', 'emergency_phone'] },
  { n: 2, title: 'Ausschreibung', keys: ['sport', 'region', 'teaser', 'image_source', 'image_credit'] },
  { n: 3, title: 'Termin & Anreise', keys: ['start_date', 'meet_time', 'end_date', 'meeting_point', 'public_transport', 'travel_legs'] },
  { n: 4, title: 'Anforderungen', keys: ['fitness', 'technique', 'requirements', 'non_members_reason', 'equipment'] },
  { n: 5, title: 'Teilnahme', keys: ['min_participants', 'max_participants', 'registration_deadline'] },
  { n: 6, title: 'Kalkulation', keys: ['teaching_hours', 'car_reason'] },
  {
    n: 7,
    title: 'Einreichen',
    keys: ['confirm_license', 'confirm_calculation', 'confirm_ul_declaration', 'confirm_emergency_card'],
  },
]

/** Bezeichnung einer fehlenden Angabe (Prototyp 6.1); fehlende Sätze als „Satz …“. */
export const MISSING_LABELS: Record<string, string> = {
  leader: 'Leitung',
  community_reason: 'Begründung Gemeinschaftstour',
  contact_email: 'E-Mail Tourenleitung',
  emergency_name: 'Notfallkontakt Name',
  emergency_phone: 'Notfallkontakt Telefon',
  sport: 'Sportart',
  region: 'Gebiet / Region',
  teaser: 'Kurzbeschreibung',
  image_source: 'Titelbild',
  image_credit: 'Bildrechte',
  start_date: 'Beginn (Datum)',
  meet_time: 'Treffzeit',
  end_date: 'Ende (Datum)',
  meeting_point: 'Treffpunkt',
  public_transport: 'Anreise mit ÖPNV',
  travel_legs: 'Geplante An- und Abreise (CO2)',
  fitness: 'Kondition',
  technique: 'Technik',
  requirements: 'Voraussetzungen',
  non_members_reason: 'Begründung Nichtmitglieder',
  equipment: 'Ausrüstung',
  min_participants: 'Mindestanzahl Teilnehmende',
  max_participants: 'Höchstanzahl Teilnehmende',
  registration_deadline: 'Anmeldeschluss',
  teaching_hours: 'Lehreinheiten',
  car_reason: 'Begründung PKW-Fahrt',
  confirm_license: 'Bestätigung Lizenz',
  confirm_calculation: 'Bestätigung Kalkulation',
  confirm_ul_declaration: 'Bestätigung ÜL-Erklärung',
  confirm_emergency_card: 'Bestätigung Notfallkarte',
}

export function missingLabel(key: string, rateLabel?: (k: string) => string | undefined): string {
  if (key.startsWith('rate:')) {
    const k = key.slice(5)
    return `Satz ${rateLabel?.(k) ?? k}`
  }
  return MISSING_LABELS[key] ?? key
}

/** Schritt, zu dem eine fehlende Angabe gehört (fehlende Sätze → Kalkulation). */
export function stepOf(key: string): number {
  if (key.startsWith('rate:')) return 6
  return STEPS.find((s) => s.keys.includes(key))?.n ?? 7
}

/** Hinweise (Prototyp 6.2, 6.3; spec.md R2, R6). */
export const WARNING_LABELS: Record<string, string> = {
  helper_rate: 'Ohne gültige Lizenz wird der Helfersatz gerechnet.',
  license_expires_during: 'Eine Lizenz läuft während der Tour ab – Verlängerung für künftige Touren nötig.',
  license_acquired_in_half: 'Lizenz im Halbjahr des Beginns erworben – Trainersatz für das ganze Halbjahr.',
  rate_kind_no_start: 'Für die Satzart fehlt der Beginn.',
  no_fee_not_allowed: 'Ohne Teilnahmebeitrag nur bei einer Familienwanderung als Tagestour.',
  price_below_suggestion: 'Beitrag liegt unter dem kostendeckenden Vorschlag.',
  flight_short: 'Flug unter der Mindestentfernung: nach DAV-Selbstverpflichtung ausgeschlossen.',
  car_pooling: 'PKW-Fahrgemeinschaften möglichst mit mindestens 3 Personen je Fahrzeug (erst ÖPV, dann Fahrgemeinschaft).',
  car_over_guideline: 'Die PKW-Strecke liegt über dem Leipziger Richtwert. Bitte prüfe eine Anreise mit Bahn und Bus oder begründe die Entfernung in den Hinweisen.',
  hut_stay_excluded: 'Übernachtungen auf DAV-Hütten rechnet das DAV-Bilanzierungstool der Hütten-Sektion zu; sie zählen nicht zum Klimaschutzbudget.',
  fitness_differs: 'Nach Gehzeit und Höhenmetern passt eine andere Kondition.',
  min_gt_max: 'Mindestanzahl ist größer als Höchstanzahl.',
  deadline_not_before_start: 'Anmeldeschluss liegt nicht vor Tourbeginn.',
  lead_time_short: 'Weniger als 6 Monate bis Tourbeginn.',
  car_permit: 'PKW über 500 km: vorher vom geschäftsführenden Vorstand genehmigen lassen.',
  overnight_over_limit: 'Übernachtung über dem Höchstsatz pro Nacht: vorher Zustimmung einholen.',
  hut_free_place: 'Auf Alpenvereinshütten übernachtet die Leitung ab 5 Teilnehmenden kostenlos („5 plus 1“). Prüfe die Übernachtungskosten der Leitung.',
  hut_hp_price: 'Übernachtung mit Halbpension auf Alpenvereinshütten kostet meist 60–68 € pro Nacht. Bitte den Wert prüfen.',
  sport_not_covered: 'Keine der Qualifikationen der Leitung deckt die Sportart ab. Bitte Qualifikation, Sportart oder Tourtyp prüfen.',
  rates_missing: 'Für mindestens einen Satz fehlt ein Wert zum Beginn. Bitte den Admin informieren.',
}

/** Felder, deren Änderung ab „freigegeben“ im Verlauf steht (R19). */
export const TRACKED_FIELD_LABELS: Record<string, string> = {
  start_date: 'Beginn',
  end_date: 'Ende',
  meet_time: 'Treffzeit',
  end_time: 'Ende (Uhrzeit)',
  leaders: 'Leitung',
  price_member: 'Beitrag Mitglieder',
  price_non_member: 'Beitrag Nichtmitglieder',
  total_costs: 'Gesamtkosten',
}

export const HISTORY_LABELS: Record<string, string> = {
  created: 'angelegt',
  copied: 'als Kopie angelegt',
  saved: 'geändert',
  submitted: 'eingereicht',
  query: 'Rückfrage',
  resubmitted: 'erneut eingereicht',
  approved: 'freigegeben',
  published: 'in Yolawo angelegt',
  cancelled: 'abgesagt',
  done: 'durchgeführt',
  closed: 'abgeschlossen',
  contacts_purged: 'Kontakt- und Notfalldaten gelöscht',
  ez_locked: 'Einsatz nicht aktualisiert (schon erfasst oder abgerechnet)',
  ez_sync_failed: 'Einsatz konnte nicht aktualisiert werden',
}

const money = new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' })
const moneyWhole = new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 })
const number = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 })

export function formatMoney(value: number | null | undefined, whole = false): string {
  if (value === null || value === undefined || Number.isNaN(value)) return '–'
  return (whole ? moneyWhole : money).format(value)
}

export function formatNumber(value: number | null | undefined): string {
  if (value === null || value === undefined || Number.isNaN(value)) return '–'
  return number.format(value)
}

export function formatKg(value: number | null | undefined): string {
  if (value === null || value === undefined || Number.isNaN(value)) return '–'
  return `${number.format(Math.round(value * 10) / 10)} kg`
}
