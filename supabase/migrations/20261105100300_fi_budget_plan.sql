-- Bereich Budget (spec.md DS v0.2 Abschnitt 2.3), Tasks T7 und T8 (DT07, DT08): Finanzplan einlesen (US-FI-22),
-- Gesamtbudgets (US-FI-23), neues Jahr (US-FI-29), Zuordnung pflegen (US-FI-24), Übernahme zuordnung.csv (US-FI-25).
-- Nur mit Budgetpflege (ad_has_budget_maintain), sonst FI_BUDGET_FORBIDDEN. Vorschau = gleiche Funktion, die am Ende
-- per Ausnahme zurückrollt (FI_BUDGET_PREVIEW_ROLLBACK, wird abgefangen).

create function public.fi_budget_require_maintain()
returns void language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.ad_has_budget_maintain() then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
end;
$$;

create function public.fi_budget_write_log(p_year smallint, p_action text, p_object uuid, p_details jsonb)
returns void language sql security definer set search_path = '' as $$
  insert into public.fi_budget_log (year, action, object_id, details, actor_person_id)
  values (p_year, p_action, p_object, coalesce(p_details, '{}'::jsonb), public.fi_my_person_id());
$$;

-- Startwert der Sichtbarkeit eines neuen Gesamtbudgets (00-steckbrief.md DS „Gesamtbudgets und Referate“):
-- gleichnamiges Gesamtbudget des Vorjahres, sonst gleichnamiges aktives Referat, sonst „alle“ für Veranstaltungen und
-- Fördermittel, sonst „ohne Referat“ (R22)
create function public.fi_budget_default_visibility(p_year smallint, p_name text,
  out visibility public.fi_budget_visibility, out referat_id uuid)
language plpgsql stable security definer set search_path = '' as $$
begin
  select g.visibility, g.referat_id into visibility, referat_id
    from public.fi_budget_groups g where g.year = p_year - 1 and lower(g.name) = lower(btrim(p_name));
  if found then
    return;
  end if;
  select r.id into referat_id from public.ea_referate r where lower(r.name) = lower(btrim(p_name)) and r.is_active;
  if referat_id is not null then
    visibility := 'referat';
  elsif lower(btrim(p_name)) in ('veranstaltungen', 'fördermittel') then
    visibility := 'all';
  else
    visibility := 'none';
  end if;
end;
$$;

-- Gesamtbudget des Jahres mit Namen holen oder anlegen
create function public.fi_budget_group_get(p_year smallint, p_name text, p_sort int)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
  v_vis record;
begin
  select g.id into v_id from public.fi_budget_groups g where g.year = p_year and lower(g.name) = lower(btrim(p_name));
  if v_id is null then
    select * into v_vis from public.fi_budget_default_visibility(p_year, p_name);
    insert into public.fi_budget_groups (year, name, visibility, referat_id, sort_order)
    values (p_year, btrim(p_name), v_vis.visibility, v_vis.referat_id, coalesce(p_sort, 0))
    returning id into v_id;
  end if;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Finanzplan einlesen (B1, R10). p_source = {file, sheet, items:[{kind, name, plan, row}], sums:{income, expense}};
-- die Excel liest der Browser.
create function public.fi_budget_plan_apply(p_year smallint, p_source jsonb, p_apply boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_item record;
  v_kind text;
  v_sum numeric;
  v_excel numeric;
  v_prev_group text;
  v_group_name text;
  v_occ int;
  v_group uuid;
  v_id uuid;
  v_seen uuid[] := '{}';
  v_rows jsonb := '[]';
  v_removed jsonb := '[]';
  v_warnings jsonb := '[]';
  v_result jsonb;
  v_sort int := 0;
  v_status text;
  v_old numeric;
begin
  perform public.fi_budget_require_maintain();
  if p_year is null or p_year not between 2026 and 2100 then
    raise exception 'FI_BUDGET_NO_PLAN' using errcode = 'P0001';
  end if;
  if jsonb_typeof(p_source -> 'items') is distinct from 'array' or jsonb_array_length(p_source -> 'items') = 0 then
    raise exception 'FI_BUDGET_PLAN_EMPTY' using errcode = 'P0001';
  end if;

  -- R10: Summe der Posten = Summenzeile der Excel
  foreach v_kind in array array['income', 'expense'] loop
    select coalesce(sum((e ->> 'plan')::numeric), 0) into v_sum
      from jsonb_array_elements(p_source -> 'items') e where e ->> 'kind' = v_kind;
    v_excel := (p_source -> 'sums' ->> v_kind)::numeric;
    if v_excel is not null and abs(v_excel - v_sum) > 0.01 then
      raise exception 'FI_BUDGET_SUM_MISMATCH' using errcode = 'P0001',
        detail = jsonb_build_object('kind', v_kind, 'sum', v_sum, 'excel', v_excel)::text;
    end if;
  end loop;

  begin
    insert into public.fi_budget_plans (year, source_file, sheet, sum_income, sum_expense)
    values (p_year, coalesce(p_source ->> 'file', ''), coalesce(p_source ->> 'sheet', ''),
            (p_source -> 'sums' ->> 'income')::numeric, (p_source -> 'sums' ->> 'expense')::numeric)
    on conflict (year) do update
      set source_file = excluded.source_file, sheet = excluded.sheet, sum_income = excluded.sum_income,
          sum_expense = excluded.sum_expense, imported_at = now(), imported_by = auth.uid();

    foreach v_kind in array array['income', 'expense'] loop
      v_prev_group := null;
      for v_item in
        select e ->> 'name' as name, (e ->> 'plan')::numeric as plan, (e ->> 'row')::int as row_no, ord
          from jsonb_array_elements(p_source -> 'items') with ordinality as t (e, ord)
         where e ->> 'kind' = v_kind
         order by ord
      loop
        v_sort := v_sort + 1;
        if btrim(coalesce(v_item.name, '')) = '' then
          raise exception 'FI_BUDGET_PLAN_EMPTY' using errcode = 'P0001';
        end if;
        -- n-tes Vorkommen dieses Namens in der Liste
        select count(*)::int into v_occ
          from jsonb_array_elements(p_source -> 'items') with ordinality as t (e, ord)
         where e ->> 'kind' = v_kind and lower(btrim(e ->> 'name')) = lower(btrim(v_item.name)) and ord <= v_item.ord;
        -- Gesamtbudget: bisherige Zuordnung im Jahr, sonst Vorjahr, sonst bei doppeltem Namen das des Postens darüber,
        -- sonst der Postenname (wie build.py)
        select g.name into v_group_name
          from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
         where i.year = p_year and i.kind = v_kind::public.fi_budget_kind and lower(i.name) = lower(btrim(v_item.name))
         order by i.removed_at nulls first, i.sort_order offset v_occ - 1 limit 1;
        if v_group_name is null then
          select g.name into v_group_name
            from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
           where i.year = p_year - 1 and i.kind = v_kind::public.fi_budget_kind and i.removed_at is null
             and lower(i.name) = lower(btrim(v_item.name))
           order by i.sort_order offset v_occ - 1 limit 1;
        end if;
        if v_group_name is null then
          if (select count(*) from jsonb_array_elements(p_source -> 'items') e
               where e ->> 'kind' = v_kind and lower(btrim(e ->> 'name')) = lower(btrim(v_item.name))) > 1
             and v_prev_group is not null then
            v_group_name := v_prev_group;
            v_warnings := v_warnings || jsonb_build_object('type', 'duplicate_name', 'name', btrim(v_item.name),
              'row', v_item.row_no, 'group', v_group_name);
          else
            v_group_name := btrim(v_item.name);
          end if;
        end if;
        v_prev_group := v_group_name;
        v_group := public.fi_budget_group_get(p_year, v_group_name, v_sort);

        select i.id, i.plan_decided into v_id, v_old from public.fi_budget_items i
         where i.year = p_year and i.kind = v_kind::public.fi_budget_kind and i.group_id = v_group
           and lower(i.name) = lower(btrim(v_item.name));
        if v_id is null then
          insert into public.fi_budget_items (year, group_id, kind, name, plan_decided, excel_row, sort_order)
          values (p_year, v_group, v_kind::public.fi_budget_kind, btrim(v_item.name), v_item.plan, v_item.row_no, v_sort)
          returning id into v_id;
          v_status := 'new';
        else
          if v_id = any (v_seen) then
            raise exception 'FI_BUDGET_ITEM_DUPLICATE' using errcode = 'P0001',
              detail = jsonb_build_object('name', btrim(v_item.name), 'group', v_group_name)::text;
          end if;
          update public.fi_budget_items
             set plan_decided = v_item.plan, excel_row = v_item.row_no, sort_order = v_sort, removed_at = null
           where id = v_id;
          v_status := case when v_old is distinct from v_item.plan then 'changed' else 'same' end;
        end if;
        v_seen := v_seen || v_id;
        v_rows := v_rows || jsonb_build_object('kind', v_kind, 'name', btrim(v_item.name), 'group', v_group_name,
          'plan', v_item.plan, 'row', v_item.row_no, 'status', v_status);
        v_group_name := null;
      end loop;
    end loop;

    -- Entfallene Posten bleiben für Verweise, werden aber nicht mehr angezeigt
    select coalesce(jsonb_agg(jsonb_build_object('kind', i.kind, 'name', i.name, 'group', g.name)), '[]')
      into v_removed
      from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
     where i.year = p_year and i.removed_at is null and not (i.id = any (v_seen));
    update public.fi_budget_items set removed_at = now()
     where year = p_year and removed_at is null and not (id = any (v_seen));

    -- Bestätigte Umschichtungen mit entfallenem Posten (B1 Schritt 4)
    select v_warnings || coalesce(jsonb_agg(jsonb_build_object('type', 'reallocation_removed_item',
             'reallocation', a.id, 'amount', a.amount)), '[]')
      into v_warnings
      from public.fi_budget_reallocations a
      join public.fi_budget_items f on f.id = a.from_item
      join public.fi_budget_items t on t.id = a.to_item
     where a.year = p_year and a.status = 'confirmed' and (f.removed_at is not null or t.removed_at is not null);

    v_result := jsonb_build_object('year', p_year, 'items', v_rows, 'removed', v_removed, 'warnings', v_warnings,
      'sums', jsonb_build_object(
        'income', (select coalesce(sum(plan_decided), 0) from public.fi_budget_items
                    where year = p_year and kind = 'income' and removed_at is null),
        'expense', (select coalesce(sum(plan_decided), 0) from public.fi_budget_items
                     where year = p_year and kind = 'expense' and removed_at is null)));

    if not p_apply then
      raise exception 'FI_BUDGET_PREVIEW_ROLLBACK' using errcode = 'P0001';
    end if;
    perform public.fi_budget_write_log(p_year, 'plan_import', null,
      jsonb_build_object('file', p_source ->> 'file', 'items', jsonb_array_length(v_rows),
                         'removed', jsonb_array_length(v_removed)));
  exception when raise_exception then
    if sqlerrm <> 'FI_BUDGET_PREVIEW_ROLLBACK' then
      raise;
    end if;
  end;
  return v_result;
end;
$$;

create function public.fi_budget_plan_preview(p_year smallint, p_source jsonb)
returns jsonb language sql security definer set search_path = '' as $$
  select public.fi_budget_plan_apply(p_year, p_source, false);
$$;

create function public.fi_budget_plan_import(p_year smallint, p_source jsonb)
returns jsonb language sql security definer set search_path = '' as $$
  select public.fi_budget_plan_apply(p_year, p_source, true);
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Sichtbarkeit eines Gesamtbudgets (US-FI-23, R22)
create function public.fi_budget_group_set(p_group uuid, p_visibility public.fi_budget_visibility, p_referat uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_year smallint;
begin
  perform public.fi_budget_require_maintain();
  if p_visibility = 'referat' and p_referat is null then
    raise exception 'FI_BUDGET_REFERAT_REQUIRED' using errcode = 'P0001';
  end if;
  update public.fi_budget_groups
     set visibility = p_visibility, referat_id = case when p_visibility = 'referat' then p_referat end
   where id = p_group
  returning year into v_year;
  if v_year is null then
    raise exception 'FI_BUDGET_ITEM_UNKNOWN' using errcode = 'P0001';
  end if;
  perform public.fi_budget_write_log(v_year, 'group_set', p_group,
    jsonb_build_object('visibility', p_visibility, 'referat', p_referat));
end;
$$;

-- Budgetposten einem anderen Gesamtbudget zuordnen (plan.md P8)
create function public.fi_budget_item_move(p_item uuid, p_group_name text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_item record;
  v_group uuid;
begin
  perform public.fi_budget_require_maintain();
  select * into v_item from public.fi_budget_items where id = p_item and removed_at is null;
  if v_item.id is null or btrim(coalesce(p_group_name, '')) = '' then
    raise exception 'FI_BUDGET_ITEM_UNKNOWN' using errcode = 'P0001';
  end if;
  v_group := public.fi_budget_group_get(v_item.year, p_group_name, v_item.sort_order);
  update public.fi_budget_items set group_id = v_group where id = p_item;
  delete from public.fi_budget_groups g
   where g.year = v_item.year and not exists (select 1 from public.fi_budget_items i where i.group_id = g.id);
  perform public.fi_budget_write_log(v_item.year, 'item_move', p_item, jsonb_build_object('group', btrim(p_group_name)));
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Zuordnungsregel anlegen oder ersetzen (US-FI-24, R11). p_rule = {id?, year, account_text, cost_centers[], item_id,
-- status, note, account_label, b_date, b_receipt, b_amount, b_side, b_text, reason}
create function public.fi_budget_rule_insert(p_year smallint, p_rule jsonb, p_comment text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_parsed jsonb;
  v_booking boolean;
  v_item uuid := nullif(p_rule ->> 'item_id', '')::uuid;
  v_cc text[];
  v_id uuid;
begin
  v_parsed := public.fi_budget_rule_parse(p_rule ->> 'account_text');
  v_booking := coalesce(p_rule ->> 'b_date', p_rule ->> 'b_receipt', p_rule ->> 'b_amount', p_rule ->> 'b_text') is not null;
  if v_booking and v_parsed ->> 'rule_type' <> 'account' then
    raise exception 'FI_BUDGET_ACCOUNT_INVALID' using errcode = 'P0001', detail = p_rule ->> 'account_text';
  end if;
  if v_booking and btrim(coalesce(p_rule ->> 'reason', '')) = '' then
    raise exception 'FI_BUDGET_REASON_REQUIRED' using errcode = 'P0001';
  end if;
  if v_item is not null and not exists (select 1 from public.fi_budget_items i
                                         where i.id = v_item and i.year = p_year and i.removed_at is null) then
    raise exception 'FI_BUDGET_ITEM_UNKNOWN' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(distinct btrim(c) order by btrim(c)), '{}') into v_cc
    from jsonb_array_elements_text(coalesce(p_rule -> 'cost_centers', '[]')) c where btrim(c) <> '';
  begin
    insert into public.fi_budget_rules (year, rule_type, account_text, main_account, sub_account, range_from, range_to,
      range_full, cost_centers, item_id, status, note, account_label, b_date, b_receipt, b_amount, b_side, b_text,
      reason, comment)
    values (p_year,
      case when v_booking then 'booking' else v_parsed ->> 'rule_type' end::public.fi_budget_rule_type,
      v_parsed ->> 'text', (v_parsed ->> 'main_account')::int, (v_parsed ->> 'sub_account')::smallint,
      (v_parsed ->> 'range_from')::int, (v_parsed ->> 'range_to')::int, (v_parsed ->> 'range_full')::boolean,
      v_cc, v_item, coalesce(nullif(p_rule ->> 'status', ''), 'ok')::public.fi_budget_rule_status,
      nullif(btrim(coalesce(p_rule ->> 'note', '')), ''), nullif(btrim(coalesce(p_rule ->> 'account_label', '')), ''),
      (p_rule ->> 'b_date')::date, nullif(btrim(coalesce(p_rule ->> 'b_receipt', '')), ''),
      (p_rule ->> 'b_amount')::numeric, nullif(upper(coalesce(p_rule ->> 'b_side', '')), ''),
      nullif(btrim(coalesce(p_rule ->> 'b_text', '')), ''), nullif(btrim(coalesce(p_rule ->> 'reason', '')), ''),
      nullif(btrim(coalesce(p_comment, '')), ''))
    returning id into v_id;
  exception when unique_violation then
    raise exception 'FI_BUDGET_RULE_DUPLICATE' using errcode = 'P0001', detail = v_parsed ->> 'text';
  end;
  return v_id;
end;
$$;

create function public.fi_budget_rule_save(p_rule jsonb, p_comment text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_year smallint := (p_rule ->> 'year')::smallint;
  v_old uuid := nullif(p_rule ->> 'id', '')::uuid;
  v_id uuid;
begin
  perform public.fi_budget_require_maintain();
  if not exists (select 1 from public.fi_budget_plans where year = v_year) then
    raise exception 'FI_BUDGET_NO_PLAN' using errcode = 'P0001';
  end if;
  if v_old is not null then
    update public.fi_budget_rules set valid_to = now()
     where id = v_old and year = v_year and valid_to is null;
    if not found then
      raise exception 'FI_BUDGET_RULE_UNKNOWN' using errcode = 'P0001';
    end if;
  end if;
  v_id := public.fi_budget_rule_insert(v_year, p_rule, p_comment);
  perform public.fi_budget_write_log(v_year, 'rule_save', v_id,
    jsonb_build_object('replaces', v_old, 'account', p_rule ->> 'account_text', 'item', p_rule ->> 'item_id'));
  return v_id;
end;
$$;

create function public.fi_budget_rule_end(p_rule uuid, p_comment text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_year smallint;
begin
  perform public.fi_budget_require_maintain();
  update public.fi_budget_rules set valid_to = now(), comment = coalesce(nullif(btrim(coalesce(p_comment, '')), ''), comment)
   where id = p_rule and valid_to is null
  returning year into v_year;
  if v_year is null then
    raise exception 'FI_BUDGET_RULE_UNKNOWN' using errcode = 'P0001';
  end if;
  perform public.fi_budget_write_log(v_year, 'rule_end', p_rule, '{}');
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Übernahme der zuordnung.csv des Prototyps (US-FI-25, B8; wie lese_zuordnung in build.py).
-- p_rows = [{line, konto, kontobezeichnung, art, gesamtbudget, budgetposten, kostenstelle, status, hinweis,
--            datum, beleg, betrag, buchungstext}]. Fehler -> {ok:false, errors}, nichts wird geschrieben.
create function public.fi_budget_rules_import_csv(p_year smallint, p_rows jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_row record;
  v_kind text;
  v_status text;
  v_errors jsonb := '[]';
  v_hints jsonb := '[]';
  v_rules jsonb := '[]';
  v_assign jsonb := '{}';
  v_item record;
  v_items uuid[];
  v_cands text[];
  v_free text[];
  v_choice text;
  v_above text;
  v_key text;
  v_target uuid;
  v_part text;
  v_parsed jsonb;
  v_sig text;
  v_sigs jsonb := '{}';
  v_date date;
  v_m text[];
  v_amount numeric;
  v_side text;
  v_other_years int := 0;
  v_count int := 0;
  v_rule jsonb;
  v_group uuid;
begin
  perform public.fi_budget_require_maintain();
  if not exists (select 1 from public.fi_budget_plans where year = p_year) then
    raise exception 'FI_BUDGET_NO_PLAN' using errcode = 'P0001';
  end if;

  create temp table if not exists pg_temp.fi_budget_csv (
    line int, konto text, label text, kind text, gesamt text, bp text, kost text[], status text, hinweis text,
    datum text, beleg text, betrag text, btext text) on commit drop;
  truncate pg_temp.fi_budget_csv;

  -- Pass 1: Art, Status, Budgetposten prüfen
  for v_row in
    select (e ->> 'line')::int as line, btrim(coalesce(e ->> 'konto', '')) as konto,
           btrim(coalesce(e ->> 'kontobezeichnung', '')) as label, lower(btrim(coalesce(e ->> 'art', ''))) as art,
           btrim(coalesce(e ->> 'gesamtbudget', '')) as gesamt, btrim(coalesce(e ->> 'budgetposten', '')) as bp,
           btrim(coalesce(e ->> 'kostenstelle', '')) as kost, lower(btrim(coalesce(e ->> 'status', ''))) as status,
           btrim(coalesce(e ->> 'hinweis', '')) as hinweis, btrim(coalesce(e ->> 'datum', '')) as datum,
           btrim(coalesce(e ->> 'beleg', '')) as beleg, btrim(coalesce(e ->> 'betrag', '')) as betrag,
           btrim(coalesce(e ->> 'buchungstext', '')) as btext
      from jsonb_array_elements(coalesce(p_rows, '[]')) e
  loop
    if v_row.konto = '' and v_row.bp = '' and v_row.gesamt = '' and v_row.hinweis = '' then
      continue;
    end if;
    v_kind := case when v_row.art in ('ausgabe', 'ausgaben', 'aufwand') then 'expense'
                   when v_row.art in ('einnahme', 'einnahmen', 'ertrag', 'erträge') then 'income' end;
    v_status := case when v_row.status in ('', 'ok') then 'ok' when v_row.status = 'unsicher' then 'uncertain'
                     when v_row.status = 'offen' then 'open'
                     when v_row.status in ('keine buchung', 'keine buchungen') then 'no_booking' end;
    if v_status is null then
      v_hints := v_hints || jsonb_build_object('line', v_row.line, 'type', 'status_unknown', 'value', v_row.status);
      v_status := 'ok';
    end if;
    if v_row.bp <> '' and v_kind is null then
      v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'art_invalid', 'value', v_row.art);
      continue;
    end if;
    if v_row.bp <> '' and not exists (select 1 from public.fi_budget_items i
                                       where i.year = p_year and i.kind = v_kind::public.fi_budget_kind
                                         and i.removed_at is null and lower(i.name) = lower(v_row.bp)) then
      v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'item_unknown', 'value', v_row.bp,
        'kind', v_kind);
      continue;
    end if;
    insert into pg_temp.fi_budget_csv values (v_row.line, v_row.konto, v_row.label, v_kind, v_row.gesamt, v_row.bp,
      coalesce((select array_agg(distinct btrim(x) order by btrim(x)) from regexp_split_to_table(v_row.kost, '[,/]') x
                 where btrim(x) <> ''), '{}'),
      v_status, v_row.hinweis, v_row.datum, v_row.beleg, v_row.betrag, v_row.btext);
  end loop;

  -- Gesamtbudget je Budgetposten (wie build.py): eindeutiger Name -> erstes genanntes Gesamtbudget;
  -- doppelter Name -> Gesamtbudget des Postens darüber, sonst das nächste freie
  for v_item in
    select i.kind::text as kind, lower(i.name) as lname, array_agg(i.id order by i.sort_order) as ids
      from public.fi_budget_items i where i.year = p_year and i.removed_at is null
     group by i.kind, lower(i.name)
     order by min(i.sort_order)
  loop
    select coalesce(array_agg(gesamt order by first_line), '{}') into v_cands
      from (select c.gesamt, min(c.line) as first_line from pg_temp.fi_budget_csv c
             where c.kind = v_item.kind and lower(c.bp) = v_item.lname and c.gesamt <> ''
             group by c.gesamt) x;
    if cardinality(v_item.ids) = 1 then
      if cardinality(v_cands) > 1 then
        v_hints := v_hints || jsonb_build_object('type', 'several_groups', 'name', v_item.lname, 'groups', to_jsonb(v_cands));
      end if;
      if cardinality(v_cands) >= 1 then
        v_assign := v_assign || jsonb_build_object(v_item.ids[1]::text, v_cands[1]);
      end if;
    end if;
  end loop;
  for v_item in
    select i.kind::text as kind, lower(i.name) as lname, array_agg(i.id order by i.sort_order) as ids
      from public.fi_budget_items i where i.year = p_year and i.removed_at is null
     group by i.kind, lower(i.name) having count(*) > 1
     order by min(i.sort_order)
  loop
    select coalesce(array_agg(gesamt order by first_line), '{}') into v_free
      from (select c.gesamt, min(c.line) as first_line from pg_temp.fi_budget_csv c
             where c.kind = v_item.kind and lower(c.bp) = v_item.lname and c.gesamt <> ''
             group by c.gesamt) x;
    foreach v_target in array v_item.ids loop
      select coalesce(v_assign ->> a.id::text, g.name) into v_above
        from public.fi_budget_items t
        join public.fi_budget_items a on a.year = t.year and a.kind = t.kind and a.removed_at is null
         and a.sort_order < t.sort_order
        join public.fi_budget_groups g on g.id = a.group_id
       where t.id = v_target
       order by a.sort_order desc limit 1;
      if v_above is not null and v_above = any (v_free) then
        v_choice := v_above;
      elsif cardinality(v_free) > 0 then
        v_choice := v_free[1];
      else
        v_choice := null;
        v_hints := v_hints || jsonb_build_object('type', 'duplicate_without_row', 'name', v_item.lname);
      end if;
      if v_choice is not null then
        v_free := array_remove(v_free, v_choice);
        v_assign := v_assign || jsonb_build_object(v_target::text, v_choice);
      end if;
    end loop;
  end loop;

  -- Pass 2: Regeln bilden
  for v_row in select * from pg_temp.fi_budget_csv where konto <> '' order by line loop
    v_target := null;
    if v_row.bp <> '' then
      select i.id into v_target
        from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
       where i.year = p_year and i.kind = v_row.kind::public.fi_budget_kind and i.removed_at is null
         and lower(i.name) = lower(v_row.bp)
       order by (coalesce(v_assign ->> i.id::text, g.name) = v_row.gesamt) desc, i.sort_order
       limit 1;
    end if;
    if v_row.datum <> '' or v_row.beleg <> '' or v_row.betrag <> '' or v_row.btext <> '' then
      -- Einzelbuchung
      v_date := null; v_amount := null; v_side := null;
      if v_row.datum <> '' then
        v_m := regexp_match(v_row.datum, '^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
        begin
          if v_m is null then
            raise exception 'date';
          end if;
          v_date := make_date(v_m[3]::int, v_m[2]::int, v_m[1]::int);
        exception when others then
          v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'date_invalid', 'value', v_row.datum);
          continue;
        end;
        if extract(year from v_date) <> p_year then
          v_other_years := v_other_years + 1;
          continue;
        end if;
      end if;
      if v_row.betrag <> '' then
        v_m := regexp_match(v_row.betrag, '^(-?[\d.]+(?:,\d{1,2})?)\s*([SsHh])?$');
        if v_m is null then
          v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'amount_invalid', 'value', v_row.betrag);
          continue;
        end if;
        v_amount := replace(replace(v_m[1], '.', ''), ',', '.')::numeric;
        v_side := upper(v_m[2]);
      end if;
      v_rule := jsonb_build_object('account_text', v_row.konto, 'item_id', v_target, 'status', v_row.status,
        'note', v_row.hinweis, 'account_label', v_row.label, 'cost_centers', to_jsonb(v_row.kost), 'b_date', v_date,
        'b_receipt', nullif(v_row.beleg, ''), 'b_amount', v_amount, 'b_side', v_side,
        'b_text', nullif(v_row.btext, ''), 'reason', 'Übernahme aus dem Prototyp', 'line', v_row.line);
      begin
        v_parsed := public.fi_budget_rule_parse(v_row.konto);
        if v_parsed ->> 'rule_type' <> 'account' then
          raise exception 'FI_BUDGET_ACCOUNT_INVALID' using errcode = 'P0001';
        end if;
      exception when raise_exception then
        v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'booking_needs_account', 'value', v_row.konto);
        continue;
      end;
      v_sig := concat_ws('|', 'b', v_parsed ->> 'text', v_date, lower(v_row.beleg), v_amount, v_side, lower(v_row.btext),
        array_to_string(v_row.kost, ','));
      if v_sigs ? v_sig then
        v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'duplicate', 'value', v_row.konto,
          'first_line', v_sigs ->> v_sig);
        continue;
      end if;
      v_sigs := v_sigs || jsonb_build_object(v_sig, v_row.line);
      v_rules := v_rules || v_rule;
    else
      foreach v_part in array regexp_split_to_array(v_row.konto, '\s*,\s*') loop
        continue when btrim(v_part) = '';
        begin
          v_parsed := public.fi_budget_rule_parse(v_part);
        exception when raise_exception then
          v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'account_invalid', 'value', v_part);
          continue;
        end;
        v_sig := concat_ws('|', v_parsed ->> 'rule_type', v_parsed ->> 'text', array_to_string(v_row.kost, ','));
        if v_sigs ? v_sig then
          v_errors := v_errors || jsonb_build_object('line', v_row.line, 'type', 'duplicate', 'value', v_part,
            'first_line', v_sigs ->> v_sig);
          continue;
        end if;
        v_sigs := v_sigs || jsonb_build_object(v_sig, v_row.line);
        v_rules := v_rules || jsonb_build_object('account_text', v_part, 'item_id', v_target, 'status', v_row.status,
          'note', v_row.hinweis, 'account_label', v_row.label, 'cost_centers', to_jsonb(v_row.kost), 'line', v_row.line);
      end loop;
    end if;
  end loop;

  if jsonb_array_length(v_errors) > 0 then
    return jsonb_build_object('ok', false, 'errors', v_errors, 'hints', v_hints);
  end if;

  -- Anwenden: Gesamtbudgets, Regeln ersetzen, „keine Buchung“, Hinweise ohne Konto
  for v_key in select jsonb_object_keys(v_assign) loop
    v_group := public.fi_budget_group_get(p_year, v_assign ->> v_key, 0);
    update public.fi_budget_items set group_id = v_group where id = v_key::uuid;
  end loop;
  update public.fi_budget_groups g
     set sort_order = coalesce((select min(i.sort_order) from public.fi_budget_items i where i.group_id = g.id), 0)
   where g.year = p_year;
  delete from public.fi_budget_groups g
   where g.year = p_year and not exists (select 1 from public.fi_budget_items i where i.group_id = g.id);

  update public.fi_budget_rules set valid_to = now() where year = p_year and valid_to is null;
  for v_rule in select * from jsonb_array_elements(v_rules) loop
    perform public.fi_budget_rule_insert(p_year, v_rule, 'Übernahme zuordnung.csv');
    v_count := v_count + 1;
  end loop;

  update public.fi_budget_items i set no_booking = exists (
      select 1 from pg_temp.fi_budget_csv c
       where c.kind = i.kind::text and lower(c.bp) = lower(i.name) and c.status = 'no_booking')
   where i.year = p_year and i.removed_at is null;

  for v_row in select * from pg_temp.fi_budget_csv where konto = '' and bp <> '' and hinweis <> '' order by line loop
    select i.id into v_target from public.fi_budget_items i
     where i.year = p_year and i.kind = v_row.kind::public.fi_budget_kind and i.removed_at is null
       and lower(i.name) = lower(v_row.bp) limit 1;
    update public.fi_budget_notes set valid_to = now() where item_id = v_target and valid_to is null;
    insert into public.fi_budget_notes (item_id, text, created_by_person_id)
    values (v_target, left(v_row.hinweis, 500), public.fi_my_person_id());
  end loop;

  if not exists (select 1 from public.fi_budget_rules where year = p_year and valid_to is null and rule_type = 'range') then
    v_hints := v_hints || jsonb_build_object('type', 'no_range');
  end if;
  select v_hints || coalesce(jsonb_agg(jsonb_build_object('type', 'item_without_account', 'name', i.name, 'kind', i.kind)), '[]')
    into v_hints
    from public.fi_budget_items i
   where i.year = p_year and i.removed_at is null and not i.no_booking
     and not exists (select 1 from public.fi_budget_rules r where r.item_id = i.id and r.valid_to is null);
  if v_other_years > 0 then
    v_hints := v_hints || jsonb_build_object('type', 'other_years', 'count', v_other_years);
  end if;

  perform public.fi_budget_write_log(p_year, 'rules_csv_import', null,
    jsonb_build_object('rules', v_count, 'other_years', v_other_years));
  return jsonb_build_object('ok', true, 'rules', v_count, 'hints', v_hints);
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Neues Jahr: Gesamtbudgets, Sichtbarkeit und Regeln des Vorjahres vorschlagen bzw. übernehmen (US-FI-29)
create function public.fi_budget_year_from_previous(p_year smallint, p_apply boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_rule record;
  v_target uuid;
  v_copied int := 0;
  v_unmapped jsonb := '[]';
  v_groups int := 0;
  v_result jsonb;
begin
  perform public.fi_budget_require_maintain();
  if not exists (select 1 from public.fi_budget_plans where year = p_year) then
    raise exception 'FI_BUDGET_NO_PLAN' using errcode = 'P0001';
  end if;
  begin
    update public.fi_budget_groups g
       set visibility = p.visibility, referat_id = p.referat_id
      from public.fi_budget_groups p
     where g.year = p_year and p.year = p_year - 1 and lower(p.name) = lower(g.name)
       and (g.visibility, g.referat_id) is distinct from (p.visibility, p.referat_id);
    get diagnostics v_groups = row_count;

    for v_rule in
      select r.*, i.kind as item_kind, i.name as item_name, g.name as group_name
        from public.fi_budget_rules r
        left join public.fi_budget_items i on i.id = r.item_id
        left join public.fi_budget_groups g on g.id = i.group_id
       where r.year = p_year - 1 and r.valid_to is null and r.rule_type <> 'booking'
       order by r.valid_from
    loop
      v_target := null;
      if v_rule.item_id is not null then
        select i.id into v_target
          from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
         where i.year = p_year and i.removed_at is null and i.kind = v_rule.item_kind
           and lower(i.name) = lower(v_rule.item_name)
         order by (lower(g.name) = lower(v_rule.group_name)) desc, i.sort_order limit 1;
        if v_target is null then
          v_unmapped := v_unmapped || jsonb_build_object('account', v_rule.account_text, 'item', v_rule.item_name);
          continue;
        end if;
      end if;
      begin
        perform public.fi_budget_rule_insert(p_year, jsonb_build_object('account_text', v_rule.account_text,
          'item_id', v_target, 'status', v_rule.status, 'note', v_rule.note, 'account_label', v_rule.account_label,
          'cost_centers', to_jsonb(v_rule.cost_centers)), 'Übernahme aus ' || (p_year - 1));
        v_copied := v_copied + 1;
      exception when raise_exception then
        if sqlerrm <> 'FI_BUDGET_RULE_DUPLICATE' then
          raise;
        end if;
      end;
    end loop;

    v_result := jsonb_build_object('groups', v_groups, 'rules', v_copied, 'unmapped', v_unmapped);
    if not p_apply then
      raise exception 'FI_BUDGET_PREVIEW_ROLLBACK' using errcode = 'P0001';
    end if;
    perform public.fi_budget_write_log(p_year, 'year_from_previous', null, v_result - 'unmapped');
  exception when raise_exception then
    if sqlerrm <> 'FI_BUDGET_PREVIEW_ROLLBACK' then
      raise;
    end if;
  end;
  return v_result;
end;
$$;

revoke all on function public.fi_budget_require_maintain(), public.fi_budget_write_log(smallint, text, uuid, jsonb),
  public.fi_budget_default_visibility(smallint, text), public.fi_budget_group_get(smallint, text, int),
  public.fi_budget_plan_apply(smallint, jsonb, boolean), public.fi_budget_rule_insert(smallint, jsonb, text)
  from public, anon, authenticated;

revoke all on function public.fi_budget_plan_preview(smallint, jsonb), public.fi_budget_plan_import(smallint, jsonb),
  public.fi_budget_group_set(uuid, public.fi_budget_visibility, uuid), public.fi_budget_item_move(uuid, text),
  public.fi_budget_rule_save(jsonb, text), public.fi_budget_rule_end(uuid, text),
  public.fi_budget_rules_import_csv(smallint, jsonb), public.fi_budget_year_from_previous(smallint, boolean)
  from public, anon;
grant execute on function public.fi_budget_plan_preview(smallint, jsonb), public.fi_budget_plan_import(smallint, jsonb),
  public.fi_budget_group_set(uuid, public.fi_budget_visibility, uuid), public.fi_budget_item_move(uuid, text),
  public.fi_budget_rule_save(jsonb, text), public.fi_budget_rule_end(uuid, text),
  public.fi_budget_rules_import_csv(smallint, jsonb), public.fi_budget_year_from_previous(smallint, boolean)
  to authenticated;
