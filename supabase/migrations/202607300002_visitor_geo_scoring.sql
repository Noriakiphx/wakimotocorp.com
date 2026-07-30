begin;

-- ============================================================
-- Visitor Geo Intelligence
-- Phase 04: Intelligence Scoring
-- ============================================================

create or replace function visitor_intelligence.clamp_score(
  score_value numeric
)
returns numeric
language sql
immutable
as $$
  select greatest(
    0::numeric,
    least(100::numeric, coalesce(score_value, 0::numeric))
  );
$$;

comment on function visitor_intelligence.clamp_score(numeric) is
  'Restricts an intelligence score to the range 0–100';


create or replace function visitor_intelligence.calculate_visitor_score(
  target_visitor_id uuid
)
returns table (
  total_score numeric,
  engagement_score numeric,
  recency_score numeric,
  return_score numeric,
  conversion_score numeric,
  source_score numeric,
  company_score numeric,
  score_breakdown jsonb
)
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  visitor_record public.vgi_visitors%rowtype;

  session_count_value bigint := 0;
  page_view_count_value bigint := 0;
  event_count_value bigint := 0;
  converted_session_count bigint := 0;

  total_duration_seconds bigint := 0;
  maximum_scroll_percent_value integer := 0;

  hours_since_last_seen numeric := 999999;

  engagement_value numeric := 0;
  recency_value numeric := 0;
  return_value numeric := 0;
  conversion_value numeric := 0;
  source_value numeric := 0;
  company_value numeric := 0;
  final_value numeric := 0;
begin
  select *
  into visitor_record
  from public.vgi_visitors
  where id = target_visitor_id;

  if not found then
    raise exception 'Visitor not found: %', target_visitor_id;
  end if;

  select
    count(*),
    coalesce(sum(coalesce(duration_seconds, 0)), 0),
    coalesce(max(maximum_scroll_percent), 0),
    count(*) filter (where converted is true)
  into
    session_count_value,
    total_duration_seconds,
    maximum_scroll_percent_value,
    converted_session_count
  from public.vgi_sessions
  where visitor_id = target_visitor_id;

  select count(*)
  into page_view_count_value
  from public.vgi_page_views
  where visitor_id = target_visitor_id;

  select count(*)
  into event_count_value
  from public.vgi_events
  where visitor_id = target_visitor_id;

  hours_since_last_seen :=
    greatest(
      0,
      extract(
        epoch from (now() - visitor_record.last_seen_at)
      ) / 3600
    );

  -- ----------------------------------------------------------
  -- Engagement: maximum 35 points
  -- ----------------------------------------------------------
  engagement_value :=
      least(page_view_count_value, 10) * 1.2
    + least(event_count_value, 20) * 0.35
    + least(total_duration_seconds, 900) / 900.0 * 10
    + least(maximum_scroll_percent_value, 100) / 100.0 * 6;

  engagement_value :=
    least(35, greatest(0, engagement_value));

  -- ----------------------------------------------------------
  -- Recency: maximum 20 points
  -- ----------------------------------------------------------
  recency_value :=
    case
      when hours_since_last_seen <= 1 then 20
      when hours_since_last_seen <= 24 then 16
      when hours_since_last_seen <= 72 then 12
      when hours_since_last_seen <= 168 then 8
      when hours_since_last_seen <= 720 then 4
      else 0
    end;

  -- ----------------------------------------------------------
  -- Return frequency: maximum 15 points
  -- ----------------------------------------------------------
  return_value :=
    least(
      15,
      greatest(
        0,
        (greatest(visitor_record.visit_count, session_count_value) - 1) * 3
      )
    );

  -- ----------------------------------------------------------
  -- Conversion: maximum 15 points
  -- ----------------------------------------------------------
  conversion_value :=
    case
      when converted_session_count >= 2 then 15
      when converted_session_count = 1 then 12
      else
        least(
          8,
          (
            select count(*) * 2
            from public.vgi_events
            where visitor_id = target_visitor_id
              and lower(coalesce(event_name, '')) in (
                'conversion',
                'contact',
                'contact_submit',
                'form_submit',
                'quote_request',
                'phone_click',
                'email_click',
                'purchase'
              )
          )
        )
    end;

  -- ----------------------------------------------------------
  -- Acquisition quality: maximum 10 points
  -- ----------------------------------------------------------
  source_value :=
    case
      when lower(coalesce(visitor_record.latest_utm_medium, '')) in (
        'cpc',
        'ppc',
        'paid',
        'paid_search',
        'display'
      ) then 8

      when lower(coalesce(visitor_record.latest_utm_medium, '')) in (
        'email',
        'newsletter'
      ) then 7

      when lower(coalesce(visitor_record.latest_utm_medium, '')) in (
        'organic',
        'seo'
      ) then 6

      when visitor_record.latest_referrer_host is not null
        and visitor_record.latest_referrer_host <> ''
      then 4

      when visitor_record.first_referrer_host is not null
        and visitor_record.first_referrer_host <> ''
      then 3

      else 2
    end;

  -- ----------------------------------------------------------
  -- Company identification: maximum 5 points
  -- ----------------------------------------------------------
  company_value :=
    case
      when visitor_record.company_id is not null then 5
      else 0
    end;

  final_value :=
    visitor_intelligence.clamp_score(
        engagement_value
      + recency_value
      + return_value
      + conversion_value
      + source_value
      + company_value
    );

  return query
  select
    round(final_value, 2),
    round(engagement_value, 2),
    round(recency_value, 2),
    round(return_value, 2),
    round(conversion_value, 2),
    round(source_value, 2),
    round(company_value, 2),
    jsonb_build_object(
      'version', 'v1',
      'calculated_at', now(),
      'metrics', jsonb_build_object(
        'sessions', session_count_value,
        'page_views', page_view_count_value,
        'events', event_count_value,
        'converted_sessions', converted_session_count,
        'duration_seconds', total_duration_seconds,
        'maximum_scroll_percent', maximum_scroll_percent_value,
        'hours_since_last_seen', round(hours_since_last_seen, 2)
      ),
      'components', jsonb_build_object(
        'engagement', round(engagement_value, 2),
        'recency', round(recency_value, 2),
        'return_frequency', round(return_value, 2),
        'conversion', round(conversion_value, 2),
        'acquisition_source', round(source_value, 2),
        'company_identification', round(company_value, 2)
      )
    );
end;
$$;

comment on function
  visitor_intelligence.calculate_visitor_score(uuid)
is
  'Calculates a privacy-conscious visitor intelligence score from 0 to 100';


create or replace function visitor_intelligence.refresh_visitor_score(
  target_visitor_id uuid
)
returns numeric
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  calculated record;
begin
  select *
  into calculated
  from visitor_intelligence.calculate_visitor_score(target_visitor_id);

  update public.vgi_visitors
  set
    intelligence_score = calculated.total_score,
    updated_at = now()
  where id = target_visitor_id;

  insert into public.vgi_intelligence_scores (
    visitor_id,
    score,
    engagement_score,
    recency_score,
    return_score,
    conversion_score,
    source_score,
    company_score,
    score_breakdown,
    calculated_at
  )
  values (
    target_visitor_id,
    calculated.total_score,
    calculated.engagement_score,
    calculated.recency_score,
    calculated.return_score,
    calculated.conversion_score,
    calculated.source_score,
    calculated.company_score,
    calculated.score_breakdown,
    now()
  );

  return calculated.total_score;
end;
$$;

comment on function
  visitor_intelligence.refresh_visitor_score(uuid)
is
  'Recalculates the current visitor score and records its score history';


create or replace function visitor_intelligence.refresh_all_visitor_scores()
returns table (
  visitor_id uuid,
  intelligence_score numeric
)
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  visitor_item record;
begin
  for visitor_item in
    select id
    from public.vgi_visitors
  loop
    visitor_id := visitor_item.id;
    intelligence_score :=
      visitor_intelligence.refresh_visitor_score(visitor_item.id);

    return next;
  end loop;
end;
$$;

comment on function
  visitor_intelligence.refresh_all_visitor_scores()
is
  'Recalculates intelligence scores for every visitor';


create or replace function visitor_intelligence.queue_score_refresh()
returns trigger
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  affected_visitor_id uuid;
begin
  affected_visitor_id :=
    case
      when tg_op = 'DELETE' then old.visitor_id
      else new.visitor_id
    end;

  if affected_visitor_id is not null then
    perform visitor_intelligence.refresh_visitor_score(
      affected_visitor_id
    );
  end if;

  return coalesce(new, old);
end;
$$;


drop trigger if exists vgi_sessions_refresh_score
  on public.vgi_sessions;

create trigger vgi_sessions_refresh_score
after insert or update or delete
on public.vgi_sessions
for each row
execute function visitor_intelligence.queue_score_refresh();


drop trigger if exists vgi_page_views_refresh_score
  on public.vgi_page_views;

create trigger vgi_page_views_refresh_score
after insert or update or delete
on public.vgi_page_views
for each row
execute function visitor_intelligence.queue_score_refresh();


drop trigger if exists vgi_events_refresh_score
  on public.vgi_events;

create trigger vgi_events_refresh_score
after insert or update or delete
on public.vgi_events
for each row
execute function visitor_intelligence.queue_score_refresh();


revoke all on function
  visitor_intelligence.calculate_visitor_score(uuid)
from public, anon, authenticated;

revoke all on function
  visitor_intelligence.refresh_visitor_score(uuid)
from public, anon, authenticated;

revoke all on function
  visitor_intelligence.refresh_all_visitor_scores()
from public, anon, authenticated;

grant execute on function
  visitor_intelligence.calculate_visitor_score(uuid)
to service_role;

grant execute on function
  visitor_intelligence.refresh_visitor_score(uuid)
to service_role;

grant execute on function
  visitor_intelligence.refresh_all_visitor_scores()
to service_role;

commit;
