// Protokoll (US-AD-14; T101) aus ad_v_audit_log; nur mit AD ≥ lesen (RLS), 50 je Seite, neueste zuerst.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { requireLevel } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type AuditAction =
  | 'invited'
  | 'email_changed'
  | 'template_assigned'
  | 'template_revoked'
  | 'referate_changed'
  | 'locked'
  | 'unlocked'
  | 'emergency_login'

export const ACTION_LABELS: Record<AuditAction, string> = {
  invited: 'eingeladen',
  email_changed: 'Login-Adresse geändert',
  template_assigned: 'Vorlage zugewiesen',
  template_revoked: 'Vorlage entzogen',
  referate_changed: 'Referate geändert',
  locked: 'gesperrt',
  unlocked: 'entsperrt',
  emergency_login: 'Anmeldung Notfall-Admin',
}

export type AuditRow = {
  id: number
  occurred_at: string
  actor_user_id: string | null
  actor_name: string | null
  subject_person_id: string
  subject_name: string
  action: AuditAction
  details: string | null
}

export type AuditResult = { rows: AuditRow[]; total: number; page: number; failed: boolean }

export async function loadAuditLog({ request }: LoaderFunctionArgs): Promise<AuditResult> {
  await requireLevel('AD', 'read')
  const raw = Number.parseInt(new URL(request.url).searchParams.get('seite') ?? '1', 10)
  const page = Number.isFinite(raw) && raw > 0 ? raw : 1
  const from = (page - 1) * PAGE_SIZE
  const { data, error, count } = await supabase
    .from('ad_v_audit_log')
    .select('*', { count: 'exact' })
    .order('occurred_at', { ascending: false })
    .order('id', { ascending: false })
    .range(from, from + PAGE_SIZE - 1)
  if (error) return { rows: [], total: 0, page, failed: true }
  return { rows: (data ?? []) as AuditRow[], total: count ?? 0, page, failed: false }
}
