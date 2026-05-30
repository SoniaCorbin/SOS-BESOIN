import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRIPE_SECRET_KEY    = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { paymentIntentId, offerId, requestId } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Récupérer l'offre
    const { data: offer, error: offerError } = await supabase
      .from("offers")
      .select("*")
      .eq("id", offerId)
      .single();

    if (offerError || !offer) {
      throw new Error(`Offer not found: ${offerError?.message}`);
    }

    // 2. Récupérer la demande
    const { data: request, error: requestError } = await supabase
      .from("requests")
      .select("*")
      .eq("id", requestId)
      .single();

    if (requestError || !request) {
      throw new Error(`Request not found: ${requestError?.message}`);
    }

    // 3. Récupérer le profil du prestataire
    const { data: providerProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", offer.provider_id)
      .single();

    // 4. Récupérer le profil du client
    const { data: clientProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", request.client_id)
      .single();

    // 5. Capturer le paiement Stripe
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

    // 6. Calculer les montants
    const totalAmount    = paymentIntent.amount / 100;
    const baseAmount     = parseFloat(paymentIntent.metadata?.base_amount ?? totalAmount.toString());
    const clientFee      = parseFloat(paymentIntent.metadata?.client_fee ?? '0');
    const platformFee    = Math.round(baseAmount * 0.10 * 100) / 100; // 10% du montant de base
    const providerAmount = Math.round(baseAmount * 0.90 * 100) / 100; // 90% du montant de base

    // 7. Créer la transaction
    const { data: transaction, error: transError } = await supabase
      .from("transactions")
      .insert({
        request_id:       requestId,
        offer_id:         offerId,
        client_id:        request.client_id,
        provider_id:      offer.provider_id,
        amount:           totalAmount,
        platform_fee:     platformFee,
        provider_amount:  providerAmount,
        status:           "completed",
        type:             "payment",
        request_title:    request.title,
        request_category: request.category,
        provider_name:    providerProfile?.full_name ?? "Prestataire",
        client_fee:       clientFee,
        client_name:      clientProfile?.full_name ?? "Client",
        completed_at:     new Date().toISOString(),
      })
      .select()
      .single();

    if (transError) {
      throw new Error(`Transaction error: ${transError.message}`);
    }

    // 8. Créer la facture
    const invoiceNumber = `INV-${Date.now()}`;
    await supabase.from("invoices").insert({
      transaction_id:   transaction.id,
      request_id:       requestId,
      client_id:        request.client_id,
      provider_id:      offer.provider_id,
      invoice_number:   invoiceNumber,
      amount:           totalAmount,
      platform_fee:     platformFee,
      provider_amount:  providerAmount,
      request_title:    request.title,
      request_category: request.category,
      provider_name:    providerProfile?.full_name ?? "Prestataire",
      client_fee:       clientFee,
      client_name:      clientProfile?.full_name ?? "Client",
      status:           "paid",
      paid_at:          new Date().toISOString(),
    });

    // 9. Mettre à jour le statut de la demande
    await supabase
      .from("requests")
      .update({ status: "completed" })
      .eq("id", requestId);

    // 10. Transférer au prestataire
    try {
      const transferResponse = await fetch(
        `${SUPABASE_URL}/functions/v1/transfer-to-provider`,
        {
          method: "POST",
          headers: {
            "Content-Type":  "application/json",
            "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({ transactionId: transaction.id }),
        }
      );

      const transferData = await transferResponse.json();

      if (transferData.error) {
        console.error("Transfer error:", transferData.error);
        // On ne bloque pas le paiement si le transfert échoue
        // Le transfert peut être fait manuellement depuis le panel admin
      }
    } catch (transferError) {
      console.error("Transfer failed:", transferError);
      // On continue même si le transfert échoue
    }


    // 11. Mettre à jour le statut de l'offre
    await supabase
      .from("offers")
      .update({ status: "accepted" })
      .eq("id", offerId);

    return new Response(
      JSON.stringify({
        success:        true,
        amount,
        platformFee,
        providerAmount,
        invoiceNumber,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
          success:         true,
          amount:          totalAmount,
          baseAmount:      baseAmount,
          clientformFee,
          providerAmount,
          invoiceNumber,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  }
});