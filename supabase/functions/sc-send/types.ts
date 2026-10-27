// Abhängigkeiten der Edge Function sc-send (spec.md SC Abschnitt 7). index.ts verdrahtet Supabase, die Tests Fakes.

export type Mail = {
  recipient_email: string
  subject: string
  body: string
  sender_email: string
  sender_name: string
}

export type ClaimedMail = Mail & { outbox_id: string; connection_id: string }

/** Ergebnis eines Aufrufs bei Brevo; kind nur bei Fehlern (spec.md SC Abschnitt 4). */
export type SendResult =
  | { ok: true; messageId: string | null }
  | { ok: false; kind: 'recipient' | 'auth' | 'rate' | 'server'; message: string }

export interface ScDb {
  /** Nutzer-ID aus dem JWT des Aufrufers; null, wenn das JWT ungültig ist. */
  callerUserId(jwt: string): Promise<string | null>
  /** ad_has_level('SC','edit') im Kontext des Aufrufers. */
  callerHasScEdit(jwt: string): Promise<boolean>
  checkDispatchSecret(secret: string): Promise<boolean>
  claim(max: number): Promise<ClaimedMail[]>
  connectionKey(connectionId: string): Promise<string | null>
  report(outboxId: string, result: SendResult): Promise<void>
  /** Wirft Error mit dem Fehlercode (SC_FORBIDDEN, SC_CONNECTION_UNKNOWN, SC_KEY_MISSING). */
  testPrepare(connectionId: string, userId: string): Promise<Mail>
  testReport(connectionId: string, userId: string, ok: boolean, message: string | null): Promise<void>
}

export type ScDeps = {
  db: ScDb
  fetch: typeof fetch
}
