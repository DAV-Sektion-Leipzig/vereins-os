// ad-access (US-AD-08 AK7, US-AD-09; spec T10): sperren, entsperren, Login-Adresse bei „eingeladen“ ändern.
import { corsHeaders } from '../_shared/cors.ts'
import { bearerToken, errorResponse, FunctionError, isUuid, json, readJsonBody } from '../_shared/responses.ts'
import type { AccessStatus, Deps } from '../_shared/types.ts'

const ACTIONS = ['lock', 'unlock', 'change_email'] as const
type Action = (typeof ACTIONS)[number]

export async function handleAccess(req: Request, deps: Deps): Promise<Response> {
  const origin = req.headers.get('origin')
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders(origin) })

  try {
    const jwt = bearerToken(req)
    const body = await readJsonBody(req)
    const action = body.action as Action
    if (!isUuid(body.person_id) || !ACTIONS.includes(action)) throw new FunctionError(400, 'AD_BAD_REQUEST')
    const personId = body.person_id
    const newEmail = typeof body.login_email === 'string' ? body.login_email.trim() : ''
    // login_email nur bei change_email (contracts/edge-functions.md)
    if ((action === 'change_email') !== (newEmail !== '')) throw new FunctionError(400, 'AD_BAD_REQUEST')

    const caller = deps.caller(jwt)
    const actor = await caller.userId()
    if (!actor) throw new FunctionError(401, 'AD_UNAUTHENTICATED')
    if (!(await caller.hasAdEdit())) throw new FunctionError(403, 'AD_FORBIDDEN')

    if (!(await deps.db.personExists(personId))) throw new FunctionError(404, 'AD_PERSON_NOT_FOUND')
    const access = await deps.db.getAccess(personId)
    const status: AccessStatus = access?.status ?? 'none'

    if (action === 'lock') {
      if (!access || (status !== 'invited' && status !== 'active')) throw new FunctionError(409, 'AD_INVALID_STATUS')
      if (access.auth_user_id) {
        const err = await deps.auth.setBanned(access.auth_user_id, true)
        if (err) throw new Error(err)
      }
      const result = await deps.db.rpc<{ status: AccessStatus }[]>('ad_apply_lock', { p_person: personId, p_actor: actor })
      return json(200, { status: result[0]?.status ?? 'locked' }, origin)
    }

    if (action === 'unlock') {
      if (!access || status !== 'locked') throw new FunctionError(409, 'AD_INVALID_STATUS')
      if (access.auth_user_id) {
        const err = await deps.auth.setBanned(access.auth_user_id, false)
        if (err) throw new Error(err)
      }
      const result = await deps.db.rpc<{ status: AccessStatus }[]>('ad_apply_unlock', { p_person: personId, p_actor: actor })
      return json(200, { status: result[0]?.status ?? 'active' }, origin)
    }

    // change_email (R20): nur bei „eingeladen“; R1, R2; alter Link wird ungültig
    if (!access || status !== 'invited') throw new FunctionError(409, 'AD_EMAIL_LOCKED')
    if (!(await deps.db.emailAllowed(newEmail))) throw new FunctionError(422, 'AD_EMAIL_DOMAIN')
    if (await deps.db.emailUsedByOtherAccess(newEmail, personId)) throw new FunctionError(409, 'AD_EMAIL_TAKEN')
    const otherUser = await deps.auth.findUserIdByEmail(newEmail)
    if (otherUser && otherUser !== access.auth_user_id) throw new FunctionError(409, 'AD_EMAIL_TAKEN')
    if (access.auth_user_id) {
      const err = await deps.auth.deleteUser(access.auth_user_id)
      if (err) throw new Error(err)
    }
    await deps.db.rpc('ad_apply_email_change', { p_person: personId, p_new_email: newEmail, p_actor: actor })
    return json(200, { status: 'none', code: 'AD_EMAIL_CHANGED' }, origin)
  } catch (error) {
    return errorResponse(error, origin)
  }
}
