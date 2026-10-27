// Deno-Tests ad-access (spec T10, US-AD-08 AK7, US-AD-09): contracts/edge-functions.md mit simulierten Clients.
import { assertEquals } from 'jsr:@std/assert@1'
import { ACCESS_ACTIVE, ACCESS_INVITED, ACCESS_LOCKED, ACCESS_NONE, makeFakeDeps, P_NOPASS, post } from '../_shared/test-fakes.ts'
import { handleAccess } from './handler.ts'

async function run(body: unknown, options: Parameters<typeof makeFakeDeps>[0] = {}, jwt: string | null = 'jwt') {
  const fake = makeFakeDeps({
    accesses: [ACCESS_NONE, ACCESS_INVITED, ACCESS_ACTIVE, ACCESS_LOCKED],
    authUsers: { [ACCESS_INVITED.login_email]: 'u-invited', [ACCESS_ACTIVE.login_email]: 'u-active', [ACCESS_LOCKED.login_email]: 'u-locked' },
    ...options,
  })
  const res = await handleAccess(post(body, jwt), fake.deps)
  return { status: res.status, body: await res.json(), ...fake }
}

Deno.test('401 ohne JWT und bei ungültigem JWT', async () => {
  const ohne = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, {}, null)
  assertEquals([ohne.status, ohne.body.code], [401, 'AD_UNAUTHENTICATED'])
  const schlecht = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, {}, 'bad')
  assertEquals([schlecht.status, schlecht.body.code], [401, 'AD_UNAUTHENTICATED'])
})

Deno.test('404 bei unbekannter Person', async () => {
  const r = await run({ person_id: '00000000-0000-4000-8000-000000000099', action: 'lock' })
  assertEquals([r.status, r.body.code], [404, 'AD_PERSON_NOT_FOUND'])
})

Deno.test('403 vor 400: ohne Recht auch bei ungültigem Request keine Details', async () => {
  const r = await run({ person_id: 'keine-uuid', action: 'delete' }, { adEdit: false })
  assertEquals([r.status, r.body.code], [403, 'AD_FORBIDDEN'])
})

Deno.test('403 ohne Recht (US-AD-09 AK5)', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, { adEdit: false })
  assertEquals([r.status, r.body.code], [403, 'AD_FORBIDDEN'])
  assertEquals(r.calls.length, 0)
})

Deno.test('400 bei unbekannter Aktion und bei login_email ohne change_email', async () => {
  assertEquals((await run({ person_id: ACCESS_ACTIVE.person_id, action: 'delete' })).status, 400)
  assertEquals((await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock', login_email: 'x@dav-leipzig.de' })).status, 400)
  assertEquals((await run({ person_id: ACCESS_INVITED.person_id, action: 'change_email' })).status, 400)
})

Deno.test('lock: aktiv → gesperrt mit Bann und Protokollfunktion (AK1)', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' })
  assertEquals([r.status, r.body.status], [200, 'locked'])
  assertEquals(r.calls[0], { name: 'rpc:ad_check_lock', args: [{ p_person: ACCESS_ACTIVE.person_id, p_actor: 'actor-1' }] })
  assertEquals(r.calls[1], { name: 'setBanned', args: ['u-active', true] })
  assertEquals(r.calls[2].name, 'rpc:ad_apply_lock')
  assertEquals((r.calls[2].args[0] as Record<string, unknown>).p_actor, 'actor-1')
})

Deno.test('lock: eigener Zugang → 409 AD_SELF_LOCK ohne Bann (Befund S-01)', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, { actor: 'u-active' })
  assertEquals([r.status, r.body.code], [409, 'AD_SELF_LOCK'])
  assertEquals(r.calls.length, 0)
})

Deno.test('lock: Datenbank lehnt vor dem Bann ab → 409 mit Code, kein Bann (Befund S-01)', async () => {
  for (const code of ['AD_SELF_LOCK', 'AD_EMERGENCY_PROTECTED', 'AD_LAST_ADMIN']) {
    const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, { rpcErrors: { ad_check_lock: code } })
    assertEquals([r.status, r.body.code], [409, code])
    assertEquals(r.calls.some((c) => c.name === 'setBanned'), false)
    assertEquals(r.calls.some((c) => c.name === 'rpc:ad_apply_lock'), false)
    assertEquals(r.accesses.get(ACCESS_ACTIVE.person_id)?.status, 'active')
  }
})

Deno.test('lock: ad_apply_lock lehnt ab → Bann zurückgenommen, 409 (Befund S-01)', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, { rpcErrors: { ad_apply_lock: 'AD_LAST_ADMIN' } })
  assertEquals([r.status, r.body.code], [409, 'AD_LAST_ADMIN'])
  const bans = r.calls.filter((c) => c.name === 'setBanned').map((c) => c.args)
  assertEquals(bans, [['u-active', true], ['u-active', false]])
})

Deno.test('lock: eingeladen → gesperrt (Einladung zurückziehen)', async () => {
  const r = await run({ person_id: ACCESS_INVITED.person_id, action: 'lock' })
  assertEquals([r.status, r.body.status], [200, 'locked'])
})

Deno.test('lock: 409 bei gesperrt und bei kein Zugang', async () => {
  assertEquals((await run({ person_id: ACCESS_LOCKED.person_id, action: 'lock' })).body.code, 'AD_INVALID_STATUS')
  assertEquals((await run({ person_id: ACCESS_NONE.person_id, action: 'lock' })).body.code, 'AD_INVALID_STATUS')
})

Deno.test('lock: Fehler beim Bann → 500, keine Statusänderung', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'lock' }, { banError: 'auth down' })
  assertEquals([r.status, r.body.code], [500, 'AD_UNEXPECTED'])
  assertEquals(r.calls.some((c) => c.name === 'rpc:ad_apply_lock'), false)
})

Deno.test('unlock: gesperrt → Status aus der internen Funktion (AK2, AK3)', async () => {
  const r = await run({ person_id: ACCESS_LOCKED.person_id, action: 'unlock' })
  assertEquals([r.status, r.body.status], [200, 'active'])
  assertEquals(r.calls[0], { name: 'setBanned', args: ['u-locked', false] })
  const ohne = await run({ person_id: P_NOPASS, action: 'unlock' }, {
    accesses: [{ ...ACCESS_LOCKED, person_id: P_NOPASS, auth_user_id: 'u-nopass' }],
  })
  assertEquals(ohne.body.status, 'invited')
})

Deno.test('unlock: 409 bei aktiv', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'unlock' })
  assertEquals([r.status, r.body.code], [409, 'AD_INVALID_STATUS'])
})

Deno.test('change_email: nur bei eingeladen, sonst AD_EMAIL_LOCKED (R20)', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id, action: 'change_email', login_email: 'neu2@dav-leipzig.de' })
  assertEquals([r.status, r.body.code], [409, 'AD_EMAIL_LOCKED'])
})

Deno.test('change_email: R1 und R2', async () => {
  const domain = await run({ person_id: ACCESS_INVITED.person_id, action: 'change_email', login_email: 'x@example.org' })
  assertEquals([domain.status, domain.body.code], [422, 'AD_EMAIL_DOMAIN'])
  const taken = await run({ person_id: ACCESS_INVITED.person_id, action: 'change_email', login_email: ACCESS_ACTIVE.login_email })
  assertEquals([taken.status, taken.body.code], [409, 'AD_EMAIL_TAKEN'])
  const takenAuth = await run({ person_id: ACCESS_INVITED.person_id, action: 'change_email', login_email: 'alt@dav-leipzig.de' }, {
    authUsers: { 'alt@dav-leipzig.de': 'u-alt' },
  })
  assertEquals(takenAuth.body.code, 'AD_EMAIL_TAKEN')
})

Deno.test('change_email: Auth-Eintrag gelöscht, dann ad_apply_email_change, Hinweis AD_EMAIL_CHANGED (AK7)', async () => {
  const r = await run({ person_id: ACCESS_INVITED.person_id, action: 'change_email', login_email: 'eva.neu@dav-leipzig.de' })
  assertEquals(r.status, 200)
  assertEquals(r.body, { status: 'none', code: 'AD_EMAIL_CHANGED' })
  assertEquals(r.calls[0], { name: 'deleteUser', args: ['u-invited'] })
  assertEquals(r.calls[1].name, 'rpc:ad_apply_email_change')
  assertEquals(r.calls[1].args[0], { p_person: ACCESS_INVITED.person_id, p_new_email: 'eva.neu@dav-leipzig.de', p_actor: 'actor-1' })
  assertEquals(r.accesses.get(ACCESS_INVITED.person_id)?.login_email, 'eva.neu@dav-leipzig.de')
})

Deno.test('change_email: Fehler beim Löschen → keine Änderung in der Datenbank', async () => {
  const r = await run({ person_id: ACCESS_INVITED.person_id, action: 'change_email', login_email: 'eva.neu@dav-leipzig.de' }, { deleteError: 'auth down' })
  assertEquals([r.status, r.body.code], [500, 'AD_UNEXPECTED'])
  assertEquals(r.calls.some((c) => c.name === 'rpc:ad_apply_email_change'), false)
  assertEquals(r.accesses.get(ACCESS_INVITED.person_id)?.login_email, ACCESS_INVITED.login_email)
})
