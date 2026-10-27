// Deno-Tests sc-send (spec.md SC T11, US-SC-03, US-SC-09): Brevo und Datenbank simuliert, kein echter Key (R14).
import { assertEquals } from 'jsr:@std/assert@1'
import { BREVO_URL, sanitize } from './brevo.ts'
import { handleSend } from './handler.ts'
import type { ClaimedMail, Mail, ScDeps, SendResult } from './types.ts'

const KEY = 'xkeysib-test-0000k3x9'
const CONN = '00000000-0000-4000-8000-000000000c01'
const MAIL: Mail = {
  recipient_email: 'test.admin@dav-leipzig.de',
  subject: 'Vereins OS: Test-E-Mail',
  body: 'Hallo,',
  sender_email: 'vereinsos.test@example.org',
  sender_name: 'Vereins OS (TEST)',
}
const claimed = (id: string): ClaimedMail => ({ ...MAIL, outbox_id: id, connection_id: CONN })

type BrevoAnswer = { status: number; body?: unknown } | 'timeout' | 'offline'

function fake(options: {
  secret?: string
  user?: string | null
  scEdit?: boolean
  mails?: ClaimedMail[]
  key?: string | null
  brevo?: BrevoAnswer[]
  prepareError?: string
} = {}) {
  const reports: { id: string; result: SendResult }[] = []
  const tests: { ok: boolean; message: string | null }[] = []
  const requests: { url: string; headers: Record<string, string>; body: Record<string, unknown> }[] = []
  const answers = [...(options.brevo ?? [])]
  let claims = 0

  const fetchFn: typeof fetch = (input, init) => {
    requests.push({
      url: String(input),
      headers: init?.headers as Record<string, string>,
      body: JSON.parse(String(init?.body ?? '{}')),
    })
    const answer = answers.shift() ?? { status: 201, body: { messageId: '<id@brevo>' } }
    if (answer === 'timeout') return Promise.reject(new DOMException('timeout', 'TimeoutError'))
    if (answer === 'offline') return Promise.reject(new TypeError('network'))
    return Promise.resolve(new Response(JSON.stringify(answer.body ?? {}), { status: answer.status }))
  }

  const deps: ScDeps = {
    fetch: fetchFn,
    db: {
      callerUserId: (jwt) => Promise.resolve(jwt === 'bad' ? null : (options.user === undefined ? 'user-1' : options.user)),
      callerHasScEdit: () => Promise.resolve(options.scEdit ?? true),
      checkDispatchSecret: (s) => Promise.resolve(s === (options.secret ?? 'geheim')),
      claim: () => Promise.resolve(claims++ === 0 ? (options.mails ?? []) : []),
      connectionKey: () => Promise.resolve(options.key === undefined ? KEY : options.key),
      report: (id, result) => {
        reports.push({ id, result })
        return Promise.resolve()
      },
      testPrepare: () =>
        options.prepareError ? Promise.reject(new Error(options.prepareError)) : Promise.resolve(MAIL),
      testReport: (_c, _u, ok, message) => {
        tests.push({ ok, message })
        return Promise.resolve()
      },
    },
  }
  return { deps, reports, tests, requests }
}

function dispatchRequest(secret = 'geheim') {
  return new Request('http://localhost/sc-send', {
    method: 'POST',
    headers: { 'x-sc-dispatch-secret': secret, 'content-type': 'application/json' },
    body: '{}',
  })
}

function testRequest(body: unknown, jwt: string | null = 'jwt') {
  const headers: Record<string, string> = { 'content-type': 'application/json' }
  if (jwt) headers.authorization = `Bearer ${jwt}`
  return new Request('http://localhost/sc-send', { method: 'POST', headers, body: JSON.stringify(body) })
}

Deno.test('Job: falsches Geheimnis → 403, kein Versand', async () => {
  const f = fake({ mails: [claimed('m1')] })
  const res = await handleSend(dispatchRequest('falsch'), f.deps)
  assertEquals([res.status, (await res.json()).code], [403, 'SC_FORBIDDEN'])
  assertEquals(f.requests.length, 0)
})

Deno.test('Job: versendet über Brevo mit Key im Header, reiner Text (A8)', async () => {
  const f = fake({ mails: [claimed('m1'), claimed('m2')] })
  const res = await handleSend(dispatchRequest(), f.deps)
  assertEquals(await res.json(), { sent: 2, failed: 0 })
  assertEquals(f.requests[0].url, BREVO_URL)
  assertEquals(f.requests[0].headers['api-key'], KEY)
  assertEquals(f.requests[0].body, {
    sender: { email: MAIL.sender_email, name: MAIL.sender_name },
    to: [{ email: MAIL.recipient_email }],
    subject: MAIL.subject,
    textContent: MAIL.body,
  })
  assertEquals(f.reports.map((r) => r.result), [{ ok: true, messageId: '<id@brevo>' }, { ok: true, messageId: '<id@brevo>' }])
})

Deno.test('Job: Fehlerarten nach spec.md SC Abschnitt 4', async () => {
  const f = fake({
    mails: [claimed('m1'), claimed('m2'), claimed('m3'), claimed('m4'), claimed('m5'), claimed('m6')],
    brevo: [
      { status: 400, body: { code: 'invalid_parameter', message: 'email is not valid in to' } },
      { status: 401, body: { code: 'unauthorized', message: `Key not found: ${KEY}` } },
      { status: 429, body: { message: 'Too many requests' } },
      { status: 502 },
      'timeout',
      'offline',
    ],
  })
  const res = await handleSend(dispatchRequest(), f.deps)
  assertEquals(await res.json(), { sent: 0, failed: 6 })
  assertEquals(f.reports.map((r) => (r.result.ok ? 'ok' : r.result.kind)), ['recipient', 'auth', 'rate', 'server', 'server', 'server'])
  const messages = f.reports.map((r) => (r.result.ok ? '' : r.result.message))
  assertEquals(messages[1], '401 unauthorized: Key not found: ***')
  assertEquals(messages[4], 'Zeitüberschreitung')
})

Deno.test('Job: ohne Key kein Aufruf bei Brevo, Fehler „auth“', async () => {
  const f = fake({ mails: [claimed('m1')], key: null })
  await handleSend(dispatchRequest(), f.deps)
  assertEquals(f.requests.length, 0)
  assertEquals(f.reports[0].result, { ok: false, kind: 'auth', message: 'Kein API-Key hinterlegt' })
})

Deno.test('Job: nichts fällig', async () => {
  const f = fake()
  const res = await handleSend(dispatchRequest(), f.deps)
  assertEquals(await res.json(), { sent: 0, failed: 0 })
})

Deno.test('Test: ohne JWT 401', async () => {
  const f = fake()
  const res = await handleSend(testRequest({ connection_id: CONN }, null), f.deps)
  assertEquals([res.status, (await res.json()).code], [401, 'SC_UNAUTHENTICATED'])
})

Deno.test('Test: ungültiges JWT 401', async () => {
  const f = fake()
  const res = await handleSend(testRequest({ connection_id: CONN }, 'bad'), f.deps)
  assertEquals(res.status, 401)
})

Deno.test('Test: ohne SC ≥ bearbeiten 403, kein Versand (R17)', async () => {
  const f = fake({ scEdit: false })
  const res = await handleSend(testRequest({ connection_id: CONN }), f.deps)
  assertEquals([res.status, (await res.json()).code], [403, 'SC_FORBIDDEN'])
  assertEquals(f.requests.length, 0)
})

Deno.test('Test: ungültige Anfrage 400', async () => {
  const f = fake()
  const res = await handleSend(testRequest({ connection_id: 'x' }), f.deps)
  assertEquals([res.status, (await res.json()).code], [400, 'SC_BAD_REQUEST'])
})

Deno.test('Test: Fehler aus der Datenbank (Recht, unbekannt)', async () => {
  const f = fake({ prepareError: 'SC_CONNECTION_UNKNOWN' })
  const res = await handleSend(testRequest({ connection_id: CONN }), f.deps)
  assertEquals([res.status, (await res.json()).code], [404, 'SC_CONNECTION_UNKNOWN'])
})

Deno.test('Test: erfolgreich', async () => {
  const f = fake()
  const res = await handleSend(testRequest({ connection_id: CONN }), f.deps)
  assertEquals(await res.json(), { ok: true, message: null })
  assertEquals(f.tests, [{ ok: true, message: null }])
})

Deno.test('Test: Brevo lehnt ab – Meldung ohne Key (R11)', async () => {
  const f = fake({ brevo: [{ status: 401, body: { code: 'unauthorized', message: `Key ${KEY} not found` } }] })
  const res = await handleSend(testRequest({ connection_id: CONN }), f.deps)
  const body = await res.json()
  assertEquals(body, { ok: false, message: '401 unauthorized: Key *** not found' })
  assertEquals(f.tests, [{ ok: false, message: '401 unauthorized: Key *** not found' }])
})

Deno.test('Test: ohne Key 422', async () => {
  const f = fake({ key: null })
  const res = await handleSend(testRequest({ connection_id: CONN }), f.deps)
  assertEquals([res.status, (await res.json()).code], [422, 'SC_KEY_MISSING'])
})

Deno.test('sanitize kürzt auf 300 Zeichen', () => {
  assertEquals(sanitize('x'.repeat(400), KEY).length, 300)
})
