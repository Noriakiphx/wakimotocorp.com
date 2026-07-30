begin;

-- ============================================================
-- Visitor Geo Intelligence
-- Phase 06: Privacy-conscious heatmap
-- ============================================================

alter table public.vgi_heatmap_points
  add column if not exists visitor_id uuid
    references public.vgi_visitors(id)
    on delete cascade,

  add column if not exists session_id uuid
    references public.vgi_sessions(id)
    on delete cascade,

  add column if not exists event_key text,
  add column if not exists occurred_at timestamptz not null default now(),
  add column if not exists page_path text,
  add column if not exists point_type text,
  add column if not exists x_percent numeric(5,2),
  add column if not exists y_percent numeric(5,2),
  add column if not exists scroll_percent integer,
  add column if not exists viewport_width integer,
  add column if not exists viewport_height integer,
  add column if not exists element_tag text,
  add column if not exists element_role text,
  add column if not exists element_label text,
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now();

alter table public.vgi_heatmap_points
  drop constraint if exists vgi_heatmap_points_point_type_check;

alter table public.vgi_heatmap_points
  add constraint vgi_heatmap_points_point_type_check
  check (
    point_type is null
    or point_type in (
      'click',
      'scroll',
      'attention',
      'exit'
    )
  );

alter table public.vgi_heatmap_points
  drop constraint if exists vgi_heatmap_points_x_percent_check;

alter table public.vgi_heatmap_points
  add constraint vgi_heatmap_points_x_percent_check
  check (
    x_percent is null
    or (
      x_percent >= 0
      and x_percent <= 100
    )
  );

alter table public.vgi_heatmap_points
  drop constraint if exists vgi_heatmap_points_y_percent_check;

alter table public.vgi_heatmap_points
  add constraint vgi_heatmap_points_y_percent_check
  check (
    y_percent is null
    or (
      y_percent >= 0
      and y_percent <= 100
    )
  );

alter table public.vgi_heatmap_points
  drop constraint if exists vgi_heatmap_points_scroll_percent_check;

alter table public.vgi_heatmap_points
  add constraint vgi_heatmap_points_scroll_percent_check
  check (
    scroll_percent is null
    or (
      scroll_percent >= 0
      and scroll_percent <= 100
    )
  );

create unique index if not exists
  vgi_heatmap_points_event_key_uidx
on public.vgi_heatmap_points(event_key)
where event_key is not null;

create index if not exists
  vgi_heatmap_points_page_time_idx
on public.vgi_heatmap_points(
  page_path,
  occurred_at desc
);

create index if not exists
  vgi_heatmap_points_session_idx
on public.vgi_heatmap_points(
  session_id,
  occurred_at desc
);

create index if not exists
  vgi_heatmap_points_type_idx
on public.vgi_heatmap_points(
  point_type,
  occurred_at desc
);

create or replace function visitor_intelligence.record_heatmap_point(
  target_visitor_id uuid,
  target_session_id uuid,
  event_key_value text,
  occurred_at_value timestamptz,
  page_path_value text,
  point_type_value text,
  x_percent_value numeric default null,
  y_percent_value numeric default null,
  scroll_percent_value integer default null,
  viewport_width_value integer default null,
  viewport_height_value integer default null,
  element_tag_value text default null,
  element_role_value text default null,
  element_label_value text default null,
  metadata_value jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  inserted_id uuid;
begin
  if target_visitor_id is null then
    raise exception 'target_visitor_id is required';
  end if;

  if target_session_id is null then
    raise exception 'target_session_id is required';
  end if;

  if point_type_value not in (
    'click',
    'scroll',
    'attention',
    'exit'
  ) then
    raise exception 'Invalid heatmap point type';
  end if;

  insert into public.vgi_heatmap_points (
    visitor_id,
    session_id,
    event_key,
    occurred_at,
    page_path,
    point_type,
    x_percent,
    y_percent,
    scroll_percent,
    viewport_width,
    viewport_height,
    element_tag,
    element_role,
    element_label,
    metadata
  )
  values (
    target_visitor_id,
    target_session_id,
    nullif(left(event_key_value, 128), ''),
    coalesce(occurred_at_value, now()),
    left(coalesce(page_path_value, '/'), 1000),
    point_type_value,
    case
      when x_percent_value is null then null
      else greatest(0, least(100, x_percent_value))
    end,
    case
      when y_percent_value is null then null
      else greatest(0, least(100, y_percent_value))
    end,
    case
      when scroll_percent_value is null then null
      else greatest(0, least(100, scroll_percent_value))
    end,
    case
      when viewport_width_value is null then null
      else greatest(0, viewport_width_value)
    end,
    case
      when viewport_height_value is null then null
      else greatest(0, viewport_height_value)
    end,
    nullif(left(element_tag_value, 64), ''),
    nullif(left(element_role_value, 128), ''),
    nullif(left(element_label_value, 200), ''),
    coalesce(metadata_value, '{}'::jsonb)
  )
  on conflict (event_key)
    where event_key is not null
  do update
  set
    occurred_at = excluded.occurred_at,
    scroll_percent = greatest(
      coalesce(public.vgi_heatmap_points.scroll_percent, 0),
      coalesce(excluded.scroll_percent, 0)
    ),
    metadata =
      coalesce(public.vgi_heatmap_points.metadata, '{}'::jsonb)
      || coalesce(excluded.metadata, '{}'::jsonb)
  returning id into inserted_id;

  return inserted_id;
end;
$$;

revoke all on function visitor_intelligence.record_heatmap_point(
  uuid,
  uuid,
  text,
  timestamptz,
  text,
  text,
  numeric,
  numeric,
  integer,
  integer,
  integer,
  text,
  text,
  text,
  jsonb
)
from public, anon, authenticated;

grant execute on function visitor_intelligence.record_heatmap_point(
  uuid,
  uuid,
  text,
  timestamptz,
  text,
  text,
  numeric,
  numeric,
  integer,
  integer,
  integer,
  text,
  text,
  text,
  jsonb
)
to service_role;

commit;
