-- US-EA-06 (EA spec T9 Teil, T5): IBAN normalisieren und prüfen (R13), Trigger ea_properties_iban auf bank_account.
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
create function pg_temp.bank() returns uuid language sql as $$
  select id from public.ea_property_types where system_key = 'bank_account'
$$;

-- Normalisierung und Prüfsumme
select is(public.ea_iban_normalize('de89 3704 0044 0532 0130 00'), 'DE89370400440532013000', 'Leerzeichen entfernt, Großbuchstaben');
select is(public.ea_iban_normalize(E' DE89\t3704\n0044 0532 0130 00 '), 'DE89370400440532013000', 'auch Tabulator und Zeilenumbruch');
select is(public.ea_iban_normalize(null), null, 'null bleibt null');
select ok(public.ea_iban_valid('DE89370400440532013000'), 'Beispiel-IBAN gültig');
select ok(public.ea_iban_valid('de89 3704 0044 0532 0130 00'), 'gültig auch mit Leerzeichen und Kleinbuchstaben');
select ok(public.ea_iban_valid('GB82WEST12345698765432'), 'IBAN mit Buchstaben im Konto gültig (ISO 13616 Beispiel)');
select ok(not public.ea_iban_valid('DE00 1234'), '„DE00 1234“ ungültig (AK3)');
select ok(not public.ea_iban_valid('DE89370400440532013001'), 'falsche Prüfsumme');
select ok(not public.ea_iban_valid('DE89370400440532013000X'), 'Muster verletzt');
select ok(not public.ea_iban_valid(''), 'leer ungültig');
select ok(not public.ea_iban_valid(null), 'null ungültig');

-- Trigger: Geschäftsstelle legt Bankverbindung an → normalisiert gespeichert
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
  values ('a0000000-0000-4000-8000-000000000004', %L,
          '{"account_holder": "Toni Muster", "iban": "de89 3704 0044 0532 0130 00"}', current_date) $$, pg_temp.bank()),
  'Bankverbindung mit Leerzeichen und Kleinbuchstaben anlegen');
select is((select field_values ->> 'iban' from public.ea_properties
            where person_id = 'a0000000-0000-4000-8000-000000000004' and property_type_id = pg_temp.bank()),
  'DE89370400440532013000', 'IBAN ohne Leerzeichen in Großbuchstaben gespeichert (AK3)');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
  values ('a0000000-0000-4000-8000-000000000009', %L, '{"account_holder": "Rita", "iban": "DE00 1234"}', current_date) $$, pg_temp.bank()),
  'P0001', 'EA_IBAN_INVALID', 'ungültige IBAN abgelehnt (R13)');
select throws_ok(format($$ update public.ea_properties set field_values = field_values || '{"iban": "DE89370400440532013001"}'
  where id = 'e0000000-0000-4000-8000-000000000024' $$),
  'P0001', 'EA_IBAN_INVALID', 'auch beim Ändern');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
  values ('a0000000-0000-4000-8000-000000000009', %L, '{"account_holder": "Rita"}', current_date) $$, pg_temp.bank()),
  'P0001', 'EA_FIELD_REQUIRED', 'fehlende IBAN meldet das Pflichtfeld, nicht EA_IBAN_INVALID');
select lives_ok($$ update public.ea_properties set field_values = field_values || '{"account_holder": "Sven S."}'
  where id = 'e0000000-0000-4000-8000-000000000024' $$, 'andere Felder ohne IBAN-Prüfung änderbar');
select is((select field_values ->> 'iban' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000024'),
  'DE89370400440532013000', 'Seed-IBAN von Sven bleibt');

-- andere Art mit Feld iban bleibt unberührt
select pg_temp.as_owner();
insert into public.ea_property_types (id, name, purpose, visible_in)
values ('d0000000-0000-4000-8000-0000000000cc', 'IBAN-Test', 'Test', '{AD,EA}');
insert into public.ea_property_fields (property_type_id, key, label, data_type, sort_order)
values ('d0000000-0000-4000-8000-0000000000cc', 'iban', 'IBAN', 'text', 1);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
  values ('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-0000000000cc', '{"iban": "kein iban"}', current_date) $$,
  'Trigger nur bei system_key bank_account');

-- Referent:in: Lesestufe GST – weder lesen noch anlegen
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is_empty($$ select 1 from public.ea_properties where property_type_id = pg_temp.bank() $$,
  'Referent:in liest keine Bankverbindung (Lesestufe GST)');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
  values ('a0000000-0000-4000-8000-000000000019', %L, '{"account_holder": "Lena", "iban": "DE89370400440532013000"}',
          (select id from public.ea_referate where name = 'Klettern'), current_date) $$, pg_temp.bank()),
  '42501', null, 'Referent:in legt keine Bankverbindung an');

select pg_temp.as_owner();
select * from finish();
rollback;
