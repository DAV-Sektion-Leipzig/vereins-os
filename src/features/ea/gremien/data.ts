// Gremium-Sichten (US-EA-13; T049): je aktivem Gremium die heute gültigen Mitgliedschaften (committee).
import { requireEaManage } from '@/features/ea/access'
import { supabase } from '@/lib/supabase'

export type Membership = {
  id: string
  personId: string
  firstName: string
  preferredName: string | null
  lastName: string
  role: string | null
  validFrom: string
  validTo: string | null
}

export type GremiumView = { id: string; name: string; members: Membership[] }

export type GremienResult = { gremien: GremiumView[]; failed: boolean }

type MembershipRow = {
  id: string
  person_id: string
  related_gremium_id: string | null
  field_values: { role?: string }
  valid_from: string
  valid_to: string | null
  ea_persons: { first_name: string; preferred_name: string | null; last_name: string } | null
}

export async function loadGremien(): Promise<GremienResult> {
  // nur mit verwalten (US-EA-01 AK5), vor jeder Datenabfrage
  await requireEaManage()
  const today = new Date().toISOString().slice(0, 10)

  const [gremien, type] = await Promise.all([
    supabase.from('ea_gremien').select('id, name').eq('is_active', true).order('sort_order'),
    supabase.from('ea_property_types').select('id').eq('system_key', 'committee').maybeSingle(),
  ])
  if (gremien.error || type.error || !type.data) return { gremien: [], failed: true }

  const memberships = await supabase
    .from('ea_properties')
    .select('id, person_id, related_gremium_id, field_values, valid_from, valid_to, ea_persons(first_name, preferred_name, last_name)')
    .eq('property_type_id', type.data.id)
    .lte('valid_from', today)
    .or(`valid_to.is.null,valid_to.gte.${today}`)
  if (memberships.error) return { gremien: [], failed: true }

  const rows = memberships.data as unknown as MembershipRow[]
  return {
    failed: false,
    gremien: (gremien.data as { id: string; name: string }[]).map((g) => ({
      ...g,
      members: rows
        .filter((r) => r.related_gremium_id === g.id && r.ea_persons)
        .map((r) => ({
          id: r.id,
          personId: r.person_id,
          firstName: r.ea_persons!.first_name,
          preferredName: r.ea_persons!.preferred_name,
          lastName: r.ea_persons!.last_name,
          role: r.field_values.role ?? null,
          validFrom: r.valid_from,
          validTo: r.valid_to,
        }))
        .sort((a, b) => a.lastName.localeCompare(b.lastName, 'de') || a.firstName.localeCompare(b.firstName, 'de')),
    })),
  }
}
