begin;

-- ============================================================
-- Visitor Geo Intelligence
-- Phase 07: Notification queue
-- ============================================================

create table if not exists public.vgi_notification_rules (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  enabled boolean not null default true,

  minimum_score numeric(5,2) not null default 70
    check (
      minimum_score >= 0
      and minimum_score <= 100
    ),

  require_company boolean not null default false,

  cooldown_minutes integer not null default 1440
    check (cooldown_minutes >= 0),

  destination_type text not null default 'webhook'
    check (
      destination_type in (
        'webhook',
        'email',
        'slack',
        'teams'
      )
    ),

  destination_label text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vgi_notification_queue (
  id uuid primary key default gen_random_uuid(),

  rule_id uuid
    references public.vgi_notification_rules(id)
    on delete set null,

  visitor_id uuid not null
    references public.vgi_visitors(id)
    on delete cascade,

  company_id uuid
    references public.vgi_companies(id)
    on delete set null,

  intelligence_score numeric(5,2),

  notification_type text not null default 'high_intent_visitor',

  status text not null default 'pending'
    check (
      status in (
        'pending',
        'processing',
        'sent',
        'failed',
        'skipped'
      )
    ),

  attempt_count integer not null default 0
    check (attempt_count >= 0),

  next_attempt_at timestamptz not null default now(),
  locked_at timestamptz,
  sent_at timestamptz,
  last_error text,

  payload jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists
  vgi_notification_queue_pending_idx
on public.vgi_notification_queue(
  status,
  next_attempt_at,
  created_at
);

create index if not exists
  vgi_notification_queue_visitor_idx
on public.vgi_notification_queue(
  visitor_id,
  created_at desc
);

create index if not exists
  vgi_notification_rules_enabled_idx
on public.vgi_notification_rules(
  enabled,
  minimum_score
);

insert into public.vgi_notification_rules (
  name,
  minimum_score,
  require_company,
  cooldown_minutes,
  destination_type,
  destination_label
)
select
  'High-intent visitor',
  75,
  false,
  1440,
  'webhook',
  'Primary alert webhook'
where not exists (
  select 1
  from public.vgi_notification_rules
  where name = 'High-intent visitor'
);

insert into public.vgi_notification_rules (
  name,
  minimum_score,
  require_company,
  cooldown_minutes,
  destination_type,
  destination_label
)
select
  'Identified company visitor',
  60,
  true,
  1440,
  'webhook',
  'Company visitor webhook'
where not exists (
  select 1
  from public.vgi_notification_rules
  where name = 'Identified company visitor'
);

create or replace function visitor_intelligence.enqueue_visitor_alerts(
  target_visitor_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  visitor_record record;
  rule_record record;
  inserted_count integer := 0;
begin
  select
    v.id,
    v.company_id,
    v.intelligence_score,
    v.country_code,
    v.region_name,
    v.city,
    v.latest_referrer_host,
    v.latest_utm_source,
    v.latest_utm_medium,
    c.name as company_name,
    c.domain as company_domain
  into visitor_record
  from public.vgi_visitors v
  left join public.vgi_companies c
    on c.id = v.company_id
  where v.id = target_visitor_id;

  if not found then
    return 0;
  end if;

  for rule_record in
    select *
    from public.vgi_notification_rules
    where enabled is true
      and coalesce(visitor_record.intelligence_score, 0)
        >= minimum_score
      and (
        require_company is false
        or visitor_record.company_id is not null
      )
  loop
    if not exists (
      select 1
      from public.vgi_notification_queue q
      where q.rule_id = rule_record.id
        and q.visitor_id = target_visitor_id
        and q.created_at >=
          now() - make_interval(
            mins => rule_record.cooldown_minutes
          )
        and q.status in (
          'pending',
          'processing',
          'sent'
        )
    ) then
      insert into public.vgi_notification_queue (
        rule_id,
        visitor_id,
        company_id,
        intelligence_score,
        payload
      )
      values (
        rule_record.id,
        target_visitor_id,
        visitor_record.company_id,
        visitor_record.intelligence_score,
        jsonb_strip_nulls(
          jsonb_build_object(
            'visitor_id', visitor_record.id,
            'score', visitor_record.intelligence_score,
            'country_code', visitor_record.country_code,
            'region_name', visitor_record.region_name,
            'city', visitor_record.city,
            'referrer_host', visitor_record.latest_referrer_host,
            'utm_source', visitor_record.latest_utm_source,
            'utm_medium', visitor_record.latest_utm_medium,
            'company_name', visitor_record.company_name,
            'company_domain', visitor_record.company_domain,
            'rule_name', rule_record.name
          )
        )
      );

      inserted_count := inserted_count + 1;
    end if;
  end loop;

  return inserted_count;
end;
$$;

create or replace function visitor_intelligence.score_alert_trigger()
returns trigger
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
begin
  if new.intelligence_score is not null
    and (
      old.intelligence_score is null
      or new.intelligence_score > old.intelligence_score
      or new.company_id is distinct from old.company_id
    )
  then
    perform visitor_intelligence.enqueue_visitor_alerts(new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists vgi_visitors_enqueue_alert
on public.vgi_visitors;

create trigger vgi_visitors_enqueue_alert
after update of intelligence_score, company_id
on public.vgi_visitors
for each row
execute function visitor_intelligence.score_alert_trigger();

create or replace function visitor_intelligence.claim_notification_batch(
  batch_size integer default 20
)
returns setof public.vgi_notification_queue
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
begin
  return query
  with selected as (
    select id
    from public.vgi_notification_queue
    where status = 'pending'
      and next_attempt_at <= now()
    order by created_at
    for update skip locked
    limit greatest(1, least(batch_size, 100))
  )
  update public.vgi_notification_queue q
  set
    status = 'processing',
    attempt_count = q.attempt_count + 1,
    locked_at = now(),
    updated_at = now()
  from selected
  where q.id = selected.id
  returning q.*;
end;
$$;

alter table public.vgi_notification_rules
  enable row level security;

alter table public.vgi_notification_queue
  enable row level security;

revoke all on table public.vgi_notification_rules
from public, anon, authenticated;

revoke all on table public.vgi_notification_queue
from public, anon, authenticated;

grant all on table public.vgi_notification_rules
to service_role;

grant all on table public.vgi_notification_queue
to service_role;

grant execute on function
visitor_intelligence.enqueue_visitor_alerts(uuid)
to service_role;

grant execute on function
visitor_intelligence.claim_notification_batch(integer)
to service_role;

commit;
