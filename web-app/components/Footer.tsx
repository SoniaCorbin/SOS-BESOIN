'use client'
import Link from 'next/link'
import { useTranslations } from 'next-intl'

export default function Footer() {
  const t = useTranslations('footer')

  return (
    <footer style={{
      borderTop: '1px solid var(--line)',
      background: 'var(--bg-2)',
      padding: '64px 24px 32px',
      marginTop: 80,
    }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 40,
          marginBottom: 48,
        }}>
          {/* Brand */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8,
                background: 'var(--amber-soft)',
                border: '1px solid var(--amber)',
                display: 'grid', placeItems: 'center',
                color: 'var(--amber)', fontSize: 16,
              }}>⚠</div>
              <span style={{ fontWeight: 700, fontSize: 15 }}>
                SOS<b style={{ color: 'var(--amber)' }}>·BESOIN</b>
              </span>
            </div>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', lineHeight: 1.6 }}>
              {t('tagline')}
            </p>
            <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
              {['𝕏', 'in', '📸'].map((icon, i) => (
                <div key={i} style={{
                  width: 32, height: 32, borderRadius: 8,
                  border: '1px solid var(--line)',
                  display: 'grid', placeItems: 'center',
                  fontSize: 14, color: 'var(--text-mute)',
                  cursor: 'pointer',
                }}>{icon}</div>
              ))}
            </div>
          </div>

          {/* Plateforme */}
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--text)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 16 }}>
              {t('platform')}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { label: t('how_it_works'), href: '#how' },
                { label: t('categories'), href: '#categories' },
                { label: t('live_requests'), href: '/explore' },
                { label: t('become_provider'), href: '/register' },
                { label: t('send_sos'), href: '/requests/new' },
              ].map(link => (
                <Link key={link.href} href={link.href} style={{ fontSize: 14, color: 'var(--text-mute)' }}>
                  {link.label}
                </Link>
              ))}
            </div>
          </div>

          {/* Support */}
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--text)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 16 }}>
              {t('support')}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { label: t('help_center'), href: '#' },
                { label: t('contact'), href: 'mailto:sosbesoinapp@outlook.com' },
                { label: t('faq'), href: '#faq' },
                { label: t('access_app'), href: 'https://app.sosbesoin.ca' },
              ].map(link => (
                <Link key={link.label} href={link.href} style={{ fontSize: 14, color: 'var(--text-mute)' }}>
                  {link.label}
                </Link>
              ))}
            </div>
          </div>

          {/* Légal */}
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--text)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 16 }}>
              {t('legal')}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { label: t('terms'), href: '/terms' },
                { label: t('privacy'), href: '/privacy' },
                { label: t('refund'), href: '/refund' },
                { label: t('cookies'), href: '#' },
              ].map(link => (
                <Link key={link.href} href={link.href} style={{ fontSize: 14, color: 'var(--text-mute)' }}>
                  {link.label}
                </Link>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom */}
        <div style={{
          borderTop: '1px solid var(--line)',
          paddingTop: 24,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 12,
        }}>
          <span style={{ fontSize: 12, color: 'var(--text-mute)' }}>
            {t('copyright')}
          </span>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--green)' }}>
            {t('status')}
          </span>
        </div>
      </div>
    </footer>
  )
}