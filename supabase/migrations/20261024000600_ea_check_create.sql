-- US-EA-05, US-EA-10 (plan.md EA O3, Entscheidung Product Owner 23.10.2026): neue Fassung von ea_check_create.
-- Grundlage ist die Fassung aus 20261023001800_ad_review_1 (Lesestufe und Bezugsart der Eigenschaftsart, R29, R39);
-- nur die Codes beim Anlegen ändern sich, die Signatur und die übrigen Prüfungen bleiben:
--   ohne EA-Recht (z. B. Vorstand)            → EA_CREATE_FORBIDDEN        (statt AD_FORBIDDEN; US-EA-05 AK6)
--   Reichweite Referat ohne Funktion oder Amt → EA_CREATE_REFERAT_REQUIRED (statt EA_RELATION_REQUIRED; R3 EA)
--   fremdes Referat                           → EA_RELATION_FOREIGN_REFERAT (unverändert)
-- Genutzt von ea_create_volunteer und ea_activate_person.

create or replace function public.ea_check_create(p_property_type uuid, p_referat uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_type public.ea_property_types%rowtype;
  v_all boolean := public.ad_has_level('EA', 'edit');
begin
  if not v_all and cardinality(public.ad_my_referate('EA', 'edit')) = 0 then
    raise exception 'EA_CREATE_FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_property_type is not null then
    select * into v_type from public.ea_property_types t where t.id = p_property_type;
    if not found then
      raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
    end if;
    if v_type.read_level = 'confidential' and not public.ad_has_level('AD', 'edit') then
      raise exception 'AD_CONFIDENTIAL_ONLY_AD' using errcode = 'P0001';
    end if;
    if v_type.relation_kind = 'group' then
      raise exception 'EA_GROUP_RELATION_ONLY_GR' using errcode = 'P0001';
    end if;
    if p_referat is not null and v_type.relation_kind <> 'referat' then
      raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
    end if;
  end if;

  if v_all then
    return;
  end if;

  -- Reichweite Referat: erste Zuordnung (Funktion oder Amt) mit Bezug auf ein eigenes Referat ist Pflicht (R3 EA, R41 AD)
  if p_property_type is null or p_referat is null or v_type.relation_kind <> 'referat'
     or v_type.system_key is null or v_type.system_key not in ('function', 'position') then
    raise exception 'EA_CREATE_REFERAT_REQUIRED' using errcode = 'P0001';
  end if;
  if not (p_referat = any (public.ad_my_referate('EA', 'edit'))) then
    raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.ea_check_create(uuid, uuid) from public, anon, authenticated;
