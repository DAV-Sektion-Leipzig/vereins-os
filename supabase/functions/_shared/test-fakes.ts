// Fakes für die Deno-Tests der Edge Functions (spec T9, T10): kein Supabase-Projekt, kein Docker.
import type { AccessRow, AuthAdmin, Caller, Deps, ServiceDb } from './types.ts'

export type Call = { name: string; args: unknown[] }

export type FakeOptions = {
  actor?: string | null
  adEdit?: boolean
  persons?: string[]
  accesses?: AccessRow[]
  allowedDomains?: string[]
  activeTemplates?: string[]
  /** Auth-Nutzer: E-Mail → ID */
  authUsers?: Record<string, string>
  inviteError?: string | null
  /** Legt die Auth-Admin-API bei einem Fehler trotzdem einen Nutzer an? (Supabase-Verhalten ist nicht festgelegt) */
  inviteCreatesUserOnError?: boolean
  deleteError?: string | null
  banError?: string | null
  rpcErrors?: Record<string, string>
}

export function makeFakeDeps(options: FakeOptions = {}) {
  const calls: Call[] = []
  const record = (name: string, ...args: unknown[]) => calls.push({ name, args })
  const accesses = new Map((options.accesses ?? []).map((a) => [a.person_id, { ...a }]))
  const authUsers = new Map(Object.entries(options.authUsers ?? {}).map(([email, id]) => [email.toLowerCase(), id]))
  const persons = new Set(options.persons ?? [...accesses.keys()])
  const allowed = options.allowedDomains ?? ['dav-leipzig.de']
  let counter = 0

  const caller = (jwt: string): Caller => ({
    userId: () => Promise.resolve(jwt === 'bad' ? null : (options.actor === undefined ? 'actor-1' : options.actor)),
    hasAdEdit: () => Promise.resolve(options.adEdit ?? true),
  })

  const db: ServiceDb = {
    personExists: (id) => Promise.resolve(persons.has(id)),
    getAccess: (id) => Promise.resolve(accesses.get(id) ?? null),
    emailAllowed: (email) => Promise.resolve(allowed.includes(email.split('@')[1]?.toLowerCase() ?? '')),
    emailUsedByOtherAccess: (email, personId) =>
      Promise.resolve([...accesses.values()].some((a) => a.person_id !== personId && a.login_email.toLowerCase() === email.toLowerCase())),
    hasActiveTemplate: (id) => Promise.resolve((options.activeTemplates ?? [...persons]).includes(id)),
    rpc: <T>(name: string, args: Record<string, unknown>): Promise<T> => {
      record(`rpc:${name}`, args)
      const err = options.rpcErrors?.[name]
      if (err) return Promise.reject(new Error(err))
      const person = accesses.get(String(args.p_person))
      switch (name) {
        case 'ad_apply_invite': {
          if (person) {
            person.status = 'invited'
            person.auth_user_id = (args.p_auth_user as string | null) ?? person.auth_user_id
            person.last_invited_at = '2026-10-23T10:00:00Z'
          }
          return Promise.resolve([{ status: 'invited', last_invited_at: '2026-10-23T10:00:00Z' }] as unknown as T)
        }
        case 'ad_revert_invite': {
          if (person) {
            person.status = args.p_status as AccessRow['status']
            person.auth_user_id = args.p_auth_user as string | null
            person.last_invited_at = args.p_last_invited_at as string | null
          }
          return Promise.resolve(null as unknown as T)
        }
        case 'ad_apply_lock': {
          if (person) person.status = 'locked'
          return Promise.resolve([{ status: 'locked' }] as unknown as T)
        }
        case 'ad_apply_unlock': {
          const status = args.p_person === P_NOPASS ? 'invited' : 'active'
          if (person) person.status = status
          return Promise.resolve([{ status }] as unknown as T)
        }
        case 'ad_apply_email_change': {
          if (person) {
            person.login_email = args.p_new_email as string
            person.auth_user_id = null
            person.status = 'none'
          }
          return Promise.resolve(null as unknown as T)
        }
        default:
          return Promise.resolve(null as unknown as T)
      }
    },
  }

  const auth: AuthAdmin = {
    inviteUserByEmail: (email, redirectTo) => {
      record('inviteUserByEmail', email, redirectTo)
      if (options.inviteError) {
        if (options.inviteCreatesUserOnError && !authUsers.has(email.toLowerCase())) authUsers.set(email.toLowerCase(), `created-${++counter}`)
        return Promise.resolve({ userId: null, error: options.inviteError })
      }
      const id = authUsers.get(email.toLowerCase()) ?? `created-${++counter}`
      authUsers.set(email.toLowerCase(), id)
      return Promise.resolve({ userId: id, error: null })
    },
    findUserIdByEmail: (email) => Promise.resolve(authUsers.get(email.toLowerCase()) ?? null),
    deleteUser: (id) => {
      record('deleteUser', id)
      if (options.deleteError) return Promise.resolve(options.deleteError)
      for (const [email, uid] of authUsers) if (uid === id) authUsers.delete(email)
      return Promise.resolve(null)
    },
    setBanned: (id, banned) => {
      record('setBanned', id, banned)
      return Promise.resolve(options.banError ?? null)
    },
  }

  const deps: Deps = { caller, db, auth, siteUrl: 'https://vereins-os.sektion-leipzig.workers.dev' }
  return { deps, calls, accesses, authUsers }
}

export function post(body: unknown, jwt: string | null = 'jwt', origin = 'https://vereins-os.sektion-leipzig.workers.dev') {
  const headers: Record<string, string> = { 'Content-Type': 'application/json', Origin: origin }
  if (jwt) headers.Authorization = `Bearer ${jwt}`
  return new Request('https://example.test/functions/v1/x', { method: 'POST', headers, body: JSON.stringify(body) })
}

export const P_NONE = '00000000-0000-4000-8000-000000000001'
export const P_INVITED = '00000000-0000-4000-8000-000000000002'
export const P_ACTIVE = '00000000-0000-4000-8000-000000000003'
export const P_LOCKED = '00000000-0000-4000-8000-000000000004'
export const P_NOPASS = '00000000-0000-4000-8000-000000000005'
export const P_ONLY = '00000000-0000-4000-8000-000000000010'

export const ACCESS_NONE: AccessRow = {
  person_id: P_NONE,
  login_email: 'neu@dav-leipzig.de',
  status: 'none',
  auth_user_id: null,
  last_invited_at: null,
}
export const ACCESS_INVITED: AccessRow = {
  person_id: P_INVITED,
  login_email: 'eingeladen@dav-leipzig.de',
  status: 'invited',
  auth_user_id: 'u-invited',
  last_invited_at: '2026-10-01T10:00:00Z',
}
export const ACCESS_ACTIVE: AccessRow = {
  person_id: P_ACTIVE,
  login_email: 'aktiv@dav-leipzig.de',
  status: 'active',
  auth_user_id: 'u-active',
  last_invited_at: '2026-09-01T10:00:00Z',
}
export const ACCESS_LOCKED: AccessRow = {
  person_id: P_LOCKED,
  login_email: 'gesperrt@dav-leipzig.de',
  status: 'locked',
  auth_user_id: 'u-locked',
  last_invited_at: '2026-08-01T10:00:00Z',
}
