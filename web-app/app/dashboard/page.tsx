'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
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

type Request = {
  id: string
  title: string
  category: string
  status: string
  budget: number
  created_at: string
}

const STATUS_LABELS: Record<string, { label: string, color: string }> = {
  open:        { label: 'Ouvert', color: 'var(--amber)' },
  in_progress: { label: 'En cours', color: 'var(--cyan)' },
  completed:   { label: 'Complété', color: 'var(--green)' },
  cancelled:   { label: 'Annulé', color: 'var(--red)' },
}

export default function DashboardPage() {
  const router = useRouter()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [requests, setRequests] = useState<Request[]>([])
  const [loading, setLoading] = useState(true)

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
        .from('service_requests')
        .select('id, title, category, status, budget, created_at')
        .eq('client_id', session.user.id)
        .order('created_at', { ascending: false })
        .limit(10)
      setRequests(reqs ?? [])
      setLoading(false)
    }
    load()

    // Temps réel
    const channel = supabase.channel('dashboard')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'service_requests' }, () => load())
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [])

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>Chargement...</div>
    </div>
  )

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '40px 24px' }}>

          {/* Header */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 40 }}>
            <div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·DASHBOARD·</span>
              <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>
                Bonjour, {profile?.full_name?.split(' ')[0]} 👋
              </h1>
            </div>
            <Link href="/requests/new" style={{
              padding: '12px 24px',
              background: 'var(--amber)',
              color: '#000',
              borderRadius: 10,
              fontWeight: 600,
              fontSize: 14,
            }}>
              + Lancer un SOS
            </Link>
          </div>

          {/* Stats */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, marginBottom: 40 }}>
            {[
              { label: 'Demandes totales', value: requests.length },
              { label: 'En cours', value: requests.filter(r => r.status === 'in_progress').length },
              { label: 'Complétées', value: requests.filter(r => r.status === 'completed').length },
              { label: 'Ouvertes', value: requests.filter(r => r.status === 'open').length },
            ].map((s, i) => (
              <div key={i} style={{
                background: 'var(--bg-2)',
                border: '1px solid var(--line)',
                borderRadius: 12,
                padding: '20px',
              }}>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 28, fontWeight: 700, color: 'var(--amber)' }}>{s.value}</div>
                <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* Demandes */}
          <div>
            <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>Mes demandes</h2>
            {requests.length === 0 ? (
              <div style={{
                background: 'var(--bg-2)', border: '1px solid var(--line)',
                borderRadius: 12, padding: '48px', textAlign: 'center',
              }}>
                <div style={{ fontSize: 32, marginBottom: 12 }}>📭</div>
                <p style={{ color: 'var(--text-mute)', marginBottom: 16 }}>Aucune demande pour l'instant.</p>
                <Link href="/requests/new" style={{
                  padding: '10px 20px', background: 'var(--amber)',
                  color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 14,
                }}>
                  Créer ma première demande
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
                        {req.budget && (
                          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)' }}>
                            {req.budget}$
                          </span>
                        )}
                        <span style={{
                          fontFamily: 'var(--font-mono)', fontSize: 11,
                          padding: '3px 10px', borderRadius: 6,
                          border: `1px solid ${status.color}`,
                          color: status.color,
                        }}>{status.label}</span>
                      </div>
                    </Link>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      </main>
    </>
  )
}