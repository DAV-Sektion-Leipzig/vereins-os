-- Finanzen (FI), spec T6; US-FI-14 bis US-FI-16; R12–R14, R20, R21, R24–R30: Auszahlungsrunden.
-- Die Freigabe bildet Auszahlzeilen je Person und Gruppe; Auszahlliste (PDF) und Überweisungsdatei (XML,
-- pain.001.001.03) erzeugt das Frontend aus fi_payout_export. Name und IBAN werden nicht gespeichert (R21).

-- Abrechnung auszahlbar (R12–R14, Betrag > 0); intern
create function public.fi_payable(p_settlement uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((public.fi_settlement_info(p_settlement) ->> 'payable')::boolean, false);
$$;

revoke all on function public.fi_payable(uuid) from public, anon, authenticated;

-- Runde laden und sperren; nur „FI verwalten“; intern
create function public.fi_lock_run(p_run uuid)
returns public.fi_payout_runs
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_r from public.fi_payout_runs r where r.id = p_run for update;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  return v_r;
end;
$$;

revoke all on function public.fi_lock_run(uuid) from public, anon, authenticated;

-- Neue Runde mit allen abgegebenen, auszahlbaren Abrechnungen ohne Runde (US-FI-14 AK1, R25, R30)
create function public.fi_create_payout_run(p_year smallint, p_half smallint, p_execution_date date)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_number smallint;
  v_id uuid;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_half is null or p_half not in (1, 2) or p_year is null or p_year not between 2026 and 2100 then
    raise exception 'FI_PERIOD_INVALID' using errcode = 'P0001';
  end if;
  if p_execution_date is null or p_execution_date < current_date then
    raise exception 'FI_EXECUTION_DATE' using errcode = 'P0001';
  end if;
  insert into public.fi_run_counters (year, half, last_number) values (p_year, p_half, 1)
  on conflict (year, half) do update set last_number = public.fi_run_counters.last_number + 1
  returning last_number into v_number;
  insert into public.fi_payout_runs (year, half, number, execution_date)
  values (p_year, p_half, v_number, p_execution_date)
  returning id into v_id;
  update public.fi_settlements s
     set payout_run_id = v_id
   where s.year = p_year and s.half = p_half and s.status = 'submitted' and s.payout_run_id is null
     and public.fi_payable(s.id);
  return v_id;
end;
$$;

-- Auswahl der Abrechnungen einer Runde im Entwurf ersetzen (US-FI-14 AK4)
create function public.fi_set_payout_run_settlements(p_run uuid, p_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype := public.fi_lock_run(p_run);
  v_id uuid;
begin
  if v_r.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  foreach v_id in array coalesce(p_ids, '{}') loop
    if not exists (select 1 from public.fi_settlements s
                    where s.id = v_id and s.year = v_r.year and s.half = v_r.half and s.status = 'submitted'
                      and (s.payout_run_id is null or s.payout_run_id = p_run)) or not public.fi_payable(v_id) then
      raise exception 'FI_NOT_PAYABLE' using errcode = 'P0001', detail = v_id::text;
    end if;
  end loop;
  update public.fi_settlements set payout_run_id = null where payout_run_id = p_run and not (id = any (coalesce(p_ids, '{}')));
  update public.fi_settlements set payout_run_id = p_run where id = any (coalesce(p_ids, '{}'));
end;
$$;

create function public.fi_update_payout_run(p_run uuid, p_execution_date date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype := public.fi_lock_run(p_run);
begin
  if v_r.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  if p_execution_date is null or p_execution_date < current_date then
    raise exception 'FI_EXECUTION_DATE' using errcode = 'P0001';
  end if;
  update public.fi_payout_runs set execution_date = p_execution_date where id = p_run;
end;
$$;

-- Runde im Entwurf verwerfen; die Nummer wird nicht wieder vergeben (R25)
create function public.fi_discard_payout_run(p_run uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype := public.fi_lock_run(p_run);
begin
  if v_r.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  update public.fi_settlements set payout_run_id = null where payout_run_id = p_run;
  delete from public.fi_payout_runs where id = p_run;
end;
$$;

-- Bezeichnung der Gruppe einer Position bzw. des Referats ohne Gruppe; intern
create function public.fi_group_label(p_group uuid, p_referat uuid)
returns text language sql stable security definer set search_path = '' as $$
  select coalesce((select g.name from public.gr_groups g where g.id = p_group),
                  (select r.name from public.ea_referate r where r.id = p_referat));
$$;

revoke all on function public.fi_group_label(uuid, uuid) from public, anon, authenticated;

-- Auszahlzeilen je Person und Gruppe (R24) einer Menge von Abrechnungen; intern, sortiert nach Gruppe (natürlich),
-- dann Zuname, Vorname (C6)
create function public.fi_lines_for(p_ids uuid[])
returns table (settlement_id uuid, person_id uuid, group_id uuid, referat_id uuid, group_label text, amount numeric,
               last_name text, first_name text, sort_no int)
language sql
stable
security definer
set search_path = ''
as $$
  with l as (
    select i.settlement_id, s.person_id, i.group_id,
           case when i.group_id is null then i.referat_id end as referat_id,
           public.fi_group_label(i.group_id, i.referat_id) as group_label,
           sum(i.amount) as amount
      from public.fi_settlement_items i
      join public.fi_settlements s on s.id = i.settlement_id
     where i.settlement_id = any (p_ids)
     group by i.settlement_id, s.person_id, i.group_id, case when i.group_id is null then i.referat_id end,
              public.fi_group_label(i.group_id, i.referat_id)
  )
  select l.settlement_id, l.person_id, l.group_id, l.referat_id, l.group_label, l.amount, p.last_name, p.first_name,
         (row_number() over (order by regexp_replace(l.group_label, '\d+', '', 'g'),
                                      nullif(substring(l.group_label from '\d+'), '')::int nulls first,
                                      l.group_label, p.last_name, p.first_name, l.settlement_id))::int
    from l join public.ea_persons p on p.id = l.person_id
   where l.amount > 0;
$$;

revoke all on function public.fi_lines_for(uuid[]) from public, anon, authenticated;

-- Vorschau einer Runde (US-FI-14 AK2, AK3): Zeilen, Summe, ausgeschlossene Abrechnungen mit Grund
create function public.fi_preview_payout_run(p_run uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_r from public.fi_payout_runs r where r.id = p_run;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  return jsonb_build_object(
    'run', to_jsonb(v_r) - 'released_by' - 'created_by',
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object('settlement_id', l.settlement_id, 'last_name', l.last_name,
                                          'first_name', l.first_name, 'group_label', l.group_label, 'amount', l.amount)
                       order by l.sort_no)
        from public.fi_lines_for(array(select s.id from public.fi_settlements s where s.payout_run_id = p_run)) l), '[]'),
    'total', coalesce((select sum(l.amount)
                         from public.fi_lines_for(array(select s.id from public.fi_settlements s
                                                          where s.payout_run_id = p_run)) l), 0),
    'available', coalesce((
      select jsonb_agg(jsonb_build_object('settlement_id', s.id, 'display_name', public.fi_person_label(s.person_id),
                                          'amount', s.amount, 'payable', (x.info ->> 'payable')::boolean,
                                          'reasons', x.info -> 'not_payable_reasons')
                       order by public.fi_person_label(s.person_id))
        from public.fi_settlements s
        cross join lateral (select public.fi_settlement_info(s.id) as info) x
       where s.year = v_r.year and s.half = v_r.half and s.status = 'submitted'
         and (s.payout_run_id is null or s.payout_run_id = p_run)
         and v_r.status = 'draft'), '[]'));
end;
$$;

-- Freigabe (US-FI-15, R20, R24, R26, R28): Zeilen, IDs, Abrechnungen ausgezahlt
create function public.fi_release_payout_run(p_run uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype := public.fi_lock_run(p_run);
  v_ids uuid[];
  v_id uuid;
  v_prefix text;
  v_count int;
  v_total numeric;
begin
  if v_r.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.ad_payout_settings_at(v_r.execution_date)) then
    raise exception 'FI_PAYOUT_SETTINGS_MISSING' using errcode = 'P0001';
  end if;
  perform 1 from public.fi_settlements s where s.payout_run_id = p_run for update;
  select coalesce(array_agg(s.id), '{}') into v_ids from public.fi_settlements s where s.payout_run_id = p_run;
  if cardinality(v_ids) = 0 then
    raise exception 'FI_RUN_EMPTY' using errcode = 'P0001';
  end if;
  foreach v_id in array v_ids loop
    if not public.fi_payable(v_id)
       or not exists (select 1 from public.fi_settlements s where s.id = v_id and s.status = 'submitted') then
      raise exception 'FI_NOT_PAYABLE' using errcode = 'P0001',
        detail = coalesce((select public.fi_person_label(s.person_id) from public.fi_settlements s where s.id = v_id), '');
    end if;
  end loop;
  if v_r.execution_date < current_date then
    raise exception 'FI_EXECUTION_DATE' using errcode = 'P0001';
  end if;

  v_prefix := 'FI-' || v_r.year || '-' || v_r.half || '-' || lpad(v_r.number::text, 2, '0');
  insert into public.fi_payout_lines (run_id, settlement_id, person_id, group_id, referat_id, group_label, amount,
                                      remittance, end_to_end_id, bank_check, sort_no)
  select p_run, l.settlement_id, l.person_id, l.group_id, l.referat_id, l.group_label, l.amount,
         left('ÜL-Vergütung ' || v_r.half || '. Hj ' || v_r.year || ' ' || l.group_label, 140),
         v_prefix || '-' || lpad(l.sort_no::text, 4, '0'),
         (select f.bank_check from public.fi_person_flags(l.person_id, v_r.year) f),
         l.sort_no
    from public.fi_lines_for(v_ids) l;
  select count(*), coalesce(sum(pl.amount), 0) into v_count, v_total from public.fi_payout_lines pl where pl.run_id = p_run;
  if v_count = 0 then
    raise exception 'FI_RUN_EMPTY' using errcode = 'P0001';
  end if;

  update public.fi_payout_runs
     set status = 'released', msg_id = v_prefix || '-' || substr(md5(gen_random_uuid()::text), 1, 8),
         pmt_inf_id = v_prefix || '-P', line_count = v_count, total = v_total,
         released_at = now(), released_by = auth.uid(), released_by_person_id = public.fi_my_person_id()
   where id = p_run;
  update public.fi_settlements set status = 'paid' where id = any (v_ids);
  foreach v_id in array v_ids loop
    perform public.fi_log(v_id, 'paid', jsonb_build_object('run', p_run, 'number', v_r.number,
                                                          'execution_date', v_r.execution_date));
  end loop;
  return p_run;
end;
$$;

-- Daten für Auszahlliste und Überweisungsdatei einer freigegebenen Runde (US-FI-15, -16, R21, R26–R29)
create function public.fi_payout_export(p_run uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_r public.fi_payout_runs%rowtype;
  v_ids uuid[];
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_r from public.fi_payout_runs r where r.id = p_run;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_r.status <> 'released' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(distinct pl.person_id), '{}') into v_ids from public.fi_payout_lines pl where pl.run_id = p_run;

  return jsonb_build_object(
    'run', jsonb_build_object('id', v_r.id, 'year', v_r.year, 'half', v_r.half, 'number', v_r.number,
                              'execution_date', v_r.execution_date, 'msg_id', v_r.msg_id, 'pmt_inf_id', v_r.pmt_inf_id,
                              'line_count', v_r.line_count, 'total', v_r.total, 'released_at', v_r.released_at,
                              'released_by_name', public.fi_person_label(v_r.released_by_person_id)),
    'debtor', (select to_jsonb(d) from public.ad_payout_settings_at(v_r.execution_date) d),
    'confirmations', coalesce((
      select jsonb_agg(jsonb_build_object('referat_name', x.referat_name, 'name', x.name, 'date', x.date,
                                          'is_substitute', x.is_substitute) order by x.referat_name, x.name)
        from (select distinct r.name as referat_name, public.fi_person_label(c.confirmed_by_person_id) as name,
                     c.confirmed_at::date as date, c.is_substitute
                from public.fi_settlement_confirmations c
                join public.ea_referate r on r.id = c.referat_id
               where c.settlement_id in (select pl.settlement_id from public.fi_payout_lines pl where pl.run_id = p_run)) x),
      '[]'),
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object(
               'sort_no', pl.sort_no, 'last_name', p.last_name, 'first_name', p.first_name, 'amount', pl.amount,
               'group_label', pl.group_label, 'remittance', pl.remittance, 'end_to_end_id', pl.end_to_end_id,
               'account_holder', fd.account_holder, 'iban', fd.iban,
               'bank_changed', pl.bank_check is distinct from (case when fd.iban is null then null else md5(fd.iban) end))
             order by pl.sort_no)
        from public.fi_payout_lines pl
        join public.ea_persons p on p.id = pl.person_id
        left join public.ea_person_finance_data(v_ids, current_date) fd on fd.person_id = pl.person_id
       where pl.run_id = p_run), '[]'));
end;
$$;

-- Liste der Runden (US-FI-16 AK1)
create function public.fi_list_payout_runs(p_year smallint default null, p_half smallint default null)
returns table (id uuid, year smallint, half smallint, number smallint, status public.fi_run_status, execution_date date,
               line_count integer, total numeric, settlement_count integer, released_at timestamptz,
               released_by_name text)
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
  select r.id, r.year, r.half, r.number, r.status, r.execution_date, r.line_count, r.total,
         (select count(*)::int from public.fi_settlements s where s.payout_run_id = r.id),
         r.released_at, public.fi_person_label(r.released_by_person_id)
    from public.fi_payout_runs r
   where (p_year is null or r.year = p_year) and (p_half is null or r.half = p_half)
   order by r.year desc, r.half desc, r.number desc;
end;
$$;

revoke all on function public.fi_create_payout_run(smallint, smallint, date) from public, anon, authenticated;
revoke all on function public.fi_set_payout_run_settlements(uuid, uuid[]) from public, anon, authenticated;
revoke all on function public.fi_update_payout_run(uuid, date) from public, anon, authenticated;
revoke all on function public.fi_discard_payout_run(uuid) from public, anon, authenticated;
revoke all on function public.fi_preview_payout_run(uuid) from public, anon, authenticated;
revoke all on function public.fi_release_payout_run(uuid) from public, anon, authenticated;
revoke all on function public.fi_payout_export(uuid) from public, anon, authenticated;
revoke all on function public.fi_list_payout_runs(smallint, smallint) from public, anon, authenticated;
grant execute on function public.fi_create_payout_run(smallint, smallint, date) to authenticated;
grant execute on function public.fi_set_payout_run_settlements(uuid, uuid[]) to authenticated;
grant execute on function public.fi_update_payout_run(uuid, date) to authenticated;
grant execute on function public.fi_discard_payout_run(uuid) to authenticated;
grant execute on function public.fi_preview_payout_run(uuid) to authenticated;
grant execute on function public.fi_release_payout_run(uuid) to authenticated;
grant execute on function public.fi_payout_export(uuid) to authenticated;
grant execute on function public.fi_list_payout_runs(smallint, smallint) to authenticated;
