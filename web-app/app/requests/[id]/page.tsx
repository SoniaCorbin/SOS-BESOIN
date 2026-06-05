'use client'
import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Link from 'next/link'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

const STATUS_LABELS: Record<string, { label: string, color: string }> = {
  open:        { label: 'Ouvert', color: 'var(--amber)' },
  in_progress: { label: 'En cours', color: 'var(--cyan)' },
  completed:   { label: 'Complété', color: 'var(--green)' },
  cancelled:   { label: 'Annulé', color: 'var(--red)' },
}

export default function RequestDetailPage() {
  const router = useRouter()
  const { id } = useParams<{ id: string }>()
  const [request, setRequest] = useState<any>(null)
  const [offers, setOffers] = useState<any[]>([])
  const [userId, setUserId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [offerMsg, setOfferMsg] = useState('')
  const [offerPrice, setOfferPrice] = useState('')
  const [offerAvail, setOfferAvail] = useState('')
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      setUserId(session.user.id)

      const { data: req } = await supabase
        .from('requests')
        .select('*')
        .eq('id', id)
        .single()
      setRequest(req)

      await loadOffers()
      setLoading(false)
    }
    load()

    const channel = supabase.channel('request-detail')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'offers' }, loadOffers)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [id])

  async function loadOffers() {
    const { data } = await supabase
      .from('offers')
      .select('*, profiles(full_name, rating, total_missions, is_kyc_verified)')
      .eq('request_id', id)
      .order('created_at', { ascending: false })
    setOffers(data ?? [])
  }

  async function handleAccept(offer: any) {
    await supabase.from('offers').update({ status: 'accepted' }).eq('id', offer.id)
    await supabase.from('requests').update({ status: 'in_progress' }).eq('id', id)
    await loadOffers()
    setRequest((r: any) => ({ ...r, status: 'in_progress' }))
  }

  async function handleValidate(offer: any) {
    if (!confirm('Valider la mission ? Le paiement sera libéré au prestataire.')) return
    await supabase.from('offers').update({ status: 'completed' }).eq('id', offer.id)
    await supabase.from('requests').update({ status: 'completed' }).eq('id', id)
    await loadOffers()
    setRequest((r: any) => ({ ...r, status: 'completed' }))
  }

  async function handleSubmitOffer() {
    if (!offerPrice || !offerMsg || !offerAvail) return
    setSubmitting(true)
    await supabase.from('offers').insert({
      request_id: id,
      provider_id: userId,
      price: parseFloat(offerPrice),
      message: offerMsg,
      availability: offerAvail,
      status: 'pending',
    })
    setOfferPrice(''); setOfferMsg(''); setOfferAvail('')
    await loadOffers()
    setSubmitting(false)
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>Chargement...</div>
    </div>
  )

  const isClient = userId === request?.client_id
  const status = STATUS_LABELS[request?.status] ?? { label: request?.status, color: 'var(--text-dim)' }
  const inputStyle = {
    width: '100%', padding: '10px 14px',
    background: 'var(--bg-3)', border: '1px solid var(--line-2)',
    borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none',
    fontFamily: 'var(--font-sans)',
  }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>

          <Link href="/dashboard" style={{ fontSize: 13, color: 'var(--text-mute)', display: 'flex', alignItems: 'center', gap: 6, marginBottom: 24 }}>
            ← Retour au dashboard
          </Link>

          {/* Carte demande */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '24px', marginBottom: 32 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
              <span style={{
                fontFamily: 'var(--font-mono)', fontSize: 11,
                padding: '3px 10px', borderRadius: 6,
                background: 'var(--amber-soft)', color: 'var(--amber)',
              }}>{request?.category}</span>
              <span style={{
                fontFamily: 'var(--font-mono)', fontSize: 11,
                padding: '3px 10px', borderRadius: 6,
                border: `1px solid ${status.color}`, color: status.color,
              }}>{status.label}</span>
            </div>
            <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 12, letterSpacing: '-0.02em' }}>{request?.title}</h1>
            <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7, marginBottom: 16 }}>{request?.description}</p>
            <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 13, color: 'var(--text-mute)' }}>📍 {request?.location}</span>
              {request?.budget && <span style={{ fontSize: 13, color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{request.budget}$</span>}
            </div>
          </div>

          {/* Offres */}
          <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>
            Offres reçues
            <span style={{ marginLeft: 8, fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)' }}>{offers.length}</span>
          </h2>

          {offers.length === 0 ? (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '32px', textAlign: 'center', marginBottom: 32 }}>
              <p style={{ color: 'var(--text-mute)' }}>Aucune offre pour l'instant. Les prestataires vont répondre sous peu.</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 32 }}>
              {offers.map(offer => {
                const profile = offer.profiles
                const name = profile?.full_name ?? 'Prestataire'
                const initials = name.split(' ').length >= 2
                  ? `${name.split(' ')[0][0]}${name.split(' ')[1][0]}`.toUpperCase()
                  : name.substring(0, 2).toUpperCase()

                return (
                  <div key={offer.id} style={{
                    background: offer.status === 'accepted' ? 'rgba(132,204,22,0.05)' : 'var(--bg-2)',
                    border: `1px solid ${offer.status === 'accepted' ? 'var(--green)' : 'var(--line)'}`,
                    borderRadius: 12, padding: '20px',
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                        <div style={{
                          width: 40, height: 40, borderRadius: '50%',
                          background: 'var(--bg-3)', border: '1px solid var(--line-2)',
                          display: 'grid', placeItems: 'center',
                          fontWeight: 700, fontSize: 13,
                        }}>{initials}</div>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 14 }}>
                            {name}
                            {profile?.is_kyc_verified && <span style={{ color: 'var(--cyan)', fontSize: 12, marginLeft: 6 }}>✓ vérifié</span>}
                          </div>
                          <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>
                            ★ {profile?.rating?.toFixed(1) ?? '—'} · {profile?.total_missions ?? 0} missions
                          </div>
                        </div>
                      </div>
                      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 22, fontWeight: 700, color: 'var(--amber)' }}>
                        {offer.price}$
                      </span>
                    </div>
                    <p style={{ fontSize: 14, color: 'var(--text-dim)', marginBottom: 8 }}>{offer.message}</p>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 16 }}>🕐 {offer.availability}</div>

                    {isClient && offer.status === 'pending' && request?.status === 'open' && (
                      <button onClick={() => handleAccept(offer)} style={{
                        width: '100%', padding: '10px',
                        background: 'var(--amber)', color: '#000',
                        border: 'none', borderRadius: 8,
                        fontWeight: 600, fontSize: 14, cursor: 'pointer',
                        fontFamily: 'var(--font-sans)',
                      }}>
                        🔒 Accepter et payer {offer.price}$
                      </button>
                    )}
                    {isClient && offer.status === 'accepted' && (
                      <button onClick={() => handleValidate(offer)} style={{
                        width: '100%', padding: '10px',
                        background: 'var(--green)', color: '#000',
                        border: 'none', borderRadius: 8,
                        fontWeight: 600, fontSize: 14, cursor: 'pointer',
                        fontFamily: 'var(--font-sans)',
                      }}>
                        ✅ Valider la mission — libérer le paiement
                      </button>
                    )}
                    {offer.status === 'accepted' && (
                      <div style={{ fontSize: 13, color: 'var(--green)', marginTop: 8 }}>✓ Offre acceptée</div>
                    )}
                  </div>
                )
              })}
            </div>
          )}

          {/* Soumettre offre (prestataire) */}
          {!isClient && request?.status === 'open' && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '24px' }}>
              <h3 style={{ fontSize: 18, fontWeight: 600, marginBottom: 20 }}>Soumettre une offre</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <input type="number" value={offerPrice} onChange={e => setOfferPrice(e.target.value)} placeholder="Votre prix ($)" style={inputStyle} />
                <input type="text" value={offerAvail} onChange={e => setOfferAvail(e.target.value)} placeholder="Disponibilité (ex: ce soir à 19h)" style={inputStyle} />
                <textarea value={offerMsg} onChange={e => setOfferMsg(e.target.value)} placeholder="Message au client..." rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
                <button onClick={handleSubmitOffer} disabled={submitting} style={{
                  padding: '12px', background: 'var(--amber)', color: '#000',
                  border: 'none', borderRadius: 8, fontWeight: 600, fontSize: 14,
                  cursor: submitting ? 'not-allowed' : 'pointer', fontFamily: 'var(--font-sans)',
                }}>
                  {submitting ? 'Envoi...' : '📤 Envoyer mon offre'}
                </button>
              </div>
            </div>
          )}
        </div>
      </main>
    </>
  )
}