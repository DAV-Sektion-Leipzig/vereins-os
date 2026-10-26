-- Finanzen (FI), spec.md FI v0.2 Abschnitte 2 und 3, spec T1: Typen, Tabellen, Rechtefunktionen, RLS.
-- Schreiben nur über die Funktionen der folgenden Migrationen (keine Insert/Update/Delete-Grants auf fi_-Tabellen).
-- Voraussetzung: Administration Nachtrag v0.10 (20261029*), Anwesenheitserfassung Nachtrag v0.6 (20261030*).

create type public.fi_settlement_status as enum ('draft', 'confirmed', 'closed', 'submitted', 'expired', 'paid');
create type public.fi_rate_role as enum ('trainer', 'helper', 'none');
create type public.fi_position as enum (
  'training_unit', 'day', 'half_day', 'competition_day', 'organization_day', 'teaching_unit');
create type public.fi_hint as enum ('no_time', 'no_training_time', 'no_license', 'rate_missing');
create type public.fi_run_status as enum ('draft', 'released');
create type public.fi_log_action as enum (
  'calculated', 'corrected', 'exception_reason', 'confirmed', 'confirmed_substitute', 'confirmation_reset', 'closed',
  'reopened', 'submitted', 'expired', 'paid');

revoke all on type public.fi_settlement_status, public.fi_rate_role, public.fi_position, public.fi_hint,
  public.fi_run_status, public.fi_log_action from public, anon;
grant usage on type public.fi_settlement_status, public.fi_rate_role, public.fi_position, public.fi_hint,
  public.fi_run_status, public.fi_log_action to authenticated, service_role;

-- ---------------------------------------------------------------------------------------------------------------
-- Auszahlungsrunde (vor den Abrechnungen, wegen des Fremdschlüssels)
create table public.fi_payout_runs (
  id uuid primary key default gen_random_uuid(),
  year smallint not null,
  half smallint not null,
  number smallint not null,
  status public.fi_run_status not null default 'draft',
  execution_date date not null,
  msg_id text,
  pmt_inf_id text,
  line_count integer,
  total numeric(12, 2),
  released_at timestamptz,
  released_by uuid,
  released_by_person_id uuid references public.ea_persons (id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  constraint fi_payout_runs_half check (half in (1, 2)),
  constraint fi_payout_runs_year check (year between 2026 and 2100),
  constraint fi_payout_runs_key unique (year, half, number),
  constraint fi_payout_runs_msg_id_key unique (msg_id),
  constraint fi_payout_runs_released check (
    (status = 'draft' and msg_id is null) or (status = 'released' and msg_id is not null and released_at is not null))
);

create table public.fi_run_counters (
  year smallint not null,
  half smallint not null,
  last_number smallint not null,
  primary key (year, half)
);

-- ---------------------------------------------------------------------------------------------------------------
-- Abrechnung je Person und Abrechnungshalbjahr
create table public.fi_settlements (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.ea_persons (id) on delete restrict,
  year smallint not null,
  half smallint not null,
  status public.fi_settlement_status not null default 'draft',
  amount numeric(10, 2) not null default 0,
  has_new_events boolean not null default false,
  closed_at timestamptz,
  closed_by uuid,
  closed_by_person_id uuid references public.ea_persons (id) on delete set null,
  submitted_on date,
  submitted_late_reason text,
  expired_at timestamptz,
  expired_by uuid,
  payout_run_id uuid references public.fi_payout_runs (id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz,
  updated_by uuid,
  constraint fi_settlements_half check (half in (1, 2)),
  constraint fi_settlements_year check (year between 2026 and 2100),
  constraint fi_settlements_key unique (person_id, year, half),
  constraint fi_settlements_late_reason check (
    submitted_late_reason is null or char_length(submitted_late_reason) between 1 and 500)
);

comment on column public.fi_settlements.has_new_events is
  'Neue abrechenbare Anwesenheiten nach dem Abschluss (Hinweis „nicht abgerechnete Einsätze“, US-FI-01 AK4).';

create index fi_settlements_period on public.fi_settlements (year, half, status);
create index fi_settlements_run on public.fi_settlements (payout_run_id);

-- Position
create table public.fi_settlement_items (
  id uuid primary key default gen_random_uuid(),
  settlement_id uuid not null references public.fi_settlements (id) on delete cascade,
  event_id uuid not null references public.ez_events (id) on delete restrict,
  attendance_id uuid references public.ez_attendances (id) on delete restrict,
  event_date date not null,
  referat_id uuid not null references public.ea_referate (id),
  group_id uuid references public.gr_groups (id) on delete restrict,
  remuneration_kind_id uuid not null references public.ad_remuneration_kinds (id) on delete restrict,
  position public.fi_position not null,
  recorded_role public.ez_role,
  calc_rate_role public.fi_rate_role not null,
  calc_quantity numeric(6, 2) not null,
  override_rate_role public.fi_rate_role,
  override_quantity numeric(6, 2),
  correction_reason text,
  corrected_at timestamptz,
  corrected_by uuid,
  exception_reason text,
  rate_key text,
  rate numeric(10, 2),
  amount numeric(10, 2),
  hints public.fi_hint[] not null default '{}',
  constraint fi_settlement_items_key unique (settlement_id, event_id, position),
  constraint fi_settlement_items_quantity check (calc_quantity >= 0 and (override_quantity is null or override_quantity >= 0)),
  constraint fi_settlement_items_correction check (
    (override_rate_role is null and override_quantity is null and correction_reason is null)
    or (correction_reason is not null and char_length(correction_reason) between 1 and 500)),
  constraint fi_settlement_items_exception check (
    exception_reason is null or char_length(exception_reason) between 1 and 500)
);

create index fi_settlement_items_attendance on public.fi_settlement_items (attendance_id);
create index fi_settlement_items_event on public.fi_settlement_items (event_id);

-- Bestätigung je Referat (R23)
create table public.fi_settlement_confirmations (
  settlement_id uuid not null references public.fi_settlements (id) on delete cascade,
  referat_id uuid not null references public.ea_referate (id),
  confirmed_at timestamptz not null default now(),
  confirmed_by uuid default auth.uid(),
  confirmed_by_person_id uuid references public.ea_persons (id) on delete set null,
  is_substitute boolean not null default false,
  substitute_reason text,
  primary key (settlement_id, referat_id),
  constraint fi_settlement_confirmations_substitute check (
    (is_substitute and substitute_reason is not null and char_length(substitute_reason) between 1 and 500)
    or (not is_substitute and substitute_reason is null))
);

-- Verlauf (R33)
create table public.fi_settlement_log (
  id bigint generated always as identity primary key,
  settlement_id uuid not null references public.fi_settlements (id) on delete cascade,
  action public.fi_log_action not null,
  detail jsonb,
  at timestamptz not null default now(),
  by uuid default auth.uid(),
  by_person_id uuid references public.ea_persons (id) on delete set null
);

create index fi_settlement_log_settlement on public.fi_settlement_log (settlement_id, at);

-- Auszahlzeile (R24); kein Name, keine IBAN (R21), nur ein Prüfwert der Bankverbindung für den Hinweis R21
create table public.fi_payout_lines (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.fi_payout_runs (id) on delete restrict,
  settlement_id uuid not null references public.fi_settlements (id) on delete restrict,
  person_id uuid not null references public.ea_persons (id) on delete restrict,
  group_id uuid references public.gr_groups (id) on delete restrict,
  referat_id uuid references public.ea_referate (id),
  group_label text not null,
  amount numeric(10, 2) not null,
  remittance text not null,
  end_to_end_id text not null,
  bank_check text,
  sort_no integer not null,
  constraint fi_payout_lines_amount check (amount > 0),
  constraint fi_payout_lines_remittance check (char_length(remittance) between 1 and 140),
  constraint fi_payout_lines_e2e_key unique (end_to_end_id),
  constraint fi_payout_lines_key unique nulls not distinct (run_id, settlement_id, group_id, referat_id),
  constraint fi_payout_lines_group_or_referat check ((group_id is null) <> (referat_id is null))
);

comment on column public.fi_payout_lines.bank_check is
  'md5 der IBAN bei der Freigabe; nur für den Hinweis „Bankverbindung seit der Freigabe geändert“ (R21), keine IBAN.';

-- Abgleich Punktekonto (US-FI-17)
create table public.fi_climbing_checks (
  id uuid primary key default gen_random_uuid(),
  location_id uuid not null references public.ad_locations (id) on delete restrict,
  period_from date not null,
  period_to date not null,
  counted_without_trials integer not null,
  counted_with_trials integer not null,
  invoiced integer not null,
  invoice_number text,
  remark text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  created_by_person_id uuid references public.ea_persons (id) on delete set null,
  constraint fi_climbing_checks_period check (period_from <= period_to),
  constraint fi_climbing_checks_invoiced check (invoiced >= 0),
  constraint fi_climbing_checks_invoice_number check (invoice_number is null or char_length(invoice_number) <= 50),
  constraint fi_climbing_checks_remark check (remark is null or char_length(remark) <= 500)
);

-- ---------------------------------------------------------------------------------------------------------------
-- Rechte (zentrale Stellen, Abschnitt 2 „Rechte“)
create function public.fi_can_manage()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.ad_has_level('FI', 'manage');
$$;

create function public.fi_can_read_all()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.ad_has_level('FI', 'read');
$$;

create function public.fi_read_referate()
returns uuid[] language sql stable security definer set search_path = '' as $$
  select public.ad_my_referate('FI', 'read');
$$;

create function public.fi_confirm_referate()
returns uuid[] language sql stable security definer set search_path = '' as $$
  select public.ad_my_approve_referate('FI');
$$;

-- R31: ganze Abrechnung lesbar, sobald sie eine Position eines eigenen Referats hat
create function public.fi_can_read_settlement(p_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.fi_can_read_all()
      or exists (select 1 from public.fi_settlement_items i
                  where i.settlement_id = p_id and i.referat_id = any (public.fi_read_referate()));
$$;

-- Person des aufrufenden Nutzers (Audit); intern
create function public.fi_my_person_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select a.person_id from public.ad_accesses a where a.auth_user_id = auth.uid() limit 1;
$$;

revoke all on function public.fi_can_manage(), public.fi_can_read_all(), public.fi_read_referate(),
  public.fi_confirm_referate(), public.fi_can_read_settlement(uuid), public.fi_my_person_id()
  from public, anon, authenticated;
grant execute on function public.fi_can_manage(), public.fi_can_read_all(), public.fi_read_referate(),
  public.fi_confirm_referate(), public.fi_can_read_settlement(uuid) to authenticated;

-- ---------------------------------------------------------------------------------------------------------------
-- RLS: nur lesen; geschrieben wird über security-definer-Funktionen
alter table public.fi_settlements enable row level security;
alter table public.fi_settlement_items enable row level security;
alter table public.fi_settlement_confirmations enable row level security;
alter table public.fi_settlement_log enable row level security;
alter table public.fi_payout_runs enable row level security;
alter table public.fi_run_counters enable row level security;
alter table public.fi_payout_lines enable row level security;
alter table public.fi_climbing_checks enable row level security;

revoke all on table public.fi_settlements, public.fi_settlement_items, public.fi_settlement_confirmations,
  public.fi_settlement_log, public.fi_payout_runs, public.fi_run_counters, public.fi_payout_lines,
  public.fi_climbing_checks from public, anon, authenticated;
grant select on table public.fi_settlements, public.fi_settlement_items, public.fi_settlement_confirmations,
  public.fi_settlement_log, public.fi_payout_runs, public.fi_run_counters, public.fi_payout_lines,
  public.fi_climbing_checks to authenticated;

create policy fi_settlements_select on public.fi_settlements
  for select to authenticated using (public.fi_can_read_settlement(id));
create policy fi_settlement_items_select on public.fi_settlement_items
  for select to authenticated using (public.fi_can_read_settlement(settlement_id));
create policy fi_settlement_confirmations_select on public.fi_settlement_confirmations
  for select to authenticated using (public.fi_can_read_settlement(settlement_id));
create policy fi_settlement_log_select on public.fi_settlement_log
  for select to authenticated using (public.fi_can_read_settlement(settlement_id));
create policy fi_payout_runs_select on public.fi_payout_runs
  for select to authenticated using (public.fi_can_manage());
create policy fi_run_counters_select on public.fi_run_counters
  for select to authenticated using (public.fi_can_manage());
create policy fi_payout_lines_select on public.fi_payout_lines
  for select to authenticated using (public.fi_can_manage());
create policy fi_climbing_checks_select on public.fi_climbing_checks
  for select to authenticated using (public.fi_can_manage());

-- ---------------------------------------------------------------------------------------------------------------
-- Satz und Betrag einer Position (R9): wirksame Satzart und Menge, Satzschlüssel aus der Position der Abrechnungsart,
-- Satz am Datum des Einsatzes; ohne Satz Hinweis rate_missing
create function public.fi_settlement_items_rate()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.fi_rate_role := coalesce(new.override_rate_role, new.calc_rate_role);
  v_qty numeric := coalesce(new.override_quantity, new.calc_quantity);
  v_key text;
  v_rate numeric;
begin
  select case v_role when 'trainer' then p.rate_key_trainer when 'helper' then p.rate_key_helper else p.rate_key_none end
    into v_key
    from public.ad_remuneration_positions p
   where p.kind_id = new.remuneration_kind_id and p.position = new.position::text;
  if v_key is not null then
    select r.value into v_rate
      from public.ad_rates r
     where r.rate_key = v_key and r.valid_from <= new.event_date
     order by r.valid_from desc
     limit 1;
  end if;
  new.rate_key := v_key;
  new.rate := v_rate;
  new.amount := case when v_rate is null then null else round(v_qty * v_rate, 2) end;
  new.hints := array(select distinct h from unnest(new.hints) as h where h <> 'rate_missing')
               || case when v_rate is null then array['rate_missing'::public.fi_hint] else '{}' end;
  return new;
end;
$$;

revoke all on function public.fi_settlement_items_rate() from public, anon, authenticated;

create trigger fi_settlement_items_rate
  before insert or update on public.fi_settlement_items
  for each row execute function public.fi_settlement_items_rate();

-- Summe der Abrechnung
create function public.fi_settlement_items_sum()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := coalesce(new.settlement_id, old.settlement_id);
begin
  update public.fi_settlements s
     set amount = coalesce((select sum(i.amount) from public.fi_settlement_items i where i.settlement_id = v_id), 0)
   where s.id = v_id;
  return null;
end;
$$;

revoke all on function public.fi_settlement_items_sum() from public, anon, authenticated;

create trigger fi_settlement_items_sum
  after insert or update or delete on public.fi_settlement_items
  for each row execute function public.fi_settlement_items_sum();

-- Unveränderliche Spalten, Audit
create function public.fi_settlements_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.person_id is distinct from old.person_id or new.year is distinct from old.year
     or new.half is distinct from old.half then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  new.updated_at := now();
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  return new;
end;
$$;

revoke all on function public.fi_settlements_guard() from public, anon, authenticated;

create trigger fi_settlements_guard
  before update on public.fi_settlements
  for each row execute function public.fi_settlements_guard();

create function public.fi_set_person_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'fi_settlement_confirmations' then
    new.confirmed_by_person_id := coalesce(new.confirmed_by_person_id, public.fi_my_person_id());
  elsif tg_table_name = 'fi_settlement_log' then
    new.by_person_id := coalesce(new.by_person_id, public.fi_my_person_id());
  elsif tg_table_name = 'fi_climbing_checks' then
    new.created_by_person_id := coalesce(new.created_by_person_id, public.fi_my_person_id());
  end if;
  return new;
end;
$$;

revoke all on function public.fi_set_person_audit() from public, anon, authenticated;

create trigger fi_settlement_confirmations_audit before insert on public.fi_settlement_confirmations
  for each row execute function public.fi_set_person_audit();
create trigger fi_settlement_log_audit before insert on public.fi_settlement_log
  for each row execute function public.fi_set_person_audit();
create trigger fi_climbing_checks_audit before insert on public.fi_climbing_checks
  for each row execute function public.fi_set_person_audit();

-- Eintrag im Verlauf; intern
create function public.fi_log(p_settlement uuid, p_action public.fi_log_action, p_detail jsonb default null)
returns void language sql security definer set search_path = '' as $$
  insert into public.fi_settlement_log (settlement_id, action, detail) values (p_settlement, p_action, p_detail);
$$;

revoke all on function public.fi_log(uuid, public.fi_log_action, jsonb) from public, anon, authenticated;
