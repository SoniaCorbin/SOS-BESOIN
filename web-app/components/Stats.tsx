'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

export default function Stats() {
  const [stats, setStats] = useState({
    providers: 0,
    requests: 0,
    completed: 0,
    avgRating: 0,
  })

  useEffect(() => {
    async function fetchStats() {
      const [
        { count: providers },
        { count: requests },
        { count: completed },
        { data: ratings },
      ] = await Promise.all([
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'provider').eq('is_kyc_verified', true),
        supabase.from('requests').select('*', { count: 'exact', head: true }).eq('status', 'open'),
        supabase.from('requests').select('*', { count: 'exact', head: true }).eq('status', 'completed'),
        supabase.from('profiles').select('rating').eq('role', 'provider').gt('rating', 0),
      ])

      const avg = ratings && ratings.length > 0
        ? ratings.reduce((sum, p) => sum + (p.rating ?? 0), 0) / ratings.length
        : 0

      setStats({
        providers: providers ?? 0,
        requests: requests ?? 0,
        completed: completed ?? 0,
        avgRating: avg,
      })
    }
    fetchStats()

    const channel = supabase.channel('stats')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests' }, fetchStats)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, fetchStats)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [])

  const items = [
    { label: 'Missions complétées', value: stats.completed.toLocaleString('fr'), icon: '📈' },
    { label: 'Délai moyen de réponse', value: stats.requests > 0 ? '— min' : '— min', icon: '🕐' },
    { label: 'Prestataires vérifiés actifs', value: stats.providers.toLocaleString('fr'), icon: '🛡' },
    { label: 'Note moyenne / 5', value: stats.avgRating > 0 ? stats.avgRating.toFixed(2) : '—', icon: '★' },
  ]

  return (
    <div style={{
      borderTop: '1px solid var(--line)',
      borderBottom: '1px solid var(--line)',
      padding: '28px 24px',
      background: 'var(--bg-2)',
    }}>
      <div style={{
        maxWidth: 1100, margin: '0 auto',
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 0,
      }}>
        {items.map((item, i) => (
          <div key={i} style={{
            textAlign: 'center',
            borderRight: i < items.length - 1 ? '1px solid var(--line)' : 'none',
            padding: '8px 24px',
          }}>
            <div style={{
              fontFamily: 'var(--font-mono)',
              fontSize: 32,
              fontWeight: 700,
              color: i % 2 === 0 ? 'var(--amber)' : 'var(--cyan)',
              lineHeight: 1.2,
            }}>{item.value}</div>
            <div style={{
              fontSize: 12,
              color: 'var(--text-mute)',
              textTransform: 'uppercase',
              letterSpacing: '0.08em',
              marginTop: 6,
            }}>{item.label}</div>
          </div>
        ))}
      </div>
    </div>
  )
}