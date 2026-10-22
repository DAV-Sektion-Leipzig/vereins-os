// Eigenschaftsarten mit Feldern (US-AD-12, US-AD-19, US-AD-22; T080, T081).
// Gespeichert wird über ea_save_property_type (Art und Felder in einer Transaktion, R9, R36);
// Lesestufe „vertraulich“ nur mit AD ≥ bearbeiten (R29), Bezug „Gruppe“ nur mit GR = verwalten.
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import type { QualificationKind } from '@/features/ad/qualifikationsarten/data'
import { hasLevel, requireLevel, type ModuleCode } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type DataType = 'text' | 'number' | 'date' | 'year' | 'boolean' | 'choice' | 'qualification_type'
export type ReadLevel = 'all' | 'office' | 'confidential'
export type RelationKind = 'none' | 'referat' | 'gremium' | 'group'
export type Category =
  | 'master_data'
  | 'contact'
  | 'assignment'
  | 'qualification'
  | 'proof'
  | 'yearly'
  | 'issue'
  | 'external_access'
  | 'other'

export const DATA_TYPE_LABELS: Record<DataType, string> = {
  text: 'Text',
  number: 'Zahl',
  date: 'Datum',
  year: 'Jahr',
  boolean: 'Ja/Nein',
  choice: 'Auswahlliste',
  qualification_type: 'Qualifikationsart',
}

export const READ_LEVEL_LABELS: Record<ReadLevel, string> = {
  all: 'alle mit Zugriff',
  office: 'nur Geschäftsstelle und Admin',
  confidential: 'vertraulich',
}

/** Erklärung je Lesestufe nach spec.md AD Abschnitt 3 (R29). */
export const READ_LEVEL_HINTS: Record<ReadLevel, string> = {
  all: 'Lesbar für alle, die die Person in ihrem Modul sehen dürfen.',
  office: 'Lesbar für die Geschäftsstelle (verwalten) und den Admin; Referent:innen sehen die Angabe nicht.',
  confidential: 'Lesbar nur mit Rechten auf die Administration, z. B. für Beschäftigtendaten.',
}

export const RELATION_LABELS: Record<RelationKind, string> = {
  none: 'kein Bezug',
  referat: 'Referat',
  gremium: 'Gremium',
  group: 'Gruppe',
}

export const CATEGORY_LABELS: Record<Category, string> = {
  master_data: 'Stammdaten',
  contact: 'Kontakt',
  assignment: 'Zuordnung',
  qualification: 'Qualifikationen',
  proof: 'Nachweise',
  yearly: 'Jahreseinträge',
  issue: 'Ausgaben',
  external_access: 'Zugänge',
  other: 'Sonstiges',
}

export const DATA_TYPES = Object.keys(DATA_TYPE_LABELS) as DataType[]
export const READ_LEVELS = Object.keys(READ_LEVEL_LABELS) as ReadLevel[]
export const CATEGORIES = Object.keys(CATEGORY_LABELS) as Category[]

export type PropertyType = {
  id: string
  name: string
  purpose: string
  category: Category
  read_level: ReadLevel
  relation_kind: RelationKind
  relation_required: boolean
  allow_multiple: boolean
  system_key: string | null
  visible_in: ModuleCode[]
  origin: 'system' | 'custom'
  valid_from_label: string | null
  valid_to_label: string | null
}

export type PropertyField = {
  id: string
  property_type_id: string
  key: string
  label: string
  data_type: DataType
  is_required: boolean
  choice_values: string[] | null
  allowed_qualification_kinds: QualificationKind[] | null
  sort_order: number
}

export type Module = { code: ModuleCode; name: string }

export type ListRow = PropertyType & { fieldCount: number }
export type ListResult = { items: ListRow[]; modules: Module[]; failed: boolean }

const TYPE_COLUMNS =
  'id, name, purpose, category, read_level, relation_kind, relation_required, allow_multiple, system_key, visible_in, origin, valid_from_label, valid_to_label'

async function loadModules() {
  const { data, error } = await supabase.from('ad_modules').select('code, name').order('sort_order')
  return error ? null : (data as Module[])
}

export async function loadPropertyTypes(): Promise<ListResult> {
  await requireLevel('AD', 'read')
  const [types, modules] = await Promise.all([
    supabase.from('ea_property_types').select(`${TYPE_COLUMNS}, ea_property_fields(count)`).order('name'),
    loadModules(),
  ])
  if (types.error || !modules) return { items: [], modules: [], failed: true }
  const items = (types.data as (PropertyType & { ea_property_fields: { count: number }[] })[]).map(
    ({ ea_property_fields, ...t }) => ({ ...t, fieldCount: ea_property_fields[0]?.count ?? 0 }),
  )
  return { items, modules, failed: false }
}

export type EditResult = {
  item: PropertyType | null
  fields: PropertyField[]
  modules: Module[]
  /** Eigenschaften dieser Art vorhanden: Datentyp, Bezug und neue Pflichtfelder gesperrt (R36) */
  inUse: boolean
  canEdit: boolean
  canConfidential: boolean
  canGroup: boolean
  failed: boolean
}

async function loadFlags() {
  const [canEdit, canConfidential, canGroup] = await Promise.all([
    hasLevel('AD', 'edit').then(async (ad) => ad || hasLevel('EA', 'manage')),
    hasLevel('AD', 'edit'),
    hasLevel('GR', 'manage'),
  ])
  return { canEdit, canConfidential, canGroup }
}

export async function loadNewPropertyType(): Promise<EditResult> {
  await requireLevel('AD', 'read')
  const [modules, flags] = await Promise.all([loadModules(), loadFlags()])
  if (!flags.canEdit) throw redirect('/kein-zugriff')
  if (!modules) return { item: null, fields: [], modules: [], inUse: false, ...flags, failed: true }
  return { item: null, fields: [], modules, inUse: false, ...flags, failed: false }
}

export async function loadPropertyType({ params }: LoaderFunctionArgs): Promise<EditResult> {
  await requireLevel('AD', 'read')
  const id = params.id!
  const [item, fields, modules, inUse, flags] = await Promise.all([
    supabase.from('ea_property_types').select(TYPE_COLUMNS).eq('id', id).maybeSingle(),
    supabase.from('ea_property_fields').select('*').eq('property_type_id', id).order('sort_order'),
    loadModules(),
    supabase.from('ea_properties').select('id', { count: 'exact', head: true }).eq('property_type_id', id),
    loadFlags(),
  ])
  if (item.error || fields.error || !modules) {
    return { item: null, fields: [], modules: [], inUse: false, ...flags, failed: true }
  }
  if (!item.data) throw redirect('/ad/eigenschaftsarten')
  return {
    item: item.data as PropertyType,
    fields: fields.data as PropertyField[],
    modules,
    inUse: (inUse.count ?? 0) > 0,
    ...flags,
    failed: false,
  }
}

export type FieldInput = {
  id: string | null
  key: string
  label: string
  data_type: DataType
  is_required: boolean
  choice_values: string[]
  allowed_qualification_kinds: QualificationKind[]
}

export type TypeInput = {
  name: string
  purpose: string
  category: Category
  read_level: ReadLevel
  relation_kind: RelationKind
  relation_required: boolean
  allow_multiple: boolean
  visible_in: ModuleCode[]
  valid_from_label: string
  valid_to_label: string
}

/** Schlüssel aus der Bezeichnung: Kleinbuchstaben, Umlaute aufgelöst, sonst Unterstrich; nach Anlage unveränderlich. */
export function suggestKey(label: string): string {
  const key = label
    .toLowerCase()
    .replace(/ä/g, 'ae')
    .replace(/ö/g, 'oe')
    .replace(/ü/g, 'ue')
    .replace(/ß/g, 'ss')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 40)
  return /^[a-z]/.test(key) ? key : key ? `f_${key}`.slice(0, 40) : ''
}

export type SaveResult = { id: string | null; error: unknown }

export async function savePropertyType(id: string | null, type: TypeInput, fields: FieldInput[]): Promise<SaveResult> {
  const p_type = {
    id: id ?? undefined,
    name: type.name.trim(),
    purpose: type.purpose,
    category: type.category,
    read_level: type.read_level,
    relation_kind: type.relation_kind,
    relation_required: type.relation_kind !== 'none' && type.relation_required,
    allow_multiple: type.allow_multiple,
    visible_in: type.visible_in,
    valid_from_label: type.valid_from_label,
    valid_to_label: type.valid_to_label,
  }
  const p_fields = fields.map((f) => ({
    id: f.id ?? undefined,
    key: f.key,
    label: f.label,
    data_type: f.data_type,
    is_required: f.is_required,
    choice_values: f.data_type === 'choice' ? f.choice_values : undefined,
    allowed_qualification_kinds:
      f.data_type === 'qualification_type' && f.allowed_qualification_kinds.length > 0 ? f.allowed_qualification_kinds : undefined,
  }))
  const { data, error } = await supabase.rpc('ea_save_property_type', { p_type, p_fields })
  return { id: (data as string | null) ?? id, error }
}
