begin;

create extension if not exists pgcrypto;

create schema if not exists visitor_intelligence;

comment on schema visitor_intelligence is
  'Private support objects for Visitor Geo Intelligence';

create table if not exists public.vgi_visitors (
  id uuid primary key default gen_random_uuid(),

  visitor_key text not null unique,

  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),

  visit_count bigint not null default 1
    check (visit_count >= 0),

  country_code text,
  country_name text,
  region_code text,
  region_name text,
  city text,
  timezone text,

  approximate_latitude numeric(6, 1),
  approximate_longitude numeric(6, 1),

  language text,
  browser text,
  operating_system text,
  device_class text
    check (
      device_class is null
      or device_class in ('desktop', 'tablet', 'mobile', 'unknown')
    ),

  first_utm_source text,
  first_utm_medium text,
  first_utm_campaign text,

  latest_utm_source text,
  latest_utm_medium text,
  latest_utm_campaign text,

  first_referrer_host text,
  latest_referrer_host text,

  company_id uuid,
  intelligence_score numeric(5, 2)
    check (
      intelligence_score is null
      or (
        intelligence_score >= 0
        and intelligence_score <= 100
      )
    ),

  attributes jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- Upgrade the initial vgi_visitors table when it already exists.
-- CREATE TABLE IF NOT EXISTS does not add columns to an existing table.
alter table public.vgi_visitors
  add column if not exists region_code text,
  add column if not exists approximate_latitude numeric(6, 1),
  add column if not exists approximate_longitude numeric(6, 1),
  add column if not exists first_utm_source text,
  add column if not exists first_utm_medium text,
  add column if not exists first_utm_campaign text,
  add column if not exists latest_utm_source text,
  add column if not exists latest_utm_medium text,
  add column if not exists latest_utm_campaign text,
  add column if not exists first_referrer_host text,
  add column if not exists latest_referrer_host text,
  add column if not exists company_id uuid,
  add column if not exists intelligence_score numeric(5, 2),
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

comment on table public.vgi_visitors is
  'Privacy-conscious visitor profiles without raw IP addresses';

comment on column public.vgi_visitors.visitor_key is
  'Pseudonymous browser-generated visitor identifier';

comment on column public.vgi_visitors.approximate_latitude is
  'Coarse location rounded before storage';

comment on column public.vgi_visitors.approximate_longitude is
  'Coarse location rounded before storage';

create table if not exists public.vgi_sessions (
  id uuid primary key default gen_random_uuid(),

  session_key text not null unique,
  visitor_id uuid not null
    references public.vgi_visitors(id)
    on delete cascade,

  started_at timestamptz not null,
  last_activity_at timestamptz not null,
  ended_at timestamptz,

  duration_seconds integer
    check (
      duration_seconds is null
      or duration_seconds >= 0
    ),

  page_view_count integer not null default 0
    check (page_view_count >= 0),

  event_count integer not null default 0
    check (event_count >= 0),

  maximum_scroll_percent integer not null default 0
    check (
      maximum_scroll_percent >= 0
      and maximum_scroll_percent <= 100
    ),

  entry_path text,
  exit_path text,

  referrer_host text,

  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_term text,
  utm_content text,

  country_code text,
  region_name text,
  city text,

  browser text,
  operating_system text,
  device_class text,

  viewport_width integer,
  viewport_height integer,
  screen_width integer,
  screen_height integer,

  is_bounce boolean,
  converted boolean not null default false,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.vgi_sessions is
  'Thirty-minute Visitor Geo Intelligence browsing sessions';

create table if not exists public.vgi_page_views (
  id uuid primary key default gen_random_uuid(),

  visitor_id uuid not null
    references public.vgi_visitors(id)
    on delete cascade,

  session_id uuid not null
    references public.vgi_sessions(id)
    on delete cascade,

  event_key text unique,

  occurred_at timestamptz not null default now(),

  page_url text,
  page_path text not null,
  page_title text,
  referrer_url text,
  referrer_host text,

  duration_seconds integer
    check (
      duration_seconds is null
      or duration_seconds >= 0
    ),

  maximum_scroll_percent integer
    check (
      maximum_scroll_percent is null
      or (
        maximum_scroll_percent >= 0
        and maximum_scroll_percent <= 100
      )
    ),

  is_entry boolean not null default false,
  is_exit boolean not null default false,

  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_term text,
  utm_content text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

comment on table public.vgi_page_views is
  'Page-view and engagement records';

create table if not exists public.vgi_events (
  id uuid primary key default gen_random_uuid(),

  visitor_id uuid
    references public.vgi_visitors(id)
    on delete set null,

  session_id uuid
    references public.vgi_sessions(id)
    on delete set null,

  page_view_id uuid
    references public.vgi_page_views(id)
    on delete set null,

  event_key text unique,

  event_type text not null,
  event_category text,
  event_action text,
  event_label text,

  occurred_at timestamptz not null default now(),

  page_path text,

  numeric_value numeric,
  text_value text,

  event_data jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

comment on table public.vgi_events is
  'Custom conversion and behavioral events';

create table if not exists public.vgi_heatmap_points (
  id bigint generated always as identity primary key,

  visitor_id uuid
    references public.vgi_visitors(id)
    on delete set null,

  session_id uuid
    references public.vgi_sessions(id)
    on delete cascade,

  page_path text not null,

  point_type text not null
    check (
      point_type in (
        'click',
        'pointer',
        'scroll',
        'viewport'
      )
    ),

  x_ratio numeric(7, 6)
    check (
      x_ratio is null
      or (
        x_ratio >= 0
        and x_ratio <= 1
      )
    ),

  y_ratio numeric(7, 6)
    check (
      y_ratio is null
      or (
        y_ratio >= 0
        and y_ratio <= 1
      )
    ),

  scroll_percent integer
    check (
      scroll_percent is null
      or (
        scroll_percent >= 0
        and scroll_percent <= 100
      )
    ),

  viewport_width integer,
  viewport_height integer,
  document_width integer,
  document_height integer,

  occurred_at timestamptz not null default now(),

  metadata jsonb not null default '{}'::jsonb
);

comment on table public.vgi_heatmap_points is
  'Normalized interaction coordinates without form-field content';

create table if not exists public.vgi_companies (
  id uuid primary key default gen_random_uuid(),

  company_name text not null,
  normalized_name text,
  domain text,
  country_code text,

  organization_type text,
  industry text,

  asn bigint,
  asn_organization text,

  confidence numeric(5, 2)
    check (
      confidence is null
      or (
        confidence >= 0
        and confidence <= 100
      )
    ),

  source text,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.vgi_visitors
  drop constraint if exists vgi_visitors_company_id_fkey;

alter table public.vgi_visitors
  add constraint vgi_visitors_company_id_fkey
  foreign key (company_id)
  references public.vgi_companies(id)
  on delete set null;

create table if not exists public.vgi_intelligence_scores (
  id uuid primary key default gen_random_uuid(),

  visitor_id uuid
    references public.vgi_visitors(id)
    on delete cascade,

  session_id uuid
    references public.vgi_sessions(id)
    on delete cascade,

  score_type text not null,
  score numeric(5, 2) not null
    check (
      score >= 0
      and score <= 100
    ),

  confidence numeric(5, 2)
    check (
      confidence is null
      or (
        confidence >= 0
        and confidence <= 100
      )
    ),

  classification text,
  reasons jsonb not null default '[]'::jsonb,
  model_version text,

  calculated_at timestamptz not null default now(),

  metadata jsonb not null default '{}'::jsonb
);

comment on table public.vgi_intelligence_scores is
  'Rule-based and future AI visitor-intent scoring';

create index if not exists vgi_visitors_last_seen_idx
  on public.vgi_visitors(last_seen_at desc);

create index if not exists vgi_visitors_country_idx
  on public.vgi_visitors(country_code);

create index if not exists vgi_visitors_company_idx
  on public.vgi_visitors(company_id);

create index if not exists vgi_sessions_visitor_idx
  on public.vgi_sessions(visitor_id, started_at desc);

create index if not exists vgi_sessions_activity_idx
  on public.vgi_sessions(last_activity_at desc);

create index if not exists vgi_page_views_session_idx
  on public.vgi_page_views(session_id, occurred_at);

create index if not exists vgi_page_views_path_idx
  on public.vgi_page_views(page_path, occurred_at desc);

create index if not exists vgi_events_session_idx
  on public.vgi_events(session_id, occurred_at);

create index if not exists vgi_events_type_idx
  on public.vgi_events(event_type, occurred_at desc);

create index if not exists vgi_heatmap_page_idx
  on public.vgi_heatmap_points(page_path, occurred_at desc);

create index if not exists vgi_scores_visitor_idx
  on public.vgi_intelligence_scores(
    visitor_id,
    calculated_at desc
  );

create index if not exists vgi_visitors_attributes_gin_idx
  on public.vgi_visitors
  using gin(attributes);

create index if not exists vgi_events_data_gin_idx
  on public.vgi_events
  using gin(event_data);

create or replace function visitor_intelligence.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

drop trigger if exists vgi_visitors_set_updated_at
  on public.vgi_visitors;

create trigger vgi_visitors_set_updated_at
before update on public.vgi_visitors
for each row
execute function visitor_intelligence.set_updated_at();

drop trigger if exists vgi_sessions_set_updated_at
  on public.vgi_sessions;

create trigger vgi_sessions_set_updated_at
before update on public.vgi_sessions
for each row
execute function visitor_intelligence.set_updated_at();

drop trigger if exists vgi_companies_set_updated_at
  on public.vgi_companies;

create trigger vgi_companies_set_updated_at
before update on public.vgi_companies
for each row
execute function visitor_intelligence.set_updated_at();

alter table public.vgi_visitors enable row level security;
alter table public.vgi_sessions enable row level security;
alter table public.vgi_page_views enable row level security;
alter table public.vgi_events enable row level security;
alter table public.vgi_heatmap_points enable row level security;
alter table public.vgi_companies enable row level security;
alter table public.vgi_intelligence_scores enable row level security;

revoke all on table public.vgi_visitors
  from anon, authenticated;

revoke all on table public.vgi_sessions
  from anon, authenticated;

revoke all on table public.vgi_page_views
  from anon, authenticated;

revoke all on table public.vgi_events
  from anon, authenticated;

revoke all on table public.vgi_heatmap_points
  from anon, authenticated;

revoke all on table public.vgi_companies
  from anon, authenticated;

revoke all on table public.vgi_intelligence_scores
  from anon, authenticated;

grant all on table public.vgi_visitors to service_role;
grant all on table public.vgi_sessions to service_role;
grant all on table public.vgi_page_views to service_role;
grant all on table public.vgi_events to service_role;
grant all on table public.vgi_heatmap_points to service_role;
grant all on table public.vgi_companies to service_role;
grant all on table public.vgi_intelligence_scores to service_role;

grant usage, select
  on all sequences in schema public
  to service_role;

commit;
