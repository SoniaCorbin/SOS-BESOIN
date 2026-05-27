import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;

serve(async (req) => {
  try {
    const { amount, currency, offerId, clientId, providerId } = await req.json();

    // Calculer les frais client (3%)
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
        "metadata[provider_id]":   providerId,
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