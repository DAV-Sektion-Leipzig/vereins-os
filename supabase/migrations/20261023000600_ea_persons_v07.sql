-- US-AD-23, US-AD-24, spec T37: Rufname, Modul der Anlage, Ehrenamtsstatus mit Historie.
-- Der Ehrenamtsstatus ist nur über die EA-Funktionen (T39) oder ohne Nutzerkontext änderbar (research.md R-23).
-- Die Policies auf ea_persons ersetzt T38; ea_volunteer_status_history erhält hier eine vorläufige Policy.

alter table public.ea_persons
  add column preferred_name text,
  add column created_in text not null default 'AD',
  add column volunteer_status public.ea_volunteer_status,
  add column volunteer_status_since date,
  add constraint ea_persons_created_in_check check (created_in in ('AD', 'EA', 'GR', 'script')),
  add constraint ea_persons_volunteer_status_since check ((volunteer_status is null) = (volunteer_status_since is null)),
  add constraint ea_persons_function_no_status check (kind = 'human' or volunteer_status is null);

comment on column public.ea_persons.created_in is 'Modul der Anlage (AD, EA, GR, script); nicht änderbar; EZ folgt mit spec T53.';
comment on column public.ea_persons.volunteer_status is 'Ehrenamtsstatus; null = gehört nicht zum Ehrenamtsmanagement (R32, R33).';

create index ea_persons_preferred_name_trgm on public.ea_persons using gin (preferred_name extensions.gin_trgm_ops);
create index ea_persons_volunteer_status on public.ea_persons (volunteer_status) where volunteer_status is not null;

-- R4 und Rufname: getrimmt, leerer Rufname → null
create or replace function public.ea_persons_normalize()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.first_name := btrim(coalesce(new.first_name, ''));
  new.last_name := btrim(coalesce(new.last_name, ''));
  new.preferred_name := nullif(btrim(coalesce(new.preferred_name, '')), '');
  if new.first_name = '' or new.last_name = '' then
    raise exception 'AD_NAME_REQUIRED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger ea_persons_normalize on public.ea_persons;
create trigger ea_persons_normalize
  before insert or update of first_name, last_name, preferred_name on public.ea_persons
  for each row execute function public.ea_persons_normalize();

-- kind und created_in unveränderlich; Ehrenamtsstatus nur ohne Nutzerkontext oder über die EA-Funktionen
create function public.ea_persons_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.kind is distinct from old.kind or new.created_in is distinct from old.created_in then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  if (new.volunteer_status is distinct from old.volunteer_status
      or new.volunteer_status_since is distinct from old.volunteer_status_since)
     and auth.uid() is not null
     and coalesce(current_setting('ea.status_change', true), '') <> 'on' then
    raise exception 'EA_STATUS_FORBIDDEN' using errcode = 'P0001';
  end if;

  return new;
end;
$$;

revoke all on function public.ea_persons_guard() from public, anon, authenticated;

create trigger ea_persons_guard
  before update on public.ea_persons
  for each row execute function public.ea_persons_guard();

-- Spaltenrechte: Rufname schreibbar; kind nur beim Anlegen
revoke update (kind) on table public.ea_persons from authenticated;
grant insert (preferred_name), update (preferred_name) on table public.ea_persons to authenticated;

-- View für die Fachmodule um die neuen Spalten erweitern (R15; Zeilen nach RLS auf ea_persons)
create or replace view public.ea_v_persons
with (security_invoker = true)
as
select id, first_name, last_name, kind, created_at, created_by,
       preferred_name, created_in, volunteer_status, volunteer_status_since
  from public.ea_persons
 where kind = 'human';

-- Historie des Ehrenamtsstatus (jeder Wechsel, auch der erste)
create table public.ea_volunteer_status_history (
  id bigint generated always as identity primary key,
  person_id uuid not null references public.ea_persons (id) on delete cascade,
  status public.ea_volunteer_status not null,
  valid_from date not null,
  set_at timestamptz not null default now(),
  set_by uuid default auth.uid() references auth.users (id) on delete set null
);

comment on table public.ea_volunteer_status_history is 'Wechsel des Ehrenamtsstatus; schreiben nur über die EA-Funktionen und ohne Nutzerkontext.';

create index ea_volunteer_status_history_person on public.ea_volunteer_status_history (person_id, set_at desc);

alter table public.ea_volunteer_status_history enable row level security;
revoke all on table public.ea_volunteer_status_history from public, anon, authenticated;
grant select on table public.ea_volunteer_status_history to authenticated;

-- vorläufig nur AD; T38 ersetzt die Policy durch ea_person_visible(person_id)
create policy ea_volunteer_status_history_select on public.ea_volunteer_status_history
  for select to authenticated using (public.ad_has_level('AD', 'read'));
