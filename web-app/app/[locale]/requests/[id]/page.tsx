'use client'
import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

export default function RequestDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const t = useTranslations('request_detail')
  const [request, setRequest] = useState<any>(null)
  const [offers, setOffers] = useState<any[]>([])
  const [userId, setUserId] = useState<string | null>(null)
  const [userRole, setUserRole] = useState<string>('client')
  const [loading, setLoading] = useState(true)
  const [showOfferForm, setShowOfferForm] = useState(false)
  const [offerForm, setOfferForm] = useState({ price: '', availability: '', message: '' })
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      setUserId(session.user.id)

      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', session.user.id)
        .single()
      setUserRole(profile?.role ?? 'client')

      await fetchRequest()
      await fetchOffers()
      setLoading(false)
    }
    load()

    const channel = supabase.channel(`request-${id}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'offers', filter: `request_id=eq.${id}` }, fetchOffers)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [id])

  async function fetchRequest() {
    const { data } = await supabase.from('requests').select('*').eq('id', id).single()
    setRequest(data)
  }

  async function fetchOffers() {
    const { data } = await supabase
      .from('offers')
      .select('*, profiles(full_name, rating, total_missions)')
      .eq('request_id', id)
      .order('created_at', { ascending: false })
    setOffers(data ?? [])
  }

  async function submitOffer() {
    if (!offerForm.price || !offerForm.availability || !offerForm.message) {
      alert(t('offer_fields_required'))
      return
    }
    setSubmitting(true)
    try {
      await supabase.from('offers').insert({
        request_id: id,
        provider_id: userId,
        price: parseFloat(offerForm.price),
        availability: offerForm.availability,
        message: offerForm.message,
        status: 'pending',
      })
      alert(t('offer_success'))
      setShowOfferForm(false)
      setOfferForm({ price: '', availability: '', message: '' })
      await fetchOffers()
    } catch (e: any) {
      if (e?.message?.includes('23505')) {
        alert(t('offer_duplicate'))
      }
    }
    setSubmitting(false)
  }

  async function acceptOffer(offerId: string, price: number) {
    try {
      await supabase.from('offers').update({ status: 'accepted' }).eq('id', offerId)
      await supabase.from('requests').update({ status: 'in_progress' }).eq('id', id)
      alert(t('payment_success'))
      await fetchRequest()
      await fetchOffers()
    } catch (e) {
      console.error(e)
    }
  }

  async function validateMission(offerId: string) {
    if (!confirm(t('validate_confirm'))) return
    await supabase.from('offers').update({ status: 'completed' }).eq('id', offerId)
    await supabase.from('requests').update({ status: 'completed' }).eq('id', id)
    alert(t('validate_success'))
    await fetchRequest()
    await fetchOffers()
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  if (!request) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--text-mute)' }}>{t('not_found')}</div>
    </div>
  )

  const isClient = userId === request.client_id
  const isProvider = userRole === 'provider' && !isClient

  const statusLabel = {
    open: t('status_open'),
    in_progress: t('status_in_progress'),
    completed: t('status_completed'),
  }[request.status] ?? request.status

  const statusColor = {
    open: 'var(--amber)',
    in_progress: 'var(--cyan)',
    completed: 'var(--green)',
  }[request.status] ?? 'var(--text-mute)'

  const urgencyLabel = {
    asap:     t('urgency_asap'),
    today:    t('urgency_today'),
    tomorrow: t('urgency_tomorrow'),
    week:     t('urgency_week'),
  }[request.urgency] ?? request.urgency

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>

          <Link href="/explore" style={{ fontSize: 13, color: 'var(--text-mute)', display: 'inline-block', marginBottom: 24 }}>
            {t('back')}
          </Link>

          {/* Carte de la demande */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '28px', marginBottom: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
              <span style={{
                fontFamily: 'var(--font-mono)', fontSize: 11,
                padding: '3px 10px', borderRadius: 6,
                background: 'var(--amber-soft)', color: 'var(--amber)',
              }}>{request.category}</span>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: statusColor }}>{statusLabel}</span>
            </div>

            <h1 style={{ fontSize: 26, fontWeight: 700, marginBottom: 12, letterSpacing: '-0.02em' }}>{request.title}</h1>
            <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7, marginBottom: 20 }}>{request.description}</p>

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: 'var(--text-mute)' }}>
              <span>📍 {request.neighborhood ? `${request.neighborhood}, ` : ''}{request.location}</span>
              <span>{urgencyLabel}</span>
              {request.budget && <span style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)', fontWeight: 700 }}>{t('budget')}: {request.budget}$</span>}
            </div>
          </div>

          {/* Offres */}
          <div style={{ marginBottom: 24 }}>
            <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>
              {t('offers_title')}
              <span style={{ marginLeft: 10, fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)', fontWeight: 400 }}>{offers.length}</span>
            </h2>

            {offers.length === 0 ? (
              <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '40px', textAlign: 'center' }}>
                <div style={{ fontSize: 32, marginBottom: 12 }}>⏳</div>
                <p style={{ color: 'var(--text-mute)', marginBottom: 4 }}>{t('no_offers')}</p>
                <p style={{ color: 'var(--text-mute)', fontSize: 12 }}>{t('pros_responding')}</p>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {offers.map(offer => {
                  const profile = offer.profiles
                  const isAccepted = offer.status === 'accepted' || offer.status === 'completed'
                  return (
                    <div key={offer.id} style={{
                      background: isAccepted ? 'var(--green-soft)' : 'var(--bg-2)',
                      border: `1px solid ${isAccepted ? 'var(--green)' : 'var(--line)'}`,
                      borderRadius: 12, padding: '20px',
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 15 }}>{profile?.full_name ?? '—'}</div>
                          <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 2 }}>
                            ★ {profile?.rating?.toFixed(1) ?? '—'} · {t('offer_missions', { count: profile?.total_missions ?? 0 })}
                          </div>
                        </div>
                        <div style={{ fontFamily: 'var(--font-mono)', fontSize: 22, fontWeight: 700, color: 'var(--amber)' }}>{offer.price}$</div>
                      </div>

                      <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.6, marginBottom: 8 }}>{offer.message}</p>
                      <p style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 16 }}>🕐 {offer.availability}</p>

                      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                        {isClient && offer.status === 'pending' && request.status === 'open' && (
                          <button
                            onClick={() => acceptOffer(offer.id, offer.price)}
                            style={{
                              padding: '10px 18px', background: 'var(--amber)',
                              color: '#000', border: 'none', borderRadius: 8,
                              fontWeight: 600, fontSize: 14, cursor: 'pointer',
                              fontFamily: 'var(--font-sans)',
                            }}
                          >
                            {t('offer_accept_pay', { price: offer.price })}
                          </button>
                        )}
                        {isAccepted && (
                          <>
                            <span style={{ fontSize: 13, color: 'var(--green)', fontWeight: 600, display: 'flex', alignItems: 'center' }}>
                              {t('offer_accepted')}
                            </span>
                            <Link href={`/chat/${offer.id}`} style={{
                              padding: '10px 18px', background: 'var(--cyan-soft)',
                              color: 'var(--cyan)', border: '1px solid var(--cyan)',
                              borderRadius: 8, fontSize: 14, fontWeight: 600,
                            }}>
                              {t('offer_open_chat')}
                            </Link>
                            {isClient && offer.status === 'accepted' && (
                              <button
                                onClick={() => validateMission(offer.id)}
                                style={{
                                  padding: '10px 18px', background: 'var(--green)',
                                  color: '#000', border: 'none', borderRadius: 8,
                                  fontWeight: 600, fontSize: 14, cursor: 'pointer',
                                  fontFamily: 'var(--font-sans)',
                                }}
                              >
                                {t('offer_validate')}
                              </button>
                            )}
                          </>
                        )}
                        <Link href={`/report?userId=${offer.provider_id}&offerId=${offer.id}`} style={{
                          padding: '10px 14px',
                          border: '1px solid var(--line)',
                          borderRadius: 8, fontSize: 13,
                          color: 'var(--text-mute)',
                        }}>
                          {t('offer_report')}
                        </Link>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* Formulaire d'offre */}
          {isProvider && request.status === 'open' && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '24px' }}>
              {!showOfferForm ? (
                <button
                  onClick={() => setShowOfferForm(true)}
                  style={{
                    width: '100%', padding: '14px',
                    background: 'var(--amber)', color: '#000',
                    border: 'none', borderRadius: 8,
                    fontWeight: 600, fontSize: 15, cursor: 'pointer',
                    fontFamily: 'var(--font-sans)',
                  }}
                >
                  {t('submit_offer_btn')}
                </button>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                  <div>
                    <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('offer_price_label')}</label>
                    <input
                      type="number"
                      value={offerForm.price}
                      onChange={e => setOfferForm(f => ({ ...f, price: e.target.value }))}
                      style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('offer_availability_label')}</label>
                    <input
                      type="text"
                      value={offerForm.availability}
                      onChange={e => setOfferForm(f => ({ ...f, availability: e.target.value }))}
                      placeholder={t('offer_availability_hint')}
                      style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('offer_message_label')}</label>
                    <textarea
                      value={offerForm.message}
                      onChange={e => setOfferForm(f => ({ ...f, message: e.target.value }))}
                      placeholder={t('offer_message_hint')}
                      rows={4}
                      style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none', resize: 'vertical', fontFamily: 'var(--font-sans)' }}
                    />
                  </div>
                  <button
                    onClick={submitOffer}
                    disabled={submitting}
                    style={{
                      padding: '12px', background: submitting ? 'var(--bg-3)' : 'var(--amber)',
                      color: submitting ? 'var(--text-dim)' : '#000',
                      border: 'none', borderRadius: 8,
                      fontWeight: 600, fontSize: 15, cursor: submitting ? 'not-allowed' : 'pointer',
                      fontFamily: 'var(--font-sans)',
                    }}
                  >
                    {submitting ? t('offer_sending') : t('offer_send_btn')}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </main>
    </>
  )
}