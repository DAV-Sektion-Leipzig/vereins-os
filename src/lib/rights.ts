// Routenschutz und eigene Person. Die Rechte prüft die Datenbank; das Frontend leitet nur um
// (spec.md AD Abschnitt 6, contracts/routes.md).
import { redirect } from 'react-router-dom'
import { supabase } from '@/lib/supabase'

export type ModuleCode = 'AD' | 'SC' | 'EA' | 'GR' | 'FI' | 'OA' | 'PM' | 'GS' | 'AM'
export type Level = 'none' | 'read' | 'edit' | 'manage'
export type AccessStatus = 'none' | 'invited' | 'active' | 'locked'

export type Me = {
  person_id: string
  first_name: string
  last_name: string
  access_status: AccessStatus
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

/** Eigene Person und eigener Zugang (ad_me); null ohne Zugang. */
export async function loadMe(): Promise<Me | null> {
  const { data, error } = await supabase.rpc('ad_me')
  if (error || !Array.isArray(data) || data.length === 0) return null
  return data[0] as Me
}
