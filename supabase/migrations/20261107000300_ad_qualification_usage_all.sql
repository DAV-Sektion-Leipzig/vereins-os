-- US-AD-17 (spec AD v0.12.1, Entscheidung Product Owner 27.10.2026): Verwendung aller Qualifikationsarten auf einmal
-- für die Spalte „Personen“ in der Liste. Zählt je Qualifikationsart verschiedene Personen mit einer aktuellen
-- Eigenschaft (valid_from <= heute <= valid_to), deren field_values auf die Art verweist. Nur die Zahl, auch über
-- vertrauliche Eigenschaftsarten; erlaubt wie ad_qualification_usage (ad_can_edit_qualification_types).
create function public.ad_qualification_usage_all()
returns table (qualification_type_id uuid, persons int)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_can_edit_qualification_types() then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
    select (p.field_values ->> f.key)::uuid as qualification_type_id,
           count(distinct p.person_id)::int as persons
      from public.ea_properties p
      join public.ea_property_fields f
        on f.property_type_id = p.property_type_id and f.data_type = 'qualification_type'
     where nullif(p.field_values ->> f.key, '') is not null
       and p.valid_from <= current_date
       and (p.valid_to is null or p.valid_to >= current_date)
     group by 1;
end;
$$;

revoke all on function public.ad_qualification_usage_all() from public, anon, authenticated;
grant execute on function public.ad_qualification_usage_all() to authenticated;
