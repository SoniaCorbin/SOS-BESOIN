import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL         = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SB_SERVICE_ROLE_KEY")!;

const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss:   serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud:   "https://oauth2.googleapis.com/token",
    exp:   now + 3600,
    iat:   now,
  };

  const header       = { alg: "RS256", typ: "JWT" };
  const encoder      = new TextEncoder();
  const headerB64    = btoa(JSON.stringify(header));
  const payloadB64   = btoa(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  const keyData = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8", binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false, ["sign"]
  );

  const signature    = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", cryptoKey, encoder.encode(signingInput)
  );
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)));
  const jwt          = `${signingInput}.${signatureB64}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method:  "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:    `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
) {
  const accessToken = await getAccessToken();
  const projectId   = serviceAccount.project_id;

  await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method:  "POST",
      headers: {
        "Content-Type":  "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token:        fcmToken,
          notification: { title, body },
          data,
          android: {
            priority:     "high",
            notification: { sound: "default" },
          },
        },
      }),
    }
  );
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const { type, table, record } = payload;

    // ── Nouvelle offre → notifier le client ──────────
    if (table === "offers" && type === "INSERT") {
      const { data: request } = await supabase
        .from("requests")
        .select("client_id, title")
        .eq("id", record.request_id)
        .single();

      if (request) {
        const { data: clientProfile } = await supabase
          .from("profiles")
          .select("fcm_token, full_name")
          .eq("id", request.client_id)
          .single();

        if (clientProfile?.fcm_token) {
          await sendPushNotification(
            clientProfile.fcm_token,
            "💼 Nouvelle offre reçue !",
            `Un pro a soumis une offre pour "${request.title}"`,
            { type: "new_offer", offer_id: record.id, request_id: record.request_id }
          );
        }
      }
    }

    // ── Offre acceptée → notifier le prestataire ─────
    if (table === "offers" && type === "UPDATE" && record.status === "accepted") {
      const { data: providerProfile } = await supabase
        .from("profiles")
        .select("fcm_token, full_name")
        .eq("id", record.provider_id)
        .single();

      if (providerProfile?.fcm_token) {
        const { data: request } = await supabase
          .from("requests")
          .select("title")
          .eq("id", record.request_id)
          .single();

        await sendPushNotification(
          providerProfile.fcm_token,
          "🎉 Offre acceptée !",
          `Votre offre pour "${request?.title}" a été acceptée !`,
          { type: "offer_accepted", offer_id: record.id }
        );
      }
    }

    // ── Nouveau message → notifier le destinataire ───
    if (table === "messages" && type === "INSERT") {
      const { data: offer } = await supabase
        .from("offers")
        .select("*, requests(title, client_id)")
        .eq("id", record.offer_id)
        .single();

      if (offer) {
        const recipientId = record.sender_id === offer.provider_id
            ? offer.requests.client_id
            : offer.provider_id;

        const { data: recipientProfile } = await supabase
          .from("profiles")
          .select("fcm_token, full_name")
          .eq("id", recipientId)
          .single();

        if (recipientProfile?.fcm_token) {
          const { data: senderProfile } = await supabase
            .from("profiles")
            .select("full_name")
            .eq("id", record.sender_id)
            .single();

          await sendPushNotification(
            recipientProfile.fcm_token,
            `💬 ${senderProfile?.full_name ?? "Quelqu'un"}`,
            record.content,
            { type: "new_message", offer_id: record.offer_id }
          );
        }
      }
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
});