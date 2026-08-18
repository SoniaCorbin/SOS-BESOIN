-- La table profiles contenait email, telephone, GPS, fcm_token et
-- stripe_account_id lisibles publiquement (policy profiles_public_read,
-- qual=true). On introduit une vue ne contenant que les colonnes
-- publiques nécessaires à l'affichage (offres, chat, listing), et une
-- policy permettant aux admins de lire tous les profils complets.

create view public_profiles as
select id, full_name, avatar_url, rating, total_missions, is_kyc_verified, role
from profiles;

grant select on public_profiles to anon, authenticated;

create policy "admin_read_all_profiles"
on profiles for select
using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
