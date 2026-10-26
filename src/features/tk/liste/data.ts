// Liste der Planungen (US-TK-01): Filter in der Adresse (status, typ, jahr, seite), 50 je Seite.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { STATUSES } from '@/features/tk/labels'
import type { PlanStatus, PlanType } from '@/features/tk/types'
import { supabase } from '@/lib/supabase'

export type PlanRow = {
  id: string
  plan_type: PlanType
  referat_name: string
  status: PlanStatus
  title: string
  start_date: string | null
  end_date: string | null
  lead_name: string | null
  price_member_effective: number | null
  missing_count: number
  total_count: number
}

export type ListFilter = { status: PlanStatus[] | null; type: PlanType | null; year: number | null; page: number }
export type ListResult = { filter: ListFilter; rows: PlanRow[]; total: number; failed: boolean }

const TYPES: PlanType[] = ['guided_tour', 'course', 'community_tour']

export function parseFilter(params: URLSearchParams): ListFilter {
  const status = (params.get('status') ?? '').split(',').filter((s): s is PlanStatus => STATUSES.includes(s as PlanStatus))
  const type = params.get('typ')
  const year = Number(params.get('jahr'))
  const page = Math.max(1, Number(params.get('seite')) || 1)
  return {
    status: status.length > 0 ? status : null,
    type: TYPES.includes(type as PlanType) ? (type as PlanType) : null,
    year: Number.isInteger(year) && year > 2000 ? year : null,
    page,
  }
}

export function listHref(filter: ListFilter, page = 1): string {
  const p = new URLSearchParams()
  if (filter.status) p.set('status', filter.status.join(','))
  if (filter.type) p.set('typ', filter.type)
  if (filter.year) p.set('jahr', String(filter.year))
  if (page > 1) p.set('seite', String(page))
  const q = p.toString()
  return q ? `/tk?${q}` : '/tk'
}

export async function loadPlanList({ request }: LoaderFunctionArgs): Promise<ListResult> {
  const filter = parseFilter(new URL(request.url).searchParams)
  const { data, error } = await supabase.rpc('tk_list_plans', {
    p_year: filter.year,
    p_type: filter.type,
    p_status: filter.status,
    p_limit: PAGE_SIZE,
    p_offset: (filter.page - 1) * PAGE_SIZE,
  })
  if (error || !Array.isArray(data)) return { filter, rows: [], total: 0, failed: true }
  const rows = data as PlanRow[]
  return { filter, rows, total: rows[0]?.total_count ?? 0, failed: false }
}

/** Termin kompakt: „12.–16.07.2027“, „15.10.2027“, „30.06.–02.07.2027“. */
export function formatSpan(start: string | null, end: string | null): string {
  if (!start) return 'ohne Termin'
  const [y1, m1, d1] = start.split('-')
  if (!end || end === start) return `${d1}.${m1}.${y1}`
  const [y2, m2, d2] = end.split('-')
  if (y1 === y2 && m1 === m2) return `${d1}.–${d2}.${m2}.${y2}`
  if (y1 === y2) return `${d1}.${m1}.–${d2}.${m2}.${y2}`
  return `${d1}.${m1}.${y1}–${d2}.${m2}.${y2}`
}
