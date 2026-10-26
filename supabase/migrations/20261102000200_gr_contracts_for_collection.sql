-- Gruppen Nachtrag v0.4 (spec.md GR, G1, G2; Finanzen FT18): Verträge für den Buchungslauf. Nur mit „FI verwalten“,
-- feste Spalten, keine Kontakt- oder Gesundheitsangaben.

create function public.gr_contracts_for_collection(p_month date, p_ids uuid[] default null)
returns table (
  contract_id uuid, membership_id uuid, group_id uuid, group_name text, referat_id uuid,
  participant_person_id uuid, participant_first_name text, participant_preferred_name text, participant_last_name text,
  holder_person_id uuid, holder_first_name text, holder_preferred_name text, holder_last_name text,
  account_holder text, iban text, mandate_reference text, mandate_signed_on date, purpose text, monthly_amount numeric,
  starts_on date, ends_on date, bank_check text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('FI', 'manage') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select c.id, m.id, g.id, g.name, g.referat_id,
         p.id, p.first_name, p.preferred_name, p.last_name,
         h.id, h.first_name, h.preferred_name, h.last_name,
         c.account_holder, c.iban, c.mandate_reference, c.mandate_signed_on, c.purpose, c.monthly_amount,
         c.starts_on, c.ends_on, md5(c.iban || '|' || c.account_holder)
    from public.gr_contracts c
    join public.gr_memberships m on m.id = c.membership_id
    join public.gr_groups g on g.id = m.group_id
    join public.ea_persons p on p.id = m.person_id
    join public.ea_persons h on h.id = c.holder_person_id
   where case when p_ids is not null then c.id = any (p_ids)
              else c.starts_on <= p_month and (c.ends_on is null or c.ends_on >= p_month) end;
end;
$$;

revoke all on function public.gr_contracts_for_collection(date, uuid[]) from public, anon, authenticated;
grant execute on function public.gr_contracts_for_collection(date, uuid[]) to authenticated;
