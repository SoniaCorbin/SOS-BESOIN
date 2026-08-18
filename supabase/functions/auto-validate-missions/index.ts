import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkWebhookSecret } from '../_shared/auth.ts'

Deno.serve(async (req) => {
  // Appelée par un Cron Job (pas d'utilisateur connecté) — on vérifie un
  // secret partagé plutôt qu'un JWT.
  if (!checkWebhookSecret(req)) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Trouver toutes les offres acceptées depuis plus de 3 jours
  const threeDaysAgo = new Date()
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 3)

  const { data: offers, error } = await supabase
    .from('offers')
    .select('id, request_id, provider_id')
    .eq('status', 'accepted')
    .lt('updated_at', threeDaysAgo.toISOString())

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  let validated = 0

  for (const offer of offers ?? []) {
    // Valider l'offre
    const { error: offerError } = await supabase.from('offers')
      .update({ status: 'completed' })
      .eq('id', offer.id)

    if (offerError) {
      console.error(`Failed to complete offer ${offer.id}:`, offerError.message)
      continue
    }

    // Compléter la demande
    const { error: requestError } = await supabase.from('requests')
      .update({ status: 'completed' })
      .eq('id', offer.request_id)

    if (requestError) {
      console.error(`Failed to complete request ${offer.request_id}:`, requestError.message)
      continue
    }

    validated++
  }

  return new Response(
    JSON.stringify({ message: `${validated} missions validées automatiquement` }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
