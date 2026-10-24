-- Anwesenheitserfassung (EZ), spec T3; spec.md EZ v0.5 Abschnitt 2 „Trigger“, R9, R19; research.md R-EZ-09, R-EZ-10.

-- Person des angemeldeten Nutzers (für „erfasst von“, „geändert von“, „abgesagt von“); intern
create function public.ez_my_person_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select a.person_id from public.ad_accesses a where a.auth_user_id = auth.uid();
$$;

revoke all on function public.ez_my_person_id() from public, anon, authenticated;

-- Referat aus der Gruppe (Stand bei Anlage), Audit
create function public.ez_events_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.group_id is not null then
    select g.referat_id into new.referat_id from public.gr_groups g where g.id = new.group_id;
  end if;
  new.created_at := now();
  new.created_by := coalesce(auth.uid(), new.created_by);
  new.created_by_person_id := coalesce(public.ez_my_person_id(), new.created_by_person_id);
  new.updated_at := null;
  new.updated_by := null;
  new.updated_by_person_id := null;
  return new;
end;
$$;

-- Sperre unveränderlicher Felder (R19, R25), Audit
create function public.ez_events_before_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.kind is distinct from old.kind
     or new.group_id is distinct from old.group_id
     or new.tk_plan_id is distinct from old.tk_plan_id
     or new.client_request_id is distinct from old.client_request_id
     or new.created_at is distinct from old.created_at
     or new.created_by is distinct from old.created_by
     or new.created_by_person_id is distinct from old.created_by_person_id
     or (new.referat_id is distinct from old.referat_id and (old.group_id is not null or old.tk_plan_id is not null)) then
    raise exception 'EZ_FIELD_LOCKED' using errcode = 'P0001';
  end if;
  new.updated_at := now();
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  new.updated_by_person_id := coalesce(public.ez_my_person_id(), new.updated_by_person_id);
  return new;
end;
$$;

create function public.ez_attendances_set_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    new.created_by := coalesce(auth.uid(), new.created_by);
    new.updated_at := null;
    new.updated_by := null;
  else
    new.created_at := old.created_at;
    new.created_by := old.created_by;
    new.updated_at := now();
    new.updated_by := coalesce(auth.uid(), new.updated_by);
  end if;
  return new;
end;
$$;

revoke all on function public.ez_events_before_insert() from public, anon, authenticated;
revoke all on function public.ez_events_before_update() from public, anon, authenticated;
revoke all on function public.ez_attendances_set_audit() from public, anon, authenticated;

create trigger ez_events_before_insert
  before insert on public.ez_events
  for each row execute function public.ez_events_before_insert();

create trigger ez_events_before_update
  before update on public.ez_events
  for each row execute function public.ez_events_before_update();

create trigger ez_attendances_set_audit
  before insert or update on public.ez_attendances
  for each row execute function public.ez_attendances_set_audit();
