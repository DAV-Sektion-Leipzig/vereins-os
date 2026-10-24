// Referate und Gremien pflegen (US-EA-14; T050). Schreiben dürfen AD ≥ bearbeiten oder EA = verwalten (RLS).
import { requireEaManage } from '@/features/ea/access'
import { supabase } from '@/lib/supabase'

export type MasterTable = 'ea_referate' | 'ea_gremien'

export type MasterRow = { id: string; name: string; sort_order: number; is_active: boolean }

export type MasterInput = { name: string; sort_order: number; is_active: boolean }

export type StammdatenResult = { referate: MasterRow[]; gremien: MasterRow[]; failed: boolean }

export async function loadStammdaten(): Promise<StammdatenResult> {
  // nur mit verwalten (US-EA-14 AK5), vor jeder Datenabfrage
  await requireEaManage()
  const [referate, gremien] = await Promise.all([
    supabase.from('ea_referate').select('id, name, sort_order, is_active').order('sort_order').order('name'),
    supabase.from('ea_gremien').select('id, name, sort_order, is_active').order('sort_order').order('name'),
  ])
  if (referate.error || gremien.error) return { referate: [], gremien: [], failed: true }
  return { referate: referate.data as MasterRow[], gremien: gremien.data as MasterRow[], failed: false }
}

/** Neu (id = null) oder Bearbeiten; doppelte Bezeichnung meldet der Unique-Index (US-EA-14 AK3). */
export async function saveMasterRow(table: MasterTable, id: string | null, input: MasterInput) {
  const row = { name: input.name.trim(), sort_order: input.sort_order, is_active: input.is_active }
  const { error } = id ? await supabase.from(table).update(row).eq('id', id) : await supabase.from(table).insert(row)
  return error ?? null
}
