-- Planungshilfe Touren und Kurse, spec T10, T23 (tasks.md T010, T012): Löschung der Kontaktdaten nach 30 Tagen (R16)
-- und externe Leitende aus der Planung anlegen bzw. wieder aktiv eintragen (R23).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', ('b0000000-0000-4000-8000-0000000000' || lpad(p_user::text, 2, '0')), 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.new_plan(p_title text, p_end date, p_status public.tk_plan_status) returns uuid language plpgsql as $$
declare
  v_id uuid;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000013',
                     'role', 'authenticated')::text, true);
  v_id := (public.tk_save_plan(jsonb_build_object('plan_type', 'guided_tour', 'title', p_title,
             'start_date', p_end - 1, 'end_date', p_end),
           '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]',
           '[{"person_id": "a0000000-0000-4000-8000-000000000016", "email": "bernd.test@example.test",
              "emergency_name": "Notfall Test", "emergency_phone": "0151 0000001"}]', '[]', '[]') ->> 'id')::uuid;
  perform set_config('request.jwt.claims', '', true);
  perform set_config('tk.status_change', 'on', true);
  update public.tk_plans set status = p_status,
         cancelled_at = case when p_status = 'cancelled' then (p_end + 1)::timestamptz end,
         cancel_reason = case when p_status = 'cancelled' then 'Test' end
   where id = v_id;
  perform set_config('tk.status_change', '', true);
  return v_id;
end $$;

-- R16: 30 Tage nach Tourende bzw. Absage
select set_config('test.old', pg_temp.new_plan('Alt (Test)', current_date - 31, 'done')::text, true);
select set_config('test.recent', pg_temp.new_plan('Neu (Test)', current_date - 20, 'published')::text, true);
select set_config('test.cancel', pg_temp.new_plan('Abgesagt (Test)', current_date - 40, 'cancelled')::text, true);
select set_config('test.draft', pg_temp.new_plan('Entwurf (Test)', current_date - 40, 'draft')::text, true);
select is(public.tk_purge_contacts(), 2, 'zwei Planungen fällig (durchgeführt vor 31 Tagen, abgesagt vor 39 Tagen)');
select is((select count(*)::int from public.tk_plan_contacts where plan_id = current_setting('test.old')::uuid), 0,
  'Kontaktdaten gelöscht');
select ok((select contacts_purged_at is not null from public.tk_plans where id = current_setting('test.old')::uuid),
  'gelöscht am gesetzt');
select is((select count(*)::int from public.tk_plan_history
            where plan_id = current_setting('test.old')::uuid and event = 'contacts_purged'), 1, 'Verlaufseintrag ohne Inhalte');
select is((select count(*)::int from public.tk_plan_contacts where plan_id = current_setting('test.recent')::uuid), 1,
  'vor 20 Tagen beendet: bleibt');
select is((select count(*)::int from public.tk_plan_contacts where plan_id = current_setting('test.draft')::uuid), 1,
  'Entwurf: bleibt');
select is(public.tk_purge_contacts(), 0, 'zweiter Lauf: nichts mehr fällig');
select ok(not has_function_privilege('authenticated', 'public.tk_purge_contacts()', 'EXECUTE'), 'Löschjob nur Scheduler');
create function pg_temp.cron_ok() returns boolean language plpgsql as $$
declare
  v boolean;
begin
  if to_regclass('cron.job') is null then
    return true;
  end if;
  execute $q$select exists (select 1 from cron.job where jobname = 'tk_purge_contacts' and schedule = '15 3 * * *')$q$ into v;
  return v;
end $$;
select ok(pg_temp.cron_ok(), 'pg_cron-Job täglich 03:15 Uhr');

-- R23: externe Leitende anlegen
select set_config('test.p', pg_temp.new_plan('Planung (Test)', current_date + 200, 'draft')::text, true);
select pg_temp.as_user(15);
select throws_ok($$ select public.tk_create_leader(current_setting('test.p')::uuid, 'Erika', 'Extern') $$,
  'P0001', 'TK_PRIVACY_NOT_CONFIRMED', 'ohne Häkchen wird nichts angelegt');
select is((select count(*)::int from public.ea_search_active_persons('Extern')), 0, 'keine Person angelegt');
select lives_ok($$ select set_config('test.erika', public.tk_create_leader(current_setting('test.p')::uuid, 'Erika', 'Extern',
                     null, 'erika.extern@example.test', true, '2026-10')::text, true) $$, 'Fritz legt Erika Extern an');
select pg_temp.as_owner();
select results_eq(
  $$ select p.created_in, p.volunteer_status::text from public.ea_persons p where p.id = current_setting('test.erika')::uuid $$,
  $$ values ('TK'::text, 'active'::text) $$, 'aktiv, angelegt aus der Planungshilfe');
select ok(exists (select 1 from public.ea_properties f
                   where f.person_id = current_setting('test.erika')::uuid and f.field_values ->> 'function' = 'Helfer:in'
                     and f.related_referat_id = (select id from public.ea_referate where name = 'Touren')),
  'Funktion Helfer:in im Referat der Planung');
select results_eq(
  $$ select plan_id, notice_version from public.tk_privacy_confirmations where person_id = current_setting('test.erika')::uuid $$,
  $$ values (current_setting('test.p')::uuid, '2026-10'::text) $$, 'Bestätigung des Hinweises gespeichert');
select pg_temp.as_user(15);
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.p')),
                     jsonb_build_array(jsonb_build_object('person_id', current_setting('test.erika'), 'role', 'co_lead')),
                     null, null, null) $$, 'Erika als Co-Leitung eingetragen');
select is((select rate_kind::text from public.tk_plan_leaders
            where plan_id = current_setting('test.p')::uuid and person_id = current_setting('test.erika')::uuid),
  'helper', 'ohne Lizenz: Helfersatz');
select pg_temp.as_user(14);
select throws_ok($$ select public.tk_create_leader(current_setting('test.p')::uuid, 'X', 'Y', null, null, true, 'v1') $$,
  'P0001', 'TK_NOT_FOUND', 'Alex: Planung des Referats Touren nicht sichtbar');
select pg_temp.as_user(2);
select is((select count(*)::int from public.tk_privacy_confirmations), 1, 'Geschäftsstelle liest die Bestätigungen');
select pg_temp.as_user(13);
select is_empty($$ select 1 from public.tk_privacy_confirmations $$, 'Tina liest keine Bestätigungen');

-- R23: wieder aktiv eintragen
select pg_temp.as_user(13);
select throws_ok($$ select public.tk_reactivate_leader(current_setting('test.p')::uuid, 'a0000000-0000-4000-8000-000000000016') $$,
  'P0001', 'TK_PERSON_NOT_INACTIVE', 'aktive Person: nichts zu tun');
select lives_ok($$ select public.tk_reactivate_leader(current_setting('test.p')::uuid, 'a0000000-0000-4000-8000-000000000011') $$,
  'Tina trägt Olga Ausgeschieden wieder aktiv ein');
select pg_temp.as_owner();
select is((select volunteer_status::text from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000011'), 'active',
  'Olga wieder aktiv');

select * from finish();
rollback;
