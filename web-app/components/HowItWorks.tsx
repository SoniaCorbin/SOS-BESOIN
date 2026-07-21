import { useTranslations } from 'next-intl'

export default function HowItWorks() {
  const t = useTranslations('how_it_works')

  const steps = [
    {
      number: '01',
      title: t('step1_title'),
      desc: t('step1_desc'),
      color: 'var(--amber)',
    },
    {
      number: '02',
      title: t('step2_title'),
      desc: t('step2_desc'),
      color: 'var(--cyan)',
    },
    {
      number: '03',
      title: t('step3_title'),
      desc: t('step3_desc'),
      color: 'var(--violet)',
    },
    {
      number: '04',
      title: t('step4_title'),
      desc: t('step4_desc'),
      color: 'var(--green)',
    },
  ]

  return (
    <section style={{ padding: '80px 24px' }} id="how">
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 64 }}>
          <span style={{
            fontFamily: 'var(--font-mono)',
            fontSize: 11,
            color: 'var(--violet)',
            letterSpacing: '0.1em',
            textTransform: 'uppercase',
          }}>{t('tag')}</span>
          <h2 style={{
            fontSize: 'clamp(28px, 4vw, 48px)',
            fontWeight: 700,
            marginTop: 12,
            letterSpacing: '-0.02em',
          }}>
            {t('title')} <span style={{ color: 'var(--violet)' }}>{t('title_accent')}</span>
          </h2>
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: 24,
        }}>
          {steps.map((step, i) => (
            <div key={i} style={{
              background: 'var(--bg-2)',
              border: '1px solid var(--line)',
              borderRadius: 16,
              padding: '28px 24px',
              position: 'relative',
            }}>
              <div style={{
                fontFamily: 'var(--font-mono)',
                fontSize: 36,
                fontWeight: 700,
                color: step.color,
                opacity: 0.3,
                lineHeight: 1,
                marginBottom: 16,
              }}>{step.number}</div>
              <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 10 }}>{step.title}</h3>
              <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.6 }}>{step.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}