-- Planungshilfe Touren und Kurse (TK), spec T1 und T2; spec.md TK v0.4 Abschnitte 2 und 3; tasks.md T001, T002.
-- Typen, Rechtefunktionen, Tabellen mit Checks, Indizes, RLS und Select-Policies; tk_person_visible ersetzt den
-- Platzhalter der Administration. Für authenticated nur select; geschrieben wird ausschließlich über
-- security-definer-Funktionen (Abschnitt 2).

create type public.tk_plan_type as enum ('guided_tour', 'course', 'community_tour');
create type public.tk_plan_status as enum (
  'draft', 'submitted', 'query', 'approved', 'published', 'done', 'closed', 'cancelled');
create type public.tk_leader_role as enum ('lead', 'co_lead', 'helper');
create type public.tk_rate_kind as enum ('trainer', 'helper');
create type public.tk_transport as enum (
  'rail_long', 'rail_regional', 'coach', 'local_bus', 'tram', 'car', 'ecar', 'van', 'flight', 'bike');
create type public.tk_accommodation as enum ('none', 'hut', 'self_catering', 'hotel', 'camping');
create type public.tk_cost_group as enum ('leader', 'fixed', 'per_participant', 'self_paid');
create type public.tk_prebriefing as enum ('none', 'online', 'office');
create type public.tk_public_transport as enum ('together', 'possible', 'not_possible');
create type public.tk_image_source as enum ('own', 'referat');
create type public.tk_fitness as enum ('low', 'medium', 'high', 'very_high');
create type public.tk_technique as enum ('easy', 'medium', 'hard', 'very_hard');
create type public.tk_yolawo_by as enum ('referat', 'leader');

-- Rechte (Abschnitt 3); zentrale Stelle
create function public.tk_can_read(p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('TK', 'read')
      or coalesce(p_referat = any (public.ad_my_referate('TK', 'read')), false);
$$;

create function public.tk_can_write(p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('TK', 'edit')
      or coalesce(p_referat = any (public.ad_my_referate('TK', 'edit')), false);
$$;

-- Freigaberecht im Referat (R50 AD, Aktion „darf freigeben“)
create function public.tk_can_approve(p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.ad_can_approve('TK', p_referat), false);
$$;

create function public.tk_can_manage()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('TK', 'manage');
$$;

-- Kontakt- und Notfalldaten: nur wer bearbeiten darf (A3: Admin mit TK lesen nicht)
create function public.tk_can_read_contacts(p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.tk_can_write(p_referat);
$$;

revoke all on function public.tk_can_read(uuid) from public, anon, authenticated;
revoke all on function public.tk_can_write(uuid) from public, anon, authenticated;
revoke all on function public.tk_can_approve(uuid) from public, anon, authenticated;
revoke all on function public.tk_can_manage() from public, anon, authenticated;
revoke all on function public.tk_can_read_contacts(uuid) from public, anon, authenticated;
grant execute on function public.tk_can_read(uuid) to authenticated;
grant execute on function public.tk_can_write(uuid) to authenticated;
grant execute on function public.tk_can_approve(uuid) to authenticated;
grant execute on function public.tk_can_manage() to authenticated;
grant execute on function public.tk_can_read_contacts(uuid) to authenticated;

-- Planung. created_by ohne Fremdschlüssel auf auth.users (wie ez_events), „angelegt von“ über created_by_person_id.
create table public.tk_plans (
  id uuid primary key default gen_random_uuid(),
  plan_type public.tk_plan_type not null,
  referat_id uuid not null references public.ea_referate (id) on delete restrict,
  status public.tk_plan_status not null default 'draft',
  title text not null,
  community_reason text,
  sport text,
  target_groups text[] not null default '{}',
  region text,
  base text,
  teaser text,
  programme text,
  image_source public.tk_image_source,
  image_credit text,
  start_date date,
  end_date date,
  meet_time time,
  end_time time,
  meeting_point text,
  meeting_coords text,
  prebriefing public.tk_prebriefing not null default 'none',
  prebriefing_at timestamp,
  public_transport public.tk_public_transport,
  travel_notes text,
  accommodation public.tk_accommodation not null default 'none',
  nights int,
  co2_persons int,
  meeting_near_pt boolean not null default false,
  max_walk_hours numeric(4, 1),
  max_ascent int,
  max_descent int,
  max_distance_km numeric(6, 1),
  fitness public.tk_fitness,
  technique public.tk_technique,
  grade text,
  requirements text,
  equipment text,
  non_members_allowed boolean not null default false,
  non_members_reason text,
  min_participants int,
  max_participants int,
  registration_deadline date,
  waitlist boolean not null default true,
  accommodation_cancellation text,
  registration_questions text[] not null default array[
    'DAV-Mitgliedschaft (Sektion Leipzig / andere Sektion / kein Mitglied)', 'Mitgliedsnummer', 'Mobilnummer',
    'Notfallkontakt (Name, Telefon)', 'Hinweise an die Tourenleitung (z. B. gesundheitlich)',
    'Einwilligung: Ausschreibung und Voraussetzungen gelesen'],
  custom_question text,
  days_full int,
  days_half int,
  teaching_hours int,
  org_days int,
  car_reason text,
  no_fee boolean not null default false,
  price_member numeric(10, 2),
  price_non_member numeric(10, 2),
  yolawo_by public.tk_yolawo_by not null default 'referat',
  notes_for_referat text,
  confirm_license boolean not null default false,
  confirm_calculation boolean not null default false,
  confirm_ul_declaration boolean not null default false,
  confirm_emergency_card boolean not null default false,
  feedback_form boolean not null default false,
  touched text[] not null default '{}',
  rates_frozen_on date,
  yolawo_ref text,
  ez_event_id uuid,
  cancelled_at timestamptz,
  cancel_reason text,
  contacts_purged_at timestamptz,
  row_version int not null default 1,
  client_request_id uuid not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  created_by_person_id uuid references public.ea_persons (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid,
  updated_by_person_id uuid references public.ea_persons (id) on delete set null,
  constraint tk_plans_client_request_id_key unique (client_request_id),
  constraint tk_plans_title check (title = btrim(title) and char_length(title) between 1 and 90),
  constraint tk_plans_dates check (end_date is null or start_date is null or end_date >= start_date),
  constraint tk_plans_prebriefing check (prebriefing <> 'none' or prebriefing_at is null),
  constraint tk_plans_numbers check (
    coalesce(nights, 0) >= 0 and coalesce(co2_persons, 0) >= 0 and coalesce(max_walk_hours, 0) >= 0
    and coalesce(max_ascent, 0) >= 0 and coalesce(max_descent, 0) >= 0 and coalesce(max_distance_km, 0) >= 0
    and coalesce(min_participants, 1) >= 1 and coalesce(max_participants, 1) >= 1
    and coalesce(days_full, 0) >= 0 and coalesce(days_half, 0) >= 0 and coalesce(teaching_hours, 0) >= 0
    and coalesce(org_days, 0) >= 0 and coalesce(price_member, 0) >= 0 and coalesce(price_non_member, 0) >= 0),
  -- Freitexte höchstens 4.000 Zeichen [ANNAHME spec.md 2]; yolawo_ref 200; Absagegrund 1–500 (R21)
  constraint tk_plans_text_length check (
    char_length(coalesce(community_reason, '')) <= 4000 and char_length(coalesce(region, '')) <= 4000
    and char_length(coalesce(base, '')) <= 4000 and char_length(coalesce(teaser, '')) <= 4000
    and char_length(coalesce(programme, '')) <= 4000 and char_length(coalesce(image_credit, '')) <= 4000
    and char_length(coalesce(meeting_point, '')) <= 4000 and char_length(coalesce(meeting_coords, '')) <= 4000
    and char_length(coalesce(travel_notes, '')) <= 4000 and char_length(coalesce(grade, '')) <= 4000
    and char_length(coalesce(requirements, '')) <= 4000 and char_length(coalesce(equipment, '')) <= 4000
    and char_length(coalesce(non_members_reason, '')) <= 4000
    and char_length(coalesce(accommodation_cancellation, '')) <= 4000
    and char_length(coalesce(custom_question, '')) <= 4000 and char_length(coalesce(car_reason, '')) <= 4000
    and char_length(coalesce(notes_for_referat, '')) <= 4000 and char_length(coalesce(yolawo_ref, '')) <= 200),
  constraint tk_plans_cancel check (
    (cancelled_at is null and cancel_reason is null)
    or (cancelled_at is not null and cancel_reason = btrim(cancel_reason) and char_length(cancel_reason) between 1 and 500)),
  constraint tk_plans_sport check (sport is null or sport in (
    'Wandern', 'Sport- und Langstreckenwandern', 'Bergwandern', 'Bergsteigen', 'Klettersteig', 'Klettern',
    'Alpinklettern', 'Bouldern', 'Hochtour', 'Skitour', 'Schneeschuhtour', 'Skilanglauf', 'Ski alpin', 'Mountainbike',
    'Sonstiges')),
  constraint tk_plans_target_groups check (
    target_groups <@ array['Familienwanderungen', 'Flinke Füße', 'Einsteiger', 'FLINTA*']),
  constraint tk_plans_registration_questions check (
    registration_questions <@ array[
      'DAV-Mitgliedschaft (Sektion Leipzig / andere Sektion / kein Mitglied)', 'Mitgliedsnummer', 'Mobilnummer',
      'Notfallkontakt (Name, Telefon)', 'Geburtsdatum', 'Hinweise an die Tourenleitung (z. B. gesundheitlich)',
      'Verpflegungswunsch (z. B. vegetarisch)', 'Bahn-Ermäßigung (BahnCard, Deutschlandticket)',
      'Einwilligung: Kontaktdaten für Fahrgemeinschaften weitergeben',
      'Einwilligung: Ausschreibung und Voraussetzungen gelesen',
      'Tourenerfahrung: bisherige Touren mit Ziel, Schwierigkeit, geführt/selbst organisiert (Textfeld)']),
  constraint tk_plans_touched check (
    touched <@ array['days_full', 'days_half', 'org_days', 'teaching_hours', 'nights', 'co2_persons'])
);

comment on table public.tk_plans is
  'Planung der Planungshilfe Touren und Kurse (spec.md TK 2). Schreiben nur über tk_save_plan, tk_change_status, '
  'tk_copy_plan, tk_delete_plan, tk_purge_contacts.';

create index tk_plans_referat_start on public.tk_plans (referat_id, start_date);
create index tk_plans_status on public.tk_plans (status);
create index tk_plans_start on public.tk_plans (start_date);

-- Leitung und Helfende
create table public.tk_plan_leaders (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.tk_plans (id) on delete cascade,
  person_id uuid not null references public.ea_persons (id) on delete restrict,
  role public.tk_leader_role not null default 'lead',
  sort_order int not null,
  rate_kind public.tk_rate_kind not null default 'helper',
  license_type_id uuid references public.ad_qualification_types (id) on delete set null,
  license_valid_from date,
  license_valid_until date,
  constraint tk_plan_leaders_person_key unique (plan_id, person_id)
);

create index tk_plan_leaders_person on public.tk_plan_leaders (person_id);

-- Kontakt- und Notfalldaten (eigene Tabelle wegen RLS, R8, R16, R18)
create table public.tk_plan_contacts (
  leader_id uuid primary key references public.tk_plan_leaders (id) on delete cascade,
  plan_id uuid not null references public.tk_plans (id) on delete cascade,
  email text,
  mobile text,
  emergency_name text,
  emergency_phone text,
  constraint tk_plan_contacts_email check (email is null or (char_length(email) <= 200 and email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')),
  constraint tk_plan_contacts_mobile check (mobile is null or mobile ~ '^[0-9 +/()\-]{5,30}$'),
  constraint tk_plan_contacts_emergency_phone check (emergency_phone is null or emergency_phone ~ '^[0-9 +/()\-]{5,30}$'),
  constraint tk_plan_contacts_emergency_name check (emergency_name is null or char_length(emergency_name) between 1 and 200)
);

create index tk_plan_contacts_plan on public.tk_plan_contacts (plan_id);

-- Teilstrecken der An- und Abreise
create table public.tk_plan_legs (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.tk_plans (id) on delete cascade,
  sort_order int not null,
  mode public.tk_transport not null default 'rail_long',
  label text,
  km_one_way numeric(8, 1) not null default 0,
  persons int not null default 0,
  vehicles int not null default 0,
  round_trip boolean not null default true,
  constraint tk_plan_legs_numbers check (km_one_way >= 0 and persons >= 0 and vehicles >= 0),
  constraint tk_plan_legs_vehicles check (vehicles = 0 or mode in ('car', 'ecar', 'van')),
  constraint tk_plan_legs_label check (label is null or char_length(label) <= 200)
);

create index tk_plan_legs_plan on public.tk_plan_legs (plan_id);

-- Kostenzeilen
create table public.tk_plan_costs (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.tk_plans (id) on delete cascade,
  cost_group public.tk_cost_group not null,
  sort_order int not null,
  label text not null,
  quantity numeric(10, 2) not null default 0,
  unit_price numeric(10, 2) not null default 0,
  is_car boolean not null default false,
  is_overnight boolean not null default false,
  is_hut_half_board boolean not null default false,
  constraint tk_plan_costs_label check (label = btrim(label) and char_length(label) between 1 and 200),
  constraint tk_plan_costs_numbers check (quantity >= 0 and unit_price >= 0),
  constraint tk_plan_costs_hut check (not is_hut_half_board or cost_group = 'self_paid')
);

create index tk_plan_costs_plan on public.tk_plan_costs (plan_id);

-- Berechnete Werte (1:1), geschrieben von tk_calculate (R1)
create table public.tk_plan_results (
  plan_id uuid primary key references public.tk_plans (id) on delete cascade,
  days int,
  hours_day1 numeric(6, 2),
  fee_total numeric(10, 2),
  org_total numeric(10, 2),
  leader_costs numeric(10, 2),
  fixed_costs numeric(10, 2),
  per_participant_costs numeric(10, 2),
  self_paid_per_participant numeric(10, 2),
  total_costs numeric(10, 2),
  fee_method text,
  price_raw numeric(12, 4),
  price_suggested numeric(10, 2),
  price_member_effective numeric(10, 2),
  price_non_member_suggested numeric(10, 2),
  price_non_member_effective numeric(10, 2),
  net_per_participant numeric(12, 4),
  contribution_per_participant numeric(12, 4),
  break_even int,
  result_min numeric(10, 2),
  result_max numeric(10, 2),
  fees_at_min numeric(10, 2),
  is_free boolean not null default false,
  section_bears numeric(10, 2),
  co2_mobility_kg numeric(12, 2),
  co2_stay_kg numeric(12, 2),
  co2_food_kg numeric(12, 2),
  co2_tour_kg numeric(12, 2),
  co2_all_kg numeric(12, 2),
  co2_per_person_kg numeric(12, 2),
  co2_per_person_day_kg numeric(12, 2),
  climate_budget_eur numeric(10, 2),
  co2_status text not null default 'missing',
  fitness_suggested public.tk_fitness,
  rates_valid_on date,
  missing text[] not null default '{}',
  warnings text[] not null default '{}',
  calculated_at timestamptz not null default now(),
  constraint tk_plan_results_co2_status check (co2_status in ('missing', 'mostly_pt', 'mixed', 'mostly_car_flight'))
);

-- Eingefrorener Satzstand (R3)
create table public.tk_plan_rates (
  plan_id uuid not null references public.tk_plans (id) on delete cascade,
  rate_key text not null,
  label text not null,
  value numeric(12, 4),
  percent numeric(6, 3),
  fixed numeric(10, 2),
  active boolean not null,
  valid_from date not null,
  primary key (plan_id, rate_key)
);

-- Verlauf
create table public.tk_plan_history (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.tk_plans (id) on delete cascade,
  at timestamptz not null default now(),
  by_user uuid default auth.uid(),
  by_person_id uuid references public.ea_persons (id) on delete set null,
  event text not null,
  from_status public.tk_plan_status,
  to_status public.tk_plan_status,
  comment text,
  changed_fields text[],
  constraint tk_plan_history_event check (event in (
    'created', 'saved', 'submitted', 'query', 'resubmitted', 'approved', 'published', 'cancelled', 'done', 'closed',
    'contacts_purged', 'ez_sync_failed', 'ez_locked', 'copied')),
  constraint tk_plan_history_comment check (comment is null or char_length(comment) <= 500)
);

create index tk_plan_history_plan on public.tk_plan_history (plan_id, at);

-- Zuordnung Qualifikationsart → Sportart (C3), Pflege per Migration
create table public.tk_qualification_sports (
  qualification_type_id uuid not null references public.ad_qualification_types (id) on delete cascade,
  sport text not null,
  primary key (qualification_type_id, sport),
  constraint tk_qualification_sports_sport check (sport in (
    'Wandern', 'Sport- und Langstreckenwandern', 'Bergwandern', 'Bergsteigen', 'Klettersteig', 'Klettern',
    'Alpinklettern', 'Bouldern', 'Hochtour', 'Skitour', 'Schneeschuhtour', 'Skilanglauf', 'Ski alpin', 'Mountainbike',
    'Sonstiges'))
);

-- Hinweis nach Art. 13 DSGVO bei neuen Personen aus der Planung (R23)
create table public.tk_privacy_confirmations (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.ea_persons (id) on delete cascade,
  plan_id uuid references public.tk_plans (id) on delete set null,
  notice_version text not null,
  confirmed_at timestamptz not null default now(),
  confirmed_by uuid default auth.uid(),
  confirmed_by_person_id uuid references public.ea_persons (id) on delete set null,
  constraint tk_privacy_confirmations_notice check (notice_version = btrim(notice_version)
                                                    and char_length(notice_version) between 1 and 50)
);

create index tk_privacy_confirmations_person on public.tk_privacy_confirmations (person_id);

-- RLS: lesen über tk_can_read der Planung; keine Schreib-Policies, keine Schreib-Grants
alter table public.tk_plans enable row level security;
alter table public.tk_plan_leaders enable row level security;
alter table public.tk_plan_contacts enable row level security;
alter table public.tk_plan_legs enable row level security;
alter table public.tk_plan_costs enable row level security;
alter table public.tk_plan_results enable row level security;
alter table public.tk_plan_rates enable row level security;
alter table public.tk_plan_history enable row level security;
alter table public.tk_qualification_sports enable row level security;
alter table public.tk_privacy_confirmations enable row level security;

revoke all on table public.tk_plans, public.tk_plan_leaders, public.tk_plan_contacts, public.tk_plan_legs,
  public.tk_plan_costs, public.tk_plan_results, public.tk_plan_rates, public.tk_plan_history,
  public.tk_qualification_sports, public.tk_privacy_confirmations from public, anon, authenticated;
grant select on table public.tk_plans, public.tk_plan_leaders, public.tk_plan_contacts, public.tk_plan_legs,
  public.tk_plan_costs, public.tk_plan_results, public.tk_plan_rates, public.tk_plan_history,
  public.tk_qualification_sports, public.tk_privacy_confirmations to authenticated;

create policy tk_plans_select on public.tk_plans
  for select to authenticated using (public.tk_can_read(referat_id));
create policy tk_plan_leaders_select on public.tk_plan_leaders
  for select to authenticated using (exists (select 1 from public.tk_plans p where p.id = plan_id));
create policy tk_plan_contacts_select on public.tk_plan_contacts
  for select to authenticated using (exists (
    select 1 from public.tk_plans p where p.id = plan_id and public.tk_can_read_contacts(p.referat_id)));
create policy tk_plan_legs_select on public.tk_plan_legs
  for select to authenticated using (exists (select 1 from public.tk_plans p where p.id = plan_id));
create policy tk_plan_costs_select on public.tk_plan_costs
  for select to authenticated using (exists (select 1 from public.tk_plans p where p.id = plan_id));
create policy tk_plan_results_select on public.tk_plan_results
  for select to authenticated using (exists (select 1 from public.tk_plans p where p.id = plan_id));
create policy tk_plan_rates_select on public.tk_plan_rates
  for select to authenticated using (exists (select 1 from public.tk_plans p where p.id = plan_id));
create policy tk_plan_history_select on public.tk_plan_history
  for select to authenticated using (exists (select 1 from public.tk_plans p where p.id = plan_id));
create policy tk_qualification_sports_select on public.tk_qualification_sports
  for select to authenticated using (public.ad_has_any_level('TK', 'read'));
create policy tk_privacy_confirmations_select on public.tk_privacy_confirmations
  for select to authenticated using (public.tk_can_manage());

-- Namen der Leitenden für die Planungshilfe (R48 AD): Person ist Leitung in einer lesbaren Planung.
-- Ersetzt den Platzhalter aus 20261104000300 mit gleicher Signatur.
create or replace function public.tk_person_visible(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.tk_plan_leaders l
      join public.tk_plans p on p.id = l.plan_id
     where l.person_id = p_person
       and public.tk_can_read(p.referat_id)
  );
$$;
