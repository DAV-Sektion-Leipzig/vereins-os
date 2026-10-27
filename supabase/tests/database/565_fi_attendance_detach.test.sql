-- Prüfbericht B-01 (spec.md EZ R34, spec.md FI R15, R23): Nach der Halbjahresberechnung lässt sich eine Person aus einem
-- Einsatz entfernen, solange ihre Abrechnung nicht abgeschlossen ist; die nächste Neuberechnung entfernt die Position.
-- Anwesenheiten in abgeschlossenen Abrechnungen bleiben gesperrt (EZ_SETTLED). Alle Namen fiktiv.
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.p(n int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
create function pg_temp.e(n int) returns uuid language sql as $$
  select ('f5650000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
create temp table ids (name text primary key, id uuid);
grant select on ids to authenticated;
create function pg_temp.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name $$;
create function pg_temp.sid(n int) returns uuid language sql as $$
  select s.id from public.fi_settlements s where s.person_id = pg_temp.p(n) and s.year = 2026 and s.half = 1 $$;
create function pg_temp.att(p_event int, p_person int) returns uuid language sql as $$
  select a.id from public.ez_attendances a where a.event_id = pg_temp.e(p_event) and a.person_id = pg_temp.p(p_person) $$;
-- Vollständige Kopfdaten eines Arbeitseinsatzes (ez_save_event übernimmt Titel und Datum nur aus dem Aufruf)
create function pg_temp.w(p_event int) returns jsonb language sql as $$
  select jsonb_build_object('id', pg_temp.e(p_event), 'kind', 'work_assignment', 'referat_id', pg_temp.id('KJ'),
                            'title', 'Hüttenputz Test ' || p_event, 'span', 'single',
                            'start_date', (date '2026-03-09' + p_event)::text, 'day_category', 'at_least_8h') $$;
create function pg_temp.helpers(variadic p_persons int[]) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('person_id', pg_temp.p(n), 'role', 'helper', 'status', 'present'))
    from unnest(p_persons) as n $$;

-- ---------------------------------------------------------------------------------------------------------------
-- Testdaten (als Eigentümer, „erfasst von“ Geschäftsstelle): zwei Arbeitseinsätze in Kinder und Jugend (halbjährliche
-- Abrechnung) mit Abrechnungsart Wettkampfbetreuung, je zwei Helfer:innen
select pg_temp.as_owner();
insert into ids select 'KJ', id from public.ea_referate where name = 'Kinder und Jugend';
insert into ids select 'COMPETITION', id from public.ad_remuneration_kinds where code = 'COMPETITION';

insert into public.ea_persons (id, first_name, last_name, kind, created_in, volunteer_status, volunteer_status_since)
values (pg_temp.p(565), 'Hanna', 'Abgeschlossen', 'human', 'EA', 'active', date '2024-01-01'),
       (pg_temp.p(566), 'Hugo', 'Entwurf', 'human', 'EA', 'active', date '2024-01-01');

insert into public.ez_events (id, kind, span, referat_id, title, start_date, day_category, client_request_id,
                              remuneration_kind_id)
select pg_temp.e(n), 'work_assignment', 'single', pg_temp.id('KJ'), 'Hüttenputz Test ' || n, date '2026-03-09' + n,
       'at_least_8h', gen_random_uuid(), pg_temp.id('COMPETITION')
  from (values (1), (2)) as v (n);

insert into public.ez_attendances (event_id, person_id, role, status)
select pg_temp.e(v.e), pg_temp.p(v.p), 'helper', 'present'
  from (values (1, 565), (1, 566), (2, 565), (2, 566)) as v (e, p);

-- ---------------------------------------------------------------------------------------------------------------
-- Struktur
select is((select c.confdeltype::text from pg_constraint c
            where c.conname = 'fi_settlement_items_attendance_id_fkey' and c.conrelid = 'public.fi_settlement_items'::regclass),
  'n', 'attendance_id: on delete set null (B-01)');
select is((select c.confdeltype::text from pg_constraint c
            where c.conname = 'fi_settlement_items_event_id_fkey' and c.conrelid = 'public.fi_settlement_items'::regclass),
  'r', 'event_id: weiter on delete restrict');

-- Erste Halbjahresberechnung; Hannas Abrechnung gilt als abgeschlossen, Hugos bleibt im Entwurf
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.fi_calculate_half(2026::smallint, 1::smallint) $$, 'Halbjahr berechnet');
select is((select count(*)::int from public.fi_settlement_items where settlement_id = pg_temp.sid(566)), 2,
  'Hugo: zwei Positionen (je Einsatz eine)');
select pg_temp.as_owner();
update public.fi_settlements set status = 'closed', closed_at = now() where id = pg_temp.sid(565);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(public.fi_attendance_locked(pg_temp.att(1, 565)), 'Hannas Anwesenheit ist abgerechnet');
select ok(not public.fi_attendance_locked(pg_temp.att(1, 566)), 'Hugos Anwesenheit ist nicht abgerechnet');

-- Person mit Position im Entwurf entfernen (bisher 23503)
select lives_ok($$ select public.ez_save_event(pg_temp.w(1), pg_temp.helpers(565), '[]') $$,
  'Hugo aus Einsatz 1 entfernt, obwohl seine Abrechnung im Entwurf eine Position dazu hat');
select ok(pg_temp.att(1, 566) is null, 'Anwesenheit entfernt');
select is((select attendance_id from public.fi_settlement_items
            where settlement_id = pg_temp.sid(566) and event_id = pg_temp.e(1)), null::uuid,
  'Position bleibt bis zur Neuberechnung, ohne Anwesenheit');

-- Abgerechnete Anwesenheit bleibt gesperrt (R34)
select throws_ok($$ select public.ez_save_event(pg_temp.w(1), '[]'::jsonb, '[]') $$, 'P0001', 'EZ_SETTLED',
  'Hanna (abgeschlossen) nicht entfernbar');
select throws_ok($$ select public.ez_delete_event(pg_temp.e(1)) $$, 'P0001', 'EZ_SETTLED',
  'Einsatz mit abgeschlossener Abrechnung nicht löschbar');
select isnt(pg_temp.att(1, 565), null::uuid, 'Hannas Anwesenheit unverändert');

-- Neuberechnung entfernt die Position
select is((public.fi_calculate_half(2026::smallint, 1::smallint) ->> 'recalculated')::int >= 1, true,
  'Neuberechnung ändert Hugos Abrechnung');
select is_empty($$ select 1 from public.fi_settlement_items where settlement_id = pg_temp.sid(566) and event_id = pg_temp.e(1) $$,
  'Position zu Einsatz 1 entfernt (R15)');
select is((select count(*)::int from public.fi_settlement_items where settlement_id = pg_temp.sid(566) and event_id = pg_temp.e(2)),
  1, 'Position zu Einsatz 2 bleibt');
select is((select count(*)::int from public.fi_settlement_items where settlement_id = pg_temp.sid(565)), 2,
  'abgeschlossene Abrechnung unverändert');

-- Auch die letzte Position entfällt: Abrechnung im Entwurf wird gelöscht (spec.md FI Abschnitt 6)
select lives_ok($$ select public.ez_save_event(pg_temp.w(2), pg_temp.helpers(565), '[]') $$,
  'Hugo aus Einsatz 2 entfernt');
select public.fi_calculate_half(2026::smallint, 1::smallint);
select pg_temp.as_owner();
select is_empty($$ select 1 from public.fi_settlements where person_id = pg_temp.p(566) and year = 2026 and half = 1 $$,
  'Hugos Abrechnung ohne Positionen gelöscht');

select * from finish();
rollback;
