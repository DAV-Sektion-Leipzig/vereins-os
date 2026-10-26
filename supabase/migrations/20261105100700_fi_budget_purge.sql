-- Bereich Budget (spec.md DS v0.2 Abschnitt 2.3), Task T12 (DT12): Löschlauf (R19).
-- Am oder nach dem 01.01. des Jahres J+2: Buchungen, Kontenübersichten, Einzelbuchungsregeln und Vorschläge des
-- Jahres J löschen. Finanzpläne (mit Gesamtbudgets, Posten, Regeln, Umschichtungen, Hinweisen) und Monatssummen
-- 5 Jahre nach Ende des Jahres (CLAUDE.md, Historie und Löschung).

create function public.fi_budget_purge()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_limit smallint := extract(year from current_date)::smallint - 2;
  v_old smallint := extract(year from current_date)::smallint - 6;
  v_bookings int;
  v_totals int;
  v_rules int;
  v_proposals int;
  v_months int;
  v_plans int;
  v_r jsonb;
begin
  begin
    delete from public.fi_budget_account_totals t using public.fi_budget_imports im
     where im.id = t.import_id and im.year <= v_limit;
    get diagnostics v_totals = row_count;
    delete from public.fi_budget_bookings where year <= v_limit;
    get diagnostics v_bookings = row_count;
    delete from public.fi_budget_proposals where year <= v_limit;
    get diagnostics v_proposals = row_count;
    delete from public.fi_budget_rules where year <= v_limit and rule_type = 'booking';
    get diagnostics v_rules = row_count;
    delete from public.fi_budget_month_totals where year <= v_old;
    get diagnostics v_months = row_count;
    -- Finanzplan mit allem, was daran hängt; Reihenfolge wegen „on delete restrict“
    delete from public.fi_budget_reallocations where year <= v_old;
    delete from public.fi_budget_proposals where year <= v_old;
    delete from public.fi_budget_rules where year <= v_old;
    delete from public.fi_budget_items where year <= v_old;
    delete from public.fi_budget_plans where year <= v_old;
    get diagnostics v_plans = row_count;
    delete from public.fi_budget_log where at < now() - interval '5 years';
    v_r := jsonb_build_object('bookings', v_bookings, 'account_totals', v_totals, 'booking_rules', v_rules,
      'proposals', v_proposals, 'month_totals', v_months, 'plans', v_plans);
    perform public.fi_budget_write_log(null, 'purge', null, v_r);
    return v_r;
  exception when others then
    insert into public.fi_budget_log (action, details, actor)
    values ('purge_failed', jsonb_build_object('error', sqlerrm), null);
    return jsonb_build_object('error', sqlerrm);
  end;
end;
$$;

revoke all on function public.fi_budget_purge() from public, anon, authenticated;

select cron.schedule('fi-budget-purge', '15 3 * * *', 'select public.fi_budget_purge()');
