// Module der Startseite (US-AD-05) aus ad_my_modules; die Rechte prüft die Datenbank.
import type { Level, ModuleCode } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type MyModule = { code: ModuleCode; name: string; level: Level }
export type MyModulesResult = { modules: MyModule[]; failed: boolean }

// Einstieg je umgesetztem Modul; Module ohne Eintrag erscheinen nicht (US-AD-05 AK1)
export const MODULE_PATHS: Partial<Record<ModuleCode, string>> = { AD: '/ad', EA: '/ea', GR: '/gr', EZ: '/ez' }

async function fetchMyModules(): Promise<MyModulesResult> {
  const { data, error } = await supabase.rpc('ad_my_modules')
  if (error || !Array.isArray(data)) return { modules: [], failed: true }
  return { modules: (data as MyModule[]).filter((m) => MODULE_PATHS[m.code]), failed: false }
}

/**
 * Lädt bei jedem Aufruf neu, damit entzogene Rechte verschwinden (US-AD-05 AK4).
 * Gibt die Abfrage als Promise zurück, damit die Seite sofort mit Ladezustand erscheint.
 */
export function loadMyModules(): { result: Promise<MyModulesResult> } {
  return { result: fetchMyModules() }
}
