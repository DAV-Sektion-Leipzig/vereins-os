-- Kern v0.6/v0.7 (spec T26, T33, T35, T37): neue Enum-Werte und Enums.
-- Eigene Migration, weil neue Enum-Werte erst nach dem Commit genutzt werden dürfen (research.md R-17).

alter type public.ea_data_type add value if not exists 'number';
alter type public.ea_data_type add value if not exists 'year';
alter type public.ea_data_type add value if not exists 'qualification_type';
alter type public.ad_audit_action add value if not exists 'referate_changed' after 'template_revoked';

-- Reichweite (R30); 'group' folgt mit A6
create type public.ad_scope as enum ('all', 'referat');

-- Personenmodell v0.7 (R29, R38)
create type public.ea_read_level as enum ('all', 'office', 'confidential');
create type public.ea_relation_kind as enum ('none', 'referat', 'gremium', 'group');
create type public.ea_property_category as enum (
  'master_data', 'contact', 'assignment', 'qualification', 'proof', 'yearly', 'issue', 'external_access', 'other'
);
create type public.ea_volunteer_status as enum ('active', 'dormant', 'left');

-- Qualifikationsarten (v0.6)
create type public.ad_qualification_kind as enum ('license', 'add_on', 'course', 'training');
create type public.ad_license_level as enum ('pre', 'C', 'B', 'A', 'none');
create type public.ad_qualification_status as enum ('current', 'historic');

revoke all on type public.ad_scope, public.ea_read_level, public.ea_relation_kind, public.ea_property_category,
  public.ea_volunteer_status, public.ad_qualification_kind, public.ad_license_level,
  public.ad_qualification_status from public, anon;
grant usage on type public.ad_scope, public.ea_read_level, public.ea_relation_kind, public.ea_property_category,
  public.ea_volunteer_status, public.ad_qualification_kind, public.ad_license_level,
  public.ad_qualification_status to authenticated, service_role;
