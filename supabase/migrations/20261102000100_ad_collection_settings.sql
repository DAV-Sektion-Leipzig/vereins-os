-- Administration Nachtrag v0.11 (spec.md AD R57, R58; Finanzen FT17): Gläubiger-Identifikationsnummer und Sachkonto der
-- Gruppenbeiträge bei den Angaben der Sektion, Stichtag des ersten Buchungslaufs. Pflege nur Admin (wie R54).

-- Gläubiger-ID: DE + 2 Prüfziffern + 3 Zeichen Geschäftsbereich + 11 Ziffern; Prüfziffer ISO 7064 Mod 97-10 über
-- nationale Kennung + „DE“ (13, 14) + Prüfziffern, Geschäftsbereich ausgenommen
create function public.ad_creditor_id_valid(p_value text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(p_value ~ '^DE[0-9]{2}[A-Z0-9]{3}[0-9]{11}$'
                  and (substr(p_value, 8) || '1314' || substr(p_value, 3, 2))::numeric % 97 = 1, false);
$$;

revoke all on function public.ad_creditor_id_valid(text) from public, anon;
grant execute on function public.ad_creditor_id_valid(text) to authenticated;

alter table public.ad_payout_settings
  add column creditor_id text,
  add column ledger_account_collection text,
  add constraint ad_payout_settings_creditor_id check (creditor_id is null or public.ad_creditor_id_valid(creditor_id)),
  add constraint ad_payout_settings_ledger_collection_length check (
    ledger_account_collection is null or char_length(ledger_account_collection) between 1 and 20);

comment on column public.ad_payout_settings.creditor_id is 'Gläubiger-Identifikationsnummer der Sektion (R57); nötig für den Buchungslauf.';
comment on column public.ad_payout_settings.ledger_account_collection is 'Sachkonto der Gruppenbeiträge für die Einzugsliste (R57).';

create or replace function public.ad_payout_settings_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.debtor_name := btrim(coalesce(new.debtor_name, ''));
  new.ledger_account := btrim(coalesce(new.ledger_account, ''));
  new.bic := upper(regexp_replace(coalesce(new.bic, ''), '\s', '', 'g'));
  new.creditor_id := nullif(upper(regexp_replace(coalesce(new.creditor_id, ''), '\s', '', 'g')), '');
  new.ledger_account_collection := nullif(btrim(coalesce(new.ledger_account_collection, '')), '');
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
  if new.creditor_id is not null and not public.ad_creditor_id_valid(new.creditor_id) then
    raise exception 'AD_CREDITOR_ID_INVALID' using errcode = 'P0001';
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

grant insert (creditor_id, ledger_account_collection), update (creditor_id, ledger_account_collection)
  on table public.ad_payout_settings to authenticated;

-- Rückgabe um beide Felder erweitert (neuer Rückgabetyp: neu anlegen)
drop function public.ad_payout_settings_at(date);
create function public.ad_payout_settings_at(p_date date)
returns table (debtor_name text, iban text, bic text, ledger_account text, valid_from date, creditor_id text,
               ledger_account_collection text)
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
  select s.debtor_name, s.iban, s.bic, s.ledger_account, s.valid_from, s.creditor_id, s.ledger_account_collection
    from public.ad_payout_settings s
   where s.valid_from <= coalesce(p_date, current_date)
   order by s.valid_from desc
   limit 1;
end;
$$;

revoke all on function public.ad_payout_settings_at(date) from public, anon, authenticated;
grant execute on function public.ad_payout_settings_at(date) to authenticated;

-- ---------------------------------------------------------------------------------------------------------------
-- Stichtag des ersten Buchungslaufs (R58): genau eine Zeile
create table public.ad_collection_settings (
  id boolean primary key default true,
  start_month date not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_collection_settings_single check (id),
  constraint ad_collection_settings_month check (extract(day from start_month) = 1)
);

comment on table public.ad_collection_settings is
  'Stichtag des ersten Buchungslaufs im Vereins OS (R58): Verträge mit Beginn davor gelten als bereits eingezogen.';

create trigger ad_collection_settings_stamp
  before update on public.ad_collection_settings
  for each row execute function public.ad_stamp_update();

alter table public.ad_collection_settings enable row level security;
revoke all on table public.ad_collection_settings from public, anon, authenticated;
grant select, insert (start_month), update (start_month) on table public.ad_collection_settings to authenticated;

create policy ad_collection_settings_select on public.ad_collection_settings
  for select to authenticated using (public.ad_has_level('AD', 'read') or public.ad_has_level('FI', 'manage'));
create policy ad_collection_settings_insert on public.ad_collection_settings
  for insert to authenticated with check (public.ad_can_edit_remuneration());
create policy ad_collection_settings_update on public.ad_collection_settings
  for update to authenticated using (public.ad_can_edit_remuneration()) with check (public.ad_can_edit_remuneration());

create function public.ad_collection_start()
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select s.start_month from public.ad_collection_settings s where s.id;
$$;

revoke all on function public.ad_collection_start() from public, anon, authenticated;
grant execute on function public.ad_collection_start() to authenticated;
