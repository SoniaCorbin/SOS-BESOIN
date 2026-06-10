import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async () => {
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
    await supabase.from('offers')
      .update({ status: 'completed' })
      .eq('id', offer.id)

    // Compléter la demande
    await supabase.from('requests')
      .update({ status: 'completed' })
      .eq('id', offer.request_id)

    validated++
  }

  return new Response(
    JSON.stringify({ message: `${validated} missions validées automatiquement` }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
