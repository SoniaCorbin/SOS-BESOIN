-- auto-validate-missions interrogeait offers.updated_at, colonne inexistante
-- (echec silencieux depuis toujours, offers.status="accepted" ne se
-- transformait jamais en "completed" automatiquement apres 3 jours).
alter table public.offers add column if not exists updated_at timestamptz not null default now();

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_offers_updated_at on public.offers;
create trigger set_offers_updated_at
  before update on public.offers
  for each row
  execute function public.set_updated_at();
