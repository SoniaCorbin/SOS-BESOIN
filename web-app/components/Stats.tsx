'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

export default function Stats() {
  const [stats, setStats] = useState({
    providers: 0,
    requests: 0,
    avgMinutes: 28,
  })

  useEffect(() => {
    async function fetchStats() {
      const [{ count: providers }, { count: requests }] = await Promise.all([
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'provider'),
        supabase.from('service_requests').select('*', { count: 'exact', head: true }).eq('status', 'open'),
      ])
      setStats(s => ({ ...s, providers: providers ?? 0, requests: requests ?? 0 }))
    }
    fetchStats()

    // Temps réel
    const channel = supabase.channel('stats')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'service_requests' }, fetchStats)
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const items = [
    { label: 'Prestataires en ligne', value: stats.providers.toLocaleString('fr') },
    { label: 'Demandes ouvertes', value: stats.requests.toLocaleString('fr') },
    { label: 'Délai médian', value: `${stats.avgMinutes} min` },
  ]

  return (
    <div style={{
      borderTop: '1px solid var(--line)',
      borderBottom: '1px solid var(--line)',
      padding: '24px 0',
      display: 'flex',
      justifyContent: 'center',
      gap: 0,
    }}>
      {items.map((item, i) => (
        <div key={i} style={{
          flex: 1,
          maxWidth: 200,
          textAlign: 'center',
          borderRight: i < items.length - 1 ? '1px solid var(--line)' : 'none',
          padding: '0 32px',
        }}>
          <div style={{
            fontFamily: 'var(--font-mono)',
            fontSize: 28,
            fontWeight: 600,
            color: 'var(--amber)',
          }}>{item.value}</div>
          <div style={{
            fontSize: 12,
            color: 'var(--text-mute)',
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            marginTop: 4,
          }}>{item.label}</div>
        </div>
      ))}
    </div>
  )
}