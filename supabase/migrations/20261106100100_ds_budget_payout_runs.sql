-- Bereich Budget (spec.md DS v0.2 R18), Task T16 (DT16): freigegebene Auszahlungsrunden eines Jahres mit Abgleich
-- „gebucht“ für den Reiter Import der Budgetpflege (Markierung von Hand über fi_budget_payout_mark). Nur Budgetpflege;
-- liest die Runden ohne FI-Rechte, aber nur Kopfdaten (keine Personen).

create function public.ds_budget_payout_runs(p_year smallint)
returns table (run_id uuid, year smallint, half smallint, number smallint, execution_date date, total numeric,
  booked boolean, marked boolean)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.fi_budget_require_maintain();
  return query
    select r.id, r.year, r.half, r.number, r.execution_date,
           coalesce(r.total, (select sum(l.amount) from public.fi_payout_lines l where l.run_id = r.id)),
           public.fi_budget_run_booked(r.id, null),
           exists (select 1 from public.fi_budget_payout_marks m where m.run_id = r.id)
      from public.fi_payout_runs r
     where r.status = 'released' and extract(year from r.execution_date) = p_year
     order by r.execution_date desc, r.number desc;
end;
$$;

revoke all on function public.ds_budget_payout_runs(smallint) from public, anon;
grant execute on function public.ds_budget_payout_runs(smallint) to authenticated;
