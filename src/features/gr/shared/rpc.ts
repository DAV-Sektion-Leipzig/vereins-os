// Aufruf der Gruppen-Funktionen (security definer, GR spec.md 2.3) mit Meldung nach contracts/error-codes.md.
import { toMessage } from '@/lib/errors'
import { supabase } from '@/lib/supabase'

export type RpcResult<T> = { data: T; error: null } | { data: null; error: string }

export async function grRpc<T = unknown>(name: string, args: Record<string, unknown>): Promise<RpcResult<T>> {
  try {
    const { data, error } = await supabase.rpc(name, args)
    if (error) return { data: null, error: toMessage(error).text }
    return { data: data as T, error: null }
  } catch (caught) {
    return { data: null, error: toMessage(caught).text }
  }
}

export type ReferatOption = { id: string; name: string; is_active: boolean }

/** Referate für die Auswahl; beim Anlegen und Ändern nur aktive (R21). */
export async function loadReferate(): Promise<ReferatOption[] | null> {
  const { data, error } = await supabase.from('ea_referate').select('id, name, is_active').order('sort_order').order('name')
  return error ? null : ((data ?? []) as ReferatOption[])
}
