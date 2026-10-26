-- Bereich Budget (spec.md DS v0.2 Abschnitt 2.3), Task T9 (DT09): DATEV-Import mit Prüfung (US-FI-26; R1, R4, R8, R9).
-- Der Browser liest die Kontenblätter (CSV) und übergibt
-- p_file = {name, info, overview:[{konto, eb, soll, haben}],
--           rows:[{line, konto, datum (JJJJ-MM-TT), bu, gegenkonto, gegenkonto_label, text, beleg, soll, haben, kost1}]}.
-- Gespeichert werden nur Zeilen auf Konten mit Regel (R1); die Datei selbst wird nicht gespeichert.

create function public.fi_budget_import_apply(p_year smallint, p_file jsonb, p_apply boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_import uuid;
  v_counts record;
  v_data_until date;
  v_checks jsonb;
  v_warnings jsonb := '[]';
  v_result jsonb;
  v_relinked int := 0;
  v_obsolete int := 0;
begin
  perform public.fi_budget_require_maintain();
  if not exists (select 1 from public.fi_budget_plans where year = p_year) then
    raise exception 'FI_BUDGET_NO_PLAN' using errcode = 'P0001';
  end if;
  if jsonb_typeof(p_file -> 'rows') is distinct from 'array' or jsonb_array_length(p_file -> 'rows') = 0 then
    raise exception 'FI_BUDGET_NO_ROWS' using errcode = 'P0001';
  end if;

  drop table if exists pg_temp.fi_budget_rows;
  create temp table pg_temp.fi_budget_rows on commit drop as
  select r.line, k.main_account, coalesce(k.sub_account, 0)::smallint as sub_account, r.datum, r.bu, r.gegenkonto,
         r.gegenkonto_label, r.text, r.beleg, coalesce(r.soll, 0) as soll, coalesce(r.haben, 0) as haben,
         nullif(btrim(coalesce(r.kost1, '')), '') as kost1,
         (coalesce(r.text, '') ilike '%EB-Wert%' or coalesce(r.gegenkonto_label, '') ilike 'Saldenvortr%') as opening,
         r.datum is not null and extract(year from r.datum) = p_year as in_year,
         null::uuid as rule_id
    from jsonb_to_recordset(p_file -> 'rows') as r (line int, konto text, datum date, bu text, gegenkonto text,
         gegenkonto_label text, text text, beleg text, soll numeric, haben numeric, kost1 text)
    cross join lateral public.fi_budget_konto_parts(r.konto) k
   where k.main_account is not null;

  update pg_temp.fi_budget_rows
     set rule_id = public.fi_budget_match_rule(p_year, main_account, sub_account, kost1, datum, beleg, soll, haben, text)
   where not opening and in_year;

  select jsonb_array_length(p_file -> 'rows') as rows_read,
         count(*) filter (where rule_id is not null) as rows_saved,
         count(*) filter (where opening) as rows_opening,
         count(*) filter (where not opening and not in_year) as rows_other_year
    into v_counts from pg_temp.fi_budget_rows;
  select max(datum) into v_data_until from pg_temp.fi_budget_rows where in_year and not opening;

  -- R8: je Konto mit gespeicherten Zeilen Summe der Einzelbuchungen des Jahres (ohne Saldovorträge) = Kontenübersicht
  with acc as (
    select main_account, sub_account, sum(soll) as soll, sum(haben) as haben
      from pg_temp.fi_budget_rows r
     where not opening and in_year
       and exists (select 1 from pg_temp.fi_budget_rows s
                    where s.rule_id is not null and s.main_account = r.main_account and s.sub_account = r.sub_account)
     group by main_account, sub_account),
  ov as (
    select k.main_account, coalesce(k.sub_account, 0)::smallint as sub_account, sum(coalesce(o.soll, 0)) as soll,
           sum(coalesce(o.haben, 0)) as haben, sum(o.eb) as eb
      from jsonb_to_recordset(coalesce(p_file -> 'overview', '[]')) as o (konto text, eb numeric, soll numeric, haben numeric)
      cross join lateral public.fi_budget_konto_parts(o.konto) k
     where k.main_account is not null
     group by k.main_account, coalesce(k.sub_account, 0))
  select coalesce(jsonb_agg(jsonb_build_object(
           'konto', a.main_account || ' ' || a.sub_account,
           'overview_debit', o.soll, 'overview_credit', o.haben, 'rows_debit', a.soll, 'rows_credit', a.haben,
           'ok', case when o.main_account is null then null
                      else abs(o.soll - a.soll) <= 0.01 and abs(o.haben - a.haben) <= 0.01 end)
           order by a.main_account, a.sub_account), '[]')
    into v_checks
    from acc a left join ov o on o.main_account = a.main_account and o.sub_account = a.sub_account;

  select v_warnings || coalesce(jsonb_agg(jsonb_build_object('type', 'incomplete', 'konto', c ->> 'konto',
           'overview', (c ->> 'overview_debit')::numeric - (c ->> 'overview_credit')::numeric,
           'rows', (c ->> 'rows_debit')::numeric - (c ->> 'rows_credit')::numeric)), '[]')
    into v_warnings
    from jsonb_array_elements(v_checks) c where (c ->> 'ok') = 'false';

  -- R9: umgeschlüsselte Buchungen (Einzelbuchungsregeln), die im Export nicht mehr vorkommen
  select v_warnings || coalesce(jsonb_agg(jsonb_build_object('type', 'rekey_missing', 'rule', r.id, 'date', r.b_date,
           'konto', r.account_text, 'amount', r.b_amount, 'side', r.b_side)), '[]')
    into v_warnings
    from public.fi_budget_rules r
   where r.year = p_year and r.valid_to is null and r.rule_type = 'booking'
     and not exists (select 1 from pg_temp.fi_budget_rows x where x.rule_id = r.id);

  v_result := jsonb_build_object('rows_read', v_counts.rows_read, 'rows_saved', v_counts.rows_saved,
    'rows_ignored', v_counts.rows_read - v_counts.rows_saved - v_counts.rows_opening - v_counts.rows_other_year,
    'rows_opening', v_counts.rows_opening, 'rows_other_year', v_counts.rows_other_year, 'data_until', v_data_until,
    'checks', v_checks, 'warnings', v_warnings);

  if not p_apply then
    return v_result || jsonb_build_object('import_id', null);
  end if;

  -- Vorigen Import ersetzen (R9)
  delete from public.fi_budget_bookings b using public.fi_budget_imports im
   where im.id = b.import_id and im.year = p_year;
  update public.fi_budget_imports set is_current = false where year = p_year and is_current;

  insert into public.fi_budget_imports (year, file_name, export_info, data_until, rows_read, rows_saved, rows_ignored,
    rows_opening, rows_other_year, checks, warnings)
  values (p_year, coalesce(p_file ->> 'name', ''), nullif(left(coalesce(p_file ->> 'info', ''), 300), ''), v_data_until,
    (v_result ->> 'rows_read')::int, (v_result ->> 'rows_saved')::int, (v_result ->> 'rows_ignored')::int,
    (v_result ->> 'rows_opening')::int, (v_result ->> 'rows_other_year')::int, v_checks, v_warnings)
  returning id into v_import;

  insert into public.fi_budget_bookings (import_id, year, main_account, sub_account, booking_date, bu, contra_account,
    contra_label, booking_text, receipt, debit, credit, cost_center, line_no)
  select v_import, p_year, main_account, sub_account, datum, nullif(bu, ''), nullif(gegenkonto, ''),
         nullif(gegenkonto_label, ''), nullif(text, ''), nullif(beleg, ''), soll, haben, kost1, coalesce(line, 0)
    from pg_temp.fi_budget_rows where rule_id is not null;

  insert into public.fi_budget_account_totals (import_id, main_account, sub_account, opening, debit, credit)
  select v_import, k.main_account, coalesce(k.sub_account, 0)::smallint, sum(o.eb), sum(coalesce(o.soll, 0)),
         sum(coalesce(o.haben, 0))
    from jsonb_to_recordset(coalesce(p_file -> 'overview', '[]')) as o (konto text, eb numeric, soll numeric, haben numeric)
    cross join lateral public.fi_budget_konto_parts(o.konto) k
   where k.main_account is not null
     and exists (select 1 from pg_temp.fi_budget_rows r where r.rule_id is not null
                  and r.main_account = k.main_account and r.sub_account = coalesce(k.sub_account, 0))
   group by k.main_account, coalesce(k.sub_account, 0);

  -- Monatssummen des Jahres ersetzen (R19, R20)
  delete from public.fi_budget_month_totals where year = p_year;
  insert into public.fi_budget_month_totals (year, month, main_account, sub_account, cost_center, debit, credit)
  select p_year, extract(month from datum)::smallint, main_account, sub_account, coalesce(kost1, ''), sum(soll), sum(haben)
    from pg_temp.fi_budget_rows where rule_id is not null
   group by extract(month from datum), main_account, sub_account, coalesce(kost1, '');

  -- Offene Vorschläge mit der neuen Buchung verbinden; ohne Treffer gegenstandslos (A5)
  update public.fi_budget_proposals p
     set booking_id = b.id
    from public.fi_budget_bookings b
   where p.year = p_year and p.status = 'proposed' and b.import_id = v_import
     and b.booking_date = p.b_date and b.main_account = p.b_main_account and b.sub_account = p.b_sub_account
     and public.fi_budget_norm(b.receipt) = public.fi_budget_norm(p.b_receipt)
     and public.fi_budget_norm(b.booking_text) = public.fi_budget_norm(p.b_text)
     and ((p.b_side = 'S' and b.debit = p.b_amount) or (p.b_side = 'H' and b.credit = p.b_amount));
  get diagnostics v_relinked = row_count;
  update public.fi_budget_proposals
     set status = 'obsolete', decided_at = now()
   where year = p_year and status = 'proposed' and booking_id is null;
  get diagnostics v_obsolete = row_count;

  perform public.fi_budget_write_log(p_year, 'booking_import', v_import,
    jsonb_build_object('file', p_file ->> 'name', 'rows_saved', v_result ->> 'rows_saved',
                       'warnings', jsonb_array_length(v_warnings), 'proposals_obsolete', v_obsolete));
  return v_result || jsonb_build_object('import_id', v_import, 'proposals_obsolete', v_obsolete);
end;
$$;

create function public.fi_budget_import_preview(p_year smallint, p_file jsonb)
returns jsonb language sql security definer set search_path = '' as $$
  select public.fi_budget_import_apply(p_year, p_file, false);
$$;

create function public.fi_budget_import(p_year smallint, p_file jsonb)
returns jsonb language sql security definer set search_path = '' as $$
  select public.fi_budget_import_apply(p_year, p_file, true);
$$;

revoke all on function public.fi_budget_import_apply(smallint, jsonb, boolean) from public, anon, authenticated;
revoke all on function public.fi_budget_import_preview(smallint, jsonb), public.fi_budget_import(smallint, jsonb)
  from public, anon;
grant execute on function public.fi_budget_import_preview(smallint, jsonb), public.fi_budget_import(smallint, jsonb)
  to authenticated;
