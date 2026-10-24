-- US-GR-02, US-GR-05, US-GR-15, US-GR-19, US-GR-20, spec T8 (GR spec.md 2.3, R13, R17, R20): Views und Lesefunktionen
-- für die Oberfläche und die Anwesenheitserfassung. Die EZ-Rechte (ad_has_level('EZ', …), ad_my_referate('EZ', …))
-- greifen erst mit Nachtrag v0.8 der Administration (plan.md O2, research.md R-GR-11).

-- Name der anlegenden Person eines Eintrags (für „angelegt von“); nur mit GR lesen; intern für Views
create function public.gr_user_name(p_user uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(p.preferred_name, p.first_name) || ' ' || p.last_name
    from public.ad_accesses a
    join public.ea_persons p on p.id = a.person_id
   where a.auth_user_id = p_user and public.ad_has_level('GR', 'read');
$$;

revoke all on function public.gr_user_name(uuid) from public, anon, authenticated;
grant execute on function public.gr_user_name(uuid) to authenticated;

-- Teilnahmen mit Vertragsstatus und Hinweisen (R2, R7, R17); Alter rechnet das Frontend aus birth_date (W2)
create view public.gr_v_memberships
with (security_invoker = true)
as
select m.id as membership_id,
       m.group_id,
       m.person_id,
       pe.first_name,
       pe.preferred_name,
       pe.last_name,
       m.joined_on,
       m.left_on,
       (select (b.field_values ->> 'date')::date
          from public.ea_properties b
          join public.ea_property_types t on t.id = b.property_type_id and t.system_key = 'birth_date'
         where b.person_id = m.person_id
         order by b.valid_from desc
         limit 1) as birth_date,
       c.id as contract_id,
       case when c.id is not null then public.gr_contract_status(c.ends_on, public.gr_today()) end as contract_status,
       c.ends_on as contract_ends_on,
       coalesce((select pc.granted from public.gr_photo_consents pc
                  where pc.person_id = m.person_id
                  order by pc.effective_on desc, pc.created_at desc, pc.id desc
                  limit 1), false) as photo_consent,
       s.needs_clarification,
       case when s.needs_clarification then
         (select max(c2.ends_on) from public.gr_contracts c2 where c2.membership_id = m.id) end as clarify_since,
       exists (select 1 from public.gr_emergency_contacts e where e.child_person_id = m.person_id) as has_emergency_contact,
       public.gr_needs_guardian(m.person_id) as needs_guardian
  from public.gr_memberships m
  join public.ea_persons pe on pe.id = m.person_id
  left join lateral (
    select c.* from public.gr_contracts c where c.membership_id = m.id order by c.starts_on desc limit 1
  ) c on true
  cross join lateral (
    select (m.left_on is null or m.left_on >= public.gr_today())
           and not exists (select 1 from public.gr_contracts c3
                            where c3.membership_id = m.id and (c3.ends_on is null or c3.ends_on >= public.gr_today()))
           as needs_clarification
  ) s;

-- Offene Aufnahmen (/gr/aufnahmen)
create view public.gr_v_pending_admissions
with (security_invoker = true)
as
select a.person_id,
       pe.first_name,
       pe.preferred_name,
       pe.last_name,
       a.group_id,
       g.name as group_name,
       a.created_at,
       public.gr_user_name(a.created_by) as created_by_name,
       public.gr_needs_guardian(a.person_id) as needs_guardian
  from public.gr_pending_admissions a
  join public.ea_persons pe on pe.id = a.person_id
  join public.gr_groups g on g.id = a.group_id;

revoke all on table public.gr_v_memberships, public.gr_v_pending_admissions from public, anon, authenticated;
grant select on table public.gr_v_memberships, public.gr_v_pending_admissions to authenticated;

-- Wochentag als Kürzel; intern
create function public.gr_weekday_label(p_weekday smallint)
returns text
language sql
immutable
set search_path = ''
as $$
  select (array['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'])[p_weekday];
$$;

revoke all on function public.gr_weekday_label(smallint) from public, anon, authenticated;
grant execute on function public.gr_weekday_label(smallint) to authenticated;

-- Gruppenübersicht (US-GR-02); security invoker: RLS entscheidet
create function public.gr_group_overview(p_include_dissolved boolean default false)
returns table (id uuid, name text, referat_id uuid, referat_name text, dissolved_on date, training_times_today text,
               active_count int, clarify_count int, no_emergency_count int, pending_count int)
language sql
stable
security invoker
set search_path = ''
as $$
  select g.id, g.name, g.referat_id, r.name, g.dissolved_on,
         (select string_agg(public.gr_weekday_label(tt.weekday) || ' ' || to_char(tt.starts_at, 'HH24:MI') || '–'
                            || to_char(tt.ends_at, 'HH24:MI'), ' · ' order by tt.weekday, tt.starts_at)
            from public.gr_training_times tt
           where tt.group_id = g.id and tt.valid_from <= public.gr_today()
             and (tt.valid_to is null or tt.valid_to >= public.gr_today())),
         (select count(*)::int from public.gr_memberships m
           where m.group_id = g.id and m.joined_on <= public.gr_today()
             and (m.left_on is null or m.left_on >= public.gr_today())),
         (select count(*)::int from public.gr_v_memberships v where v.group_id = g.id and v.needs_clarification),
         (select count(*)::int from public.gr_v_memberships v
           where v.group_id = g.id and (v.left_on is null or v.left_on >= public.gr_today()) and not v.has_emergency_contact),
         (select count(*)::int from public.gr_pending_admissions a where a.group_id = g.id)
    from public.gr_groups g
    join public.ea_referate r on r.id = g.referat_id
   where public.ad_has_level('GR', 'read')
     and (p_include_dissolved or g.dissolved_on is null)
   order by g.name;
$$;

-- E-Mail-Liste der Erziehungsberechtigten (R13, A9); volljährige Teilnehmer:innen mit eigener Adresse
create function public.gr_guardian_emails(p_group uuid)
returns setof text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := public.gr_today();
begin
  if not public.ad_has_level('GR', 'read') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  with active as (
    select m.person_id from public.gr_memberships m
     where m.group_id = p_group and m.joined_on <= v_today and (m.left_on is null or m.left_on >= v_today)
  ), recipients as (
    select g.guardian_person_id as person_id
      from active a join public.gr_guardians g on g.child_person_id = a.person_id
     where not public.gr_is_adult(a.person_id, v_today)
    union
    select a.person_id from active a where public.gr_is_adult(a.person_id, v_today)
  )
  select min(btrim(c.field_values ->> 'email'))
    from recipients r
    join public.ea_properties c on c.person_id = r.person_id
    join public.ea_property_types t on t.id = c.property_type_id and t.system_key = 'contact'
   where c.field_values ? 'email' and c.valid_from <= v_today and (c.valid_to is null or c.valid_to >= v_today)
   group by lower(btrim(c.field_values ->> 'email'))
   order by lower(btrim(c.field_values ->> 'email'));
end;
$$;

-- Rolle einer Funktion in Gruppe; intern
create function public.gr_role(p_function text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_function when 'Gruppenleitung' then 'group_lead' when 'Trainer:in' then 'trainer'
                         when 'Helfer:in' then 'helper' end;
$$;

revoke all on function public.gr_role(text) from public, anon, authenticated;

-- Namensliste je Gruppe und Stichtag für die Anwesenheitserfassung (R20, US-GR-19)
create function public.gr_group_roster(p_group_id uuid, p_date date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_date date := coalesce(p_date, public.gr_today());
  v_all boolean := public.ad_has_level('GR', 'read') or public.ad_has_level('EZ', 'read');
  v_referate uuid[] := public.ad_my_referate('EZ', 'read');
  v_group record;
begin
  if not v_all and cardinality(v_referate) = 0 then
    raise exception 'GR_ROSTER_FORBIDDEN' using errcode = 'P0001';
  end if;
  select g.id, g.name, g.referat_id, r.name as referat_name, g.dissolved_on into v_group
    from public.gr_groups g join public.ea_referate r on r.id = g.referat_id
   where g.id = p_group_id;
  if not found or (v_group.dissolved_on is not null and v_group.dissolved_on < v_date) then
    raise exception 'GR_GROUP_NOT_FOUND' using errcode = 'P0001';
  end if;
  if not v_all and not (v_group.referat_id = any (v_referate)) then
    raise exception 'GR_ROSTER_FORBIDDEN' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'group', jsonb_build_object('id', v_group.id, 'name', v_group.name, 'referat_id', v_group.referat_id,
                                'referat_name', v_group.referat_name),
    'training_times', coalesce((
      select jsonb_agg(jsonb_build_object('starts_at', to_char(tt.starts_at, 'HH24:MI'),
                                          'ends_at', to_char(tt.ends_at, 'HH24:MI')) order by tt.starts_at)
        from public.gr_training_times tt
       where tt.group_id = p_group_id and tt.weekday = extract(isodow from v_date)
         and tt.valid_from <= v_date and (tt.valid_to is null or tt.valid_to >= v_date)), '[]'),
    'persons', coalesce((
      select jsonb_agg(jsonb_build_object('person_id', x.person_id, 'first_name', x.first_name,
                                          'preferred_name', x.preferred_name, 'last_name', x.last_name, 'role', x.role)
                       order by x.role_order, x.last_name, coalesce(x.preferred_name, x.first_name), x.person_id)
        from (
          select distinct pe.id as person_id, pe.first_name, pe.preferred_name, pe.last_name,
                 public.gr_role(p.field_values ->> 'function') as role,
                 array_position(array['group_lead', 'trainer', 'helper', 'participant'],
                                public.gr_role(p.field_values ->> 'function')) as role_order
            from public.ea_properties p
            join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
            join public.ea_persons pe on pe.id = p.person_id and pe.kind = 'human'
           where p.related_group_id = p_group_id
             and p.valid_from <= v_date and (p.valid_to is null or p.valid_to >= v_date)
          union
          select pe.id, pe.first_name, pe.preferred_name, pe.last_name, 'participant', 4
            from public.gr_memberships m
            join public.ea_persons pe on pe.id = m.person_id and pe.kind = 'human'
           where m.group_id = p_group_id
             and m.joined_on <= v_date and (m.left_on is null or m.left_on >= v_date)
        ) x), '[]'));
end;
$$;

-- Wählbare Gruppen für die Anwesenheitserfassung (US-GR-19 AK8)
create function public.gr_groups_for_attendance(p_date date)
returns table (group_id uuid, group_name text, referat_id uuid, referat_name text)
language sql
stable
security definer
set search_path = ''
as $$
  select g.id, g.name, g.referat_id, r.name
    from public.gr_groups g
    join public.ea_referate r on r.id = g.referat_id
   where (g.dissolved_on is null or g.dissolved_on >= coalesce(p_date, public.gr_today()))
     and (public.ad_has_level('GR', 'read') or public.ad_has_level('EZ', 'read')
          or g.referat_id = any (public.ad_my_referate('EZ', 'read')))
   order by g.name;
$$;

-- Eigene Gruppen des angemeldeten Nutzers (US-GR-20)
create function public.gr_my_groups(p_date date)
returns table (group_id uuid, group_name text, referat_id uuid, referat_name text, function text, weekdays smallint[])
language sql
stable
security definer
set search_path = ''
as $$
  with me as (
    select m.person_id from public.ad_me() m where m.access_status = 'active'
  ), d as (
    select coalesce(p_date, public.gr_today()) as day
  )
  select g.id, g.name, g.referat_id, r.name, public.gr_role(p.field_values ->> 'function'),
         coalesce(array(
           select distinct tt.weekday from public.gr_training_times tt
            where tt.group_id = g.id and tt.valid_from <= d.day and (tt.valid_to is null or tt.valid_to >= d.day)
            order by tt.weekday), '{}')
    from me
    cross join d
    join public.ea_properties p on p.person_id = me.person_id
    join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
    join public.gr_groups g on g.id = p.related_group_id
    join public.ea_referate r on r.id = g.referat_id
   where p.valid_from <= d.day and (p.valid_to is null or p.valid_to >= d.day)
     and (g.dissolved_on is null or g.dissolved_on >= d.day)
   order by g.name, public.gr_role(p.field_values ->> 'function');
$$;

revoke all on function public.gr_group_overview(boolean) from public, anon, authenticated;
revoke all on function public.gr_guardian_emails(uuid) from public, anon, authenticated;
revoke all on function public.gr_group_roster(uuid, date) from public, anon, authenticated;
revoke all on function public.gr_groups_for_attendance(date) from public, anon, authenticated;
revoke all on function public.gr_my_groups(date) from public, anon, authenticated;
grant execute on function public.gr_group_overview(boolean) to authenticated;
grant execute on function public.gr_guardian_emails(uuid) to authenticated;
grant execute on function public.gr_group_roster(uuid, date) to authenticated;
grant execute on function public.gr_groups_for_attendance(date) to authenticated;
grant execute on function public.gr_my_groups(date) to authenticated;
