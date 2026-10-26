-- Planungshilfe Touren und Kurse, spec.md TK Abschnitt 8 (Mengengerüst, plan.md P13): 60 Planungen je Jahr mit je
-- 10 Leitenden, 10 Teilstrecken und 40 Kostenzeilen. Lokal: tk_save_plan < 1 s, Liste und Auswertung < 1 s;
-- in CI großzügigere Grenze (geteilte Maschinen).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- zehn fiktive Aktive im Referat Touren
insert into public.ea_persons (id, first_name, last_name, kind, created_in, volunteer_status, volunteer_status_since)
select ('c9000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'Menge' || n, 'Test', 'human', 'AD',
       'active', date '2020-01-01'
  from generate_series(1, 10) n;

select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000013',
                  'role', 'authenticated')::text, true);
select set_config('test.leaders', (select jsonb_agg(jsonb_build_object(
         'person_id', 'c9000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'),
         'role', case when n = 1 then 'lead' else 'helper' end)) from generate_series(1, 10) n)::text, true);
select set_config('test.legs', (select jsonb_agg(jsonb_build_object('mode', 'rail_regional', 'km_one_way', 50 + n,
         'persons', 10)) from generate_series(1, 10) n)::text, true);
select set_config('test.costs', (select jsonb_agg(jsonb_build_object(
         'cost_group', (array['leader', 'fixed', 'per_participant', 'self_paid'])[1 + n % 4],
         'label', 'Position ' || n, 'quantity', 1 + n % 3, 'unit_price', 10 + n)) from generate_series(1, 40) n)::text, true);

create function pg_temp.save_one(p_n int) returns interval language plpgsql as $$
declare
  v_start timestamptz := clock_timestamp();
begin
  perform public.tk_save_plan(
    jsonb_build_object('plan_type', 'guided_tour', 'title', 'Menge ' || p_n, 'start_date', make_date(2027, 1 + p_n % 12, 10),
                       'end_date', make_date(2027, 1 + p_n % 12, 13), 'min_participants', 6, 'max_participants', 12),
    current_setting('test.leaders')::jsonb, null, current_setting('test.legs')::jsonb,
    current_setting('test.costs')::jsonb);
  return clock_timestamp() - v_start;
end $$;

select set_config('test.max', (select max(pg_temp.save_one(n))::text from generate_series(1, 60) n), true);
select is((select count(*)::int from public.tk_plans where title like 'Menge %'), 60, '60 Planungen gespeichert');
select is((select count(*)::int from public.tk_plan_costs c join public.tk_plans p on p.id = c.plan_id
            where p.title like 'Menge %'), 2400, '2.400 Kostenzeilen');
select ok(current_setting('test.max')::interval < interval '3 seconds',
  'tk_save_plan je Planung unter 3 s (Ziel lokal < 1 s): ' || current_setting('test.max'));

set local role authenticated;
select set_config('test.t0', clock_timestamp()::text, true);
select is((select count(*)::int from public.tk_list_plans(2027, p_limit => 200)), 60, 'Liste eines Jahres');
select is((select count(*)::int from public.tk_cost_report(2027)), 60, 'Auswertung eines Jahres');
select ok(clock_timestamp() - current_setting('test.t0')::timestamptz < interval '3 seconds',
  'Liste und Auswertung unter 3 s (Ziel lokal < 1 s)');

select * from finish();
rollback;
