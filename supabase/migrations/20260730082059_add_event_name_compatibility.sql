begin;

alter table public.vgi_events
  add column if not exists event_name text
  generated always as (
    coalesce(event_action, event_type)
  ) stored;

comment on column public.vgi_events.event_name is
  'Compatibility alias used by visitor-intelligence scoring';

commit;
