-- Finanzen Nachtrag v0.3 (spec.md FI Abschnitt 12, FT19; US-FI-18 bis US-FI-21; R34–R47): Buchungslauf Verträge.
-- Einzug je Vertrag und Monat; keine IBAN und kein Kontoinhaber in fi_-Tabellen (R43), Lesen über
-- gr_contracts_for_collection (Nachtrag GR v0.4). Schreiben nur über die Funktionen dieser Migration.

create type public.fi_collection_status as enum ('draft', 'released');
create type public.fi_sequence as enum ('FRST', 'RCUR');

revoke all on type public.fi_collection_status, public.fi_sequence from public, anon;
grant usage on type public.fi_collection_status, public.fi_sequence to authenticated, service_role;

create table public.fi_collection_runs (
  id uuid primary key default gen_random_uuid(),
  month date not null,
  number smallint not null,
  status public.fi_collection_status not null default 'draft',
  due_date date not null,
  msg_id text,
  pmt_inf_id_frst text,
  pmt_inf_id_rcur text,
  line_count integer,
  total numeric(12, 2),
  total_frst numeric(12, 2),
  total_rcur numeric(12, 2),
  released_at timestamptz,
  released_by uuid,
  released_by_person_id uuid references public.ea_persons (id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  constraint fi_collection_runs_month check (extract(day from month) = 1),
  constraint fi_collection_runs_key unique (month, number),
  constraint fi_collection_runs_msg_id_key unique (msg_id),
  constraint fi_collection_runs_released check (
    (status = 'draft' and msg_id is null) or (status = 'released' and msg_id is not null and released_at is not null))
);

comment on table public.fi_collection_runs is 'Buchungslauf Verträge je Monat, fortlaufend nummeriert (R35).';

create table public.fi_collection_counters (
  month date primary key,
  last_number smallint not null
);

create table public.fi_collections (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.fi_collection_runs (id) on delete cascade,
  contract_id uuid not null references public.gr_contracts (id) on delete restrict,
  month date not null,
  included boolean not null default true,
  excluded_reason text,
  monthly_amount numeric(10, 2) not null,
  extra_amount numeric(10, 2),
  extra_text text,
  extra_reason text,
  amount numeric(10, 2) generated always as (monthly_amount + coalesce(extra_amount, 0)) stored,
  sequence public.fi_sequence not null,
  group_id uuid not null references public.gr_groups (id) on delete restrict,
  group_label text not null,
  participant_person_id uuid not null references public.ea_persons (id) on delete restrict,
  holder_person_id uuid not null references public.ea_persons (id) on delete restrict,
  mandate_reference text not null,
  mandate_signed_on date not null,
  remittance text,
  end_to_end_id text,
  sort_no integer,
  bank_check text not null,
  constraint fi_collections_amount check (monthly_amount > 0),
  constraint fi_collections_excluded check (
    excluded_reason is null or (excluded_reason = 'mandate_not_signed' and not included)),
  constraint fi_collections_extra check (
    (extra_amount is null and extra_text is null and extra_reason is null)
    or (extra_amount > 0 and extra_text is not null and extra_reason is not null
        and char_length(extra_text) between 1 and 60 and char_length(extra_reason) between 1 and 500)),
  constraint fi_collections_end_to_end_key unique (end_to_end_id)
);

comment on table public.fi_collections is 'Einzug je Vertrag und Monat (R34, R35); ohne IBAN und Kontoinhaber (R43).';

-- R35: je Vertrag und Monat höchstens ein enthaltener Einzug (Entwurf oder freigegeben)
create unique index fi_collections_contract_month on public.fi_collections (contract_id, month) where included;
create index fi_collections_run on public.fi_collections (run_id);

alter table public.fi_collection_runs enable row level security;
alter table public.fi_collection_counters enable row level security;
alter table public.fi_collections enable row level security;
revoke all on table public.fi_collection_runs, public.fi_collection_counters, public.fi_collections
  from public, anon, authenticated;
grant select on table public.fi_collection_runs, public.fi_collection_counters, public.fi_collections to authenticated;
create policy fi_collection_runs_select on public.fi_collection_runs
  for select to authenticated using (public.fi_can_manage());
create policy fi_collection_counters_select on public.fi_collection_counters
  for select to authenticated using (public.fi_can_manage());
create policy fi_collections_select on public.fi_collections
  for select to authenticated using (public.fi_can_manage());

-- ---------------------------------------------------------------------------------------------------------------
-- Hilfsfunktionen (intern)

-- Nächster Bankarbeitstag nach p_day (Mo–Fr; Feiertage nicht berücksichtigt, R39)
create function public.fi_next_business_day(p_day date)
returns date language sql immutable set search_path = '' as $$
  select case extract(isodow from p_day + 1)::int when 6 then p_day + 3 when 7 then p_day + 2 else p_day + 1 end;
$$;

-- Vorschlag Fälligkeitstag: heute + 3 Tage, Wochenende → Montag (R39)
create function public.fi_default_due_date(p_today date default current_date)
returns date language sql stable set search_path = '' as $$
  select case extract(isodow from p_today + 3)::int when 6 then p_today + 5 when 7 then p_today + 4 else p_today + 3 end;
$$;

create function public.fi_month_name(p_month date)
returns text language sql immutable set search_path = '' as $$
  select (array['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober',
                'November', 'Dezember'])[extract(month from p_month)::int] || ' ' || extract(year from p_month)::int;
$$;

-- R38: Erstlastschrift, wenn noch kein freigegebener Einzug und Vertragsbeginn am oder nach dem Stichtag
create function public.fi_collection_sequence(p_contract uuid, p_starts_on date)
returns public.fi_sequence language sql stable security definer set search_path = '' as $$
  select case
           when not exists (select 1 from public.fi_collections c
                              join public.fi_collection_runs r on r.id = c.run_id
                             where c.contract_id = p_contract and r.status = 'released')
                and p_starts_on >= public.ad_collection_start()
           then 'FRST'::public.fi_sequence
           else 'RCUR'::public.fi_sequence
         end;
$$;

create function public.fi_lock_collection_run(p_run uuid, p_draft boolean default true)
returns public.fi_collection_runs
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_collection_runs%rowtype;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_r from public.fi_collection_runs r where r.id = p_run for update;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  if p_draft and v_r.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  return v_r;
end;
$$;

-- Zeilen eines Entwurfs mit den Verträgen abgleichen (R34, R35, R37, R38): entfernen, aktualisieren, ergänzen
create function public.fi_fill_collection_run(p_run uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_collection_runs%rowtype;
begin
  select * into v_r from public.fi_collection_runs r where r.id = p_run;
  perform pg_advisory_xact_lock(hashtext('fi_collection_' || v_r.month::text));

  delete from public.fi_collections c
   where c.run_id = p_run
     and not exists (select 1 from public.gr_contracts_for_collection(v_r.month) g where g.contract_id = c.contract_id);

  update public.fi_collections c
     set monthly_amount = g.monthly_amount,
         mandate_reference = g.mandate_reference,
         mandate_signed_on = g.mandate_signed_on,
         group_id = g.group_id,
         group_label = g.group_name,
         participant_person_id = g.participant_person_id,
         holder_person_id = g.holder_person_id,
         bank_check = g.bank_check,
         sequence = public.fi_collection_sequence(g.contract_id, g.starts_on),
         excluded_reason = case when g.mandate_signed_on > v_r.due_date then 'mandate_not_signed' end,
         included = case
                      when g.mandate_signed_on > v_r.due_date then false
                      when c.excluded_reason is not null then not exists (
                        select 1 from public.fi_collections x
                         where x.contract_id = c.contract_id and x.month = c.month and x.included and x.id <> c.id)
                      else c.included
                    end
    from public.gr_contracts_for_collection(v_r.month) g
   where c.run_id = p_run and g.contract_id = c.contract_id;

  insert into public.fi_collections (run_id, contract_id, month, included, excluded_reason, monthly_amount, sequence,
                                     group_id, group_label, participant_person_id, holder_person_id, mandate_reference,
                                     mandate_signed_on, bank_check)
  select p_run, g.contract_id, v_r.month, g.mandate_signed_on <= v_r.due_date,
         case when g.mandate_signed_on > v_r.due_date then 'mandate_not_signed' end,
         g.monthly_amount, public.fi_collection_sequence(g.contract_id, g.starts_on), g.group_id, g.group_name,
         g.participant_person_id, g.holder_person_id, g.mandate_reference, g.mandate_signed_on, g.bank_check
    from public.gr_contracts_for_collection(v_r.month) g
   where not exists (select 1 from public.fi_collections x
                      where x.contract_id = g.contract_id and x.month = v_r.month and (x.included or x.run_id = p_run));
end;
$$;

revoke all on function public.fi_next_business_day(date),
  public.fi_collection_sequence(uuid, date), public.fi_lock_collection_run(uuid, boolean),
  public.fi_fill_collection_run(uuid) from public, anon, authenticated;
revoke all on function public.fi_default_due_date(date) from public, anon;
revoke all on function public.fi_month_name(date) from public, anon;
grant execute on function public.fi_default_due_date(date), public.fi_month_name(date) to authenticated;

-- ---------------------------------------------------------------------------------------------------------------
-- Schreiben (US-FI-18 bis US-FI-20)

create function public.fi_create_collection_run(p_month date, p_due_date date default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_month date := date_trunc('month', p_month)::date;
  v_due date := coalesce(p_due_date, public.fi_default_due_date());
  v_start date := public.ad_collection_start();
  v_number smallint;
  v_id uuid;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  -- R36: kein vergangener Monat, nicht vor dem Stichtag (ohne Stichtag kein Buchungslauf)
  if v_month is null or v_start is null or v_month < v_start
     or v_month < date_trunc('month', current_date)::date then
    raise exception 'FI_COLLECTION_MONTH' using errcode = 'P0001';
  end if;
  if v_due < public.fi_next_business_day(current_date) then
    raise exception 'FI_DUE_DATE' using errcode = 'P0001';
  end if;
  insert into public.fi_collection_counters (month, last_number) values (v_month, 1)
  on conflict (month) do update set last_number = public.fi_collection_counters.last_number + 1
  returning last_number into v_number;
  insert into public.fi_collection_runs (month, number, due_date) values (v_month, v_number, v_due)
  returning id into v_id;
  perform public.fi_fill_collection_run(v_id);
  return v_id;
end;
$$;

create function public.fi_refresh_collection_run(p_run uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.fi_lock_collection_run(p_run);
  perform public.fi_fill_collection_run(p_run);
end;
$$;

create function public.fi_update_collection_run(p_run uuid, p_due_date date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.fi_lock_collection_run(p_run);
  if p_due_date is null or p_due_date < public.fi_next_business_day(current_date) then
    raise exception 'FI_DUE_DATE' using errcode = 'P0001';
  end if;
  update public.fi_collection_runs set due_date = p_due_date where id = p_run;
  perform public.fi_fill_collection_run(p_run);
end;
$$;

create function public.fi_set_collection_included(p_collection uuid, p_included boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_c public.fi_collections%rowtype;
begin
  select * into v_c from public.fi_collections c where c.id = p_collection;
  if not found then
    if not public.fi_can_manage() then
      raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
    end if;
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  perform public.fi_lock_collection_run(v_c.run_id);
  if coalesce(p_included, false) then
    if v_c.excluded_reason is not null then
      raise exception 'FI_COLLECTION_EXCLUDED' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.fi_collections x
                where x.contract_id = v_c.contract_id and x.month = v_c.month and x.included and x.id <> v_c.id) then
      raise exception 'FI_COLLECTION_TAKEN' using errcode = 'P0001';
    end if;
  end if;
  update public.fi_collections set included = coalesce(p_included, false) where id = p_collection;
end;
$$;

create function public.fi_set_collection_extra(p_collection uuid, p_amount numeric, p_text text, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_c public.fi_collections%rowtype;
  v_text text := nullif(btrim(coalesce(p_text, '')), '');
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  select * into v_c from public.fi_collections c where c.id = p_collection;
  if not found then
    if not public.fi_can_manage() then
      raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
    end if;
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  perform public.fi_lock_collection_run(v_c.run_id);
  if p_amount is null then
    update public.fi_collections set extra_amount = null, extra_text = null, extra_reason = null where id = p_collection;
    return;
  end if;
  if p_amount <= 0 or p_amount <> round(p_amount, 2) or p_amount >= 100000 then
    raise exception 'FI_AMOUNT_INVALID' using errcode = 'P0001';
  end if;
  if v_text is null or v_reason is null or char_length(v_text) > 60 or char_length(v_reason) > 500 then
    raise exception 'FI_EXTRA_REQUIRED' using errcode = 'P0001';
  end if;
  update public.fi_collections set extra_amount = p_amount, extra_text = v_text, extra_reason = v_reason
   where id = p_collection;
end;
$$;

create function public.fi_discard_collection_run(p_run uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.fi_lock_collection_run(p_run);
  delete from public.fi_collection_runs where id = p_run;
end;
$$;

-- Freigabe (US-FI-19, R40, R42, R45): prüfen, IDs und Verwendungszweck vergeben, nicht enthaltene Zeilen löschen
create function public.fi_release_collection_run(p_run uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_collection_runs%rowtype;
  v_changed text;
  v_prefix text;
  v_msg text;
begin
  v_r := public.fi_lock_collection_run(p_run);
  if not exists (select 1 from public.fi_collections c where c.run_id = p_run and c.included) then
    raise exception 'FI_COLLECTION_EMPTY' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.ad_payout_settings_at(v_r.due_date) s where s.creditor_id is not null) then
    raise exception 'FI_COLLECTION_SETTINGS_MISSING' using errcode = 'P0001';
  end if;
  if v_r.due_date < public.fi_next_business_day(current_date) then
    raise exception 'FI_DUE_DATE' using errcode = 'P0001';
  end if;
  -- Verträge seit dem Erstellen bzw. Aktualisieren unverändert und am Monatsersten aktiv
  select public.fi_person_label(c.participant_person_id) into v_changed
    from public.fi_collections c
    left join public.gr_contracts_for_collection(v_r.month) g on g.contract_id = c.contract_id
   where c.run_id = p_run and c.included
     and (g.contract_id is null or g.monthly_amount <> c.monthly_amount or g.mandate_reference <> c.mandate_reference
          or g.mandate_signed_on <> c.mandate_signed_on or g.mandate_signed_on > v_r.due_date)
   limit 1;
  if v_changed is not null then
    raise exception 'FI_COLLECTION_CHANGED' using errcode = 'P0001', detail = v_changed;
  end if;

  delete from public.fi_collections c where c.run_id = p_run and not c.included;

  v_prefix := 'FI-L-' || to_char(v_r.month, 'YYYY-MM') || '-' || lpad(v_r.number::text, 2, '0');
  v_msg := v_prefix || '-' || substr(md5(gen_random_uuid()::text), 1, 8);
  with ordered as (
    select c.id,
           row_number() over (order by regexp_replace(c.group_label, '\d+', '', 'g'),
                                       nullif(substring(c.group_label from '\d+'), '')::int nulls first,
                                       c.group_label, p.last_name, coalesce(p.preferred_name, p.first_name), c.id) as n
      from public.fi_collections c
      join public.ea_persons p on p.id = c.participant_person_id
     where c.run_id = p_run
  )
  update public.fi_collections c
     set sequence = public.fi_collection_sequence(c.contract_id, gc.starts_on),
         sort_no = o.n,
         end_to_end_id = v_prefix || '-' || lpad(o.n::text, 4, '0'),
         remittance = left(c.group_label || ' Beitragszahlung ' || public.fi_month_name(c.month)
                           || coalesce(' ' || c.extra_text, ''), 140)
    from ordered o, public.gr_contracts gc
   where o.id = c.id and gc.id = c.contract_id;

  update public.fi_collection_runs r
     set status = 'released', msg_id = v_msg,
         pmt_inf_id_frst = case when x.frst_count > 0 then v_msg || '-FRST' end,
         pmt_inf_id_rcur = case when x.rcur_count > 0 then v_msg || '-RCUR' end,
         line_count = x.cnt, total = x.total, total_frst = x.total_frst, total_rcur = x.total_rcur,
         released_at = now(), released_by = auth.uid(), released_by_person_id = public.fi_my_person_id()
    from (select count(*)::int as cnt, coalesce(sum(c.amount), 0) as total,
                 count(*) filter (where c.sequence = 'FRST') as frst_count,
                 count(*) filter (where c.sequence = 'RCUR') as rcur_count,
                 coalesce(sum(c.amount) filter (where c.sequence = 'FRST'), 0) as total_frst,
                 coalesce(sum(c.amount) filter (where c.sequence = 'RCUR'), 0) as total_rcur
            from public.fi_collections c where c.run_id = p_run) x
   where r.id = p_run;
  return p_run;
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Lesen (US-FI-18, -21)

create function public.fi_list_collection_runs()
returns table (id uuid, month date, number smallint, status public.fi_collection_status, due_date date,
               line_count integer, total numeric, included_count integer, included_total numeric,
               released_at timestamptz, released_by_name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select r.id, r.month, r.number, r.status, r.due_date, r.line_count, r.total,
         (select count(*)::int from public.fi_collections c where c.run_id = r.id and c.included),
         (select coalesce(sum(c.amount), 0) from public.fi_collections c where c.run_id = r.id and c.included),
         r.released_at, public.fi_person_label(r.released_by_person_id)
    from public.fi_collection_runs r
   order by r.month desc, r.number desc;
end;
$$;

create function public.fi_get_collection_run(p_run uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_r public.fi_collection_runs%rowtype;
  v_ids uuid[];
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_r from public.fi_collection_runs r where r.id = p_run;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(c.contract_id), '{}') into v_ids from public.fi_collections c where c.run_id = p_run;
  return jsonb_build_object(
    'run', to_jsonb(v_r) - 'released_by' - 'created_by'
           || jsonb_build_object('released_by_name', public.fi_person_label(v_r.released_by_person_id)),
    'settings_ok', exists (select 1 from public.ad_payout_settings_at(v_r.due_date) s where s.creditor_id is not null),
    'min_due_date', public.fi_next_business_day(current_date),
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', c.id, 'contract_id', c.contract_id, 'included', c.included, 'excluded_reason', c.excluded_reason,
               'participant_name', public.fi_person_label(c.participant_person_id),
               'participant_last_name', p.last_name,
               'holder_name', public.fi_person_label(c.holder_person_id),
               'group_id', c.group_id, 'group_label', c.group_label,
               'mandate_reference', c.mandate_reference, 'mandate_signed_on', c.mandate_signed_on,
               'iban_last4', right(g.iban, 4), 'sequence', c.sequence,
               'monthly_amount', c.monthly_amount, 'extra_amount', c.extra_amount, 'extra_text', c.extra_text,
               'extra_reason', c.extra_reason, 'amount', c.amount, 'remittance', c.remittance,
               'end_to_end_id', c.end_to_end_id, 'sort_no', c.sort_no,
               -- R44: Bankverbindung seit dem letzten freigegebenen Einzug geändert
               'bank_changed_since_last', coalesce((
                 select l.bank_check <> c.bank_check
                   from public.fi_collections l join public.fi_collection_runs lr on lr.id = l.run_id
                  where l.contract_id = c.contract_id and lr.status = 'released' and l.run_id <> p_run
                    and l.month < c.month
                  order by l.month desc limit 1), false))
             order by c.sort_no nulls last, c.group_label, p.last_name, coalesce(p.preferred_name, p.first_name))
        from public.fi_collections c
        join public.ea_persons p on p.id = c.participant_person_id
        left join public.gr_contracts_for_collection(null, v_ids) g on g.contract_id = c.contract_id
       where c.run_id = p_run), '[]'));
end;
$$;

-- Daten für Lastschriftdatei und Einzugsliste eines freigegebenen Laufs (US-FI-19, -21, R40–R43)
create function public.fi_collection_export(p_run uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_r public.fi_collection_runs%rowtype;
  v_ids uuid[];
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_r from public.fi_collection_runs r where r.id = p_run;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_r.status <> 'released' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(c.contract_id), '{}') into v_ids from public.fi_collections c where c.run_id = p_run;
  return jsonb_build_object(
    'run', jsonb_build_object('id', v_r.id, 'month', v_r.month, 'number', v_r.number, 'due_date', v_r.due_date,
                              'msg_id', v_r.msg_id, 'pmt_inf_id_frst', v_r.pmt_inf_id_frst,
                              'pmt_inf_id_rcur', v_r.pmt_inf_id_rcur, 'line_count', v_r.line_count, 'total', v_r.total,
                              'released_at', v_r.released_at,
                              'released_by_name', public.fi_person_label(v_r.released_by_person_id)),
    'creditor', (select to_jsonb(s) from public.ad_payout_settings_at(v_r.due_date) s),
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object(
               'sort_no', c.sort_no, 'participant_first_name', p.first_name, 'participant_last_name', p.last_name,
               'participant_preferred_name', p.preferred_name,
               'holder_name', public.fi_person_label(c.holder_person_id), 'group_label', c.group_label,
               'mandate_reference', c.mandate_reference, 'mandate_signed_on', c.mandate_signed_on,
               'sequence', c.sequence, 'monthly_amount', c.monthly_amount, 'extra_amount', c.extra_amount,
               'extra_text', c.extra_text, 'amount', c.amount, 'remittance', c.remittance,
               'end_to_end_id', c.end_to_end_id, 'account_holder', g.account_holder, 'iban', g.iban,
               'bank_changed', g.bank_check is distinct from c.bank_check)
             order by c.sort_no)
        from public.fi_collections c
        join public.ea_persons p on p.id = c.participant_person_id
        left join public.gr_contracts_for_collection(null, v_ids) g on g.contract_id = c.contract_id
       where c.run_id = p_run), '[]'));
end;
$$;

revoke all on function public.fi_create_collection_run(date, date), public.fi_refresh_collection_run(uuid),
  public.fi_update_collection_run(uuid, date), public.fi_set_collection_included(uuid, boolean),
  public.fi_set_collection_extra(uuid, numeric, text, text), public.fi_discard_collection_run(uuid),
  public.fi_release_collection_run(uuid), public.fi_list_collection_runs(), public.fi_get_collection_run(uuid),
  public.fi_collection_export(uuid) from public, anon, authenticated;
grant execute on function public.fi_create_collection_run(date, date), public.fi_refresh_collection_run(uuid),
  public.fi_update_collection_run(uuid, date), public.fi_set_collection_included(uuid, boolean),
  public.fi_set_collection_extra(uuid, numeric, text, text), public.fi_discard_collection_run(uuid),
  public.fi_release_collection_run(uuid), public.fi_list_collection_runs(), public.fi_get_collection_run(uuid),
  public.fi_collection_export(uuid) to authenticated;
