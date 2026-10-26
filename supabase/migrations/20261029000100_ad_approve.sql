-- Nachtrag v0.10 (spec.md AD v0.10.0), spec T68; R30, R50; Q1 aus dem Querschnitts-Check.
-- Aktion „freigeben“ als Kennzeichen can_approve am Recht einer Vorlage (nur FI und TK, nur mit Stufe ≠ none);
-- Reichweite „Referat“ zusätzlich für TK und FI. Das Modul TKF aus Nachtrag v0.9 entfällt (nie umgesetzt).

alter table public.ad_template_rights
  add column can_approve boolean not null default false;

comment on column public.ad_template_rights.can_approve is
  'Aktion „freigeben“ (R50): darf im Modul freigeben bzw. bestätigen, mit der Reichweite dieses Rechts. Nur FI und TK.';

alter table public.ad_template_rights
  add constraint ad_template_rights_approve_allowed
  check (not can_approve or (module_code in ('FI', 'TK') and level <> 'none'));

-- R30: Reichweite „Referat“ für EA, EZ, TK und FI
alter table public.ad_template_rights drop constraint ad_template_rights_scope_allowed;
alter table public.ad_template_rights
  add constraint ad_template_rights_scope_allowed
  check (scope = 'all' or (scope = 'referat' and module_code in ('EA', 'EZ', 'TK', 'FI')));

-- R30, R50 mit Fehlercodes vor den Checks
create or replace function public.ad_template_rights_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.scope = 'referat' and new.module_code not in ('EA', 'EZ', 'TK', 'FI') then
    raise exception 'AD_SCOPE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  if new.can_approve and (new.module_code not in ('FI', 'TK') or new.level = 'none') then
    raise exception 'AD_APPROVE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger ad_template_rights_guard on public.ad_template_rights;
create trigger ad_template_rights_guard
  before insert or update of scope, module_code, level, can_approve on public.ad_template_rights
  for each row execute function public.ad_template_rights_guard();

grant update (can_approve) on table public.ad_template_rights to authenticated;

-- Referate, in denen der aufrufende Nutzer im Modul freigeben darf (Reichweite „Referat“)
create function public.ad_my_approve_referate(p_module text)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct ar.referat_id), '{}')
    from public.ad_accesses a
    join public.ad_template_assignments ta on ta.person_id = a.person_id
    join public.ad_template_rights r on r.template_id = ta.template_id
    join public.ad_assignment_referate ar on ar.assignment_id = ta.id
   where a.auth_user_id = auth.uid()
     and a.status = 'active'
     and ta.revoked_at is null
     and (ta.valid_from is null or ta.valid_from <= current_date)
     and (ta.valid_to is null or ta.valid_to >= current_date)
     and r.module_code = p_module
     and r.object is null
     and r.scope = 'referat'
     and r.can_approve;
$$;

-- Freigaberecht mit Reichweite „alle“
create function public.ad_has_approve(p_module text)
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
       and r.module_code = p_module
       and r.object is null
       and r.scope = 'all'
       and r.can_approve
  );
$$;

-- Zentrale Prüfung für Finanzen (Bestätigung) und Planungshilfe (Freigabe)
create function public.ad_can_approve(p_module text, p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_approve(p_module)
      or (p_referat is not null and p_referat = any (public.ad_my_approve_referate(p_module)));
$$;

revoke all on function public.ad_my_approve_referate(text) from public, anon, authenticated;
revoke all on function public.ad_has_approve(text) from public, anon, authenticated;
revoke all on function public.ad_can_approve(text, uuid) from public, anon, authenticated;
grant execute on function public.ad_my_approve_referate(text) to authenticated;
grant execute on function public.ad_has_approve(text) to authenticated;
grant execute on function public.ad_can_approve(text, uuid) to authenticated;
