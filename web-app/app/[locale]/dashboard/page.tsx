'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

type Profile = {
  id: string
  full_name: string
  email: string
  role: string
  rating: number
  total_missions: number
  is_kyc_verified: boolean
}

export default function DashboardPage() {
  const router = useRouter()
  const t = useTranslations('dashboard')
  const [profile, setProfile] = useState<Profile | null>(null)
  const [activeRole, setActiveRole] = useState<'client' | 'provider'>('client')
  const [requests, setRequests] = useState<any[]>([])
  const [offers, setOffers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  const STATUS_LABELS: Record<string, { label: string, color: string }> = {
    open:        { label: t('status_open'), color: 'var(--amber)' },
    in_progress: { label: t('status_in_progress'), color: 'var(--cyan)' },
    completed:   { label: t('status_completed'), color: 'var(--green)' },
    cancelled:   { label: t('status_cancelled'), color: 'var(--red)' },
    pending:     { label: t('status_pending'), color: 'var(--text-dim)' },
    accepted:    { label: t('status_accepted'), color: 'var(--green)' },
  }

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }

      const { data: prof } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single()
      setProfile(prof)

      const { data: reqs } = await supabase
        .from('requests')
        .select('id, title, category, status, budget, created_at')
        .eq('client_id', session.user.id)
        .order('created_at', { ascending: false })
        .limit(10)
      setRequests(reqs ?? [])

      const { data: offs } = await supabase
        .from('offers')
        .select('*, requests(title, category, status, budget)')
        .eq('provider_id', session.user.id)
        .order('created_at', { ascending: false })
        .limit(10)
      setOffers(offs ?? [])

      setLoading(false)
    }
    load()

    const channel = supabase.channel('dashboard')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests' }, load)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'offers' }, load)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [])

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '40px 24px' }}>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
            <div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
              <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>
                {t('greeting', { name: profile?.full_name?.split(' ')[0] ?? '' })}
              </h1>
            </div>
            {activeRole === 'client' && (
              <Link href="/requests/new" style={{
                padding: '12px 24px', background: 'var(--amber)',
                color: '#000', borderRadius: 10, fontWeight: 600, fontSize: 14,
              }}>
                {t('sos_btn')}
              </Link>
            )}
          </div>

          <div style={{
            display: 'inline-flex',
            background: 'var(--bg-2)',
            border: '1px solid var(--line)',
            borderRadius: 10,
            padding: 4,
            marginBottom: 32,
          }}>
            {(['client', 'provider'] as const).map(r => (
              <button
                key={r}
                onClick={() => setActiveRole(r)}
                style={{
                  padding: '8px 20px',
                  borderRadius: 8,
                  border: 'none',
                  background: activeRole === r ? 'var(--amber)' : 'transparent',
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

          {activeRole === 'client' && (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, marginBottom: 32 }}>
                {[
                  { label: t('stat_total_requests'), value: requests.length },
                  { label: t('stat_in_progress'), value: requests.filter(r => r.status === 'in_progress').length },
                  { label: t('stat_completed'), value: requests.filter(r => r.status === 'completed').length },
                  { label: t('stat_open'), value: requests.filter(r => r.status === 'open').length },
                ].map((s, i) => (
                  <div key={i} style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '20px' }}>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 28, fontWeight: 700, color: 'var(--amber)' }}>{s.value}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
                  </div>
                ))}
              </div>

              <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>{t('my_requests')}</h2>
              {requests.length === 0 ? (
                <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '48px', textAlign: 'center' }}>
                  <div style={{ fontSize: 32, marginBottom: 12 }}>📭</div>
                  <p style={{ color: 'var(--text-mute)', marginBottom: 16 }}>{t('no_requests')}</p>
                  <Link href="/requests/new" style={{ padding: '10px 20px', background: 'var(--amber)', color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 14 }}>
                    {t('create_first')}
                  </Link>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {requests.map(req => {
                    const status = STATUS_LABELS[req.status] ?? { label: req.status, color: 'var(--text-dim)' }
                    return (
                      <Link key={req.id} href={`/requests/${req.id}`} style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                        background: 'var(--bg-2)', border: '1px solid var(--line)',
                        borderRadius: 12, padding: '16px 20px',
                      }}>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: 500, fontSize: 15, marginBottom: 4 }}>{req.title}</div>
                          <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{req.category}</div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                          {req.budget && <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)' }}>{req.budget}$</span>}
                          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, padding: '3px 10px', borderRadius: 6, border: `1px solid ${status.color}`, color: status.color }}>{status.label}</span>
                        </div>
                      </Link>
                    )
                  })}
                </div>
              )}
            </>
          )}

          {activeRole === 'provider' && (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, marginBottom: 32 }}>
                {[
                  { label: t('stat_offers'), value: offers.length },
                  { label: t('stat_accepted'), value: offers.filter(o => o.status === 'accepted').length },
                  { label: t('stat_completed'), value: offers.filter(o => o.status === 'completed').length },
                  { label: t('stat_rating'), value: profile?.rating ? `${profile.rating.toFixed(1)} ★` : '—' },
                ].map((s, i) => (
                  <div key={i} style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '20px' }}>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 28, fontWeight: 700, color: 'var(--green)' }}>{s.value}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
                  </div>
                ))}
              </div>

              <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>{t('my_offers')}</h2>
              {offers.length === 0 ? (
                <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '48px', textAlign: 'center' }}>
                  <div style={{ fontSize: 32, marginBottom: 12 }}>🔍</div>
                  <p style={{ color: 'var(--text-mute)' }}>{t('no_offers')}</p>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {offers.map(offer => {
                    const req = offer.requests
                    const offerStatus = STATUS_LABELS[offer.status] ?? { label: offer.status, color: 'var(--text-dim)' }
                    return (
                      <Link key={offer.id} href={`/requests/${offer.request_id}`} style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                        background: 'var(--bg-2)', border: '1px solid var(--line)',
                        borderRadius: 12, padding: '16px 20px',
                      }}>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: 500, fontSize: 15, marginBottom: 4 }}>{req?.title ?? 'Demande'}</div>
                          <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{req?.category}</div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--green)' }}>{offer.price}$</span>
                          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, padding: '3px 10px', borderRadius: 6, border: `1px solid ${offerStatus.color}`, color: offerStatus.color }}>{offerStatus.label}</span>
                        </div>
                      </Link>
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