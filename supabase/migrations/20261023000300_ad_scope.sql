-- US-AD-20, US-AD-21, spec T33: Reichweite „Referat“ (R30, nur EA im Kern), Referate je Zuweisung (R31),
-- ad_my_referate, ad_has_any_level, neue Fassungen von ad_user_level, ad_my_modules, ad_assign_template.
-- Der Check auf scope wird mit T50 (EZ) und T59 (TK, TKF) per neuer Migration erweitert (research.md R-18).

-- Reichweite als Enum
alter table public.ad_template_rights drop constraint ad_template_rights_scope_mvp;
alter table public.ad_template_rights alter column scope drop default;
alter table public.ad_template_rights alter column scope type public.ad_scope using scope::public.ad_scope;
alter table public.ad_template_rights alter column scope set default 'all';
alter table public.ad_template_rights
  add constraint ad_template_rights_scope_allowed
  check (scope = 'all' or (scope = 'referat' and module_code = 'EA'));

-- R30 mit Fehlercode vor dem Check
create function public.ad_template_rights_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.scope = 'referat' and new.module_code <> 'EA' then
    raise exception 'AD_SCOPE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_template_rights_guard() from public, anon, authenticated;

create trigger ad_template_rights_guard
  before insert or update of scope, module_code on public.ad_template_rights
  for each row execute function public.ad_template_rights_guard();

grant update (scope) on table public.ad_template_rights to authenticated;

-- Referate je Zuweisung (R31)
create table public.ad_assignment_referate (
  assignment_id uuid not null references public.ad_template_assignments (id) on delete cascade,
  referat_id uuid not null references public.ea_referate (id),
  primary key (assignment_id, referat_id)
);

comment on table public.ad_assignment_referate is
  'Referate einer Zuweisung mit Reichweite „Referat“; schreiben nur über ad_assign_template und ad_set_assignment_referate.';

create index ad_assignment_referate_referat on public.ad_assignment_referate (referat_id);

alter table public.ad_assignment_referate enable row level security;
revoke all on table public.ad_assignment_referate from public, anon, authenticated;
grant select on table public.ad_assignment_referate to authenticated;

create policy ad_assignment_referate_select on public.ad_assignment_referate
  for select to authenticated using (public.ad_has_level('AD', 'read'));

-- Rechte mit Reichweite „alle“ (R5, R6, R30); Rechte mit Reichweite „Referat“ zählen hier nicht
create or replace function public.ad_user_level(p_module text)
returns public.ad_level
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_level public.ad_level;
begin
  select max(r.level)
    into v_level
    from public.ad_accesses a
    join public.ad_template_assignments ta on ta.person_id = a.person_id
    join public.ad_template_rights r on r.template_id = ta.template_id
   where a.auth_user_id = auth.uid()
     and a.status = 'active'
     and ta.revoked_at is null
     and (ta.valid_from is null or ta.valid_from <= current_date)
     and (ta.valid_to is null or ta.valid_to >= current_date)
     and r.module_code = p_module
     and r.object is null
     and r.scope = 'all';

  return coalesce(v_level, 'none');
end;
$$;

-- Referate des aufrufenden Nutzers für ein Modul mit Reichweite „Referat“ und Stufe ≥ p_min
create function public.ad_my_referate(p_module text, p_min public.ad_level)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct ar.referat_id), '{}')
    from public.ad_accesses a
    join public.ad_template_assignments ta on ta.person_id = a.person_id
    join public.ad_template_rights r on r.template_id = ta.template_id
    join public.ad_assignment_referate ar on ar.assignment_id = ta.id
   where a.auth_user_id = auth.uid()
     and a.status = 'active'
     and ta.revoked_at is null
     and (ta.valid_from is null or ta.valid_from <= current_date)
     and (ta.valid_to is null or ta.valid_to >= current_date)
     and r.module_code = p_module
     and r.object is null
     and r.scope = 'referat'
     and r.level >= p_min;
$$;

-- Recht in irgendeiner Reichweite (Navigation, Routenschutz)
create function public.ad_has_any_level(p_module text, p_min public.ad_level)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level(p_module, p_min)
      or cardinality(public.ad_my_referate(p_module, p_min)) > 0;
$$;

revoke all on function public.ad_my_referate(text, public.ad_level) from public, anon, authenticated;
revoke all on function public.ad_has_any_level(text, public.ad_level) from public, anon, authenticated;
grant execute on function public.ad_my_referate(text, public.ad_level) to authenticated;
grant execute on function public.ad_has_any_level(text, public.ad_level) to authenticated;

-- Module für Startseite und Navigation; Stufe = höchste über beide Reichweiten
create or replace function public.ad_my_modules()
returns table (code text, name text, level public.ad_level)
language sql
stable
security definer
set search_path = ''
as $$
  with lv as (
    select m.code, m.name, m.sort_order,
           greatest(
             public.ad_user_level(m.code),
             coalesce((
               select max(r.level)
                 from public.ad_accesses a
                 join public.ad_template_assignments ta on ta.person_id = a.person_id
                 join public.ad_template_rights r on r.template_id = ta.template_id
                where a.auth_user_id = auth.uid()
                  and a.status = 'active'
                  and ta.revoked_at is null
                  and (ta.valid_from is null or ta.valid_from <= current_date)
                  and (ta.valid_to is null or ta.valid_to >= current_date)
                  and r.module_code = m.code
                  and r.object is null
                  and r.scope = 'referat'
                  and exists (select 1 from public.ad_assignment_referate ar where ar.assignment_id = ta.id)
             ), 'none')
           ) as level
      from public.ad_modules m
     where m.is_available
  )
  select lv.code, lv.name, lv.level
    from lv
   where lv.level >= 'read'
   order by lv.sort_order;
$$;

-- Hat die Vorlage ein Recht mit Reichweite „Referat“? (R31)
create function public.ad_template_needs_referate(p_template uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ad_template_rights r
     where r.template_id = p_template and r.scope = 'referat' and r.level > 'none'
  );
$$;

revoke all on function public.ad_template_needs_referate(uuid) from public, anon, authenticated;

-- Referate prüfen (R31): mindestens eines, alle vorhanden und aktiv; liefert die Namen für das Protokoll
create function public.ad_check_referate(p_referate uuid[])
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ids uuid[] := array(select distinct x from unnest(coalesce(p_referate, '{}')) as x where x is not null);
  v_names text;
begin
  if cardinality(v_ids) = 0 or exists (
    select 1 from unnest(v_ids) as x
     where not exists (select 1 from public.ea_referate r where r.id = x and r.is_active)
  ) then
    raise exception 'AD_REFERAT_REQUIRED' using errcode = 'P0001';
  end if;

  select string_agg(r.name, ', ' order by r.sort_order, r.name)
    into v_names
    from public.ea_referate r
   where r.id = any (v_ids);

  return v_names;
end;
$$;

revoke all on function public.ad_check_referate(uuid[]) from public, anon, authenticated;

-- Vorlage zuweisen (R13, R31, US-AD-11, US-AD-21); neue Signatur mit Referaten
drop function public.ad_assign_template(uuid, uuid);

create function public.ad_assign_template(p_person uuid, p_template uuid, p_referate uuid[] default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
  v_needs boolean;
  v_referat_names text;
  v_assignment uuid;
begin
  if not public.ad_has_level('AD', 'edit') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  select t.name into v_name from public.ad_templates t where t.id = p_template;

  if exists (
    select 1 from public.ad_template_assignments ta
     where ta.person_id = p_person and ta.template_id = p_template and ta.revoked_at is null
  ) then
    return;
  end if;

  v_needs := public.ad_template_needs_referate(p_template);
  if v_needs then
    v_referat_names := public.ad_check_referate(p_referate);
  end if;

  insert into public.ad_template_assignments (person_id, template_id)
  values (p_person, p_template)
  returning id into v_assignment;

  -- Bei Vorlagen ohne Reichweite „Referat“ werden keine Referate gespeichert (R31)
  if v_needs then
    insert into public.ad_assignment_referate (assignment_id, referat_id)
    select distinct v_assignment, x from unnest(p_referate) as x where x is not null;
  end if;

  insert into public.ad_audit_log (subject_person_id, action, details)
  values (p_person, 'template_assigned',
          v_name || coalesce(' (Referate: ' || v_referat_names || ')', ''));
end;
$$;

-- Referate einer Zuweisung ändern (R31, US-AD-21 AK3)
create function public.ad_set_assignment_referate(p_assignment uuid, p_referate uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
  v_template uuid;
  v_name text;
  v_old text;
  v_new text;
begin
  if not public.ad_has_level('AD', 'edit') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  select ta.person_id, ta.template_id, t.name
    into v_person, v_template, v_name
    from public.ad_template_assignments ta
    join public.ad_templates t on t.id = ta.template_id
   where ta.id = p_assignment and ta.revoked_at is null;

  if v_person is null or not public.ad_template_needs_referate(v_template) then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  v_new := public.ad_check_referate(p_referate);

  select string_agg(r.name, ', ' order by r.sort_order, r.name)
    into v_old
    from public.ad_assignment_referate ar
    join public.ea_referate r on r.id = ar.referat_id
   where ar.assignment_id = p_assignment;

  delete from public.ad_assignment_referate where assignment_id = p_assignment;
  insert into public.ad_assignment_referate (assignment_id, referat_id)
  select distinct p_assignment, x from unnest(p_referate) as x where x is not null;

  insert into public.ad_audit_log (subject_person_id, action, details)
  values (v_person, 'referate_changed', v_name || ': ' || coalesce(v_old, '–') || ' → ' || v_new);
end;
$$;

revoke all on function public.ad_assign_template(uuid, uuid, uuid[]) from public, anon, authenticated;
revoke all on function public.ad_set_assignment_referate(uuid, uuid[]) from public, anon, authenticated;
grant execute on function public.ad_assign_template(uuid, uuid, uuid[]) to authenticated;
grant execute on function public.ad_set_assignment_referate(uuid, uuid[]) to authenticated;
