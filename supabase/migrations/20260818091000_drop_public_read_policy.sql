-- Ferme le trou de sécurité : plus aucune lecture publique de la table
-- profiles complète. L'accès public passe désormais uniquement par la
-- vue public_profiles (voir 20260818090000).

drop policy profiles_public_read on profiles;
