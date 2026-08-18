import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCallerRole } from "../_shared/auth.ts";

const STRIPE_SECRET_KEY    = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    // Appel serveur-à-serveur uniquement (déclenché par capture-payment avec
    // la clé service role) — jamais directement par un client.
    if (getCallerRole(req) !== "service_role") {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403, headers: { "Content-Type": "application/json" },
      });
    }

    const { transactionId } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Récupérer la transaction
    const { data: transaction, error: transError } = await supabase
      .from("transactions")
      .select("*")
      .eq("id", transactionId)
      .single();

    if (transError || !transaction) {
      throw new Error(`Transaction not found: ${transError?.message}`);
    }

    // Idempotence : un transfert a déjà été fait pour cette transaction —
    // ne jamais repayer le prestataire une deuxième fois.
    if (transaction.stripe_transfer_id) {
      return new Response(
        JSON.stringify({
          success:    true,
          transferId: transaction.stripe_transfer_id,
          amount:     transaction.provider_amount,
          alreadyTransferred: true,
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Récupérer le stripe_account_id du prestataire
    const { data: providerProfile } = await supabase
      .from("profiles")
      .select("stripe_account_id, full_name")
      .eq("id", transaction.provider_id)
      .single();

    if (!providerProfile?.stripe_account_id) {
      throw new Error("Le prestataire n'a pas de compte Stripe Connect configuré.");
    }

    // 3. Calculer le montant à transférer (90% du montant de base)
    const transferAmount = Math.round(transaction.provider_amount * 100); // en centimes

    // 4. Créer le transfert Stripe
    const transferResponse = await fetch("https://api.stripe.com/v1/transfers", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        amount:      transferAmount.toString(),
        currency:    "cad",
        destination: providerProfile.stripe_account_id,
        "metadata[transaction_id]": transactionId,
        "metadata[provider_name]":  providerProfile.full_name ?? "",
      }),
    });

    const transfer = await transferResponse.json();

    if (transfer.error) {
      throw new Error(transfer.error.message);
    }

    // 5. Mettre à jour la transaction avec l'ID du transfert
    const { error: updateError } = await supabase
      .from("transactions")
      .update({
        stripe_transfer_id: transfer.id,
        transfer_status:    "transferred",
      })
      .eq("id", transactionId);

    if (updateError) {
      // Le transfert Stripe a déjà eu lieu à ce stade — on ne peut pas
      // l'annuler, mais il faut au moins remonter l'erreur pour éviter
      // qu'un retry ne redéclenche un deuxième transfert.
      throw new Error(`Transfer succeeded but failed to record it: ${updateError.message}`);
    }

    return new Response(
      JSON.stringify({
        success:    true,
        transferId: transfer.id,
        amount:     transferAmount / 100,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
});