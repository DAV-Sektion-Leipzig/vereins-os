// Aufruf der TK-Funktionen (security definer, spec.md TK 2) mit Meldung nach contracts/error-codes.md.
import { tkError, type TkError } from '@/features/tk/errors'
import { supabase } from '@/lib/supabase'

export type TkResult<T> = { data: T; error: null } | { data: null; error: TkError }

export async function tkRpc<T = unknown>(name: string, args: Record<string, unknown>, action?: string): Promise<TkResult<T>> {
  try {
    const { data, error } = await supabase.rpc(name, args)
    if (error) return { data: null, error: tkError(error, action) }
    return { data: data as T, error: null }
  } catch (caught) {
    return { data: null, error: tkError(caught, action) }
  }
}
