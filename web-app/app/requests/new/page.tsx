'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

const CATEGORIES = [
  'Tech & Informatique',
  'Réparation & Bricolage',
  'Musique & Événements',
  'Transport & Livraison',
  'Cours & Tutoriels',
  'Rédaction & Graphisme',
  'Web & Développement',
  'Juridique & Admin',
  'Santé & Bien-être',
  'Autres',
]

const URGENCY = [
  { value: 'asap', label: '🔴 Dès que possible' },
  { value: 'today', label: '🟠 Aujourd\'hui' },
  { value: 'tomorrow', label: '🟡 Demain' },
  { value: 'week', label: '🟢 Cette semaine' },
]

export default function NewRequestPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [form, setForm] = useState({
    title: '',
    description: '',
    category: '',
    urgency: 'asap',
    budget: '',
    location: 'Montréal',
  })

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) router.push('/login')
    })
  }, [])

  function update(key: string, value: string) {
    setForm(f => ({ ...f, [key]: value }))
  }

  async function handleSubmit() {
    if (!form.title || !form.description || !form.category) {
      setError('Remplissez tous les champs obligatoires.')
      return
    }
    setLoading(true)
    setError('')

    const { data: { session } } = await supabase.auth.getSession()
    if (!session) { router.push('/login'); return }

    const { data, error: insertError } = await supabase
      .from('requests')
      .insert({
        title: form.title,
        description: form.description,
        category: form.category,
        urgency: form.urgency,
        budget: form.budget ? parseFloat(form.budget) : null,
        location: form.location,
        client_id: session.user.id,
        status: 'open',
      })
      .select()
      .single()

    if (insertError) {
      setError('Erreur lors de la création. Réessayez.')
      setLoading(false)
      return
    }

    router.push(`/requests/${data.id}`)
  }

  const inputStyle = {
    width: '100%', padding: '10px 14px',
    background: 'var(--bg-3)', border: '1px solid var(--line-2)',
    borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none',
    fontFamily: 'var(--font-sans)',
  }

  const labelStyle = {
    fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6,
  }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 680, margin: '0 auto', padding: '40px 24px' }}>

          {/* Header */}
          <div style={{ marginBottom: 32 }}>
            <Link href="/dashboard" style={{ fontSize: 13, color: 'var(--text-mute)', display: 'flex', alignItems: 'center', gap: 6, marginBottom: 16 }}>
              ← Retour au dashboard
            </Link>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·NOUVELLE_DEMANDE·</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>
              Décrivez votre besoin.
            </h1>
            <p style={{ fontSize: 14, color: 'var(--text-dim)', marginTop: 8 }}>
              Prenez 90 secondes. Les prestataires vous répondent rapidement.
            </p>
          </div>

          {/* Form */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '32px', display: 'flex', flexDirection: 'column', gap: 20 }}>

            {error && (
              <div style={{
                background: 'rgba(239,68,68,0.1)', border: '1px solid var(--red)',
                borderRadius: 8, padding: '10px 14px', fontSize: 13, color: 'var(--red)',
              }}>{error}</div>
            )}

            {/* Titre */}
            <div>
              <label style={labelStyle}>Titre de la demande *</label>
              <input
                type="text"
                value={form.title}
                onChange={e => update('title', e.target.value)}
                placeholder="ex: Réparer mon lave-vaisselle en urgence"
                style={inputStyle}
              />
            </div>

            {/* Catégorie */}
            <div>
              <label style={labelStyle}>Catégorie *</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 8 }}>
                {CATEGORIES.map(cat => (
                  <button
                    key={cat}
                    onClick={() => update('category', cat)}
                    style={{
                      padding: '8px 12px',
                      background: form.category === cat ? 'var(--amber-soft)' : 'var(--bg-3)',
                      border: `1px solid ${form.category === cat ? 'var(--amber)' : 'var(--line-2)'}`,
                      borderRadius: 8, cursor: 'pointer',
                      fontSize: 13, color: form.category === cat ? 'var(--amber)' : 'var(--text-dim)',
                      fontFamily: 'var(--font-sans)', textAlign: 'left',
                    }}
                  >{cat}</button>
                ))}
              </div>
            </div>

            {/* Description */}
            <div>
              <label style={labelStyle}>Description *</label>
              <textarea
                value={form.description}
                onChange={e => update('description', e.target.value)}
                placeholder="Décrivez votre situation en détail..."
                rows={4}
                style={{ ...inputStyle, resize: 'vertical' }}
              />
            </div>

            {/* Urgence */}
            <div>
              <label style={labelStyle}>Urgence</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8 }}>
                {URGENCY.map(u => (
                  <button
                    key={u.value}
                    onClick={() => update('urgency', u.value)}
                    style={{
                      padding: '10px 14px',
                      background: form.urgency === u.value ? 'var(--amber-soft)' : 'var(--bg-3)',
                      border: `1px solid ${form.urgency === u.value ? 'var(--amber)' : 'var(--line-2)'}`,
                      borderRadius: 8, cursor: 'pointer',
                      fontSize: 13, color: 'var(--text)',
                      fontFamily: 'var(--font-sans)', textAlign: 'left',
                    }}
                  >{u.label}</button>
                ))}
              </div>
            </div>

            {/* Budget + Lieu */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div>
                <label style={labelStyle}>Budget estimé ($)</label>
                <input
                  type="number"
                  value={form.budget}
                  onChange={e => update('budget', e.target.value)}
                  placeholder="ex: 150"
                  style={inputStyle}
                />
              </div>
              <div>
                <label style={labelStyle}>Ville</label>
                <input
                  type="text"
                  value={form.location}
                  onChange={e => update('location', e.target.value)}
                  placeholder="Montréal"
                  style={inputStyle}
                />
              </div>
            </div>

            {/* Bouton */}
            <button
              onClick={handleSubmit}
              disabled={loading}
              style={{
                width: '100%', padding: '14px',
                background: loading ? 'var(--bg-3)' : 'var(--amber)',
                color: loading ? 'var(--text-dim)' : '#000',
                border: 'none', borderRadius: 10,
                fontSize: 15, fontWeight: 600,
                cursor: loading ? 'not-allowed' : 'pointer',
                fontFamily: 'var(--font-sans)',
                marginTop: 8,
              }}
            >
              {loading ? 'Publication...' : '🚨 Lancer mon SOS'}
            </button>
          </div>
        </div>
      </main>
    </>
  )
}