// Abrechnung mit Positionen, Bestätigungen und Verlauf (US-FI-02 bis -12, FT12) aus fi_get_settlement.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadFiAccess } from '@/features/fi/access'
import { fiError } from '@/features/fi/errors'
import type { Position, RateRole, SettlementStatus } from '@/features/fi/labels'
import { supabase } from '@/lib/supabase'

export type Item = {
  id: string
  event_id: string
  event_date: string
  event_kind: string
  event_label: string | null
  span: 'single' | 'multi'
  end_date: string | null
  start_time: string | null
  end_time: string | null
  day_category: string | null
  referat_id: string
  referat_name: string
  group_id: string | null
  group_name: string | null
  remuneration_kind: string | null
  position: Position
  recorded_role: 'trainer' | 'helper' | null
  calc_rate_role: RateRole
  calc_quantity: number
  override_rate_role: RateRole | null
  override_quantity: number | null
  rate_role: RateRole
  quantity: number
  correction_reason: string | null
  exception_reason: string | null
  rate: number | null
  amount: number | null
  hints: string[]
}

export type Confirmation = {
  referat_id: string
  referat_name: string
  confirmed_at: string | null
  confirmed_by_name: string | null
  is_substitute: boolean | null
  substitute_reason: string | null
  can_confirm: boolean
}

export type LogEntry = { action: string; detail: Record<string, unknown> | null; at: string; by_name: string | null }

export type Settlement = {
  id: string
  person_id: string
  year: number
  half: 1 | 2
  status: SettlementStatus
  amount: number
  display_name: string
  closed_at: string | null
  closed_by_name: string | null
  submitted_on: string | null
  submitted_late_reason: string | null
  expired_at: string | null
  payout_run_id: string | null
  deadline: string | null
  has_new_events: boolean
}

export type SettlementInfo = {
  hints: string[]
  max: { year: number; total: number; limit: number | null }
  payable: boolean
  not_payable_reasons: string[]
}

export type SettlementDetail = {
  settlement: Settlement
  info: SettlementInfo
  items: Item[]
  confirmations: Confirmation[]
  log: LogEntry[]
  can_manage: boolean
}

export type DetailResult = { detail: SettlementDetail | null; notFound: boolean }

export async function fetchSettlement(id: string): Promise<DetailResult> {
  const { data, error } = await supabase.rpc('fi_get_settlement', { p_id: id })
  if (error || !data) return { detail: null, notFound: !error || fiError(error).code === 'FI_NOT_FOUND' }
  return { detail: data as SettlementDetail, notFound: false }
}

export async function loadSettlement({ params }: LoaderFunctionArgs): Promise<DetailResult> {
  await loadFiAccess()
  return fetchSettlement(params.id ?? '')
}
