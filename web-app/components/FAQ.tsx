'use client'
import { useState } from 'react'
import { useTranslations } from 'next-intl'

export default function FAQ() {
  const t = useTranslations('faq')
  const [open, setOpen] = useState<number | null>(null)

  const FAQ_ITEMS = [
    { q: t('q1'), a: t('a1') },
    { q: t('q2'), a: t('a2') },
    { q: t('q3'), a: t('a3') },
    { q: t('q4'), a: t('a4') },
    { q: t('q5'), a: t('a5') },
    { q: t('q6'), a: t('a6') },
  ]

  return (
    <section style={{ padding: '80px 24px', background: 'var(--bg-2)' }} id="faq">
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
          <h2 style={{ fontSize: 'clamp(28px, 4vw, 48px)', fontWeight: 700, marginTop: 12, letterSpacing: '-0.02em' }}>
            {t('title')}<br />{t('title_2')}
          </h2>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {FAQ_ITEMS.map((item, i) => (
            <div key={i} style={{
              background: 'var(--bg)',
              border: `1px solid ${open === i ? 'var(--amber)' : 'var(--line)'}`,
              borderRadius: 12,
              overflow: 'hidden',
              transition: 'border-color 0.2s',
            }}>
              <button
                onClick={() => setOpen(open === i ? null : i)}
                style={{
                  width: '100%', padding: '18px 20px',
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                  background: 'transparent', border: 'none',
                  cursor: 'pointer', fontFamily: 'var(--font-sans)',
                  textAlign: 'left',
                }}
              >
                <span style={{ fontSize: 15, fontWeight: 500, color: 'var(--text)' }}>{item.q}</span>
                <span style={{ color: 'var(--amber)', fontSize: 20, marginLeft: 16, flexShrink: 0 }}>
                  {open === i ? '−' : '+'}
                </span>
              </button>
              {open === i && (
                <div style={{ padding: '0 20px 18px', fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7 }}>
                  {item.a}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}