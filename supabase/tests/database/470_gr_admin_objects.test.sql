-- US-GR-01 (GR spec T1, T2, T10): Ergänzungen an Objekten der Administration – Eigenschaftsart group_function,
-- related_group_id (R38), Schreiben nur über Gruppen (R39, Ü7), Gruppenbezug in ad_v_person_overview (Ü3).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.gf() returns uuid language sql as $$
  select id from public.ea_property_types where system_key = 'group_function'
$$;

-- Eigenschaftsart „Funktion in Gruppe“ (GR spec.md 2.2)
select results_eq(
  $$ select name, category::text, read_level::text, relation_kind::text, relation_required, allow_multiple, visible_in,
            origin, valid_from_label, valid_to_label
       from public.ea_property_types where system_key = 'group_function' $$,
  $$ values ('Funktion in Gruppe'::text, 'assignment'::text, 'all'::text, 'group'::text, true, true, '{AD,EA,GR}'::text[],
             'system'::text, 'seit'::text, 'bis'::text) $$,
  'Art group_function');
select results_eq(
  $$ select key, data_type::text, is_required, choice_values, sort_order from public.ea_property_fields
      where property_type_id = pg_temp.gf() $$,
  $$ values ('function'::text, 'choice'::text, true, '{Gruppenleitung,Trainer:in,Helfer:in}'::text[], 1) $$,
  'Feld function');
select lives_ok($$ select public.gr_seed_group_function_type() $$, 'zweiter Lauf');
select is((select count(*)::int from public.ea_property_fields where property_type_id = pg_temp.gf()), 1, 'idempotent');

-- R38: Bezug Gruppe
select fk_ok('public', 'ea_properties', 'related_group_id', 'public', 'gr_groups', 'id');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                           values ('a0000000-0000-4000-8000-000000000024', %L, '{"function": "Helfer:in"}', current_date) $$,
                        pg_temp.gf()),
  'P0001', 'EA_RELATION_REQUIRED', 'Gruppe Pflicht (R38)');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_group_id, valid_from)
                           values ('a0000000-0000-4000-8000-000000000024', %L, '{"function": "Helfer:in"}',
                                   'c0000000-0000-4000-8000-000000000004', date '2025-07-01') $$, pg_temp.gf()),
  'P0001', 'GR_GROUP_DISSOLVED', 'aufgelöste Gruppe nicht neu wählbar');
select is((select related_group_id from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000002'), null::uuid,
  'Funktion mit Bezug Referat ohne Gruppe');
update public.ea_properties set related_group_id = 'c0000000-0000-4000-8000-000000000001'
 where id = 'e0000000-0000-4000-8000-000000000002';
select is((select related_group_id from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000002'), null::uuid,
  'related_group_id wird bei Bezug Referat geleert');

-- Historie mit related_group_id
update public.ea_properties set related_group_id = 'c0000000-0000-4000-8000-000000000002'
 where id = 'e0000000-0000-4000-8000-000000000039';
select is((select related_group_id from public.ea_property_history where property_id = 'e0000000-0000-4000-8000-000000000039'
            order by changed_at desc limit 1), 'c0000000-0000-4000-8000-000000000001'::uuid,
  'Historie schreibt related_group_id mit');

-- R39/Ü7: nie über RLS schreibbar
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(not public.ea_property_writable(pg_temp.gf(), 'a0000000-0000-4000-8000-000000000026', null),
  'Geschäftsstelle: group_function nicht über RLS schreibbar');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_group_id, valid_from)
                           values ('a0000000-0000-4000-8000-000000000024', %L, '{"function": "Helfer:in"}',
                                   'c0000000-0000-4000-8000-000000000001', current_date) $$, pg_temp.gf()),
  '42501', null, 'direkter Insert scheitert an der Policy');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select ok(not public.ea_property_writable(pg_temp.gf(), 'a0000000-0000-4000-8000-000000000026', null),
  'Admin: group_function nicht über RLS schreibbar');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_group_id, valid_from)
                           values ('a0000000-0000-4000-8000-000000000024', %L, '{"function": "Helfer:in"}',
                                   'c0000000-0000-4000-8000-000000000001', current_date) $$, pg_temp.gf()),
  '42501', null, 'Admin: kein Spaltenrecht auf related_group_id, Schreiben nur über Gruppen (R39)');
select ok(public.ea_property_writable((select id from public.ea_property_types where system_key = 'contact'),
                                      'a0000000-0000-4000-8000-000000000024', null),
  'andere Arten weiterhin nach den Regeln der Administration');

-- Ü3: Gruppenbezug für die Personenübersicht
select is((select array_agg(right(person_id::text, 2)::int order by person_id) from public.ad_v_person_overview
            where has_group_relation), array[23, 24, 25, 26, 28, 29, 30], 'Gruppenbezug nur bei laufendem Bezug (Ü3, Ü4)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.gr_person_has_group_relation('a0000000-0000-4000-8000-000000000023'), null::boolean,
  'Kennzeichen nur mit AD ≥ lesen');

-- interne Funktionen
select ok(not has_function_privilege('authenticated', 'public.gr_has_current_relation(uuid)', 'EXECUTE'),
  'gr_has_current_relation ohne Grant');
select ok(not has_function_privilege('authenticated', 'public.gr_is_adult(uuid, date)', 'EXECUTE'), 'gr_is_adult ohne Grant');
select ok(not has_function_privilege('authenticated', 'public.gr_create_person(jsonb, text, text)', 'EXECUTE'),
  'gr_create_person ohne Grant');

select * from finish();
rollback;
