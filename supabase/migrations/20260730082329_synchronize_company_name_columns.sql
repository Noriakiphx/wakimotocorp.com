begin;

alter table public.vgi_companies
  add column if not exists name text;

update public.vgi_companies
set name = company_name
where name is null;

create or replace function
visitor_intelligence.synchronize_company_names()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, visitor_intelligence
as $function$
begin
  if tg_op = 'INSERT' then
    new.name := coalesce(new.name, new.company_name);
    new.company_name := coalesce(new.company_name, new.name);
  elsif new.name is distinct from old.name then
    new.company_name := new.name;
  elsif new.company_name is distinct from old.company_name then
    new.name := new.company_name;
  else
    new.name := coalesce(new.name, new.company_name);
    new.company_name := coalesce(new.company_name, new.name);
  end if;

  return new;
end;
$function$;

drop trigger if exists vgi_companies_synchronize_names
  on public.vgi_companies;

create trigger vgi_companies_synchronize_names
before insert or update on public.vgi_companies
for each row
execute function visitor_intelligence.synchronize_company_names();

comment on column public.vgi_companies.name is
  'Canonical compatibility name synchronized with company_name';

commit;
