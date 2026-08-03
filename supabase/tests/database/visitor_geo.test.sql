begin;

create extension if not exists pgtap;

select plan(23);

select has_table(
  'public',
  'vgi_visitors',
  'vgi_visitors exists'
);

select has_table(
  'public',
  'vgi_sessions',
  'vgi_sessions exists'
);

select has_table(
  'public',
  'vgi_heatmap_points',
  'vgi_heatmap_points exists'
);

select has_table(
  'public',
  'vgi_companies',
  'vgi_companies exists'
);

select has_table(
  'public',
  'vgi_company_matches',
  'vgi_company_matches exists'
);

select has_table(
  'public',
  'vgi_notification_rules',
  'vgi_notification_rules exists'
);

select has_table(
  'public',
  'vgi_notification_queue',
  'vgi_notification_queue exists'
);

select has_column(
  'public',
  'vgi_visitors',
  'intelligence_score',
  'visitor score column exists'
);

select has_column(
  'public',
  'vgi_visitors',
  'company_id',
  'visitor company column exists'
);

select has_column(
  'public',
  'vgi_heatmap_points',
  'x_percent',
  'heatmap x percentage exists'
);

select has_column(
  'public',
  'vgi_heatmap_points',
  'y_percent',
  'heatmap y percentage exists'
);

select has_function(
  'visitor_intelligence',
  'calculate_visitor_score',
  array['uuid'],
  'score calculation exists'
);

select has_function(
  'public',
  'vgi_dashboard_rollup',
  array['timestamp with time zone'],
  'dashboard rollup exists'
);

insert into public.vgi_visitors (
  id, visitor_key, last_seen_at, country_code, region_name, city
) values
  (
    '10000000-0000-0000-0000-000000000001',
    'dashboard-test-1',
    now(),
    'JP',
    'Tokyo',
    'Chiyoda'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'dashboard-test-2',
    now(),
    'JP',
    'Tokyo',
    'Chiyoda'
  );

insert into public.vgi_sessions (
  id, session_key, visitor_id, started_at, last_activity_at,
  duration_seconds, converted
) values
  (
    '20000000-0000-0000-0000-000000000001',
    'dashboard-session-1',
    '10000000-0000-0000-0000-000000000001',
    now(),
    now(),
    10,
    true
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'dashboard-session-2',
    '10000000-0000-0000-0000-000000000002',
    now(),
    now(),
    20,
    false
  );

insert into public.vgi_page_views (
  visitor_id, session_id, event_key, occurred_at, page_path
) values
  (
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'dashboard-page-1',
    now(),
    '/dashboard-test'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    'dashboard-page-2',
    now(),
    '/dashboard-test'
  );

select is(
  (public.vgi_dashboard_rollup(now() - interval '1 day')
    -> 'summary' ->> 'sessions')::bigint,
  2::bigint,
  'dashboard rollup counts every session'
);

select is(
  (public.vgi_dashboard_rollup(now() - interval '1 day')
    -> 'summary' ->> 'conversionRate')::numeric,
  50.0::numeric,
  'dashboard rollup calculates conversion rate over the complete window'
);

select is(
  (public.vgi_dashboard_rollup(now() - interval '1 day')
    -> 'summary' ->> 'averageDurationSeconds')::numeric,
  15::numeric,
  'dashboard rollup calculates average duration over the complete window'
);

select is(
  (public.vgi_dashboard_rollup(now() - interval '1 day')
    -> 'topPages' -> 0 ->> 'value')::bigint,
  2::bigint,
  'dashboard rollup ranks pages over the complete window'
);

select has_function(
  'visitor_intelligence',
  'attach_company_match',
  array[
    'uuid',
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'numeric',
    'jsonb',
    'jsonb'
  ],
  'company matching exists'
);

select has_function(
  'visitor_intelligence',
  'record_heatmap_point',
  array[
    'uuid',
    'uuid',
    'text',
    'timestamp with time zone',
    'text',
    'text',
    'numeric',
    'numeric',
    'integer',
    'integer',
    'integer',
    'text',
    'text',
    'text',
    'jsonb'
  ],
  'heatmap recording exists'
);

select has_function(
  'visitor_intelligence',
  'enqueue_visitor_alerts',
  array['uuid'],
  'notification enqueue exists'
);

select is(
  visitor_intelligence.clamp_score(-10),
  0::numeric,
  'scores are clamped at zero'
);

select is(
  visitor_intelligence.clamp_score(150),
  100::numeric,
  'scores are clamped at 100'
);

select is(
  visitor_intelligence.classify_network_owner(
    'Example Corporation',
    'Example Network',
    '{}'::jsonb
  ),
  'business',
  'ordinary organization is classified as business'
);

select * from finish();

rollback;
