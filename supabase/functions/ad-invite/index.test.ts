// Deno-Tests ad-invite (spec T9, US-AD-08 AK5, AK6): contracts/edge-functions.md mit simulierten Clients.
import { assertEquals } from 'jsr:@std/assert@1'
import { ACCESS_ACTIVE, ACCESS_INVITED, ACCESS_NONE, makeFakeDeps, P_ONLY, post } from '../_shared/test-fakes.ts'
import { handleInvite } from './handler.ts'

async function run(body: unknown, options: Parameters<typeof makeFakeDeps>[0] = {}, jwt: string | null = 'jwt') {
  const fake = makeFakeDeps({ accesses: [ACCESS_NONE, ACCESS_INVITED, ACCESS_ACTIVE], ...options })
  const res = await handleInvite(post(body, jwt), fake.deps)
  return { status: res.status, body: await res.json(), ...fake }
}

Deno.test('401 ohne JWT', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, {}, null)
  assertEquals([r.status, r.body.code], [401, 'AD_UNAUTHENTICATED'])
})

Deno.test('401 bei ungültigem JWT', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, {}, 'bad')
  assertEquals([r.status, r.body.code], [401, 'AD_UNAUTHENTICATED'])
})

Deno.test('403 ohne AD ≥ bearbeiten, keine Einladung (AK6)', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { adEdit: false })
  assertEquals([r.status, r.body.code], [403, 'AD_FORBIDDEN'])
  assertEquals(r.calls.length, 0)
})

Deno.test('400 bei ungültigem Request', async () => {
  const r = await run({ person_id: 'keine-uuid' })
  assertEquals([r.status, r.body.code], [400, 'AD_BAD_REQUEST'])
})

Deno.test('404 bei unbekannter Person', async () => {
  const r = await run({ person_id: '00000000-0000-4000-8000-000000000099' })
  assertEquals([r.status, r.body.code], [404, 'AD_PERSON_NOT_FOUND'])
})

Deno.test('422 ohne Login-Adresse', async () => {
  const r = await run({ person_id: P_ONLY }, { persons: [P_ONLY] })
  assertEquals([r.status, r.body.code], [422, 'AD_EMAIL_MISSING'])
})

Deno.test('422 bei fremder Domain (R1)', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { allowedDomains: ['example.test'] })
  assertEquals([r.status, r.body.code], [422, 'AD_EMAIL_DOMAIN'])
})

Deno.test('409 wenn die Adresse einem anderen Auth-Nutzer gehört (R2)', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { authUsers: { [ACCESS_NONE.login_email]: 'u-fremd' } })
  assertEquals([r.status, r.body.code], [409, 'AD_EMAIL_TAKEN'])
})

Deno.test('422 ohne wirksame Vorlage (R17, AK2)', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { activeTemplates: [] })
  assertEquals([r.status, r.body.code], [422, 'AD_NO_TEMPLATE'])
})

Deno.test('409 bei Status aktiv', async () => {
  const r = await run({ person_id: ACCESS_ACTIVE.person_id })
  assertEquals([r.status, r.body.code], [409, 'AD_INVALID_STATUS'])
})

Deno.test('Erfolg: Einladung, ad_apply_invite mit Akteur und neuem Auth-Nutzer (AK1)', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id })
  assertEquals(r.status, 200)
  assertEquals(r.body.status, 'invited')
  const invite = r.calls.find((c) => c.name === 'inviteUserByEmail')!
  assertEquals(invite.args, [ACCESS_NONE.login_email, 'https://vereins-os.sektion-leipzig.workers.dev/passwort-setzen'])
  const apply = r.calls.find((c) => c.name === 'rpc:ad_apply_invite')!
  assertEquals(apply.args[0], { p_person: ACCESS_NONE.person_id, p_auth_user: 'created-1', p_actor: 'actor-1' })
})

Deno.test('Erneut einladen bei „eingeladen“ behält den Auth-Nutzer (AK4)', async () => {
  const r = await run({ person_id: ACCESS_INVITED.person_id }, { authUsers: { [ACCESS_INVITED.login_email]: 'u-invited' } })
  assertEquals(r.status, 200)
  const apply = r.calls.find((c) => c.name === 'rpc:ad_apply_invite')!
  assertEquals((apply.args[0] as Record<string, unknown>).p_auth_user, 'u-invited')
  assertEquals(r.calls.some((c) => c.name === 'deleteUser'), false)
})

Deno.test('Mailfehler: neu angelegter Auth-Eintrag wird gelöscht, Ausgangsstand zurückgesetzt, 502 (AK5)', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { inviteError: 'smtp down', inviteCreatesUserOnError: true })
  assertEquals([r.status, r.body.code], [502, 'AD_MAIL_FAILED'])
  assertEquals(r.calls.some((c) => c.name === 'deleteUser' && c.args[0] === 'created-1'), true)
  const revert = r.calls.find((c) => c.name === 'rpc:ad_revert_invite')!
  assertEquals(revert.args[0], { p_person: ACCESS_NONE.person_id, p_status: 'none', p_auth_user: null, p_last_invited_at: null })
  assertEquals(r.calls.some((c) => c.name === 'rpc:ad_apply_invite'), false)
  assertEquals(r.authUsers.size, 0)
})

Deno.test('Mailfehler ohne angelegten Eintrag: nichts löschen, trotzdem zurücksetzen', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { inviteError: 'smtp down' })
  assertEquals([r.status, r.body.code], [502, 'AD_MAIL_FAILED'])
  assertEquals(r.calls.some((c) => c.name === 'deleteUser'), false)
  assertEquals(r.calls.some((c) => c.name === 'rpc:ad_revert_invite'), true)
})

Deno.test('Mailfehler bei erneuter Einladung: vorhandener Auth-Nutzer bleibt', async () => {
  const r = await run({ person_id: ACCESS_INVITED.person_id }, { inviteError: 'smtp down', authUsers: { [ACCESS_INVITED.login_email]: 'u-invited' } })
  assertEquals([r.status, r.body.code], [502, 'AD_MAIL_FAILED'])
  assertEquals(r.calls.some((c) => c.name === 'deleteUser'), false)
  const revert = r.calls.find((c) => c.name === 'rpc:ad_revert_invite')!
  assertEquals((revert.args[0] as Record<string, unknown>).p_auth_user, 'u-invited')
})

Deno.test('Fehler der internen Funktion wird abgebildet', async () => {
  const r = await run({ person_id: ACCESS_NONE.person_id }, { rpcErrors: { ad_apply_invite: 'AD_INVALID_STATUS' } })
  assertEquals([r.status, r.body.code], [409, 'AD_INVALID_STATUS'])
})

Deno.test('OPTIONS liefert CORS für erlaubte Origins', async () => {
  const fake = makeFakeDeps()
  const req = new Request('https://example.test/x', { method: 'OPTIONS', headers: { Origin: 'https://feature-vereins-os.sektion-leipzig.workers.dev' } })
  const res = await handleInvite(req, fake.deps)
  assertEquals(res.status, 204)
  assertEquals(res.headers.get('Access-Control-Allow-Origin'), 'https://feature-vereins-os.sektion-leipzig.workers.dev')
  const fremd = await handleInvite(new Request('https://example.test/x', { method: 'OPTIONS', headers: { Origin: 'https://fremd.example' } }), fake.deps)
  assertEquals(fremd.headers.get('Access-Control-Allow-Origin'), null)
})
