// Abgleich Punktekonto Kletterhalle (US-FI-17, FT15): Kontrollliste aus fi_climbing_report, gespeicherte Abgleiche
// aus fi_list_climbing_checks; nur „FI verwalten“, keine Namen.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { previousMonth, type ReportRow } from '@/features/ez/kletterhalle/data'
import { loadLocations, type Location } from '@/features/ez/shared/locations'
import { requireFiManage } from '@/features/fi/access'
import { supabase } from '@/lib/supabase'

export type ClimbingFilter = { location: string; from: string; to: string }

export type ClimbingCheck = {
  id: string
  location_id: string
  location_name: string
  period_from: string
  period_to: string
  counted_without_trials: number
  counted_with_trials: number
  invoiced: number
  invoice_number: string | null
  remark: string | null
  created_at: string
  created_by_name: string | null
}

export type ClimbingResult = {
  filter: ClimbingFilter
  locations: Location[]
  rows: ReportRow[]
  checks: ClimbingCheck[]
  failed: boolean
}

export function climbingHref(filter: ClimbingFilter): string {
  const p = new URLSearchParams()
  if (filter.location) p.set('ort', filter.location)
  if (filter.from) p.set('von', filter.from)
  if (filter.to) p.set('bis', filter.to)
  return `/fi/kletterhalle?${p.toString()}`
}

export async function loadClimbing({ request }: LoaderFunctionArgs): Promise<ClimbingResult> {
  await requireFiManage()
  const locations = (await loadLocations()).filter((l) => l.has_climbing_points)
  const p = new URL(request.url).searchParams
  const month = previousMonth()
  const filter = {
    location: p.get('ort') ?? locations.find((l) => l.is_active)?.id ?? '',
    from: p.get('von') ?? month.from,
    to: p.get('bis') ?? month.to,
  }
  if (!filter.location) return { filter, locations, rows: [], checks: [], failed: false }
  const [report, checks] = await Promise.all([
    supabase.rpc('fi_climbing_report', { p_location: filter.location, p_from: filter.from || null, p_to: filter.to || null }),
    supabase.rpc('fi_list_climbing_checks', { p_location: filter.location }),
  ])
  if (report.error || !Array.isArray(report.data)) return { filter, locations, rows: [], checks: [], failed: true }
  return {
    filter,
    locations,
    rows: report.data as ReportRow[],
    checks: Array.isArray(checks.data) ? (checks.data as ClimbingCheck[]) : [],
    failed: false,
  }
}
