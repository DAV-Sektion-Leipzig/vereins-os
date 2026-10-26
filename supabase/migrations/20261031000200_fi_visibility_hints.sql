-- Finanzen (FI), spec T2; R11–R14, R17, R31, R56: Ersatz der Platzhalter fi_person_visible (Administration),
-- fi_attendance_locked und fi_event_locked (Anwesenheitserfassung); interne Hinweise je Abrechnung.
-- Die Hinweise liefern Referent:innen nur Ja/Nein-Werte, nie Bankverbindung oder Nachweisdaten (R31, R55).

create or replace function public.fi_person_visible(p_person uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.fi_settlements s
                  where s.person_id = p_person and public.fi_can_read_settlement(s.id));
$$;

create or replace function public.fi_attendance_locked(p_attendance uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1
                   from public.fi_settlement_items i
                   join public.fi_settlements s on s.id = i.settlement_id
                  where i.attendance_id = p_attendance
                    and s.status in ('closed', 'submitted', 'expired', 'paid'));
$$;

create or replace function public.fi_event_locked(p_event uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1
                   from public.fi_settlement_items i
                   join public.fi_settlements s on s.id = i.settlement_id
                  where i.event_id = p_event
                    and s.status in ('closed', 'submitted', 'expired', 'paid'));
$$;

-- Voraussetzungen der Auszahlung einer Person (R12–R14) als Ja/Nein; intern, ohne Rechteprüfung
create function public.fi_person_flags(p_person uuid, p_year int)
returns table (has_bank boolean, has_agreement boolean, has_tax_confirmation boolean, bank_check text)
language sql
stable
security definer
set search_path = ''
as $$
  select ba.iban is not null,
         exists (select 1 from public.ea_properties a
                   join public.ea_property_types t on t.id = a.property_type_id
                  where t.system_key = 'trainer_agreement' and a.person_id = p_person
                    and a.valid_from <= current_date and (a.valid_to is null or a.valid_to >= current_date)
                    and coalesce((a.field_values ->> 'signed')::boolean, false)),
         exists (select 1 from public.ea_properties c
                   join public.ea_property_types t on t.id = c.property_type_id
                  where t.system_key = 'tax_free_confirmation' and c.person_id = p_person
                    and (nullif(c.field_values ->> 'year', '') is null
                         or nullif(c.field_values ->> 'year', '')::int = p_year)),
         case when ba.iban is null then null else md5(ba.iban) end
    from (select (select b.field_values ->> 'iban'
                    from public.ea_properties b
                    join public.ea_property_types t on t.id = b.property_type_id
                   where t.system_key = 'bank_account' and b.person_id = p_person
                     and b.valid_from <= current_date and (b.valid_to is null or b.valid_to >= current_date)
                   order by b.valid_from desc
                   limit 1) as iban) ba;
$$;

revoke all on function public.fi_person_flags(uuid, int) from public, anon, authenticated;

-- Hinweise, Höchstbetrag und Auszahlbarkeit einer Abrechnung (R11–R14); intern
create function public.fi_settlement_info(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_s public.fi_settlements%rowtype;
  v_flags record;
  v_year int;
  v_total numeric;
  v_limit numeric;
  v_hints text[] := '{}';
  v_reasons text[] := '{}';
begin
  select * into v_s from public.fi_settlements s where s.id = p_id;
  if not found then
    return null;
  end if;
  select * into v_flags from public.fi_person_flags(v_s.person_id, v_s.year);

  -- Auszahlungsjahr (Zuflussprinzip, R11): ausgezahlt → Jahr der Ausführung, sonst Jahr der Abgabefrist (= Jahr des Halbjahres)
  select coalesce(extract(year from r.execution_date)::int, v_s.year) into v_year
    from (select 1) x left join public.fi_payout_runs r on r.id = v_s.payout_run_id and r.status = 'released';
  select coalesce(sum(s.amount), 0) into v_total
    from public.fi_settlements s
    left join public.fi_payout_runs r on r.id = s.payout_run_id and r.status = 'released'
   where s.person_id = v_s.person_id
     and (s.status in ('closed', 'submitted', 'paid') or s.id = p_id)
     and coalesce(extract(year from r.execution_date)::int, s.year) = v_year;
  select r.value into v_limit
    from public.ad_rates r
   where r.rate_key = 'maxUeL' and r.valid_from <= make_date(v_year, 12, 31)
   order by r.valid_from desc
   limit 1;

  if not v_flags.has_tax_confirmation then
    v_hints := v_hints || 'no_tax_confirmation';
    v_reasons := v_reasons || 'no_tax_confirmation';
  end if;
  if not v_flags.has_bank then
    v_hints := v_hints || 'no_bank_account';
    v_reasons := v_reasons || 'no_bank_account';
  end if;
  if not v_flags.has_agreement then
    v_hints := v_hints || 'no_trainer_agreement';
    v_reasons := v_reasons || 'no_trainer_agreement';
  end if;
  if v_limit is not null and v_total > v_limit then
    v_hints := v_hints || 'max_exceeded';
  end if;
  if v_s.has_new_events then
    v_hints := v_hints || 'has_new_events';
  end if;
  v_hints := v_hints || array(
    select distinct h::text from public.fi_settlement_items i, unnest(i.hints) as h where i.settlement_id = p_id);
  if v_s.amount <= 0 then
    v_reasons := v_reasons || 'amount_zero';
  end if;

  return jsonb_build_object(
    'hints', to_jsonb(array(select distinct x from unnest(v_hints) as x order by x)),
    'max', jsonb_build_object('year', v_year, 'total', v_total, 'limit', v_limit),
    'payable', cardinality(v_reasons) = 0,
    'not_payable_reasons', to_jsonb(v_reasons),
    'bank_check', v_flags.bank_check);
end;
$$;

revoke all on function public.fi_settlement_info(uuid) from public, anon, authenticated;
