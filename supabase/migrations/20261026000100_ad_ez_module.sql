-- Nachtrag v0.8 (spec.md AD v0.9.4, Nachtrag v0.8.1), spec T50; US-AD-28; Übergabe EZ A1, A2, A5; Übergabe GR Ü5.
-- Modul Anwesenheitserfassung (EZ) in ad_modules, Startwerte EZ, Reichweite „Referat“ für EA und EZ (R30),
-- created_in = 'EZ'. is_available bleibt false; das setzt die Anwesenheitserfassung mit ihrer Freigabe.
-- Idempotent; überschreibt keine Änderungen des Admins (nur Zeilen, die noch „kein Zugriff“ mit Reichweite „alle“ haben).

-- Modul direkt nach Gruppen (bestätigt 24.10.2026)
do $$
begin
  if not exists (select 1 from public.ad_modules where code = 'EZ') then
    update public.ad_modules
       set sort_order = sort_order + 1
     where sort_order > (select sort_order from public.ad_modules where code = 'GR');
    insert into public.ad_modules (code, name, sort_order, is_available)
    select 'EZ', 'Anwesenheitserfassung', g.sort_order + 1, false
      from public.ad_modules g where g.code = 'GR';
  end if;
end;
$$;

-- Je vorhandener Vorlage eine Zeile EZ mit „kein Zugriff“; neue Vorlagen erhalten sie über ad_templates_init_rights
insert into public.ad_template_rights (template_id, module_code)
select t.id, 'EZ' from public.ad_templates t
on conflict do nothing;

-- R30: Reichweite „Referat“ für EA und EZ
alter table public.ad_template_rights drop constraint ad_template_rights_scope_allowed;
alter table public.ad_template_rights
  add constraint ad_template_rights_scope_allowed
  check (scope = 'all' or (scope = 'referat' and module_code in ('EA', 'EZ')));

create or replace function public.ad_template_rights_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.scope = 'referat' and new.module_code not in ('EA', 'EZ') then
    raise exception 'AD_SCOPE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

-- Startwerte EZ (A1): Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne
update public.ad_template_rights r
   set level = case t.name when 'Admin' then 'read'::public.ad_level
                           when 'Geschäftsstelle' then 'manage'::public.ad_level
                           when 'Referent:in' then 'edit'::public.ad_level end,
       scope = case t.name when 'Referent:in' then 'referat'::public.ad_scope else 'all'::public.ad_scope end
  from public.ad_templates t
 where r.template_id = t.id
   and t.name in ('Admin', 'Geschäftsstelle', 'Referent:in')
   and r.module_code = 'EZ'
   and r.object is null
   and r.level = 'none'
   and r.scope = 'all';

-- Anlagemodul EZ (R45)
alter table public.ea_persons drop constraint ea_persons_created_in_check;
alter table public.ea_persons
  add constraint ea_persons_created_in_check check (created_in in ('AD', 'EA', 'GR', 'EZ', 'script'));
