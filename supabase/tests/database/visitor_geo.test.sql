begin;

create extension if not exists pgtap;

select plan(18);

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
