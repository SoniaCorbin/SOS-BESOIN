'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'

export default function LiveBoard() {
  const t = useTranslations('liveboard')
  const [requests, setRequests] = useState<any[]>([])

  useEffect(() => {
    fetchRequests()
    const channel = supabase.channel('liveboard')
      .on('postgres_changes', {
        event: '*', schema: 'public', table: 'requests',
      }, fetchRequests)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [])

  async function fetchRequests() {
    const { data } = await supabase
      .from('requests')
      .select('id, title, category, location, urgency, budget, created_at')
      .eq('status', 'open')
      .order('created_at', { ascending: false })
      .limit(6)
    setRequests(data ?? [])
  }

  const ago = (date: string) => {
    const mins = Math.round((Date.now() - new Date(date).getTime()) / 60000)
    if (mins < 1) return t('ago_now')
    if (mins < 60) return t('ago_min', { count: mins })
    return t('ago_hours', { count: Math.floor(mins / 60) })
  }

  const urgencyLabel = (urgency: string) => {
    const labels: Record<string, string> = {
      asap:     t('urgency_asap'),
      today:    t('urgency_today'),
      tomorrow: t('urgency_tomorrow'),
      week:     t('urgency_week'),
    }
    return labels[urgency] ?? urgency
  }

  return (
    <section style={{ padding: '80px 24px', background: 'var(--bg-2)' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 40, flexWrap: 'wrap', gap: 16 }}>
          <div>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--cyan)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>
              <span style={{ display: 'inline-block', width: 6, height: 6, borderRadius: '50%', background: 'var(--cyan)', marginRight: 6, animation: 'pulse 2s infinite' }} />
              {t('tag')}
            </span>
            <h2 style={{ fontSize: 'clamp(24px, 3vw, 40px)', fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>
              {t('title')} <span style={{ color: 'var(--cyan)' }}>{t('title_accent')}</span>
            </h2>
          </div>
          <Link href="/explore" style={{ fontSize: 14, color: 'var(--cyan)', fontWeight: 500 }}>
            {t('see_all')}
          </Link>
        </div>

        {requests.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '48px', color: 'var(--text-mute)', fontSize: 14 }}>
            {t('empty')}
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
            gap: 16,
          }}>
            {requests.map(req => (
              <Link key={req.id} href={`/requests/${req.id}`} style={{
                background: 'var(--bg)',
                border: '1px solid var(--line)',
                borderRadius: 12,
                padding: '18px 20px',
                display: 'block',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
                  <span style={{
                    fontFamily: 'var(--font-mono)', fontSize: 10,
                    padding: '2px 8px', borderRadius: 6,
                    background: 'var(--amber-soft)', color: 'var(--amber)',
                  }}>{req.category}</span>
                  <span style={{ fontSize: 11, color: 'var(--text-mute)', fontFamily: 'var(--font-mono)' }}>{ago(req.created_at)}</span>
                </div>
                <h3 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8, lineHeight: 1.4 }}>{req.title}</h3>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 12, color: 'var(--text-mute)' }}>
                    📍 {req.location} · {urgencyLabel(req.urgency)}
                  </span>
                  {req.budget && (
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)', fontWeight: 700 }}>
                      {req.budget}$
                    </span>
                  )}
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </section>
  )
}