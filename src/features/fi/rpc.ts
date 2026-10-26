// Aufruf der FI-Funktionen (security definer, spec.md FI 2) mit Meldung nach contracts/error-codes.md.
import { fiError, type FiError } from '@/features/fi/errors'
import { supabase } from '@/lib/supabase'

export type FiResult<T> = { data: T; error: null } | { data: null; error: FiError }

export async function fiRpc<T = unknown>(
  name: string,
  args: Record<string, unknown>,
  names?: Record<string, string>,
): Promise<FiResult<T>> {
  try {
    const { data, error } = await supabase.rpc(name, args)
    if (error) return { data: null, error: fiError(error, names) }
    return { data: data as T, error: null }
  } catch (caught) {
    return { data: null, error: fiError(caught, names) }
  }
}
