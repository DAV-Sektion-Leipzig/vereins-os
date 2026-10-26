-- Planungshilfe Touren und Kurse (TK), spec T7; spec.md TK v0.4 Abschnitt 2 (tk_save_plan Schritte 1–9 ohne EZ,
-- tk_copy_plan, tk_delete_plan), R12, R13, R17–R20; tasks.md T007. Die Anbindung der Anwesenheitserfassung
-- (Schritt 8) folgt mit Stufe 3 (tasks.md T015).

-- Darf der Nutzer die Planung im aktuellen Status ändern? (R19) Intern.
create function public.tk_can_edit_plan(p_status public.tk_plan_status, p_referat uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_status in ('draft', 'submitted', 'query') then public.tk_can_write(p_referat)
    when p_status in ('approved', 'published') then public.tk_can_approve(p_referat) or public.tk_can_manage()
    else false end;
$$;

revoke all on function public.tk_can_edit_plan(public.tk_plan_status, uuid) from public, anon, authenticated;

-- R20: Name der Person, die zuletzt geändert hat (für TK_CONFLICT); intern
create function public.tk_last_editor(p_plan public.tk_plans)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select coalesce(e.preferred_name, e.first_name) || ' ' || e.last_name
                     from public.ea_persons e where e.id = p_plan.updated_by_person_id), '');
$$;

revoke all on function public.tk_last_editor(public.tk_plans) from public, anon, authenticated;

-- Ergebnis eines Speicherns (id, row_version, Ergebnisse); intern
create function public.tk_save_result(p_id uuid, p_warning text default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id, 'row_version', p.row_version, 'status', p.status, 'warning', p_warning,
    'results', (select to_jsonb(r) - 'plan_id' from public.tk_plan_results r where r.plan_id = p.id))
    from public.tk_plans p where p.id = p_id;
$$;

revoke all on function public.tk_save_result(uuid, text) from public, anon, authenticated;

-- Werte für Verlauf ab „freigegeben“ (R19): Termin, Leitung, Beitrag, Gesamtkosten; intern
create function public.tk_tracked_values(p_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'start_date', p.start_date, 'end_date', p.end_date, 'meet_time', p.meet_time, 'end_time', p.end_time,
    'leaders', (select coalesce(jsonb_agg(jsonb_build_array(l.person_id, l.role) order by l.sort_order), '[]')
                  from public.tk_plan_leaders l where l.plan_id = p.id),
    'price_member', p.price_member, 'price_non_member', p.price_non_member,
    'total_costs', (select r.total_costs from public.tk_plan_results r where r.plan_id = p.id))
    from public.tk_plans p where p.id = p_id;
$$;

revoke all on function public.tk_tracked_values(uuid) from public, anon, authenticated;

create function public.tk_save_plan(
  p_plan jsonb, p_leaders jsonb, p_contacts jsonb, p_legs jsonb, p_costs jsonb, p_row_version int default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := nullif(p_plan ->> 'id', '')::uuid;
  v_is_new boolean := v_id is null;
  v_old public.tk_plans%rowtype;
  v_type public.tk_plan_type;
  v_referat uuid;
  v_crid uuid;
  v_before jsonb;
  v_after jsonb;
  v_changed text[];
  v_item jsonb;
  v_person uuid;
  v_role public.tk_leader_role;
  v_sort int := 0;
  v_persons uuid[] := '{}';
  v_leader_id uuid;
  v_status public.ea_volunteer_status;
  v_email text;
  v_mobile text;
  v_ename text;
  v_ephone text;
  v_constraint text;
begin
  if not v_is_new then
    select * into v_old from public.tk_plans p where p.id = v_id for update;
    if not found or not public.tk_can_read(v_old.referat_id) then
      raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
    end if;
    if not public.tk_can_edit_plan(v_old.status, v_old.referat_id) then
      if v_old.status in ('approved', 'published') and public.tk_can_write(v_old.referat_id) then
        raise exception 'TK_LOCKED' using errcode = 'P0001', detail = 'approved';
      elsif v_old.status in ('done', 'closed', 'cancelled') and public.tk_can_write(v_old.referat_id) then
        raise exception 'TK_LOCKED' using errcode = 'P0001', detail = 'final';
      end if;
      raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
    end if;
    if p_row_version is not null and p_row_version <> v_old.row_version then
      raise exception 'TK_CONFLICT' using errcode = 'P0001', detail = public.tk_last_editor(v_old);
    end if;
    v_type := coalesce(nullif(p_plan ->> 'plan_type', '')::public.tk_plan_type, v_old.plan_type);
    if v_type <> v_old.plan_type then
      v_referat := public.tk_plan_referat(v_type);
      if v_referat <> v_old.referat_id and not public.tk_can_write(v_referat) then
        raise exception 'TK_FORBIDDEN_REFERAT' using errcode = 'P0001', detail = v_type::text;
      end if;
    end if;
    if v_old.status in ('approved', 'published') then
      v_before := public.tk_tracked_values(v_id);
    end if;
  else
    -- R12: Referat aus dem Tourtyp; Recht im Ziel-Referat
    v_type := nullif(p_plan ->> 'plan_type', '')::public.tk_plan_type;
    if v_type is null then
      raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'plan_type';
    end if;
    v_referat := public.tk_plan_referat(v_type);
    if not public.tk_can_write(v_referat) then
      if public.ad_has_any_level('TK', 'edit') then
        raise exception 'TK_FORBIDDEN_REFERAT' using errcode = 'P0001', detail = v_type::text;
      end if;
      raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
    end if;
    v_crid := coalesce(nullif(p_plan ->> 'client_request_id', '')::uuid, gen_random_uuid());
    -- Schutz gegen doppeltes Anlegen
    select p.id into v_id from public.tk_plans p where p.client_request_id = v_crid;
    if v_id is not null then
      return public.tk_save_result(v_id);
    end if;
    insert into public.tk_plans (plan_type, referat_id, title, client_request_id)
    values (v_type, v_referat, btrim(coalesce(p_plan ->> 'title', '')), v_crid)
    returning id into v_id;
    insert into public.tk_plan_history (plan_id, event, to_status) values (v_id, 'created', 'draft');
  end if;

  -- Felder (nur übergebene Schlüssel); Prüfungen über die Checks der Tabelle
  begin
    update public.tk_plans set
         title = case when p_plan ? 'title' then btrim(coalesce(p_plan ->> 'title', '')) else title end,
         community_reason = case when p_plan ? 'community_reason' then nullif(btrim(coalesce(p_plan ->> 'community_reason', '')), '') else community_reason end,
         sport = case when p_plan ? 'sport' then nullif(btrim(coalesce(p_plan ->> 'sport', '')), '') else sport end,
         region = case when p_plan ? 'region' then nullif(btrim(coalesce(p_plan ->> 'region', '')), '') else region end,
         base = case when p_plan ? 'base' then nullif(btrim(coalesce(p_plan ->> 'base', '')), '') else base end,
         teaser = case when p_plan ? 'teaser' then nullif(btrim(coalesce(p_plan ->> 'teaser', '')), '') else teaser end,
         programme = case when p_plan ? 'programme' then nullif(btrim(coalesce(p_plan ->> 'programme', '')), '') else programme end,
         image_credit = case when p_plan ? 'image_credit' then nullif(btrim(coalesce(p_plan ->> 'image_credit', '')), '') else image_credit end,
         meeting_point = case when p_plan ? 'meeting_point' then nullif(btrim(coalesce(p_plan ->> 'meeting_point', '')), '') else meeting_point end,
         meeting_coords = case when p_plan ? 'meeting_coords' then nullif(btrim(coalesce(p_plan ->> 'meeting_coords', '')), '') else meeting_coords end,
         travel_notes = case when p_plan ? 'travel_notes' then nullif(btrim(coalesce(p_plan ->> 'travel_notes', '')), '') else travel_notes end,
         grade = case when p_plan ? 'grade' then nullif(btrim(coalesce(p_plan ->> 'grade', '')), '') else grade end,
         requirements = case when p_plan ? 'requirements' then nullif(btrim(coalesce(p_plan ->> 'requirements', '')), '') else requirements end,
         equipment = case when p_plan ? 'equipment' then nullif(btrim(coalesce(p_plan ->> 'equipment', '')), '') else equipment end,
         non_members_reason = case when p_plan ? 'non_members_reason' then nullif(btrim(coalesce(p_plan ->> 'non_members_reason', '')), '') else non_members_reason end,
         accommodation_cancellation = case when p_plan ? 'accommodation_cancellation' then nullif(btrim(coalesce(p_plan ->> 'accommodation_cancellation', '')), '') else accommodation_cancellation end,
         custom_question = case when p_plan ? 'custom_question' then nullif(btrim(coalesce(p_plan ->> 'custom_question', '')), '') else custom_question end,
         car_reason = case when p_plan ? 'car_reason' then nullif(btrim(coalesce(p_plan ->> 'car_reason', '')), '') else car_reason end,
         notes_for_referat = case when p_plan ? 'notes_for_referat' then nullif(btrim(coalesce(p_plan ->> 'notes_for_referat', '')), '') else notes_for_referat end,
         plan_type = case when p_plan ? 'plan_type' then coalesce(nullif(p_plan ->> 'plan_type', '')::public.tk_plan_type, plan_type) else plan_type end,
         image_source = case when p_plan ? 'image_source' then nullif(p_plan ->> 'image_source', '')::public.tk_image_source else image_source end,
         prebriefing = case when p_plan ? 'prebriefing' then coalesce(nullif(p_plan ->> 'prebriefing', '')::public.tk_prebriefing, 'none') else prebriefing end,
         public_transport = case when p_plan ? 'public_transport' then nullif(p_plan ->> 'public_transport', '')::public.tk_public_transport else public_transport end,
         accommodation = case when p_plan ? 'accommodation' then coalesce(nullif(p_plan ->> 'accommodation', '')::public.tk_accommodation, 'none') else accommodation end,
         fitness = case when p_plan ? 'fitness' then nullif(p_plan ->> 'fitness', '')::public.tk_fitness else fitness end,
         technique = case when p_plan ? 'technique' then nullif(p_plan ->> 'technique', '')::public.tk_technique else technique end,
         yolawo_by = case when p_plan ? 'yolawo_by' then coalesce(nullif(p_plan ->> 'yolawo_by', '')::public.tk_yolawo_by, 'referat') else yolawo_by end,
         start_date = case when p_plan ? 'start_date' then nullif(p_plan ->> 'start_date', '')::date else start_date end,
         end_date = case when p_plan ? 'end_date' then nullif(p_plan ->> 'end_date', '')::date else end_date end,
         registration_deadline = case when p_plan ? 'registration_deadline' then nullif(p_plan ->> 'registration_deadline', '')::date else registration_deadline end,
         meet_time = case when p_plan ? 'meet_time' then nullif(p_plan ->> 'meet_time', '')::time else meet_time end,
         end_time = case when p_plan ? 'end_time' then nullif(p_plan ->> 'end_time', '')::time else end_time end,
         prebriefing_at = case when p_plan ? 'prebriefing_at' then nullif(p_plan ->> 'prebriefing_at', '')::timestamp else prebriefing_at end,
         nights = case when p_plan ? 'nights' then nullif(p_plan ->> 'nights', '')::int else nights end,
         co2_persons = case when p_plan ? 'co2_persons' then nullif(p_plan ->> 'co2_persons', '')::int else co2_persons end,
         max_ascent = case when p_plan ? 'max_ascent' then nullif(p_plan ->> 'max_ascent', '')::int else max_ascent end,
         max_descent = case when p_plan ? 'max_descent' then nullif(p_plan ->> 'max_descent', '')::int else max_descent end,
         min_participants = case when p_plan ? 'min_participants' then nullif(p_plan ->> 'min_participants', '')::int else min_participants end,
         max_participants = case when p_plan ? 'max_participants' then nullif(p_plan ->> 'max_participants', '')::int else max_participants end,
         days_full = case when p_plan ? 'days_full' then nullif(p_plan ->> 'days_full', '')::int else days_full end,
         days_half = case when p_plan ? 'days_half' then nullif(p_plan ->> 'days_half', '')::int else days_half end,
         teaching_hours = case when p_plan ? 'teaching_hours' then nullif(p_plan ->> 'teaching_hours', '')::int else teaching_hours end,
         org_days = case when p_plan ? 'org_days' then nullif(p_plan ->> 'org_days', '')::int else org_days end,
         max_walk_hours = case when p_plan ? 'max_walk_hours' then nullif(p_plan ->> 'max_walk_hours', '')::numeric else max_walk_hours end,
         max_distance_km = case when p_plan ? 'max_distance_km' then nullif(p_plan ->> 'max_distance_km', '')::numeric else max_distance_km end,
         price_member = case when p_plan ? 'price_member' then nullif(p_plan ->> 'price_member', '')::numeric else price_member end,
         price_non_member = case when p_plan ? 'price_non_member' then nullif(p_plan ->> 'price_non_member', '')::numeric else price_non_member end,
         meeting_near_pt = case when p_plan ? 'meeting_near_pt' then coalesce((p_plan ->> 'meeting_near_pt')::boolean, false) else meeting_near_pt end,
         non_members_allowed = case when p_plan ? 'non_members_allowed' then coalesce((p_plan ->> 'non_members_allowed')::boolean, false) else non_members_allowed end,
         waitlist = case when p_plan ? 'waitlist' then coalesce((p_plan ->> 'waitlist')::boolean, true) else waitlist end,
         no_fee = case when p_plan ? 'no_fee' then coalesce((p_plan ->> 'no_fee')::boolean, false) else no_fee end,
         confirm_license = case when p_plan ? 'confirm_license' then coalesce((p_plan ->> 'confirm_license')::boolean, false) else confirm_license end,
         confirm_calculation = case when p_plan ? 'confirm_calculation' then coalesce((p_plan ->> 'confirm_calculation')::boolean, false) else confirm_calculation end,
         confirm_ul_declaration = case when p_plan ? 'confirm_ul_declaration' then coalesce((p_plan ->> 'confirm_ul_declaration')::boolean, false) else confirm_ul_declaration end,
         confirm_emergency_card = case when p_plan ? 'confirm_emergency_card' then coalesce((p_plan ->> 'confirm_emergency_card')::boolean, false) else confirm_emergency_card end,
         feedback_form = case when p_plan ? 'feedback_form' then coalesce((p_plan ->> 'feedback_form')::boolean, false) else feedback_form end,
         target_groups = case when p_plan ? 'target_groups' then coalesce(array(select jsonb_array_elements_text(case when jsonb_typeof(p_plan -> 'target_groups') = 'array' then p_plan -> 'target_groups' else '[]' end)), '{}') else target_groups end,
         registration_questions = case when p_plan ? 'registration_questions' then coalesce(array(select jsonb_array_elements_text(case when jsonb_typeof(p_plan -> 'registration_questions') = 'array' then p_plan -> 'registration_questions' else '[]' end)), '{}') else registration_questions end,
         touched = case when p_plan ? 'touched' then coalesce(array(select jsonb_array_elements_text(case when jsonb_typeof(p_plan -> 'touched') = 'array' then p_plan -> 'touched' else '[]' end)), '{}') else touched end,
           row_version = case when v_is_new then row_version else row_version + 1 end
     where id = v_id;
  exception
    when check_violation then
      get stacked diagnostics v_constraint = constraint_name;
      raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = v_constraint;
    when invalid_text_representation or invalid_datetime_format or datetime_field_overflow
         or numeric_value_out_of_range then
      raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = sqlerrm;
  end;

  -- Leitung (R13, R17): Liste ersetzt die gespeicherte; vorhandene Personen behalten ihre Zeile (Kontakte)
  if p_leaders is not null then
    for v_item in select * from jsonb_array_elements(p_leaders) loop
      v_person := nullif(v_item ->> 'person_id', '')::uuid;
      v_role := coalesce(nullif(v_item ->> 'role', '')::public.tk_leader_role, 'lead');
      if v_person is null then
        raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'person_id';
      end if;
      if v_person = any (v_persons) then
        raise exception 'TK_DUPLICATE_PERSON' using errcode = 'P0001';
      end if;
      v_persons := v_persons || v_person;
      v_sort := v_sort + 1;
      select l.id into v_leader_id from public.tk_plan_leaders l where l.plan_id = v_id and l.person_id = v_person;
      if v_leader_id is null then
        select e.volunteer_status into v_status from public.ea_persons e where e.id = v_person and e.kind = 'human';
        if v_status is distinct from 'active' then
          raise exception 'TK_PERSON_NOT_ACTIVE' using errcode = 'P0001';
        end if;
        insert into public.tk_plan_leaders (plan_id, person_id, role, sort_order)
        values (v_id, v_person, v_role, v_sort);
      else
        update public.tk_plan_leaders set role = v_role, sort_order = v_sort where id = v_leader_id;
      end if;
    end loop;
    delete from public.tk_plan_leaders l where l.plan_id = v_id and not (l.person_id = any (v_persons));
  end if;

  -- Kontakt- und Notfalldaten (R8, R18): nur mit Recht, nicht nach der Löschung (R16)
  if p_contacts is not null and public.tk_can_read_contacts(public.tk_plan_referat(v_type))
     and (v_is_new or v_old.contacts_purged_at is null) then
    delete from public.tk_plan_contacts c where c.plan_id = v_id;
    for v_item in select * from jsonb_array_elements(p_contacts) loop
      select l.id into v_leader_id from public.tk_plan_leaders l
       where l.plan_id = v_id and l.person_id = nullif(v_item ->> 'person_id', '')::uuid;
      continue when v_leader_id is null;
      v_email := nullif(btrim(coalesce(v_item ->> 'email', '')), '');
      v_mobile := nullif(btrim(coalesce(v_item ->> 'mobile', '')), '');
      v_ename := nullif(btrim(coalesce(v_item ->> 'emergency_name', '')), '');
      v_ephone := nullif(btrim(coalesce(v_item ->> 'emergency_phone', '')), '');
      if v_email is not null and not (char_length(v_email) <= 200 and v_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$') then
        raise exception 'TK_EMAIL_INVALID' using errcode = 'P0001';
      end if;
      if (v_mobile is not null and v_mobile !~ '^[0-9 +/()\-]{5,30}$')
         or (v_ephone is not null and v_ephone !~ '^[0-9 +/()\-]{5,30}$') then
        raise exception 'TK_PHONE_INVALID' using errcode = 'P0001';
      end if;
      if v_ename is not null and char_length(v_ename) > 200 then
        raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'emergency_name';
      end if;
      continue when v_email is null and v_mobile is null and v_ename is null and v_ephone is null;
      insert into public.tk_plan_contacts (leader_id, plan_id, email, mobile, emergency_name, emergency_phone)
      values (v_leader_id, v_id, v_email, v_mobile, v_ename, v_ephone);
    end loop;
  end if;

  -- Teilstrecken und Kostenzeilen ersetzen die gespeicherten vollständig
  begin
    if p_legs is not null then
      delete from public.tk_plan_legs g where g.plan_id = v_id;
      insert into public.tk_plan_legs (plan_id, sort_order, mode, label, km_one_way, persons, vehicles, round_trip)
      select v_id, x.ord, coalesce(nullif(x.v ->> 'mode', '')::public.tk_transport, 'rail_long'),
             nullif(btrim(coalesce(x.v ->> 'label', '')), ''), coalesce(nullif(x.v ->> 'km_one_way', '')::numeric, 0),
             coalesce(nullif(x.v ->> 'persons', '')::int, 0), coalesce(nullif(x.v ->> 'vehicles', '')::int, 0),
             coalesce((x.v ->> 'round_trip')::boolean, true)
        from jsonb_array_elements(p_legs) with ordinality as x (v, ord);
    end if;
    if p_costs is not null then
      delete from public.tk_plan_costs c where c.plan_id = v_id;
      insert into public.tk_plan_costs (plan_id, cost_group, sort_order, label, quantity, unit_price, is_car,
                                        is_overnight, is_hut_half_board)
      select v_id, (x.v ->> 'cost_group')::public.tk_cost_group, x.ord, btrim(coalesce(x.v ->> 'label', '')),
             coalesce(nullif(x.v ->> 'quantity', '')::numeric, 0), coalesce(nullif(x.v ->> 'unit_price', '')::numeric, 0),
             coalesce((x.v ->> 'is_car')::boolean, false), coalesce((x.v ->> 'is_overnight')::boolean, false),
             coalesce((x.v ->> 'is_hut_half_board')::boolean, false)
        from jsonb_array_elements(p_costs) with ordinality as x (v, ord);
    end if;
  exception
    when check_violation or not_null_violation then
      get stacked diagnostics v_constraint = constraint_name;
      raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = coalesce(nullif(v_constraint, ''), sqlerrm);
    when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = sqlerrm;
  end;

  perform public.tk_calculate(v_id);

  -- R19: ab „freigegeben“ Verlauf mit geänderten Feldern (ohne Werte)
  if v_before is not null then
    v_after := public.tk_tracked_values(v_id);
    select array_agg(k order by k) into v_changed
      from jsonb_object_keys(v_after) k
     where v_after -> k is distinct from v_before -> k;
    if v_changed is not null then
      insert into public.tk_plan_history (plan_id, event, changed_fields) values (v_id, 'saved', v_changed);
    end if;
  end if;

  return public.tk_save_result(v_id);
end;
$$;

revoke all on function public.tk_save_plan(jsonb, jsonb, jsonb, jsonb, jsonb, int) from public, anon, authenticated;
grant execute on function public.tk_save_plan(jsonb, jsonb, jsonb, jsonb, jsonb, int) to authenticated;

-- US-TK-23: Kopie als Entwurf ohne Termin, Anmeldeschluss, Vorbesprechungsdatum, Status, Verlauf, Einsatz,
-- Yolawo-Angebot, Kontakt- und Notfalldaten und Bestätigungen; nur aktive Personen der Leitung; aktuelle Sätze.
create function public.tk_copy_plan(p_id uuid, p_client_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_src public.tk_plans%rowtype;
  v_new uuid;
  v_removed text[];
begin
  select * into v_src from public.tk_plans p where p.id = p_id;
  if not found or not public.tk_can_read(v_src.referat_id) then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if not public.tk_can_write(v_src.referat_id) then
    raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
  end if;
  select p.id into v_new from public.tk_plans p where p.client_request_id = p_client_request_id;
  if v_new is not null then
    return jsonb_build_object('id', v_new, 'removed', '[]'::jsonb);
  end if;

  insert into public.tk_plans (
    plan_type, referat_id, title, community_reason, sport, target_groups, region, base, teaser, programme,
    image_source, image_credit, meet_time, end_time, meeting_point, meeting_coords, prebriefing, public_transport,
    travel_notes, accommodation, nights, co2_persons, meeting_near_pt, max_walk_hours, max_ascent, max_descent,
    max_distance_km, fitness, technique, grade, requirements, equipment, non_members_allowed, non_members_reason,
    min_participants, max_participants, waitlist, accommodation_cancellation, registration_questions, custom_question,
    days_full, days_half, teaching_hours, org_days, car_reason, no_fee, price_member, price_non_member, yolawo_by,
    notes_for_referat, feedback_form, touched, client_request_id)
  select plan_type, referat_id, title, community_reason, sport, target_groups, region, base, teaser, programme,
         image_source, image_credit, meet_time, end_time, meeting_point, meeting_coords, prebriefing, public_transport,
         travel_notes, accommodation, nights, co2_persons, meeting_near_pt, max_walk_hours, max_ascent, max_descent,
         max_distance_km, fitness, technique, grade, requirements, equipment, non_members_allowed, non_members_reason,
         min_participants, max_participants, waitlist, accommodation_cancellation, registration_questions,
         custom_question, days_full, days_half, teaching_hours, org_days, car_reason, no_fee, price_member,
         price_non_member, yolawo_by, notes_for_referat, feedback_form, touched, p_client_request_id
    from public.tk_plans where id = p_id
  returning id into v_new;

  insert into public.tk_plan_leaders (plan_id, person_id, role, sort_order)
  select v_new, l.person_id, l.role, row_number() over (order by l.sort_order)
    from public.tk_plan_leaders l
    join public.ea_persons e on e.id = l.person_id and e.volunteer_status = 'active'
   where l.plan_id = p_id;
  select coalesce(array_agg(coalesce(e.preferred_name, e.first_name) || ' ' || e.last_name order by l.sort_order), '{}')
    into v_removed
    from public.tk_plan_leaders l
    join public.ea_persons e on e.id = l.person_id
   where l.plan_id = p_id and e.volunteer_status is distinct from 'active';

  insert into public.tk_plan_legs (plan_id, sort_order, mode, label, km_one_way, persons, vehicles, round_trip)
  select v_new, sort_order, mode, label, km_one_way, persons, vehicles, round_trip
    from public.tk_plan_legs where plan_id = p_id;
  insert into public.tk_plan_costs (plan_id, cost_group, sort_order, label, quantity, unit_price, is_car, is_overnight,
                                    is_hut_half_board)
  select v_new, cost_group, sort_order, label, quantity, unit_price, is_car, is_overnight, is_hut_half_board
    from public.tk_plan_costs where plan_id = p_id;
  insert into public.tk_plan_history (plan_id, event, to_status, comment)
  values (v_new, 'copied', 'draft', left('Kopie von „' || v_src.title || '“', 500));

  perform public.tk_calculate(v_new);
  return jsonb_build_object('id', v_new, 'removed', to_jsonb(v_removed));
end;
$$;

revoke all on function public.tk_copy_plan(uuid, uuid) from public, anon, authenticated;
grant execute on function public.tk_copy_plan(uuid, uuid) to authenticated;

-- Löschen nur Geschäftsstelle, nur Entwurf oder abgesagt ohne Einsatz
create function public.tk_delete_plan(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan public.tk_plans%rowtype;
begin
  select * into v_plan from public.tk_plans p where p.id = p_id for update;
  if not found or not public.tk_can_read(v_plan.referat_id) then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if not public.tk_can_manage()
     or not (v_plan.status = 'draft' or (v_plan.status = 'cancelled' and v_plan.ez_event_id is null)) then
    raise exception 'TK_DELETE_FORBIDDEN' using errcode = 'P0001';
  end if;
  delete from public.tk_plans where id = p_id;
end;
$$;

revoke all on function public.tk_delete_plan(uuid) from public, anon, authenticated;
grant execute on function public.tk_delete_plan(uuid) to authenticated;
