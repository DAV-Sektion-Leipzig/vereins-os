import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

const missing = [
  !supabaseUrl && 'VITE_SUPABASE_URL',
  !supabaseAnonKey && 'VITE_SUPABASE_ANON_KEY',
].filter(Boolean)

if (missing.length > 0) {
  throw new Error(
    `Supabase-Konfiguration fehlt: ${missing.join(', ')}. ` +
      'Trage die Werte in .env.local ein (Vorlage: .env.example) und starte den Dev-Server neu.',
  )
}

// Ausschließlich der Publishable Key (sb_publishable_…); Schutz der Daten nur über RLS.
export const supabase = createClient(supabaseUrl, supabaseAnonKey)
