begin;

-- ============================================================
-- Visitor Geo Intelligence
-- Phase 05: Company Detection
--
-- Privacy principles:
-- - Never persist raw IP addresses.
-- - Store only a one-way lookup hash for cache deduplication.
-- - Separate likely businesses from ISP, hosting, VPN and Tor.
-- ============================================================

alter table public.vgi_companies
  add column if not exists normalized_name text,
  add column if not exists domain text,
  add column if not exists asn text,
  add column if not exists as_name text,
  add column if not exists organization_name text,
  add column if not exists organization_type text,
  add column if not exists country_code text,
  add column if not exists region_name text,
  add column if not exists city text,
  add column if not exists confidence_score numeric(5, 2),
  add column if not exists is_business boolean not null default false,
  add column if not exists is_isp boolean not null default false,
  add column if not exists is_hosting boolean not null default false,
  add column if not exists is_vpn boolean not null default false,
  add column if not exists is_proxy boolean not null default false,
  add column if not exists is_tor boolean not null default false,
  add column if not exists provider_name text,
  add column if not exists provider_reference text,
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists first_detected_at timestamptz not null default now(),
  add column if not exists last_detected_at timestamptz not null default now(),
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

comment on table public.vgi_companies is
  'Privacy-conscious organization and network ownership intelligence';

comment on column public.vgi_companies.confidence_score is
  'Company identification confidence from 0 to 100';

comment on column public.vgi_companies.is_business is
  'True only when the network is likely operated by an identifiable organization';

comment on column public.vgi_companies.provider_reference is
  'Non-sensitive provider record identifier; never a raw IP address';


alter table public.vgi_companies
  drop constraint if exists vgi_companies_confidence_score_check;

alter table public.vgi_companies
  add constraint vgi_companies_confidence_score_check
  check (
    confidence_score is null
    or (
      confidence_score >= 0
      and confidence_score <= 100
    )
  );


create table if not exists public.vgi_company_matches (
  id uuid primary key default gen_random_uuid(),

  visitor_id uuid not null
    references public.vgi_visitors(id)
    on delete cascade,

  company_id uuid
    references public.vgi_companies(id)
    on delete set null,

  lookup_hash text not null,

  matched_at timestamptz not null default now(),

  confidence_score numeric(5, 2)
    check (
      confidence_score is null
      or (
        confidence_score >= 0
        and confidence_score <= 100
      )
    ),

  match_method text not null default 'network_lookup'
    check (
      match_method in (
        'network_lookup',
        'asn',
        'reverse_dns',
        'domain',
        'manual',
        'unknown'
      )
    ),

  decision text not null default 'unknown'
    check (
      decision in (
        'business',
        'isp',
        'hosting',
        'vpn',
        'proxy',
        'tor',
        'residential',
        'unknown'
      )
    ),

  provider_name text,

  raw_response_summary jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

comment on table public.vgi_company_matches is
  'Audit history for company detection without raw IP address storage';

comment on column public.vgi_company_matches.lookup_hash is
  'One-way HMAC hash generated from the source network address';

comment on column public.vgi_company_matches.raw_response_summary is
  'Allow-listed provider fields only; must never contain a raw IP address';


-- Non-unique lookup indexes are used here because multiple provider
-- records can legitimately resolve to the same ASN or normalized name.
drop index if exists public.vgi_companies_asn_normalized_name_uidx;

create index if not exists
  vgi_companies_asn_normalized_name_idx
on public.vgi_companies (
  asn,
  normalized_name
)
where
  asn is not null
  or normalized_name is not null;


create index if not exists
  vgi_companies_domain_idx
on public.vgi_companies(domain);


create index if not exists
  vgi_companies_business_idx
on public.vgi_companies(is_business, confidence_score desc);


create index if not exists
  vgi_company_matches_visitor_idx
on public.vgi_company_matches(visitor_id, matched_at desc);


create index if not exists
  vgi_company_matches_company_idx
on public.vgi_company_matches(company_id, matched_at desc);


create index if not exists
  vgi_company_matches_lookup_hash_idx
on public.vgi_company_matches(lookup_hash, matched_at desc);


create or replace function
visitor_intelligence.normalize_company_name(
  input_name text
)
returns text
language sql
immutable
as $$
  select nullif(
    trim(
      regexp_replace(
        regexp_replace(
          lower(coalesce(input_name, '')),
          '\m(incorporated|inc|limited|ltd|llc|corp|corporation|company|co|株式会社|有限会社|合同会社)\M\.?',
          '',
          'gi'
        ),
        '[^[:alnum:]\p{Han}\p{Hiragana}\p{Katakana}]+',
        ' ',
        'g'
      )
    ),
    ''
  );
$$;

comment on function
visitor_intelligence.normalize_company_name(text)
is
  'Normalizes company names for privacy-conscious matching and deduplication';


create or replace function
visitor_intelligence.classify_network_owner(
  organization_name text,
  as_name text,
  provider_flags jsonb default '{}'::jsonb
)
returns text
language plpgsql
immutable
as $$
declare
  combined_name text;
begin
  if coalesce((provider_flags ->> 'is_tor')::boolean, false) then
    return 'tor';
  end if;

  if coalesce((provider_flags ->> 'is_vpn')::boolean, false) then
    return 'vpn';
  end if;

  if coalesce((provider_flags ->> 'is_proxy')::boolean, false) then
    return 'proxy';
  end if;

  if coalesce((provider_flags ->> 'is_hosting')::boolean, false) then
    return 'hosting';
  end if;

  if coalesce((provider_flags ->> 'is_isp')::boolean, false) then
    return 'isp';
  end if;

  combined_name :=
    lower(
      coalesce(organization_name, '')
      || ' '
      || coalesce(as_name, '')
    );

  if combined_name ~
    '(amazon|aws|google cloud|microsoft azure|cloudflare|digitalocean|linode|akamai|hosting|datacenter|data center|vps|server)'
  then
    return 'hosting';
  end if;

  if combined_name ~
    '(telecom|communications|broadband|mobile|internet service|network services|ntt|softbank|kddi|docomo|isp)'
  then
    return 'isp';
  end if;

  if trim(combined_name) <> '' then
    return 'business';
  end if;

  return 'unknown';
end;
$$;

comment on function
visitor_intelligence.classify_network_owner(text, text, jsonb)
is
  'Classifies a network as business, ISP, hosting, VPN, proxy, Tor or unknown';


create or replace function
visitor_intelligence.company_confidence(
  organization_name text,
  domain_name text,
  asn_value text,
  decision_value text,
  provider_confidence numeric default null
)
returns numeric
language plpgsql
immutable
as $$
declare
  calculated numeric := 0;
begin
  if provider_confidence is not null then
    calculated :=
      greatest(0, least(100, provider_confidence));
  end if;

  if nullif(trim(coalesce(organization_name, '')), '') is not null then
    calculated := greatest(calculated, 45);
  end if;

  if nullif(trim(coalesce(asn_value, '')), '') is not null then
    calculated := greatest(calculated, 55);
  end if;

  if nullif(trim(coalesce(domain_name, '')), '') is not null then
    calculated := greatest(calculated, 75);
  end if;

  if decision_value = 'business' then
    calculated := greatest(calculated, 60);
  end if;

  if decision_value in (
    'isp',
    'hosting',
    'vpn',
    'proxy',
    'tor',
    'residential',
    'unknown'
  ) then
    calculated := least(calculated, 49);
  end if;

  return round(
    greatest(0, least(100, calculated)),
    2
  );
end;
$$;

comment on function
visitor_intelligence.company_confidence(text, text, text, text, numeric)
is
  'Returns company-identification confidence from 0 to 100';


create or replace function
visitor_intelligence.attach_company_match(
  target_visitor_id uuid,
  lookup_hash_value text,
  organization_name_value text default null,
  domain_value text default null,
  asn_value text default null,
  as_name_value text default null,
  country_code_value text default null,
  region_name_value text default null,
  city_value text default null,
  provider_name_value text default null,
  provider_reference_value text default null,
  provider_confidence_value numeric default null,
  provider_flags_value jsonb default '{}'::jsonb,
  safe_metadata_value jsonb default '{}'::jsonb
)
returns table (
  company_id uuid,
  decision text,
  confidence_score numeric
)
language plpgsql
security definer
set search_path = public, visitor_intelligence
as $$
declare
  detected_company_id uuid;
  detected_decision text;
  detected_confidence numeric;
  normalized_company_name text;
  business_match boolean;
begin
  if target_visitor_id is null then
    raise exception 'target_visitor_id is required';
  end if;

  if nullif(trim(coalesce(lookup_hash_value, '')), '') is null then
    raise exception 'lookup_hash_value is required';
  end if;

  if not exists (
    select 1
    from public.vgi_visitors
    where id = target_visitor_id
  ) then
    raise exception 'Visitor not found: %', target_visitor_id;
  end if;

  normalized_company_name :=
    visitor_intelligence.normalize_company_name(
      organization_name_value
    );

  detected_decision :=
    visitor_intelligence.classify_network_owner(
      organization_name_value,
      as_name_value,
      provider_flags_value
    );

  detected_confidence :=
    visitor_intelligence.company_confidence(
      organization_name_value,
      domain_value,
      asn_value,
      detected_decision,
      provider_confidence_value
    );

  business_match :=
    detected_decision = 'business'
    and detected_confidence >= 60;

  if business_match then
    select id
    into detected_company_id
    from public.vgi_companies
    where
      (
        asn_value is not null
        and asn = asn_value
      )
      or
      (
        normalized_company_name is not null
        and normalized_name = normalized_company_name
      )
      or
      (
        domain_value is not null
        and domain = lower(domain_value)
      )
    order by
      case
        when domain = lower(domain_value) then 1
        when asn = asn_value then 2
        else 3
      end
    limit 1;

    if detected_company_id is null then
      insert into public.vgi_companies (
        name,
        normalized_name,
        domain,
        asn,
        as_name,
        organization_name,
        organization_type,
        country_code,
        region_name,
        city,
        confidence_score,
        is_business,
        is_isp,
        is_hosting,
        is_vpn,
        is_proxy,
        is_tor,
        provider_name,
        provider_reference,
        metadata,
        first_detected_at,
        last_detected_at
      )
      values (
        coalesce(
          nullif(trim(organization_name_value), ''),
          nullif(trim(as_name_value), ''),
          'Unknown organization'
        ),
        normalized_company_name,
        lower(nullif(trim(domain_value), '')),
        nullif(trim(asn_value), ''),
        nullif(trim(as_name_value), ''),
        nullif(trim(organization_name_value), ''),
        detected_decision,
        nullif(trim(country_code_value), ''),
        nullif(trim(region_name_value), ''),
        nullif(trim(city_value), ''),
        detected_confidence,
        true,
        false,
        false,
        false,
        false,
        false,
        nullif(trim(provider_name_value), ''),
        nullif(trim(provider_reference_value), ''),
        coalesce(safe_metadata_value, '{}'::jsonb),
        now(),
        now()
      )
      returning id
      into detected_company_id;
    else
      update public.vgi_companies
      set
        name = coalesce(
          nullif(trim(organization_name_value), ''),
          name
        ),
        normalized_name = coalesce(
          normalized_company_name,
          normalized_name
        ),
        domain = coalesce(
          lower(nullif(trim(domain_value), '')),
          domain
        ),
        asn = coalesce(
          nullif(trim(asn_value), ''),
          asn
        ),
        as_name = coalesce(
          nullif(trim(as_name_value), ''),
          as_name
        ),
        organization_name = coalesce(
          nullif(trim(organization_name_value), ''),
          organization_name
        ),
        organization_type = detected_decision,
        country_code = coalesce(
          nullif(trim(country_code_value), ''),
          country_code
        ),
        region_name = coalesce(
          nullif(trim(region_name_value), ''),
          region_name
        ),
        city = coalesce(
          nullif(trim(city_value), ''),
          city
        ),
        confidence_score = greatest(
          coalesce(confidence_score, 0),
          detected_confidence
        ),
        is_business = true,
        provider_name = coalesce(
          nullif(trim(provider_name_value), ''),
          provider_name
        ),
        provider_reference = coalesce(
          nullif(trim(provider_reference_value), ''),
          provider_reference
        ),
        metadata =
          coalesce(metadata, '{}'::jsonb)
          || coalesce(safe_metadata_value, '{}'::jsonb),
        last_detected_at = now(),
        updated_at = now()
      where id = detected_company_id;
    end if;

    update public.vgi_visitors
    set
      company_id = detected_company_id,
      updated_at = now()
    where id = target_visitor_id;
  else
    detected_company_id := null;

    update public.vgi_visitors
    set
      company_id = null,
      updated_at = now()
    where id = target_visitor_id;
  end if;

  insert into public.vgi_company_matches (
    visitor_id,
    company_id,
    lookup_hash,
    confidence_score,
    match_method,
    decision,
    provider_name,
    raw_response_summary
  )
  values (
    target_visitor_id,
    detected_company_id,
    lookup_hash_value,
    detected_confidence,
    case
      when domain_value is not null then 'domain'
      when asn_value is not null then 'asn'
      else 'network_lookup'
    end,
    detected_decision,
    nullif(trim(provider_name_value), ''),
    jsonb_strip_nulls(
      jsonb_build_object(
        'asn', asn_value,
        'as_name', as_name_value,
        'organization_name', organization_name_value,
        'domain', domain_value,
        'country_code', country_code_value,
        'region_name', region_name_value,
        'city', city_value,
        'flags', coalesce(provider_flags_value, '{}'::jsonb)
      )
    )
  );

  if to_regprocedure(
    'visitor_intelligence.refresh_visitor_score(uuid)'
  ) is not null then
    perform visitor_intelligence.refresh_visitor_score(
      target_visitor_id
    );
  end if;

  return query
  select
    detected_company_id,
    detected_decision,
    detected_confidence;
end;
$$;

comment on function
visitor_intelligence.attach_company_match(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  jsonb
)
is
  'Attaches privacy-safe company intelligence to a visitor';


drop trigger if exists vgi_companies_set_updated_at
  on public.vgi_companies;

create trigger vgi_companies_set_updated_at
before update on public.vgi_companies
for each row
execute function visitor_intelligence.set_updated_at();


alter table public.vgi_company_matches
  enable row level security;


revoke all on table public.vgi_company_matches
from public, anon, authenticated;

revoke all on function
visitor_intelligence.attach_company_match(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  jsonb
)
from public, anon, authenticated;


grant all on table public.vgi_company_matches
to service_role;

grant execute on function
visitor_intelligence.attach_company_match(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  jsonb
)
to service_role;

grant execute on function
visitor_intelligence.normalize_company_name(text)
to service_role;

grant execute on function
visitor_intelligence.classify_network_owner(text, text, jsonb)
to service_role;

grant execute on function
visitor_intelligence.company_confidence(
  text,
  text,
  text,
  text,
  numeric
)
to service_role;

commit;
