// Auszahlungsrunden (US-FI-14 bis -16, FT14): Liste aus fi_list_payout_runs, Runde aus fi_preview_payout_run.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { requireFiManage } from '@/features/fi/access'
import type { RunStatus } from '@/features/fi/labels'
import { supabase } from '@/lib/supabase'

export type RunRow = {
  id: string
  year: number
  half: 1 | 2
  number: number
  status: RunStatus
  execution_date: string
  line_count: number | null
  total: number | null
  settlement_count: number
  released_at: string | null
  released_by_name: string | null
}

export type RunsResult = { runs: RunRow[]; failed: boolean }

export async function loadRuns(): Promise<RunsResult> {
  await requireFiManage()
  const { data, error } = await supabase.rpc('fi_list_payout_runs', {})
  if (error || !Array.isArray(data)) return { runs: [], failed: true }
  return { runs: data as RunRow[], failed: false }
}

export type Run = {
  id: string
  year: number
  half: 1 | 2
  number: number
  status: RunStatus
  execution_date: string
  msg_id: string | null
  pmt_inf_id: string | null
  line_count: number | null
  total: number | null
  released_at: string | null
}

export type PreviewLine = { settlement_id: string; last_name: string; first_name: string; group_label: string; amount: number }
export type Available = { settlement_id: string; display_name: string; amount: number; payable: boolean; reasons: string[] }

export type RunPreview = { run: Run; lines: PreviewLine[]; total: number; available: Available[] }

export type RunResult = { preview: RunPreview | null; failed: boolean }

export async function loadRun({ params }: LoaderFunctionArgs): Promise<RunResult> {
  await requireFiManage()
  const { data, error } = await supabase.rpc('fi_preview_payout_run', { p_run: params.id ?? '' })
  if (error || !data) return { preview: null, failed: true }
  return { preview: data as RunPreview, failed: false }
}
