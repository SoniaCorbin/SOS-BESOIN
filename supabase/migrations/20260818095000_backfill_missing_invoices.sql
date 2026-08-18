-- Avant le correctif de capture-payment (client_fee inexistant sur
-- invoices), l'insert de facture échouait silencieusement pour tous les
-- paiements déjà capturés. On reconstitue les factures manquantes à
-- partir de transactions, qui contient les mêmes données et n'a jamais
-- eu ce problème.

insert into invoices (
  transaction_id, request_id, client_id, provider_id, invoice_number,
  amount, platform_fee, provider_amount, request_title, request_category,
  provider_name, client_name, status, paid_at, created_at
)
select
  t.id, t.request_id, t.client_id, t.provider_id,
  'INV-' || (extract(epoch from t.created_at) * 1000)::bigint::text,
  t.amount, t.platform_fee, t.provider_amount, t.request_title, t.request_category,
  t.provider_name, t.client_name, 'paid',
  coalesce(t.completed_at, t.created_at), t.created_at
from transactions t
where t.type = 'payment'
  and t.status = 'completed'
  and not exists (select 1 from invoices i where i.transaction_id = t.id);
