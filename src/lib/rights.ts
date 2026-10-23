// Routenschutz und eigene Person. Die Rechte prüft die Datenbank; das Frontend leitet nur um
// (spec.md AD Abschnitt 6, contracts/routes.md).
import { redirect } from 'react-router-dom'
import { supabase } from '@/lib/supabase'

export type ModuleCode = 'AD' | 'SC' | 'EA' | 'GR' | 'FI' | 'OA' | 'PM' | 'GS' | 'AM'
export type Level = 'none' | 'read' | 'edit' | 'manage'
export type AccessStatus = 'none' | 'invited' | 'active' | 'locked'
export type Scope = 'all' | 'referat'

export type Me = {
  person_id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  access_status: AccessStatus
}

export const LEVELS: Level[] = ['none', 'read', 'edit', 'manage']

export const LEVEL_LABELS: Record<Level, string> = {
  none: 'kein Zugriff',
  read: 'lesen',
  edit: 'bearbeiten',
  manage: 'verwalten',
}

export const SCOPES: Scope[] = ['all', 'referat']

export const SCOPE_LABELS: Record<Scope, string> = {
  all: 'alle',
  referat: 'Referat',
}

/** Ohne Sitzung → /login (US-AD-02 AK5). */
export async function requireSession() {
  const { data } = await supabase.auth.getSession()
  if (!data.session) throw redirect('/login')
  return data.session
}

/** Ohne Stufe → /kein-zugriff, bevor Daten geladen werden (US-AD-05 AK3). */
export async function requireLevel(module: ModuleCode, min: Level) {
  await requireSession()
  const { data, error } = await supabase.rpc('ad_has_level', { p_module: module, p_min: min })
  if (error || data !== true) throw redirect('/kein-zugriff')
}

/** Prüft eine Stufe ohne Umleitung, z. B. für Schreibknöpfe. Die Datenbank prüft beim Schreiben erneut. */
export async function hasLevel(module: ModuleCode, min: Level): Promise<boolean> {
  const { data, error } = await supabase.rpc('ad_has_level', { p_module: module, p_min: min })
  return !error && data === true
}

/** Recht in irgendeiner Reichweite (alle oder Referat), z. B. für Navigation und /ea (spec.md AD Abschnitt 6). */
export async function hasAnyLevel(module: ModuleCode, min: Level): Promise<boolean> {
  const { data, error } = await supabase.rpc('ad_has_any_level', { p_module: module, p_min: min })
  return !error && data === true
}

/**
 * Zugang zu den Seiten Eigenschafts- und Qualifikationsarten (US-EA-15, T051): unter /ad mit AD ≥ lesen,
 * unter /ea mit EA = verwalten; sonst /kein-zugriff, bevor Daten geladen werden.
 */
export type TypesGate = 'AD' | 'EA'

export async function requireTypesAccess(gate: TypesGate) {
  if (gate === 'AD') return requireLevel('AD', 'read')
  await requireSession()
  if (!(await hasLevel('EA', 'manage'))) throw redirect('/kein-zugriff')
}

/** Qualifikationsarten pflegen: Admin oder Geschäftsstelle (AD ≥ bearbeiten oder EA = verwalten). */
export async function canEditQualificationTypes(): Promise<boolean> {
  const { data, error } = await supabase.rpc('ad_can_edit_qualification_types')
  return !error && data === true
}

/** Eigene Person und eigener Zugang (ad_me); null ohne Zugang. */
export async function loadMe(): Promise<Me | null> {
  const { data, error } = await supabase.rpc('ad_me')
  if (error || !Array.isArray(data) || data.length === 0) return null
  return data[0] as Me
}
