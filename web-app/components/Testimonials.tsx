import { useTranslations } from 'next-intl'

export default function Testimonials() {
  const t = useTranslations('testimonials')

  const TESTIMONIALS = [
    {
      quote:    t('q1'),
      name:     t('n1'),
      role:     t('r1'),
      initials: 'EL',
      color:    'var(--amber)',
    },
    {
      quote:    t('q2'),
      name:     t('n2'),
      role:     t('r2'),
      initials: 'KB',
      color:    'var(--cyan)',
    },
    {
      quote:    t('q3'),
      name:     t('n3'),
      role:     t('r3'),
      initials: 'SM',
      color:    'var(--violet)',
    },
  ]

  return (
    <section style={{ padding: '80px 24px' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>
            {t('tag')}
          </span>
          <h2 style={{ fontSize: 'clamp(28px, 4vw, 48px)', fontWeight: 700, marginTop: 12, letterSpacing: '-0.02em' }}>
            {t('title')} <span style={{ color: 'var(--amber)' }}>{t('title_accent')}</span>{t('title_2')}
          </h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 20 }}>
          {TESTIMONIALS.map((item, i) => (
            <div key={i} style={{
              background: 'var(--bg-2)', border: '1px solid var(--line)',
              borderRadius: 16, padding: '28px',
              display: 'flex', flexDirection: 'column', gap: 16,
            }}>
              <div style={{ display: 'flex', gap: 4 }}>
                {[0,1,2,3,4].map(s => (
                  <span key={s} style={{ color: 'var(--amber)', fontSize: 14 }}>★</span>
                ))}
              </div>
              <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7, flex: 1 }}>
                « {item.quote} »
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 40, height: 40, borderRadius: '50%',
                  background: item.color, opacity: 0.8,
                  display: 'grid', placeItems: 'center',
                  fontWeight: 700, fontSize: 13, color: '#000',
                }}>{item.initials}</div>
                <div>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{item.name}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{item.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}