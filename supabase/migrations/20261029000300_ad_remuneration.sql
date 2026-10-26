-- Nachtrag v0.10 (spec.md AD v0.10.0), spec T69, T70; Übergabe FI A1, A2, A5, A6, A10; R51–R54.
-- Abrechnungsarten mit Positionen, Vorbelegung je Einsatzart, Abgabefristen, Angaben der Sektion für die Auszahlung,
-- Kennzeichen „halbjährliche Abrechnung“ am Referat. Pflege nur Admin; kein Löschen; keine Personendaten.
-- Angaben der Sektion ohne Startbestand (keine echten Kontodaten im Repository).

-- Rechte (zentrale Stellen)
create function public.ad_can_edit_remuneration()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'edit');
$$;

create function public.ad_can_read_remuneration()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'read')
      or public.ad_has_any_level('EZ', 'read')
      or public.ad_has_any_level('FI', 'read')
      or public.ad_has_any_level('TK', 'read');
$$;

revoke all on function public.ad_can_edit_remuneration() from public, anon, authenticated;
revoke all on function public.ad_can_read_remuneration() from public, anon, authenticated;
grant execute on function public.ad_can_edit_remuneration() to authenticated;
grant execute on function public.ad_can_read_remuneration() to authenticated;

-- Gemeinsamer Audit-Trigger für die neuen Stammdaten (created_* bleiben, updated_* setzt das System)
create function public.ad_stamp_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    new.created_at := old.created_at;
    new.created_by := old.created_by;
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;
  return new;
end;
$$;

revoke all on function public.ad_stamp_update() from public, anon, authenticated;

-- ---------------------------------------------------------------------------------------------------------------
-- Abrechnungsarten (A1, R51)
create table public.ad_remuneration_kinds (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  is_active boolean not null default true,
  sort_order int not null,
  source text not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_remuneration_kinds_code_format check (code ~ '^[A-Z][A-Z_]{1,29}$'),
  constraint ad_remuneration_kinds_code_key unique (code),
  constraint ad_remuneration_kinds_name_length check (char_length(name) between 1 and 80)
);

comment on table public.ad_remuneration_kinds is
  'Abrechnungsarten nach Anhang 1 der Vergütungsordnung (spec.md AD R51); „keine Vergütung“ ist der leere Wert am Einsatz.';

create unique index ad_remuneration_kinds_name_key on public.ad_remuneration_kinds (lower(name));

create function public.ad_remuneration_kinds_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.name := btrim(coalesce(new.name, ''));
  new.source := btrim(coalesce(new.source, ''));
  if new.name = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'name';
  end if;
  if new.source = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'source';
  end if;
  if tg_op = 'UPDATE' then
    new.code := old.code;
  end if;
  if exists (select 1 from public.ad_remuneration_kinds k
              where (lower(k.name) = lower(new.name) or k.code = new.code) and k.id <> new.id) then
    raise exception 'AD_REMUNERATION_DUPLICATE' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_remuneration_kinds_guard() from public, anon, authenticated;

create trigger ad_remuneration_kinds_guard
  before insert or update on public.ad_remuneration_kinds
  for each row execute function public.ad_remuneration_kinds_guard();
create trigger ad_remuneration_kinds_stamp
  before update on public.ad_remuneration_kinds
  for each row execute function public.ad_stamp_update();

-- ---------------------------------------------------------------------------------------------------------------
-- Positionen je Abrechnungsart (A1, R51)
create table public.ad_remuneration_positions (
  id uuid primary key default gen_random_uuid(),
  kind_id uuid not null references public.ad_remuneration_kinds (id) on delete restrict,
  position text not null,
  rate_key_trainer text,
  rate_key_helper text,
  rate_key_none text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_remuneration_positions_position check (
    position in ('training_unit', 'day', 'half_day', 'competition_day', 'organization_day', 'teaching_unit')),
  constraint ad_remuneration_positions_shape check (
    (position in ('organization_day', 'teaching_unit')
       and rate_key_none is not null and rate_key_trainer is null and rate_key_helper is null)
    or (position not in ('organization_day', 'teaching_unit')
       and rate_key_none is null and rate_key_trainer is not null and rate_key_helper is not null)),
  constraint ad_remuneration_positions_key unique (kind_id, position)
);

comment on table public.ad_remuneration_positions is
  'Positionen einer Abrechnungsart mit Satzschlüssel je Rolle (spec.md AD R51); Schlüssel müssen in ad_rates existieren.';

create function public.ad_remuneration_positions_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key text;
begin
  new.rate_key_trainer := nullif(btrim(coalesce(new.rate_key_trainer, '')), '');
  new.rate_key_helper := nullif(btrim(coalesce(new.rate_key_helper, '')), '');
  new.rate_key_none := nullif(btrim(coalesce(new.rate_key_none, '')), '');
  if tg_op = 'UPDATE' then
    new.kind_id := old.kind_id;
    new.position := old.position;
  end if;
  if (new.position in ('organization_day', 'teaching_unit')
        and (new.rate_key_none is null or new.rate_key_trainer is not null or new.rate_key_helper is not null))
     or (new.position not in ('organization_day', 'teaching_unit')
        and (new.rate_key_none is not null or new.rate_key_trainer is null or new.rate_key_helper is null)) then
    raise exception 'AD_REMUNERATION_POSITION' using errcode = 'P0001';
  end if;
  foreach v_key in array array_remove(array[new.rate_key_trainer, new.rate_key_helper, new.rate_key_none], null) loop
    if not exists (select 1 from public.ad_rates r where r.rate_key = v_key) then
      raise exception 'AD_RATE_KEY_UNKNOWN' using errcode = 'P0001', detail = v_key;
    end if;
  end loop;
  if exists (select 1 from public.ad_remuneration_positions p
              where p.kind_id = new.kind_id and p.position = new.position and p.id <> new.id) then
    raise exception 'AD_REMUNERATION_DUPLICATE' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_remuneration_positions_guard() from public, anon, authenticated;

create trigger ad_remuneration_positions_guard
  before insert or update on public.ad_remuneration_positions
  for each row execute function public.ad_remuneration_positions_guard();
create trigger ad_remuneration_positions_stamp
  before update on public.ad_remuneration_positions
  for each row execute function public.ad_stamp_update();

-- ---------------------------------------------------------------------------------------------------------------
-- Vorbelegung je Einsatzart (A2, R52)
create table public.ad_remuneration_defaults (
  id uuid primary key default gen_random_uuid(),
  event_kind text not null,
  span text not null,
  kind_id uuid references public.ad_remuneration_kinds (id) on delete restrict,
  valid_from date not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_remuneration_defaults_event_kind check (event_kind in (
    'training', 'day_trip', 'multi_day_trip', 'training_trip', 'competition', 'work_assignment', 'course', 'tour',
    'training_camp')),
  constraint ad_remuneration_defaults_span check (span in ('single', 'multi')),
  constraint ad_remuneration_defaults_shape check (
    (event_kind not in ('training', 'day_trip') or span = 'single')
    and (event_kind not in ('multi_day_trip', 'training_camp') or span = 'multi')),
  constraint ad_remuneration_defaults_key unique (event_kind, span, valid_from)
);

comment on table public.ad_remuneration_defaults is
  'Vorbelegung der Abrechnungsart je Einsatzart und ein-/mehrtägig mit „gültig ab“ (spec.md AD R52); kind_id null = keine Vergütung.';

create function public.ad_remuneration_defaults_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    new.event_kind := old.event_kind;
    new.span := old.span;
    new.valid_from := old.valid_from;
  end if;
  if new.kind_id is not null
     and (tg_op = 'INSERT' or new.kind_id is distinct from old.kind_id)
     and not exists (select 1 from public.ad_remuneration_kinds k where k.id = new.kind_id and k.is_active) then
    raise exception 'AD_REMUNERATION_INACTIVE' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ad_remuneration_defaults d
              where d.event_kind = new.event_kind and d.span = new.span and d.valid_from = new.valid_from
                and d.id <> new.id) then
    raise exception 'AD_RATE_DUPLICATE' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_remuneration_defaults_guard() from public, anon, authenticated;

create trigger ad_remuneration_defaults_guard
  before insert or update on public.ad_remuneration_defaults
  for each row execute function public.ad_remuneration_defaults_guard();
create trigger ad_remuneration_defaults_stamp
  before update on public.ad_remuneration_defaults
  for each row execute function public.ad_stamp_update();

-- ---------------------------------------------------------------------------------------------------------------
-- Abgabefristen der halbjährlichen Abrechnung (A5, R53)
create table public.ad_settlement_deadlines (
  id uuid primary key default gen_random_uuid(),
  half smallint not null,
  deadline_month smallint not null,
  deadline_day smallint not null,
  valid_from date not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_settlement_deadlines_half check (half in (1, 2)),
  constraint ad_settlement_deadlines_month check (deadline_month between 1 and 12),
  constraint ad_settlement_deadlines_day check (deadline_day between 1 and 31),
  constraint ad_settlement_deadlines_key unique (half, valid_from)
);

comment on table public.ad_settlement_deadlines is
  'Abgabefristen je Abrechnungshalbjahr mit „gültig ab“ (spec.md AD R53); Frist im Jahr des Halbjahres.';

create function public.ad_settlement_deadlines_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    new.half := old.half;
    new.valid_from := old.valid_from;
  end if;
  begin
    perform make_date(2001, new.deadline_month, new.deadline_day);
  exception when others then
    raise exception 'AD_DEADLINE_INVALID' using errcode = 'P0001';
  end;
  if exists (select 1 from public.ad_settlement_deadlines d
              where d.half = new.half and d.valid_from = new.valid_from and d.id <> new.id) then
    raise exception 'AD_RATE_DUPLICATE' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_settlement_deadlines_guard() from public, anon, authenticated;

create trigger ad_settlement_deadlines_guard
  before insert or update on public.ad_settlement_deadlines
  for each row execute function public.ad_settlement_deadlines_guard();
create trigger ad_settlement_deadlines_stamp
  before update on public.ad_settlement_deadlines
  for each row execute function public.ad_stamp_update();

-- ---------------------------------------------------------------------------------------------------------------
-- Angaben der Sektion für die Auszahlung (A10, R54)
create table public.ad_payout_settings (
  id uuid primary key default gen_random_uuid(),
  debtor_name text not null,
  iban text not null,
  bic text not null,
  ledger_account text not null,
  valid_from date not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_payout_settings_name_length check (char_length(debtor_name) between 1 and 70),
  constraint ad_payout_settings_ledger_length check (char_length(ledger_account) between 1 and 20),
  constraint ad_payout_settings_bic_format check (bic ~ '^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$'),
  constraint ad_payout_settings_valid_from unique (valid_from)
);

comment on table public.ad_payout_settings is
  'Name, IBAN, BIC und Sachkonto der Sektion für Auszahlliste und Überweisungsdatei (spec.md AD R54). Kein Startbestand.';

create function public.ad_payout_settings_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.debtor_name := btrim(coalesce(new.debtor_name, ''));
  new.ledger_account := btrim(coalesce(new.ledger_account, ''));
  new.bic := upper(regexp_replace(coalesce(new.bic, ''), '\s', '', 'g'));
  if new.debtor_name = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'debtor_name';
  end if;
  if new.ledger_account = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'ledger_account';
  end if;
  if not public.ea_iban_valid(new.iban) then
    raise exception 'EA_IBAN_INVALID' using errcode = 'P0001';
  end if;
  new.iban := public.ea_iban_normalize(new.iban);
  if new.bic !~ '^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$' then
    raise exception 'AD_BIC_INVALID' using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' then
    new.valid_from := old.valid_from;
  end if;
  if exists (select 1 from public.ad_payout_settings s where s.valid_from = new.valid_from and s.id <> new.id) then
    raise exception 'AD_RATE_DUPLICATE' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_payout_settings_guard() from public, anon, authenticated;

create trigger ad_payout_settings_guard
  before insert or update on public.ad_payout_settings
  for each row execute function public.ad_payout_settings_guard();
create trigger ad_payout_settings_stamp
  before update on public.ad_payout_settings
  for each row execute function public.ad_stamp_update();

-- ---------------------------------------------------------------------------------------------------------------
-- Kennzeichen „halbjährliche Abrechnung“ am Referat (A6, R53); setzt nur der Admin
alter table public.ea_referate add column semiannual_settlement boolean not null default false;

comment on column public.ea_referate.semiannual_settlement is
  'Halbjährliche Abrechnung in Finanzen (spec.md AD R53, Übergabe FI A6); ändert nur der Admin.';

create function public.ea_referate_settlement_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.semiannual_settlement is distinct from old.semiannual_settlement
     and auth.uid() is not null
     and not public.ad_can_edit_remuneration() then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ea_referate_settlement_guard() from public, anon, authenticated;

create trigger ea_referate_settlement_guard
  before update of semiannual_settlement on public.ea_referate
  for each row execute function public.ea_referate_settlement_guard();

grant update (semiannual_settlement) on table public.ea_referate to authenticated;

update public.ea_referate
   set semiannual_settlement = true
 where name in ('Kinder und Jugend', 'Leistungssport')
   and not semiannual_settlement;

-- ---------------------------------------------------------------------------------------------------------------
-- Lesefunktionen (T70)
create function public.ad_remuneration_default_at(p_event_kind text, p_span text, p_date date)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_kind uuid;
begin
  if not public.ad_can_read_remuneration() then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  select d.kind_id into v_kind
    from public.ad_remuneration_defaults d
   where d.event_kind = p_event_kind
     and d.span = p_span
     and d.valid_from <= coalesce(p_date, current_date)
   order by d.valid_from desc
   limit 1;
  return v_kind;
end;
$$;

create function public.ad_settlement_deadline(p_year int, p_half int)
returns date
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_month smallint;
  v_day smallint;
begin
  if not public.ad_can_read_remuneration() then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_half not in (1, 2) or p_year is null then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;
  select d.deadline_month, d.deadline_day into v_month, v_day
    from public.ad_settlement_deadlines d
   where d.half = p_half
     and d.valid_from <= make_date(p_year, case p_half when 1 then 1 else 7 end, 1)
   order by d.valid_from desc
   limit 1;
  if v_month is null then
    raise exception 'AD_DEADLINE_MISSING' using errcode = 'P0001';
  end if;
  return make_date(p_year, v_month, v_day);
end;
$$;

create function public.ad_payout_settings_at(p_date date)
returns table (debtor_name text, iban text, bic text, ledger_account text, valid_from date)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (public.ad_has_level('AD', 'read') or public.ad_has_level('FI', 'manage')) then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select s.debtor_name, s.iban, s.bic, s.ledger_account, s.valid_from
    from public.ad_payout_settings s
   where s.valid_from <= coalesce(p_date, current_date)
   order by s.valid_from desc
   limit 1;
end;
$$;

revoke all on function public.ad_remuneration_default_at(text, text, date) from public, anon, authenticated;
revoke all on function public.ad_settlement_deadline(int, int) from public, anon, authenticated;
revoke all on function public.ad_payout_settings_at(date) from public, anon, authenticated;
grant execute on function public.ad_remuneration_default_at(text, text, date) to authenticated;
grant execute on function public.ad_settlement_deadline(int, int) to authenticated;
grant execute on function public.ad_payout_settings_at(date) to authenticated;

-- ---------------------------------------------------------------------------------------------------------------
-- RLS und Grants
alter table public.ad_remuneration_kinds enable row level security;
alter table public.ad_remuneration_positions enable row level security;
alter table public.ad_remuneration_defaults enable row level security;
alter table public.ad_settlement_deadlines enable row level security;
alter table public.ad_payout_settings enable row level security;

revoke all on table public.ad_remuneration_kinds, public.ad_remuneration_positions, public.ad_remuneration_defaults,
  public.ad_settlement_deadlines, public.ad_payout_settings from public, anon, authenticated;

grant select on table public.ad_remuneration_kinds, public.ad_remuneration_positions, public.ad_remuneration_defaults,
  public.ad_settlement_deadlines, public.ad_payout_settings to authenticated;
grant insert (code, name, is_active, sort_order, source), update (name, is_active, sort_order, source)
  on table public.ad_remuneration_kinds to authenticated;
grant insert (kind_id, position, rate_key_trainer, rate_key_helper, rate_key_none),
      update (rate_key_trainer, rate_key_helper, rate_key_none)
  on table public.ad_remuneration_positions to authenticated;
grant insert (event_kind, span, kind_id, valid_from), update (kind_id)
  on table public.ad_remuneration_defaults to authenticated;
grant insert (half, deadline_month, deadline_day, valid_from), update (deadline_month, deadline_day)
  on table public.ad_settlement_deadlines to authenticated;
grant insert (debtor_name, iban, bic, ledger_account, valid_from), update (debtor_name, iban, bic, ledger_account)
  on table public.ad_payout_settings to authenticated;

create policy ad_remuneration_kinds_select on public.ad_remuneration_kinds
  for select to authenticated using (public.ad_can_read_remuneration());
create policy ad_remuneration_kinds_insert on public.ad_remuneration_kinds
  for insert to authenticated with check (public.ad_can_edit_remuneration());
create policy ad_remuneration_kinds_update on public.ad_remuneration_kinds
  for update to authenticated using (public.ad_can_edit_remuneration()) with check (public.ad_can_edit_remuneration());

create policy ad_remuneration_positions_select on public.ad_remuneration_positions
  for select to authenticated using (public.ad_can_read_remuneration());
create policy ad_remuneration_positions_insert on public.ad_remuneration_positions
  for insert to authenticated with check (public.ad_can_edit_remuneration());
create policy ad_remuneration_positions_update on public.ad_remuneration_positions
  for update to authenticated using (public.ad_can_edit_remuneration()) with check (public.ad_can_edit_remuneration());

create policy ad_remuneration_defaults_select on public.ad_remuneration_defaults
  for select to authenticated using (public.ad_can_read_remuneration());
create policy ad_remuneration_defaults_insert on public.ad_remuneration_defaults
  for insert to authenticated with check (public.ad_can_edit_remuneration());
create policy ad_remuneration_defaults_update on public.ad_remuneration_defaults
  for update to authenticated using (public.ad_can_edit_remuneration()) with check (public.ad_can_edit_remuneration());

create policy ad_settlement_deadlines_select on public.ad_settlement_deadlines
  for select to authenticated using (public.ad_can_read_remuneration());
create policy ad_settlement_deadlines_insert on public.ad_settlement_deadlines
  for insert to authenticated with check (public.ad_can_edit_remuneration());
create policy ad_settlement_deadlines_update on public.ad_settlement_deadlines
  for update to authenticated using (public.ad_can_edit_remuneration()) with check (public.ad_can_edit_remuneration());

create policy ad_payout_settings_select on public.ad_payout_settings
  for select to authenticated using (public.ad_has_level('AD', 'read') or public.ad_has_level('FI', 'manage'));
create policy ad_payout_settings_insert on public.ad_payout_settings
  for insert to authenticated with check (public.ad_can_edit_remuneration());
create policy ad_payout_settings_update on public.ad_payout_settings
  for update to authenticated using (public.ad_can_edit_remuneration()) with check (public.ad_can_edit_remuneration());

-- ---------------------------------------------------------------------------------------------------------------
-- Startbestand (TEST und PROD; idempotent, ohne Überschreiben)
insert into public.ad_remuneration_kinds (code, name, sort_order, source)
select v.code, v.name, v.sort_order, 'Vergütungsordnung 2025, Anhang 1'
  from (values
    ('TRAINING', 'Trainingseinheiten', 10),
    ('TRIP', 'Kinder- und Jugendfahrten, Gruppenfahrten', 20),
    ('COMPETITION', 'Wettkampfbetreuung', 30),
    ('MULTIDAY', 'Mehrtageskurse, Führungstouren, Trainingslager', 40),
    ('COURSE', 'Kurse', 50),
    ('COMMUNITY_TOUR', 'Gemeinschaftstour', 60)
  ) as v (code, name, sort_order)
 where not exists (select 1 from public.ad_remuneration_kinds k where k.code = v.code);

insert into public.ad_remuneration_positions (kind_id, position, rate_key_trainer, rate_key_helper, rate_key_none)
select k.id, v.position, v.kt, v.kh, v.kn
  from (values
    ('TRAINING', 'training_unit', 'rTE', 'rTEH', null),
    ('TRIP', 'day', 'rFT', 'rFH', null),
    ('TRIP', 'half_day', 'rFTh', 'rFHh', null),
    ('TRIP', 'organization_day', null, null, 'rOrg'),
    ('COMPETITION', 'competition_day', 'rWK', 'rWKH', null),
    ('MULTIDAY', 'day', 'rTL', 'rH', null),
    ('MULTIDAY', 'half_day', 'rTLh', 'rHh', null),
    ('MULTIDAY', 'organization_day', null, null, 'rOrg'),
    ('COURSE', 'teaching_unit', null, null, 'rLE'),
    ('COMMUNITY_TOUR', 'organization_day', null, null, 'rOrg')
  ) as v (code, position, kt, kh, kn)
  join public.ad_remuneration_kinds k on k.code = v.code
 where not exists (select 1 from public.ad_remuneration_positions p where p.kind_id = k.id and p.position = v.position);

insert into public.ad_remuneration_defaults (event_kind, span, kind_id, valid_from)
select v.event_kind, v.span, k.id, date '2026-01-01'
  from (values
    ('training', 'single', 'TRAINING'),
    ('day_trip', 'single', 'TRIP'),
    ('multi_day_trip', 'multi', 'TRIP'),
    ('training_trip', 'single', 'MULTIDAY'),
    ('training_trip', 'multi', 'MULTIDAY'),
    ('competition', 'single', 'COMPETITION'),
    ('competition', 'multi', 'COMPETITION'),
    ('training_camp', 'multi', 'MULTIDAY'),
    ('course', 'single', 'COURSE'),
    ('course', 'multi', 'COURSE'),
    ('tour', 'single', 'MULTIDAY'),
    ('tour', 'multi', 'MULTIDAY'),
    ('work_assignment', 'single', null),
    ('work_assignment', 'multi', null)
  ) as v (event_kind, span, code)
  left join public.ad_remuneration_kinds k on k.code = v.code
 where not exists (select 1 from public.ad_remuneration_defaults d
                    where d.event_kind = v.event_kind and d.span = v.span and d.valid_from = date '2026-01-01');

insert into public.ad_settlement_deadlines (half, deadline_month, deadline_day, valid_from)
select v.half, v.m, v.d, date '2026-01-01'
  from (values (1, 7, 31), (2, 12, 15)) as v (half, m, d)
 where not exists (select 1 from public.ad_settlement_deadlines s
                    where s.half = v.half and s.valid_from = date '2026-01-01');
