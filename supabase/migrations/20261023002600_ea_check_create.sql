-- US-EA-05, US-EA-10 (plan.md EA O3, Entscheidung Product Owner 23.10.2026): neue Fassung der Prüfung beim
-- Anlegen bzw. Übernehmen einer Person im Pfad EA. Gleiche Signatur und Eigenschaften wie in 20261023001100;
-- genutzt von ea_create_volunteer und ea_activate_person.
--   ohne EA-Recht (z. B. Vorstand)            → EA_CREATE_FORBIDDEN      (statt AD_FORBIDDEN; US-EA-05 AK6)
--   Reichweite Referat ohne Funktion oder Amt → EA_CREATE_REFERAT_REQUIRED (statt EA_RELATION_REQUIRED; R3 EA)
--   fremdes Referat                           → EA_RELATION_FOREIGN_REFERAT (unverändert)

create or replace function public.ea_check_create(p_property_type uuid, p_referat uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.ad_has_level('EA', 'edit') then
    return;
  end if;
  if cardinality(public.ad_my_referate('EA', 'edit')) = 0 then
    raise exception 'EA_CREATE_FORBIDDEN' using errcode = 'P0001';
  end if;
  -- Reichweite Referat: erste Zuordnung (Funktion oder Amt) mit Bezug auf ein eigenes Referat ist Pflicht (R3)
  if p_property_type is null or p_referat is null or not exists (
    select 1 from public.ea_property_types t
     where t.id = p_property_type and t.system_key in ('function', 'position')
  ) then
    raise exception 'EA_CREATE_REFERAT_REQUIRED' using errcode = 'P0001';
  end if;
  if not (p_referat = any (public.ad_my_referate('EA', 'edit'))) then
    raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.ea_check_create(uuid, uuid) from public, anon, authenticated;
