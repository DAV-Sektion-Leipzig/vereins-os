// Kostenauswertung (US-TK-20): tk_cost_report je Jahr, Tourtyp, abgesagte; Referat filtert die Oberfläche.
import type { LoaderFunctionArgs } from 'react-router-dom'
import type { PlanStatus, PlanType } from '@/features/tk/types'
import { supabase } from '@/lib/supabase'
import { todayIso } from '@/lib/format'

export type ReportRow = {
  id: string
  title: string
  plan_type: PlanType
  referat_id: string
  referat_name: string
  start_date: string | null
  end_date: string | null
  status: PlanStatus
  fee_total: number | null
  org_total: number | null
  leader_costs: number | null
  fixed_costs: number | null
  total_costs: number | null
  price_member_effective: number | null
  min_participants: number | null
  max_participants: number | null
  result_min: number | null
  result_max: number | null
  section_bears: number | null
}

export type ReportFilter = { year: number; type: PlanType | null; referat: string | null; cancelled: boolean }
export type ReportResult = { filter: ReportFilter; rows: ReportRow[]; failed: boolean }

const MONEY_KEYS = [
  'fee_total', 'org_total', 'leader_costs', 'fixed_costs', 'total_costs', 'price_member_effective', 'result_min', 'result_max',
  'section_bears',
] as const

export function reportHref(f: ReportFilter): string {
  const p = new URLSearchParams()
  p.set('jahr', String(f.year))
  if (f.type) p.set('typ', f.type)
  if (f.referat) p.set('referat', f.referat)
  if (f.cancelled) p.set('abgesagt', '1')
  return `/tk/auswertung?${p.toString()}`
}

export async function loadReport({ request }: LoaderFunctionArgs): Promise<ReportResult> {
  const params = new URL(request.url).searchParams
  const year = Number(params.get('jahr')) || Number(todayIso().slice(0, 4))
  const typeParam = params.get('typ')
  const type = typeParam === 'guided_tour' || typeParam === 'course' || typeParam === 'community_tour' ? typeParam : null
  const filter: ReportFilter = { year, type, referat: params.get('referat'), cancelled: params.get('abgesagt') === '1' }
  const { data, error } = await supabase.rpc('tk_cost_report', { p_year: year, p_type: type, p_include_cancelled: filter.cancelled })
  if (error || !Array.isArray(data)) return { filter, rows: [], failed: true }
  const rows = (data as ReportRow[]).map((r) => {
    const copy = { ...r }
    for (const k of MONEY_KEYS) copy[k] = r[k] === null ? null : Number(r[k])
    return copy
  })
  return { filter, rows, failed: false }
}

const CSV_COLUMNS: { header: string; value: (r: ReportRow) => string | number | null; integer?: boolean }[] = [
  { header: 'Titel', value: (r) => r.title },
  { header: 'Tourtyp', value: (r) => r.plan_type },
  { header: 'Referat', value: (r) => r.referat_name },
  { header: 'Beginn', value: (r) => r.start_date },
  { header: 'Ende', value: (r) => r.end_date },
  { header: 'Status', value: (r) => r.status },
  { header: 'Vergütung', value: (r) => r.fee_total },
  { header: 'Organisationspauschale', value: (r) => r.org_total },
  { header: 'Kosten der Leitung', value: (r) => r.leader_costs },
  { header: 'Sonstige Kosten', value: (r) => r.fixed_costs },
  { header: 'Gesamtkosten', value: (r) => r.total_costs },
  { header: 'Beitrag Mitglieder', value: (r) => r.price_member_effective },
  { header: 'Mindestzahl', value: (r) => r.min_participants, integer: true },
  { header: 'Höchstzahl', value: (r) => r.max_participants, integer: true },
  { header: 'Ergebnis Mindestzahl', value: (r) => r.result_min },
  { header: 'Ergebnis Höchstzahl', value: (r) => r.result_max },
  { header: 'Sektion trägt', value: (r) => r.section_bears },
]

function cell(v: string | number | null, integer = false): string {
  if (v === null || v === undefined) return ''
  const text = typeof v === 'number' ? (integer ? String(v) : v.toFixed(2).replace('.', ',')) : v
  return /[;"\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text
}

/** CSV mit Semikolon, UTF-8 mit BOM (spec.md TK 6); keine Kontakt- oder Notfalldaten (US-TK-20 AK5). */
export function reportCsv(rows: ReportRow[]): string {
  const lines = [CSV_COLUMNS.map((c) => c.header).join(';')]
  for (const r of rows) lines.push(CSV_COLUMNS.map((c) => cell(c.value(r), c.integer)).join(';'))
  return `﻿${lines.join('\r\n')}\r\n`
}
