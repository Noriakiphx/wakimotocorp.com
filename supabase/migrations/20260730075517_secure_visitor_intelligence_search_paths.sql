begin;

alter function visitor_intelligence.clamp_score(numeric)
  set search_path = pg_catalog, public, visitor_intelligence;

alter function visitor_intelligence.normalize_company_name(text)
  set search_path = pg_catalog, public, visitor_intelligence;

alter function visitor_intelligence.classify_network_owner(text, text, jsonb)
  set search_path = pg_catalog, public, visitor_intelligence;

alter function visitor_intelligence.company_confidence(
  text,
  text,
  text,
  text,
  numeric
)
  set search_path = pg_catalog, public, visitor_intelligence;

commit;
