-- Planungshilfe Touren und Kurse, spec T14 mit EZ T037/T038 (tasks.md T016): Einsatz bei „in Yolawo angelegt“ mit
-- Inhalt R15 (Abrechnungsart R26a), Aktualisieren vor und nach der ersten Anwesenheit, Absage (R27), Rollback bei
-- Fehlern, Rechte der EZ-Funktionen.
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
create function pg_temp.complete(p_type text, p_start date, p_end date, p_lead text) returns uuid language sql as $$
  select (public.tk_save_plan(jsonb_build_object(
    'plan_type', p_type, 'title', 'Einsatz-Test ' || p_type, 'sport', 'Wandern', 'region', 'x', 'teaser', 'x',
    'image_source', 'referat', 'start_date', p_start, 'end_date', p_end, 'meet_time', '08:00', 'end_time', '17:00',
    'meeting_point', 'x', 'public_transport', 'possible', 'fitness', 'medium', 'technique', 'easy', 'requirements', 'x',
    'equipment', 'x', 'min_participants', 4, 'max_participants', 8, 'registration_deadline', p_start - 30,
    'community_reason', 'Test', 'confirm_license', true, 'confirm_calculation', true, 'confirm_ul_declaration', true,
    'confirm_emergency_card', true),
    jsonb_build_array(jsonb_build_object('person_id', p_lead, 'role', 'lead'),
                      jsonb_build_object('person_id', 'a0000000-0000-4000-8000-000000000017', 'role', 'helper')),
    jsonb_build_array(jsonb_build_object('person_id', p_lead, 'email', 'leitung.test@example.test',
                      'emergency_name', 'Notfall Test', 'emergency_phone', '0151 0000001')),
    '[{"mode": "rail_regional", "km_one_way": 100, "persons": 10}]', '[]') ->> 'id')::uuid
$$;
create function pg_temp.to_approved(p_id uuid) returns void language plpgsql as $$
begin
  perform public.tk_change_status(p_id, 'submit');
  perform public.tk_change_status(p_id, 'approve');
end $$;
create function pg_temp.ev(p_plan uuid) returns public.ez_events language sql as $$
  select * from public.ez_events where tk_plan_id = p_plan
$$;

-- Führungstour, mehrtägig
select pg_temp.as_user(13);
select set_config('test.p', pg_temp.complete('guided_tour', date '2027-07-12', date '2027-07-14',
                                              'a0000000-0000-4000-8000-000000000016')::text, true);
select pg_temp.to_approved(current_setting('test.p')::uuid);
select is((select count(*)::int from public.ez_events where tk_plan_id = current_setting('test.p')::uuid), 0,
  'vor „in Yolawo angelegt“ kein Einsatz');
select lives_ok($$ select public.tk_change_status(current_setting('test.p')::uuid, 'publish', null, 'YLW-1') $$,
  'in Yolawo angelegt');
select pg_temp.as_owner();
select results_eq(
  $$ select e.kind::text, e.span::text, e.title, e.start_date, e.end_date, e.start_time, e.end_time, e.organizer_person_id,
            k.code, e.referat_id = (select id from public.ea_referate where name = 'Touren')
       from public.ez_events e left join public.ad_remuneration_kinds k on k.id = e.remuneration_kind_id
      where e.tk_plan_id = current_setting('test.p')::uuid $$,
  $$ values ('tour'::text, 'multi'::text, 'Einsatz-Test guided_tour'::text, date '2027-07-12', date '2027-07-14',
             time '08:00', time '17:00', 'a0000000-0000-4000-8000-000000000016'::uuid, 'MULTIDAY'::text, true) $$,
  'Einsatz: Tour, mehrtägig, Zeiten, organisierende Person = erste Leitung, Vorbelegung „Mehrtageskurse, Führungstouren“');
select results_eq(
  $$ select a.person_id, a.role::text, a.status::text, a.from_plan from public.ez_attendances a
      where a.event_id = (pg_temp.ev(current_setting('test.p')::uuid)).id order by a.role $$,
  $$ values ('a0000000-0000-4000-8000-000000000016'::uuid, 'trainer'::text, 'registered'::text, true),
            ('a0000000-0000-4000-8000-000000000017', 'helper', 'registered', true) $$,
  'Leitende mit Trainer:in bzw. Helfer:in, Stand eingetragen, aus der Planung');
select is((select ez_event_id from public.tk_plans where id = current_setting('test.p')::uuid),
  (pg_temp.ev(current_setting('test.p')::uuid)).id, 'Planung verweist auf den Einsatz');

-- Änderung vor der ersten Anwesenheit wird übertragen
select pg_temp.as_user(13);
select is(public.tk_save_plan(jsonb_build_object('id', current_setting('test.p'), 'title', 'Neuer Titel (Test)'),
                              null, null, null, null) ->> 'warning', null, 'Speichern ohne Warnung');
select pg_temp.as_owner();
select is((pg_temp.ev(current_setting('test.p')::uuid)).title, 'Neuer Titel (Test)', 'Titel im Einsatz aktualisiert');
select pg_temp.as_user(13);
select results_eq($$ select (public.ez_planned_event_state(current_setting('test.p')::uuid) ->> 'is_done')::boolean $$,
  $$ values (false) $$, 'Stand: noch nicht durchgeführt');

-- erste Anwesenheit → Einsatz gesperrt, Planung bleibt gespeichert (R26)
select pg_temp.as_owner();
update public.ez_attendances set status = 'present'
 where event_id = (pg_temp.ev(current_setting('test.p')::uuid)).id and role = 'trainer';
select pg_temp.as_user(13);
select is(public.tk_save_plan(jsonb_build_object('id', current_setting('test.p'), 'title', 'Noch ein Titel (Test)'),
                              null, null, null, null) ->> 'warning', 'TK_EZ_LOCKED', 'Warnung TK_EZ_LOCKED');
select is((select title from public.tk_plans where id = current_setting('test.p')::uuid), 'Noch ein Titel (Test)',
  'Planung gespeichert');
select pg_temp.as_owner();
select is((pg_temp.ev(current_setting('test.p')::uuid)).title, 'Neuer Titel (Test)', 'Einsatz unverändert');
select is((select count(*)::int from public.tk_plan_history where plan_id = current_setting('test.p')::uuid and event = 'ez_locked'), 1,
  'Verlauf ez_locked');
select pg_temp.as_user(13);
select results_eq($$ select (public.ez_planned_event_state(current_setting('test.p')::uuid) ->> 'is_done')::boolean $$,
  $$ values (true) $$, 'Stand: durchgeführt (Leitung anwesend)');
select throws_like($$ select public.tk_change_status(current_setting('test.p')::uuid, 'cancel', 'Wetter') $$, 'TK_EZ_LOCKED',
  'Absage mit anwesenden Personen nicht möglich');
select is((select status::text from public.tk_plans where id = current_setting('test.p')::uuid), 'published', 'Status bleibt');

-- Gemeinschaftstour: Abrechnungsart „Gemeinschaftstour“; Wechsel zur Führungstour → Vorbelegung (R15)
select set_config('test.c', pg_temp.complete('community_tour', date '2027-09-10', date '2027-09-12',
                                              'a0000000-0000-4000-8000-000000000016')::text, true);
select pg_temp.to_approved(current_setting('test.c')::uuid);
select lives_ok($$ select public.tk_change_status(current_setting('test.c')::uuid, 'publish') $$, 'Gemeinschaftstour angelegt');
select pg_temp.as_owner();
select is((select k.code from public.ad_remuneration_kinds k where k.id = (pg_temp.ev(current_setting('test.c')::uuid)).remuneration_kind_id),
  'COMMUNITY_TOUR', 'Abrechnungsart Gemeinschaftstour');
select pg_temp.as_user(13);
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.c'), 'plan_type', 'guided_tour'),
                     null, null, null, null) $$, 'Tourtyp auf Führungstour geändert');
select pg_temp.as_owner();
select is((select k.code from public.ad_remuneration_kinds k where k.id = (pg_temp.ev(current_setting('test.c')::uuid)).remuneration_kind_id),
  'MULTIDAY', 'Abrechnungsart wieder nach Vorbelegung');

-- Absage ohne Anwesenheit markiert den Einsatz (R27)
select pg_temp.as_user(13);
select lives_ok($$ select public.tk_change_status(current_setting('test.c')::uuid, 'cancel', 'Zu wenige Anmeldungen') $$,
  'Absage');
select pg_temp.as_owner();
select results_eq($$ select cancelled_at is not null, cancel_reason from public.ez_events
                     where tk_plan_id = current_setting('test.c')::uuid $$,
  $$ values (true, 'Zu wenige Anmeldungen'::text) $$, 'Einsatz abgesagt mit Grund');

-- eintägiger Kurs: Einsatzart Kurs, eintägig mit Dauer-Kategorie (ab 8 Stunden)
select pg_temp.as_user(14);
select set_config('test.k', pg_temp.complete('course', date '2027-10-15', date '2027-10-15',
                                              'a0000000-0000-4000-8000-000000000016')::text, true);
select lives_ok($$ select public.tk_change_status(current_setting('test.k')::uuid, 'submit') $$, 'Kurs eingereicht');
-- Alex hat kein Freigaberecht; Freigabe hier direkt (Freigabe selbst prüft 830)
select pg_temp.as_owner();
select set_config('tk.status_change', 'on', true);
update public.tk_plans set status = 'approved' where id = current_setting('test.k')::uuid;
select set_config('tk.status_change', '', true);
select pg_temp.as_user(2);
select lives_ok($$ select public.tk_change_status(current_setting('test.k')::uuid, 'publish') $$,
  'Geschäftsstelle: in Yolawo angelegt');
select pg_temp.as_owner();
select results_eq(
  $$ select e.kind::text, e.span::text, e.day_category::text, e.end_date, e.start_time, k.code
       from public.ez_events e left join public.ad_remuneration_kinds k on k.id = e.remuneration_kind_id
      where e.tk_plan_id = current_setting('test.k')::uuid $$,
  $$ values ('course'::text, 'single'::text, 'at_least_8h'::text, null::date, null::time, 'COURSE'::text) $$,
  'Kurs eintägig: ab 8 Stunden, Abrechnungsart Kurse');

-- Fehler der Anwesenheitserfassung → nichts geändert (US-TK-16 AK4)
select pg_temp.as_user(13);
select set_config('test.f', pg_temp.complete('guided_tour', date '2027-08-01', date '2027-08-02',
                                              'a0000000-0000-4000-8000-000000000016')::text, true);
select pg_temp.to_approved(current_setting('test.f')::uuid);
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'left' where id = 'a0000000-0000-4000-8000-000000000016';
select pg_temp.as_user(13);
select throws_like($$ select public.tk_change_status(current_setting('test.f')::uuid, 'publish') $$, 'TK_EZ_FAILED',
  'organisierende Person nicht mehr aktiv → TK_EZ_FAILED');
select is((select status::text from public.tk_plans where id = current_setting('test.f')::uuid), 'approved',
  'Status bleibt freigegeben');
select is((select count(*)::int from public.ez_events where tk_plan_id = current_setting('test.f')::uuid), 0, 'kein Einsatz');
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'active' where id = 'a0000000-0000-4000-8000-000000000016';

-- Rechte der EZ-Funktionen
select pg_temp.as_user(3);
select throws_ok($$ select public.ez_upsert_planned_event(gen_random_uuid(), 'tour', (select id from public.ea_referate where name = 'Touren'),
                      'X', 'single', current_date, null, null, null, 'under_8h', 'a0000000-0000-4000-8000-000000000016', '[]') $$,
  'P0001', 'EZ_FORBIDDEN', 'Vorstand: kein Einsatz aus der Planungshilfe');
select pg_temp.as_user(14);
select throws_ok($$ select public.ez_planned_event_state(current_setting('test.p')::uuid) $$, 'P0001', 'EZ_NOT_FOUND',
  'Alex: Stand einer Tour nicht lesbar');
select pg_temp.as_user(13);
select throws_ok($$ select public.ez_cancel_event((pg_temp.ev(current_setting('test.p')::uuid)).id, 'x') $$, 'P0001', 'EZ_TK_MANAGED',
  'Absage in der Anwesenheitserfassung nur über die Planungshilfe (R25)');

select * from finish();
rollback;
