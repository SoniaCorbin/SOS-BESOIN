'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import Link from 'next/link'

type Request = {
  id: string
  title: string
  category: string
  budget: number
  created_at: string
  status: string
  location: string
  urgency: string
}

const CATEGORY_COLORS: Record<string, string> = {
  'Tech & Informatique':   '#06b6d4',
  'Réparation & Bricolage': '#f59e0b',
  'Musique & Événements':  '#8b5cf6',
  'Transport & Livraison': '#84cc16',
  'Cours & Tutoriels':     '#f59e0b',
  'Rédaction & Graphisme': '#ec4899',
  'Web & Développement':   '#06b6d4',
  'Juridique & Admin':     '#8b5cf6',
  'Santé & Bien-être':     '#84cc16',
  'Autres':                '#8892a4',
}

const URGENCY_LABELS: Record<string, string> = {
  asap:     'Dès que possible',
  today:    "Aujourd'hui",
  tomorrow: 'Demain',
  week:     'Cette semaine',
}

export default function LiveBoard() {
  const [requests, setRequests] = useState<Request[]>([])
  const [category, setCategory] = useState('Toutes')
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())

  const CATEGORIES = ['Toutes', 'Tech & Informatique', 'Réparation & Bricolage', 'Musique & Événements', 'Transport & Livraison', 'Cours & Tutoriels', 'Autres']

  useEffect(() => {
    fetchRequests()

    const channel = supabase.channel('liveboard')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests' }, () => {
        fetchRequests()
        setLastUpdate(new Date())
      })
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [category])

  async function fetchRequests() {
    let query = supabase
      .from('requests')
      .select('id, title, category, budget, created_at, status, location, urgency')
      .in('status', ['open', 'in_progress'])
      .order('created_at', { ascending: false })
      .limit(10)

    if (category !== 'Toutes') {
      query = query.eq('category', category)
    }

    const { data } = await query
    setRequests(data ?? [])
    setLastUpdate(new Date())
  }

  const ago = (date: string) => {
    const mins = Math.round((Date.now() - new Date(date).getTime()) / 60000)
    if (mins < 1) return 'à l\'instant'
    if (mins < 60) return `il y a ${mins} min`
    const hrs = Math.floor(mins / 60)
    if (hrs < 24) return `il y a ${hrs}h`
    return `il y a ${Math.floor(hrs / 24)}j`
  }

  return (
    <section style={{ padding: '80px 24px', background: 'var(--bg)' }} id="live">
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>

        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--cyan)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·LIVE_FEED·</span>
          <h2 style={{ fontSize: 'clamp(28px, 4vw, 48px)', fontWeight: 700, marginTop: 12, letterSpacing: '-0.02em' }}>
            Ce qui s'est lancé<br /><span style={{ color: 'var(--cyan)' }}>dans les dernières minutes.</span>
          </h2>
          <p style={{ fontSize: 15, color: 'var(--text-dim)', marginTop: 16, maxWidth: 480, margin: '16px auto 0' }}>
            Aperçu en temps réel des demandes ouvertes. Connectez-vous pour soumettre une offre.
          </p>
        </div>

        {/* Layout */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 24 }}>

          {/* Sidebar filtres */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--text-mute)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>FILTRES</div>
            {CATEGORIES.map(cat => (
              <button
                key={cat}
                onClick={() => setCategory(cat)}
                style={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                  padding: '10px 14px',
                  background: category === cat ? 'var(--cyan-soft)' : 'transparent',
                  border: `1px solid ${category === cat ? 'var(--cyan)' : 'transparent'}`,
                  borderRadius: 8, cursor: 'pointer',
                  fontFamily: 'var(--font-sans)',
                  color: category === cat ? 'var(--cyan)' : 'var(--text-dim)',
                  fontSize: 14, textAlign: 'left',
                }}
              >
                {cat}
              </button>
            ))}

            {/* Mode pro CTA */}
            <div style={{
              marginTop: 16,
              background: 'var(--amber-soft)',
              border: '1px solid var(--amber)',
              borderRadius: 12, padding: '16px',
            }}>
              <div style={{ fontSize: 18, marginBottom: 8 }}>⚡</div>
              <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 6 }}>Mode prestataire</div>
              <div style={{ fontSize: 12, color: 'var(--text-dim)', marginBottom: 12 }}>
                Recevez les nouvelles demandes par notification.
              </div>
              <Link href="/register" style={{ fontSize: 13, color: 'var(--amber)', fontWeight: 600 }}>
                Devenir prestataire →
              </Link>
            </div>
          </div>

          {/* Liste demandes */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, overflow: 'hidden' }}>
            {/* Header liste */}
            <div style={{
              padding: '14px 20px',
              borderBottom: '1px solid var(--line)',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--cyan)', display: 'inline-block' }} />
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--cyan)' }}>
                  Direct · mise à jour {ago(lastUpdate.toISOString())}
                </span>
              </div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-mute)' }}>
                {requests.length} résultats
              </span>
            </div>

            {/* Rows */}
            {requests.length === 0 ? (
              <div style={{ padding: '48px', textAlign: 'center', color: 'var(--text-mute)', fontFamily: 'var(--font-mono)', fontSize: 13 }}>
                Aucune demande active pour le moment.
              </div>
            ) : requests.map((req, i) => {
              const color = CATEGORY_COLORS[req.category] ?? 'var(--text-dim)'
              return (
                <Link key={req.id} href={`/requests/${req.id}`} style={{
                  display: 'flex', alignItems: 'center', gap: 16,
                  padding: '14px 20px',
                  borderBottom: i < requests.length - 1 ? '1px solid var(--line)' : 'none',
                  transition: 'background 0.15s',
                }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-mute)', minWidth: 70, textAlign: 'right' }}>
                    {ago(req.created_at)}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 500, fontSize: 14, marginBottom: 2 }}>{req.title}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>
                      {req.location} · {URGENCY_LABELS[req.urgency] ?? req.urgency}
                    </div>
                  </div>
                  <span style={{
                    fontFamily: 'var(--font-mono)', fontSize: 11,
                    padding: '3px 10px', borderRadius: 6,
                    background: `${color}20`, color,
                    whiteSpace: 'nowrap',
                  }}>
                    {req.category.split(' ')[0]}
                  </span>
                  {req.budget && (
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, fontWeight: 700, color: 'var(--amber)', minWidth: 60, textAlign: 'right' }}>
                      {req.budget}$<span style={{ fontSize: 10, color: 'var(--text-mute)', fontWeight: 400 }}> budget</span>
                    </span>
                  )}
                </Link>
              )
            })}
          </div>
        </div>
      </div>
    </section>
  )
}