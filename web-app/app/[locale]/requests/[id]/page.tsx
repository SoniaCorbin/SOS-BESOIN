'use client'
import { useState, useEffect, useCallback } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import RatingForm from '@/components/RatingForm'

export default function RequestDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const t = useTranslations('request_detail')
  const [request, setRequest] = useState<any>(null)
  const [offers, setOffers] = useState<any[]>([])
  const [invoice, setInvoice] = useState<any>(null)
  const [userId, setUserId] = useState<string | null>(null)
  const [userRole, setUserRole] = useState<string>('client')
  const [loading, setLoading] = useState(true)
  const [showOfferForm, setShowOfferForm] = useState(false)
  const [offerForm, setOfferForm] = useState({ price: '', availability: '', message: '' })
  const [submitting, setSubmitting] = useState(false)
  const [showEditRequest, setShowEditRequest] = useState(false)
  const [editForm, setEditForm] = useState({ title: '', description: '', budget: '', urgency: '' })
  const [editingOfferId, setEditingOfferId] = useState<string | null>(null)
  const [editOfferForm, setEditOfferForm] = useState({ price: '', availability: '', message: '' })
  const [ratingOffer, setRatingOffer] = useState<{ offerId: string; providerId: string } | null>(null)

  const fetchRequest = useCallback(async () => {
    const { data } = await supabase.from('requests').select('*').eq('id', id).single()
    setRequest(data)
    if (data) {
      setEditForm({
        title: data.title,
        description: data.description,
        budget: data.budget?.toString() ?? '',
        urgency: data.urgency,
      })
    }
  }, [id])

  const fetchOffers = useCallback(async () => {
    const { data } = await supabase
      .from('offers')
      .select('*')
      .eq('request_id', id)
      .order('created_at', { ascending: false })

    // Fetch profiles manually (FK points to auth.users, not profiles)
    const enriched = []
    for (const offer of data ?? []) {
      try {
        const { data: profile } = await supabase
          .from('public_profiles')
          .select('full_name, rating, total_missions')
          .eq('id', offer.provider_id)
          .single()
        enriched.push({ ...offer, profiles: profile })
      } catch {
        enriched.push({ ...offer, profiles: null })
      }
    }
    setOffers(enriched)
  }, [id])

  const fetchInvoice = useCallback(async () => {
    const { data } = await supabase
      .from('invoices')
      .select('id, invoice_number, amount, status')
      .eq('request_id', id)
      .maybeSingle()
    setInvoice(data)
  }, [id])

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

      await Promise.all([fetchRequest(), fetchOffers(), fetchInvoice()])
      setLoading(false)
    }
    load()

    const channel = supabase.channel(`request-${id}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'offers', filter: `request_id=eq.${id}` }, () => { fetchOffers(); fetchInvoice() })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests', filter: `id=eq.${id}` }, fetchRequest)
      .subscribe()

    const handleVisibility = () => {
      if (document.visibilityState === 'visible') {
        fetchRequest()
        fetchOffers()
        fetchInvoice()
      }
    }
    document.addEventListener('visibilitychange', handleVisibility)

    return () => {
      supabase.removeChannel(channel)
      document.removeEventListener('visibilitychange', handleVisibility)
    }
  }, [id, fetchRequest, fetchOffers, fetchInvoice, router])

  // ── Actions ─────────────────────────────────────
  async function submitOffer() {
    if (!offerForm.price || !offerForm.availability || !offerForm.message) {
      alert(t('offer_fields_required')); return
    }
    setSubmitting(true)
    try {
      await supabase.from('offers').insert({
        request_id: id, provider_id: userId,
        price: parseFloat(offerForm.price),
        availability: offerForm.availability,
        message: offerForm.message, status: 'pending',
      })
      alert(t('offer_success'))
      setShowOfferForm(false)
      setOfferForm({ price: '', availability: '', message: '' })
      await fetchOffers()
    } catch (e: any) {
      if (e?.message?.includes('23505')) alert(t('offer_duplicate'))
    }
    setSubmitting(false)
  }

  async function acceptOffer(offerId: string) {
    try {
      await supabase.from('offers').update({ status: 'accepted' }).eq('id', offerId)
      await supabase.from('requests').update({ status: 'in_progress' }).eq('id', id)
      alert(t('payment_success'))
      await fetchRequest(); await fetchOffers()
    } catch (e) { console.error(e) }
  }

  async function validateMission(offer: any) {
    if (!confirm(t('validate_confirm'))) return
    await supabase.from('offers').update({ status: 'completed' }).eq('id', offer.id)
    await supabase.from('requests').update({ status: 'completed' }).eq('id', id)
    await fetchRequest(); await fetchOffers()
    setRatingOffer({ offerId: offer.id, providerId: offer.provider_id })
  }

  async function cancelRequest() {
    if (!confirm(t('cancel_confirm'))) return
    await supabase.from('requests').update({ status: 'cancelled' }).eq('id', id)
    alert(t('cancel_success'))
    await fetchRequest()
  }

  async function saveEditRequest() {
    setSubmitting(true)
    try {
      await supabase.from('requests').update({
        title: editForm.title,
        description: editForm.description,
        budget: editForm.budget ? parseFloat(editForm.budget) : null,
        urgency: editForm.urgency,
      }).eq('id', id)
      alert(t('edit_saved'))
      setShowEditRequest(false)
      await fetchRequest()
    } catch (e) { console.error(e) }
    setSubmitting(false)
  }

  async function withdrawOffer(offerId: string) {
    if (!confirm(t('withdraw_confirm'))) return
    await supabase.from('offers').delete().eq('id', offerId)
    alert(t('withdraw_success'))
    await fetchOffers()
  }

  async function saveEditOffer() {
    if (!editingOfferId) return
    setSubmitting(true)
    try {
      await supabase.from('offers').update({
        price: parseFloat(editOfferForm.price),
        availability: editOfferForm.availability,
        message: editOfferForm.message,
      }).eq('id', editingOfferId)
      alert(t('edit_saved'))
      setEditingOfferId(null)
      await fetchOffers()
    } catch (e) { console.error(e) }
    setSubmitting(false)
  }

  // ── Render ──────────────────────────────────────
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
  const canManage = isClient && request.status === 'open'

  const statusLabel = { open: t('status_open'), in_progress: t('status_in_progress'), completed: t('status_completed'), cancelled: t('status_cancelled') }[request.status as string] ?? request.status
  const statusColor = { open: 'var(--amber)', in_progress: 'var(--cyan)', completed: 'var(--green)', cancelled: 'var(--red)' }[request.status as string] ?? 'var(--text-mute)'
  const urgencyLabel = { asap: t('urgency_asap'), today: t('urgency_today'), tomorrow: t('urgency_tomorrow'), week: t('urgency_week') }[request.urgency as string] ?? request.urgency

  const inputStyle = { width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none', fontFamily: 'var(--font-sans)' }
  const btnAmber = { padding: '10px 18px', background: 'var(--amber)', color: '#000', border: 'none', borderRadius: 8, fontWeight: 600, fontSize: 14, cursor: 'pointer', fontFamily: 'var(--font-sans)' }
  const btnOutline = (color: string) => ({ padding: '10px 14px', border: `1px solid ${color}`, borderRadius: 8, fontSize: 13, color, background: 'none', cursor: 'pointer', fontFamily: 'var(--font-sans)' })

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>

          <Link href="/dashboard" style={{ fontSize: 13, color: 'var(--text-mute)', display: 'inline-block', marginBottom: 24 }}>
            {t('back')}
          </Link>

          {/* ═══ Request card ═══ */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '28px', marginBottom: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, padding: '3px 10px', borderRadius: 6, background: 'var(--amber-soft)', color: 'var(--amber)' }}>
                {request.category}
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: statusColor }}>{statusLabel}</span>
                {canManage && (
                  <div style={{ position: 'relative' }}>
                    <details style={{ position: 'relative' }}>
                      <summary style={{ cursor: 'pointer', color: 'var(--text-mute)', fontSize: 18, listStyle: 'none', userSelect: 'none' }}>⋮</summary>
                      <div style={{ position: 'absolute', right: 0, top: 24, background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 8, overflow: 'hidden', zIndex: 10, minWidth: 150 }}>
                        <button onClick={() => { setShowEditRequest(true) }} style={{ display: 'block', width: '100%', padding: '10px 14px', background: 'none', border: 'none', color: 'var(--text)', fontSize: 13, cursor: 'pointer', textAlign: 'left' }}>
                          ✏️ {t('edit_btn')}
                        </button>
                        <button onClick={cancelRequest} style={{ display: 'block', width: '100%', padding: '10px 14px', background: 'none', border: 'none', color: 'var(--red)', fontSize: 13, cursor: 'pointer', textAlign: 'left' }}>
                          ❌ {t('cancel_btn')}
                        </button>
                      </div>
                    </details>
                  </div>
                )}
              </div>
            </div>

            <h1 style={{ fontSize: 26, fontWeight: 700, marginBottom: 12, letterSpacing: '-0.02em' }}>{request.title}</h1>
            <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7, marginBottom: 20 }}>{request.description}</p>

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: 'var(--text-mute)' }}>
              <span>📍 {request.neighborhood ? `${request.neighborhood}, ` : ''}{request.location}</span>
              <span>{urgencyLabel}</span>
              {request.budget && <span style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)', fontWeight: 700 }}>{t('budget')}: {request.budget}$</span>}
            </div>

            {/* Invoice link */}
            {invoice && (
              <div style={{ marginTop: 16 }}>
                <Link href={`/invoices/${invoice.id}`} style={{ color: 'var(--amber)', fontSize: 13, fontWeight: 600 }}>
                  📄 {t('view_invoice')}
                </Link>
              </div>
            )}
          </div>

          {/* ═══ Edit request modal ═══ */}
          {showEditRequest && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '24px', marginBottom: 24 }}>
              <h3 style={{ fontSize: 18, fontWeight: 600, marginBottom: 16 }}>{t('edit_title')}</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div>
                  <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('edit_title_label')}</label>
                  <input value={editForm.title} onChange={e => setEditForm(f => ({ ...f, title: e.target.value }))} style={inputStyle} />
                </div>
                <div>
                  <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('edit_desc_label')}</label>
                  <textarea value={editForm.description} onChange={e => setEditForm(f => ({ ...f, description: e.target.value }))} rows={4} style={{ ...inputStyle, resize: 'vertical' as const }} />
                </div>
                <div>
                  <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('edit_budget_label')}</label>
                  <input type="number" value={editForm.budget} onChange={e => setEditForm(f => ({ ...f, budget: e.target.value }))} style={inputStyle} />
                </div>
                <div>
                  <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('edit_urgency_label')}</label>
                  <select value={editForm.urgency} onChange={e => setEditForm(f => ({ ...f, urgency: e.target.value }))} style={inputStyle}>
                    <option value="asap">{t('urgency_asap')}</option>
                    <option value="today">{t('urgency_today')}</option>
                    <option value="tomorrow">{t('urgency_tomorrow')}</option>
                    <option value="week">{t('urgency_week')}</option>
                  </select>
                </div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button onClick={saveEditRequest} disabled={submitting} style={btnAmber}>
                    {submitting ? '...' : t('edit_save_btn')}
                  </button>
                  <button onClick={() => setShowEditRequest(false)} style={btnOutline('var(--text-mute)')}>
                    {t('edit_cancel_btn')}
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ═══ Offers ═══ */}
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
                  const isOwnOffer = offer.provider_id === userId
                  const isEditing = editingOfferId === offer.id

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

                      {isEditing ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 12 }}>
                          <input type="number" value={editOfferForm.price} onChange={e => setEditOfferForm(f => ({ ...f, price: e.target.value }))} placeholder={t('offer_price_label')} style={inputStyle} />
                          <input value={editOfferForm.availability} onChange={e => setEditOfferForm(f => ({ ...f, availability: e.target.value }))} placeholder={t('offer_availability_label')} style={inputStyle} />
                          <textarea value={editOfferForm.message} onChange={e => setEditOfferForm(f => ({ ...f, message: e.target.value }))} rows={3} style={{ ...inputStyle, resize: 'vertical' as const }} />
                          <div style={{ display: 'flex', gap: 8 }}>
                            <button onClick={saveEditOffer} disabled={submitting} style={btnAmber}>{submitting ? '...' : t('edit_save_btn')}</button>
                            <button onClick={() => setEditingOfferId(null)} style={btnOutline('var(--text-mute)')}>{t('edit_cancel_btn')}</button>
                          </div>
                        </div>
                      ) : (
                        <>
                          <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.6, marginBottom: 8 }}>{offer.message}</p>
                          <p style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 16 }}>🕐 {offer.availability}</p>
                        </>
                      )}

                      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                        {isClient && offer.status === 'pending' && request.status === 'open' && (
                          <button onClick={() => acceptOffer(offer.id)} style={btnAmber}>
                            {t('offer_accept_pay', { price: offer.price })}
                          </button>
                        )}

                        {isOwnOffer && offer.status === 'pending' && !isEditing && (
                          <>
                            <button onClick={() => { setEditingOfferId(offer.id); setEditOfferForm({ price: offer.price.toString(), availability: offer.availability, message: offer.message }) }} style={btnOutline('var(--text-dim)')}>
                              ✏️ {t('offer_edit_btn')}
                            </button>
                            <button onClick={() => withdrawOffer(offer.id)} style={btnOutline('var(--red)')}>
                              🗑 {t('offer_withdraw_btn')}
                            </button>
                          </>
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
                              <button onClick={() => validateMission(offer)} style={{ ...btnAmber, background: 'var(--green)' }}>
                                {t('offer_validate')}
                              </button>
                            )}
                          </>
                        )}

                        <Link href={`/report?userId=${offer.provider_id}&offerId=${offer.id}`} style={btnOutline('var(--text-mute)')}>
                          {t('offer_report')}
                        </Link>
                      </div>

                      {isClient && ratingOffer?.offerId === offer.id && (
                        <RatingForm
                          requestId={id}
                          offerId={offer.id}
                          clientId={userId ?? ''}
                          providerId={offer.provider_id}
                          onRated={() => {}}
                        />
                      )}
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* ═══ Offer form (provider) ═══ */}
          {isProvider && request.status === 'open' && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '24px' }}>
              {!showOfferForm ? (
                <button onClick={() => setShowOfferForm(true)} style={{ ...btnAmber, width: '100%', padding: '14px', fontSize: 15 }}>
                  {t('submit_offer_btn')}
                </button>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                  <div>
                    <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('offer_price_label')}</label>
                    <input type="number" value={offerForm.price} onChange={e => setOfferForm(f => ({ ...f, price: e.target.value }))} style={inputStyle} />
                  </div>
                  <div>
                    <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('offer_availability_label')}</label>
                    <input value={offerForm.availability} onChange={e => setOfferForm(f => ({ ...f, availability: e.target.value }))} placeholder={t('offer_availability_hint')} style={inputStyle} />
                  </div>
                  <div>
                    <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('offer_message_label')}</label>
                    <textarea value={offerForm.message} onChange={e => setOfferForm(f => ({ ...f, message: e.target.value }))} placeholder={t('offer_message_hint')} rows={4} style={{ ...inputStyle, resize: 'vertical' as const }} />
                  </div>
                  <button onClick={submitOffer} disabled={submitting} style={{ ...btnAmber, padding: '12px', fontSize: 15, opacity: submitting ? 0.5 : 1 }}>
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