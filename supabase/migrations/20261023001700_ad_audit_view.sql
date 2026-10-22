-- US-AD-14, spec T4 (Teil), T22: Protokoll mit Namen des Akteurs und der betroffenen Person.
-- security_invoker: Zeilen und Namen nur, soweit die RLS auf ad_audit_log, ad_accesses und ea_persons es erlaubt (AD ≥ lesen).
-- Der Akteur wird über ad_accesses.auth_user_id → ea_persons aufgelöst; Rufname bevorzugt (spec.md Abschnitt 6).

create view public.ad_v_audit_log
with (security_invoker = true)
as
select l.id,
       l.occurred_at,
       l.actor_user_id,
       case when ap.id is null then null
            else coalesce(nullif(ap.preferred_name, ''), ap.first_name) || ' ' || ap.last_name end as actor_name,
       l.subject_person_id,
       coalesce(nullif(sp.preferred_name, ''), sp.first_name) || ' ' || sp.last_name as subject_name,
       l.action,
       l.details
  from public.ad_audit_log l
  join public.ea_persons sp on sp.id = l.subject_person_id
  left join public.ad_accesses aa on aa.auth_user_id = l.actor_user_id
  left join public.ea_persons ap on ap.id = aa.person_id;

comment on view public.ad_v_audit_log is 'Protokoll (R13, R16) mit Anzeigenamen; nur lesen, Einträge entstehen nur durch das System.';

revoke all on table public.ad_v_audit_log from public, anon, authenticated;
grant select on table public.ad_v_audit_log to authenticated;
