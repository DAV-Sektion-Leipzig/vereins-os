-- Review-Befund D-02 (R12, R24, GR spec.md 2.3): Ein Eintrag zur Fotoerlaubnis oder zur Einwilligung zu
-- Gesundheitsangaben mit einem Datum vor dem aktuellen Eintrag würde gespeichert, bliebe aber wirkungslos, weil der
-- aktuelle Stand nach effective_on desc bestimmt wird (gr_can_read_health, Oberfläche). Ein rückdatierter Widerruf
-- ließe Gesundheitsangaben lesbar. Neu: Datum vor dem aktuellen Eintrag wird mit GR_CONSENT_DATE_BEFORE_CURRENT
-- abgelehnt (detail = Datum des aktuellen Eintrags TT.MM.JJJJ). Gleiches Datum bleibt erlaubt (created_at/id entscheiden).
-- Sonst unverändert gegenüber 20261025000600_gr_consents_health.sql.

create or replace function public.gr_set_consent(p_health boolean, p_person uuid, p_granted boolean, p_effective_on date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current boolean;
  v_current_on date;
begin
  if not public.ad_has_level('GR', 'edit') or not public.gr_person_visible(p_person, 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_granted is null then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;
  if p_effective_on is null then
    raise exception 'GR_CONSENT_DATE_REQUIRED' using errcode = 'P0001';
  end if;
  if p_effective_on > public.gr_today() then
    raise exception 'GR_DATE_IN_FUTURE' using errcode = 'P0001';
  end if;

  if p_health then
    select c.granted, c.effective_on into v_current, v_current_on from public.gr_health_consents c
     where c.person_id = p_person order by c.effective_on desc, c.created_at desc, c.id desc limit 1;
  else
    select c.granted, c.effective_on into v_current, v_current_on from public.gr_photo_consents c
     where c.person_id = p_person order by c.effective_on desc, c.created_at desc, c.id desc limit 1;
  end if;
  -- ohne Eintrag gilt „nein“
  if coalesce(v_current, false) = p_granted then
    raise exception 'GR_CONSENT_UNCHANGED' using errcode = 'P0001';
  end if;
  -- Ein Eintrag vor dem aktuellen wäre nie der aktuelle Stand (Befund D-02)
  if v_current_on is not null and p_effective_on < v_current_on then
    raise exception 'GR_CONSENT_DATE_BEFORE_CURRENT' using errcode = 'P0001',
      detail = to_char(v_current_on, 'DD.MM.YYYY');
  end if;

  if p_health then
    insert into public.gr_health_consents (person_id, granted, effective_on) values (p_person, p_granted, p_effective_on);
  else
    insert into public.gr_photo_consents (person_id, granted, effective_on) values (p_person, p_granted, p_effective_on);
  end if;
end;
$$;

revoke all on function public.gr_set_consent(boolean, uuid, boolean, date) from public, anon, authenticated;
