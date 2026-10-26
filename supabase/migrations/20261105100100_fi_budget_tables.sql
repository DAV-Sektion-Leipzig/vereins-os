-- Bereich Budget in Finanzen (spec.md DS v0.2 Abschnitte 2.1, 2.2, 3), Task T5 (DT05).
-- Typen, Tabellen, Rechtefunktionen, RLS (nur lesen). Schreiben nur über die Funktionen der folgenden Migrationen.
-- Voraussetzung: 20261103000100_ad_ds_module.sql (Modul DS, ad_has_budget_maintain), Finanzen (fi_payout_runs).

create type public.fi_budget_kind as enum ('income', 'expense');
create type public.fi_budget_visibility as enum ('referat', 'all', 'none');
create type public.fi_budget_rule_type as enum ('booking', 'account', 'main_account', 'range');
create type public.fi_budget_rule_status as enum ('ok', 'uncertain', 'open', 'no_booking');
create type public.fi_budget_realloc_status as enum ('requested', 'withdrawn', 'confirmed', 'rejected');
create type public.fi_budget_proposal_status as enum ('proposed', 'withdrawn', 'accepted', 'rejected', 'obsolete');

revoke all on type public.fi_budget_kind, public.fi_budget_visibility, public.fi_budget_rule_type,
  public.fi_budget_rule_status, public.fi_budget_realloc_status, public.fi_budget_proposal_status from public, anon;
grant usage on type public.fi_budget_kind, public.fi_budget_visibility, public.fi_budget_rule_type,
  public.fi_budget_rule_status, public.fi_budget_realloc_status, public.fi_budget_proposal_status
  to authenticated, service_role;

-- ---------------------------------------------------------------------------------------------------------------
-- Finanzplan je Jahr
create table public.fi_budget_plans (
  year smallint primary key,
  source_file text not null,
  sheet text not null,
  sum_income numeric(12, 2),
  sum_expense numeric(12, 2),
  imported_at timestamptz not null default now(),
  imported_by uuid default auth.uid(),
  constraint fi_budget_plans_year check (year between 2026 and 2100)
);

-- Gesamtbudget
create table public.fi_budget_groups (
  id uuid primary key default gen_random_uuid(),
  year smallint not null references public.fi_budget_plans (year) on delete cascade,
  name text not null,
  visibility public.fi_budget_visibility not null default 'none',
  referat_id uuid references public.ea_referate (id),
  sort_order int not null default 0,
  constraint fi_budget_groups_name check (char_length(btrim(name)) between 1 and 80),
  constraint fi_budget_groups_referat check ((visibility = 'referat') = (referat_id is not null))
);
create unique index fi_budget_groups_key on public.fi_budget_groups (year, lower(name));

-- Budgetposten
create table public.fi_budget_items (
  id uuid primary key default gen_random_uuid(),
  year smallint not null references public.fi_budget_plans (year) on delete cascade,
  group_id uuid not null references public.fi_budget_groups (id) on delete restrict,
  kind public.fi_budget_kind not null,
  name text not null,
  plan_decided numeric(12, 2),
  excel_row int,
  sort_order int not null default 0,
  no_booking boolean not null default false,
  removed_at timestamptz,
  constraint fi_budget_items_name check (char_length(btrim(name)) between 1 and 120)
);
create unique index fi_budget_items_key on public.fi_budget_items (year, kind, group_id, lower(name));
create index fi_budget_items_group on public.fi_budget_items (group_id);

-- Zuordnungsregel mit Historie (valid_to null = gültig)
create table public.fi_budget_rules (
  id uuid primary key default gen_random_uuid(),
  year smallint not null references public.fi_budget_plans (year) on delete cascade,
  rule_type public.fi_budget_rule_type not null,
  account_text text not null,
  main_account int,
  sub_account smallint,
  range_from int,
  range_to int,
  range_full boolean,
  cost_centers text[] not null default '{}',
  item_id uuid references public.fi_budget_items (id) on delete restrict,
  status public.fi_budget_rule_status not null default 'ok',
  note text,
  account_label text,
  b_date date,
  b_receipt text,
  b_amount numeric(12, 2),
  b_side char(1),
  b_text text,
  reason text,
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  created_by uuid default auth.uid(),
  comment text,
  constraint fi_budget_rules_shape check (
    (rule_type = 'range' and range_from is not null and range_to is not null and range_from <= range_to
       and range_full is not null)
    or (rule_type = 'main_account' and main_account is not null and sub_account is null)
    or (rule_type in ('account', 'booking') and main_account is not null and sub_account is not null)),
  constraint fi_budget_rules_side check (b_side is null or b_side in ('S', 'H')),
  constraint fi_budget_rules_booking check (
    rule_type = 'booking' or (b_date is null and b_receipt is null and b_amount is null and b_side is null and b_text is null)),
  constraint fi_budget_rules_note check (note is null or char_length(note) <= 500),
  constraint fi_budget_rules_reason check (reason is null or char_length(reason) <= 500)
);
create unique index fi_budget_rules_current_key on public.fi_budget_rules (
  year, rule_type, coalesce(main_account, -1), coalesce(sub_account, -1), coalesce(range_from, -1),
  coalesce(range_to, -1), coalesce(range_full, false), cost_centers, coalesce(b_date, 'infinity'::date),
  lower(coalesce(b_receipt, '')), coalesce(b_amount, -1), coalesce(b_side, ''), lower(coalesce(b_text, '')))
  where valid_to is null;
create index fi_budget_rules_year on public.fi_budget_rules (year) where valid_to is null;
create index fi_budget_rules_item on public.fi_budget_rules (item_id);

-- DATEV-Import
create table public.fi_budget_imports (
  id uuid primary key default gen_random_uuid(),
  year smallint not null references public.fi_budget_plans (year) on delete cascade,
  file_name text not null,
  export_info text,
  data_until date,
  rows_read int not null default 0,
  rows_saved int not null default 0,
  rows_ignored int not null default 0,
  rows_opening int not null default 0,
  rows_other_year int not null default 0,
  checks jsonb not null default '[]',
  warnings jsonb not null default '[]',
  is_current boolean not null default true,
  imported_at timestamptz not null default now(),
  imported_by uuid default auth.uid()
);
create unique index fi_budget_imports_current on public.fi_budget_imports (year) where is_current;

-- Buchung (nur Zeilen auf Konten mit Regel, R1)
create table public.fi_budget_bookings (
  id uuid primary key default gen_random_uuid(),
  import_id uuid not null references public.fi_budget_imports (id) on delete cascade,
  year smallint not null,
  main_account int not null,
  sub_account smallint not null,
  booking_date date not null,
  bu text,
  contra_account text,
  contra_label text,
  booking_text text,
  receipt text,
  debit numeric(12, 2) not null default 0,
  credit numeric(12, 2) not null default 0,
  cost_center text,
  line_no int not null,
  constraint fi_budget_bookings_amounts check (debit >= 0 and credit >= 0)
);
create index fi_budget_bookings_account on public.fi_budget_bookings (year, main_account, sub_account);
create index fi_budget_bookings_import on public.fi_budget_bookings (import_id);

-- Kontenübersicht des Imports (Prüfung R8)
create table public.fi_budget_account_totals (
  import_id uuid not null references public.fi_budget_imports (id) on delete cascade,
  main_account int not null,
  sub_account smallint not null,
  opening numeric(12, 2),
  debit numeric(12, 2) not null default 0,
  credit numeric(12, 2) not null default 0,
  primary key (import_id, main_account, sub_account)
);

-- Kontensumme je Monat (bleibt nach dem Löschlauf, R19)
create table public.fi_budget_month_totals (
  year smallint not null,
  month smallint not null,
  main_account int not null,
  sub_account smallint not null,
  cost_center text not null default '',
  debit numeric(12, 2) not null default 0,
  credit numeric(12, 2) not null default 0,
  primary key (year, month, main_account, sub_account, cost_center),
  constraint fi_budget_month_totals_month check (month between 1 and 12)
);

-- Umschichtung
create table public.fi_budget_reallocations (
  id uuid primary key default gen_random_uuid(),
  year smallint not null references public.fi_budget_plans (year) on delete cascade,
  from_item uuid not null references public.fi_budget_items (id) on delete restrict,
  to_item uuid not null references public.fi_budget_items (id) on delete restrict,
  amount numeric(12, 2) not null,
  reason text not null,
  status public.fi_budget_realloc_status not null default 'requested',
  requested_by uuid default auth.uid(),
  requested_by_person_id uuid references public.ea_persons (id) on delete set null,
  requested_at timestamptz not null default now(),
  decided_by uuid,
  decided_by_person_id uuid references public.ea_persons (id) on delete set null,
  decided_at timestamptz,
  decision_reason text,
  constraint fi_budget_reallocations_items check (from_item <> to_item),
  constraint fi_budget_reallocations_amount check (amount > 0),
  constraint fi_budget_reallocations_reason check (char_length(btrim(reason)) between 1 and 500),
  constraint fi_budget_reallocations_decision check (decision_reason is null or char_length(decision_reason) <= 500)
);
create index fi_budget_reallocations_open on public.fi_budget_reallocations (year) where status = 'requested';

-- Umschlüsselungs-Vorschlag
create table public.fi_budget_proposals (
  id uuid primary key default gen_random_uuid(),
  year smallint not null references public.fi_budget_plans (year) on delete cascade,
  booking_id uuid references public.fi_budget_bookings (id) on delete set null,
  b_date date not null,
  b_main_account int not null,
  b_sub_account smallint not null,
  b_receipt text,
  b_amount numeric(12, 2) not null,
  b_side char(1) not null,
  b_text text,
  from_item uuid references public.fi_budget_items (id) on delete restrict,
  to_item uuid not null references public.fi_budget_items (id) on delete restrict,
  reason text not null,
  status public.fi_budget_proposal_status not null default 'proposed',
  proposed_by uuid default auth.uid(),
  proposed_by_person_id uuid references public.ea_persons (id) on delete set null,
  proposed_at timestamptz not null default now(),
  decided_by uuid,
  decided_at timestamptz,
  decision_reason text,
  rule_id uuid references public.fi_budget_rules (id) on delete set null,
  constraint fi_budget_proposals_side check (b_side in ('S', 'H')),
  constraint fi_budget_proposals_reason check (char_length(btrim(reason)) between 1 and 500),
  constraint fi_budget_proposals_decision check (decision_reason is null or char_length(decision_reason) <= 500)
);
create unique index fi_budget_proposals_open on public.fi_budget_proposals (
  year, b_date, b_main_account, b_sub_account, lower(coalesce(b_receipt, '')), b_amount, b_side,
  lower(coalesce(b_text, '')))
  where status = 'proposed';

-- Hinweis je Budgetposten (Historie; valid_to null = aktuell)
create table public.fi_budget_notes (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.fi_budget_items (id) on delete cascade,
  text text not null,
  created_by uuid default auth.uid(),
  created_by_person_id uuid references public.ea_persons (id) on delete set null,
  created_at timestamptz not null default now(),
  valid_to timestamptz,
  constraint fi_budget_notes_text check (char_length(btrim(text)) between 1 and 500)
);
create unique index fi_budget_notes_current on public.fi_budget_notes (item_id) where valid_to is null;

-- Auszahlungsrunde von Hand als gebucht markiert (R18)
create table public.fi_budget_payout_marks (
  run_id uuid primary key references public.fi_payout_runs (id) on delete cascade,
  marked_by uuid default auth.uid(),
  marked_at timestamptz not null default now()
);

-- Protokoll (R24), ohne Buchungstexte
create table public.fi_budget_log (
  id uuid primary key default gen_random_uuid(),
  year smallint,
  action text not null,
  object_id uuid,
  details jsonb not null default '{}',
  actor uuid default auth.uid(),
  actor_person_id uuid references public.ea_persons (id) on delete set null,
  at timestamptz not null default now()
);
create index fi_budget_log_at on public.fi_budget_log (at);

-- ---------------------------------------------------------------------------------------------------------------
-- Rechtefunktionen (spec 2.3)
create function public.fi_budget_can_read()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.ad_has_any_level('DS', 'read');
$$;

create function public.fi_budget_scope_all()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.ad_has_level('DS', 'read') or public.ad_has_budget_maintain();
$$;

create function public.fi_budget_group_mine(p_group uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.fi_budget_groups g
                  where g.id = p_group and g.visibility = 'referat'
                    and g.referat_id = any (public.ad_my_referate('DS', 'read')));
$$;

create function public.fi_budget_can_see_bookings(p_item uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.fi_budget_scope_all()
      or exists (select 1 from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
                  where i.id = p_item and public.fi_budget_can_read()
                    and (g.visibility = 'all' or public.fi_budget_group_mine(g.id)));
$$;

create function public.fi_budget_can_edit_item(p_item uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.ad_has_budget_maintain()
      or exists (select 1 from public.fi_budget_items i
                  where i.id = p_item and public.fi_budget_group_mine(i.group_id));
$$;

revoke all on function public.fi_budget_can_read(), public.fi_budget_scope_all(), public.fi_budget_group_mine(uuid),
  public.fi_budget_can_see_bookings(uuid), public.fi_budget_can_edit_item(uuid) from public, anon, authenticated;
grant execute on function public.fi_budget_can_read(), public.fi_budget_scope_all(), public.fi_budget_group_mine(uuid),
  public.fi_budget_can_see_bookings(uuid), public.fi_budget_can_edit_item(uuid) to authenticated;

-- ---------------------------------------------------------------------------------------------------------------
-- RLS: nur lesen; Referent:innen lesen Buchungen ausschließlich über ds_budget_bookings
alter table public.fi_budget_plans enable row level security;
alter table public.fi_budget_groups enable row level security;
alter table public.fi_budget_items enable row level security;
alter table public.fi_budget_rules enable row level security;
alter table public.fi_budget_imports enable row level security;
alter table public.fi_budget_bookings enable row level security;
alter table public.fi_budget_account_totals enable row level security;
alter table public.fi_budget_month_totals enable row level security;
alter table public.fi_budget_reallocations enable row level security;
alter table public.fi_budget_proposals enable row level security;
alter table public.fi_budget_notes enable row level security;
alter table public.fi_budget_payout_marks enable row level security;
alter table public.fi_budget_log enable row level security;

create policy fi_budget_plans_read on public.fi_budget_plans for select to authenticated using (public.fi_budget_can_read());
create policy fi_budget_groups_read on public.fi_budget_groups for select to authenticated using (public.fi_budget_can_read());
create policy fi_budget_items_read on public.fi_budget_items for select to authenticated using (public.fi_budget_can_read());
create policy fi_budget_notes_read on public.fi_budget_notes for select to authenticated using (public.fi_budget_can_read());
create policy fi_budget_rules_read on public.fi_budget_rules for select to authenticated using (public.fi_budget_scope_all());
create policy fi_budget_imports_read on public.fi_budget_imports for select to authenticated using (public.fi_budget_scope_all());
create policy fi_budget_bookings_read on public.fi_budget_bookings for select to authenticated using (public.fi_budget_scope_all());
create policy fi_budget_account_totals_read on public.fi_budget_account_totals for select to authenticated
  using (public.fi_budget_scope_all());
create policy fi_budget_month_totals_read on public.fi_budget_month_totals for select to authenticated
  using (public.fi_budget_scope_all());
create policy fi_budget_payout_marks_read on public.fi_budget_payout_marks for select to authenticated
  using (public.fi_budget_scope_all());
create policy fi_budget_log_read on public.fi_budget_log for select to authenticated using (public.fi_budget_scope_all());
create policy fi_budget_reallocations_read on public.fi_budget_reallocations for select to authenticated
  using (public.fi_budget_scope_all() or requested_by = auth.uid());
create policy fi_budget_proposals_read on public.fi_budget_proposals for select to authenticated
  using (public.fi_budget_scope_all() or proposed_by = auth.uid());

revoke all on public.fi_budget_plans, public.fi_budget_groups, public.fi_budget_items, public.fi_budget_rules,
  public.fi_budget_imports, public.fi_budget_bookings, public.fi_budget_account_totals, public.fi_budget_month_totals,
  public.fi_budget_reallocations, public.fi_budget_proposals, public.fi_budget_notes, public.fi_budget_payout_marks,
  public.fi_budget_log from public, anon, authenticated;
grant select on public.fi_budget_plans, public.fi_budget_groups, public.fi_budget_items, public.fi_budget_rules,
  public.fi_budget_imports, public.fi_budget_bookings, public.fi_budget_account_totals, public.fi_budget_month_totals,
  public.fi_budget_reallocations, public.fi_budget_proposals, public.fi_budget_notes, public.fi_budget_payout_marks,
  public.fi_budget_log to authenticated;
