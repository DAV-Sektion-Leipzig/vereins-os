-- Planungshilfe Touren und Kurse (TK), spec T5; spec.md TK v0.4 Abschnitt 2 (tk_calculate) und 5 (R1–R4, R6, R14,
-- R22), Prototyp 4.1–4.8; tasks.md T005. Maßgeblich ist das Ergebnis der Datenbank (R1); src/features/tk/calc.ts
-- rechnet gleich (plan.md P1, P2).

-- Satzstand einer Planung (R3): eingefroren in tk_plan_rates, sonst ad_rates_at(Beginn bzw. heute). Intern.
create function public.tk_rates(p_plan_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_start date;
  v_rates jsonb;
begin
  select coalesce(jsonb_object_agg(r.rate_key, jsonb_build_object(
           'label', r.label, 'value', r.value, 'percent', r.percent, 'fixed', r.fixed, 'active', r.active,
           'valid_from', r.valid_from)), '{}')
    into v_rates
    from public.tk_plan_rates r where r.plan_id = p_plan_id;
  if v_rates <> '{}' then
    return v_rates;
  end if;
  select coalesce(p.start_date, current_date) into v_start from public.tk_plans p where p.id = p_plan_id;
  select coalesce(jsonb_object_agg(r.rate_key, jsonb_build_object(
           'label', r.label, 'value', r.value, 'percent', r.percent, 'fixed', r.fixed, 'active', r.active,
           'valid_from', r.valid_from)), '{}')
    into v_rates
    from public.ad_rates_at(v_start) r
   where r.rate_group <> 'remuneration' or r.rate_key in ('rTL', 'rTLh', 'rH', 'rHh', 'rOrg', 'rLE');
  return v_rates;
end;
$$;

revoke all on function public.tk_rates(uuid) from public, anon, authenticated;

-- Wert eines Satzes; null, wenn nicht vorhanden
create function public.tk_rate(p_rates jsonb, p_key text)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select nullif(p_rates -> p_key ->> 'value', '')::numeric;
$$;

revoke all on function public.tk_rate(jsonb, text) from public, anon, authenticated;

-- Beitrag auf rRund aufrunden (R1): ceil(roh / rund − 1e−9) × rund
create function public.tk_round_up(p_value numeric, p_step numeric)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select case when p_value is null then null
              when coalesce(p_step, 0) <= 0 then ceil(p_value - 1e-9)
              else ceil(p_value / p_step - 1e-9) * p_step end;
$$;

revoke all on function public.tk_round_up(numeric, numeric) from public, anon, authenticated;

create function public.tk_calculate(p_plan_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.tk_plans%rowtype;
  v_rates jsonb;
  v_missing text[] := '{}';
  v_warn text[] := '{}';
  v_key text;
  v_days int := 0;
  v_hours numeric;
  v_is_course boolean;
  v_is_community boolean;
  v_lic jsonb := '[]';
  v_leader record;
  v_best jsonb;
  v_n_trainer int := 0;
  v_n_helper int := 0;
  v_n_leaders int := 0;
  v_df int;
  v_dh int;
  v_od int;
  v_th int;
  v_fee numeric := 0;
  v_org numeric := 0;
  v_leader_costs numeric := 0;
  v_fixed numeric := 0;
  v_var numeric := 0;
  v_self numeric := 0;
  v_total numeric := 0;
  v_vat numeric;
  v_rund numeric;
  v_min int;
  v_max int;
  v_free boolean;
  v_fee_method text;
  v_fp numeric := 0;
  v_ff numeric := 0;
  v_need numeric;
  v_raw numeric;
  v_sugg numeric;
  v_pm numeric;
  v_pn_sugg numeric;
  v_pn numeric;
  v_net numeric;
  v_contrib numeric;
  v_break int;
  v_res_min numeric;
  v_res_max numeric;
  v_fees_min numeric;
  v_mob numeric := 0;
  v_mob_car numeric := 0;
  v_stay numeric := 0;
  v_food numeric := 0;
  v_tour numeric;
  v_all numeric;
  v_ef numeric;
  v_leg record;
  v_kg numeric;
  v_lim numeric;
  v_co2_status text;
  v_g numeric;
  v_h numeric;
  v_fit public.tk_fitness;
  v_first_lead uuid;
  v_contact public.tk_plan_contacts%rowtype;
  v_lead_months numeric;
begin
  select * into p from public.tk_plans where id = p_plan_id;
  if not found then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  v_rates := public.tk_rates(p_plan_id);
  v_is_course := p.plan_type = 'course';
  v_is_community := p.plan_type = 'community_tour';

  -- 4.1 Tage und Stunden des ersten Tages
  if p.start_date is not null and p.end_date is not null then
    v_days := greatest((p.end_date - p.start_date) + 1, 0);
  end if;
  if p.meet_time is not null and p.end_time is not null and p.end_time > p.meet_time then
    v_hours := extract(epoch from (p.end_time - p.meet_time)) / 3600.0;
  end if;

  -- R2 Satzart der Leitung: Lizenz am Startdatum gültig oder im Halbjahr des Startdatums erworben (förderfähig)
  select count(*) into v_n_leaders from public.tk_plan_leaders l where l.plan_id = p_plan_id;
  if p.start_date is not null and v_n_leaders > 0 then
    select coalesce(jsonb_agg(to_jsonb(x)), '[]') into v_lic
      from public.ea_person_licenses(
             (select array_agg(l.person_id) from public.tk_plan_leaders l where l.plan_id = p_plan_id),
             p.start_date) x;
  end if;
  for v_leader in
    select l.* from public.tk_plan_leaders l where l.plan_id = p_plan_id order by l.sort_order
  loop
    v_best := null;
    if v_leader.role <> 'helper' and p.start_date is not null then
      select e into v_best
        from jsonb_array_elements(v_lic) e
       where (e ->> 'person_id')::uuid = v_leader.person_id
         and (e ->> 'is_fundable')::boolean
       order by (e ->> 'valid_on_date')::boolean desc, (e ->> 'valid_until')::date desc nulls first
       limit 1;
    end if;
    update public.tk_plan_leaders
       set rate_kind = case when v_best is null then 'helper'::public.tk_rate_kind else 'trainer' end,
           license_type_id = (v_best ->> 'qualification_type_id')::uuid,
           license_valid_from = (v_best ->> 'valid_from')::date,
           license_valid_until = (v_best ->> 'valid_until')::date
     where id = v_leader.id;
    if v_best is null then
      v_n_helper := v_n_helper + 1;
      if v_leader.role <> 'helper' and p.start_date is not null and not v_is_community then
        v_warn := v_warn || 'helper_rate'::text;
      end if;
    else
      v_n_trainer := v_n_trainer + 1;
      if not v_is_community then
        if (v_best ->> 'valid_until')::date < p.end_date then
          v_warn := v_warn || 'license_expires_during'::text;
        end if;
        if not (v_best ->> 'valid_on_date')::boolean then
          v_warn := v_warn || 'license_acquired_in_half'::text;
        end if;
      end if;
    end if;
  end loop;
  if p.start_date is null and exists (
       select 1 from public.tk_plan_leaders l where l.plan_id = p_plan_id and l.role <> 'helper') then
    v_warn := v_warn || 'rate_kind_no_start'::text;
  end if;

  -- 4.2 Vorschläge für Felder, die nicht in touched stehen
  v_df := coalesce(p.days_full, 0);
  v_dh := coalesce(p.days_half, 0);
  v_od := coalesce(p.org_days, 0);
  v_th := p.teaching_hours;
  if not ('days_full' = any (p.touched)) then
    v_df := case when v_days > 1 then v_days when v_days = 1 then (case when v_hours >= 8 then 1 else 0 end) else 0 end;
  end if;
  if not ('days_half' = any (p.touched)) then
    v_dh := case when v_days = 1 then 1 - v_df else 0 end;
  end if;
  if not ('org_days' = any (p.touched)) then
    v_od := case when v_days > 1 then v_days else 0 end;
  end if;
  -- R22: Lehreinheiten nur bei eintägigem Kurs vorgeschlagen
  if v_is_course and not ('teaching_hours' = any (p.touched)) and v_days = 1 and v_hours is not null then
    v_th := greatest(floor(v_hours), 0)::int;
  end if;
  update public.tk_plans
     set days_full = v_df, days_half = v_dh, org_days = v_od, teaching_hours = v_th,
         nights = case when 'nights' = any (p.touched) then p.nights
                       when p.accommodation = 'none' then 0 else greatest(v_days - 1, 0) end,
         co2_persons = case when 'co2_persons' = any (p.touched) then p.co2_persons
                            when coalesce(p.max_participants, 0) > 0
                              then p.max_participants + greatest(v_n_leaders, 1)
                            else p.co2_persons end
   where id = p_plan_id
  returning * into p;

  -- 4.3 Vergütung, R4 Gemeinschaftstour, R22 Kurs
  if v_is_community then
    v_fee := 0;
    v_org := coalesce(p.org_days, 0) * coalesce(public.tk_rate(v_rates, 'rOrg'), 0);
  elsif v_is_course then
    v_fee := v_n_trainer * coalesce(p.teaching_hours, 0) * coalesce(public.tk_rate(v_rates, 'rLE'), 0);
    v_org := 0;
  else
    v_fee := v_n_trainer * (coalesce(p.days_full, 0) * coalesce(public.tk_rate(v_rates, 'rTL'), 0)
                           + coalesce(p.days_half, 0) * coalesce(public.tk_rate(v_rates, 'rTLh'), 0))
           + v_n_helper * (coalesce(p.days_full, 0) * coalesce(public.tk_rate(v_rates, 'rH'), 0)
                           + coalesce(p.days_half, 0) * coalesce(public.tk_rate(v_rates, 'rHh'), 0));
    v_org := coalesce(p.org_days, 0) * coalesce(public.tk_rate(v_rates, 'rOrg'), 0);
  end if;

  -- 4.4 Kosten
  select coalesce(sum(c.quantity * c.unit_price) filter (where c.cost_group = 'leader'), 0),
         coalesce(sum(c.quantity * c.unit_price) filter (where c.cost_group = 'fixed'), 0),
         coalesce(sum(c.quantity * c.unit_price) filter (where c.cost_group = 'per_participant'), 0),
         coalesce(sum(c.quantity * c.unit_price) filter (where c.cost_group = 'self_paid'), 0)
    into v_leader_costs, v_fixed, v_var, v_self
    from public.tk_plan_costs c where c.plan_id = p_plan_id;
  if v_is_community then
    v_leader_costs := 0;
    v_fixed := 0;
    v_var := 0;
  end if;
  v_total := v_fee + v_org + v_leader_costs + v_fixed;

  -- 4.5 Teilnahmebeitrag
  v_free := v_is_community
            or (p.no_fee and v_days = 1 and 'Familienwanderungen' = any (p.target_groups));
  if p.no_fee and not v_free then
    v_warn := v_warn || 'no_fee_not_allowed'::text;
  end if;
  v_vat := coalesce(public.tk_rate(v_rates, 'rVat'), 0) / 100;
  v_rund := coalesce(public.tk_rate(v_rates, 'rRund'), 1);
  v_min := p.min_participants;
  v_max := p.max_participants;
  -- teuerste aktive Zahlmethode (größter Bedarf); ohne Mindestanzahl mit 1 gewählt
  select k, pp, ff, need into v_fee_method, v_fp, v_ff, v_need
    from (
      select e.key as k,
             (e.value ->> 'percent')::numeric / 100 * (1 + v_vat) as pp,
             (e.value ->> 'fixed')::numeric * (1 + v_vat) as ff
        from jsonb_each(v_rates) e
       where e.key like 'fee\_%' and coalesce((e.value ->> 'active')::boolean, false)
         and e.value ->> 'percent' is not null
    ) m
    cross join lateral (
      select (v_total / greatest(coalesce(v_min, 1), 1) + v_var + m.ff) / (1 - m.pp) as need
    ) n
   order by need desc, k
   limit 1;
  if v_fee_method is null then
    v_fp := 0;
    v_ff := 0;
  end if;
  if coalesce(v_min, 0) > 0 then
    v_raw := (v_total / v_min + v_var + v_ff) / (1 - v_fp);
  end if;
  v_sugg := case when v_free then 0 else public.tk_round_up(v_raw, v_rund) end;
  v_pm := case when v_free then 0 else coalesce(p.price_member, v_sugg) end;
  if p.non_members_allowed and not v_free and v_pm is not null then
    v_pn_sugg := public.tk_round_up(v_pm * (1 + coalesce(public.tk_rate(v_rates, 'rNM'), 0) / 100), v_rund);
    v_pn := coalesce(p.price_non_member, v_pn_sugg);
  end if;
  if v_pm is not null then
    v_net := case when v_pm <= 0 then 0 else v_pm * (1 - v_fp) - v_ff end;
    v_contrib := v_net - v_var;
    if v_contrib > 0 then
      v_break := ceil(v_total / v_contrib - 1e-9)::int;
    end if;
    if v_min is not null then
      v_res_min := v_min * v_contrib - v_total;
      v_fees_min := v_min * (v_pm - v_net);
    end if;
    if v_max is not null then
      v_res_max := v_max * v_contrib - v_total;
    end if;
  end if;
  if not v_free and p.price_member is not null and v_sugg is not null and p.price_member < v_sugg then
    v_warn := v_warn || 'price_below_suggestion'::text;
  end if;

  -- 4.7 CO2
  for v_leg in select * from public.tk_plan_legs g where g.plan_id = p_plan_id order by g.sort_order loop
    v_ef := coalesce(public.tk_rate(v_rates, 'ef_' || v_leg.mode::text), 0);
    v_kg := v_leg.km_one_way * (case when v_leg.round_trip then 2 else 1 end)
            * (case when v_leg.mode in ('car', 'ecar', 'van') then v_leg.vehicles else v_leg.persons end) * v_ef / 1000;
    v_mob := v_mob + v_kg;
    if v_leg.mode in ('car', 'ecar', 'van', 'flight') then
      v_mob_car := v_mob_car + v_kg;
    end if;
    if v_leg.mode = 'flight' and v_leg.km_one_way > 0
       and v_leg.km_one_way < coalesce(public.tk_rate(v_rates, 'flight_min_km'), 0) then
      v_warn := v_warn || 'flight_short'::text;
    end if;
    if v_leg.mode in ('car', 'ecar', 'van') and v_leg.vehicles > 0 and v_leg.persons::numeric / v_leg.vehicles < 3 then
      v_warn := v_warn || 'car_pooling'::text;
    end if;
    v_lim := coalesce(public.tk_rate(v_rates, 'rKmTag1'), 0) + greatest(v_days - 1, 0) * coalesce(public.tk_rate(v_rates, 'rKmTagN'), 0);
    if v_leg.mode in ('car', 'ecar', 'van') and v_lim > 0 and v_leg.km_one_way > v_lim then
      v_warn := v_warn || 'car_over_guideline'::text;
    end if;
  end loop;
  if p.accommodation <> 'none' then
    v_stay := coalesce(p.nights, 0) * coalesce(p.co2_persons, 0)
              * coalesce(public.tk_rate(v_rates, case p.accommodation when 'hut' then 'ef_stay_hut'
                                                  when 'self_catering' then 'ef_stay_self_catering'
                                                  when 'hotel' then 'ef_stay_hotel' else 'ef_stay_camping' end), 0);
  end if;
  if v_days > 0 then
    v_food := coalesce(p.co2_persons, 0) * v_days
              * coalesce(public.tk_rate(v_rates, case when coalesce(p.nights, 0) > 0 then 'ef_food_overnight'
                                                      else 'ef_food_day' end), 0);
  end if;
  v_tour := v_mob + v_food + (case when p.accommodation = 'hut' then 0 else v_stay end);
  v_all := v_mob + v_stay + v_food;
  if p.accommodation = 'hut' and v_stay > 0 then
    v_warn := v_warn || 'hut_stay_excluded'::text;
  end if;
  v_co2_status := case
    when not exists (select 1 from public.tk_plan_legs g where g.plan_id = p_plan_id and g.km_one_way > 0) then 'missing'
    when v_mob <= 0 or v_mob_car / v_mob < 0.25 then 'mostly_pt'
    when v_mob_car / v_mob < 0.5 then 'mixed'
    else 'mostly_car_flight' end;

  -- 4.8 Kondition
  v_g := coalesce(p.max_walk_hours, 0);
  v_h := greatest(coalesce(p.max_ascent, 0), coalesce(p.max_descent, 0));
  if v_g > 0 or v_h > 0 then
    v_fit := case when v_g > 8 or v_h > 1500 then 'very_high'
                  when v_g > 6 or v_h > 1000 then 'high'
                  when v_g > 4 or v_h > 500 then 'medium'
                  else 'low' end;
    if p.fitness is not null and p.fitness <> v_fit then
      v_warn := v_warn || 'fitness_differs'::text;
    end if;
  end if;

  -- 6.2/6.3 weitere Warnungen (R6: Kennzeichen statt Texterkennung, Grenzwerte aus den Sätzen)
  if v_min is not null and v_max is not null and v_min > v_max then
    v_warn := v_warn || 'min_gt_max'::text;
  end if;
  if p.registration_deadline is not null and p.start_date is not null and p.registration_deadline >= p.start_date then
    v_warn := v_warn || 'deadline_not_before_start'::text;
  end if;
  v_lead_months := public.tk_rate(v_rates, 'planning_lead_months');
  if p.start_date is not null and v_lead_months is not null and p.status = 'draft'
     and p.start_date < current_date + (v_lead_months * 30.4)::int then
    v_warn := v_warn || 'lead_time_short'::text;
  end if;
  if not v_is_community then
    if (select coalesce(sum(c.quantity), 0) from public.tk_plan_costs c
         where c.plan_id = p_plan_id and c.cost_group = 'leader' and c.is_car)
       > coalesce(public.tk_rate(v_rates, 'car_permit_km'), 'infinity'::numeric) then
      v_warn := v_warn || 'car_permit'::text;
    end if;
    if exists (select 1 from public.tk_plan_costs c
                where c.plan_id = p_plan_id and c.cost_group = 'leader' and c.is_overnight
                  and c.unit_price > coalesce(public.tk_rate(v_rates, 'rUe'), 'infinity'::numeric)) then
      v_warn := v_warn || 'overnight_over_limit'::text;
    end if;
    if p.accommodation = 'hut' and coalesce(v_min, 0) >= 5 and exists (
         select 1 from public.tk_plan_costs c
          where c.plan_id = p_plan_id and c.cost_group = 'leader' and c.is_overnight and c.unit_price > 0) then
      v_warn := v_warn || 'hut_free_place'::text;
    end if;
  end if;
  if exists (select 1 from public.tk_plan_costs c
              where c.plan_id = p_plan_id and c.cost_group = 'self_paid' and c.is_hut_half_board
                and (c.unit_price < coalesce(public.tk_rate(v_rates, 'hut_hp_min'), 0)
                     or c.unit_price > coalesce(public.tk_rate(v_rates, 'hut_hp_max'), 'infinity'::numeric))) then
    v_warn := v_warn || 'hut_hp_price'::text;
  end if;
  -- Qualifikation deckt Sportart (C3, nur Hinweis)
  if not v_is_community and p.sport is not null and p.sport <> 'Sonstiges'
     and exists (select 1 from public.tk_plan_leaders l where l.plan_id = p_plan_id and l.role <> 'helper')
     and not exists (
       select 1
         from public.tk_plan_leaders l
         join jsonb_array_elements(v_lic) e on (e ->> 'person_id')::uuid = l.person_id
         join public.tk_qualification_sports qs on qs.qualification_type_id = (e ->> 'qualification_type_id')::uuid
        where l.plan_id = p_plan_id and l.role <> 'helper' and qs.sport = p.sport) then
    v_warn := v_warn || 'sport_not_covered'::text;
  end if;

  -- R6 Pflichtangaben (Prototyp 6.1 ohne PDF-Punkte; Schlüssel = Feldname)
  if v_is_community and p.community_reason is null then v_missing := v_missing || 'community_reason'::text; end if;
  if not exists (select 1 from public.tk_plan_leaders l where l.plan_id = p_plan_id and l.role = 'lead') then
    v_missing := v_missing || 'leader'::text;
  end if;
  if p.contacts_purged_at is null then
    select l.id into v_first_lead from public.tk_plan_leaders l
     where l.plan_id = p_plan_id and l.role = 'lead' order by l.sort_order limit 1;
    if v_first_lead is not null then
      select * into v_contact from public.tk_plan_contacts c where c.leader_id = v_first_lead;
      if v_contact.email is null then v_missing := v_missing || 'contact_email'::text; end if;
      if v_contact.emergency_name is null then v_missing := v_missing || 'emergency_name'::text; end if;
      if v_contact.emergency_phone is null then v_missing := v_missing || 'emergency_phone'::text; end if;
    end if;
  end if;
  if p.sport is null then v_missing := v_missing || 'sport'::text; end if;
  if p.region is null then v_missing := v_missing || 'region'::text; end if;
  if p.teaser is null then v_missing := v_missing || 'teaser'::text; end if;
  if p.image_source is null then v_missing := v_missing || 'image_source'::text; end if;
  if p.image_source = 'own' and p.image_credit is null then v_missing := v_missing || 'image_credit'::text; end if;
  if p.start_date is null then v_missing := v_missing || 'start_date'::text; end if;
  if p.meet_time is null then v_missing := v_missing || 'meet_time'::text; end if;
  if p.end_date is null then v_missing := v_missing || 'end_date'::text; end if;
  if p.meeting_point is null then v_missing := v_missing || 'meeting_point'::text; end if;
  if p.public_transport is null then v_missing := v_missing || 'public_transport'::text; end if;
  if not exists (
       select 1 from public.tk_plan_legs g
        where g.plan_id = p_plan_id and g.km_one_way > 0
          and (case when g.mode in ('car', 'ecar', 'van') then g.vehicles else g.persons end) > 0) then
    v_missing := v_missing || 'travel_legs'::text;
  end if;
  if p.fitness is null then v_missing := v_missing || 'fitness'::text; end if;
  if p.technique is null then v_missing := v_missing || 'technique'::text; end if;
  if p.requirements is null then v_missing := v_missing || 'requirements'::text; end if;
  if p.non_members_allowed and not v_is_community and p.non_members_reason is null then
    v_missing := v_missing || 'non_members_reason'::text;
  end if;
  if p.equipment is null then v_missing := v_missing || 'equipment'::text; end if;
  if p.min_participants is null then v_missing := v_missing || 'min_participants'::text; end if;
  if p.max_participants is null then v_missing := v_missing || 'max_participants'::text; end if;
  if p.registration_deadline is null then v_missing := v_missing || 'registration_deadline'::text; end if;
  if v_is_course and v_days > 1 and coalesce(p.teaching_hours, 0) = 0 then
    v_missing := v_missing || 'teaching_hours'::text;
  end if;
  if not v_is_community and p.car_reason is null and exists (
       select 1 from public.tk_plan_costs c where c.plan_id = p_plan_id and c.cost_group = 'leader' and c.is_car) then
    v_missing := v_missing || 'car_reason'::text;
  end if;
  if not v_is_community then
    if not p.confirm_license then v_missing := v_missing || 'confirm_license'::text; end if;
    if not p.confirm_calculation then v_missing := v_missing || 'confirm_calculation'::text; end if;
    if not p.confirm_ul_declaration then v_missing := v_missing || 'confirm_ul_declaration'::text; end if;
  end if;
  if not p.confirm_emergency_card then v_missing := v_missing || 'confirm_emergency_card'::text; end if;
  -- R3 fehlender Satz
  foreach v_key in array array['rTL', 'rTLh', 'rH', 'rHh', 'rOrg', 'rLE', 'rNM', 'rRund', 'rVat', 'rCO2'] loop
    if public.tk_rate(v_rates, v_key) is null then
      v_missing := v_missing || ('rate:' || v_key);
    end if;
  end loop;
  for v_key in
    select distinct 'ef_' || g.mode::text from public.tk_plan_legs g where g.plan_id = p_plan_id
  loop
    if public.tk_rate(v_rates, v_key) is null then
      v_missing := v_missing || ('rate:' || v_key);
    end if;
  end loop;
  if exists (select 1 from unnest(v_missing) m where m like 'rate:%') then
    v_warn := v_warn || 'rates_missing'::text;
  end if;

  insert into public.tk_plan_results as r (
    plan_id, days, hours_day1, fee_total, org_total, leader_costs, fixed_costs, per_participant_costs,
    self_paid_per_participant, total_costs, fee_method, price_raw, price_suggested, price_member_effective,
    price_non_member_suggested, price_non_member_effective, net_per_participant, contribution_per_participant,
    break_even, result_min, result_max, fees_at_min, is_free, section_bears, co2_mobility_kg, co2_stay_kg,
    co2_food_kg, co2_tour_kg, co2_all_kg, co2_per_person_kg, co2_per_person_day_kg, climate_budget_eur, co2_status,
    fitness_suggested, rates_valid_on, missing, warnings, calculated_at)
  values (
    p_plan_id, v_days, round(v_hours, 2), round(v_fee, 2), round(v_org, 2), round(v_leader_costs, 2),
    round(v_fixed, 2), round(v_var, 2), round(v_self, 2), round(v_total, 2), v_fee_method, round(v_raw, 4), v_sugg,
    round(v_pm, 2), v_pn_sugg, round(v_pn, 2), round(v_net, 4), round(v_contrib, 4), v_break,
    round(v_res_min, 2), round(v_res_max, 2), round(v_fees_min, 2), v_free,
    case when v_free then round(v_total, 2) else 0 end,
    round(v_mob, 2), round(v_stay, 2), round(v_food, 2), round(v_tour, 2), round(v_all, 2),
    case when coalesce(p.co2_persons, 0) > 0 then round(v_all / p.co2_persons, 2) end,
    case when coalesce(p.co2_persons, 0) > 0 and v_days > 0 then round(v_all / p.co2_persons / v_days, 2) end,
    round(v_tour / 1000 * coalesce(public.tk_rate(v_rates, 'rCO2'), 0), 2), v_co2_status, v_fit,
    coalesce(p.start_date, current_date),
    v_missing, (select coalesce(array_agg(distinct w order by w), '{}') from unnest(v_warn) w), now())
  on conflict (plan_id) do update set
    days = excluded.days, hours_day1 = excluded.hours_day1, fee_total = excluded.fee_total,
    org_total = excluded.org_total, leader_costs = excluded.leader_costs, fixed_costs = excluded.fixed_costs,
    per_participant_costs = excluded.per_participant_costs,
    self_paid_per_participant = excluded.self_paid_per_participant, total_costs = excluded.total_costs,
    fee_method = excluded.fee_method, price_raw = excluded.price_raw, price_suggested = excluded.price_suggested,
    price_member_effective = excluded.price_member_effective,
    price_non_member_suggested = excluded.price_non_member_suggested,
    price_non_member_effective = excluded.price_non_member_effective,
    net_per_participant = excluded.net_per_participant,
    contribution_per_participant = excluded.contribution_per_participant, break_even = excluded.break_even,
    result_min = excluded.result_min, result_max = excluded.result_max, fees_at_min = excluded.fees_at_min,
    is_free = excluded.is_free, section_bears = excluded.section_bears, co2_mobility_kg = excluded.co2_mobility_kg,
    co2_stay_kg = excluded.co2_stay_kg, co2_food_kg = excluded.co2_food_kg, co2_tour_kg = excluded.co2_tour_kg,
    co2_all_kg = excluded.co2_all_kg, co2_per_person_kg = excluded.co2_per_person_kg,
    co2_per_person_day_kg = excluded.co2_per_person_day_kg, climate_budget_eur = excluded.climate_budget_eur,
    co2_status = excluded.co2_status, fitness_suggested = excluded.fitness_suggested,
    rates_valid_on = excluded.rates_valid_on, missing = excluded.missing, warnings = excluded.warnings,
    calculated_at = excluded.calculated_at;
end;
$$;

revoke all on function public.tk_calculate(uuid) from public, anon, authenticated;
