-- Planungshilfe Touren und Kurse, spec T18 (tasks.md T014): Sichtbarkeitsmatrix spec.md TK Abschnitt 9, R19 je Status,
-- Kontaktdaten-RLS, Löschen, Namen über tk_person_visible. Testzugänge aus seed.sql: b…01 Admin, b…02 Geschäftsstelle,
-- b…03 Vorstand, b…09 Rita Referentin (Klettern), b…13 Tina Touren (+ Freigabe), b…14 Alex Ausbildung,
-- b…15 Fritz Freigabe (nur Freigabe Touren).
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
create function pg_temp.plan(p_n int) returns uuid language sql as $$
  select current_setting('test.p' || p_n)::uuid
$$;
-- sichtbare Planungen als Nummern 1–8
create function pg_temp.visible() returns int[] language sql as $$
  select coalesce(array_agg(n order by n), '{}') from generate_series(1, 8) n
   where exists (select 1 from public.tk_plans p where p.id = pg_temp.plan(n))
$$;
create function pg_temp.editable() returns int[] language plpgsql as $$
declare
  v int[] := '{}';
  n int;
begin
  for n in 1..8 loop
    begin
      perform public.tk_save_plan(jsonb_build_object('id', pg_temp.plan(n)), null, null, null, null);
      v := v || n;
    exception when sqlstate 'P0001' then
      null;
    end;
  end loop;
  return v;
end $$;
create function pg_temp.set_status(p_n int, p_status public.tk_plan_status) returns void language plpgsql as $$
begin
  perform set_config('tk.status_change', 'on', true);
  update public.tk_plans set status = p_status,
         cancelled_at = case when p_status = 'cancelled' then now() end,
         cancel_reason = case when p_status = 'cancelled' then 'Test' end
   where id = pg_temp.plan(p_n);
  perform set_config('tk.status_change', '', true);
end $$;

-- Planungen 1–8 (spec.md 9): 1 eingereicht, 2 Kurs Entwurf, 3 freigegeben, 4 Entwurf, 5 in Yolawo angelegt,
-- 6 abgesagt, 7 Entwurf, 8 abgeschlossen
select pg_temp.as_user(13);
select set_config('test.p' || n, (public.tk_save_plan(jsonb_build_object('plan_type', 'guided_tour', 'title', 'Planung ' || n),
         '[{"person_id": "a0000000-0000-4000-8000-000000000017", "role": "lead"}]',
         '[{"person_id": "a0000000-0000-4000-8000-000000000017", "email": "hilde.test@example.test",
            "emergency_name": "Notfall Test", "emergency_phone": "0151 0000001"}]', '[]', '[]') ->> 'id'), true)
  from unnest(array[1, 3, 4, 5, 6, 7, 8]) n;
select pg_temp.as_user(14);
select set_config('test.p2', (public.tk_save_plan('{"plan_type": "course", "title": "Planung 2"}',
         '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]', null, '[]', '[]') ->> 'id'), true);
select pg_temp.as_owner();
select pg_temp.set_status(1, 'submitted');
select pg_temp.set_status(3, 'approved');
select pg_temp.set_status(5, 'published');
select pg_temp.set_status(6, 'cancelled');
select pg_temp.set_status(8, 'closed');

-- Admin (TK lesen): sieht alle, bearbeitet nichts, keine Kontaktdaten (A3)
select pg_temp.as_user(1);
select is(pg_temp.visible(), array[1, 2, 3, 4, 5, 6, 7, 8], 'Admin sieht 1–8');
select is(pg_temp.editable(), '{}'::int[], 'Admin bearbeitet nichts');
select is_empty($$ select 1 from public.tk_plan_contacts $$, 'Admin: Kontaktdaten per RLS leer');
select ok(not (public.tk_get_plan(pg_temp.plan(1)) ? 'contacts'), 'Admin: tk_get_plan ohne Kontaktdaten');
select throws_ok($$ select public.tk_change_status(pg_temp.plan(4), 'submit') $$, 'P0001', 'TK_FORBIDDEN',
  'Admin: Einreichen verboten (US-TK-13 AK4)');

-- Geschäftsstelle (TK verwalten): alle; bearbeitet Entwurf/eingereicht und nach R19 auch freigegeben/in Yolawo;
-- gibt nicht frei (A2); Kontaktdaten ja
select pg_temp.as_user(2);
select is(pg_temp.visible(), array[1, 2, 3, 4, 5, 6, 7, 8], 'Geschäftsstelle sieht 1–8');
select is(pg_temp.editable(), array[1, 2, 3, 4, 5, 7], 'Geschäftsstelle bearbeitet 1, 2, 4, 7 und 3, 5 (R19)');
select ok(public.tk_get_plan(pg_temp.plan(1)) ? 'contacts', 'Geschäftsstelle: Kontaktdaten');
select throws_ok($$ select public.tk_change_status(pg_temp.plan(1), 'approve') $$, 'P0001', 'TK_FORBIDDEN',
  'Geschäftsstelle gibt nicht frei (A2)');

-- Tina (Referent:in Touren + Freigabe)
select pg_temp.as_user(13);
select is(pg_temp.visible(), array[1, 3, 4, 5, 6, 7, 8], 'Tina sieht 1, 3–8 (nicht den Kurs)');
select is(pg_temp.editable(), array[1, 3, 4, 5, 7], 'Tina bearbeitet 1, 4, 7 und mit Freigaberecht 3, 5');
select ok((public.tk_get_plan(pg_temp.plan(1)) ->> 'can_approve')::boolean, 'Tina darf 1 freigeben');
select is((select count(*)::int from public.tk_plan_contacts), 7, 'Tina: Kontaktdaten Touren');

-- Alex (Referent:in Ausbildung, ohne Freigabe)
select pg_temp.as_user(14);
select is(pg_temp.visible(), array[2], 'Alex sieht nur den Kurs');
select is(pg_temp.editable(), array[2], 'Alex bearbeitet den Kurs');
select ok(not (public.tk_get_plan(pg_temp.plan(2)) ->> 'can_approve')::boolean, 'Alex gibt nicht frei');

-- Fritz (nur Freigabe Touren)
select pg_temp.as_user(15);
select is(pg_temp.visible(), array[1, 3, 4, 5, 6, 7, 8], 'Fritz sieht 1, 3–8');
select is(pg_temp.editable(), array[1, 3, 4, 5, 7], 'Fritz bearbeitet 1, 4, 7, 3, 5');
select ok(public.tk_get_plan(pg_temp.plan(1)) ? 'contacts', 'Fritz: Kontaktdaten Touren');
select is((select count(*)::int from public.ea_person_names(array['a0000000-0000-4000-8000-000000000017'::uuid])), 1,
  'Fritz: Name der Leitung über tk_person_visible');

-- Rita (Referent:in Klettern): keine Planung ihres Referats
select pg_temp.as_user(9);
select is(pg_temp.visible(), '{}'::int[], 'Rita sieht keine Planung');

-- Vorstand: nichts
select pg_temp.as_user(3);
select is(pg_temp.visible(), '{}'::int[], 'Vorstand sieht nichts');
select throws_ok($$ select * from public.tk_list_plans() $$, 'P0001', 'TK_FORBIDDEN', 'Vorstand: keine Liste');
select throws_ok($$ select public.tk_get_plan(pg_temp.plan(1)) $$, 'P0001', 'TK_NOT_FOUND', 'Vorstand: Planung nicht gefunden');

-- R19 Meldungen
select pg_temp.as_owner();
select pg_temp.set_status(2, 'approved');
select pg_temp.as_user(14);
select throws_like($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.plan(2)), null, null, null, null) $$,
  'TK_LOCKED', 'Alex nach der Freigabe: TK_LOCKED');
select pg_temp.as_user(2);
select throws_like($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.plan(8)), null, null, null, null) $$,
  'TK_LOCKED', 'abgeschlossen: niemand ändert');

-- Liste: Standard ohne abgesagt und abgeschlossen; Name der ersten Leitung
select pg_temp.as_user(13);
select is((select count(*)::int from public.tk_list_plans()), 5, 'Tina: Liste ohne abgesagt/abgeschlossen (1, 3, 4, 5, 7)');
select is((select count(*)::int from public.tk_list_plans(p_status => array['cancelled', 'closed']::public.tk_plan_status[])), 2,
  'Filter Status');
select is((select lead_name from public.tk_list_plans() limit 1), 'Hilde Helfer', 'erste Leitung mit Namen');

-- Löschen: nur Geschäftsstelle, nur Entwurf oder abgesagt ohne Einsatz
select throws_ok($$ select public.tk_delete_plan(pg_temp.plan(4)) $$, 'P0001', 'TK_DELETE_FORBIDDEN', 'Tina löscht nicht');
select pg_temp.as_user(2);
select throws_ok($$ select public.tk_delete_plan(pg_temp.plan(1)) $$, 'P0001', 'TK_DELETE_FORBIDDEN',
  'eingereicht: nicht löschbar');
select lives_ok($$ select public.tk_delete_plan(pg_temp.plan(4)) $$, 'Geschäftsstelle löscht Entwurf');
select lives_ok($$ select public.tk_delete_plan(pg_temp.plan(6)) $$, 'Geschäftsstelle löscht abgesagte ohne Einsatz');
select is((select count(*)::int from public.tk_plans), 6, 'zwei Planungen gelöscht');

-- Kostenauswertung: keine Kontaktdaten, abgesagte nur auf Wunsch
select pg_temp.as_user(13);
select is((select count(*)::int from public.tk_cost_report(extract(year from current_date)::int)), 5,
  'Kostenauswertung Tina (laufendes Jahr, ohne abgesagte)');

select * from finish();
rollback;
