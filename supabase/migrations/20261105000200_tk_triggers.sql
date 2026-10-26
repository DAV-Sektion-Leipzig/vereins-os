-- Planungshilfe Touren und Kurse (TK), spec T3 und T4; spec.md TK v0.4 Abschnitt 2 (tk_qualification_sports,
-- Trigger), R12; tasks.md T003, T004.

-- Startbestand Qualifikationsart → Sportart (Prototyp 4.8, C3). Zuordnung der Prototyp-Bezeichnungen über die Kürzel
-- der Qualifikationsarten; „Trainer*in C Sportklettern“ gilt für TCSPI, TCSP und KS (alle Sportklettern Breitensport).
-- Nicht zuordenbare Kürzel meldet die Migration (raise notice); Pflege später.
do $$
declare
  v_missing text;
begin
  insert into public.tk_qualification_sports (qualification_type_id, sport)
  select q.id, v.sport
    from (values
      ('TCBW', 'Wandern'), ('TCBW', 'Sport- und Langstreckenwandern'), ('TCBW', 'Bergwandern'),
      ('TCBS', 'Wandern'), ('TCBS', 'Sport- und Langstreckenwandern'), ('TCBS', 'Bergwandern'), ('TCBS', 'Bergsteigen'),
      ('TCBS', 'Klettersteig'),
      ('TBHT', 'Wandern'), ('TBHT', 'Bergwandern'), ('TBHT', 'Bergsteigen'), ('TBHT', 'Klettersteig'), ('TBHT', 'Hochtour'),
      ('TCSB', 'Skitour'), ('TCSB', 'Schneeschuhtour'),
      ('TCSPI', 'Klettern'), ('TCSPI', 'Bouldern'), ('TCSP', 'Klettern'), ('TCSP', 'Bouldern'),
      ('KS', 'Klettern'), ('KS', 'Bouldern'),
      ('TBAK', 'Klettern'), ('TBAK', 'Alpinklettern'), ('TBAK', 'Bergsteigen'), ('TBAK', 'Klettersteig'),
      ('WL', 'Wandern'), ('WL', 'Sport- und Langstreckenwandern'),
      ('UBPR', 'Wandern')
    ) as v (code, sport)
    join public.ad_qualification_types q on q.code = v.code
  on conflict do nothing;

  select string_agg(v.code, ', ') into v_missing
    from (values ('TCBW'), ('TCBS'), ('TBHT'), ('TCSB'), ('TCSPI'), ('TCSP'), ('KS'), ('TBAK'), ('WL'), ('UBPR')) as v (code)
   where not exists (select 1 from public.ad_qualification_types q where q.code = v.code);
  if v_missing is not null then
    raise notice 'tk_qualification_sports: Qualifikationsarten nicht gefunden: %', v_missing;
  end if;
end;
$$;

-- Person des angemeldeten Nutzers (Audit); intern
create function public.tk_my_person_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select a.person_id from public.ad_accesses a where a.auth_user_id = auth.uid();
$$;

revoke all on function public.tk_my_person_id() from public, anon, authenticated;

-- R12: Referat aus dem Tourtyp (Kurs → Ausbildung, sonst Touren), aufgelöst über den Namen in ea_referate (plan.md P3)
create function public.tk_plan_referat(p_type public.tk_plan_type)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  select r.id into v_id from public.ea_referate r
   where r.name = case p_type when 'course' then 'Ausbildung' else 'Touren' end;
  if v_id is null then
    raise exception 'TK_REFERAT_MISSING' using errcode = 'P0001';
  end if;
  return v_id;
end;
$$;

revoke all on function public.tk_plan_referat(public.tk_plan_type) from public, anon, authenticated;

-- Statuswechsel nur innerhalb von tk_change_status (Schalter tk.status_change); Audit; Referat aus Tourtyp
create function public.tk_plans_before_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.referat_id := public.tk_plan_referat(new.plan_type);
  if tg_op = 'INSERT' then
    if new.status <> 'draft' and coalesce(current_setting('tk.status_change', true), '') <> 'on' then
      raise exception 'TK_STATUS_DIRECT' using errcode = 'P0001';
    end if;
    new.created_at := now();
    new.created_by := coalesce(auth.uid(), new.created_by);
    new.created_by_person_id := coalesce(public.tk_my_person_id(), new.created_by_person_id);
    new.updated_at := null;
    new.updated_by := null;
    new.updated_by_person_id := null;
  else
    if new.status is distinct from old.status and coalesce(current_setting('tk.status_change', true), '') <> 'on' then
      raise exception 'TK_STATUS_DIRECT' using errcode = 'P0001';
    end if;
    if new.client_request_id is distinct from old.client_request_id
       or new.created_at is distinct from old.created_at
       or new.created_by is distinct from old.created_by
       or new.created_by_person_id is distinct from old.created_by_person_id then
      raise exception 'TK_FIELD_LOCKED' using errcode = 'P0001';
    end if;
    new.updated_at := now();
    new.updated_by := coalesce(auth.uid(), new.updated_by);
    new.updated_by_person_id := coalesce(public.tk_my_person_id(), new.updated_by_person_id);
  end if;
  return new;
end;
$$;

revoke all on function public.tk_plans_before_write() from public, anon, authenticated;

create trigger tk_plans_before_write
  before insert or update on public.tk_plans
  for each row execute function public.tk_plans_before_write();

-- Verlauf: Akteur setzen
create function public.tk_plan_history_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.at := clock_timestamp();
  new.by_user := coalesce(auth.uid(), new.by_user);
  new.by_person_id := coalesce(public.tk_my_person_id(), new.by_person_id);
  return new;
end;
$$;

revoke all on function public.tk_plan_history_before_insert() from public, anon, authenticated;

create trigger tk_plan_history_before_insert
  before insert on public.tk_plan_history
  for each row execute function public.tk_plan_history_before_insert();
