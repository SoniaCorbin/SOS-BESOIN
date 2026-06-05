'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

type Request = {
  id: string
  title: string
  category: string
  budget: number
  created_at: string
  status: string
}

const STATUS_LABELS: Record<string, { label: string, color: string }> = {
  open: { label: 'Ouvert', color: 'var(--amber)' },
  in_progress: { label: 'En cours', color: 'var(--cyan)' },
  completed: { label: 'Complété', color: 'var(--green)' },
}

export default function LiveBoard() {
  const [requests, setRequests] = useState<Request[]>([])

  useEffect(() => {
    async function fetchRequests() {
      const { data } = await supabase
        .from('requests')
        .select('id, title, category, budget, created_at, status')
        .in('status', ['open', 'in_progress'])
        .order('created_at', { ascending: false })
        .limit(6)
      setRequests(data ?? [])
    }
    fetchRequests()

    const channel = supabase.channel('liveboard')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests' }, fetchRequests)
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  return (
    <section style={{ padding: '80px 24px', background: 'var(--bg-2)' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 48 }}>
          <div>
            <span style={{
              fontFamily: 'var(--font-mono)',
              fontSize: 11,
              color: 'var(--cyan)',
              letterSpacing: '0.1em',
              textTransform: 'uppercase',
            }}>·LIVE·</span>
            <h2 style={{
              fontSize: 'clamp(28px, 4vw, 48px)',
              fontWeight: 700,
              marginTop: 12,
              letterSpacing: '-0.02em',
            }}>Demandes <span style={{ color: 'var(--cyan)' }}>en ce moment.</span></h2>
          </div>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            fontFamily: 'var(--font-mono)',
            fontSize: 12,
            color: 'var(--cyan)',
          }}>
            <span style={{
              width: 8, height: 8, borderRadius: '50%',
              background: 'var(--cyan)',
              animation: 'pulse 2s infinite',
            }} />
            LIVE
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 12 }}>
          {requests.length === 0 ? (
            <div style={{ color: 'var(--text-mute)', fontFamily: 'var(--font-mono)', fontSize: 13 }}>
              Aucune demande active pour le moment.
            </div>
          ) : requests.map((req) => {
            const status = STATUS_LABELS[req.status] ?? { label: req.status, color: 'var(--text-dim)' }
            const ago = Math.round((Date.now() - new Date(req.created_at).getTime()) / 60000)
            return (
              <div key={req.id} style={{
                background: 'var(--bg)',
                border: '1px solid var(--line)',
                borderRadius: 12,
                padding: '16px 20px',
                display: 'flex',
                flexDirection: 'column',
                gap: 10,
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <span style={{ fontSize: 14, fontWeight: 600, flex: 1 }}>{req.title}</span>
                  <span style={{
                    fontFamily: 'var(--font-mono)',
                    fontSize: 11,
                    color: status.color,
                    border: `1px solid ${status.color}`,
                    borderRadius: 6,
                    padding: '2px 8px',
                    marginLeft: 8,
                    whiteSpace: 'nowrap',
                  }}>{status.label}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 12, color: 'var(--text-mute)' }}>{req.category}</span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--amber)' }}>
                    {req.budget ? `${req.budget}$` : '—'}
                  </span>
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-mute)', fontFamily: 'var(--font-mono)' }}>
                  il y a {ago < 1 ? 'moins d\'1' : ago} min
                </div>
              </div>
            )
          })}
        </div>
      </div>
      <style>{`@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }`}</style>
    </section>
  )
}