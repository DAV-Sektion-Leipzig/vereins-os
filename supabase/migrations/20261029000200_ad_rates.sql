-- Nachtrag v0.9 (Sätze und Pauschalen, spec T60) mit Finanzen vorgezogen (spec.md AD v0.10.0, querschnitt-administration.md 4);
-- Startbestand der Vergütung (spec T61 Teil, Nachtrag v0.10 A3, A4; T69 Teil). R46.
-- Die übrigen Schlüssel der Planungshilfe (Reisekosten, Beitrag, Zahlungsgebühren, Klima, Grenzwerte der Planung)
-- kommen mit der Planungshilfe (T61 Rest), weil sie nur dort gebraucht werden.

create type public.ad_rate_group as enum ('remuneration', 'travel', 'fee', 'payment_fee', 'climate', 'threshold');

revoke all on type public.ad_rate_group from public, anon;
grant usage on type public.ad_rate_group to authenticated, service_role;

create table public.ad_rates (
  id uuid primary key default gen_random_uuid(),
  rate_key text not null,
  label text not null,
  rate_group public.ad_rate_group not null,
  unit text not null,
  value numeric(12, 4),
  percent numeric(6, 3),
  fixed numeric(10, 2),
  active boolean not null default true,
  valid_from date not null,
  source text not null,
  note text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_rates_key_format check (rate_key ~ '^[a-zA-Z][a-zA-Z0-9_]{1,39}$'),
  constraint ad_rates_shape check (
    (rate_group = 'payment_fee' and value is null and percent is not null and fixed is not null)
    or (rate_group <> 'payment_fee' and value is not null and percent is null and fixed is null)
  ),
  constraint ad_rates_not_negative check (coalesce(value, 0) >= 0 and coalesce(percent, 0) >= 0 and coalesce(fixed, 0) >= 0),
  constraint ad_rates_key_from unique (rate_key, valid_from)
);

comment on table public.ad_rates is
  'Sätze und Pauschalen mit „gültig ab“ (spec.md AD R46); Pflege nur Admin; kein Löschen. Genutzt von Finanzen und Planungshilfe.';

create index ad_rates_key_valid on public.ad_rates (rate_key, valid_from desc);

-- R46: Pflichtfelder, Werte ≥ 0, je Schlüssel und Datum eine Zeile; Schlüssel, Gruppe und „gültig ab“ nicht änderbar
create function public.ad_rates_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.label := btrim(coalesce(new.label, ''));
  new.unit := btrim(coalesce(new.unit, ''));
  new.source := btrim(coalesce(new.source, ''));
  new.note := nullif(btrim(coalesce(new.note, '')), '');
  if new.label = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'label';
  end if;
  if new.unit = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'unit';
  end if;
  if new.source = '' then
    raise exception 'AD_RATE_FIELD_REQUIRED' using errcode = 'P0001', detail = 'source';
  end if;
  if tg_op = 'UPDATE' then
    new.rate_key := old.rate_key;
    new.rate_group := old.rate_group;
    new.valid_from := old.valid_from;
    new.created_at := old.created_at;
    new.created_by := old.created_by;
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;
  if coalesce(new.value, 0) < 0 or coalesce(new.percent, 0) < 0 or coalesce(new.fixed, 0) < 0
     or (new.rate_group = 'payment_fee' and (new.value is not null or new.percent is null or new.fixed is null))
     or (new.rate_group <> 'payment_fee' and (new.value is null or new.percent is not null or new.fixed is not null)) then
    raise exception 'AD_RATE_VALUE' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ad_rates r
              where r.rate_key = new.rate_key and r.valid_from = new.valid_from and r.id <> new.id) then
    raise exception 'AD_RATE_DUPLICATE' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ad_rates_guard() from public, anon, authenticated;

create trigger ad_rates_guard
  before insert or update on public.ad_rates
  for each row execute function public.ad_rates_guard();

-- Rechte (zentrale Stellen, R46; v0.10 ohne TKF)
create function public.ad_can_edit_rates()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'edit');
$$;

create function public.ad_can_read_rates()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'read')
      or public.ad_has_any_level('TK', 'read')
      or public.ad_has_level('FI', 'read');
$$;

revoke all on function public.ad_can_edit_rates() from public, anon, authenticated;
revoke all on function public.ad_can_read_rates() from public, anon, authenticated;
grant execute on function public.ad_can_edit_rates() to authenticated;
grant execute on function public.ad_can_read_rates() to authenticated;

-- Je Schlüssel die Zeile mit dem spätesten „gültig ab“ ≤ p_date
create function public.ad_rates_at(p_date date)
returns table (
  rate_key text, label text, rate_group public.ad_rate_group, unit text, value numeric, percent numeric,
  fixed numeric, active boolean, valid_from date, source text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_can_read_rates() then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select distinct on (r.rate_key)
         r.rate_key, r.label, r.rate_group, r.unit, r.value, r.percent, r.fixed, r.active, r.valid_from, r.source
    from public.ad_rates r
   where r.valid_from <= coalesce(p_date, current_date)
   order by r.rate_key, r.valid_from desc;
end;
$$;

revoke all on function public.ad_rates_at(date) from public, anon, authenticated;
grant execute on function public.ad_rates_at(date) to authenticated;

alter table public.ad_rates enable row level security;
revoke all on table public.ad_rates from public, anon, authenticated;
grant select on table public.ad_rates to authenticated;
grant insert (rate_key, label, rate_group, unit, value, percent, fixed, active, valid_from, source, note)
  on table public.ad_rates to authenticated;
grant update (label, unit, value, percent, fixed, active, source, note) on table public.ad_rates to authenticated;

create policy ad_rates_select on public.ad_rates
  for select to authenticated using (public.ad_can_read_rates());
create policy ad_rates_insert on public.ad_rates
  for insert to authenticated with check (public.ad_can_edit_rates());
create policy ad_rates_update on public.ad_rates
  for update to authenticated using (public.ad_can_edit_rates()) with check (public.ad_can_edit_rates());

-- Startbestand Vergütung (TEST und PROD; keine Personendaten). Gültig ab 01.01.2026 [ANNAHME, spec.md AD Abschnitt 11];
-- Höchstbetrag mit Historie. Idempotent, überschreibt keine Änderungen des Admins.
insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
select v.k, v.l, v.g::public.ad_rate_group, v.u, v.v, v.d, v.s
  from (values
  ('rTL', 'Tagessatz Trainer:in (Mehrtageskurse, Führungstouren, Trainingslager)', 'remuneration', '€', 50, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rTLh', 'Halbtagessatz Trainer:in (Mehrtageskurse, Führungstouren, Trainingslager)', 'remuneration', '€', 25,
   date '2026-01-01', 'Vergütungsordnung 2025, Anhang 1'),
  ('rH', 'Tagessatz Helfer:in (Mehrtageskurse, Führungstouren, Trainingslager)', 'remuneration', '€', 40, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rHh', 'Halbtagessatz Helfer:in (Mehrtageskurse, Führungstouren, Trainingslager)', 'remuneration', '€', 20,
   date '2026-01-01', 'Vergütungsordnung 2025, Anhang 1'),
  ('rOrg', 'Organisationspauschale je Tag', 'remuneration', '€', 10, date '2026-01-01', 'Vergütungsordnung 2025, Anhang 1'),
  ('rLE', 'Lehreinheit Kurs (1 Stunde)', 'remuneration', '€', 15, date '2026-01-01', 'Vergütungsordnung 2025, Anhang 1'),
  ('rTE', 'Trainingseinheit Trainer:in (30 Minuten)', 'remuneration', '€', 6, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rTEH', 'Trainingseinheit Helfer:in (30 Minuten)', 'remuneration', '€', 4, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rFT', 'Tagessatz Trainer:in (Kinder- und Jugendfahrten, Gruppenfahrten)', 'remuneration', '€', 30, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rFTh', 'Halbtagessatz Trainer:in (Kinder- und Jugendfahrten, Gruppenfahrten)', 'remuneration', '€', 15,
   date '2026-01-01', 'Vergütungsordnung 2025, Anhang 1'),
  ('rFH', 'Tagessatz Helfer:in (Kinder- und Jugendfahrten, Gruppenfahrten)', 'remuneration', '€', 20, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rFHh', 'Halbtagessatz Helfer:in (Kinder- und Jugendfahrten, Gruppenfahrten)', 'remuneration', '€', 10,
   date '2026-01-01', 'Vergütungsordnung 2025, Anhang 1'),
  ('rWK', 'Wettkampfbetreuung je Tag Trainer:in', 'remuneration', '€', 50, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('rWKH', 'Wettkampfbetreuung je Tag Helfer:in', 'remuneration', '€', 40, date '2026-01-01',
   'Vergütungsordnung 2025, Anhang 1'),
  ('maxUeL', 'Steuerfreier Höchstbetrag Übungsleiterpauschale je Kalenderjahr', 'threshold', '€', 3000, date '2021-01-01',
   '§ 3 Nr. 26 EStG'),
  ('maxUeL', 'Steuerfreier Höchstbetrag Übungsleiterpauschale je Kalenderjahr', 'threshold', '€', 3300, date '2026-01-01',
   '§ 3 Nr. 26 EStG')
  ) as v (k, l, g, u, v, d, s)
 where not exists (select 1 from public.ad_rates r where r.rate_key = v.k and r.valid_from = v.d);
