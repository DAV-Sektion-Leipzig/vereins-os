// Aufruf der EZ-Funktionen (security definer, spec.md EZ 2) mit Meldung nach contracts/error-codes.md.
import { ezError, type EzError } from '@/features/ez/errors'
import { personName } from '@/lib/format'
import { supabase } from '@/lib/supabase'

export type EzResult<T> = { data: T; error: null } | { data: null; error: EzError }

export async function ezRpc<T = unknown>(name: string, args: Record<string, unknown>): Promise<EzResult<T>> {
  try {
    const { data, error } = await supabase.rpc(name, args)
    if (error) return { data: null, error: ezError(error) }
    return { data: data as T, error: null }
  } catch (caught) {
    return { data: null, error: ezError(caught) }
  }
}

export type PersonNames = Record<string, string>

/** Namen über ea_person_names (nur sichtbare Personen, R44 AD; höchstens 500 IDs). */
export async function loadPersonNames(ids: (string | null | undefined)[]): Promise<PersonNames> {
  const unique = [...new Set(ids.filter((id): id is string => !!id))]
  if (unique.length === 0) return {}
  const names: PersonNames = {}
  for (let i = 0; i < unique.length; i += 500) {
    const { data, error } = await supabase.rpc('ea_person_names', { p_ids: unique.slice(i, i + 500) })
    if (error || !Array.isArray(data)) continue
    for (const row of data as { id: string; first_name: string; preferred_name: string | null; last_name: string }[]) {
      names[row.id] = personName(row)
    }
  }
  return names
}

/** Name oder Platzhalter, wenn die Person nicht (mehr) sichtbar ist. */
export function nameOf(names: PersonNames, id: string | null | undefined): string {
  return (id && names[id]) || 'unbekannte Person'
}
