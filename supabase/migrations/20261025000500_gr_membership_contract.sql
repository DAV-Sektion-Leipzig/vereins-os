-- US-GR-08, US-GR-11, spec T5 (GR spec.md 2.1, 2.3): Teilnahme nur mit Vertrag (R16), Folgevertrag (R8a), Vertrag
-- ändern und kündigen (R8, R8b), „Teilnahme bis“. Vertragsprüfung R4–R6, R27. security definer; GR ≥ edit zuerst.

-- Vertragsangaben prüfen und normalisiert zurückgeben; p_contract_id = eigener Vertrag (für R6 beim Ändern); intern
create function public.gr_check_contract(p_child uuid, p_contract jsonb, p_contract_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_key text;
  v_holder uuid;
  v_starts date;
  v_signed date;
  v_amount numeric;
  v_iban text;
  v_mandate text := public.gr_text(p_contract, 'mandate_reference');
  v_account text := public.gr_text(p_contract, 'account_holder');
  v_purpose text := public.gr_text(p_contract, 'purpose');
begin
  foreach v_key in array array['holder_person_id', 'starts_on', 'account_holder', 'iban', 'mandate_reference',
                               'mandate_signed_on', 'purpose', 'monthly_amount'] loop
    if public.gr_text(p_contract, v_key) is null then
      raise exception 'GR_CONTRACT_FIELDS_REQUIRED' using errcode = 'P0001';
    end if;
  end loop;

  begin
    v_holder := (p_contract ->> 'holder_person_id')::uuid;
    v_starts := (p_contract ->> 'starts_on')::date;
    v_signed := (p_contract ->> 'mandate_signed_on')::date;
  exception when others then
    raise exception 'GR_CONTRACT_FIELDS_REQUIRED' using errcode = 'P0001';
  end;
  begin
    v_amount := (p_contract ->> 'monthly_amount')::numeric;
  exception when others then
    raise exception 'GR_AMOUNT_INVALID' using errcode = 'P0001';
  end;

  -- R4: erziehungsberechtigt oder volljährige Teilnehmer:in selbst (am Vertragsbeginn)
  if not exists (select 1 from public.gr_guardians g
                  where g.child_person_id = p_child and g.guardian_person_id = v_holder)
     and not (v_holder = p_child and public.gr_is_adult(p_child, v_starts)) then
    raise exception 'GR_HOLDER_INVALID' using errcode = 'P0001';
  end if;

  -- R5
  v_iban := public.ea_iban_normalize(p_contract ->> 'iban');
  if not public.ea_iban_valid(v_iban) then
    raise exception 'GR_IBAN_INVALID' using errcode = 'P0001';
  end if;

  -- R27
  if char_length(v_mandate) > 35 or v_mandate !~ '^[A-Za-z0-9+?/:().,'' -]+$' then
    raise exception 'GR_MANDATE_FORMAT' using errcode = 'P0001';
  end if;
  if char_length(v_account) > 70 then
    raise exception 'GR_TEXT_TOO_LONG' using errcode = 'P0001', detail = '70';
  end if;
  if char_length(v_purpose) > 140 then
    raise exception 'GR_TEXT_TOO_LONG' using errcode = 'P0001', detail = '140';
  end if;
  if v_amount <= 0 then
    raise exception 'GR_AMOUNT_INVALID' using errcode = 'P0001';
  end if;
  if v_signed > public.gr_today() then
    raise exception 'GR_DATE_IN_FUTURE' using errcode = 'P0001';
  end if;

  -- R6: eindeutig über alle Verträge, auch beendete
  if exists (select 1 from public.gr_contracts c
              where lower(c.mandate_reference) = lower(v_mandate) and c.id is distinct from p_contract_id) then
    raise exception 'GR_MANDATE_TAKEN' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'holder_person_id', v_holder, 'starts_on', v_starts, 'account_holder', v_account, 'iban', v_iban,
    'mandate_reference', v_mandate, 'mandate_signed_on', v_signed, 'purpose', v_purpose,
    'monthly_amount', round(v_amount, 2));
end;
$$;

-- Teilnahme der Funktion: vorhanden und Person im Pfad GR mit edit sichtbar; intern
create function public.gr_check_membership(p_membership uuid)
returns public.gr_memberships
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_m public.gr_memberships%rowtype;
begin
  select * into v_m from public.gr_memberships m where m.id = p_membership;
  if not found or not public.gr_person_visible(v_m.person_id, 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  return v_m;
end;
$$;

-- Vertrag einfügen; intern
create function public.gr_insert_contract(p_membership uuid, p_values jsonb)
returns uuid
language sql
security definer
set search_path = ''
as $$
  insert into public.gr_contracts (membership_id, holder_person_id, starts_on, account_holder, iban,
                                   mandate_reference, mandate_signed_on, purpose, monthly_amount)
  values (p_membership, (p_values ->> 'holder_person_id')::uuid, (p_values ->> 'starts_on')::date,
          p_values ->> 'account_holder', p_values ->> 'iban', p_values ->> 'mandate_reference',
          (p_values ->> 'mandate_signed_on')::date, p_values ->> 'purpose', (p_values ->> 'monthly_amount')::numeric)
  returning id;
$$;

revoke all on function public.gr_check_contract(uuid, jsonb, uuid) from public, anon, authenticated;
revoke all on function public.gr_check_membership(uuid) from public, anon, authenticated;
revoke all on function public.gr_insert_contract(uuid, jsonb) from public, anon, authenticated;

-- Teilnahme und Vertrag in einer Transaktion (R16); löscht die offene Aufnahme für diese Gruppe
create function public.gr_admit(p_person uuid, p_group uuid, p_joined_on date, p_contract jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_values jsonb;
  v_membership uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(p_group);
  if not public.gr_person_visible(p_person, 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_contract is null or jsonb_typeof(p_contract) <> 'object' or p_contract = '{}' then
    raise exception 'GR_CONTRACT_REQUIRED' using errcode = 'P0001';
  end if;
  if p_joined_on is null then
    raise exception 'GR_CONTRACT_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  -- R10: keine überschneidende Teilnahme an derselben Gruppe
  if exists (select 1 from public.gr_memberships m
              where m.person_id = p_person and m.group_id = p_group
                and (m.left_on is null or m.left_on >= p_joined_on)) then
    raise exception 'GR_ALREADY_MEMBER' using errcode = 'P0001';
  end if;

  v_values := public.gr_check_contract(p_person, p_contract);

  insert into public.gr_memberships (group_id, person_id, joined_on)
  values (p_group, p_person, p_joined_on)
  returning id into v_membership;
  perform public.gr_insert_contract(v_membership, v_values);
  delete from public.gr_pending_admissions where person_id = p_person and group_id = p_group;
  return v_membership;
end;
$$;

-- Folgevertrag (R8a)
create function public.gr_add_contract(p_membership uuid, p_contract jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_m public.gr_memberships%rowtype;
  v_values jsonb;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_m := public.gr_check_membership(p_membership);
  if p_contract is null or jsonb_typeof(p_contract) <> 'object' then
    raise exception 'GR_CONTRACT_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  v_values := public.gr_check_contract(v_m.person_id, p_contract);
  if exists (select 1 from public.gr_contracts c where c.membership_id = p_membership and c.ends_on is null)
     or (v_values ->> 'starts_on')::date <= (select max(c.ends_on) from public.gr_contracts c
                                              where c.membership_id = p_membership) then
    raise exception 'GR_CONTRACT_EXISTS' using errcode = 'P0001';
  end if;
  return public.gr_insert_contract(p_membership, v_values);
end;
$$;

-- Vertrag ändern: Inhaber:in, Kontoinhaber:in, IBAN, Mandatsreferenz, Unterschriftsdatum, Verwendungszweck, Betrag
create function public.gr_update_contract(p_contract uuid, p_data jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_c public.gr_contracts%rowtype;
  v_m public.gr_memberships%rowtype;
  v_merged jsonb;
  v_values jsonb;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_c from public.gr_contracts c where c.id = p_contract;
  if not found then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_m := public.gr_check_membership(v_c.membership_id);

  v_merged := jsonb_build_object(
    'holder_person_id', v_c.holder_person_id, 'starts_on', v_c.starts_on, 'account_holder', v_c.account_holder,
    'iban', v_c.iban, 'mandate_reference', v_c.mandate_reference, 'mandate_signed_on', v_c.mandate_signed_on,
    'purpose', v_c.purpose, 'monthly_amount', v_c.monthly_amount)
    || (select coalesce(jsonb_object_agg(e.key, e.value), '{}')
          from jsonb_each(coalesce(p_data, '{}')) e
         where e.key in ('holder_person_id', 'account_holder', 'iban', 'mandate_reference', 'mandate_signed_on',
                         'purpose', 'monthly_amount'));
  v_values := public.gr_check_contract(v_m.person_id, v_merged, p_contract);

  update public.gr_contracts
     set holder_person_id = (v_values ->> 'holder_person_id')::uuid,
         account_holder = v_values ->> 'account_holder',
         iban = v_values ->> 'iban',
         mandate_reference = v_values ->> 'mandate_reference',
         mandate_signed_on = (v_values ->> 'mandate_signed_on')::date,
         purpose = v_values ->> 'purpose',
         monthly_amount = (v_values ->> 'monthly_amount')::numeric
   where id = p_contract;
end;
$$;

-- Kündigen bzw. Vertragsende ändern (R8, R8b); optional endet die Teilnahme zum Vertragsende
create function public.gr_cancel_contract(p_contract uuid, p_cancelled_on date, p_ends_on date, p_end_membership boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_c public.gr_contracts%rowtype;
  v_m public.gr_memberships%rowtype;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_c from public.gr_contracts c where c.id = p_contract;
  if not found then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_m := public.gr_check_membership(v_c.membership_id);
  if p_cancelled_on is null or p_ends_on is null then
    raise exception 'GR_CONTRACT_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  if p_ends_on < v_c.starts_on then
    raise exception 'GR_CONTRACT_END_BEFORE_START' using errcode = 'P0001';
  end if;

  update public.gr_contracts set cancelled_on = p_cancelled_on, ends_on = p_ends_on where id = p_contract;

  if coalesce(p_end_membership, false) and (v_m.left_on is null or v_m.left_on > p_ends_on) then
    if p_ends_on < v_m.joined_on then
      raise exception 'GR_LEFT_BEFORE_JOINED' using errcode = 'P0001';
    end if;
    update public.gr_memberships set left_on = p_ends_on where id = v_m.id;
  end if;
end;
$$;

-- „Teilnahme bis“ setzen oder ändern (R8); Vertrag bleibt (R8b)
create function public.gr_end_membership(p_membership uuid, p_left_on date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_m public.gr_memberships%rowtype;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_m := public.gr_check_membership(p_membership);
  if p_left_on is not null and p_left_on < v_m.joined_on then
    raise exception 'GR_LEFT_BEFORE_JOINED' using errcode = 'P0001';
  end if;
  update public.gr_memberships set left_on = p_left_on where id = p_membership;
end;
$$;

revoke all on function public.gr_admit(uuid, uuid, date, jsonb) from public, anon, authenticated;
revoke all on function public.gr_add_contract(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_update_contract(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_cancel_contract(uuid, date, date, boolean) from public, anon, authenticated;
revoke all on function public.gr_end_membership(uuid, date) from public, anon, authenticated;
grant execute on function public.gr_admit(uuid, uuid, date, jsonb) to authenticated;
grant execute on function public.gr_add_contract(uuid, jsonb) to authenticated;
grant execute on function public.gr_update_contract(uuid, jsonb) to authenticated;
grant execute on function public.gr_cancel_contract(uuid, date, date, boolean) to authenticated;
grant execute on function public.gr_end_membership(uuid, date) to authenticated;
