-- Nachtrag v0.9 (spec.md AD v0.12.0), spec T59; Übergabe TK 1–3, 9, 11; R30, R50; spec.md TK v0.4 Abschnitt 3 (A2).
-- Modul Planungshilfe Touren und Kurse (TK) in ad_modules, Startwerte TK, neue Vorlage „Freigabe Touren und Kurse“
-- (TK bearbeiten + darf freigeben, Reichweite Referat). is_available bleibt false; das setzt die Planungshilfe mit
-- ihrer Freigabe. Idempotent; überschreibt keine Änderungen des Admins (nur Zeilen mit „kein Zugriff“, Reichweite „alle“).

-- Modul direkt nach der Anwesenheitserfassung
do $$
begin
  if not exists (select 1 from public.ad_modules where code = 'TK') then
    update public.ad_modules
       set sort_order = sort_order + 1
     where sort_order > (select sort_order from public.ad_modules where code = 'EZ');
    insert into public.ad_modules (code, name, sort_order, is_available)
    select 'TK', 'Planungshilfe Touren und Kurse', e.sort_order + 1, false
      from public.ad_modules e where e.code = 'EZ';
  end if;
end;
$$;

-- Je vorhandener Vorlage eine Zeile TK mit „kein Zugriff“; neue Vorlagen erhalten sie über ad_templates_init_rights
insert into public.ad_template_rights (template_id, module_code)
select t.id, 'TK' from public.ad_templates t
on conflict do nothing;

-- Startwerte TK: Admin lesen, Geschäftsstelle verwalten (ohne freigeben), Referent:in bearbeiten mit Reichweite Referat,
-- Vorstand ohne
update public.ad_template_rights r
   set level = case t.name when 'Admin' then 'read'::public.ad_level
                           when 'Geschäftsstelle' then 'manage'::public.ad_level
                           when 'Referent:in' then 'edit'::public.ad_level end,
       scope = case t.name when 'Referent:in' then 'referat'::public.ad_scope else 'all'::public.ad_scope end
  from public.ad_templates t
 where r.template_id = t.id
   and t.name in ('Admin', 'Geschäftsstelle', 'Referent:in')
   and r.module_code = 'TK'
   and r.object is null
   and r.level = 'none'
   and r.scope = 'all'
   and not r.can_approve;

-- Vorlage „Freigabe Touren und Kurse“ (der Trigger ad_templates_init_rights legt je Modul „kein Zugriff“ an)
insert into public.ad_templates (name, description)
select 'Freigabe Touren und Kurse',
       'Darf Touren und Kurse des zugewiesenen Referats freigeben, bearbeiten und Rückfragen stellen.'
 where not exists (select 1 from public.ad_templates t where lower(t.name) = lower('Freigabe Touren und Kurse'));

update public.ad_template_rights r
   set level = 'edit', scope = 'referat', can_approve = true
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Freigabe Touren und Kurse'
   and r.module_code = 'TK'
   and r.object is null
   and r.level = 'none'
   and r.scope = 'all'
   and not r.can_approve;

-- A2 (spec.md TK, Product Owner 26.10.2026): Startwert – alle Referent:innen der Referate Touren und Ausbildung erhalten
-- die Vorlage „Freigabe Touren und Kurse“ für diese Referate. Nur für Zuweisungen, die es beim Lauf der Migration gibt;
-- vergibt nichts doppelt. Protokoll ohne Akteur (Migration).
with src as (
  select ta.person_id, array_agg(r.id order by r.name) as referate, string_agg(r.name, ', ' order by r.name) as names
    from public.ad_template_assignments ta
    join public.ad_templates t on t.id = ta.template_id and t.name = 'Referent:in'
    join public.ad_assignment_referate ar on ar.assignment_id = ta.id
    join public.ea_referate r on r.id = ar.referat_id and r.name in ('Touren', 'Ausbildung')
   where ta.revoked_at is null
   group by ta.person_id
), fg as (
  select id from public.ad_templates where name = 'Freigabe Touren und Kurse'
), ins as (
  insert into public.ad_template_assignments (person_id, template_id)
  select s.person_id, fg.id
    from src s cross join fg
   where not exists (
     select 1 from public.ad_template_assignments x
      where x.person_id = s.person_id and x.template_id = fg.id and x.revoked_at is null
   )
  returning id, person_id
), refs as (
  insert into public.ad_assignment_referate (assignment_id, referat_id)
  select ins.id, unnest(s.referate)
    from ins join src s on s.person_id = ins.person_id
  returning assignment_id
)
insert into public.ad_audit_log (actor_user_id, subject_person_id, action, details)
select null, ins.person_id, 'template_assigned',
       'Freigabe Touren und Kurse (Referate: ' || s.names || ') – Startwert der Planungshilfe'
  from ins join src s on s.person_id = ins.person_id;
