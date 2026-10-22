-- US-AD-06, US-AD-24, spec T6 (Teil), T41, T26 (Teil): Personenübersicht, ad_me mit Rufname,
-- Verwendung einer Qualifikationsart.

-- Übersicht für /ad; Zeilen nach der RLS der Basistabellen (security_invoker)
create view public.ad_v_person_overview
with (security_invoker = true)
as
select p.id as person_id,
       p.first_name,
       p.preferred_name,
       p.last_name,
       p.kind,
       p.created_in,
       p.volunteer_status,
       p.volunteer_status_since,
       a.login_email,
       coalesce(a.status, 'none') as access_status,
       -- Gruppenbezug bis zur ersten GR-Migration über das Anlagemodul [ANNAHME v0.7]
       p.created_in = 'GR' as has_group_relation,
       coalesce((
         select array_agg(
                  t.name || coalesce(' (' || (
                    select string_agg(r.name, ', ' order by r.sort_order, r.name)
                      from public.ad_assignment_referate ar
                      join public.ea_referate r on r.id = ar.referat_id
                     where ar.assignment_id = ta.id
                  ) || ')', '')
                  order by t.name)
           from public.ad_template_assignments ta
           join public.ad_templates t on t.id = ta.template_id
          where ta.person_id = p.id
            and ta.revoked_at is null
            and (ta.valid_from is null or ta.valid_from <= current_date)
            and (ta.valid_to is null or ta.valid_to >= current_date)
       ), '{}') as templates
  from public.ea_persons p
  left join public.ad_accesses a on a.person_id = p.id;

revoke all on table public.ad_v_person_overview from public, anon, authenticated;
grant select on table public.ad_v_person_overview to authenticated;

-- Eigene Person und eigener Zugang, jetzt mit Rufname (Rückgabe wächst → neu anlegen)
drop function public.ad_me();

create function public.ad_me()
returns table (person_id uuid, first_name text, last_name text, preferred_name text,
               access_status public.ad_access_status)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.first_name, p.last_name, p.preferred_name, a.status
    from public.ad_accesses a
    join public.ea_persons p on p.id = a.person_id
   where a.auth_user_id = auth.uid();
$$;

revoke all on function public.ad_me() from public, anon, authenticated;
grant execute on function public.ad_me() to authenticated;

-- Anzahl verschiedener Personen mit einer Eigenschaft, die auf die Qualifikationsart verweist (nur die Zahl)
create function public.ad_qualification_usage(p_id uuid)
returns int
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_can_edit_qualification_types() then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return (
    select count(distinct p.person_id)::int
      from public.ea_properties p
      join public.ea_property_fields f
        on f.property_type_id = p.property_type_id and f.data_type = 'qualification_type'
     where p.field_values ->> f.key = p_id::text
  );
end;
$$;

revoke all on function public.ad_qualification_usage(uuid) from public, anon, authenticated;
grant execute on function public.ad_qualification_usage(uuid) to authenticated;
