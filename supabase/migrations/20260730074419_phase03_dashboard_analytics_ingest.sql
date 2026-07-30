begin;

-- Phase 03: query and idempotency support for analytics ingest/dashboard.
create unique index if not exists vgi_page_views_event_key_uidx
  on public.vgi_page_views (event_key)
  where event_key is not null;

create unique index if not exists vgi_events_event_key_uidx
  on public.vgi_events (event_key)
  where event_key is not null;

create index if not exists vgi_visitors_dashboard_idx
  on public.vgi_visitors (last_seen_at desc, intelligence_score desc);

create index if not exists vgi_sessions_dashboard_idx
  on public.vgi_sessions (started_at desc, converted);

create index if not exists vgi_page_views_dashboard_idx
  on public.vgi_page_views (occurred_at desc, page_path);

create index if not exists vgi_events_dashboard_idx
  on public.vgi_events (occurred_at desc, event_type);

-- All analytics tables remain service-role only. Edge Functions perform
-- validation and authorization before accessing them.
alter table public.vgi_visitors enable row level security;
alter table public.vgi_sessions enable row level security;
alter table public.vgi_page_views enable row level security;
alter table public.vgi_events enable row level security;

revoke all on table public.vgi_visitors from anon, authenticated;
revoke all on table public.vgi_sessions from anon, authenticated;
revoke all on table public.vgi_page_views from anon, authenticated;
revoke all on table public.vgi_events from anon, authenticated;

grant all on table public.vgi_visitors to service_role;
grant all on table public.vgi_sessions to service_role;
grant all on table public.vgi_page_views to service_role;
grant all on table public.vgi_events to service_role;

commit;
