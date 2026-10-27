// Qualifikationsarten (US-AD-17, US-AD-18; T077–T079) über PostgREST; Regeln R21–R26 prüft die Datenbank.
// Die Komponenten sind so gebaut, dass /ea/qualifikationsarten sie mit EA ohne Änderung einhängt.
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import { canEditQualificationTypes, requireTypesAccess, type TypesGate } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type QualificationKind = 'license' | 'add_on' | 'course' | 'training'
export type LicenseLevel = 'pre' | 'C' | 'B' | 'A' | 'none'
export type QualificationStatus = 'current' | 'historic'

export type QualificationType = {
  id: string
  code: string | null
  name: string
  discipline: string
  kind: QualificationKind
  level: LicenseLevel | null
  specification: string | null
  issuer: string
  dosb_eligible: boolean | null
  validity_years: number | null
  status: QualificationStatus
  note: string | null
  source_ref: string | null
  created_at: string
  updated_at: string | null
  updated_by: string | null
}

export const KIND_LABELS: Record<QualificationKind, string> = {
  license: 'Lizenz',
  add_on: 'Zusatzqualifikation',
  course: 'Lehrgang',
  training: 'Weiterbildung',
}

export const LEVEL_LABELS: Record<LicenseLevel, string> = {
  pre: 'Vorstufe',
  C: 'C',
  B: 'B',
  A: 'A',
  none: 'ohne Stufe',
}

export const STATUS_LABELS: Record<QualificationStatus, string> = {
  current: 'aktuell',
  historic: 'historisch',
}

export const KINDS = Object.keys(KIND_LABELS) as QualificationKind[]
export const LEVELS = Object.keys(LEVEL_LABELS) as LicenseLevel[]

/** Gültigkeitsdauer je Typ (R24): Pflicht, optional oder ausgeblendet. */
export function validityRule(kind: QualificationKind): 'required' | 'optional' | 'hidden' {
  if (kind === 'license') return 'required'
  if (kind === 'training') return 'optional'
  return 'hidden'
}

/** Anzeige „Kürzel – Bezeichnung“, historische mit Zusatz (R25). */
export function qualificationLabel(q: Pick<QualificationType, 'code' | 'name' | 'status'>) {
  const base = q.code ? `${q.code} – ${q.name}` : q.name
  return q.status === 'historic' ? `${base} (historisch)` : base
}

const COLUMNS =
  'id, code, name, discipline, kind, level, specification, issuer, dosb_eligible, validity_years, status, note, source_ref, created_at, updated_at, updated_by'

export type ListResult = {
  items: QualificationType[]
  canEdit: boolean
  /** Personen mit aktueller Eigenschaft je Qualifikationsart (ad_qualification_usage_all); null, wenn nicht abrufbar */
  usage: Record<string, number> | null
  failed: boolean
}

/** Pfade je Modul (T052): unter /ad bzw. /ea dieselben Seiten. */
export const QUALIFICATION_TYPES_PATH: Record<TypesGate, string> = {
  AD: '/ad/qualifikationsarten',
  EA: '/ea/qualifikationsarten',
}

export const loadQualificationTypes = qualificationTypesLoader('AD')

export function qualificationTypesLoader(gate: TypesGate) {
  return () => loadQualificationTypesFor(gate)
}

async function loadQualificationTypesFor(gate: TypesGate): Promise<ListResult> {
  await requireTypesAccess(gate)
  const [list, canEdit, usage] = await Promise.all([
    supabase.from('ad_qualification_types').select(COLUMNS).order('discipline').order('name'),
    canEditQualificationTypes(),
    loadUsageAll(),
  ])
  if (list.error) return { items: [], canEdit, usage: null, failed: true }
  return { items: list.data as QualificationType[], canEdit, usage, failed: false }
}

type UsageRow = { qualification_type_id: string; persons: number }

/** Spalte „Personen“: nur die Zahl je Art; ohne Recht (AD_FORBIDDEN) bleibt die Spalte leer. */
async function loadUsageAll(): Promise<Record<string, number> | null> {
  const { data, error } = await supabase.rpc('ad_qualification_usage_all')
  if (error || !Array.isArray(data)) return null
  return Object.fromEntries((data as UsageRow[]).map((r) => [r.qualification_type_id, r.persons]))
}

export type EditResult = {
  item: QualificationType | null
  canEdit: boolean
  usage: number | null
  updatedByName: string | null
  /** Vorschläge für Sparte und Aussteller aus vorhandenen Werten */
  disciplines: string[]
  issuers: string[]
  failed: boolean
}

async function loadSuggestions() {
  const { data } = await supabase.from('ad_qualification_types').select('discipline, issuer')
  const disciplines = [...new Set((data ?? []).map((r) => r.discipline as string))].sort((a, b) => a.localeCompare(b, 'de'))
  const issuers = [...new Set((data ?? []).map((r) => r.issuer as string))].sort((a, b) => a.localeCompare(b, 'de'))
  return { disciplines, issuers }
}

export const loadNewQualificationType = newQualificationTypeLoader('AD')

export function newQualificationTypeLoader(gate: TypesGate) {
  return () => loadNewQualificationTypeFor(gate)
}

async function loadNewQualificationTypeFor(gate: TypesGate): Promise<EditResult> {
  await requireTypesAccess(gate)
  const canEdit = await canEditQualificationTypes()
  if (!canEdit) throw redirect('/kein-zugriff')
  const suggestions = await loadSuggestions()
  return { item: null, canEdit, usage: null, updatedByName: null, ...suggestions, failed: false }
}

export const loadQualificationType = qualificationTypeLoader('AD')

export function qualificationTypeLoader(gate: TypesGate) {
  return (args: LoaderFunctionArgs) => loadQualificationTypeFor(gate, args)
}

async function loadQualificationTypeFor(gate: TypesGate, { params }: LoaderFunctionArgs): Promise<EditResult> {
  await requireTypesAccess(gate)
  const id = params.id!
  const [item, canEdit, suggestions] = await Promise.all([
    supabase.from('ad_qualification_types').select(COLUMNS).eq('id', id).maybeSingle(),
    canEditQualificationTypes(),
    loadSuggestions(),
  ])
  if (item.error) return { item: null, canEdit, usage: null, updatedByName: null, disciplines: [], issuers: [], failed: true }
  if (!item.data) throw redirect(QUALIFICATION_TYPES_PATH[gate])

  const row = item.data as QualificationType
  const [usage, updatedByName] = await Promise.all([
    canEdit ? supabase.rpc('ad_qualification_usage', { p_id: id }).then((r) => (r.error ? null : (r.data as number))) : null,
    row.updated_by ? loadUserName(row.updated_by) : null,
  ])
  return { item: row, canEdit, usage, updatedByName, ...suggestions, failed: false }
}

// Name zu einem Auth-Nutzer über Zugang → Person (nur mit AD ≥ lesen lesbar; sonst null)
async function loadUserName(userId: string): Promise<string | null> {
  const access = await supabase.from('ad_accesses').select('person_id').eq('auth_user_id', userId).maybeSingle()
  if (access.error || !access.data) return null
  const person = await supabase
    .from('ea_persons')
    .select('first_name, preferred_name, last_name')
    .eq('id', access.data.person_id)
    .maybeSingle()
  if (person.error || !person.data) return null
  const { first_name, preferred_name, last_name } = person.data
  return `${preferred_name?.trim() || first_name} ${last_name}`
}

export type SaveInput = {
  code: string
  name: string
  discipline: string
  kind: QualificationKind
  level: LicenseLevel | ''
  specification: string
  issuer: string
  dosb_eligible: '' | 'true' | 'false'
  validity_years: string
  status: QualificationStatus
  note: string
}

export type SaveResult = { id: string | null; error: unknown }

function toRow(input: SaveInput) {
  const rule = validityRule(input.kind)
  const validity = input.validity_years.trim() === '' ? null : Number(input.validity_years)
  return {
    code: input.code.trim() || null,
    name: input.name,
    discipline: input.discipline,
    kind: input.kind,
    level: input.kind === 'license' && input.level ? input.level : null,
    specification: input.specification.trim() || null,
    issuer: input.issuer.trim() || 'Bundesverband',
    dosb_eligible: input.dosb_eligible === '' ? null : input.dosb_eligible === 'true',
    validity_years: rule === 'hidden' ? null : Number.isFinite(validity) ? validity : null,
    status: input.status,
    note: input.note.trim() || null,
  }
}

export async function saveQualificationType(id: string | null, input: SaveInput): Promise<SaveResult> {
  const row = toRow(input)
  if (!id) {
    const { data, error } = await supabase.from('ad_qualification_types').insert(row).select('id').single()
    return { id: data?.id ?? null, error }
  }
  const { error } = await supabase.from('ad_qualification_types').update(row).eq('id', id)
  return { id, error }
}
