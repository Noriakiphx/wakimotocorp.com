begin;

alter table public.vgi_intelligence_scores
  alter column score_type set default 'lead_intent',
  add column if not exists engagement_score numeric(5, 2),
  add column if not exists recency_score numeric(5, 2),
  add column if not exists return_score numeric(5, 2),
  add column if not exists conversion_score numeric(5, 2),
  add column if not exists source_score numeric(5, 2),
  add column if not exists company_score numeric(5, 2),
  add column if not exists score_breakdown jsonb
    not null default '{}'::jsonb;

comment on column public.vgi_intelligence_scores.score_breakdown is
  'Component-level explanation for the rule-based visitor score';

commit;
