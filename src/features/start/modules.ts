// Module der Startseite (US-AD-05) aus ad_my_modules; die Rechte prüft die Datenbank.
import type { Level, ModuleCode } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type MyModule = { code: ModuleCode; name: string; level: Level }

// Einstieg je umgesetztem Modul; Module ohne Eintrag erscheinen nicht (US-AD-05 AK1)
export const MODULE_PATHS: Partial<Record<ModuleCode, string>> = { AD: '/ad' }

export const LEVEL_LABELS: Record<Level, string> = {
  none: 'kein Zugriff',
  read: 'lesen',
  edit: 'bearbeiten',
  manage: 'verwalten',
}

/** Lädt bei jedem Aufruf neu, damit entzogene Rechte verschwinden (US-AD-05 AK4). */
export async function loadMyModules(): Promise<{ modules: MyModule[]; failed: boolean }> {
  const { data, error } = await supabase.rpc('ad_my_modules')
  if (error || !Array.isArray(data)) return { modules: [], failed: true }
  return { modules: (data as MyModule[]).filter((m) => MODULE_PATHS[m.code]), failed: false }
}
