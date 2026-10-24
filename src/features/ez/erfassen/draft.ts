// Entwurf im Browser (US-EZ-18, research.md R-EZ-18): nur Feldwerte und Person-IDs, keine Namen; Schlüssel je Nutzer.
// Gelöscht nach erfolgreichem Speichern, beim Abbrechen und beim Abmelden. Speicher kann fehlen (privates Fenster).
import { supabase } from '@/lib/supabase'

const PREFIX = 'ez-entwurf:'

export type Draft<T> = { savedAt: string; values: T }

function key(userId: string): string {
  return PREFIX + userId
}

export function readDraft<T>(userId: string): Draft<T> | null {
  try {
    const raw = window.localStorage.getItem(key(userId))
    return raw ? (JSON.parse(raw) as Draft<T>) : null
  } catch {
    return null
  }
}

export function writeDraft<T>(userId: string, values: T): void {
  try {
    window.localStorage.setItem(key(userId), JSON.stringify({ savedAt: new Date().toISOString(), values }))
  } catch {
    // ohne Speicher bleibt nur das Formular selbst
  }
}

export function clearDraft(userId: string): void {
  try {
    window.localStorage.removeItem(key(userId))
  } catch {
    // nichts zu tun
  }
}

/** Beim Abmelden alle Entwürfe der Anwesenheitserfassung löschen (spec.md 6, 8). */
function clearAllDrafts(): void {
  try {
    for (let i = window.localStorage.length - 1; i >= 0; i--) {
      const k = window.localStorage.key(i)
      if (k?.startsWith(PREFIX)) window.localStorage.removeItem(k)
    }
  } catch {
    // nichts zu tun
  }
}

supabase.auth.onAuthStateChange((event) => {
  if (event === 'SIGNED_OUT') clearAllDrafts()
})
