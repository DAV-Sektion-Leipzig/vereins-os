// Abhängigkeiten der Edge Functions ad-invite und ad-access (contracts/edge-functions.md, research.md R-07).
// Die Handler arbeiten nur gegen diese Schnittstellen; index.ts verdrahtet Supabase, die Tests Fakes.

export type AccessStatus = 'none' | 'invited' | 'active' | 'locked'

export type AccessRow = {
  person_id: string
  login_email: string
  status: AccessStatus
  auth_user_id: string | null
  last_invited_at: string | null
}

/** Datenbank im Kontext des Aufrufers (JWT, RLS). */
export interface Caller {
  /** Nutzer-ID aus dem JWT; null, wenn das JWT ungültig ist. */
  userId(): Promise<string | null>
  /** ad_has_level('AD','edit') im Kontext des Aufrufers. */
  hasAdEdit(): Promise<boolean>
}

/** Datenbank mit dem Service-Schlüssel (nur für die internen Statusfunktionen und Prüfungen). */
export interface ServiceDb {
  personExists(personId: string): Promise<boolean>
  getAccess(personId: string): Promise<AccessRow | null>
  /** R1 über ad_login_email_allowed (in TEST zusätzlich Domains aus ad_test_login_domains). */
  emailAllowed(email: string): Promise<boolean>
  /** R2: Adresse gehört schon zum Zugang einer anderen Person. */
  emailUsedByOtherAccess(email: string, personId: string): Promise<boolean>
  /** R17: mindestens eine wirksame Zuweisung. */
  hasActiveTemplate(personId: string): Promise<boolean>
  /** Ruft eine interne Funktion auf; wirft bei Fehlern einen Error, dessen message der Fehlercode ist. */
  rpc<T = unknown>(name: string, args: Record<string, unknown>): Promise<T>
}

/** Auth-Admin-API (Service-Schlüssel). Fehler als Text, null bei Erfolg. */
export interface AuthAdmin {
  inviteUserByEmail(email: string, redirectTo: string): Promise<{ userId: string | null; error: string | null }>
  findUserIdByEmail(email: string): Promise<string | null>
  deleteUser(userId: string): Promise<string | null>
  /** Sperren mit ban_duration '876000h', Entsperren mit 'none' (research.md R-05). */
  setBanned(userId: string, banned: boolean): Promise<string | null>
}

export type Deps = {
  caller: (jwt: string) => Caller
  db: ServiceDb
  auth: AuthAdmin
  /** Basis-URL der SPA für redirectTo (SITE_URL). */
  siteUrl: string
}
