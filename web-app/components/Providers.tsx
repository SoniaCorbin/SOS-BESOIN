'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'

export default function Providers() {
  const t = useTranslations('providers')
  const [providers, setProviders] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      const { data } = await supabase
        .from('profiles')
        .select('id, full_name, role, rating, total_missions, is_kyc_verified')
        .eq('role', 'provider')
        .eq('is_kyc_verified', true)
        .order('total_missions', { ascending: false })
        .limit(6)
      setProviders(data ?? [])
      setLoading(false)
    }
    load()
  }, [])

  return (
    <section style={{ padding: '80px 24px' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{
            fontFamily: 'var(--font-mono)', fontSize: 11,
            color: 'var(--green)', letterSpacing: '0.1em', textTransform: 'uppercase',
          }}>{t('tag')}</span>
          <h2 style={{
            fontSize: 'clamp(28px, 4vw, 48px)', fontWeight: 700,
            marginTop: 12, letterSpacing: '-0.02em',
          }}>
            {t('title')} <span style={{ color: 'var(--green)' }}>{t('title_accent')}</span>
          </h2>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', color: 'var(--text-mute)', fontFamily: 'var(--font-mono)' }}>
            {t('loading')}
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
            gap: 16, marginBottom: 48,
          }}>
            {providers.map(p => {
              const initials = p.full_name?.split(' ').length >= 2
                ? `${p.full_name.split(' ')[0][0]}${p.full_name.split(' ')[1][0]}`.toUpperCase()
                : p.full_name?.substring(0, 2).toUpperCase() ?? '??'

              return (
                <div key={p.id} style={{
                  background: 'var(--bg-2)', border: '1px solid var(--line)',
                  borderRadius: 14, padding: '20px',
                  display: 'flex', alignItems: 'center', gap: 14,
                }}>
                  <div style={{
                    width: 48, height: 48, borderRadius: '50%',
                    background: 'var(--green-soft)',
                    border: '2px solid var(--green)',
                    display: 'grid', placeItems: 'center',
                    fontSize: 16, fontWeight: 700, color: 'var(--green)',
                    flexShrink: 0,
                  }}>{initials}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 2 }}>{p.full_name}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      <span>★ {p.rating?.toFixed(1) ?? '—'}</span>
                      <span>·</span>
                      <span>{t('missions', { count: p.total_missions ?? 0 })}</span>
                    </div>
                    {p.is_kyc_verified && (
                      <div style={{ fontSize: 11, color: 'var(--green)', marginTop: 4, fontFamily: 'var(--font-mono)' }}>
                        {t('kyc')}
                      </div>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {/* CTA prestataire */}
        <div style={{
          background: 'var(--bg-2)', border: '1px solid var(--green)',
          borderRadius: 16, padding: '32px', textAlign: 'center',
        }}>
          <h3 style={{ fontSize: 20, fontWeight: 600, marginBottom: 8 }}>{t('join_title')}</h3>
          <p style={{ fontSize: 14, color: 'var(--text-dim)', marginBottom: 20 }}>{t('join_subtitle')}</p>
          <Link href="/register" style={{
            padding: '12px 24px', background: 'var(--green)',
            color: '#000', borderRadius: 8,
            fontWeight: 600, fontSize: 14, display: 'inline-block',
          }}>
            {t('join_btn')}
          </Link>
        </div>
      </div>
    </section>
  )
}