-- Nachtrag v0.10 (spec.md AD v0.10.0), spec T72; Übergabe FI A8, A9; R55, R56; Querschnitt P7, Q2.
-- Lesefunktion mit festen Spalten für Bankverbindung, Trainervereinbarung, Bestätigung steuerfreie Einnahmen und
-- Lizenzen (nur FI-Reichweite „alle“); Platzhalter fi_person_visible; ea_person_names um Finanzen erweitert.

-- Platzhalter; die erste Migration von Finanzen ersetzt die Funktion mit derselben Signatur (spec.md FI Abschnitt 2)
create function public.fi_person_visible(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select false;
$$;

revoke all on function public.fi_person_visible(uuid) from public, anon, authenticated;
grant execute on function public.fi_person_visible(uuid) to authenticated;

-- Namen zu IDs (R44, R48, R56): Pfade AD, EA, GR sowie Anwesenheitserfassung und Finanzen
create or replace function public.ea_person_names(p_ids uuid[])
returns table (id uuid, first_name text, preferred_name text, last_name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(cardinality(p_ids), 0) > 500 then
    raise exception 'AD_TOO_MANY_IDS' using errcode = 'P0001';
  end if;
  return query
  select p.id, p.first_name, p.preferred_name, p.last_name
    from public.ea_persons p
   where p.id = any (coalesce(p_ids, '{}'))
     and p.kind = 'human'
     and (public.ea_person_visible(p.id) or public.ez_person_visible(p.id) or public.fi_person_visible(p.id));
end;
$$;

-- Personendaten für Finanzen (R55): nur mit FI ≥ lesen und Reichweite „alle“; unabhängig von EA-Rechten und vom
-- Ehrenamtsstatus; feste Spalten, keine Lizenznummer, keine anderen Eigenschaften.
create function public.ea_person_finance_data(p_person_ids uuid[], p_date date)
returns table (
  person_id uuid, account_holder text, iban text, trainer_agreement_from date, tax_free_confirmations jsonb, licenses jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_date date := coalesce(p_date, current_date);
begin
  if not public.ad_has_level('FI', 'read') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  if coalesce(cardinality(p_person_ids), 0) > 500 then
    raise exception 'AD_TOO_MANY_IDS' using errcode = 'P0001';
  end if;

  return query
  select p.id,
         ba.field_values ->> 'account_holder',
         ba.field_values ->> 'iban',
         ta.valid_from,
         coalesce((
           select jsonb_agg(jsonb_build_object(
                    'year', nullif(c.field_values ->> 'year', '')::int,
                    'submitted_on', c.valid_from) order by c.valid_from)
             from public.ea_properties c
             join public.ea_property_types ct on ct.id = c.property_type_id
            where ct.system_key = 'tax_free_confirmation'
              and c.person_id = p.id
         ), '[]'::jsonb),
         coalesce((
           select jsonb_agg(jsonb_build_object(
                    'qualification_type_id', q.id,
                    'code', q.code,
                    'name', q.name,
                    'valid_from', l.valid_from,
                    'valid_until', nullif(l.field_values ->> 'valid_until', '')::date,
                    'is_fundable', coalesce(q.dosb_eligible, false)) order by l.valid_from)
             from public.ea_properties l
             join public.ea_property_types lt on lt.id = l.property_type_id
             join public.ad_qualification_types q on q.id = nullif(l.field_values ->> 'qualification_type', '')::uuid
            where lt.system_key = 'license'
              and l.person_id = p.id
              and q.kind = 'license'
         ), '[]'::jsonb)
    from public.ea_persons p
    left join lateral (
      select b.field_values
        from public.ea_properties b
        join public.ea_property_types bt on bt.id = b.property_type_id
       where bt.system_key = 'bank_account'
         and b.person_id = p.id
         and b.valid_from <= v_date
         and (b.valid_to is null or b.valid_to >= v_date)
       order by b.valid_from desc
       limit 1
    ) ba on true
    left join lateral (
      select a.valid_from
        from public.ea_properties a
        join public.ea_property_types tt on tt.id = a.property_type_id
       where tt.system_key = 'trainer_agreement'
         and a.person_id = p.id
         and a.valid_from <= v_date
         and (a.valid_to is null or a.valid_to >= v_date)
         and coalesce((a.field_values ->> 'signed')::boolean, false)
       order by a.valid_from desc
       limit 1
    ) ta on true
   where p.id = any (coalesce(p_person_ids, '{}'))
     and p.kind = 'human';
end;
$$;

revoke all on function public.ea_person_finance_data(uuid[], date) from public, anon, authenticated;
grant execute on function public.ea_person_finance_data(uuid[], date) to authenticated;
