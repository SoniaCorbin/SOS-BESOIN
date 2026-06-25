'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import { getCurrentPosition } from '@/lib/geolocation'

export default function ProfilePage() {
  const router = useRouter()
  const [profile, setProfile] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [success, setSuccess] = useState(false)
  const [locating, setLocating] = useState(false)
  const [coords, setCoords] = useState<{ lat: number; lng: number } | null>(null)
  const [maxDistanceKm, setMaxDistanceKm] = useState(50)
  const [form, setForm] = useState({
    full_name: '',
    email: '',
    phone: '',
    city: '',
    bio: '',
  })

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }

      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single()

      setProfile(data)
      console.log('ROLE:', data?.role)
      setForm({
        full_name: data?.full_name ?? '',
        email: data?.email ?? '',
        phone: data?.phone ?? '',
        city: data?.city ?? '',
        bio: data?.bio ?? '',
      })
      if (data?.latitude && data?.longitude) {
        setCoords({ lat: data.latitude, lng: data.longitude })
      }
      setMaxDistanceKm(data?.max_distance_km ?? 50)
      setLoading(false)
    }
    load()
  }, [])

  async function handleUseLocation() {
    setLocating(true)
    try {
      const pos = await getCurrentPosition()
      setCoords(pos)
    } catch (e) {
      alert('Impossible d\'obtenir votre position. Vérifiez les permissions.')
    }
    setLocating(false)
  }

  async function handleSave() {
    setSaving(true)
    const { data: { session } } = await supabase.auth.getSession()
    await supabase.from('profiles').update({
      full_name: form.full_name,
      phone: form.phone,
      city: form.city,
      bio: form.bio,
      latitude: coords?.lat ?? null,
      longitude: coords?.lng ?? null,
      max_distance_km: maxDistanceKm,
    }).eq('id', session!.user.id)
    setSaving(false)
    setSuccess(true)
    setTimeout(() => setSuccess(false), 3000)
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>Chargement...</div>
    </div>
  )

  const initials = form.full_name.split(' ').length >= 2
    ? `${form.full_name.split(' ')[0][0]}${form.full_name.split(' ')[1][0]}`.toUpperCase()
    : form.full_name.substring(0, 2).toUpperCase()

  const inputStyle = {
    width: '100%', padding: '10px 14px',
    background: 'var(--bg-3)', border: '1px solid var(--line-2)',
    borderRadius: 8, color: 'var(--text)', fontSize: 14,
    outline: 'none', fontFamily: 'var(--font-sans)',
  }

  const labelStyle = {
    fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6,
  }

const isProvider = profile?.role === 'provider' || profile?.role === 'prestataire'

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 680, margin: '0 auto', padding: '40px 24px' }}>

          {/* Header */}
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·PROFIL·</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>Mon profil</h1>
          </div>

          {/* Avatar + infos */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 32 }}>
            <div style={{
              width: 72, height: 72, borderRadius: '50%',
              background: 'var(--amber-soft)',
              border: '2px solid var(--amber)',
              display: 'grid', placeItems: 'center',
              fontWeight: 700, fontSize: 24, color: 'var(--amber)',
            }}>{initials}</div>
            <div>
              <div style={{ fontWeight: 600, fontSize: 18 }}>{form.full_name}</div>
              <div style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 4 }}>{form.email}</div>
              <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                {profile?.is_kyc_verified && (
                  <span style={{ fontSize: 11, color: 'var(--cyan)', border: '1px solid var(--cyan)', borderRadius: 6, padding: '2px 8px', fontFamily: 'var(--font-mono)' }}>
                    ✓ KYC vérifié
                  </span>
                )}
                <span style={{ fontSize: 11, color: 'var(--text-mute)', border: '1px solid var(--line)', borderRadius: 6, padding: '2px 8px', fontFamily: 'var(--font-mono)' }}>
                  {isProvider ? '🔧 Prestataire' : '🙋 Client'}
                </span>
                {profile?.rating > 0 && (
                  <span style={{ fontSize: 11, color: 'var(--amber)', border: '1px solid var(--amber)', borderRadius: 6, padding: '2px 8px', fontFamily: 'var(--font-mono)' }}>
                    ★ {profile.rating.toFixed(1)}
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Formulaire */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '32px', display: 'flex', flexDirection: 'column', gap: 20 }}>

            {success && (
              <div style={{ background: 'rgba(132,204,22,0.1)', border: '1px solid var(--green)', borderRadius: 8, padding: '10px 14px', fontSize: 13, color: 'var(--green)' }}>
                ✅ Profil mis à jour!
              </div>
            )}

            <div>
              <label style={labelStyle}>Nom complet</label>
              <input type="text" value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))} style={inputStyle} />
            </div>

            <div>
              <label style={labelStyle}>Courriel</label>
              <input type="email" value={form.email} disabled style={{ ...inputStyle, opacity: 0.5, cursor: 'not-allowed' }} />
            </div>

            <div>
              <label style={labelStyle}>Téléphone</label>
              <input type="tel" value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} placeholder="514-555-1234" style={inputStyle} />
            </div>

            <div>
              <label style={labelStyle}>Ville</label>
              <input type="text" value={form.city} onChange={e => setForm(f => ({ ...f, city: e.target.value }))} placeholder="Montréal" style={inputStyle} />
            </div>

            {/* Position GPS */}
            <div>
              <label style={labelStyle}>Position précise (optionnel)</label>
              <button
                onClick={handleUseLocation}
                disabled={locating}
                style={{
                  width: '100%', padding: '10px 14px',
                  background: coords ? 'var(--green-soft)' : 'var(--bg-3)',
                  border: `1px solid ${coords ? 'var(--green)' : 'var(--line-2)'}`,
                  borderRadius: 8, cursor: locating ? 'not-allowed' : 'pointer',
                  fontSize: 13, color: coords ? 'var(--green)' : 'var(--text-dim)',
                  fontFamily: 'var(--font-sans)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                }}
              >
                {locating ? '📍 Localisation...' : coords ? '✓ Position enregistrée' : '📍 Utiliser ma position actuelle'}
              </button>
            </div>

            {/* Rayon de travail (prestataire seulement) */}
            {isProvider && (
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                  <label style={labelStyle}>📡 Rayon de travail</label>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--cyan)', fontWeight: 600 }}>
                    {maxDistanceKm >= 500 ? 'Illimité' : `${maxDistanceKm} km`}
                  </span>
                </div>
                <input
                  type="range"
                  min={5}
                  max={500}
                  value={maxDistanceKm}
                  onChange={e => setMaxDistanceKm(Number(e.target.value))}
                  style={{ width: '100%', accentColor: 'var(--cyan)' }}
                />
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--text-mute)', marginTop: 4 }}>
                  <span>5 km</span>
                  <span>Illimité</span>
                </div>
                <p style={{ fontSize: 11, color: 'var(--text-mute)', marginTop: 6 }}>
                  Vous ne verrez que les demandes dans ce rayon.
                </p>
              </div>
            )}

            <div>
              <label style={labelStyle}>Bio {isProvider ? '(visible par les clients)' : ''}</label>
              <textarea value={form.bio} onChange={e => setForm(f => ({ ...f, bio: e.target.value }))} placeholder="Décrivez-vous en quelques mots..." rows={4} style={{ ...inputStyle, resize: 'vertical' }} />
            </div>

            <button onClick={handleSave} disabled={saving} style={{
              padding: '12px', background: saving ? 'var(--bg-3)' : 'var(--amber)',
              color: saving ? 'var(--text-dim)' : '#000',
              border: 'none', borderRadius: 8,
              fontSize: 15, fontWeight: 600,
              cursor: saving ? 'not-allowed' : 'pointer',
              fontFamily: 'var(--font-sans)',
            }}>
              {saving ? 'Sauvegarde...' : 'Sauvegarder'}
            </button>
          </div>
        </div>
      </main>
    </>
  )
}