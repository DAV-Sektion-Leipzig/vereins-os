// Versand über die Brevo-API (spec.md SC Abschnitt 7): POST /v3/smtp/email, reiner Text, ohne Tracking (A8).
import type { Mail, SendResult } from './types.ts'

export const BREVO_URL = 'https://api.brevo.com/v3/smtp/email'
const TIMEOUT_MS = 15_000

/** Meldung kürzen und den Key entfernen, bevor sie gespeichert wird (spec.md SC Abschnitt 8). */
export function sanitize(message: string, key: string): string {
  const cleaned = key ? message.split(key).join('***') : message
  return cleaned.replace(/\s+/g, ' ').trim().slice(0, 300)
}

function classify(status: number, message: string): 'recipient' | 'auth' | 'rate' | 'server' {
  if (status === 401 || status === 403) return 'auth'
  if (status === 429) return 'rate'
  // 400 wegen der Empfängeradresse: sofort fehlgeschlagen, keine Störung der Anbindung (A7)
  if (status === 400) return /\b(to|email|recipient)\b/i.test(message) ? 'recipient' : 'auth'
  return 'server'
}

export async function sendBrevo(fetchFn: typeof fetch, key: string, mail: Mail): Promise<SendResult> {
  let res: Response
  try {
    res = await fetchFn(BREVO_URL, {
      method: 'POST',
      headers: { 'api-key': key, 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify({
        sender: { email: mail.sender_email, name: mail.sender_name },
        to: [{ email: mail.recipient_email }],
        subject: mail.subject,
        textContent: mail.body,
      }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    })
  } catch (error) {
    const timeout = error instanceof DOMException && error.name === 'TimeoutError'
    return { ok: false, kind: 'server', message: timeout ? 'Zeitüberschreitung' : 'Brevo nicht erreichbar' }
  }

  let payload: Record<string, unknown> = {}
  try {
    payload = await res.json()
  } catch {
    // leere oder ungültige Antwort
  }
  if (res.status === 201 || res.status === 200) {
    return { ok: true, messageId: typeof payload.messageId === 'string' ? payload.messageId : null }
  }
  const text = [payload.code, payload.message].filter((v) => typeof v === 'string').join(': ') || `HTTP ${res.status}`
  const message = sanitize(`${res.status} ${text}`, key)
  return { ok: false, kind: classify(res.status, message), message }
}
