// Orte aus ad_locations (lesbar mit aktivem Zugang, R43 AD; spec.md EZ R12, US-EZ-16).
import { supabase } from '@/lib/supabase'

export type Location = { id: string; name: string; is_active: boolean; has_climbing_points: boolean }

export async function loadLocations(): Promise<Location[]> {
  const { data, error } = await supabase.from('ad_locations').select('id, name, is_active, has_climbing_points').order('name')
  return error || !data ? [] : (data as Location[])
}
