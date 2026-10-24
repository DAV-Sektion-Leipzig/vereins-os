-- US-GR-01, spec T2 (GR spec.md 2.1, 2.3, 3): Aufnahme, Teilnahme, Vertrag, Erziehungsberechtigte, Notfallkontakte,
-- Fotoerlaubnis, Einwilligung und Gesundheitsangaben; Sichtbarkeit im Pfad GR (Ersatz der Platzhalter
-- gr_person_visible und gr_person_ids, Ü4); Gruppenbezug in ad_v_person_overview (Ü3, research.md R-GR-05).
-- Schreiben nur über security-definer-Funktionen (…000300 ff.); authenticated hat nur select.

-- Aufnahme offen
create table public.gr_pending_admissions (
  person_id uuid primary key references public.ea_persons (id),
  group_id uuid not null references public.gr_groups (id),
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null
);

comment on table public.gr_pending_admissions is 'Aufnahme offen (Zwischenspeichern, W7); höchstens eine je Person.';

create index gr_pending_admissions_group on public.gr_pending_admissions (group_id);

-- Teilnahme
create table public.gr_memberships (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.gr_groups (id) on delete restrict,
  person_id uuid not null references public.ea_persons (id) on delete restrict,
  joined_on date not null,
  left_on date,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint gr_memberships_left_after_joined check (left_on is null or left_on >= joined_on)
);

comment on table public.gr_memberships is 'Teilnahme an einer Gruppe; left_on = „Teilnahme bis“ (letzter Tag).';

create index gr_memberships_group on public.gr_memberships (group_id);
create index gr_memberships_person on public.gr_memberships (person_id);

create trigger gr_memberships_set_updated
  before update on public.gr_memberships
  for each row execute function public.ad_set_updated();

-- Vertrag (SEPA-fähig für Finanzen)
create table public.gr_contracts (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid not null references public.gr_memberships (id) on delete restrict,
  holder_person_id uuid not null references public.ea_persons (id),
  starts_on date not null,
  cancelled_on date,
  ends_on date,
  account_holder text not null,
  iban text not null,
  mandate_reference text not null,
  mandate_signed_on date not null,
  purpose text not null,
  monthly_amount numeric(10, 2) not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint gr_contracts_end_after_start check (ends_on is null or ends_on >= starts_on),
  constraint gr_contracts_end_needs_cancel check (ends_on is null or cancelled_on is not null),
  constraint gr_contracts_account_holder check (account_holder = btrim(account_holder) and char_length(account_holder) between 1 and 70),
  constraint gr_contracts_iban check (iban = public.ea_iban_normalize(iban) and public.ea_iban_valid(iban)),
  constraint gr_contracts_mandate_reference check (mandate_reference ~ '^[A-Za-z0-9+?/:().,'' -]{1,35}$'
                                                   and mandate_reference = btrim(mandate_reference)),
  constraint gr_contracts_purpose check (purpose = btrim(purpose) and char_length(purpose) between 1 and 140),
  constraint gr_contracts_amount check (monthly_amount > 0)
);

comment on table public.gr_contracts is 'Vertrag je Teilnahme mit SEPA-Mandat; Status über gr_contract_status(ends_on, Datum).';

create unique index gr_contracts_mandate_reference on public.gr_contracts (lower(mandate_reference));
create index gr_contracts_membership on public.gr_contracts (membership_id);
create index gr_contracts_holder on public.gr_contracts (holder_person_id);

create trigger gr_contracts_set_updated
  before update on public.gr_contracts
  for each row execute function public.ad_set_updated();

-- Erziehungsberechtigung
create table public.gr_guardians (
  id uuid primary key default gen_random_uuid(),
  child_person_id uuid not null references public.ea_persons (id),
  guardian_person_id uuid not null references public.ea_persons (id),
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  constraint gr_guardians_not_self check (guardian_person_id <> child_person_id),
  constraint gr_guardians_unique unique (child_person_id, guardian_person_id)
);

create index gr_guardians_guardian on public.gr_guardians (guardian_person_id);

-- höchstens zwei Erziehungsberechtigte je Kind (R3)
create function public.gr_guardians_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.gr_guardians g where g.child_person_id = new.child_person_id) >= 2 then
    raise exception 'GR_GUARDIAN_LIMIT' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.gr_guardians_limit() from public, anon, authenticated;

create trigger gr_guardians_limit
  before insert on public.gr_guardians
  for each row execute function public.gr_guardians_limit();

-- Notfallkontakt
create table public.gr_emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  child_person_id uuid not null references public.ea_persons (id),
  contact_person_id uuid not null references public.ea_persons (id),
  sort_order int not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  constraint gr_emergency_contacts_not_self check (contact_person_id <> child_person_id),
  constraint gr_emergency_contacts_unique unique (child_person_id, contact_person_id)
);

create index gr_emergency_contacts_contact on public.gr_emergency_contacts (contact_person_id);

-- Fotoerlaubnis und Einwilligung zu Gesundheitsangaben (Historie, nur Einfügen)
create table public.gr_photo_consents (
  id bigint generated always as identity primary key,
  person_id uuid not null references public.ea_persons (id),
  granted boolean not null,
  effective_on date not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null
);

create index gr_photo_consents_current on public.gr_photo_consents (person_id, effective_on desc, created_at desc);

create table public.gr_health_consents (
  id bigint generated always as identity primary key,
  person_id uuid not null references public.ea_persons (id),
  granted boolean not null,
  effective_on date not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null
);

create index gr_health_consents_current on public.gr_health_consents (person_id, effective_on desc, created_at desc);

-- Gesundheitsangaben (R11, R24)
create table public.gr_health_notes (
  person_id uuid primary key references public.ea_persons (id),
  note text not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid() references auth.users (id) on delete set null,
  constraint gr_health_notes_note check (note = btrim(note) and char_length(note) between 1 and 2000)
);

create table public.gr_health_note_history (
  id bigint generated always as identity primary key,
  person_id uuid not null references public.ea_persons (id),
  note text not null,
  valid_since timestamptz not null,
  replaced_at timestamptz not null default now(),
  replaced_by uuid default auth.uid() references auth.users (id) on delete set null
);

create index gr_health_note_history_person on public.gr_health_note_history (person_id, replaced_at desc);

create function public.gr_health_notes_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.note is distinct from old.note then
    insert into public.gr_health_note_history (person_id, note, valid_since)
    values (old.person_id, old.note, old.updated_at);
  end if;
  return new;
end;
$$;

revoke all on function public.gr_health_notes_history() from public, anon, authenticated;

create trigger gr_health_notes_history
  after update on public.gr_health_notes
  for each row execute function public.gr_health_notes_history();

-- Laufender Bezug einer Person zu Gruppen (spec.md 2.3, Punkte 1–5); ohne Rechteprüfung, ohne Grant
create function public.gr_has_current_relation(p_person uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := public.gr_today();
begin
  -- 1.–3. als Kind bzw. Vertragsinhaber:in
  if exists (select 1 from public.gr_pending_admissions a where a.person_id = p_person)
     or exists (select 1 from public.gr_memberships m
                 where m.person_id = p_person and (m.left_on is null or m.left_on >= v_today))
     or exists (select 1 from public.gr_contracts c join public.gr_memberships m on m.id = c.membership_id
                 where (m.person_id = p_person or c.holder_person_id = p_person)
                   and (c.ends_on is null or c.ends_on >= v_today)) then
    return true;
  end if;

  -- 4. Erziehungsberechtigte:r oder Notfallkontakt eines Kindes mit 1.–3.
  if exists (
    select 1
      from (select g.child_person_id from public.gr_guardians g where g.guardian_person_id = p_person
            union
            select e.child_person_id from public.gr_emergency_contacts e where e.contact_person_id = p_person) k
     where exists (select 1 from public.gr_pending_admissions a where a.person_id = k.child_person_id)
        or exists (select 1 from public.gr_memberships m
                    where m.person_id = k.child_person_id and (m.left_on is null or m.left_on >= v_today))
        or exists (select 1 from public.gr_contracts c join public.gr_memberships m on m.id = c.membership_id
                    where m.person_id = k.child_person_id and (c.ends_on is null or c.ends_on >= v_today))
  ) then
    return true;
  end if;

  -- 5. nicht beendete Funktion in Gruppe
  return exists (
    select 1 from public.ea_properties p
      join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
     where p.person_id = p_person and (p.valid_to is null or p.valid_to >= v_today)
  );
end;
$$;

-- Dieselbe Regel als Menge (für Policies, research.md R-GR-06); ohne Rechteprüfung, ohne Grant
create function public.gr_current_relation_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  with kids as (
    select a.person_id from public.gr_pending_admissions a
    union
    select m.person_id from public.gr_memberships m
     where m.left_on is null or m.left_on >= public.gr_today()
    union
    select m.person_id from public.gr_contracts c join public.gr_memberships m on m.id = c.membership_id
     where c.ends_on is null or c.ends_on >= public.gr_today()
  )
  select k.person_id from kids k
  union
  select c.holder_person_id from public.gr_contracts c
   where c.ends_on is null or c.ends_on >= public.gr_today()
  union
  select g.guardian_person_id from public.gr_guardians g join kids k on k.person_id = g.child_person_id
  union
  select e.contact_person_id from public.gr_emergency_contacts e join kids k on k.person_id = e.child_person_id
  union
  select p.person_id from public.ea_properties p
    join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
   where p.valid_to is null or p.valid_to >= public.gr_today();
$$;

revoke all on function public.gr_has_current_relation(uuid) from public, anon, authenticated;
revoke all on function public.gr_current_relation_ids() from public, anon, authenticated;

-- Pfad GR (Ersatz des Platzhalters, gleiche Signatur): Mensch mit laufendem Bezug (Ü4)
create or replace function public.gr_person_visible(p_person uuid, p_min public.ad_level default 'read')
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('GR', p_min)
     and exists (select 1 from public.ea_persons pe where pe.id = p_person and pe.kind = 'human')
     and public.gr_has_current_relation(p_person);
$$;

-- Personen im Pfad GR als Menge (Ersatz, gleiche Signatur)
create or replace function public.gr_person_ids(p_min public.ad_level default 'read')
returns setof uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('GR', p_min) then
    return;
  end if;
  return query
  select r.id
    from public.gr_current_relation_ids() as r (id)
    join public.ea_persons pe on pe.id = r.id and pe.kind = 'human';
end;
$$;

-- Personenbezogene gr_-Zeilen: GR lesen und (Pfad GR oder Admin über Pfad AD)
create function public.gr_row_visible(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('GR', 'read')
     and (public.ad_has_level('AD', 'read') or public.gr_person_visible(p_person));
$$;

-- Volljährig am Datum; nur intern (R4, R13), das Alter wird nie zurückgegeben
create function public.gr_is_adult(p_person uuid, p_date date)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select ((b.field_values ->> 'date')::date + interval '18 years')::date <= p_date
      from public.ea_properties b
      join public.ea_property_types t on t.id = b.property_type_id and t.system_key = 'birth_date'
     where b.person_id = p_person and b.field_values ? 'date'
     order by b.valid_from desc
     limit 1
  ), false);
$$;

revoke all on function public.gr_is_adult(uuid, date) from public, anon, authenticated;

-- Gesundheitsangaben lesen: Pfad GR mit edit und aktuelle Einwilligung „ja“ (R11, R24)
create function public.gr_can_read_health(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.gr_person_visible(p_person, 'edit')
     and coalesce((
       select c.granted from public.gr_health_consents c
        where c.person_id = p_person
        order by c.effective_on desc, c.created_at desc, c.id desc
        limit 1
     ), false);
$$;

-- Vertragsstatus am Datum
create function public.gr_contract_status(p_ends_on date, p_date date)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_ends_on is null then 'active'
    when p_ends_on >= p_date then 'cancelled'
    else 'ended'
  end;
$$;

-- Hinweis R2 ohne Alter: unter 18 (oder ohne Geburtsdatum) mit laufender Teilnahme oder offener Aufnahme
-- und ohne erziehungsberechtigte Person; null, wenn die Person nicht sichtbar ist (research.md R-GR-09)
create function public.gr_needs_guardian(p_person uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.gr_row_visible(p_person) then
    return null;
  end if;
  return (exists (select 1 from public.gr_pending_admissions a where a.person_id = p_person)
          or exists (select 1 from public.gr_memberships m
                      where m.person_id = p_person and (m.left_on is null or m.left_on >= public.gr_today())))
     and not public.gr_is_adult(p_person, public.gr_today())
     and not exists (select 1 from public.gr_guardians g where g.child_person_id = p_person);
end;
$$;

-- Gruppenbezug für die Personenübersicht der Administration (Ü3); nur mit AD ≥ lesen
create function public.gr_person_has_group_relation(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.ad_has_level('AD', 'read') then public.gr_has_current_relation(p_person) end;
$$;

revoke all on function public.gr_row_visible(uuid) from public, anon, authenticated;
revoke all on function public.gr_can_read_health(uuid) from public, anon, authenticated;
revoke all on function public.gr_contract_status(date, date) from public, anon, authenticated;
revoke all on function public.gr_needs_guardian(uuid) from public, anon, authenticated;
revoke all on function public.gr_person_has_group_relation(uuid) from public, anon, authenticated;
grant execute on function public.gr_row_visible(uuid) to authenticated;
grant execute on function public.gr_can_read_health(uuid) to authenticated;
grant execute on function public.gr_contract_status(date, date) to authenticated;
grant execute on function public.gr_needs_guardian(uuid) to authenticated;
grant execute on function public.gr_person_has_group_relation(uuid) to authenticated;

-- Personenübersicht der Administration: Gruppenbezug statt Anlagemodul (Ü3); sonst unverändert
create or replace view public.ad_v_person_overview
with (security_invoker = true)
as
select p.id as person_id,
       p.first_name,
       p.preferred_name,
       p.last_name,
       p.kind,
       p.created_in,
       p.volunteer_status,
       p.volunteer_status_since,
       a.login_email,
       coalesce(a.status, 'none') as access_status,
       coalesce(public.gr_person_has_group_relation(p.id), false) as has_group_relation,
       coalesce((
         select array_agg(
                  t.name || coalesce(' (' || (
                    select string_agg(r.name, ', ' order by r.sort_order, r.name)
                      from public.ad_assignment_referate ar
                      join public.ea_referate r on r.id = ar.referat_id
                     where ar.assignment_id = ta.id
                  ) || ')', '')
                  order by t.name)
           from public.ad_template_assignments ta
           join public.ad_templates t on t.id = ta.template_id
          where ta.person_id = p.id
            and ta.revoked_at is null
            and (ta.valid_from is null or ta.valid_from <= current_date)
            and (ta.valid_to is null or ta.valid_to >= current_date)
       ), '{}') as templates
  from public.ea_persons p
  left join public.ad_accesses a on a.person_id = p.id;

-- RLS (GR spec.md 3): nur select für authenticated, keine Schreib-Policies
alter table public.gr_pending_admissions enable row level security;
alter table public.gr_memberships enable row level security;
alter table public.gr_contracts enable row level security;
alter table public.gr_guardians enable row level security;
alter table public.gr_emergency_contacts enable row level security;
alter table public.gr_photo_consents enable row level security;
alter table public.gr_health_consents enable row level security;
alter table public.gr_health_notes enable row level security;
alter table public.gr_health_note_history enable row level security;

revoke all on table public.gr_pending_admissions, public.gr_memberships, public.gr_contracts, public.gr_guardians,
  public.gr_emergency_contacts, public.gr_photo_consents, public.gr_health_consents, public.gr_health_notes,
  public.gr_health_note_history from public, anon, authenticated;
grant select on table public.gr_pending_admissions, public.gr_memberships, public.gr_contracts, public.gr_guardians,
  public.gr_emergency_contacts, public.gr_photo_consents, public.gr_health_consents, public.gr_health_notes,
  public.gr_health_note_history to authenticated;

create policy gr_pending_admissions_select on public.gr_pending_admissions
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read')));

-- gr_row_visible als Menge: einmal je Abfrage statt je Zeile
create policy gr_memberships_select on public.gr_memberships
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read'))
         and ((select public.ad_has_level('AD', 'read')) or person_id in (select public.gr_person_ids('read'))));
create policy gr_contracts_select on public.gr_contracts
  for select to authenticated
  using (exists (select 1 from public.gr_memberships m where m.id = membership_id));
create policy gr_guardians_select on public.gr_guardians
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read'))
         and ((select public.ad_has_level('AD', 'read')) or child_person_id in (select public.gr_person_ids('read'))));
create policy gr_emergency_contacts_select on public.gr_emergency_contacts
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read'))
         and ((select public.ad_has_level('AD', 'read')) or child_person_id in (select public.gr_person_ids('read'))));
create policy gr_photo_consents_select on public.gr_photo_consents
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read'))
         and ((select public.ad_has_level('AD', 'read')) or person_id in (select public.gr_person_ids('read'))));

-- Gesundheit: nie über GR lesen und nie über den Pfad AD (R11)
create policy gr_health_consents_select on public.gr_health_consents
  for select to authenticated
  using (person_id in (select public.gr_person_ids('edit')));
create policy gr_health_notes_select on public.gr_health_notes
  for select to authenticated
  using (public.gr_can_read_health(person_id));
create policy gr_health_note_history_select on public.gr_health_note_history
  for select to authenticated
  using (public.gr_can_read_health(person_id));
