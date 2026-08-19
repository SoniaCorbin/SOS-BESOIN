import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getCallerId } from "../_shared/auth.ts";

const STRIPE_SECRET_KEY    = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const callerId = getCallerId(req);
    if (!callerId) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { offerId, currency } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Le prix vient de la DB, jamais du body — sinon un client pourrait
    // payer moins cher que le prix réel de l'offre acceptée.
    const { data: offer, error: offerError } = await supabase
      .from("offers")
      .select("id, price, provider_id, request_id, requests(client_id)")
      .eq("id", offerId)
      .single();

    if (offerError || !offer) {
      throw new Error(`Offer not found: ${offerError?.message}`);
    }

    const clientId = (offer as any).requests?.client_id;
    if (callerId !== clientId) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amount       = offer.price;
    const clientFee    = Math.round(amount * 0.03 * 100) / 100;
    const totalAmount  = Math.round((amount + clientFee) * 100); // en centimes

    // Créer un Payment Intent Stripe
    const response = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        amount:                    totalAmount.toString(),
        currency:                  currency || "cad",
        "metadata[offer_id]":      offerId,
        "metadata[client_id]":     clientId,
        "metadata[provider_id]":   offer.provider_id,
        "metadata[base_amount]":   amount.toString(),
        "metadata[client_fee]":    clientFee.toString(),
        "capture_method":          "manual",
      }),
    });

    const paymentIntent = await response.json();

    if (paymentIntent.error) {
      throw new Error(paymentIntent.error.message);
    }

    return new Response(
      JSON.stringify({
        clientSecret:     paymentIntent.client_secret,
        paymentIntentId:  paymentIntent.id,
        totalAmount:      totalAmount / 100,
        clientFee:        clientFee,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
