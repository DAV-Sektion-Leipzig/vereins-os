-- Bereich Budget (spec.md DS v0.2 Abschnitte 2.3, 2.4), Task T6 (DT06): Kontoangaben lesen wie build.py
-- (konto_teile, regel_aus_konto), Regel nach Vorrang (R2), Betrag nach Art (R3), View der zugeordneten Buchungen.

-- Vergleichsform für Texte (Beleg, Buchungstext): Leerraum zusammenfassen, Groß/klein egal
create function public.fi_budget_norm(p_text text)
returns text language sql immutable set search_path = '' as $$
  select lower(regexp_replace(btrim(coalesce(p_text, '')), '\s+', ' ', 'g'));
$$;

-- '6326 3' -> (6326, 3, true); '6326' -> (6326, null, false); '63263' -> (6326, 3, true); sonst null
create function public.fi_budget_konto_parts(p_text text, out main_account int, out sub_account smallint, out is_full boolean)
language plpgsql immutable set search_path = '' as $$
declare
  v_t text := regexp_replace(btrim(coalesce(p_text, '')), '\s+', ' ', 'g');
  v_m text[];
begin
  v_m := regexp_match(v_t, '^(\d{1,6})(?: (\d))?$');
  if v_m is null then
    return;
  end if;
  if v_m[2] is not null then
    main_account := v_m[1]::int; sub_account := v_m[2]::smallint; is_full := true;
  elsif length(v_m[1]) >= 5 then
    main_account := left(v_m[1], length(v_m[1]) - 1)::int; sub_account := right(v_m[1], 1)::smallint; is_full := true;
  else
    main_account := v_m[1]::int; sub_account := null; is_full := false;
  end if;
end;
$$;

-- Kontoangabe -> Regelform (Einzelkonto, Hauptkonto, Bereich); Fehler FI_BUDGET_ACCOUNT_INVALID, FI_BUDGET_RANGE_INVALID
create function public.fi_budget_rule_parse(p_text text)
returns jsonb language plpgsql immutable set search_path = '' as $$
declare
  v_t text := btrim(coalesce(p_text, ''));
  v_m text[];
  v_von record;
  v_bis record;
  v_k record;
  v_a int;
  v_b int;
begin
  if v_t = '' or position(',' in v_t) > 0 then
    raise exception 'FI_BUDGET_ACCOUNT_INVALID' using errcode = 'P0001', detail = v_t;
  end if;
  v_m := regexp_match(v_t, '^(.+?)\s*(?:-|–|bis)\s*(.+)$');
  if v_m is not null then
    select * into v_von from public.fi_budget_konto_parts(v_m[1]);
    select * into v_bis from public.fi_budget_konto_parts(v_m[2]);
    if v_von.main_account is null or v_bis.main_account is null or v_von.is_full <> v_bis.is_full then
      raise exception 'FI_BUDGET_RANGE_INVALID' using errcode = 'P0001', detail = v_t;
    end if;
    if v_von.is_full then
      v_a := v_von.main_account * 10 + v_von.sub_account; v_b := v_bis.main_account * 10 + v_bis.sub_account;
    else
      v_a := v_von.main_account; v_b := v_bis.main_account;
    end if;
    if v_a > v_b then
      raise exception 'FI_BUDGET_RANGE_INVALID' using errcode = 'P0001', detail = v_t;
    end if;
    return jsonb_build_object('rule_type', 'range', 'range_from', v_a, 'range_to', v_b, 'range_full', v_von.is_full,
      'text', btrim(v_m[1]) || '–' || btrim(v_m[2]));
  end if;
  select * into v_k from public.fi_budget_konto_parts(v_t);
  if v_k.main_account is null then
    raise exception 'FI_BUDGET_ACCOUNT_INVALID' using errcode = 'P0001', detail = v_t;
  end if;
  if v_k.is_full then
    return jsonb_build_object('rule_type', 'account', 'main_account', v_k.main_account, 'sub_account', v_k.sub_account,
      'text', v_k.main_account || ' ' || v_k.sub_account);
  end if;
  return jsonb_build_object('rule_type', 'main_account', 'main_account', v_k.main_account,
    'text', v_k.main_account::text);
end;
$$;

-- Gültige Regel für eine Buchung nach Vorrang R2: Einzelbuchung, Einzelkonto, Hauptkonto, engster Bereich;
-- mit Kostenstelle vor ohne
create function public.fi_budget_match_rule(
  p_year smallint, p_main int, p_sub smallint, p_cost_center text, p_date date, p_receipt text,
  p_debit numeric, p_credit numeric, p_text text)
returns uuid language sql stable set search_path = '' as $$
  select r.id
    from public.fi_budget_rules r
   where r.year = p_year
     and r.valid_to is null
     and (cardinality(r.cost_centers) = 0 or coalesce(p_cost_center, '') = any (r.cost_centers))
     and case r.rule_type
           when 'booking' then
             r.main_account = p_main and r.sub_account = p_sub
             and (r.b_date is null or r.b_date = p_date)
             and (r.b_receipt is null or public.fi_budget_norm(r.b_receipt) = public.fi_budget_norm(p_receipt))
             and (r.b_amount is null
                  or (r.b_side = 'S' and p_debit = r.b_amount)
                  or (r.b_side = 'H' and p_credit = r.b_amount)
                  or (r.b_side is null and (p_debit = r.b_amount or p_credit = r.b_amount)))
             and (r.b_text is null or public.fi_budget_norm(r.b_text) = public.fi_budget_norm(p_text))
           when 'account' then r.main_account = p_main and r.sub_account = p_sub
           when 'main_account' then r.main_account = p_main
           else case when r.range_full then p_main * 10 + p_sub between r.range_from and r.range_to
                     else p_main between r.range_from and r.range_to end
         end
   order by case r.rule_type when 'booking' then 0 when 'account' then 1 when 'main_account' then 2 else 3 end,
            cardinality(r.cost_centers) = 0,
            case when r.rule_type = 'range' then
              case when r.range_full then r.range_to - r.range_from else (r.range_to - r.range_from) * 10 + 9 end end
              nulls first,
            r.valid_from
   limit 1;
$$;

-- Zugeordnete Buchungen des aktuellen Imports je Jahr (intern; Grundlage aller Summen)
create view public.fi_budget_assigned as
select b.id, b.import_id, b.year, b.main_account, b.sub_account, b.booking_date, b.bu, b.contra_account,
       b.contra_label, b.booking_text, b.receipt, b.debit, b.credit, b.cost_center, b.line_no,
       r.id as rule_id, r.rule_type, r.item_id, i.kind, i.group_id,
       case when i.kind = 'income' then b.credit - b.debit else b.debit - b.credit end as amount
  from public.fi_budget_bookings b
  join public.fi_budget_imports im on im.id = b.import_id and im.is_current
  left join lateral (
    select x.id, x.rule_type, x.item_id from public.fi_budget_rules x
     where x.id = public.fi_budget_match_rule(b.year, b.main_account, b.sub_account, b.cost_center, b.booking_date,
                                              b.receipt, b.debit, b.credit, b.booking_text)) r on true
  left join public.fi_budget_items i on i.id = r.item_id;

-- Aktueller Plan = beschlossener Plan + bestätigte Umschichtungen hinein − hinaus
create function public.fi_budget_plan_current(p_item uuid)
returns numeric language sql stable set search_path = '' as $$
  select i.plan_decided
         + coalesce((select sum(a.amount) from public.fi_budget_reallocations a
                      where a.to_item = i.id and a.status = 'confirmed'), 0)
         - coalesce((select sum(a.amount) from public.fi_budget_reallocations a
                      where a.from_item = i.id and a.status = 'confirmed'), 0)
    from public.fi_budget_items i where i.id = p_item;
$$;

revoke all on function public.fi_budget_norm(text), public.fi_budget_konto_parts(text),
  public.fi_budget_match_rule(smallint, int, smallint, text, date, text, numeric, numeric, text),
  public.fi_budget_plan_current(uuid) from public, anon, authenticated;
revoke all on public.fi_budget_assigned from public, anon, authenticated;

revoke all on function public.fi_budget_rule_parse(text) from public, anon;
grant execute on function public.fi_budget_rule_parse(text) to authenticated;
