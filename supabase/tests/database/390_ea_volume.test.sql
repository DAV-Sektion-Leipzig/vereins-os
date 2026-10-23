-- EA spec T9 Teil, Abschnitt 8: Mengentest – 1.000 Personen mit je 30 Eigenschaften (Funktion, Lizenz, 28 weitere).
-- Misst als Referent:in ea_volunteer_list mit allen Filtern (< 1 s), ea_v_expiry für ein Jahr (< 2 s) und ein
-- Personendetail (< 1 s). Muster wie 190_mengentest (research.md R-EA-12). Nur ein Anhaltspunkt aus CI.
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

-- Mengengerüst ohne Trigger einfügen (Validierung ist nicht Gegenstand dieses Tests)
alter table public.ea_persons disable trigger user;
alter table public.ea_properties disable trigger user;

insert into public.ea_persons (id, first_name, last_name, created_in, volunteer_status, volunteer_status_since)
select gen_random_uuid(), 'Vorname' || g, 'Nachname' || lpad(g::text, 4, '0'), 'script', 'active', date '2024-01-01'
  from generate_series(1, 1000) as g;

-- je Person: eine Funktion Trainer:in (jede vierte im Referat Klettern), eine Lizenz TCSPI mit Ablauf 2027, 28 weitere
insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
select p.id, (select id from public.ea_property_types where system_key = 'function'), '{"function": "Trainer:in"}',
       (select r.id from public.ea_referate r
         where r.name = case when right(p.last_name, 1) in ('0', '4', '8') then 'Klettern' else 'Touren' end),
       date '2024-01-01'
  from public.ea_persons p where p.created_in = 'script';

insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select p.id, (select id from public.ea_property_types where system_key = 'license'),
       jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCSPI'),
                          'valid_until', case when right(p.last_name, 1) in ('1', '5') then '2027-06-30' else '2029-12-31' end),
       date '2024-01-01'
  from public.ea_persons p where p.created_in = 'script';

insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select p.id, 'd0000000-0000-4000-8000-000000000003', jsonb_build_object('date', '2024-01-01'), date '2024-01-01' + n
  from public.ea_persons p cross join generate_series(1, 28) as n
 where p.created_in = 'script';

alter table public.ea_persons enable trigger user;
alter table public.ea_properties enable trigger user;
analyze public.ea_persons;
analyze public.ea_properties;

select is((select count(*)::int from public.ea_properties p join public.ea_persons pe on pe.id = p.person_id
            where pe.created_in = 'script'), 30000, '1.000 Personen mit je 30 Eigenschaften');

create temp table timing (what text, ms numeric);
grant all on timing to authenticated;

select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
do $$
declare t0 timestamptz; n int; v_person uuid; v_klettern uuid;
begin
  select id into v_klettern from public.ea_referate where name = 'Klettern';

  t0 := clock_timestamp();
  select count(*) into n from public.ea_volunteer_list(
    p_search => 'Nachname', p_status => '{active,dormant}', p_referate => array[v_klettern],
    p_function => 'Trainer:in', p_position => null, p_gremium => null,
    p_qualification_type => (select id from public.ad_qualification_types where code = 'TCSPI'),
    p_discipline => 'Klettersport', p_expiry => '{valid,expiring,expired,none}',
    p_trainer_without_license => false, p_without_assignment => false, p_limit => 50, p_offset => 0);
  insert into timing values ('Liste mit allen Filtern', extract(epoch from clock_timestamp() - t0) * 1000);

  t0 := clock_timestamp();
  select count(*) into n from public.ea_volunteer_list(p_limit => 50, p_offset => 100);
  insert into timing values ('Liste Seite 3', extract(epoch from clock_timestamp() - t0) * 1000);

  t0 := clock_timestamp();
  select count(*) into n from public.ea_v_expiry
   where kind in ('license', 'qualification') and valid_until between '2027-01-01' and '2027-12-31';
  insert into timing values ('Stichtagsliste 2027', extract(epoch from clock_timestamp() - t0) * 1000);

  select id into v_person from public.ea_persons where last_name = 'Nachname0004';
  t0 := clock_timestamp();
  select count(*) into n from public.ea_properties p left join public.ea_property_history h on h.property_id = p.id
   where p.person_id = v_person;
  select count(*) into n from public.ea_v_expiry where person_id = v_person;
  insert into timing values ('Personendetail', extract(epoch from clock_timestamp() - t0) * 1000);
end $$;

select pg_temp.as_owner();
select cmp_ok((select ms from timing where what = 'Liste mit allen Filtern'), '<', 1000::numeric,
  'Referent:in: ea_volunteer_list mit allen Filtern < 1 s');
select cmp_ok((select ms from timing where what = 'Liste Seite 3'), '<', 1000::numeric, 'Referent:in: Liste Seite 3 < 1 s');
select cmp_ok((select ms from timing where what = 'Stichtagsliste 2027'), '<', 2000::numeric, 'Referent:in: ea_v_expiry ein Jahr < 2 s');
select cmp_ok((select ms from timing where what = 'Personendetail'), '<', 1000::numeric, 'Referent:in: Personendetail < 1 s');
select diag(what || ': ' || round(ms) || ' ms') from timing;

select * from finish();
rollback;
