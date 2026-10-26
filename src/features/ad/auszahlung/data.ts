// Abgabefristen, halbjährliche Abrechnung je Referat und Angaben der Sektion für die Auszahlung
// (spec.md AD v0.10, R53, R54; T129) sowie Gläubiger-ID, Sachkonto der Gruppenbeiträge und Stichtag des ersten
// Buchungslaufs (v0.11, R57, R58; T133). Pflege nur Admin (RLS, Trigger).
import { requireLevel } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type Deadline = { id: string; half: 1 | 2; deadline_month: number; deadline_day: number; valid_from: string }
export type ReferatFlag = { id: string; name: string; is_active: boolean; semiannual_settlement: boolean }
export type PayoutSettings = {
  id: string
  debtor_name: string
  iban: string
  bic: string
  ledger_account: string
  valid_from: string
  creditor_id: string | null
  ledger_account_collection: string | null
}

export type PayoutAdminData = {
  deadlines: Deadline[]
  referate: ReferatFlag[]
  settings: PayoutSettings[]
  /** Stichtag des ersten Buchungslaufs (1. eines Monats) oder null. */
  collectionStart: string | null
  failed: boolean
}

export async function loadPayoutAdmin(): Promise<PayoutAdminData> {
  await requireLevel('AD', 'read')
  const [deadlines, referate, settings, collection] = await Promise.all([
    supabase.from('ad_settlement_deadlines').select('id, half, deadline_month, deadline_day, valid_from').order('valid_from', { ascending: false }),
    supabase.from('ea_referate').select('id, name, is_active, semiannual_settlement').order('sort_order'),
    supabase
      .from('ad_payout_settings')
      .select('id, debtor_name, iban, bic, ledger_account, valid_from, creditor_id, ledger_account_collection')
      .order('valid_from', { ascending: false }),
    supabase.from('ad_collection_settings').select('start_month').maybeSingle(),
  ])
  if (deadlines.error || referate.error || settings.error || collection.error) {
    return { deadlines: [], referate: [], settings: [], collectionStart: null, failed: true }
  }
  return {
    deadlines: deadlines.data as Deadline[],
    referate: referate.data as ReferatFlag[],
    settings: settings.data as PayoutSettings[],
    collectionStart: (collection.data as { start_month: string } | null)?.start_month ?? null,
    failed: false,
  }
}

export function deadlineLabel(d: Pick<Deadline, 'deadline_day' | 'deadline_month'>) {
  return `${String(d.deadline_day).padStart(2, '0')}.${String(d.deadline_month).padStart(2, '0')}.`
}

/** IBAN in Vierergruppen; verdeckt nur mit den letzten 4 Stellen (spec.md AD Abschnitt 6). */
export function formatIban(iban: string, visible: boolean) {
  if (!visible) return `•••• ${iban.slice(-4)}`
  return iban.replace(/(.{4})/g, '$1 ').trim()
}

export async function saveDeadline(half: 1 | 2, day: number, month: number, validFrom: string) {
  return supabase
    .from('ad_settlement_deadlines')
    .insert({ half, deadline_day: day, deadline_month: month, valid_from: validFrom })
}

export async function setSemiannual(referatId: string, value: boolean) {
  return supabase.from('ea_referate').update({ semiannual_settlement: value }).eq('id', referatId)
}

export async function savePayoutSettings(input: Omit<PayoutSettings, 'id'>) {
  return supabase.from('ad_payout_settings').insert({
    debtor_name: input.debtor_name.trim(),
    iban: input.iban,
    bic: input.bic,
    ledger_account: input.ledger_account.trim(),
    valid_from: input.valid_from,
    creditor_id: input.creditor_id?.trim() || null,
    ledger_account_collection: input.ledger_account_collection?.trim() || null,
  })
}

/** Stichtag des ersten Buchungslaufs (R58): genau eine Zeile, anlegen oder ändern. */
export async function saveCollectionStart(month: string, exists: boolean) {
  const startMonth = `${month}-01`
  if (exists) return supabase.from('ad_collection_settings').update({ start_month: startMonth }).eq('id', true)
  return supabase.from('ad_collection_settings').insert({ start_month: startMonth })
}
