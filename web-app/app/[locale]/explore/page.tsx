'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import { getCurrentPosition, calculateDistance, formatDistance } from '@/lib/geolocation'

const CATEGORIES_FR = [
  'Toutes',
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

const CATEGORIES_EN = [
  'All',
  'Tech & IT',
  'Repair & DIY',
  'Music & Events',
  'Transport & Delivery',
  'Courses & Tutoring',
  'Writing & Design',
  'Web & Development',
  'Legal & Admin',
  'Health & Wellness',
  'Other',
]

export default function ExplorePage() {
  const t = useTranslations('explore')
  const [requests, setRequests] = useState<any[]>([])
  const [category, setCategory] = useState(0) // index
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [myCoords, setMyCoords] = useState<{ lat: number; lng: number } | null>(null)
  const [sortByDistance, setSortByDistance] = useState(false)
  const [locating, setLocating] = useState(false)
  const [maxDistance, setMaxDistance] = useState(500)
  const [isProvider, setIsProvider] = useState(false)
  const [locale, setLocale] = useState('fr')

  const CATEGORIES = locale === 'en' ? CATEGORIES_EN : CATEGORIES_FR

  const URGENCY_LABELS: Record<string, string> = {
    asap:     t('urgency_asap'),
    today:    t('urgency_today'),
    tomorrow: t('urgency_tomorrow'),
    week:     t('urgency_week'),
  }

  useEffect(() => {
    const html = document.documentElement.lang
    setLocale(html || 'fr')
  }, [])

  useEffect(() => {
    fetchRequests()
    const channel = supabase.channel('explore')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'requests' }, fetchRequests)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [category])

  useEffect(() => {
    async function loadProfile() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) return
      const { data } = await supabase
        .from('profiles')
        .select('max_distance_km, role, latitude, longitude')
        .eq('id', session.user.id)
        .single()

      if (data?.role === 'provider') {
        setIsProvider(true)
        if (data?.max_distance_km) setMaxDistance(data.max_distance_km)
        if (data?.latitude && data?.longitude) {
          setMyCoords({ lat: data.latitude, lng: data.longitude })
          setSortByDistance(true)
        }
      }
    }
    loadProfile()
  }, [])

  async function fetchRequests() {
    let query = supabase
      .from('requests')
      .select('*')
      .eq('status', 'open')
      .order('created_at', { ascending: false })
      .limit(50)

    const selectedCat = CATEGORIES[category]
    if (category !== 0) {
      query = query.eq('category', selectedCat)
    }

    const { data } = await query
    setRequests(data ?? [])
    setLoading(false)
  }

  async function handleSortByDistance() {
    if (myCoords) {
      setSortByDistance(s => !s)
      return
    }
    setLocating(true)
    try {
      const pos = await getCurrentPosition()
      setMyCoords(pos)
      setSortByDistance(true)
    } catch (e) {
      alert(t('no_results'))
    }
    setLocating(false)
  }

  function getDistance(req: any): number | null {
    if (!myCoords || !req.latitude || !req.longitude) return null
    return calculateDistance(myCoords.lat, myCoords.lng, req.latitude, req.longitude)
  }

  let filtered = requests.filter(r => {
    const matchesSearch = r.title.toLowerCase().includes(search.toLowerCase()) ||
      r.description?.toLowerCase().includes(search.toLowerCase())
    if (!matchesSearch) return false
    if (sortByDistance && myCoords && maxDistance < 500) {
      const dist = getDistance(r)
      if (dist === null) return true
      return dist <= maxDistance
    }
    return true
  })

  if (sortByDistance && myCoords) {
    filtered = [...filtered].sort((a, b) => {
      const da = getDistance(a)
      const db = getDistance(b)
      if (da === null && db === null) return 0
      if (da === null) return 1
      if (db === null) return -1
      return da - db
    })
  }

  const ago = (date: string) => {
    const mins = Math.round((Date.now() - new Date(date).getTime()) / 60000)
    if (mins < 1) return t('ago_now')
    if (mins < 60) return t('ago_min', { count: mins })
    const hrs = Math.floor(mins / 60)
    if (hrs < 24) return t('ago_hours', { count: hrs })
    return t('ago_days', { count: Math.floor(hrs / 24) })
  }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '40px 24px' }}>

          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--cyan)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>
              {t('title')}
              <span style={{ marginLeft: 12, fontFamily: 'var(--font-mono)', fontSize: 16, color: 'var(--cyan)', fontWeight: 400 }}>{filtered.length}</span>
            </h1>
          </div>

          <div style={{ display: 'flex', gap: 10, marginBottom: 12 }}>
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder={t('search_placeholder')}
              style={{
                flex: 1, padding: '12px 16px',
                background: 'var(--bg-2)', border: '1px solid var(--line-2)',
                borderRadius: 10, color: 'var(--text)', fontSize: 14,
                outline: 'none', fontFamily: 'var(--font-sans)',
              }}
            />
            <button
              onClick={handleSortByDistance}
              disabled={locating}
              style={{
                padding: '12px 16px',
                background: sortByDistance ? 'var(--cyan-soft)' : 'var(--bg-2)',
                border: `1px solid ${sortByDistance ? 'var(--cyan)' : 'var(--line-2)'}`,
                borderRadius: 10, color: sortByDistance ? 'var(--cyan)' : 'var(--text-dim)',
                fontSize: 13, cursor: locating ? 'not-allowed' : 'pointer',
                fontFamily: 'var(--font-sans)', whiteSpace: 'nowrap',
              }}
            >
              {locating ? t('locating') : sortByDistance ? t('near_me_active') : t('near_me')}
            </button>
          </div>

          {(isProvider || (sortByDistance && myCoords)) && (
            <div style={{
              background: 'var(--bg-2)', border: '1px solid var(--line)',
              borderRadius: 10, padding: '14px 18px', marginBottom: 20,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 8 }}>
                <span style={{ fontSize: 13, color: 'var(--text-dim)', whiteSpace: 'nowrap' }}>
                  {t('radius_label')}
                </span>
                <input
                  type="range"
                  min={5}
                  max={500}
                  value={maxDistance}
                  onChange={e => setMaxDistance(Number(e.target.value))}
                  style={{ flex: 1, accentColor: 'var(--cyan)' }}
                />
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--cyan)', minWidth: 70, textAlign: 'right' }}>
                  {maxDistance >= 500 ? t('radius_unlimited') : `${maxDistance} km`}
                </span>
              </div>
              {isProvider && (
                <p style={{ fontSize: 11, color: 'var(--text-mute)', margin: 0 }}>
                  {t('radius_profile')} <Link href="/profile" style={{ color: 'var(--cyan)' }}>profil</Link>.
                </p>
              )}
            </div>
          )}

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 32 }}>
            {CATEGORIES.map((cat, i) => (
              <button
                key={cat}
                onClick={() => setCategory(i)}
                style={{
                  padding: '6px 14px',
                  background: category === i ? 'var(--cyan-soft)' : 'var(--bg-2)',
                  border: `1px solid ${category === i ? 'var(--cyan)' : 'var(--line)'}`,
                  borderRadius: 20, cursor: 'pointer',
                  fontSize: 13, color: category === i ? 'var(--cyan)' : 'var(--text-dim)',
                  fontFamily: 'var(--font-sans)',
                }}
              >{cat}</button>
            ))}
          </div>

          {loading ? (
            <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
          ) : filtered.length === 0 ? (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '48px', textAlign: 'center' }}>
              <div style={{ fontSize: 32, marginBottom: 12 }}>🔍</div>
              <p style={{ color: 'var(--text-mute)' }}>{t('no_results')}</p>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 16 }}>
              {filtered.map(req => {
                const dist = getDistance(req)
                return (
                  <Link key={req.id} href={`/requests/${req.id}`} style={{
                    background: 'var(--bg-2)', border: '1px solid var(--line)',
                    borderRadius: 12, padding: '20px', display: 'block',
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
                      <span style={{
                        fontFamily: 'var(--font-mono)', fontSize: 11,
                        padding: '3px 8px', borderRadius: 6,
                        background: 'var(--amber-soft)', color: 'var(--amber)',
                      }}>{req.category}</span>
                      <span style={{ fontSize: 11, color: 'var(--text-mute)', fontFamily: 'var(--font-mono)' }}>{ago(req.created_at)}</span>
                    </div>
                    <h3 style={{ fontSize: 15, fontWeight: 600, marginBottom: 8, lineHeight: 1.4 }}>{req.title}</h3>
                    <p style={{ fontSize: 13, color: 'var(--text-dim)', marginBottom: 12, lineHeight: 1.5, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                      {req.description}
                    </p>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: 12, color: 'var(--text-mute)' }}>{URGENCY_LABELS[req.urgency] ?? req.urgency}</span>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        {dist !== null && (
                          <span style={{ fontSize: 12, color: 'var(--cyan)', fontFamily: 'var(--font-mono)' }}>📍 {formatDistance(dist)}</span>
                        )}
                        {req.budget && <span style={{ fontFamily: 'var(--font-mono)', fontSize: 14, color: 'var(--amber)', fontWeight: 700 }}>{req.budget}$</span>}
                      </div>
                    </div>
                  </Link>
                )
              })}
            </div>
          )}
        </div>
      </main>
    </>
  )
}