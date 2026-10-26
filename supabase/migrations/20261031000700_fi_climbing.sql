-- Finanzen (FI), spec T7; US-FI-17: Abgleich Punktekonto Kletterhalle. Zählt aus der Kontrollliste der
-- Anwesenheitserfassung (ez_climbing_points_report, mit „FI verwalten“ freigegeben); keine Namen.

create function public.fi_climbing_report(p_location uuid, p_from date, p_to date)
returns table (event_id uuid, start_date date, group_name text, participants_present int, trial_count int)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.ad_locations l where l.id = p_location and l.has_climbing_points) then
    raise exception 'FI_LOCATION_NO_POINTS' using errcode = 'P0001';
  end if;
  return query select * from public.ez_climbing_points_report(p_location, p_from, p_to);
end;
$$;

create function public.fi_save_climbing_check(
  p_location uuid, p_from date, p_to date, p_invoiced int, p_invoice_number text default null, p_remark text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_without int;
  v_with int;
  v_id uuid;
begin
  if p_from is null or p_to is null or p_from > p_to or p_invoiced is null or p_invoiced < 0 then
    raise exception 'FI_QUANTITY' using errcode = 'P0001';
  end if;
  select coalesce(sum(r.participants_present), 0), coalesce(sum(r.participants_present + r.trial_count), 0)
    into v_without, v_with
    from public.fi_climbing_report(p_location, p_from, p_to) r;
  insert into public.fi_climbing_checks (location_id, period_from, period_to, counted_without_trials, counted_with_trials,
                                         invoiced, invoice_number, remark)
  values (p_location, p_from, p_to, v_without, v_with, p_invoiced,
          nullif(btrim(coalesce(p_invoice_number, '')), ''), nullif(btrim(coalesce(p_remark, '')), ''))
  returning id into v_id;
  return v_id;
end;
$$;

create function public.fi_list_climbing_checks(p_location uuid default null)
returns table (id uuid, location_id uuid, location_name text, period_from date, period_to date,
               counted_without_trials int, counted_with_trials int, invoiced int, invoice_number text, remark text,
               created_at timestamptz, created_by_name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select c.id, c.location_id, l.name, c.period_from, c.period_to, c.counted_without_trials, c.counted_with_trials,
         c.invoiced, c.invoice_number, c.remark, c.created_at,
         (select coalesce(p.preferred_name, p.first_name) || ' ' || p.last_name
            from public.ea_persons p where p.id = c.created_by_person_id)
    from public.fi_climbing_checks c
    join public.ad_locations l on l.id = c.location_id
   where p_location is null or c.location_id = p_location
   order by c.period_from desc, c.created_at desc;
end;
$$;

revoke all on function public.fi_climbing_report(uuid, date, date) from public, anon, authenticated;
revoke all on function public.fi_save_climbing_check(uuid, date, date, int, text, text) from public, anon, authenticated;
revoke all on function public.fi_list_climbing_checks(uuid) from public, anon, authenticated;
grant execute on function public.fi_climbing_report(uuid, date, date) to authenticated;
grant execute on function public.fi_save_climbing_check(uuid, date, date, int, text, text) to authenticated;
grant execute on function public.fi_list_climbing_checks(uuid) to authenticated;
