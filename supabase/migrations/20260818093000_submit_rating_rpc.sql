-- Correction: la notation d'un prestataire mettait à jour profiles.rating /
-- profiles.total_missions directement depuis le client, ce qui est bloqué
-- silencieusement par la policy RLS "auth.uid() = id" (le client n'est pas
-- le prestataire). Cette fonction SECURITY DEFINER valide l'autorisation
-- côté serveur puis recalcule l'agrégat de façon fiable.

create or replace function public.submit_rating(
  p_request_id uuid,
  p_offer_id   uuid,
  p_rating     integer,
  p_comment    text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id       uuid;
  v_request_status  text;
  v_provider_id     uuid;
  v_offer_status    text;
  v_avg             numeric;
  v_count           integer;
begin
  if p_rating < 1 or p_rating > 5 then
    raise exception 'invalid_rating';
  end if;

  select client_id, status
    into v_client_id, v_request_status
  from requests
  where id = p_request_id;

  if v_client_id is null then
    raise exception 'request_not_found';
  end if;

  if v_client_id <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  select provider_id, status
    into v_provider_id, v_offer_status
  from offers
  where id = p_offer_id and request_id = p_request_id;

  if v_provider_id is null then
    raise exception 'offer_not_found';
  end if;

  if v_offer_status <> 'completed' or v_request_status <> 'completed' then
    raise exception 'mission_not_completed';
  end if;

  if exists (
    select 1 from ratings
    where request_id = p_request_id and offer_id = p_offer_id
  ) then
    update ratings
    set rating  = p_rating,
        comment = nullif(p_comment, '')
    where request_id = p_request_id and offer_id = p_offer_id;
  else
    insert into ratings (request_id, offer_id, client_id, provider_id, rating, comment)
    values (p_request_id, p_offer_id, v_client_id, v_provider_id, p_rating, nullif(p_comment, ''));
  end if;

  select avg(rating), count(*)
    into v_avg, v_count
  from ratings
  where provider_id = v_provider_id;

  update profiles
  set rating         = round(v_avg, 1),
      total_missions = v_count
  where id = v_provider_id;
end;
$$;

grant execute on function public.submit_rating(uuid, uuid, integer, text) to authenticated;
