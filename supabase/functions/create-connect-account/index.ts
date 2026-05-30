import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRIPE_SECRET_KEY    = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { userId, email } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Vérifier si le prestataire a déjà un compte Connect
    const { data: profile } = await supabase
      .from("profiles")
      .select("stripe_account_id")
      .eq("id", userId)
      .single();

    let accountId = profile?.stripe_account_id;

    // 2. Créer un compte Connect si nécessaire
    if (!accountId) {
      const accountResponse = await fetch("https://api.stripe.com/v1/accounts", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          type:                    "express",
          country:                 "CA",
          email:                   email,
          "capabilities[transfers][requested]": "true",
          "business_type":         "individual",
        }),
      });

      const account = await accountResponse.json();

      if (account.error) {
        throw new Error(account.error.message);
      }

      accountId = account.id;

      // 3. Sauvegarder l'ID dans le profil
      await supabase
        .from("profiles")
        .update({ stripe_account_id: accountId })
        .eq("id", userId);
    }

    // 4. Créer un lien d'onboarding
    const linkResponse = await fetch("https://api.stripe.com/v1/account_links", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        account:     accountId,
        refresh_url: "io.sosbesoin://stripe-refresh",
        return_url:  "io.sosbesoin://stripe-return",
        type:        "account_onboarding",
      }),
    });

    const link = await linkResponse.json();

    if (link.error) {
      throw new Error(link.error.message);
    }

    return new Response(
      JSON.stringify({
        url:       link.url,
        accountId: accountId,
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