// sc-send (spec.md SC Abschnitt 7, US-SC-03, US-SC-09): Versand-Job (Header x-sc-dispatch-secret) und Test-E-Mail (JWT).
// Der Key wird nur hier aus Vault gelesen und nie gespeichert, protokolliert oder zurückgegeben (R1, R11).
import { corsHeaders } from '../_shared/cors.ts'
import { bearerToken, FunctionError, isUuid, json } from '../_shared/responses.ts'
import { sanitize, sendBrevo } from './brevo.ts'
import type { ScDeps } from './types.ts'

const BATCH = 20
const RPC_STATUS: Record<string, number> = {
  SC_FORBIDDEN: 403,
  SC_CONNECTION_UNKNOWN: 404,
  SC_KEY_MISSING: 422,
}

async function readBody(req: Request): Promise<Record<string, unknown>> {
  try {
    const body = await req.json()
    return typeof body === 'object' && body !== null && !Array.isArray(body) ? body : {}
  } catch {
    return {}
  }
}

async function dispatch(deps: ScDeps): Promise<{ sent: number; failed: number }> {
  const mails = await deps.db.claim(BATCH)
  const keys = new Map<string, string | null>()
  let sent = 0
  let failed = 0
  for (const mail of mails) {
    if (!keys.has(mail.connection_id)) keys.set(mail.connection_id, await deps.db.connectionKey(mail.connection_id))
    const key = keys.get(mail.connection_id)
    const result = key
      ? await sendBrevo(deps.fetch, key, mail)
      : { ok: false as const, kind: 'auth' as const, message: 'Kein API-Key hinterlegt' }
    await deps.db.report(mail.outbox_id, result)
    if (result.ok) sent++
    else failed++
  }
  return { sent, failed }
}

async function testMail(req: Request, deps: ScDeps): Promise<{ ok: boolean; message: string | null }> {
  const jwt = bearerToken(req)
  const userId = await deps.db.callerUserId(jwt)
  if (!userId) throw new FunctionError(401, 'SC_UNAUTHENTICATED')
  if (!(await deps.db.callerHasScEdit(jwt))) throw new FunctionError(403, 'SC_FORBIDDEN')

  const body = await readBody(req)
  if (!isUuid(body.connection_id)) throw new FunctionError(400, 'SC_BAD_REQUEST')
  const connectionId = body.connection_id

  const mail = await deps.db.testPrepare(connectionId, userId)
  const key = await deps.db.connectionKey(connectionId)
  if (!key) throw new FunctionError(422, 'SC_KEY_MISSING')
  const result = await sendBrevo(deps.fetch, key, mail)
  const message = result.ok ? null : sanitize(result.message, key)
  await deps.db.testReport(connectionId, userId, result.ok, message)
  return { ok: result.ok, message }
}

export async function handleSend(req: Request, deps: ScDeps): Promise<Response> {
  const origin = req.headers.get('origin')
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders(origin) })

  try {
    if (req.method !== 'POST') throw new FunctionError(400, 'SC_BAD_REQUEST')

    const secret = req.headers.get('x-sc-dispatch-secret')
    if (secret !== null) {
      if (!(await deps.db.checkDispatchSecret(secret))) throw new FunctionError(403, 'SC_FORBIDDEN')
      return json(200, await dispatch(deps), origin)
    }
    return json(200, await testMail(req, deps), origin)
  } catch (error) {
    if (error instanceof FunctionError) {
      const code = error.code.replace(/^AD_/, 'SC_')
      return json(error.status, { code }, origin)
    }
    const code = error instanceof Error ? error.message : ''
    if (code in RPC_STATUS) return json(RPC_STATUS[code], { code }, origin)
    console.error('sc-send failed', error instanceof Error ? error.name : 'unknown')
    return json(500, { code: 'SC_UNEXPECTED' }, origin)
  }
}
