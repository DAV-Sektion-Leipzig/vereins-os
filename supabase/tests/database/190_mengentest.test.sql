-- US-AD-23 (spec T45 Teil, Abschnitt 8): Mengentest – 1.000 Personen mit Ehrenamtsstatus und je 30 Eigenschaften;
-- Pfad EA mit Reichweite Referat < 1 s (research.md R-27). Nur ein Anhaltspunkt aus CI, kein Nachweis für TEST.
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

-- je Person: eine Funktion mit Bezug auf ein Referat (jede vierte im Referat Klettern), 29 weitere Eigenschaften
insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
select p.id, (select id from public.ea_property_types where system_key = 'function'), '{"function": "Helfer:in"}',
       (select r.id from public.ea_referate r
         where r.name = case when right(p.last_name, 1) in ('0', '4', '8') then 'Klettern' else 'Touren' end),
       date '2024-01-01'
  from public.ea_persons p where p.created_in = 'script';

insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select p.id, 'd0000000-0000-4000-8000-000000000003', jsonb_build_object('date', '2024-01-01'), date '2024-01-01' + n
  from public.ea_persons p cross join generate_series(1, 29) as n
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
declare t0 timestamptz; n int;
begin
  t0 := clock_timestamp();
  select count(*) into n from (
    select person_id from public.ad_v_person_overview order by last_name, first_name limit 50
  ) s;
  insert into timing values ('Übersicht Seite 1', extract(epoch from clock_timestamp() - t0) * 1000);

  t0 := clock_timestamp();
  select count(*) into n from public.ea_properties;
  insert into timing values ('Eigenschaften aller sichtbaren Personen', extract(epoch from clock_timestamp() - t0) * 1000);
end $$;

select pg_temp.as_owner();
select cmp_ok((select ms from timing where what = 'Übersicht Seite 1'), '<', 1000::numeric,
  'Referent:in: Seite der Personenübersicht < 1 s');
select cmp_ok((select ms from timing where what = 'Eigenschaften aller sichtbaren Personen'), '<', 1000::numeric,
  'Referent:in: Eigenschaften aller sichtbaren Personen < 1 s');
select diag(what || ': ' || round(ms) || ' ms') from timing;

select * from finish();
rollback;
