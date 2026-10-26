// Abrechnungsarten mit Positionen und Vorbelegung je Einsatzart (spec.md AD v0.10, R51, R52; T129).
// Pflege nur Admin (RLS); Regeln prüft die Datenbank (Trigger).
import { loadRates, ratesAt, type Rate } from '@/features/ad/saetze/data'
import { KIND_LABELS, KINDS, type EventKind, type Span } from '@/features/ez/labels'
import { requireLevel } from '@/lib/rights'
import { supabase } from '@/lib/supabase'
import { todayIso } from '@/lib/format'

export type PositionCode = 'training_unit' | 'day' | 'half_day' | 'competition_day' | 'organization_day' | 'teaching_unit'

export const POSITION_LABELS: Record<PositionCode, string> = {
  training_unit: 'Trainingseinheit',
  day: 'Tagessatz',
  half_day: 'Halbtagessatz',
  competition_day: 'Satz je Tag (Wettkampfbetreuung)',
  organization_day: 'Organisationspauschale je Tag',
  teaching_unit: 'Lehreinheit',
}

export const POSITIONS = Object.keys(POSITION_LABELS) as PositionCode[]

/** Organisationspauschale und Lehreinheit nur „ohne Rolle“, übrige mit Trainer:in und Helfer:in (R51). */
export function isNoRolePosition(position: PositionCode) {
  return position === 'organization_day' || position === 'teaching_unit'
}

export type RemunerationKind = { id: string; code: string; name: string; is_active: boolean; sort_order: number; source: string }
export type RemunerationPosition = {
  id: string
  kind_id: string
  position: PositionCode
  rate_key_trainer: string | null
  rate_key_helper: string | null
  rate_key_none: string | null
}
export type RemunerationDefault = { id: string; event_kind: EventKind; span: Span; kind_id: string | null; valid_from: string }

export type RemunerationData = {
  kinds: RemunerationKind[]
  positions: RemunerationPosition[]
  defaults: RemunerationDefault[]
  rates: Rate[]
  failed: boolean
}

export async function loadRemuneration(): Promise<RemunerationData> {
  await requireLevel('AD', 'read')
  const [kinds, positions, defaults, rates] = await Promise.all([
    supabase.from('ad_remuneration_kinds').select('id, code, name, is_active, sort_order, source').order('sort_order'),
    supabase.from('ad_remuneration_positions').select('id, kind_id, position, rate_key_trainer, rate_key_helper, rate_key_none'),
    supabase.from('ad_remuneration_defaults').select('id, event_kind, span, kind_id, valid_from').order('valid_from', { ascending: false }),
    loadRates(),
  ])
  if (kinds.error || positions.error || defaults.error || rates.failed) {
    return { kinds: [], positions: [], defaults: [], rates: [], failed: true }
  }
  return {
    kinds: kinds.data as RemunerationKind[],
    positions: positions.data as RemunerationPosition[],
    defaults: defaults.data as RemunerationDefault[],
    rates: rates.rates,
    failed: false,
  }
}

/** Einsatzart und ein-/mehrtägig wie ez_events_shape (R52). */
export const DEFAULT_SLOTS: { kind: EventKind; span: Span }[] = KINDS.flatMap((kind): { kind: EventKind; span: Span }[] => {
  if (kind === 'training' || kind === 'day_trip') return [{ kind, span: 'single' as Span }]
  if (kind === 'multi_day_trip' || kind === 'training_camp') return [{ kind, span: 'multi' as Span }]
  return [
    { kind, span: 'single' as Span },
    { kind, span: 'multi' as Span },
  ]
})

export function slotLabel(kind: EventKind, span: Span) {
  const base = KIND_LABELS[kind]
  if (kind === 'training' || kind === 'day_trip' || kind === 'multi_day_trip' || kind === 'training_camp') return base
  return `${base} (${span === 'single' ? 'eintägig' : 'mehrtägig'})`
}

/** Vorbelegung mit dem spätesten „gültig ab“ ≤ Stichtag (wie ad_remuneration_default_at). */
export function defaultAt(defaults: RemunerationDefault[], kind: EventKind, span: Span, day = todayIso()) {
  return defaults
    .filter((d) => d.event_kind === kind && d.span === span && d.valid_from <= day)
    .sort((a, b) => b.valid_from.localeCompare(a.valid_from))[0]
}

/** Sätze der Gruppe Vergütung, je Schlüssel der heute gültige Wert (Auswahl für Positionen). */
export function remunerationRates(rates: Rate[]): Rate[] {
  return [...ratesAt(rates, todayIso()).values()]
    .filter((r) => r.rate_group === 'remuneration')
    .sort((a, b) => a.label.localeCompare(b.label, 'de'))
}

export async function saveKind(id: string | null, fields: { code: string; name: string; is_active: boolean; source: string; sort_order: number }) {
  if (id) {
    return supabase
      .from('ad_remuneration_kinds')
      .update({ name: fields.name.trim(), is_active: fields.is_active, source: fields.source.trim() })
      .eq('id', id)
  }
  return supabase.from('ad_remuneration_kinds').insert({
    code: fields.code.trim().toUpperCase(),
    name: fields.name.trim(),
    is_active: fields.is_active,
    source: fields.source.trim(),
    sort_order: fields.sort_order,
  })
}

export async function savePosition(
  existing: RemunerationPosition | null,
  kindId: string,
  position: PositionCode,
  keys: { trainer: string; helper: string; none: string },
) {
  const values = isNoRolePosition(position)
    ? { rate_key_trainer: null, rate_key_helper: null, rate_key_none: keys.none || null }
    : { rate_key_trainer: keys.trainer || null, rate_key_helper: keys.helper || null, rate_key_none: null }
  if (existing) return supabase.from('ad_remuneration_positions').update(values).eq('id', existing.id)
  return supabase.from('ad_remuneration_positions').insert({ kind_id: kindId, position, ...values })
}

export async function saveDefault(kind: EventKind, span: Span, kindId: string | null, validFrom: string) {
  return supabase
    .from('ad_remuneration_defaults')
    .insert({ event_kind: kind, span, kind_id: kindId, valid_from: validFrom })
}
