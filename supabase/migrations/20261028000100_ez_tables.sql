-- Anwesenheitserfassung (EZ), spec T1 und T2 (Teil); spec.md EZ v0.5 Abschnitt 2 und 3.
-- Typen, Rechtefunktionen, Tabellen mit Check ez_events_shape, Indizes, RLS und Select-Policies.
-- Für authenticated nur select; geschrieben wird ausschließlich über security-definer-Funktionen (research.md R-EZ-04).

create type public.ez_event_kind as enum (
  'training', 'day_trip', 'multi_day_trip', 'training_trip', 'competition', 'work_assignment', 'course', 'tour',
  'training_camp');
create type public.ez_span as enum ('single', 'multi');
create type public.ez_day_category as enum ('under_8h', 'at_least_8h');
create type public.ez_role as enum ('trainer', 'helper', 'participant');
create type public.ez_attendance_status as enum ('registered', 'present', 'absent');

-- Rechte (R13, R14); zentrale Stelle, damit Iteration 1 die Reichweite „Gruppe“ nur hier ergänzt
create function public.ez_can_read(p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('EZ', 'read')
      or coalesce(p_referat = any (public.ad_my_referate('EZ', 'read')), false);
$$;

create function public.ez_can_write(p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('EZ', 'edit')
      or coalesce(p_referat = any (public.ad_my_referate('EZ', 'edit')), false);
$$;

create function public.ez_can_delete()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('EZ', 'manage');
$$;

revoke all on function public.ez_can_read(uuid) from public, anon, authenticated;
revoke all on function public.ez_can_write(uuid) from public, anon, authenticated;
revoke all on function public.ez_can_delete() from public, anon, authenticated;
grant execute on function public.ez_can_read(uuid) to authenticated;
grant execute on function public.ez_can_write(uuid) to authenticated;
grant execute on function public.ez_can_delete() to authenticated;

-- Einsatz. created_by ohne Fremdschlüssel auf auth.users, damit das Aufräumen von Testnutzern in TEST nicht
-- an Einsätzen scheitert; „erfasst von“ zeigt created_by_person_id (research.md R-EZ-09).
create table public.ez_events (
  id uuid primary key default gen_random_uuid(),
  kind public.ez_event_kind not null,
  span public.ez_span not null,
  referat_id uuid not null references public.ea_referate (id) on delete restrict,
  group_id uuid references public.gr_groups (id) on delete restrict,
  title text,
  organizer_person_id uuid references public.ea_persons (id) on delete restrict,
  start_date date not null,
  start_time time,
  end_date date,
  end_time time,
  day_category public.ez_day_category,
  location_id uuid references public.ad_locations (id) on delete restrict,
  remark text,
  client_request_id uuid not null,
  tk_plan_id uuid,
  cancelled_at timestamptz,
  cancelled_by uuid,
  cancelled_by_person_id uuid references public.ea_persons (id) on delete set null,
  cancel_reason text,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid(),
  created_by_person_id uuid references public.ea_persons (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid,
  updated_by_person_id uuid references public.ea_persons (id) on delete set null,
  constraint ez_events_client_request_id_key unique (client_request_id),
  constraint ez_events_title_length check (title is null or (title = btrim(title) and char_length(title) between 1 and 90)),
  constraint ez_events_remark_length check (remark is null or (remark = btrim(remark) and char_length(remark) between 1 and 500)),
  constraint ez_events_cancel_reason check (
    (cancelled_at is null and cancel_reason is null)
    or (cancelled_at is not null and cancel_reason = btrim(cancel_reason) and char_length(cancel_reason) between 1 and 500)),
  constraint ez_events_tk_plan_kind check (tk_plan_id is null or kind in ('course', 'tour')),
  -- R1–R3, R28: Form je Einsatzart (Tabelle in spec.md 2); „leer“ = null
  constraint ez_events_shape check (
    case kind
      when 'training' then
        span = 'single' and group_id is not null and title is null and organizer_person_id is null
        and start_time is null and end_time is null and end_date is null and day_category is null
        and location_id is not null
      when 'day_trip' then
        span = 'single' and group_id is not null and title is not null and organizer_person_id is not null
        and location_id is null
      when 'multi_day_trip' then
        span = 'multi' and group_id is not null and title is not null and organizer_person_id is not null
        and location_id is null
      when 'training_trip' then
        group_id is not null and title is not null and organizer_person_id is not null and location_id is null
      when 'competition' then
        group_id is not null and title is not null and organizer_person_id is null and location_id is null
      when 'work_assignment' then
        group_id is null and title is not null and organizer_person_id is null and location_id is null
      when 'training_camp' then
        span = 'multi' and group_id is not null and title is not null and organizer_person_id is not null
        and location_id is null
      else -- course, tour
        group_id is null and title is not null and organizer_person_id is not null and location_id is null
    end
    and (kind = 'training'
         or case span
              when 'single' then end_date is null and start_time is null and end_time is null and day_category is not null
              else end_date is not null and end_date > start_date and day_category is null
            end))
);

comment on table public.ez_events is
  'Einsatz der Anwesenheitserfassung (spec.md EZ 2). Schreiben nur über ez_save_event, ez_cancel_event, ez_restore_event, ez_delete_event.';

create index ez_events_start_date on public.ez_events (start_date desc);
create index ez_events_referat_start on public.ez_events (referat_id, start_date desc);
create index ez_events_group_start on public.ez_events (group_id, start_date desc);
create index ez_events_location_training on public.ez_events (location_id, start_date) where kind = 'training';
create unique index ez_events_tk_plan_key on public.ez_events (tk_plan_id) where tk_plan_id is not null;
-- technisch ergänzt (plan.md H6): ez_person_visible und Fremdschlüssel
create index ez_events_organizer on public.ez_events (organizer_person_id) where organizer_person_id is not null;
create index ez_events_created_by_person on public.ez_events (created_by_person_id);
create index ez_events_updated_by_person on public.ez_events (updated_by_person_id) where updated_by_person_id is not null;

-- Weitere Gruppen einer Wettkampfbetreuung (R30); Prüfungen in ez_save_event
create table public.ez_event_groups (
  event_id uuid not null references public.ez_events (id) on delete cascade,
  group_id uuid not null references public.gr_groups (id) on delete restrict,
  primary key (event_id, group_id)
);

create index ez_event_groups_group on public.ez_event_groups (group_id);

-- Anwesenheit
create table public.ez_attendances (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.ez_events (id) on delete cascade,
  person_id uuid not null references public.ea_persons (id) on delete restrict,
  role public.ez_role not null,
  status public.ez_attendance_status not null default 'present',
  is_substitute boolean not null default false,
  from_plan boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz,
  updated_by uuid,
  constraint ez_attendances_event_person_key unique (event_id, person_id)
);

create index ez_attendances_person on public.ez_attendances (person_id);

-- Probetraining (nur Vorname, R6)
create table public.ez_trial_participants (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.ez_events (id) on delete cascade,
  first_name text not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  constraint ez_trial_participants_first_name check (first_name = btrim(first_name) and char_length(first_name) between 1 and 30)
);

create index ez_trial_participants_event on public.ez_trial_participants (event_id);

-- RLS: lesen über ez_can_read; keine Schreib-Policies, keine Schreib-Grants
alter table public.ez_events enable row level security;
alter table public.ez_event_groups enable row level security;
alter table public.ez_attendances enable row level security;
alter table public.ez_trial_participants enable row level security;

revoke all on table public.ez_events from public, anon, authenticated;
revoke all on table public.ez_event_groups from public, anon, authenticated;
revoke all on table public.ez_attendances from public, anon, authenticated;
revoke all on table public.ez_trial_participants from public, anon, authenticated;
grant select on table public.ez_events to authenticated;
grant select on table public.ez_event_groups to authenticated;
grant select on table public.ez_attendances to authenticated;
grant select on table public.ez_trial_participants to authenticated;

create policy ez_events_select on public.ez_events
  for select to authenticated using (public.ez_can_read(referat_id));

create policy ez_event_groups_select on public.ez_event_groups
  for select to authenticated using (exists (select 1 from public.ez_events e where e.id = event_id));

create policy ez_attendances_select on public.ez_attendances
  for select to authenticated using (exists (select 1 from public.ez_events e where e.id = event_id));

create policy ez_trial_participants_select on public.ez_trial_participants
  for select to authenticated using (exists (select 1 from public.ez_events e where e.id = event_id));
