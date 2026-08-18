-- Une fois profiles_public_read supprimée (20260818091000), les policies
-- admin_read_all_profiles / admin_update_profiles se sont mises à
-- provoquer "infinite recursion detected in policy for relation
-- profiles" (42P17) : elles interrogent profiles pour vérifier is_admin,
-- ce qui redéclenche RLS sur profiles, etc. On sort la vérification
-- dans une fonction SECURITY DEFINER qui contourne RLS pour cette
-- lecture interne uniquement.

create or replace function public.is_admin(uid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(is_admin, false) from profiles where id = uid;
$$;

drop policy admin_read_all_profiles on profiles;
create policy admin_read_all_profiles
on profiles for select
using (is_admin(auth.uid()));

drop policy admin_update_profiles on profiles;
create policy admin_update_profiles
on profiles for update
using (is_admin(auth.uid()));
