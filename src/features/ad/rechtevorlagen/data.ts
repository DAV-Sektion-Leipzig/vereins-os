// Rechtevorlagen (US-AD-10, US-AD-20; T067–T069) über PostgREST; Rechte prüft die Datenbank (RLS, AK4, AK5).
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import { requireAdEdit } from '@/features/ad/access'
import { requireLevel, type Level, type ModuleCode, type Scope } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type Module = { code: ModuleCode; name: string }
export type TemplateRow = { id: string; name: string; description: string | null; personCount: number }
export type Template = { id: string; name: string; description: string | null }
export type Right = { level: Level; scope: Scope; approve: boolean }
export type Rights = Record<string, Right>

/** Reichweite „Referat“ nach R30 (Nachträge v0.8 und v0.10): Ehrenamtsmanagement, Anwesenheitserfassung, Planungshilfe, Finanzen. */
export const SCOPE_MODULES: string[] = ['EA', 'EZ', 'TK', 'FI']

export function allowsReferat(code: string): boolean {
  return SCOPE_MODULES.includes(code)
}

/** Aktion „freigeben“ (R50, Nachtrag v0.10): nur Finanzen (bestätigen) und Planungshilfe (freigeben). */
export const APPROVE_MODULES: string[] = ['FI', 'TK']

export function allowsApprove(code: string): boolean {
  return APPROVE_MODULES.includes(code)
}

const NONE: Right = { level: 'none', scope: 'all', approve: false }

export type ListResult = { templates: TemplateRow[]; failed: boolean }
export type EditData = {
  modules: Module[]
  template: Template | null
  rights: Rights
  personCount: number
  failed: boolean
}

// React Router lädt Eltern- und Kind-Loader gleichzeitig. Deshalb prüft jeder Loader
// selbst AD ≥ lesen, bevor er Daten abfragt (US-AD-05 AK3).

/** Liste mit Anzahl Personen aus wirksamen Zuweisungen (revoked_at is null). */
export async function loadTemplateList(): Promise<ListResult> {
  await requireLevel('AD', 'read')
  const [templates, assignments] = await Promise.all([
    supabase.from('ad_templates').select('id, name, description').order('name'),
    supabase.from('ad_template_assignments').select('template_id').is('revoked_at', null),
  ])
  if (templates.error || assignments.error) return { templates: [], failed: true }

  const counts = new Map<string, number>()
  for (const a of assignments.data) counts.set(a.template_id, (counts.get(a.template_id) ?? 0) + 1)

  return {
    templates: templates.data.map((t) => ({ ...t, personCount: counts.get(t.id) ?? 0 })),
    failed: false,
  }
}

async function loadModules() {
  return supabase.from('ad_modules').select('code, name').order('sort_order')
}

export async function loadNewTemplate(): Promise<EditData> {
  await requireAdEdit()
  const modules = await loadModules()
  if (modules.error) return { modules: [], template: null, rights: {}, personCount: 0, failed: true }
  return {
    modules: modules.data as Module[],
    template: null,
    rights: Object.fromEntries(modules.data.map((m) => [m.code, NONE])),
    personCount: 0,
    failed: false,
  }
}

export async function loadTemplate({ params }: LoaderFunctionArgs): Promise<EditData> {
  await requireLevel('AD', 'read')
  const id = params.id!
  const [modules, template, rights, assignments] = await Promise.all([
    loadModules(),
    supabase.from('ad_templates').select('id, name, description').eq('id', id).maybeSingle(),
    supabase.from('ad_template_rights').select('module_code, level, scope, can_approve').eq('template_id', id),
    supabase
      .from('ad_template_assignments')
      .select('id', { count: 'exact', head: true })
      .eq('template_id', id)
      .is('revoked_at', null),
  ])
  if (modules.error || template.error || rights.error || assignments.error) {
    return { modules: [], template: null, rights: {}, personCount: 0, failed: true }
  }
  if (!template.data) throw redirect('/ad/rechtevorlagen')
  return {
    modules: modules.data as Module[],
    template: template.data,
    rights: Object.fromEntries(
      rights.data.map((r) => [r.module_code, { level: r.level as Level, scope: r.scope as Scope, approve: r.can_approve === true }]),
    ),
    personCount: assignments.count ?? 0,
    failed: false,
  }
}

function sameRight(a: Right | undefined, b: Right) {
  return a?.level === b.level && a?.scope === b.scope && (a?.approve ?? false) === b.approve
}

// Zeilen nacheinander, damit bei einem Fehler (z. B. R30) klar ist, welche Stufen schon gespeichert sind
async function updateRights(templateId: string, changed: [string, Right][]) {
  for (const [code, right] of changed) {
    const { error } = await supabase
      .from('ad_template_rights')
      .update({ level: right.level, scope: right.scope, can_approve: right.level !== 'none' && right.approve })
      .eq('template_id', templateId)
      .eq('module_code', code)
    if (error) return error
  }
  return null
}

export function personCountLabel(n: number) {
  return n === 1 ? '1 Person' : `${n} Personen`
}

export type SaveInput = { name: string; description: string; rights: Rights }
export type SaveResult = { id: string | null; error: unknown }

/**
 * Speichert Name, Beschreibung und geänderte Stufen bzw. Reichweiten. Neue Vorlagen bekommen ihre
 * Rechte-Zeilen per Trigger (Stufe „kein Zugriff“, Reichweite „alle“); danach werden die gewählten Werte gesetzt.
 */
export async function saveTemplate(
  existing: { id: string; rights: Rights } | null,
  input: SaveInput,
): Promise<SaveResult> {
  const fields = { name: input.name.trim(), description: input.description.trim() || null }

  if (!existing) {
    const { data, error } = await supabase.from('ad_templates').insert(fields).select('id').single()
    if (error) return { id: null, error }
    const changed = Object.entries(input.rights).filter(([, right]) => !sameRight(NONE, right))
    return { id: data.id, error: await updateRights(data.id, changed) }
  }

  const { error } = await supabase.from('ad_templates').update(fields).eq('id', existing.id)
  if (error) return { id: existing.id, error }
  const changed = Object.entries(input.rights).filter(([code, right]) => !sameRight(existing.rights[code], right))
  return { id: existing.id, error: await updateRights(existing.id, changed) }
}
