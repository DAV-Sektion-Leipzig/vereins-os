// CORS: erlaubt sind die Redirect-Adressen aus supabase/config.toml (PROD, Vorschau je Branch, lokal).

const EXACT = new Set(['https://vereins-os.sektion-leipzig.workers.dev', 'http://localhost:5173'])
const PREVIEW = /^https:\/\/[a-z0-9-]+-vereins-os\.sektion-leipzig\.workers\.dev$/

export function isAllowedOrigin(origin: string | null): origin is string {
  return origin !== null && (EXACT.has(origin) || PREVIEW.test(origin))
}

export function corsHeaders(origin: string | null): Record<string, string> {
  if (!isAllowedOrigin(origin)) return {}
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  }
}
