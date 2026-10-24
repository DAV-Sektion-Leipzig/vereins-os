-- Anwesenheitserfassung (EZ), spec T2; spec.md EZ v0.5 Abschnitt 2 „Sichtbarkeit von Namen“, research.md R-EZ-08.
-- Ersetzt den Platzhalter der Administration (20261026000300_ad_name_functions.sql) mit gleicher Signatur:
-- wahr, wenn die Person in einem lesbaren Einsatz als Anwesenheit, organisierende Person oder erfasst/geändert von
-- vorkommt. Bleibt ohne EZ-Recht false (z. B. ohne Nutzerkontext). Der Grant an authenticated bleibt erhalten.

create or replace function public.ez_person_visible(p_person uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_all boolean := public.ad_has_level('EZ', 'read');
  v_referate uuid[] := public.ad_my_referate('EZ', 'read');
begin
  if not v_all and cardinality(v_referate) = 0 then
    return false;
  end if;
  return exists (
    select 1 from public.ez_attendances a join public.ez_events e on e.id = a.event_id
     where a.person_id = p_person and (v_all or e.referat_id = any (v_referate))
    union all
    select 1 from public.ez_events e
     where e.organizer_person_id = p_person and (v_all or e.referat_id = any (v_referate))
    union all
    select 1 from public.ez_events e
     where e.created_by_person_id = p_person and (v_all or e.referat_id = any (v_referate))
    union all
    select 1 from public.ez_events e
     where e.updated_by_person_id = p_person and (v_all or e.referat_id = any (v_referate))
  );
end;
$$;
