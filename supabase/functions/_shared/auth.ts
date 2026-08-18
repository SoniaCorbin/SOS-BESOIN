// La plateforme Supabase valide déjà la signature du JWT avant d'invoquer
// la fonction (verify_jwt = true dans config.toml). Décoder le payload ici
// pour lire les claims est donc sûr et évite un aller-retour réseau.
function decodeJwtPayload(req: Request): Record<string, unknown> | null {
  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  const parts = jwt.split(".");
  if (parts.length !== 3) return null;
  try {
    return JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
  } catch {
    return null;
  }
}

export function getCallerId(req: Request): string | null {
  const payload = decodeJwtPayload(req);
  return (payload?.sub as string) ?? null;
}

export function getCallerRole(req: Request): string | null {
  const payload = decodeJwtPayload(req);
  return (payload?.role as string) ?? null;
}

export function checkWebhookSecret(req: Request): boolean {
  const expected = Deno.env.get("WEBHOOK_SECRET");
  if (!expected) return false;
  return req.headers.get("x-webhook-secret") === expected;
}
