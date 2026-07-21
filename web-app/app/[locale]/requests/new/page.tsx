'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import { getCurrentPosition } from '@/lib/geolocation'

const CATEGORIES = [
  { emoji: '💻', label: 'Tech & Informatique', slug: 'Tech & Informatique' },
  { emoji: '🔧', label: 'Réparation & Bricolage', slug: 'Réparation & Bricolage' },
  { emoji: '🎵', label: 'Musique & Événements', slug: 'Musique & Événements' },
  { emoji: '🚗', label: 'Transport & Livraison', slug: 'Transport & Livraison' },
  { emoji: '📚', label: 'Cours & Tutoriels', slug: 'Cours & Tutoriels' },
  { emoji: '✍️', label: 'Rédaction & Graphisme', slug: 'Rédaction & Graphisme' },
  { emoji: '🌐', label: 'Web & Développement', slug: 'Web & Développement' },
  { emoji: '⚖️', label: 'Juridique & Admin', slug: 'Juridique & Admin' },
  { emoji: '💆', label: 'Santé & Bien-être', slug: 'Santé & Bien-être' },
  { emoji: '🔁', label: 'Autres', slug: 'Autres' },
]

export default function NewRequestPage() {
  const router = useRouter()
  const t = useTranslations('request_new')
  const [form, setForm] = useState({
    category: '',
    title: '',
    description: '',
    urgency: 'today',
    location: '',
    neighborhood: '',
    budget: '',
    latitude: null as number | null,
    longitude: null as number | null,
  })
  const [locating, setLocating] = useState(false)
  const [locationObtained, setLocationObtained] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [userId, setUserId] = useState<string | null>(null)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) { router.push('/login'); return }
      setUserId(data.session.user.id)
    })
  }, [])

  async function handleLocation() {
    setLocating(true)
    try {
      const pos = await getCurrentPosition()
      setForm(f => ({ ...f, latitude: pos.lat, longitude: pos.lng }))
      setLocationObtained(true)
    } catch (e) {}
    setLocating(false)
  }

  async function handleSubmit() {
    if (!form.category) { alert(t('error_category')); return }
    if (!form.title || !form.description || !form.location) { alert(t('error_fields')); return }
    setSubmitting(true)

    const { error } = await supabase.from('requests').insert({
      client_id:    userId,
      category:     form.category,
      title:        form.title,
      description:  form.description,
      urgency:      form.urgency,
      location:     form.location,
      neighborhood: form.neighborhood || null,
      budget:       form.budget ? parseFloat(form.budget) : null,
      latitude:     form.latitude,
      longitude:    form.longitude,
      status:       'open',
    })

    if (!error) {
      alert(t('success'))
      router.push('/dashboard')
    }
    setSubmitting(false)
  }

  const URGENCIES = [
    { id: 'asap',     label: t('urgency_asap') },
    { id: 'today',    label: t('urgency_today') },
    { id: 'tomorrow', label: t('urgency_tomorrow') },
    { id: 'week',     label: t('urgency_week') },
  ]

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 700, margin: '0 auto', padding: '40px 24px' }}>

          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('title')}</h1>
          </div>

          {/* Étape 1 — Catégorie */}
          <div style={{ marginBottom: 32 }}>
            <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 16, color: 'var(--text-dim)' }}>{t('step1')}</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 10 }}>
              {CATEGORIES.map(cat => (
                <button
                  key={cat.slug}
                  onClick={() => setForm(f => ({ ...f, category: cat.slug }))}
                  style={{
                    padding: '12px 14px',
                    background: form.category === cat.slug ? 'var(--amber-soft)' : 'var(--bg-2)',
                    border: `1px solid ${form.category === cat.slug ? 'var(--amber)' : 'var(--line)'}`,
                    borderRadius: 10, cursor: 'pointer',
                    color: form.category === cat.slug ? 'var(--amber)' : 'var(--text-dim)',
                    fontSize: 13, fontWeight: form.category === cat.slug ? 600 : 400,
                    textAlign: 'left', fontFamily: 'var(--font-sans)',
                    display: 'flex', alignItems: 'center', gap: 8,
                  }}
                >
                  <span>{cat.emoji}</span>
                  <span>{cat.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Étape 2 — Détails */}
          <div style={{ marginBottom: 32 }}>
            <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 16, color: 'var(--text-dim)' }}>{t('step2')}</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('title_label')}</label>
                <input
                  type="text"
                  value={form.title}
                  onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                  placeholder={t('title_hint')}
                  style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-2)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
                />
              </div>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('desc_label')}</label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder={t('desc_hint')}
                  rows={4}
                  style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-2)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none', resize: 'vertical', fontFamily: 'var(--font-sans)' }}
                />
              </div>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 10 }}>{t('urgency_label')}</label>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  {URGENCIES.map(u => (
                    <button
                      key={u.id}
                      onClick={() => setForm(f => ({ ...f, urgency: u.id }))}
                      style={{
                        padding: '8px 14px',
                        background: form.urgency === u.id ? 'var(--amber-soft)' : 'var(--bg-2)',
                        border: `1px solid ${form.urgency === u.id ? 'var(--amber)' : 'var(--line)'}`,
                        borderRadius: 20, cursor: 'pointer',
                        fontSize: 13, color: form.urgency === u.id ? 'var(--amber)' : 'var(--text-dim)',
                        fontFamily: 'var(--font-sans)',
                      }}
                    >
                      {u.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Étape 3 — Localisation & Budget */}
          <div style={{ marginBottom: 32 }}>
            <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 16, color: 'var(--text-dim)' }}>{t('step3')}</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('city_label')}</label>
                <input
                  type="text"
                  value={form.location}
                  onChange={e => setForm(f => ({ ...f, location: e.target.value }))}
                  placeholder={t('city_hint')}
                  style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-2)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
                />
              </div>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('neighborhood_label')}</label>
                <input
                  type="text"
                  value={form.neighborhood}
                  onChange={e => setForm(f => ({ ...f, neighborhood: e.target.value }))}
                  placeholder={t('neighborhood_hint')}
                  style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-2)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
                />
              </div>
              <button
                onClick={handleLocation}
                disabled={locating}
                style={{
                  padding: '10px 16px',
                  background: locationObtained ? 'var(--green-soft)' : 'var(--bg-2)',
                  border: `1px solid ${locationObtained ? 'var(--green)' : 'var(--line-2)'}`,
                  borderRadius: 8, fontSize: 13,
                  color: locationObtained ? 'var(--green)' : 'var(--text-dim)',
                  cursor: 'pointer', fontFamily: 'var(--font-sans)', textAlign: 'left',
                }}
              >
                {locating ? t('locating') : locationObtained ? t('location_obtained') : t('location_btn')}
              </button>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('budget_label')}</label>
                <input
                  type="number"
                  value={form.budget}
                  onChange={e => setForm(f => ({ ...f, budget: e.target.value }))}
                  placeholder={t('budget_hint')}
                  style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-2)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
                />
              </div>
            </div>
          </div>

          {/* Note + bouton */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '16px 20px', marginBottom: 20 }}>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', display: 'flex', alignItems: 'center', gap: 8 }}>
              🔒 {t('escrow_note')}
            </p>
          </div>

          <button
            onClick={handleSubmit}
            disabled={submitting}
            style={{
              width: '100%', padding: '14px',
              background: submitting ? 'var(--bg-3)' : 'var(--amber)',
              color: submitting ? 'var(--text-dim)' : '#000',
              border: 'none', borderRadius: 10,
              fontWeight: 700, fontSize: 16, cursor: submitting ? 'not-allowed' : 'pointer',
              fontFamily: 'var(--font-sans)',
            }}
          >
            {submitting ? t('submitting') : t('submit_btn')}
          </button>
        </div>
      </main>
    </>
  )
}