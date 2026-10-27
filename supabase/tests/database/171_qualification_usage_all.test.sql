-- US-AD-17 (spec AD v0.12.1): ad_qualification_usage_all – Verwendung je Qualifikationsart, nur aktuelle Eigenschaften.
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

-- Geschäftsstelle: Zahlen wie ad_qualification_usage, solange alle Einträge aktuell sind
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select persons from public.ad_qualification_usage_all()
            where qualification_type_id = (select id from public.ad_qualification_types where code = 'TCSPI')), 3,
  'TCSPI: 3 Personen (Toni, Max, Karl Kletter)');
select is((select persons from public.ad_qualification_usage_all()
            where qualification_type_id = (select id from public.ad_qualification_types where code = 'TCBO')), 1,
  'TCBO: 1 Person (Lena)');
select is((select count(*)::int from public.ad_qualification_usage_all() where persons <= 0), 0, 'keine Zeile ohne Personen');

-- Beendete Eigenschaft zählt nicht mehr (Karl Kletters Lizenz gestern beendet)
select pg_temp.as_owner();
update public.ea_properties set valid_to = current_date - 1 where id = 'e0000000-0000-4000-8000-000000000049';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select persons from public.ad_qualification_usage_all()
            where qualification_type_id = (select id from public.ad_qualification_types where code = 'TCSPI')), 2,
  'TCSPI nach Beenden: 2 Personen');
select is(public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCSPI')), 3,
  'ad_qualification_usage zählt weiter alle Einträge (3)');

-- Vorstand ohne Recht auf Qualifikationsarten
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select * from public.ad_qualification_usage_all() $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand: AD_FORBIDDEN');

select pg_temp.as_owner();
select * from finish();
rollback;
