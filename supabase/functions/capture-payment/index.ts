import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRIPE_SECRET_KEY    = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { paymentIntentId, offerId, requestId } = await req.json();

    // 1. Capturer le paiement Stripe
    const captureResponse = await fetch(
      `https://api.stripe.com/v1/payment_intents/${paymentIntentId}/capture`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    const paymentIntent = await captureResponse.json();

    if (paymentIntent.error) {
      throw new Error(paymentIntent.error.message);
    }

    // 2. Calculer les montants
    const amount         = paymentIntent.amount / 100; // convertir de centimes
    const platformFee    = Math.round(amount * 0.10 * 100) / 100; // 10%
    const providerAmount = Math.round(amount * 0.90 * 100) / 100; // 90%

    // 3. Récupérer les infos de l'offre
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const { data: offer } = await supabase
      .from("offers")
      .select("*, requests(title, category, client_id), profiles!provider_id(full_name)")
      .eq("id", offerId)
      .single();

    const { data: clientProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", offer.requests.client_id)
      .single();

    // 4. Créer la transaction
    const { data: transaction } = await supabase
      .from("transactions")
      .insert({
        request_id:       requestId,
        offer_id:         offerId,
        client_id:        offer.requests.client_id,
        provider_id:      offer.provider_id,
        amount:           amount,
        platform_fee:     platformFee,
        provider_amount:  providerAmount,
        status:           "completed",
        type:             "payment",
        request_title:    offer.requests.title,
        request_category: offer.requests.category,
        provider_name:    offer.profiles.full_name,
        client_name:      clientProfile.full_name,
        completed_at:     new Date().toISOString(),
      })
      .select()
      .single();

    // 5. Créer la facture
    const invoiceNumber = `INV-${Date.now()}`;
    await supabase.from("invoices").insert({
      transaction_id:   transaction.id,
      request_id:       requestId,
      client_id:        offer.requests.client_id,
      provider_id:      offer.provider_id,
      invoice_number:   invoiceNumber,
      amount:           amount,
      platform_fee:     platformFee,
      provider_amount:  providerAmount,
      request_title:    offer.requests.title,
      request_category: offer.requests.category,
      provider_name:    offer.profiles.full_name,
      client_name:      clientProfile.full_name,
      status:           "paid",
      paid_at:          new Date().toISOString(),
    });

    // 6. Mettre à jour le statut de la demande
    await supabase
      .from("requests")
      .update({ status: "completed" })
      .eq("id", requestId);

    return new Response(
      JSON.stringify({
        success: true,
        amount,
        platformFee,
        providerAmount,
        invoiceNumber,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});