-- US-GR-10, US-GR-12, spec T6 (GR spec.md 2.3): Fotoerlaubnis und Einwilligung zu Gesundheitsangaben mit Historie
-- (R12, R24), Gesundheitsangaben (R11, R24). security definer; Person im Pfad GR mit edit.

-- Gemeinsame Prüfung und Einfügen für beide Einwilligungen; p_health = Einwilligung Gesundheitsangaben; intern
create function public.gr_set_consent(p_health boolean, p_person uuid, p_granted boolean, p_effective_on date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current boolean;
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
    select c.granted into v_current from public.gr_health_consents c
     where c.person_id = p_person order by c.effective_on desc, c.created_at desc, c.id desc limit 1;
  else
    select c.granted into v_current from public.gr_photo_consents c
     where c.person_id = p_person order by c.effective_on desc, c.created_at desc, c.id desc limit 1;
  end if;
  -- ohne Eintrag gilt „nein“
  if coalesce(v_current, false) = p_granted then
    raise exception 'GR_CONSENT_UNCHANGED' using errcode = 'P0001';
  end if;

  if p_health then
    insert into public.gr_health_consents (person_id, granted, effective_on) values (p_person, p_granted, p_effective_on);
  else
    insert into public.gr_photo_consents (person_id, granted, effective_on) values (p_person, p_granted, p_effective_on);
  end if;
end;
$$;

revoke all on function public.gr_set_consent(boolean, uuid, boolean, date) from public, anon, authenticated;

create function public.gr_set_photo_consent(p_person uuid, p_granted boolean, p_effective_on date)
returns void
language sql
security definer
set search_path = ''
as $$
  select public.gr_set_consent(false, p_person, p_granted, p_effective_on);
$$;

-- Bei „nein“ bleiben Gesundheitsangaben gespeichert, sind aber nicht mehr lesbar (R24)
create function public.gr_set_health_consent(p_person uuid, p_granted boolean, p_effective_on date)
returns void
language sql
security definer
set search_path = ''
as $$
  select public.gr_set_consent(true, p_person, p_granted, p_effective_on);
$$;

-- Gesundheitsangabe speichern (Insert oder Update; Historie über Trigger gr_health_notes_history)
create function public.gr_save_health_note(p_person uuid, p_note text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_note text := btrim(coalesce(p_note, ''));
begin
  if not public.gr_can_read_health(p_person) then
    if public.gr_person_visible(p_person, 'edit') then
      raise exception 'GR_HEALTH_CONSENT_REQUIRED' using errcode = 'P0001';
    end if;
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  if char_length(v_note) not between 1 and 2000 then
    raise exception 'GR_HEALTH_NOTE_INVALID' using errcode = 'P0001';
  end if;

  insert into public.gr_health_notes (person_id, note) values (p_person, v_note)
  on conflict (person_id) do update
    set note = excluded.note, updated_at = now(), updated_by = auth.uid()
    where public.gr_health_notes.note is distinct from excluded.note;
end;
$$;

revoke all on function public.gr_set_photo_consent(uuid, boolean, date) from public, anon, authenticated;
revoke all on function public.gr_set_health_consent(uuid, boolean, date) from public, anon, authenticated;
revoke all on function public.gr_save_health_note(uuid, text) from public, anon, authenticated;
grant execute on function public.gr_set_photo_consent(uuid, boolean, date) to authenticated;
grant execute on function public.gr_set_health_consent(uuid, boolean, date) to authenticated;
grant execute on function public.gr_save_health_note(uuid, text) to authenticated;
