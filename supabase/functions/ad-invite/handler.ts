// ad-invite (US-AD-08, spec T9): Einladung verschicken bzw. erneut verschicken, mit Aufräumen bei Fehlern (AK5).
import { corsHeaders } from '../_shared/cors.ts'
import { bearerToken, errorResponse, FunctionError, isUuid, json, readJsonBody } from '../_shared/responses.ts'
import type { AccessStatus, Deps } from '../_shared/types.ts'

type ApplyResult = { status: AccessStatus; last_invited_at: string }[]

export async function handleInvite(req: Request, deps: Deps): Promise<Response> {
  const origin = req.headers.get('origin')
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders(origin) })

  try {
    // Recht des Aufrufers zuerst (contracts/edge-functions.md, AK6); ohne gültiges JWT 401
    const jwt = bearerToken(req)
    const caller = deps.caller(jwt)
    const actor = await caller.userId()
    if (!actor) throw new FunctionError(401, 'AD_UNAUTHENTICATED')
    if (!(await caller.hasAdEdit())) throw new FunctionError(403, 'AD_FORBIDDEN')

    const body = await readJsonBody(req)
    if (!isUuid(body.person_id)) throw new FunctionError(400, 'AD_BAD_REQUEST')
    const personId = body.person_id

    if (!(await deps.db.personExists(personId))) throw new FunctionError(404, 'AD_PERSON_NOT_FOUND')
    const access = await deps.db.getAccess(personId)
    if (!access || !access.login_email) throw new FunctionError(422, 'AD_EMAIL_MISSING')
    if (!(await deps.db.emailAllowed(access.login_email))) throw new FunctionError(422, 'AD_EMAIL_DOMAIN')
    const existingUser = await deps.auth.findUserIdByEmail(access.login_email)
    if (existingUser && existingUser !== access.auth_user_id) throw new FunctionError(409, 'AD_EMAIL_TAKEN')
    if (!(await deps.db.hasActiveTemplate(personId))) throw new FunctionError(422, 'AD_NO_TEMPLATE')
    if (access.status !== 'none' && access.status !== 'invited') throw new FunctionError(409, 'AD_INVALID_STATUS')

    // Ausgangsstand merken (für das Aufräumen bei Fehlern der Auth-Admin-API)
    const before = { status: access.status, auth_user_id: access.auth_user_id, last_invited_at: access.last_invited_at }

    const invite = await deps.auth.inviteUserByEmail(access.login_email, `${deps.siteUrl}/passwort-setzen`)
    if (invite.error) {
      // Neu angelegten Auth-Eintrag entfernen; der Insert-Trigger hat den Zugang ggf. schon verknüpft
      if (!before.auth_user_id) {
        const created = invite.userId ?? (await deps.auth.findUserIdByEmail(access.login_email))
        if (created) {
          const deleteError = await deps.auth.deleteUser(created)
          // Verwaister Auth-Eintrag würde die nächste Einladung mit AD_EMAIL_TAKEN blockieren: im Log sichtbar machen
          if (deleteError) console.error('ad-invite: Aufräumen des Auth-Eintrags fehlgeschlagen', { personId, deleteError })
        }
      }
      await deps.db.rpc('ad_revert_invite', {
        p_person: personId,
        p_status: before.status,
        p_auth_user: before.auth_user_id,
        p_last_invited_at: before.last_invited_at,
      })
      throw new FunctionError(502, 'AD_MAIL_FAILED')
    }

    const result = await deps.db.rpc<ApplyResult>('ad_apply_invite', {
      p_person: personId,
      p_auth_user: invite.userId ?? before.auth_user_id,
      p_actor: actor,
    })
    const row = result[0]
    return json(200, { status: row?.status ?? 'invited', last_invited_at: row?.last_invited_at ?? null }, origin)
  } catch (error) {
    return errorResponse(error, origin)
  }
}
