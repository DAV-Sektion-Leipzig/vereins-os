-- Review-Befund S-01: Schutz vor Aussperren (R14) in der Datenbank.
-- Sperren, Entziehen und Herabsetzen der Stufe AD dürfen den letzten aktiven Zugang mit AD = verwalten
-- (Reichweite alle) nicht entfernen (AD_LAST_ADMIN). Der Notfallzugang kann nicht gesperrt werden und
-- seine Vorlage mit AD = verwalten nicht entzogen werden (AD_EMERGENCY_PROTECTED). Niemand sperrt den
-- eigenen Zugang (AD_SELF_LOCK).
-- Neu: ad_manage_remains, ad_check_lock, Trigger ad_template_rights_keep_admin.
-- Neue Fassungen (create or replace): ad_apply_lock (20261023001600), ad_revoke_template (20261020000300).

-- Bleibt mindestens ein aktiver Zugang mit wirksamer Zuweisung und AD = verwalten (Reichweite alle)?
-- Gültigkeit wie ad_user_level (20261023000300), aber für alle Zugänge statt auth.uid().
-- p_exclude_person: Zugang dieser Person nicht mitzählen (Sperren).
-- p_exclude_assignment: diese Zuweisung nicht mitzählen (Entziehen).
-- Intern, kein Grant an authenticated.
create function public.ad_manage_remains(p_exclude_person uuid default null, p_exclude_assignment uuid default null)
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
     where a.status = 'active'
       and (p_exclude_person is null or a.person_id <> p_exclude_person)
       and (p_exclude_assignment is null or ta.id <> p_exclude_assignment)
       and ta.revoked_at is null
       and (ta.valid_from is null or ta.valid_from <= current_date)
       and (ta.valid_to is null or ta.valid_to >= current_date)
       and r.module_code = 'AD'
       and r.object is null
       and r.scope = 'all'
       and r.level = 'manage'
  );
$$;

revoke all on function public.ad_manage_remains(uuid, uuid) from public, anon, authenticated;

-- Prüfungen vor dem Sperren; die Edge Function ad-access ruft sie vor dem Bann in Supabase Auth auf,
-- ad_apply_lock noch einmal in derselben Transaktion wie die Statusänderung.
create function public.ad_check_lock(p_person uuid, p_actor uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_access public.ad_accesses%rowtype;
begin
  select * into v_access from public.ad_accesses a where a.person_id = p_person;
  if not found or v_access.status not in ('invited', 'active') then
    raise exception 'AD_INVALID_STATUS' using errcode = 'P0001';
  end if;

  if v_access.is_emergency then
    raise exception 'AD_EMERGENCY_PROTECTED' using errcode = 'P0001';
  end if;

  if p_actor is not null and v_access.auth_user_id = p_actor then
    raise exception 'AD_SELF_LOCK' using errcode = 'P0001';
  end if;

  -- Nur wenn es vorher einen aktiven Admin gab und danach keinen mehr
  if public.ad_manage_remains() and not public.ad_manage_remains(p_exclude_person => p_person) then
    raise exception 'AD_LAST_ADMIN' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.ad_check_lock(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ad_check_lock(uuid, uuid) to service_role;

-- Sperren (US-AD-09); neue Fassung mit Schutz vor Aussperren
create or replace function public.ad_apply_lock(p_person uuid, p_actor uuid)
returns table (status public.ad_access_status)
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Zeile sperren, damit parallele Sperren nicht beide den vorletzten Admin sehen
  perform 1 from public.ad_accesses a where a.status = 'active' for update;

  perform public.ad_check_lock(p_person, p_actor);

  update public.ad_accesses a
     set status = 'locked',
         locked_at = now(),
         locked_by = p_actor
   where a.person_id = p_person
     and a.status in ('invited', 'active');
  if not found then
    raise exception 'AD_INVALID_STATUS' using errcode = 'P0001';
  end if;

  insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
  values (p_actor, p_person, 'locked');

  return query select 'locked'::public.ad_access_status;
end;
$$;

revoke all on function public.ad_apply_lock(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ad_apply_lock(uuid, uuid) to service_role;

-- Vorlage entziehen (R13, US-AD-11); Endzustand aus 20261020000300 plus Schutz vor Aussperren
create or replace function public.ad_revoke_template(p_person uuid, p_template uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
  v_assignment uuid;
begin
  if not public.ad_has_level('AD', 'edit') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  -- Aktive Zugänge sperren, damit parallele Entzüge nicht beide den vorletzten Admin sehen
  perform 1 from public.ad_accesses a where a.status = 'active' for update;

  select ta.id into v_assignment
    from public.ad_template_assignments ta
   where ta.person_id = p_person and ta.template_id = p_template and ta.revoked_at is null;

  if v_assignment is not null then
    -- Notfall-Admin (R14): die Vorlage, über die er AD = verwalten hat, bleibt
    if exists (
      select 1 from public.ad_accesses a where a.person_id = p_person and a.is_emergency
    ) and exists (
      select 1 from public.ad_template_rights r
       where r.template_id = p_template and r.module_code = 'AD' and r.object is null
         and r.scope = 'all' and r.level = 'manage'
    ) and not exists (
      select 1
        from public.ad_template_assignments ta
        join public.ad_template_rights r on r.template_id = ta.template_id
       where ta.person_id = p_person
         and ta.id <> v_assignment
         and ta.revoked_at is null
         and (ta.valid_from is null or ta.valid_from <= current_date)
         and (ta.valid_to is null or ta.valid_to >= current_date)
         and r.module_code = 'AD' and r.object is null and r.scope = 'all' and r.level = 'manage'
    ) then
      raise exception 'AD_EMERGENCY_PROTECTED' using errcode = 'P0001';
    end if;

    if public.ad_manage_remains() and not public.ad_manage_remains(p_exclude_assignment => v_assignment) then
      raise exception 'AD_LAST_ADMIN' using errcode = 'P0001';
    end if;
  end if;

  update public.ad_template_assignments ta
     set revoked_at = now(), revoked_by = auth.uid()
   where ta.person_id = p_person and ta.template_id = p_template and ta.revoked_at is null;

  if found then
    select t.name into v_name from public.ad_templates t where t.id = p_template;
    insert into public.ad_audit_log (subject_person_id, action, details)
    values (p_person, 'template_revoked', v_name);
  end if;
end;
$$;

revoke all on function public.ad_revoke_template(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ad_revoke_template(uuid, uuid) to authenticated;

-- Stufe AD einer Vorlage herabsetzen: nach dem Update (alle Zeilen der Anweisung sichtbar) prüfen,
-- ob noch ein aktiver Zugang AD verwalten kann. Nur wenn die Vorlage vorher einem aktiven Zugang
-- AD = verwalten gab; sonst entfernt die Änderung keinen Admin.
create function public.ad_template_rights_keep_admin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
      from public.ad_accesses a
      join public.ad_template_assignments ta on ta.person_id = a.person_id
     where ta.template_id = old.template_id
       and a.status = 'active'
       and ta.revoked_at is null
       and (ta.valid_from is null or ta.valid_from <= current_date)
       and (ta.valid_to is null or ta.valid_to >= current_date)
  ) and not public.ad_manage_remains() then
    raise exception 'AD_LAST_ADMIN' using errcode = 'P0001';
  end if;
  return null;
end;
$$;

revoke all on function public.ad_template_rights_keep_admin() from public, anon, authenticated;

create trigger ad_template_rights_keep_admin
  after update of level, scope on public.ad_template_rights
  for each row
  when (old.module_code = 'AD' and old.object is null and old.level = 'manage' and old.scope = 'all'
        and (new.level <> 'manage' or new.scope <> 'all'))
  execute function public.ad_template_rights_keep_admin();
