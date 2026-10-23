-- US-EA-07, US-EA-11, US-EA-12 (EA spec T9 Teil, T4): ea_expiry_status (R9), ea_default_valid_until (R5),
-- View ea_v_expiry je Testzugang (R10, R11, Erwartete Ergebnisse spec.md Abschnitt 9, research.md R-EA-06).
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
create function pg_temp.qual(p_code text) returns uuid language sql as $$
  select id from public.ad_qualification_types where code = p_code
$$;
create function pg_temp.expiry() returns table (person int, kind text, status text) language sql as $$
  select right(person_id::text, 2)::int, e.kind, e.expiry_status
    from public.ea_v_expiry e order by 1, 2
$$;

-- Ablaufstatus (R9)
select is(public.ea_expiry_status(null), 'none', 'ohne Datum: none');
select is(public.ea_expiry_status(current_date - 1), 'expired', 'gestern: expired');
select is(public.ea_expiry_status(current_date), 'expiring', 'heute: expiring');
select is(public.ea_expiry_status((current_date + interval '3 months')::date), 'expiring', 'heute + 3 Monate: expiring');
select is(public.ea_expiry_status((current_date + interval '3 months')::date + 1), 'valid', 'heute + 3 Monate + 1 Tag: valid');
select is(public.ea_expiry_status('2026-04-01', '2026-01-01'), 'expiring', 'fester Stichtag, genau 3 Monate');
select is(public.ea_expiry_status('2026-04-02', '2026-01-01'), 'valid', 'fester Stichtag, ein Tag später');

-- Vorbelegung „gültig bis“ (R5, US-EA-07 AK1, AK2, AK5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ea_default_valid_until(pg_temp.qual('TCSPI'), '2026-05-15'), date '2030-12-31',
  'TCSPI (4 Jahre) erworben 15.05.2026 → 31.12.2030 (AK1)');
select is(public.ea_default_valid_until(pg_temp.qual('TCSPI'), '2026-05-15', '2027-03-10'), date '2031-12-31',
  'mit letzter Fortbildung 10.03.2027 → 31.12.2031 (AK2)');
select is(public.ea_default_valid_until(pg_temp.qual('ZQOS'), '2026-05-15'), null::date,
  'Zusatzqualifikation ohne Gültigkeitsdauer → leer (AK5)');
select is(public.ea_default_valid_until(pg_temp.qual('EH'), '2026-05-15'), date '2028-12-31', 'Erste Hilfe (2 Jahre)');
select is(public.ea_default_valid_until('00000000-0000-4000-8000-000000000000', '2026-05-15'), null::date,
  'unbekannte Qualifikationsart → null');

-- View: Admin und Geschäftsstelle sehen alle Zeilen aktiver und ruhender Personen
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select results_eq($$ select * from pg_temp.expiry() $$,
  $$ values (4, 'license'::text, 'valid'::text), (5, 'license', 'expired'), (19, 'license', 'expiring'),
            (20, 'license', 'expired'), (20, 'police_clearance', 'expiring') $$,
  'Admin: Toni gültig, Anton abgelaufen, Lena läuft ab, Max Lizenz abgelaufen und Führungszeugnis läuft ab');
select is((select valid_until from public.ea_v_expiry where person_id = 'a0000000-0000-4000-8000-000000000019'),
  (current_date + interval '2 months')::date, 'Lena: gültig bis heute + 2 Monate (AK1)');
select is((select valid_until from public.ea_v_expiry where kind = 'police_clearance'),
  (current_date - interval '34 months' + interval '3 years')::date, 'Führungszeugnis: Ausstellungsdatum + 3 Jahre (R10, AK3)');
select results_eq(
  $$ select qualification_code, qualification_name is not null, discipline from public.ea_v_expiry
      where person_id = 'a0000000-0000-4000-8000-000000000004' $$,
  $$ values ('TCSPI'::text, true, 'Klettersport'::text) $$, 'Qualifikationsart mit Kürzel, Bezeichnung und Sparte');
select is((select qualification_type_id from public.ea_v_expiry where kind = 'police_clearance'), null::uuid,
  'Führungszeugnis ohne Qualifikationsart');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select * from pg_temp.expiry() $$,
  $$ values (4, 'license'::text, 'valid'::text), (5, 'license', 'expired'), (19, 'license', 'expiring'),
            (20, 'license', 'expired'), (20, 'police_clearance', 'expiring') $$,
  'Geschäftsstelle wie Admin');

-- Stichtagsliste Jahr 2027 (R11): Toni, dazu Lena nur, wenn heute + 2 Monate in 2027 liegt (research.md R-EA-06)
select results_eq(
  $$ select right(person_id::text, 2)::int from public.ea_v_expiry
      where kind in ('license', 'qualification') and valid_until between '2027-01-01' and '2027-12-31' order by 1 $$,
  $$ select 4 union all select 19 where extract(year from current_date + interval '2 months') = 2027 order by 1 $$,
  'Jahr 2027: Toni Muster TCSPI 31.12.2027 (+ Lena, falls heute + 2 Monate in 2027)');

-- Referent:in Klettern: nur Personen ihrer Referate, keine Führungszeugnis-Zeile (Lesestufe GST; AK5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select results_eq($$ select * from pg_temp.expiry() $$,
  $$ values (4, 'license'::text, 'valid'::text), (19, 'license', 'expiring') $$,
  'Referent:in: Toni und Lena, nicht Anton (Ausbildung) und nicht Max (Kinder und Jugend)');
select is_empty($$ select 1 from public.ea_v_expiry where kind = 'police_clearance' $$, 'Referent:in sieht keine Führungszeugnis-Einsicht');
select results_eq(
  $$ select right(person_id::text, 2)::int from public.ea_v_expiry
      where kind in ('license', 'qualification') and valid_until between '2027-01-01' and '2027-12-31' order by 1 $$,
  $$ select 4 union all select 19 where extract(year from current_date + interval '2 months') = 2027 order by 1 $$,
  'Referent:in Jahr 2027: nur Personen aus {4, 19}');

-- Vorstand: nichts
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.ea_v_expiry $$, 'Vorstand sieht keine Ablaufzeilen');

-- beendete Lizenz und ausgeschiedene Person erscheinen nicht (AK4)
select pg_temp.as_owner();
update public.ea_properties set valid_to = current_date - 1 where id = 'e0000000-0000-4000-8000-000000000007';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is_empty($$ select 1 from public.ea_v_expiry where person_id = 'a0000000-0000-4000-8000-000000000005' $$,
  'beendete Lizenz von Anton ohne Markierung');
select pg_temp.as_owner();
select set_config('ea.status_change', 'on', true);
update public.ea_persons set volunteer_status = 'left', volunteer_status_since = current_date
 where id = 'a0000000-0000-4000-8000-000000000020';
select set_config('ea.status_change', '', true);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is_empty($$ select 1 from public.ea_v_expiry where person_id = 'a0000000-0000-4000-8000-000000000020' $$,
  'ausgeschiedene Person ohne Markierung');

-- Zeile ohne gültig bis: Qualifikation ohne Datum → none
select pg_temp.as_owner();
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
values ('a0000000-0000-4000-8000-000000000004', (select id from public.ea_property_types where system_key = 'qualification'),
        jsonb_build_object('qualification_type', pg_temp.qual('ZQOS')), current_date);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select expiry_status from public.ea_v_expiry where kind = 'qualification'), 'none', 'Qualifikation ohne Ablauf: none');

select pg_temp.as_owner();
select * from finish();
rollback;
