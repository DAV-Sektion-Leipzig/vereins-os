-- US-EA-06, spec T5 (EA spec.md 2.3, R13): IBAN normalisieren und prüfen (ISO 13616), Trigger auf ea_properties
-- für die Art mit system_key = 'bank_account' (research.md R-EA-08). Der Trigger heißt ea_properties_iban, damit
-- er alphabetisch vor ea_properties_validate läuft.

-- Leerzeichen entfernen, Großbuchstaben; null bleibt null
create function public.ea_iban_normalize(p_iban text)
returns text
language sql
immutable
set search_path = public
as $$
  select upper(regexp_replace(p_iban, '\s', '', 'g'));
$$;

-- Muster und Prüfsumme (mod 97 = 1); abschnittsweise Division, damit kein großer numeric nötig ist
create function public.ea_iban_valid(p_iban text)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  v_iban text := public.ea_iban_normalize(p_iban);
  v_rearranged text;
  v_digits text := '';
  v_char text;
  v_rem int := 0;
  i int;
begin
  if v_iban is null or v_iban !~ '^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$' then
    return false;
  end if;

  v_rearranged := substr(v_iban, 5) || substr(v_iban, 1, 4);
  for i in 1 .. char_length(v_rearranged) loop
    v_char := substr(v_rearranged, i, 1);
    if v_char between '0' and '9' then
      v_digits := v_digits || v_char;
    else
      v_digits := v_digits || (ascii(v_char) - 55)::text;
    end if;
  end loop;

  i := 1;
  while i <= char_length(v_digits) loop
    v_rem := (v_rem::text || substr(v_digits, i, 7))::bigint % 97;
    i := i + 7;
  end loop;

  return v_rem = 1;
end;
$$;

-- Trigger: nur bei der Art bank_account und gesetztem Feld iban
create function public.ea_properties_iban()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_raw text;
  v_iban text;
begin
  if not (new.field_values ? 'iban') then
    return new;
  end if;
  if not exists (
    select 1 from public.ea_property_types t where t.id = new.property_type_id and t.system_key = 'bank_account'
  ) then
    return new;
  end if;

  v_raw := new.field_values ->> 'iban';
  if v_raw is null or btrim(v_raw) = '' then
    return new; -- Pflichtfeld prüft ea_properties_validate (EA_FIELD_REQUIRED)
  end if;

  v_iban := public.ea_iban_normalize(v_raw);
  if not public.ea_iban_valid(v_iban) then
    raise exception 'EA_IBAN_INVALID' using errcode = 'P0001';
  end if;
  new.field_values := new.field_values || jsonb_build_object('iban', v_iban);
  return new;
end;
$$;

revoke all on function public.ea_properties_iban() from public, anon, authenticated;

create trigger ea_properties_iban
  before insert or update on public.ea_properties
  for each row execute function public.ea_properties_iban();

revoke all on function public.ea_iban_normalize(text) from public, anon;
revoke all on function public.ea_iban_valid(text) from public, anon;
grant execute on function public.ea_iban_normalize(text) to authenticated;
grant execute on function public.ea_iban_valid(text) to authenticated;
