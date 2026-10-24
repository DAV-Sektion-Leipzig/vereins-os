// Kontrollliste Punktekonto Kletterhalle (US-EZ-16, T032) aus ez_climbing_points_report; ohne Namen.
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import { loadEzAccess } from '@/features/ez/access'
import { todayIso } from '@/features/ez/dates'
import { loadLocations, type Location } from '@/features/ez/shared/locations'
import { supabase } from '@/lib/supabase'

export type ReportRow = { event_id: string; start_date: string; group_name: string; participants_present: number; trial_count: number }

export type ReportFilter = { location: string; from: string; to: string }

export type ReportResult = { filter: ReportFilter; locations: Location[]; rows: ReportRow[]; failed: boolean }

/** Standard: Vormonat (spec.md 6). */
export function previousMonth(today = todayIso()): { from: string; to: string } {
  const [y, m] = today.split('-').map(Number)
  const year = m === 1 ? y - 1 : y
  const month = m === 1 ? 12 : m - 1
  const last = new Date(Date.UTC(year, month, 0)).getUTCDate()
  const mm = String(month).padStart(2, '0')
  return { from: `${year}-${mm}-01`, to: `${year}-${mm}-${String(last).padStart(2, '0')}` }
}

export function reportHref(filter: ReportFilter): string {
  const p = new URLSearchParams()
  if (filter.location) p.set('ort', filter.location)
  if (filter.from) p.set('von', filter.from)
  if (filter.to) p.set('bis', filter.to)
  return `/ez/kletterhalle?${p.toString()}`
}

export async function loadReport({ request }: LoaderFunctionArgs): Promise<ReportResult> {
  const access = await loadEzAccess()
  // Navigation „Kontrolle Kletterhalle“ nur mit EZ ≥ bearbeiten oder Admin (spec.md 6)
  if (!access.canEdit && !access.canReadAll) throw redirect('/kein-zugriff')
  const locations = (await loadLocations()).filter((l) => l.has_climbing_points)
  const p = new URL(request.url).searchParams
  const month = previousMonth()
  const filter = { location: p.get('ort') ?? locations.find((l) => l.is_active)?.id ?? '', from: p.get('von') ?? month.from, to: p.get('bis') ?? month.to }
  if (!filter.location) return { filter, locations, rows: [], failed: false }
  const { data, error } = await supabase.rpc('ez_climbing_points_report', {
    p_location: filter.location,
    p_from: filter.from || null,
    p_to: filter.to || null,
  })
  if (error || !Array.isArray(data)) return { filter, locations, rows: [], failed: true }
  return { filter, locations, rows: data as ReportRow[], failed: false }
}
