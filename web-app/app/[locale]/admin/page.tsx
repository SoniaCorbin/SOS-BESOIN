'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

export default function AdminPage() {
  const router = useRouter()
  const t = useTranslations('admin')
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'stats' | 'users' | 'requests' | 'categories' | 'litiges' | 'waitlist'>('stats')
  const [stats, setStats] = useState({ users: 0, providers: 0, requests: 0, completed: 0 })
  const [users, setUsers] = useState<any[]>([])
  const [requests, setRequests] = useState<any[]>([])
  const [categories, setCategories] = useState<any[]>([])
  const [litiges, setLitiges] = useState<any[]>([])
  const [completedRequests, setCompletedRequests] = useState<any[]>([])
  const [waitlist, setWaitlist] = useState<any[]>([])
  const [litigeForm, setLitigeForm] = useState({ reason: 'plainte_client', description: '' })
  const [showLitigeForm, setShowLitigeForm] = useState<string | null>(null)
  const [detailRequest, setDetailRequest] = useState<any>(null)
  const [detailOffers, setDetailOffers] = useState<any[]>([])
  const [detailInvoice, setDetailInvoice] = useState<any>(null)
  const [detailMessages, setDetailMessages] = useState<any[]>([])
  const [showDetail, setShowDetail] = useState(false)
  const [detailLoading, setDetailLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      const { data: profile } = await supabase.from('profiles').select('is_admin').eq('id', session.user.id).single()
      if (!profile?.is_admin) { router.push('/dashboard'); return }
      await Promise.all([fetchStats(), fetchUsers(), fetchRequests(), fetchCategories(), fetchLitiges(), fetchCompletedRequests(), fetchWaitlist()])
      setLoading(false)
    }
    load()
  }, [router])

  async function fetchStats() {
    const [{ count: users }, { count: providers }, { count: requests }, { count: completed }] = await Promise.all([
      supabase.from('profiles').select('*', { count: 'exact', head: true }),
      supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'provider'),
      supabase.from('requests').select('*', { count: 'exact', head: true }),
      supabase.from('requests').select('*', { count: 'exact', head: true }).eq('status', 'completed'),
    ])
    setStats({ users: users ?? 0, providers: providers ?? 0, requests: requests ?? 0, completed: completed ?? 0 })
  }

  async function fetchUsers() {
    const { data } = await supabase.from('profiles').select('*').order('created_at', { ascending: false }).limit(50)
    setUsers(data ?? [])
  }

  async function fetchRequests() {
    const { data } = await supabase.from('requests').select('*').order('created_at', { ascending: false }).limit(50)
    setRequests(data ?? [])
  }

  async function fetchCategories() {
    const { data } = await supabase.from('categories').select('*').order('is_custom').order('sort_order')
    setCategories(data ?? [])
  }

  async function fetchWaitlist() {
    const { data } = await supabase.from('waitlist').select('*').order('created_at', { ascending: false })
    setWaitlist(data ?? [])
  }

  async function fetchLitiges() {
    const { data } = await supabase.from('litiges').select('*').order('created_at', { ascending: false })
    const enriched = []
    for (const l of data ?? []) {
      try {
        const { data: req } = await supabase.from('requests').select('title, category, status').eq('id', l.request_id).single()
        enriched.push({ ...l, request: req })
      } catch { enriched.push({ ...l, request: null }) }
    }
    setLitiges(enriched)
  }

  const fetchCompletedRequests = useCallback(async () => {
    const { data } = await supabase.from('requests').select('*')
      .in('status', ['completed', 'in_progress']).order('created_at', { ascending: false })
    const enriched = []
    for (const r of data ?? []) {
      let clientName = 'Inconnu', providerName = '—', offerId = ''
      try {
        const { data: cp } = await supabase.from('profiles').select('full_name').eq('id', r.client_id).single()
        clientName = cp?.full_name ?? 'Inconnu'
      } catch {}
      try {
        const { data: offer } = await supabase.from('offers').select('id, provider_id')
          .eq('request_id', r.id).in('status', ['accepted', 'completed']).limit(1).maybeSingle()
        if (offer) {
          offerId = offer.id
          const { data: pp } = await supabase.from('profiles').select('full_name').eq('id', offer.provider_id).single()
          providerName = pp?.full_name ?? '—'
        }
      } catch {}
      enriched.push({ ...r, client_name: clientName, provider_name: providerName, offer_id: offerId })
    }
    setCompletedRequests(enriched)
  }, [])

  async function toggleSuspend(userId: string, isSuspended: boolean) {
    await supabase.from('profiles').update({ is_suspended: !isSuspended }).eq('id', userId)
    await fetchUsers()
  }

  async function deleteCategory(categoryId: string, slug: string) {
    if (!confirm(t('cat_delete_confirm'))) return
    await supabase.from('requests').update({ category: 'other' }).eq('category', slug)
    await supabase.from('categories').delete().eq('id', categoryId)
    await fetchCategories()
  }

  async function createLitige(requestId: string, offerId: string) {
    if (!litigeForm.description.trim()) { alert(t('litige_desc_required')); return }
    setSubmitting(true)
    try {
      const { data: { session } } = await supabase.auth.getSession()
      await supabase.from('litiges').insert({
        request_id: requestId, offer_id: offerId || null,
        opened_by: session?.user.id, reason: litigeForm.reason,
        description: litigeForm.description.trim(), status: 'open',
      })
      setShowLitigeForm(null)
      setLitigeForm({ reason: 'plainte_client', description: '' })
      await fetchLitiges()
    } catch (e) { console.error(e) }
    setSubmitting(false)
  }

  async function resolveLitige(litigeId: string) {
    if (!confirm(t('litige_resolve_confirm'))) return
    await supabase.from('litiges').update({ status: 'resolved', resolved_at: new Date().toISOString() }).eq('id', litigeId)
    await fetchLitiges()
  }

  async function openDetail(requestId: string) {
    setDetailLoading(true)
    setShowDetail(true)

    // Request + client name
    const { data: req } = await supabase.from('requests').select('*').eq('id', requestId).single()
    let clientName = 'Inconnu'
    try {
      const { data: cp } = await supabase.from('profiles').select('full_name').eq('id', req.client_id).single()
      clientName = cp?.full_name ?? 'Inconnu'
    } catch {}
    setDetailRequest({ ...req, client_name: clientName })

    // Offers with provider names
    const { data: offersData } = await supabase.from('offers').select('*').eq('request_id', requestId).order('created_at', { ascending: false })
    const enrichedOffers = []
    for (const offer of offersData ?? []) {
      try {
        const { data: profile } = await supabase.from('profiles').select('full_name').eq('id', offer.provider_id).single()
        enrichedOffers.push({ ...offer, provider_name: profile?.full_name ?? '—' })
      } catch { enrichedOffers.push({ ...offer, provider_name: '—' }) }
    }
    setDetailOffers(enrichedOffers)

    // Invoice
    const { data: inv } = await supabase.from('invoices').select('*').eq('request_id', requestId).maybeSingle()
    setDetailInvoice(inv)

    // Messages
    const offerIds = enrichedOffers.map((o: any) => o.id)
    if (offerIds.length > 0) {
      const { data: msgsData } = await supabase.from('messages').select('*').in('offer_id', offerIds).order('created_at')
      const enrichedMsgs = []
      for (const msg of msgsData ?? []) {
        try {
          const { data: profile } = await supabase.from('profiles').select('full_name').eq('id', msg.sender_id).single()
          enrichedMsgs.push({ ...msg, sender_name: profile?.full_name ?? '—' })
        } catch { enrichedMsgs.push({ ...msg, sender_name: '—' }) }
      }
      setDetailMessages(enrichedMsgs)
    } else {
      setDetailMessages([])
    }

    setDetailLoading(false)
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  const tabStyle = (tab: string) => ({
    padding: '8px 16px', borderRadius: 8, border: 'none',
    background: activeTab === tab ? 'var(--amber)' : 'transparent',
    color: activeTab === tab ? '#000' : 'var(--text-dim)',
    fontWeight: activeTab === tab ? 600 : 400,
    fontSize: 13, cursor: 'pointer', fontFamily: 'var(--font-sans)',
    whiteSpace: 'nowrap' as const,
  })

  const cardStyle = { background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '14px 18px', marginBottom: 10 }

  const REASONS = [
    { id: 'plainte_client', label: t('reason_client') },
    { id: 'plainte_prestataire', label: t('reason_provider') },
    { id: 'remboursement', label: t('reason_refund') },
    { id: 'qualite', label: t('reason_quality') },
    { id: 'no_show', label: t('reason_noshow') },
    { id: 'autre', label: t('reason_other') },
  ]

  const reasonLabel = (r: string) => REASONS.find(x => x.id === r)?.label ?? r

  const timeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 60) return `${mins} min`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h`
    return `${Math.floor(hours / 24)}j`
  }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--red)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('title')}</h1>
          </div>

          <div style={{ display: 'flex', gap: 4, background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 10, padding: 4, marginBottom: 32, width: 'fit-content', flexWrap: 'wrap' }}>
            <button style={tabStyle('stats')} onClick={() => setActiveTab('stats')}>{t('tab_stats')}</button>
            <button style={tabStyle('users')} onClick={() => setActiveTab('users')}>{t('tab_users')}</button>
            <button style={tabStyle('requests')} onClick={() => setActiveTab('requests')}>{t('tab_requests')}</button>
            <button style={tabStyle('categories')} onClick={() => setActiveTab('categories')}>{t('tab_categories')}</button>
            <button style={tabStyle('litiges')} onClick={() => setActiveTab('litiges')}>{t('tab_litiges')}</button>
            <button style={tabStyle('waitlist')} onClick={() => setActiveTab('waitlist')}>{t('tab_waitlist')}</button>
          </div>

          {/* ═══ STATS ═══ */}
          {activeTab === 'stats' && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
              {[
                { label: t('stat_users'), value: stats.users, color: 'var(--amber)' },
                { label: t('stat_providers'), value: stats.providers, color: 'var(--cyan)' },
                { label: t('stat_requests'), value: stats.requests, color: 'var(--violet, var(--amber))' },
                { label: t('stat_completed'), value: stats.completed, color: 'var(--green)' },
              ].map((s, i) => (
                <div key={i} style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '24px' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 36, fontWeight: 700, color: s.color }}>{s.value}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
                </div>
              ))}
            </div>
          )}

          {/* ═══ USERS ═══ */}
          {activeTab === 'users' && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, overflow: 'hidden' }}>
              <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--line)' }}>
                <span style={{ fontWeight: 600 }}>{t('tab_users')} ({users.length})</span>
              </div>
              {users.map((user, i) => (
                <div key={user.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 20px', borderBottom: i < users.length - 1 ? '1px solid var(--line)' : 'none', opacity: user.is_suspended ? 0.5 : 1 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 500, fontSize: 14 }}>
                      {user.full_name}
                      {user.is_admin && <span style={{ marginLeft: 8, fontSize: 11, color: 'var(--red)', border: '1px solid var(--red)', borderRadius: 4, padding: '1px 6px' }}>ADMIN</span>}
                      {user.is_kyc_verified && <span style={{ marginLeft: 8, fontSize: 11, color: 'var(--cyan)', border: '1px solid var(--cyan)', borderRadius: 4, padding: '1px 6px' }}>KYC</span>}
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 2 }}>{user.email} · {user.role} · ★ {user.rating?.toFixed(1) ?? '—'}</div>
                  </div>
                  <button onClick={() => toggleSuspend(user.id, user.is_suspended)} style={{
                    padding: '6px 14px', background: user.is_suspended ? 'var(--green-soft)' : 'rgba(239,68,68,0.1)',
                    border: `1px solid ${user.is_suspended ? 'var(--green)' : 'var(--red)'}`, borderRadius: 6,
                    color: user.is_suspended ? 'var(--green)' : 'var(--red)', fontSize: 12, cursor: 'pointer', fontFamily: 'var(--font-sans)',
                  }}>
                    {user.is_suspended ? t('reactivate') : t('suspend')}
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* ═══ REQUESTS ═══ */}
          {activeTab === 'requests' && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, overflow: 'hidden' }}>
              <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--line)' }}>
                <span style={{ fontWeight: 600 }}>{t('tab_requests')} ({requests.length})</span>
              </div>
              {requests.map((req, i) => (
                <Link key={req.id} href={`/requests/${req.id}`} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 20px', borderBottom: i < requests.length - 1 ? '1px solid var(--line)' : 'none' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 500, fontSize: 14 }}>{req.title}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 2 }}>{req.category} · {req.location}</div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    {req.budget && <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--amber)' }}>{req.budget}$</span>}
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, padding: '3px 8px', borderRadius: 6,
                      background: req.status === 'open' ? 'var(--amber-soft)' : req.status === 'completed' ? 'var(--green-soft)' : 'var(--bg-3)',
                      color: req.status === 'open' ? 'var(--amber)' : req.status === 'completed' ? 'var(--green)' : 'var(--text-dim)',
                    }}>{req.status}</span>
                  </div>
                </Link>
              ))}
            </div>
          )}

          {/* ═══ CATEGORIES ═══ */}
          {activeTab === 'categories' && (
            <div>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 12 }}>{t('cat_base_title')} ({categories.filter(c => !c.is_custom).length})</h2>
              <p style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 16 }}>{t('cat_base_hint')}</p>
              {categories.filter(c => !c.is_custom).map(cat => (
                <div key={cat.id} style={cardStyle}>
                  <span style={{ fontSize: 18, marginRight: 10 }}>{cat.emoji}</span>
                  <span style={{ fontSize: 14, color: 'var(--text)' }}>{cat.label}</span>
                </div>
              ))}
              <h2 style={{ fontSize: 18, fontWeight: 700, marginTop: 32, marginBottom: 12 }}>{t('cat_custom_title')} ({categories.filter(c => c.is_custom).length})</h2>
              {categories.filter(c => c.is_custom).length === 0 ? (
                <div style={{ ...cardStyle, textAlign: 'center', padding: '24px', color: 'var(--text-mute)' }}>{t('cat_custom_empty')}</div>
              ) : (
                categories.filter(c => c.is_custom).map(cat => (
                  <div key={cat.id} style={{ ...cardStyle, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <span style={{ fontSize: 18, marginRight: 10 }}>{cat.emoji}</span>
                      <span style={{ fontSize: 14, color: 'var(--text)' }}>{cat.label}</span>
                    </div>
                    <button onClick={() => deleteCategory(cat.id, cat.slug)} style={{ background: 'none', border: 'none', color: 'var(--red)', cursor: 'pointer', fontSize: 16 }}>🗑</button>
                  </div>
                ))
              )}
            </div>
          )}

          {/* ═══ LITIGES ═══ */}
          {activeTab === 'litiges' && (
            <div>
              {/* Open litiges */}
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 12 }}>{t('litiges_open_title')}</h2>
              {litiges.filter(l => l.status === 'open').length === 0 ? (
                <div style={{ ...cardStyle, textAlign: 'center', padding: '24px', color: 'var(--text-mute)' }}>{t('litiges_none')}</div>
              ) : (
                litiges.filter(l => l.status === 'open').map(l => (
                  <div key={l.id} style={{ ...cardStyle, background: 'rgba(239,68,68,0.08)', borderColor: 'var(--red)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                      <div style={{ display: 'flex', gap: 8 }}>
                        <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 6, background: 'rgba(239,68,68,0.15)', color: 'var(--red)', fontWeight: 700 }}>● {t('status_open')}</span>
                        <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 6, background: 'var(--bg-3)', color: 'var(--text-dim)', fontWeight: 600 }}>{reasonLabel(l.reason)}</span>
                      </div>
                      <span style={{ fontSize: 11, color: 'var(--text-mute)' }}>{timeAgo(l.created_at)}</span>
                    </div>
                    <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>SOS: {l.request?.title ?? '—'}</div>
                    <p style={{ fontSize: 13, color: 'var(--text-dim)', lineHeight: 1.5, marginBottom: 12 }}>{l.description}</p>
                    <button onClick={() => resolveLitige(l.id)} style={{
                      padding: '8px 16px', background: 'var(--green)', color: '#000', border: 'none',
                      borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'var(--font-sans)',
                    }}>{t('litige_resolve_btn')}</button>
                  </div>
                ))
              )}

              {/* Resolved */}
              {litiges.filter(l => l.status === 'resolved').length > 0 && (
                <>
                  <h3 style={{ fontSize: 14, fontWeight: 600, color: 'var(--text-mute)', marginTop: 24, marginBottom: 12 }}>
                    {t('litiges_resolved')} ({litiges.filter(l => l.status === 'resolved').length})
                  </h3>
                  {litiges.filter(l => l.status === 'resolved').map(l => (
                    <div key={l.id} style={cardStyle}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                        <span style={{ fontSize: 11, color: 'var(--green)', fontWeight: 700 }}>✓ {t('status_resolved')}</span>
                        <span style={{ fontSize: 11, color: 'var(--text-mute)' }}>{timeAgo(l.created_at)}</span>
                      </div>
                      <div style={{ fontSize: 13 }}>SOS: {l.request?.title ?? '—'}</div>
                      <p style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4 }}>{l.description}</p>
                    </div>
                  ))}
                </>
              )}

              {/* Completed SOS */}
              <div style={{ borderTop: '1px solid var(--line)', marginTop: 32, paddingTop: 24 }}>
                <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 4 }}>{t('litiges_completed_title')}</h2>
                <p style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 16 }}>{t('litiges_completed_hint')}</p>
                {completedRequests.length === 0 ? (
                  <div style={{ ...cardStyle, textAlign: 'center', padding: '24px', color: 'var(--text-mute)' }}>{t('litiges_no_completed')}</div>
                ) : (
                  completedRequests.map(r => (
                    <div key={r.id} style={cardStyle}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                        <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 6, background: 'var(--amber-soft)', color: 'var(--amber)', fontWeight: 700 }}>{r.category?.toUpperCase()}</span>
                        <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 6,
                          background: r.status === 'completed' ? 'var(--green-soft)' : 'var(--cyan-soft)',
                          color: r.status === 'completed' ? 'var(--green)' : 'var(--cyan)', fontWeight: 700,
                        }}>{r.status === 'completed' ? t('status_completed') : t('status_in_progress')}</span>
                      </div>
                      <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 6 }}>{r.title}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 8 }}>
                        👤 Client: {r.client_name} · 🔧 Pro: {r.provider_name} · {timeAgo(r.created_at)}
                      </div>
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button onClick={() => openDetail(r.id)} style={{
                          flex: 1, padding: '8px 16px', background: 'none', border: '1px solid var(--cyan)',
                          borderRadius: 8, fontSize: 13, color: 'var(--cyan)', cursor: 'pointer', fontFamily: 'var(--font-sans)',
                        }}>🔍 {t('detail_btn')}</button>

                        {showLitigeForm === r.id ? (
                          <div style={{ flex: 2, background: 'var(--bg-3)', borderRadius: 10, padding: 16 }}>
                            <select value={litigeForm.reason} onChange={e => setLitigeForm(f => ({ ...f, reason: e.target.value }))} style={{
                              width: '100%', padding: '8px 12px', background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 8,
                              color: 'var(--text)', fontSize: 13, marginBottom: 10, outline: 'none', fontFamily: 'var(--font-sans)',
                            }}>
                              {REASONS.map(re => <option key={re.id} value={re.id}>{re.label}</option>)}
                            </select>
                            <textarea value={litigeForm.description} onChange={e => setLitigeForm(f => ({ ...f, description: e.target.value }))}
                              placeholder={t('litige_desc_placeholder')} rows={3} style={{
                                width: '100%', padding: '8px 12px', background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 8,
                                color: 'var(--text)', fontSize: 13, marginBottom: 10, outline: 'none', resize: 'vertical' as const, fontFamily: 'var(--font-sans)',
                              }} />
                            <div style={{ display: 'flex', gap: 8 }}>
                              <button onClick={() => createLitige(r.id, r.offer_id)} disabled={submitting} style={{
                                padding: '8px 16px', background: 'var(--red)', color: '#fff', border: 'none',
                                borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'var(--font-sans)',
                              }}>{submitting ? '...' : t('litige_confirm_btn')}</button>
                              <button onClick={() => setShowLitigeForm(null)} style={{
                                padding: '8px 16px', background: 'none', border: '1px solid var(--line)',
                                borderRadius: 8, fontSize: 13, color: 'var(--text-mute)', cursor: 'pointer', fontFamily: 'var(--font-sans)',
                              }}>{t('litige_cancel_btn')}</button>
                            </div>
                          </div>
                        ) : (
                          <button onClick={() => { setShowLitigeForm(r.id); setLitigeForm({ reason: 'plainte_client', description: '' }) }} style={{
                            flex: 1, padding: '8px 16px', background: 'none', border: '1px solid var(--red)',
                            borderRadius: 8, fontSize: 13, color: 'var(--red)', cursor: 'pointer', fontFamily: 'var(--font-sans)',
                          }}>⚖️ {t('litige_open_btn')}</button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* ═══ WAITLIST ═══ */}
          {activeTab === 'waitlist' && (
            <div>
              {waitlist.length === 0 ? (
                <div style={{ ...cardStyle, textAlign: 'center', padding: '48px', color: 'var(--text-mute)' }}>
                  {t('waitlist_empty')}
                </div>
              ) : (
                <>
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16,
                    background: 'var(--amber-soft)', border: '1px solid var(--amber)',
                    borderRadius: 12, padding: 16,
                  }}>
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: 20, fontWeight: 700, color: 'var(--amber)' }}>
                      {waitlist.length}
                    </span>
                    <span style={{ fontSize: 14, fontWeight: 600, color: 'var(--amber)' }}>
                      {t('waitlist_registered')}
                    </span>
                    <span style={{ marginLeft: 'auto', fontSize: 12, color: 'var(--amber)' }}>
                      {waitlist.filter(w => w.role === 'prestataire').length} {t('waitlist_pros')} · {waitlist.filter(w => w.role === 'client').length} {t('waitlist_clients')}
                    </span>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {waitlist.map((w, i) => {
                      const isProvider = w.role === 'prestataire'
                      const name = w.name || t('waitlist_no_name')
                      return (
                        <div key={w.id ?? i} style={{
                          display: 'flex', alignItems: 'center', gap: 12,
                          background: 'var(--bg-2)', border: '1px solid var(--line)',
                          borderRadius: 12, padding: '12px 16px',
                        }}>
                          <div style={{
                            width: 40, height: 40, borderRadius: '50%',
                            background: isProvider ? 'var(--cyan-soft)' : 'var(--amber-soft)',
                            border: `1px solid ${isProvider ? 'var(--cyan)' : 'var(--amber)'}`,
                            display: 'grid', placeItems: 'center', flexShrink: 0,
                            fontSize: 16, fontWeight: 700,
                            color: isProvider ? 'var(--cyan)' : 'var(--amber)',
                          }}>
                            {name[0]?.toUpperCase() ?? '?'}
                          </div>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--text)' }}>{name}</div>
                            <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{w.email}</div>
                          </div>
                          <span style={{
                            fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 6,
                            background: isProvider ? 'var(--cyan-soft)' : 'var(--amber-soft)',
                            color: isProvider ? 'var(--cyan)' : 'var(--amber)',
                          }}>
                            {isProvider ? t('waitlist_pro_badge') : t('waitlist_client_badge')}
                          </span>
                        </div>
                      )
                    })}
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </main>

      {/* ═══ DETAIL MODAL ═══ */}
      {showDetail && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 100, display: 'grid', placeItems: 'center', padding: 24 }}
          onClick={() => setShowDetail(false)}>
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: 28,
            maxWidth: 700, width: '100%', maxHeight: '85vh', overflowY: 'auto' }}
            onClick={e => e.stopPropagation()}>
            {detailLoading ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'var(--amber)' }}>{t('loading')}</div>
            ) : (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                  <h2 style={{ fontSize: 20, fontWeight: 700 }}>{t('detail_title')}</h2>
                  <button onClick={() => setShowDetail(false)} style={{ background: 'none', border: 'none', color: 'var(--text-mute)', fontSize: 20, cursor: 'pointer' }}>✕</button>
                </div>

                {/* SOS info */}
                <div style={{ marginBottom: 24 }}>
                  {[
                    [t('detail_label_title'), detailRequest?.title],
                    [t('detail_label_client'), detailRequest?.client_name],
                    [t('detail_label_category'), detailRequest?.category],
                    [t('detail_label_status'), detailRequest?.status],
                    [t('detail_label_location'), detailRequest?.location],
                    [t('detail_label_urgency'), detailRequest?.urgency],
                    ...(detailRequest?.budget ? [[t('detail_label_budget'), `${detailRequest.budget}$`]] : []),
                    [t('detail_label_description'), detailRequest?.description],
                  ].map(([label, value], i) => (
                    <div key={i} style={{ display: 'flex', gap: 16, padding: '8px 0', borderBottom: '1px solid var(--line)' }}>
                      <span style={{ fontSize: 13, color: 'var(--text-mute)', minWidth: 100 }}>{label}</span>
                      <span style={{ fontSize: 14, color: 'var(--text)' }}>{value ?? '—'}</span>
                    </div>
                  ))}
                </div>

                {/* Offers */}
                <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 10 }}>{t('detail_offers')} ({detailOffers.length})</h3>
                {detailOffers.length === 0 ? (
                  <p style={{ fontSize: 13, color: 'var(--text-mute)', marginBottom: 20 }}>{t('detail_no_offers')}</p>
                ) : (
                  <div style={{ marginBottom: 20 }}>
                    {detailOffers.map((offer: any) => (
                      <div key={offer.id} style={{
                        padding: 12, marginBottom: 8, borderRadius: 10,
                        background: offer.status === 'accepted' || offer.status === 'completed' ? 'var(--green-soft)' : 'var(--bg-3)',
                        border: `1px solid ${offer.status === 'accepted' || offer.status === 'completed' ? 'var(--green)' : 'var(--line)'}`,
                      }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                          <span style={{ fontWeight: 600 }}>{offer.provider_name}</span>
                          <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, color: 'var(--amber)' }}>{offer.price}$</span>
                        </div>
                        <p style={{ fontSize: 12, color: 'var(--text-dim)', marginTop: 4 }}>{offer.message}</p>
                        <div style={{ fontSize: 11, color: 'var(--text-mute)', marginTop: 4 }}>{offer.status} · 🕐 {offer.availability}</div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Invoice */}
                <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 10 }}>{t('detail_invoice')}</h3>
                {!detailInvoice ? (
                  <p style={{ fontSize: 13, color: 'var(--text-mute)', marginBottom: 20 }}>{t('detail_no_invoice')}</p>
                ) : (
                  <div style={{ padding: 12, borderRadius: 10, background: 'var(--bg-3)', border: '1px solid var(--line)', marginBottom: 20 }}>
                    {[
                      [t('detail_invoice_number'), `#${detailInvoice.invoice_number}`],
                      [t('detail_invoice_amount'), `${detailInvoice.amount}$`],
                      [t('detail_invoice_provider'), `${detailInvoice.provider_amount}$`],
                      [t('detail_invoice_status'), detailInvoice.status],
                    ].map(([label, value], i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0' }}>
                        <span style={{ fontSize: 13, color: 'var(--text-mute)' }}>{label}</span>
                        <span style={{ fontSize: 14, fontWeight: 600 }}>{value}</span>
                      </div>
                    ))}
                  </div>
                )}

                {/* Messages */}
                <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 10 }}>{t('detail_messages')} ({detailMessages.length})</h3>
                {detailMessages.length === 0 ? (
                  <p style={{ fontSize: 13, color: 'var(--text-mute)' }}>{t('detail_no_messages')}</p>
                ) : (
                  <div>
                    {detailMessages.map((msg: any) => (
                      <div key={msg.id} style={{ padding: 10, marginBottom: 6, borderRadius: 8, background: 'var(--bg-3)' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                          <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--cyan)' }}>{msg.sender_name}</span>
                          {msg.created_at && <span style={{ fontSize: 10, color: 'var(--text-mute)' }}>{timeAgo(msg.created_at)}</span>}
                        </div>
                        <p style={{ fontSize: 13, color: 'var(--text)', lineHeight: 1.4 }}>{msg.content}</p>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      )}
    </>
  )
}