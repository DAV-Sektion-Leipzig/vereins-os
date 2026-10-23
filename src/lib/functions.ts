// Aufruf der Edge Functions ad-invite und ad-access (contracts/edge-functions.md).
// Per fetch statt functions.invoke, damit der Fehlercode aus dem Antwortkörper bei jedem Status lesbar ist.
import { supabase } from '@/lib/supabase'

export type FunctionResult<T> = { ok: true; data: T } | { ok: false; code: string }

export async function callFunction<T = Record<string, unknown>>(name: string, body: unknown): Promise<FunctionResult<T>> {
  const { data } = await supabase.auth.getSession()
  const token = data.session?.access_token
  if (!token) return { ok: false, code: 'AD_UNAUTHENTICATED' }

  try {
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/${name}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        apikey: import.meta.env.VITE_SUPABASE_ANON_KEY,
      },
      body: JSON.stringify(body),
    })
    const payload = (await response.json().catch(() => ({}))) as Record<string, unknown>
    if (response.status === 401) {
      // Sitzung abgelaufen oder ungültig: zur Anmeldung (contracts/error-codes.md: AD_UNAUTHENTICATED)
      window.location.assign('/login')
      return { ok: false, code: 'AD_UNAUTHENTICATED' }
    }
    if (!response.ok) return { ok: false, code: typeof payload.code === 'string' ? payload.code : 'AD_UNEXPECTED' }
    return { ok: true, data: payload as T }
  } catch {
    return { ok: false, code: 'AD_UNEXPECTED' }
  }
}
