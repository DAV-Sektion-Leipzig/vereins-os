-- Befund S-02 (Sicherheits-Review): ez_upsert_planned_event und ez_cancel_planned_event nur intern, Fremdschlüssel
-- ez_events.tk_plan_id → tk_plans, Einsatz nur zu einer vorhandenen Planung im selben Referat mit Status „freigegeben“
-- oder „in Yolawo angelegt“. Der Weg über die Planungshilfe (tk_change_status publish) legt den Einsatz weiter an.
-- Testzugänge aus seed.sql: b…02 Geschäftsstelle, b…13 Referent:in Touren.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', ('b0000000-0000-4000-8000-0000000000' || lpad(p_user::text, 2, '0')), 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
-- interner Aufruf (wie aus einer TK-Funktion mit security definer): Eigentümerrolle, Nutzerkontext bleibt gesetzt
create function pg_temp.as_owner_for(p_user int) returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object(
    'sub', ('b0000000-0000-4000-8000-0000000000' || lpad(p_user::text, 2, '0')), 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.complete(p_type text, p_start date, p_end date) returns uuid language sql as $$
  select (public.tk_save_plan(jsonb_build_object(
    'plan_type', p_type, 'title', 'Härtung ' || p_type, 'sport', 'Wandern', 'region', 'x', 'teaser', 'x',
    'image_source', 'referat', 'start_date', p_start, 'end_date', p_end, 'meet_time', '08:00', 'end_time', '17:00',
    'meeting_point', 'x', 'public_transport', 'possible', 'fitness', 'medium', 'technique', 'easy', 'requirements', 'x',
    'equipment', 'x', 'min_participants', 4, 'max_participants', 8, 'registration_deadline', p_start - 30,
    'community_reason', 'Test', 'confirm_license', true, 'confirm_calculation', true, 'confirm_ul_declaration', true,
    'confirm_emergency_card', true),
    jsonb_build_array(jsonb_build_object('person_id', 'a0000000-0000-4000-8000-000000000016', 'role', 'lead')),
    jsonb_build_array(jsonb_build_object('person_id', 'a0000000-0000-4000-8000-000000000016',
                      'email', 'leitung.test@example.test', 'emergency_name', 'Notfall Test',
                      'emergency_phone', '0151 0000001')),
    '[{"mode": "rail_regional", "km_one_way": 100, "persons": 10}]', '[]') ->> 'id')::uuid
$$;
create function pg_temp.to_approved(p_id uuid) returns void language plpgsql as $$
begin
  perform public.tk_change_status(p_id, 'submit');
  perform public.tk_change_status(p_id, 'approve');
end $$;
create function pg_temp.up(p_plan uuid, p_referat uuid) returns uuid language sql as $$
  select public.ez_upsert_planned_event(p_plan, 'tour', p_referat, 'Härtung direkt', 'single', date '2027-06-01',
    null, null, null, 'under_8h', 'a0000000-0000-4000-8000-000000000016', '[]')
$$;
create function pg_temp.touren() returns uuid language sql as $$
  select id from public.ea_referate where name = 'Touren'
$$;

-- 1. Rechte: nur intern
select ok(not has_function_privilege('authenticated',
  'public.ez_upsert_planned_event(uuid, public.ez_event_kind, uuid, text, public.ez_span, date, time, date, time, public.ez_day_category, uuid, jsonb, text)',
  'execute'), 'authenticated: kein execute auf ez_upsert_planned_event');
select ok(not has_function_privilege('anon',
  'public.ez_upsert_planned_event(uuid, public.ez_event_kind, uuid, text, public.ez_span, date, time, date, time, public.ez_day_category, uuid, jsonb, text)',
  'execute'), 'anon: kein execute auf ez_upsert_planned_event');
select ok(not has_function_privilege('authenticated', 'public.ez_cancel_planned_event(uuid, text)', 'execute'),
  'authenticated: kein execute auf ez_cancel_planned_event');
select ok(not has_function_privilege('anon', 'public.ez_cancel_planned_event(uuid, text)', 'execute'),
  'anon: kein execute auf ez_cancel_planned_event');
select ok(has_function_privilege('authenticated', 'public.ez_planned_event_state(uuid)', 'execute'),
  'authenticated: ez_planned_event_state bleibt aufrufbar');

-- 2. Fremdschlüssel
select fk_ok('public', 'ez_events', 'tk_plan_id', 'public', 'tk_plans', 'id', 'Fremdschlüssel ez_events.tk_plan_id → tk_plans.id');
select results_eq(
  $$ select c.confdeltype::text, c.convalidated from pg_constraint c
      where c.conrelid = 'public.ez_events'::regclass and c.conname = 'ez_events_tk_plan_id_fkey' $$,
  $$ values ('r'::text, true) $$, 'on delete restrict, validiert (lokal ohne verwaiste Werte)');

-- Planungen: freigegeben und Entwurf (Referent:in Touren)
select pg_temp.as_user(13);
select set_config('test.a', pg_temp.complete('guided_tour', date '2027-06-01', date '2027-06-02')::text, true);
select pg_temp.to_approved(current_setting('test.a')::uuid);
select set_config('test.d', pg_temp.complete('guided_tour', date '2027-06-05', date '2027-06-06')::text, true);

-- 3. Direkter Aufruf per RPC verweigert
select throws_ok($$ select pg_temp.up(current_setting('test.a')::uuid, pg_temp.touren()) $$, '42501', null,
  'Referent:in: ez_upsert_planned_event nicht direkt aufrufbar');
select throws_ok($$ select public.ez_cancel_planned_event(current_setting('test.a')::uuid, 'x') $$, '42501', null,
  'Referent:in: ez_cancel_planned_event nicht direkt aufrufbar');
select lives_ok($$ select public.ez_planned_event_state(current_setting('test.a')::uuid) $$,
  'Referent:in: Stand der Planung weiter lesbar');

-- 4. Prüfungen in ez_upsert_planned_event (interner Aufruf)
select pg_temp.as_owner_for(13);
select throws_ok($$ select pg_temp.up(gen_random_uuid(), pg_temp.touren()) $$, 'P0001', 'EZ_FORBIDDEN',
  'Planung nicht vorhanden → EZ_FORBIDDEN');
select throws_ok($$ select pg_temp.up(current_setting('test.d')::uuid, pg_temp.touren()) $$, 'P0001', 'EZ_FORBIDDEN',
  'Planung im Entwurf (nicht freigegeben) → EZ_FORBIDDEN');
select pg_temp.as_owner_for(2);
select ok(public.tk_can_write((select id from public.ea_referate where name <> 'Touren' order by name limit 1)),
  'Geschäftsstelle darf im anderen Referat bearbeiten (Voraussetzung)');
select throws_ok($$ select pg_temp.up(current_setting('test.a')::uuid,
                                      (select id from public.ea_referate where name <> 'Touren' order by name limit 1)) $$,
  'P0001', 'EZ_FORBIDDEN', 'Referat weicht von der Planung ab → EZ_FORBIDDEN');
select pg_temp.as_owner();
select is((select count(*)::int from public.ez_events where tk_plan_id in (current_setting('test.a')::uuid,
                                                                             current_setting('test.d')::uuid)), 0,
  'kein Einsatz entstanden');

-- 5. Weg über die Planungshilfe legt den Einsatz weiter an
select pg_temp.as_user(13);
select lives_ok($$ select public.tk_change_status(current_setting('test.a')::uuid, 'publish') $$, 'in Yolawo angelegt');
select pg_temp.as_owner();
select is((select count(*)::int from public.ez_events where tk_plan_id = current_setting('test.a')::uuid), 1,
  'Einsatz zur Planung angelegt');
select pg_temp.as_user(13);
select is(public.tk_save_plan(jsonb_build_object('id', current_setting('test.a'), 'title', 'Härtung neu'),
                              null, null, null, null) ->> 'warning', null, 'Aktualisierung über tk_save_plan ohne Warnung');
select pg_temp.as_owner();
select is((select title from public.ez_events where tk_plan_id = current_setting('test.a')::uuid), 'Härtung neu',
  'Einsatz aktualisiert');

-- 6. Fremdschlüssel wirkt für neue Zeilen
select pg_temp.as_owner_for(13);
select throws_ok($$ insert into public.ez_events (kind, span, referat_id, title, organizer_person_id, start_date,
                                                  day_category, client_request_id, tk_plan_id)
                    values ('tour', 'single', pg_temp.touren(), 'Verwaist', 'a0000000-0000-4000-8000-000000000016',
                            date '2027-06-01', 'under_8h', gen_random_uuid(), gen_random_uuid()) $$,
  '23503', null, 'Einsatz mit unbekannter Planung abgelehnt');
select pg_temp.as_owner();
select throws_ok($$ delete from public.tk_plans where id = current_setting('test.a')::uuid $$, '23503', null,
  'Planung mit Einsatz nicht löschbar (on delete restrict)');

select * from finish();
rollback;
