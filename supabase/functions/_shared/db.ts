// Supabase-Anbindung für die Edge Functions: Aufrufer-Client (JWT, RLS), Service-Client und Auth-Admin-API.
// SUPABASE_URL, SUPABASE_ANON_KEY und SUPABASE_SERVICE_ROLE_KEY stellt die Edge-Laufzeit bereit (kein Secret im Repo).
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2'
import type { AccessRow, AuthAdmin, Caller, Deps, ServiceDb } from './types.ts'

const url = Deno.env.get('SUPABASE_URL') ?? ''
const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

export function makeCaller(jwt: string): Caller {
  const client = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  })
  return {
    async userId() {
      const { data, error } = await client.auth.getUser(jwt)
      return error || !data.user ? null : data.user.id
    },
    async hasAdEdit() {
      const { data, error } = await client.rpc('ad_has_level', { p_module: 'AD', p_min: 'edit' })
      return !error && data === true
    },
  }
}

function makeServiceDb(service: SupabaseClient): ServiceDb {
  return {
    async personExists(personId) {
      const { data, error } = await service.from('ea_persons').select('id').eq('id', personId).maybeSingle()
      if (error) throw new Error(error.message)
      return data !== null
    },
    async getAccess(personId) {
      const { data, error } = await service
        .from('ad_accesses')
        .select('person_id, login_email, status, auth_user_id, last_invited_at')
        .eq('person_id', personId)
        .maybeSingle()
      if (error) throw new Error(error.message)
      return (data as AccessRow | null) ?? null
    },
    async emailAllowed(email) {
      const { data, error } = await service.rpc('ad_login_email_allowed', { p_email: email })
      if (error) throw new Error(error.message)
      return data === true
    },
    async emailUsedByOtherAccess(email, personId) {
      const { data, error } = await service.from('ad_accesses').select('person_id').eq('login_email', email).neq('person_id', personId)
      if (error) throw new Error(error.message)
      return (data ?? []).length > 0
    },
    async hasActiveTemplate(personId) {
      const today = new Date().toISOString().slice(0, 10)
      const { data, error } = await service
        .from('ad_template_assignments')
        .select('id')
        .eq('person_id', personId)
        .is('revoked_at', null)
        .or(`valid_from.is.null,valid_from.lte.${today}`)
        .or(`valid_to.is.null,valid_to.gte.${today}`)
        .limit(1)
      if (error) throw new Error(error.message)
      return (data ?? []).length > 0
    },
    async rpc<T>(name: string, args: Record<string, unknown>) {
      const { data, error } = await service.rpc(name, args)
      if (error) throw new Error(error.message)
      return data as T
    },
  }
}

function makeAuthAdmin(service: SupabaseClient): AuthAdmin {
  return {
    async inviteUserByEmail(email, redirectTo) {
      const { data, error } = await service.auth.admin.inviteUserByEmail(email, { redirectTo })
      return { userId: data?.user?.id ?? null, error: error?.message ?? null }
    },
    async findUserIdByEmail(email) {
      const needle = email.toLowerCase()
      for (let page = 1; page <= 20; page++) {
        const { data, error } = await service.auth.admin.listUsers({ page, perPage: 500 })
        if (error) throw new Error(error.message)
        const hit = data.users.find((u) => (u.email ?? '').toLowerCase() === needle)
        if (hit) return hit.id
        if (data.users.length < 500) return null
      }
      return null
    },
    async deleteUser(userId) {
      const { error } = await service.auth.admin.deleteUser(userId)
      return error?.message ?? null
    },
    async setBanned(userId, banned) {
      const { error } = await service.auth.admin.updateUserById(userId, { ban_duration: banned ? '876000h' : 'none' })
      return error?.message ?? null
    },
  }
}

export function makeDeps(): Deps {
  const service = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } })
  return {
    caller: makeCaller,
    db: makeServiceDb(service),
    auth: makeAuthAdmin(service),
    siteUrl: (Deno.env.get('SITE_URL') ?? 'https://vereins-os.sektion-leipzig.workers.dev').replace(/\/$/, ''),
  }
}
