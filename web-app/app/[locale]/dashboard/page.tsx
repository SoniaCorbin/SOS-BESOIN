'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import { useActiveRole } from '@/lib/useActiveRole'
import { setActiveRole } from '@/lib/activeRole'

type Profile = {
  id: string
  full_name: string
  email: string
  role: string
  rating: number
  total_missions: number
  is_kyc_verified: boolean
  max_distance_km: number
  provider_categories: string[] | null
}

export default function DashboardPage() {
  const router = useRouter()
  const t = useTranslations('dashboard')
  const [profile, setProfile] = useState<Profile | null>(null)
  const activeRole = useActiveRole()
  const [requests, setRequests] = useState<any[]>([])
  const [offers, setOffers] = useState<any[]>([])
  const [pendingOffersCount, setPendingOffersCount] = useState(0)
  const [showArchived, setShowArchived] = useState(false)
  const [loading, setLoading] = useState(true)
  const [monthlyRevenue, setMonthlyRevenue] = useState(0)

  const STATUS_LABELS: Record<string, { label: string; color: string }> = {
    open: { label: t('status_open'), color: 'var(--amber)' },
    in_progress: { label: t('status_in_progress'), color: 'var(--cyan)' },
    completed: { label: t('status_completed'), color: 'var(--green)' },
    cancelled: { label: t('status_cancelled'), color: 'var(--red)' },
    pending: { label: t('status_pending'), color: 'var(--text-dim)' },
    accepted: { label: t('status_accepted'), color: 'var(--green)' },
  }

  const load = useCallback(async () => {
    const {
      data: { session },
    } = await supabase.auth.getSession()
    if (!session) {
      router.push('/login')
      return
    }

    const { data: prof } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .single()
    setProfile(prof)

    // Client requests (filtered by archive status)
    const { data: reqs } = await supabase
      .from('requests')
      .select('id, title, category, status, budget, created_at')
      .eq('client_id', session.user.id)
      .eq('archived_by_client', showArchived)
      .order('created_at', { ascending: false })
      .limit(20)
    setRequests(reqs ?? [])

    // Pending offers count
    const { data: offersData } = await supabase
      .from('offers')
      .select('id, status')
    const pending = (offersData ?? []).filter(
      (o: any) => o.status === 'pending'
    ).length
    setPendingOffersCount(pending)

    // Provider offers (filtered by archive status)
    const { data: offs } = await supabase
      .from('offers')
      .select('*, requests(id, title, category, status, budget, archived_by_provider)')
      .eq('provider_id', session.user.id)
      .order('created_at', { ascending: false })
      .limit(20)
    // Filter by archive status on the request side
    const filteredOffs = (offs ?? []).filter((o: any) => {
      const req = o.requests
      if (!req) return false
      return req.archived_by_provider === showArchived
    })
    setOffers(filteredOffs)

    // Monthly revenue
    const { data: invoices } = await supabase
      .from('invoices')
      .select('provider_amount, status, created_at')
      .eq('provider_id', session.user.id)
    const now = new Date()
    const revenue = (invoices ?? [])
      .filter((inv: any) => {
        if (inv.status !== 'paid') return false
        const d = new Date(inv.created_at)
        return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth()
      })
      .reduce((sum: number, inv: any) => sum + (inv.provider_amount ?? 0), 0)
    setMonthlyRevenue(revenue)

    setLoading(false)
  }, [showArchived, router])

  useEffect(() => {
    load()

    const channel = supabase
      .channel('dashboard')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests' }, load)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'offers' }, load)
      .subscribe()

    // Reconnect on visibility change
    const handleVisibility = () => {
      if (document.visibilityState === 'visible') {
        supabase.realtime.setAuth(null)
        load()
      }
    }
    document.addEventListener('visibilitychange', handleVisibility)

    return () => {
      supabase.removeChannel(channel)
      document.removeEventListener('visibilitychange', handleVisibility)
    }
  }, [load])

  async function archiveRequest(requestId: string) {
    const column = activeRole === 'client' ? 'archived_by_client' : 'archived_by_provider'
    await supabase.from('requests').update({ [column]: !showArchived }).eq('id', requestId)
    load()
  }

  if (loading)
    return (
      <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
        <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
      </div>
    )

  // Stats for client
  const allClientRequests = requests
  const clientStats = {
    total: allClientRequests.length,
    inProgress: allClientRequests.filter((r) => r.status === 'in_progress').length,
    completed: allClientRequests.filter((r) => r.status === 'completed').length,
  }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '40px 24px' }}>
          {/* Header */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
            <div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>
                {t('tag')}
              </span>
              <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>
                {t('greeting', { name: profile?.full_name?.split(' ')[0] ?? '' })}
              </h1>
            </div>
            {activeRole === 'client' && (
              <Link
                href="/requests/new"
                style={{
                  padding: '12px 24px',
                  background: 'var(--amber)',
                  color: '#000',
                  borderRadius: 10,
                  fontWeight: 600,
                  fontSize: 14,
                }}
              >
                {t('sos_btn')}
              </Link>
            )}
          </div>

          {/* Role toggle */}
          <div
            style={{
              display: 'inline-flex',
              background: 'var(--bg-2)',
              border: '1px solid var(--line)',
              borderRadius: 10,
              padding: 4,
              marginBottom: 32,
            }}
          >
            {(['client', 'provider'] as const).map((r) => (
              <button
                key={r}
                onClick={() => { setActiveRole(r); setShowArchived(false) }}
                style={{
                  padding: '8px 20px',
                  borderRadius: 8,
                  border: 'none',
                  background: activeRole === r ? (r === 'provider' ? 'var(--cyan)' : 'var(--amber)') : 'transparent',
                  color: activeRole === r ? '#000' : 'var(--text-dim)',
                  fontWeight: activeRole === r ? 600 : 400,
                  fontSize: 14,
                  cursor: 'pointer',
                  fontFamily: 'var(--font-sans)',
                  transition: 'all 0.15s',
                }}
              >
                {r === 'client' ? t('role_client') : t('role_provider')}
              </button>
            ))}
          </div>

          {/* ═══ CLIENT VIEW ═══ */}
          {activeRole === 'client' && (
            <>
              {/* Stats */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, marginBottom: 16 }}>
                {[
                  { label: t('stat_total_requests'), value: clientStats.total, color: 'var(--amber)' },
                  { label: t('stat_in_progress'), value: clientStats.inProgress, color: 'var(--cyan)' },
                  { label: t('stat_completed'), value: clientStats.completed, color: 'var(--green)' },
                ].map((s, i) => (
                  <div key={i} style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '20px' }}>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 28, fontWeight: 700, color: s.color }}>{s.value}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
                  </div>
                ))}
              </div>

              {/* Pending offers banner */}
              <div
                style={{
                  padding: '14px 16px',
                  borderRadius: 14,
                  border: `1.5px solid ${pendingOffersCount > 0 ? 'var(--amber)' : 'var(--line)'}`,
                  background: pendingOffersCount > 0 ? 'var(--amber-soft)' : 'var(--bg-2)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  marginBottom: 32,
                  boxShadow: pendingOffersCount > 0 ? '0 0 16px rgba(245,158,11,0.25)' : 'none',
                }}
              >
                <span style={{ fontSize: 18 }}>{pendingOffersCount > 0 ? '🏷️' : '🏷️'}</span>
                <span
                  style={{
                    flex: 1,
                    fontSize: 13,
                    fontWeight: pendingOffersCount > 0 ? 700 : 500,
                    color: pendingOffersCount > 0 ? 'var(--amber)' : 'var(--text-mute)',
                  }}
                >
                  {pendingOffersCount > 0
                    ? t('pending_offers', { count: pendingOffersCount })
                    : t('no_pending_offers')}
                </span>
                {pendingOffersCount > 0 && (
                  <span
                    style={{
                      background: 'var(--amber)',
                      color: '#000',
                      fontWeight: 800,
                      fontSize: 13,
                      padding: '3px 9px',
                      borderRadius: 20,
                    }}
                  >
                    {pendingOffersCount}
                  </span>
                )}
              </div>

              {/* SOS list header + archive toggle */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <h2 style={{ fontSize: 20, fontWeight: 600 }}>{t('my_requests')}</h2>
                <ArchiveToggle active={showArchived} onChange={setShowArchived} />
              </div>

              {/* SOS list */}
              {requests.length === 0 ? (
                <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '48px', textAlign: 'center' }}>
                  <div style={{ fontSize: 32, marginBottom: 12 }}>{showArchived ? '📦' : '📭'}</div>
                  <p style={{ color: 'var(--text-mute)', marginBottom: 16 }}>
                    {showArchived ? t('no_archived') : t('no_requests')}
                  </p>
                  {!showArchived && (
                    <Link
                      href="/requests/new"
                      style={{
                        padding: '10px 20px',
                        background: 'var(--amber)',
                        color: '#000',
                        borderRadius: 8,
                        fontWeight: 600,
                        fontSize: 14,
                      }}
                    >
                      {t('create_first')}
                    </Link>
                  )}
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {requests.map((req) => {
                    const status = STATUS_LABELS[req.status] ?? { label: req.status, color: 'var(--text-dim)' }
                    return (
                      <div
                        key={req.id}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          background: 'var(--bg-2)',
                          border: '1px solid var(--line)',
                          borderRadius: 12,
                          padding: '16px 20px',
                        }}
                      >
                        <Link href={`/requests/${req.id}`} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                          <div>
                            <div style={{ fontWeight: 500, fontSize: 15, marginBottom: 4 }}>{req.title}</div>
                            <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{req.category}</div>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                            {req.budget && (
                              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)' }}>{req.budget}$</span>
                            )}
                            <span
                              style={{
                                fontFamily: 'var(--font-mono)',
                                fontSize: 11,
                                padding: '3px 10px',
                                borderRadius: 6,
                                border: `1px solid ${status.color}`,
                                color: status.color,
                              }}
                            >
                              {status.label}
                            </span>
                          </div>
                        </Link>
                        <button
                          onClick={() => archiveRequest(req.id)}
                          title={showArchived ? t('unarchive') : t('archive')}
                          style={{
                            marginLeft: 12,
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            color: 'var(--text-mute)',
                            fontSize: 16,
                          }}
                        >
                          {showArchived ? '📤' : '📥'}
                        </button>
                      </div>
                    )
                  })}
                </div>
              )}
            </>
          )}

          {/* ═══ PROVIDER VIEW ═══ */}
          {activeRole === 'provider' && (
            <>
              {/* Stats */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, marginBottom: 32 }}>
                {[
                  { label: t('stat_this_month'), value: `${monthlyRevenue.toFixed(0)}$`, color: 'var(--green)' },
                  { label: t('stat_rating'), value: profile?.rating ? `${profile.rating.toFixed(1)} ★` : '—', color: 'var(--amber)' },
                  { label: t('stat_missions'), value: profile?.total_missions ?? 0, color: 'var(--cyan)' },
                ].map((s, i) => (
                  <div key={i} style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '20px' }}>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 28, fontWeight: 700, color: s.color }}>{s.value}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
                  </div>
                ))}
              </div>

              {/* Missions list header + archive toggle */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <h2 style={{ fontSize: 20, fontWeight: 600 }}>{t('my_offers')}</h2>
                <ArchiveToggle active={showArchived} onChange={setShowArchived} />
              </div>

              {/* Missions list */}
              {offers.length === 0 ? (
                <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '48px', textAlign: 'center' }}>
                  <div style={{ fontSize: 32, marginBottom: 12 }}>{showArchived ? '📦' : '🔍'}</div>
                  <p style={{ color: 'var(--text-mute)' }}>
                    {showArchived ? t('no_archived_missions') : t('no_offers')}
                  </p>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {offers.map((offer) => {
                    const req = offer.requests
                    const offerStatus = STATUS_LABELS[offer.status] ?? { label: offer.status, color: 'var(--text-dim)' }
                    return (
                      <div
                        key={offer.id}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          background: 'var(--bg-2)',
                          border: '1px solid var(--line)',
                          borderRadius: 12,
                          padding: '16px 20px',
                        }}
                      >
                        <Link href={`/requests/${offer.request_id}`} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                          <div>
                            <div style={{ fontWeight: 500, fontSize: 15, marginBottom: 4 }}>{req?.title ?? 'SOS'}</div>
                            <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{req?.category}</div>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--green)' }}>{offer.price}$</span>
                            <span
                              style={{
                                fontFamily: 'var(--font-mono)',
                                fontSize: 11,
                                padding: '3px 10px',
                                borderRadius: 6,
                                border: `1px solid ${offerStatus.color}`,
                                color: offerStatus.color,
                              }}
                            >
                              {offerStatus.label}
                            </span>
                          </div>
                        </Link>
                        <button
                          onClick={() => archiveRequest(offer.request_id)}
                          title={showArchived ? t('unarchive') : t('archive')}
                          style={{
                            marginLeft: 12,
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            color: 'var(--text-mute)',
                            fontSize: 16,
                          }}
                        >
                          {showArchived ? '📤' : '📥'}
                        </button>
                      </div>
                    )
                  })}
                </div>
              )}
            </>
          )}
        </div>
      </main>
    </>
  )
}

function ArchiveToggle({ active, onChange }: { active: boolean; onChange: (v: boolean) => void }) {
  const t = useTranslations('dashboard')
  return (
    <div
      style={{
        display: 'inline-flex',
        background: 'var(--bg-2)',
        border: '1px solid var(--line)',
        borderRadius: 20,
        padding: 3,
      }}
    >
      {[false, true].map((val) => (
        <button
          key={String(val)}
          onClick={() => onChange(val)}
          style={{
            padding: '6px 12px',
            borderRadius: 16,
            border: 'none',
            background: active === val ? 'var(--amber)' : 'transparent',
            color: active === val ? '#000' : 'var(--text-mute)',
            fontWeight: 700,
            fontSize: 11,
            cursor: 'pointer',
            fontFamily: 'var(--font-sans)',
            transition: 'all 0.2s',
          }}
        >
          {val ? t('toggle_archived') : t('toggle_active')}
        </button>
      ))}
    </div>
  )
}