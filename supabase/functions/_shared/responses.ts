// JSON-Antworten nach contracts/edge-functions.md: Erfolg mit Status, Fehler mit { code }.
import { corsHeaders } from './cors.ts'

export class FunctionError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
  ) {
    super(code)
  }
}

/** HTTP-Status je Fehlercode aus den internen Funktionen (raise exception '<CODE>'). */
export const RPC_STATUS: Record<string, number> = {
  AD_INVALID_STATUS: 409,
  AD_LAST_ADMIN: 409,
  AD_EMERGENCY_PROTECTED: 409,
  AD_SELF_LOCK: 409,
  AD_EMAIL_LOCKED: 409,
  AD_EMAIL_TAKEN: 409,
  AD_EMAIL_DOMAIN: 422,
  AD_NO_TEMPLATE: 422,
  AD_FORBIDDEN: 403,
}

export function json(status: number, body: unknown, origin: string | null): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) },
  })
}

export function errorResponse(error: unknown, origin: string | null): Response {
  if (error instanceof FunctionError) return json(error.status, { code: error.code }, origin)
  const code = error instanceof Error ? error.message : ''
  if (code in RPC_STATUS) return json(RPC_STATUS[code], { code }, origin)
  console.error('ad function failed', error)
  return json(500, { code: 'AD_UNEXPECTED' }, origin)
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && UUID.test(value)
}

/** Liest den JSON-Body eines POST; alles andere ist AD_BAD_REQUEST. */
export async function readJsonBody(req: Request): Promise<Record<string, unknown>> {
  if (req.method !== 'POST') throw new FunctionError(400, 'AD_BAD_REQUEST')
  try {
    const body = await req.json()
    if (typeof body !== 'object' || body === null || Array.isArray(body)) throw new Error()
    return body as Record<string, unknown>
  } catch {
    throw new FunctionError(400, 'AD_BAD_REQUEST')
  }
}

export function bearerToken(req: Request): string {
  const header = req.headers.get('authorization') ?? ''
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : ''
  if (!token) throw new FunctionError(401, 'AD_UNAUTHENTICATED')
  return token
}
