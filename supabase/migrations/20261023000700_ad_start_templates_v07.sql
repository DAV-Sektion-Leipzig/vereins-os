-- US-AD-20, spec T40: Startvorlage „Referent:in“ (EA bearbeiten, Reichweite Referat) und Admin „Gruppen lesen“ (E5).
-- Idempotent; überschreibt keine Änderungen des Admins (nur Zeilen, die noch „kein Zugriff“ haben).
-- Startwerte für EZ, TK, TKF folgen mit den Nachträgen (spec T50, T59).

insert into public.ad_templates (name, description)
select 'Referent:in', 'Ehrenamtsmanagement bearbeiten, Reichweite Referat'
 where not exists (select 1 from public.ad_templates t where lower(t.name) = lower('Referent:in'));

-- Der Trigger ad_templates_init_rights hat je Modul eine Zeile mit „kein Zugriff“ angelegt
update public.ad_template_rights r
   set level = 'edit', scope = 'referat'
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Referent:in'
   and r.module_code = 'EA'
   and r.level = 'none'
   and r.scope = 'all';

update public.ad_template_rights r
   set level = 'read'
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Admin'
   and r.module_code = 'GR'
   and r.level = 'none';
