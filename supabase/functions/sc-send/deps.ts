// Supabase-Anbindung für sc-send: Aufrufer-Client (JWT) und Service-Client für die Funktionen mit grant an service_role.
// SUPABASE_URL, SUPABASE_ANON_KEY und SUPABASE_SERVICE_ROLE_KEY stellt die Edge-Laufzeit bereit (kein Secret im Repo).
import { createClient } from 'npm:@supabase/supabase-js@2'
import type { ClaimedMail, Mail, ScDeps } from './types.ts'

const url = Deno.env.get('SUPABASE_URL') ?? ''
const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

export function makeScDeps(): ScDeps {
  const service = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } })
  const caller = (jwt: string) =>
    createClient(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    })

  async function rpc<T>(name: string, args: Record<string, unknown>): Promise<T> {
    const { data, error } = await service.rpc(name, args)
    if (error) throw new Error(error.message)
    return data as T
  }

  return {
    fetch: (input, init) => fetch(input, init),
    db: {
      async callerUserId(jwt) {
        const { data, error } = await caller(jwt).auth.getUser(jwt)
        return error || !data.user ? null : data.user.id
      },
      async callerHasScEdit(jwt) {
        const { data, error } = await caller(jwt).rpc('ad_has_level', { p_module: 'SC', p_min: 'edit' })
        if (error) throw new Error(error.message)
        return data === true
      },
      checkDispatchSecret: (secret) => rpc<boolean>('sc_check_dispatch_secret', { p_secret: secret }),
      claim: (max) => rpc<ClaimedMail[]>('sc_claim', { p_max: max }),
      connectionKey: (id) => rpc<string | null>('sc_connection_key', { p_connection: id }),
      report: (outboxId, result) =>
        rpc<void>('sc_report', {
          p_outbox: outboxId,
          p_ok: result.ok,
          p_error_kind: result.ok ? null : result.kind,
          p_message: result.ok ? null : result.message,
          p_provider_id: result.ok ? result.messageId : null,
        }),
      async testPrepare(connectionId, userId) {
        const rows = await rpc<Mail[]>('sc_test_prepare', { p_connection: connectionId, p_user: userId })
        if (!rows?.length) throw new Error('SC_CONNECTION_UNKNOWN')
        return rows[0]
      },
      testReport: (connectionId, userId, ok, message) =>
        rpc<void>('sc_test_report', { p_connection: connectionId, p_user: userId, p_ok: ok, p_message: message }),
    },
  }
}
