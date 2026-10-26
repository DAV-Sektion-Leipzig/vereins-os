-- Dashboard (spec.md DS v0.2), Tasks T1 und T2 (Datenbankteil); uebergabe-administration.md DS v1.4 D1–D4, D6, D10.
-- Modul DS (Dashboard) vor AD, je Vorlage eine Zeile DS, Reichweite „Referat“ für DS (R30), Kennzeichen
-- „darf Budget pflegen“ (can_maintain_budget, nur DS, Reichweite alle), ad_has_budget_maintain(), Startwerte DS,
-- Vorlage „Budgetpflege“, Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz.
-- is_available bleibt false; das setzt das Dashboard mit seiner Freigabe (T19).
-- Idempotent; überschreibt keine Änderungen des Admins.

-- Modul an erster Stelle (plan.md P1)
do $$
begin
  if not exists (select 1 from public.ad_modules where code = 'DS') then
    update public.ad_modules set sort_order = sort_order + 1;
    insert into public.ad_modules (code, name, sort_order, is_available)
    values ('DS', 'Dashboard', 1, false);
  end if;
end;
$$;

-- Je vorhandener Vorlage eine Zeile DS mit „kein Zugriff“; neue Vorlagen erhalten sie über ad_templates_init_rights
insert into public.ad_template_rights (template_id, module_code)
select t.id, 'DS' from public.ad_templates t
on conflict do nothing;

-- Kennzeichen „darf Budget pflegen“ (D6)
alter table public.ad_template_rights
  add column can_maintain_budget boolean not null default false;

comment on column public.ad_template_rights.can_maintain_budget is
  'Budgetpflege (spec.md DS): Finanzplan einlesen, Zuordnung, DATEV-Import, umschlüsseln, Anträge entscheiden. Nur DS, Stufe ≠ none, Reichweite alle.';

alter table public.ad_template_rights
  add constraint ad_template_rights_budget_allowed
  check (not can_maintain_budget or (module_code = 'DS' and level <> 'none' and scope = 'all'));

-- R30: Reichweite „Referat“ für EA, EZ, TK, FI und DS
alter table public.ad_template_rights drop constraint ad_template_rights_scope_allowed;
alter table public.ad_template_rights
  add constraint ad_template_rights_scope_allowed
  check (scope = 'all' or (scope = 'referat' and module_code in ('EA', 'EZ', 'TK', 'FI', 'DS')));

-- R30, R50 und Budgetpflege mit Fehlercodes vor den Checks
create or replace function public.ad_template_rights_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.scope = 'referat' and new.module_code not in ('EA', 'EZ', 'TK', 'FI', 'DS') then
    raise exception 'AD_SCOPE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  if new.can_approve and (new.module_code not in ('FI', 'TK') or new.level = 'none') then
    raise exception 'AD_APPROVE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  if new.can_maintain_budget and (new.module_code <> 'DS' or new.level = 'none' or new.scope <> 'all') then
    raise exception 'AD_BUDGET_MAINTAIN_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger ad_template_rights_guard on public.ad_template_rights;
create trigger ad_template_rights_guard
  before insert or update of scope, module_code, level, can_approve, can_maintain_budget on public.ad_template_rights
  for each row execute function public.ad_template_rights_guard();

grant update (can_maintain_budget) on table public.ad_template_rights to authenticated;

-- Budgetpflege des aufrufenden Nutzers (aktiver Zugang, gültige Zuweisung, DS mit Reichweite alle und Kennzeichen)
create function public.ad_has_budget_maintain()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.ad_accesses a
      join public.ad_template_assignments ta on ta.person_id = a.person_id
      join public.ad_template_rights r on r.template_id = ta.template_id
     where a.auth_user_id = auth.uid()
       and a.status = 'active'
       and ta.revoked_at is null
       and (ta.valid_from is null or ta.valid_from <= current_date)
       and (ta.valid_to is null or ta.valid_to >= current_date)
       and r.module_code = 'DS'
       and r.object is null
       and r.scope = 'all'
       and r.level <> 'none'
       and r.can_maintain_budget
  );
$$;

revoke all on function public.ad_has_budget_maintain() from public, anon, authenticated;
grant execute on function public.ad_has_budget_maintain() to authenticated;

-- Startwerte DS (D3): Admin, Geschäftsstelle, Vorstand lesen (alle); Referent:in lesen (Referat)
update public.ad_template_rights r
   set level = 'read'::public.ad_level,
       scope = case t.name when 'Referent:in' then 'referat'::public.ad_scope else 'all'::public.ad_scope end
  from public.ad_templates t
 where r.template_id = t.id
   and t.name in ('Admin', 'Geschäftsstelle', 'Vorstand', 'Referent:in')
   and r.module_code = 'DS'
   and r.object is null
   and r.level = 'none'
   and r.scope = 'all';

-- Vorlage „Budgetpflege“ (D6): 1. Vorsitzender und Schatzmeister:in; Zuweisung durch den Admin
insert into public.ad_templates (name, description)
select 'Budgetpflege',
       'Dashboard lesen und Budget pflegen: Finanzplan einlesen, Zuordnung, DATEV-Import, umschlüsseln, Anträge entscheiden.'
 where not exists (select 1 from public.ad_templates t where lower(t.name) = lower('Budgetpflege'));

-- Der Trigger ad_templates_init_rights hat je Modul eine Zeile mit „kein Zugriff“ angelegt
update public.ad_template_rights r
   set level = 'read'::public.ad_level, scope = 'all'::public.ad_scope, can_maintain_budget = true
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Budgetpflege'
   and r.module_code = 'DS'
   and r.object is null
   and r.level = 'none';

-- Neue Referate (D10)
insert into public.ea_referate (name, sort_order)
select v.name, v.sort_order
  from (values ('Öffentlichkeitsarbeit', 8), ('Umwelt und Naturschutz', 9)) as v (name, sort_order)
 where not exists (select 1 from public.ea_referate r where lower(r.name) = lower(v.name));
