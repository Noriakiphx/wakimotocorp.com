begin;

-- Aggregate the complete reporting window in PostgreSQL. The dashboard still
-- limits detail rows for response size, but totals and rankings remain exact.
create or replace function public.vgi_dashboard_rollup(p_since timestamptz)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'summary', jsonb_build_object(
      'visitors', (
        select count(*) from public.vgi_visitors where last_seen_at >= p_since
      ),
      'sessions', (
        select count(*) from public.vgi_sessions where started_at >= p_since
      ),
      'pageViews', (
        select count(*) from public.vgi_page_views where occurred_at >= p_since
      ),
      'events', (
        select count(*) from public.vgi_events where occurred_at >= p_since
      ),
      'conversions', (
        select count(*) filter (where converted)
        from public.vgi_sessions
        where started_at >= p_since
      ),
      'conversionRate', coalesce((
        select round(
          count(*) filter (where converted)::numeric
          / nullif(count(*), 0) * 100,
          1
        )
        from public.vgi_sessions
        where started_at >= p_since
      ), 0),
      'bounceRate', coalesce((
        select round(
          count(*) filter (
            where page_view_count <= 1 and event_count = 0
          )::numeric / nullif(count(*), 0) * 100,
          1
        )
        from public.vgi_sessions
        where started_at >= p_since
      ), 0),
      'averageDurationSeconds', coalesce((
        select round(avg(coalesce(duration_seconds, 0)))
        from public.vgi_sessions
        where started_at >= p_since
      ), 0)
    ),
    'topPages', coalesce((
      select jsonb_agg(jsonb_build_object('label', label, 'value', value))
      from (
        select coalesce(nullif(page_path, ''), 'Unknown') as label, count(*) as value
        from public.vgi_page_views
        where occurred_at >= p_since
        group by 1
        order by value desc, label
        limit 15
      ) ranked_pages
    ), '[]'::jsonb),
    'topReferrers', coalesce((
      select jsonb_agg(jsonb_build_object('label', label, 'value', value))
      from (
        select coalesce(nullif(referrer_host, ''), 'Unknown') as label,
          count(*) as value
        from public.vgi_page_views
        where occurred_at >= p_since
        group by 1
        order by value desc, label
        limit 15
      ) ranked_referrers
    ), '[]'::jsonb),
    'topLocations', coalesce((
      select jsonb_agg(jsonb_build_object('label', label, 'value', value))
      from (
        select coalesce(
          nullif(concat_ws(
            ' / ',
            nullif(country_code, ''),
            nullif(region_name, ''),
            nullif(city, '')
          ), ''),
          'Unknown'
        ) as label,
        count(*) as value
        from public.vgi_visitors
        where last_seen_at >= p_since
        group by 1
        order by value desc, label
        limit 15
      ) ranked_locations
    ), '[]'::jsonb)
  );
$$;

revoke all on function public.vgi_dashboard_rollup(timestamptz) from public;
revoke all on function public.vgi_dashboard_rollup(timestamptz) from anon, authenticated;
grant execute on function public.vgi_dashboard_rollup(timestamptz) to service_role;

commit;
