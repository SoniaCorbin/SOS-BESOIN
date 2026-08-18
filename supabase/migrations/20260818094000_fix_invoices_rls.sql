-- Bug: la facture est bien créée côté serveur (fonction capture-payment,
-- clé service_role, contourne RLS) et la notification "facture #INV-..."
-- part correctement. Mais côté client/prestataire, l'écran Facturation
-- reste vide : seule une policy admin existe sur invoices, donc le
-- SELECT du propriétaire ne matche aucune policy et Postgres renvoie un
-- tableau vide (pas une erreur) — d'où "ça reste vide" sans message.

alter table invoices enable row level security;

drop policy if exists invoices_owner_read on invoices;
create policy invoices_owner_read
on invoices for select
using (auth.uid() = client_id or auth.uid() = provider_id);
