// Sätze und Pauschalen (spec.md AD v0.10, R46; T129) über PostgREST; Pflege nur Admin (RLS), lesen mit AD ≥ lesen.
import { requireLevel } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type RateGroup = 'remuneration' | 'travel' | 'fee' | 'payment_fee' | 'climate' | 'threshold'

export const GROUP_LABELS: Record<RateGroup, string> = {
  remuneration: 'Vergütung',
  travel: 'Reisekosten',
  fee: 'Beitrag und Rundung',
  payment_fee: 'Zahlungsgebühren',
  climate: 'Klima und Emissionsfaktoren',
  threshold: 'Grenzwerte',
}

export const GROUPS = Object.keys(GROUP_LABELS) as RateGroup[]

export type Rate = {
  id: string
  rate_key: string
  label: string
  rate_group: RateGroup
  unit: string
  value: number | null
  percent: number | null
  fixed: number | null
  active: boolean
  valid_from: string
  source: string
  note: string | null
}

export type RatesData = { rates: Rate[]; failed: boolean }

export async function loadRates(): Promise<RatesData> {
  await requireLevel('AD', 'read')
  const { data, error } = await supabase
    .from('ad_rates')
    .select('id, rate_key, label, rate_group, unit, value, percent, fixed, active, valid_from, source, note')
    .order('rate_key')
    .order('valid_from', { ascending: false })
  if (error) return { rates: [], failed: true }
  return { rates: data as Rate[], failed: false }
}

/** Je Schlüssel die Zeile mit dem spätesten „gültig ab“ ≤ Stichtag (wie ad_rates_at). */
export function ratesAt(rates: Rate[], day: string): Map<string, Rate> {
  const result = new Map<string, Rate>()
  for (const rate of rates) {
    if (rate.valid_from > day) continue
    const current = result.get(rate.rate_key)
    if (!current || current.valid_from < rate.valid_from) result.set(rate.rate_key, rate)
  }
  return result
}

const numberFormat = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 4 })
const moneyFormat = new Intl.NumberFormat('de-DE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

export function formatNumber(value: number, unit?: string): string {
  return unit === '€' ? `${moneyFormat.format(value)} €` : `${numberFormat.format(value)}${unit ? ` ${unit}` : ''}`
}

export function formatRate(rate: Pick<Rate, 'rate_group' | 'value' | 'percent' | 'fixed' | 'unit' | 'active'>): string {
  if (rate.rate_group === 'payment_fee') {
    const text = `${numberFormat.format(rate.percent ?? 0)} % + ${moneyFormat.format(rate.fixed ?? 0)} € fix`
    return rate.active ? text : `${text} (inaktiv)`
  }
  return rate.value === null ? '–' : formatNumber(rate.value, rate.unit)
}

/** Zahl aus einer Eingabe mit Komma oder Punkt; leer → null, ungültig → NaN. */
export function parseNumber(text: string): number | null {
  const trimmed = text.trim()
  if (!trimmed) return null
  // „1.234,56“ und „6,5“ deutsch, „6.5“ mit Punkt als Dezimaltrenner
  return Number(trimmed.includes(',') ? trimmed.replace(/\./g, '').replace(',', '.') : trimmed)
}

export type NewRateInput = {
  base: Rate
  value: number | null
  percent: number | null
  fixed: number | null
  active: boolean
  validFrom: string
  source: string
  note: string
}

/** Neuer Wert als neue Zeile mit „gültig ab“ (R46); Schlüssel, Bezeichnung, Gruppe und Einheit wie bisher. */
export async function saveNewRate(input: NewRateInput) {
  const isFee = input.base.rate_group === 'payment_fee'
  return supabase.from('ad_rates').insert({
    rate_key: input.base.rate_key,
    label: input.base.label,
    rate_group: input.base.rate_group,
    unit: input.base.unit,
    value: isFee ? null : input.value,
    percent: isFee ? input.percent : null,
    fixed: isFee ? input.fixed : null,
    active: input.active,
    valid_from: input.validFrom,
    source: input.source.trim(),
    note: input.note.trim() || null,
  })
}
