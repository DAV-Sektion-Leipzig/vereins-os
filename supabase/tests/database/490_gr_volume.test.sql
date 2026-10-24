-- US-GR-01, US-GR-19 (GR spec T10, spec.md 8): Mengentest mit 20 Gruppen und 400 Teilnehmer:innen (mit Vertrag,
-- Erziehungsberechtigter und Notfallkontakt). Zeiten als Diagnose; Grenzen nach spec.md 8.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.ms(p_sql text) returns numeric language plpgsql as $$
declare
  v_start timestamptz := clock_timestamp();
begin
  execute p_sql;
  return round(extract(epoch from clock_timestamp() - v_start) * 1000, 1);
end $$;
grant execute on function pg_temp.ms(text) to authenticated;

-- Daten: 20 Gruppen, je 20 Kinder mit Geburtsdatum, Kontaktdaten, Elternteil und Notfallkontakt, Teilnahme und Vertrag
insert into public.gr_groups (id, name, referat_id)
select ('c9000000-0000-4000-8000-0000000000' || lpad(g::text, 2, '0'))::uuid, 'Mengengruppe ' || g,
       (select id from public.ea_referate where name = 'Kinder und Jugend')
  from generate_series(1, 20) g;
insert into public.gr_training_times (group_id, weekday, starts_at, ends_at, valid_from)
select id, (row_number() over (order by id) % 7 + 1)::smallint, '16:00', '17:30', date '2025-01-01'
  from public.gr_groups where name like 'Mengengruppe %';

create temp table kids as
select n, gen_random_uuid() as child, gen_random_uuid() as parent, gen_random_uuid() as contact,
       ('c9000000-0000-4000-8000-0000000000' || lpad(((n - 1) / 20 + 1)::text, 2, '0'))::uuid as group_id
  from generate_series(1, 400) n;

insert into public.ea_persons (id, first_name, last_name, created_in)
select child, 'Kind' || n, 'Menge', 'GR' from kids
union all select parent, 'Elter' || n, 'Menge', 'GR' from kids
union all select contact, 'Kontakt' || n, 'Menge', 'GR' from kids;

insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select k.child, t.id, jsonb_build_object('date', '2015-05-05'), date '2015-05-05'
  from kids k, public.ea_property_types t where t.system_key = 'birth_date'
union all
select k.parent, t.id, jsonb_build_object('street', 'Mengenweg ' || k.n, 'postal_code', '04109', 'city', 'Leipzig',
                                          'email', 'elter' || k.n || '@example.test'), date '2025-01-01'
  from kids k, public.ea_property_types t where t.system_key = 'contact'
union all
select k.contact, t.id, jsonb_build_object('phone_mobile', '0151 ' || k.n), date '2025-01-01'
  from kids k, public.ea_property_types t where t.system_key = 'contact';

insert into public.gr_guardians (child_person_id, guardian_person_id) select child, parent from kids;
insert into public.gr_emergency_contacts (child_person_id, contact_person_id, sort_order) select child, contact, 1 from kids;
insert into public.gr_memberships (id, group_id, person_id, joined_on)
select child, group_id, child, date '2025-01-01' from kids;
insert into public.gr_contracts (membership_id, holder_person_id, starts_on, account_holder, iban, mandate_reference,
                                 mandate_signed_on, purpose, monthly_amount)
select child, parent, date '2025-01-01', 'Elter Menge', 'DE89370400440532013000', 'MENGE-' || n, date '2024-12-01',
       'Beitrag', 20
  from kids;

-- Messungen als Geschäftsstelle
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(pg_temp.ms($$ select * from public.gr_group_overview() $$) < 1000, 'gr_group_overview < 1 s');
select diag('Übersicht: ' || pg_temp.ms($$ select * from public.gr_group_overview() $$) || ' ms');
select ok(pg_temp.ms($$ select * from public.gr_v_memberships where group_id = 'c9000000-0000-4000-8000-000000000001' $$) < 1000,
  'Gruppendetail (Teilnahmen) < 1 s');
select ok(pg_temp.ms($$ select public.gr_group_roster('c9000000-0000-4000-8000-000000000001', public.gr_today()) $$) < 300,
  'gr_group_roster < 300 ms');
select diag('Roster: ' || pg_temp.ms($$ select public.gr_group_roster('c9000000-0000-4000-8000-000000000001', public.gr_today()) $$) || ' ms');
select ok((select count(*) from public.ea_persons) >= 500, 'mindestens 500 Personen im Pfad GR sichtbar');
select ok(pg_temp.ms($$ select id, first_name, last_name from public.ea_persons $$) < 1000, 'Personenliste im Pfad GR < 1 s');
select diag('Personenliste: ' || pg_temp.ms($$ select id, first_name, last_name from public.ea_persons $$) || ' ms');

select * from finish();
rollback;
