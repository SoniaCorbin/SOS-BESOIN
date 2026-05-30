import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRIPE_SECRET_KEY    = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
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
    await supabase
      .from("transactions")
      .update({
        stripe_transfer_id: transfer.id,
        transfer_status:    "transferred",
      })
      .eq("id", transactionId);

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