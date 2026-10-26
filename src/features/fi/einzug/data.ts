// Buchungsläufe Verträge (US-FI-18 bis US-FI-21, FT23) aus fi_list_collection_runs und fi_get_collection_run.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { requireFiManage } from '@/features/fi/access'
import { monthLabel } from '@/features/fi/labels'
import { supabase } from '@/lib/supabase'

export function runTitle(r: { month: string; number: number }) {
  return `${monthLabel(r.month)} – Lauf ${r.number}`
}

export type CollectionStatus = 'draft' | 'released'
export type Sequence = 'FRST' | 'RCUR'

export type CollectionRunRow = {
  id: string
  month: string
  number: number
  status: CollectionStatus
  due_date: string
  line_count: number | null
  total: number | null
  included_count: number
  included_total: number
  released_at: string | null
  released_by_name: string | null
}

export type RunsResult = { runs: CollectionRunRow[]; collectionStart: string | null; failed: boolean }

export async function loadCollectionRuns(): Promise<RunsResult> {
  await requireFiManage()
  const [runs, start] = await Promise.all([supabase.rpc('fi_list_collection_runs'), supabase.rpc('ad_collection_start')])
  if (runs.error || !Array.isArray(runs.data)) return { runs: [], collectionStart: null, failed: true }
  return { runs: runs.data as CollectionRunRow[], collectionStart: (start.data as string | null) ?? null, failed: false }
}

export type CollectionLine = {
  id: string
  contract_id: string
  included: boolean
  excluded_reason: string | null
  participant_name: string
  participant_last_name: string
  holder_name: string | null
  group_id: string
  group_label: string
  mandate_reference: string
  mandate_signed_on: string
  iban_last4: string | null
  sequence: Sequence
  monthly_amount: number
  extra_amount: number | null
  extra_text: string | null
  extra_reason: string | null
  amount: number
  remittance: string | null
  end_to_end_id: string | null
  sort_no: number | null
  bank_changed_since_last: boolean
}

export type CollectionRun = {
  id: string
  month: string
  number: number
  status: CollectionStatus
  due_date: string
  msg_id: string | null
  pmt_inf_id_frst: string | null
  pmt_inf_id_rcur: string | null
  line_count: number | null
  total: number | null
  released_at: string | null
  released_by_name: string | null
}

export type CollectionDetail = { run: CollectionRun; settings_ok: boolean; min_due_date: string; lines: CollectionLine[] }

export type DetailResult = { detail: CollectionDetail | null; failed: boolean }

export async function loadCollectionRun({ params }: LoaderFunctionArgs): Promise<DetailResult> {
  await requireFiManage()
  const { data, error } = await supabase.rpc('fi_get_collection_run', { p_run: params.id ?? '' })
  if (error || !data) return { detail: null, failed: true }
  return { detail: data as CollectionDetail, failed: false }
}
