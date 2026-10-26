-- US-AD-20 (spec T7 Teil, T40): Startvorlage „Referent:in“ und Admin „Gruppen lesen“ (E5); Idempotenz.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select results_eq(
  $$ select r.module_code, r.level::text, r.scope::text
       from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where t.name = 'Referent:in' order by r.module_code $$,
  $$ values ('AD'::text, 'none'::text, 'all'::text), ('AM', 'none', 'all'), ('EA', 'edit', 'referat'),
            ('EZ', 'edit', 'referat'), ('FI', 'read', 'referat'), ('GR', 'none', 'all'), ('GS', 'none', 'all'), ('OA', 'none', 'all'),
            ('PM', 'none', 'all'), ('SC', 'none', 'all') $$,
  'Referent:in: EA und EZ bearbeiten, FI lesen (Nachtrag v0.10), je Reichweite Referat; übrige Module kein Zugriff');
select results_eq(
  $$ select r.module_code from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where t.name = 'Referent:in' and r.can_approve order by r.module_code $$,
  $$ values ('FI'::text) $$, 'Referent:in: darf in Finanzen freigeben (bestätigen), sonst nirgends (R50)');
select is(
  (select r.level::text from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
    where t.name = 'Admin' and r.module_code = 'GR'),
  'read', 'Admin: Gruppen lesen (E5)');
select is(
  (select r.level::text from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
    where t.name = 'Vorstand' and r.level <> 'none' limit 1),
  null, 'Vorstand weiter ohne Rechte');

-- Zweiter Lauf ändert nichts und überschreibt keine Änderung des Admins
update public.ad_template_rights r set level = 'read'
  from public.ad_templates t
 where r.template_id = t.id and t.name = 'Referent:in' and r.module_code = 'EA';

insert into public.ad_templates (name, description)
select 'Referent:in', 'Ehrenamtsmanagement bearbeiten, Reichweite Referat'
 where not exists (select 1 from public.ad_templates t where lower(t.name) = lower('Referent:in'));
update public.ad_template_rights r
   set level = 'edit', scope = 'referat'
  from public.ad_templates t
 where r.template_id = t.id and t.name = 'Referent:in' and r.module_code = 'EA'
   and r.level = 'none' and r.scope = 'all';

select is((select count(*)::int from public.ad_templates where name = 'Referent:in'), 1, 'keine zweite Vorlage');
select is(
  (select r.level::text from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
    where t.name = 'Referent:in' and r.module_code = 'EA'),
  'read', 'Änderung des Admins bleibt erhalten');

select * from finish();
rollback;
